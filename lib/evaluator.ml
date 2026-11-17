(* The Rust evaluator client: discovery, the sha256 pin, request building
   and response mapping. The pinned binary deserialises a {s,e,c} object as
   a record, so the client forwards the normalised decimal form only.
   Licence: AGPL-3.0-or-later; see README.md. *)

type pin = { platform : string; sha256 : string }
type resolved = { path : string; sha256 : string }

(** The pinned evaluator release named in the installation path. *)
let default_version = "v0.7.1"

(** The whole content of [path], read in binary mode. Raises [Sys_error] when
    the file cannot be opened or read. *)
let read_file path =
  let channel = open_in_bin path in
  let length = in_channel_length channel in
  let text = really_input_string channel length in
  close_in channel;
  text

(** The pins listed in the digest table at [path]. Returns [Error] when the file
    is unreadable, is not JSON, or carries no pin row. *)
let load_table path =
  try
    match Json_parse.parse (read_file path) with
    | Error error ->
        Error
          (Failure.make "evaluator" "the digest table %s is not JSON: %s" path
             error.message)
    | Ok document ->
        let rows =
          match Json_ast.member "pins" document with
          | Some (Json_ast.Array rows) -> rows
          | _ -> []
        in
        let parse_row row =
          match
            (Json_ast.member "platform" row, Json_ast.member "sha256" row)
          with
          | Some (Json_ast.String platform), Some (Json_ast.String sha256) ->
              Some { platform; sha256 }
          | _ -> None
        in
        let pins = List.filter_map parse_row rows in
        if pins = [] then
          Error
            (Failure.make "evaluator" "the digest table %s carries no pin" path)
        else Ok pins
  with Sys_error error ->
    Error
      (Failure.make "evaluator" "cannot read the digest table %s: %s" path error)

(** The pins rendered as "platform digest" text joined by commas, for diagnostic
    messages. *)
let supported pins =
  String.concat ", "
    (List.map (fun pin -> Printf.sprintf "%s %s" pin.platform pin.sha256) pins)

(** The first [program] present in the PATH directories, or [None] when no
    directory holds it. *)
let search_path program =
  let path = try Sys.getenv "PATH" with Not_found -> "" in
  let directories = String.split_on_char ':' path in
  List.find_map
    (fun directory ->
      let candidate = Filename.concat directory program in
      if Sys.file_exists candidate then Some candidate else None)
    directories

(** The HOME environment variable, or the empty string when it is unset. *)
let home_directory () = try Sys.getenv "HOME" with Not_found -> ""

(** The installation path of the pinned evaluator, under the .quint directory of
    the home directory. *)
let pinned_path () =
  Filename.concat
    (Filename.concat
       (Filename.concat (home_directory ()) ".quint")
       ("rust-evaluator-" ^ default_version))
    "quint_evaluator"

(** The evaluator path used when no explicit path is given. *)
let default_path () = pinned_path ()

(** A parenthetical note naming the rust-evaluator directories present under
    .quint, or the empty string when none is present or the directory cannot be
    read. *)
let enrichment_note () =
  let root = Filename.concat (home_directory ()) ".quint" in
  if not (Sys.file_exists root) then ""
  else
    try
      let names = Array.to_list (Sys.readdir root) in
      let matches =
        List.filter
          (fun name ->
            String.length name >= String.length "rust-evaluator-v"
            && String.sub name 0 (String.length "rust-evaluator-v")
               = "rust-evaluator-v"
            && Sys.file_exists
                 (Filename.concat (Filename.concat root name) "quint_evaluator"))
          names
      in
      if matches = [] then ""
      else
        Printf.sprintf " (found evaluator directories: %s)"
          (String.concat ", " matches)
    with Sys_error _ -> ""

(** The digest-table paths tried in turn, each resolved beside the running
    executable. *)
let candidate_tables () =
  let beside = Filename.dirname Sys.executable_name in
  [
    Filename.concat beside "evaluator-digests.json";
    Filename.concat beside "../bin/evaluator-digests.json";
    Filename.concat beside "bin/evaluator-digests.json";
    Filename.concat beside "../../bin/evaluator-digests.json";
  ]

(** The first candidate digest-table path that exists, or the first candidate
    when none does. *)
let table_path () =
  match List.find_opt Sys.file_exists (candidate_tables ()) with
  | Some path -> path
  | None -> (
      match candidate_tables () with
      | first :: _ -> first
      | [] -> "evaluator-digests.json")

(** Pin the evaluator binary: an explicit path with a slash is used as given, a
    bare name is searched in PATH, and no argument falls back to the
    installation path; [Error] carries stage "evaluator" on failure. *)
let resolve ?evaluator ?table () =
  let table = match table with Some path -> path | None -> table_path () in
  match load_table table with
  | Error failure -> Error failure
  | Ok pins -> (
      let path =
        match evaluator with
        | Some explicit ->
            if String.contains explicit '/' then
              if Sys.file_exists explicit then Some explicit else None
            else search_path explicit
        | None ->
            let default = default_path () in
            if Sys.file_exists default then Some default else None
      in
      let expected =
        match evaluator with Some path -> path | None -> default_path ()
      in
      match path with
      | None ->
          let note =
            match evaluator with Some _ -> "" | None -> enrichment_note ()
          in
          Error
            (Failure.make "evaluator"
               "evaluator %s does not exist%s; pass --evaluator or install the \
                pinned evaluator"
               expected note)
      | Some path -> (
          try
            let sha256 = Sha256.hex (read_file path) in
            match
              List.find_opt (fun (pin : pin) -> pin.sha256 = sha256) pins
            with
            | Some _ -> Ok { path; sha256 }
            | None ->
                Error
                  (Failure.make "evaluator"
                     "the digest of %s is sha256=%s, which is in no row of the \
                      supported set: %s"
                     path sha256 (supported pins))
          with Sys_error error ->
            Error
              (Failure.make "evaluator" "cannot read evaluator %s: %s" path
                 error)))

(** Run one evaluation request through the binary, passing [request] on standard
    input. Returns [Error] on spawn failure, timeout or a non-zero exit, the
    stage being "evaluate". *)
let run_request evaluator ?(timeout = 30.0) request =
  match
    Proc.run_combined ~stdin:request ~timeout
      [| evaluator.path; "evaluate-at-state-from-stdin" |]
  with
  | { Proc.spawn_error = Some error; _ } ->
      Error
        (Failure.make "evaluate" "cannot run evaluator %s: %s" evaluator.path
           error)
  | { Proc.timed_out = true; _ } ->
      Error
        (Failure.make "evaluate"
           "the evaluator call exceeded the %gs per-call timeout" timeout)
  | { Proc.status = Some 0; output; _ } -> Ok output
  | { Proc.status; output; _ } ->
      let code =
        match status with Some code -> string_of_int code | None -> "unknown"
      in
      Error
        (Failure.make "evaluate" "the evaluator exited with status %s: %s" code
           (String.trim output))

(** Encode a decoded value into the JSON form the evaluator accepts, tagging
    integers, tuples, sets, maps and variants as the protocol requires. Record
    fields are sorted by name. *)
let rec encode_value = function
  | Itf_value.Bool value -> Json_ast.Bool value
  | Itf_value.Str value -> Json_ast.String value
  | Itf_value.Int text -> Json_ast.Object [ ("#bigint", Json_ast.String text) ]
  | Itf_value.List items -> Json_ast.Array (List.map encode_value items)
  | Itf_value.Tuple items ->
      Json_ast.Object [ ("#tup", Json_ast.Array (List.map encode_value items)) ]
  | Itf_value.Set items ->
      Json_ast.Object [ ("#set", Json_ast.Array (List.map encode_value items)) ]
  | Itf_value.Map entries ->
      Json_ast.Object
        [
          ( "#map",
            Json_ast.Array
              (List.map
                 (fun (key, value) ->
                   Json_ast.Array [ encode_value key; encode_value value ])
                 entries) );
        ]
  | Itf_value.Record fields ->
      Json_ast.Object
        (List.map
           (fun (name, value) -> (name, encode_value value))
           (List.sort (fun (a, _) (b, _) -> String.compare a b) fields))
  | Itf_value.Variant (tag, payload) ->
      Json_ast.Object
        [ ("tag", Json_ast.String tag); ("value", encode_value payload) ]
  | Itf_value.Unit -> Json_ast.Object [ ("tag", Json_ast.String "UNIT") ]

(** Build the state object of a request: each declared field carries its encoded
    value, or an empty object when the state does not hold it, all under a
    "#meta" member. *)
let build_state ~decls state =
  let fields =
    decls
    |> List.sort (fun (a, _) (b, _) -> String.compare a b)
    |> List.map (fun (name, _) ->
        match List.assoc_opt name state.Decoder.values with
        | Some value -> (name, encode_value value)
        | None -> (name, Json_ast.Object []))
  in
  Json_ast.Object (("#meta", Json_ast.Object []) :: fields)

(** The decimal magnitude of the signed 64-bit minimum, as the frontend prints
    it. *)
let i64_minimum_magnitude = "9223372036854775808"

(* The pinned evaluator parses integer literals as signed 64-bit values. The
   frontend encodes the signed 64-bit minimum as a negation applied to its
   magnitude, and that magnitude is one past the signed maximum, so the
   evaluator refuses the document. The accepted spelling of the same value is
   the negative decimal literal, which the pinned protocol parses; the corpus
   records that spelling as the accepted request form. Normalise only that one
   shape so the forwarded expression denotes the same value. *)

(** Rewrite the negation-of-magnitude spelling of the signed 64-bit minimum into
    the negative decimal literal the evaluator parses, recursing over objects
    and arrays and leaving other values unchanged. *)
let rec normalise_minimum = function
  | Json_ast.Object members -> (
      match
        ( Json_ast.member "kind" (Json_ast.Object members),
          Json_ast.member "opcode" (Json_ast.Object members),
          Json_ast.member "args" (Json_ast.Object members) )
      with
      | ( Some (Json_ast.String "app"),
          Some (Json_ast.String "iuminus"),
          Some (Json_ast.Array [ argument ]) ) -> (
          match
            (Json_ast.member "kind" argument, Json_ast.member "value" argument)
          with
          | Some (Json_ast.String "int"), Some (Json_ast.Number raw)
            when raw = i64_minimum_magnitude ->
              let id = Json_ast.member "id" (Json_ast.Object members) in
              Json_ast.Object
                ((match id with Some id -> [ ("id", id) ] | None -> [])
                @ [
                    ("kind", Json_ast.String "int");
                    ("value", Json_ast.Number ("-" ^ raw));
                  ])
          | _ ->
              Json_ast.Object
                (List.map
                   (fun (key, value) -> (key, normalise_minimum value))
                   members))
      | _ ->
          Json_ast.Object
            (List.map
               (fun (key, value) -> (key, normalise_minimum value))
               members))
  | Json_ast.Array items -> Json_ast.Array (List.map normalise_minimum items)
  | other -> other

(** Assemble the request object from [table], [state] and [exprs], applying the
    minimum-value normalisation to the table and the expressions. *)
let build_request ~table ~state ~exprs =
  Json_ast.Object
    [
      ("table", normalise_minimum table);
      ("state", state);
      ("exprs", Json_ast.Array (List.map normalise_minimum exprs));
    ]

type outcome = Pass | Fail

(** The protocol type name of a value for diagnostic messages: a tagged object
    reports its first key, an untagged one reports "object". *)
let itf_form = function
  | Json_ast.Object ((key, _) :: _) when String.length key > 0 && key.[0] = '#'
    ->
      key
  | Json_ast.Object _ -> "object"
  | Json_ast.Bool _ -> "boolean"
  | Json_ast.String _ -> "string"
  | Json_ast.Number _ -> "number"
  | Json_ast.Array _ -> "array"
  | Json_ast.Null -> "null"

(** The diagnostic code carried by an error object, or "QNT000" when the object
    carries no string code. *)
let code_of_error error =
  match Json_ast.member "code" error with
  | Some (Json_ast.String code) -> code
  | _ -> "QNT000"

(** The message carried by an error object, or the empty string when it is
    absent or not a string. *)
let message_of_error error =
  match Json_ast.member "message" error with
  | Some (Json_ast.String message) -> message
  | _ -> ""

(** Map one evaluator response to a verdict per invariant. Returns [Error] when
    the output is not JSON, carries no results array, returns a count that
    differs from [invariants], or holds an error or non-boolean result. *)
let interpret ~invariants ~state_index output =
  match Json_parse.parse output with
  | Error error ->
      Error
        (Failure.make "evaluate"
           "the evaluator output at state %d is not JSON: %s" state_index
           error.message)
  | Ok document -> (
      let results =
        match Json_ast.member "results" document with
        | Some (Json_ast.Array results) -> Ok results
        | _ ->
            Error
              (Failure.make "evaluate"
                 "the evaluator output at state %d carries no results array"
                 state_index)
      in
      match results with
      | Error failure -> Error failure
      | Ok results ->
          if List.length results <> List.length invariants then
            Error
              (Failure.make "evaluate"
                 "the evaluator returned %d result(s) at state %d for %d \
                  expression(s)"
                 (List.length results) state_index (List.length invariants))
          else
            let rec combine names results acc =
              match (names, results) with
              | [], [] -> Ok (List.rev acc)
              | name :: names, result :: results -> (
                  match result with
                  | Json_ast.Object members -> (
                      match
                        ( List.assoc_opt "value" members,
                          List.assoc_opt "error" members )
                      with
                      | Some (Json_ast.Bool value), None ->
                          combine names results
                            ((if value then Pass else Fail) :: acc)
                      | Some value, None ->
                          Error
                            (Failure.make "evaluate"
                               "invariant '%s' at state %d returned a \
                                non-boolean %s result"
                               name state_index (itf_form value))
                      | None, Some error ->
                          Error
                            (Failure.make "evaluate"
                               "invariant '%s' at state %d failed: %s %s" name
                               state_index (code_of_error error)
                               (message_of_error error))
                      | _ ->
                          Error
                            (Failure.make "evaluate"
                               "the result for invariant '%s' at state %d is \
                                not a value or an error object"
                               name state_index))
                  | _ ->
                      Error
                        (Failure.make "evaluate"
                           "the result for invariant '%s' at state %d is not \
                            an object"
                           name state_index))
              | _ -> assert false
            in
            combine invariants results [])
