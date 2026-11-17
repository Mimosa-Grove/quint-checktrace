Property: an invariant whose expression reads an unbound constant cannot be
evaluated, so the run is a could-not-run rather than a violation.

Expected result: exit 2 at stage evaluate. No verdict rows are printed; the
invocation's only invariant, atC, is expected silent. The diagnostic names
atC, state 0 and the Quint error code QNT500.

Reasoning: C is a constant with no default and no instance binding. The
constant is therefore unbound in the main module, and Quint reports the same
condition as QNT500 for an equivalent run. The checker resolves constants
from the parsed model and forwards the invariant expression to the
evaluator; an expression that reads an unbound constant produces an error
result, and an error result is never a verdict. The failure order places
evaluate after decode, so the diagnostic names stage evaluate. A could-not-run
is exit 2 and is never a specification violation.
