(* Report rendering in both formats.

   Both formats are produced from one verdict model. The human report escapes
   caller-controlled strings onto a single line, renders a failing state in the
   fixed value grammar and caps that rendering at 200 Unicode characters. The
   machine report carries the full forwarded state and the full digests.
   Licence: AGPL-3.0-or-later; see README.md. *)

(** Sentence stating that a verdict covers the recorded states only. *)
let coverage_line =
  "The verdict covers the recorded states only; it is not a proof."

(** Wording shown beside an invariant that recorded no violation. *)
let pass_wording = "no violation observed in this trace"

type verdict =
  | Pass
  | Fail of { state : int; state_value : Json_ast.t; rendering : string }

type row = { name : string; verdict : verdict }

type input = {
  spec_path : string;
  main : string;
  quint_version : string;
  ir_sha256 : string;
  trace_path : string;
  trace : Decoder.trace;
  evaluator : Evaluator.resolved;
  rows : row list;
}

(** Number of rows whose verdict is [Pass]. *)
let pass_count rows =
  List.length (List.filter (fun row -> row.verdict = Pass) rows)

(** Number of rows whose verdict is not [Pass]. *)
let fail_count rows =
  List.length (List.filter (fun row -> row.verdict <> Pass) rows)

(** Process exit code for the rows: 0 when no row fails, 1 otherwise. *)
let exit_code rows = if fail_count rows = 0 then 0 else 1

(** JSON-style Unicode escape for one character code, in lower-case hex. *)
let lowercase_hex4 code = Printf.sprintf "\\u%04x" code

(* A JSON-style escape for the human output. Control characters become
   \uXXXX; the backslash and the double quote take their JSON escapes. *)

(** JSON-style escape of [text]. Control characters become Unicode escapes;
    [quoted] adds surrounding double quotes. *)
let escape_text ?(quoted = false) text =
  let buf = Buffer.create (String.length text + 8) in
  String.iter
    (fun c ->
      match c with
      | '\\' -> Buffer.add_string buf "\\\\"
      | '"' -> Buffer.add_string buf "\\\""
      | c when Char.code c < 0x20 ->
          Buffer.add_string buf (lowercase_hex4 (Char.code c))
      | c -> Buffer.add_char buf c)
    text;
  let body = Buffer.contents buf in
  if quoted then "\"" ^ body ^ "\"" else body

(* One rendered value is a list of atoms: a plain character is one atom, and an
   existing escape sequence is one atom so truncation never splits it. The cap
   counts Unicode characters, so a multibyte UTF-8 sequence is one atom too.
   The input is already rendered: its escapes are not re-escaped here. *)

(** Splits already rendered text into atoms. Each atom is one character, one
    escape sequence or one UTF-8 sequence; truncation never splits an atom. *)
let atoms_of_text text =
  let atoms = ref [] in
  let add atom = atoms := atom :: !atoms in
  let length = String.length text in
  let index = ref 0 in
  while !index < length do
    let c = text.[!index] in
    if c = '\\' then begin
      let width =
        if !index + 5 < length && text.[!index + 1] = 'u' then 6 else 2
      in
      let width = min width (length - !index) in
      add (String.sub text !index width);
      index := !index + width
    end
    else begin
      let start = !index in
      let byte = Char.code c in
      let width =
        if byte land 0x80 = 0 then 1
        else if byte land 0xE0 = 0xC0 then 2
        else if byte land 0xF0 = 0xE0 then 3
        else if byte land 0xF8 = 0xF0 then 4
        else 1
      in
      let width = min width (length - start) in
      add (String.sub text start width);
      index := start + width
    end
  done;
  List.rev !atoms

(** Character width of one atom: its length for an escape, else 1. *)
let atom_width atom =
  if String.length atom > 0 && atom.[0] = '\\' then String.length atom else 1

(** Maximum character count kept in one state rendering. *)
let idiom = 200

(** Truncates [text] to the character limit. A truncated text ends with three
    dots. *)
let capped text =
  let atoms = atoms_of_text text in
  let characters =
    List.fold_left (fun sum atom -> sum + atom_width atom) 0 atoms
  in
  if characters <= idiom then text
  else
    let limit = idiom - 3 in
    let buf = Buffer.create (String.length text) in
    let used = ref 0 in
    let rec take = function
      | [] -> ()
      | atom :: rest ->
          let width = atom_width atom in
          if !used + width <= limit then begin
            Buffer.add_string buf atom;
            used := !used + width;
            take rest
          end
    in
    take atoms;
    Buffer.contents buf ^ "..."

(** Renders an interface value in the fixed value grammar. Set, map and record
    members are sorted by their rendered text. *)
let rec render_value = function
  | Itf_value.Bool true -> "true"
  | Itf_value.Bool false -> "false"
  | Itf_value.Str text -> escape_text ~quoted:true text
  | Itf_value.Int text -> text
  | Itf_value.List items ->
      "[" ^ String.concat ", " (List.map render_value items) ^ "]"
  | Itf_value.Tuple items ->
      "(" ^ String.concat ", " (List.map render_value items) ^ ")"
  | Itf_value.Unit -> "()"
  | Itf_value.Set items ->
      let rendered = List.map render_value items |> List.sort String.compare in
      "Set(" ^ String.concat ", " rendered ^ ")"
  | Itf_value.Map entries ->
      let rendered =
        List.map
          (fun (key, value) -> (render_value key, render_value value))
          entries
        |> List.sort (fun (left, _) (right, _) -> String.compare left right)
        |> List.map (fun (key, value) -> key ^ " -> " ^ value)
      in
      "Map(" ^ String.concat ", " rendered ^ ")"
  | Itf_value.Record fields ->
      let rendered =
        fields
        |> List.sort (fun (left, _) (right, _) -> String.compare left right)
        |> List.map (fun (name, value) -> name ^ ": " ^ render_value value)
      in
      "{ " ^ String.concat ", " rendered ^ " }"
  | Itf_value.Variant (tag, payload) -> tag ^ "(" ^ render_value payload ^ ")"

(** Value the state records for [name], when present; [None] otherwise. *)
let declared_value variables (state : Decoder.state) name =
  match List.assoc_opt name state.Decoder.values with
  | Some value -> Some value
  | None -> (
      match List.assoc_opt name variables with Some _ -> None | None -> None)

(* The rendering covers the declared variables at that state, sorted by name.
   The forwarded #meta is not part of the human rendering. *)

(** Renders the declared variables of one state as a single-line object. Fields
    are sorted by variable name and the forwarded meta is omitted. *)
let render_state variables (state : Decoder.state) =
  let names = variables |> List.map fst |> List.sort_uniq String.compare in
  let fields =
    List.filter_map
      (fun name ->
        match declared_value variables state name with
        | Some value -> Some (name ^ ": " ^ render_value value)
        | None -> None)
      names
  in
  "{ " ^ String.concat ", " fields ^ " }"

(** State whose recorded index equals [index], when the trace holds one. *)
let state_at trace index =
  List.find_opt
    (fun (state : Decoder.state) -> state.Decoder.index = index)
    trace.Decoder.states

(** Builds the report rows from the check results and the trace. A failing row
    carries its state value and capped rendering; a failure with no recorded
    state keeps an empty value and an empty rendering. *)
let build_rows ~trace ~variables result =
  List.map
    (fun (row : Check.row) ->
      match row.Check.outcome with
      | Check.Pass -> { name = row.Check.name; verdict = Pass }
      | Check.Fail index ->
          let state = state_at trace index in
          let state_value =
            match state with
            | Some state -> Evaluator.build_state ~decls:variables state
            | None -> Json_ast.Object [ ("#meta", Json_ast.Object []) ]
          in
          let rendering =
            match state with
            | Some state -> capped (render_state variables state)
            | None -> "{  }"
          in
          {
            name = row.Check.name;
            verdict = Fail { state = index; state_value; rendering };
          })
    result.Check.rows

(** Optional metadata field as a one-member association, or an empty list. *)
let metadata_type_field key = function
  | Some text -> [ (key, Json_ast.String text) ]
  | None -> []

(* The comparison projection the fixture corpus records: the trace object's
   members flattened beside exit, summary, invariants and the pinned trace
   digest. *)

(** Comparison projection: trace members flattened beside exit, summary and the
    per-invariant verdicts. *)
let projection input =
  let trace = input.trace in
  let stable =
    [
      ("exit", Json_ast.Number (string_of_int (exit_code input.rows)));
      ( "invariants",
        Json_ast.Array
          (List.map
             (fun row ->
               match row.verdict with
               | Pass ->
                   Json_ast.Object
                     [
                       ("name", Json_ast.String row.name);
                       ("verdict", Json_ast.String "pass");
                     ]
               | Fail fail ->
                   Json_ast.Object
                     [
                       ("name", Json_ast.String row.name);
                       ("verdict", Json_ast.String "fail");
                       ("state", Json_ast.Number (string_of_int fail.state));
                       ("state_value", fail.state_value);
                       ("rendering", Json_ast.String fail.rendering);
                     ])
             input.rows) );
      ( "summary",
        Json_ast.Object
          [
            ("pass", Json_ast.Number (string_of_int (pass_count input.rows)));
            ("fail", Json_ast.Number (string_of_int (fail_count input.rows)));
          ] );
      ( "states",
        Json_ast.Number (string_of_int (List.length trace.Decoder.states)) );
      ( "source",
        match trace.Decoder.meta.source with
        | Some source -> Json_ast.String source
        | None -> Json_ast.Null );
      ( "status",
        match trace.Decoder.meta.status with
        | Some status -> Json_ast.String status
        | None -> Json_ast.Null );
      ("source_mismatch", Json_ast.Bool trace.Decoder.source_mismatch);
      ( "ignored_vars",
        Json_ast.Array
          (List.map
             (fun name -> Json_ast.String name)
             trace.Decoder.ignored_vars) );
      ( "unknown_top_level_fields",
        Json_ast.Array
          (List.map
             (fun name -> Json_ast.String name)
             trace.Decoder.unknown_top_level_fields) );
      ("trace_sha256", Json_ast.String trace.Decoder.sha256);
    ]
  in
  let loop =
    match trace.Decoder.loop with
    | Some index -> [ ("loop", Json_ast.Number (string_of_int index)) ]
    | None -> []
  in
  Json_ast.Object
    (stable @ loop
    @ metadata_type_field "source_type" trace.Decoder.meta.source_type
    @ metadata_type_field "status_type" trace.Decoder.meta.status_type)

(** Full machine report as a JSON tree. Carries the tool, spec, trace,
    evaluator, invariant rows and summary. *)
let document input =
  let trace = input.trace in
  let invariants =
    List.map
      (fun row ->
        match row.verdict with
        | Pass ->
            Json_ast.Object
              [
                ("name", Json_ast.String row.name);
                ("verdict", Json_ast.String "pass");
              ]
        | Fail fail ->
            Json_ast.Object
              [
                ("name", Json_ast.String row.name);
                ("verdict", Json_ast.String "fail");
                ("state", Json_ast.Number (string_of_int fail.state));
                ("state_value", fail.state_value);
                ("rendering", Json_ast.String fail.rendering);
              ])
      input.rows
  in
  let trace_object =
    [
      ("path", Json_ast.String input.trace_path);
      ("sha256", Json_ast.String trace.Decoder.sha256);
      ( "source",
        match trace.Decoder.meta.source with
        | Some source -> Json_ast.String source
        | None -> Json_ast.Null );
      ( "status",
        match trace.Decoder.meta.status with
        | Some status -> Json_ast.String status
        | None -> Json_ast.Null );
    ]
    @ metadata_type_field "source_type" trace.Decoder.meta.source_type
    @ metadata_type_field "status_type" trace.Decoder.meta.status_type
    @ [
        ("source_mismatch", Json_ast.Bool trace.Decoder.source_mismatch);
        ( "states",
          Json_ast.Number (string_of_int (List.length trace.Decoder.states)) );
        ( "loop",
          match trace.Decoder.loop with
          | Some index -> Json_ast.Number (string_of_int index)
          | None -> Json_ast.Null );
        ( "ignored_vars",
          Json_ast.Array
            (List.map
               (fun name -> Json_ast.String name)
               trace.Decoder.ignored_vars) );
        ( "unknown_top_level_fields",
          Json_ast.Array
            (List.map
               (fun name -> Json_ast.String name)
               trace.Decoder.unknown_top_level_fields) );
      ]
  in
  Json_ast.Object
    [
      ( "tool",
        Json_ast.Object
          [
            ("name", Json_ast.String "quint-checktrace");
            ("version", Json_ast.String Version.number);
          ] );
      ("mode", Json_ast.String "checktrace");
      ( "spec",
        Json_ast.Object
          [
            ("path", Json_ast.String input.spec_path);
            ("main", Json_ast.String input.main);
            ("quint_version", Json_ast.String input.quint_version);
            ("ir_sha256", Json_ast.String input.ir_sha256);
          ] );
      ("trace", Json_ast.Object trace_object);
      ( "evaluator",
        Json_ast.Object
          [
            ("path", Json_ast.String input.evaluator.Evaluator.path);
            ("sha256", Json_ast.String input.evaluator.Evaluator.sha256);
          ] );
      ("invariants", Json_ast.Array invariants);
      ( "summary",
        Json_ast.Object
          [
            ("pass", Json_ast.Number (string_of_int (pass_count input.rows)));
            ("fail", Json_ast.Number (string_of_int (fail_count input.rows)));
          ] );
      ("exit", Json_ast.Number (string_of_int (exit_code input.rows)));
    ]

(** Human rendering of the recorded source, or [source=absent]. *)
let source_rendering (trace : Decoder.trace) =
  match trace.Decoder.meta.source with
  | Some source -> "source=" ^ escape_text source
  | None -> "source=absent"

(** Human rendering of the recorded status, or [status=absent]. *)
let status_rendering (trace : Decoder.trace) =
  match trace.Decoder.meta.status with
  | Some status -> "status=" ^ escape_text status
  | None -> "status=absent"

(** Report title line naming the specification path and module. *)
let header_line input =
  let dash = "\226\148\128" in
  let title =
    dash ^ dash ^ " Trace check: "
    ^ escape_text input.spec_path
    ^ " (module " ^ escape_text input.main ^ ")"
  in
  let width = 64 in
  let fill = max 1 (width - String.length title - 1) in
  title ^ " " ^ String.concat "" (List.init fill (fun _ -> dash))

(** First twelve characters of a digest, or the whole digest when shorter. *)
let digest_prefix digest =
  if String.length digest <= 12 then digest else String.sub digest 0 12

(** Note lines describing metadata quirks of the trace. Covers typed metadata
    treated as absent, a source mismatch, ignored keys and unknown top-level
    fields, in output order. *)
let information_lines input =
  let trace = input.trace in
  let lines = ref [] in
  (match (trace.Decoder.meta.source_type, trace.Decoder.meta.status_type) with
  | None, None -> ()
  | source_type, status_type ->
      let fields =
        List.filter_map
          (fun (name, kind) ->
            match kind with
            | Some kind ->
                Some
                  (Printf.sprintf "#meta.%s is a %s, which is treated as absent"
                     name kind)
            | None -> None)
          [ ("source", source_type); ("status", status_type) ]
      in
      lines := ("note: " ^ String.concat "; " fields) :: !lines);
  if trace.Decoder.source_mismatch then
    lines :=
      Printf.sprintf
        "note: the trace records source %s, which differs from the supplied \
         specification %s"
        (match trace.Decoder.meta.source with
        | Some source -> escape_text source
        | None -> "")
        (escape_text input.spec_path)
      :: !lines;
  if trace.Decoder.ignored_vars <> [] then
    lines :=
      ("note: ignored state keys: "
      ^ String.concat ", "
          (List.map (fun name -> escape_text name) trace.Decoder.ignored_vars))
      :: !lines;
  if trace.Decoder.unknown_top_level_fields <> [] then
    lines :=
      ("note: unknown top-level fields: "
      ^ String.concat ", "
          (List.map
             (fun name -> escape_text name)
             trace.Decoder.unknown_top_level_fields))
      :: !lines;
  List.rev !lines

(** Summary line with pass and fail counts and the exit code. A source mismatch
    appends a marker. *)
let summary_line input =
  let trace = input.trace in
  Printf.sprintf "Summary: %d pass, %d fail (exit %d)%s" (pass_count input.rows)
    (fail_count input.rows) (exit_code input.rows)
    (if trace.Decoder.source_mismatch then " source-mismatch" else "")

(** One row line: passing wording, or the failure state and its rendering. *)
let row_line prefix row =
  match row.verdict with
  | Pass -> Printf.sprintf "%s%-19s✓  PASS - %s" prefix row.name pass_wording
  | Fail fail ->
      Printf.sprintf "%s%-19s✗  FAIL at state %d: %s" prefix row.name fail.state
        fail.rendering

(** All lines of the human report, in order. Header, trace details, notes, one
    line per invariant and the summary. *)
let human_lines input =
  let trace = input.trace in
  let lines =
    [
      header_line input;
      Printf.sprintf "   trace: %s  %s"
        (escape_text input.trace_path)
        (source_rendering trace);
      Printf.sprintf "   states=%d  %s"
        (List.length trace.Decoder.states)
        (status_rendering trace);
      Printf.sprintf "   Quint %s  evaluator %s  sha256=%s  mode checktrace"
        input.quint_version
        (escape_text input.evaluator.Evaluator.path)
        (digest_prefix input.evaluator.Evaluator.sha256);
      "   " ^ coverage_line;
      "";
    ]
    @ information_lines input @ [ "Invariants" ]
    @ List.map (row_line "   ") input.rows
    @ [ ""; summary_line input ]
  in
  lines

(** Human report as one string with newline separators. *)
let human_string input = String.concat "\n" (human_lines input)

(** Machine report as one compact JSON string. *)
let json_string input = Json_writer.to_string (document input)
