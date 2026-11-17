Property: the invariant positive is false at the initial recorded state.

Expected result: exit 1. One verdict row, positive FAIL at state index 0,
with the violating state rendered as { count: 0 }.

Reasoning: positive is count > 0. State 0 carries count 0, and 0 is not
greater than 0, so the invariant is false at the first state. The checker
evaluates state 0 like every other recorded state, records the FAIL there and
stops evaluating that invariant, because the earliest witness is the verdict.
The first violating state is index 0. The expected row also records the
forwarded state at that index, {"count": {"#bigint": "0"}, "#meta":
{}}, derived from the trace's state 0 and R21's empty forwarded #meta.
