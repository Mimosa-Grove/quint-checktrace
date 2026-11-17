(* JSON document tree. Duplicate object member names are preserved so the
   decoder can refuse them at the depth where it decodes. Licence:
   AGPL-3.0-or-later; see README.md. *)

type t =
  | Null
  | Bool of bool
  | Number of string
  | String of string
  | Array of t list
  | Object of (string * t) list

(** [number_float raw] parses the literal text of a number, or gives [None] when
    the text is not a float. *)
let number_float (raw : string) : float option =
  match float_of_string_opt raw with Some f -> Some f | None -> None

(** [number_is_integer raw] is true when the number text denotes a finite value
    with no fractional part. *)
let number_is_integer (raw : string) : bool =
  match number_float raw with
  | Some f -> Float.is_finite f && Float.floor f = f
  | None -> false

(** [equal a b] compares two documents by shape and content. Numbers match by
    value when both texts parse, otherwise by text. *)
let rec equal (a : t) (b : t) : bool =
  match (a, b) with
  | Null, Null -> true
  | Bool x, Bool y -> x = y
  | Number x, Number y -> (
      match (number_float x, number_float y) with
      | Some fx, Some fy -> fx = fy
      | _ -> x = y)
  | String x, String y -> x = y
  | Array xs, Array ys ->
      List.length xs = List.length ys && List.for_all2 equal xs ys
  | Object xs, Object ys ->
      List.length xs = List.length ys
      && List.for_all
           (fun (k, v) ->
             match List.assoc_opt k ys with
             | Some w -> equal v w
             | None -> false)
           xs
  | _ -> false

(** [member key json] is the value of member [key] of a JSON object, or [None]
    when there is no object or no such member. *)
let member key = function
  | Object members -> List.assoc_opt key members
  | _ -> None

(** [member_names json] lists the member names of a JSON object in order, and is
    empty for any other document. *)
let member_names = function Object members -> List.map fst members | _ -> []

(** [has_member key json] is true when [json] is an object holding a member
    named [key]. *)
let has_member key obj = member key obj <> None

(** [duplicate_names members] lists, in order of first appearance, the member
    names that occur more than once. *)
let duplicate_names (members : (string * t) list) : string list =
  let seen = Hashtbl.create 16 in
  let dups = ref [] in
  List.iter
    (fun (k, _) ->
      if Hashtbl.mem seen k then (
        if not (List.mem k !dups) then dups := k :: !dups)
      else Hashtbl.add seen k ())
    members;
  List.rev !dups

(* JSON Schema counts string lengths in Unicode code points. Strings reaching
   this function are valid UTF-8, so continuation bytes are the only bytes
   that do not start a code point. *)

(** [utf8_length s] counts Unicode code points in valid UTF-8 text by skipping
    continuation bytes. *)
let utf8_length (s : string) : int =
  let n = ref 0 in
  String.iter (fun c -> if Char.code c land 0xC0 <> 0x80 then incr n) s;
  !n

(** [type_name json] names the JSON type of a document, reporting an integral
    number as "integer". *)
let type_name = function
  | Null -> "null"
  | Bool _ -> "boolean"
  | Number raw -> if number_is_integer raw then "integer" else "number"
  | String _ -> "string"
  | Array _ -> "array"
  | Object _ -> "object"

(* The report carries the observed JSON type of a non-string metadata field.
   JSON has one number type, so an integral value is still "number" here. *)

(** [json_type_name json] names the JSON type of a document, reporting every
    number as "number". *)
let json_type_name = function
  | Null -> "null"
  | Bool _ -> "boolean"
  | Number _ -> "number"
  | String _ -> "string"
  | Array _ -> "array"
  | Object _ -> "object"
