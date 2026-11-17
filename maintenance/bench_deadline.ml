(* Deadline benchmark: records how long the decoder's deadline machinery takes
   on this machine. It reports; it never fails a build. The cells are the flat
   list calibration (clock reads and path construction only) and the wide-member
   name cells (one path built from a megabyte-scale member name per node), each
   run under a one-second deadline so the refusal time is what is recorded.
   Licence: AGPL-3.0-or-later; see README.md. *)

let started_at = Unix.gettimeofday ()
let elapsed reference = Unix.gettimeofday () -. reference

let flat_trace elements =
  let buffer = Buffer.create ((4 * elements) + 96) in
  Buffer.add_string buffer
    "{\"vars\":[\"v\"],\"states\":[{\"#meta\":{\"index\":0},\"v\":[";
  for index = 0 to elements - 1 do
    if index > 0 then Buffer.add_char buffer ',';
    Buffer.add_string buffer "\"x\""
  done;
  Buffer.add_string buffer "]}]}";
  Buffer.contents buffer

let wide_name_trace ~width ~nodes () =
  let buffer = Buffer.create ((nodes * 4) + width + 64) in
  Buffer.add_string buffer
    "{\"vars\":[\"l\"],\"states\":[{\"#meta\":{\"index\":0},\"l\":{\"";
  Buffer.add_string buffer (String.make width 'k');
  Buffer.add_string buffer "\":[";
  for index = 0 to nodes - 1 do
    if index > 0 then Buffer.add_char buffer ',';
    Buffer.add_string buffer "\"x\""
  done;
  Buffer.add_string buffer "]}}]}";
  Buffer.contents buffer

let parse label raw =
  match Decoder.preparse raw with
  | Ok parsed -> parsed
  | Error refusal ->
      Printf.printf "bench: %s did not preparse: %s\n%!" label
        refusal.Decoder.message;
      exit 2

let report label seconds nodes =
  let per_node = seconds /. float_of_int (max 1 nodes) in
  Printf.printf "bench: %-28s elapsed=%8.3fs nodes=%9d per_node=%7.1fns\n%!"
    label seconds nodes (per_node *. 1e9)

(* The clock read and the path construction at every node, with no wide path:
   the per-node cost a deadline tick adds to a decode whose values are small. *)
let flat_cell () =
  let elements = 4000000 in
  let parsed = parse "flat list" (flat_trace elements) in
  let stats = Decoder.fresh_stats () in
  let decls = [ ("v", Ir_types.List Ir_types.Str) ] in
  let reference = Unix.gettimeofday () in
  let outcome =
    Decoder.decode_typed_at ~stats ~deadline_at:(started_at +. 3600.0) ~decls
      parsed
  in
  let seconds = elapsed reference in
  match outcome with
  | Error refusal ->
      Printf.printf "bench: flat list refused: %s\n%!" refusal.Decoder.message
  | Ok _ ->
      report
        (Printf.sprintf "flat list %d elements" elements)
        seconds stats.Decoder.nodes;
      Printf.printf "bench: %-28s ticks=%d nodes=%d\n%!" "flat list counters"
        stats.Decoder.ticks stats.Decoder.nodes

(* One path built from the whole member name at every node, under a one-second
   deadline: the refusal time is the deadline plus the one node in flight. *)
let wide_cell label width nodes =
  let parsed = parse label (wide_name_trace ~width ~nodes ()) in
  let stats = Decoder.fresh_stats () in
  let reference = Unix.gettimeofday () in
  let outcome =
    Decoder.decode_structural_at ~stats
      ~deadline_at:(Unix.gettimeofday () +. 1.0)
      ~names:[ "l" ] parsed
  in
  let seconds = elapsed reference in
  match outcome with
  | Ok () ->
      Printf.printf "bench: %s completed inside its deadline\n%!" label;
      report label seconds stats.Decoder.nodes
  | Error refusal ->
      report label seconds stats.Decoder.nodes;
      Printf.printf "bench: %-28s refusal=%s class=%d\n%!" label
        refusal.Decoder.stage refusal.Decoder.klass

let () =
  Printf.printf "bench: start=%s\n%!"
    (let tm = Unix.localtime started_at in
     Printf.sprintf "%04d-%02d-%02d %02d:%02d:%02d" (tm.Unix.tm_year + 1900)
       (tm.Unix.tm_mon + 1) tm.Unix.tm_mday tm.Unix.tm_hour tm.Unix.tm_min
       tm.Unix.tm_sec);
  flat_cell ();
  wide_cell "wide name 4 MiB, 4002 nodes" (4 * 1024 * 1024) 4002;
  wide_cell "wide name 16 MiB, 4002 nodes" (16 * 1024 * 1024) 4002;
  Printf.printf "bench: done elapsed=%.3fs\n%!" (elapsed started_at)
