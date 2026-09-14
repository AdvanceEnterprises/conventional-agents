---
type: change-plan
role: implementer
language: markdown
status: draft
related_specs: [FS-0035]
approved_by: ""
related_adrs: [ADR-0042]
touches:
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - docs/decisions/README.md
  - CHANGELOG.md
created: 2026-09-14
updated: 2026-09-14
---

# PLAN-0041: Implement FS-0035 — Portable flow-report read-model

## Approval Routing

This plan **cannot self-approve**. Its `touches:` set includes
`docs/decisions/README.md`, which per ADR-0027 is a reserved path a PLAN may
never self-approve. Human approval required before implementation proceeds
past the Approved checkpoint (ADR-0019: `feature` may not advance past
Approved without human approval).

## Summary

Implements the portable flow-report read-model contract defined by FS-0035:

1. **ADR-0042** (proposed) — the architecture decision: the flow-report is a
   read-only visibility profile, not a seventh ADR-0024 capability and not a
   work-item binding; the Git-native work-item decision is deferred and
   recorded separately.
2. **FS-0035** (draft) — the contract spec with mandatory envelope, mandatory
   governance profile, optional advisory planning profile, lossless
   unset/invalid rendering, evidence-backed findings, traceability semantics,
   and a consumer-conformance statement rule.
3. Index rows in `docs/specifications/README.md`,
   `docs/change-plans/README.md`, and `docs/decisions/README.md`; a CHANGELOG
   entry.

## Verification

- `npm run check:status` — all status checks (FS/PLAN/ADR consistency, index
  sync, cross-repo lint) pass.
- `npm run lint:docs` (markdownlint) passes for the new documents.
- `npm run lint:adrs` / `npm run lint:specs` pass for the new ADR and FS.

## Out of scope (this plan)

- Any executable report generator, npm script, or CI wiring — the contract is
  doc-only until the human approves; the generator is a future work item
  under the same FS (SC-6 example outputs ship with the implementation once
  approved).
- The Git-native work-item binding decision (issue #146's Git-native
  work-item decision acceptance bullet; out of scope for FS-0035).

## Open Questions

- Whether the report contract should also ship a validator
  (e.g. `scripts/check-flow-report.sh`) at implementation time — deferred to
  the approved-implementation work item.
