(* Seed-controlled decoder properties: totality, integer normalisation
   round-trip and report determinism. Each run prints its seed, records a
   verdict digest for the same-seed comparison, and shrinks the first failing
   mutant input into a replay record. Licence: AGPL-3.0-or-later; see
   README.md. *)

type report = {
  seed : int;
  cases : int;
  failures : int;
  input_digest : string;
  verdict_digest : string;
  first_replay : string option;
  first_error : string option;
}

let first_existing candidates =
  match List.find_opt Sys.file_exists candidates with
  | Some path -> path
  | None ->
      failwith ("none of these paths exists: " ^ String.concat ", " candidates)

let fixtures_dir () =
  first_existing [ "fixtures"; "../fixtures"; "../../fixtures" ]

let read_file path =
  let channel = open_in_bin path in
  let length = in_channel_length channel in
  let text = really_input_string channel length in
  close_in channel;
  text

(* One generic runner: generate the cases, record the verdicts, and when a
   case fails, shrink it with QCheck and keep the first replay record. *)

let run ~cases ~seed ~gen ~print ~shrink ~verdict =
  let generated =
    QCheck.Gen.generate ~rand:(Random.State.make [| seed |]) ~n:cases gen
  in
  let input_digest = Buffer.create 8192 in
  let verdict_digest = Buffer.create 8192 in
  let failures = ref 0 in
  let first = ref None in
  let first_error = ref None in
  List.iter
    (fun case ->
      Buffer.add_string input_digest (print case);
      Buffer.add_char input_digest '\n';
      match verdict case with
      | Ok () -> Buffer.add_string verdict_digest "ok\n"
      | Error message ->
          incr failures;
          if !first = None then first := Some (print case);
          if !first_error = None then first_error := Some message;
          Buffer.add_string verdict_digest ("error:" ^ message ^ "\n"))
    generated;
  let first_replay =
    if !failures = 0 then None
    else begin
      let arbitrary = QCheck.make ~print ~shrink gen in
      let cell =
        QCheck.Test.make_cell ~count:cases ~name:"decoder-property" arbitrary
          (fun case -> verdict case = Ok ())
      in
      let result =
        QCheck.Test.check_cell ~rand:(Random.State.make [| seed |]) cell
      in
      match QCheck.TestResult.get_state result with
      | QCheck.TestResult.Failed { instances = first :: _ } ->
          Some (first.QCheck.TestResult.instance |> print)
      | QCheck.TestResult.Error { instance; _ } ->
          Some (instance.QCheck.TestResult.instance |> print)
      | _ -> !first
    end
  in
  {
    seed;
    cases;
    failures = !failures;
    input_digest = Sha256.hex (Buffer.contents input_digest);
    verdict_digest = Sha256.hex (Buffer.contents verdict_digest);
    first_replay;
    first_error = !first_error;
  }

let print_report name report =
  Printf.printf "property %s seed: %d\n" name report.seed;
  Printf.printf "property %s: cases=%d failures=%d inputs=%s verdicts=%s\n" name
    report.cases report.failures report.input_digest report.verdict_digest;
  (match report.first_error with
  | None -> ()
  | Some message -> Printf.printf "property %s failure: %s\n" name message);
  match report.first_replay with
  | None -> ()
  | Some replay ->
      Printf.printf "property %s replay case (seed=%d): %s\n" name report.seed
        replay

(* Totality: every byte sequence, and every structurally valid trace the
   generated declaration list names, yields a decoded trace or a refusal whose
   class is in the closed set 1 to 16. The structured arm generates the
   declaration list alongside the trace so the typed-phase classes are
   reachable. *)

type totality_case = {
  declarations : (string * Ir_types.ty) list;
  raw : string;
}

let gen_byte state = QCheck.Gen.int_range 0 255 state

let gen_bytes state =
  let length = QCheck.Gen.int_range 0 64 state in
  let bytes = Bytes.create length in
  for index = 0 to length - 1 do
    Bytes.set bytes index (Char.chr (gen_byte state))
  done;
  Bytes.to_string bytes

let scalar_types = [ Ir_types.Int; Ir_types.Str; Ir_types.Bool ]
let gen_scalar_type state = QCheck.Gen.oneof_list scalar_types state

let gen_type depth state =
  if depth <= 0 then gen_scalar_type state
  else
    QCheck.Gen.oneof
      [
        gen_scalar_type;
        QCheck.Gen.map (fun elem -> Ir_types.List elem) gen_scalar_type;
        QCheck.Gen.map
          (fun (left, right) -> Ir_types.Record [ ("a", left); ("b", right) ])
          (QCheck.Gen.pair gen_scalar_type gen_scalar_type);
        QCheck.Gen.map
          (fun payload ->
            Ir_types.Variant [ ("Red", payload); ("Green", payload) ])
          gen_scalar_type;
      ]
      state

let gen_declarations state =
  let seen = Hashtbl.create 4 in
  let declarations =
    QCheck.Gen.list_size (QCheck.Gen.int_range 1 2)
      (QCheck.Gen.pair (QCheck.Gen.oneof_list [ "a"; "b"; "v" ]) (gen_type 1))
      state
  in
  List.filter
    (fun (name, _) ->
      if Hashtbl.mem seen name then false
      else begin
        Hashtbl.add seen name ();
        true
      end)
    declarations

let rec gen_value depth state =
  let leaf =
    QCheck.Gen.oneof
      [
        QCheck.Gen.map (fun value -> Json_ast.Bool value) QCheck.Gen.bool;
        QCheck.Gen.oneof_list
          [
            Json_ast.String "x";
            Json_ast.String "";
            Json_ast.Null;
            Json_ast.Number "7";
            Json_ast.Object [ ("#bigint", Json_ast.String "1") ];
            Json_ast.Object [ ("#bigint", Json_ast.Number "1") ];
            Json_ast.Object [ ("#bogus", Json_ast.String "x") ];
            Json_ast.Object [ ("#unserializable", Json_ast.String "x") ];
            Json_ast.Object
              [ ("a", Json_ast.String "1"); ("a", Json_ast.String "2") ];
            Json_ast.Object
              [ ("tag", Json_ast.String "Red"); ("value", Json_ast.String "x") ];
            Json_ast.Object [ ("tag", Json_ast.String "UNIT") ];
            Json_ast.Object
              [
                ("s", Json_ast.String "1");
                ("e", Json_ast.String "15");
                ("c", Json_ast.String "9");
              ];
          ];
      ]
      state
  in
  if depth <= 0 then leaf
  else
    QCheck.Gen.oneof
      [
        QCheck.Gen.return leaf;
        QCheck.Gen.map
          (fun items -> Json_ast.Array items)
          (QCheck.Gen.list_size (QCheck.Gen.int_range 0 3)
             (gen_value (depth - 1)));
        QCheck.Gen.map
          (fun items -> Json_ast.Object [ ("#tup", Json_ast.Array items) ])
          (QCheck.Gen.list_size (QCheck.Gen.int_range 0 3)
             (gen_value (depth - 1)));
        QCheck.Gen.map
          (fun entries -> Json_ast.Object [ ("#map", Json_ast.Array entries) ])
          (QCheck.Gen.list_size (QCheck.Gen.int_range 0 3)
             (QCheck.Gen.map
                (fun value -> Json_ast.Array [ Json_ast.String "k"; value ])
                (gen_value (depth - 1))));
        QCheck.Gen.map
          (fun members -> Json_ast.Object members)
          (QCheck.Gen.list_size (QCheck.Gen.int_range 0 3)
             (QCheck.Gen.pair
                (QCheck.Gen.oneof_list [ "a"; "b"; "tag"; "#set"; "extra" ])
                (gen_value (depth - 1))));
      ]
      state

let anomalies_for = function
  | Ir_types.Int ->
      [ "malformed-bigint"; "bare-number"; "unknown-hash"; "unserializable" ]
  | Ir_types.Record _ -> [ "record-collision"; "record-unit"; "unknown-hash" ]
  | Ir_types.List _ | Ir_types.Set _ ->
      [ "bare-number"; "unknown-hash"; "unserializable" ]
  | _ -> [ "unknown-hash"; "unserializable"; "bare-number" ]

let anomaly_value = function
  | "malformed-bigint" ->
      Json_ast.Object
        [
          ("s", Json_ast.String "1");
          ("e", Json_ast.String "15");
          ("c", Json_ast.String "9");
        ]
  | "record-collision" ->
      Json_ast.Object
        [ ("tag", Json_ast.String "Red"); ("value", Json_ast.String "x") ]
  | "record-unit" -> Json_ast.Object [ ("tag", Json_ast.String "UNIT") ]
  | "unknown-hash" -> Json_ast.Object [ ("#bogus", Json_ast.String "x") ]
  | "unserializable" ->
      Json_ast.Object [ ("#unserializable", Json_ast.String "x") ]
  | _ -> Json_ast.Number "7"

let gen_structured state =
  let declarations = gen_declarations state in
  let names = List.map fst declarations in
  let probe_shape =
    match declarations with
    | (_, ty) :: _ -> QCheck.Gen.oneof_list ("none" :: anomalies_for ty) state
    | [] -> "none"
  in
  let missing = QCheck.Gen.oneof_list ("" :: names) state in
  let state_count = QCheck.Gen.int_range 1 2 state in
  let state_document index =
    let members =
      List.mapi
        (fun position (name, _) ->
          let value =
            if position = 0 && probe_shape <> "none" then
              anomaly_value probe_shape
            else gen_value 2 state
          in
          (name, value))
        declarations
    in
    let members =
      if index = 0 && missing <> "" then List.remove_assoc missing members
      else members
    in
    Json_ast.Object
      (( "#meta",
         Json_ast.Object [ ("index", Json_ast.Number (string_of_int index)) ] )
      :: members)
  in
  let states = List.init state_count state_document in
  let vars = if QCheck.Gen.bool state then names else names @ [ "extra" ] in
  let document =
    Json_ast.Object
      [
        ("#meta", Json_ast.Object [ ("status", Json_ast.String "ok") ]);
        ( "vars",
          Json_ast.Array (List.map (fun name -> Json_ast.String name) vars) );
        ("states", Json_ast.Array states);
      ]
  in
  { declarations; raw = Json_writer.to_string document }

let gen_totality state =
  if QCheck.Gen.bool state then { declarations = []; raw = gen_bytes state }
  else gen_structured state

let shrink_totality case =
  let length = String.length case.raw in
  let candidates =
    List.filter_map
      (fun size ->
        if size < length then
          Some { case with raw = String.sub case.raw 0 size }
        else None)
      [ 0; length / 2; max 0 (length - 1) ]
  in
  QCheck.Iter.of_list candidates

let totality_verdict ~mutant case =
  if mutant then Error "mutant: the decoder raised"
  else
    try
      match Decoder.decode ~decls:case.declarations case.raw with
      | Ok _ -> Ok ()
      | Error refusal ->
          if
            refusal.Decoder.stage = "decode"
            && refusal.Decoder.klass >= 1
            && refusal.Decoder.klass <= 16
          then Ok ()
          else
            Error
              (Printf.sprintf "refusal class %d is outside 1..16"
                 refusal.Decoder.klass)
    with exception_ ->
      Error ("exception escaped: " ^ Printexc.to_string exception_)

let render_decls declarations =
  String.concat ","
    (List.map
       (fun (name, ty) ->
         Printf.sprintf "%s:%s" name
           (match ty with
           | Ir_types.Int -> "int"
           | Ir_types.Str -> "str"
           | Ir_types.Bool -> "bool"
           | Ir_types.List _ -> "list"
           | Ir_types.Set _ -> "set"
           | Ir_types.Tuple _ -> "tup"
           | Ir_types.Map _ -> "map"
           | Ir_types.Record _ -> "rec"
           | Ir_types.Variant _ -> "sum"
           | Ir_types.Unresolved _ -> "unresolved"))
       declarations)

let run_totality ?(mutant = false) ?(cases = 200) seed =
  run ~cases ~seed ~gen:gen_totality
    ~print:(fun case ->
      Printf.sprintf "%S decls=[%s]" case.raw (render_decls case.declarations))
    ~shrink:shrink_totality ~verdict:(totality_verdict ~mutant)

(* Reach of the totality generator: the classes the generated cases
   exercise, so the closed-set claim is substantiated by the property. *)
let totality_classes ?(cases = 200) seed =
  let generated =
    QCheck.Gen.generate
      ~rand:(Random.State.make [| seed |])
      ~n:cases gen_totality
  in
  let classes = ref [] in
  List.iter
    (fun case ->
      match Decoder.decode ~decls:case.declarations case.raw with
      | Ok _ -> ()
      | Error refusal -> classes := refusal.Decoder.klass :: !classes)
    generated;
  List.sort_uniq compare !classes

(* Normalisation round-trip: the chunk form of any nonzero signed 64-bit value
   normalises to its canonical decimal text, and the decimal form is unchanged.
   The endpoints are generated explicitly; zero is excluded from the chunk arm
   because the chunk form cannot represent it. *)

type roundtrip_case = { value : int64; chunk : bool }

let endpoint_values = [ Int64.min_int; Int64.max_int; 0L; 1L; -1L; 42L; -42L ]

let gen_roundtrip state =
  let value =
    if QCheck.Gen.bool state then QCheck.Gen.oneof_list endpoint_values state
    else QCheck.Gen.int64 state
  in
  let chunk = value <> 0L && QCheck.Gen.bool state in
  { value; chunk }

let shrink_roundtrip case =
  (* Every candidate is the zero case, and zero shrinks no further, so the
     shrink search is acyclic. *)
  QCheck.Iter.of_list
    (if case = { value = 0L; chunk = false } then []
     else [ { value = 0L; chunk = false } ])

let trace_json ~value =
  Json_ast.Object
    [
      ("#meta", Json_ast.Object [ ("format", Json_ast.String "ITF") ]);
      ("vars", Json_ast.Array [ Json_ast.String "v" ]);
      ("states", Json_ast.Array [ Json_ast.Object [ ("v", value) ] ]);
    ]

let decode_int_value raw =
  match Decoder.decode ~decls:[ ("v", Ir_types.Int) ] raw with
  | Error refusal -> Error refusal.Decoder.message
  | Ok trace -> (
      match List.hd trace.Decoder.states with
      | state -> (
          match List.assoc_opt "v" state.Decoder.values with
          | Some (Itf_value.Int text) -> Ok text
          | _ -> Error "the decoded value is not an integer"))

let roundtrip_verdict ~mutant case =
  let expected = Int64.to_string case.value in
  let json_value =
    if case.chunk then Evaluator_property.s_e_c expected
    else Json_ast.Object [ ("#bigint", Json_ast.String expected) ]
  in
  let raw = Json_writer.to_string (trace_json ~value:json_value) in
  match decode_int_value raw with
  | Error message -> Error message
  | Ok actual ->
      let actual = if mutant then actual ^ "0" else actual in
      if actual = expected then Ok ()
      else Error (Printf.sprintf "expected %s, got %s" expected actual)

let run_roundtrip ?(mutant = false) ?(cases = 200) seed =
  run ~cases ~seed ~gen:gen_roundtrip
    ~print:(fun case ->
      Printf.sprintf "%s:%s"
        (Int64.to_string case.value)
        (if case.chunk then "chunk" else "decimal"))
    ~shrink:shrink_roundtrip
    ~verdict:(roundtrip_verdict ~mutant)

(* Report determinism: two runs over the same input render byte-identical
   reports in both formats. The cases are a sample of the committed fixture
   corpus plus small random traces. *)

type determinism_case =
  | Fixture of {
      label : string;
      path : string;
      decls : (string * Ir_types.ty) list;
    }
  | Random of {
      label : string;
      raw : string;
      decls : (string * Ir_types.ty) list;
    }

let fixture_cases =
  [
    Fixture
      {
        label = "plain-pass";
        path = "plain-pass.itf.json";
        decls = [ ("count", Ir_types.Int); ("log", Ir_types.List Ir_types.Int) ];
      };
    Fixture
      {
        label = "hand-pass";
        path = "hand-verified/hand-pass.itf.json";
        decls = [ ("count", Ir_types.Int) ];
      };
  ]

let gen_random_determinism state =
  let ty =
    QCheck.Gen.oneof_list [ Ir_types.Int; Ir_types.Str; Ir_types.Bool ] state
  in
  let value state =
    match ty with
    | Ir_types.Int ->
        QCheck.Gen.map
          (fun number ->
            Json_ast.Object
              [ ("#bigint", Json_ast.String (string_of_int number)) ])
          (QCheck.Gen.int_range 0 999)
          state
    | Ir_types.Str ->
        QCheck.Gen.map
          (fun text -> Json_ast.String text)
          (QCheck.Gen.string_size ~gen:QCheck.Gen.char_printable
             (QCheck.Gen.int_range 0 8))
          state
    | _ ->
        QCheck.Gen.map (fun value -> Json_ast.Bool value) QCheck.Gen.bool state
  in
  let count = QCheck.Gen.int_range 1 4 state in
  let states =
    List.init count (fun _ -> Json_ast.Object [ ("v", value state) ])
  in
  let raw =
    Json_writer.to_string
      (Json_ast.Object
         [
           ("vars", Json_ast.Array [ Json_ast.String "v" ]);
           ("states", Json_ast.Array states);
         ])
  in
  Random { label = "random"; raw; decls = [ ("v", ty) ] }

let gen_determinism state =
  if QCheck.Gen.bool state then QCheck.Gen.oneof_list fixture_cases state
  else gen_random_determinism state

let shrink_determinism _ = QCheck.Iter.of_list []

let source_of_case = function
  | Fixture { path; _ } -> read_file (Filename.concat (fixtures_dir ()) path)
  | Random { raw; _ } -> raw

let decls_of_case = function
  | Fixture { decls; _ } | Random { decls; _ } -> decls

let label_of_case = function
  | Fixture { label; _ } -> label
  | Random { label; _ } -> label

let render_once ~decls ~mutant raw =
  match Decoder.decode ~decls raw with
  | Error refusal -> Error refusal.Decoder.message
  | Ok trace ->
      let result =
        {
          Check.rows = [ { Check.name = "inv"; outcome = Check.Fail 0 } ];
          evaluations = 1;
        }
      in
      let rows = Report.build_rows ~trace ~variables:decls result in
      let input =
        {
          Report.spec_path = "spec.qnt";
          main = "M";
          quint_version = Quint.pinned_version;
          ir_sha256 = Sha256.hex "ir";
          trace_path = "trace.itf.json";
          trace;
          evaluator =
            { Evaluator.path = "evaluator"; sha256 = Sha256.hex "evaluator" };
          rows;
        }
      in
      let rendered =
        Report.json_string input ^ "\n"
        ^ String.concat "\n" (Report.human_lines input)
      in
      Ok (if mutant then rendered ^ "mutant" else rendered)

let first_difference left right =
  let length = min (String.length left) (String.length right) in
  let rec scan index =
    if index >= length then index
    else if left.[index] <> right.[index] then index
    else scan (index + 1)
  in
  let at = scan 0 in
  let excerpt text =
    let start = max 0 (at - 20) in
    let stop = min (String.length text) (at + 40) in
    String.sub text start (stop - start)
  in
  Printf.sprintf "first difference at byte %d: %S vs %S" at (excerpt left)
    (excerpt right)

let determinism_verdict ~mutant case =
  let raw = source_of_case case in
  let decls = decls_of_case case in
  match render_once ~decls ~mutant:false raw with
  | Error message -> Error message
  | Ok first -> (
      match render_once ~decls ~mutant:false raw with
      | Error message -> Error message
      | Ok second ->
          let second = if mutant then second ^ "mutant" else second in
          if first = second then Ok ()
          else Error ("the two runs differ: " ^ first_difference first second))

let run_determinism ?(mutant = false) ?(cases = 20) seed =
  run ~cases ~seed ~gen:gen_determinism
    ~print:(fun case ->
      Printf.sprintf "%s:%S" (label_of_case case) (source_of_case case))
    ~shrink:shrink_determinism
    ~verdict:(determinism_verdict ~mutant)
