(* JSON Schema validator for the keyword subset the three shipped schemas
   use, matching the reference Janet validator rather than the full
   draft 2020-12 surface. Licence: AGPL-3.0-or-later; see README.md. *)

open Json_ast

type quant = One | Opt | Plus | Star | Rep of int * int

type node =
  | Lit of char
  | Class of bool * (char * char) list
  | Group of seq list

and atom = { node : node; quant : quant }
and seq = atom list

type pattern = { alts : seq list; start_anchor : bool; end_anchor : bool }

(** Schema keywords the validator accepts; any other key is an error. *)
let allowed_keywords =
  [
    "$schema";
    "$id";
    "title";
    "description";
    "$comment";
    "$defs";
    "type";
    "const";
    "enum";
    "required";
    "properties";
    "additionalProperties";
    "propertyNames";
    "minProperties";
    "maxProperties";
    "items";
    "minItems";
    "maxItems";
    "uniqueItems";
    "minLength";
    "maxLength";
    "pattern";
    "minimum";
    "maximum";
    "allOf";
    "anyOf";
    "oneOf";
    "not";
    "if";
    "then";
    "else";
    "$ref";
  ]

(** Parses a pattern string into a pattern tree. Handles classes, groups,
    alternation and quantifiers; raises [Failure] when a class, group or
    quantifier is malformed. *)
let parse_pattern (pat : string) : pattern =
  let start_anchor = String.length pat > 0 && pat.[0] = '^' in
  let end_anchor = String.length pat > 0 && pat.[String.length pat - 1] = '$' in
  let body_start = if start_anchor then 1 else 0 in
  let body_end =
    if end_anchor then String.length pat - 1 else String.length pat
  in
  let body = String.sub pat body_start (body_end - body_start) in
  let n = String.length body in
  let pos = ref 0 in
  let peek () = if !pos < n then Some body.[!pos] else None in
  let parse_class () =
    incr pos;
    let neg =
      if !pos < n && body.[!pos] = '^' then (
        incr pos;
        true)
      else false
    in
    let ranges = ref [] in
    let closed = ref false in
    while (not !closed) && !pos < n do
      let lo = body.[!pos] in
      incr pos;
      if lo = ']' then closed := true
      else if !pos + 1 < n && body.[!pos] = '-' && body.[!pos + 1] <> ']' then begin
        let hi = body.[!pos + 1] in
        ranges := (lo, hi) :: !ranges;
        pos := !pos + 2
      end
      else ranges := (lo, lo) :: !ranges
    done;
    if not !closed then failwith "unterminated character class";
    Class (neg, List.rev !ranges)
  in
  let parse_quant () =
    match peek () with
    | Some '?' ->
        incr pos;
        Opt
    | Some '+' ->
        incr pos;
        Plus
    | Some '*' ->
        incr pos;
        Star
    | Some '{' ->
        let close =
          match String.index_from_opt body !pos '}' with
          | Some at -> at
          | None -> failwith "unterminated quantifier"
        in
        let qbody = String.sub body (!pos + 1) (close - !pos - 1) in
        let parts = String.split_on_char ',' qbody in
        let lo = int_of_string (List.hd parts) in
        let hi =
          match parts with [ _; m ] when m <> "" -> int_of_string m | _ -> lo
        in
        pos := close + 1;
        Rep (lo, hi)
    | _ -> One
  in
  let rec parse_atom () =
    let node =
      match peek () with
      | Some '(' ->
          incr pos;
          let alts = parse_alts () in
          if !pos >= n || body.[!pos] <> ')' then failwith "unterminated group";
          incr pos;
          Group alts
      | Some '[' -> parse_class ()
      | Some '\\' ->
          incr pos;
          if !pos >= n then Lit '\\'
          else
            let c = body.[!pos] in
            incr pos;
            Lit c
      | Some c ->
          incr pos;
          Lit c
      | None -> failwith "unexpected end of pattern"
    in
    { node; quant = parse_quant () }
  and parse_seq () =
    let atoms = ref [] in
    let more = ref true in
    while !more do
      match peek () with
      | Some '|' | Some ')' | None -> more := false
      | Some _ -> atoms := parse_atom () :: !atoms
    done;
    List.rev !atoms
  and parse_alts () =
    let alts = ref [ parse_seq () ] in
    while !pos < n && body.[!pos] = '|' do
      incr pos;
      alts := parse_seq () :: !alts
    done;
    List.rev !alts
  in
  { alts = parse_alts (); start_anchor; end_anchor }

(** Removes duplicates from a position list, keeping first occurrences. *)
let dedup_positions xs =
  List.fold_left (fun acc x -> if List.mem x acc then acc else x :: acc) [] xs
  |> List.rev

(** Positions reachable after matching one node at [pos]. The result is empty
    when the node does not match there. *)
let rec match_node node s pos =
  match node with
  | Lit c -> if pos < String.length s && s.[pos] = c then [ pos + 1 ] else []
  | Class (neg, ranges) ->
      if pos >= String.length s then []
      else
        let c = s.[pos] in
        let hit = List.exists (fun (lo, hi) -> c >= lo && c <= hi) ranges in
        if if neg then not hit else hit then [ pos + 1 ] else []
  | Group alts -> match_alts alts s pos

and match_alts alts s pos =
  List.concat_map (fun seq -> match_seq seq s pos) alts |> dedup_positions

and match_seq seq s pos =
  match seq with
  | [] -> [ pos ]
  | atom :: rest ->
      List.concat_map
        (fun next -> match_seq rest s next)
        (match_atom atom s pos)
      |> dedup_positions

and match_atom atom s pos =
  let node = atom.node in
  match atom.quant with
  | One -> match_node node s pos
  | Opt -> dedup_positions (pos :: match_node node s pos)
  | Plus ->
      List.concat_map
        (fun next -> star_match node s next)
        (match_node node s pos)
      |> dedup_positions
  | Star -> star_match node s pos
  | Rep (lo, hi) ->
      let rec repeat k positions =
        if k = 0 then positions
        else
          repeat (k - 1)
            (List.concat_map (fun p -> match_node node s p) positions
            |> dedup_positions)
      in
      let rec up k acc =
        if k > hi then acc
        else
          let positions = repeat k [ pos ] in
          up (k + 1) (positions @ acc)
      in
      up lo [] |> dedup_positions

and star_match node s pos =
  let first = match_node node s pos in
  let seen = ref (dedup_positions (pos :: first)) in
  let frontier = ref first in
  while !frontier <> [] do
    let next = ref [] in
    List.iter
      (fun p ->
        List.iter
          (fun q ->
            if not (List.mem q !seen) then begin
              seen := q :: !seen;
              next := q :: !next
            end)
          (match_node node s p))
      !frontier;
    frontier := !next
  done;
  List.rev !seen

(** Whether [value] matches [pat] anywhere, honouring ^ and $ anchors. Raises
    [Failure] when the pattern cannot be parsed. *)
let pattern_match (pat : string) (value : string) : bool =
  let parsed = parse_pattern pat in
  let starts =
    if parsed.start_anchor then [ 0 ]
    else List.init (String.length value + 1) (fun i -> i)
  in
  List.exists
    (fun start ->
      List.exists
        (fun finish -> (not parsed.end_anchor) || finish = String.length value)
        (match_alts parsed.alts value start))
    starts

(* Schema validation. *)

(** Member of a JSON object, when the value is an object holding that key. *)
let get key = function
  | Object members -> List.assoc_opt key members
  | _ -> None

(** Resolves a local "#/..." reference inside the root schema. Raises [Failure]
    when the reference is not local or does not resolve. *)
let resolve_ref root ref =
  if String.length ref < 2 || String.sub ref 0 2 <> "#/" then
    failwith ("unsupported $ref " ^ ref);
  let parts =
    String.split_on_char '/' (String.sub ref 2 (String.length ref - 2))
  in
  let rec walk node = function
    | [] -> node
    | part :: rest -> (
        match get part node with
        | Some next -> walk next rest
        | None -> failwith ("unresolvable $ref " ^ ref))
  in
  walk root parts

(** Whether an instance has the named JSON type; unknown names never match. *)
let type_matches want inst =
  match want with
  | "null" -> inst = Null
  | "boolean" -> ( match inst with Bool _ -> true | _ -> false)
  | "number" -> ( match inst with Number _ -> true | _ -> false)
  | "integer" -> (
      match inst with Number raw -> number_is_integer raw | _ -> false)
  | "string" -> ( match inst with String _ -> true | _ -> false)
  | "array" -> ( match inst with Array _ -> true | _ -> false)
  | "object" -> ( match inst with Object _ -> true | _ -> false)
  | _ -> false

(** Error messages for [inst] against [schema], each prefixed by [path]. Every
    supported keyword is checked; the list is empty when the instance is valid,
    and an unsupported reference raises [Failure]. *)
let rec errors_for root schema inst path =
  match schema with
  | Object schema_members ->
      let errs = ref [] in
      let fail msg = errs := (path ^ ": " ^ msg) :: !errs in
      List.iter
        (fun key ->
          if not (List.mem key allowed_keywords) then
            fail ("unsupported schema keyword " ^ key))
        (List.map fst schema_members);
      (match List.assoc_opt "$ref" schema_members with
      | Some (String ref) ->
          errs := errors_for root (resolve_ref root ref) inst path @ !errs
      | _ -> ());
      (match List.assoc_opt "type" schema_members with
      | Some (String want) ->
          if not (type_matches want inst) then
            fail ("expected type " ^ want ^ ", got " ^ type_name inst)
      | Some (Array wants) ->
          let wants =
            List.filter_map (function String s -> Some s | _ -> None) wants
          in
          if not (List.exists (fun want -> type_matches want inst) wants) then
            fail
              ("expected type " ^ String.concat "|" wants ^ ", got "
             ^ type_name inst)
      | _ -> ());
      (match List.assoc_opt "const" schema_members with
      | Some expected ->
          if not (equal expected inst) then
            fail "value does not match the constant"
      | None -> ());
      (match List.assoc_opt "enum" schema_members with
      | Some (Array values) ->
          if not (List.exists (fun value -> equal value inst) values) then
            fail "value is not in the enum"
      | _ -> ());
      (match inst with
      | String s -> (
          (match List.assoc_opt "minLength" schema_members with
          | Some (Number raw) ->
              if utf8_length s < int_of_float (float_of_string raw) then
                fail "shorter than minLength"
          | _ -> ());
          (match List.assoc_opt "maxLength" schema_members with
          | Some (Number raw) ->
              if utf8_length s > int_of_float (float_of_string raw) then
                fail "longer than maxLength"
          | _ -> ());
          match List.assoc_opt "pattern" schema_members with
          | Some (String pat) ->
              if not (pattern_match pat s) then
                fail ("does not match pattern " ^ pat)
          | _ -> ())
      | Number raw -> (
          (match List.assoc_opt "minimum" schema_members with
          | Some (Number min_raw) ->
              if float_of_string raw < float_of_string min_raw then
                fail "below minimum"
          | _ -> ());
          match List.assoc_opt "maximum" schema_members with
          | Some (Number max_raw) ->
              if float_of_string raw > float_of_string max_raw then
                fail "above maximum"
          | _ -> ())
      | Array items -> (
          (match List.assoc_opt "minItems" schema_members with
          | Some (Number raw) ->
              if List.length items < int_of_float (float_of_string raw) then
                fail "fewer than minItems"
          | _ -> ());
          (match List.assoc_opt "maxItems" schema_members with
          | Some (Number raw) ->
              if List.length items > int_of_float (float_of_string raw) then
                fail "more than maxItems"
          | _ -> ());
          (match List.assoc_opt "uniqueItems" schema_members with
          | Some (Bool true) ->
              let rec check i = function
                | [] -> ()
                | x :: rest ->
                    if List.exists (fun y -> equal x y) rest then
                      fail ("duplicate item at " ^ string_of_int i);
                    check (i + 1) rest
              in
              check 0 items
          | _ -> ());
          match List.assoc_opt "items" schema_members with
          | Some items_schema ->
              List.iteri
                (fun i item ->
                  errs :=
                    errors_for root items_schema item
                      (path ^ "/" ^ string_of_int i)
                    @ !errs)
                items
          | None -> ())
      | Object inst_members -> (
          (match List.assoc_opt "minProperties" schema_members with
          | Some (Number raw) ->
              if List.length inst_members < int_of_float (float_of_string raw)
              then fail "fewer than minProperties"
          | _ -> ());
          (match List.assoc_opt "maxProperties" schema_members with
          | Some (Number raw) ->
              if List.length inst_members > int_of_float (float_of_string raw)
              then fail "more than maxProperties"
          | _ -> ());
          (match List.assoc_opt "required" schema_members with
          | Some (Array required) ->
              List.iter
                (function
                  | String key ->
                      if not (List.mem_assoc key inst_members) then
                        fail ("missing required member " ^ key)
                  | _ -> ())
                required
          | _ -> ());
          let properties =
            match List.assoc_opt "properties" schema_members with
            | Some (Object props) -> props
            | _ -> []
          in
          List.iter
            (fun (key, value) ->
              match List.assoc_opt key properties with
              | Some sub ->
                  errs := errors_for root sub value (path ^ "/" ^ key) @ !errs
              | None -> (
                  match
                    List.assoc_opt "additionalProperties" schema_members
                  with
                  | Some (Bool false) -> fail ("unexpected member " ^ key)
                  | Some (Object _ as sub) ->
                      errs :=
                        errors_for root sub value (path ^ "/" ^ key) @ !errs
                  | _ -> ()))
            inst_members;
          match List.assoc_opt "propertyNames" schema_members with
          | Some names_schema ->
              List.iter
                (fun (key, _) ->
                  errs :=
                    errors_for root names_schema (String key) (path ^ "/<key>")
                    @ !errs)
                inst_members
          | None -> ())
      | _ -> ());
      (match List.assoc_opt "allOf" schema_members with
      | Some (Array subs) ->
          List.iter
            (fun sub -> errs := errors_for root sub inst path @ !errs)
            subs
      | _ -> ());
      (match List.assoc_opt "anyOf" schema_members with
      | Some (Array subs) ->
          if
            not
              (List.exists (fun sub -> errors_for root sub inst path = []) subs)
          then fail "no anyOf branch matched"
      | _ -> ());
      (match List.assoc_opt "oneOf" schema_members with
      | Some (Array subs) ->
          let hits =
            List.length
              (List.filter (fun sub -> errors_for root sub inst path = []) subs)
          in
          if hits <> 1 then
            fail ("expected exactly one oneOf branch, got " ^ string_of_int hits)
      | _ -> ());
      (match List.assoc_opt "not" schema_members with
      | Some sub ->
          if errors_for root sub inst path = [] then
            fail "value matches a forbidden schema"
      | None -> ());
      (match List.assoc_opt "if" schema_members with
      | Some condition -> (
          if errors_for root condition inst path = [] then
            match List.assoc_opt "then" schema_members with
            | Some then_schema ->
                errs := errors_for root then_schema inst path @ !errs
            | None -> ()
          else
            match List.assoc_opt "else" schema_members with
            | Some else_schema ->
                errs := errors_for root else_schema inst path @ !errs
            | None -> ())
      | None -> ());
      List.rev !errs
  | _ -> []

(** Error messages for a document validated against a schema. *)
let validate_doc schema document = errors_for schema schema document "#"
