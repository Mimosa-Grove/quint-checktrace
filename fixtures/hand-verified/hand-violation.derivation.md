Property: the invariant belowThree is false at one recorded state.

Expected result: exit 1. One verdict row, belowThree FAIL at state index 3,
with the violating state rendered as { count: 3 }.

Reasoning: belowThree is count < 3. The trace records count 0, 1, 2 and 3 at
indexes 0 to 3. The expression is true at indexes 0, 1 and 2, and false at
index 3, because 3 is not less than 3. The first violating state is
therefore index 3, and the report names only the first one. The rendering
sorts the single field count and renders the integer in decimal, giving
{ count: 3 }. The expected row also records the forwarded state at that
index, {"count": {"#bigint": "3"}, "#meta": {}}, derived from the
trace's state 3 and R21's empty forwarded #meta.
