(* Corpus-gate cases: the committed registry, the registry refusal classes and
   the acceptance sequences. Licence: AGPL-3.0-or-later; see README.md. *)

let read = Corpus_support.read_file

let write path text =
  let channel = open_out_bin path in
  output_string channel text;
  close_out channel

let rec copy_tree source target =
  if Sys.is_directory source then begin
    if not (Sys.file_exists target) then Unix.mkdir target 0o755;
    Array.iter
      (fun name ->
        if name <> "." && name <> ".." then
          copy_tree (Filename.concat source name) (Filename.concat target name))
      (Sys.readdir source)
  end
  else write target (read source)

let temp_dir () =
  let path = Filename.temp_file "quint-checktrace-gate" "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let registry_copies () =
  let root = temp_dir () in
  copy_tree (Corpus_support.repo_file "test/corpus") root;
  ( root,
    Filename.concat root "corpus",
    Filename.concat root "manifest.json",
    Filename.concat root "hand-verified",
    Filename.concat root "records",
    Filename.concat root "traces" )

let binary () =
  Corpus_support.first_existing
    [
      "../bin/main.exe";
      "bin/main.exe";
      "_build/default/bin/main.exe";
      "../../_build/default/bin/main.exe";
      "../_build/default/bin/main.exe";
    ]

let run_gate_in ~root args =
  let program =
    let path = binary () in
    if Filename.is_relative path then Filename.concat (Sys.getcwd ()) path
    else path
  in
  let saved = Sys.getcwd () in
  Sys.chdir root;
  let capture =
    Proc.run_combined ~timeout:180.0
      (Array.of_list ([ program; "--gate" ] @ args))
  in
  Sys.chdir saved;
  capture

let load_json = Corpus_support.load_json
let save_json path json = write path (Json_writer.to_string json)
let members = Corpus_support.jobj
let manifest_rows path = Corpus_support.jarray (load_json path)
let save_rows path rows = save_json path (Json_ast.Array rows)
let mutate_record path transform = save_json path (transform (load_json path))

let set_member key value = function
  | Json_ast.Object fields ->
      Json_ast.Object ((key, value) :: List.remove_assoc key fields)
  | other -> other

let string_member key json = List.assoc_opt key (members json)

let replace_all ~needle ~replacement text =
  let buffer = Buffer.create (String.length text) in
  let length = String.length text and n = String.length needle in
  let rec loop index =
    if index + n > length then
      Buffer.add_substring buffer text index (length - index)
    else if String.sub text index n = needle then begin
      Buffer.add_string buffer replacement;
      loop (index + n)
    end
    else begin
      Buffer.add_char buffer text.[index];
      loop (index + 1)
    end
  in
  if n = 0 then text
  else begin
    loop 0;
    Buffer.contents buffer
  end

let check_counts_and_marker label capture =
  Alcotest.(check bool)
    (label ^ ": counts line") true
    (Corpus_support.contains_sub capture.Proc.output "entries=");
  Alcotest.(check bool)
    (label ^ ": end marker") true
    (Corpus_support.contains_sub capture.Proc.output "== END OF GATE RUN ==")

let check_refusal label capture tokens =
  Alcotest.(check bool) (label ^ ": exit 2") true (capture.Proc.status = Some 2);
  check_counts_and_marker label capture;
  Alcotest.(check bool)
    (label ^ ": stage resolve")
    true
    (Corpus_support.contains_sub capture.Proc.output "resolve: ");
  List.iter
    (fun token ->
      Alcotest.(check bool)
        (Printf.sprintf "%s: diagnostic carries %S" label token)
        true
        (Corpus_support.contains_sub capture.Proc.output token))
    tokens

let test_committed_registry () =
  let capture =
    run_gate_in
      ~root:(Corpus_support.repo_file ".")
      [
        Corpus_support.repo_file "test/corpus/corpus";
        Corpus_support.repo_file "test/corpus/manifest.json";
        Corpus_support.repo_file "test/corpus/hand-verified";
      ]
  in
  Alcotest.(check bool) "exit 0" true (capture.Proc.status = Some 0);
  check_counts_and_marker "committed registry" capture;
  List.iter
    (fun token ->
      Alcotest.(check bool)
        (Printf.sprintf "counts carry %S" token)
        true
        (Corpus_support.contains_sub capture.Proc.output token))
    [
      "entries=67";
      "runnable=51";
      "triples=55";
      "agree=55";
      "disagree=0";
      "excluded=25";
      "fixtures=8";
      "fixtures_disagree=0";
    ]

let set_command transform path =
  mutate_record path (fun record ->
      match string_member "command" record with
      | Some (Json_ast.String command) ->
          set_member "command" (Json_ast.String (transform command)) record
      | _ -> record)

let test_registry_refusals () =
  let cases =
    [
      ( "duplicate rows",
        (fun (_, _, manifest, _, _, _) ->
          let rows = manifest_rows manifest in
          save_rows manifest (rows @ [ List.hd rows ])),
        [ "two rows" ] );
      ( "repeated invariant",
        (fun (_, _, manifest, _, _, _) ->
          let rows = manifest_rows manifest in
          match rows with
          | row :: _ ->
              let fields = members row in
              let first =
                List.hd (Corpus_support.jarray (List.assoc "invariants" fields))
              in
              save_rows manifest
                [
                  Json_ast.Object
                    (("invariants", Json_ast.Array [ first; first ])
                    :: List.remove_assoc "invariants" fields);
                ]
          | [] -> Alcotest.fail "empty manifest"),
        [ "repeats the invariant" ] );
      ( "parent path",
        (fun (_, _, manifest, _, _, _) ->
          let rows = manifest_rows manifest in
          match rows with
          | row :: _ ->
              save_rows manifest
                [ set_member "path" (Json_ast.String "../escape.qnt") row ]
          | [] -> Alcotest.fail "empty manifest"),
        [ "parent-directory" ] );
      ( "absent file",
        (fun (_, _, manifest, _, _, _) ->
          let rows = manifest_rows manifest in
          match rows with
          | row :: _ ->
              save_rows manifest
                [ set_member "path" (Json_ast.String "real/absent.qnt") row ]
          | [] -> Alcotest.fail "empty manifest"),
        [ "absent from the corpus" ] );
      ( "corpus entry with no row",
        (fun (_, corpus, _, _, _, _) ->
          write (Filename.concat corpus "real/extra.qnt") "module Extra {\n}\n"),
        [ "has no manifest row" ] );
      ( "manifest invariant with no record",
        (fun (_, _, _, _, records, _) ->
          Sys.remove
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")),
        [ "has no derivation record" ] );
      ( "record main differs",
        (fun (_, _, _, _, records, _) ->
          set_command
            (replace_all ~needle:"--main=implResolution"
               ~replacement:"--main=Other")
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")),
        [ "--main=Other" ] );
      ( "record invariant absent from the row",
        (fun (_, _, _, _, records, _) ->
          let record =
            load_json
              (Filename.concat records
                 "impl-resolution--implResolution--probeAtMostOnce.json")
          in
          let extra =
            match string_member "command" record with
            | Some (Json_ast.String command) ->
                set_member "command"
                  (Json_ast.String
                     (replace_all ~needle:"--invariant=probeAtMostOnce"
                        ~replacement:"--invariant=extra" command))
                  record
            | _ -> record
          in
          save_json
            (Filename.concat records
               "impl-resolution--implResolution--extra.json")
            extra),
        [ "absent from that row's manifest entries" ] );
      ( "error record against derive",
        (fun (_, _, _, _, records, _) ->
          mutate_record
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")
            (fun record ->
              record
              |> set_member "stdout" (Json_ast.String "[error] Runtime error\n")
              |> set_member "stderr"
                   (Json_ast.String "Error [QNT500]: unbound\n")
              |> set_member "exit_code" (Json_ast.Number "1"))),
        [ "runtime error" ] );
      ( "both success forms",
        (fun (_, _, _, _, records, _) ->
          mutate_record
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")
            (fun record ->
              record
              |> set_member "stdout"
                   (Json_ast.String
                      "[ok] No violation found\n[violation] Found an issue\n")
              |> set_member "exit_code" (Json_ast.Number "1"))),
        [ "both success forms" ] );
      ( "lone error marker",
        (fun (_, _, _, _, records, _) ->
          mutate_record
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")
            (fun record ->
              record
              |> set_member "stdout" (Json_ast.String "[error] Runtime error\n")
              |> set_member "exit_code" (Json_ast.Number "1"))),
        [ "no QNT diagnostic" ] );
      ( "lone QNT diagnostic",
        (fun (_, _, _, _, records, _) ->
          mutate_record
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")
            (fun record ->
              record
              |> set_member "stdout" (Json_ast.String "")
              |> set_member "stderr"
                   (Json_ast.String "Error [QNT500]: unbound\n")
              |> set_member "exit_code" (Json_ast.Number "1"))),
        [ "no stdout error marker" ] );
      ( "no recognised outcome",
        (fun (_, _, _, _, records, _) ->
          mutate_record
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")
            (fun record ->
              set_member "stdout" (Json_ast.String "quiet\n") record)),
        [ "no recognised outcome" ] );
      ( "inconsistent recorded exit",
        (fun (_, _, _, _, records, _) ->
          mutate_record
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")
            (fun record -> set_member "exit_code" (Json_ast.Number "1") record)),
        [ "does not agree" ] );
      ( "digest mismatch",
        (fun (_, _, _, _, records, _) ->
          mutate_record
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")
            (fun record ->
              set_member "spec_sha256"
                (Json_ast.String (String.make 64 '0'))
                record)),
        [ "spec-file digest is" ] );
      ( "malformed digest set",
        (fun (_, _, _, _, records, _) ->
          mutate_record
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")
            (fun record ->
              set_member "spec_sha256" (Json_ast.String "abc") record)),
        [ "not a 64-hex digest" ] );
      ( "import path escapes",
        (fun (_, _, _, _, records, _) ->
          mutate_record
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")
            (fun record ->
              set_member "imports"
                (Json_ast.Object
                   [ ("../escape.qnt", Json_ast.String (String.make 64 '0')) ])
                record)),
        [ "escapes the tree" ] );
      ( "absent import",
        (fun (_, _, _, _, records, _) ->
          mutate_record
            (Filename.concat records
               "impl-resolution--implResolution--probeAtMostOnce.json")
            (fun record ->
              set_member "imports"
                (Json_ast.Object
                   [
                     ("real/nothing.qnt", Json_ast.String (String.make 64 '0'));
                   ])
                record)),
        [ "is absent" ] );
      ( "trace source mismatch",
        (fun (_, _, _, _, _, traces) ->
          let path =
            Filename.concat traces
              "impl-resolution--implResolution--probeAtMostOnce.itf.json"
          in
          let trace = load_json path in
          let meta =
            match string_member "#meta" trace with
            | Some meta ->
                set_member "source"
                  (Json_ast.String "other/impl-resolution.qnt") meta
            | None -> Json_ast.Object []
          in
          save_json path (set_member "#meta" meta trace)),
        [ "the trace records source" ] );
      ( "absent trace",
        (fun (_, _, _, _, _, traces) ->
          Sys.remove
            (Filename.concat traces
               "impl-resolution--implResolution--probeAtMostOnce.itf.json")),
        [ "is absent" ] );
    ]
  in
  List.iter
    (fun (label, mutate, tokens) ->
      let root, corpus, manifest, fixtures, records, traces =
        registry_copies ()
      in
      mutate (root, corpus, manifest, fixtures, records, traces);
      let capture = run_gate_in ~root [ corpus; manifest; fixtures ] in
      check_refusal label capture tokens)
    cases

let test_zero_triples () =
  let root, corpus, manifest, fixtures, records, _ = registry_copies () in
  let rows = manifest_rows manifest in
  (* Every derive invariant becomes an exclude, and every record an error
     outcome, so the registry validates and the manifest admits no triple. *)
  let excluded_rows =
    List.map
      (fun row ->
        match row with
        | Json_ast.Object fields ->
            let invariants =
              match List.assoc_opt "invariants" fields with
              | Some (Json_ast.Array entries) ->
                  Json_ast.Array
                    (List.map
                       (fun entry ->
                         match entry with
                         | Json_ast.Object entry_fields ->
                             Json_ast.Object
                               (("status", Json_ast.String "exclude")
                               :: ("reason", Json_ast.String "QNT500")
                               :: List.remove_assoc "status"
                                    (List.remove_assoc "reason" entry_fields))
                         | other -> other)
                       entries)
              | Some other -> other
              | None -> Json_ast.Null
            in
            Json_ast.Object
              (("invariants", invariants)
              :: List.remove_assoc "invariants" fields)
        | other -> other)
      rows
  in
  save_rows manifest excluded_rows;
  let record_names = Sys.readdir records in
  Array.iter
    (fun name ->
      if Filename.check_suffix name ".json" then
        mutate_record (Filename.concat records name) (fun record ->
            record
            |> set_member "stdout" (Json_ast.String "[error] Runtime error\n")
            |> set_member "stderr" (Json_ast.String "Error [QNT500]: unbound\n")
            |> set_member "exit_code" (Json_ast.Number "1")))
    record_names;
  ignore root;
  let capture = run_gate_in ~root [ corpus; manifest; fixtures ] in
  check_refusal "zero triples" capture [ "no admitted triple" ];
  List.iter
    (fun token ->
      Alcotest.(check bool)
        (Printf.sprintf "zero triples counts carry %S" token)
        true
        (Corpus_support.contains_sub capture.Proc.output token))
    [ "runnable=0"; "triples=0"; "excluded=76" ]

let test_short_inventory () =
  let root, corpus, manifest, fixtures, _, _ = registry_copies () in
  List.iter
    (fun name ->
      Sys.remove (Filename.concat fixtures (name ^ ".expected.json")))
    [ "hand-mixed"; "hand-precedence"; "hand-precedence-scope" ];
  let capture = run_gate_in ~root [ corpus; manifest; fixtures ] in
  check_refusal "short inventory" capture [ "fewer than the six" ]

let test_missing_category () =
  let root, corpus, manifest, fixtures, _, _ = registry_copies () in
  Sys.remove (Filename.concat fixtures "hand-bigint.expected.json");
  let capture = run_gate_in ~root [ corpus; manifest; fixtures ] in
  check_refusal "missing category" capture [ "big-integer category" ]

let test_absent_inventory () =
  let root, corpus, manifest, _, _, _ = registry_copies () in
  let capture =
    run_gate_in ~root
      [ corpus; manifest; Filename.concat root "absent-inventory" ]
  in
  check_refusal "absent inventory" capture [ "is absent" ]

let test_doctored_trace () =
  let root, corpus, manifest, fixtures, _, traces = registry_copies () in
  (* A violation triple with its failing state duplicated as a later state:
     the replay's first FAIL sits at the original index while the trace grew,
     so the recorded fail position no longer matches and the verdict
     disagrees. *)
  let path = Filename.concat traces "ir--vizIR--mutantEq.itf.json" in
  let trace = load_json path in
  let states =
    match string_member "states" trace with
    | Some (Json_ast.Array states) -> states
    | _ -> Alcotest.fail "the trace carries no states"
  in
  let count = List.length states in
  if count < 1 then Alcotest.fail "the trace carries no state";
  let bump_index state =
    match state with
    | Json_ast.Object fields -> (
        match List.assoc_opt "#meta" fields with
        | Some (Json_ast.Object meta) ->
            Json_ast.Object
              (( "#meta",
                 Json_ast.Object
                   (("index", Json_ast.Number "1")
                   :: List.remove_assoc "index" meta) )
              :: List.remove_assoc "#meta" fields)
        | _ -> state)
    | other -> other
  in
  let doctored = states @ [ bump_index (List.hd states) ] in
  save_json path (set_member "states" (Json_ast.Array doctored) trace);
  let capture = run_gate_in ~root [ corpus; manifest; fixtures ] in
  Alcotest.(check bool)
    "doctored trace: exit 1" true
    (capture.Proc.status = Some 1);
  check_counts_and_marker "doctored trace" capture;
  Alcotest.(check bool)
    "doctored trace: disagreement counted" true
    (Corpus_support.contains_sub capture.Proc.output "disagree=1")

let test_doctored_record () =
  let root, corpus, manifest, fixtures, records, _ = registry_copies () in
  mutate_record
    (Filename.concat records
       "impl-resolution--implResolution--probeAtMostOnce.json") (fun record ->
      record
      |> set_member "stdout" (Json_ast.String "[violation] Found an issue\n")
      |> set_member "exit_code" (Json_ast.Number "0"));
  let capture = run_gate_in ~root [ corpus; manifest; fixtures ] in
  check_refusal "doctored record" capture [ "does not agree" ]

let test_doctored_fixture () =
  let root, corpus, manifest, fixtures, _, _ = registry_copies () in
  let path = Filename.concat fixtures "hand-violation.expected.json" in
  let expected = load_json path in
  let report =
    match string_member "expected_report" expected with
    | Some report -> report
    | None -> Alcotest.fail "hand-violation carries no expected_report"
  in
  let invariants =
    match string_member "invariants" report with
    | Some (Json_ast.Array [ row ]) ->
        [ set_member "state" (Json_ast.Number "2") row ]
    | _ -> Alcotest.fail "hand-violation carries no single row"
  in
  let report = set_member "invariants" (Json_ast.Array invariants) report in
  save_json path (set_member "expected_report" report expected);
  let capture = run_gate_in ~root [ corpus; manifest; fixtures ] in
  Alcotest.(check bool)
    "doctored fixture: exit 1" true
    (capture.Proc.status = Some 1);
  check_counts_and_marker "doctored fixture" capture;
  Alcotest.(check bool)
    "doctored fixture: disagreement counted" true
    (Corpus_support.contains_sub capture.Proc.output "fixtures_disagree=1")

let test_checker_exit_two () =
  let root, corpus, manifest, fixtures, _, traces = registry_copies () in
  (* One state value becomes a non-decimal #bigint: the registry still
     validates, the checker refuses at decode under class 10, and an exit 2
     on an admitted triple is a disagreement. *)
  let path =
    Filename.concat traces
      "impl-resolution--implResolution--probeAtMostOnce.itf.json"
  in
  let trace = load_json path in
  let states =
    match string_member "states" trace with
    | Some (Json_ast.Array states) -> states
    | _ -> Alcotest.fail "the trace carries no states"
  in
  let doctor state =
    match state with
    | Json_ast.Object fields -> (
        match List.find_opt (fun (name, _) -> not (name = "#meta")) fields with
        | Some (name, _) ->
            Json_ast.Object
              ((name, Json_ast.Object [ ("#bigint", Json_ast.String "zz") ])
              :: List.remove_assoc name fields)
        | None -> state)
    | other -> other
  in
  let states = List.map doctor states in
  save_json path (set_member "states" (Json_ast.Array states) trace);
  let capture = run_gate_in ~root [ corpus; manifest; fixtures ] in
  Alcotest.(check bool)
    "checker exit 2: gate exit 1" true
    (capture.Proc.status = Some 1);
  check_counts_and_marker "checker exit 2" capture;
  Alcotest.(check bool)
    "checker exit 2: disagreement counted" true
    (Corpus_support.contains_sub capture.Proc.output "disagree=1")

let test_deadline () =
  let root, corpus, manifest, fixtures, _, _ = registry_copies () in
  let capture =
    run_gate_in ~root [ corpus; manifest; fixtures; "--gate-deadline=1" ]
  in
  Alcotest.(check bool) "deadline: exit 2" true (capture.Proc.status = Some 2);
  check_counts_and_marker "deadline" capture

let suite =
  [
    Alcotest.test_case "committed registry" `Quick test_committed_registry;
    Alcotest.test_case "registry refusals" `Quick test_registry_refusals;
    Alcotest.test_case "zero triples" `Quick test_zero_triples;
    Alcotest.test_case "short inventory" `Quick test_short_inventory;
    Alcotest.test_case "missing category" `Quick test_missing_category;
    Alcotest.test_case "absent inventory" `Quick test_absent_inventory;
    Alcotest.test_case "doctored trace" `Quick test_doctored_trace;
    Alcotest.test_case "doctored record" `Quick test_doctored_record;
    Alcotest.test_case "doctored fixture" `Quick test_doctored_fixture;
    Alcotest.test_case "checker exit 2" `Quick test_checker_exit_two;
    Alcotest.test_case "gate deadline" `Quick test_deadline;
  ]
