---
type: change-plan
role: implementer
language: markdown
status: draft
related_specs: [FS-0036]
approved_by: ""
related_adrs: [ADR-0043]
touches:
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - docs/decisions/README.md
  - CHANGELOG.md
created: 2026-09-16
updated: 2026-09-16
---

# PLAN-0042: Implement FS-0036 — Planning-field conventions for the GitHub binding

## Approval Routing

This plan **cannot self-approve**. Its `touches:` set includes
`docs/decisions/README.md`, which per ADR-0027 is a reserved path a PLAN may
never self-approve. Human approval required before implementation proceeds
past the Approved checkpoint (ADR-0019: `feature` may not advance past
Approved without human approval).

## Summary

Implements the planning-field conventions defined by FS-0036 for the GitHub
binding:

1. **ADR-0043** (proposed) — the architecture decision: planning fields
   (Priority/Iteration/Milestone) are binding policy, not framework state;
   the authority matrix (human primary, agent read/recommend, three
   sanctioned idempotent+attributable agent writes); the flow-report
   boundary is inherited from ADR-0042.
2. **FS-0036** (draft) — the contract spec covering field semantics and the
   cross-repository Milestone limitation, the authority matrix and evidence
   requirement, the UNSET-only Priority backfill mapping, the iteration
   scheduling contract (active-iteration computation, roll-forward,
   pull-forward, config-exhaustion warning), the read-only `--flow` report,
   and bats test coverage.
3. Index rows in `docs/specifications/README.md`,
   `docs/change-plans/README.md`, and `docs/decisions/README.md`; a
   CHANGELOG entry.

This draft package intentionally does NOT yet touch
`integrations/github/README.md`, `integrations/github/bin/gh-board-audit.sh`,
or `test/` — implementation of those interface areas is gated on FS-0036
approval ("Do NOT implement unless status == approved").

## Verification

- `npm run check:status` — all status checks (FS/PLAN/ADR consistency, index
  sync, cross-repo lint) pass.
- `npm run lint:docs` (markdownlint) passes for the new documents.
- `npm run lint:adrs` / `npm run lint:specs` pass for the new ADR and FS.

## Out of scope (this plan)

- Any executable `--flow` mode, npm script, or CI wiring — the read-only
  flow report is a future implementation step under the same FS once
  approved (SC-5).
- Instance metadata edits (`config/project.example.yml` or
  `pack-protocol/config/boards/*.yml`) — the authority mapping is
  documented here; instance field identifiers/options ship with the
  approved implementation.

## Open Questions

- Should the UNSET-Priority backfill mapping be a hard default or opt-in
  per consumer? (Proposal: default-with-opt-out, recorded in instance
  metadata; human decides at approval.)
- Does the pull-forward rule (SC-4) belong in the core binding or in the
  consumer's continuous-flow policy? (ADR-0043 says policy stays out of
  core; the FS currently places the *mechanism* of pull-forward in the
  binding and the *decision to use it* with the consumer.)
