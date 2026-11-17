Property: a failure recorded for one invariant does not mask an evaluation
error for another invariant at the same state.

Expected result: exit 2 at stage evaluate, naming divLater and state 1. No
verdict rows are printed; both invariants are expected silent.

Reasoning: belowOne is count < 1. At state 0 count is 0, so belowOne is true.
divLater is 10 / (1 - count) > -100. At state 0 the divisor is 1, so the value
is 10 and the comparison is true; the invariant passes at state 0 and stays
active at state 1. At state 1 count is 1, so belowOne is false and is recorded
as FAIL at index 1. Every invariant is evaluated at every recorded state, and
the checker sends one call per state carrying every invariant still active at
that state, so the state-1 call carries belowOne and divLater together. In that
call divLater's divisor is 0, and division by zero is an evaluation error. An
evaluation error in any evaluation the checker performs makes the run exit 2,
so the run stops there. An exit-2 outcome is the exit code and the named stage
with no verdict rows; the belowOne FAIL at state 1 is part of the reasoning,
not an expected row.

Re-derivation from the specification text: at state 0 the divisor 1 - count is
1, so divLater is 10 > -100 and true; belowOne is 0 < 1 and true. At state 1
belowOne is 1 < 1 and false, so belowOne is recorded FAIL at index 1; divLater
has not failed, so R23's early stop does not apply to it and it stays active.
In the state-1 call divLater's divisor is 0, and division by zero is an
evaluation error. R31 makes an evaluation error in any performed evaluation
fatal: the whole run exits 2, so the completed FAIL does not mask it. This
expectation was derived from the specification text; the two expressions
were then run once through the pinned evaluator as a cross-check, and the
captures fixtures/probes/hand-precedence-state0.out and
fixtures/probes/hand-precedence-state1.out record the matching results (true
at state 0; false with QNT503 at state 1).
