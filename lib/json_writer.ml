(* Compact JSON rendering. The decoder keeps integer literals as exact text,
   so numbers are emitted as their source spelling and never pass through a
   floating-point value. Licence: AGPL-3.0-or-later; see README.md. *)

(** [escape buf text] writes [text] to [buf] with the JSON string escapes
    applied to quotes, backslashes and control characters. *)
let escape buf text =
  String.iter
    (fun c ->
      match c with
      | '"' -> Buffer.add_string buf "\\\""
      | '\\' -> Buffer.add_string buf "\\\\"
      | '\n' -> Buffer.add_string buf "\\n"
      | '\r' -> Buffer.add_string buf "\\r"
      | '\t' -> Buffer.add_string buf "\\t"
      | c when Char.code c < 0x20 ->
          Buffer.add_string buf (Printf.sprintf "\\u%04x" (Char.code c))
      | c -> Buffer.add_char buf c)
    text

(** [write buf json] appends the compact JSON text of a document to [buf],
    emitting numbers as their source spelling. *)
let rec write buf = function
  | Json_ast.Null -> Buffer.add_string buf "null"
  | Json_ast.Bool true -> Buffer.add_string buf "true"
  | Json_ast.Bool false -> Buffer.add_string buf "false"
  | Json_ast.Number raw -> Buffer.add_string buf raw
  | Json_ast.String text ->
      Buffer.add_char buf '"';
      escape buf text;
      Buffer.add_char buf '"'
  | Json_ast.Array items ->
      Buffer.add_char buf '[';
      List.iteri
        (fun index item ->
          if index > 0 then Buffer.add_char buf ',';
          write buf item)
        items;
      Buffer.add_char buf ']'
  | Json_ast.Object members ->
      Buffer.add_char buf '{';
      List.iteri
        (fun index (key, value) ->
          if index > 0 then Buffer.add_char buf ',';
          Buffer.add_char buf '"';
          escape buf key;
          Buffer.add_string buf "\":";
          write buf value)
        members;
      Buffer.add_char buf '}'

(** [to_string json] renders a document as compact JSON text. *)
let to_string document =
  let buf = Buffer.create 256 in
  write buf document;
  Buffer.contents buf
