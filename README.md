# quint-checktrace

quint-checktrace checks that a software system's actual behaviour
matches its formal [Quint](https://quint.sh/) specification, by comparing recorded
execution traces against what the spec says should happen. The
benefit: Quint models are only paper promises until something
connects them to real code - this tool closes that gap, so bugs where
the implementation silently diverges from the verified design get
caught automatically instead of by luck. To use it, you run your
system (or Quint itself) to produce a trace file, point
quint-checktrace at the trace plus the spec, and it reports pass,
fail, or error - with a human-readable report and machine-checkable
records that work in CI.

Status: the specification, the three JSON schemas and the fixture
corpus are complete, and the checker implements the decoder, the
evaluator client, the human and machine reports, and the corpus gate.

## Quick start

A check takes a specification, a trace and the invariants to test:

```sh
quint-checktrace ledger.qnt out/ledger.itf.json \
  --main=Ledger --invariant=nonNegative --invariant=balanceBounded
```

A passing check prints one row per invariant and a summary line:

```text
── Trace check: ledger.qnt (module Ledger) ─────────────────────
   trace: out/ledger.itf.json  source=ledger.qnt
   states=4  status=ok
   Quint 0.33.1  evaluator .../quint_evaluator sha256=0123456789ab  mode checktrace
   The verdict covers the recorded states only; it is not a proof.

Invariants
   balanceBounded     ✓  PASS - no violation observed in this trace
   nonNegative        ✓  PASS - no violation observed in this trace

Summary: 2 pass, 0 fail (exit 0)
```

A violation exits 1 and quotes the failing state:

```text
── Trace check: two-inv.qnt (module TwoInv) ───────────────────
   trace: out/two-inv.itf.json  source=violation/two-inv.qnt
   states=4  status=violation
   Quint 0.33.1  evaluator .../quint_evaluator sha256=0123456789ab  mode checktrace
   The verdict covers the recorded states only; it is not a proof.

Invariants
   belowThree         ✗  FAIL at state 3: { count: 3 }
   positive           ✓  PASS - no violation observed in this trace

Summary: 1 pass, 1 fail (exit 1)
```

The gate mode replays whole sets of checks at once instead of a single
check:

```sh
quint-checktrace --gate test/corpus/corpus test/corpus/manifest.json \
  test/corpus/hand-verified
```

## What is a trace?

A trace records a system's states step by step: one snapshot of the
tracked variables per state. The format is the [Informal Trace
Format](https://apalache-mc.org/docs/adr/015adr-trace.html) (ITF)
defined by the Apalache project - plain JSON, one object per state -
with writer libraries available in [Python, Rust, Go and
TypeScript](https://apalache-mc.org/docs/adr/015adr-trace.html). By
convention these files end in `.itf.json`.

## How a check works

A check runs one specification against one trace. The trace supplies
the recorded states; the specification supplies the invariants. For
every recorded state, quint-checktrace evaluates each named invariant
with Quint's own evaluator, against that state's variable values, and
reports pass or fail per invariant.

It is not a comparison of two traces: no second trace is needed, and
the specification is never executed to produce one. If you want the
spec's own behaviour as a reference, simulate it (next section) - but
the verdict comes from the invariants, at the states you recorded.

## Where traces come from

Three sources, one of which is yours:

- **The specification itself.** Quint's simulator writes ITF
  directly:

  ```sh
  quint run ledger.qnt --main=Ledger --max-samples=10 \
    --out-itf=out/ledger.itf.json
  ```

  Checking a simulated trace is the sanity check: the simulator and
  the checker must agree.

- **Apalache.** A verification run writes its counterexample with
  `--out-itf`. Checking a counterexample is the pointed question: is
  this failure reproducible against the spec?

- **Your system.** The implementation under test does not emit ITF on
  its own; you record its states. At the points worth checking, dump
  the tracked variables as ITF JSON - a state is one object mapping
  variable names to values, so a recorder is small, and the ITF
  libraries above handle the format. This is the trace that matters:
  your program's actual behaviour, measured against the spec.

Quint itself can simulate, model-check, and display such traces - but
nothing in the Quint toolchain decides whether a given, already
recorded trace obeys the specification. That decision is what
quint-checktrace adds.

## What is a Quint specification?

A Quint specification is a precise description of what a system is
allowed to do, written in a language a model checker can reason about.
If you have verified your design in Quint, the specification is your
statement of intended behaviour. quint-checktrace checks that the
implementation, as recorded in traces, stayed within that statement.

## Where are the specifications?

The specifications this tool checks against are yours - the `.qnt`
file you pass on the command line. The repository's own published
contract has three layers:

- `docs/*.schema.json` - the machine-checkable contract for the
  three JSON artefacts: what a check's report must contain, what the
  corpus manifest must contain, and what a derivation record must
  contain.
- `fixtures/` - the specification-plus-trace pairs with expected
  outcomes that pin the checker's behaviour case by case (see The
  fixtures and the corpus, below).
- `test/corpus/` - real-world Quint specifications harvested from
  published packages and third-party projects, each with a recorded
  verdict (the acceptance evidence, below).

Design documents are maintained outside the repository and do not
ship.

## What pass, fail and error mean

- **Pass (exit 0).** Every requested invariant passed on every
  recorded state. A PASS row says exactly `no violation observed in
  this trace`; a PASS covers the recorded states only, never the
  specification as a proof.
- **Fail (exit 1).** At least one requested invariant failed. The FAIL
  row names the invariant, the state index and a rendering of the
  violating state, for example `FAIL at state 3: { count: 3 }`.
- **Error (exit 2).** The check did not complete: a usage error, a
  missing or mismatched Quint, a missing evaluator, a parse failure, a
  decode refusal, an unresolved invariant, an evaluation error, a
  timeout, or an internal error. Exit 2 is never a specification
  violation, and exit 1 is never a could-not-run.

Every exit 2 diagnostic is one plain-text line on standard error that
names the stage reached: `usage`, `quint`, `evaluator`, `parse`,
`decode`, `resolve`, `evaluate` or `internal`. A decode refusal also
names its refusal class and, where one exists, its JSON path or byte
offset. The human report ends with one summary line of the exact form
`Summary: <n> pass, <n> fail (exit <n>)`; when the trace's recorded
source differs from the supplied specification path, the summary ends
with the token `source-mismatch`.

`--format=json` replaces the human report with one JSON object
carrying the same verdicts, the full 64-character sha256 digests and
the forwarded state values. That object validates against
`docs/report-schema.json`, which ships in this repository together with
`docs/manifest.schema.json` and `docs/derivation-record.schema.json`.

## The fixtures and the corpus

Two different sets of evidence live in the repository.

`fixtures/` is the regression net: 125 edge fixtures and 8
hand-verified fixtures, 134 specification files in all. Each fixture
pairs a specification and a trace with a complete expected outcome,
so a decoder, report or evaluator change that alters a verdict is
caught by comparison rather than by review.

`test/corpus/` is the acceptance evidence: real Quint specifications
harvested from published packages and third-party projects, each
paired with a recorded verdict. The corpus exists to prove that the
checker agrees with recorded outcomes on specifications it did not
shape - the difference between passing your own tests and working on
the Quint that exists in the wild.

The gate above replays the recorded corpus and the hand-verified
fixtures, prints a counts line and the marker `== END OF GATE RUN ==`
on every exit, and exits 1 on any disagreement. A missing marker is a
crashed gate, never a pass.

## Install and requirements

The checker is built from OCaml 5.3 sources with `dune build` and
installed as `quint-checktrace`. At run time it requires Quint 0.33.1
on `PATH` and the Rust evaluator v0.7.1, whose binary is accepted by
sha256 for the pinned platform (linux-x86_64). The version pair is part
of the release contract.

The repository toolchain is OCaml and Quint. The corpus generator is
`maintenance/build_fixtures.exe`; run it with `--root <directory>` to
write the fixture tree under that directory. It recomputes each
report's trace digest from the bytes it writes. The corpus gate's
derivation script is `maintenance/derive_registry.exe`; its recipe is in
`docs/README.md`. Run the gates with:

```sh
./run_tests.sh
```

That command builds the checker and the generator, regenerates the
fixture corpus in a scratch copy and diffs it against the committed
tree, parses every fixture specification with Quint 0.33.1, and runs
the test suite and the seed-controlled property runner. It prints
`RESULT: pass` or `RESULT: fail` and exits non-zero on failure.

The formatting and lint gates are ocamlformat 0.29.0 and Zanuda 2.0.0:

```sh
dune build @fmt --auto-promote   # promote formatting once
dune build @fmt                  # must then be clean
zanuda -dir .                    # advisory-level lint; exits 0 when clean
```

## Repository layout

- `docs/` - the three JSON schemas, the corpus derivation recipe
  (`docs/README.md`), and the benchmark record
  (`docs/benchmarks.md`).
- `fixtures/` and `test/` - the regression net and the corpus
  described above.
- `lib/`, `bin/`, `maintenance/` - the checker, its entry point and
  the corpus tooling.

The checker accepts `--deadline=<seconds>`. A decode that exceeds the
budget stops and reports expiry instead of running on, so a hostile
trace cannot hold the process open. `docs/benchmarks.md` records the
measured behaviour of that budget on named hardware; it is evidence,
not a test.

## Licence

AGPL-3.0-or-later. The full licence text is in `LICENSE`.

## AI assistance

The code in this repository was written with the assistance of a large language model and reviewed by its maintainer.
