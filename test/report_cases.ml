(* Report fixtures: the human rendering and the machine report against every
   report-bearing expected file in the corpus. Licence: AGPL-3.0-or-later;
   see README.md. *)

let contains = Corpus_support.contains_sub
let fixtures () = Corpus_support.fixtures_dir ()
let expected_files () = Corpus_support.collect_expected (fixtures ()) []

let report_bearing () =
  List.filter
    (fun path ->
      let expected = Corpus_support.load_json path in
      Corpus_support.jopt (Corpus_support.jobj expected) "expected_report"
      <> None)
    (expected_files ())

let report_schema () =
  Corpus_support.load_json (Corpus_support.repo_file "docs/report-schema.json")

let sub path = Filename.concat (fixtures ()) path

let real_evaluator () =
  match Evaluator.resolve () with
  | Ok resolved -> resolved
  | Error failure -> Alcotest.fail (Failure.to_string failure)

let run_fixture expected_path =
  let expected = Corpus_support.load_json expected_path in
  let members = Corpus_support.jobj expected in
  let args = Corpus_support.invocation_args members in
  let spec_rel =
    Option.value (Corpus_support.find_arg ".qnt" args) ~default:""
  in
  let trace_rel =
    Option.value (Corpus_support.find_arg ".itf.json" args) ~default:""
  in
  let main = Option.value (Corpus_support.find_main args) ~default:"" in
  let invariants = Corpus_support.find_invariants args in
  let base = Filename.dirname expected_path in
  let spec_path = Filename.concat base spec_rel in
  let trace_path = Filename.concat base trace_rel in
  let ir =
    match Corpus_support.ir_for spec_path with
    | Some ir -> ir
    | None -> Alcotest.fail (spec_rel ^ " does not parse")
  in
  let decls =
    match Resolver.variable_decls ir ~main with
    | Ok decls -> decls
    | Error message -> Alcotest.fail message
  in
  let raw = Corpus_support.read_file trace_path in
  let trace =
    match Decoder.decode ~spec_path:spec_rel ~decls raw with
    | Ok trace -> trace
    | Error refusal -> Alcotest.fail refusal.Decoder.message
  in
  let resolved =
    match Resolver.resolve ir ~main ~invariants with
    | Ok resolved -> resolved
    | Error message -> Alcotest.fail message
  in
  let result =
    match
      Check.run ~ir ~trace ~resolved ~evaluator:(real_evaluator ())
        ~timeout:30.0 ~deadline:300.0
    with
    | Ok result -> result
    | Error failure -> Alcotest.fail (Failure.to_string failure)
  in
  let ir_sha256 = Sha256.hex (Json_writer.to_string ir) in
  let input =
    {
      Report.spec_path = spec_rel;
      main;
      quint_version = Quint.pinned_version;
      ir_sha256;
      trace_path = trace_rel;
      trace;
      evaluator = real_evaluator ();
      rows =
        Report.build_rows ~trace ~variables:resolved.Resolver.variables result;
    }
  in
  (members, input)

let json_lines document =
  match document with
  | Json_ast.Object members -> members
  | _ -> failwith "the report is not an object"

let member key document = List.assoc key (json_lines document)

let hex_prefix digest =
  if String.length digest <= 12 then digest else String.sub digest 0 12

let is_hex c = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')

let check_header_patterns input properties =
  match
    Corpus_support.jopt (Corpus_support.jobj properties) "header_patterns"
  with
  | None -> ()
  | Some (Json_ast.Array patterns) ->
      List.iter
        (fun pattern ->
          match pattern with
          | Json_ast.String "sha256=[0-9a-f]{12}([^0-9a-f]|$)" -> (
              let human = Report.human_string input in
              let prefix =
                "sha256=" ^ hex_prefix input.Report.evaluator.Evaluator.sha256
              in
              let at = Corpus_support.find_sub human prefix in
              Alcotest.(check bool)
                "digest prefix pattern: prefix present" true (at <> None);
              match at with
              | Some at ->
                  let after = at + String.length prefix in
                  Alcotest.(check bool)
                    "digest prefix pattern: non-hex or end" true
                    (after >= String.length human || not (is_hex human.[after]))
              | None -> ())
          | Json_ast.String _ ->
              Alcotest.fail "unhandled header pattern in the corpus"
          | _ -> Alcotest.fail "a header pattern is not a string")
        patterns
  | Some _ -> Alcotest.fail "header_patterns is not an array"

let starts_with prefix text =
  String.length text >= String.length prefix
  && String.sub text 0 (String.length prefix) = prefix

let row_lines lines =
  List.filter (fun line -> contains line "✓" || contains line "✗") lines

let check_human label members input =
  match Corpus_support.jopt members "expected_human" with
  | None -> ()
  | Some properties -> (
      let properties = Corpus_support.jobj properties in
      let human = Report.human_string input in
      let lines = Report.human_lines input in
      let rows = row_lines lines in
      let string_list key =
        match Corpus_support.jopt properties key with
        | Some value -> Corpus_support.jstrings value
        | None -> []
      in
      let summary_lines =
        List.filter (fun line -> starts_with "Summary: " line) lines
      in
      (match Corpus_support.jopt properties "single_line_header" with
      | Some (Json_ast.Bool true) ->
          Alcotest.(check int)
            (label ^ ": header line") 1
            (List.length (List.filter (fun line -> contains line "──") lines))
      | _ -> ());
      List.iter
        (fun token ->
          Alcotest.(check bool)
            (Printf.sprintf "%s: header carries %S" label token)
            true (contains human token))
        (string_list "header_tokens");
      check_header_patterns input (Json_ast.Object properties);
      (match Corpus_support.jopt properties "summary_lines" with
      | Some (Json_ast.Number raw) ->
          Alcotest.(check int)
            (label ^ ": summary lines")
            (int_of_float (float_of_string raw))
            (List.length summary_lines)
      | _ -> ());
      (match Corpus_support.jopt properties "summary_form" with
      | Some (Json_ast.String form) ->
          Alcotest.(check bool)
            (label ^ ": summary form") true
            (List.mem form summary_lines)
      | _ -> ());
      (match Corpus_support.jopt properties "summary_token" with
      | Some (Json_ast.String token) -> (
          match summary_lines with
          | [ line ] ->
              Alcotest.(check bool)
                (label ^ ": summary token " ^ token)
                true (contains line token)
          | _ -> Alcotest.fail (label ^ ": expected exactly one summary line"))
      | _ -> ());
      (match Corpus_support.jopt properties "summary_absent_tokens" with
      | Some value ->
          List.iter
            (fun token ->
              List.iter
                (fun line ->
                  Alcotest.(check bool)
                    (label ^ ": summary omits " ^ token)
                    false (contains line token))
                summary_lines)
            (Corpus_support.jstrings value)
      | None -> ());
      (match Corpus_support.jopt properties "source_rendering" with
      | Some (Json_ast.String rendering) ->
          Alcotest.(check bool)
            (label ^ ": source rendering")
            true (contains human rendering)
      | _ -> ());
      (match Corpus_support.jopt properties "status_rendering" with
      | Some (Json_ast.String rendering) ->
          Alcotest.(check bool)
            (label ^ ": status rendering")
            true (contains human rendering)
      | _ -> ());
      (match Corpus_support.jopt properties "pass_wording" with
      | Some (Json_ast.String wording) ->
          List.iter
            (fun line ->
              if contains line "✓" then
                Alcotest.(check bool)
                  (label ^ ": PASS wording") true (contains line wording))
            rows
      | _ -> ());
      (match Corpus_support.jopt properties "pass_absent_tokens" with
      | Some value ->
          List.iter
            (fun token ->
              List.iter
                (fun line ->
                  if contains line "✓" then
                    Alcotest.(check bool)
                      (label ^ ": PASS omits " ^ token)
                      false (contains line token))
                rows)
            (Corpus_support.jstrings value)
      | None -> ());
      (match Corpus_support.jopt properties "fail_wording" with
      | Some (Json_ast.String wording) ->
          Alcotest.(check bool)
            (label ^ ": FAIL wording") true (contains human wording)
      | _ -> ());
      (match Corpus_support.jopt properties "fail_tokens" with
      | Some value ->
          List.iter
            (fun token ->
              List.iter
                (fun line ->
                  if contains line "✗" then
                    Alcotest.(check bool)
                      (label ^ ": FAIL omits " ^ token)
                      false (contains line token))
                rows)
            (Corpus_support.jstrings value)
      | None -> ());
      List.iter
        (fun escaped ->
          Alcotest.(check bool)
            (Printf.sprintf "%s: escaped rendering %S" label escaped)
            true (contains human escaped))
        (string_list "escaped_renderings");
      (match Corpus_support.jopt properties "coverage_line" with
      | Some (Json_ast.String line) ->
          Alcotest.(check bool)
            (label ^ ": coverage line")
            true (contains human line)
      | _ -> ());
      (match Corpus_support.jopt properties "status_glyphs" with
      | Some glyphs ->
          let glyphs = Corpus_support.jobj glyphs in
          List.iter
            (fun (verdict, present) ->
              if present then
                match List.assoc_opt verdict glyphs with
                | Some (Json_ast.String glyph) ->
                    Alcotest.(check bool)
                      (label ^ ": glyph " ^ verdict)
                      true (contains human glyph)
                | _ -> ())
            [
              ( "pass",
                List.exists
                  (fun row -> row.Report.verdict = Report.Pass)
                  input.Report.rows );
              ( "fail",
                List.exists
                  (fun row -> row.Report.verdict <> Report.Pass)
                  input.Report.rows );
            ]
      | None -> ());
      let note_lines = List.filter (fun line -> contains line "note: ") lines in
      List.iter
        (fun token ->
          Alcotest.(check bool)
            (Printf.sprintf "%s: information carries %S" label token)
            true
            (List.exists (fun line -> contains line token) note_lines))
        (string_list "information_tokens");
      List.iter
        (fun token ->
          List.iter
            (fun line ->
              Alcotest.(check bool)
                (label ^ ": information omits " ^ token)
                false (contains line token))
            note_lines)
        (string_list "information_absent_tokens");
      match Corpus_support.jopt properties "single_line_information_lines" with
      | Some (Json_ast.Bool true) ->
          List.iter
            (fun line ->
              Alcotest.(check bool)
                (label ^ ": information line is one line")
                false (contains line "\n"))
            note_lines
      | _ -> ())

let test_reports () =
  let files = report_bearing () in
  Printf.printf "report fixtures: %d\n%!" (List.length files);
  Alcotest.(check int) "report-bearing fixtures" 56 (List.length files);
  let schema = report_schema () in
  List.iter
    (fun expected_path ->
      let label = Filename.basename expected_path in
      let members, input = run_fixture expected_path in
      let expected_report = List.assoc "expected_report" members in
      let actual = Report.projection input in
      if not (Json_ast.equal expected_report actual) then begin
        Printf.printf "expected: %s\nactual:   %s\n%!"
          (Json_writer.to_string expected_report)
          (Json_writer.to_string actual)
      end;
      Alcotest.(check bool)
        (label ^ ": report projection")
        true
        (Json_ast.equal expected_report actual);
      let document = Report.document input in
      let errors = Schema.validate_doc schema document in
      Alcotest.(check (list string)) (label ^ ": schema") [] errors;
      check_human label members input)
    files

(* The evaluation-stage fixtures whose completed outcome is a verdict report
   carry a FAIL row with its state index, the still-active PASS row and the
   summary line. *)
let test_precedence_scope () =
  let path =
    Filename.concat
      (Filename.concat (fixtures ()) "hand-verified")
      "hand-precedence-scope.expected.json"
  in
  let members, input = run_fixture path in
  Alcotest.(check int) "exit" 1 (Report.exit_code input.Report.rows);
  Alcotest.(check string)
    "summary" "Summary: 1 pass, 1 fail (exit 1)"
    (Report.summary_line input);
  let rows = input.Report.rows in
  Alcotest.(check int) "rows" 2 (List.length rows);
  ignore members;
  (match
     List.assoc_opt "nonNegative"
       (List.map (fun row -> (row.Report.name, row.Report.verdict)) rows)
   with
  | Some Report.Pass -> ()
  | _ -> Alcotest.fail "nonNegative is not a PASS row");
  match
    List.assoc_opt "zeroDiv"
      (List.map (fun row -> (row.Report.name, row.Report.verdict)) rows)
  with
  | Some (Report.Fail { state; rendering; state_value }) ->
      Alcotest.(check int) "zeroDiv state" 0 state;
      Alcotest.(check string) "zeroDiv rendering" "{ count: 0 }" rendering;
      Alcotest.(check bool)
        "zeroDiv state_value" true
        (Json_ast.equal
           (Json_ast.Object
              [
                ("#meta", Json_ast.Object []);
                ("count", Json_ast.Object [ ("#bigint", Json_ast.String "0") ]);
              ])
           state_value);
      let human = Report.human_string input in
      Alcotest.(check bool)
        "human FAIL row" true
        (contains human "FAIL at state 0: { count: 0 }")
  | _ -> Alcotest.fail "zeroDiv is not a FAIL row"

let suite =
  [
    Alcotest.test_case "report fixtures" `Quick test_reports;
    Alcotest.test_case "precedence scope outcome" `Quick test_precedence_scope;
  ]
