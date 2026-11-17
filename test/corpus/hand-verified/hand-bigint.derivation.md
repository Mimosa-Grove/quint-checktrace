Property: the Rust {s,e,c} integer form denotes the i64 maximum, so the
equality against the decimal literal is true.

Expected result: exit 0. One verdict row, atMax PASS.

Reasoning: the object has s equal to 1, e equal to 18 and two chunks, 92233
and 72036854775807. The stored width is the leading chunk's digits plus 14 per
non-leading chunk, which is 5 + 14 = 19 digits, and e + 1 is 19, so the width
rule holds. The decimal text is the leading chunk followed by the second chunk
padded to 14 digits: 9223372036854775807. That value is the largest signed
64-bit integer, so it is inside the evaluator's range, and the normalised
state carries the decimal #bigint form. The invariant atMax compares x with
the literal 9223372036854775807, and the two are equal, so the state passes.
