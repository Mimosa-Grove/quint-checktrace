(* A failure carries the stage it was reached at and the diagnostic. The
   stage order is usage, quint, evaluator, parse, decode, resolve, evaluate,
   internal. Licence: AGPL-3.0-or-later; see README.md. *)

type t = { stage : string; message : string }

(** [make stage fmt] builds a failure for [stage] from a format string and its
    arguments. *)
let make stage fmt = Printf.ksprintf (fun message -> { stage; message }) fmt

(** [to_string failure] renders the stage and the message as a single "stage:
    message" line. *)
let to_string failure = Printf.sprintf "%s: %s" failure.stage failure.message
