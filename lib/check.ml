(* The evaluation loop: one evaluator call per recorded state carrying every
   invariant still active, positional results mapped back to the invariant
   names, and an early stop once an invariant has failed. Licence:
   AGPL-3.0-or-later; see README.md. *)

type outcome = Pass | Fail of int
type row = { name : string; outcome : outcome }
type result = { rows : row list; evaluations : int }

exception Stop of Failure.t

(** Evaluate every invariant in [resolved] against each recorded state in
    [trace] until one fails. Returns the per-invariant rows with the count of
    evaluator calls, or [Error] with a failure when a call fails, the deadline
    expires or an invariant has no expression. *)
let run ~ir ~trace ~resolved ~evaluator ~timeout ~deadline =
  let started = Unix.gettimeofday () in
  let deadline_at = started +. deadline in
  let table =
    match Json_ast.member "table" ir with
    | Some table -> table
    | None -> Json_ast.Object []
  in
  let active = ref resolved.Resolver.invariants in
  let failed = Hashtbl.create 8 in
  let rows = ref [] in
  let evaluations = ref 0 in
  let record state outcomes =
    List.iter2
      (fun name outcome ->
        match outcome with
        | Evaluator.Pass -> ()
        | Evaluator.Fail ->
            Hashtbl.replace failed name state.Decoder.index;
            rows := { name; outcome = Fail state.Decoder.index } :: !rows)
      !active outcomes;
    active := List.filter (fun name -> not (Hashtbl.mem failed name)) !active
  in
  try
    List.iter
      (fun state ->
        if !active <> [] then begin
          let remaining = deadline_at -. Unix.gettimeofday () in
          if remaining <= 0.0 then
            raise
              (Stop
                 (Failure.make "evaluate" "the deadline expired before state %d"
                    state.Decoder.index));
          let exprs =
            List.map
              (fun name ->
                match
                  Resolver.invariant_expr ir ~main:resolved.Resolver.main name
                with
                | Some expr -> expr
                | None ->
                    raise
                      (Stop
                         (Failure.make "internal"
                            "invariant '%s' has no expression in the main \
                             module"
                            name)))
              !active
          in
          let state_json =
            Evaluator.build_state ~decls:resolved.Resolver.variables state
          in
          let request =
            Json_writer.to_string
              (Evaluator.build_request ~table ~state:state_json ~exprs)
          in
          incr evaluations;
          let call_timeout = Float.min timeout remaining in
          match
            Evaluator.run_request evaluator ~timeout:call_timeout request
          with
          | Error failure -> raise (Stop failure)
          | Ok output -> (
              match
                Evaluator.interpret ~invariants:!active
                  ~state_index:state.Decoder.index output
              with
              | Error failure -> raise (Stop failure)
              | Ok outcomes -> record state outcomes)
        end)
      trace.Decoder.states;
    List.iter
      (fun name ->
        if not (Hashtbl.mem failed name) then
          rows := { name; outcome = Pass } :: !rows)
      resolved.Resolver.invariants;
    Ok
      {
        rows =
          List.sort
            (fun left right -> String.compare left.name right.name)
            !rows;
        evaluations = !evaluations;
      }
  with Stop failure -> Error failure
