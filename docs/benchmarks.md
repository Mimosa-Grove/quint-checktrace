# Deadline benchmark

The deadline mechanism is a shipping feature (`--deadline`); this file
records its measured behaviour. A record, not a gate. The values below
are what one machine measured. The
test suite's deadline cells assert mechanism properties (one deadline check
per visited node, expiry at the first check past the deadline) and carry no
durations, so nothing in the suite depends on these numbers and no run fails
because a machine is slow.

## What the deadline does

`--deadline` bounds a whole run in seconds. Every value node the decoder
visits reads the clock, so an expiry inside one value is reported at stage
`decode` within one node's work. The tick costs one clock read per node; a
counter sampled every k nodes would multiply that bound by k.

## Method

The cells run from `maintenance/bench_deadline`, which times the decode call
with `Unix.gettimeofday` around it and prints the elapsed time, the nodes
visited and the per-node cost. Each cell is one run: no average, no
discarded warm-up, no pass/fail.

- Flat list: 4,000,000 single-character elements in one state, decoded and
  type-checked with no expiry. This is the per-node cost of a decode whose
  values are small.
- Wide name: 4,002 nodes under a single member name of 4 MiB and of 16 MiB,
  walked with a 1 s deadline. Each node builds a path string from the whole
  member name, so the per-node cost is the name length, not the node shape.
  The refusal time is the deadline plus the node in flight.

## Machine

x86_64, 4 vCPU, Intel Core Processor (Haswell, no TSX, IBRS), Linux
6.12.111, dune 3.24.2 under an OCaml 5 switch, 2026-11-17.

## Recorded run

| cell | elapsed | nodes visited | per node |
|---|---|---|---|
| flat list, 4,000,000 elements | 1.698 s | 8,000,002 | 212 ns |
| wide name 4 MiB, 4,002 nodes, 1 s deadline | 1.000 s | 968 | 1.033 ms |
| wide name 16 MiB, 4,002 nodes, 1 s deadline | 1.003 s | 296 | 3.389 ms |

Both wide cells reported stage `decode`, class 0, checkpoint "during the
value descent". An earlier calibration measured a clock read at 44 ns per
node; the flat-list cell above measures 212 ns per node for the whole typed
descent, clock read included, so the tick is the smaller part of the
per-node work. The same one-second cells were recorded at 1.012 s (4 MiB)
and 1.017 s (16 MiB) in an earlier run of the same shape.

## Retired measured-control cell

The suite once carried a measured-control deadline test. It derived its own
deadline as 80 percent of a control run's elapsed time over a
6,000,000-element trace and asserted the expiry stage against it, so both the
input and the expectation were wall-clock derived.

Recorded observations of that cell: the group passed alone in 28.1 s, and the
same cell failed inside a 152-run concurrent sweep. No third run was taken;
the cell was deleted rather than skipped or retried. The replacement cells
assert node counts against a scripted clock and carry no duration.

## End-to-end pinned cells

The suite runs the checker binary against wide-name traces at a 10 s
deadline: 100,000 nodes at 4 MiB and 40,002 nodes at 16 MiB. At the per-node
costs above that is roughly 103 s and 136 s of work against a 10 s deadline,
so the refusal holds under any load and keeps a wide margin against a faster
machine. Recorded on the same machine: exit 2 at 10.043 s (4 MiB) and
10.046 s (16 MiB), stage `decode`, the same value-descent checkpoint.

The deadline also bounds the specification parse, which is why these cells
take 10 s rather than the smallest legal value: at a 1 s deadline the parse
allowance is a fraction of a second and the refusal can land at stage
`parse` instead, which would pin a different property.

## Reproduction

```sh
dune build maintenance/bench_deadline.exe
_build/default/maintenance/bench_deadline.exe
```

The suite cells are in the descent and taxonomy groups of `dune runtest`.
Values move with the machine; the record's purpose is the shape of the
result (a wide-name decode refuses within one node's work of its deadline,
and the per-node cost scales with the path length), not the values.
