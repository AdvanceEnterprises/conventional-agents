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

> **Template note:** this plan intentionally departs from the
> `templates/core/change-plan.md` section shell (it is a governance package:
> an FS/PLAN/ADR trio plus index rows, no code). The template's numbered
> sections are mapped to the house headings below so a template-keyed lint
> rule can still parse it.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0036
* Related ADR ID(s): ADR-0043
* Issue / PR Reference: #145 (GitHub PR #158)

## 2. Scope of Change

**This change WILL:**

* Publish ADR-0043 (proposed) — planning fields are binding policy, not
  framework state; the authority matrix; flow-report boundary inheritance.
* Publish FS-0036 (draft) — field semantics, the iteration scheduling
  contract, the UNSET-only Priority backfill mapping, the read-only `--flow`
  report, and bats test criteria.
* Add index rows in `docs/specifications/README.md`,
  `docs/change-plans/README.md`, and `docs/decisions/README.md`; add a
  CHANGELOG entry.

**This change will NOT:**

* Touch `integrations/github/README.md`, `integrations/github/bin/gh-board-audit.sh`,
  `config/project.example.yml`, instance metadata, or `test/` — executable
  implementation is gated on FS-0036 approval ("Do NOT implement unless
  status == approved").

## 3. Approval Routing

This plan **cannot self-approve**. Its `touches:` set includes
`docs/decisions/README.md`, which per ADR-0027 is a reserved path a PLAN may
never self-approve. Human approval required before implementation proceeds
past the Approved checkpoint (ADR-0019: `feature` may not advance past
Approved without human approval).

## 4. Verification

* `npm run check:status` — all status checks (FS/PLAN/ADR consistency, index
  sync, cross-repo lint) pass.
* `npm run lint:docs` (markdownlint) passes for the new documents.
* `npm run lint:adrs` / `npm run lint:specs` pass for the new ADR and FS.

## 5. Rollback

Reverse the index rows and CHANGELOG entry; remove the three documents. No
code ships under this plan, so rollback is content-only. The FS-0036 spec's
own wording stays authoritative for what later implementation may do.

## 6. Out of scope (this plan)

* Any executable `--flow` mode, npm script, or CI wiring — the read-only
  flow report is a future implementation step under the same FS once
  approved (SC-5).
* Instance metadata edits (`config/project.example.yml` or
  `pack-protocol/config/boards/*.yml`) — the authority mapping is
  documented here; instance field identifiers/options ship with the
  approved implementation.

## 7. Open Questions

* Should the UNSET-Priority backfill mapping be a hard default or opt-in
  per consumer? (Proposal: default-with-opt-out, recorded in instance
  metadata; human decides at approval.)
* Does the pull-forward rule (SC-4) belong in the core binding or in the
  consumer's continuous-flow policy? (ADR-0043 says policy stays out of
  core; the FS currently places the *mechanism* of pull-forward in the
  binding and the *decision to use it* with the consumer.)
