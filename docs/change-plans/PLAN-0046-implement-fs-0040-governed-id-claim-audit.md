---
type: change-plan
role: implementer
language: markdown
status: approved
related_specs: [FS-0040]
approved_by: "Joey Clark <administrator@ajoeofalltrades.dev>"
related_adrs: [ADR-0015, ADR-0024, ADR-0026, ADR-0027, ADR-0033, ADR-0037]
touches:
  - scripts/check-status.sh
  - scripts/README.md
  - integrations/github/bin/gh-pr-claim-audit.sh
  - integrations/github/README.md
  - package.json
  - .github/workflows/lint-docs.yml
  - test/FS-0040/**
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-09-30
updated: 2026-10-03
---

# PLAN-0046: Implement FS-0040 — Governed-ID claim and citation audit

> **Template note:** this plan declares the full implementation surface up
> front. The executable work is gated on FS-0040 reaching `status: approved` —
> "Do NOT implement unless status == approved" — and on the recorded approval
> described in §3. The same implementation revision covers the #179 claim
> audit and #186's event-driven stale-citation complement.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0040
* Related ADR ID(s): ADR-0015 (tool taxonomy — report-only command is
  integration tooling, not a Category 1 gate), ADR-0024 (detection over
  prevention), ADR-0026 (recorded approval), ADR-0027 (reserved paths),
  ADR-0033 / FS-0024 (caller-relative target resolution), ADR-0037 /
  FS-0029 (executable GitHub binding layer)
* Issue / PR Reference: #179 (read-only PR-claim audit) and #186 (stale
  governed-ID citations after pre-merge renumbering), from #174's and #186's
  closing recommendations

## 2. Scope of Change

**This revision WILL:**

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

**Before the recorded approval, this branch will NOT:**

* Modify the executable or workflow surfaces listed in `touches:`.
* Change `cross-repo-lint.sh` check 3, the filename/id agreement check, or
  any existing gate (FS-0040 §Relationship to existing checks).

**After the recorded approval, the implementation revision WILL**:

* Extend `scripts/check-status.sh` with duplicate-ID detection across the
  FS / PLAN / ADR registry directories, failing with every offending file
  named (SC-1..SC-4).
* Add `integrations/github/bin/gh-pr-claim-audit.sh` — the read-only
  cross-PR claim and citation audit (SC-5..SC-10, SC-13..SC-17), registered in
  `package.json` as `github:pr-claim-audit` (SC-11).
* Add the informational pull-request step to
  `.github/workflows/lint-docs.yml` (SC-12).
* Add `test/FS-0040/*.bats` covering SC-1..SC-17 with fixture-driven
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

The initial commit on this branch ships the documents and full declared
boundary only. No implementation commit is written until the approval record
exists.

## 4. Tests Driving This Change

* Test file(s) (implementation revision):

  * `test/FS-0040/claim-audit.bats` — SC-1..SC-4 local duplicate
    detection: injected FS duplicate fails naming both files; injected
    PLAN duplicate fails; injected ADR duplicate fails; clean corpus
    passes. Pattern: `test/FS-0022/gate-coverage.bats`
    disposable-worktree fixture (mutate → run gate → assert → restore).
  * `test/FS-0040/pr-claim-audit.bats` — SC-5..SC-17: cross-PR
    same-ID/different-path finding; default-branch collision finding;
    same-path edit emits nothing; strict/non-strict exit codes; `--json`
    shape; run-failure exit 2; read-only source assertion; citation drift
    after an open-PR rename; registration and `--help`. Pattern:
    `test/FS-0029/board-audit.bats` fake-`gh`
    doubles with paginated GraphQL fixtures.

* Manual verification (implementation revision):

  * Inject a duplicate FS copy in a scratch worktree of this repository →
    `npm run check:status` rc≠0 naming both files (currently rc=0 — the
    regression proof).
  * `npm run github:pr-claim-audit` against a fixture with a known claim
    collision and an open-PR rename/citation pair → both finding classes are
    emitted without a write.

## 5. Rollback

Remove the new command, duplicate rule, fixtures, documentation, index rows,
and CHANGELOG entry. Existing IDs, branches, and pull requests are never
mutated by the audit, so rollback is content-only.

## 6. Readiness Check

* [x] Issue #179 links here and carries the empirical evidence
* [x] Spec is approved; recorded approval is in the latest commit
* [x] Scope is minimal and explicit
* [x] Full implementation surface is declared before approval
* [x] No implementation commit precedes the recorded approval
