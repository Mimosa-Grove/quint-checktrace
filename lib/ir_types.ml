(* Declared variable types from the Quint parse IR. The decoder needs the
   resolved type at every descended position: the Rust big-integer form is an
   integer only at an int-typed position, and the eager type check walks the
   same positions. Licence: AGPL-3.0-or-later; see README.md. *)

type ty =
  | Bool
  | Str
  | Int
  | List of ty
  | Set of ty
  | Tuple of ty list
  | Map of ty * ty
  | Record of (string * ty) list
  | Variant of (string * ty) list
  | Unresolved of string

(** Return the value of [key] in a JSON object, or [None] when it is absent or
    the value is not a JSON object. *)
let member key = function
  | Json_ast.Object members -> List.assoc_opt key members
  | _ -> None

(** Return the [kind] string of a JSON object, or the empty string when it is
    absent or not a string. *)
let kind json =
  match member "kind" json with Some (Json_ast.String s) -> s | _ -> ""

(** Return the [name] string of a JSON object, or the empty string when it is
    absent or not a string. *)
let name json =
  match member "name" json with Some (Json_ast.String s) -> s | _ -> ""

(** Return the [key] member of a JSON object as an array, or [None] when it is
    absent or not an array. *)
let array_member key json =
  match member key json with Some (Json_ast.Array xs) -> Some xs | _ -> None

(** Return the field list of a row object. Returns [Error] for a missing row, a
    missing field list, or a row whose open tail is not empty. *)
let row_fields json =
  match member "fields" json with
  | Some (Json_ast.Object row) -> (
      if kind (Json_ast.Object row) = "empty" then Ok []
      else
        let open_ok =
          match List.assoc_opt "other" row with
          | Some other -> kind other = "empty"
          | None -> false
        in
        if not open_ok then Error "open row"
        else
          match List.assoc_opt "fields" row with
          | Some (Json_ast.Array fields) -> Ok fields
          | _ -> Error "missing row fields")
  | _ -> Error "missing row"

(** Return the [fieldName] string of a row field, or the empty string when it is
    absent or not a string. *)
let field_name json =
  match member "fieldName" json with Some (Json_ast.String s) -> s | _ -> ""

(** Return the [fieldType] value of a row field, or [Json_ast.Null] when it is
    absent. *)
let field_type json =
  match member "fieldType" json with Some t -> t | None -> Json_ast.Null

type context = {
  table : (string, Json_ast.t) Hashtbl.t;
  duplicates : string list;
}

(** Return the annotation id of a type node as raw text, or [None] when it
    carries neither a number nor a string id. *)
let id json =
  match member "id" json with
  | Some (Json_ast.Number raw) -> Some raw
  | Some (Json_ast.String raw) -> Some raw
  | _ -> None

(* A table key the IR carries more than once makes every alias resolution
   ambiguous: the JSON reader retains both members and a last-wins lookup would
   pick one silently. The duplicate is recorded here and every resolution
   reports it as unresolved, which the decoder refuses as class 13. *)

(** Build the typedef lookup table from the [table] member of [ir], recording
    every key carried more than once so that resolution can reject the entry. *)
let context_of_ir (ir : Json_ast.t) : context =
  let table = Hashtbl.create 32 in
  let duplicates = ref [] in
  (match member "table" ir with
  | Some (Json_ast.Object rows) ->
      List.iter
        (fun (key, entry) ->
          if Hashtbl.mem table key then
            begin if not (List.mem key !duplicates) then
              duplicates := key :: !duplicates
            end;
          Hashtbl.replace table key entry)
        rows
  | _ -> ());
  { table; duplicates = List.rev !duplicates }

(** Resolve the type node [json] against [typedefs]. Returns an [Unresolved]
    value carrying a message for a duplicated table key, a missing or
    non-typedef entry, a recursive alias or an unknown kind. *)
let resolve_type (typedefs : context) (json : Json_ast.t) : ty =
  match typedefs.duplicates with
  | key :: _ ->
      Unresolved
        (Printf.sprintf
           "the IR table carries the key %s more than once; the entry is not \
            determined"
           key)
  | [] ->
      let rec resolve visited json =
        match kind json with
        | "int" -> Int
        | "str" -> Str
        | "bool" -> Bool
        | "list" -> (
            match member "elem" json with
            | Some elem -> List (resolve visited elem)
            | None -> Unresolved "list without an element type")
        | "set" -> (
            match member "elem" json with
            | Some elem -> Set (resolve visited elem)
            | None -> Unresolved "set without an element type")
        | "tup" -> (
            match row_fields json with
            | Ok fields ->
                Tuple
                  (List.map (fun f -> resolve visited (field_type f)) fields)
            | Error why -> Unresolved why)
        | "fun" -> (
            match (member "arg" json, member "res" json) with
            | Some arg, Some res ->
                Map (resolve visited arg, resolve visited res)
            | _ -> Unresolved "map without an argument or result type")
        | "rec" -> (
            match row_fields json with
            | Ok fields ->
                Record
                  (List.map
                     (fun f -> (field_name f, resolve visited (field_type f)))
                     fields)
            | Error why -> Unresolved why)
        | "sum" -> (
            match row_fields json with
            | Ok fields ->
                Variant
                  (List.map
                     (fun f -> (field_name f, resolve visited (field_type f)))
                     fields)
            | Error why -> Unresolved why)
        | "const" -> (
            let ty_name = name json in
            match id json with
            | None ->
                Unresolved
                  (Printf.sprintf "type alias %s carries no annotation id"
                     ty_name)
            | Some annotation_id -> (
                if List.mem annotation_id visited then
                  Unresolved ("recursive alias " ^ ty_name)
                else
                  match Hashtbl.find_opt typedefs.table annotation_id with
                  | None ->
                      Unresolved
                        (Printf.sprintf
                           "type alias %s has no table entry for annotation id \
                            %s"
                           ty_name annotation_id)
                  | Some entry -> (
                      if kind entry <> "typedef" then
                        Unresolved
                          (Printf.sprintf
                             "the table entry %s for type alias %s is not a \
                              typedef"
                             annotation_id ty_name)
                      else
                        match member "type" entry with
                        | Some body -> resolve (annotation_id :: visited) body
                        | None ->
                            Unresolved
                              (Printf.sprintf
                                 "the table entry %s for type alias %s carries \
                                  no type"
                                 annotation_id ty_name))))
        | "var" -> Unresolved ("type parameter " ^ name json)
        | "" -> Unresolved "type annotation without a kind"
        | other -> Unresolved ("unsupported type kind " ^ other)
      in
      resolve [] json
