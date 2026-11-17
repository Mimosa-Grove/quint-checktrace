(* ITF trace decoder. Every unhandled shape is a refusal with a class,
   stage, JSON path and byte offset where one exists. Licence:
   AGPL-3.0-or-later; see README.md. *)

type refusal = {
  stage : string;
  klass : int;
  message : string;
  path : string option;
  offset : int option;
}

exception Refuse of int * string * string option * int option

(** Raise [Refuse] carrying [klass], the formatted detail, and the optional JSON
    path and byte offset. *)
let refuse klass ?path ?offset fmt =
  Printf.ksprintf
    (fun detail -> raise (Refuse (klass, detail, path, offset)))
    fmt

(** Append [name] to [path], or return [name] when [path] is empty. *)
let child path name = if path = "" then name else path ^ "/" ^ name

(** Refuse class 2 on the first member name that occurs more than once,
    reporting the offending path under [base]. *)
let check_duplicates ~base members =
  match Json_ast.duplicate_names members with
  | [] -> ()
  | name :: _ ->
      let path = child base name in
      refuse 2 ~path "duplicate member name %s at %s" name path

type trace_meta = {
  format : string option;
  source : string option;
  status : string option;
  description : string option;
  timestamp : string option;
  source_type : string option;
  status_type : string option;
}

type state = {
  index : int;
  values : (string * Itf_value.t) list;
  meta : Json_ast.t option;
}

type trace = {
  meta : trace_meta;
  vars : string list;
  states : state list;
  loop : int option;
  params : string list;
  unknown_top_level_fields : string list;
  ignored_vars : string list;
  source_mismatch : bool;
  sha256 : string;
}

(** A metadata record with every field absent. *)
let empty_meta =
  {
    format = None;
    source = None;
    status = None;
    description = None;
    timestamp = None;
    source_type = None;
    status_type = None;
  }

(** The string value of member [key], or [None] when the member is absent or is
    not a JSON string. *)
let string_option key members =
  match List.assoc_opt key members with
  | Some (Json_ast.String s) -> Some s
  | _ -> None

(** The JSON type name of member [key] when it is present and is not a string,
    or [None]. *)
let non_string_type key members =
  match List.assoc_opt key members with
  | Some (Json_ast.String _) | None -> None
  | Some value -> Some (Json_ast.json_type_name value)

(** Convert [f] to an int by truncation, or [None] when it lies outside the int
    range. *)
let float_to_int (f : float) : int option =
  if f > float_of_int max_int || f < float_of_int min_int then None
  else Some (int_of_float f)

(** The variable name segment of a states/<index>/<var> path, or "?" for any
    other shape. *)
let path_var path =
  match String.split_on_char '/' path with
  | "states" :: _ :: var :: _ -> var
  | _ -> "?"

(** The index segment of a states/<index>/... path, or "?" for any other shape.
*)
let path_state path =
  match String.split_on_char '/' path with
  | "states" :: index :: _ -> index
  | _ -> "?"

(** Refuse class 13 at [path] for a value that cannot be typed against its
    variable's declared type. *)
let type_error ~path =
  refuse 13 ~path
    "value at %s cannot be typed against the declared type of variable %s in \
     state %s"
    path (path_var path) (path_state path)

(** Refuse class 16 for an object at [path] carrying the [keys] members, which
    reads both as a record and as [reading] under the type-blind
    deserialisation. *)
let collision ~path keys reading =
  refuse 16 ~path
    "collision at %s (variable %s, state %s): the object takes the %s keys and \
     reads as a record field set under the specification and as %s under the \
     evaluator's type-blind deserialisation; the record/%s collision is \
     refused"
    path (path_var path) (path_state path) keys reading reading

(** True when [s] is a non-empty run of decimal digits, optionally preceded by a
    minus sign. *)
let is_decimal_text s =
  let n = String.length s in
  if n = 0 then false
  else
    let start = if s.[0] = '-' then 1 else 0 in
    start < n
    &&
    let ok = ref true in
    for i = start to n - 1 do
      if not (s.[i] >= '0' && s.[i] <= '9') then ok := false
    done;
    !ok

(** Strip leading zeros from [s], returning "0" for an empty or all-zero string.
*)
let canonical_chunk s =
  let n = String.length s in
  if n = 0 then "0"
  else
    let i = ref 0 in
    while !i < n - 1 && s.[!i] = '0' do
      incr i
    done;
    String.sub s !i (n - !i)

(** The magnitude limit of a signed 64-bit integer as a decimal string. *)
let i64_limit = "9223372036854775808"

(* The deadline is a bound on the whole run (R6). Every visited node reads the
   clock so an expiry inside one value reports at stage decode within one
   node's work; a node counter multiplied that floor by the interval. The
   clock is a parameter and the counters are carried in the pass, so a test
   scripts the expiry at an exact node instead of measuring one.

   [deadline_stats] carries the counters: [ticks] counts the deadline checks
   fired and [nodes] the value nodes visited. One check per node is the
   property the descent holds, so the two counters agree on every pass, and a
   caller that keeps its own record reads both after the pass. *)

type deadline_stats = { mutable ticks : int; mutable nodes : int }

type descent = {
  deadline_at : float option;
  now : unit -> float;
  stats : deadline_stats;
}

(** Fresh counters for one instrumented pass. *)
let fresh_stats () = { ticks = 0; nodes = 0 }

(** Turn a remaining duration in seconds into an absolute deadline, or [None]
    when no duration was given. *)
let absolute_deadline ?(now = Unix.gettimeofday) = function
  | None -> None
  | Some remaining -> Some (now () +. remaining)

(** True when an absolute deadline is set and [now] has reached it. *)
let deadline_expired ?(now = Unix.gettimeofday) = function
  | Some at -> now () >= at
  | None -> false

(** Refuse class 0 naming [checkpoint] once the deadline has expired. *)
let check_deadline ?(now = Unix.gettimeofday) deadline_at checkpoint =
  if deadline_expired ~now deadline_at then
    refuse 0 "the deadline expired during the decode of the trace (%s)"
      checkpoint

(** Consult the deadline once and count the check. *)
let tick_descent descent =
  descent.stats.ticks <- descent.stats.ticks + 1;
  check_deadline ~now:descent.now descent.deadline_at "during the value descent"

(** Record one visited value node and consult the deadline at it. *)
let enter_node descent =
  descent.stats.nodes <- descent.stats.nodes + 1;
  tick_descent descent

(** Decode a Rust big-integer object (fields s, e and c) at [path] into an
    integer value, refusing class 12 when a field is malformed or the value
    falls outside the i64 range. *)
let decode_rust_bigint ~descent ~path members =
  let field key =
    match List.assoc_opt key members with
    | Some value -> value
    | None ->
        refuse 12 ~path "malformed Rust big-integer at %s: missing %s" path key
  in
  let bigint_text key value =
    match value with
    | Json_ast.Object [ (name, Json_ast.String text) ] when name = "#bigint" ->
        text
    | _ ->
        refuse 12 ~path
          "malformed Rust big-integer at %s: field %s is not a #bigint string"
          path key
  in
  let sign_text = bigint_text "s" (field "s") in
  if sign_text <> "1" && sign_text <> "-1" then
    refuse 12 ~path
      "malformed Rust big-integer at %s: field s sign text %s is not canonical"
      path sign_text;
  let exponent_text = bigint_text "e" (field "e") in
  let exponent_ok =
    exponent_text = "0"
    || String.length exponent_text > 0
       && exponent_text.[0] >= '1'
       && exponent_text.[0] <= '9'
       && String.for_all (fun c -> c >= '0' && c <= '9') exponent_text
  in
  if not exponent_ok then
    refuse 12 ~path
      "malformed Rust big-integer at %s: field e exponent text %s is not \
       canonical"
      path exponent_text;
  let chunks =
    match field "c" with
    | Json_ast.Array chunks ->
        List.map
          (fun chunk ->
            enter_node descent;
            bigint_text "c" chunk)
          chunks
    | _ ->
        refuse 12 ~path
          "malformed Rust big-integer at %s: field c is not an array" path
  in
  List.iter
    (fun text ->
      enter_node descent;
      if text = "" || not (String.for_all (fun c -> c >= '0' && c <= '9') text)
      then
        refuse 12 ~path
          "malformed Rust big-integer at %s: field c carries a non-decimal \
           chunk"
          path)
    chunks;
  let chunks =
    List.map
      (fun text ->
        enter_node descent;
        canonical_chunk text)
      chunks
  in
  if
    List.exists
      (fun s ->
        enter_node descent;
        String.length s > 14)
      chunks
  then
    refuse 12 ~path "malformed Rust big-integer at %s: a chunk exceeds the base"
      path;
  let values =
    List.map
      (fun text ->
        enter_node descent;
        int_of_string text)
      chunks
  in
  let count = List.length values in
  if count = 0 then
    refuse 12 ~path "malformed Rust big-integer at %s: field c is empty" path;
  let leading = List.hd values in
  let last = List.nth values (count - 1) in
  if leading = 0 then
    refuse 12 ~path "malformed Rust big-integer at %s: leading chunk is zero"
      path;
  if last = 0 then
    refuse 12 ~path
      "malformed Rust big-integer at %s: last stored chunk is zero" path;
  if String.length exponent_text > 2 then
    refuse 12 ~path
      "malformed Rust big-integer at %s: exponent e is outside the i64 range"
      path;
  let exponent = int_of_string exponent_text in
  let width = exponent + 1 in
  let groups = (width + 13) / 14 in
  if count > groups then
    refuse 12 ~path
      "malformed Rust big-integer at %s: chunk count exceeds the exponent's \
       group count"
      path;
  let leading_digits = String.length (List.hd chunks) in
  if leading_digits + (14 * (groups - 1)) <> width then
    refuse 12 ~path
      "malformed Rust big-integer at %s: chunk width does not match the \
       exponent"
      path;
  if width > 19 then
    refuse 12 ~path
      "malformed Rust big-integer at %s: value is outside the i64 range" path;
  let buf = Buffer.create width in
  Buffer.add_string buf (List.hd chunks);
  List.iteri
    (fun i chunk ->
      enter_node descent;
      if i > 0 then
        Buffer.add_string buf
          (String.make (14 - String.length chunk) '0' ^ chunk))
    chunks;
  let built = Buffer.contents buf in
  let built =
    if String.length built < width then
      built ^ String.make (width - String.length built) '0'
    else built
  in
  if String.length built <> width then
    refuse 12 ~path
      "malformed Rust big-integer at %s: decimal width is inconsistent" path;
  if width = 19 then begin
    if sign_text = "1" && built >= i64_limit then
      refuse 12 ~path
        "malformed Rust big-integer at %s: positive magnitude is outside the \
         i64 range"
        path;
    if sign_text = "-1" && built > i64_limit then
      refuse 12 ~path
        "malformed Rust big-integer at %s: negative magnitude is outside the \
         i64 range"
        path
  end;
  Itf_value.Int (if sign_text = "-1" then "-" ^ built else built)

(** Decode [json] at [path] into a value, using [ty] to type list, set, map,
    tuple and record elements. Refuses class 9, 10, 11 or 13 on a misplaced or
    unknown # constructor, a bare number, an unserialisable value or a null. *)
let rec decode_value ~descent ~ty ~path json =
  enter_node descent;
  match json with
  | Json_ast.Bool b -> Itf_value.Bool b
  | Json_ast.String s -> Itf_value.Str s
  | Json_ast.Null -> type_error ~path
  | Json_ast.Number _ -> refuse 10 ~path "bare JSON number at %s" path
  | Json_ast.Array items ->
      let elem_ty =
        match ty with Some (Ir_types.List t) -> Some t | _ -> None
      in
      Itf_value.List
        (List.mapi
           (fun i item ->
             decode_value ~descent ~ty:elem_ty
               ~path:(child path (string_of_int i))
               item)
           items)
  | Json_ast.Object members -> (
      check_duplicates ~base:path members;
      let hash_members =
        List.filter
          (fun (key, _) -> String.length key > 0 && key.[0] = '#')
          members
      in
      match hash_members with
      | [] -> decode_plain_object ~descent ~ty ~path members
      | [ (key, value) ] -> (
          if List.length members > 1 then
            refuse 9 ~path
              "the # constructor %s at %s appears beside other object members"
              key path;
          match key with
          | "#bigint" -> (
              match value with
              | Json_ast.String text when is_decimal_text text ->
                  Itf_value.Int text
              | _ ->
                  refuse 10 ~path "#bigint at %s is not a decimal string" path)
          | "#tup" -> (
              match value with
              | Json_ast.Array items ->
                  let slots =
                    match ty with
                    | Some (Ir_types.Tuple slots) -> slots
                    | _ -> []
                  in
                  Itf_value.Tuple
                    (List.mapi
                       (fun i item ->
                         decode_value ~descent ~ty:(List.nth_opt slots i)
                           ~path:(child path (string_of_int i))
                           item)
                       items)
              | _ -> refuse 10 ~path "#tup at %s is not an array" path)
          | "#set" -> (
              match value with
              | Json_ast.Array items ->
                  let elem_ty =
                    match ty with Some (Ir_types.Set t) -> Some t | _ -> None
                  in
                  Itf_value.Set
                    (List.mapi
                       (fun i item ->
                         decode_value ~descent ~ty:elem_ty
                           ~path:(child path (string_of_int i))
                           item)
                       items)
              | _ -> refuse 10 ~path "#set at %s is not an array" path)
          | "#map" -> (
              match value with
              | Json_ast.Array entries ->
                  let key_ty, value_ty =
                    match ty with
                    | Some (Ir_types.Map (k, v)) -> (Some k, Some v)
                    | _ -> (None, None)
                  in
                  Itf_value.Map
                    (List.mapi
                       (fun i entry ->
                         match entry with
                         | Json_ast.Array [ k; v ] ->
                             ( decode_value ~descent ~ty:key_ty
                                 ~path:(child path (string_of_int i) ^ "/0")
                                 k,
                               decode_value ~descent ~ty:value_ty
                                 ~path:(child path (string_of_int i) ^ "/1")
                                 v )
                         | _ ->
                             refuse 10 ~path
                               "#map entry at %s is not a two-element array"
                               path)
                       entries)
              | _ -> refuse 10 ~path "#map at %s is not an array" path)
          | "#unserializable" ->
              refuse 11 ~path "#unserializable value at %s" path
          | other -> refuse 9 ~path "unknown # constructor %s at %s" other path)
      | _ ->
          let names =
            String.concat ", " (List.map (fun (key, _) -> key) hash_members)
          in
          refuse 9 ~path "more than one # key at %s: %s" path names)

and decode_plain_object ~descent ~ty ~path members =
  let exact_two =
    List.length members = 2
    && List.mem_assoc "tag" members
    && List.mem_assoc "value" members
  in
  if exact_two then
    begin match ty with
    | Some (Ir_types.Record _) -> collision ~path "tag/value" "a variant"
    | _ -> (
        match List.assoc "tag" members with
        | Json_ast.String tag ->
            let payload_ty =
              match ty with
              | Some (Ir_types.Variant variants) -> List.assoc_opt tag variants
              | _ -> None
            in
            Itf_value.Variant
              ( tag,
                decode_value ~descent ~ty:payload_ty ~path:(child path "value")
                  (List.assoc "value" members) )
        | _ -> refuse 10 ~path "variant tag at %s is not a string" path)
    end
  else
    match members with
    | [ ("tag", Json_ast.String "UNIT") ] -> (
        match ty with
        | Some (Ir_types.Record _) -> collision ~path "tag/UNIT" "a unit"
        | _ -> Itf_value.Unit)
    | _ -> (
        let exact_three =
          List.length members = 3
          && List.mem_assoc "s" members && List.mem_assoc "e" members
          && List.mem_assoc "c" members
        in
        match ty with
        | Some Ir_types.Int when exact_three ->
            decode_rust_bigint ~descent ~path members
        | _ ->
            Itf_value.Record
              (List.map
                 (fun (key, value) ->
                   let field_ty =
                     match ty with
                     | Some (Ir_types.Record fields) ->
                         List.assoc_opt key fields
                     | _ -> None
                   in
                   ( key,
                     decode_value ~descent ~ty:field_ty ~path:(child path key)
                       value ))
                 members))

(** Check [value] against [ty] at [path], refusing class 13 on a mismatch or an
    unresolved declared type and class 16 when a record position receives a
    variant or unit shape. *)
let rec check_type ~descent ~ty ~path value =
  enter_node descent;
  match (ty, value) with
  | Ir_types.Int, Itf_value.Int _
  | Ir_types.Str, Itf_value.Str _
  | Ir_types.Bool, Itf_value.Bool _ ->
      ()
  | Ir_types.List elem, Itf_value.List items ->
      List.iteri
        (fun i item ->
          check_type ~descent ~ty:elem ~path:(child path (string_of_int i)) item)
        items
  | Ir_types.Set elem, Itf_value.Set items ->
      List.iteri
        (fun i item ->
          check_type ~descent ~ty:elem ~path:(child path (string_of_int i)) item)
        items
  | Ir_types.Tuple slots, Itf_value.Tuple items ->
      if List.length slots <> List.length items then type_error ~path
      else
        let rec loop i slots items =
          match (slots, items) with
          | [], [] -> ()
          | slot :: slots, item :: items ->
              check_type ~descent ~ty:slot
                ~path:(child path (string_of_int i))
                item;
              loop (i + 1) slots items
          | _ -> type_error ~path
        in
        loop 0 slots items
  | Ir_types.Tuple [], Itf_value.Unit -> ()
  | Ir_types.Map (key_ty, value_ty), Itf_value.Map entries ->
      List.iteri
        (fun i (k, v) ->
          check_type ~descent ~ty:key_ty
            ~path:(child path (string_of_int i) ^ "/0")
            k;
          check_type ~descent ~ty:value_ty
            ~path:(child path (string_of_int i) ^ "/1")
            v)
        entries
  | Ir_types.Record fields, Itf_value.Record actual ->
      let expected = List.map fst fields in
      let got = List.map fst actual in
      let sorted = List.sort String.compare in
      if sorted expected <> sorted got then type_error ~path
      else
        List.iter
          (fun (key, field_ty) ->
            match List.assoc_opt key actual with
            | Some value ->
                check_type ~descent ~ty:field_ty ~path:(child path key) value
            | None -> type_error ~path)
          fields
  | Ir_types.Record _, Itf_value.Variant _ | Ir_types.Record _, Itf_value.Unit
    ->
      collision ~path "tag/value" "a variant or unit"
  | Ir_types.Variant variants, Itf_value.Variant (tag, payload) -> (
      match List.assoc_opt tag variants with
      | Some payload_ty ->
          check_type ~descent ~ty:payload_ty ~path:(child path "value") payload
      | None -> type_error ~path)
  | Ir_types.Unresolved why, _ ->
      refuse 13 ~path
        "the declared type of variable %s in state %s cannot be resolved: %s"
        (path_var path) (path_state path) why
  | _, _ -> type_error ~path

(* The structural value walk: the type-independent checks over a declared
   variable's value. It runs between the preparse and the typed phase, so a
   trace whose value cannot be decoded is refused at stage decode before any
   declaration type exists (R13, R44). The caller supplies the declared names
   only: an ignored key's value is never walked (R10). *)

(** Walk a declared variable's value at [path], refusing the structural errors
    that need no declared type: a bare number or a misplaced or malformed #
    constructor. *)
let rec walk_value ~descent ~path json =
  enter_node descent;
  match json with
  | Json_ast.Bool _ | Json_ast.String _ | Json_ast.Null -> ()
  | Json_ast.Number _ -> refuse 10 ~path "bare JSON number at %s" path
  | Json_ast.Array items ->
      List.iteri
        (fun i item ->
          walk_value ~descent ~path:(child path (string_of_int i)) item)
        items
  | Json_ast.Object members -> (
      check_duplicates ~base:path members;
      let hash_members =
        List.filter
          (fun (key, _) -> String.length key > 0 && key.[0] = '#')
          members
      in
      match hash_members with
      | [] ->
          let exact_two =
            List.length members = 2
            && List.mem_assoc "tag" members
            && List.mem_assoc "value" members
          in
          if exact_two then
            (* A variant payload is a value position only when the tag is a
            string; a non-string tag is the typed phase's malformed-variant
            refusal. *)
            match List.assoc_opt "tag" members with
            | Some (Json_ast.String _) ->
                walk_value ~descent ~path:(child path "value")
                  (List.assoc "value" members)
            | _ -> ()
          else
            List.iter
              (fun (key, value) ->
                walk_value ~descent ~path:(child path key) value)
              members
      | [ (key, value) ] -> (
          if List.length members > 1 then
            refuse 9 ~path
              "the # constructor %s at %s appears beside other object members"
              key path;
          match key with
          | "#bigint" -> (
              match value with
              | Json_ast.String text when is_decimal_text text -> ()
              | _ ->
                  refuse 10 ~path "#bigint at %s is not a decimal string" path)
          | "#tup" | "#set" -> (
              match value with
              | Json_ast.Array items ->
                  List.iteri
                    (fun i item ->
                      walk_value ~descent
                        ~path:(child path (string_of_int i))
                        item)
                    items
              | _ -> refuse 10 ~path "%s at %s is not an array" key path)
          | "#map" -> (
              match value with
              | Json_ast.Array entries ->
                  List.iteri
                    (fun i entry ->
                      match entry with
                      | Json_ast.Array [ k; v ] ->
                          walk_value ~descent
                            ~path:(child path (string_of_int i) ^ "/0")
                            k;
                          walk_value ~descent
                            ~path:(child path (string_of_int i) ^ "/1")
                            v
                      | _ ->
                          refuse 10 ~path
                            "#map entry at %s is not a two-element array" path)
                    entries
              | _ -> refuse 10 ~path "#map at %s is not an array" path)
          | "#unserializable" ->
              refuse 11 ~path "#unserializable value at %s" path
          | other -> refuse 9 ~path "unknown # constructor %s at %s" other path)
      | _ ->
          let names =
            String.concat ", " (List.map (fun (key, _) -> key) hash_members)
          in
          refuse 9 ~path "more than one # key at %s: %s" path names)

(** True when [needle] occurs in [text]; an empty needle matches. *)
let contains_text text needle =
  let n = String.length needle and h = String.length text in
  let rec loop i =
    if i + n > h then false
    else if String.sub text i n = needle then true
    else loop (i + 1)
  in
  n = 0 || loop 0

type parsed = {
  sha256 : string;
  meta : trace_meta;
  vars : string list;
  state_items : Json_ast.t list;
  loop : int option;
  unknown_top_level_fields : string list;
  source_mismatch : bool;
  metas : Json_ast.t option array;
}

(** Build a decode-stage refusal from its class, message, path and offset. *)
let refusal klass detail path offset =
  { stage = "decode"; klass; message = detail; path; offset }

(* One JSON path per diagnostic: the message keeps the path it names and the
   suffix carries it only when the message does not already embed it. *)

(** Build the refusal for a caught [Refuse], prefixing the stage and class and
    appending the byte offset, plus the JSON path unless the detail already
    names it. *)
let caught_refusal (klass, detail, path, offset) =
  let suffix =
    match (path, offset) with
    | Some path, Some offset -> Printf.sprintf " at %s (byte %d)" path offset
    | Some path, None ->
        if contains_text detail path then "" else Printf.sprintf " at %s" path
    | None, Some offset -> Printf.sprintf " (byte %d)" offset
    | None, None -> ""
  in
  let message =
    if klass = 0 then Printf.sprintf "decode: %s%s" detail suffix
    else Printf.sprintf "decode: class %d: %s%s" klass detail suffix
  in
  refusal klass message path offset

(* The structural phase. It parses the document and applies every check that
   needs no declaration types: the top-level and state shapes, the metadata,
   the loop index and the strict-source rule. The typed value phase below
   consumes the result once the declaration types are derived. *)

(** Parse [raw] and apply every check that needs no declaration type: the
    top-level and state shapes, metadata, loop index and strict-source rule.
    Returns the parsed trace, or [Error] with the first refusal. *)
let preparse_at ?spec_path ?(strict_source = false) ?deadline_at (raw : string)
    : (parsed, refusal) result =
  let sha256 = Sha256.hex raw in
  let error klass message path offset =
    Error (refusal klass message path offset)
  in
  if deadline_expired deadline_at then
    error 0 "decode: the deadline expired before the document parse" None None
  else
    match Json_parse.parse raw with
    | Error parse_error ->
        if parse_error.Json_parse.kind = Json_parse.Utf8 then
          error 14
            (Printf.sprintf "decode: class 14: invalid UTF-8 at byte %d"
               parse_error.offset)
            None (Some parse_error.offset)
        else if parse_error.message = "trailing data" then
          error 1
            (Printf.sprintf "decode: class 1: trailing data at byte %d"
               parse_error.offset)
            None (Some parse_error.offset)
        else if
          parse_error.message = "unexpected end of input"
          || parse_error.message = "empty document"
        then
          error 1
            (Printf.sprintf "decode: class 1: truncated JSON at byte %d"
               parse_error.offset)
            None (Some parse_error.offset)
        else
          error 1
            (Printf.sprintf "decode: class 1: not JSON at byte %d: %s"
               parse_error.offset parse_error.message)
            None (Some parse_error.offset)
    | Ok root -> (
        try
          check_deadline deadline_at "after the document parse";
          let members =
            match root with
            | Json_ast.Object members -> members
            | _ -> refuse 2 "top level is not an object"
          in
          check_duplicates ~base:"" members;
          let known = [ "vars"; "states"; "#meta"; "loop"; "params" ] in
          let unknown_top_level_fields =
            List.sort_uniq String.compare
              (List.filter_map
                 (fun (key, _) -> if List.mem key known then None else Some key)
                 members)
          in
          let vars =
            match List.assoc_opt "vars" members with
            | Some (Json_ast.Array items) ->
                let names =
                  List.mapi
                    (fun i item ->
                      check_deadline deadline_at "during the typed descent";
                      match item with
                      | Json_ast.String s -> s
                      | _ ->
                          refuse 2
                            ~path:(Printf.sprintf "vars/%d" i)
                            "vars element %d at vars/%d is not a string" i i)
                    items
                in
                let seen = Hashtbl.create 16 in
                let deduped =
                  List.filter
                    (fun name ->
                      if Hashtbl.mem seen name then false
                      else (
                        Hashtbl.add seen name ();
                        true))
                    names
                in
                if deduped = [] then refuse 15 ~path:"vars" "vars is empty";
                List.iteri
                  (fun i name ->
                    if name = "" then
                      refuse 15
                        ~path:(Printf.sprintf "vars/%d" i)
                        "vars contains an empty name at vars/%d" i)
                  deduped;
                deduped
            | Some _ -> refuse 2 ~path:"vars" "vars must be an array"
            | None -> refuse 2 ~path:"vars" "vars is missing"
          in
          let state_items =
            match List.assoc_opt "states" members with
            | Some (Json_ast.Array []) ->
                refuse 3 ~path:"states" "states is empty"
            | Some (Json_ast.Array items) -> items
            | Some _ -> refuse 2 ~path:"states" "states must be an array"
            | None -> refuse 2 ~path:"states" "states is missing"
          in
          let meta =
            match List.assoc_opt "#meta" members with
            | None -> empty_meta
            | Some (Json_ast.Object meta_members) ->
                check_duplicates ~base:"#meta" meta_members;
                {
                  format = string_option "format" meta_members;
                  source = string_option "source" meta_members;
                  status = string_option "status" meta_members;
                  description = string_option "description" meta_members;
                  timestamp = string_option "timestamp" meta_members;
                  source_type = non_string_type "source" meta_members;
                  status_type = non_string_type "status" meta_members;
                }
            | Some _ ->
                refuse 2 ~path:"#meta" "top-level #meta must be an object"
          in
          let state_count = List.length state_items in
          let loop =
            match List.assoc_opt "loop" members with
            | None -> None
            | Some (Json_ast.Number raw_number)
              when Json_ast.number_is_integer raw_number -> (
                match float_to_int (float_of_string raw_number) with
                | Some value when value >= 0 && value < state_count ->
                    Some value
                | Some value ->
                    refuse 7 ~path:"loop"
                      "loop index %d is outside the state range [0, %d]" value
                      (state_count - 1)
                | None ->
                    refuse 7 ~path:"loop" "loop is outside the integer range")
            | Some _ ->
                refuse 7 ~path:"loop"
                  "loop must be an integer in the state range"
          in
          (match List.assoc_opt "params" members with
          | None | Some (Json_ast.Array []) -> ()
          | Some (Json_ast.Array _) ->
              refuse 8 ~path:"params"
                "params must be an empty array; trace-level parameters have no \
                 evaluation channel in this version"
          | Some value ->
              refuse 8 ~path:"params" "params must be an array, got %s"
                (Json_ast.type_name value));
          if strict_source then
            begin match meta.source with
            | Some source -> (
                match spec_path with
                | Some path when source = path -> ()
                | Some path ->
                    refuse 0 ~path:"#meta/source"
                      "strict-source: #meta.source %s does not match the \
                       supplied specification path %s"
                      source path
                | None ->
                    refuse 0 ~path:"#meta/source"
                      "strict-source: #meta.source %s has no supplied \
                       specification path to match"
                      source)
            | None ->
                refuse 0 ~path:"#meta/source"
                  "strict-source: #meta.source is absent or not a string"
            end;
          let source_mismatch =
            match (meta.source, spec_path) with
            | Some source, Some path -> source <> path
            | _ -> false
          in
          let indices = Array.make state_count None in
          let metas = Array.make state_count None in
          List.iteri
            (fun i item ->
              check_deadline deadline_at "during the structural state pass";
              match item with
              | Json_ast.Object state_members -> (
                  let base = Printf.sprintf "states/%d" i in
                  check_duplicates ~base state_members;
                  match List.assoc_opt "#meta" state_members with
                  | None -> ()
                  | Some (Json_ast.Object meta_members) -> (
                      check_duplicates ~base:(base ^ "/#meta") meta_members;
                      metas.(i) <- Some (Json_ast.Object meta_members);
                      match List.assoc_opt "index" meta_members with
                      | None -> ()
                      | Some (Json_ast.Number raw_index)
                        when Json_ast.number_is_integer raw_index -> (
                          match float_to_int (float_of_string raw_index) with
                          | Some value -> indices.(i) <- Some value
                          | None ->
                              refuse 6 ~path:(base ^ "/#meta")
                                "#meta.index at %s is outside the integer range"
                                base)
                      | Some _ ->
                          refuse 6 ~path:(base ^ "/#meta")
                            "#meta.index at %s is not an integer" base)
                  | Some _ ->
                      refuse 6 ~path:(base ^ "/#meta")
                        "#meta at %s is not an object" base)
              | _ ->
                  refuse 4
                    ~path:(Printf.sprintf "states/%d" i)
                    "state at states/%d is not an object" i)
            state_items;
          let any_index = Array.exists (fun value -> value <> None) indices in
          if any_index then
            Array.iteri
              (fun i value ->
                match value with
                | None ->
                    refuse 6
                      ~path:(Printf.sprintf "states/%d/#meta" i)
                      "state states/%d has no #meta.index while other states \
                       carry one"
                      i
                | Some index ->
                    if index <> i then
                      refuse 6
                        ~path:(Printf.sprintf "states/%d/#meta" i)
                        "#meta.index at states/%d is %d, expected the array \
                         position %d"
                        i index i)
              indices;
          Ok
            {
              sha256;
              meta;
              vars;
              state_items;
              loop;
              unknown_top_level_fields;
              source_mismatch;
              metas;
            }
        with Refuse (klass, detail, path, offset) ->
          Error (caught_refusal (klass, detail, path, offset)))

(* The structural value pass: the declared names are readable from the IR
   before any type is resolved, so the type-independent refusals inside a
   declared value land at stage decode ahead of every resolution refusal
   (R44). When no declaration name is derivable the trace's own vars array
   bounds the walk; the typed phase still checks the real declarations. *)

(** Walk the declared [names]' values through every state of [parsed], returning
    [Error] with the first structural refusal. [now] is the clock the deadline
    is read from and [stats] the counters the pass records into; both exist so a
    test can script the expiry and read the node counts, and neither changes
    what a default call does. *)
let decode_structural_at ?deadline_at ?(now = Unix.gettimeofday)
    ?(stats = fresh_stats ()) ~names (parsed : parsed) : (unit, refusal) result
    =
  try
    let descent = { deadline_at; now; stats } in
    List.iteri
      (fun i item ->
        check_deadline ~now deadline_at "during the structural value pass";
        match item with
        | Json_ast.Object state_members ->
            List.iter
              (fun name ->
                match List.assoc_opt name state_members with
                | None -> ()
                | Some value ->
                    walk_value ~descent
                      ~path:(Printf.sprintf "states/%d/%s" i name)
                      value)
              names
        | _ -> ())
      parsed.state_items;
    check_deadline ~now deadline_at "during the structural value pass";
    Ok ()
  with Refuse (klass, detail, path, offset) ->
    Error (caught_refusal (klass, detail, path, offset))

(* The typed value phase: declaration types direct every state value's
   normalisation and type check, and the declared set fixes the ignored-key
   report. It runs only after the declaration types exist. *)

(** Decode and type-check each declared variable's value in every state of
    [parsed] and return the trace, or [Error] with the first refusal. A
    duplicated IR table key is refused when every declaration type resolved.
    [now] is the clock the deadline is read from and [stats] the counters the
    pass records into; see [decode_structural_at]. *)
let decode_typed_at ?deadline_at ?(now = Unix.gettimeofday)
    ?(stats = fresh_stats ()) ?(duplicates = []) ~decls (parsed : parsed) :
    (trace, refusal) result =
  try
    check_deadline ~now deadline_at "before the typed value phase";
    let unresolved_decl =
      List.exists
        (fun (_, ty) ->
          match ty with Ir_types.Unresolved _ -> true | _ -> false)
        decls
    in
    (match duplicates with
    | key :: _ when not unresolved_decl ->
        refuse 13
          "the IR table carries the key %s more than once; the entry is not \
           determined"
          key
    | _ -> ());
    let descent = { deadline_at; now; stats } in
    let declared_names = List.map fst decls in
    let states =
      List.mapi
        (fun i item ->
          check_deadline ~now deadline_at "during the typed descent";
          match item with
          | Json_ast.Object state_members ->
              let values =
                List.map
                  (fun (name, ty) ->
                    match List.assoc_opt name state_members with
                    | None ->
                        refuse 5
                          ~path:(Printf.sprintf "states/%d/%s" i name)
                          "declared variable %s is missing from state %d at \
                           states/%d/%s"
                          name i i name
                    | Some value_json ->
                        let path = Printf.sprintf "states/%d/%s" i name in
                        let value =
                          decode_value ~descent ~ty:(Some ty) ~path value_json
                        in
                        check_type ~descent ~ty ~path value;
                        (name, value))
                  decls
              in
              { index = i; values; meta = parsed.metas.(i) }
          | _ -> assert false)
        parsed.state_items
    in
    check_deadline ~now deadline_at "after the last state";
    let ignored_vars =
      List.sort_uniq String.compare
        (List.concat_map
           (fun item ->
             match item with
             | Json_ast.Object state_members ->
                 List.filter_map
                   (fun (key, _) ->
                     if key = "#meta" || List.mem key declared_names then None
                     else Some key)
                   state_members
             | _ -> [])
           parsed.state_items)
    in
    Ok
      {
        meta = parsed.meta;
        vars = parsed.vars;
        states;
        loop = parsed.loop;
        params = [];
        unknown_top_level_fields = parsed.unknown_top_level_fields;
        ignored_vars;
        source_mismatch = parsed.source_mismatch;
        sha256 = parsed.sha256;
      }
  with Refuse (klass, detail, path, offset) ->
    Error (caught_refusal (klass, detail, path, offset))

(** [preparse_at] taking a remaining duration in seconds rather than an absolute
    deadline. *)
let preparse ?spec_path ?strict_source ?deadline raw =
  preparse_at ?spec_path ?strict_source
    ?deadline_at:(absolute_deadline deadline)
    raw

(** [decode_typed_at] taking a remaining duration in seconds rather than an
    absolute deadline. *)
let decode_typed ?deadline ?duplicates ~decls parsed =
  decode_typed_at
    ?deadline_at:(absolute_deadline deadline)
    ?duplicates ~decls parsed

(** [decode_structural_at] taking a remaining duration in seconds rather than an
    absolute deadline. *)
let decode_structural ?deadline ~names parsed =
  decode_structural_at ?deadline_at:(absolute_deadline deadline) ~names parsed

(** Run the structural, value and typed phases in order over [raw] and return
    the trace, or the first refusal. The value walk takes the declared names,
    falling back to the trace's own vars when [decls] is empty. *)
let decode ?spec_path ?strict_source ?deadline ?duplicates ~decls (raw : string)
    : (trace, refusal) result =
  let deadline_at = absolute_deadline deadline in
  match preparse_at ?spec_path ?strict_source ?deadline_at raw with
  | Error refusal -> Error refusal
  | Ok parsed -> (
      let names =
        match List.map fst decls with [] -> parsed.vars | names -> names
      in
      match decode_structural_at ?deadline_at ~names parsed with
      | Error refusal -> Error refusal
      | Ok () -> decode_typed_at ?deadline_at ?duplicates ~decls parsed)
