# RE-PLAYBOOK - P15 `goblin-re-mobile`

The P15 procedure: one shipped Android build, understood as **facts for study**, with a
reproducible, hash-manifested corpus. This document is the procedure; `docs/FLOWS.md` carries
the summary, and the four `RC-` rows in `manifest/enforcement.tsv` are what make its
verification column measurable rather than aspirational. Two houses: the **lab repo** holds
scripts, notes and hash manifests only; the **quarantine** (inside the sandbox) holds every
extracted byte and never enters a repo.

## The fences, and what enforces each

| fence | what bites |
|---|---|
| An owned or free build only - never a cracked or pirated APK | stated here; S1 is the hard fence, and `RC-04` records what was acquired and from where |
| One dedicated sandbox, never the host | S0 preflight; nothing in this row can see the host's filesystem, so the preflight is the fence |
| No extracted byte is ever tracked in a repo | `RC-03` - the lab repo's tracked tree, allowlist plus payload-hash clause |
| Nothing expression-shaped (art, text) leaves the quarantine | `RC-01` - the exact-hash gate over `security: build_output:` at release time |
| A manifest that cannot pass vacuously | `RC-02` - the `reference-manifest/1` schema |

## The steps

### S0 - preflight

The sandbox exists and is the one the fences describe: a disposable LXC or VM, never the
host. Confirm it before touching a binary. **Produces:** a live sandbox with a quarantine
root and a lab repo inside it. **Enforced by:** S0 itself - no `RC-` row inspects the host.

### S1 - acquire

An owned or free build only: a store listing with a **published hash** (md5 or sha256).
Cracked or pirated APKs are a hard fence - not a judgment call, a stop. **Produces:** the
APK file inside the sandbox. **Enforced by:** `RC-04`, the acquisition record.

### S2 - provenance

Verify the download against the store's published md5/sha256 **before anything else touches
it**. **Produces:** the measured digest, written into the acquisition record with the
target slug + version and the source store. **Enforced by:** `RC-04` - a header naming
target + version + store + checksum, and a 64-hex token equal to the apk row's sha256.

### S3 - triage

The engine verdict, cheapest test first. Marker rules over the archive listing: `.so`
libraries - `lib/*/libunity.so` = Unity IL2CPP (with `libil2cpp.so`), `libue4.so` = Unreal,
`libcocos2d*.so` = Cocos, `libgodot*` = Godot; `assets/bin/Data/Managed` + `libmono` =
Unity Mono; `global-metadata.dat` = Unity IL2CPP; no `.so` and packed assets in `assets/`
= custom Java/Dalvik engine. **Produces:** the verdict line in the triage note.
**Enforced by:** nothing mechanised - the verdict is a note, and `RC-03` sees only that
the note lives under `notes/`.

### S4 - static decompile

apktool/jadx into the **quarantine**, never into any repo. **Produces:** the decompiled
tree under the sandbox quarantine root. **Enforced by:** `RC-03` - the lab allowlist has
no `build/`, `dist/`, or decompiled tree.

### S5 - carve the containers

A carver written **from decompiled evidence, not guessed**: read the loader in the
decompiled tree, recover the transform (key, offset, container layout), reimplement, and
only then run it. The precedent: Kairosoft's whole-file-XOR `.dat` containers, whose
loader was found at `kairo/android/util/g.java` and whose 16-byte XOR key came from
`b.a.a()` in the decompiled tree - the carver was written from that evidence, and its
parse was cross-checked against size tables *inside* each container (16/16 consistent).
**Produces:** extracted payloads under the quarantine root, and the carver script in the
lab repo (`scripts/`). **Enforced by:** `RC-03` - the script is tracked, the payloads are
not.

### S6 - manifest the corpus

sha256 of **every** extracted payload into `manifests/*.sha256`, with a header naming
target + version + source store + anchor, and the **apk row itself** - this is what
`RC-04` reads, and what `RC-01`'s build-time gate consumes as `reference_manifest:`.
**Produces:** the manifest. **Enforced by:** `RC-04` (the header + the apk row), `RC-02`
(the `reference-manifest/1` schema so `RC-01` cannot pass vacuously - `entries` non-empty,
`entry_count` honest, 64-hex digests, byte counts).

### S7 - dossier

Facts and numbers, never expression: measurements, counts, class/method citations
(`file:line`), and the digests already in the manifest. **No extracted art, no copied
text** - an asset's dimensions and its hash are facts; the asset itself is expression and
stays in the quarantine. **Produces:** `notes/<date>-<target>.md`. **Enforced by:**
`RC-03` (the note is tracked; nothing it quotes may be a tracked payload byte) and, at
release time, `RC-01` (any corpus hash that shows up in a shipping build fails it).

### S8 - runtime analysis, deferred by design

Frida hooking needs a device or emulator and an owned build, and static facts come first:
a hash-manifested corpus and a written dossier are reproducible; a hook session is not.
S8 is **not** cut - it is deferred, and a future pass may pick it up with its own fence
(the device, the owned-build check, its own quarantine).

### S9 - retention / teardown

The corpus lives only in the sandbox quarantine; the lab repo keeps scripts, notes and
hashes only. **Delete or keep is a recorded decision** - recorded where the dossier is,
with the date. **Enforced by:** `RC-03`, re-run after any teardown: the tracked tree must
still be scripts/notes/manifests/docs only, and no tracked file may hash to a manifest row.

## What the `RC-` rows bite

| row | gate | bites at |
|---|---|---|
| `RC-01` | build output | S7 / release: no file in the shipping tree matches a corpus hash (four clauses: skip-when-empty, fail-when-absent, the hash clause, and the manifest itself must not ship) |
| `RC-02` | the manifest | S6: the manifest's shape - so `RC-01` cannot pass vacuously |
| `RC-03` | the lab tree | S4-S9: every tracked path is on the allowlist and no tracked byte equals a payload |
| `RC-04` | the manifest header | S1-S2: the acquisition record exists and names target, version, store, checksum |

## First real run - 2026-09-27, Oh!Edo Towns Lite

- **Target:** `edotownsL-1.0.9.apk`, package `net.kairosoft.android.edotownsL`, version
  1.0.9 (versionCode 10), 6,119,826 bytes, md5 `23974f8582359aa32eac30ad42a7744e`,
  acquired from Aptoide (`pool.apk.aptoide.com`) - a free listing with a published md5.
- **Sandbox:** LXC 217 `re-lab`; quarantine root `/opt/re-lab/refs/edotownsL-1.0.9/`.
- **Verdict (S3):** Java/Dalvik, **custom Kairosoft `.dat` containers** - no engine
  `.so` matched; 16 `.dat` files in `assets/`, with `xls.dat` the design-data suspect
  (it turned out to be 3 localisation text entries, not balance data - the dossier
  records the measurement, not the hope).
- **S5 precedent:** the carver (`scripts/karve-dat.py`) written from the decompiled
  loader, not guessed; 312 payloads extracted, 16/16 containers parse-consistent.
- **Lab repo:** `/home/harvey/projects/re-lab` - `scripts/triage-apk.sh`,
  `scripts/karve-dat.py`, `manifests/edotownsL-1.0.9.sha256`,
  `notes/2026-09-27-edotowns-lite-triage.md`.

## Verification

- The corpus manifest verifies `sha256sum -c` **where the corpus lives** (in the sandbox,
  against the anchor the manifest header names).
- `goblin-verify --only RC-01` / `RC-02` / `RC-03` / `RC-04` return the exits their rows
  define - an exact hash inside the build output, a weak manifest and a tracked payload
  each fail the build.
- Every negative control NC-1..NC-6 was shown RED and then restored: NC-1/NC-2 under
  `RC-01` (a payload, then the manifest itself, inside the build output), NC-3 under
  `RC-02` (`entries` truncated to `[]`, with the pair-proving `RC-01`-stays-GREEN half),
  NC-4 under `RC-01` (the declared manifest file deleted), NC-5/NC-6 under `RC-03`
  (a payload git-added under an allowed path, then a tracked path outside the
  allowlist). `tests/t-verify-red.sh` is the file that runs them.

## What this cannot see

- **A re-encoded, resized or recoloured asset** passes `RC-01`'s exact-hash gate - the
  gate is sha256 equality, and a byte that differs is a different byte.
- **Copied text inside a shipped string** is level 3 and invisible to the hash gate.
- **A weak manifest authored by hand** is `RC-02`'s problem only if it is *malformed* -
  a well-formed manifest of the wrong bytes is exactly what the schema cannot judge
  (`LIMITS.md` #28, the weakened-input defect; `installed.json` is unsigned, #18).
- **Nothing here proves a fact is CORRECT** - only that it is traceable to the corpus.
  The dossier's measurements are as good as the commands that produced them, and a
  misread loader produces a confidently wrong carver. `RC-04`, the weakest of the four,
  proves the acquisition record *exists*, never that the number came from the store.
