# Evaluator request records

Each request file is a self-contained input to the pinned evaluator, and each
matching output file is the recorded capture of that run. Each request carries
the evaluator `table` and the expression under test. The scalar fixtures use a
minimal table (the evaluator resolves a variable by name, so one variable
declaration is enough); the instance fixtures carry the parsed table the
fixture's specification produces, because the state names are
instance-qualified.

Run a request from this directory:

```sh
$HOME/.quint/rust-evaluator-v0.7.1/quint_evaluator \
  evaluate-at-state-from-stdin < <name>.json > <name>.out 2>&1
```

Environment: Quint 0.33.1, Rust evaluator v0.7.1. Binary digest:
`1764f11e8c1a9f644af5c934e9a71645b313f82f8db1284965866a2f417da9aa`.

| request | exercised shape | observed |
|---|---|---|
| `unit-result` | unit tuple decoded from `{"tag":"UNIT"}`, invariant is a tuple | exit 0, a tuple value, which the checker refuses as a non-boolean result |
| `unit-eq` | the same unit value compared with the empty tuple | exit 0, true |
| `variant-eq` | a two-key `tag`/`value` object at a variant position | exit 0, true |
| `unit-record-field` | the one-key UNIT object at a record position, field access | exit 101, panic, expected record |
| `collision-record-field` | a two-key `tag`/`value` object at a record position, field access | exit 101, panic, expected record |
| `bigint-*` | Rust `{s,e,c}` objects and their decimal `#bigint` twins | the unnormalised object compares false at exit 0; the normalised decimal form compares true |
| `bigint-beyond-i64` | a decimal `#bigint` above the signed 64-bit range | exit 101, panic, value does not fit in i64 |
| `newline-render` | the `text == ""` invariant at the newline state | exit 0, false |
| `loop-fail-eval` | the `belowThree` invariant at count 3 | exit 0, false |
| `ignored-malformed-bigint-eval` | the stripped state of a trace whose ignored key carries a malformed integer object | exit 0, true |
| `vars-omits-declared-eval` | a state carrying a declared key the `vars` array omits | exit 0, true |
| `hand-precedence-state0` | the hand-precedence fixture's two expressions, `belowOne` and `divLater`, at state 0 | exit 0, true for both |
| `hand-precedence-state1` | the same two expressions at state 1 | exit 0; `belowOne` false, `divLater` the QNT503 division-by-zero error |
| `nested-instance-eval`, `-1`, `-2` | nested instance states with their qualified variable names | exit 0, true at each state |
| `two-instance-eval`, `-1`, `-2` | two-instance states with their per-alias variable names | exit 0, true at each state |
| `const-instance-eval`, `-1`, `-2`, `-3` | instance-qualified states with the invariant reading the instance constant `C` | exit 0; false at state 0 (0 is not in `C`), true at states 1 to 3 |

The `bigint-*` records exist in pairs: the `{s,e,c}` request and a
`-normalised` request carrying the decimal form the checker forwards. The
difference between the two results is the reason the decoder normalises before
evaluation.

The two `hand-precedence-*` records are a cross-check, not the source of the
hand-verified fixture's expectation: the outcome was derived from the
specification text first, and these captures record the one-time run that
followed it. The fixture's `expected_source` stays `hand`.
