(* Seed-controlled property over generated well-formed traces.

   The generator draws states, variables and invariants from the accepted
   value grammar. Every generated request must be well formed (integer values
   carry the normalised decimal form, the forwarded state carries an empty
   #meta, the expression array has one entry per invariant), and every
   generated evaluator response must map to a verdict row or an evaluation
   error, never an internal error. Licence: AGPL-3.0-or-later; see README.md. *)

type typed_value = { json : Json_ast.t; value : Itf_value.t }
type gvar = { gname : string; gty : Ir_types.ty }

type gtrace = {
  gvars : gvar list;
  gstates : typed_value list list;
  ginvariants : string list;
}

let int_range = QCheck.Gen.int_range

let rec row_json entries =
  let fields =
    List.map
      (fun (name, ty) ->
        Json_ast.Object
          [ ("fieldName", Json_ast.String name); ("fieldType", type_json ty) ])
      entries
  in
  Json_ast.Object
    [
      ("kind", Json_ast.String "row");
      ("fields", Json_ast.Array fields);
      ("other", Json_ast.Object [ ("kind", Json_ast.String "empty") ]);
    ]

and type_json = function
  | Ir_types.Bool -> Json_ast.Object [ ("kind", Json_ast.String "bool") ]
  | Ir_types.Str -> Json_ast.Object [ ("kind", Json_ast.String "str") ]
  | Ir_types.Int -> Json_ast.Object [ ("kind", Json_ast.String "int") ]
  | Ir_types.List ty ->
      Json_ast.Object
        [ ("kind", Json_ast.String "list"); ("elem", type_json ty) ]
  | Ir_types.Set ty ->
      Json_ast.Object
        [ ("kind", Json_ast.String "set"); ("elem", type_json ty) ]
  | Ir_types.Tuple slots ->
      Json_ast.Object
        [
          ("kind", Json_ast.String "tup");
          ( "fields",
            row_json
              (List.mapi (fun index ty -> (string_of_int index, ty)) slots) );
        ]
  | Ir_types.Map (key, value) ->
      Json_ast.Object
        [
          ("kind", Json_ast.String "fun");
          ("arg", type_json key);
          ("res", type_json value);
        ]
  | Ir_types.Record fields ->
      Json_ast.Object
        [ ("kind", Json_ast.String "rec"); ("fields", row_json fields) ]
  | Ir_types.Variant variants ->
      Json_ast.Object
        [ ("kind", Json_ast.String "sum"); ("fields", row_json variants) ]
  | Ir_types.Unresolved why ->
      Json_ast.Object
        [ ("kind", Json_ast.String "unresolved"); ("why", Json_ast.String why) ]

let bigint text = Json_ast.Object [ ("#bigint", Json_ast.String text) ]

let canonical_chunk text =
  let length = String.length text in
  let index = ref 0 in
  while !index < length - 1 && text.[!index] = '0' do
    incr index
  done;
  String.sub text !index (length - !index)

let chunks_of digits =
  let width = String.length digits in
  let groups = (width + 13) / 14 in
  let leading = width - (14 * (groups - 1)) in
  let rec split offset acc =
    if offset >= width then List.rev acc
    else
      let size = if offset = 0 then leading else 14 in
      let size = min size (width - offset) in
      split (offset + size) (String.sub digits offset size :: acc)
  in
  let rec drop_trailing = function
    | [] -> []
    | [ last ] ->
        if String.for_all (fun c -> c = '0') last then [] else [ last ]
    | head :: rest -> head :: drop_trailing rest
  in
  drop_trailing (split 0 [])

let s_e_c decimal =
  let negative = String.length decimal > 0 && decimal.[0] = '-' in
  let digits =
    if negative then String.sub decimal 1 (String.length decimal - 1)
    else decimal
  in
  let width = String.length digits in
  let chunks = chunks_of digits in
  Json_ast.Object
    [
      ("s", bigint (if negative then "-1" else "1"));
      ("e", bigint (string_of_int (width - 1)));
      ( "c",
        Json_ast.Array
          (List.map (fun chunk -> bigint (canonical_chunk chunk)) chunks) );
    ]

let gen_int_value state =
  let magnitude = int_range 0 999999999999999 state in
  let negative = QCheck.Gen.bool state in
  let chunk_form = QCheck.Gen.bool state in
  let decimal =
    (if negative && magnitude <> 0 then "-" else "") ^ string_of_int magnitude
  in
  let json =
    if chunk_form && magnitude <> 0 then s_e_c decimal else bigint decimal
  in
  { json; value = Itf_value.Int decimal }

let gen_string_value state =
  let characters =
    QCheck.Gen.list_size (int_range 0 6)
      (QCheck.Gen.oneof_list [ 'a'; 'b'; 'c'; ' '; '0' ])
      state
  in
  let text = String.concat "" (List.map (String.make 1) characters) in
  { json = Json_ast.String text; value = Itf_value.Str text }

let gen_scalar_ty state =
  QCheck.Gen.oneof
    [
      QCheck.Gen.return Ir_types.Bool;
      QCheck.Gen.return Ir_types.Str;
      QCheck.Gen.return Ir_types.Int;
    ]
    state

let rec gen_ty depth state =
  if depth <= 0 then gen_scalar_ty state
  else
    QCheck.Gen.oneof
      [
        gen_scalar_ty;
        QCheck.Gen.map (fun ty -> Ir_types.List ty) (gen_ty (depth - 1));
        QCheck.Gen.map (fun ty -> Ir_types.Set ty) (gen_ty (depth - 1));
        QCheck.Gen.map
          (fun (left, right) -> Ir_types.Tuple [ left; right ])
          (QCheck.Gen.pair (gen_ty (depth - 1)) (gen_ty (depth - 1)));
        QCheck.Gen.map
          (fun ty -> Ir_types.Map (Ir_types.Str, ty))
          (gen_ty (depth - 1));
        QCheck.Gen.map
          (fun tys ->
            Ir_types.Record
              (List.mapi (fun index ty -> ("f" ^ string_of_int index, ty)) tys))
          (QCheck.Gen.list_size (int_range 1 2) (gen_ty (depth - 1)));
        QCheck.Gen.map
          (fun ty -> Ir_types.Variant [ ("A", ty) ])
          (gen_ty (depth - 1));
        QCheck.Gen.return (Ir_types.Tuple []);
      ]
      state

let rec gen_value ty state =
  match ty with
  | Ir_types.Bool ->
      let value = QCheck.Gen.bool state in
      { json = Json_ast.Bool value; value = Itf_value.Bool value }
  | Ir_types.Str -> gen_string_value state
  | Ir_types.Int -> gen_int_value state
  | Ir_types.List elem ->
      let items = QCheck.Gen.list_size (int_range 0 3) (gen_value elem) state in
      {
        json = Json_ast.Array (List.map (fun item -> item.json) items);
        value = Itf_value.List (List.map (fun item -> item.value) items);
      }
  | Ir_types.Set elem ->
      let items = QCheck.Gen.list_size (int_range 0 3) (gen_value elem) state in
      {
        json =
          Json_ast.Object
            [
              ("#set", Json_ast.Array (List.map (fun item -> item.json) items));
            ];
        value = Itf_value.Set (List.map (fun item -> item.value) items);
      }
  | Ir_types.Tuple [] ->
      {
        json = Json_ast.Object [ ("tag", Json_ast.String "UNIT") ];
        value = Itf_value.Unit;
      }
  | Ir_types.Tuple slots ->
      let items = List.map (fun slot -> gen_value slot state) slots in
      {
        json =
          Json_ast.Object
            [
              ("#tup", Json_ast.Array (List.map (fun item -> item.json) items));
            ];
        value = Itf_value.Tuple (List.map (fun item -> item.value) items);
      }
  | Ir_types.Map (key_ty, value_ty) ->
      let entries =
        QCheck.Gen.list_size (int_range 0 2)
          (QCheck.Gen.pair (gen_value key_ty) (gen_value value_ty))
          state
      in
      {
        json =
          Json_ast.Object
            [
              ( "#map",
                Json_ast.Array
                  (List.map
                     (fun (key, value) ->
                       Json_ast.Array [ key.json; value.json ])
                     entries) );
            ];
        value =
          Itf_value.Map (List.map (fun (k, v) -> (k.value, v.value)) entries);
      }
  | Ir_types.Record fields ->
      let values = List.map (fun (_, ty) -> gen_value ty state) fields in
      {
        json =
          Json_ast.Object
            (List.map2
               (fun (name, _) value -> (name, value.json))
               fields values);
        value =
          Itf_value.Record
            (List.map2
               (fun (name, _) value -> (name, value.value))
               fields values);
      }
  | Ir_types.Variant [ (tag, payload_ty) ] ->
      let payload = gen_value payload_ty state in
      {
        json =
          Json_ast.Object
            [ ("tag", Json_ast.String tag); ("value", payload.json) ];
        value = Itf_value.Variant (tag, payload.value);
      }
  | Ir_types.Variant _ | Ir_types.Unresolved _ ->
      { json = Json_ast.Null; value = Itf_value.Unit }

let gen_trace state =
  let types = QCheck.Gen.list_size (int_range 1 3) (gen_ty 2) state in
  let gvars =
    List.mapi
      (fun index ty -> { gname = "v" ^ string_of_int index; gty = ty })
      types
  in
  let state_count = int_range 1 2 state in
  let gstates =
    List.init state_count (fun _ ->
        List.map (fun variable -> gen_value variable.gty state) gvars)
  in
  let invariant_count = int_range 1 2 state in
  let ginvariants =
    List.init invariant_count (fun index -> "inv" ^ string_of_int index)
  in
  { gvars; gstates; ginvariants }

let print_trace trace =
  Printf.sprintf "vars=%d states=%d invariants=%d" (List.length trace.gvars)
    (List.length trace.gstates)
    (List.length trace.ginvariants)

let shrink_trace trace =
  if List.length trace.gvars <= 1 then QCheck.Iter.empty
  else
    let drop_var index =
      {
        gvars = List.filteri (fun i _ -> i <> index) trace.gvars;
        gstates =
          List.map
            (fun values -> List.filteri (fun i _ -> i <> index) values)
            trace.gstates;
        ginvariants = trace.ginvariants;
      }
    in
    QCheck.Iter.of_list (List.mapi (fun index _ -> drop_var index) trace.gvars)

let variable_json trace values =
  List.map2
    (fun variable value -> (variable.gname, value.json))
    trace.gvars values

let trace_json trace =
  let states =
    List.mapi
      (fun index values ->
        Json_ast.Object
          (( "#meta",
             Json_ast.Object
               [ ("index", Json_ast.Number (string_of_int index)) ] )
          :: variable_json trace values))
      trace.gstates
  in
  Json_ast.Object
    [
      ( "vars",
        Json_ast.Array
          (List.map
             (fun variable -> Json_ast.String variable.gname)
             trace.gvars) );
      ("states", Json_ast.Array states);
    ]

let rec request_well_formed = function
  | Json_ast.Number _ -> false
  | Json_ast.Array items -> List.for_all request_well_formed items
  | Json_ast.Object members ->
      let names = List.map fst members in
      let chunk_object = List.sort String.compare names = [ "c"; "e"; "s" ] in
      (not chunk_object)
      && List.for_all (fun (_key, value) -> request_well_formed value) members
  | Json_ast.Null | Json_ast.Bool _ | Json_ast.String _ -> true

let sorted_names built = List.sort String.compare (Json_ast.member_names built)

let response_for invariants =
  let results =
    List.mapi
      (fun index _ ->
        match (index + String.length (String.concat "" invariants)) mod 4 with
        | 0 -> Json_ast.Object [ ("value", Json_ast.Bool false) ]
        | 3 ->
            Json_ast.Object
              [
                ( "error",
                  Json_ast.Object
                    [
                      ("code", Json_ast.String "QNT503");
                      ("message", Json_ast.String "Division by zero");
                      ("#trace", Json_ast.Array []);
                    ] );
              ]
        | _ -> Json_ast.Object [ ("value", Json_ast.Bool true) ])
      invariants
  in
  Json_ast.Object [ ("results", Json_ast.Array results) ]

let bool_expr =
  Json_ast.Object
    [ ("kind", Json_ast.String "bool"); ("value", Json_ast.Bool true) ]

let ir_json trace =
  let variable variable =
    Json_ast.Object
      [
        ("kind", Json_ast.String "var");
        ("name", Json_ast.String variable.gname);
        ("typeAnnotation", type_json variable.gty);
      ]
  in
  let invariant name =
    Json_ast.Object
      [
        ("kind", Json_ast.String "def");
        ("name", Json_ast.String name);
        ("qualifier", Json_ast.String "val");
        ("expr", bool_expr);
      ]
  in
  Json_ast.Object
    [
      ( "modules",
        Json_ast.Array
          [
            Json_ast.Object
              [
                ("name", Json_ast.String "M");
                ( "declarations",
                  Json_ast.Array
                    (List.map variable trace.gvars
                    @ List.map invariant trace.ginvariants) );
              ];
          ] );
      ("table", Json_ast.Object []);
    ]

let check trace =
  let raw = Json_writer.to_string (trace_json trace) in
  match Json_parse.parse (Json_writer.to_string (ir_json trace)) with
  | Error error -> Error ("ir: " ^ error.message)
  | Ok ir -> (
      match Resolver.resolve ir ~main:"M" ~invariants:trace.ginvariants with
      | Error message -> Error ("resolve: " ^ message)
      | Ok resolved -> (
          let decls = resolved.Resolver.variables in
          match Decoder.decode ~decls raw with
          | Error refusal -> Error ("decode: " ^ refusal.Decoder.message)
          | Ok decoded ->
              let state = List.hd decoded.Decoder.states in
              let built = Evaluator.build_state ~decls state in
              let expected_names =
                List.sort String.compare
                  ("#meta"
                  :: List.map (fun variable -> variable.gname) trace.gvars)
              in
              let meta_ok =
                match Json_ast.member "#meta" built with
                | Some (Json_ast.Object []) -> true
                | _ -> false
              in
              let names_ok = sorted_names built = expected_names in
              let integers_ok = request_well_formed built in
              let exprs =
                List.map
                  (fun name ->
                    match Resolver.invariant_expr ir ~main:"M" name with
                    | Some expr -> expr
                    | None -> bool_expr)
                  trace.ginvariants
              in
              let table =
                match Json_ast.member "table" ir with
                | Some table -> table
                | None -> Json_ast.Object []
              in
              let request =
                Evaluator.build_request ~table ~state:built ~exprs
              in
              let request_ok =
                match Json_ast.member "exprs" request with
                | Some (Json_ast.Array items) ->
                    List.length items = List.length trace.ginvariants
                | _ -> false
              in
              let response = response_for trace.ginvariants in
              let mapping_ok =
                match
                  Evaluator.interpret ~invariants:trace.ginvariants
                    ~state_index:0
                    (Json_writer.to_string response)
                with
                | Ok outcomes ->
                    List.length outcomes = List.length trace.ginvariants
                | Error failure -> failure.Failure.stage = "evaluate"
              in
              let arity_ok =
                let longer =
                  match Json_ast.member "results" response with
                  | Some (Json_ast.Array results) ->
                      Json_ast.Object
                        [
                          ( "results",
                            Json_ast.Array
                              (results
                              @ [
                                  Json_ast.Object
                                    [ ("value", Json_ast.Bool true) ];
                                ]) );
                        ]
                  | Some _ | None -> response
                in
                match
                  Evaluator.interpret ~invariants:trace.ginvariants
                    ~state_index:0
                    (Json_writer.to_string longer)
                with
                | Ok _ -> false
                | Error failure -> failure.Failure.stage = "evaluate"
              in
              if not meta_ok then Error "the forwarded #meta is not empty"
              else if not names_ok then
                Error "the forwarded state keys differ from the declarations"
              else if not integers_ok then
                Error "the forwarded value is not in the normalised grammar"
              else if not request_ok then
                Error "the expression array length differs from the invariants"
              else if not mapping_ok then
                Error "a valid response did not map to a verdict row"
              else if not arity_ok then
                Error "an arity mismatch was not refused"
              else Ok ()))

let statement trace = match check trace with Ok () -> true | Error _ -> false
let arbitrary = QCheck.make ~print:print_trace ~shrink:shrink_trace gen_trace

type report = {
  seed : int;
  cases : int;
  failures : int;
  input_digest : string;
  verdict_digest : string;
  first_reason : string option;
}

let law trace = statement trace

let first_shrunk ~cases seed =
  let cell =
    QCheck.Test.make_cell ~count:cases ~name:"evaluator-requests" arbitrary law
  in
  let result =
    QCheck.Test.check_cell ~rand:(Random.State.make [| seed |]) cell
  in
  match QCheck.TestResult.get_state result with
  | QCheck.TestResult.Failed { instances = first :: _ } ->
      Some first.QCheck.TestResult.instance
  | QCheck.TestResult.Error { instance; _ } ->
      Some instance.QCheck.TestResult.instance
  | _ -> None

let run ?(cases = 200) seed =
  let generated =
    QCheck.Gen.generate ~rand:(Random.State.make [| seed |]) ~n:cases gen_trace
  in
  let input_digest = Buffer.create 8192 in
  let verdict_digest = Buffer.create 8192 in
  let failures = ref 0 in
  let first_reason = ref None in
  List.iter
    (fun trace ->
      Buffer.add_string input_digest (Json_writer.to_string (trace_json trace));
      match check trace with
      | Ok () -> Buffer.add_string verdict_digest "ok\n"
      | Error reason ->
          incr failures;
          if !first_reason = None then first_reason := Some reason;
          Buffer.add_string verdict_digest ("error:" ^ reason ^ "\n"))
    generated;
  {
    seed;
    cases;
    failures = !failures;
    input_digest = Sha256.hex (Buffer.contents input_digest);
    verdict_digest = Sha256.hex (Buffer.contents verdict_digest);
    first_reason = !first_reason;
  }

let print_report report =
  Printf.printf "property evaluator-requests seed: %d\n" report.seed;
  Printf.printf
    "property evaluator-requests: cases=%d failures=%d inputs=%s verdicts=%s\n"
    report.cases report.failures report.input_digest report.verdict_digest;
  (match report.first_reason with
  | Some reason ->
      Printf.printf "property evaluator-requests first failure: %s\n" reason
  | None -> ());
  if report.failures > 0 then
    match first_shrunk ~cases:report.cases report.seed with
    | Some trace ->
        Printf.printf "property evaluator-requests replay (seed=%d): %s\n"
          report.seed (print_trace trace)
    | None -> ()

(* Results-array arity: for any evaluator response, the client accepts it only
   when the results array length equals the request expression count. The
   generator draws a request expression count and a response length that is
   shorter or longer than it, and drives the client through a stub binary. *)

type arity_case = { expressions : int; results : int }

let temp_dir () =
  let path = Filename.temp_file "quint-checktrace-arity" "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let write_file path text =
  let channel = open_out_bin path in
  output_string channel text;
  close_out channel

let gen_arity state =
  let expressions = QCheck.Gen.int_range 1 4 state in
  let delta =
    let magnitude = QCheck.Gen.int_range 1 4 state in
    if QCheck.Gen.bool state then magnitude else -magnitude
  in
  let results = max 0 (expressions + delta) in
  {
    expressions;
    results = (if results = expressions then expressions + 1 else results);
  }

let results_document count =
  Json_ast.Object
    [
      ( "results",
        Json_ast.Array
          (List.init count (fun _ ->
               Json_ast.Object [ ("value", Json_ast.Bool true) ])) );
    ]

let check_arity ~directory case =
  let response_path = Filename.concat directory "response.json" in
  write_file response_path
    (Json_writer.to_string (results_document case.results));
  let stub = Filename.concat directory "stub" in
  write_file stub
    (Printf.sprintf "#!/bin/sh\ncat >/dev/null\ncat %s\n" response_path);
  Unix.chmod stub 0o755;
  let invariants =
    List.init case.expressions (fun index -> "inv" ^ string_of_int index)
  in
  let request =
    Json_writer.to_string (Json_ast.Object [ ("request", Json_ast.Bool true) ])
  in
  match
    Evaluator.run_request
      { Evaluator.path = stub; sha256 = "" }
      ~timeout:10.0 request
  with
  | Error failure -> Error ("the stub did not run: " ^ Failure.to_string failure)
  | Ok output -> (
      match Evaluator.interpret ~invariants ~state_index:0 output with
      | Ok _ -> Error "an arity mismatch was accepted"
      | Error failure ->
          let message = Failure.to_string failure in
          let has_count count =
            let token = string_of_int count in
            let length = String.length message and n = String.length token in
            let rec find index =
              if index + n > length then false
              else if String.sub message index n = token then true
              else find (index + 1)
            in
            find 0
          in
          if
            failure.Failure.stage = "evaluate"
            && has_count case.expressions && has_count case.results
          then Ok ()
          else Error ("the refusal does not name both counts: " ^ message))

type arity_report = {
  arity_seed : int;
  arity_cases : int;
  arity_failures : int;
  arity_input_digest : string;
  arity_verdict_digest : string;
  arity_first_reason : string option;
}

let run_arity ?(cases = 200) seed =
  let generated =
    QCheck.Gen.generate ~rand:(Random.State.make [| seed |]) ~n:cases gen_arity
  in
  let directory = temp_dir () in
  let input_digest = Buffer.create 4096 in
  let verdict_digest = Buffer.create 4096 in
  let failures = ref 0 in
  let first_reason = ref None in
  List.iter
    (fun case ->
      Buffer.add_string input_digest
        (Printf.sprintf "%d/%d\n" case.expressions case.results);
      match check_arity ~directory case with
      | Ok () -> Buffer.add_string verdict_digest "ok\n"
      | Error reason ->
          incr failures;
          if !first_reason = None then first_reason := Some reason;
          Buffer.add_string verdict_digest ("error:" ^ reason ^ "\n"))
    generated;
  (try
     Array.iter
       (fun name -> Sys.remove (Filename.concat directory name))
       (Sys.readdir directory);
     Unix.rmdir directory
   with Sys_error _ -> ());
  {
    arity_seed = seed;
    arity_cases = cases;
    arity_failures = !failures;
    arity_input_digest = Sha256.hex (Buffer.contents input_digest);
    arity_verdict_digest = Sha256.hex (Buffer.contents verdict_digest);
    arity_first_reason = !first_reason;
  }

let print_arity_report report =
  Printf.printf "property results-arity seed: %d\n" report.arity_seed;
  Printf.printf
    "property results-arity: cases=%d failures=%d inputs=%s verdicts=%s\n"
    report.arity_cases report.arity_failures report.arity_input_digest
    report.arity_verdict_digest;
  match report.arity_first_reason with
  | Some reason ->
      Printf.printf "property results-arity first failure: %s\n" reason
  | None -> ()
