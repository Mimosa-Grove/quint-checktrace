(* JSON parser with byte-offset diagnostics and duplicate member retention.
   The decoder's pre-parse refusal classes need the offset of the first
   invalid byte, of the end of input, or of the first trailing byte.
   Licence: AGPL-3.0-or-later; see README.md. *)

type error_kind = Utf8 | Syntax
type error = { kind : error_kind; offset : int; message : string }

exception Fail of int * string
exception Trunc

(** [is_ws c] is true for the four JSON whitespace characters. *)
let is_ws = function ' ' | '\t' | '\n' | '\r' -> true | _ -> false

(** [is_digit c] is true for an ASCII decimal digit. *)
let is_digit c = c >= '0' && c <= '9'

(** [is_hex c] is true for an ASCII hexadecimal digit. *)
let is_hex = function
  | '0' .. '9' | 'a' .. 'f' | 'A' .. 'F' -> true
  | _ -> false

(** [hex_value c] is the value of a hexadecimal digit, or 0 for any other
    character. *)
let hex_value = function
  | '0' .. '9' as c -> Char.code c - Char.code '0'
  | 'a' .. 'f' as c -> Char.code c - Char.code 'a' + 10
  | 'A' .. 'F' as c -> Char.code c - Char.code 'A' + 10
  | _ -> 0

(** [add_utf8 buf cp] appends code point [cp] to [buf] as UTF-8 bytes. *)
let add_utf8 (buf : Buffer.t) (cp : int) =
  if cp < 0x80 then Buffer.add_char buf (Char.chr cp)
  else if cp < 0x800 then begin
    Buffer.add_char buf (Char.chr (0xC0 lor (cp lsr 6)));
    Buffer.add_char buf (Char.chr (0x80 lor (cp land 0x3F)))
  end
  else if cp < 0x10000 then begin
    Buffer.add_char buf (Char.chr (0xE0 lor (cp lsr 12)));
    Buffer.add_char buf (Char.chr (0x80 lor ((cp lsr 6) land 0x3F)));
    Buffer.add_char buf (Char.chr (0x80 lor (cp land 0x3F)))
  end
  else begin
    Buffer.add_char buf (Char.chr (0xF0 lor (cp lsr 18)));
    Buffer.add_char buf (Char.chr (0x80 lor ((cp lsr 12) land 0x3F)));
    Buffer.add_char buf (Char.chr (0x80 lor ((cp lsr 6) land 0x3F)));
    Buffer.add_char buf (Char.chr (0x80 lor (cp land 0x3F)))
  end

(** [parse s] decodes a JSON document. Returns [Error] holding the byte offset
    and a message when the text is not valid UTF-8, is empty, ends early or
    carries data after the document. *)
let parse (s : string) : (Json_ast.t, error) result =
  match Utf8.first_invalid s with
  | Some offset -> Error { kind = Utf8; offset; message = "invalid UTF-8" }
  | None -> (
      let n = String.length s in
      let pos = ref 0 in
      let skip_ws () =
        while !pos < n && is_ws s.[!pos] do
          incr pos
        done
      in
      let need_char () = if !pos >= n then raise Trunc in
      let fail at msg = raise (Fail (at, msg)) in
      let hex4 () =
        if !pos + 4 > n then raise Trunc;
        let v = ref 0 in
        for k = 0 to 3 do
          let c = s.[!pos + k] in
          if not (is_hex c) then fail (!pos + k) "invalid hexadecimal escape";
          v := (!v lsl 4) lor hex_value c
        done;
        pos := !pos + 4;
        !v
      in
      let rec parse_string () =
        incr pos;
        let buf = Buffer.create 16 in
        let rec loop () =
          need_char ();
          let c = s.[!pos] in
          if c = '"' then (
            incr pos;
            Buffer.contents buf)
          else if c = '\\' then begin
            let esc = !pos in
            incr pos;
            need_char ();
            let e = s.[!pos] in
            incr pos;
            match e with
            | '"' ->
                Buffer.add_char buf '"';
                loop ()
            | '\\' ->
                Buffer.add_char buf '\\';
                loop ()
            | '/' ->
                Buffer.add_char buf '/';
                loop ()
            | 'b' ->
                Buffer.add_char buf '\b';
                loop ()
            | 'f' ->
                Buffer.add_char buf '\012';
                loop ()
            | 'n' ->
                Buffer.add_char buf '\n';
                loop ()
            | 'r' ->
                Buffer.add_char buf '\r';
                loop ()
            | 't' ->
                Buffer.add_char buf '\t';
                loop ()
            | 'u' ->
                let hi = hex4 () in
                if hi >= 0xD800 && hi <= 0xDBFF then begin
                  if !pos + 1 >= n then raise Trunc;
                  if s.[!pos] <> '\\' || s.[!pos + 1] <> 'u' then
                    fail esc "unpaired high surrogate";
                  pos := !pos + 2;
                  let lo = hex4 () in
                  if lo < 0xDC00 || lo > 0xDFFF then
                    fail esc "invalid low surrogate";
                  let cp = 0x10000 + ((hi - 0xD800) lsl 10) + (lo - 0xDC00) in
                  add_utf8 buf cp;
                  loop ()
                end
                else if hi >= 0xDC00 && hi <= 0xDFFF then
                  fail esc "unpaired low surrogate"
                else (
                  add_utf8 buf hi;
                  loop ())
            | _ -> fail esc "invalid escape"
          end
          else if Char.code c < 0x20 then
            fail !pos "control character in string"
          else (
            Buffer.add_char buf c;
            incr pos;
            loop ())
        in
        loop ()
      and parse_number () =
        let start = !pos in
        if s.[!pos] = '-' then incr pos;
        need_char ();
        if s.[!pos] = '0' then incr pos
        else if s.[!pos] >= '1' && s.[!pos] <= '9' then
          while !pos < n && is_digit s.[!pos] do
            incr pos
          done
        else fail start "malformed number";
        if !pos < n && s.[!pos] = '.' then begin
          incr pos;
          need_char ();
          if not (is_digit s.[!pos]) then fail start "malformed number";
          while !pos < n && is_digit s.[!pos] do
            incr pos
          done
        end;
        if !pos < n && (s.[!pos] = 'e' || s.[!pos] = 'E') then begin
          incr pos;
          if !pos < n && (s.[!pos] = '+' || s.[!pos] = '-') then incr pos;
          need_char ();
          if not (is_digit s.[!pos]) then fail start "malformed number";
          while !pos < n && is_digit s.[!pos] do
            incr pos
          done
        end;
        Json_ast.Number (String.sub s start (!pos - start))
      and parse_object () =
        incr pos;
        skip_ws ();
        need_char ();
        if s.[!pos] = '}' then (
          incr pos;
          Json_ast.Object [])
        else begin
          let members = ref [] in
          let rec loop () =
            skip_ws ();
            need_char ();
            if s.[!pos] <> '"' then fail !pos "expected object member name";
            let key = parse_string () in
            skip_ws ();
            need_char ();
            if s.[!pos] <> ':' then fail !pos "expected ':'";
            incr pos;
            let value = parse_value () in
            members := (key, value) :: !members;
            skip_ws ();
            need_char ();
            match s.[!pos] with
            | ',' ->
                incr pos;
                loop ()
            | '}' ->
                incr pos;
                Json_ast.Object (List.rev !members)
            | _ -> fail !pos "expected ',' or '}'"
          in
          loop ()
        end
      and parse_array () =
        incr pos;
        skip_ws ();
        need_char ();
        if s.[!pos] = ']' then (
          incr pos;
          Json_ast.Array [])
        else begin
          let items = ref [] in
          let rec loop () =
            let value = parse_value () in
            items := value :: !items;
            skip_ws ();
            need_char ();
            match s.[!pos] with
            | ',' ->
                incr pos;
                loop ()
            | ']' ->
                incr pos;
                Json_ast.Array (List.rev !items)
            | _ -> fail !pos "expected ',' or ']'"
          in
          loop ()
        end
      and parse_literal word value =
        let start = !pos in
        let len = String.length word in
        if start + len > n then raise Trunc;
        if String.sub s start len <> word then fail start "invalid literal";
        pos := start + len;
        value
      and parse_value () =
        skip_ws ();
        need_char ();
        match s.[!pos] with
        | '{' -> parse_object ()
        | '[' -> parse_array ()
        | '"' -> Json_ast.String (parse_string ())
        | 't' -> parse_literal "true" (Json_ast.Bool true)
        | 'f' -> parse_literal "false" (Json_ast.Bool false)
        | 'n' -> parse_literal "null" Json_ast.Null
        | '-' | '0' .. '9' -> parse_number ()
        | c -> fail !pos (Printf.sprintf "unexpected character %C" c)
      in
      try
        skip_ws ();
        if !pos >= n then
          Error { kind = Syntax; offset = n; message = "empty document" }
        else
          let value = parse_value () in
          skip_ws ();
          if !pos < n then
            Error { kind = Syntax; offset = !pos; message = "trailing data" }
          else Ok value
      with
      | Trunc ->
          Error
            { kind = Syntax; offset = n; message = "unexpected end of input" }
      | Fail (at, message) -> Error { kind = Syntax; offset = at; message })
