(* Regression cells: the two-phase decode puts a structural
   refusal before declaration derivation, and the full stage-order matrix
   holds across the failure order. The recorded property regressions -
   totality, normalisation and report determinism - replay their mutant
   counter-examples.
   Licence: AGPL-3.0-or-later; see README.md. *)

let contains = Corpus_support.contains_sub
let read = Corpus_support.read_file
let fixtures () = Corpus_support.fixtures_dir ()

let run_binary args =
  Proc.run_combined ~timeout:90.0
    (Array.of_list (Evaluator_cases.binary () :: args))

let stage_named = Evaluator_cases.stage_named

let test_decode_before_declarations () =
  let capture =
    run_binary
      [
        Filename.concat (fixtures ()) "resolver-main-absent.qnt";
        Filename.concat (fixtures ()) "json-garbage.itf.json";
        "--main=Absent";
        "--invariant=nonNegative";
      ]
  in
  Alcotest.(check bool)
    "the combined failure exits 2" true
    (capture.Proc.status = Some 2);
  Alcotest.(check bool)
    "the structural refusal names stage decode" true
    (stage_named "decode" capture.output);
  Alcotest.(check bool)
    "the resolution refusal is not reached first" false
    (stage_named "resolve" capture.output);
  Alcotest.(check bool)
    "the refusal is JSON class 1" true
    (contains capture.output "class 1")

let ty_of_string = function
  | "int" -> Ir_types.Int
  | "str" -> Ir_types.Str
  | "bool" -> Ir_types.Bool
  | other -> Alcotest.fail ("unknown declaration type " ^ other)

let write_file path text =
  let channel = open_out path in
  output_string channel text;
  close_out channel

let test_stage_order_matrix () =
  let wrong_quint = Evaluator_cases.script "echo 0.0.0\n" in
  let broken_dir = Evaluator_cases.temp_dir () in
  let broken_spec = Filename.concat broken_dir "broken.qnt" in
  write_file broken_spec "module Broken {\n";
  let plain = Filename.concat (fixtures ()) "plain-pass.qnt" in
  let plain_trace = Filename.concat (fixtures ()) "plain-pass.itf.json" in
  let garbage = Filename.concat (fixtures ()) "json-garbage.itf.json" in
  let absent = [ "--main=Absent"; "--invariant=nonNegative" ] in
  let missing_evaluator = "--evaluator=/nonexistent/evaluator" in
  let cases =
    [
      ("usage", [ "--quint=" ^ wrong_quint; missing_evaluator ], "usage");
      ( "quint",
        [ "--quint=" ^ wrong_quint; missing_evaluator; plain; garbage ] @ absent,
        "quint" );
      ( "evaluator",
        [ missing_evaluator; broken_spec; garbage ] @ absent,
        "evaluator" );
      ("parse", [ broken_spec; garbage ] @ absent, "parse");
      ("decode", [ plain; garbage ] @ absent, "decode");
      ("resolve", [ plain; plain_trace ] @ absent, "resolve");
    ]
  in
  List.iter
    (fun (label, args, stage) ->
      let capture = run_binary args in
      Alcotest.(check bool)
        (label ^ ": exit 2") true
        (capture.Proc.status = Some 2);
      Alcotest.(check bool)
        (label ^ ": earliest stage " ^ stage)
        true
        (stage_named stage capture.output))
    cases

let regression_file () =
  Corpus_support.repo_file "test/regressions/decoder-properties.json"

let test_recorded_property_regressions () =
  let document = Corpus_support.load_json (regression_file ()) in
  let records =
    match Corpus_support.jopt (Corpus_support.jobj document) "records" with
    | Some value -> Corpus_support.jarray value
    | None -> Alcotest.fail "the regression file carries no records"
  in
  Alcotest.(check bool) "at least one record" true (records <> []);
  List.iter
    (fun record ->
      let fields = Corpus_support.jobj record in
      let property = Corpus_support.jstr (List.assoc "property" fields) in
      match property with
      | "totality" -> (
          let input = Corpus_support.jstr (List.assoc "input" fields) in
          try
            match Decoder.decode ~decls:[] input with
            | Ok _ -> ()
            | Error refusal ->
                Alcotest.(check bool)
                  "totality refusal names decode" true
                  (refusal.Decoder.stage = "decode");
                Alcotest.(check bool)
                  "totality class is in 1..16" true
                  (refusal.Decoder.klass >= 1 && refusal.Decoder.klass <= 16)
          with exception_ ->
            Alcotest.fail
              ("totality replay escaped: " ^ Printexc.to_string exception_))
      | "normalisation" -> (
          let text = Corpus_support.jstr (List.assoc "input" fields) in
          let json_value =
            if text = "0" then
              Json_ast.Object [ ("#bigint", Json_ast.String "0") ]
            else Evaluator_property.s_e_c text
          in
          let raw =
            Json_writer.to_string
              (Decoder_property.trace_json ~value:json_value)
          in
          match Decoder_property.decode_int_value raw with
          | Ok actual ->
              Alcotest.(check string)
                ("normalisation replay " ^ text)
                text actual
          | Error message ->
              Alcotest.fail ("normalisation replay " ^ text ^ ": " ^ message))
      | "report-determinism" ->
          let raw =
            match Corpus_support.jopt fields "input" with
            | Some (Json_ast.String text) -> text
            | _ ->
                let fixture =
                  Corpus_support.jstr (List.assoc "fixture" fields)
                in
                read (Filename.concat (fixtures ()) fixture)
          in
          let decls =
            match Corpus_support.jopt fields "declarations" with
            | Some (Json_ast.Array pairs) ->
                List.map
                  (fun pair ->
                    match pair with
                    | Json_ast.Array
                        [ Json_ast.String name; Json_ast.String ty ] ->
                        (name, ty_of_string ty)
                    | _ -> Alcotest.fail "a declaration record is not a pair")
                  pairs
            | _ ->
                [ ("count", Ir_types.Int); ("log", Ir_types.List Ir_types.Int) ]
          in
          let fixture =
            match Corpus_support.jopt fields "fixture" with
            | Some (Json_ast.String value) -> value
            | _ -> "inline"
          in
          let first = Decoder_property.render_once ~decls ~mutant:false raw in
          let second = Decoder_property.render_once ~decls ~mutant:false raw in
          Alcotest.(check bool)
            ("determinism replay " ^ fixture)
            true (first = second)
      | other -> Alcotest.fail ("unknown recorded property " ^ other))
    records

let suite =
  [
    Alcotest.test_case "decode before declaration derivation" `Quick
      test_decode_before_declarations;
    Alcotest.test_case "stage-order matrix" `Quick test_stage_order_matrix;
    Alcotest.test_case "recorded property regressions" `Quick
      test_recorded_property_regressions;
  ]
