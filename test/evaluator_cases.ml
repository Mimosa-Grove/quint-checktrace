(* Evaluator protocol cases: discovery and the digest pin, the version gate,
   request building, response mapping, the recorded probe replays and the
   evaluation-stage fixtures. Licence: AGPL-3.0-or-later; see README.md. *)

let contains = Corpus_support.contains_sub
let read = Corpus_support.read_file
let fixtures () = Corpus_support.fixtures_dir ()
let repo name = Corpus_support.repo_file name
let table_path () = repo (Filename.concat "bin" "evaluator-digests.json")

let json_of_string text =
  match Json_parse.parse text with
  | Ok value -> value
  | Error error -> Alcotest.fail ("test JSON is not JSON: " ^ error.message)

let check_tokens label tokens message =
  List.iter
    (fun token ->
      Alcotest.(check bool)
        (Printf.sprintf "%s: diagnostic carries %S" label token)
        true (contains message token))
    tokens

let stage_named stage message =
  let prefix = stage ^ ": " in
  String.length message >= String.length prefix
  && String.sub message 0 (String.length prefix) = prefix

let real_evaluator () =
  match Evaluator.resolve ~table:(table_path ()) () with
  | Ok resolved -> resolved
  | Error failure -> Alcotest.fail (Failure.to_string failure)

let temp_dir () =
  let path = Filename.temp_file "quint-checktrace-test" "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let script body =
  let directory = temp_dir () in
  let path = Filename.concat directory "tool" in
  let channel = open_out path in
  output_string channel "#!/bin/sh\n";
  output_string channel body;
  close_out channel;
  Unix.chmod path 0o755;
  path

let file_in dir name = Filename.concat dir name
let ir_for spec = Corpus_support.ir_for spec

let decoded_fixture ~spec ~trace ~main =
  match ir_for spec with
  | None -> Alcotest.fail ("the specification does not parse: " ^ spec)
  | Some ir -> (
      match Resolver.variable_decls ir ~main with
      | Error message -> Alcotest.fail message
      | Ok decls -> (
          match Decoder.decode ~decls (read trace) with
          | Error refusal -> Alcotest.fail refusal.Decoder.message
          | Ok parsed -> (ir, decls, parsed)))

let evaluation_fixture ~spec ~trace ~main ~invariants =
  let ir, _, parsed = decoded_fixture ~spec ~trace ~main in
  let resolved =
    match Resolver.resolve ir ~main ~invariants with
    | Ok resolved -> resolved
    | Error message -> Alcotest.fail message
  in
  (ir, resolved, parsed)

(* Discovery and the digest pin. *)

let test_missing_evaluator () =
  match
    Evaluator.resolve ~evaluator:"/nonexistent/quint_evaluator"
      ~table:(table_path ()) ()
  with
  | Ok _ -> Alcotest.fail "expected an evaluator refusal"
  | Error failure ->
      let message = Failure.to_string failure in
      Alcotest.(check bool)
        "stage evaluator" true
        (stage_named "evaluator" message);
      check_tokens "missing evaluator"
        [ "/nonexistent"; "does not exist" ]
        message

let test_digest_mismatch () =
  let path = script "exit 0\n" in
  match Evaluator.resolve ~evaluator:path ~table:(table_path ()) () with
  | Ok _ -> Alcotest.fail "expected a digest refusal"
  | Error failure ->
      let message = Failure.to_string failure in
      Alcotest.(check bool)
        "stage evaluator" true
        (stage_named "evaluator" message);
      let digest = Sha256.hex (read path) in
      check_tokens "digest mismatch"
        [ "sha256"; digest; "supported set" ]
        message

let test_wrong_quint_version () =
  let path = script "echo 0.0.0\n" in
  match Quint.version ~quint:path () with
  | Ok () -> Alcotest.fail "expected a version refusal"
  | Error failure ->
      let message = Failure.to_string failure in
      Alcotest.(check bool) "stage quint" true (stage_named "quint" message);
      check_tokens "wrong version" [ "0.0.0"; "0.33.1" ] message

(* The evaluator invocation: panic mapping and the timeout. *)

let test_panic_mapping () =
  let request =
    read (file_in (file_in (fixtures ()) "probes") "bigint-beyond-i64.json")
  in
  match Evaluator.run_request (real_evaluator ()) request with
  | Ok _ -> Alcotest.fail "expected a panic refusal"
  | Error failure ->
      let message = Failure.to_string failure in
      Alcotest.(check bool)
        "stage evaluate" true
        (stage_named "evaluate" message);
      check_tokens "panic" [ "101" ] message

let test_timeout_mapping () =
  let path = script "sleep 5\n" in
  match
    Evaluator.run_request { Evaluator.path; sha256 = "" } ~timeout:0.5 "{}"
  with
  | Ok _ -> Alcotest.fail "expected a timeout refusal"
  | Error failure ->
      let message = Failure.to_string failure in
      Alcotest.(check bool)
        "stage evaluate" true
        (stage_named "evaluate" message);
      check_tokens "timeout" [ "timeout" ] message

(* Request building: the normalised decimal form and the empty #meta. *)

let test_request_state () =
  let spec = file_in (fixtures ()) "bigint-10e15.qnt" in
  let trace = file_in (fixtures ()) "bigint-10e15.itf.json" in
  let ir, decls, parsed = decoded_fixture ~spec ~trace ~main:"BigValue" in
  let expected =
    json_of_string {|{"#meta":{},"x":{"#bigint":"1000000000000000"}}|}
  in
  let state = List.hd parsed.Decoder.states in
  let built = Evaluator.build_state ~decls state in
  Alcotest.(check bool) "normalised state" true (Json_ast.equal expected built);
  let table =
    match Json_ast.member "table" ir with
    | Some table -> table
    | None -> Json_ast.Object []
  in
  let expr =
    match Resolver.invariant_expr ir ~main:"BigValue" "exact" with
    | Some expr -> expr
    | None -> Alcotest.fail "the invariant expression is absent"
  in
  let request = Evaluator.build_request ~table ~state:built ~exprs:[ expr ] in
  Alcotest.(check bool)
    "request carries a table" true
    (Json_ast.member "table" request <> None);
  Alcotest.(check bool)
    "request carries one expression" true
    (match Json_ast.member "exprs" request with
    | Some (Json_ast.Array [ _ ]) -> true
    | _ -> false);
  Alcotest.(check bool)
    "request state is the built state" true
    (match Json_ast.member "state" request with
    | Some value -> Json_ast.equal built value
    | None -> false)

(* Response mapping. *)

let interpret_one invariants state_index output =
  Evaluator.interpret ~invariants ~state_index output

let test_response_mapping () =
  (match interpret_one [ "inv" ] 0 {|{"results":[{"value":true}]}|} with
  | Ok [ Evaluator.Pass ] -> ()
  | _ -> Alcotest.fail "a true value is a PASS");
  (match interpret_one [ "inv" ] 2 {|{"results":[{"value":false}]}|} with
  | Ok [ Evaluator.Fail ] -> ()
  | _ -> Alcotest.fail "a false value is a FAIL");
  (match
     interpret_one [ "pair" ] 0
       {|{"results":[{"value":{"#tup":[{"#tup":[]},{"#tup":[]}]}}]}|}
   with
  | Ok _ -> Alcotest.fail "a non-boolean value must be refused"
  | Error failure ->
      check_tokens "non-boolean" [ "pair"; "0"; "#tup" ]
        (Failure.to_string failure));
  (match
     interpret_one [ "divLater" ] 1
       {|{"results":[{"error":{"code":"QNT503","message":"Division by zero","#trace":[]}}]}|}
   with
  | Ok _ -> Alcotest.fail "an error result must be refused"
  | Error failure ->
      check_tokens "error result"
        [ "divLater"; "1"; "QNT503" ]
        (Failure.to_string failure));
  (match interpret_one [ "a"; "b" ] 0 {|{"results":[{"value":true}]}|} with
  | Ok _ -> Alcotest.fail "an arity mismatch must be refused"
  | Error failure ->
      let message = Failure.to_string failure in
      check_tokens "arity" [ "1"; "2" ] message;
      Alcotest.(check bool)
        "stage evaluate" true
        (stage_named "evaluate" message));
  match interpret_one [ "inv" ] 0 "not json" with
  | Ok _ -> Alcotest.fail "unparseable output must be refused"
  | Error failure ->
      Alcotest.(check bool)
        "stage evaluate" true
        (stage_named "evaluate" (Failure.to_string failure))

(* The evaluation-stage fixtures. *)

let test_evaluation_fixtures () =
  let cases =
    [
      ( "unit-result",
        file_in (fixtures ()) "unit-result.qnt",
        file_in (fixtures ()) "unit-result.itf.json",
        "Unit",
        [ "pair" ],
        [ "pair"; "0"; "#tup" ] );
      ( "hand-evaluation-error",
        file_in
          (file_in (fixtures ()) "hand-verified")
          "hand-evaluation-error.qnt",
        file_in
          (file_in (fixtures ()) "hand-verified")
          "hand-evaluation-error.itf.json",
        "HandUnbound",
        [ "atC" ],
        [ "atC"; "0"; "QNT500" ] );
      ( "hand-precedence",
        file_in (file_in (fixtures ()) "hand-verified") "hand-precedence.qnt",
        file_in
          (file_in (fixtures ()) "hand-verified")
          "hand-precedence.itf.json",
        "HandPrecedence",
        [ "belowOne"; "divLater" ],
        [ "divLater"; "1"; "QNT503" ] );
      ( "bigint-beyond-i64-typescript",
        file_in (fixtures ()) "bigint-beyond-i64-typescript.qnt",
        file_in (fixtures ()) "bigint-beyond-i64-typescript.itf.json",
        "BigOnly",
        [ "bigPositive" ],
        [ "evaluate" ] );
    ]
  in
  List.iter
    (fun (label, spec, trace, main, invariants, tokens) ->
      let ir, resolved, parsed =
        evaluation_fixture ~spec ~trace ~main ~invariants
      in
      match
        Check.run ~ir ~trace:parsed ~resolved ~evaluator:(real_evaluator ())
          ~timeout:30.0 ~deadline:300.0
      with
      | Ok _ -> Alcotest.fail (label ^ ": expected an evaluation refusal")
      | Error failure ->
          let message = Failure.to_string failure in
          Alcotest.(check bool)
            (label ^ ": stage evaluate")
            true
            (stage_named "evaluate" message);
          check_tokens label tokens message)
    cases

let test_loop_counts () =
  let run label spec trace main invariant expected_rows expected_calls =
    let ir, resolved, parsed =
      evaluation_fixture ~spec ~trace ~main ~invariants:[ invariant ]
    in
    match
      Check.run ~ir ~trace:parsed ~resolved ~evaluator:(real_evaluator ())
        ~timeout:30.0 ~deadline:300.0
    with
    | Error failure -> Alcotest.fail (label ^ ": " ^ Failure.to_string failure)
    | Ok result ->
        Alcotest.(check int)
          (label ^ ": evaluator calls")
          expected_calls result.Check.evaluations;
        Alcotest.(check int)
          (label ^ ": rows")
          (List.length expected_rows)
          (List.length result.rows);
        List.iter2
          (fun expected row ->
            Alcotest.(check string) (label ^ ": name") expected row.Check.name)
          expected_rows result.rows
  in
  run "loop-valid"
    (file_in (fixtures ()) "loop-valid.qnt")
    (file_in (fixtures ()) "loop-valid.itf.json")
    "Base" "nonNegative" [ "nonNegative" ] 3;
  run "loop-fail"
    (file_in (fixtures ()) "loop-fail.qnt")
    (file_in (fixtures ()) "loop-fail.itf.json")
    "Base" "belowThree" [ "belowThree" ] 4

let test_loop_fail_state_value () =
  let spec = file_in (fixtures ()) "loop-fail.qnt" in
  let trace = file_in (fixtures ()) "loop-fail.itf.json" in
  let _, decls, parsed = decoded_fixture ~spec ~trace ~main:"Base" in
  let state = List.nth parsed.Decoder.states 3 in
  let built = Evaluator.build_state ~decls state in
  let expected = json_of_string {|{"#meta":{},"count":{"#bigint":"3"}}|} in
  Alcotest.(check bool) "state 3 value" true (Json_ast.equal expected built)

(* The 42 committed request and capture pairs. *)

let normalise_thread_id text =
  let marker = "thread 'main' (" in
  let n = String.length text in
  let m = String.length marker in
  let rec find i =
    if i + m > n then None
    else if String.sub text i m = marker then Some i
    else find (i + 1)
  in
  match find 0 with
  | None -> text
  | Some at ->
      let start = at + m in
      let stop = ref start in
      while !stop < n && text.[!stop] >= '0' && text.[!stop] <= '9' do
        incr stop
      done;
      if !stop = start then text
      else String.sub text 0 start ^ "TID" ^ String.sub text !stop (n - !stop)

let probe_names dir =
  Sys.readdir dir |> Array.to_list
  |> List.filter (fun name -> Filename.check_suffix name ".json")
  |> List.sort String.compare

let test_probe_replay () =
  let directory = file_in (fixtures ()) "probes" in
  let names = probe_names directory in
  Alcotest.(check int) "probe pairs" 42 (List.length names);
  let evaluator = real_evaluator () in
  let failures = ref [] in
  List.iter
    (fun name ->
      let request = read (file_in directory name) in
      let expected =
        read (file_in directory (Filename.chop_extension name ^ ".out"))
      in
      match
        Proc.run_combined ~stdin:request ~timeout:30.0
          [| evaluator.Evaluator.path; "evaluate-at-state-from-stdin" |]
      with
      | { Proc.timed_out = true; _ } ->
          failures := (name ^ ": timed out") :: !failures
      | { Proc.spawn_error = Some error; _ } ->
          failures := (name ^ ": " ^ error) :: !failures
      | capture ->
          let got = normalise_thread_id capture.output in
          let want = normalise_thread_id expected in
          if got <> want then
            failures :=
              Printf.sprintf "%s: capture differs (got %d bytes, expected %d)"
                name (String.length got) (String.length want)
              :: !failures)
    names;
  List.iter
    (fun message -> Printf.printf "  %s\n%!" message)
    (List.rev !failures);
  Alcotest.(check int) "capture disagreements" 0 (List.length !failures)

(* The CLI value matrix, run against the built binary. *)

let binary () =
  Corpus_support.first_existing
    [
      "../bin/main.exe";
      "bin/main.exe";
      "_build/default/bin/main.exe";
      "../../_build/default/bin/main.exe";
      "../_build/default/bin/main.exe";
    ]

let run_binary args =
  Proc.run_combined ~timeout:30.0 (Array.of_list (binary () :: args))

let run_binary_with program args =
  Proc.run_combined ~timeout:30.0 (Array.of_list (program :: args))

let test_cli_matrix () =
  let expected =
    Corpus_support.load_json (file_in (fixtures ()) "cli-values.expected.json")
  in
  let invocations =
    match Corpus_support.jopt (Corpus_support.jobj expected) "invocations" with
    | Some value -> Corpus_support.jarray value
    | None -> Alcotest.fail "cli-values carries no invocations"
  in
  Alcotest.(check int) "invocation count" 32 (List.length invocations);
  let failures = ref [] in
  List.iter
    (fun invocation ->
      let fields = Corpus_support.jobj invocation in
      let args = Corpus_support.jstrings (List.assoc "args" fields) in
      let tokens, _ = Corpus_support.diagnostic_tokens fields in
      match run_binary args with
      | { Proc.timed_out = true; _ } ->
          failures := ("timed out: " ^ String.concat " " args) :: !failures
      | capture ->
          let ok_status = capture.Proc.status = Some 2 in
          let stderr = capture.output in
          let ok_stage = stage_named "usage" stderr in
          let missing =
            List.filter (fun token -> not (contains stderr token)) tokens
          in
          if not (ok_status && ok_stage && missing = []) then
            failures :=
              Printf.sprintf "%s: status=%s stage=%b missing=%s"
                (String.concat " " args)
                (match capture.status with
                | Some code -> string_of_int code
                | None -> "none")
                ok_stage
                (String.concat "," missing)
              :: !failures)
    invocations;
  List.iter
    (fun message -> Printf.printf "  %s\n%!" message)
    (List.rev !failures);
  Alcotest.(check int) "CLI disagreements" 0 (List.length !failures)

let test_path_shim () =
  let directory = temp_dir () in
  let shim = file_in directory "quint" in
  let channel = open_out shim in
  output_string channel "#!/bin/sh\necho 0.0.0\n";
  close_out channel;
  Unix.chmod shim 0o755;
  (* The digest table is resolved beside the binary. The shim run therefore
     uses a scratch copy of the binary with the table staged beside it. *)
  let scratch = file_in directory "quint-checktrace" in
  let copy source target =
    let channel = open_out_bin target in
    output_string channel (read source);
    close_out channel;
    Unix.chmod target 0o755
  in
  copy (binary ()) scratch;
  copy (table_path ()) (file_in directory "evaluator-digests.json");
  let saved = Sys.getenv_opt "PATH" in
  Unix.putenv "PATH" (directory ^ ":" ^ Option.value saved ~default:"");
  let capture =
    run_binary_with scratch
      [
        file_in (fixtures ()) "plain-pass.qnt";
        file_in (fixtures ()) "plain-pass.itf.json";
        "--main=Plain";
        "--invariant=nonNegative";
      ]
  in
  (match saved with Some value -> Unix.putenv "PATH" value | None -> ());
  Alcotest.(check bool) "exit 2" true (capture.Proc.status = Some 2);
  Alcotest.(check bool) "stage quint" true (stage_named "quint" capture.output);
  check_tokens "PATH shim" [ "0.0.0"; "0.33.1" ] capture.output

let test_wrong_quint_precedes_evaluator () =
  let directory = temp_dir () in
  let shim = file_in directory "quint" in
  let channel = open_out shim in
  output_string channel "#!/bin/sh\necho 0.0.0\n";
  close_out channel;
  Unix.chmod shim 0o755;
  let saved = Sys.getenv_opt "PATH" in
  Unix.putenv "PATH" (directory ^ ":" ^ Option.value saved ~default:"");
  let capture =
    run_binary
      [
        "--evaluator=/nonexistent/quint_evaluator";
        file_in (fixtures ()) "plain-pass.qnt";
        file_in (fixtures ()) "plain-pass.itf.json";
        "--main=Plain";
        "--invariant=nonNegative";
      ]
  in
  (match saved with Some value -> Unix.putenv "PATH" value | None -> ());
  Alcotest.(check bool) "exit 2" true (capture.Proc.status = Some 2);
  Alcotest.(check bool)
    "stage quint precedes evaluator" true
    (stage_named "quint" capture.output)

let test_version_deadline () =
  let directory = temp_dir () in
  let shim = file_in directory "quint" in
  let channel = open_out shim in
  output_string channel "#!/bin/sh\nsleep 5\n";
  close_out channel;
  Unix.chmod shim 0o755;
  let saved = Sys.getenv_opt "PATH" in
  Unix.putenv "PATH" (directory ^ ":" ^ Option.value saved ~default:"");
  let capture =
    run_binary
      [
        "--deadline=1";
        "--timeout=1";
        file_in (fixtures ()) "plain-pass.qnt";
        file_in (fixtures ()) "plain-pass.itf.json";
        "--main=Plain";
        "--invariant=nonNegative";
      ]
  in
  (match saved with Some value -> Unix.putenv "PATH" value | None -> ());
  Alcotest.(check bool) "exit 2" true (capture.Proc.status = Some 2);
  Alcotest.(check bool) "stage quint" true (stage_named "quint" capture.output)

let test_binary_missing_evaluator () =
  let capture =
    run_binary
      [
        "--evaluator=/nonexistent/quint_evaluator";
        file_in (fixtures ()) "plain-pass.qnt";
        file_in (fixtures ()) "plain-pass.itf.json";
        "--main=Plain";
        "--invariant=nonNegative";
      ]
  in
  Alcotest.(check bool) "exit 2" true (capture.Proc.status = Some 2);
  Alcotest.(check bool)
    "stage evaluator" true
    (stage_named "evaluator" capture.output);
  check_tokens "missing evaluator" [ "/nonexistent" ] capture.output

let suite =
  [
    Alcotest.test_case "missing evaluator" `Quick test_missing_evaluator;
    Alcotest.test_case "digest mismatch" `Quick test_digest_mismatch;
    Alcotest.test_case "wrong quint version" `Quick test_wrong_quint_version;
    Alcotest.test_case "panic mapping" `Quick test_panic_mapping;
    Alcotest.test_case "timeout mapping" `Quick test_timeout_mapping;
    Alcotest.test_case "request state" `Quick test_request_state;
    Alcotest.test_case "response mapping" `Quick test_response_mapping;
    Alcotest.test_case "evaluation fixtures" `Quick test_evaluation_fixtures;
    Alcotest.test_case "loop counts" `Quick test_loop_counts;
    Alcotest.test_case "loop fail state value" `Quick test_loop_fail_state_value;
    Alcotest.test_case "probe replay" `Quick test_probe_replay;
    Alcotest.test_case "CLI matrix" `Quick test_cli_matrix;
    Alcotest.test_case "PATH shim" `Quick test_path_shim;
    Alcotest.test_case "wrong quint precedes evaluator" `Quick
      test_wrong_quint_precedes_evaluator;
    Alcotest.test_case "version deadline" `Quick test_version_deadline;
    Alcotest.test_case "binary missing evaluator" `Quick
      test_binary_missing_evaluator;
  ]
