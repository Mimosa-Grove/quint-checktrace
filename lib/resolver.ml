(* Invariant and variable resolution against the Quint parse IR.

   Name resolution sees the main module's own declaration list and nothing
   else: an imported declaration is refused unless the main module wraps it.
   The variable set follows the observed instance naming rule, whose qualifier
   is the direct importer's module name plus the alias, not a recursive path.
   Licence: AGPL-3.0-or-later; see README.md. *)

type resolved = {
  main : string;
  invariants : string list;
  variables : (string * Ir_types.ty) list;
}

exception Refuse of string

(** Raise [Refuse] with the message prefixed "resolve: ". *)
let refuse fmt =
  Printf.ksprintf (fun detail -> raise (Refuse ("resolve: " ^ detail))) fmt

(** The member [key] of a JSON object node, or [None]. *)
let member = Ir_types.member

(** The [kind] member of an IR node as a string, empty when absent. *)
let kind = Ir_types.kind

(** The [name] member of an IR node as a string, empty when absent. *)
let name_of = Ir_types.name

(** The array member [key] of a JSON object node, or [None]. *)
let array_member = Ir_types.array_member

(** The module nodes of the IR's [modules] array, empty when absent. *)
let modules ir =
  match member "modules" ir with
  | Some (Json_ast.Array modules) -> modules
  | _ -> []

(** The name of a module node. *)
let module_name json = name_of json

(** The declaration list of a module node, empty when absent. *)
let declarations json =
  Option.value (array_member "declarations" json) ~default:[]

(** The names of every module in the IR, in declaration order. *)
let module_names ir = List.map module_name (modules ir)

(** The module names joined for a message, or "none" when there is none. *)
let module_list ir =
  match module_names ir with [] -> "none" | names -> String.concat ", " names

(** The module node named [wanted], or [None] when no such module is declared.
    Raises [Refuse] when the name is declared more than once. *)
let find_module ir wanted =
  match List.filter (fun json -> module_name json = wanted) (modules ir) with
  | [] -> None
  | [ json ] -> Some json
  | _ -> refuse "module '%s' is declared more than once in the IR" wanted

(** The string member [key] of a JSON object node, or [None]. *)
let string_member key json =
  match member key json with
  | Some (Json_ast.String value) -> Some value
  | _ -> None

(** The [qualifier] member of a declaration, empty when absent or not a string.
*)
let qualifier json = Option.value (string_member "qualifier" json) ~default:""

(** True when the declaration's [expr] member has kind "lambda". *)
let parameterised json =
  match member "expr" json with
  | Some expr -> kind expr = "lambda"
  | None -> false

(** The first non-instance declaration of [module_json] named [wanted]. *)
let declaration_named module_json wanted =
  List.find_opt
    (fun decl -> kind decl <> "instance" && name_of decl = wanted)
    (declarations module_json)

(** The [expr] member of the declaration [wanted] in module [main], or [None]
    when the module or the declaration is absent. *)
let invariant_expr ir ~main wanted =
  match find_module ir main with
  | None -> None
  | Some module_json -> (
      match declaration_named module_json wanted with
      | Some declaration -> member "expr" declaration
      | None -> None)

(** The names of the modules carrying a non-instance declaration named [wanted].
*)
let declaring_modules ir wanted =
  modules ir
  |> List.filter_map (fun json ->
      match declaration_named json wanted with
      | Some _ -> Some (module_name json)
      | None -> None)

(** True when [name] contains "::". *)
let is_qualified name =
  let n = String.length name in
  let rec scan i =
    if i + 1 >= n then false
    else if name.[i] = ':' && name.[i + 1] = ':' then true
    else scan (i + 1)
  in
  scan 0

(** The segment after the last ":" of a qualified name, or [name] when it holds
    no separator. *)
let unqualified name =
  match List.rev (String.split_on_char ':' name) with
  | leaf :: _ :: _ -> leaf
  | _ -> name

(** The non-empty names of the non-instance declarations of [module_json]. *)
let own_declaration_names module_json =
  declarations module_json
  |> List.filter_map (fun decl ->
      match kind decl with
      | "instance" -> None
      | _ -> ( match name_of decl with "" -> None | name -> Some name))

(** Return [inv] when it names a val or pureval declaration of module [main]
    that is not a lambda. Raises [Refuse] on a qualified name, a missing module
    or declaration, or any other qualifier. *)
let resolve_invariant ir ~main inv =
  if is_qualified inv then
    refuse
      "qualified invariant name '%s' is not accepted; declare a wrapper val in \
       module '%s' and name that, for example val %s = %s"
      inv main (unqualified inv) inv;
  match find_module ir main with
  | None -> refuse "main module '%s' is not declared in the specification" main
  | Some main_json -> (
      match declaration_named main_json inv with
      | Some decl -> (
          match qualifier decl with
          | "val" | "pureval" ->
              if parameterised decl then
                refuse
                  "declaration '%s' is parameterised (an expression of kind \
                   lambda), which is not an invariant"
                  inv;
              inv
          | other ->
              refuse
                "declaration '%s' has qualifier '%s', which is not an \
                 invariant; accepted qualifiers are val and pureval"
                inv other)
      | None -> (
          match declaring_modules ir inv with
          | [] ->
              refuse
                "invariant '%s' is not declared in module '%s'; declarations: \
                 %s"
                inv main
                (match own_declaration_names main_json with
                | [] -> "none"
                | names -> String.concat ", " names)
          | elsewhere ->
              refuse
                "invariant '%s' is not declared in module '%s'; the name is \
                 declared in %s and is not visible in the main module's \
                 declaration list"
                inv main
                (String.concat ", "
                   (List.map
                      (fun n -> Printf.sprintf "module '%s'" n)
                      elsewhere))))

(** Return [main] when the IR declares that module, and raise [Refuse] with the
    module list otherwise. *)
let resolve_main ir main =
  match find_module ir main with
  | Some _ -> main
  | None ->
      refuse
        "main module '%s' is not declared in the specification; modules: %s"
        main (module_list ir)

(* The variable-path walk is shared by the typed derivation and the names-only
   derivation: only the type step differs. *)

(** Call [add] with each variable path and its type annotation, walking the
    instance imports of module [main] in declaration order. Raises [Refuse] on a
    recursive chain or an instance or import shape it cannot model. *)
let walk_variable_paths ir ~main add =
  let own_declarations module_json prefix =
    List.iter
      (fun decl ->
        if kind decl = "var" then
          add (prefix ^ name_of decl) (member "typeAnnotation" decl))
      (declarations module_json)
  in
  let rec walk chain module_json prefix =
    let mname = module_name module_json in
    if List.mem mname chain then
      refuse
        "the instance import chain %s is recursive; variable paths are not \
         derivable"
        (String.concat " -> " (List.rev (mname :: chain)));
    own_declarations module_json prefix;
    List.iter
      (fun decl ->
        if kind decl = "instance" then
          match
            (string_member "protoName" decl, string_member "qualifiedName" decl)
          with
          | Some proto, Some alias -> (
              match find_module ir proto with
              | Some target ->
                  walk (mname :: chain) target (mname ^ "::" ^ alias ^ "::")
              | None ->
                  refuse
                    "instance '%s' in module '%s' imports module '%s', which \
                     is absent from the IR"
                    alias mname proto)
          | _ ->
              refuse
                "instance declaration in module '%s' carries no imported \
                 module or no alias; its variable paths are not derivable"
                mname
        else if kind decl = "import" then
          match string_member "protoName" decl with
          | Some proto -> (
              match find_module ir proto with
              | Some target ->
                  let declares_var =
                    List.exists (fun d -> kind d = "var") (declarations target)
                  in
                  let shape =
                    match string_member "qualifiedName" decl with
                    | None -> "star"
                    | Some alias -> Printf.sprintf "name (as %s)" alias
                  in
                  if
                    string_member "qualifiedName" decl = None
                    && List.exists
                         (fun d -> kind d = "instance")
                         (declarations target)
                  then
                    refuse
                      "the star import of module '%s' in module '%s' carries \
                       an instance; the variable paths it introduces are not \
                       modelled"
                      proto mname
                  else if declares_var then
                    refuse
                      "the %s import of module '%s' in module '%s' can \
                       introduce the variables declared there; the variable \
                       paths it introduces are not modelled"
                      shape proto mname
              | None -> ())
          | None -> ())
      (declarations module_json)
  in
  let main_json =
    match find_module ir main with
    | Some json -> json
    | None ->
        refuse
          "main module '%s' is not declared in the specification; modules: %s"
          main (module_list ir)
  in
  walk [] main_json ""

(** Raise [Refuse] when [path] is already recorded in [seen], because the IR
    then does not determine the path. *)
let first_path_refusal seen path =
  if Hashtbl.mem seen path then
    refuse "variable path '%s' is derived twice; the IR does not determine it"
      path

(* The duplicate table keys are a property of the IR, not of any declaration:
   the typed phase refuses them even when no declaration reaches one. *)

(** The IR table keys that occur more than once. *)
let duplicate_keys ir = (Ir_types.context_of_ir ir).duplicates

(** Derive the variable paths of module [main] with their resolved types, in
    declaration order, and return them or [Error] with the refusal message. *)
let variable_decls ir ~main =
  try
    let context = Ir_types.context_of_ir ir in
    let seen = Hashtbl.create 16 in
    let order = ref [] in
    let add path annotation =
      first_path_refusal seen path;
      Hashtbl.add seen path ();
      let ty =
        match annotation with
        | Some annotation -> Ir_types.resolve_type context annotation
        | None -> Ir_types.Unresolved "variable without a type"
      in
      order := (path, ty) :: !order
    in
    walk_variable_paths ir ~main add;
    Ok (List.rev !order)
  with Refuse message -> Error message

(* The names-only derivation: the structural value walk needs the declared
   names before any type is resolved. *)

(** Derive the variable paths of module [main] as names only, in declaration
    order, and return them or [Error] with the refusal message. *)
let declaration_names ir ~main =
  try
    let seen = Hashtbl.create 16 in
    let order = ref [] in
    let add path _ =
      first_path_refusal seen path;
      Hashtbl.add seen path ();
      order := path :: !order
    in
    walk_variable_paths ir ~main add;
    Ok (List.rev !order)
  with Refuse message -> Error message

(** Resolve the main module, the deduplicated invariants and the typed variable
    paths, returning [Ok] with the record or [Error] with the first refusal
    message. *)
let resolve ir ~main ~invariants =
  try
    let main = resolve_main ir main in
    let invariants =
      List.map
        (resolve_invariant ir ~main)
        (List.sort_uniq String.compare invariants)
    in
    let variables =
      match variable_decls ir ~main with
      | Ok variables -> variables
      | Error message -> raise (Refuse message)
    in
    Ok { main; invariants; variables }
  with Refuse message -> Error message
