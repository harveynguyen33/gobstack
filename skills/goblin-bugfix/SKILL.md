---
name: goblin-bugfix
description: P2: reproduce a defect, fix its measured root cause, prove absence with a control.
---

# goblin-bugfix (P2)

1. **Reproduce it yourself**, with the exact command, before touching anything. A bug you did
   not reproduce is a bug you will not fix.
2. **State the root cause with a measurement.** Never "should be" and never "probably". Paste
   the command and its output that shows the cause.
3. **Fix the root, not the symptom.** A guard added at the call site of a wrong value is a
   symptom fix; the wrong value is the bug.
4. **Prove absence on the same surface, with a negative control.** The repro command fails
   before and passes after. Then revert the fix, confirm the repro fails again, restore.

## Verification

- The repro fails before and passes after, on the *same* command.
- A unit test shows branch behaviour, not bug absence. Do not report a green suite as proof
  the bug is gone; report the repro.
- If the defect also exists in a sibling project, say so and do not silently fix it there.

## What this cannot see

Bugs whose only symptom is a human noticing something looks wrong.
