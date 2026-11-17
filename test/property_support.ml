(* Seed-controlled resolver property on the QCheck generator and shrinker.

   One seed initialises QCheck's random state, so the generated case sequence
   and the verdicts it produces are reproducible. The wrapper keeps the seed
   plumbing: it prints the seed, records the verdict digest for the same-seed
   comparison, and keeps the first shrunk counter-example as a replay
   record. Licence: AGPL-3.0-or-later; see README.md. *)

let default_seed = 20261115
let default_cases = 200

type declaration = { name : string; qualifier : string; parameterised : bool }
type imported = { module_name : string; alias : string; names : string list }

type case = {
  main : string;
  declarations : declaration list;
  imports : imported list;
  requested : string;
}

let declaration_names =
  [ "a"; "b"; "x"; "y"; "inv"; "threshold"; "init"; "settled" ]

let qualifiers = [ "val"; "pureval"; "action"; "temporal"; "def"; "puredef" ]
let main_names = [ "M0"; "M1"; "M2"; "M3" ]

let imported_module =
  { module_name = "Spec"; alias = "s"; names = [ "imported1"; "imported2" ] }

let dedupe declarations =
  let seen = Hashtbl.create 8 in
  List.filter
    (fun declaration ->
      if Hashtbl.mem seen declaration.name then false
      else begin
        Hashtbl.add seen declaration.name ();
        true
      end)
    declarations

let gen_declaration =
  QCheck.Gen.map
    (fun (name, qualifier, parameterised) -> { name; qualifier; parameterised })
    (QCheck.Gen.triple
       (QCheck.Gen.oneof_list declaration_names)
       (QCheck.Gen.oneof_list qualifiers)
       QCheck.Gen.bool)

let gen_case =
  QCheck.Gen.map
    (fun (main, declarations, imports, requested) ->
      { main; declarations = dedupe declarations; imports; requested })
    (QCheck.Gen.quad
       (QCheck.Gen.oneof_list main_names)
       (QCheck.Gen.list_size (QCheck.Gen.int_range 0 3) gen_declaration)
       (QCheck.Gen.map
          (fun present -> if present then [ imported_module ] else [])
          QCheck.Gen.bool)
       (QCheck.Gen.oneof_list
          (declaration_names @ [ "imported1"; "missing"; "s::b" ])))

let app_expr = {|{"kind":"app","opcode":"eq","args":[]}|}

let lambda_expr =
  {|{"kind":"lambda","params":[],"expr":{"kind":"bool","value":true}}|}

let variable = {|{"kind":"var","name":"v","typeAnnotation":{"kind":"int"}}|}

let render_ir case =
  let render_declaration declaration =
    Printf.sprintf {|{"kind":"def","name":%S,"qualifier":%S,"expr":%s}|}
      declaration.name declaration.qualifier
      (if declaration.parameterised then lambda_expr else app_expr)
  in
  let render_import imported =
    Printf.sprintf {|{"kind":"instance","protoName":%S,"qualifiedName":%S}|}
      imported.module_name imported.alias
  in
  let render_imported_module imported =
    let declarations =
      List.map
        (fun name ->
          Printf.sprintf
            {|{"kind":"def","name":%S,"qualifier":"val","expr":%s}|} name
            app_expr)
        imported.names
    in
    Printf.sprintf {|{"name":%S,"declarations":[%s]}|} imported.module_name
      (String.concat "," declarations)
  in
  let main =
    Printf.sprintf {|{"name":%S,"declarations":[%s]}|} case.main
      (String.concat ","
         (variable
         :: (List.map render_declaration case.declarations
            @ List.map render_import case.imports)))
  in
  Printf.sprintf {|{"modules":[%s]}|}
    (String.concat "," (main :: List.map render_imported_module case.imports))

let ir_of_case case =
  match Json_parse.parse (render_ir case) with
  | Ok ir -> ir
  | Error error ->
      failwith
        (Printf.sprintf "the generated case is not JSON: %s" error.message)

let model_accepts case =
  List.exists
    (fun declaration ->
      declaration.name = case.requested
      && (declaration.qualifier = "val" || declaration.qualifier = "pureval")
      && not declaration.parameterised)
    case.declarations

let contains haystack needle =
  let n = String.length needle and h = String.length haystack in
  let rec scan i =
    if i + n > h then false
    else if String.sub haystack i n = needle then true
    else scan (i + 1)
  in
  n = 0 || scan 0

let stage_named message =
  String.length message >= 9 && String.sub message 0 9 = "resolve: "

let mutant_outcome case =
  Ok
    {
      Resolver.main = case.main;
      invariants = [ case.requested ];
      variables = [];
    }

let outcome_of ~mutant case =
  if mutant then mutant_outcome case
  else
    Resolver.resolve (ir_of_case case) ~main:case.main
      ~invariants:[ case.requested ]

(* The statement: every resolved pair names a declaration of the right
   qualifier, and every pair the contract refuses is refused at stage
   resolve, naming the request. *)
let verdict ~mutant case =
  match outcome_of ~mutant case with
  | Ok resolved ->
      if not (model_accepts case) then
        Error "resolved a pair the contract refuses"
      else if resolved.Resolver.invariants <> [ case.requested ] then
        Error "the resolved invariant list differs from the request"
      else Ok ()
  | Error message ->
      if model_accepts case then
        Error ("refused a pair the contract accepts: " ^ message)
      else if not (stage_named message) then
        Error "the refusal does not name stage resolve"
      else if not (contains message case.requested) then
        Error "the refusal does not name the requested invariant"
      else Ok ()

let shrink_case case =
  let drop_declaration index =
    {
      case with
      declarations = List.filteri (fun i _ -> i <> index) case.declarations;
    }
  in
  let drop_import index =
    { case with imports = List.filteri (fun i _ -> i <> index) case.imports }
  in
  QCheck.Iter.of_list
    (List.mapi (fun index _ -> drop_declaration index) case.declarations
    @ List.mapi (fun index _ -> drop_import index) case.imports)

let print_case case =
  Printf.sprintf {|{main=%s; requested=%s; declarations=[%s]; imports=[%s]}|}
    case.main case.requested
    (String.concat "; "
       (List.map
          (fun declaration ->
            Printf.sprintf "%s:%s%s" declaration.name declaration.qualifier
              (if declaration.parameterised then "(lambda)" else ""))
          case.declarations))
    (String.concat "; "
       (List.map
          (fun imported -> imported.module_name ^ " as " ^ imported.alias)
          case.imports))

let arbitrary = QCheck.make ~print:print_case ~shrink:shrink_case gen_case

let replay_record case =
  Printf.sprintf {|{"main":%S,"invariants":[%S],"ir":%s}|} case.main
    case.requested (render_ir case)

type report = {
  seed : int;
  cases : int;
  failures : int;
  input_digest : string;
  verdict_digest : string;
  first_failure : case option;
}

let first_shrunk ~cases ~mutant seed fallback =
  let cell =
    QCheck.Test.make_cell ~count:cases ~name:"resolver-names" arbitrary
      (fun case -> verdict ~mutant case = Ok ())
  in
  let result =
    QCheck.Test.check_cell ~rand:(Random.State.make [| seed |]) cell
  in
  match QCheck.TestResult.get_state result with
  | QCheck.TestResult.Failed { instances = first :: _ } ->
      Some first.QCheck.TestResult.instance
  | QCheck.TestResult.Error { instance; _ } ->
      Some instance.QCheck.TestResult.instance
  | _ -> fallback

let run ?(mutant = false) ?(cases = default_cases) seed =
  let generated =
    QCheck.Gen.generate ~rand:(Random.State.make [| seed |]) ~n:cases gen_case
  in
  let input_digest = Buffer.create 8192 in
  let verdict_digest = Buffer.create 8192 in
  let failures = ref 0 in
  let first_failure = ref None in
  List.iter
    (fun case ->
      Buffer.add_string input_digest (render_ir case);
      match verdict ~mutant case with
      | Ok () -> Buffer.add_string verdict_digest "ok\n"
      | Error message ->
          incr failures;
          Buffer.add_string verdict_digest ("error:" ^ message ^ "\n");
          if !first_failure = None then first_failure := Some case)
    generated;
  let first_failure =
    if !failures = 0 then None
    else first_shrunk ~cases ~mutant seed !first_failure
  in
  {
    seed;
    cases;
    failures = !failures;
    input_digest = Sha256.hex (Buffer.contents input_digest);
    verdict_digest = Sha256.hex (Buffer.contents verdict_digest);
    first_failure;
  }

let print_report report =
  Printf.printf "property seed: %d\n" report.seed;
  Printf.printf
    "property resolver-names: cases=%d failures=%d inputs=%s verdicts=%s\n"
    report.cases report.failures report.input_digest report.verdict_digest;
  match report.first_failure with
  | None -> ()
  | Some case ->
      Printf.printf "property replay case (seed=%d): %s\n" report.seed
        (replay_record case)
