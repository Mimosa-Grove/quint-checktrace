(* Corpus-driven acceptance checks for the decoder, metadata extraction and
   the schema validator. The fixture corpus is the reference. Licence:
   AGPL-3.0-or-later; see README.md. *)

let read_file path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let data = really_input_string ic n in
  close_in ic;
  data

let first_existing candidates =
  match List.find_opt Sys.file_exists candidates with
  | Some path -> path
  | None ->
      failwith ("none of these paths exists: " ^ String.concat ", " candidates)

let fixtures_dir () =
  first_existing [ "fixtures"; "../fixtures"; "../../fixtures" ]

let repo_file name = first_existing [ name; "../" ^ name; "../../" ^ name ]

let jstr = function
  | Json_ast.String s -> s
  | _ -> failwith "expected a JSON string"

let jint = function
  | Json_ast.Number raw -> int_of_float (float_of_string raw)
  | _ -> failwith "expected a JSON integer"

let jarray = function
  | Json_ast.Array xs -> xs
  | _ -> failwith "expected a JSON array"

let jobj = function
  | Json_ast.Object members -> members
  | _ -> failwith "expected a JSON object"

let jopt members key = List.assoc_opt key members

let jstrings = function
  | Json_ast.Array xs -> List.map jstr xs
  | _ -> failwith "expected a JSON string array"

let load_json path =
  match Json_parse.parse (read_file path) with
  | Ok value -> value
  | Error error ->
      failwith
        (Printf.sprintf "%s: JSON error at byte %d: %s" path error.offset
           error.message)

let contains_sub haystack needle =
  let n = String.length needle in
  let h = String.length haystack in
  let rec loop i =
    if i + n > h then false
    else if String.sub haystack i n = needle then true
    else loop (i + 1)
  in
  n = 0 || loop 0

let find_sub haystack needle =
  let n = String.length needle in
  let h = String.length haystack in
  let rec loop i =
    if i + n > h then None
    else if String.sub haystack i n = needle then Some i
    else loop (i + 1)
  in
  loop 0

let expected_class requirement =
  match find_sub requirement "class " with
  | None -> None
  | Some at ->
      let start = at + String.length "class " in
      let stop = ref start in
      while
        !stop < String.length requirement
        && requirement.[!stop] >= '0'
        && requirement.[!stop] <= '9'
      do
        incr stop
      done;
      if !stop = start then None
      else Some (int_of_string (String.sub requirement start (!stop - start)))

let rec collect_expected dir acc =
  Sys.readdir dir |> Array.to_list |> List.sort String.compare
  |> List.fold_left
       (fun acc name ->
         let path = Filename.concat dir name in
         if Sys.is_directory path then
           if name = "probes" || name = "traces" then acc
           else collect_expected path acc
         else if Filename.check_suffix name ".expected.json" then path :: acc
         else acc)
       acc

let invocation_args expected =
  match jopt expected "invocation" with
  | Some invocation ->
      jarray (List.assoc "args" (jobj invocation)) |> List.map jstr
  | None -> (
      match jopt expected "invocations" with
      | Some (Json_ast.Array (first :: _)) ->
          jarray (List.assoc "args" (jobj first)) |> List.map jstr
      | _ -> [])

let find_main args =
  List.find_map
    (fun arg ->
      let prefix = "--main=" in
      let plen = String.length prefix in
      if String.length arg > plen && String.sub arg 0 plen = prefix then
        Some (String.sub arg plen (String.length arg - plen))
      else None)
    args

let find_arg suffix args =
  List.find_opt (fun arg -> Filename.check_suffix arg suffix) args

let find_invariants args =
  let pref = "--invariant=" in
  let plen = String.length pref in
  let rec names = function
    | arg :: rest when String.length arg > 0 && arg.[0] <> '-' ->
        let picked, rest = names rest in
        (arg :: picked, rest)
    | rest -> ([], rest)
  in
  let rec loop acc = function
    | [] -> List.rev acc
    | arg :: rest ->
        if String.length arg > plen && String.sub arg 0 plen = pref then
          loop (String.sub arg plen (String.length arg - plen) :: acc) rest
        else if arg = "--invariants" then
          let picked, rest = names rest in
          loop (List.rev_append picked acc) rest
        else loop acc rest
  in
  loop [] args

let ir_cache : (string, Json_ast.t option) Hashtbl.t = Hashtbl.create 32

let run_quint_parse spec out =
  let argv = [| "quint"; "parse"; "--out"; out; spec |] in
  let devnull = Unix.openfile "/dev/null" [ Unix.O_WRONLY ] 0 in
  let pid =
    try Unix.create_process "quint" argv Unix.stdin devnull devnull
    with Unix.Unix_error (error, _, _) ->
      Unix.close devnull;
      failwith
        (Printf.sprintf "cannot run quint: %s" (Unix.error_message error))
  in
  let _, status = Unix.waitpid [] pid in
  Unix.close devnull;
  match status with Unix.WEXITED 0 -> true | _ -> false

let ir_for spec_path =
  match Hashtbl.find_opt ir_cache spec_path with
  | Some ir -> ir
  | None ->
      let out = Filename.temp_file "quint-checktrace-ir" ".json" in
      let ok = run_quint_parse spec_path out in
      let ir =
        if not ok then None
        else
          match Json_parse.parse (read_file out) with
          | Ok ir -> Some ir
          | Error _ -> None
      in
      if Sys.file_exists out then Sys.remove out;
      Hashtbl.add ir_cache spec_path ir;
      ir

let expected_source report =
  match jopt report "source" with
  | Some Json_ast.Null | None -> None
  | Some value -> Some (jstr value)

let expected_status report =
  match jopt report "status" with
  | Some Json_ast.Null | None -> None
  | Some value -> Some (jstr value)

let expected_loop report =
  match jopt report "loop" with
  | Some Json_ast.Null | None -> None
  | Some value -> Some (jint value)

let expected_type_field report key =
  match jopt report key with Some value -> Some (jstr value) | None -> None

let check_metadata report (trace : Decoder.trace) =
  let errors = ref [] in
  let check name expected actual =
    if expected <> actual then
      errors :=
        Printf.sprintf "%s: expected %s, got %s" name expected actual :: !errors
  in
  check "trace_sha256"
    (jstr (List.assoc "trace_sha256" report))
    trace.Decoder.sha256;
  check "states"
    (string_of_int (jint (List.assoc "states" report)))
    (string_of_int (List.length trace.Decoder.states));
  check "source"
    (match expected_source report with Some s -> "Some " ^ s | None -> "None")
    (match trace.Decoder.meta.source with
    | Some s -> "Some " ^ s
    | None -> "None");
  check "status"
    (match expected_status report with Some s -> "Some " ^ s | None -> "None")
    (match trace.Decoder.meta.status with
    | Some s -> "Some " ^ s
    | None -> "None");
  check "loop"
    (match expected_loop report with
    | Some n -> string_of_int n
    | None -> "None")
    (match trace.Decoder.loop with Some n -> string_of_int n | None -> "None");
  check "source_mismatch"
    (match List.assoc "source_mismatch" report with
    | Json_ast.Bool b -> string_of_bool b
    | _ -> "?")
    (string_of_bool trace.Decoder.source_mismatch);
  check "unknown_top_level_fields"
    (String.concat ","
       (jstrings (List.assoc "unknown_top_level_fields" report)))
    (String.concat "," trace.Decoder.unknown_top_level_fields);
  check "source_type"
    (match expected_type_field report "source_type" with
    | Some s -> s
    | None -> "None")
    (match trace.Decoder.meta.source_type with Some s -> s | None -> "None");
  check "status_type"
    (match expected_type_field report "status_type" with
    | Some s -> s
    | None -> "None")
    (match trace.Decoder.meta.status_type with Some s -> s | None -> "None");
  (* The declared set is the resolution result: own variables unqualified and
     instance-qualified variables per the direct-importer rule. *)
  check "ignored_vars"
    (String.concat "," (jstrings (List.assoc "ignored_vars" report)))
    (String.concat "," trace.Decoder.ignored_vars);
  List.rev !errors

let diagnostic_tokens members =
  match jopt members "expected_diagnostic" with
  | Some value -> (
      let fields = jobj value in
      ( (match jopt fields "must_contain" with
        | Some value -> jstrings value
        | None -> []),
        match jopt fields "must_not_contain" with
        | Some value -> jstrings value
        | None -> [] ))
  | None -> ([], [])

let corpus_gate () =
  let fixtures = fixtures_dir () in
  let expected_files = collect_expected fixtures [] in
  let refusal_pass = ref 0 and refusal_fail = ref 0 in
  let resolve_pass = ref 0 and resolve_fail = ref 0 in
  let accept_pass = ref 0 and accept_fail = ref 0 in
  let metadata_pass = ref 0 and metadata_fail = ref 0 in
  let failures = ref [] in
  let fail label details =
    failures := (label ^ ": " ^ String.concat "; " details) :: !failures
  in
  List.iter
    (fun expected_path ->
      let expected = load_json expected_path in
      let members = jobj expected in
      let fixture =
        match jopt members "fixture" with
        | Some value -> jstr value
        | None -> expected_path
      in
      let exit_code =
        match jopt members "expected_exit" with
        | Some value -> jint value
        | None -> -1
      in
      let stage =
        match jopt members "expected_stage" with
        | Some value -> Some (jstr value)
        | None -> None
      in
      let base = Filename.dirname expected_path in
      let args = invocation_args members in
      let spec = find_arg ".qnt" args in
      let trace_rel = find_arg ".itf.json" args in
      let main = find_main args in
      let invariants = find_invariants args in
      let strict_source = List.mem "--strict-source" args in
      let spec_path = Option.map (fun rel -> Filename.concat base rel) spec in
      let ir = match spec_path with Some path -> ir_for path | None -> None in
      let decls_result =
        match (ir, main) with
        | Some ir, Some main -> Resolver.variable_decls ir ~main
        | None, _ -> Error "the specification does not parse to an IR"
        | _, None -> Error "the invocation carries no --main"
      in
      let decls = match decls_result with Ok decls -> decls | Error _ -> [] in
      let must_contain, must_not_contain = diagnostic_tokens members in
      let missing message =
        List.filter (fun token -> not (contains_sub message token)) must_contain
      in
      let present message =
        List.filter (fun token -> contains_sub message token) must_not_contain
      in
      let is_decode_refusal = exit_code = 2 && stage = Some "decode" in
      let is_resolve_refusal = exit_code = 2 && stage = Some "resolve" in
      if is_resolve_refusal then begin
        let outcome =
          match (ir, main) with
          | Some ir, Some main -> Resolver.resolve ir ~main ~invariants
          | Some _, None -> Error "resolve: the invocation carries no --main"
          | None, _ ->
              Error "resolve: the specification does not parse to an IR"
        in
        match outcome with
        | Ok _ ->
            incr resolve_fail;
            fail fixture [ "expected a resolve refusal, resolution succeeded" ]
        | Error message ->
            let missing = missing message and present = present message in
            let stage_named =
              String.length message >= 9 && String.sub message 0 9 = "resolve: "
            in
            if stage_named && missing = [] && present = [] then
              incr resolve_pass
            else begin
              incr resolve_fail;
              fail fixture
                ([ Printf.sprintf "message=%S" message ]
                @ (if stage_named then []
                   else [ "the diagnostic does not name stage resolve" ])
                @ (if missing = [] then []
                   else [ "missing tokens: " ^ String.concat "," missing ])
                @
                if present = [] then []
                else [ "forbidden tokens: " ^ String.concat "," present ])
            end
      end
      else begin
        let trace_path =
          match trace_rel with
          | Some rel -> Filename.concat base rel
          | None -> expected_path
        in
        let raw = read_file trace_path in
        let result =
          Decoder.decode
            ~spec_path:(Option.value spec ~default:"")
            ~strict_source ~decls raw
        in
        if is_decode_refusal then
          begin match result with
          | Error refusal ->
              let missing = missing refusal.message in
              let present = present refusal.message in
              let requirement =
                match jopt members "requirement" with
                | Some value -> jstr value
                | None -> ""
              in
              let class_ok =
                match expected_class requirement with
                | Some klass -> refusal.klass = klass
                | None -> true
              in
              let offset_ok =
                if refusal.klass = 1 || refusal.klass = 14 then
                  match refusal.offset with
                  | Some offset -> List.mem (string_of_int offset) must_contain
                  | None -> false
                else true
              in
              if
                refusal.stage = "decode" && missing = [] && present = []
                && class_ok && offset_ok
              then incr refusal_pass
              else begin
                incr refusal_fail;
                fail fixture
                  ([
                     Printf.sprintf "message=%S class=%d" refusal.message
                       refusal.klass;
                   ]
                  @ (if missing = [] then []
                     else [ "missing tokens: " ^ String.concat "," missing ])
                  @ (if present = [] then []
                     else [ "forbidden tokens: " ^ String.concat "," present ])
                  @ (if class_ok then []
                     else [ "wrong class for: " ^ requirement ])
                  @
                  if offset_ok then []
                  else [ "byte offset is not the pinned one" ])
              end
          | Ok _ ->
              incr refusal_fail;
              fail fixture [ "expected a decode refusal, decoded successfully" ]
          end
        else
          match result with
          | Error refusal ->
              incr accept_fail;
              fail fixture
                [ "expected a successful decode: " ^ refusal.message ]
          | Ok trace -> (
              incr accept_pass;
              match jopt members "expected_report" with
              | Some report -> (
                  match decls_result with
                  | Error message ->
                      incr metadata_fail;
                      fail fixture [ "declared variables: " ^ message ]
                  | Ok _ ->
                      let errors = check_metadata (jobj report) trace in
                      if errors = [] then incr metadata_pass
                      else begin
                        incr metadata_fail;
                        fail fixture errors
                      end)
              | None -> ())
      end)
    expected_files;
  let refusal_total = !refusal_pass + !refusal_fail in
  let resolve_total = !resolve_pass + !resolve_fail in
  let accept_total = !accept_pass + !accept_fail in
  let failures = List.rev !failures in
  Printf.printf "corpus decode refusals: pass=%d fail=%d total=%d\n%!"
    !refusal_pass !refusal_fail refusal_total;
  Printf.printf "corpus resolve refusals: pass=%d fail=%d total=%d\n%!"
    !resolve_pass !resolve_fail resolve_total;
  Printf.printf "corpus decode acceptance: pass=%d fail=%d total=%d\n%!"
    !accept_pass !accept_fail accept_total;
  Printf.printf "corpus metadata: pass=%d fail=%d total=%d\n%!" !metadata_pass
    !metadata_fail
    (!metadata_pass + !metadata_fail);
  if failures <> [] then begin
    Printf.printf "corpus failures:\n%!";
    List.iter (fun message -> Printf.printf "  %s\n%!" message) failures
  end;
  failures = []

let schema_for name =
  let path =
    repo_file
      (match name with
      | "report-schema" -> "docs/report-schema.json"
      | "manifest-schema" -> "docs/manifest.schema.json"
      | "derivation-record-schema" -> "docs/derivation-record.schema.json"
      | other -> failwith ("unknown schema " ^ other))
  in
  load_json path

let schema_case_file () =
  first_existing
    [
      "schema-cases.json"; "test/schema-cases.json"; "../test/schema-cases.json";
    ]

(* The expected accept/refuse pairs are committed data, derived once from a
   conformance proof over the three schemas. A schema change re-derives the
   pairs; the recipe is in docs/README.md. *)
let schema_expected_pairs () =
  let cases = jarray (load_json (schema_case_file ())) in
  let report = schema_for "report-schema" in
  let manifest = schema_for "manifest-schema" in
  let derivation = schema_for "derivation-record-schema" in
  let agreed = ref 0 and disagreed = ref 0 and details = ref [] in
  List.iter
    (fun case ->
      let fields = jobj case in
      let name = jstr (List.assoc "name" fields) in
      let schema_name = jstr (List.assoc "schema" fields) in
      let document = List.assoc "document" fields in
      let expected_accepted =
        match List.assoc "accepted" fields with
        | Json_ast.Bool b -> b
        | _ -> false
      in
      let schema =
        match schema_name with
        | "report-schema" -> report
        | "manifest-schema" -> manifest
        | "derivation-record-schema" -> derivation
        | other -> failwith ("unknown schema name " ^ other)
      in
      let accepted = Schema.validate_doc schema document = [] in
      if accepted = expected_accepted then incr agreed
      else begin
        incr disagreed;
        details :=
          Printf.sprintf "%s: expected accepted=%b, got accepted=%b errors=%s"
            name expected_accepted accepted
            (String.concat " | " (Schema.validate_doc schema document))
          :: !details
      end)
    cases;
  Printf.printf "schema expected pairs: cases=%d agreed=%d disagreed=%d\n%!"
    (List.length cases) !agreed !disagreed;
  List.iter
    (fun message -> Printf.printf "  %s\n%!" message)
    (List.rev !details);
  !disagreed = 0
