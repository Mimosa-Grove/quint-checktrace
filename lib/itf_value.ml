(* Decoded ITF values. Integers carry canonical decimal text, never a
   floating-point value. Licence: AGPL-3.0-or-later; see README.md. *)

type t =
  | Bool of bool
  | Str of string
  | Int of string
  | List of t list
  | Tuple of t list
  | Set of t list
  | Map of (t * t) list
  | Record of (string * t) list
  | Variant of string * t
  | Unit
