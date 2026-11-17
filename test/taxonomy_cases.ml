(* Regression cells: the time-sampled descent deadline, the s/e/c member
   descent without a structural classification, the legal record values a
   shape-based classification would refuse, and the duplicate table key
   refused without a reaching declaration.
   Licence: AGPL-3.0-or-later; see README.md. *)

let contains = Corpus_support.contains_sub
let fixtures () = Corpus_support.fixtures_dir ()

let regressions () =
  Corpus_support.first_existing
    [
      "test/regressions/record-values";
      "../test/regressions/record-values";
      "../../test/regressions/record-values";
    ]

let stage_named = Evaluator_cases.stage_named

let run_binary args =
  Proc.run_combined ~timeout:300.0
    (Array.of_list (Evaluator_cases.binary () :: args))

let write_file path text =
  let channel = open_out_bin path in
  output_string channel text;
  close_out channel

let check_refusal label capture klass path =
  Alcotest.(check bool) (label ^ ": exit 2") true (capture.Proc.status = Some 2);
  Alcotest.(check bool)
    (label ^ ": stage decode") true
    (stage_named "decode" capture.output);
  Alcotest.(check bool)
    (label ^ ": resolution is not reached")
    false
    (stage_named "resolve" capture.output);
  Alcotest.(check bool)
    (label ^ ": class " ^ string_of_int klass)
    true
    (contains capture.output (Printf.sprintf "class %d" klass));
  Alcotest.(check bool)
    (label ^ ": path " ^ path)
    true
    (contains capture.output path)

(* A #bogus member under the exact-three s/e/c shape is
   reached by the structural walk even when the main module is absent; the
   s,e,d control and a legal chunk form stay green. *)
let test_chunk_members_reach_the_stage_hole () =
  let rec3 = Filename.concat (regressions ()) "rec3.qnt" in
  let rec3_trace = Filename.concat (regressions ()) "rec3-bogus.json" in
  let rec3d = Filename.concat (regressions ()) "rec3d.qnt" in
  let rec3d_trace = Filename.concat (regressions ()) "rec3d-bogus.json" in
  let run spec trace main =
    run_binary
      [
        spec;
        trace;
        "--main=" ^ main;
        "--invariant=ok";
        "--deadline=30";
        "--timeout=5";
      ]
  in
  List.iter
    (fun main ->
      check_refusal ("rec3 " ^ main) (run rec3 rec3_trace main) 9 "states/0/p/s")
    [ "Absent"; "Rec3" ];
  List.iter
    (fun main ->
      check_refusal ("rec3d " ^ main)
        (run rec3d rec3d_trace main)
        9 "states/0/p/s")
    [ "Absent"; "Rec3d" ];
  let legal =
    run_binary
      [
        Filename.concat (fixtures ()) "bigint-10e15.qnt";
        Filename.concat (fixtures ()) "bigint-10e15.itf.json";
        "--main=BigValue";
        "--invariant=exact";
        "--deadline=30";
        "--timeout=5";
      ]
  in
  Alcotest.(check bool)
    "a legal chunk form still decodes" true
    (legal.Proc.status = Some 0);
  Alcotest.(check bool)
    "a legal chunk form still passes" true
    (contains legal.output "Summary: 1 pass, 0 fail")

(* The structural walk descends a s/e/c object as ordinary record
   fields and classifies nothing, so the refusal taxonomy splits at the member
   path. A non-decimal #bigint member is class 10 at its own path under both
   mains; a
   chunk form whose members pass the type-independent checks keeps class 12
   where the resolved type is int, and its absent-main control reports the
   resolve refusal. A standalone #bigint keeps class 10. *)
let test_chunk_taxonomy_splits_at_the_member_path () =
  let moved_spec = Filename.concat (fixtures ()) "bigint-s-noncanonical.qnt" in
  let moved_trace =
    Filename.concat (fixtures ()) "bigint-s-noncanonical.itf.json"
  in
  List.iter
    (fun main ->
      let capture =
        run_binary
          [
            moved_spec;
            moved_trace;
            "--main=" ^ main;
            "--invariant=ok";
            "--deadline=30";
            "--timeout=5";
          ]
      in
      check_refusal ("bigint-s-noncanonical " ^ main) capture 10 "states/0/x/s";
      Alcotest.(check bool)
        ("the member is the refusal site under " ^ main)
        true
        (contains capture.output
           "#bigint at states/0/x/s is not a decimal string"))
    [ "BigRefusal"; "Absent" ];
  let pin_spec = Filename.concat (fixtures ()) "bigint-s-two-chunk.qnt" in
  let pin_trace = Filename.concat (fixtures ()) "bigint-s-two-chunk.itf.json" in
  let pin =
    run_binary
      [
        pin_spec;
        pin_trace;
        "--main=BigRefusal";
        "--invariant=ok";
        "--deadline=30";
        "--timeout=5";
      ]
  in
  check_refusal "bigint-s-two-chunk BigRefusal" pin 12 "states/0/x";
  Alcotest.(check bool)
    "the sign field is named by the typed phase" true
    (contains pin.output "field s sign text 2 is not canonical");
  let absent =
    run_binary
      [
        pin_spec;
        pin_trace;
        "--main=Absent";
        "--invariant=ok";
        "--deadline=30";
        "--timeout=5";
      ]
  in
  Alcotest.(check bool)
    "the absent-main control exits 2" true
    (absent.Proc.status = Some 2);
  Alcotest.(check bool)
    "the absent-main control reports resolve" true
    (stage_named "resolve" absent.output);
  Alcotest.(check bool)
    "the absent-main control is not a decode refusal" false
    (stage_named "decode" absent.output);
  let directory = Evaluator_cases.temp_dir () in
  let standalone =
    Filename.concat directory "taxonomy-standalone-bigint.itf.json"
  in
  write_file standalone
    "{\"vars\":[\"x\"],\"states\":[{\"#meta\":{\"index\":0},\"x\":{\"#bigint\":\"+1\"}}]}";
  let capture =
    run_binary
      [
        moved_spec;
        standalone;
        "--main=BigRefusal";
        "--invariant=ok";
        "--deadline=30";
        "--timeout=5";
      ]
  in
  check_refusal "standalone #bigint" capture 10 "states/0/x";
  Alcotest.(check bool)
    "the standalone class-10 text is kept" true
    (contains capture.output "not a decimal string")

(* An object carrying exactly s, e and c is a record at
   any non-int position, so a member spelling outside the chunk rule set is
   decoded as a value and never refused for its shape (R17). *)
let test_legal_record_values_are_accepted () =
  let cases =
    [
      ("record, s = 5", "recvalue.qnt", "recvalue-s5.itf.json", "RV");
      ("record, c = [-1]", "recvalue.qnt", "recvalue-cneg.itf.json", "RV");
      ("record, e = 01", "recvalue.qnt", "recvalue-enoncanon.itf.json", "RV");
      ("list of records", "recvalue-list.qnt", "recvalue-list.itf.json", "RL");
      ( "variant payload",
        "recvalue-variant.qnt",
        "recvalue-variant.itf.json",
        "RW" );
    ]
  in
  List.iter
    (fun (label, spec, trace, main) ->
      let capture =
        run_binary
          [
            Filename.concat (regressions ()) spec;
            Filename.concat (regressions ()) trace;
            "--main=" ^ main;
            "--invariant=ok";
            "--deadline=30";
            "--timeout=5";
          ]
      in
      Alcotest.(check bool)
        (label ^ ": exit 0") true
        (capture.Proc.status = Some 0);
      Alcotest.(check bool)
        (label ^ ": the record value passes")
        true
        (contains capture.output "Summary: 1 pass, 0 fail"))
    cases

(* Every node consults the deadline. A single state carrying a wide member name
   and 4,002 nodes pays the path construction per node, so the whole structural
   pass is one unchecked window under a node counter; the time-sampled tick
   refuses inside it. The clock is scripted, so the node the expiry lands on is
   exact: read 1 is the state boundary, read 2 is the first node, and a
   sampling tick would refuse thousands of nodes later instead of one. *)
let wide_name_trace ?(width = 1024 * 1024) ?(nodes = 4002) () =
  let buffer = Buffer.create ((nodes * 4) + width + 64) in
  Buffer.add_string buffer
    "{\"vars\":[\"l\"],\"states\":[{\"#meta\":{\"index\":0},\"l\":{\"";
  Buffer.add_string buffer (String.make width 'k');
  Buffer.add_string buffer "\":[";
  for index = 0 to nodes - 1 do
    if index > 0 then Buffer.add_char buffer ',';
    Buffer.add_string buffer "\"x\""
  done;
  Buffer.add_string buffer "]}}]}";
  Buffer.contents buffer

let test_descent_deadline_is_time_sampled () =
  match Decoder.preparse (wide_name_trace ()) with
  | Error refusal ->
      Alcotest.fail
        ("the wide-name trace did not preparse: " ^ refusal.Decoder.message)
  | Ok parsed ->
      let live = 1002 in
      let reads = ref 0 in
      let now () =
        incr reads;
        if !reads > live then 1000.0 else 0.0
      in
      let stats = Decoder.fresh_stats () in
      let result =
        Decoder.decode_structural_at ~now ~stats ~deadline_at:10.0
          ~names:[ "l" ] parsed
      in
      (match result with
      | Ok () -> Alcotest.fail "the structural pass completed past its deadline"
      | Error refusal ->
          Alcotest.(check string) "stage decode" "decode" refusal.Decoder.stage;
          Alcotest.(check int) "class 0" 0 refusal.Decoder.klass;
          Alcotest.(check bool)
            "the value descent is the checkpoint" true
            (contains refusal.Decoder.message "during the value descent"));
      Alcotest.(check int)
        "the expiry lands on the node the clock names" live stats.Decoder.nodes;
      Alcotest.(check int)
        "one deadline check per visited node" stats.Decoder.nodes
        stats.Decoder.ticks

(* Pinned expiry cells, end to end: a wide member name and enough nodes that
   the decode cannot finish inside the deadline. Every node builds a path from
   the whole member name, so the deadline is exceeded by a wide margin: 100,000
   nodes at 4 MiB and 40,002 at 16 MiB are minutes of work on this machine
   against a 10 s deadline, and load only brings the refusal forward. The
   deadline also bounds the specification parse, so it is set well above the
   parse cost rather than at the minimum; the expiry stage is what the cell
   pins. *)
let test_wide_name_expiry_is_pinned () =
  List.iter
    (fun (label, width, nodes) ->
      let directory = Evaluator_cases.temp_dir () in
      let trace = Filename.concat directory "taxonomy-wide-name.itf.json" in
      write_file trace (wide_name_trace ~width ~nodes ());
      let capture =
        run_binary
          [
            Filename.concat (fixtures ()) "shapes-rust.qnt";
            trace;
            "--main=Shapes";
            "--invariant=allThere";
            "--deadline=10";
            "--timeout=10";
          ]
      in
      Alcotest.(check bool)
        (label ^ ": exit 2") true
        (capture.Proc.status = Some 2);
      Alcotest.(check bool)
        (label ^ ": stage decode") true
        (stage_named "decode" capture.output);
      Alcotest.(check bool)
        (label ^ ": the deadline is named")
        true
        (contains capture.output
           "the deadline expired during the decode of the trace");
      Alcotest.(check bool)
        (label ^ ": resolution is not reached")
        false
        (stage_named "resolve" capture.output))
    [ ("4 MiB", 4 * 1024 * 1024, 100000); ("16 MiB", 16 * 1024 * 1024, 40002) ]

(* A duplicate IR table key is refused even when no declaration
   reaches it, at decode and in the class-13 family; the reachable case keeps
   its message. *)
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

let test_duplicate_key_refused_without_a_declaration () =
  let spec = Filename.concat (regressions ()) "collide.qnt" in
  let trace = Filename.concat (regressions ()) "collide.itf.json" in
  let ir =
    match Corpus_support.ir_for spec with
    | Some ir -> ir
    | None -> Alcotest.fail "the collide specification did not parse to an IR"
  in
  let crafted = duplicate_first_table_key ir in
  let duplicates = Resolver.duplicate_keys crafted in
  let key =
    match duplicates with
    | key :: _ -> key
    | [] -> Alcotest.fail "no duplicate key was recorded"
  in
  match Resolver.variable_decls crafted ~main:"RecB" with
  | Error message ->
      Alcotest.fail ("the no-vars main refused at resolve: " ^ message)
  | Ok decls -> (
      Alcotest.(check int)
        "the no-vars main declares nothing" 0 (List.length decls);
      (match
         Decoder.decode ~duplicates ~decls (Corpus_support.read_file trace)
       with
      | Ok _ -> Alcotest.fail "the no-vars duplicate key was accepted"
      | Error refusal ->
          Alcotest.(check string) "stage decode" "decode" refusal.Decoder.stage;
          Alcotest.(check int) "class 13" 13 refusal.Decoder.klass;
          Alcotest.(check bool)
            "the duplicated key is named" true
            (contains refusal.Decoder.message key));
      match Resolver.variable_decls crafted ~main:"Main" with
      | Error message ->
          Alcotest.fail ("the reachable main refused at resolve: " ^ message)
      | Ok decls -> (
          match
            Decoder.decode ~duplicates ~decls (Corpus_support.read_file trace)
          with
          | Ok _ -> Alcotest.fail "the reachable duplicate key was accepted"
          | Error refusal ->
              Alcotest.(check string)
                "reachable stage decode" "decode" refusal.Decoder.stage;
              Alcotest.(check int) "reachable class 13" 13 refusal.Decoder.klass;
              Alcotest.(check bool)
                "the reachable message is kept" true
                (contains refusal.Decoder.message
                   "the declared type of variable w in state 0 cannot be \
                    resolved")))

let suite =
  [
    Alcotest.test_case "chunk members reach the stage hole" `Quick
      test_chunk_members_reach_the_stage_hole;
    Alcotest.test_case "chunk taxonomy splits at the member path" `Quick
      test_chunk_taxonomy_splits_at_the_member_path;
    Alcotest.test_case "legal record values are accepted" `Quick
      test_legal_record_values_are_accepted;
    Alcotest.test_case "descent deadline is time-sampled" `Quick
      test_descent_deadline_is_time_sampled;
    Alcotest.test_case "wide-name expiry is pinned" `Slow
      test_wide_name_expiry_is_pinned;
    Alcotest.test_case "duplicate key refused without a declaration" `Quick
      test_duplicate_key_refused_without_a_declaration;
  ]
