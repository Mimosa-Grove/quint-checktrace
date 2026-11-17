(* Command-line model and the positive-integer timeout validation. The
   guards run before any stage touches the filesystem. Licence:
   AGPL-3.0-or-later; see README.md. *)

type t = {
  gate : bool;
  positionals : string list;
  main : string option;
  invariants : string list;
  format : string;
  quint : string;
  evaluator : string option;
  timeout : int;
  deadline : int;
  gate_deadline : int;
  strict_source : bool;
}

(** Default per-call timeout in seconds. *)
let default_timeout = 30

(** Default overall deadline in seconds for a check run. *)
let default_deadline = 300

(** Default overall deadline in seconds for a gate run. *)
let default_gate_deadline = 600

(** Default name of the quint executable. *)
let default_quint = "quint"

(** The usage text shown for both the check and the gate forms. *)
let help_text =
  String.concat "\n"
    [
      "quint-checktrace <spec.qnt> <trace.itf.json> --main=<Module>";
      "  (--invariant=<name> | --invariants <name>...)";
      "  [--format=human|json] [--quint <path>] [--evaluator <path>]";
      "  [--timeout=<seconds>] [--deadline=<seconds>] [--strict-source]";
      "quint-checktrace --gate <corpus-root> <manifest> <hand-verified>";
      "  [--timeout=<seconds>] [--deadline=<seconds>]";
      "  [--gate-deadline=<seconds>]";
      "";
      Printf.sprintf
        "--timeout defaults to %d, --deadline to %d, --gate-deadline to %d"
        default_timeout default_deadline default_gate_deadline;
    ]

(** Parse [value] as a positive whole number of seconds. Returns [Ok] with the
    number, or [Error] with a message naming [flag] when the text is not wholly
    digits or is zero. *)
let positive_int flag value =
  let digits =
    String.length value > 0
    && String.for_all (fun c -> c >= '0' && c <= '9') value
  in
  match (digits, int_of_string_opt value) with
  | true, Some number when number > 0 -> Ok number
  | _ ->
      Error
        (Printf.sprintf "%s: '%s' is not a positive integer number of seconds"
           flag value)

(** Return the text after [flag] and an equals sign when [arg] starts with that
    prefix, or [None] otherwise. *)
let split flag arg =
  let prefix = flag ^ "=" in
  if
    String.length arg >= String.length prefix
    && String.sub arg 0 (String.length prefix) = prefix
  then
    Some
      (String.sub arg (String.length prefix)
         (String.length arg - String.length prefix))
  else None

(** Parse [argv] into a command model. Returns [Error] with a message for an
    unknown flag, a missing flag value, a malformed number, a timeout larger
    than its deadline and a wrong count of positional arguments. *)
let parse argv =
  let gate = ref false in
  let positionals = ref [] in
  let main = ref None in
  let invariants = ref [] in
  let format = ref "human" in
  let quint = ref default_quint in
  let evaluator = ref None in
  let timeout = ref default_timeout in
  let deadline = ref default_deadline in
  let gate_deadline = ref default_gate_deadline in
  let strict_source = ref false in
  let error = ref None in
  let fail message = error := Some message in
  let take flag value rest =
    match value with
    | Some value -> Some (value, rest)
    | None -> (
        match rest with
        | value :: rest -> Some (value, rest)
        | [] ->
            fail (Printf.sprintf "%s requires a value" flag);
            None)
  in
  let set_format value =
    match value with
    | "human" | "json" -> format := value
    | _ -> fail (Printf.sprintf "--format: '%s' is not human or json" value)
  in
  let set_int flag target value rest =
    match take flag value rest with
    | Some (value, rest) -> (
        match positive_int flag value with
        | Ok number ->
            target := number;
            Some rest
        | Error message ->
            fail message;
            Some rest)
    | None -> None
  in
  let equals arg =
    let try_flag flag action =
      match split flag arg with
      | Some value ->
          action value;
          true
      | None -> false
    in
    try_flag "--main" (fun value -> main := Some value)
    || try_flag "--invariant" (fun value -> invariants := value :: !invariants)
    || try_flag "--quint" (fun value -> quint := value)
    || try_flag "--evaluator" (fun value -> evaluator := Some value)
    || try_flag "--format" set_format
    || (match split "--timeout" arg with
      | Some value ->
          (match positive_int "--timeout" value with
          | Ok number -> timeout := number
          | Error message -> fail message);
          true
      | None -> false)
    || (match split "--deadline" arg with
      | Some value ->
          (match positive_int "--deadline" value with
          | Ok number -> deadline := number
          | Error message -> fail message);
          true
      | None -> false)
    ||
    match split "--gate-deadline" arg with
    | Some value ->
        (match positive_int "--gate-deadline" value with
        | Ok number -> gate_deadline := number
        | Error message -> fail message);
        true
    | None -> false
  in
  let rec loop = function
    | [] -> ()
    | "--" :: rest -> positionals := List.rev_append rest !positionals
    | arg :: rest -> (
        match arg with
        | "--gate" ->
            gate := true;
            loop rest
        | "--strict-source" ->
            strict_source := true;
            loop rest
        | "--main" -> (
            match take "--main" None rest with
            | Some (value, rest) ->
                main := Some value;
                loop rest
            | None -> ())
        | "--invariant" -> (
            match take "--invariant" None rest with
            | Some (value, rest) ->
                invariants := value :: !invariants;
                loop rest
            | None -> ())
        | "--invariants" ->
            let rec take_names picked = function
              | value :: rest when String.length value > 0 && value.[0] <> '-'
                ->
                  take_names (value :: picked) rest
              | rest -> (List.rev picked, rest)
            in
            let picked, rest = take_names [] rest in
            if picked = [] then fail "--invariants requires at least one value"
            else invariants := List.rev_append picked !invariants;
            loop rest
        | "--quint" -> (
            match take "--quint" None rest with
            | Some (value, rest) ->
                quint := value;
                loop rest
            | None -> ())
        | "--evaluator" -> (
            match take "--evaluator" None rest with
            | Some (value, rest) ->
                evaluator := Some value;
                loop rest
            | None -> ())
        | "--format" -> (
            match take "--format" None rest with
            | Some (value, rest) ->
                set_format value;
                loop rest
            | None -> ())
        | "--timeout" -> (
            match set_int "--timeout" timeout None rest with
            | Some rest -> loop rest
            | None -> ())
        | "--deadline" -> (
            match set_int "--deadline" deadline None rest with
            | Some rest -> loop rest
            | None -> ())
        | "--gate-deadline" -> (
            match set_int "--gate-deadline" gate_deadline None rest with
            | Some rest -> loop rest
            | None -> ())
        | _ ->
            if equals arg then loop rest
            else if String.length arg > 0 && arg.[0] = '-' then
              fail (Printf.sprintf "unknown flag '%s'" arg)
            else begin
              positionals := arg :: !positionals;
              loop rest
            end)
  in
  loop argv;
  match !error with
  | Some message -> Error message
  | None ->
      let positionals = List.rev !positionals in
      let invariants = List.rev !invariants in
      if !timeout > !deadline then
        Error
          (Printf.sprintf "--timeout %d exceeds --deadline %d" !timeout
             !deadline)
      else if !gate then
        if List.length positionals <> 3 then
          Error
            (Printf.sprintf "--gate takes three positional arguments, got %d"
               (List.length positionals))
        else
          Ok
            {
              gate = true;
              positionals;
              main = !main;
              invariants;
              format = !format;
              quint = !quint;
              evaluator = !evaluator;
              timeout = !timeout;
              deadline = !deadline;
              gate_deadline = !gate_deadline;
              strict_source = !strict_source;
            }
      else if List.length positionals <> 2 then
        Error
          (Printf.sprintf "two positional arguments are required, got %d"
             (List.length positionals))
      else if !main = None then Error "--main is required"
      else if invariants = [] then
        Error "at least one --invariant (or --invariants) name is required"
      else
        Ok
          {
            gate = false;
            positionals;
            main = !main;
            invariants;
            format = !format;
            quint = !quint;
            evaluator = !evaluator;
            timeout = !timeout;
            deadline = !deadline;
            gate_deadline = !gate_deadline;
            strict_source = !strict_source;
          }
