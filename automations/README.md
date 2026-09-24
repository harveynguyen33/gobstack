# Automations — three parts, and only one of them lives in this repo

An automation is a **card producer**, not an event daemon. It runs on a trigger, does read-only
work, and its only write is a card. A defect gets fixed by P2, reviewed by P7, on other
profiles. The three parts below are the whole design.

    producer (this repo)      a deterministic script that cannot hallucinate. Silent when
                              there is nothing to report. Costs zero tokens on a quiet run.
        |
        v
    card      (the board)     the ONLY trigger surface with a durable record and a model knob.
                              `--skill <name>` is the label (there is no --label flag),
                              `--idempotency-key` is the dedup, `--parent` is the lineage.
        |
        v
    repair    (a skill)       judgement starts here, on a different profile, under a playbook.

    P13  goblin-bugreporter   a report arrived  -> reproduce -> one fix card on proof
    P14  goblin-drift-audit   a claim disagrees with the artifact -> one repair card per repo

## Files

    automations/drift-audit.sh        A-02's producer. No network. Silent when clean.
    automations/bugreporter-intake.sh A-01's intake validator (schema check -> card, or a
                                      refusal card with no assignee).
    automations/report.schema.tsv     the intake schema, machine-readable.
    templates/report.yaml.tmpl        the report template the producer copies.

The installer writes these into the target at `.goblin/automations/`, so the target is
self-contained and `IN-02`/`SK-02` hash them like every other installed file.

## The fleet steps goblin-stack cannot do (it writes nothing outside its target)

    cp <target>/.goblin/automations/drift-audit.sh       ~/.hermes/scripts/
    cp <target>/.goblin/automations/bugreporter-intake.sh ~/.hermes/scripts/
    hermes cron create "0 9 * * 1" --name "Drift audit - weekly" \
        --no-agent --script drift-audit.sh --deliver discord:<notification-channel>
    hermes skills trust <target>

A cron script must resolve inside the profile's `scripts/` directory, which is why that copy
step exists rather than an installer write. **Hook configuration is per-profile**: a hook
declared only in the root `config.yaml` never fires for a worker running under another
profile, so any notification hook must be declared in every profile that can be an assignee.

## Kill switches, and the order to turn one on

1. `hermes cron pause <id>` — stops the producer. Immediate, total, no agent involved.
2. `kanban.dispatch_profiles` excluding the automation's profile — fail-closed by construction.
3. The producer's own state file (`.goblin/automations/<name>.state`, `enabled: false`).

Turn on A-02 first: no agent sits inside its producer. Run it by hand
(`bash .goblin/automations/drift-audit.sh --dry-run`) and read the record before scheduling it.
Only after that run is clean does A-01's trigger get enabled.
