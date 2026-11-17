(* quint-checktrace - trace-to-specification conformance for Quint.
   Licence: AGPL-3.0-or-later; see README.md.

   The run reaches its stages in the fixed failure order: usage, quint,
   evaluator, parse, decode, resolve, evaluate, internal. A completed check
   renders the human report or the machine report from one verdict model. *)

let read_file path =
  let channel = open_in_bin path in
  let length = in_channel_length channel in
  let text = really_input_string channel length in
  close_in channel;
  text

let fail failure =
  let stage = failure.Failure.stage in
  let message = failure.message in
  let prefix = stage ^ ": " in
  if
    String.length message >= String.length prefix
    && String.sub message 0 (String.length prefix) = prefix
  then Printf.eprintf "%s\n" message
  else Printf.eprintf "%s: %s\n" stage message;
  exit 2

let print_human input =
  List.iter
    (fun line -> if line <> "" then print_endline line else print_newline ())
    (Report.human_lines input)

let print_json input =
  print_endline (Report.json_string input);
  List.iter prerr_endline (Report.information_lines input);
  prerr_endline (Report.summary_line input)

let has_flag argv flag = List.exists (fun arg -> arg = flag) argv

let () =
  let argv = Array.to_list Sys.argv |> List.tl in
  if has_flag argv "--version" then begin
    print_endline Version.banner;
    exit 0
  end;
  if has_flag argv "--help" || has_flag argv "-h" then begin
    print_endline Cli.help_text;
    exit 0
  end;
  match Cli.parse argv with
  | Error message ->
      Printf.eprintf "usage: %s\n" message;
      exit 2
  | Ok config -> (
      let started = Unix.gettimeofday () in
      let remaining () =
        float_of_int config.Cli.deadline -. (Unix.gettimeofday () -. started)
      in
      if config.Cli.gate then
        exit
          (Gate.run
             {
               Gate.corpus_root = List.nth config.Cli.positionals 0;
               manifest = List.nth config.Cli.positionals 1;
               fixtures = List.nth config.Cli.positionals 2;
               timeout = config.Cli.timeout;
               deadline = config.Cli.deadline;
               gate_deadline = config.Cli.gate_deadline;
               quint = config.Cli.quint;
               evaluator = config.Cli.evaluator;
             });
      match
        Quint.version ~quint:config.Cli.quint ~timeout:(remaining ()) ()
      with
      | Error failure -> fail failure
      | Ok () -> (
          match Evaluator.resolve ?evaluator:config.Cli.evaluator () with
          | Error failure -> fail failure
          | Ok evaluator -> (
              let spec = List.nth config.Cli.positionals 0 in
              let trace_path = List.nth config.Cli.positionals 1 in
              let main = Option.value config.Cli.main ~default:"" in
              let parse_timeout = Float.min 120.0 (remaining ()) in
              if parse_timeout <= 0.0 then
                fail
                  (Failure.make "parse"
                     "the deadline expired before the parse of %s" spec);
              match
                Quint.parse ~quint:config.Cli.quint ~timeout:parse_timeout ~spec
                  ()
              with
              | Error failure -> fail failure
              | Ok (ir, ir_sha256) -> (
                  let raw =
                    try read_file trace_path
                    with Sys_error error ->
                      fail
                        (Failure.make "decode" "cannot read %s: %s" trace_path
                           error)
                  in
                  match
                    Decoder.preparse ~spec_path:spec
                      ~strict_source:config.Cli.strict_source
                      ~deadline:(remaining ()) raw
                  with
                  | Error refusal ->
                      fail (Failure.make "decode" "%s" refusal.Decoder.message)
                  | Ok parsed -> (
                      (* The names-only derivation runs before the typed phase so a
                   value the structural walk refuses reports at stage decode
                   ahead of any resolution refusal (R44). When the IR yields no
                   names the trace's own vars array bounds the walk. *)
                      let names =
                        match Resolver.declaration_names ir ~main with
                        | Ok names -> names
                        | Error _ -> parsed.Decoder.vars
                      in
                      match
                        Decoder.decode_structural ~names
                          ~deadline:(remaining ()) parsed
                      with
                      | Error refusal ->
                          fail
                            (Failure.make "decode" "%s" refusal.Decoder.message)
                      | Ok () -> (
                          match Resolver.variable_decls ir ~main with
                          | Error message ->
                              fail (Failure.make "resolve" "%s" message)
                          | Ok decls -> (
                              let duplicates = Resolver.duplicate_keys ir in
                              match
                                Decoder.decode_typed ~decls ~duplicates
                                  ~deadline:(remaining ()) parsed
                              with
                              | Error refusal ->
                                  fail
                                    (Failure.make "decode" "%s"
                                       refusal.Decoder.message)
                              | Ok trace -> (
                                  match
                                    Resolver.resolve ir ~main
                                      ~invariants:config.Cli.invariants
                                  with
                                  | Error message ->
                                      fail (Failure.make "resolve" "%s" message)
                                  | Ok resolved -> (
                                      match
                                        Check.run ~ir ~trace ~resolved
                                          ~evaluator
                                          ~timeout:
                                            (float_of_int config.Cli.timeout)
                                          ~deadline:(remaining ())
                                      with
                                      | Error failure -> fail failure
                                      | Ok result ->
                                          let input =
                                            {
                                              Report.spec_path = spec;
                                              main;
                                              quint_version =
                                                Quint.pinned_version;
                                              ir_sha256;
                                              trace_path;
                                              trace;
                                              evaluator;
                                              rows =
                                                Report.build_rows ~trace
                                                  ~variables:
                                                    resolved.Resolver.variables
                                                  result;
                                            }
                                          in
                                          (match config.Cli.format with
                                          | "json" -> print_json input
                                          | _ -> print_human input);
                                          exit (Report.exit_code input.rows)))))
                      )))))
