---
name: goblin-re-mobile
description: P15: understand one shipped Android build as facts for study - triage, carve, manifest, dossier.
---

# goblin-re-mobile (P15)

Use when one shipped Android build must be understood as facts for study, with a
reproducible, hash-manifested corpus. The full procedure is `docs/RE-PLAYBOOK.md`; the
steps:

1. **S0 preflight.** The dedicated sandbox exists and is the one the fences describe - a
   disposable LXC/VM, never the host.
2. **S1 acquire.** Owned or free builds only, from a store listing with a published hash.
   A cracked or pirated APK is a hard fence - a stop, not a judgment call.
3. **S2 provenance.** Verify the download against the store's published md5/sha256 before
   anything else touches it; record it in the acquisition record.
4. **S3 triage.** The engine verdict, cheapest test first: `.so` markers
   (`lib/*/libunity.so` + `global-metadata.dat` = Unity IL2CPP, `libue4.so` = Unreal,
   `libcocos2d*.so` = Cocos, `libgodot*` = Godot); no `.so` plus packed assets = custom
   Java engine.
5. **S4 static decompile.** apktool/jadx into the quarantine, never into any repo.
6. **S5 carve.** A carver written from decompiled evidence, never guessed - find the
   loader, recover the transform, reimplement, cross-check against the container's own
   size tables (the Kairosoft `.dat` precedent).
7. **S6 manifest.** sha256 of every extracted payload into `manifests/*.sha256`, header
   naming target + version + source store + anchor, plus the apk row itself.
8. **S7 dossier.** Facts and numbers, never expression: measurements, counts,
   class/method citations. No extracted art, no copied text.
9. **S8 runtime analysis.** Deferred by design: frida hooking needs a device/emulator and
   an owned build; static facts first.
10. **S9 retention/teardown.** The corpus lives only in the sandbox quarantine; the lab
    repo keeps scripts, notes and hashes only. Delete or keep is a recorded decision.

## Verification

- The corpus manifest verifies `sha256sum -c` where the corpus lives.
- `goblin-verify --only RC-01` / `RC-02` / `RC-03` / `RC-04` return the exits their rows
  define - an exact hash inside the build output, a weak manifest and a tracked payload
  each fail the build.
- Every negative control NC-1..NC-6 was shown RED and then restored.

## What this cannot see

- A re-encoded or resized asset passes `RC-01`'s exact-hash gate (level 2); copied text
  inside a shipped string is level 3.
- A weak manifest authored by hand is `RC-02`'s problem only if malformed.
- Nothing here proves a fact is CORRECT - only that it is traceable to the corpus.
