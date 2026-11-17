(* Argv-only subprocess execution with a wall-clock bound. Standard output
   and standard error share one capture file, matching the recorded probe
   captures. Licence: AGPL-3.0-or-later; see README.md. *)

type capture = {
  status : int option;
  output : string;
  timed_out : bool;
  spawn_error : string option;
}

(** Read the whole file at [path] into a string. Raises [Sys_error] when the
    file cannot be opened or read. *)
let read_file path =
  let channel = open_in_bin path in
  let length = in_channel_length channel in
  let text = really_input_string channel length in
  close_in channel;
  text

(** Write [text] to [path], truncating any existing contents. Raises [Sys_error]
    when the file cannot be opened or written. *)
let write_file path text =
  let channel = open_out_bin path in
  output_string channel text;
  close_out channel

type split_capture = {
  split_status : int option;
  split_stdout : string;
  split_stderr : string;
  split_timed_out : bool;
  split_spawn_error : string option;
}

(** Run [argv] with [stdin] on its standard input, capturing standard output and
    standard error into separate files. Returns the exit status, both streams, a
    timeout flag and a spawn error; a child killed by a signal reports 128 plus
    the signal number, and a child still running after [timeout] seconds is
    killed with SIGKILL. *)
let run_split ?(stdin = "") ?(timeout = 30.0) (argv : string array) :
    split_capture =
  let argv = if Array.length argv = 0 then [| "" |] else argv in
  let in_path = Filename.temp_file "quint-checktrace-in" ".tmp" in
  let out_path = Filename.temp_file "quint-checktrace-out" ".tmp" in
  let err_path = Filename.temp_file "quint-checktrace-err" ".tmp" in
  write_file in_path stdin;
  let in_fd = Unix.openfile in_path [ Unix.O_RDONLY ] 0 in
  let out_fd = Unix.openfile out_path [ Unix.O_WRONLY; Unix.O_TRUNC ] 0o600 in
  let err_fd = Unix.openfile err_path [ Unix.O_WRONLY; Unix.O_TRUNC ] 0o600 in
  let cleanup () =
    (try Unix.close in_fd with Unix.Unix_error _ -> ());
    (try Unix.close out_fd with Unix.Unix_error _ -> ());
    (try Unix.close err_fd with Unix.Unix_error _ -> ());
    (try Sys.remove in_path with Sys_error _ -> ());
    (try Sys.remove out_path with Sys_error _ -> ());
    try Sys.remove err_path with Sys_error _ -> ()
  in
  let read path = try read_file path with Sys_error _ -> "" in
  let finish capture =
    cleanup ();
    capture
  in
  match Unix.create_process argv.(0) argv in_fd out_fd err_fd with
  | exception Unix.Unix_error (error, _, _) ->
      finish
        {
          split_status = None;
          split_stdout = "";
          split_stderr = "";
          split_timed_out = false;
          split_spawn_error = Some (Unix.error_message error);
        }
  | pid -> (
      let deadline = Unix.gettimeofday () +. timeout in
      let rec wait () =
        let finished, status = Unix.waitpid [ Unix.WNOHANG ] pid in
        if finished <> 0 then Some status
        else if Unix.gettimeofday () >= deadline then None
        else begin
          ignore (Unix.select [] [] [] 0.01);
          wait ()
        end
      in
      match wait () with
      | Some status ->
          let code =
            match status with
            | Unix.WEXITED code -> Some code
            | Unix.WSIGNALED signal -> Some (128 + signal)
            | Unix.WSTOPPED signal -> Some (128 + signal)
          in
          finish
            {
              split_status = code;
              split_stdout = read out_path;
              split_stderr = read err_path;
              split_timed_out = false;
              split_spawn_error = None;
            }
      | None ->
          (try Unix.kill pid Sys.sigkill with Unix.Unix_error _ -> ());
          (try ignore (Unix.waitpid [] pid) with Unix.Unix_error _ -> ());
          finish
            {
              split_status = None;
              split_stdout = read out_path;
              split_stderr = read err_path;
              split_timed_out = true;
              split_spawn_error = None;
            })

(** Run [argv] with [stdin] on its standard input, capturing standard output and
    standard error into one file. Returns the exit status, that output, a
    timeout flag and a spawn error; a child still running after [timeout]
    seconds is killed with SIGKILL. *)
let run_combined ?(stdin = "") ?(timeout = 30.0) (argv : string array) : capture
    =
  let argv = if Array.length argv = 0 then [| "" |] else argv in
  let in_path = Filename.temp_file "quint-checktrace-in" ".tmp" in
  let out_path = Filename.temp_file "quint-checktrace-out" ".tmp" in
  write_file in_path stdin;
  let in_fd = Unix.openfile in_path [ Unix.O_RDONLY ] 0 in
  let out_fd = Unix.openfile out_path [ Unix.O_WRONLY; Unix.O_TRUNC ] 0o600 in
  let cleanup () =
    (try Unix.close in_fd with Unix.Unix_error _ -> ());
    (try Unix.close out_fd with Unix.Unix_error _ -> ());
    (try Sys.remove in_path with Sys_error _ -> ());
    try Sys.remove out_path with Sys_error _ -> ()
  in
  let finish capture =
    cleanup ();
    capture
  in
  match Unix.create_process argv.(0) argv in_fd out_fd out_fd with
  | exception Unix.Unix_error (error, _, _) ->
      finish
        {
          status = None;
          output = "";
          timed_out = false;
          spawn_error = Some (Unix.error_message error);
        }
  | pid -> (
      let deadline = Unix.gettimeofday () +. timeout in
      let rec wait () =
        let finished, status = Unix.waitpid [ Unix.WNOHANG ] pid in
        if finished <> 0 then Some status
        else if Unix.gettimeofday () >= deadline then None
        else begin
          ignore (Unix.select [] [] [] 0.01);
          wait ()
        end
      in
      match wait () with
      | Some status ->
          let output = try read_file out_path with Sys_error _ -> "" in
          let code =
            match status with
            | Unix.WEXITED code -> Some code
            | Unix.WSIGNALED signal -> Some (128 + signal)
            | Unix.WSTOPPED signal -> Some (128 + signal)
          in
          finish
            { status = code; output; timed_out = false; spawn_error = None }
      | None ->
          (try Unix.kill pid Sys.sigkill with Unix.Unix_error _ -> ());
          (try ignore (Unix.waitpid [] pid) with Unix.Unix_error _ -> ());
          let output = try read_file out_path with Sys_error _ -> "" in
          finish { status = None; output; timed_out = true; spawn_error = None }
      )
