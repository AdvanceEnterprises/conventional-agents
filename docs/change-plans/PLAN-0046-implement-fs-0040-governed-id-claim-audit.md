---
type: change-plan
role: implementer
language: markdown
status: draft
related_specs: [FS-0040]
approved_by: ""
related_adrs: [ADR-0015, ADR-0024, ADR-0026, ADR-0027, ADR-0033, ADR-0037]
touches:
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-09-30
updated: 2026-09-30
---

# PLAN-0046: Implement FS-0040 — Governed-ID claim audit

> **Template note:** this plan ships the governance package for FS-0040
> (spec + plan + index rows + CHANGELOG entry). The executable
> implementation is gated on FS-0040 reaching `status: approved` — "Do NOT
> implement unless status == approved" — and arrives as a **separate
> revision** of this plan that declares the full executable surface in
> `touches:`. Because that surface includes `ADR-0027` reserved paths, the
> routing is human-only, and **no implementation commit is written until
> the record described in §3 exists**. This matches the packaging used by
> PLAN-0043 for FS-0037 and PLAN-0042 for FS-0036.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0040
* Related ADR ID(s): ADR-0015 (tool taxonomy — report-only command is
  integration tooling, not a Category 1 gate), ADR-0024 (detection over
  prevention), ADR-0026 (recorded approval), ADR-0027 (reserved paths),
  ADR-0033 / FS-0024 (caller-relative target resolution), ADR-0037 /
  FS-0029 (executable GitHub binding layer)
* Issue / PR Reference: #179 (feature: read-only PR-claim audit), from
  #174's closing recommendation

## 2. Scope of Change

**This revision (documentation package) WILL:**

* Publish `docs/specifications/FS-0040-governed-id-claim-audit.md`
  (draft) — defining two coverage layers for the governed-ID collision
  class: local duplicate detection in `scripts/check-status.sh` across all
  three registries, and the read-only cross-PR claim audit in the GitHub
  binding.
* Publish this plan.
* Register FS-0040 and PLAN-0046 in `docs/specifications/README.md` and
  `docs/change-plans/README.md`.
* Add a CHANGELOG entry naming `FS-0040` (rule 7: an FS at
  approved-or-beyond with exported-surface interfaces — `scripts/` is
  exported — requires a consumer-framed entry; the entry is added at draft
  time as house practice, as PLAN-0042/PLAN-0043 did).

**This revision will NOT:**

* Modify `scripts/check-status.sh`, `scripts/README.md`, or any
  `integrations/` or `.github/workflows/` file — implementation is gated
  on FS-0040 approval.
* Add `test/FS-0040/` bats coverage — same gate.
* Change `cross-repo-lint.sh` check 3, the filename/id agreement check, or
  any existing gate (FS-0040 §Relationship to existing checks).

**The implementation revision (separate; not this PR) WILL** — only after
its own recorded approval exists:

* Extend `scripts/check-status.sh` with duplicate-ID detection across the
  FS / PLAN / ADR registry directories, failing with every offending file
  named (SC-1..SC-4).
* Add `integrations/github/bin/gh-pr-claim-audit.sh` — the read-only
  cross-PR claim audit (SC-5..SC-10), registered in `package.json` as
  `github:pr-claim-audit` (SC-11).
* Add the informational pull-request step to
  `.github/workflows/lint-docs.yml` (SC-12).
* Add `test/FS-0040/*.bats` covering SC-1..SC-12 with fixture-driven
  fake-`gh` doubles (no live GitHub calls), in the pattern of
  `test/FS-0029/board-audit.bats` and `test/FS-0022/gate-coverage.bats`.
* Document the extended rule in `scripts/README.md` and the new command in
  `integrations/github/README.md` (including its `reports` classification
  in the enforcement-posture table).

## 3. Approval Routing

This plan **cannot self-approve** in its implementation revision. That
revision will declare `scripts/check-status.sh`, `scripts/README.md`,
`package.json`, and `.github/workflows/lint-docs.yml` in `touches:` — all
reserved under ADR-0027 (the gate that would evaluate the change, its
entry points, and CI enforcement). Under ADR-0026 a recorded approval
covers only the `touches:` set that existed when it was given, so the
implementation revision needs its own recorded approval covering its own
set; **no implementation commit is written until that record exists**.

This draft revision ships documentation only (`touches:` is the three
docs paths above) and is safe to hold in draft.

## 4. Tests Driving This Change

* Test file(s) (implementation revision):

  * `test/FS-0040/claim-audit.bats` — SC-1..SC-4 local duplicate
    detection: injected FS duplicate fails naming both files; injected
    PLAN duplicate fails; injected ADR duplicate fails; clean corpus
    passes. Pattern: `test/FS-0022/gate-coverage.bats`
    disposable-worktree fixture (mutate → run gate → assert → restore).
  * `test/FS-0040/pr-claim-audit.bats` — SC-5..SC-12: cross-PR
    same-ID/different-path finding; default-branch collision finding;
    same-path edit emits nothing; strict/non-strict exit codes; `--json`
    shape; run-failure exit 2; read-only source assertion; registration
    and `--help`. Pattern: `test/FS-0029/board-audit.bats` fake-`gh`
    doubles with paginated GraphQL fixtures.

* Manual verification (implementation revision):

  * Inject a duplicate FS copy in a scratch worktree of this repository →
    `npm run check:status` rc≠0 naming both files (currently rc=0 — the
    regression proof).
  * Run `npm run github:pr-claim-audit` against this repository while a
    known-colliding fixture pair exists → finding lists both claiming PRs.

## 5. Rollback

Reverse the two README rows and the CHANGELOG entry; remove this plan and
`docs/specifications/FS-0040-governed-id-claim-audit.md`.
Documentation-only revision, so rollback is content-only.

## 6. Readiness Check

* [x] Issue #179 links here and carries the empirical evidence
* [x] Spec is draft (approval is the human's next act)
* [x] Scope is minimal and explicit
* [x] No code ships in this revision
