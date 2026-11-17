(* Regression cells: the deadline checkpoints inside the value
   descent, the names-only pre-pass and the structural value walk, the single
   JSON path per diagnostic, the gate's named missing member, the duplicate IR
   table key, and the totality generator's declaration reach.
   Licence: AGPL-3.0-or-later; see README.md. *)

let contains = Corpus_support.contains_sub
let fixtures () = Corpus_support.fixtures_dir ()
let stage_named = Evaluator_cases.stage_named

let run_binary args =
  Proc.run_combined ~timeout:300.0
    (Array.of_list (Evaluator_cases.binary () :: args))

let write_file path text =
  let channel = open_out_bin path in
  output_string channel text;
  close_out channel

let count_occurrences text needle =
  let n = String.length needle and h = String.length text in
  let rec loop index count =
    if index + n > h then count
    else if String.sub text index n = needle then loop (index + 1) (count + 1)
    else loop (index + 1) count
  in
  if n = 0 then 0 else loop 0 0

(* The trace's declared values carry nested refusals whose classes
   are type-independent, so they must be reported at stage decode even when
   the main module the resolution needs is absent. The four traces are written
   at run time (the generator is the test) to keep the committed tree small. *)
let test_structural_refusals_precede_resolution () =
  let directory = Evaluator_cases.temp_dir () in
  let spec = Filename.concat (fixtures ()) "plain-pass.qnt" in
  let head =
    "{\"vars\":[\"count\",\"log\"],\"states\":[{\"#meta\":{\"index\":0},"
  in
  let cases =
    [
      ( "nested duplicate",
        head
        ^ "\"count\":{\"#bigint\":\"0\"},\"log\":[{\"a\":{\"#bigint\":\"1\"},\"a\":{\"#bigint\":\"2\"}}]}]}",
        "class 2" );
      ( "unknown constructor",
        head ^ "\"count\":{\"#bigint\":\"0\"},\"log\":[{\"#bogus\":\"x\"}]}]}",
        "class 9" );
      ( "unserializable",
        head
        ^ "\"count\":{\"#bigint\":\"0\"},\"log\":[{\"#unserializable\":\"x\"}]}]}",
        "class 11" );
      ("bare number", head ^ "\"count\":7,\"log\":[]}]}", "class 10");
    ]
  in
  List.iteri
    (fun index (label, raw, klass) ->
      let trace =
        Filename.concat directory
          ("descent-structural-" ^ string_of_int index ^ ".itf.json")
      in
      write_file trace raw;
      List.iter
        (fun main ->
          let capture =
            run_binary
              [
                spec;
                trace;
                "--main=" ^ main;
                "--invariant=nonNegative";
                "--deadline=30";
                "--timeout=5";
              ]
          in
          Alcotest.(check bool)
            (label ^ " main " ^ main ^ ": exit 2")
            true
            (capture.Proc.status = Some 2);
          Alcotest.(check bool)
            (label ^ " main " ^ main ^ ": stage decode")
            true
            (stage_named "decode" capture.output);
          Alcotest.(check bool)
            (label ^ " main " ^ main ^ ": names " ^ klass)
            true
            (contains capture.output klass);
          Alcotest.(check bool)
            (label ^ " main " ^ main ^ ": resolution is not reached first")
            false
            (stage_named "resolve" capture.output))
        [ "Absent"; "Plain" ])
    cases

(* One JSON path per diagnostic. *)
let test_single_json_path () =
  let raw =
    "{\"vars\":[\"count\"],\"states\":[{\"#meta\":{\"index\":0},\"count\":{\"#bigint\":\"0\",\"#bigint\":\"1\"}}]}"
  in
  match Decoder.decode ~decls:[ ("count", Ir_types.Int) ] raw with
  | Ok _ -> Alcotest.fail "the duplicate member was accepted"
  | Error refusal ->
      Alcotest.(check int) "class 2" 2 refusal.Decoder.klass;
      Alcotest.(check int)
        "the path appears once" 1
        (count_occurrences refusal.Decoder.message "states/0/count");
      Alcotest.(check bool)
        "the path is not doubled" false
        (contains refusal.Decoder.message "states/0/count at states/0/count")

(* Deadline cells, mechanism level. The deadline is an absolute time and a pass
   takes its clock as a parameter, so a cell scripts the expiry at an exact
   node and asserts a node count instead of measuring a duration. The counters
   in Decoder.deadline_stats are that surface: one deadline check per visited
   value node, and one node count per visited node. *)

let list_trace elements =
  let buffer = Buffer.create ((4 * elements) + 96) in
  Buffer.add_string buffer
    "{\"vars\":[\"v\"],\"states\":[{\"#meta\":{\"index\":0},\"v\":[";
  for index = 0 to elements - 1 do
    if index > 0 then Buffer.add_char buffer ',';
    Buffer.add_string buffer "\"x\""
  done;
  Buffer.add_string buffer "]}]}";
  Buffer.contents buffer

let list_parsed elements =
  match Decoder.preparse (list_trace elements) with
  | Error refusal ->
      Alcotest.fail
        ("the deadline fixture did not preparse: " ^ refusal.Decoder.message)
  | Ok parsed -> parsed

(* The typed pass enters the list and each of its members once for the decode
   and once for the type check, so its node count follows from the input shape:
   a sampling tick lowers the tick count, and a recursion site that stopped
   consulting the deadline lowers the tick count against the node count. *)
let test_deadline_ticks_match_nodes () =
  let elements = 1000 in
  let parsed = list_parsed elements in
  let clock_reads = ref 0 in
  let now () =
    incr clock_reads;
    0.0
  in
  let stats = Decoder.fresh_stats () in
  let decls = [ ("v", Ir_types.List Ir_types.Str) ] in
  (match
     Decoder.decode_typed_at ~now ~stats ~deadline_at:1000.0 ~decls parsed
   with
  | Error refusal ->
      Alcotest.fail
        ("the typed descent refused inside its deadline: "
       ^ refusal.Decoder.message)
  | Ok trace ->
      Alcotest.(check int)
        "one state decodes" 1
        (List.length trace.Decoder.states));
  let nodes = 2 * (elements + 1) in
  Alcotest.(check int) "visited nodes" nodes stats.Decoder.nodes;
  Alcotest.(check int) "ticks fired" nodes stats.Decoder.ticks;
  Alcotest.(check bool)
    "every tick reads the clock" true
    (!clock_reads >= stats.Decoder.ticks)

(* The structural pass enters the list and each member once. *)
let test_structural_ticks_match_nodes () =
  let elements = 1000 in
  let parsed = list_parsed elements in
  let stats = Decoder.fresh_stats () in
  (match
     Decoder.decode_structural_at
       ~now:(fun () -> 0.0)
       ~stats ~deadline_at:1000.0 ~names:[ "v" ] parsed
   with
  | Error refusal ->
      Alcotest.fail
        ("the structural pass refused inside its deadline: "
       ^ refusal.Decoder.message)
  | Ok () -> ());
  let nodes = elements + 1 in
  Alcotest.(check int) "visited nodes" nodes stats.Decoder.nodes;
  Alcotest.(check int) "ticks fired" nodes stats.Decoder.ticks

(* A deadline that has already passed at the first read refuses before any node
   is visited: the pin never depends on how long a node takes to run. *)
let test_expired_deadline_refuses_before_the_first_node () =
  let parsed = list_parsed 1000 in
  let stats = Decoder.fresh_stats () in
  let decls = [ ("v", Ir_types.List Ir_types.Str) ] in
  match
    Decoder.decode_typed_at
      ~now:(fun () -> 5.0)
      ~stats ~deadline_at:5.0 ~decls parsed
  with
  | Ok _ -> Alcotest.fail "the typed descent completed past its deadline"
  | Error refusal ->
      Alcotest.(check string) "stage decode" "decode" refusal.Decoder.stage;
      Alcotest.(check int) "class 0" 0 refusal.Decoder.klass;
      Alcotest.(check bool)
        "the phase boundary is the checkpoint" true
        (contains refusal.Decoder.message "before the typed value phase");
      Alcotest.(check int) "no node is visited" 0 stats.Decoder.nodes;
      Alcotest.(check int) "no tick fires" 0 stats.Decoder.ticks

(* Expiry fires at the first node check after the clock passes the deadline.
   The clock returns the start value for [live] reads and a past-deadline value
   after that. Reads 1 and 2 are the phase and state boundaries, so read 3 is
   the first node and the run stops at the node whose check found the expiry,
   [live - 1]. Two runs one read apart differ by one node, which is the
   overshoot bound measured in nodes. *)
let typed_expiry_nodes elements live =
  let parsed = list_parsed elements in
  let reads = ref 0 in
  let now () =
    incr reads;
    if !reads > live then 1000.0 else 0.0
  in
  let stats = Decoder.fresh_stats () in
  let decls = [ ("v", Ir_types.List Ir_types.Str) ] in
  match Decoder.decode_typed_at ~now ~stats ~deadline_at:10.0 ~decls parsed with
  | Ok _ -> Alcotest.fail "the typed descent completed past its deadline"
  | Error refusal ->
      Alcotest.(check string) "stage decode" "decode" refusal.Decoder.stage;
      Alcotest.(check int) "class 0" 0 refusal.Decoder.klass;
      Alcotest.(check bool)
        "the value descent is the checkpoint" true
        (contains refusal.Decoder.message "during the value descent");
      (stats.Decoder.nodes, stats.Decoder.ticks)

let test_deadline_overshoot_is_one_node () =
  let nodes, ticks = typed_expiry_nodes 1000 10 in
  Alcotest.(check int) "the expiry lands on the ninth node" 9 nodes;
  Alcotest.(check int) "one tick per node" nodes ticks;
  let next_nodes, _ = typed_expiry_nodes 1000 11 in
  Alcotest.(check int)
    "one further clock read visits exactly one further node" (nodes + 1)
    next_nodes

(* Retired cell: the measured-control deadline test. Its input and its
   expected expiry were both derived from a wall-clock measurement; the
   replacement cells assert node counts against a scripted clock. *)

(* The gate names the missing member. *)
let remove_member key = function
  | Json_ast.Object fields -> Json_ast.Object (List.remove_assoc key fields)
  | other -> other

let test_gate_names_the_missing_member () =
  let root, corpus, manifest, hand, records, _ =
    Gate_cases.registry_copies ()
  in
  Gate_cases.mutate_record
    (Filename.concat records
       "impl-resolution--implResolution--probeAtMostOnce.json")
    (remove_member "command");
  let capture = Gate_cases.run_gate_in ~root [ corpus; manifest; hand ] in
  Alcotest.(check bool) "exit 2" true (capture.Proc.status = Some 2);
  Gate_cases.check_counts_and_marker "missing command" capture;
  Alcotest.(check bool)
    "the missing member is named" true
    (contains capture.output "the command member is missing");
  Alcotest.(check bool)
    "the imports member is not blamed" false
    (contains capture.output "the imports member is not a JSON object")

(* A duplicate IR table key fails closed through the unresolved
   path, which the decoder refuses as class 13. *)
let duplicate_first_table_key ir =
  match ir with
  | Json_ast.Object members -> (
      match List.assoc_opt "table" members with
      | Some (Json_ast.Object rows) -> (
          match rows with
          | (key, entry) :: _ ->
              let rows = (key, entry) :: rows in
              Json_ast.Object
                (("table", Json_ast.Object rows)
                :: List.remove_assoc "table" members)
          | [] -> ir)
      | _ -> ir)
  | _ -> ir

let test_duplicate_table_key_fails_closed () =
  let spec = Filename.concat (fixtures ()) "plain-pass.qnt" in
  let trace = Filename.concat (fixtures ()) "plain-pass.itf.json" in
  let ir =
    match Corpus_support.ir_for spec with
    | Some ir -> ir
    | None -> Alcotest.fail "the fixture specification did not parse to an IR"
  in
  let crafted = duplicate_first_table_key ir in
  let rows =
    match crafted with
    | Json_ast.Object members -> (
        match List.assoc_opt "table" members with
        | Some (Json_ast.Object rows) -> rows
        | _ -> [])
    | _ -> []
  in
  let key =
    match rows with
    | (key, _) :: _ -> key
    | [] -> Alcotest.fail "the IR table is empty"
  in
  Alcotest.(check int)
    "the crafted IR carries the key twice" 2
    (List.length (List.filter (fun (name, _) -> name = key) rows));
  match Resolver.variable_decls crafted ~main:"Plain" with
  | Error message ->
      Alcotest.fail ("the crafted IR refused at resolve: " ^ message)
  | Ok decls -> (
      match Decoder.decode ~decls (Corpus_support.read_file trace) with
      | Ok _ -> Alcotest.fail "the duplicate table key resolved last-wins"
      | Error refusal ->
          Alcotest.(check string) "stage decode" "decode" refusal.Decoder.stage;
          Alcotest.(check int) "class 13" 13 refusal.Decoder.klass;
          Alcotest.(check bool)
            "the duplicated key is named" true
            (contains refusal.Decoder.message key))

(* The totality property reaches the typed-phase classes. *)
let test_totality_reaches_typed_classes () =
  let reached =
    Decoder_property.totality_classes ~cases:200 Property_support.default_seed
  in
  let required = [ 5; 9; 10; 11; 12; 13; 16 ] in
  List.iter
    (fun klass ->
      Alcotest.(check bool)
        (Printf.sprintf "the generator reaches class %d" klass)
        true (List.mem klass reached))
    required

let suite =
  [
    Alcotest.test_case "structural refusals precede resolution" `Quick
      test_structural_refusals_precede_resolution;
    Alcotest.test_case "one JSON path per diagnostic" `Quick
      test_single_json_path;
    Alcotest.test_case "deadline ticks match visited nodes" `Quick
      test_deadline_ticks_match_nodes;
    Alcotest.test_case "structural ticks match visited nodes" `Quick
      test_structural_ticks_match_nodes;
    Alcotest.test_case "an expired deadline refuses before the first node"
      `Quick test_expired_deadline_refuses_before_the_first_node;
    Alcotest.test_case "the deadline overshoot is one node" `Quick
      test_deadline_overshoot_is_one_node;
    Alcotest.test_case "gate names the missing member" `Quick
      test_gate_names_the_missing_member;
    Alcotest.test_case "duplicate table key fails closed" `Quick
      test_duplicate_table_key_fails_closed;
    Alcotest.test_case "totality reaches the typed classes" `Quick
      test_totality_reaches_typed_classes;
  ]
