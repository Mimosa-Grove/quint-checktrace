(* Generated fixture table for the OCaml corpus generator.
   Every entry is the data the generator writes; the writer recomputes the
   trace digest and the report's metadata projection from the bytes it
   writes. Licence: AGPL-3.0-or-later; see README.md. *)

type json =
  | JNull
  | JBool of bool
  | JNum of int
  | JStr of string
  | JArr of json list
  | JObj of (string * json) list

type trace = TText of string | TJson of json

type entry = {
  name : string;
  spec : string;
  trace : trace;
  trace_rel : string option;
  expected : json;
  expected_human : json option;
  derivation : string option;
  hand : bool;
}

let entry_apalache_instrumentation =
  {
    name = "apalache-instrumentation";
    spec = "module LassoCheck {\n  var x: int\n\n  val nonNegative = x >= 0\n}";
    trace =
      TText
        "{\"#meta\":{\"format\":\"ITF\",\"format-description\":\"https://apalache-mc.org/docs/adr/015adr-trace.html\",\"description\":\"Created \
         by Apalache on Fri Nov 13 09:17:20 UTC \
         2026\",\"varTypes\":{\"__temporal_t_1\":\"Bool\",\"__saved___temporal_t_1\":\"Bool\",\"__temporal_t_2\":\"Bool\",\"__saved___temporal_t_2\":\"Bool\",\"__temporal_t_2_unroll\":\"Bool\",\"__temporal_t_2_unroll_prev\":\"Bool\",\"__q::temporalProps_init\":\"Bool\",\"__saved_x\":\"Int\",\"__InLoop\":\"Bool\",\"x\":\"Int\"},\"variables-to-expressions\":{\"__temporal_t_2\":\"\xe2\x97\x87(x \
         = 1)\",\"__temporal_t_1\":\"\xe2\x97\x87(x = \
         1)\",\"__saved___temporal_t_1\":\"__saved_\xe2\x97\x87(x = \
         1)\",\"__saved___temporal_t_2\":\"__saved_\xe2\x97\x87(x = \
         1)\"}},\"vars\":[\"__temporal_t_1\",\"__saved___temporal_t_1\",\"__temporal_t_2\",\"__saved___temporal_t_2\",\"__temporal_t_2_unroll\",\"__temporal_t_2_unroll_prev\",\"__q::temporalProps_init\",\"__saved_x\",\"__InLoop\",\"x\"],\"states\":[{\"#meta\":{\"index\":0},\"__InLoop\":false,\"__q::temporalProps_init\":false,\"__saved___temporal_t_1\":false,\"__saved___temporal_t_2\":false,\"__saved_x\":{\"#bigint\":\"0\"},\"__temporal_t_1\":false,\"__temporal_t_2\":false,\"__temporal_t_2_unroll\":false,\"__temporal_t_2_unroll_prev\":false,\"x\":{\"#bigint\":\"0\"}},{\"#meta\":{\"index\":1},\"__InLoop\":true,\"__q::temporalProps_init\":false,\"__saved___temporal_t_1\":false,\"__saved___temporal_t_2\":false,\"__saved_x\":{\"#bigint\":\"0\"},\"__temporal_t_1\":false,\"__temporal_t_2\":false,\"__temporal_t_2_unroll\":false,\"__temporal_t_2_unroll_prev\":false,\"x\":{\"#bigint\":\"0\"}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ( "ignored_vars",
                  JArr
                    [
                      JStr "__InLoop";
                      JStr "__q::temporalProps_init";
                      JStr "__saved___temporal_t_1";
                      JStr "__saved___temporal_t_2";
                      JStr "__saved_x";
                      JStr "__temporal_t_1";
                      JStr "__temporal_t_2";
                      JStr "__temporal_t_2_unroll";
                      JStr "__temporal_t_2_unroll_prev";
                    ] );
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 2);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "producer-trace");
          ("fixture", JStr "apalache-instrumentation");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "apalache-instrumentation.qnt";
                      JStr "apalache-instrumentation.itf.json";
                      JStr "--main=LassoCheck";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "origin",
                  JStr
                    "copied unmodified from traces/lasso.itf.json (Apalache \
                     0.62.4 temporal counterexample)" );
              ] );
          ( "requirement",
            JStr
              "R36: Apalache __ instrumentation is ignored when every spec \
               variable is present" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_10e15_bigint =
  {
    name = "bigint-10e15-bigint";
    spec =
      "module BigValue {\n  var x: int\n\n  val exact = x == 1000000000000000}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"1000000000000000\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-10e15-bigint");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-10e15-bigint.qnt";
                      JStr "bigint-10e15-bigint.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Probe: $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-10e15-bigint.json returned exit 0 with \
                     {\"results\":[{\"value\":true}]} with the #bigint state. \
                     Request: probes/bigint-10e15-bigint.json" );
              ] );
          ( "requirement",
            JStr
              "R36: the #bigint twin of an integer form gives the identical \
               verdict" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_10e15 =
  {
    name = "bigint-10e15";
    spec =
      "module BigValue {\n  var x: int\n\n  val exact = x == 1000000000000000}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"10\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"15\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-10e15");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-10e15.qnt";
                      JStr "bigint-10e15.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: run from the fixtures root, \
                     `$HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-10e15-normalised.json` returned exit 0 with \
                     {\"results\":[{\"value\":true}]} on the normalised state \
                     {\"#bigint\":\"1000000000000000\"}. The unnormalised \
                     {s,e,c} state returned false at exit 0, which is the \
                     silent wrong value the normalisation prevents. Request: \
                     probes/bigint-10e15-normalised.json" );
              ] );
          ( "requirement",
            JStr
              "R36: an integer form normalises to its decimal value and the \
               exact comparison passes" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_9007199254740993_bigint =
  {
    name = "bigint-9007199254740993-bigint";
    spec =
      "module BigValue {\n  var x: int\n\n  val exact = x == 9007199254740993}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"9007199254740993\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-9007199254740993-bigint");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-9007199254740993-bigint.qnt";
                      JStr "bigint-9007199254740993-bigint.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Probe: $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-9007199254740993-bigint.json returned exit \
                     0 with {\"results\":[{\"value\":true}]} with the #bigint \
                     state. Request: \
                     probes/bigint-9007199254740993-bigint.json" );
              ] );
          ( "requirement",
            JStr
              "R36: the #bigint twin of an integer form gives the identical \
               verdict" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_9007199254740993 =
  {
    name = "bigint-9007199254740993";
    spec =
      "module BigValue {\n  var x: int\n\n  val exact = x == 9007199254740993}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"90\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"7199254740993\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"15\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-9007199254740993");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-9007199254740993.qnt";
                      JStr "bigint-9007199254740993.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: run from the fixtures root, \
                     `$HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-9007199254740993-normalised.json` returned \
                     exit 0 with {\"results\":[{\"value\":true}]} on the \
                     normalised state {\"#bigint\":\"9007199254740993\"}. The \
                     unnormalised {s,e,c} state returned false at exit 0, \
                     which is the silent wrong value the normalisation \
                     prevents. Request: \
                     probes/bigint-9007199254740993-normalised.json" );
              ] );
          ( "requirement",
            JStr
              "R36: an integer form normalises to its decimal value and the \
               exact comparison passes" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_999999999999999999_bigint =
  {
    name = "bigint-999999999999999999-bigint";
    spec =
      "module BigValue {\n\
      \  var x: int\n\n\
      \  val exact = x == 999999999999999999}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"999999999999999999\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-999999999999999999-bigint");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-999999999999999999-bigint.qnt";
                      JStr "bigint-999999999999999999-bigint.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Probe: $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-999999999999999999-bigint.json returned \
                     exit 0 with {\"results\":[{\"value\":true}]} with the \
                     #bigint state. Request: \
                     probes/bigint-999999999999999999-bigint.json" );
              ] );
          ( "requirement",
            JStr
              "R36: the #bigint twin of an integer form gives the identical \
               verdict" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_999999999999999999 =
  {
    name = "bigint-999999999999999999";
    spec =
      "module BigValue {\n\
      \  var x: int\n\n\
      \  val exact = x == 999999999999999999}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"9999\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"99999999999999\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"17\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-999999999999999999");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-999999999999999999.qnt";
                      JStr "bigint-999999999999999999.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: run from the fixtures root, \
                     `$HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-999999999999999999-normalised.json` \
                     returned exit 0 with {\"results\":[{\"value\":true}]} on \
                     the normalised state \
                     {\"#bigint\":\"999999999999999999\"}. The unnormalised \
                     {s,e,c} state returned false at exit 0, which is the \
                     silent wrong value the normalisation prevents. Request: \
                     probes/bigint-999999999999999999-normalised.json" );
              ] );
          ( "requirement",
            JStr
              "R36: an integer form normalises to its decimal value and the \
               exact comparison passes" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_beyond_i64_typescript =
  {
    name = "bigint-beyond-i64-typescript";
    spec = "module BigOnly {\n  var big: int\n\n  val bigPositive = big > 0\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"big\": {\n\
        \        \"#bigint\": \"18446744073709551616\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"big\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "evaluate" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "probe");
          ("expected_stage", JStr "evaluate");
          ("fixture", JStr "bigint-beyond-i64-typescript");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-beyond-i64-typescript.qnt";
                      JStr "bigint-beyond-i64-typescript.itf.json";
                      JStr "--main=BigOnly";
                      JStr "--invariant=bigPositive";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: run from the fixtures root, \
                     `$HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-beyond-i64.json` exited 101 with a panic at \
                     src/itf.rs:144:43, BigInt value does not fit in i64. \
                     Observed exit 101 and no result document. The checker \
                     maps the non-zero exit to exit 2 at stage evaluate. \
                     Request: probes/bigint-beyond-i64.json" );
              ] );
          ( "requirement",
            JStr
              "R36: a #bigint beyond i64 in an evaluated state exits 2 at \
               stage evaluate" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_chunk_noncanonical =
  {
    name = "bigint-chunk-noncanonical";
    spec =
      "module BigValue {\n  var x: int\n\n  val exact = x == 100000000000001}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"01\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"00000000000001\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"14\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-chunk-noncanonical");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-chunk-noncanonical.qnt";
                      JStr "bigint-chunk-noncanonical.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: run from the fixtures root, \
                     `$HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-chunk-noncanonical-normalised.json` \
                     returned exit 0 with {\"results\":[{\"value\":true}]} on \
                     the normalised state {\"#bigint\":\"100000000000001\"}. \
                     The unnormalised {s,e,c} state returned false at exit 0, \
                     which is the silent wrong value the normalisation \
                     prevents. Request: \
                     probes/bigint-chunk-noncanonical-normalised.json" );
              ] );
          ( "requirement",
            JStr
              "R36: an integer form normalises to its decimal value and the \
               exact comparison passes" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_chunk_range =
  {
    name = "bigint-chunk-range";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"100000000000000\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"14\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "x"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-chunk-range");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-chunk-range.qnt";
                      JStr "bigint-chunk-range.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_e_noncanonical =
  {
    name = "bigint-e-noncanonical";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"10\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"01\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "e"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-e-noncanonical");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-e-noncanonical.qnt";
                      JStr "bigint-e-noncanonical.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_empty_chunks =
  {
    name = "bigint-empty-chunks";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"0\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "c"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-empty-chunks");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-empty-chunks.qnt";
                      JStr "bigint-empty-chunks.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_group_count =
  {
    name = "bigint-group-count";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"10\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"15\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "x"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-group-count");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-group-count.qnt";
                      JStr "bigint-group-count.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_i64_max_bigint =
  {
    name = "bigint-i64-max-bigint";
    spec =
      "module BigValue {\n\
      \  var x: int\n\n\
      \  val exact = x == 9223372036854775807}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"9223372036854775807\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-i64-max-bigint");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-i64-max-bigint.qnt";
                      JStr "bigint-i64-max-bigint.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Probe: $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-i64-max-bigint.json returned exit 0 with \
                     {\"results\":[{\"value\":true}]} with the #bigint state. \
                     Request: probes/bigint-i64-max-bigint.json" );
              ] );
          ( "requirement",
            JStr
              "R36: an integer form normalises to its decimal value and the \
               exact comparison passes" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_i64_max =
  {
    name = "bigint-i64-max";
    spec =
      "module BigValue {\n\
      \  var x: int\n\n\
      \  val exact = x == 9223372036854775807}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"92233\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"72036854775807\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"18\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-i64-max");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-i64-max.qnt";
                      JStr "bigint-i64-max.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: run from the fixtures root, \
                     `$HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-i64-max-normalised.json` returned exit 0 \
                     with {\"results\":[{\"value\":true}]} on the normalised \
                     state {\"#bigint\":\"9223372036854775807\"}. The \
                     unnormalised {s,e,c} state returned false at exit 0, \
                     which is the silent wrong value the normalisation \
                     prevents. Request: probes/bigint-i64-max-normalised.json"
                );
              ] );
          ( "requirement",
            JStr
              "R36: an integer form normalises to its decimal value and the \
               exact comparison passes" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_i64_min_bigint =
  {
    name = "bigint-i64-min-bigint";
    spec =
      "module BigValue {\n\
      \  var x: int\n\n\
      \  val exact = x == -9223372036854775808}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"-9223372036854775808\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-i64-min-bigint");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-i64-min-bigint.qnt";
                      JStr "bigint-i64-min-bigint.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Probe: $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-i64-min-bigint.json returned exit 0 with \
                     {\"results\":[{\"value\":true}]} with the #bigint state. \
                     Request: probes/bigint-i64-min-bigint.json" );
              ] );
          ( "requirement",
            JStr
              "R36: an integer form normalises to its decimal value and the \
               exact comparison passes" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_i64_min =
  {
    name = "bigint-i64-min";
    spec =
      "module BigValue {\n\
      \  var x: int\n\n\
      \  val exact = x == -9223372036854775808}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"92233\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"72036854775808\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"18\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"-1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-i64-min");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-i64-min.qnt";
                      JStr "bigint-i64-min.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: run from the fixtures root, \
                     `$HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-i64-min-normalised.json` returned exit 0 \
                     with {\"results\":[{\"value\":true}]} on the normalised \
                     state {\"#bigint\":\"-9223372036854775808\"}. The \
                     unnormalised {s,e,c} state returned false at exit 0, \
                     which is the silent wrong value the normalisation \
                     prevents. Request: probes/bigint-i64-min-normalised.json"
                );
              ] );
          ( "requirement",
            JStr
              "R36: an integer form normalises to its decimal value and the \
               exact comparison passes" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_ignored_key_fail =
  {
    name = "bigint-ignored-key-fail";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"10\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"15\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      },\n\
        \      \"extra\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"10\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"15\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr [ JStr "extra" ]);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "belowThree");
                          ("rendering", JStr "{ count: 1000000000000000 }");
                          ("state", JNum 0);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ( "count",
                                  JObj [ ("#bigint", JStr "1000000000000000") ]
                                );
                              ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "bigint-ignored-key-fail");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-ignored-key-fail.qnt";
                      JStr "bigint-ignored-key-fail.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=belowThree";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R29: a FAIL row's state_value strips an ignored key and shows \
               the normalised integer at the declared position" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_leading_zero_chunk =
  {
    name = "bigint-leading-zero-chunk";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"0\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"14\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "x"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-leading-zero-chunk");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-leading-zero-chunk.qnt";
                      JStr "bigint-leading-zero-chunk.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_negative_bigint =
  {
    name = "bigint-negative-bigint";
    spec =
      "module BigValue {\n  var x: int\n\n  val exact = x == -9007199254740993}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"-9007199254740993\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-negative-bigint");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-negative-bigint.qnt";
                      JStr "bigint-negative-bigint.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Probe: $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-negative-bigint.json returned exit 0 with \
                     {\"results\":[{\"value\":true}]} with the #bigint state. \
                     Request: probes/bigint-negative-bigint.json" );
              ] );
          ( "requirement",
            JStr
              "R36: the #bigint twin of an integer form gives the identical \
               verdict" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_negative_exponent =
  {
    name = "bigint-negative-exponent";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"-1\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "e"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-negative-exponent");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-negative-exponent.qnt";
                      JStr "bigint-negative-exponent.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_negative_over_i64 =
  {
    name = "bigint-negative-over-i64";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"92233\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"72036854775809\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"18\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"-1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "x"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-negative-over-i64");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-negative-over-i64.qnt";
                      JStr "bigint-negative-over-i64.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_negative =
  {
    name = "bigint-negative";
    spec =
      "module BigValue {\n  var x: int\n\n  val exact = x == -9007199254740993}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"90\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"7199254740993\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"15\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"-1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "bigint-negative");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-negative.qnt";
                      JStr "bigint-negative.itf.json";
                      JStr "--main=BigValue";
                      JStr "--invariant=exact";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: run from the fixtures root, \
                     `$HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/bigint-negative-normalised.json` returned exit 0 \
                     with {\"results\":[{\"value\":true}]} on the normalised \
                     state {\"#bigint\":\"-9007199254740993\"}. The \
                     unnormalised {s,e,c} state returned false at exit 0, \
                     which is the silent wrong value the normalisation \
                     prevents. Request: probes/bigint-negative-normalised.json"
                );
              ] );
          ( "requirement",
            JStr
              "R36: an integer form normalises to its decimal value and the \
               exact comparison passes" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_nested =
  {
    name = "bigint-nested";
    spec =
      "module NestedBig {\n\
      \  type Row = { n: int }\n\n\
      \  var r: Row\n\
      \  var l: List[int]\n\
      \  var s: Set[int]\n\
      \  var m: str -> int\n\
      \  var t: (int, int)\n\n\
      \  val belowZero = r.n < 0\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"l\": [\n\
        \        {\n\
        \          \"c\": [\n\
        \            {\n\
        \              \"#bigint\": \"7\"\n\
        \            }\n\
        \          ],\n\
        \          \"e\": {\n\
        \            \"#bigint\": \"0\"\n\
        \          },\n\
        \          \"s\": {\n\
        \            \"#bigint\": \"1\"\n\
        \          }\n\
        \        }\n\
        \      ],\n\
        \      \"m\": {\n\
        \        \"#map\": [\n\
        \          [\n\
        \            \"a\",\n\
        \            {\n\
        \              \"c\": [\n\
        \                {\n\
        \                  \"#bigint\": \"3\"\n\
        \                }\n\
        \              ],\n\
        \              \"e\": {\n\
        \                \"#bigint\": \"0\"\n\
        \              },\n\
        \              \"s\": {\n\
        \                \"#bigint\": \"1\"\n\
        \              }\n\
        \            }\n\
        \          ]\n\
        \        ]\n\
        \      },\n\
        \      \"r\": {\n\
        \        \"n\": {\n\
        \          \"c\": [\n\
        \            {\n\
        \              \"#bigint\": \"10\"\n\
        \            }\n\
        \          ],\n\
        \          \"e\": {\n\
        \            \"#bigint\": \"15\"\n\
        \          },\n\
        \          \"s\": {\n\
        \            \"#bigint\": \"1\"\n\
        \          }\n\
        \        }\n\
        \      },\n\
        \      \"s\": {\n\
        \        \"#set\": [\n\
        \          {\n\
        \            \"c\": [\n\
        \              {\n\
        \                \"#bigint\": \"2\"\n\
        \              }\n\
        \            ],\n\
        \            \"e\": {\n\
        \              \"#bigint\": \"0\"\n\
        \            },\n\
        \            \"s\": {\n\
        \              \"#bigint\": \"1\"\n\
        \            }\n\
        \          }\n\
        \        ]\n\
        \      },\n\
        \      \"t\": {\n\
        \        \"#tup\": [\n\
        \          {\n\
        \            \"c\": [\n\
        \              {\n\
        \                \"#bigint\": \"4\"\n\
        \              }\n\
        \            ],\n\
        \            \"e\": {\n\
        \              \"#bigint\": \"0\"\n\
        \            },\n\
        \            \"s\": {\n\
        \              \"#bigint\": \"1\"\n\
        \            }\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"5\"\n\
        \          }\n\
        \        ]\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"r\",\n\
        \    \"l\",\n\
        \    \"s\",\n\
        \    \"m\",\n\
        \    \"t\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "belowZero");
                          ( "rendering",
                            JStr
                              "{ l: [7], m: Map(\"a\" -> 3), r: { n: \
                               1000000000000000 }, s: Set(2), t: (4, 5) }" );
                          ("state", JNum 0);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ("l", JArr [ JObj [ ("#bigint", JStr "7") ] ]);
                                ( "m",
                                  JObj
                                    [
                                      ( "#map",
                                        JArr
                                          [
                                            JArr
                                              [
                                                JStr "a";
                                                JObj [ ("#bigint", JStr "3") ];
                                              ];
                                          ] );
                                    ] );
                                ( "r",
                                  JObj
                                    [
                                      ( "n",
                                        JObj
                                          [
                                            ("#bigint", JStr "1000000000000000");
                                          ] );
                                    ] );
                                ( "s",
                                  JObj
                                    [
                                      ( "#set",
                                        JArr [ JObj [ ("#bigint", JStr "2") ] ]
                                      );
                                    ] );
                                ( "t",
                                  JObj
                                    [
                                      ( "#tup",
                                        JArr
                                          [
                                            JObj [ ("#bigint", JStr "4") ];
                                            JObj [ ("#bigint", JStr "5") ];
                                          ] );
                                    ] );
                              ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "bigint-nested");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-nested.qnt";
                      JStr "bigint-nested.itf.json";
                      JStr "--main=NestedBig";
                      JStr "--invariant=belowZero";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R17: the {s,e,c} form normalises at nested declared-int \
               positions: a record field, a list element, a set element, a map \
               value and a tuple slot" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_positive_over_i64 =
  {
    name = "bigint-positive-over-i64";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"92233\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"72036854775808\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"18\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "x"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-positive-over-i64");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-positive-over-i64.qnt";
                      JStr "bigint-positive-over-i64.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_record_shape =
  {
    name = "bigint-record-shape";
    spec =
      "module BigRecord {\n\
      \  type Chunks = { s: int, e: int, c: List[int], extra: int }\n\n\
      \  var r: Chunks\n\n\
      \  val extraIsSeven = r.extra == 7\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"r\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"0\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"0\"\n\
        \        },\n\
        \        \"extra\": {\n\
        \          \"#bigint\": \"7\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"r\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "extraIsSeven"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "bigint-record-shape");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-record-shape.qnt";
                      JStr "bigint-record-shape.itf.json";
                      JStr "--main=BigRecord";
                      JStr "--invariant=extraIsSeven";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: an object carrying s, e, c and another key is a record, \
               not an integer" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_s_negative_zero =
  {
    name = "bigint-s-negative-zero";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"0\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"-0\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "s"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-s-negative-zero");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-s-negative-zero.qnt";
                      JStr "bigint-s-negative-zero.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_s_noncanonical =
  {
    name = "bigint-s-noncanonical";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"0\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"+1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr
                    [
                      JStr "decode";
                      JStr "class 10";
                      JStr "#bigint";
                      JStr "not a decimal string";
                      JStr "states/0/x/s";
                    ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-s-noncanonical");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-s-noncanonical.qnt";
                      JStr "bigint-s-noncanonical.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a non-decimal #bigint member of the chunk shape is refused \
               at the member position (class 10)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_s_two_chunk =
  {
    name = "bigint-s-two-chunk";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"0\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"2\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr
                    [
                      JStr "decode";
                      JStr "class 12";
                      JStr "malformed Rust big-integer";
                      JStr "field s sign text 2 is not canonical";
                      JStr "states/0/x";
                    ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-s-two-chunk");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-s-two-chunk.qnt";
                      JStr "bigint-s-two-chunk.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: the chunk form whose members pass the type-independent \
               checks keeps class 12 (R17)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_sign =
  {
    name = "bigint-sign";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"0\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"2\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "s"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-sign");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-sign.qnt";
                      JStr "bigint-sign.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_too_wide =
  {
    name = "bigint-too-wide";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"10\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"999999999999999991\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "e"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-too-wide");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-too-wide.qnt";
                      JStr "bigint-too-wide.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_trailing_zero_chunk =
  {
    name = "bigint-trailing-zero-chunk";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"0\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"14\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "x"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-trailing-zero-chunk");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-trailing-zero-chunk.qnt";
                      JStr "bigint-trailing-zero-chunk.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_width_mismatch =
  {
    name = "bigint-width-mismatch";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"15\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "x"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-width-mismatch");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-width-mismatch.qnt";
                      JStr "bigint-width-mismatch.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_width =
  {
    name = "bigint-width";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"16\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "e"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-width");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-width.qnt";
                      JStr "bigint-width.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigint_zero_chunk =
  {
    name = "bigint-zero-chunk";
    spec = "module BigRefusal {\n  var x: int\n\n  val ok = x >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"0\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"0\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "x"; JStr "states/0/x" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "bigint-zero-chunk");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigint-zero-chunk.qnt";
                      JStr "bigint-zero-chunk.itf.json";
                      JStr "--main=BigRefusal";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a malformed Rust big-integer object is refused (class 12)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_bigs_rust =
  {
    name = "bigs-rust";
    spec =
      "module Bigs {\n\
      \  var a: int\n\
      \  var b: int\n\
      \  var c: int\n\
      \  var d: int\n\n\
      \  val ok = a >= -1000000\n\
      \  val exact = and {\n\
      \    a == 1000000000000000,\n\
      \    b == 9007199254740993,\n\
      \    c == 999999999999999999,\n\
      \    d == -9007199254740993,\n\
      \  }\n\
       }";
    trace =
      TText
        "{\"#meta\":{\"format\":\"ITF\",\"format-description\":\"https://apalache-mc.org/docs/adr/015adr-trace.html\",\"source\":\"shapes/bigs.qnt\",\"status\":\"ok\",\"description\":\"Created \
         by Quint on Fri Nov 13 2026 09:25:32 GMT+0000 (Coordinated Universal \
         Time)\",\"timestamp\":1794561932034},\"vars\":[\"a\",\"b\",\"c\",\"d\"],\"states\":[{\"#meta\":{\"index\":0},\"a\":{\"s\":{\"#bigint\":\"1\"},\"e\":{\"#bigint\":\"15\"},\"c\":[{\"#bigint\":\"10\"}]},\"b\":{\"s\":{\"#bigint\":\"1\"},\"e\":{\"#bigint\":\"15\"},\"c\":[{\"#bigint\":\"90\"},{\"#bigint\":\"7199254740993\"}]},\"c\":{\"s\":{\"#bigint\":\"1\"},\"e\":{\"#bigint\":\"17\"},\"c\":[{\"#bigint\":\"9999\"},{\"#bigint\":\"99999999999999\"}]},\"d\":{\"s\":{\"#bigint\":\"-1\"},\"e\":{\"#bigint\":\"15\"},\"c\":[{\"#bigint\":\"90\"},{\"#bigint\":\"7199254740993\"}]}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "exact"); ("verdict", JStr "pass") ];
                      JObj [ ("name", JStr "ok"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 2) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "producer-trace");
          ("fixture", JStr "bigs-rust");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "bigs-rust.qnt";
                      JStr "bigs-rust.itf.json";
                      JStr "--main=Bigs";
                      JStr "--invariant=exact";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "origin",
                  JStr
                    "copied unmodified from traces/bigs.itf.json; the four \
                     values are 10^15, 9007199254740993, 999999999999999999 \
                     and -9007199254740993" );
              ] );
          ( "requirement",
            JStr
              "A5: the Rust {s,e,c} integer form is normalised before \
               evaluation" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class10_bare_number =
  {
    name = "class10-bare-number";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": 3\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "count"; JStr "states/0/count" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class10-bare-number");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class10-bare-number.qnt";
                      JStr "class10-bare-number.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a bare JSON number in a value position is refused (class \
               10)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class10_bigint =
  {
    name = "class10-bigint";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"12a\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "#bigint"; JStr "states/0/count" ]
                );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class10-bigint");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class10-bigint.qnt";
                      JStr "class10-bigint.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ("requirement", JStr "R36: a malformed #bigint is refused (class 10)");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class10_map =
  {
    name = "class10-map";
    spec =
      "module MapValue {\n  var m: int -> str\n\n  val ok = m.size() >= 0\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"m\": {\n\
        \        \"#map\": [\n\
        \          [\n\
        \            {\n\
        \              \"#bigint\": \"1\"\n\
        \            }\n\
        \          ]\n\
        \        ]\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"m\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "#map"; JStr "states/0/m" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class10-map");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class10-map.qnt";
                      JStr "class10-map.itf.json";
                      JStr "--main=MapValue";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a #map entry that is not a two-element array is refused \
               (class 10)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class10_set =
  {
    name = "class10-set";
    spec = "module SetValue {\n  var s: Set[int]\n\n  val ok = s.size() >= 0\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"s\": {\n\
        \        \"#set\": 1\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"s\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "#set"; JStr "states/0/s" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class10-set");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class10-set.qnt";
                      JStr "class10-set.itf.json";
                      JStr "--main=SetValue";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a #set that is not an array is refused (class 10)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class10_tup =
  {
    name = "class10-tup";
    spec =
      "module TupValue {\n  var t: (int, int)\n\n  val ok = t._1 >= -1000000\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"t\": {\n\
        \        \"#tup\": 1\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"t\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "#tup"; JStr "states/0/t" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class10-tup");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class10-tup.qnt";
                      JStr "class10-tup.itf.json";
                      JStr "--main=TupValue";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a #tup that is not an array is refused (class 10)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class10_variant_tag =
  {
    name = "class10-variant-tag";
    spec =
      "module Variant {\n\
      \  type Color = | Red | Green\n\n\
      \  var v: Color\n\n\
      \  val isRed = v == Red\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"v\": {\n\
        \        \"tag\": 5,\n\
        \        \"value\": 1\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"v\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr
                    [
                      JStr "decode";
                      JStr "tag";
                      JStr "variant";
                      JStr "states/0/v";
                    ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class10-variant-tag");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class10-variant-tag.qnt";
                      JStr "class10-variant-tag.itf.json";
                      JStr "--main=Variant";
                      JStr "--invariant=isRed";
                    ] );
              ] );
          ("requirement", JStr "R36: a malformed variant is refused (class 10)");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class13_int_for_record =
  {
    name = "class13-int-for-record";
    spec =
      "module RecRow {\n\
      \  type Row = { a: int, b: str }\n\n\
      \  var r: Row\n\n\
      \  val ok = r.a >= -1000000\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"r\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"r\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "r"; JStr "states/0/r" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class13-int-for-record");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class13-int-for-record.qnt";
                      JStr "class13-int-for-record.itf.json";
                      JStr "--main=RecRow";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: an integer where a record is declared is refused (class 13)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class13_list_element =
  {
    name = "class13-list-element";
    spec =
      "module ListInt {\n  var l: List[int]\n\n  val ok = l.length() >= 0\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"l\": [\n\
        \        \"not-an-int\"\n\
        \      ]\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"l\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "l"; JStr "states/0/l" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class13-list-element");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class13-list-element.qnt";
                      JStr "class13-list-element.itf.json";
                      JStr "--main=ListInt";
                      JStr "--invariant=ok";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a List[int] carrying a string is refused (class 13)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class13_variant_position =
  {
    name = "class13-variant-position";
    spec =
      "module Variant {\n\
      \  type Color = | Red | Green\n\n\
      \  var v: Color\n\n\
      \  val isRed = v == Red\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"v\": {\n\
        \        \"tag\": \"Red\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"v\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "v"; JStr "0"; JStr "states/0/v" ]
                );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class13-variant-position");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class13-variant-position.qnt";
                      JStr "class13-variant-position.itf.json";
                      JStr "--main=Variant";
                      JStr "--invariant=isRed";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a record at a variant-typed position is refused (class 13)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class9_record_hash =
  {
    name = "class9-record-hash";
    spec =
      "module Tagged {\n\
      \  type TaggedRecord = { tag: str, value: int, extra: int }\n\n\
      \  var r: TaggedRecord\n\n\
      \  val tagIsX = r.tag == \"x\"\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"r\": {\n\
        \        \"#weird\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        },\n\
        \        \"tag\": \"x\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"r\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "#weird"; JStr "states/0/r" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class9-record-hash");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class9-record-hash.qnt";
                      JStr "class9-record-hash.itf.json";
                      JStr "--main=Tagged";
                      JStr "--invariant=tagIsX";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a record field name starting with # is refused (class 9)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class9_two_hash =
  {
    name = "class9-two-hash";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\",\n\
        \        \"#tup\": []\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "#"; JStr "states/0/count" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class9-two-hash");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class9-two-hash.qnt";
                      JStr "class9-two-hash.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: an object with more than one # key is refused (class 9)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_class9_unknown_hash =
  {
    name = "class9-unknown-hash";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#foo\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "#foo"; JStr "states/0/count" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "class9-unknown-hash");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "class9-unknown-hash.qnt";
                      JStr "class9-unknown-hash.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: an unknown # prefixed constructor is refused (class 9)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_cli_values =
  {
    name = "cli-values";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("fixture", JStr "cli-values");
          ( "invocations",
            JArr
              [
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--timeout=0";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "0" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--timeout=0";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "0" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--timeout=-1";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "-1" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--timeout=-1";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "-1" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--timeout=abc";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "abc" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--timeout=abc";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "abc" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--timeout=1.5";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "1.5" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--timeout=1.5";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "1.5" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--timeout=inf";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "inf" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--timeout=inf";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "inf" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--timeout=nan";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "nan" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--timeout=nan";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--timeout"; JStr "nan" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--deadline=0";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--deadline"; JStr "0" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--deadline=0";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--deadline"; JStr "0" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--deadline=-1";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--deadline"; JStr "-1" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--deadline=-1";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ("must_contain", JArr [ JStr "--deadline"; JStr "-1" ]);
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--deadline=abc";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--deadline"; JStr "abc" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--deadline=abc";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--deadline"; JStr "abc" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--deadline=1.5";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--deadline"; JStr "1.5" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--deadline=1.5";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--deadline"; JStr "1.5" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--deadline=inf";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--deadline"; JStr "inf" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--deadline=inf";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--deadline"; JStr "inf" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--deadline=nan";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--deadline"; JStr "nan" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--deadline=nan";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--deadline"; JStr "nan" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--gate-deadline=0";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--gate-deadline"; JStr "0" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--gate-deadline=-1";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--gate-deadline"; JStr "-1" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--gate-deadline=abc";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--gate-deadline"; JStr "abc" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--gate-deadline=1.5";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--gate-deadline"; JStr "1.5" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--gate-deadline=inf";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--gate-deadline"; JStr "inf" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--gate-deadline=nan";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--gate-deadline"; JStr "nan" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "cli-values.qnt";
                          JStr "cli-values.itf.json";
                          JStr "--main=Base";
                          JStr "--invariant=nonNegative";
                          JStr "--timeout=30";
                          JStr "--deadline=5";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--timeout"; JStr "--deadline" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
                JObj
                  [
                    ( "args",
                      JArr
                        [
                          JStr "--gate";
                          JStr "corpus";
                          JStr "manifest.json";
                          JStr "hand-verified";
                          JStr "--timeout=30";
                          JStr "--deadline=5";
                        ] );
                    ( "expected_diagnostic",
                      JObj
                        [
                          ( "must_contain",
                            JArr [ JStr "--timeout"; JStr "--deadline" ] );
                        ] );
                    ("expected_exit", JNum 2);
                    ("expected_stage", JStr "usage");
                  ];
              ] );
          ( "requirement",
            JStr
              "R6, R36: malformed --timeout, --deadline and --gate-deadline \
               values, and a --timeout larger than --deadline, exit 2 at stage \
               usage" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_collision_record =
  {
    name = "collision-record";
    spec =
      "module Collision {\n\
      \  type TaggedRecord = { tag: str, value: int }\n\n\
      \  var r: TaggedRecord\n\n\
      \  val tagIsHello = r.tag == \"hello\"\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"r\": {\n\
        \        \"tag\": \"hello\",\n\
        \        \"value\": {\n\
        \          \"#bigint\": \"42\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"r\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr
                    [
                      JStr "decode";
                      JStr "r";
                      JStr "states";
                      JStr "0";
                      JStr "states/0/r";
                      JStr "tag";
                      JStr "value";
                      JStr "record";
                      JStr "variant";
                    ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "probe");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "collision-record");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "collision-record.qnt";
                      JStr "collision-record.itf.json";
                      JStr "--main=Collision";
                      JStr "--invariant=tagIsHello";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: at a record-typed position the two-key \
                     tag/value object is read as a variant, and field access \
                     panics. Command, run from the fixtures root: \
                     $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/collision-record-field.json Observed at exit 101: \
                     thread 'main' panicked at src/value.rs:779:18: Expected \
                     record" );
              ] );
          ( "requirement",
            JStr
              "R36: an exact two-key tag/value object at a record-typed \
               position is refused at decode (class 16)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_collision_unit =
  {
    name = "collision-unit";
    spec =
      "module UnitCollision {\n\
      \  type Tag = { tag: str }\n\n\
      \  var b: Tag\n\n\
      \  val tagIsUnit = b.tag == \"UNIT\"\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"b\": {\n\
        \        \"tag\": \"UNIT\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"b\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr
                    [
                      JStr "decode";
                      JStr "b";
                      JStr "states";
                      JStr "0";
                      JStr "states/0/b";
                      JStr "tag";
                      JStr "UNIT";
                      JStr "record";
                      JStr "unit";
                    ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "probe");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "collision-unit");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "collision-unit.qnt";
                      JStr "collision-unit.itf.json";
                      JStr "--main=UnitCollision";
                      JStr "--invariant=tagIsUnit";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: at a record-typed position the one-key \
                     UNIT object is read as a unit value, and field access \
                     panics. Command, run from the fixtures root: \
                     $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/unit-record-field.json Observed at exit 101: \
                     thread 'main' panicked at src/value.rs:779:18: Expected \
                     record" );
              ] );
          ( "requirement",
            JStr
              "R36: a one-key UNIT object at a record-typed position is \
               refused at decode (class 16)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_const_instance =
  {
    name = "const-instance";
    spec =
      "module Instance {\n\
      \  import Spec(C = Set(1, 2, 3)) as s from \"./spec\"\n\n\
      \  val bounded = s::bounded\n\
       }";
    trace =
      TText
        "{\"#meta\":{\"format\":\"ITF\",\"format-description\":\"https://apalache-mc.org/docs/adr/015adr-trace.html\",\"source\":\"const-instance/instance.qnt\",\"status\":\"ok\",\"description\":\"Created \
         by Quint on Sat Nov 14 2026 22:49:47 GMT+0000 (Coordinated Universal \
         Time)\",\"timestamp\":1794696587299},\"vars\":[\"Instance::s::seen\",\"Instance::s::x\"],\"states\":[{\"#meta\":{\"index\":0},\"Instance::s::seen\":{\"#set\":[]},\"Instance::s::x\":{\"#bigint\":\"0\"}},{\"#meta\":{\"index\":1},\"Instance::s::seen\":{\"#set\":[{\"#bigint\":\"1\"}]},\"Instance::s::x\":{\"#bigint\":\"1\"}},{\"#meta\":{\"index\":2},\"Instance::s::seen\":{\"#set\":[{\"#bigint\":\"1\"},{\"#bigint\":\"2\"}]},\"Instance::s::x\":{\"#bigint\":\"2\"}},{\"#meta\":{\"index\":3},\"Instance::s::seen\":{\"#set\":[{\"#bigint\":\"1\"},{\"#bigint\":\"2\"},{\"#bigint\":\"3\"}]},\"Instance::s::x\":{\"#bigint\":\"3\"}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "bounded");
                          ( "rendering",
                            JStr
                              "{ Instance::s::seen: Set(), Instance::s::x: 0 }"
                          );
                          ("state", JNum 0);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ("Instance::s::seen", JObj [ ("#set", JArr []) ]);
                                ( "Instance::s::x",
                                  JObj [ ("#bigint", JStr "0") ] );
                              ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 4);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "const-instance");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "const-instance.qnt";
                      JStr "const-instance.itf.json";
                      JStr "--main=Instance";
                      JStr "--invariant=bounded";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ("companion_file", JStr "spec.qnt");
                ( "origin",
                  JStr
                    "regenerated with Quint 0.33.1 (Rust backend, \
                     --max-steps=3) from a producer copy of the fixture spec \
                     carrying init and step actions; the spec imports Spec(C = \
                     Set(1, 2, 3)) from ./spec" );
                ( "probe",
                  JStr
                    "Probe: states 0, 1, 2 and 3 each returned exit 0. State 0 \
                     returned {\"results\":[{\"value\":false}]} because 0 is \
                     not in C = Set(1, 2, 3); states 1 to 3 returned \
                     {\"results\":[{\"value\":true}]}. Requests: \
                     probes/const-instance-eval.json and -1, -2, -3. Command: \
                     $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/const-instance-eval.json" );
              ] );
          ( "requirement",
            JStr
              "A6: instance variable names and a constant supplied by an \
               instance binding; the invariant reads C" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_duplicate_members =
  {
    name = "duplicate-members";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\"vars\":[\"count\"],\"states\":[{\"#meta\":{\"index\":0},\"count\":{\"#bigint\":\"0\"},\"count\":{\"#bigint\":\"1\"}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "count"; JStr "states/0/count" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "duplicate-members");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "duplicate-members.qnt";
                      JStr "duplicate-members.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: duplicate members inside a state are refused, naming the \
               member and its path (class 2)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_extra_key =
  {
    name = "extra-key";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      },\n\
        \      \"noise\": {\n\
        \        \"#bigint\": \"5\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr [ JStr "noise" ]);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "extra-key");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "extra-key.qnt";
                      JStr "extra-key.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: an extra unrelated state key is stripped and listed as \
               ignored" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_forged_ignored_key =
  {
    name = "forged-ignored-key";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      },\n\
        \      \"elsewhere\\nSummary: 1 pass, 0 fail (exit 0)\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_human",
            JObj
              [
                ( "escaped_renderings",
                  JArr
                    [ JStr "elsewhere\\u000aSummary: 1 pass, 0 fail (exit 0)" ]
                );
                ("single_line_information_lines", JBool true);
                ("source_rendering", JStr "source=absent");
                ("status_rendering", JStr "status=absent");
                ("summary_lines", JNum 1);
              ] );
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ( "ignored_vars",
                  JArr [ JStr "elsewhere\nSummary: 1 pass, 0 fail (exit 0)" ] );
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "forged-ignored-key");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "forged-ignored-key.qnt";
                      JStr "forged-ignored-key.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: an ignored key carrying a newline and forged summary text \
               is escaped in the information line" );
        ];
    expected_human =
      Some
        (JObj
           [
             ( "escaped_renderings",
               JArr [ JStr "elsewhere\\u000aSummary: 1 pass, 0 fail (exit 0)" ]
             );
             ("single_line_information_lines", JBool true);
             ("source_rendering", JStr "source=absent");
             ("status_rendering", JStr "status=absent");
             ("summary_lines", JNum 1);
           ]);
    derivation = None;
    hand = false;
  }

let entry_forged_path =
  {
    name = "forged-path";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"#meta\": {\n\
        \    \"status\": \"ok\"\n\
        \  },\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel =
      Some "forged-path\nSummary: 1 pass, 0 fail (exit 0)/trace.itf.json";
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_human",
            JObj
              [
                ( "escaped_renderings",
                  JArr
                    [
                      JStr
                        "forged-path\\u000aSummary: 1 pass, 0 fail (exit \
                         0)/trace.itf.json";
                    ] );
                ("single_line_header", JBool true);
                ("summary_lines", JNum 1);
              ] );
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 2);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "forged-path");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "forged-path.qnt";
                      JStr
                        "forged-path\n\
                         Summary: 1 pass, 0 fail (exit 0)/trace.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a trace file path carrying a newline and forged summary \
               text is escaped in the header" );
        ];
    expected_human =
      Some
        (JObj
           [
             ( "escaped_renderings",
               JArr
                 [
                   JStr
                     "forged-path\\u000aSummary: 1 pass, 0 fail (exit \
                      0)/trace.itf.json";
                 ] );
             ("single_line_header", JBool true);
             ("summary_lines", JNum 1);
           ]);
    derivation = None;
    hand = false;
  }

let entry_forged_source_meta =
  {
    name = "forged-source-meta";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"#meta\": {\n\
        \    \"source\": \"elsewhere\\nSummary: 1 pass, 0 fail (exit 0)\",\n\
        \    \"status\": \"ok\"\n\
        \  },\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_human",
            JObj
              [
                ( "escaped_renderings",
                  JArr
                    [ JStr "elsewhere\\u000aSummary: 1 pass, 0 fail (exit 0)" ]
                );
                ("single_line_header", JBool true);
                ("summary_lines", JNum 1);
                ("summary_token", JStr "source-mismatch");
              ] );
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 2);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "forged-source-meta");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "forged-source-meta.qnt";
                      JStr "forged-source-meta.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a #meta.source carrying a newline and forged summary text \
               is escaped in the header" );
        ];
    expected_human =
      Some
        (JObj
           [
             ( "escaped_renderings",
               JArr [ JStr "elsewhere\\u000aSummary: 1 pass, 0 fail (exit 0)" ]
             );
             ("single_line_header", JBool true);
             ("summary_lines", JNum 1);
             ("summary_token", JStr "source-mismatch");
           ]);
    derivation = None;
    hand = false;
  }

let entry_hand_bigint =
  {
    name = "hand-bigint";
    spec =
      "module HandBigMax {\n\
      \  var x: int\n\n\
      \  val atMax = x == 9223372036854775807\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"c\": [\n\
        \          {\n\
        \            \"#bigint\": \"92233\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"72036854775807\"\n\
        \          }\n\
        \        ],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"18\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("category", JStr "big-integer");
          ("derivation", JStr "hand-bigint.derivation.md");
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "atMax"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JBool false);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_silent", JArr []);
          ("expected_source", JStr "hand");
          ("fixture", JStr "hand-bigint");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "hand-bigint.qnt";
                      JStr "hand-bigint.itf.json";
                      JStr "--main=HandBigMax";
                      JStr "--invariant=atMax";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R46: a big-integer fixture with the value and verdict derived \
               by hand" );
        ];
    expected_human = None;
    derivation =
      Some
        "Property: the Rust {s,e,c} integer form denotes the i64 maximum, so the\n\
         equality against the decimal literal is true.\n\n\
         Expected result: exit 0. One verdict row, atMax PASS.\n\n\
         Reasoning: the object has s equal to 1, e equal to 18 and two chunks, \
         92233\n\
         and 72036854775807. The stored width is the leading chunk's digits \
         plus 14 per\n\
         non-leading chunk, which is 5 + 14 = 19 digits, and e + 1 is 19, so \
         the width\n\
         rule holds. The decimal text is the leading chunk followed by the \
         second chunk\n\
         padded to 14 digits: 9223372036854775807. That value is the largest \
         signed\n\
         64-bit integer, so it is inside the evaluator's range, and the \
         normalised\n\
         state carries the decimal #bigint form. The invariant atMax compares \
         x with\n\
         the literal 9223372036854775807, and the two are equal, so the state \
         passes.\n";
    hand = true;
  }

let entry_hand_evaluation_error =
  {
    name = "hand-evaluation-error";
    spec =
      "module HandUnbound {\n\
      \  const C: int\n\n\
      \  var count: int\n\n\
      \  val atC = count == C\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("category", JStr "evaluation-error");
          ("derivation", JStr "hand-evaluation-error.derivation.md");
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "evaluate"; JStr "atC"; JStr "0"; JStr "QNT500" ]
                );
              ] );
          ("expected_exit", JNum 2);
          ("expected_silent", JArr [ JStr "atC" ]);
          ("expected_source", JStr "hand");
          ("expected_stage", JStr "evaluate");
          ("fixture", JStr "hand-evaluation-error");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "hand-evaluation-error.qnt";
                      JStr "hand-evaluation-error.itf.json";
                      JStr "--main=HandUnbound";
                      JStr "--invariant=atC";
                    ] );
              ] );
          ( "requirement",
            JStr "R46: an evaluation-error fixture with its expected stage" );
        ];
    expected_human = None;
    derivation =
      Some
        "Property: an invariant whose expression reads an unbound constant \
         cannot be\n\
         evaluated, so the run is a could-not-run rather than a violation.\n\n\
         Expected result: exit 2 at stage evaluate. No verdict rows are \
         printed; the\n\
         invocation's only invariant, atC, is expected silent. The diagnostic \
         names\n\
         atC, state 0 and the Quint error code QNT500.\n\n\
         Reasoning: C is a constant with no default and no instance binding. The\n\
         constant is therefore unbound in the main module, and Quint reports \
         the same\n\
         condition as QNT500 for an equivalent run. The checker resolves \
         constants\n\
         from the parsed model and forwards the invariant expression to the\n\
         evaluator; an expression that reads an unbound constant produces an \
         error\n\
         result, and an error result is never a verdict. The failure order \
         places\n\
         evaluate after decode, so the diagnostic names stage evaluate. A \
         could-not-run\n\
         is exit 2 and is never a specification violation.\n";
    hand = true;
  }

let entry_hand_init_fail =
  {
    name = "hand-init-fail";
    spec =
      "module HandInitFail {\n  var count: int\n\n  val positive = count > 0\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("category", JStr "initial-state-violation");
          ("derivation", JStr "hand-init-fail.derivation.md");
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "positive");
                          ("rendering", JStr "{ count: 0 }");
                          ("state", JNum 0);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ("count", JObj [ ("#bigint", JStr "0") ]);
                              ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JBool false);
                ("states", JNum 2);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_silent", JArr []);
          ("expected_source", JStr "hand");
          ("fixture", JStr "hand-init-fail");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "hand-init-fail.qnt";
                      JStr "hand-init-fail.itf.json";
                      JStr "--main=HandInitFail";
                      JStr "--invariant=positive";
                    ] );
              ] );
          ("requirement", JStr "R46: an invariant false at the initial state");
        ];
    expected_human = None;
    derivation =
      Some
        "Property: the invariant positive is false at the initial recorded \
         state.\n\n\
         Expected result: exit 1. One verdict row, positive FAIL at state \
         index 0,\n\
         with the violating state rendered as { count: 0 }.\n\n\
         Reasoning: positive is count > 0. State 0 carries count 0, and 0 is not\n\
         greater than 0, so the invariant is false at the first state. The \
         checker\n\
         evaluates state 0 like every other recorded state, records the FAIL \
         there and\n\
         stops evaluating that invariant, because the earliest witness is the \
         verdict.\n\
         The first violating state is index 0. The expected row also records the\n\
         forwarded state at that index, {\"count\": {\"#bigint\": \"0\"}, \
         \"#meta\":\n\
         {}}, derived from the trace's state 0 and R21's empty forwarded #meta.\n";
    hand = true;
  }

let entry_hand_mixed =
  {
    name = "hand-mixed";
    spec =
      "module HandMixed {\n\
      \  var count: int\n\n\
      \  val belowThree = count < 3\n\
      \  val nonNegative = count >= 0\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"2\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 3\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"3\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("category", JStr "violation");
          ("derivation", JStr "hand-mixed.derivation.md");
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "belowThree");
                          ("rendering", JStr "{ count: 3 }");
                          ("state", JNum 3);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ("count", JObj [ ("#bigint", JStr "3") ]);
                              ] );
                          ("verdict", JStr "fail");
                        ];
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JBool false);
                ("states", JNum 4);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_silent", JArr []);
          ("expected_source", JStr "hand");
          ("fixture", JStr "hand-mixed");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "hand-mixed.qnt";
                      JStr "hand-mixed.itf.json";
                      JStr "--main=HandMixed";
                      JStr "--invariant=belowThree";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R46: every invariant of the invocation accounted for, one FAIL \
               and one PASS" );
        ];
    expected_human = None;
    derivation =
      Some
        "Property: both requested invariants are accounted for, and the early \
         stop of\n\
         one does not affect the other.\n\n\
         Expected result: exit 1. Two verdict rows, sorted by name: belowThree \
         FAIL at\n\
         state index 3 with rendering { count: 3 }, and nonNegative PASS. No \
         silent\n\
         invariant.\n\n\
         Reasoning: belowThree is count < 3. The recorded counts are 0, 1, 2 \
         and 3, so\n\
         the expression is first false at index 3. nonNegative is count >= 0, \
         which is\n\
         true at all four states; the early stop applies only to belowThree, so\n\
         nonNegative is evaluated to the end of the trace and is reported \
         PASS. One\n\
         failure is enough for exit 1, and the summary counts one pass and one \
         fail.\n\
         The FAIL row also records the forwarded state at index 3, {\"count\":\n\
         {\"#bigint\": \"3\"}, \"#meta\": {}}, derived from the trace's state \
         3 and\n\
         R21's empty forwarded #meta.\n";
    hand = true;
  }

let entry_hand_pass =
  {
    name = "hand-pass";
    spec =
      "module HandPass {\n  var count: int\n\n  val nonNegative = count >= 0\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"2\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("category", JStr "pass");
          ("derivation", JStr "hand-pass.derivation.md");
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JBool false);
                ("states", JNum 3);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_silent", JArr []);
          ("expected_source", JStr "hand");
          ("fixture", JStr "hand-pass");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "hand-pass.qnt";
                      JStr "hand-pass.itf.json";
                      JStr "--main=HandPass";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R46: a passing fixture with a complete expected outcome" );
        ];
    expected_human = None;
    derivation =
      Some
        "Property: the invariant nonNegative holds at every recorded state.\n\n\
         Expected result: exit 0. One verdict row, nonNegative PASS. No FAIL \
         row, no\n\
         silent invariant.\n\n\
         Reasoning: nonNegative is the expression count >= 0. The trace \
         records three\n\
         states with count 0, 1 and 2. Every recorded value is at least zero, \
         so the\n\
         expression is true at every state the checker evaluates. A PASS \
         covers the\n\
         recorded states only; no claim is made about the specification. \
         Nothing in\n\
         the trace is undecodable: the only variable is count, declared int, \
         present\n\
         in all three states, and every integer is in the decimal #bigint form.\n";
    hand = true;
  }

let entry_hand_precedence_scope =
  {
    name = "hand-precedence-scope";
    spec =
      "module HandPrecedenceScope {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val zeroDiv = 10 / (1 - count) < 0\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"2\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("category", JStr "multi-invariant-precedence");
          ("derivation", JStr "hand-precedence-scope.derivation.md");
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                      JObj
                        [
                          ("name", JStr "zeroDiv");
                          ("rendering", JStr "{ count: 0 }");
                          ("state", JNum 0);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ("count", JObj [ ("#bigint", JStr "0") ]);
                              ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JBool false);
                ("states", JNum 3);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_silent", JArr []);
          ("expected_source", JStr "hand");
          ("fixture", JStr "hand-precedence-scope");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "hand-precedence-scope.qnt";
                      JStr "hand-precedence-scope.itf.json";
                      JStr "--main=HandPrecedenceScope";
                      JStr "--invariant=zeroDiv";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R46: an early-stopped invariant's later evaluation error is \
               outside the exit-2 scope, beside a still-active invariant" );
        ];
    expected_human = None;
    derivation =
      Some
        "Property: a later evaluation error for an invariant already recorded \
         FAIL\n\
         at an earlier state does not turn the run into exit 2.\n\n\
         Expected result: exit 1. Two verdict rows sorted by name: nonNegative \
         PASS,\n\
         and zeroDiv FAIL at state index 0 with rendering { count: 0 } and the\n\
         forwarded state { count: 0 } plus the empty #meta object.\n\n\
         Reasoning: the trace records count 0, 1 and 2 at indexes 0 to 2. \
         zeroDiv\n\
         is 10 / (1 - count) < 0. At state 0 the divisor is 1, the quotient is \
         10 and\n\
         the comparison is false, so zeroDiv FAILs at index 0. R23's early \
         stop then\n\
         ends zeroDiv: it is not evaluated at states 1 and 2. At state 1 the \
         divisor\n\
         would be 0, which would be an evaluation error; that evaluation is \
         never\n\
         performed, and the early-stop rule (R23, R31) places a state at which \
         an\n\
         invariant is not evaluated because its FAIL was already recorded \
         outside the\n\
         exit-2 scope.\n\
         nonNegative is count >= 0, true at all three states and evaluated \
         through\n\
         state 2, so it PASSes. The report therefore carries one FAIL and one \
         PASS and\n\
         the run exits 1.\n\n\
         Cross-check, performed after the hand derivation and not used to \
         derive it: the\n\
         state-0 expressions were evaluated once through the pinned evaluator, \
         which\n\
         returned true for nonNegative and false for zeroDiv, and the state-1\n\
         evaluation of zeroDiv returned the division-by-zero error. The \
         expected outcome\n\
         below was fixed before that run and is unchanged.\n";
    hand = true;
  }

let entry_hand_precedence =
  {
    name = "hand-precedence";
    spec =
      "module HandPrecedence {\n\
      \  var count: int\n\n\
      \  val belowOne = count < 1\n\
      \  val divLater = 10 / (1 - count) > -100\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"2\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("category", JStr "multi-invariant-precedence");
          ("derivation", JStr "hand-precedence.derivation.md");
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "divLater"; JStr "1"; JStr "QNT503" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_silent", JArr [ JStr "belowOne"; JStr "divLater" ]);
          ("expected_source", JStr "hand");
          ("expected_stage", JStr "evaluate");
          ("fixture", JStr "hand-precedence");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "hand-precedence.qnt";
                      JStr "hand-precedence.itf.json";
                      JStr "--main=HandPrecedence";
                      JStr "--invariant=belowOne";
                      JStr "--invariant=divLater";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R46: a multi-invariant precedence case; an evaluation error \
               outranks a completed FAIL" );
        ];
    expected_human = None;
    derivation =
      Some
        "Property: a failure recorded for one invariant does not mask an \
         evaluation\n\
         error for another invariant at the same state.\n\n\
         Expected result: exit 2 at stage evaluate, naming divLater and state \
         1. No\n\
         verdict rows are printed; both invariants are expected silent.\n\n\
         Reasoning: belowOne is count < 1. At state 0 count is 0, so belowOne \
         is true.\n\
         divLater is 10 / (1 - count) > -100. At state 0 the divisor is 1, so \
         the value\n\
         is 10 and the comparison is true; the invariant passes at state 0 and \
         stays\n\
         active at state 1. At state 1 count is 1, so belowOne is false and is \
         recorded\n\
         as FAIL at index 1. Every invariant is evaluated at every recorded \
         state, and\n\
         the checker sends one call per state carrying every invariant still \
         active at\n\
         that state, so the state-1 call carries belowOne and divLater \
         together. In that\n\
         call divLater's divisor is 0, and division by zero is an evaluation \
         error. An\n\
         evaluation error in any evaluation the checker performs makes the run \
         exit 2,\n\
         so the run stops there. An exit-2 outcome is the exit code and the \
         named stage\n\
         with no verdict rows; the belowOne FAIL at state 1 is part of the \
         reasoning,\n\
         not an expected row.\n\n\
         Re-derivation from the specification text: at state 0 the divisor 1 - \
         count is\n\
         1, so divLater is 10 > -100 and true; belowOne is 0 < 1 and true. At \
         state 1\n\
         belowOne is 1 < 1 and false, so belowOne is recorded FAIL at index 1; \
         divLater\n\
         has not failed, so R23's early stop does not apply to it and it stays \
         active.\n\
         In the state-1 call divLater's divisor is 0, and division by zero is an\n\
         evaluation error. R31 makes an evaluation error in any performed \
         evaluation\n\
         fatal: the whole run exits 2, so the completed FAIL does not mask it. \
         This\n\
         expectation was derived from the specification text; the two \
         expressions\n\
         were then run once through the pinned evaluator as a cross-check, and \
         the\n\
         captures fixtures/probes/hand-precedence-state0.out and\n\
         fixtures/probes/hand-precedence-state1.out record the matching \
         results (true\n\
         at state 0; false with QNT503 at state 1).\n";
    hand = true;
  }

let entry_hand_violation =
  {
    name = "hand-violation";
    spec =
      "module HandViolation {\n\
      \  var count: int\n\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"2\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 3\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"3\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("category", JStr "violation");
          ("derivation", JStr "hand-violation.derivation.md");
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "belowThree");
                          ("rendering", JStr "{ count: 3 }");
                          ("state", JNum 3);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ("count", JObj [ ("#bigint", JStr "3") ]);
                              ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JBool false);
                ("states", JNum 4);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_silent", JArr []);
          ("expected_source", JStr "hand");
          ("fixture", JStr "hand-violation");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "hand-violation.qnt";
                      JStr "hand-violation.itf.json";
                      JStr "--main=HandViolation";
                      JStr "--invariant=belowThree";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R46: a violation fixture with a hand-derived failing state index"
          );
        ];
    expected_human = None;
    derivation =
      Some
        "Property: the invariant belowThree is false at one recorded state.\n\n\
         Expected result: exit 1. One verdict row, belowThree FAIL at state \
         index 3,\n\
         with the violating state rendered as { count: 3 }.\n\n\
         Reasoning: belowThree is count < 3. The trace records count 0, 1, 2 \
         and 3 at\n\
         indexes 0 to 3. The expression is true at indexes 0, 1 and 2, and \
         false at\n\
         index 3, because 3 is not less than 3. The first violating state is\n\
         therefore index 3, and the report names only the first one. The \
         rendering\n\
         sorts the single field count and renders the integer in decimal, giving\n\
         { count: 3 }. The expected row also records the forwarded state at that\n\
         index, {\"count\": {\"#bigint\": \"3\"}, \"#meta\": {}}, derived from \
         the\n\
         trace's state 3 and R21's empty forwarded #meta.\n";
    hand = true;
  }

let entry_ignored_duplicates =
  {
    name = "ignored-duplicates";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\"vars\":[\"count\"],\"states\":[{\"#meta\":{\"index\":0},\"count\":{\"#bigint\":\"0\"},\"extra\":{\"a\":1,\"a\":2}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr [ JStr "extra" ]);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "ignored-duplicates");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "ignored-duplicates.qnt";
                      JStr "ignored-duplicates.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: duplicate members inside an ignored key's value are never \
               inspected and are accepted" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_ignored_malformed_bigint =
  {
    name = "ignored-malformed-bigint";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"broken\": {\n\
        \        \"c\": [],\n\
        \        \"e\": {\n\
        \          \"#bigint\": \"-1\"\n\
        \        },\n\
        \        \"s\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        }\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr [ JStr "broken" ]);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "ignored-malformed-bigint");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "ignored-malformed-bigint.qnt";
                      JStr "ignored-malformed-bigint.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Probe: $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/ignored-malformed-bigint-eval.json returned exit 0 \
                     with {\"results\":[{\"value\":true}]} for the stripped \
                     state. Request: probes/ignored-malformed-bigint-eval.json"
                );
              ] );
          ( "requirement",
            JStr
              "A7: an ignored key carrying a malformed integer-shaped object \
               is stripped unread" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_json_garbage =
  {
    name = "json-garbage";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace = TText "not json at all";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ("must_contain", JArr [ JStr "decode"; JStr "byte"; JStr "0" ]);
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "json-garbage");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "json-garbage.qnt";
                      JStr "json-garbage.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a plain non-JSON byte sequence is refused (class 1)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_json_top_array =
  {
    name = "json-top-array";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace = TText "[]";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "object" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "json-top-array");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "json-top-array.qnt";
                      JStr "json-top-array.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a top-level array is refused (class 2, top level not an \
               object)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_json_trailing =
  {
    name = "json-trailing";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\"vars\":[\"count\"],\"states\":[{\"#meta\":{\"index\":0},\"count\":{\"#bigint\":\"0\"}}]} \
         trailing";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ("must_contain", JArr [ JStr "decode"; JStr "byte"; JStr "76" ]);
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "json-trailing");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "json-trailing.qnt";
                      JStr "json-trailing.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: trailing data after the JSON document is refused (class 1)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_json_truncated =
  {
    name = "json-truncated";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace = TText "{\"vars\":[\"count\"],\"states\":[";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ("must_contain", JArr [ JStr "decode"; JStr "byte"; JStr "28" ]);
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "json-truncated");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "json-truncated.qnt";
                      JStr "json-truncated.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ("requirement", JStr "R36: truncated JSON is refused (class 1)");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_loop_fail =
  {
    name = "loop-fail";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"loop\": 2,\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"2\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 3\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"3\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_evaluation_calls", JNum 4);
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "belowThree");
                          ("rendering", JStr "{ count: 3 }");
                          ("state", JNum 3);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ("count", JObj [ ("#bigint", JStr "3") ]);
                              ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("loop", JNum 2);
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 4);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "loop-fail");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "loop-fail.qnt";
                      JStr "loop-fail.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=belowThree";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Probe: $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < probes/loop-fail-eval.json \
                     returned exit 0 with {\"results\":[{\"value\":false}]} \
                     for state 3. Request: probes/loop-fail-eval.json" );
              ] );
          ( "requirement",
            JStr "A8: a FAIL recorded at a loop-state index carries that index"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_loop_negative =
  {
    name = "loop-negative";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"loop\": -1,\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"2\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "loop" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "loop-negative");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "loop-negative.qnt";
                      JStr "loop-negative.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ("requirement", JStr "R36: a negative loop index is refused (class 7)");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_loop_out_of_range =
  {
    name = "loop-out-of-range";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"loop\": 3,\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"2\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "loop" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "loop-out-of-range");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "loop-out-of-range.qnt";
                      JStr "loop-out-of-range.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a loop index at the state count is refused (class 7)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_loop_valid =
  {
    name = "loop-valid";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"loop\": 1,\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"2\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_evaluation_calls", JNum 3);
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("loop", JNum 1);
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 3);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "loop-valid");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "loop-valid.qnt";
                      JStr "loop-valid.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a loop index within the state range is accepted and every \
               state is checked once" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_mbt_vars =
  {
    name = "mbt-vars";
    spec =
      "module Plain {\n\
      \  var count: int\n\
      \  var log: List[int]\n\n\
      \  val nonNegative = count >= 0\n\
      \  val logLengthMatches = log.length() == count\n\
       }";
    trace =
      TText
        "{\"#meta\":{\"format\":\"ITF\",\"format-description\":\"https://apalache-mc.org/docs/adr/015adr-trace.html\",\"source\":\"plain/plain.qnt\",\"status\":\"ok\",\"description\":\"Created \
         by Quint on Fri Nov 13 2026 09:15:33 GMT+0000 (Coordinated Universal \
         Time)\",\"timestamp\":1794561333512},\"vars\":[\"count\",\"log\",\"mbt::actionTaken\",\"mbt::nondetPicks\",\"mbt::actionTaken\",\"mbt::nondetPicks\"],\"states\":[{\"#meta\":{\"index\":0},\"count\":{\"#bigint\":\"0\"},\"log\":[],\"mbt::actionTaken\":\"init\",\"mbt::nondetPicks\":{}},{\"#meta\":{\"index\":1},\"count\":{\"#bigint\":\"1\"},\"log\":[{\"#bigint\":\"1\"}],\"mbt::actionTaken\":\"increment\",\"mbt::nondetPicks\":{}},{\"#meta\":{\"index\":2},\"count\":{\"#bigint\":\"0\"},\"log\":[],\"mbt::actionTaken\":\"reset\",\"mbt::nondetPicks\":{}},{\"#meta\":{\"index\":3},\"count\":{\"#bigint\":\"1\"},\"log\":[{\"#bigint\":\"1\"}],\"mbt::actionTaken\":\"increment\",\"mbt::nondetPicks\":{}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ( "ignored_vars",
                  JArr [ JStr "mbt::actionTaken"; JStr "mbt::nondetPicks" ] );
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "logLengthMatches");
                          ("verdict", JStr "pass");
                        ];
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 4);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 2) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "producer-trace");
          ("fixture", JStr "mbt-vars");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "mbt-vars.qnt";
                      JStr "mbt-vars.itf.json";
                      JStr "--main=Plain";
                      JStr "--invariant=nonNegative";
                      JStr "--invariant=logLengthMatches";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "origin",
                  JStr
                    "copied unmodified from traces/plain-mbt.itf.json (quint \
                     run --mbt); the vars array carries duplicate mbt:: \
                     entries" );
              ] );
          ( "requirement",
            JStr "R36: extra mbt:: variables are removed before evaluation" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_meta_source_absent_strict =
  {
    name = "meta-source-absent-strict";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"#meta\": {\n\
        \    \"status\": \"ok\"\n\
        \  },\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "source" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "meta-source-absent-strict");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "meta-source-absent-strict.qnt";
                      JStr "meta-source-absent-strict.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                      JStr "--strict-source";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R11/A16: a trace with no #meta.source is refused under \
               --strict-source" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_meta_source_mismatch_strict =
  {
    name = "meta-source-mismatch-strict";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"#meta\": {\n\
        \    \"source\": \"elsewhere/base.qnt\",\n\
        \    \"status\": \"ok\"\n\
        \  },\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "source" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "meta-source-mismatch-strict");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "meta-source-mismatch-strict.qnt";
                      JStr "meta-source-mismatch-strict.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                      JStr "--strict-source";
                    ] );
              ] );
          ( "requirement",
            JStr
              "A16: a present string #meta.source differing from the spec path \
               is refused under --strict-source" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_meta_source_number_strict =
  {
    name = "meta-source-number-strict";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"#meta\": {\n\
        \    \"source\": 42,\n\
        \    \"status\": 7\n\
        \  },\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "source" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "meta-source-number-strict");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "meta-source-number-strict.qnt";
                      JStr "meta-source-number-strict.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                      JStr "--strict-source";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a non-string #meta.source counts as absent under \
               --strict-source" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_meta_source_number =
  {
    name = "meta-source-number";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"#meta\": {\n\
        \    \"source\": 42,\n\
        \    \"status\": 7\n\
        \  },\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_human",
            JObj
              [
                ("information_absent_tokens", JArr [ JStr "42"; JStr "7" ]);
                ( "information_tokens",
                  JArr [ JStr "source"; JStr "status"; JStr "number" ] );
                ("single_line_information_lines", JBool true);
                ("source_rendering", JStr "source=absent");
                ("status_rendering", JStr "status=absent");
                ("summary_absent_tokens", JArr [ JStr "source-mismatch" ]);
              ] );
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("source_type", JStr "number");
                ("states", JNum 2);
                ("status", JNull);
                ("status_type", JStr "number");
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "meta-source-number");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "meta-source-number.qnt";
                      JStr "meta-source-number.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a non-string #meta.source or #meta.status is treated as \
               absent, with its type recorded" );
        ];
    expected_human =
      Some
        (JObj
           [
             ("information_absent_tokens", JArr [ JStr "42"; JStr "7" ]);
             ( "information_tokens",
               JArr [ JStr "source"; JStr "status"; JStr "number" ] );
             ("single_line_information_lines", JBool true);
             ("source_rendering", JStr "source=absent");
             ("status_rendering", JStr "status=absent");
             ("summary_absent_tokens", JArr [ JStr "source-mismatch" ]);
           ]);
    derivation = None;
    hand = false;
  }

let entry_meta_top_number =
  {
    name = "meta-top-number";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"#meta\": 7,\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "#meta" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "meta-top-number");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "meta-top-number.qnt";
                      JStr "meta-top-number.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a top-level #meta that is a number is refused (class 2)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_meta_top_string =
  {
    name = "meta-top-string";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"#meta\": \"x\",\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "#meta" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "meta-top-string");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "meta-top-string.qnt";
                      JStr "meta-top-string.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a top-level #meta that is a string is refused (class 2)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_missing_variable =
  {
    name = "missing-variable";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr
                    [
                      JStr "decode";
                      JStr "count";
                      JStr "states";
                      JStr "0";
                      JStr "states/0/count";
                    ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "missing-variable");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "missing-variable.qnt";
                      JStr "missing-variable.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a declared variable absent from a state is refused (class \
               5)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_nested_instance =
  {
    name = "nested-instance";
    spec =
      "module Inner {\n\
      \  const C: int\n\n\
      \  var x: int\n\n\
      \  action init = x' = C\n\
      \  action step = x' = x + 1\n\n\
      \  val inRange = x <= C + 3\n\
       }\n\n\
       module Mid {\n\
      \  const D: int\n\n\
      \  import Inner(C = D) as i\n\n\
      \  var y: int\n\n\
      \  action init = all { i::init, y' = D }\n\
      \  action step = all { i::step, y' = y + 1 }\n\n\
      \  val nested = i::inRange and y >= 0\n\
       }\n\n\
       module Outer {\n\
      \  import Mid(D = 0) as m\n\n\
      \  action init = m::init\n\
      \  action step = m::step\n\n\
      \  val deep = m::nested\n\
       }";
    trace =
      TText
        "{\"#meta\":{\"format\":\"ITF\",\"format-description\":\"https://apalache-mc.org/docs/adr/015adr-trace.html\",\"source\":\"nested-instance.qnt\",\"status\":\"ok\",\"description\":\"Created \
         by Quint on Sat Nov 14 2026 17:05:10 GMT+0000 (Coordinated Universal \
         Time)\",\"timestamp\":1794675910110},\"vars\":[\"Mid::i::x\",\"Outer::m::y\"],\"states\":[{\"#meta\":{\"index\":0},\"Mid::i::x\":{\"#bigint\":\"0\"},\"Outer::m::y\":{\"#bigint\":\"0\"}},{\"#meta\":{\"index\":1},\"Mid::i::x\":{\"#bigint\":\"1\"},\"Outer::m::y\":{\"#bigint\":\"1\"}},{\"#meta\":{\"index\":2},\"Mid::i::x\":{\"#bigint\":\"2\"},\"Outer::m::y\":{\"#bigint\":\"2\"}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [ JObj [ ("name", JStr "deep"); ("verdict", JStr "pass") ] ]
                );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 3);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "nested-instance");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "nested-instance.qnt";
                      JStr "nested-instance.itf.json";
                      JStr "--main=Outer";
                      JStr "--invariant=deep";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "origin",
                  JStr
                    "copied unmodified from traces/nested-instance.itf.json; \
                     produced with --max-steps=2" );
                ( "probe",
                  JStr
                    "Probe: states 0, 1 and 2 each returned exit 0 with \
                     {\"results\":[{\"value\":true}]} (state 0 in \
                     probes/nested-instance-eval.json, states 1 and 2 in \
                     probes/nested-instance-eval-1.json and \
                     probes/nested-instance-eval-2.json). Command: \
                     $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/nested-instance-eval.json" );
              ] );
          ( "requirement",
            JStr
              "A6: a nested instance pins the two-level variable-naming rule, \
               whose qualifier is the direct importer's module plus the alias"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_newline_render =
  {
    name = "newline-render";
    spec = "module Text {\n  var text: str\n\n  val blank = text == \"\"\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"text\": \"\\n\"\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"text\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 1);
          ("expected_human", JObj [ ("summary_lines", JNum 1) ]);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "blank");
                          ("rendering", JStr "{ text: \"\\u000a\" }");
                          ("state", JNum 0);
                          ( "state_value",
                            JObj [ ("#meta", JObj []); ("text", JStr "\n") ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "newline-render");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "newline-render.qnt";
                      JStr "newline-render.itf.json";
                      JStr "--main=Text";
                      JStr "--invariant=blank";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Probe: $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < probes/newline-render.json \
                     returned exit 0 with {\"results\":[{\"value\":false}]} \
                     for state 0. Request: probes/newline-render.json" );
              ] );
          ( "requirement",
            JStr
              "R36: a violating state carrying a newline renders as a single \
               escaped line" );
        ];
    expected_human = Some (JObj [ ("summary_lines", JNum 1) ]);
    derivation = None;
    hand = false;
  }

let entry_ordinal_absent =
  {
    name = "ordinal-absent";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 2);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "ordinal-absent");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "ordinal-absent.qnt";
                      JStr "ordinal-absent.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: absent ordinals are accepted and array order is the ordinal"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_ordinal_duplicate =
  {
    name = "ordinal-duplicate";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr
                    [ JStr "decode"; JStr "index"; JStr "states/1"; JStr "0" ]
                );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "ordinal-duplicate");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "ordinal-duplicate.qnt";
                      JStr "ordinal-duplicate.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a duplicated #meta.index is refused (class 6)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_ordinal_mismatch =
  {
    name = "ordinal-mismatch";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr
                    [ JStr "decode"; JStr "index"; JStr "states/1"; JStr "2" ]
                );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "ordinal-mismatch");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "ordinal-mismatch.qnt";
                      JStr "ordinal-mismatch.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: an #meta.index differing from the array position is \
               refused (class 6)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_ordinal_noninteger =
  {
    name = "ordinal-noninteger";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": \"0\"\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "index"; JStr "states/0" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "ordinal-noninteger");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "ordinal-noninteger.qnt";
                      JStr "ordinal-noninteger.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a non-integer #meta.index is refused (class 6)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_ordinal_partial =
  {
    name = "ordinal-partial";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "index"; JStr "states/1" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "ordinal-partial");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "ordinal-partial.qnt";
                      JStr "ordinal-partial.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: partial presence of #meta.index across states is refused \
               (class 6)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_params_empty =
  {
    name = "params-empty";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"params\": [],\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 2);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "params-empty");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "params-empty.qnt";
                      JStr "params-empty.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ("requirement", JStr "R36: an empty params array is accepted");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_params_nonempty =
  {
    name = "params-nonempty";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"params\": [\n\
        \    \"p\"\n\
        \  ],\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "params" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "params-nonempty");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "params-nonempty.qnt";
                      JStr "params-nonempty.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a non-empty params array is refused (class 8)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_params_null =
  {
    name = "params-null";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\"vars\":[\"count\"],\"params\":null,\"states\":[{\"#meta\":{\"index\":0},\"count\":{\"#bigint\":\"0\"}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "params" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "params-null");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "params-null.qnt";
                      JStr "params-null.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ("requirement", JStr "R36: params null is refused (class 8)");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_params_number =
  {
    name = "params-number";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"params\": 7,\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "params" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "params-number");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "params-number.qnt";
                      JStr "params-number.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ("requirement", JStr "R36: params as a number is refused (class 8)");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_params_string =
  {
    name = "params-string";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"params\": \"p\",\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "params" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "params-string");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "params-string.qnt";
                      JStr "params-string.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ("requirement", JStr "R36: params as a string is refused (class 8)");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_plain_pass =
  {
    name = "plain-pass";
    spec =
      "module Plain {\n\
      \  var count: int\n\
      \  var log: List[int]\n\n\
      \  val nonNegative = count >= 0\n\
      \  val logLengthMatches = log.length() == count\n\
       }";
    trace =
      TText
        "{\"#meta\":{\"format\":\"ITF\",\"format-description\":\"https://apalache-mc.org/docs/adr/015adr-trace.html\",\"source\":\"plain/plain.qnt\",\"status\":\"ok\",\"description\":\"Created \
         by Quint on Fri Nov 13 2026 09:15:32 GMT+0000 (Coordinated Universal \
         Time)\",\"timestamp\":1794561332673},\"vars\":[\"count\",\"log\"],\"states\":[{\"#meta\":{\"index\":0},\"count\":{\"#bigint\":\"0\"},\"log\":[]},{\"#meta\":{\"index\":1},\"count\":{\"#bigint\":\"1\"},\"log\":[{\"#bigint\":\"1\"}]},{\"#meta\":{\"index\":2},\"count\":{\"#bigint\":\"0\"},\"log\":[]},{\"#meta\":{\"index\":3},\"count\":{\"#bigint\":\"1\"},\"log\":[{\"#bigint\":\"1\"}]}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_human",
            JObj
              [
                ( "coverage_line",
                  JStr
                    "The verdict covers the recorded states only; it is not a \
                     proof." );
                ( "header_patterns",
                  JArr [ JStr "sha256=[0-9a-f]{12}([^0-9a-f]|$)" ] );
                ( "header_tokens",
                  JArr
                    [
                      JStr "plain-pass.qnt";
                      JStr "Plain";
                      JStr "plain-pass.itf.json";
                      JStr "source=plain/plain.qnt";
                      JStr "states=4";
                      JStr "status=ok";
                      JStr "Quint 0.33.1";
                      JStr "quint_evaluator";
                      JStr "sha256=";
                      JStr "mode checktrace";
                    ] );
                ( "pass_absent_tokens",
                  JArr
                    [
                      JStr "holds";
                      JStr "valid";
                      JStr "verified";
                      JStr "proved";
                      JStr "correct";
                    ] );
                ("pass_wording", JStr "no violation observed in this trace");
                ("single_line_header", JBool true);
                ( "status_glyphs",
                  JObj
                    [
                      ("fail", JStr "\xe2\x9c\x97");
                      ("pass", JStr "\xe2\x9c\x93");
                    ] );
                ( "summary_form",
                  JStr "Summary: 2 pass, 0 fail (exit 0) source-mismatch" );
                ("summary_lines", JNum 1);
              ] );
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "logLengthMatches");
                          ("verdict", JStr "pass");
                        ];
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 4);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 2) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "producer-trace");
          ("fixture", JStr "plain-pass");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "plain-pass.qnt";
                      JStr "plain-pass.itf.json";
                      JStr "--main=Plain";
                      JStr "--invariant=nonNegative";
                      JStr "--invariant=logLengthMatches";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "origin",
                  JStr
                    "copied unmodified from traces/plain.itf.json; produced by \
                     quint 0.33.1 with the Rust backend" );
              ] );
          ("requirement", JStr "A1: a clean trace with passing invariants");
        ];
    expected_human =
      Some
        (JObj
           [
             ( "coverage_line",
               JStr
                 "The verdict covers the recorded states only; it is not a \
                  proof." );
             ( "header_patterns",
               JArr [ JStr "sha256=[0-9a-f]{12}([^0-9a-f]|$)" ] );
             ( "header_tokens",
               JArr
                 [
                   JStr "plain-pass.qnt";
                   JStr "Plain";
                   JStr "plain-pass.itf.json";
                   JStr "source=plain/plain.qnt";
                   JStr "states=4";
                   JStr "status=ok";
                   JStr "Quint 0.33.1";
                   JStr "quint_evaluator";
                   JStr "sha256=";
                   JStr "mode checktrace";
                 ] );
             ( "pass_absent_tokens",
               JArr
                 [
                   JStr "holds";
                   JStr "valid";
                   JStr "verified";
                   JStr "proved";
                   JStr "correct";
                 ] );
             ("pass_wording", JStr "no violation observed in this trace");
             ("single_line_header", JBool true);
             ( "status_glyphs",
               JObj
                 [
                   ("fail", JStr "\xe2\x9c\x97"); ("pass", JStr "\xe2\x9c\x93");
                 ] );
             ( "summary_form",
               JStr "Summary: 2 pass, 0 fail (exit 0) source-mismatch" );
             ("summary_lines", JNum 1);
           ]);
    derivation = None;
    hand = false;
  }

let entry_render_shapes =
  {
    name = "render-shapes";
    spec =
      "module RenderShapes {\n\
      \  type Shape = | Circle(int) | Square(int)\n\n\
      \  var b: bool\n\
      \  var l: List[int]\n\
      \  var m: int -> str\n\
      \  var n: int\n\
      \  var s: Set[int]\n\
      \  var t: (int, str)\n\
      \  var u: ()\n\
      \  var v: Shape\n\n\
      \  val positive = n > 0\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"b\": true,\n\
        \      \"l\": [\n\
        \        {\n\
        \          \"#bigint\": \"1\"\n\
        \        },\n\
        \        {\n\
        \          \"#bigint\": \"2\"\n\
        \        }\n\
        \      ],\n\
        \      \"m\": {\n\
        \        \"#map\": [\n\
        \          [\n\
        \            {\n\
        \              \"#bigint\": \"10\"\n\
        \            },\n\
        \            \"a\"\n\
        \          ],\n\
        \          [\n\
        \            {\n\
        \              \"#bigint\": \"2\"\n\
        \            },\n\
        \            \"b\"\n\
        \          ]\n\
        \        ]\n\
        \      },\n\
        \      \"n\": {\n\
        \        \"#bigint\": \"-7\"\n\
        \      },\n\
        \      \"s\": {\n\
        \        \"#set\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"10\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"2\"\n\
        \          }\n\
        \        ]\n\
        \      },\n\
        \      \"t\": {\n\
        \        \"#tup\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          },\n\
        \          \"x\"\n\
        \        ]\n\
        \      },\n\
        \      \"u\": {\n\
        \        \"tag\": \"UNIT\"\n\
        \      },\n\
        \      \"v\": {\n\
        \        \"tag\": \"Circle\",\n\
        \        \"value\": {\n\
        \          \"#bigint\": \"5\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"b\",\n\
        \    \"l\",\n\
        \    \"m\",\n\
        \    \"n\",\n\
        \    \"s\",\n\
        \    \"t\",\n\
        \    \"u\",\n\
        \    \"v\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "positive");
                          ( "rendering",
                            JStr
                              "{ b: true, l: [1, 2], m: Map(10 -> \"a\", 2 -> \
                               \"b\"), n: -7, s: Set(1, 10, 2), t: (1, \"x\"), \
                               u: (), v: Circle(5) }" );
                          ("state", JNum 0);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ("b", JBool true);
                                ( "l",
                                  JArr
                                    [
                                      JObj [ ("#bigint", JStr "1") ];
                                      JObj [ ("#bigint", JStr "2") ];
                                    ] );
                                ( "m",
                                  JObj
                                    [
                                      ( "#map",
                                        JArr
                                          [
                                            JArr
                                              [
                                                JObj [ ("#bigint", JStr "10") ];
                                                JStr "a";
                                              ];
                                            JArr
                                              [
                                                JObj [ ("#bigint", JStr "2") ];
                                                JStr "b";
                                              ];
                                          ] );
                                    ] );
                                ("n", JObj [ ("#bigint", JStr "-7") ]);
                                ( "s",
                                  JObj
                                    [
                                      ( "#set",
                                        JArr
                                          [
                                            JObj [ ("#bigint", JStr "1") ];
                                            JObj [ ("#bigint", JStr "10") ];
                                            JObj [ ("#bigint", JStr "2") ];
                                          ] );
                                    ] );
                                ( "t",
                                  JObj
                                    [
                                      ( "#tup",
                                        JArr
                                          [
                                            JObj [ ("#bigint", JStr "1") ];
                                            JStr "x";
                                          ] );
                                    ] );
                                ("u", JObj [ ("tag", JStr "UNIT") ]);
                                ( "v",
                                  JObj
                                    [
                                      ("tag", JStr "Circle");
                                      ("value", JObj [ ("#bigint", JStr "5") ]);
                                    ] );
                              ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "render-shapes");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "render-shapes.qnt";
                      JStr "render-shapes.itf.json";
                      JStr "--main=RenderShapes";
                      JStr "--invariant=positive";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R27/A11: every renderable value form is rendered byte-exactly, \
               including the unit form and the Set and Map sort rules" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_render_truncate =
  {
    name = "render-truncate";
    spec = "module Text {\n  var text: str\n\n  val blank = text == \"\"\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"text\": \
         \"\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\"\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"text\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "blank");
                          ( "rendering",
                            JStr
                              "{ text: \
                               \"\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001..."
                          );
                          ("state", JNum 0);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ( "text",
                                  JStr
                                    "\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\xc3\xa9\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
                                );
                              ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "render-truncate");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "render-truncate.qnt";
                      JStr "render-truncate.itf.json";
                      JStr "--main=Text";
                      JStr "--invariant=blank";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R27: the 200-code-point cap counts code points, and a truncated \
               prefix stops at a complete \\uXXXX escape boundary: the 197 \
               available code points end inside an escape here" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_resolver_action_invariant =
  {
    name = "resolver-action-invariant";
    spec =
      "module ActionHolder {\n\
      \  var x: int\n\n\
      \  action init = x' = 0\n\n\
      \  val ok = x >= -1000000\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "resolve"; JStr "init"; JStr "action" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "resolve");
          ("fixture", JStr "resolver-action-invariant");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "resolver-action-invariant.qnt";
                      JStr "resolver-action-invariant.itf.json";
                      JStr "--main=ActionHolder";
                      JStr "--invariant=init";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R3: an action named as an invariant is refused, naming the \
               declaration and its qualifier" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_resolver_def_invariant =
  {
    name = "resolver-def-invariant";
    spec = "module DefHolder {\n  var x: int\n\n  def doubled = x * 2\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "resolve"; JStr "doubled"; JStr "def" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "resolve");
          ("fixture", JStr "resolver-def-invariant");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "resolver-def-invariant.qnt";
                      JStr "resolver-def-invariant.itf.json";
                      JStr "--main=DefHolder";
                      JStr "--invariant=doubled";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R3: a def-qualified definition named as an invariant is \
               refused, naming the declaration and its qualifier" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_resolver_export_visible =
  {
    name = "resolver-export-visible";
    spec =
      "module ExportSpec {\n\
      \  const K: int\n\n\
      \  val exported = K == 8\n\
       }\n\n\
       module ExportBridge {\n\
      \  import ExportSpec(K = 7) as e\n\
      \  export e\n\
       }\n\n\
       module ExportHolder {\n\
      \  import ExportBridge.*\n\n\
      \  var x: int\n\n\
      \  val visible = x >= 0\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "resolve"; JStr "exported"; JStr "visible" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "resolve");
          ("fixture", JStr "resolver-export-visible");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "resolver-export-visible.qnt";
                      JStr "resolver-export-visible.itf.json";
                      JStr "--main=ExportHolder";
                      JStr "--invariant=exported";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R3: a name visible only through an export, not declared in the \
               main module, is refused" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_resolver_hidden_import =
  {
    name = "resolver-hidden-import";
    spec =
      "module HiddenSpec {\n\
      \  const K: int\n\n\
      \  val hidden = K == 8\n\
       }\n\n\
       module HiddenHolder {\n\
      \  import HiddenSpec(K = 7) as h\n\n\
      \  var x: int\n\n\
      \  val visible = x >= 0\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "resolve"; JStr "hidden"; JStr "visible" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "resolve");
          ("fixture", JStr "resolver-hidden-import");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "resolver-hidden-import.qnt";
                      JStr "resolver-hidden-import.itf.json";
                      JStr "--main=HiddenHolder";
                      JStr "--invariant=hidden";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R3: a name declared only in an imported module, absent from the \
               main module's declarations, is refused" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_resolver_invariant_absent =
  {
    name = "resolver-invariant-absent";
    spec =
      "module MainHolder {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "resolve"; JStr "missing"; JStr "nonNegative" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "resolve");
          ("fixture", JStr "resolver-invariant-absent");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "resolver-invariant-absent.qnt";
                      JStr "resolver-invariant-absent.itf.json";
                      JStr "--main=MainHolder";
                      JStr "--invariant=missing";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R3: an --invariant name absent from the main module is refused, \
               naming the declarations" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_resolver_main_absent =
  {
    name = "resolver-main-absent";
    spec =
      "module MainHolder {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "resolve"; JStr "Absent"; JStr "MainHolder" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "resolve");
          ("fixture", JStr "resolver-main-absent");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "resolver-main-absent.qnt";
                      JStr "resolver-main-absent.itf.json";
                      JStr "--main=Absent";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R2: a --main name absent from the module list is refused, \
               listing the module names" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_resolver_param_val =
  {
    name = "resolver-param-val";
    spec =
      "module ParamHolder {\n  var x: int\n\n  val threshold = (n) => n > x\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "resolve"; JStr "threshold" ]) ]
          );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "resolve");
          ("fixture", JStr "resolver-param-val");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "resolver-param-val.qnt";
                      JStr "resolver-param-val.itf.json";
                      JStr "--main=ParamHolder";
                      JStr "--invariant=threshold";
                    ] );
              ] );
          ( "requirement",
            JStr "R3: a parameterised val named as an invariant is refused" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_resolver_puredef_invariant =
  {
    name = "resolver-puredef-invariant";
    spec =
      "module PuredefHolder {\n  var x: int\n\n  pure def doubled = 2 * 2\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "resolve"; JStr "doubled"; JStr "puredef" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "resolve");
          ("fixture", JStr "resolver-puredef-invariant");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "resolver-puredef-invariant.qnt";
                      JStr "resolver-puredef-invariant.itf.json";
                      JStr "--main=PuredefHolder";
                      JStr "--invariant=doubled";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R3: a puredef-qualified definition named as an invariant is \
               refused, naming the declaration and its qualifier" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_resolver_temporal_invariant =
  {
    name = "resolver-temporal-invariant";
    spec =
      "module TemporalHolder {\n\
      \  var x: int\n\n\
      \  temporal settled = always(x >= 0)\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"x\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"x\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "resolve"; JStr "settled"; JStr "temporal" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "resolve");
          ("fixture", JStr "resolver-temporal-invariant");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "resolver-temporal-invariant.qnt";
                      JStr "resolver-temporal-invariant.itf.json";
                      JStr "--main=TemporalHolder";
                      JStr "--invariant=settled";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R3: a temporal definition named as an invariant is refused, \
               naming the declaration and its qualifier" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_shapes_rust =
  {
    name = "shapes-rust";
    spec =
      "module Shapes {\n\
      \  type Color = | Red | Green\n\
      \  type Row = { a: int, b: str }\n\n\
      \  var m: int -> str\n\
      \  var r: Row\n\
      \  var t: (int, str)\n\
      \  var v: Color\n\
      \  var s: Set[int]\n\
      \  var l: List[str]\n\
      \  var flag: bool\n\
      \  var big: int\n\n\
      \  val allThere = big >= -1000000\n\
      \  val bigPositive = big > 0\n\
       }";
    trace =
      TText
        "{\"#meta\":{\"format\":\"ITF\",\"format-description\":\"https://apalache-mc.org/docs/adr/015adr-trace.html\",\"source\":\"shapes/shapes.qnt\",\"status\":\"ok\",\"description\":\"Created \
         by Quint on Fri Nov 13 2026 09:17:58 GMT+0000 (Coordinated Universal \
         Time)\",\"timestamp\":1794561478343},\"vars\":[\"big\",\"flag\",\"l\",\"m\",\"r\",\"s\",\"t\",\"v\"],\"states\":[{\"#meta\":{\"index\":0},\"big\":{\"s\":{\"#bigint\":\"1\"},\"e\":{\"#bigint\":\"15\"},\"c\":[{\"#bigint\":\"90\"},{\"#bigint\":\"7199254740993\"}]},\"flag\":true,\"l\":[\"a\"],\"m\":{\"#map\":[[{\"#bigint\":\"1\"},\"a\"],[{\"#bigint\":\"2\"},\"b\"]]},\"r\":{\"a\":{\"#bigint\":\"1\"},\"b\":\"x\"},\"s\":{\"#set\":[{\"#bigint\":\"1\"},{\"#bigint\":\"2\"}]},\"t\":{\"#tup\":[{\"#bigint\":\"1\"},\"y\"]},\"v\":{\"tag\":\"Red\",\"value\":{\"#tup\":[]}}},{\"#meta\":{\"index\":1},\"big\":{\"s\":{\"#bigint\":\"1\"},\"e\":{\"#bigint\":\"15\"},\"c\":[{\"#bigint\":\"90\"},{\"#bigint\":\"7199254740993\"}]},\"flag\":true,\"l\":[\"a\"],\"m\":{\"#map\":[[{\"#bigint\":\"1\"},\"a\"],[{\"#bigint\":\"2\"},\"b\"]]},\"r\":{\"a\":{\"#bigint\":\"1\"},\"b\":\"x\"},\"s\":{\"#set\":[{\"#bigint\":\"1\"},{\"#bigint\":\"2\"}]},\"t\":{\"#tup\":[{\"#bigint\":\"1\"},\"y\"]},\"v\":{\"tag\":\"Red\",\"value\":{\"#tup\":[]}}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [ ("name", JStr "allThere"); ("verdict", JStr "pass") ];
                      JObj
                        [
                          ("name", JStr "bigPositive"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 2);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 2) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "producer-trace");
          ("fixture", JStr "shapes-rust");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "shapes-rust.qnt";
                      JStr "shapes-rust.itf.json";
                      JStr "--main=Shapes";
                      JStr "--invariant=allThere";
                      JStr "--invariant=bigPositive";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "origin",
                  JStr
                    "copied unmodified from traces/shapes.itf.json (Rust \
                     backend)" );
              ] );
          ("requirement", JStr "R14: every value form decodes and evaluates");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_shapes_typescript =
  {
    name = "shapes-typescript";
    spec =
      "module Shapes {\n\
      \  type Color = | Red | Green\n\
      \  type Row = { a: int, b: str }\n\n\
      \  var m: int -> str\n\
      \  var r: Row\n\
      \  var t: (int, str)\n\
      \  var v: Color\n\
      \  var s: Set[int]\n\
      \  var l: List[str]\n\
      \  var flag: bool\n\
      \  var big: int\n\n\
      \  val allThere = big >= -1000000\n\
      \  val bigPositive = big > 0\n\
       }";
    trace =
      TText
        "{\"#meta\":{\"format\":\"ITF\",\"format-description\":\"https://apalache-mc.org/docs/adr/015adr-trace.html\",\"source\":\"shapes/shapes.qnt\",\"status\":\"ok\",\"description\":\"Created \
         by Quint on Fri Nov 13 2026 09:18:10 GMT+0000 (Coordinated Universal \
         Time)\",\"timestamp\":1794561490834},\"vars\":[\"m\",\"r\",\"t\",\"v\",\"s\",\"l\",\"flag\",\"big\"],\"states\":[{\"#meta\":{\"index\":0},\"big\":{\"#bigint\":\"9007199254740993\"},\"flag\":true,\"l\":[\"a\"],\"m\":{\"#map\":[[{\"#bigint\":\"1\"},\"a\"],[{\"#bigint\":\"2\"},\"b\"]]},\"r\":{\"a\":{\"#bigint\":\"1\"},\"b\":\"x\"},\"s\":{\"#set\":[{\"#bigint\":\"1\"},{\"#bigint\":\"2\"}]},\"t\":{\"#tup\":[{\"#bigint\":\"1\"},\"y\"]},\"v\":{\"tag\":\"Red\",\"value\":{\"#tup\":[]}}},{\"#meta\":{\"index\":1},\"big\":{\"#bigint\":\"9007199254740993\"},\"flag\":true,\"l\":[\"a\"],\"m\":{\"#map\":[[{\"#bigint\":\"1\"},\"a\"],[{\"#bigint\":\"2\"},\"b\"]]},\"r\":{\"a\":{\"#bigint\":\"1\"},\"b\":\"x\"},\"s\":{\"#set\":[{\"#bigint\":\"1\"},{\"#bigint\":\"2\"}]},\"t\":{\"#tup\":[{\"#bigint\":\"1\"},\"y\"]},\"v\":{\"tag\":\"Red\",\"value\":{\"#tup\":[]}}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [ ("name", JStr "allThere"); ("verdict", JStr "pass") ];
                      JObj
                        [
                          ("name", JStr "bigPositive"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 2);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 2) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "producer-trace");
          ("fixture", JStr "shapes-typescript");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "shapes-typescript.qnt";
                      JStr "shapes-typescript.itf.json";
                      JStr "--main=Shapes";
                      JStr "--invariant=allThere";
                      JStr "--invariant=bigPositive";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "origin",
                  JStr
                    "copied unmodified from traces/shapes-ts.itf.json \
                     (TypeScript backend)" );
              ] );
          ( "requirement",
            JStr "R14: the TypeScript backend value forms decode and evaluate"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_source_mismatch =
  {
    name = "source-mismatch";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"#meta\": {\n\
        \    \"source\": \"elsewhere/base.qnt\",\n\
        \    \"status\": \"ok\"\n\
        \  },\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_human",
            JObj
              [
                ( "information_tokens",
                  JArr [ JStr "source"; JStr "elsewhere/base.qnt" ] );
                ("single_line_information_lines", JBool true);
                ("summary_token", JStr "source-mismatch");
              ] );
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 2);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "source-mismatch");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "source-mismatch.qnt";
                      JStr "source-mismatch.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "A17: a differing source prints the source-mismatch token \
               without refusing" );
        ];
    expected_human =
      Some
        (JObj
           [
             ( "information_tokens",
               JArr [ JStr "source"; JStr "elsewhere/base.qnt" ] );
             ("single_line_information_lines", JBool true);
             ("summary_token", JStr "source-mismatch");
           ]);
    derivation = None;
    hand = false;
  }

let entry_state_meta_not_object =
  {
    name = "state-meta-not-object";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": \"x\",\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "#meta"; JStr "states/0" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "state-meta-not-object");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "state-meta-not-object.qnt";
                      JStr "state-meta-not-object.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a state #meta that is not an object is refused (class 6)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_state_not_object =
  {
    name = "state-not-object";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n  \"states\": [\n    1\n  ],\n  \"vars\": [\n    \"count\"\n  ]\n}";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "state"; JStr "states/0" ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "state-not-object");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "state-not-object.qnt";
                      JStr "state-not-object.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a state that is not an object is refused (class 4)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_states_empty =
  {
    name = "states-empty";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace = TText "{\n  \"states\": [],\n  \"vars\": [\n    \"count\"\n  ]\n}";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "states" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "states-empty");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "states-empty.qnt";
                      JStr "states-empty.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ("requirement", JStr "R36: an empty states array is refused (class 3)");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_states_not_array =
  {
    name = "states-not-array";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace = TText "{\n  \"states\": {},\n  \"vars\": [\n    \"count\"\n  ]\n}";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "states" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "states-not-array");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "states-not-array.qnt";
                      JStr "states-not-array.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a wrong-typed states field is refused (class 2)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_status_ok_failing =
  {
    name = "status-ok-failing";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"#meta\": {\n\
        \    \"source\": \"status-ok-failing.qnt\",\n\
        \    \"status\": \"ok\"\n\
        \  },\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"2\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 3\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"3\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "belowThree");
                          ("rendering", JStr "{ count: 3 }");
                          ("state", JNum 3);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ("count", JObj [ ("#bigint", JStr "3") ]);
                              ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 4);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "status-ok-failing");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "status-ok-failing.qnt";
                      JStr "status-ok-failing.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=belowThree";
                    ] );
              ] );
          ( "requirement",
            JStr
              "A9: a status of ok does not stop a genuine failure from exiting \
               1" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_status_violation_passing =
  {
    name = "status-violation-passing";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"#meta\": {\n\
        \    \"source\": \"status-violation-passing.qnt\",\n\
        \    \"status\": \"violation\"\n\
        \  },\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 2\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"2\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 3);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "status-violation-passing");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "status-violation-passing.qnt";
                      JStr "status-violation-passing.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "A9: a status of violation does not manufacture a failure" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_tagged_record =
  {
    name = "tagged-record";
    spec =
      "module Tagged {\n\
      \  type TaggedRecord = { tag: str, value: int, extra: int }\n\n\
      \  var r: TaggedRecord\n\n\
      \  val tagIsX = r.tag == \"x\"\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"r\": {\n\
        \        \"extra\": {\n\
        \          \"#bigint\": \"7\"\n\
        \        },\n\
        \        \"tag\": \"x\",\n\
        \        \"value\": {\n\
        \          \"#bigint\": \"42\"\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"r\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "tagIsX"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "tagged-record");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "tagged-record.qnt";
                      JStr "tagged-record.itf.json";
                      JStr "--main=Tagged";
                      JStr "--invariant=tagIsX";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a tag-bearing object with other fields is a record" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_text_escapes =
  {
    name = "text-escapes";
    spec = "module Text {\n  var text: str\n\n  val blank = text == \"\"\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"text\": \"a\\\"b\\\\c\"\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"text\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 1);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "blank");
                          ("rendering", JStr "{ text: \"a\\\"b\\\\c\" }");
                          ("state", JNum 0);
                          ( "state_value",
                            JObj
                              [ ("#meta", JObj []); ("text", JStr "a\"b\\c") ]
                          );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "text-escapes");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "text-escapes.qnt";
                      JStr "text-escapes.itf.json";
                      JStr "--main=Text";
                      JStr "--invariant=blank";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R27: backslash and double quote in a violating state render \
               with their JSON-style escapes, byte-exact" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_two_instance =
  {
    name = "two-instance";
    spec =
      "module Spec {\n\
      \  const C: int\n\n\
      \  var x: int\n\n\
      \  action init = x' = C\n\
      \  action step = x' = x + 1\n\n\
      \  val bounded = x <= C + 2\n\
       }\n\n\
       module TwoInstances {\n\
      \  import Spec(C = 0) as a\n\
      \  import Spec(C = 10) as b\n\n\
      \  action init = all { a::init, b::init }\n\
      \  action step = all { a::step, b::step }\n\n\
      \  val both = a::bounded and b::bounded\n\
       }";
    trace =
      TText
        "{\"#meta\":{\"format\":\"ITF\",\"format-description\":\"https://apalache-mc.org/docs/adr/015adr-trace.html\",\"source\":\"two-instance.qnt\",\"status\":\"ok\",\"description\":\"Created \
         by Quint on Sat Nov 14 2026 17:05:10 GMT+0000 (Coordinated Universal \
         Time)\",\"timestamp\":1794675910929},\"vars\":[\"TwoInstances::a::x\",\"TwoInstances::b::x\"],\"states\":[{\"#meta\":{\"index\":0},\"TwoInstances::a::x\":{\"#bigint\":\"0\"},\"TwoInstances::b::x\":{\"#bigint\":\"10\"}},{\"#meta\":{\"index\":1},\"TwoInstances::a::x\":{\"#bigint\":\"1\"},\"TwoInstances::b::x\":{\"#bigint\":\"11\"}},{\"#meta\":{\"index\":2},\"TwoInstances::a::x\":{\"#bigint\":\"2\"},\"TwoInstances::b::x\":{\"#bigint\":\"12\"}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [ JObj [ ("name", JStr "both"); ("verdict", JStr "pass") ] ]
                );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 3);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "two-instance");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "two-instance.qnt";
                      JStr "two-instance.itf.json";
                      JStr "--main=TwoInstances";
                      JStr "--invariant=both";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "origin",
                  JStr
                    "copied unmodified from traces/two-instance.itf.json; \
                     produced with --max-steps=2" );
                ( "probe",
                  JStr
                    "Probe: states 0, 1 and 2 each returned exit 0 with \
                     {\"results\":[{\"value\":true}]} (state 0 in \
                     probes/two-instance-eval.json, states 1 and 2 in \
                     probes/two-instance-eval-1.json and \
                     probes/two-instance-eval-2.json). Command: \
                     $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/two-instance-eval.json" );
              ] );
          ( "requirement",
            JStr
              "A6: two instances in one module pin the per-alias \
               variable-naming rule" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_unit_result =
  {
    name = "unit-result";
    spec = "module Unit {\n  var b: ()\n\n  val pair = (b, ())\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"b\": {\n\
        \        \"tag\": \"UNIT\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"b\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ("must_contain", JArr [ JStr "pair"; JStr "0"; JStr "#tup" ]);
                ("must_not_contain", JArr [ JStr "QNT" ]);
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "probe");
          ("expected_stage", JStr "evaluate");
          ("fixture", JStr "unit-result");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "unit-result.qnt";
                      JStr "unit-result.itf.json";
                      JStr "--main=Unit";
                      JStr "--invariant=pair";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: a tuple result is a successful \
                     non-boolean value. Command, run from the fixtures root: \
                     $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < probes/unit-result.json \
                     Observed at exit 0: \
                     {\"results\":[{\"value\":{\"#tup\":[{\"#tup\":[]},{\"#tup\":[]}]}}]}"
                );
              ] );
          ( "requirement",
            JStr
              "R36: a successful tuple result is refused, naming the \
               invariant, state index and #tup form" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_unit_tuple_accepted =
  {
    name = "unit-tuple-accepted";
    spec = "module UnitEq {\n  var b: ()\n\n  val eqUnit = b == ()\n}";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"b\": {\n\
        \        \"tag\": \"UNIT\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"b\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "eqUnit"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "unit-tuple-accepted");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "unit-tuple-accepted.qnt";
                      JStr "unit-tuple-accepted.itf.json";
                      JStr "--main=UnitEq";
                      JStr "--invariant=eqUnit";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: the UNIT form evaluates equal to the \
                     empty tuple. Command, run from the fixtures root: \
                     $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < probes/unit-eq.json \
                     Observed at exit 0: {\"results\":[{\"value\":true}]}" );
              ] );
          ( "requirement",
            JStr
              "R36: the UNIT form at a non-record-typed position decodes as a \
               unit tuple" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_unknown_top_level_fields =
  {
    name = "unknown-top-level-fields";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"alpha\": 2,\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    },\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 1\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"1\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ],\n\
        \  \"zeta\": 1\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_human",
            JObj
              [
                ("information_tokens", JArr [ JStr "alpha"; JStr "zeta" ]);
                ("single_line_information_lines", JBool true);
              ] );
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 2);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr [ JStr "alpha"; JStr "zeta" ]);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "unknown-top-level-fields");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "unknown-top-level-fields.qnt";
                      JStr "unknown-top-level-fields.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R29: unknown top-level fields are accepted and listed sorted by \
               name" );
        ];
    expected_human =
      Some
        (JObj
           [
             ("information_tokens", JArr [ JStr "alpha"; JStr "zeta" ]);
             ("single_line_information_lines", JBool true);
           ]);
    derivation = None;
    hand = false;
  }

let entry_unserializable =
  {
    name = "unserializable";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#unserializable\": \"<opaque>\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr
                    [
                      JStr "decode";
                      JStr "#unserializable";
                      JStr "count";
                      JStr "states/0";
                    ] );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "unserializable");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "unserializable.qnt";
                      JStr "unserializable.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: the #unserializable form is refused (class 11)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_utf8_invalid =
  {
    name = "utf8-invalid";
    spec = "module Text {\n  var text: str\n\n  val blank = text == \"\"\n}";
    trace =
      TText
        "{\"vars\":[\"text\"],\"states\":[{\"#meta\":{\"index\":0},\"text\":\"\xff\"}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ("must_contain", JArr [ JStr "decode"; JStr "UTF-8"; JStr "56" ]);
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "utf8-invalid");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "utf8-invalid.qnt";
                      JStr "utf8-invalid.itf.json";
                      JStr "--main=Text";
                      JStr "--invariant=blank";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a non-UTF-8 byte sequence in a string is refused (class 14)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_value_forms =
  {
    name = "value-forms";
    spec =
      "module Shapes {\n\
      \  type Color = | Red | Green\n\
      \  type Row = { a: int, b: str }\n\n\
      \  var m: int -> str\n\
      \  var r: Row\n\
      \  var t: (int, str)\n\
      \  var v: Color\n\
      \  var s: Set[int]\n\
      \  var l: List[str]\n\
      \  var flag: bool\n\
      \  var big: int\n\n\
      \  val allThere = big >= -1000000\n\
      \  val bigPositive = big > 0\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"big\": {\n\
        \        \"#bigint\": \"9007199254740993\"\n\
        \      },\n\
        \      \"flag\": true,\n\
        \      \"l\": [\n\
        \        \"a\"\n\
        \      ],\n\
        \      \"m\": {\n\
        \        \"#map\": [\n\
        \          [\n\
        \            {\n\
        \              \"#bigint\": \"1\"\n\
        \            },\n\
        \            \"a\"\n\
        \          ]\n\
        \        ]\n\
        \      },\n\
        \      \"r\": {\n\
        \        \"a\": {\n\
        \          \"#bigint\": \"1\"\n\
        \        },\n\
        \        \"b\": \"x\"\n\
        \      },\n\
        \      \"s\": {\n\
        \        \"#set\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          },\n\
        \          {\n\
        \            \"#bigint\": \"2\"\n\
        \          }\n\
        \        ]\n\
        \      },\n\
        \      \"t\": {\n\
        \        \"#tup\": [\n\
        \          {\n\
        \            \"#bigint\": \"1\"\n\
        \          },\n\
        \          \"y\"\n\
        \        ]\n\
        \      },\n\
        \      \"v\": {\n\
        \        \"tag\": \"Red\",\n\
        \        \"value\": {\n\
        \          \"#tup\": []\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"m\",\n\
        \    \"r\",\n\
        \    \"t\",\n\
        \    \"v\",\n\
        \    \"s\",\n\
        \    \"l\",\n\
        \    \"flag\",\n\
        \    \"big\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [ ("name", JStr "allThere"); ("verdict", JStr "pass") ];
                      JObj
                        [
                          ("name", JStr "bigPositive"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 2) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "requirements");
          ("fixture", JStr "value-forms");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "value-forms.qnt";
                      JStr "value-forms.itf.json";
                      JStr "--main=Shapes";
                      JStr "--invariant=allThere";
                      JStr "--invariant=bigPositive";
                    ] );
              ] );
          ("requirement", JStr "R36: every R14 value form decodes and evaluates");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_variant_accepted =
  {
    name = "variant-accepted";
    spec =
      "module Variant {\n\
      \  type Color = | Red | Green\n\n\
      \  var v: Color\n\n\
      \  val isRed = v == Red\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"v\": {\n\
        \        \"tag\": \"Red\",\n\
        \        \"value\": {\n\
        \          \"#tup\": []\n\
        \        }\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"v\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj [ ("name", JStr "isRed"); ("verdict", JStr "pass") ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "variant-accepted");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "variant-accepted.qnt";
                      JStr "variant-accepted.itf.json";
                      JStr "--main=Variant";
                      JStr "--invariant=isRed";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Evaluator probe: a two-key tag/value value evaluates \
                     equal to the variant Red. Command, run from the fixtures \
                     root: $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < probes/variant-eq.json \
                     Observed at exit 0: {\"results\":[{\"value\":true}]}" );
              ] );
          ( "requirement",
            JStr
              "R36: the exact two-key tag/value object at a non-record-typed \
               position is a variant" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_vars_all_empty =
  {
    name = "vars-all-empty";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"\",\n\
        \    \"\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "vars" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "vars-all-empty");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "vars-all-empty.qnt";
                      JStr "vars-all-empty.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a vars array of empty strings collapses to one empty name \
               and is refused (class 15)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_vars_element =
  {
    name = "vars-element";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\",\n\
        \    1\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj
              [
                ( "must_contain",
                  JArr [ JStr "decode"; JStr "vars"; JStr "1"; JStr "vars/1" ]
                );
              ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "vars-element");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "vars-element.qnt";
                      JStr "vars-element.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr
              "R36: a non-string vars element is refused, naming the element \
               and its path" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_vars_empty_element =
  {
    name = "vars-empty-element";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\",\n\
        \    \"\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "vars" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "vars-empty-element");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "vars-empty-element.qnt";
                      JStr "vars-empty-element.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a remaining empty string in vars is refused (class 15)"
          );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_vars_empty =
  {
    name = "vars-empty";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": []\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "vars" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "vars-empty");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "vars-empty.qnt";
                      JStr "vars-empty.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ("requirement", JStr "R36: an empty vars array is refused (class 15)");
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_vars_not_array =
  {
    name = "vars-not-array";
    spec =
      "module Base {\n\
      \  var count: int\n\n\
      \  val nonNegative = count >= 0\n\
      \  val belowThree = count < 3\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      }\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": \"count\"\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ( "expected_diagnostic",
            JObj [ ("must_contain", JArr [ JStr "decode"; JStr "vars" ]) ] );
          ("expected_exit", JNum 2);
          ("expected_source", JStr "requirements");
          ("expected_stage", JStr "decode");
          ("fixture", JStr "vars-not-array");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "vars-not-array.qnt";
                      JStr "vars-not-array.itf.json";
                      JStr "--main=Base";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "requirement",
            JStr "R36: a wrong-typed vars field is refused (class 2)" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_vars_omits_declared =
  {
    name = "vars-omits-declared";
    spec =
      "module Plain {\n\
      \  var count: int\n\
      \  var log: List[int]\n\n\
      \  val nonNegative = count >= 0\n\
      \  val logLengthMatches = log.length() == count\n\
       }";
    trace =
      TText
        "{\n\
        \  \"states\": [\n\
        \    {\n\
        \      \"#meta\": {\n\
        \        \"index\": 0\n\
        \      },\n\
        \      \"count\": {\n\
        \        \"#bigint\": \"0\"\n\
        \      },\n\
        \      \"log\": []\n\
        \    }\n\
        \  ],\n\
        \  \"vars\": [\n\
        \    \"count\"\n\
        \  ]\n\
         }";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 0);
          ( "expected_report",
            JObj
              [
                ("exit", JNum 0);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "nonNegative"); ("verdict", JStr "pass");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 1);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 0); ("pass", JNum 1) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "probe");
          ("fixture", JStr "vars-omits-declared");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "vars-omits-declared.qnt";
                      JStr "vars-omits-declared.itf.json";
                      JStr "--main=Plain";
                      JStr "--invariant=nonNegative";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "probe",
                  JStr
                    "Probe: $HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
                     evaluate-at-state-from-stdin < \
                     probes/vars-omits-declared-eval.json returned exit 0 with \
                     {\"results\":[{\"value\":true}]} for state 0. Request: \
                     probes/vars-omits-declared-eval.json" );
              ] );
          ( "requirement",
            JStr
              "A7: a vars array omitting a declared state key is accepted; \
               state keys drive the comparison" );
        ];
    expected_human = None;
    derivation = None;
    hand = false;
  }

let entry_violating_trace =
  {
    name = "violating-trace";
    spec =
      "module Violating {\n  var count: int\n\n  val belowThree = count < 3\n}";
    trace =
      TText
        "{\"#meta\":{\"format\":\"ITF\",\"format-description\":\"https://apalache-mc.org/docs/adr/015adr-trace.html\",\"source\":\"violation/violating.qnt\",\"status\":\"violation\",\"description\":\"Created \
         by Quint on Fri Nov 13 2026 09:15:34 GMT+0000 (Coordinated Universal \
         Time)\",\"timestamp\":1794561334229},\"vars\":[\"count\"],\"states\":[{\"#meta\":{\"index\":0},\"count\":{\"#bigint\":\"0\"}},{\"#meta\":{\"index\":1},\"count\":{\"#bigint\":\"1\"}},{\"#meta\":{\"index\":2},\"count\":{\"#bigint\":\"2\"}},{\"#meta\":{\"index\":3},\"count\":{\"#bigint\":\"3\"}}]}";
    trace_rel = None;
    expected =
      JObj
        [
          ("expected_exit", JNum 1);
          ( "expected_human",
            JObj
              [
                ( "fail_tokens",
                  JArr
                    [
                      JStr "no violation observed in this trace";
                      JStr "\xe2\x9c\x93";
                    ] );
                ("fail_wording", JStr "FAIL at state 3: { count: 3 }");
                ("single_line_header", JBool true);
                ( "summary_form",
                  JStr "Summary: 0 pass, 1 fail (exit 1) source-mismatch" );
                ("summary_lines", JNum 1);
              ] );
          ( "expected_report",
            JObj
              [
                ("exit", JNum 1);
                ("ignored_vars", JArr []);
                ( "invariants",
                  JArr
                    [
                      JObj
                        [
                          ("name", JStr "belowThree");
                          ("rendering", JStr "{ count: 3 }");
                          ("state", JNum 3);
                          ( "state_value",
                            JObj
                              [
                                ("#meta", JObj []);
                                ("count", JObj [ ("#bigint", JStr "3") ]);
                              ] );
                          ("verdict", JStr "fail");
                        ];
                    ] );
                ("source", JNull);
                ("source_mismatch", JNull);
                ("states", JNum 4);
                ("status", JNull);
                ("summary", JObj [ ("fail", JNum 1); ("pass", JNum 0) ]);
                ("trace_sha256", JNull);
                ("unknown_top_level_fields", JArr []);
              ] );
          ("expected_source", JStr "producer-trace");
          ("fixture", JStr "violating-trace");
          ( "invocation",
            JObj
              [
                ( "args",
                  JArr
                    [
                      JStr "violating-trace.qnt";
                      JStr "violating-trace.itf.json";
                      JStr "--main=Violating";
                      JStr "--invariant=belowThree";
                    ] );
              ] );
          ( "provenance",
            JObj
              [
                ( "origin",
                  JStr
                    "copied unmodified from traces/violating.itf.json; \
                     produced by quint 0.33.1 with the Rust backend" );
              ] );
          ( "requirement",
            JStr "A2: a finite violating trace, FAIL at its last state" );
        ];
    expected_human =
      Some
        (JObj
           [
             ( "fail_tokens",
               JArr
                 [
                   JStr "no violation observed in this trace";
                   JStr "\xe2\x9c\x93";
                 ] );
             ("fail_wording", JStr "FAIL at state 3: { count: 3 }");
             ("single_line_header", JBool true);
             ( "summary_form",
               JStr "Summary: 0 pass, 1 fail (exit 1) source-mismatch" );
             ("summary_lines", JNum 1);
           ]);
    derivation = None;
    hand = false;
  }

let entries =
  [
    entry_apalache_instrumentation;
    entry_bigint_10e15_bigint;
    entry_bigint_10e15;
    entry_bigint_9007199254740993_bigint;
    entry_bigint_9007199254740993;
    entry_bigint_999999999999999999_bigint;
    entry_bigint_999999999999999999;
    entry_bigint_beyond_i64_typescript;
    entry_bigint_chunk_noncanonical;
    entry_bigint_chunk_range;
    entry_bigint_e_noncanonical;
    entry_bigint_empty_chunks;
    entry_bigint_group_count;
    entry_bigint_i64_max_bigint;
    entry_bigint_i64_max;
    entry_bigint_i64_min_bigint;
    entry_bigint_i64_min;
    entry_bigint_ignored_key_fail;
    entry_bigint_leading_zero_chunk;
    entry_bigint_negative_bigint;
    entry_bigint_negative_exponent;
    entry_bigint_negative_over_i64;
    entry_bigint_negative;
    entry_bigint_nested;
    entry_bigint_positive_over_i64;
    entry_bigint_record_shape;
    entry_bigint_s_negative_zero;
    entry_bigint_s_noncanonical;
    entry_bigint_s_two_chunk;
    entry_bigint_sign;
    entry_bigint_too_wide;
    entry_bigint_trailing_zero_chunk;
    entry_bigint_width_mismatch;
    entry_bigint_width;
    entry_bigint_zero_chunk;
    entry_bigs_rust;
    entry_class10_bare_number;
    entry_class10_bigint;
    entry_class10_map;
    entry_class10_set;
    entry_class10_tup;
    entry_class10_variant_tag;
    entry_class13_int_for_record;
    entry_class13_list_element;
    entry_class13_variant_position;
    entry_class9_record_hash;
    entry_class9_two_hash;
    entry_class9_unknown_hash;
    entry_cli_values;
    entry_collision_record;
    entry_collision_unit;
    entry_const_instance;
    entry_duplicate_members;
    entry_extra_key;
    entry_forged_ignored_key;
    entry_forged_path;
    entry_forged_source_meta;
    entry_hand_bigint;
    entry_hand_evaluation_error;
    entry_hand_init_fail;
    entry_hand_mixed;
    entry_hand_pass;
    entry_hand_precedence_scope;
    entry_hand_precedence;
    entry_hand_violation;
    entry_ignored_duplicates;
    entry_ignored_malformed_bigint;
    entry_json_garbage;
    entry_json_top_array;
    entry_json_trailing;
    entry_json_truncated;
    entry_loop_fail;
    entry_loop_negative;
    entry_loop_out_of_range;
    entry_loop_valid;
    entry_mbt_vars;
    entry_meta_source_absent_strict;
    entry_meta_source_mismatch_strict;
    entry_meta_source_number_strict;
    entry_meta_source_number;
    entry_meta_top_number;
    entry_meta_top_string;
    entry_missing_variable;
    entry_nested_instance;
    entry_newline_render;
    entry_ordinal_absent;
    entry_ordinal_duplicate;
    entry_ordinal_mismatch;
    entry_ordinal_noninteger;
    entry_ordinal_partial;
    entry_params_empty;
    entry_params_nonempty;
    entry_params_null;
    entry_params_number;
    entry_params_string;
    entry_plain_pass;
    entry_render_shapes;
    entry_render_truncate;
    entry_resolver_action_invariant;
    entry_resolver_def_invariant;
    entry_resolver_export_visible;
    entry_resolver_hidden_import;
    entry_resolver_invariant_absent;
    entry_resolver_main_absent;
    entry_resolver_param_val;
    entry_resolver_puredef_invariant;
    entry_resolver_temporal_invariant;
    entry_shapes_rust;
    entry_shapes_typescript;
    entry_source_mismatch;
    entry_state_meta_not_object;
    entry_state_not_object;
    entry_states_empty;
    entry_states_not_array;
    entry_status_ok_failing;
    entry_status_violation_passing;
    entry_tagged_record;
    entry_text_escapes;
    entry_two_instance;
    entry_unit_result;
    entry_unit_tuple_accepted;
    entry_unknown_top_level_fields;
    entry_unserializable;
    entry_utf8_invalid;
    entry_value_forms;
    entry_variant_accepted;
    entry_vars_all_empty;
    entry_vars_element;
    entry_vars_empty_element;
    entry_vars_empty;
    entry_vars_not_array;
    entry_vars_omits_declared;
    entry_violating_trace;
  ]

let companion_spec =
  "module Spec {\n\
  \  const C: Set[int]\n\n\
  \  var x: int\n\
  \  var seen: Set[int]\n\n\
  \  val bounded = C.contains(x)\n\
   }"
