---
name: goblin-feature
description: P3: SPEC first, then land the feature in units that each end checkable.
---

# goblin-feature (P3)

1. **SPEC first.** A `*-SPEC.md` with a measured root cause and an `AC:` list, committed with
   or before the code. No code moves until it exists.
2. **Name the data shape before the code.** The shape decided late is the shape that gets
   rewritten.
3. **Land it in units that each end checkable.** Each unit ends with a measurement, not with
   "and now the next part".
4. **Write the SHA it landed at into the review note** (`goblin-pr-gate`, P7). "The reviewer
   approved this" is a claim about a moment until it names a commit.

## Verification

- Every `AC:` item has a checkable assertion: a backticked command, or a comparison operator.
- The round reports one line of measured numbers.
- The commit SHA is named.

## What this cannot see

Whether the feature was the right thing to build. That is the SPEC's job, and it is a human's
decision.
