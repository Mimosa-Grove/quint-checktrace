Property: both requested invariants are accounted for, and the early stop of
one does not affect the other.

Expected result: exit 1. Two verdict rows, sorted by name: belowThree FAIL at
state index 3 with rendering { count: 3 }, and nonNegative PASS. No silent
invariant.

Reasoning: belowThree is count < 3. The recorded counts are 0, 1, 2 and 3, so
the expression is first false at index 3. nonNegative is count >= 0, which is
true at all four states; the early stop applies only to belowThree, so
nonNegative is evaluated to the end of the trace and is reported PASS. One
failure is enough for exit 1, and the summary counts one pass and one fail.
The FAIL row also records the forwarded state at index 3, {"count":
{"#bigint": "3"}, "#meta": {}}, derived from the trace's state 3 and
R21's empty forwarded #meta.
