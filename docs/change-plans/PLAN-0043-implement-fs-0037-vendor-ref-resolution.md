---
type: change-plan
role: implementer
language: bash
status: draft
related_specs: [FS-0037]
approved_by: ""
related_adrs: [ADR-0033, ADR-0027]
touches:
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-09-22
updated: 2026-09-22
---

# PLAN-0043: Implement FS-0037 — Vendor-prefixed reference resolution

> **Template note:** this plan ships the governance package for FS-0037 (spec +
> plan + index rows + CHANGELOG entry). The executable implementation is gated
> on FS-0037 reaching `status: approved` — "Do NOT implement unless status ==
> approved" — and arrives as a separate revision of this plan that declares the
> full `scripts/` + `test/` surface in `touches:`. This matches the packaging
> used by PLAN-0042 (#158) for FS-0036.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0037
* Related ADR ID(s): ADR-0033 (target resolution and configuration), ADR-0027
  (reserved paths), ADR-0030 (current-state documents)
* Issue / PR Reference: #165

## 2. Scope of Change

**This change WILL:**

* Publish `docs/specifications/FS-0037-vendor-ref-resolution.md` (draft) —
  closing the `FS-0022` §1c blind spot where `vendor/conventional-agents/`
  references are blanket-skipped before any resolution is attempted, plus the
  companion clause extending the extractor for the three exported-surface
  documents to non-backticked occurrences of the same prefix.
* Publish this plan.
* Register FS-0037 and PLAN-0043 in `docs/specifications/README.md` and
  `docs/change-plans/README.md`.
* Add a CHANGELOG entry naming `FS-0037` (rule 7: an FS at approved-or-beyond
  with exported-surface interfaces — `scripts/` is exported — requires a
  consumer-framed entry; the entry is added at draft time as house practice,
  as PLAN-0042 did).

**This change will NOT:**

* Modify `scripts/check-status.sh` or `scripts/README.md` — implementation is
  gated on FS-0037 approval.
* Add `test/FS-0037/` bats coverage — same gate.
* Touch `FS-0022` §1c's wording for documents outside the three
  exported-surface files, re-open the decision-record scope decision, or
  edit the historical vendor references inside `ADR-0006` / `ADR-0007` /
  `ADR-0039`.
* Repair the `docs/ARC42.md` phantom references recorded in `BACKLOG.md` §8.3
  /§8.4 — that is that document's own refresh.

## 3. Approval Routing

This plan **cannot self-approve**. Its revision implementing the gate will
declare `scripts/check-status.sh` and `scripts/README.md` in `touches:` —
both reserved under ADR-0027 (the check that would evaluate the change lives
in `scripts/`). Human approval is required before implementation proceeds
past the Approved checkpoint (ADR-0019: `feature` may not advance past
Approved without human approval). This draft revision ships documentation
only and is safe to hold in draft.

## 4. Tests Driving This Change

* Test file(s) (implementation revision):

  * `test/FS-0037/vendor-ref-resolution.bats` — SC-1..SC-7: phantom backticked
    prefixed ref fails; resolving prefixed ref passes; other `vendor/*` skips;
    placeholder and prose anti-example exempt; non-backticked phantom in the
    three exported-surface docs fails; non-self-check uninitialised-submodule
    exemption; `ref_exempt` honoured. Pattern: `test/FS-0022/gate-coverage.bats`
    disposable-worktree fixture (mutate → run gate → assert → restore).

* Manual verification (implementation revision):

  * Inject `vendor/conventional-agents/guidelines/NEVER-EXISTED.md` into
    `INTEGRATION.md` → gate rc≠0 (currently rc=0 — the regression proof).
  * Full local run: `npm run check:status` rc=0 on the clean tree
    (155 currently-resolving prefixed refs across the three repos produce no
    failures).

## 5. Rollback

Reverse the two README rows and the CHANGELOG entry; remove this plan and
`docs/specifications/FS-0037-vendor-ref-resolution.md`. Documentation-only
revision, so rollback is content-only.

## 6. Readiness Check

* [x] Issue #165 links here and carries the empirical evidence
* [x] Spec is draft (approval is the human's next act)
* [x] Scope is minimal and explicit
* [x] No code ships in this revision
