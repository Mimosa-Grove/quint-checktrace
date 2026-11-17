(* Strict UTF-8 validation over bytes. The decoder needs the byte offset of
   the first invalid sequence, so this module reports positions rather than
   raising. Licence: AGPL-3.0-or-later; see README.md. *)

(** [is_cont b] is true when [b] is a UTF-8 continuation byte. *)
let is_cont b = b land 0xC0 = 0x80

(** [first_invalid s] is the byte offset of the first byte that does not begin a
    well-formed UTF-8 sequence, or [None] when [s] is valid. *)
let first_invalid (s : string) : int option =
  let n = String.length s in
  let code i = Char.code s.[i] in
  let seq_ok start len lo2 hi2 =
    if start + len >= n then Some start
    else
      let b1 = code (start + 1) in
      if b1 < lo2 || b1 > hi2 then Some start
      else
        let rec rest j =
          if j > len then None
          else if is_cont (code (start + j)) then rest (j + 1)
          else Some start
        in
        rest 2
  in
  let rec loop i =
    if i >= n then None
    else
      let b = code i in
      if b < 0x80 then loop (i + 1)
      else if b < 0xC2 then Some i
      else if b <= 0xDF then
        match seq_ok i 1 0x80 0xBF with None -> loop (i + 2) | some -> some
      else if b = 0xE0 then
        match seq_ok i 2 0xA0 0xBF with None -> loop (i + 3) | some -> some
      else if b >= 0xE1 && b <= 0xEC then
        match seq_ok i 2 0x80 0xBF with None -> loop (i + 3) | some -> some
      else if b = 0xED then
        match seq_ok i 2 0x80 0x9F with None -> loop (i + 3) | some -> some
      else if b <= 0xEF then
        match seq_ok i 2 0x80 0xBF with None -> loop (i + 3) | some -> some
      else if b = 0xF0 then
        match seq_ok i 3 0x90 0xBF with None -> loop (i + 4) | some -> some
      else if b >= 0xF1 && b <= 0xF3 then
        match seq_ok i 3 0x80 0xBF with None -> loop (i + 4) | some -> some
      else if b = 0xF4 then
        match seq_ok i 3 0x80 0x8F with None -> loop (i + 4) | some -> some
      else Some i
  in
  loop 0
