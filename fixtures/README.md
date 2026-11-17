# Fixture corpus

The fixture corpus is the executable specification of the checker's decoder,
evaluator client and report. Each fixture is a specification, a trace and an
expected outcome. The corpus is self-contained: every file a fixture needs is
in this directory tree, and every reused producer trace carries its origin in
its expected file.

## Layout

```
<name>.qnt             the specification, one module with the named invariants
<name>.itf.json        the trace
<name>.expected.json   the complete expected outcome
hand-verified/         the hand-derived fixture set (eight fixtures)
probes/                recorded evaluator requests and captures
traces/                unmodified producer traces that the generator copies
spec.qnt               companion module imported by const-instance.qnt
```

`nested-instance.qnt` and `two-instance.qnt` declare the modules they import in
the same file.

Every specification parses with Quint 0.33.1. All traces parse as JSON except
the three deliberate malformed-JSON fixtures named under "Non-JSON traces";
`utf8-invalid.itf.json` is valid JSON bytes only if the reader tolerates invalid
UTF-8, which the checker must not.

## Expected outcome file

| field | meaning |
|---|---|
| `fixture` | the fixture name, matching the file stem |
| `requirement` | the requirement item the fixture pins, by id and by the behaviour it exercises |
| `expected_source` | how the expectation was established: `probe`, `requirements`, `hand` or `producer-trace` |
| `invocation` | the exact argv to the checker, with fixture-relative paths |
| `invocations` | an array of invocations, each with its own expected exit, stage and diagnostic; used where one fixture covers a family of argument values |
| `expected_exit` | the process exit code: 0, 1 or 2 |
| `expected_stage` | for exit 2, the stage named in the diagnostic |
| `expected_diagnostic` | the tokens the exit-2 diagnostic must contain, and for a case that must omit an error code, the tokens it must not contain |
| `expected_report` | for exit 0 and 1, a flattened comparison projection of the report object, not the report object itself: the `trace` object's members (`source`, `status`, `source_mismatch`, `states`, `loop`, `ignored_vars`, `unknown_top_level_fields`) where present sit at the top level beside `exit`, `summary`, `invariants` and `trace_sha256`, which is the pinned comparison key for the report's `trace.sha256` field (the digest of the fixture's committed trace bytes), not a report field |
| `expected_human` | the human-format properties that are byte-checked: a single-line header, the header's required tokens, exactly one summary line, the summary form, a summary token, single-line information lines, the absent-value renderings, the exact PASS wording with the tokens a PASS row must not carry, or the exact FAIL wording with the tokens a FAIL row must not carry |
| `expected_silent` | optional; invariants recorded as expected absent from the report. Present on the hand-verified fixtures, whose expected outcome is complete; an exit-2 fixture records the invariants it leaves without a report row. An edge fixture that carries a row for every requested invariant may omit it. |
| `expected_evaluation_calls` | the invariant-evaluation count a DEBUG-instrumented evaluator records; present on the loop fixtures, where it equals the recorded state count |
| `provenance` | where a reused trace came from, and the probe record for a probe-side premise |
| `derivation` | the hand-derivation document, in the hand-verified set |
| `category` | the R46 category of a hand-verified fixture, one of the six named categories |

The `expected_human` object uses these property names: `single_line_header`,
`header_tokens` (the strings the header block must carry: the spec path, the
main module, the trace path, the source and status renderings, the state count,
the Quint version, the evaluator path and the `sha256=` prefix, and the mode),
`header_patterns` (regular expressions the header block must contain a match
for; `plain-pass` pins the evaluator digest prefix to R4's first 12 lowercase
hex characters, followed by a non-hex character or the end of the line),
`summary_lines`, `summary_form` (the exact summary line:
`Summary: <n> pass, <n> fail (exit <n>)`, carrying the exact
`source-mismatch` token whenever `#meta.source` is a present string that
differs from the supplied spec path without `--strict-source`),
`summary_token` (the token the summary line must carry),
`summary_absent_tokens` (the strings the summary line must not carry),
`single_line_information_lines`, `source_rendering`, `status_rendering`,
`pass_wording` (the exact text every PASS row must carry), `pass_absent_tokens`
(the strings a PASS row must not carry), `fail_wording` (the exact text every
FAIL row must carry, including the state index and the rendered state),
`fail_tokens` (the strings a FAIL row must not carry), `escaped_renderings`
(caller-controlled values asserted in their escaped single-line form, with a
newline as `\u000a`), `coverage_line` (the exact sentence after the header
stating that the verdict covers the recorded states only), `status_glyphs`
(the `pass` and `fail` status glyphs), `information_tokens` (the strings the
information line or lines must carry) and `information_absent_tokens` (the
strings the information line or lines must not carry; `meta-source-number`
uses it to pin that a non-string `#meta.source` or `#meta.status` renders no
value).

Each fixture's recorded `invocation` is run twice: once exactly as recorded,
which produces the default human report, and once with `--format=json`
appended, which produces the machine report. `expected_human` is compared
against the first run and `expected_report` against the second. An `invocations`
entry is read the same way: its own exit, stage and diagnostic apply to both
runs, and a successful entry's report and human properties are compared against
the two runs.

Requirement and acceptance identifiers in `requirement` fields are stable
labels for the behavioural rule each fixture pins; the rule's substance is
stated in the field itself, and the label stays fixed so fixtures, this index
and the generator's committed table stay cross-referenceable.

`expected_source` values:

- `probe`: the expected outcome, or the evaluator-side premise it rests on, was
  verified against the pinned binaries. The command and the captured output
  are recorded in the expected file, and where the fixture has a committed
  request and capture they are under `probes/` as `<name>.json` and
  `<name>.out`.
- `requirements`: the expectation is a contract statement, fixed before the
  implementation from the behavioural rules this corpus pins, and not taken
  from a run or a hand derivation.
- `hand`: the expectation was derived by hand from the specification text, for
  the hand-verified set. The evaluator is not run to establish any expectation.
  After the derivation a one-time evaluator cross-check is permitted; where its
  requests and captures are committed they are listed under `probes/`, and the
  derivation record states the cross-check as a separate, later step. The
  precedence fixtures carry such cross-check notes.
- `producer-trace`: the fixture replays an archived producer trace. The trace is
  the evidence; its `origin` records the producing output and the archive it
  came from, and no evaluator request was recorded for it.

`expected_diagnostic` carries required substrings rather than an exact sentence.
The stage, the refusal class, the variable or member name and the presence of a
JSON path or byte offset are fixed by the contract; the diagnostic
wording is the implementation's choice. The path tokens in the refusal
fixtures use the slash form the existing fixtures established:
`states/<index>/<variable>` for a value position, `vars/<index>` for a `vars`
element and `#meta` for a top-level member (which is both the member name and
its path), so a class-13 or duplicate-member diagnostic carries the state index
inside the path token. A `must_not_contain` list pins an
absence the contract states, such as the Quint error code a non-boolean
result carries none of. The byte position recorded for the class-1 fixtures is
the 0-based offset of the first non-whitespace trailing byte, or of the end of
input for a truncated document; whitespace between the document and the
trailing data is not trailing data.

The stage assignments are fixed by the contract and recorded on the
fixtures:

- the `--strict-source` refusal is at stage `decode` (R11), because trace
  metadata is read during decoding;
- the pre-parse JSON classes are at stage `decode` with a byte position and no
  JSON path (R18, A4);
- the invalid-UTF-8 half of class 14 records the 0-based offset of the first
  invalid byte, which `utf8-invalid` pins at offset 56.

## Edge fixtures (R36)

Every item of the edge-fixture contract is carried by at least one fixture.

| item | fixtures |
|---|---|
| evaluator response carrying a tuple value, refused as non-boolean | `unit-result` |
| FAIL with a newline string, rendering pinned byte-exactly | `newline-render` |
| forged `Summary:` text in `#meta.source` | `forged-source-meta` |
| forged `Summary:` text in the trace file path | `forged-path` |
| forged `Summary:` text in an ignored key name | `forged-ignored-key` |
| malformed `--timeout`, `--deadline` and `--gate-deadline` values, and a `--timeout` larger than `--deadline`, on the check and the gate invocation | `cli-values` |
| truncated JSON, trailing bytes, non-JSON bytes, top-level array | `json-truncated`, `json-trailing`, `json-garbage`, `json-top-array` |
| empty `states`, state not an object, missing declared variable | `states-empty`, `state-not-object`, `missing-variable` |
| wrong-typed `vars` and `states`, non-string `vars` element, top-level `#meta` as a string and as a number | `vars-not-array`, `states-not-array`, `vars-element`, `meta-top-string`, `meta-top-number` |
| duplicate members in a state, duplicate members inside an ignored value | `duplicate-members`, `ignored-duplicates` |
| duplicated ordinal, ordinal mismatch, absent ordinals, partial presence, a non-integer ordinal | `ordinal-duplicate`, `ordinal-mismatch`, `ordinal-absent`, `ordinal-partial`, `ordinal-noninteger` |
| state `#meta` not an object | `state-meta-not-object` |
| `#meta.source` and `#meta.status` as non-strings, and the strict-source refusal | `meta-source-number`, `meta-source-number-strict` |
| valid loop, out-of-range loop, negative loop | `loop-valid`, `loop-out-of-range`, `loop-negative` |
| unknown top-level fields accepted and listed sorted | `unknown-top-level-fields` |
| MBT variables, Apalache instrumentation, an unrelated extra key | `mbt-vars`, `apalache-instrumentation`, `extra-key` |
| every value form, a tag-bearing record with other fields, a variant, both record collisions, the unit tuple | `value-forms`, `tagged-record`, `variant-accepted`, `collision-record`, `collision-unit`, `unit-tuple-accepted`, `unit-result` |
| unknown `#` constructor, more than one `#` key, a record field starting with `#` | `class9-unknown-hash`, `class9-two-hash`, `class9-record-hash` |
| malformed `#bigint`, `#set`, `#tup`, `#map`, variant; bare JSON number | `class10-bigint`, `class10-set`, `class10-tup`, `class10-map`, `class10-variant-tag`, `class10-bare-number` |
| `#unserializable` | `unserializable` |
| value not typeable against the declaration | `class13-int-for-record`, `class13-list-element`, `class13-variant-position` |
| accepted Rust big-integer objects and their decimal twins | `bigint-10e15`, `bigint-10e15-bigint`, `bigint-9007199254740993`, `bigint-9007199254740993-bigint`, `bigint-999999999999999999`, `bigint-999999999999999999-bigint`, `bigint-negative`, `bigint-negative-bigint`, `bigint-i64-max`, `bigint-i64-max-bigint`, `bigint-i64-min`, `bigint-i64-min-bigint`, `bigint-chunk-noncanonical`, `bigint-record-shape` |
| refused Rust big-integer objects (class 12) | `bigint-width`, `bigint-width-mismatch`, `bigint-chunk-range`, `bigint-leading-zero-chunk`, `bigint-trailing-zero-chunk`, `bigint-sign`, `bigint-s-two-chunk` (the chunk-legal member spelling that keeps class 12), `bigint-empty-chunks`, `bigint-negative-exponent`, `bigint-group-count`, `bigint-s-negative-zero` (the non-canonical `-0` sign text), `bigint-e-noncanonical`, `bigint-zero-chunk` (the `c: [0]` zero spelling), `bigint-too-wide`, `bigint-positive-over-i64`, `bigint-negative-over-i64` |
| a non-decimal `#bigint` member of the chunk shape, refused at the member position under class 10 | `bigint-s-noncanonical` |
| a TypeScript-backend decimal integer beyond the signed 64-bit range | `bigint-beyond-i64-typescript` |
| `{s,e,c}` at a record field, a list element, a set element, a map value and a tuple slot | `bigint-nested` |
| empty `vars`, all-empty entries, an empty entry beside a name | `vars-empty`, `vars-all-empty`, `vars-empty-element` |
| empty `params` accepted, non-empty `params`, wrong-typed `params` | `params-empty`, `params-nonempty`, `params-null`, `params-string`, `params-number` |
| a non-UTF-8 byte sequence in a string | `utf8-invalid` |
| a multibyte rendering truncated at the 200-code-point cap | `render-truncate` |
| backslash and double-quote escapes in a rendered string | `text-escapes` |
| a FAIL `state_value` with an ignored key stripped and a `{s,e,c}` value normalised | `bigint-ignored-key-fail` |

## Acceptance criteria support

| criterion | supporting fixtures |
|---|---|
| A1, clean trace and exact PASS wording | `plain-pass` (the expected file pins the wording and the token a PASS row must not carry), `hand-pass` |
| A2, violation trace, failing name and state, quoted state, full state value | `violating-trace` (the expected report pins `state_value`, and the expected human pins the FAIL row wording and the tokens a FAIL row must not carry), `hand-violation` |
| A3, violation at the initial state | `hand-init-fail` |
| A4, a fixture for every refusal class | every `class9-*`, `class10-*`, `class13-*`, `unserializable`, `json-*`, `states-empty`, `states-not-array`, `state-not-object`, `missing-variable`, `vars-*`, `meta-top-*`, `duplicate-members`, `ordinal-*`, `state-meta-not-object`, `loop-*`, `params-*`, `bigint-*`, `utf8-invalid`, `collision-record`, `collision-unit` fixture |
| A5, Rust integer forms and their twins give equal verdicts | `bigs-rust`, `bigint-10e15` and `bigint-10e15-bigint`, `bigint-9007199254740993` and `bigint-9007199254740993-bigint`, `bigint-999999999999999999` and `bigint-999999999999999999-bigint`, `bigint-negative` and `bigint-negative-bigint`, `bigint-i64-max` and `bigint-i64-max-bigint`, `bigint-i64-min` and `bigint-i64-min-bigint`, `hand-bigint` |
| A6, instance verdicts and variable naming | `const-instance`, `nested-instance`, `two-instance` |
| A7, MBT and extra-key stripping, ignored names listed | `mbt-vars`, `extra-key`, `ignored-malformed-bigint`, `vars-omits-declared` (the JSON `ignored_vars` only) and `forged-ignored-key` (the human information line) |
| A8, loop states checked once, a FAIL at a loop-state index, Apalache trace accepted | `loop-valid`, `loop-fail` (both pin `expected_evaluation_calls`), `apalache-instrumentation` |
| A9, status is not authoritative | `status-ok-failing`, `status-violation-passing` |
| A10, gate counts, refusals and non-vacuity | the gate run; a zero-triple manifest exits 2 with `triples=0`; an absent, short or category-incomplete hand-verified inventory exits 2 at `resolve`; small `--gate-deadline` runs pin expiry during validation, classification and the fixture phase; a checker exit 2 on an admitted triple is a disagreement; a trace with one value byte mutated in a scratch corpus makes the gate exit 1, a derivation record with one outcome marker flipped makes the gate exit 2 at `resolve` before any replay, and a wrong hand-fixture expectation makes the gate exit 1 with `fixtures_disagree` greater than zero |
| A11, deterministic reports | `newline-render` (byte-pinned rendering), `render-shapes` (every renderable form, byte-pinned), `render-truncate` (the 200-code-point cap, distinguished from a byte cap by a multibyte value), `text-escapes` (backslash and double-quote escapes), `plain-pass` (the complete header token set and the 12-hex digest-prefix pattern, the coverage sentence and the exact summary form), `unknown-top-level-fields` (sorted list, information line); every fixture can be run twice |
| A12, failure stages | `unit-result` (non-boolean result); the acceptance commands for the missing evaluator, wrong Quint version, parse timeout, evaluator-call timeout and precedence case, with their shims |
| A13, JSON report validates against the schema | every `expected_report` states the values the report must carry, including a FAIL row's `state_value`; the recorded invocation is additionally run with `--format=json` and that output validates; the checker's fixed fields (`tool`, `mode`, `spec`, `evaluator`) complete it to a full document, and the schema applies to the completed document |
| A14, no simulation call | the corpus never invokes the checker's Quint surface; the PATH shim test is a suite fixture, not a corpus fixture, and asserts the R24 allowlist: only `quint --version` and `quint parse` appear, never `quint run`, `quint verify`, `quint test` or the evaluator's `run` |
| A15, build, test, fmt and lint | not fixture-driven; the release procedure records the commands and the pinned versions |
| A16, A17, strict-source and the mismatch token | `meta-source-number-strict`, `meta-source-absent-strict`, `meta-source-mismatch-strict`, `source-mismatch`, `forged-source-meta` |
| A18, resolver refusals | `resolver-main-absent`, `resolver-invariant-absent`, `resolver-action-invariant`, `resolver-temporal-invariant`, `resolver-def-invariant`, `resolver-puredef-invariant`, `resolver-param-val`, `resolver-hidden-import` (a name declared only in an imported module), `resolver-export-visible` (a name visible only through an export) |

## Rendering and report-surface fixtures

The rendering fixtures pin R27's rendering grammar beside the records the
producer traces already carry. `render-shapes` renders one value of every
renderable form in a
single failing state, so the Set and Map ordering rules (by rendered text, not
by numeric order) are byte-pinned: `{ b: true, l: [1, 2], m: Map(10 -> "a", 2
-> "b"), n: -7, s: Set(1, 10, 2), t: (1, "x"), u: (), v: Circle(5) }`.
`render-truncate` renders a value of ten two-byte characters (`é`) followed by
forty control characters, whose full rendering is 9 + 10 + 40 × 6 + 3 = 262
code points. The 197 code points available to the prefix end four characters
inside the thirtieth `\u0001` escape, so the pinned prefix stops at the last
complete escape: the ten multibyte characters and 29 complete `\u0001` escapes
plus the ellipsis, 196 code points and 206 bytes. A byte-counting cap stops one
escape earlier, at 190 code points and 200 bytes, so the fixture distinguishes
the code-point rule from a byte rule, and a truncation inside an escape fails
it. `text-escapes` pins the backslash and double-quote escapes
byte-exactly in a rendered string. `plain-pass` pins the human header token
set and the 12-hex digest prefix, the coverage sentence, the status glyphs and
the exact summary form;
`loop-valid` and `loop-fail` pin `trace.loop` to 1 and 2 and carry
`expected_evaluation_calls` (3 and 4). The suite runs a DEBUG-instrumented
evaluator that records one invariant evaluation per recorded state, which pins
the checked-once property that a pure Quint invariant cannot otherwise expose.

## Hand-verified set (R46)

Eight fixtures, each with a complete expected outcome and a derivation document
stating the property, the expected result and the reasoning from the
specification text. A FAIL row records the invariant name, the verdict, the
hand-derived state index, and the rendering and forwarded `state_value` the
derivation derives; the agreement contract is on the name, the verdict and the
index, and a recorded rendering or `state_value` that differs from the
checker's report is a disagreement. The set covers the six required categories
plus a mixed multi-invariant row set. Each expected file carries the category as
a machine-readable `category` field, and the gate reads it and checks that all
six categories are present; `hand-mixed` is a second `violation` case with a
mixed row set.

| fixture | category | expected outcome |
|---|---|---|
| `hand-pass` | `pass` | exit 0, `nonNegative` PASS, 3 states |
| `hand-violation` | `violation` | exit 1, `belowThree` FAIL at state 3, rendering `{ count: 3 }` |
| `hand-init-fail` | `initial-state-violation` | exit 1, `positive` FAIL at state 0 |
| `hand-evaluation-error` | `evaluation-error` | exit 2 at stage `evaluate`, naming the unbound constant |
| `hand-precedence` | `multi-invariant-precedence` | exit 2 at stage `evaluate`, naming `divLater` at state 1 |
| `hand-precedence-scope` | `multi-invariant-precedence` | exit 1, `zeroDiv` FAIL at state 0, `nonNegative` PASS; the failed invariant is not evaluated later, so its would-be error at state 1 is outside the exit-2 scope |
| `hand-bigint` | `big-integer` | exit 0, `atMax` PASS, i64 maximum in the `{s,e,c}` form |
| `hand-mixed` | `violation` | exit 1, `belowThree` FAIL at state 3, `nonNegative` PASS |

## Reused producer traces

| fixture | origin |
|---|---|
| `plain-pass` | Quint 0.33.1, Rust backend, `plain/plain.qnt` |
| `violating-trace` | Quint 0.33.1, Rust backend, `violation/violating.qnt` |
| `mbt-vars` | Quint 0.33.1, Rust backend, `plain/plain.qnt` with `--mbt` |
| `const-instance` | Quint 0.33.1, Rust backend, instance with `C = Set(1, 2, 3)` |
| `shapes-rust` | Quint 0.33.1, Rust backend, `shapes/shapes.qnt` |
| `shapes-typescript` | Quint 0.33.1, TypeScript backend, `shapes/shapes.qnt` |
| `bigs-rust` | Quint 0.33.1, Rust backend, `shapes/bigs.qnt` |
| `apalache-instrumentation` | Apalache 0.62.4 temporal counterexample |
| `nested-instance` | Quint 0.33.1, Rust backend, `nested-instance.qnt` with `--max-steps=2` |
| `two-instance` | Quint 0.33.1, Rust backend, `two-instance.qnt` with `--max-steps=2` |

Each of the ten is copied from its unmodified original in `traces/`. The eight
archived traces were produced by Quint 0.33.1 (Rust or TypeScript backend) or
Apalache 0.62.4; the two instance traces were produced by Quint 0.33.1 with the
Rust backend. The `const-instance` trace was regenerated with the pinned Quint
when the fixture's invariant began reading the instance constant `C`, and its
verdict premise is the committed evaluator probe. Each expected file records its
in-corpus trace copy in `provenance.origin`. The copies are unmodified, so a copied trace's
`#meta.source` keeps its producer spelling; where that differs from the
fixture-local path, the expected file records `source_mismatch: true` or the
strict-source refusal, as the contract directs.

## Non-JSON traces

`json-truncated`, `json-trailing` and `json-garbage` are deliberately not
valid JSON: they pin the pre-parse refusal class. `utf8-invalid` carries a raw
byte that is not valid UTF-8 inside a JSON string.

## Corpus provenance

The corpus is a set of static files. The generator and the schema validator
beside it are maintenance tools, not corpus content: the corpus needs no
build step and imports no library, and every file a fixture needs is in this
tree. The generator writes the edge fixtures and the hand-verified set; the
evaluator probes, this README, the probes README and the traces under `traces/`
are hand-captured additions outside its scope. The ten reused
traces have their unmodified originals in `traces/`;
each is an output of Quint 0.33.1 or Apalache 0.62.4, as recorded in its
fixture's expected file.

One fixture's trace path carries a newline: `forged-path` keeps its trace in a
directory named `forged-path`, a newline, and `Summary: 1 pass, 0 fail (exit 0)`.
Git carries the entry, and the corpus generator recreates it exactly, but
archive tools, patch tools and some checkouts may mangle it, and a plain
directory listing splits the name across two lines.

Every specification parses with the pinned frontend:

```sh
quint parse --out "$TMPDIR/fixture.ir.json" <fixture>.qnt
```

## Counts

125 edge fixtures, 8 hand-verified fixtures, 134 specification files (125 edge
fixture specifications, eight hand-verified specifications and the companion
module `spec.qnt`). The tree also carries ten producer traces under `traces/`
and 42 evaluator request and capture pairs under `probes/`.

## Lint baseline

`quint-audit lint` over the 133 fixture specification files (the companion
module `spec.qnt` beside them is not part of the lint set), with the default
fail threshold. `bigint-s-two-chunk` carries the same specification text as
`bigint-sign`:

- 127 exit 0, carrying 303 findings (QL001 10, QL002 8, QL006 150, QL009 134,
  QP002 1) on replay-shaped fixtures that have no actions; QP002 is an
  information-level note on the export fixture's `export` declaration;
- 1 exits 1: `two-instance.qnt`, whose invariant reads instance-qualified state
  (`a::bounded`, `b::bounded`) that the QL006 check does not recognise as a
  state reference. This is a quint-audit false positive for instance-qualified
  invariants, not a fixture defect;
- 5 exit 2: `bigint-i64-max.qnt`, `bigint-i64-max-bigint.qnt`,
  `bigint-i64-min.qnt`, `bigint-i64-min-bigint.qnt` and
  `hand-verified/hand-bigint.qnt`, because quint-audit refuses an integer
  literal above the OCaml `int` range. All five parse and evaluate correctly
  with the pinned Quint and evaluator.

No other specification carries a fail-severity finding, and QP001 fires on no
file. Both remaining classes are quint-audit-side defects; they are recorded
here and not fixed in this corpus.
