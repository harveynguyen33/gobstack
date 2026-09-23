---
name: goblin-bootstrap
description: P8: adopt goblin-stack in a repo - classify, install, verify, then the first round.
---

# goblin-bootstrap (P8)

Use when adopting goblin-stack in a repo, or starting one.

1. **Classify the project A-E.** The class selects which parts are required, optional or off;
   it is not a stringency level.
2. **`goblin-install --target <dir> --class <x>`**
3. **`goblin-verify`** — a fresh install is not automatically green. The class's required
   parts that only a round can produce (a first review, a real gate) are reported as FAIL, and
   that list is the repo's first-step list, not a defect.
4. **Fix `.gitignore` BEFORE any `git init`.** A credentials file already in the tree is
   committed by the first `git add -A` and is then in history forever.
5. **First HANDOFF, first SPEC, first check script** — in that order, each independently
   useful.

## Verification

- `goblin-verify` exit 0, and the created-file list matches `.goblin/installed.json`.
- A repo with no gate declares one and records its first measured numbers.
- `.gitignore` is verified before the first commit, not after.

## What this cannot see

Whether the class you chose matches how the project actually ships. Re-classify when it does
not; the installer records the class and `CL-01` checks the parts against it.
