# docs/ - schemas, the deadline benchmark, derivation and the corpus gate

This directory carries the three JSON schemas, the deadline benchmark record
and the recipes that make the repository's checked-in evidence reproducible:
how the fixture corpus is generated, how the corpus gate's registry is
derived, and how the gate consumes it.

## The three schemas

- `report-schema.json` - the machine report `--format=json` prints on exit 0
  and exit 1. An exit-2 run prints a plain-text diagnostic instead and never
  a report document.
- `manifest.schema.json` - the corpus gate's manifest, the reviewed list of
  corpus entries the gate replays. A row names a specification path relative
  to the corpus tree root, a main module and, per invariant, whether the gate
  derives a replay triple from it or records its exclusion.
- `derivation-record.schema.json` - one derivation record per replay triple:
  the recorded Quint command, both output streams, the exit code, and the
  sha256 digests of the specification and every file it transitively imports.

The test suite holds these schemas to a committed set of expected
accept/refuse pairs (`test/schema-cases.json`). A schema change re-derives
that set: add the new accept and refuse documents to the case file, one entry
per case, and run `dune runtest`. Every rule the schemas express appears as
one accepting document and at least one refusing mutation of it.

## The fixture corpus and its generator

`fixtures/` holds 125 edge fixtures and 8 hand-verified fixtures, 134
specification files in all, each pairing a specification and a trace with a
complete expected outcome. The tree is generated: `maintenance/build_fixtures`
(a dune executable built by `dune build`) writes the edge fixtures and the
hand-verified set deterministically from its committed table:

```sh
dune build maintenance/build_fixtures.exe
_build/default/maintenance/build_fixtures.exe --root <scratch-directory>
diff -r fixtures <scratch-directory>/fixtures
```

The diff must be empty. The generator's scope is the edge fixtures and the
hand-verified set: the evaluator probes under `fixtures/probes/`, the ten
reused producer traces under `fixtures/traces/` and the two READMEs are
curated additions outside it. Each report-facing `trace_sha256` is computed
from the bytes the generator writes.

The hand-verified expected files state the property, the expected result and
the hand reasoning in a derivation document beside them; the gate reads each
expected file's `category` and requires all six categories to be present.

## The corpus gate registry

`--gate` replays two instruments against the checker itself: the corpus
registry under `test/corpus/` and the hand-verified fixture set. The registry
has four parts:

- `test/corpus/corpus/` - the corpus of Quint specifications: 67 entries,
  47 first-party, 18 third-party and 2 synthetic, with
  `test/corpus/corpus/PROVENANCE.md` as the authority for the origin, commit
  and licence of every entry.
- `test/corpus/manifest.json` - the reviewed manifest: one row per runnable
  main of each corpus entry, each row naming its invariants.
- `test/corpus/records/` - one derivation record per
  `(path, main, invariant)` triple, recording the Quint run that produced the
  expected verdict.
- `test/corpus/traces/` - the trace each derivation record's `--out-itf`
  names.

`maintenance/derive_registry` (a dune executable built by `dune build`)
regenerates the records and traces from the committed manifest:

```sh
dune build maintenance/derive_registry.exe
_build/default/maintenance/derive_registry.exe \
  --corpus test/corpus/corpus --manifest test/corpus/manifest.json
```

It runs the pinned Quint from the corpus tree root (so each trace's
`#meta.source` records the corpus-relative path the gate compares), resolves
the import digest set from Quint's own source map, and writes each record
with the complete stdout and stderr of the recorded command. The recorded
traces carry Quint's creation timestamp, so a re-derivation refreshes those
bytes; the verdicts, exit codes and digests are stable, and the gate's
agreement check reads only those.

The gate run itself:

```sh
_build/default/bin/main.exe --gate test/corpus/corpus \
  test/corpus/manifest.json test/corpus/hand-verified
```

It prints a counts line and the marker `== END OF GATE RUN ==` on every exit,
and exits 0 only when every replayed triple and every hand-verified fixture
agrees with its recorded outcome.

### Curating the manifest

A manifest row is added by hand, then derived: run the specification's module
list through `quint parse`, take every main that declares its own `init` and
`step`, choose one or more boolean `val` declarations of that main as its
invariants, and record `--max-steps` and `--seed` with the row. A main whose
invariants cannot run (for example a module whose constants carry no values)
carries the exclusion reason in the row instead. The derivation script then
regenerates the records and traces for every derive invariant.

## The deadline benchmark record

`benchmarks.md` records how long the decoder's deadline machinery takes
on one machine: the per-node cost of a flat decode, and the refusal time and
node count of wide-member-name decodes under a one-second deadline. The
numbers come from `maintenance/bench_deadline`, which reports and never
fails. The suite's deadline cells assert mechanism properties and carry no
durations.

## Repository layout notes

The published layout keeps the corpus gate's manifest, records, traces and
hand-verified set together under `test/corpus/`, and the three schemas in
this directory. Two documents a separate layout might place here, a
decoder-contract document and a corpus-gate document, are stated in place
instead: the decoder's input contract in `fixtures/README.md` and this file,
the corpus-gate contract in this file. The derivation script
ships as a maintenance executable (`maintenance/derive_registry.ml`) rather
than as a file inside the registry, so it builds with the rest of the tree
and needs no extra toolchain.

The corpus is shared verification material: it may later move to its own
repository, and until then it ships here in full with its provenance record.

## Licence

The corpus entries carry their upstream licences, recorded per entry in
`test/corpus/corpus/PROVENANCE.md`; the third-party trees keep their licence
files beside the specifications. Everything else in this repository is
AGPL-3.0-or-later; the full licence text is in `LICENSE`.
