Property: a later evaluation error for an invariant already recorded FAIL
at an earlier state does not turn the run into exit 2.

Expected result: exit 1. Two verdict rows sorted by name: nonNegative PASS,
and zeroDiv FAIL at state index 0 with rendering { count: 0 } and the
forwarded state { count: 0 } plus the empty #meta object.

Reasoning: the trace records count 0, 1 and 2 at indexes 0 to 2. zeroDiv
is 10 / (1 - count) < 0. At state 0 the divisor is 1, the quotient is 10 and
the comparison is false, so zeroDiv FAILs at index 0. R23's early stop then
ends zeroDiv: it is not evaluated at states 1 and 2. At state 1 the divisor
would be 0, which would be an evaluation error; that evaluation is never
performed, and the early-stop rule (R23, R31) places a state at which an
invariant is not evaluated because its FAIL was already recorded outside the
exit-2 scope.
nonNegative is count >= 0, true at all three states and evaluated through
state 2, so it PASSes. The report therefore carries one FAIL and one PASS and
the run exits 1.

Cross-check, performed after the hand derivation and not used to derive it: the
state-0 expressions were evaluated once through the pinned evaluator, which
returned true for nonNegative and false for zeroDiv, and the state-1
evaluation of zeroDiv returned the division-by-zero error. The expected outcome
below was fixed before that run and is unchanged.
