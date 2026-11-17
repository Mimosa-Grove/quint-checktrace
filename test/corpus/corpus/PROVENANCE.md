# Corpus provenance

Authority for provenance and licensing of every corpus entry. The licence
summary in the repository's `docs/README.md` is the human summary; if the
two disagree, this file wins and that summary is a defect.

Rules:

- Every `.qnt` file under this tree has exactly one row below.
- `origin_url` and `licence` are never empty. A file that cannot be given
  both is excluded and listed under Rejected. Where an entry has no public
  source, the origin is stated as `first-party working copy, no public
  source` and its licence source is this repository's `LICENSE` (a
  first-party grant by the same author).
- `first_party_third_party` is one of `first-party`, `third-party`,
  `synthetic`. Synthetic files are written for this corpus and carry the
  AGPL-3.0-or-later licence of their origin project.
- `commit` is the commit the file was taken from. An archive copy whose
  upstream commit does not contain the file names the archive commit and
  the upstream branch state.
- `q33_1_valid` is the validity-gate result at the pinned Quint 0.33.1
  (typecheck rc 0 and parse rc 0).
- The row-per-file rule is enforced by the corpus maintenance process.

| path | origin_url | repo | commit | licence | licence_source | first_party_third_party | model | standalone | q33_1_valid |
|---|---|---|---|---|---|---|---|---|---|
| real/janet-num/specs/impl-resolution.qnt | https://github.com/jennystats/janet-num | jennystats/janet-num | b06e7d2b | AGPL-3.0-or-later | LICENSE (janet-num repo) | first-party | impl versus :num call resolution with dynamic switching | yes | yes |
| real/janet-num/specs/syspath-heal.qnt | https://github.com/jennystats/janet-num | jennystats/janet-num | b06e7d2b | AGPL-3.0-or-later | LICENSE (janet-num repo) | first-party | syspath self-heal decision table | yes | yes |
| real/janet-query/specs/catalogue-partb.qnt | https://github.com/jennystats/janet-query | jennystats/janet-query | 49d42a63 | AGPL-3.0-or-later | LICENSE (janet-query repo) | first-party | catalogue writer-identity lane | no, imports catalogue-record and catalogue-shapes | yes |
| real/janet-query/specs/catalogue-record.qnt | https://github.com/jennystats/janet-query | jennystats/janet-query | 49d42a63 | AGPL-3.0-or-later | LICENSE (janet-query repo) | first-party | catalogue writer lane and present walk | no, imports catalogue-shapes | yes |
| real/janet-query/specs/catalogue-shapes.qnt | https://github.com/jennystats/janet-query | jennystats/janet-query | 49d42a63 | AGPL-3.0-or-later | LICENSE (janet-query repo) | first-party | catalogue shape lane and key-role table | yes | yes |
| real/janet-query/specs/intersection.qnt | https://github.com/jennystats/janet-query | jennystats/janet-query | 49d42a63 | AGPL-3.0-or-later | LICENSE (janet-query repo) | first-party | registration and denial machine | yes | yes |
| real/janet-query/specs/scope-model.qnt | https://github.com/jennystats/janet-query | jennystats/janet-query | 49d42a63 | AGPL-3.0-or-later | LICENSE (janet-query repo) | first-party | reference scope machine | no, imports catalogue-record | yes |
| real/janet-rayforce/specs/ownership.qnt | https://github.com/jennystats/janet-rayforce | jennystats/janet-rayforce | 4065b3b4 | AGPL-3.0-or-later | LICENSE (janet-rayforce repo) | first-party | ownership protocol over the Rayforce C ABI | yes | yes |
| real/janet-rayforce/specs/packed-seam.qnt | first-party working copy, no public source | janet-rayforce (working copy) | 2a9a82e1 | AGPL-3.0-or-later | LICENSE (this repository, first-party grant) | first-party | packed f64 seam across the binding boundary | yes | yes |
| real/janet-stats/specs/ecdf-ks.qnt | https://github.com/jennystats/janet-stats | jennystats/janet-stats | b350d2cf | AGPL-3.0-or-later | LICENSE (janet-stats repo) | first-party | ECDF and KS test contract | yes | yes |
| real/janet-stats/specs/iterative-solver.qnt | https://github.com/jennystats/janet-stats | jennystats/janet-stats | b350d2cf | AGPL-3.0-or-later | LICENSE (janet-stats repo) | first-party | termination and error contract of iterative estimators | yes | yes |
| real/janet-stats/specs/km-logrank.qnt | https://github.com/jennystats/janet-stats | jennystats/janet-stats | b350d2cf | AGPL-3.0-or-later | LICENSE (janet-stats repo) | first-party | Kaplan-Meier and log-rank contract | yes | yes |
| real/janet-stats/specs/mc-chain.qnt | https://github.com/jennystats/janet-stats | jennystats/janet-stats | b350d2cf | AGPL-3.0-or-later | LICENSE (janet-stats repo) | first-party | MH and Gibbs bookkeeping contract | yes | yes |
| real/janet-stats/specs/perm-enumeration.qnt | https://github.com/jennystats/janet-stats | jennystats/janet-stats | b350d2cf | AGPL-3.0-or-later | LICENSE (janet-stats repo) | first-party | two-lane permutation test contract | yes | yes |
| real/janet-viz/quint/geom.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-trace.qnt line 2 (janet-viz repo has no LICENSE file) | first-party | geometry margin and placement functions | yes | yes |
| real/janet-viz/quint/ir.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-trace.qnt line 2 (janet-viz repo has no LICENSE file) | first-party | display-list IR op enumeration with properties P1-P6 | yes | yes |
| real/janet-viz/quint/surface-limb-calibration.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-limb-calibration.qnt line 2 | first-party | limb sweep instrument calibration | no, imports surface | yes |
| real/janet-viz/quint/surface-trace.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-trace.qnt line 2 | first-party | shipped surface and witness specimens | yes | yes |
| real/janet-viz/quint/surface.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-trace.qnt line 2 (janet-viz repo has no LICENSE file) | first-party | grammar surface limbs | yes | yes |
| real/janet-viz/quint/ticks.qnt | local repository, no remote configured | janet-viz | 4ee48bdd | AGPL-3.0-or-later | quint/surface-trace.qnt line 2 (janet-viz repo has no LICENSE file) | first-party | Wilkinson tick construction | yes | yes |
| real/mark-task/specs/alias_commands.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | alias name and command registry | yes | yes |
| real/mark-task/specs/atomic_write.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | atomic write phases with an inline mutant module | yes | yes |
| real/mark-task/specs/configuration.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | configuration values | yes | yes |
| real/mark-task/specs/conflict_resolution.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | task status conflict resolution | yes | yes |
| real/mark-task/specs/data_storage.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | task record storage | yes | yes |
| real/mark-task/specs/default_values.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | default status, priority, complexity and effort | yes | yes |
| real/mark-task/specs/desktop_notifications.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | due and overdue notification modes | yes | yes |
| real/mark-task/specs/interactive_mode.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | command history and responses | yes | yes |
| real/mark-task/specs/performance.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | due-window performance modes | yes | yes |
| real/mark-task/specs/recurring_tasks.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | recurrence periods and due-date rollover | yes | yes |
| real/mark-task/specs/search_functionality.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | task search over description and category | yes | yes |
| real/mark-task/specs/task_archiving.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | archive and restore tasks | yes | yes |
| real/mark-task/specs/task_attributes.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | task attribute set | yes | yes |
| real/mark-task/specs/task_counts.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | task counts by status | yes | yes |
| real/mark-task/specs/task_management.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | create, update and complete tasks | yes | yes |
| real/mark-task/specs/task_views.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | filtered task views | yes | yes |
| real/mark-task/specs/undo_functionality.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | undo stack for task edits | yes | yes |
| real/mark-task/specs/user_interface.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | interface rendering over status and priority | yes | yes |
| real/mark-task/specs/validation_error_handling.qnt | https://github.com/phillc73/mark-task | phillc73/mark-task | 721fb342 | AGPL-3.0-or-later | LICENSE (mark-task repo) | first-party | record and warning validation | yes | yes |
| real/njuggle/icon-machine.qnt | first-party working copy, no public source | njuggle (working copy) | 67d555e7 | AGPL-3.0-or-later | LICENSE (this repository, first-party grant) | first-party | pane status-icon state machine and tab aggregation | yes | yes |
| real/njuggle/tab-visibility.qnt | first-party working copy, no public source | njuggle (working copy) | 67d555e7 | AGPL-3.0-or-later | LICENSE (this repository, first-party grant) | first-party | tab visibility decision table | yes | yes |
| real/omazing/specs/game-state-evidence/constant-check.qnt | https://github.com/phillc73/OMazing | phillc73/OMazing | 469a92f5 | AGPL-3.0-or-later | LICENSE (OMazing repo) | first-party | maze constant checks against reviewed grids | no, imports ../game-state | yes |
| real/omazing/specs/game-state-evidence/properties.qnt | https://github.com/phillc73/OMazing | phillc73/OMazing | 469a92f5 | AGPL-3.0-or-later | LICENSE (OMazing repo) | first-party | P3 premise checks | no, imports ../game-state | yes |
| real/omazing/specs/game-state-evidence/transitions.qnt | https://github.com/phillc73/OMazing | phillc73/OMazing | 469a92f5 | AGPL-3.0-or-later | LICENSE (OMazing repo) | first-party | P2, P4, P5 and P6 as transition properties | no, imports ../game-state | yes |
| real/omazing/specs/game-state.qnt | https://github.com/phillc73/OMazing | phillc73/OMazing | 469a92f5 | AGPL-3.0-or-later | LICENSE (OMazing repo) | first-party | game-state movement contract | yes | yes |
| real/quint-audit/spec/qcalc.qnt | local repository, no remote configured | quint-audit | 8fc78e8 | AGPL-3.0-or-later | LICENSE (quint-audit repo) | first-party | QP001 constant classification calculus | yes | yes |
| real/quint-audit/spec/rundisc.qnt | local repository, no remote configured | quint-audit | 8fc78e8 | AGPL-3.0-or-later | LICENSE (quint-audit repo) | first-party | C6 three-state run discipline | yes | yes |
| synthetic/language-shapes.qnt | local repository, no remote configured | quint-audit | 5b2d23d5 | AGPL-3.0-or-later | LICENSE (quint-audit repo) | synthetic | higher-order operators, three-deep records, 24-constructor enum | yes | yes |
| synthetic/version-drift.qnt | local repository, no remote configured | quint-audit | 5b2d23d5 | AGPL-3.0-or-later | LICENSE (quint-audit repo) | synthetic | conditionals in actions, nested record updates, nondet bindings, map and filter | yes | yes |
| third-party/chonkybft/defs.qnt | https://raw.githubusercontent.com/matter-labs/era-consensus/5f571c435f99c08f2db2fb4460d572819229fa93/spec/protocol-spec/defs.qnt | matter-labs/era-consensus | 5f571c43 | Apache-2.0 OR MIT | third-party/chonkybft/LICENSE-APACHE and LICENSE-MIT | third-party | ChonkyBFT shared definitions | yes | yes |
| third-party/chonkybft/option.qnt | https://raw.githubusercontent.com/matter-labs/era-consensus/5f571c435f99c08f2db2fb4460d572819229fa93/spec/protocol-spec/option.qnt | matter-labs/era-consensus | 5f571c43 | Apache-2.0 OR MIT | third-party/chonkybft/LICENSE-APACHE and LICENSE-MIT | third-party | option type helpers | yes | yes |
| third-party/chonkybft/simplified/n6f1b1.qnt | https://raw.githubusercontent.com/matter-labs/era-consensus/5f571c435f99c08f2db2fb4460d572819229fa93/spec/protocol-spec/simplified/n6f1b1.qnt | matter-labs/era-consensus | 5f571c43 | Apache-2.0 OR MIT | third-party/chonkybft/LICENSE-APACHE and LICENSE-MIT | third-party | n=6, f=1 replica instance | no, imports replica | yes |
| third-party/chonkybft/simplified/replica.qnt | https://raw.githubusercontent.com/matter-labs/era-consensus/5f571c435f99c08f2db2fb4460d572819229fa93/spec/protocol-spec/simplified/replica.qnt | matter-labs/era-consensus | 5f571c43 | Apache-2.0 OR MIT | third-party/chonkybft/LICENSE-APACHE and LICENSE-MIT | third-party | ChonkyBFT simplified replica protocol | no, imports types, defs and option | yes |
| third-party/chonkybft/simplified/types.qnt | https://raw.githubusercontent.com/matter-labs/era-consensus/5f571c435f99c08f2db2fb4460d572819229fa93/spec/protocol-spec/simplified/types.qnt | matter-labs/era-consensus | 5f571c43 | Apache-2.0 OR MIT | third-party/chonkybft/LICENSE-APACHE and LICENSE-MIT | third-party | ChonkyBFT protocol types | no, imports option | yes |
| third-party/cosmwasm-to-quint/lib/BoundedUInt.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/BoundedUInt.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | bounded unsigned integer module | yes | yes |
| third-party/cosmwasm-to-quint/lib/bank.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/bank.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | bank module over cw_types | no, imports cw_types | yes |
| third-party/cosmwasm-to-quint/lib/basicSpells.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/basicSpells.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | basic CosmWasm helpers | yes | yes |
| third-party/cosmwasm-to-quint/lib/cw_types.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/cw_types.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | CosmWasm type definitions | no, imports basicSpells | yes |
| third-party/cosmwasm-to-quint/lib/cw_utils.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/cw_utils.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | CosmWasm utility definitions | no, imports cw_types | yes |
| third-party/cosmwasm-to-quint/lib/messaging.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/lib/messaging.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | CosmWasm message dispatch | no, imports cw_types, bank and basicSpells | yes |
| third-party/cosmwasm-to-quint/oaksecurity_cosmwasm_ctf_01_stubs.qnt | https://raw.githubusercontent.com/informalsystems/cosmwasm-to-quint/13222c398b9657a27cf226d461c985f80d18453d/examples/ctf-01/quint/oaksecurity_cosmwasm_ctf_01_stubs.qnt | informalsystems/cosmwasm-to-quint | 13222c39 | Apache-2.0 | third-party/cosmwasm-to-quint/LICENSE and NOTICE | third-party | generated model stubs for the CTF-01 contract | no, imports the four lib modules | yes |
| third-party/quint/DiningPhilosophers5.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/classic/distributed/DiningPhilosophers/DiningPhilosophers5.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | five-philosopher dining model | yes | yes |
| third-party/quint/Paxos.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/classic/distributed/Paxos/Paxos.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | Paxos consensus model | no, imports Voting | yes |
| third-party/quint/Voting.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/classic/distributed/Paxos/Voting.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | voting module used by Paxos | yes | yes |
| third-party/quint/bank.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/cosmos/bank/bank.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | Cosmos bank module | yes | yes |
| third-party/quint/bankTest.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/cosmos/bank/bankTest.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | run tests for the bank module | no, imports bank | yes |
| third-party/quint/two_phase_commit_modules.qnt | https://raw.githubusercontent.com/quint-co/quint/07d7a1a69c2093b5bc656caf3b5dfefa0d766cd0/examples/classic/distributed/TwoPhaseCommit/two_phase_commit_modules.qnt | quint-co/quint | 07d7a1a6 | Apache-2.0 | third-party/quint/LICENSE | third-party | two-phase commit with module parameters | yes | yes |

## Rejected

Files excluded from the corpus, with the reason.

- `third-party/chonkybft/simplified/inductive.qnt` and
  `n6f1b1_inductive.qnt`: fail the 0.33.1 gate with QNT404
  `Name 'generate' not found`. `generate` is a removed builtin; replacing
  it changes sampling semantics, which is a port, not a mechanical fix,
  so both are dropped.
- janet-query `specs/im/*.qnt` (five files): probe variants of
  `intersection.qnt`, one invariant changed per file.
- janet-query `specs/iv/*.qnt` (six files): 130-byte single-value wrappers
  around `intersection.qnt`.
- janet-viz `tmp/exp/minm*.qnt`, `probe8.qnt`, `probe9.qnt`: probe
  variants. `tmp/build/*.qnt`: scratch copies of the surface model.
- an earlier local copy of janet-query's
  `specs/catalogue-record.orig.qnt`: superseded copy of
  `catalogue-record.qnt`.
- local checkout copies of the published repos: the same bytes
  under a different checkout path, so the published-repo copy is the
  canonical row.
- mark-task `AtomicWriteMutant`: an inline mutant module inside
  `atomic_write.qnt`. The file is kept as the base model; the mutant module
  is not a separate corpus entry.
- OMazing `specs/game-state-evidence/gate-m1.qnt` through `gate-m6.qnt`,
  `mutants/*.qnt`, `tlc-*.qnt`, `probe-*.qnt`: mutants, templates and
  backend probes. `ctl-falsifiable.qnt` is a near-copy of
  `transitions.qnt` differing in one limb plus the module name.
- quint-audit `test/fixtures/specs/*.qnt`: single-expression probe
  fixtures. Probe-decoder specifications and mutants of
  `rundisc.qnt` and `qcalc.qnt`: same rule.
- two MBT fixtures copied from an unrelated checkout; the source tree does
  not record their origin commit, so they cannot be given a provenance
  row.
