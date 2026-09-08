---
type: change-plan
role: implementer
language: bash
status: draft
related_specs: [FS-0031]
approved_by: ""
related_adrs: []
touches:
  - scripts/bench-run.sh
  - benchmark/task-card.schema.json
  - benchmark/task-cards/pilot-001.md
  - test/FS-0031/bench-harness.bats
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - scripts/README.md
  - package.json
  - CHANGELOG.md
created: 2026-09-07
updated: 2026-09-07
---

# PLAN-0037: Implement FS-0031 — Governed-agent benchmark harness

## Approval Routing

This plan **cannot self-approve**. Its `touches:` set includes `package.json`
and `scripts/README.md`, which per ADR-0027 are reserved paths a PLAN may never
self-approve. Human approval required before implementation proceeds past the
Approved checkpoint (ADR-0019: `feature` may not advance past Approved without
human approval).

## Summary

Implements the reproducible benchmark harness defined by FS-0031:

1. `scripts/bench-run.sh` — bash runner: validates the task card against the
   schema, sets up a disposable worktree from the card's pinned base commit,
   runs the condition's driver command with a captured action log, and emits a
   JSON report with separate `functional` / `governance` / `evidence` /
   `overhead` / `failures` sections.
2. `benchmark/task-card.schema.json` — versioned v1 schema (jq-validatable).
3. `benchmark/task-cards/pilot-001.md` — the first shipped task card: a
   governed consumer task with an escalation scenario and an adversarial
   instruction (SC-5).
4. `test/FS-0031/bench-harness.bats` — bats coverage for SC-1..SC-6 using
   mock drivers (no live model calls).
5. Index rows in `docs/specifications/README.md` and
   `docs/change-plans/README.md`, a `scripts/README.md` entry, the
   `bench:run` npm script, and a CHANGELOG entry.

## Implementation Notes

- The runner is a Category 1 governance gate script per ADR-0015: lives under
  `scripts/`, registered in `package.json`, documented in `scripts/README.md`.
- Schema validation uses `jq` (already a dev dependency of the framework's
  check scripts) — no new runtime dependencies.
- The runner never executes the task in the framework's own checkout; it
  always clones/worktrees the pinned base commit into a disposable directory
  under `${TMPDIR:-/tmp}`.
- Driver commands are arbitrary shell commands supplied by the caller (e.g.
  `bash driver-baseline.sh`); the harness captures stdout/stderr and the
  driver's exit code, and treats a non-zero driver exit as task failure, not
  harness failure.

## Verification

- `npm run check:status` passes (FS/PLAN pairing, README sync, interfaces).
- `npm test` passes (bats suite, including the new FS-0031 suite).
- `npm run bench:run -- benchmark/task-cards/pilot-001.md baseline` runs
  end-to-end with a mock driver and produces a valid JSON report.
