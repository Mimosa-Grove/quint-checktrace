(* Resolution cases: main-module and invariant name resolution, and the
   instance-qualified variable names. Licence: AGPL-3.0-or-later; see
   README.md. *)

let ir_of string =
  match Json_parse.parse string with
  | Ok value -> value
  | Error error ->
      failwith (Printf.sprintf "test IR is not JSON: %s" error.message)

let var name =
  Printf.sprintf {|{"kind":"var","name":"%s","typeAnnotation":{"kind":"int"}}|}
    name

let def name qualifier expr =
  Printf.sprintf {|{"kind":"def","name":"%s","qualifier":"%s","expr":%s}|} name
    qualifier expr

let app = {|{"kind":"app","opcode":"eq","args":[]}|}
let name_expr n = Printf.sprintf {|{"kind":"name","name":"%s"}|} n

let lambda =
  {|{"kind":"lambda","params":[],"expr":{"kind":"bool","value":true}}|}

let instance proto alias =
  Printf.sprintf {|{"kind":"instance","protoName":"%s","qualifiedName":"%s"}|}
    proto alias

let module_ name declarations =
  Printf.sprintf {|{"name":"%s","declarations":[%s]}|} name
    (String.concat "," declarations)

let ir modules =
  ir_of @@ Printf.sprintf {|{"modules":[%s]}|} (String.concat "," modules)

let contains haystack needle = Corpus_support.contains_sub haystack needle

let check_tokens message tokens =
  List.iter
    (fun token ->
      Alcotest.(check bool)
        (Printf.sprintf "diagnostic carries %S" token)
        true (contains message token))
    tokens

let refusal_of = function
  | Ok _ -> Alcotest.fail "expected a refusal, resolution succeeded"
  | Error message -> message

let accepted ir ~main ~invariants =
  match Resolver.resolve ir ~main ~invariants with
  | Ok resolved -> resolved
  | Error message -> Alcotest.fail ("expected resolution, refused: " ^ message)

let sorted names = List.sort String.compare names

let variables ir main =
  match Resolver.variable_decls ir ~main with
  | Ok decls -> sorted (List.map fst decls)
  | Error message -> Alcotest.fail ("expected variables, refused: " ^ message)

let holder declaration =
  ir
    [
      module_ "MainHolder"
        [ var "count"; def "nonNegative" "val" app; declaration ];
    ]

let test_main_absent () =
  let ir = holder (def "other" "val" app) in
  let message =
    refusal_of
      (Resolver.resolve ir ~main:"Absent" ~invariants:[ "nonNegative" ])
  in
  check_tokens message [ "resolve"; "Absent"; "MainHolder" ]

let test_invariant_absent () =
  let ir = holder (def "other" "val" app) in
  let message =
    refusal_of
      (Resolver.resolve ir ~main:"MainHolder" ~invariants:[ "missing" ])
  in
  check_tokens message [ "resolve"; "missing"; "nonNegative" ]

let test_qualifier_refusals () =
  let cases =
    [
      ("action", "init", [ "init"; "action" ]);
      ("temporal", "settled", [ "settled"; "temporal" ]);
      ("def", "doubled", [ "doubled"; "def" ]);
      ("puredef", "doubled", [ "doubled"; "puredef" ]);
    ]
  in
  List.iter
    (fun (qualifier, name, tokens) ->
      let ir = holder (def name qualifier app) in
      let message =
        refusal_of (Resolver.resolve ir ~main:"MainHolder" ~invariants:[ name ])
      in
      check_tokens message ("resolve" :: tokens))
    cases

let test_parameterised_val () =
  let ir = holder (def "threshold" "val" lambda) in
  let message =
    refusal_of
      (Resolver.resolve ir ~main:"MainHolder" ~invariants:[ "threshold" ])
  in
  check_tokens message [ "resolve"; "threshold" ]

let test_accepted_qualifiers () =
  let ir =
    holder
      (String.concat ","
         [ def "checked" "val" app; def "pureChecked" "pureval" app ])
  in
  let resolved =
    accepted ir ~main:"MainHolder" ~invariants:[ "checked"; "pureChecked" ]
  in
  Alcotest.(check (list string))
    "invariants"
    [ "checked"; "pureChecked" ]
    resolved.Resolver.invariants;
  Alcotest.(check (list string))
    "variables" [ "count" ]
    (List.map fst resolved.Resolver.variables)

let test_qualified_name () =
  let ir = holder (def "other" "val" app) in
  let message =
    refusal_of
      (Resolver.resolve ir ~main:"MainHolder" ~invariants:[ "s::bounded" ])
  in
  check_tokens message [ "resolve"; "s::bounded"; "wrapper"; "val" ]

let test_hidden_import () =
  let ir =
    ir
      [
        module_ "HiddenSpec" [ var "x"; def "hidden" "val" app ];
        module_ "HiddenHolder"
          [ var "x"; instance "HiddenSpec" "h"; def "visible" "val" app ];
      ]
  in
  let message =
    refusal_of
      (Resolver.resolve ir ~main:"HiddenHolder" ~invariants:[ "hidden" ])
  in
  check_tokens message [ "resolve"; "hidden"; "visible" ]

let test_export_visible () =
  let ir =
    ir
      [
        module_ "ExportSpec" [ var "x"; def "exported" "val" app ];
        module_ "ExportBridge" [ instance "ExportSpec" "e" ];
        module_ "ExportHolder" [ var "x"; def "visible" "val" app ];
      ]
  in
  let message =
    refusal_of
      (Resolver.resolve ir ~main:"ExportHolder" ~invariants:[ "exported" ])
  in
  check_tokens message [ "resolve"; "exported"; "visible" ]

let test_duplicate_invariant () =
  let ir = holder (def "other" "val" app) in
  let resolved =
    accepted ir ~main:"MainHolder" ~invariants:[ "nonNegative"; "nonNegative" ]
  in
  Alcotest.(check (list string))
    "collapsed" [ "nonNegative" ] resolved.Resolver.invariants

let test_nested_variables () =
  let ir =
    ir
      [
        module_ "Inner" [ var "x" ];
        module_ "Mid" [ var "y"; instance "Inner" "i" ];
        module_ "Outer"
          [ instance "Mid" "m"; def "deep" "val" (name_expr "deep") ];
      ]
  in
  Alcotest.(check (list string))
    "one and two levels"
    [ "Mid::i::x"; "Outer::m::y" ]
    (variables ir "Outer")

let test_two_instance_variables () =
  let ir =
    ir
      [
        module_ "Spec" [ var "x"; def "bounded" "val" app ];
        module_ "TwoInstances"
          [ instance "Spec" "a"; instance "Spec" "b"; def "both" "val" app ];
      ]
  in
  Alcotest.(check (list string))
    "per-alias names"
    [ "TwoInstances::a::x"; "TwoInstances::b::x" ]
    (variables ir "TwoInstances")

let test_mixed_module_variables () =
  let ir =
    ir
      [
        module_ "Spec" [ var "x"; var "seen" ];
        module_ "Instance"
          [ var "own"; instance "Spec" "s"; def "bounded" "val" app ];
      ]
  in
  Alcotest.(check (list string))
    "own beside instance"
    [ "Instance::s::seen"; "Instance::s::x"; "own" ]
    (variables ir "Instance")

let test_absent_proto () =
  let ir = ir [ module_ "Main" [ var "x"; instance "Gone" "g" ] ] in
  let message =
    match Resolver.variable_decls ir ~main:"Main" with
    | Ok _ -> ""
    | Error message -> message
  in
  check_tokens message [ "resolve"; "Gone"; "g" ]

let test_recursive_instance () =
  let ir =
    ir
      [
        module_ "A" [ var "x"; instance "B" "b" ];
        module_ "B" [ var "y"; instance "A" "a" ];
      ]
  in
  let refused =
    match Resolver.variable_decls ir ~main:"A" with
    | Ok _ -> false
    | Error _ -> true
  in
  Alcotest.(check bool) "recursive instance refused" true refused

let test_duplicate_alias () =
  let ir =
    ir
      [
        module_ "Spec" [ var "x" ];
        module_ "Main" [ instance "Spec" "a"; instance "Spec" "a" ];
      ]
  in
  let refused =
    match Resolver.variable_decls ir ~main:"Main" with
    | Ok _ -> false
    | Error _ -> true
  in
  Alcotest.(check bool) "duplicate alias refused" true refused

let test_recorded_regressions () =
  let path =
    Corpus_support.first_existing
      [
        "regressions/resolver-names.json";
        "test/regressions/resolver-names.json";
        "../test/regressions/resolver-names.json";
      ]
  in
  let document = Corpus_support.load_json path in
  let records =
    match Corpus_support.jopt (Corpus_support.jobj document) "records" with
    | Some value -> Corpus_support.jarray value
    | None -> Alcotest.fail "the regression file carries no records"
  in
  Alcotest.(check bool) "at least one record" true (records <> []);
  List.iter
    (fun record ->
      let fields = Corpus_support.jobj record in
      let label = Corpus_support.jstr (List.assoc "name" fields) in
      let main = Corpus_support.jstr (List.assoc "main" fields) in
      let invariants =
        Corpus_support.jstrings (List.assoc "invariants" fields)
      in
      let ir = List.assoc "ir" fields in
      match Resolver.resolve ir ~main ~invariants with
      | Ok _ -> Alcotest.fail (label ^ ": expected the recorded refusal")
      | Error message ->
          Alcotest.(check bool)
            (label ^ ": stage named") true
            (String.length message >= 9 && String.sub message 0 9 = "resolve: ");
          List.iter
            (fun invariant ->
              Alcotest.(check bool)
                (label ^ ": names " ^ invariant)
                true
                (contains message invariant))
            invariants)
    records

let test_star_import_instance () =
  let ir =
    ir
      [
        module_ "Spec" [ var "x" ];
        module_ "Bridge" [ instance "Spec" "s" ];
        module_ "Main" [ {|{"kind":"import","protoName":"Bridge"}|} ];
      ]
  in
  let message =
    match Resolver.variable_decls ir ~main:"Main" with
    | Ok _ -> ""
    | Error message -> message
  in
  check_tokens message [ "resolve"; "Bridge"; "not modelled" ]

let suite =
  [
    Alcotest.test_case "main absent" `Quick test_main_absent;
    Alcotest.test_case "invariant absent" `Quick test_invariant_absent;
    Alcotest.test_case "qualifier refusals" `Quick test_qualifier_refusals;
    Alcotest.test_case "parameterised val" `Quick test_parameterised_val;
    Alcotest.test_case "accepted qualifiers" `Quick test_accepted_qualifiers;
    Alcotest.test_case "qualified name" `Quick test_qualified_name;
    Alcotest.test_case "hidden import" `Quick test_hidden_import;
    Alcotest.test_case "export visible" `Quick test_export_visible;
    Alcotest.test_case "duplicate invariant" `Quick test_duplicate_invariant;
    Alcotest.test_case "nested variables" `Quick test_nested_variables;
    Alcotest.test_case "two instances" `Quick test_two_instance_variables;
    Alcotest.test_case "mixed module" `Quick test_mixed_module_variables;
    Alcotest.test_case "absent proto" `Quick test_absent_proto;
    Alcotest.test_case "recursive instance" `Quick test_recursive_instance;
    Alcotest.test_case "duplicate alias" `Quick test_duplicate_alias;
    Alcotest.test_case "star import with instance" `Quick
      test_star_import_instance;
    Alcotest.test_case "recorded regressions" `Quick test_recorded_regressions;
  ]
