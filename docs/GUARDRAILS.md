# The guard rails - the security and perf rows

`manifest/enforcement.tsv` is the machine-readable form; this is the prose for the ten rows it
gained in v0.2 (`SC-01`..`SC-09`, `PF-01`). Every one of them is **declared** in
`.gob/goblin.yaml` under `security:` and `perf:` - a stack-specific rule guessed from the
files on disk is how a matrix starts lying, so nothing here infers a stack.

## The rung ladder, and the rule for choosing a rung

    (a) lint rule / static check  >  (b) script gate  >  (c) CI job  >  (d) runtime check  >  (e) prose

The rung is chosen by **what can observe the failure**, not by what is cheapest to write, and the
rung below must be *demonstrably unable* to see it - the reason is recorded in the row's
`if_not_why` cell. Three constraints shaped the design, and all three are pre-existing:

1. **No network at verify time.** `docs/RISKS.md` K4: a network call at verify time breaks the
   offline dependency contract. So `SC-07` reads a **recorded** audit; recording is a separate,
   deliberate command (`.gob/bin/goblin-audit`). A row that needs the network is not a
   verify-time row.
2. **`enforced_by` is a closed enum** (`script`, `lint`, `gate`, `advisory`) and `check` is one of:
   a real command, the literal `advisory`, or `goblin-verify --only <ID>` for a multi-line body.
   Every row here obeys that, and `IN-03` fails the manifest otherwise.
3. **`advisory_ceiling` is 10 and the count was 8.** This design spends **one** slot (`SC-09`),
   which took the count to 9 of 10. **Corrected 2026-09-25 (AB3):** it is **10 of 10** now —
   `JG-03` took the tenth slot in W3, and the run prints `advisory 10 of ceiling 10 (0 free
   slots: the next advisory row FAILs)`. Nothing else in this lane is prose dressed as a check.

## T1 - secrets and the config surface (`SC-01`..`SC-04`)

All four are rung (a)/(b): one shell line or a small builtin, and all four are RED-able.

| row | what it proves | how it proves it |
|---|---|---|
| `SC-01` | no secret file is tracked | `git ls-files` over the `.env`/`.pem`/`.key` family (`.example`/`.sample`/`.template` excluded) |
| `SC-02` | the ignore rules cover the **whole** family | clause 1 reads `.gitignore`; clause 2 asks git's own matcher, `git check-ignore -q`, once per path - a rule that looks right but does not match still fails |
| `SC-03` | no client-visible name is secret-shaped, and no build output carries a secret literal | the `NEXT_PUBLIC_*_(SECRET\|TOKEN\|KEY\|PASSWORD\|PRIVATE)` name pattern over source, then known secret prefixes (`sk-`, `ghp_`, `AKIA`, `eyJ`) over `security.build_output` |
| `SC-04` | every cookie write carries its flags | `document.cookie =` needs `secure` + `samesite` in the same statement; `cookies().set(` / `res.cookie(` need `httpOnly` + `sameSite` |

`SC-02` ships a real control rather than being assumed, because the honest baseline is GREEN: a
fresh install writes the family into `.gitignore` (`sec_gitignore_family: yes`), and the control
proves the row would notice the day a hand edit narrows it.

**A JS-written cookie is readable by any script.** `SC-04` *reports* that; it does not fail on it.
That is a design fact about the product, not a bug, and a matrix that failed on it would be wrong
about the thing it was measuring.

## T2 - input boundaries and dependencies (`SC-05`..`SC-08`)

| row | what it proves | the limit it states |
|---|---|---|
| `SC-05` | every write route calls a validator, or is waived | it proves a validator is *called* (`safeParse\|zod\|valibot\|yup\|ajv\|superstruct\|validate(`), never that the schema is right - a schema that accepts everything passes |
| `SC-06` | a lockfile exists and is tracked | it cannot see that the lockfile is *stale* relative to `package.json`: resolving that needs the package manager, which is a deliberate network-shaped step |
| `SC-07` | the audit record exists, is dated, is fresh, and every high\|critical line is waived with its own dated reason | it cannot see an advisory the registry did not know on the day the record was taken, and it never calls the registry itself |
| `SC-08` | no dependency runs an install-time script outside the allowlist | `pnpm`/`yarn` lockfiles carry no `hasInstallScript` field, so those repos get a SKIP with that reason rather than a vacuous pass |

`SC-07` prints its waiver count on the gate line (`N high|critical line(s), W matched waiver(s), U
unwaived`), reusing `DS-02`'s annotation pattern, so **the debt is visible on every run** and the
row can pass while the debt stays loud.

`.gob/bin/goblin-audit` is the one tool in the toolchain allowed to touch the network, and it
is not a check: a human runs it, once, deliberately, and commits `.gob/audit.tsv`. Its exit
codes are part of the contract:

| exit | meaning |
|---|---|
| 0 | the record was written (clean or not) |
| 2 | usage, or no `.gob/goblin.yaml` to read `security.audit_cmd` from |
| 3 | the class declares no audit command - nothing to run |
| 4 | the declared command could not run |
| 5 | the output could not be parsed as an audit report, and it **refuses to write a record**: an empty record reads to `SC-07` as "clean", which would be a fabricated pass |

`SC-08` is the lowest-value row of the ten and the first to cut if the matrix gets heavy: it is
regression detection, not a live finding. It is in because an install hook is arbitrary code that
runs on every `npm ci`.

## T3 - the performance budget (`PF-01`, plus the ratchet)

The budget **is** `GT-04`/`GT-05`, unchanged: `ratchet.name` is the metric, `ratchet.cmd` is the
one command that produces it, `ratchet.ceiling` is the measured baseline, and `GT-05` prints
`old <n> + <delta> new = <n>` when the number rises. **No second mechanism, no new key for the
number.**

| class | metric | command | hermetic? |
|---|---|---|---|
| A - web app (Next) | total client JS bytes | `find .next/static -type f -name '*.js' -exec cat {} + \| wc -c` | yes |
| A - SPA (Vite) | bundle JS bytes | `find dist/assets -type f -name '*.js' -exec cat {} + \| wc -c` | yes |
| A - component lib | published bytes | `find dist -type f -exec cat {} + \| wc -c` | yes |
| B - service/config | own build bytes, plus host latency | `find dist -type f -exec cat {} + \| wc -c` · `curl -w '%{time_total}'` | size yes, latency **no** |
| C - game | build bytes, plus host frame time | as A · Editor run | size yes, frame time **no** |
| D, E | none declared | - | - |

`find ... -exec cat {} + | wc -c` is used rather than `du` because `du` reports block sizes and is
not deterministic across filesystems. Raw bytes are the *reported* number and are the only one
that is ratcheted: a gzip figure changes with the compressor, so it is a report, never a ceiling.

**The class-A preset ships this metric** (`client_js_bytes`), and the TODO count that used to be
the ratchet moved into a **gate** (`todo_ceiling`, `-le 160`): a shipped-software round is
supposed to move the perf number, and the TODO ceiling is a floor against decay, not the budget.
A fresh install measures `0` for a repo with no build output, so the number is honest from the
first commit and gets re-anchored deliberately.

**Re-anchoring is deliberate, never automatic.** When a round legitimately raises the number, the
operator re-runs the command, writes the new `ceiling`, and writes the matching
`perf.baseline_value`/`baseline_commit`/`measured`. `PF-01` is the row that stops "I raised the
ceiling" from silently becoming "I never measured again": a baseline whose commit does not resolve
to an ancestor of `HEAD` is a RED.

`PF-01` **skips with a reason** when the class declares no metric (`perf.metric` empty) or when no
baseline has been recorded yet - because a row that is RED on every fresh install teaches people
to ignore it. The skip names the command to run.

## What this lane cannot see

- **A local byte count is not a real user's device.** It says nothing about parse/execute time on
  a mid-range phone, a cold cache or a slow network - and nothing about what the bytes do. A
  700 KB bundle that does nothing is better than a 200 KB one that blocks the main thread.
- **Frame time, idle CPU, memory growth and latency are host gates**, named as such in
  `perf.host_gate` and in `gates:` - never hermetic ratchets.
- **A perf budget cannot see a layout thrash or a re-render per keystroke.** Only a frame-time
  measurement can, and that is a host gate.
- **No automation or audit has ever run against a real registry here.** Cost per run, and whether
  the recorded waiver set matches the real advisory set, are unmeasured; the first real
  `goblin-audit` is what produces those numbers.
- **The record's parser reads npm's JSON by field name.** A different audit tool with a different
  shape is refused (exit 5) rather than silently recorded as clean - which is the safe failure,
  but it is still a failure.
