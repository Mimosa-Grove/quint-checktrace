(* The Quint frontend: the pinned version check and the parse invocation.
   Both calls are argv-only and bounded. Licence: AGPL-3.0-or-later; see
   README.md. *)

(** The Quint version this tool requires. *)
let pinned_version = "0.33.1"

(** Run [quint] with [--version] and compare the reported version with the
    pinned version. Returns [Ok ()] on a match and [Error] with a failure when
    the command cannot run, times out, fails or reports a different version. *)
let version ?(quint = "quint") ?(timeout = 30.0) () =
  match Proc.run_combined ~timeout [| quint; "--version" |] with
  | { Proc.spawn_error = Some error; _ } ->
      Error (Failure.make "quint" "cannot run %s: %s" quint error)
  | { Proc.timed_out = true; _ } ->
      Error (Failure.make "quint" "%s --version timed out" quint)
  | { Proc.status = Some 0; output; _ } ->
      let observed = String.trim output in
      if observed = pinned_version then Ok ()
      else
        Error
          (Failure.make "quint"
             "quint version %s is not the pinned version %s (%s)" observed
             pinned_version quint)
  | { Proc.status; output; _ } ->
      Error
        (Failure.make "quint" "%s --version exited with status %s: %s" quint
           (match status with
           | Some code -> string_of_int code
           | None -> "unknown")
           (String.trim output))

(** Run [quint] parse on [spec] and return the parsed IR document with the
    SHA-256 of the document text. Returns [Error] with a failure when the
    command cannot run, times out, emits no document, emits text that is not
    JSON, or reports parse errors. *)
let parse ?(quint = "quint") ?(timeout = 120.0) ~spec () =
  let ir_path = Filename.temp_file "quint-checktrace-ir" ".json" in
  let map_path = Filename.temp_file "quint-checktrace-map" ".json" in
  let cleanup () =
    (try Sys.remove ir_path with Sys_error _ -> ());
    try Sys.remove map_path with Sys_error _ -> ()
  in
  let result =
    Proc.run_combined ~timeout
      [| quint; "parse"; "--out"; ir_path; "--source-map"; map_path; spec |]
  in
  match result with
  | { Proc.spawn_error = Some error; _ } ->
      cleanup ();
      Error (Failure.make "parse" "cannot run %s: %s" quint error)
  | { Proc.timed_out = true; _ } ->
      cleanup ();
      Error
        (Failure.make "parse" "parsing %s exceeded the %gs parse timeout" spec
           timeout)
  | { Proc.status = Some 0; _ } -> (
      let text = try Proc.read_file ir_path with Sys_error _error -> "" in
      cleanup ();
      if text = "" then
        Error (Failure.make "parse" "%s produced no parse document" spec)
      else
        match Json_parse.parse text with
        | Error error ->
            Error
              (Failure.make "parse" "the parse document for %s is not JSON: %s"
                 spec error.message)
        | Ok ir ->
            let errors =
              match Json_ast.member "errors" ir with
              | Some (Json_ast.Array items) -> items
              | _ -> []
            in
            if errors = [] then Ok (ir, Sha256.hex text)
            else
              Error
                (Failure.make "parse" "the parse of %s reports %d error(s)" spec
                   (List.length errors)))
  | { Proc.status; output; _ } ->
      cleanup ();
      Error
        (Failure.make "parse" "quint parse of %s exited with status %s: %s" spec
           (match status with
           | Some code -> string_of_int code
           | None -> "unknown")
           (String.trim output))
