(* Corpus gate: the fixture corpus is the reference for the decoder
   and the metadata fields, and the committed expected pairs are the reference
   for the schema module. Licence: AGPL-3.0-or-later; see README.md. *)

let sha256_vectors =
  [
    ("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    ("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    ( "The quick brown fox jumps over the lazy dog",
      "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592" );
  ]

let test_sha256 () =
  List.iter
    (fun (input, digest) ->
      Alcotest.(check string) input digest (Sha256.hex input))
    sha256_vectors

let path_pattern =
  "^([^/]|[^/.][^/]+|\\.[^/.][^/]*|\\.\\.[^/]+)(/(|[^/]|[^/.][^/]+|\\.[^/.][^/]*|\\.\\.[^/]+))*$"

let test_patterns () =
  Alcotest.(check bool)
    "digest" true
    (Schema.pattern_match "^[0-9a-f]{64}$"
       "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
  Alcotest.(check bool)
    "short digest" false
    (Schema.pattern_match "^[0-9a-f]{64}$" (String.make 63 'a'));
  Alcotest.(check bool)
    "uppercase digest" false
    (Schema.pattern_match "^[0-9a-f]{64}$" (String.make 64 'A'));
  Alcotest.(check bool)
    "relative path" true
    (Schema.pattern_match path_pattern "real/janet-stats/specs/x.qnt");
  Alcotest.(check bool)
    "one segment" true
    (Schema.pattern_match path_pattern "library.qnt");
  Alcotest.(check bool)
    "two segments" true
    (Schema.pattern_match path_pattern "real/x.qnt");
  Alcotest.(check bool)
    "alt group" true
    (Schema.pattern_match "^([^/]|[^/.][^/]+)$" "library.qnt");
  Alcotest.(check bool)
    "absolute path" false
    (Schema.pattern_match path_pattern "/corpus/real/x.qnt");
  Alcotest.(check bool)
    "parent path" false
    (Schema.pattern_match path_pattern "../escape.qnt");
  Alcotest.(check bool)
    "interior parent path" false
    (Schema.pattern_match path_pattern "real/../escape.qnt");
  Alcotest.(check bool)
    "seed hex" true
    (Schema.pattern_match "^(0x[0-9a-fA-F]+|[0-9]+)$" "0x1F");
  Alcotest.(check bool)
    "empty seed" false
    (Schema.pattern_match "^(0x[0-9a-fA-F]+|[0-9]+)$" "")

let test_version () =
  Alcotest.(check string) "version line" "quint-checktrace 0.1.0" Version.banner

let test_corpus () =
  if not (Corpus_support.corpus_gate ()) then Alcotest.fail "corpus gate failed"

let test_schema () =
  if not (Corpus_support.schema_expected_pairs ()) then
    Alcotest.fail "schema expected pairs disagree"

let () =
  Alcotest.run "quint-checktrace"
    [
      ("sha256", [ Alcotest.test_case "vectors" `Quick test_sha256 ]);
      ("version", [ Alcotest.test_case "banner" `Quick test_version ]);
      ("patterns", [ Alcotest.test_case "anchored subset" `Quick test_patterns ]);
      ("resolver", Resolver_cases.suite);
      ("evaluator", Evaluator_cases.suite);
      ("report", Report_cases.suite);
      ("gate", Gate_cases.suite);
      ("resolver scope", Resolver_scope_cases.suite);
      ("stage order", Stage_order_cases.suite);
      ("descent", Descent_cases.suite);
      ("taxonomy", Taxonomy_cases.suite);
      ("corpus", [ Alcotest.test_case "decode and metadata" `Quick test_corpus ]);
      ("schema", [ Alcotest.test_case "expected pairs" `Quick test_schema ]);
    ]
