(* Regression cells: annotation-id type aliases, unmodelled
   import shapes, the version-probe scope, the decode deadline, the gate's
   import-digest refusal, single stage prefixes and abandoned gate calls.
   Licence: AGPL-3.0-or-later; see README.md. *)

let contains = Corpus_support.contains_sub
let read = Corpus_support.read_file
let fixtures () = Corpus_support.fixtures_dir ()

let regression name =
  Corpus_support.repo_file (Filename.concat "test/regressions/imports" name)

let run_binary args =
  Proc.run_combined ~timeout:90.0
    (Array.of_list (Evaluator_cases.binary () :: args))

let stage_named = Evaluator_cases.stage_named
let evaluator = Evaluator_cases.real_evaluator

let ir name =
  match Corpus_support.ir_for (regression name) with
  | Some ir -> ir
  | None -> Alcotest.fail (name ^ " does not parse")

let decls ~ir ~main =
  match Resolver.variable_decls ir ~main with
  | Ok decls -> decls
  | Error message -> Alcotest.fail message

let decode ~ir ~main ~trace =
  let decls = decls ~ir ~main in
  match Decoder.decode ~decls (read (regression trace)) with
  | Ok parsed -> (decls, parsed)
  | Error refusal -> Alcotest.fail refusal.Decoder.message

let resolved ~ir ~main ~invariants =
  match Resolver.resolve ir ~main ~invariants with
  | Ok resolved -> resolved
  | Error message -> Alcotest.fail message

let rows ~ir ~trace ~main invariant =
  match
    Check.run ~ir ~trace
      ~resolved:(resolved ~ir ~main ~invariants:[ invariant ])
      ~evaluator:(evaluator ()) ~timeout:30.0 ~deadline:300.0
  with
  | Ok result -> result.Check.rows
  | Error failure -> Alcotest.fail (Failure.to_string failure)

let outcome_of name rows =
  match List.find_opt (fun row -> row.Check.name = name) rows with
  | Some row -> Some row.Check.outcome
  | None -> None

let test_alias_annotation_id () =
  let ir = ir "confuse2c.qnt" in
  let decls, parsed = decode ~ir ~main:"Main" ~trace:"confuse2c.itf.json" in
  (match List.assoc_opt "w" decls with
  | Some
      (Ir_types.Record
         [
           ("s", Ir_types.Int);
           ("e", Ir_types.Int);
           ("c", Ir_types.List Ir_types.Int);
         ]) ->
      ()
  | _ ->
      Alcotest.fail "the W annotation did not resolve to the RecB record alias");
  match List.assoc_opt "w" (List.hd parsed.Decoder.states).Decoder.values with
  | Some
      (Itf_value.Record
         [
           ("s", Itf_value.Int "1");
           ("e", Itf_value.Int "0");
           ("c", Itf_value.List [ Itf_value.Int "1" ]);
         ]) ->
      ()
  | _ -> Alcotest.fail "the record trace value was not decoded as a record"

let test_alias_verdicts () =
  let ir = ir "confuse2c.qnt" in
  let _, parsed = decode ~ir ~main:"Main" ~trace:"confuse2c.itf.json" in
  (match
     outcome_of "isTheRecord"
       (rows ~ir ~trace:parsed ~main:"Main" "isTheRecord")
   with
  | Some Check.Pass -> ()
  | _ -> Alcotest.fail "isTheRecord was not a clean pass on the record state");
  match
    outcome_of "recordIsNotOne"
      (rows ~ir ~trace:parsed ~main:"Main" "recordIsNotOne")
  with
  | Some (Check.Fail 0) -> ()
  | _ ->
      Alcotest.fail
        "recordIsNotOne was not a fail at state 0 on the record state"

let test_unique_alias_control () =
  let ir = ir "confuse3.qnt" in
  let _, parsed = decode ~ir ~main:"Main" ~trace:"confuse3.itf.json" in
  match
    outcome_of "isTheRecord" (rows ~ir ~trace:parsed ~main:"Main" "isTheRecord")
  with
  | Some Check.Pass -> ()
  | _ -> Alcotest.fail "the unique-alias control was not a clean pass"

let test_star_import_refused () =
  match Resolver.variable_decls (ir "star.qnt") ~main:"StarMain" with
  | Ok _ ->
      Alcotest.fail "the star import of a module declaring a var was accepted"
  | Error message ->
      List.iter
        (fun token ->
          Alcotest.(check bool)
            (Printf.sprintf "star refusal carries %S" token)
            true (contains message token))
        [ "import"; "Lib"; "not modelled" ]

let test_alias_import_refused () =
  match Resolver.variable_decls (ir "alias.qnt") ~main:"AliasMain" with
  | Ok _ ->
      Alcotest.fail "the alias import of a module declaring a var was accepted"
  | Error message ->
      List.iter
        (fun token ->
          Alcotest.(check bool)
            (Printf.sprintf "alias refusal carries %S" token)
            true (contains message token))
        [ "import"; "Lib"; "not modelled" ]

let test_cli_import_refusals () =
  let cases =
    [
      ("star.qnt", "star.itf.json", "StarMain");
      ("alias.qnt", "alias.itf.json", "AliasMain");
    ]
  in
  List.iter
    (fun (spec, trace, main) ->
      let label = spec in
      let capture =
        run_binary
          [
            regression spec;
            regression trace;
            "--main=" ^ main;
            "--invariant=ok";
          ]
      in
      Alcotest.(check bool)
        (label ^ ": exit 2") true
        (capture.Proc.status = Some 2);
      Alcotest.(check bool)
        (label ^ ": stage resolve")
        true
        (stage_named "resolve" capture.output);
      Alcotest.(check bool)
        (label ^ ": refusal names the unmodelled shape")
        true
        (contains capture.output "not modelled"))
    cases

let test_version_probe_deadline_only () =
  let saved = Sys.getenv_opt "PATH" in
  let shim =
    Evaluator_cases.script
      (Printf.sprintf
         "if [ \"$1\" = \"--version\" ]; then sleep 1.2; echo 0.33.1; exit 0; fi\n\
          PATH='%s' exec quint \"$@\"\n"
         (Option.value saved ~default:""))
  in
  let spec = Filename.concat (fixtures ()) "plain-pass.qnt" in
  let trace = Filename.concat (fixtures ()) "plain-pass.itf.json" in
  let common =
    [
      "--quint=" ^ shim; spec; trace; "--main=Plain"; "--invariant=nonNegative";
    ]
  in
  let without_timeout_cap =
    run_binary ([ "--timeout=1"; "--deadline=30" ] @ common)
  in
  Alcotest.(check bool)
    "the version probe is not capped by --timeout" false
    (stage_named "quint" without_timeout_cap.output);
  Alcotest.(check bool)
    "the run reaches a later stage or completes" true
    (without_timeout_cap.status = Some 0
    || stage_named "evaluate" without_timeout_cap.output);
  let deadline_bounded =
    run_binary ([ "--timeout=1"; "--deadline=1" ] @ common)
  in
  Alcotest.(check bool)
    "the deadline still bounds the version probe" true
    (stage_named "quint" deadline_bounded.output);
  Alcotest.(check bool)
    "the deadline-bound run exits 2" true
    (deadline_bounded.status = Some 2)

let write_big_trace path states =
  let buffer = Buffer.create (32 * 1024 * 1024) in
  Buffer.add_string buffer
    "{\"#meta\":{\"format\":\"ITF\",\"status\":\"ok\"},\"vars\":[\"count\"],\"states\":[";
  for i = 0 to states - 1 do
    if i > 0 then Buffer.add_char buffer ',';
    Buffer.add_string buffer "{\"#meta\":{\"index\":";
    Buffer.add_string buffer (string_of_int i);
    Buffer.add_string buffer "},\"count\":{\"#bigint\":\"";
    Buffer.add_string buffer (string_of_int (i mod 1000));
    Buffer.add_string buffer "\"}}"
  done;
  Buffer.add_string buffer "]}";
  let channel = open_out_bin path in
  output_string channel (Buffer.contents buffer);
  close_out channel

(* A deadline that has passed at the first typed-state check refuses at stage
   decode inside the typed descent, before any state is decoded. The clock is
   scripted, so the verdict holds whatever the machine's speed and load are;
   the trace is long enough to reach the state loop but its parse time is not
   part of the assertion. *)
let test_decode_deadline () =
  let directory = Evaluator_cases.temp_dir () in
  let trace = Filename.concat directory "decode-deadline.itf.json" in
  write_big_trace trace 5000;
  match Decoder.preparse (Corpus_support.read_file trace) with
  | Error refusal ->
      Alcotest.fail
        ("the deadline trace did not preparse: " ^ refusal.Decoder.message)
  | Ok parsed -> (
      let stats = Decoder.fresh_stats () in
      let decls = [ ("count", Ir_types.Int) ] in
      let reads = ref 0 in
      let now () =
        incr reads;
        if !reads > 1 then 5.0 else 0.0
      in
      match
        Decoder.decode_typed_at ~now ~stats ~deadline_at:5.0 ~decls parsed
      with
      | Ok _ -> Alcotest.fail "the typed descent completed past its deadline"
      | Error refusal ->
          Alcotest.(check string) "stage decode" "decode" refusal.Decoder.stage;
          Alcotest.(check int) "class 0" 0 refusal.Decoder.klass;
          Alcotest.(check bool)
            "the state loop is the checkpoint" true
            (contains refusal.Decoder.message "during the typed descent");
          Alcotest.(check int) "no state is decoded" 0 stats.Decoder.nodes;
          Alcotest.(check bool)
            "the deadline refusal is not an evaluator failure" false
            (contains refusal.Decoder.message "evaluate"))

let mutate_imports imports record =
  Gate_cases.set_member "imports" imports record

let test_gate_nonstring_digest () =
  let cases =
    [
      ( "numeric digest",
        Json_ast.Object
          [ ("real/janet-num/specs/impl-resolution.qnt", Json_ast.Number "42") ],
        [ "not a JSON string" ] );
      ("malformed imports value", Json_ast.String "not-an-object", [ "imports" ]);
    ]
  in
  List.iter
    (fun (label, imports, tokens) ->
      let root, corpus, manifest, fixtures, records, _ =
        Gate_cases.registry_copies ()
      in
      Gate_cases.mutate_record
        (Filename.concat records
           "impl-resolution--implResolution--probeAtMostOnce.json")
        (mutate_imports imports);
      let capture =
        Gate_cases.run_gate_in ~root [ corpus; manifest; fixtures ]
      in
      Alcotest.(check bool)
        (label ^ ": exit 2") true
        (capture.Proc.status = Some 2);
      Alcotest.(check bool)
        (label ^ ": stage resolve")
        true
        (contains capture.output "resolve: ");
      List.iter
        (fun token ->
          Alcotest.(check bool)
            (Printf.sprintf "%s: counts or message carry %S" label token)
            true
            (contains capture.output token))
        ([ "entries=67"; "runnable=0"; "triples=0" ] @ tokens))
    cases

let test_gate_deadline_no_disagreement () =
  let root, corpus, manifest, fixtures, _, _ = Gate_cases.registry_copies () in
  let saved = Sys.getenv_opt "PATH" in
  let shim =
    Evaluator_cases.script
      (Printf.sprintf
         "if [ \"$1\" = \"--version\" ]; then echo 0.33.1; exit 0; fi\n\
          sleep 2\n\
          PATH='%s' exec quint \"$@\"\n"
         (Option.value saved ~default:""))
  in
  let capture =
    Gate_cases.run_gate_in ~root
      [ corpus; manifest; fixtures; "--gate-deadline=2"; "--quint=" ^ shim ]
  in
  Alcotest.(check bool)
    "the gate deadline exits 2" true
    (capture.Proc.status = Some 2);
  Alcotest.(check bool)
    "an abandoned call issues no disagreement verdict" false
    (contains capture.output "triple disagreement");
  Alcotest.(check bool)
    "the disagreement count stays zero" true
    (contains capture.output "disagree=0")

let test_single_stage_prefix () =
  let decode_capture =
    run_binary
      [
        Filename.concat (fixtures ()) "json-garbage.qnt";
        Filename.concat (fixtures ()) "json-garbage.itf.json";
        "--main=Base";
        "--invariant=nonNegative";
      ]
  in
  Alcotest.(check bool)
    "the decode refusal names its stage" true
    (stage_named "decode" decode_capture.output);
  Alcotest.(check bool)
    "the decode prefix appears once" false
    (contains decode_capture.output "decode: decode:");
  let resolve_capture =
    run_binary
      [
        Filename.concat (fixtures ()) "resolver-main-absent.qnt";
        Filename.concat (fixtures ()) "resolver-main-absent.itf.json";
        "--main=Absent";
        "--invariant=nonNegative";
      ]
  in
  Alcotest.(check bool)
    "the resolve refusal names its stage" true
    (stage_named "resolve" resolve_capture.output);
  Alcotest.(check bool)
    "the resolve prefix appears once" false
    (contains resolve_capture.output "resolve: resolve:")

let suite =
  [
    Alcotest.test_case "annotation id alias" `Quick test_alias_annotation_id;
    Alcotest.test_case "annotation id verdicts" `Quick test_alias_verdicts;
    Alcotest.test_case "unique alias control" `Quick test_unique_alias_control;
    Alcotest.test_case "star import refused" `Quick test_star_import_refused;
    Alcotest.test_case "alias import refused" `Quick test_alias_import_refused;
    Alcotest.test_case "CLI import refusals" `Quick test_cli_import_refusals;
    Alcotest.test_case "version probe deadline scope" `Quick
      test_version_probe_deadline_only;
    Alcotest.test_case "decode deadline" `Slow test_decode_deadline;
    Alcotest.test_case "gate non-string digest" `Quick
      test_gate_nonstring_digest;
    Alcotest.test_case "gate deadline disagreement" `Slow
      test_gate_deadline_no_disagreement;
    Alcotest.test_case "single stage prefix" `Quick test_single_stage_prefix;
  ]
