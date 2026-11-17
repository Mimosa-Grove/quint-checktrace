(* Corpus generator: writes the edge fixtures and the hand-verified set from
   the embedded table. The trace digest and the report's metadata projection
   are computed from the bytes written. Licence: AGPL-3.0-or-later; see
   README.md. *)

open Fixture_table

let escape_string text =
  let buffer = Buffer.create (String.length text + 8) in
  String.iter
    (fun c ->
      match c with
      | '"' -> Buffer.add_string buffer "\\\""
      | '\\' -> Buffer.add_string buffer "\\\\"
      | '\n' -> Buffer.add_string buffer "\\n"
      | '\r' -> Buffer.add_string buffer "\\r"
      | '\t' -> Buffer.add_string buffer "\\t"
      | '\b' -> Buffer.add_string buffer "\\b"
      | '\012' -> Buffer.add_string buffer "\\f"
      | c when Char.code c < 0x20 ->
          Buffer.add_string buffer (Printf.sprintf "\\u%04x" (Char.code c))
      | c -> Buffer.add_char buffer c)
    text;
  Buffer.contents buffer

let indent level = String.concat "" (List.init level (fun _ -> "  "))

let rec pretty json level =
  match json with
  | JNull -> "null"
  | JBool true -> "true"
  | JBool false -> "false"
  | JNum value -> string_of_int value
  | JStr text -> "\"" ^ escape_string text ^ "\""
  | JArr [] -> "[]"
  | JArr items ->
      let rendered =
        List.map
          (fun item -> indent (level + 1) ^ pretty item (level + 1))
          items
      in
      "[\n" ^ String.concat ",\n" rendered ^ "\n" ^ indent level ^ "]"
  | JObj [] -> "{}"
  | JObj members ->
      let members =
        List.sort
          (fun (left, _) (right, _) -> String.compare left right)
          members
      in
      let rendered =
        List.map
          (fun (key, value) ->
            indent (level + 1)
            ^ "\"" ^ escape_string key ^ "\": "
            ^ pretty value (level + 1))
          members
      in
      "{\n" ^ String.concat ",\n" rendered ^ "\n" ^ indent level ^ "}"

let rec mkdir_p path =
  if path <> "" && path <> "/" && not (Sys.file_exists path) then begin
    mkdir_p (Filename.dirname path);
    Unix.mkdir path 0o755
  end

let write_file path text =
  mkdir_p (Filename.dirname path);
  let channel = open_out_bin path in
  output_string channel text;
  close_out channel

let member key = function
  | JObj members -> List.assoc_opt key members
  | _ -> None

let set_member key value = function
  | JObj members -> JObj ((key, value) :: List.remove_assoc key members)
  | other -> other

let string_of_json = function JStr text -> Some text | _ -> None

let trace_meta_source trace_text =
  match Json_parse.parse trace_text with
  | Error _ -> (None, None)
  | Ok document ->
      let meta = Json_ast.member "#meta" document in
      let string_member key =
        match meta with
        | Some meta -> (
            match Json_ast.member key meta with
            | Some (Json_ast.String text) -> Some text
            | _ -> None)
        | None -> None
      in
      (string_member "source", string_member "status")

let invocation_spec_path expected =
  match member "invocation" expected with
  | Some invocation -> (
      match member "args" invocation with
      | Some (JArr (first :: _)) -> string_of_json first
      | _ -> None)
  | None -> None

let expected_with_digest entry trace_text =
  let digest = Sha256.hex trace_text in
  match member "expected_report" entry.expected with
  | None -> entry.expected
  | Some report ->
      let report = set_member "trace_sha256" (JStr digest) report in
      let report =
        if entry.hand then report
        else
          let source, status = trace_meta_source trace_text in
          let spec = invocation_spec_path entry.expected in
          let mismatch =
            match (source, spec) with
            | Some source, Some spec -> source <> spec
            | _ -> false
          in
          let report =
            set_member "source"
              (match source with Some text -> JStr text | None -> JNull)
              report
          in
          let report =
            set_member "status"
              (match status with Some text -> JStr text | None -> JNull)
              report
          in
          set_member "source_mismatch" (JBool mismatch) report
      in
      set_member "expected_report" report entry.expected

let parse_root argv =
  let root = ref "." in
  let rec loop = function
    | [] -> ()
    | "--root" :: value :: rest ->
        root := value;
        loop rest
    | arg :: rest ->
        if String.length arg > 7 && String.sub arg 0 7 = "--root=" then
          root := String.sub arg 7 (String.length arg - 7)
        else loop rest
  in
  loop argv;
  !root

let () =
  let root = parse_root (List.tl (Array.to_list Sys.argv)) in
  let fixtures = Filename.concat root "fixtures" in
  mkdir_p fixtures;
  List.iter
    (fun entry ->
      let directory =
        if entry.hand then Filename.concat fixtures "hand-verified"
        else fixtures
      in
      write_file (Filename.concat directory (entry.name ^ ".qnt")) entry.spec;
      let trace_rel =
        match entry.trace_rel with
        | Some rel -> rel
        | None -> entry.name ^ ".itf.json"
      in
      let trace_text =
        match entry.trace with
        | TText text -> text
        | TJson json -> pretty json 0
      in
      let trace_path = Filename.concat directory trace_rel in
      write_file trace_path trace_text;
      let expected = expected_with_digest entry trace_text in
      write_file
        (Filename.concat directory (entry.name ^ ".expected.json"))
        (pretty expected 0);
      match entry.derivation with
      | Some derivation ->
          write_file
            (Filename.concat directory (entry.name ^ ".derivation.md"))
            derivation
      | None -> ())
    entries;
  write_file (Filename.concat fixtures "spec.qnt") companion_spec;
  Printf.printf "wrote %d fixtures and the hand-verified set to %s\n"
    (List.length (List.filter (fun entry -> not entry.hand) entries))
    fixtures
