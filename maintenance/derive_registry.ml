(* Derives the corpus gate's registry: one derivation record and one trace
   per derive invariant of the committed manifest. Each derivation runs the
   pinned Quint from the corpus tree root, so the trace's #meta.source and
   the record's command both spell the corpus-relative path the gate compares
   on replay. Licence: AGPL-3.0-or-later; see README.md. *)

let fail message =
  Printf.eprintf "derive_registry: %s\n%!" message;
  exit 2

let jopt key = function
  | Json_ast.Object members -> List.assoc_opt key members
  | _ -> None

let jstring key json =
  match jopt key json with
  | Some (Json_ast.String text) -> Some text
  | _ -> None

let jint key json =
  match jopt key json with
  | Some (Json_ast.Number raw) ->
      Option.map int_of_float (Json_ast.number_float raw)
  | _ -> None

let jarray key json =
  match jopt key json with
  | Some (Json_ast.Array items) -> Some items
  | _ -> None

let rec mkdir_p path =
  match Sys.file_exists path with
  | true -> ()
  | false ->
      (match Filename.dirname path with
      | "" | "." | "/" -> ()
      | parent -> mkdir_p parent);
      Unix.mkdir path 0o755

let move_file source target =
  mkdir_p (Filename.dirname target);
  if Sys.file_exists target then Sys.remove target;
  Sys.rename source target

let run_in ~cwd argv =
  let before = Sys.getcwd () in
  let restore () = try Sys.chdir before with Sys_error _ -> () in
  (try Sys.chdir cwd with Sys_error _ -> fail ("cannot enter " ^ cwd));
  let capture = Proc.run_split ~timeout:600.0 (Array.of_list argv) in
  restore ();
  capture

let sha256_of_file path = Sha256.hex (Proc.read_file path)

let relative_to root path =
  let root =
    if String.length root > 1 && root.[String.length root - 1] = '/' then
      String.sub root 0 (String.length root - 1)
    else root
  in
  let prefix = root ^ "/" in
  if
    String.length path > String.length prefix
    && String.sub path 0 (String.length prefix) = prefix
  then
    Some
      (String.sub path (String.length prefix)
         (String.length path - String.length prefix))
  else None

(* The import digest map: Quint's source map spells every source file
   absolutely; the record keeps corpus-relative paths, the same spelling as
   the manifest's path field, minus the specification itself. *)
let import_digests ~corpus ~scratch ~quint path =
  let ir = Filename.concat scratch "derive.ir.json" in
  let map = Filename.concat scratch "derive.map.json" in
  let argv = [ quint; "parse"; path; "--out"; ir; "--source-map"; map ] in
  let capture = run_in ~cwd:corpus argv in
  if capture.Proc.split_status <> Some 0 then
    fail
      (Printf.sprintf "quint parse failed for %s: %s" path
         capture.Proc.split_stderr);
  let json =
    match Json_parse.parse (Proc.read_file map) with
    | Ok document -> document
    | Error _ -> fail ("cannot parse the source map for " ^ path)
  in
  let entries = ref [] in
  (match jopt "sourceIndex" json with
  | Some (Json_ast.Object members) ->
      List.iter
        (fun (_, value) ->
          match value with
          | Json_ast.String absolute ->
              let relative =
                match relative_to corpus absolute with
                | Some rel -> rel
                | None ->
                    fail
                      (Printf.sprintf
                         "the source map names a file outside the corpus tree: \
                          %s"
                         absolute)
              in
              if not (relative = path) then
                entries := (relative, sha256_of_file absolute) :: !entries
          | _ -> ())
        members
  | _ -> fail ("the source map for " ^ path ^ " carries no sourceIndex"));
  List.sort (fun (a, _) (b, _) -> String.compare a b) !entries

type context = {
  corpus : string;
  quint : string;
  records_dir : string;
  traces_dir : string;
  corpus_traces : string;
  scratch : string;
  mutable derived : int;
}

let write_record ctx row_name record =
  let path = Filename.concat ctx.records_dir (row_name ^ ".json") in
  Proc.write_file path (Json_writer.to_string record)

let derive_invariant ctx path main ~max_steps ~seed stem imports spec_digest
    entry =
  let name =
    match jstring "name" entry with
    | Some name -> name
    | None -> fail (path ^ " has an invariant with no name")
  in
  let status =
    match jstring "status" entry with
    | Some status -> status
    | None -> fail (path ^ " has an invariant with no status")
  in
  let row_name = Printf.sprintf "%s--%s--%s" stem main name in
  let trace_name = row_name ^ ".itf.json" in
  let command =
    Printf.sprintf
      "%s run %s --main=%s --backend=rust --max-samples=1 --max-steps=%d \
       --seed=%s --invariant=%s --out-itf=traces/%s"
      ctx.quint path main max_steps seed name trace_name
  in
  let argv =
    [
      ctx.quint;
      "run";
      path;
      Printf.sprintf "--main=%s" main;
      "--backend=rust";
      "--max-samples=1";
      Printf.sprintf "--max-steps=%d" max_steps;
      Printf.sprintf "--seed=%s" seed;
      Printf.sprintf "--invariant=%s" name;
      Printf.sprintf "--out-itf=traces/%s" trace_name;
    ]
  in
  let capture = run_in ~cwd:ctx.corpus argv in
  (match capture.Proc.split_status with
  | Some code -> Printf.printf "derive %s (%s) exit %d\n" row_name status code
  | None -> fail ("quint run produced no exit code for " ^ row_name));
  move_file
    (Filename.concat ctx.corpus_traces trace_name)
    (Filename.concat ctx.traces_dir trace_name);
  let imports_json =
    Json_ast.Object (List.map (fun (p, d) -> (p, Json_ast.String d)) imports)
  in
  let record =
    Json_ast.Object
      [
        ("command", Json_ast.String command);
        ("stdout", Json_ast.String capture.Proc.split_stdout);
        ("stderr", Json_ast.String capture.Proc.split_stderr);
        ( "exit_code",
          match capture.Proc.split_status with
          | Some code -> Json_ast.Number (string_of_int code)
          | None -> Json_ast.Null );
        ("spec_sha256", Json_ast.String spec_digest);
        ("imports", imports_json);
      ]
  in
  write_record ctx row_name record;
  ctx.derived <- ctx.derived + 1

let derive_row ctx row =
  let path =
    match jstring "path" row with
    | Some path -> path
    | None -> fail "a manifest row carries no path"
  in
  let invariants =
    match jarray "invariants" row with
    | Some items -> items
    | None -> fail (path ^ " carries no invariants array")
  in
  match (jstring "main" row, invariants) with
  | Some main, _ :: _ ->
      let max_steps =
        match jint "max_steps" row with
        | Some value -> value
        | None -> fail (path ^ " carries no max_steps")
      in
      let seed =
        match jstring "seed" row with
        | Some value -> value
        | None -> fail (path ^ " carries no seed")
      in
      let stem = Filename.remove_extension (Filename.basename path) in
      let imports =
        import_digests ~corpus:ctx.corpus ~scratch:ctx.scratch ~quint:ctx.quint
          path
      in
      let spec_digest = sha256_of_file (Filename.concat ctx.corpus path) in
      List.iter
        (derive_invariant ctx path main ~max_steps ~seed stem imports
           spec_digest)
        invariants
  | Some main, [] -> (
      match jstring "reason" row with
      | Some reason -> Printf.printf "skip %s %s (%s)\n" path main reason
      | None -> Printf.printf "skip %s %s (excluded)\n" path main)
  | None, _ -> (
      match jstring "reason" row with
      | Some reason -> Printf.printf "skip %s (%s)\n" path reason
      | None -> Printf.printf "skip %s (excluded)\n" path)

let usage () =
  Printf.printf
    "derive_registry --corpus <dir> --manifest <file> [--quint <path>]\n%!";
  exit 2

let () =
  let corpus = ref "" and manifest = ref "" and quint = ref "quint" in
  let rec parse_args = function
    | "--corpus" :: value :: rest ->
        corpus := value;
        parse_args rest
    | "--manifest" :: value :: rest ->
        manifest := value;
        parse_args rest
    | "--quint" :: value :: rest ->
        quint := value;
        parse_args rest
    | [] -> ()
    | _ -> usage ()
  in
  parse_args (List.tl (Array.to_list Sys.argv));
  let absolute path =
    if Filename.is_relative path then Filename.concat (Sys.getcwd ()) path
    else path
  in
  corpus := absolute !corpus;
  manifest := absolute !manifest;
  if String.length !corpus = 0 || String.length !manifest = 0 then usage ();
  if not (Sys.file_exists !manifest) then fail "the manifest is absent";
  let manifest_dir = Filename.dirname !manifest in
  let records_dir = Filename.concat manifest_dir "records" in
  let traces_dir = Filename.concat manifest_dir "traces" in
  mkdir_p records_dir;
  mkdir_p traces_dir;
  let corpus_traces = Filename.concat !corpus "traces" in
  mkdir_p corpus_traces;
  let scratch = Filename.concat manifest_dir ".derive-scratch" in
  mkdir_p scratch;
  let ctx =
    {
      corpus = !corpus;
      quint = !quint;
      records_dir;
      traces_dir;
      corpus_traces;
      scratch;
      derived = 0;
    }
  in
  let rows =
    match Json_parse.parse (Proc.read_file !manifest) with
    | Ok (Json_ast.Array rows) -> rows
    | _ -> fail "the manifest is not a JSON array"
  in
  List.iter (derive_row ctx) rows;
  (try Sys.remove (Filename.concat scratch "derive.ir.json")
   with Sys_error _ -> ());
  (try Sys.remove (Filename.concat scratch "derive.map.json")
   with Sys_error _ -> ());
  (try Unix.rmdir scratch with Unix.Unix_error _ -> ());
  (try
     let listing = Sys.readdir corpus_traces in
     if Array.length listing = 0 then Unix.rmdir corpus_traces
   with Sys_error _ -> ());
  Printf.printf "derive_registry: %d records\n" ctx.derived;
  Printf.printf "== END OF DERIVATION RUN ==\n%!"
