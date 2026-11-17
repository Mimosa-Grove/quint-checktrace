(* The corpus gate: the acceptance instrument.

   The gate validates the committed registry (manifest, derivation records and
   the hand-verified inventory) before classifying rows, replays every admitted
   triple against this checker and evaluates the hand-verified fixtures last.
   It prints its counts line and the end marker on every exit.
   Licence: AGPL-3.0-or-later; see README.md. *)

type config = {
  corpus_root : string;
  manifest : string;
  fixtures : string;
  timeout : int;
  deadline : int;
  gate_deadline : int;
  quint : string;
  evaluator : string option;
}

type counts = {
  mutable entries : int;
  mutable runnable : int;
  mutable triples : int;
  mutable agree : int;
  mutable disagree : int;
  mutable excluded : int;
  mutable fixtures : int;
  mutable fixtures_disagree : int;
}

(** A count record holding [entries] and every other counter at zero. *)
let zeros entries =
  {
    entries;
    runnable = 0;
    triples = 0;
    agree = 0;
    disagree = 0;
    excluded = 0;
    fixtures = 0;
    fixtures_disagree = 0;
  }

(** The counts rendered as the single "name=value" line the gate prints. *)
let count_line counts =
  Printf.sprintf
    "entries=%d runnable=%d triples=%d agree=%d disagree=%d excluded=%d \
     fixtures=%d fixtures_disagree=%d"
    counts.entries counts.runnable counts.triples counts.agree counts.disagree
    counts.excluded counts.fixtures counts.fixtures_disagree

(** The line printed last on every gate exit. *)
let end_marker = "== END OF GATE RUN =="

exception Refusal of string * string

(** Raise [Refusal] carrying [stage] and the formatted message. *)
let refuse stage fmt =
  Printf.ksprintf (fun message -> raise (Refusal (stage, message))) fmt

(** Read a whole file as a binary string. Raises [Sys_error] when the file
    cannot be read. *)
let read_file = Proc.read_file

(** Whether [needle] occurs in [haystack] as a literal substring. An empty
    needle always matches. *)
let contains_sub haystack needle =
  let n = String.length needle and h = String.length haystack in
  let rec loop index =
    if index + n > h then false
    else if String.sub haystack index n = needle then true
    else loop (index + 1)
  in
  n = 0 || loop 0

(** Parse the file at [path] as JSON. Returns [Error] with a message carrying
    the byte offset when the file is unreadable or not JSON. *)
let load_json path =
  try
    match Json_parse.parse (read_file path) with
    | Ok value -> Ok value
    | Error error ->
        Error
          (Printf.sprintf "%s is not JSON: %s (byte %d)" path error.message
             error.offset)
  with Sys_error error ->
    Error (Printf.sprintf "cannot read %s: %s" path error)

(** The member named [key] of a JSON object, or [None] for a missing member or a
    non-object. *)
let json_member key = function
  | Json_ast.Object members -> List.assoc_opt key members
  | _ -> None

(** The string member named [key], or [None] when it is absent or not a string.
*)
let string_member key json =
  match json_member key json with
  | Some (Json_ast.String text) -> Some text
  | _ -> None

(** The integer denoted by a decimal number string, or [None] when the string
    does not parse, is not finite, or carries a fractional part. *)
let int_of_float_opt raw =
  match float_of_string_opt raw with
  | Some value when Float.is_finite value && Float.floor value = value ->
      Some (int_of_float value)
  | _ -> None

(** The integer member named [key], or [None] when it is absent or not an
    integral number. *)
let int_member key json =
  match json_member key json with
  | Some (Json_ast.Number raw) -> int_of_float_opt raw
  | _ -> None

(** The array member named [key], or [None] when it is absent or not an array.
*)
let array_member key json =
  match json_member key json with
  | Some (Json_ast.Array items) -> Some items
  | _ -> None

(** The pattern a relative path must match: no leading slash and no empty or
    parent-directory segment. *)
let relative_path_pattern =
  "^([^/]|[^/.][^/]+|\\.[^/.][^/]*|\\.\\.[^/]+)(/(|[^/]|[^/.][^/]+|\\.[^/.][^/]*|\\.\\.[^/]+))*$"

(** The pattern a digest must match: exactly 64 lowercase hex digits. *)
let digest_pattern = "^[0-9a-f]{64}$"

(** Whether [text] is a 64-character lowercase hexadecimal digest. *)
let is_valid_digest text =
  String.length text = 64 && Schema.pattern_match digest_pattern text

(** Whether [text] is a non-empty relative path with no empty or
    parent-directory segment. *)
let is_relative_path text =
  String.length text > 0 && Schema.pattern_match relative_path_pattern text

(** Accumulate the ".qnt" files below the directory [root]/[relative] as
    (relative path, full path) pairs in sorted order; an unreadable directory
    contributes nothing. *)
let rec collect_qnt root relative acc =
  let directory =
    if relative = "" then root else Filename.concat root relative
  in
  let names =
    try Array.to_list (Sys.readdir directory) with Sys_error _ -> []
  in
  List.fold_left
    (fun acc name ->
      let rel = if relative = "" then name else relative ^ "/" ^ name in
      let path = Filename.concat root rel in
      if Sys.is_directory path then collect_qnt root rel acc
      else if Filename.check_suffix name ".qnt" then (rel, path) :: acc
      else acc)
    acc
    (List.sort String.compare names)

(** Every ".qnt" entry of the corpus, as (relative path, full path) pairs. *)
let corpus_entries root = collect_qnt root "" []

(** Accumulate the "*.expected.json" fixture paths below [directory], skipping
    the "probes" and "traces" directories; an unreadable directory contributes
    nothing. *)
let rec collect_expected directory acc =
  let names =
    try Array.to_list (Sys.readdir directory) with Sys_error _ -> []
  in
  List.fold_left
    (fun acc name ->
      let path = Filename.concat directory name in
      if Sys.is_directory path then
        if name = "probes" || name = "traces" then acc
        else collect_expected path acc
      else if Filename.check_suffix name ".expected.json" then path :: acc
      else acc)
    acc
    (List.sort String.compare names)

type invariant_status = Derive | Exclude of string

type manifest_row = {
  path : string;
  main : string option;
  invariants : (string * invariant_status) list;
  reason : string option;
  max_steps : int;
  seed : string;
}

(** Parse one manifest invariant entry into its name and derive-or-exclude
    status. Returns [None] when the entry is not an object, lacks a name, or
    carries an unknown status; an exclusion without a reason gets "". *)
let parse_invariant = function
  | Json_ast.Object members -> (
      match
        (List.assoc_opt "name" members, List.assoc_opt "status" members)
      with
      | Some (Json_ast.String name), Some (Json_ast.String "derive") ->
          Some (name, Derive)
      | Some (Json_ast.String name), Some (Json_ast.String "exclude") ->
          let reason =
            match List.assoc_opt "reason" members with
            | Some (Json_ast.String reason) -> reason
            | _ -> ""
          in
          Some (name, Exclude reason)
      | _ -> None)
  | _ -> None

(** Parse one manifest row, taking its path, main, invariants, reason, step
    bound and seed. Returns [None] when a required member is absent or mistyped;
    a non-integral max_steps and a non-string seed become 0 and "". *)
let parse_row = function
  | Json_ast.Object members -> (
      match List.assoc_opt "path" members with
      | Some (Json_ast.String path) -> (
          let main =
            match List.assoc_opt "main" members with
            | Some Json_ast.Null -> Some None
            | Some (Json_ast.String main) -> Some (Some main)
            | _ -> None
          in
          match main with
          | None -> None
          | Some main -> (
              let raw_invariants =
                match List.assoc_opt "invariants" members with
                | Some (Json_ast.Array items) -> Some items
                | _ -> None
              in
              match raw_invariants with
              | None -> None
              | Some items ->
                  let parsed = List.map parse_invariant items in
                  if List.exists Option.is_none parsed then None
                  else
                    let reason =
                      match List.assoc_opt "reason" members with
                      | Some (Json_ast.String reason) -> Some reason
                      | _ -> None
                    in
                    let max_steps =
                      match List.assoc_opt "max_steps" members with
                      | Some (Json_ast.Number raw) ->
                          Option.value (int_of_float_opt raw) ~default:0
                      | _ -> 0
                    in
                    let seed =
                      match List.assoc_opt "seed" members with
                      | Some (Json_ast.String seed) -> seed
                      | _ -> ""
                    in
                    Some
                      {
                        path;
                        main;
                        invariants = List.map Option.get parsed;
                        reason;
                        max_steps;
                        seed;
                      }))
      | _ -> None)
  | _ -> None

(** The (path, main) keys that occur more than once among [rows], in the order
    of their later occurrence. *)
let duplicate_pairs rows =
  let seen = Hashtbl.create 16 in
  let duplicates = ref [] in
  List.iter
    (fun row ->
      let key = (row.path, row.main) in
      if Hashtbl.mem seen key then duplicates := key :: !duplicates
      else Hashtbl.add seen key ())
    rows;
  List.rev !duplicates

(** The first invariant name repeated within [row], or [None] when all names are
    distinct. *)
let duplicate_invariant row =
  let seen = Hashtbl.create 8 in
  List.find_map
    (fun (name, _) ->
      if Hashtbl.mem seen name then Some name
      else begin
        Hashtbl.add seen name ();
        None
      end)
    row.invariants

(** The row's path and main rendered for diagnostic messages, with "none" for an
    absent main. *)
let row_label row =
  Printf.sprintf "%s (main %s)" row.path
    (match row.main with Some main -> main | None -> "none")

(** The file name of [path] without its extension. *)
let stem_of path = Filename.remove_extension (Filename.basename path)

(** The conventional derivation-record path for one row and invariant, named
    after the file stem, the main and the invariant. *)
let record_path records_dir row invariant =
  let main = match row.main with Some main -> main | None -> "none" in
  Filename.concat records_dir
    (Printf.sprintf "%s--%s--%s.json" (stem_of row.path) main invariant)

type record = {
  command : string;
  stdout : string;
  stderr : string;
  exit_code : int;
  spec_sha256 : string;
  imports : (string * string) list;
}

(* A record that fails the schema's required-member set names the member that is
   missing or wrong-typed; the order follows
   derivation-record.schema.json. *)

(** Parse a derivation record and check its required members. Returns [Error]
    naming the member that is missing or wrongly typed, including an import
    digest that is not a string. *)
let parse_record json =
  match json with
  | Json_ast.Object members -> (
      try
        let text key =
          match List.assoc_opt key members with
          | Some (Json_ast.String text) -> text
          | Some other ->
              raise
                (Invalid_argument
                   (Printf.sprintf "the %s member is not a JSON string (got %s)"
                      key (Json_ast.type_name other)))
          | None ->
              raise
                (Invalid_argument
                   (Printf.sprintf "the %s member is missing" key))
        in
        let command = text "command" in
        let stdout = text "stdout" in
        let stderr = text "stderr" in
        let spec_sha256 = text "spec_sha256" in
        let exit_code =
          match int_member "exit_code" json with
          | Some code -> code
          | None -> (
              match List.assoc_opt "exit_code" members with
              | Some other ->
                  raise
                    (Invalid_argument
                       (Printf.sprintf
                          "the exit_code member is not a JSON integer (got %s)"
                          (Json_ast.type_name other)))
              | None ->
                  raise (Invalid_argument "the exit_code member is missing"))
        in
        let imports =
          match List.assoc_opt "imports" members with
          | Some (Json_ast.Object imports) -> imports
          | Some other ->
              raise
                (Invalid_argument
                   (Printf.sprintf
                      "the imports member is not a JSON object (got %s)"
                      (Json_ast.type_name other)))
          | None -> raise (Invalid_argument "the imports member is missing")
        in
        match
          List.find_map
            (fun (path, digest) ->
              match digest with
              | Json_ast.String _ -> None
              | other ->
                  Some
                    (Printf.sprintf
                       "the import digest for %s is not a JSON string (got %s)"
                       path (Json_ast.type_name other)))
            imports
        with
        | Some message -> Error message
        | None ->
            let imports =
              List.filter_map
                (fun (path, digest) ->
                  match digest with
                  | Json_ast.String digest -> Some (path, digest)
                  | _ -> None)
                imports
            in
            Ok { command; stdout; stderr; exit_code; spec_sha256; imports }
      with Invalid_argument message -> Error message)
  | _ -> Error "is not a derivation record"

(** Split a recorded command line into tokens on blanks, honouring single and
    double quotes. *)
let command_tokens command =
  let buf = Buffer.create 32 in
  let tokens = ref [] in
  let flush () =
    if Buffer.length buf > 0 then begin
      tokens := Buffer.contents buf :: !tokens;
      Buffer.clear buf
    end
  in
  let quote = ref None in
  String.iter
    (fun c ->
      match !quote with
      | Some q -> if c = q then quote := None else Buffer.add_char buf c
      | None ->
          if c = '\'' || c = '"' then quote := Some c
          else if c = ' ' || c = '\t' then flush ()
          else Buffer.add_char buf c)
    command;
  flush ();
  List.rev !tokens

(** Whether the token starts with a hyphen and so reads as a flag. *)
let is_flag token = String.length token > 0 && token.[0] = '-'

(** The spec path a recorded command names: the first non-flag token after
    "run", else the first non-flag token after the program name. An empty token
    list raises [Failure]. *)
let spec_in_tokens tokens =
  let rec after_run = function
    | [] -> None
    | "run" :: rest -> List.find_opt (fun token -> not (is_flag token)) rest
    | _ :: rest -> after_run rest
  in
  match after_run tokens with
  | Some spec -> Some spec
  | None -> List.find_opt (fun token -> not (is_flag token)) (List.tl tokens)

(** The text following [prefix] in the first token that carries it, or [None]
    when no token does. *)
let token_value prefix tokens =
  List.find_map
    (fun token ->
      let plen = String.length prefix in
      if String.length token > plen && String.sub token 0 plen = prefix then
        Some (String.sub token plen (String.length token - plen))
      else None)
    tokens

(** The first diagnostic code made of "QNT" plus three digits in [text], or
    [None] when none occurs. *)
let qnt_code text =
  let length = String.length text in
  let digit c = c >= '0' && c <= '9' in
  let rec find index =
    if index + 6 > length then None
    else if
      String.sub text index 3 = "QNT"
      && digit text.[index + 3]
      && digit text.[index + 4]
      && digit text.[index + 5]
    then Some (String.sub text index 6)
    else find (index + 1)
  in
  find 0

type outcome = Success_ok | Success_violation | Runtime_error

(** Classify a derivation record from its output markers: a success, a
    violation, or the error marker with a QNT code on standard error. Returns
    [Error] when the markers are absent, contradictory or unpaired. *)
let classify_record record =
  let ok = contains_sub record.stdout "[ok] No violation found" in
  let violation = contains_sub record.stdout "[violation] Found an issue" in
  let marker = contains_sub record.stdout "[error] Runtime error" in
  let code = qnt_code record.stderr in
  if ok && violation then Error "the record carries both success forms"
  else if ok && (marker || code <> None) then
    Error "the record is classified as both success and error"
  else if violation && (marker || code <> None) then
    Error "the record is classified as both success and error"
  else if ok then Ok Success_ok
  else if violation then Ok Success_violation
  else if marker && code <> None then Ok Runtime_error
  else if marker then
    Error
      "the record carries the stdout error marker and no QNT diagnostic on \
       stderr"
  else if code <> None then
    Error
      "the record carries a QNT diagnostic on stderr and no stdout error marker"
  else Error "the record carries no recognised outcome"

(** Index the derivation records in [records_dir] by (spec, main, invariant).
    Returns the index and the problems found: unreadable or malformed files, bad
    digests, and commands naming no spec, main or invariant. *)
let record_index records_dir =
  let names =
    try Array.to_list (Sys.readdir records_dir) with Sys_error _ -> []
  in
  let index = Hashtbl.create 64 in
  let errors = ref [] in
  List.iter
    (fun name ->
      if Filename.check_suffix name ".json" then begin
        let path = Filename.concat records_dir name in
        match load_json path with
        | Error message -> errors := message :: !errors
        | Ok json -> (
            match parse_record json with
            | Error message ->
                errors :=
                  (if message = "is not a derivation record" then
                     path ^ " " ^ message
                   else path ^ ": " ^ message)
                  :: !errors
            | Ok record -> (
                let tokens = command_tokens record.command in
                let main = token_value "--main=" tokens in
                let invariant = token_value "--invariant=" tokens in
                let spec = spec_in_tokens tokens in
                match (spec, main, invariant) with
                | Some spec, Some main, Some invariant ->
                    if is_valid_digest record.spec_sha256 then begin
                      let key = (spec, main, invariant) in
                      let previous = Hashtbl.find_opt index key in
                      Hashtbl.replace index key
                        (match previous with
                        | Some existing -> existing @ [ (path, record) ]
                        | None -> [ (path, record) ])
                    end
                    else
                      errors :=
                        (path ^ ": spec_sha256 is not a 64-hex digest")
                        :: !errors
                | _ ->
                    errors :=
                      (path
                     ^ ": the command does not name a spec path, --main and \
                        --invariant")
                      :: !errors))
      end)
    (List.sort String.compare names);
  (index, List.rev !errors)

(** The lowercase hexadecimal sha256 digest of the file at [path]. *)
let sha256_of path = Sha256.hex (read_file path)

(** Check every import of [record] against the corpus under [corpus_root]:
    relative path, 64-hex digest, file present, digest matching. Returns the
    failure messages, empty when all agree. *)
let verify_digests ~corpus_root record =
  let failures = ref [] in
  let fail message = failures := message :: !failures in
  if not (is_valid_digest record.spec_sha256) then
    fail "the spec-file digest is not a 64-hex digest";
  List.iter
    (fun (path, digest) ->
      if not (is_relative_path path) then
        fail
          (Printf.sprintf "the recorded import path %S escapes the tree" path)
      else if not (is_valid_digest digest) then
        fail (Printf.sprintf "the digest for %s is not a 64-hex digest" path)
      else begin
        let full = Filename.concat corpus_root path in
        if not (Sys.file_exists full) then
          fail (Printf.sprintf "the recorded import %s is absent" path)
        else
          let observed = try sha256_of full with Sys_error _ -> "" in
          if observed <> digest then
            fail
              (Printf.sprintf "the digest of %s is %s, recorded %s" path
                 observed digest)
      end)
    record.imports;
  List.rev !failures

(** Run the checker with [argv] from [cwd] and capture its separated output,
    restoring the working directory afterwards. A directory that cannot be
    entered yields a capture carrying the "cannot change directory" error. *)
let run_checker ~cwd ~timeout argv =
  let before = Sys.getcwd () in
  let restore () = try Sys.chdir before with Sys_error _ -> () in
  try
    Sys.chdir cwd;
    let capture = Proc.run_split ~timeout (Array.of_list argv) in
    restore ();
    capture
  with Sys_error _ ->
    restore ();
    {
      Proc.split_status = None;
      split_stdout = "";
      split_stderr = "";
      split_timed_out = false;
      split_spawn_error = Some "cannot change directory";
    }

(** The path of the running executable, made absolute against the working
    directory when it was given relatively. *)
let executable_path () =
  if Filename.is_relative Sys.executable_name then
    Filename.concat (Sys.getcwd ()) Sys.executable_name
  else Sys.executable_name

(** The checker command line for one triple, with the per-call and deadline
    timeouts clamped to the remaining budget and at least one second, plus the
    evaluator argument when the configuration names one. *)
let checker_argv config ~remaining ~spec ~trace ~main ~invariant =
  let clamp seconds = max 1 (min seconds (int_of_float (ceil remaining))) in
  let binary = executable_path () in
  let argv =
    [
      binary;
      spec;
      trace;
      "--main=" ^ main;
      "--invariant=" ^ invariant;
      "--strict-source";
      "--format=json";
      Printf.sprintf "--timeout=%d" (clamp config.timeout);
      Printf.sprintf "--deadline=%d" (clamp config.deadline);
      "--quint=" ^ config.quint;
    ]
  in
  match config.evaluator with
  | Some evaluator -> argv @ [ "--evaluator=" ^ evaluator ]
  | None -> argv

type triple = {
  entry : manifest_row;
  invariant : string;
  recorded : outcome;
  trace_path : string;
  trace_states : int;
}

(** The comparable projection of a checker report: its exit, invariants and
    summary fields, the trace members, and the trace digest when recorded.
    Returns [None] when the report carries no trace object. *)
let projection_of_report document =
  match json_member "trace" document with
  | Some (Json_ast.Object trace_members) ->
      let base =
        List.filter
          (fun (key, _) ->
            key = "exit" || key = "invariants" || key = "summary")
          (match document with Json_ast.Object members -> members | _ -> [])
      in
      let sha =
        match List.assoc_opt "sha256" trace_members with
        | Some sha -> [ ("trace_sha256", sha) ]
        | None -> []
      in
      Some (Json_ast.Object (base @ trace_members @ sha))
  | _ -> None

(** Compare a report projection against the expected one, field by field and row
    by row. Returns the differences found, empty when the two agree. *)
let compare_projection ~expected ~actual =
  let failures = ref [] in
  let fail message = failures := message :: !failures in
  (match (expected, actual) with
  | Json_ast.Object expected_members, Json_ast.Object actual_members ->
      List.iter
        (fun (key, expected_value) ->
          match List.assoc_opt key actual_members with
          | None -> fail ("the report is missing " ^ key)
          | Some actual_value ->
              if key = "invariants" then
                begin match (expected_value, actual_value) with
                | Json_ast.Array expected_rows, Json_ast.Array actual_rows ->
                    if List.length expected_rows <> List.length actual_rows then
                      fail
                        (Printf.sprintf
                           "the report carries %d rows, expected %d"
                           (List.length actual_rows)
                           (List.length expected_rows))
                    else
                      List.iter2
                        (fun expected_row actual_row ->
                          match (expected_row, actual_row) with
                          | ( Json_ast.Object expected_fields,
                              Json_ast.Object actual_fields ) ->
                              List.iter
                                (fun (field, expected_field) ->
                                  match List.assoc_opt field actual_fields with
                                  | None -> fail ("a row is missing " ^ field)
                                  | Some actual_field ->
                                      if
                                        not
                                          (Json_ast.equal expected_field
                                             actual_field)
                                      then
                                        fail
                                          (Printf.sprintf
                                             "row %s field %s differs"
                                             (match
                                                List.assoc_opt "name"
                                                  expected_fields
                                              with
                                             | Some (Json_ast.String name) ->
                                                 name
                                             | _ -> "?")
                                             field))
                                expected_fields
                          | _ -> fail "a row is not an object")
                        expected_rows actual_rows
                | _ -> fail "the invariants field is not an array"
                end
              else if not (Json_ast.equal expected_value actual_value) then
                fail ("the report field " ^ key ^ " differs"))
        expected_members
  | _ -> fail "the report is not an object");
  List.rev !failures

(** The report row whose name is [name], or [None] when no row carries it. *)
let invariant_row document name =
  match array_member "invariants" document with
  | Some rows ->
      List.find_opt
        (fun row ->
          match string_member "name" row with
          | Some row_name -> row_name = name
          | None -> false)
        rows
  | None -> None

(** The text of a JSON string, or the empty string for any other value. *)
let string_of_json = function Json_ast.String text -> text | _ -> ""

(** Run one hand-verified fixture and compare its exit code and outcome with the
    expectation file, checking the refusal stage and diagnostic text for exit 2,
    or the report projection otherwise. [Error] details a mismatch. *)
let run_fixture ~directory ~timeout expected_path =
  match load_json expected_path with
  | Error message -> Error message
  | Ok expected -> (
      match json_member "invocation" expected with
      | None -> Error (expected_path ^ " carries no invocation")
      | Some invocation -> (
          match array_member "args" invocation with
          | None -> Error (expected_path ^ ": the invocation carries no args")
          | Some args -> (
              let args = List.map string_of_json args in
              let expected_exit =
                match int_member "expected_exit" expected with
                | Some value -> value
                | None -> -1
              in
              let argv =
                executable_path ()
                ::
                (if expected_exit = 2 then args else args @ [ "--format=json" ])
              in
              let capture = run_checker ~cwd:directory ~timeout argv in
              if capture.Proc.split_timed_out then
                Error (expected_path ^ ": timed out")
              else
                match capture.Proc.split_status with
                | Some exit_code when exit_code = expected_exit -> (
                    if expected_exit = 2 then begin
                      let stage =
                        match string_member "expected_stage" expected with
                        | Some stage -> stage
                        | None -> ""
                      in
                      let prefix = stage ^ ": " in
                      let diagnostic = capture.split_stderr in
                      let stage_ok =
                        String.length diagnostic >= String.length prefix
                        && String.sub diagnostic 0 (String.length prefix)
                           = prefix
                      in
                      let tokens =
                        match json_member "expected_diagnostic" expected with
                        | Some fields -> (
                            match array_member "must_contain" fields with
                            | Some tokens -> List.map string_of_json tokens
                            | None -> [])
                        | None -> []
                      in
                      let missing =
                        List.filter
                          (fun token -> not (contains_sub diagnostic token))
                          tokens
                      in
                      if stage_ok && missing = [] then Ok ()
                      else
                        Error
                          (Printf.sprintf "%s: stage=%b missing=%s"
                             expected_path stage_ok
                             (String.concat "," missing))
                    end
                    else
                      match Json_parse.parse capture.split_stdout with
                      | Error error ->
                          Error
                            (Printf.sprintf "%s: the report is not JSON: %s"
                               expected_path error.message)
                      | Ok document -> (
                          match json_member "expected_report" expected with
                          | None ->
                              Error
                                (expected_path ^ " carries no expected_report")
                          | Some expected_report -> (
                              match projection_of_report document with
                              | None ->
                                  Error
                                    (expected_path
                                   ^ ": the report carries no trace")
                              | Some actual ->
                                  let failures =
                                    compare_projection ~expected:expected_report
                                      ~actual
                                  in
                                  let silent =
                                    match
                                      array_member "expected_silent" expected
                                    with
                                    | Some names ->
                                        List.map string_of_json names
                                    | None -> []
                                  in
                                  let unexpected_silent =
                                    List.filter
                                      (fun name ->
                                        invariant_row document name <> None)
                                      silent
                                    |> List.map (fun name ->
                                        "row " ^ name ^ " was expected silent")
                                  in
                                  let missing_rows =
                                    match
                                      array_member "invariants" expected_report
                                    with
                                    | Some rows ->
                                        List.filter_map
                                          (fun row ->
                                            match string_member "name" row with
                                            | Some name
                                              when invariant_row document name
                                                   = None ->
                                                Some
                                                  ("row " ^ name ^ " is absent")
                                            | _ -> None)
                                          rows
                                    | None -> []
                                  in
                                  let failures =
                                    failures @ unexpected_silent @ missing_rows
                                  in
                                  if failures = [] then Ok ()
                                  else
                                    Error
                                      (Printf.sprintf "%s: %s" expected_path
                                         (String.concat "; " failures)))))
                | Some exit_code ->
                    Error
                      (Printf.sprintf "%s: exit %d, expected %d" expected_path
                         exit_code expected_exit)
                | None ->
                    Error
                      (Printf.sprintf "%s: %s" expected_path
                         (Option.value capture.Proc.split_spawn_error
                            ~default:"no exit status")))))

(** Validate the manifest against the corpus: relative paths, present files,
    distinct invariants, a reason on every exclusion, unique rows, and a row for
    every corpus entry. Returns rows and entries, or raises [Refusal]. *)
let validate_manifest_corpus ~corpus_root manifest_path =
  let rows =
    match load_json manifest_path with
    | Error message -> refuse "resolve" "%s" message
    | Ok (Json_ast.Array rows) -> rows
    | Ok _ -> refuse "resolve" "the manifest is not an array of rows"
  in
  if rows = [] then refuse "resolve" "the manifest carries no rows";
  let parsed = List.map parse_row rows in
  if List.exists Option.is_none parsed then
    refuse "resolve" "a manifest row is malformed";
  let rows = List.map Option.get parsed in
  List.iter
    (fun row ->
      if not (is_relative_path row.path) then
        refuse "resolve"
          "the manifest row %s carries a path that is absolute or contains a \
           parent-directory segment"
          (row_label row);
      let full = Filename.concat corpus_root row.path in
      if not (Sys.file_exists full) then
        refuse "resolve"
          "the manifest row %s names a file absent from the corpus"
          (row_label row);
      (match duplicate_invariant row with
      | Some name ->
          refuse "resolve" "the manifest row %s repeats the invariant %s"
            (row_label row) name
      | None -> ());
      if row.main <> None && row.invariants = [] && row.reason = None then
        refuse "resolve"
          "the manifest row %s carries no invariant and no reason"
          (row_label row);
      List.iter
        (fun (name, status) ->
          match status with
          | Exclude reason when reason = "" ->
              refuse "resolve"
                "the manifest row %s excludes %s without a recorded reason"
                (row_label row) name
          | _ -> ())
        row.invariants)
    rows;
  (match duplicate_pairs rows with
  | (path, main) :: _ ->
      refuse "resolve" "the manifest carries two rows for %s (main %s)" path
        (match main with Some main -> main | None -> "none")
  | [] -> ());
  let entries = corpus_entries corpus_root in
  let covered = Hashtbl.create 32 in
  List.iter (fun row -> Hashtbl.replace covered row.path ()) rows;
  List.iter
    (fun (relative, _) ->
      if not (Hashtbl.mem covered relative) then
        refuse "resolve" "the corpus entry %s has no manifest row" relative)
    entries;
  (rows, entries)

(** Validate the derivation records beside the manifest and build the admitted
    triples: each must classify, agree on exit code, digests and main, and carry
    a trace with states. Returns the triples or raises [Refusal]. *)
let validate_registry ~corpus_root ~manifest_dir rows =
  let records_dir = Filename.concat manifest_dir "records" in
  if not (Sys.file_exists records_dir) then
    refuse "resolve"
      "the registry carries no records directory beside the manifest";
  let index, index_errors = record_index records_dir in
  (match index_errors with
  | first :: _ -> refuse "resolve" "%s" first
  | [] -> ());
  (* A record whose command names a row's main but an invariant absent from
     that row's entries is an inventory failure. *)
  Hashtbl.iter
    (fun (path, main, invariant) _ ->
      match
        List.find_opt (fun row -> row.path = path && row.main = Some main) rows
      with
      | Some row
        when not
               (List.exists (fun (name, _) -> name = invariant) row.invariants)
        ->
          refuse "resolve"
            "the derivation record for %s (main %s) names %s, which is absent \
             from that row's manifest entries"
            path main invariant
      | _ -> ())
    index;
  let triples = ref [] in
  List.iter
    (fun row ->
      List.iter
        (fun (invariant, status) ->
          match
            Hashtbl.find_opt index
              (row.path, Option.value row.main ~default:"", invariant)
          with
          | None ->
              (* A record offered for this triple under the file-name convention
               but carrying another path or main is an unrecorded inventory
               mismatch, not an absent record. *)
              let conventional = record_path records_dir row invariant in
              if Sys.file_exists conventional then
                match load_json conventional with
                | Ok json -> (
                    match parse_record json with
                    | Ok record ->
                        let tokens = command_tokens record.command in
                        let recorded_main = token_value "--main=" tokens in
                        let recorded_spec = spec_in_tokens tokens in
                        refuse "resolve"
                          "the derivation record offered for %s invariant %s \
                           names path %s and --main=%s"
                          (row_label row) invariant
                          (Option.value recorded_spec ~default:"none")
                          (Option.value recorded_main ~default:"none")
                    | Error message ->
                        refuse "resolve" "%s: %s" conventional message)
                | Error message -> refuse "resolve" "%s" message
              else
                refuse "resolve"
                  "the manifest invariant %s of %s has no derivation record"
                  invariant (row_label row)
          | Some [] -> assert false
          | Some [ (_, record) ] -> (
              let classified =
                match classify_record record with
                | Ok outcome -> outcome
                | Error message ->
                    refuse "resolve"
                      "the derivation record for %s invariant %s: %s"
                      (row_label row) invariant message
              in
              let expected_exit =
                match classified with
                | Success_ok -> 0
                | Success_violation | Runtime_error -> 1
              in
              if record.exit_code <> expected_exit then
                refuse "resolve"
                  "the derivation record for %s invariant %s carries exit code \
                   %d, which does not agree with the recorded outcome"
                  (row_label row) invariant record.exit_code;
              (match (status, classified) with
              | Derive, Runtime_error ->
                  refuse "resolve"
                    "the manifest says derive for %s invariant %s, but the \
                     record is a runtime error"
                    (row_label row) invariant
              | Exclude _, (Success_ok | Success_violation) ->
                  refuse "resolve"
                    "the manifest excludes %s invariant %s, but the record \
                     records a success"
                    (row_label row) invariant
              | _ -> ());
              let digest_failures = verify_digests ~corpus_root record in
              (match digest_failures with
              | first :: _ ->
                  refuse "resolve" "%s invariant %s: %s" (row_label row)
                    invariant first
              | [] -> ());
              let spec_path = Filename.concat corpus_root row.path in
              let observed = try sha256_of spec_path with Sys_error _ -> "" in
              if observed <> record.spec_sha256 then
                refuse "resolve"
                  "%s invariant %s: the spec-file digest is %s, recorded %s"
                  (row_label row) invariant observed record.spec_sha256;
              let tokens = command_tokens record.command in
              let recorded_main = token_value "--main=" tokens in
              if recorded_main <> row.main then
                refuse "resolve"
                  "the derivation record for %s invariant %s names --main=%s, \
                   which differs from the row's main"
                  (row_label row) invariant
                  (Option.value recorded_main ~default:"none");
              let out_itf =
                match token_value "--out-itf=" tokens with
                | Some path -> path
                | None ->
                    refuse "resolve"
                      "the derivation record for %s invariant %s names no \
                       --out-itf trace"
                      (row_label row) invariant
              in
              let trace_path =
                if Filename.is_relative out_itf then
                  Filename.concat manifest_dir out_itf
                else out_itf
              in
              if not (Sys.file_exists trace_path) then
                refuse "resolve" "the trace %s for %s invariant %s is absent"
                  out_itf (row_label row) invariant;
              let trace =
                match load_json trace_path with
                | Ok trace -> trace
                | Error message ->
                    refuse "resolve" "%s invariant %s: %s" (row_label row)
                      invariant message
              in
              let source =
                match json_member "#meta" trace with
                | Some meta -> string_member "source" meta
                | None -> None
              in
              (match source with
              | Some source when source = row.path -> ()
              | Some source ->
                  refuse "resolve"
                    "%s invariant %s: the trace records source %s, the replay \
                     spelling is %s"
                    (row_label row) invariant source row.path
              | None ->
                  refuse "resolve"
                    "%s invariant %s: the trace records no #meta.source; the \
                     replay spelling is %s"
                    (row_label row) invariant row.path);
              let states =
                match array_member "states" trace with
                | Some states -> List.length states
                | None -> 0
              in
              if states = 0 then
                refuse "resolve"
                  "the trace for %s invariant %s carries no states"
                  (row_label row) invariant;
              match (status, classified) with
              | Derive, (Success_ok | Success_violation) ->
                  triples :=
                    {
                      entry = row;
                      invariant;
                      recorded = classified;
                      trace_path;
                      trace_states = states;
                    }
                    :: !triples
              | _ -> ())
          | Some _ ->
              refuse "resolve"
                "the manifest invariant %s of %s has more than one derivation \
                 record"
                invariant (row_label row))
        row.invariants)
    rows;
  List.rev !triples

(** Validate the hand-verified inventory: it must exist, carry at least six
    fixtures, and cover every required category. Returns the fixture paths;
    raises [Refusal] with stage "resolve" on any violation. *)
let validate_inventory fixtures_dir =
  if not (Sys.file_exists fixtures_dir) then
    refuse "resolve" "the hand-verified inventory %s is absent" fixtures_dir;
  let expected = collect_expected fixtures_dir [] in
  if expected = [] then
    refuse "resolve" "the hand-verified inventory %s carries no fixture"
      fixtures_dir;
  if List.length expected < 6 then
    refuse "resolve"
      "the hand-verified inventory carries %d fixtures, fewer than the six \
       required"
      (List.length expected);
  let categories = Hashtbl.create 8 in
  List.iter
    (fun path ->
      match load_json path with
      | Error message -> refuse "resolve" "%s" message
      | Ok json -> (
          match string_member "category" json with
          | Some category -> Hashtbl.replace categories category ()
          | None -> refuse "resolve" "the fixture %s carries no category" path))
    expected;
  let required =
    [
      "pass";
      "violation";
      "initial-state-violation";
      "evaluation-error";
      "multi-invariant-precedence";
      "big-integer";
    ]
  in
  List.iter
    (fun category ->
      if not (Hashtbl.mem categories category) then
        refuse "resolve" "the hand-verified inventory lacks the %s category"
          category)
    required;
  expected

(** Replay one triple and decide whether the checker agrees with the recorded
    outcome, printing a disagreement line to standard error when it does not.
    Raises [Refusal] with stage "gate" when the deadline expires. *)
let verify_triple config ~remaining triple =
  if remaining () <= 0.0 then
    raise (Refusal ("gate", "the gate deadline expired"));
  let argv =
    checker_argv config ~remaining:(remaining ()) ~spec:triple.entry.path
      ~trace:triple.trace_path
      ~main:(Option.value triple.entry.main ~default:"")
      ~invariant:triple.invariant
  in
  let capture =
    run_checker ~cwd:config.corpus_root ~timeout:(remaining ()) argv
  in
  (* An abandoned in-flight call issues no disagreement verdict: the gate
     deadline is reported instead. *)
  if remaining () <= 0.0 then
    raise (Refusal ("gate", "the gate deadline expired during replay"));
  let ok =
    if capture.Proc.split_timed_out then false
    else
      match capture.Proc.split_status with
      | Some 2 -> false
      | Some exit_code -> (
          match Json_parse.parse capture.split_stdout with
          | Error _ -> false
          | Ok document -> (
              match invariant_row document triple.invariant with
              | None -> false
              | Some row -> (
                  match (triple.recorded, exit_code) with
                  | Success_ok, 0 -> string_member "verdict" row = Some "pass"
                  | Success_violation, 1 -> (
                      match
                        (string_member "verdict" row, int_member "state" row)
                      with
                      | Some "fail", Some index ->
                          index = triple.trace_states - 1
                      | _ -> false)
                  | _ -> false)))
      | None -> false
  in
  if not ok then
    Printf.eprintf
      "triple disagreement: %s invariant %s (checker status %s): %s\n"
      triple.entry.path triple.invariant
      (match capture.Proc.split_status with
      | Some code -> string_of_int code
      | None -> "none")
      (String.trim capture.split_stdout);
  ok

(** Run the whole gate and return the process exit code: 0 when every triple and
    fixture agrees, 1 on any disagreement, and 2 on a refusal or a system error.
    The counts line and the end marker are printed on every path. *)
let run config =
  let absolute path =
    if Filename.is_relative path then Filename.concat (Sys.getcwd ()) path
    else path
  in
  let config =
    {
      config with
      corpus_root = absolute config.corpus_root;
      manifest = absolute config.manifest;
      fixtures = absolute config.fixtures;
    }
  in
  let started = Unix.gettimeofday () in
  let deadline_at = started +. float_of_int config.gate_deadline in
  let remaining () = deadline_at -. Unix.gettimeofday () in
  let entries = corpus_entries config.corpus_root in
  let counts = zeros (List.length entries) in
  let print_counts () = print_endline (count_line counts) in
  let finish exit_code message =
    (match message with
    | Some (stage, message) -> Printf.eprintf "%s: %s\n" stage message
    | None -> ());
    print_counts ();
    print_endline end_marker;
    exit_code
  in
  try
    if remaining () <= 0.0 then
      raise (Refusal ("gate", "the gate deadline expired during validation"));
    (match
       Quint.version ~quint:config.quint
         ~timeout:(Float.min 30.0 (remaining ()))
         ()
     with
    | Ok () -> ()
    | Error failure ->
        raise (Refusal (failure.Failure.stage, failure.Failure.message)));
    (match Evaluator.resolve ?evaluator:config.evaluator () with
    | Ok resolved -> ignore resolved
    | Error failure ->
        raise (Refusal (failure.Failure.stage, failure.Failure.message)));
    if remaining () <= 0.0 then
      raise (Refusal ("gate", "the gate deadline expired during validation"));
    let rows, _ =
      validate_manifest_corpus ~corpus_root:config.corpus_root config.manifest
    in
    let manifest_dir = Filename.dirname config.manifest in
    let fixtures = validate_inventory config.fixtures in
    if remaining () <= 0.0 then
      raise (Refusal ("gate", "the gate deadline expired during validation"));
    let triples =
      validate_registry ~corpus_root:config.corpus_root ~manifest_dir rows
    in
    if remaining () <= 0.0 then
      raise
        (Refusal ("gate", "the gate deadline expired during classification"));
    counts.triples <- List.length triples;
    counts.runnable <-
      List.length
        (List.filter
           (fun row -> List.exists (fun triple -> triple.entry == row) triples)
           rows);
    counts.excluded <- List.length rows - counts.runnable;
    if counts.triples = 0 then
      raise
        (Refusal
           ( "resolve",
             "no admitted triple: a gate that admits nothing is a could-not-run"
           ));
    (* Replay the admitted triples. *)
    List.iter
      (fun triple ->
        if remaining () <= 0.0 then
          raise (Refusal ("gate", "the gate deadline expired during replay"));
        let ok = verify_triple config ~remaining triple in
        if remaining () <= 0.0 then
          raise (Refusal ("gate", "the gate deadline expired during replay"));
        if ok then counts.agree <- counts.agree + 1
        else counts.disagree <- counts.disagree + 1)
      triples;
    (* Evaluate the hand-verified fixtures last. *)
    List.iter
      (fun expected_path ->
        if remaining () <= 0.0 then
          raise
            (Refusal ("gate", "the gate deadline expired during the fixtures"));
        let result =
          run_fixture
            ~directory:(Filename.dirname expected_path)
            ~timeout:(Float.min 60.0 (remaining ()))
            expected_path
        in
        if remaining () <= 0.0 then
          raise
            (Refusal ("gate", "the gate deadline expired during the fixtures"));
        (match result with
        | Ok () -> ()
        | Error message ->
            counts.fixtures_disagree <- counts.fixtures_disagree + 1;
            Printf.eprintf "fixture disagreement: %s\n" message);
        counts.fixtures <- counts.fixtures + 1)
      fixtures;
    if counts.disagree > 0 || counts.fixtures_disagree > 0 then finish 1 None
    else finish 0 None
  with
  | Refusal (stage, message) -> finish 2 (Some (stage, message))
  | Sys_error message -> finish 2 (Some ("internal", message))
