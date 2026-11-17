(* Property runner: the seed-controlled resolver, evaluator-request,
   decoder-totality, integer-normalisation and report-determinism properties,
   their same-seed verdict comparisons, the different-seed exploration check,
   and mutation self-checks that prove each harness detects a broken engine.
   Usage: property_main [--seed=N] [--cases=N]
   Licence: AGPL-3.0-or-later; see README.md. *)

let parse_args argv =
  let seed = ref Property_support.default_seed in
  let cases = ref Property_support.default_cases in
  let assign prefix value target =
    if
      String.length value > String.length prefix
      && String.sub value 0 (String.length prefix) = prefix
    then begin
      target :=
        int_of_string
          (String.sub value (String.length prefix)
             (String.length value - String.length prefix));
      true
    end
    else false
  in
  let rec loop = function
    | [] -> ()
    | arg :: rest ->
        if assign "--seed=" arg seed then loop rest
        else if assign "--cases=" arg cases then loop rest
        else if arg = "--seed" then
          match rest with
          | value :: rest ->
              seed := int_of_string value;
              loop rest
          | [] -> ()
        else if arg = "--cases" then
          match rest with
          | value :: rest ->
              cases := int_of_string value;
              loop rest
          | [] -> ()
        else if arg = "--" then loop rest
        else loop rest
  in
  loop argv;
  (!seed, !cases)

let report_verdicts label baseline repeat repeat2 other =
  let same_seed =
    baseline.Property_support.verdict_digest
    = repeat.Property_support.verdict_digest
    && baseline.Property_support.verdict_digest
       = repeat2.Property_support.verdict_digest
  in
  let different_inputs =
    baseline.Property_support.input_digest
    <> other.Property_support.input_digest
  in
  Printf.printf
    "property %s verdicts: same-seed=%b (three runs) different-seed-inputs=%b\n"
    label same_seed different_inputs;
  (same_seed, different_inputs)

let () =
  let seed, cases = parse_args (List.tl (Array.to_list Sys.argv)) in
  let report = Property_support.run ~cases seed in
  Property_support.print_report report;
  let repeat = Property_support.run ~cases seed in
  let repeat2 = Property_support.run ~cases seed in
  let other = Property_support.run ~cases (seed + 1) in
  let resolver_same, resolver_inputs =
    report_verdicts "resolver-names" report repeat repeat2 other
  in
  let evaluator = Evaluator_property.run ~cases seed in
  Evaluator_property.print_report evaluator;
  let arity = Evaluator_property.run_arity ~cases seed in
  Evaluator_property.print_arity_report arity;
  let arity_repeat = Evaluator_property.run_arity ~cases seed in
  let arity_same =
    arity.Evaluator_property.arity_verdict_digest
    = arity_repeat.Evaluator_property.arity_verdict_digest
  in
  Printf.printf "property results-arity verdicts: same-seed=%b (two runs)\n"
    arity_same;
  let evaluator_repeat = Evaluator_property.run ~cases seed in
  let evaluator_repeat2 = Evaluator_property.run ~cases seed in
  let evaluator_other = Evaluator_property.run ~cases (seed + 1) in
  let evaluator_same, evaluator_inputs =
    let same_seed =
      evaluator.Evaluator_property.verdict_digest
      = evaluator_repeat.Evaluator_property.verdict_digest
      && evaluator.Evaluator_property.verdict_digest
         = evaluator_repeat2.Evaluator_property.verdict_digest
    in
    let different_inputs =
      evaluator.Evaluator_property.input_digest
      <> evaluator_other.Evaluator_property.input_digest
    in
    Printf.printf
      "property evaluator-requests verdicts: same-seed=%b (three runs) \
       different-seed-inputs=%b\n"
      same_seed different_inputs;
    (same_seed, different_inputs)
  in
  let totality = Decoder_property.run_totality ~cases seed in
  Decoder_property.print_report "totality" totality;
  let totality_repeat = Decoder_property.run_totality ~cases seed in
  let totality_same =
    totality.Decoder_property.verdict_digest
    = totality_repeat.Decoder_property.verdict_digest
  in
  Printf.printf "property totality verdicts: same-seed=%b (two runs)\n"
    totality_same;
  let roundtrip = Decoder_property.run_roundtrip ~cases seed in
  Decoder_property.print_report "normalisation-roundtrip" roundtrip;
  let roundtrip_repeat = Decoder_property.run_roundtrip ~cases seed in
  let roundtrip_same =
    roundtrip.Decoder_property.verdict_digest
    = roundtrip_repeat.Decoder_property.verdict_digest
  in
  Printf.printf
    "property normalisation-roundtrip verdicts: same-seed=%b (two runs)\n"
    roundtrip_same;
  let determinism_cases = min cases 20 in
  let determinism =
    Decoder_property.run_determinism ~cases:determinism_cases seed
  in
  Decoder_property.print_report "report-determinism" determinism;
  let determinism_repeat =
    Decoder_property.run_determinism ~cases:determinism_cases seed
  in
  let determinism_same =
    determinism.Decoder_property.verdict_digest
    = determinism_repeat.Decoder_property.verdict_digest
  in
  Printf.printf
    "property report-determinism verdicts: same-seed=%b (two runs)\n"
    determinism_same;
  let totality_mutant =
    Decoder_property.run_totality ~mutant:true ~cases seed
  in
  Decoder_property.print_report "totality-mutant" totality_mutant;
  let roundtrip_mutant =
    Decoder_property.run_roundtrip ~mutant:true ~cases seed
  in
  Decoder_property.print_report "normalisation-roundtrip-mutant"
    roundtrip_mutant;
  let determinism_mutant =
    Decoder_property.run_determinism ~mutant:true ~cases:determinism_cases seed
  in
  Decoder_property.print_report "report-determinism-mutant" determinism_mutant;
  let next_seed_failures =
    other.Property_support.failures
    + evaluator_other.Evaluator_property.failures
  in
  if next_seed_failures > 0 then
    Printf.printf
      "property run failed: seed %d produced %d failure(s); record the replay \
       case\n"
      (seed + 1) next_seed_failures;
  let self_check = Property_support.run ~mutant:true ~cases seed in
  Printf.printf
    "property harness self-check (mutant): seed=%d cases=%d failures=%d\n"
    self_check.Property_support.seed self_check.cases self_check.failures;
  (match self_check.first_failure with
  | Some case ->
      Printf.printf "property harness self-check replay case (seed=%d): %s\n"
        self_check.seed
        (Property_support.replay_record case)
  | None -> ());
  let passed =
    report.Property_support.failures = 0
    && evaluator.Evaluator_property.failures = 0
    && arity.Evaluator_property.arity_failures = 0
    && arity_same && resolver_same && resolver_inputs && evaluator_same
    && evaluator_inputs
    && totality.Decoder_property.failures = 0
    && roundtrip.Decoder_property.failures = 0
    && determinism.Decoder_property.failures = 0
    && totality_same && roundtrip_same && determinism_same
    && totality_mutant.Decoder_property.failures > 0
    && roundtrip_mutant.Decoder_property.failures > 0
    && determinism_mutant.Decoder_property.failures > 0
    && next_seed_failures = 0
    && self_check.Property_support.failures > 0
  in
  Printf.printf "RESULT: %s\n" (if passed then "pass" else "fail");
  exit (if passed then 0 else 1)
