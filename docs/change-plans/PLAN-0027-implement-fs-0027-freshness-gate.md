---
type: change-plan
role: implementer
language: bash
status: draft
related_specs: [FS-0027]
approved_by: ""
related_adrs: []
touches:
  - scripts/check-freshness.sh
  - package.json
  - scripts/README.md
  - .github/workflows/lint-docs.yml
  - workflows/*.md
  - guidelines/**/*.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
created: 2026-08-29
updated: 2026-08-29
---

# PLAN-0027: Implement FS-0027 — Workflow and Guideline Doc Freshness Gate

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0027
* Related ADR ID(s): none (new capability; pattern precedent is feral-fleet PR #127)
* Issue / PR Reference: #94

## 2. Scope of Change

**This change WILL:**

* Add `scripts/check-freshness.sh` — a freshness gate with two rules:
  * **Hard:** every governed doc under `workflows/` and `guidelines/**` (excluding
    `**/README.md`) must carry an `updated: YYYY-MM-DD` front-matter field; exit
    non-zero with the offending files otherwise.
  * **Soft:** docs whose `updated:` date exceeds the threshold (default 90 days,
    `DOC_STALE_DAYS` override, validated as non-negative integer) are reported
    as staleness candidates but do not fail the run.
* Register `npm run check:freshness` in `package.json`.
* Add a `check-freshness` job to `.github/workflows/lint-docs.yml` (push + PR),
  mirroring the `check-status` job shape.
* Backfill `updated:` front matter on all 7 workflow docs and 10 guideline docs
  using each file's **last commit date** (real last modification, not the gate's
  introduction date — the field must continue to mean "last actually modified").
* Document the gate in `scripts/README.md` and register FS-0027/PLAN-0027 in
  both README indexes.

**This change WILL NOT:**

* Automatically refresh doc content or transition docs to `status: stale`.
* Extend the gate beyond `workflows/` and `guidelines/` (docs/, skills/, etc.
  keep their existing conventions).
* Alter check-status.sh, lint targets, or any existing gate behavior.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0027/freshness-gate.bats` — bats suite asserting the hard rule
    (missing field, invalid date, prose-only occurrence not accepted), the soft
    rule (stale report format), `DOC_STALE_DAYS` validation, README exclusion,
    recursive guidelines coverage, and corpus-green after backfill.

* Manual verification:

  * `bash -n scripts/check-freshness.sh`
  * `npm run check:freshness` — exit 0, no STALE lines after backfill
  * `npm run check:status` — all status checks passed (README indexes synced)
  * `npm run lint:docs` — 0 issues (new files + frontmatter additions)
  * `npm test` — all bats suites pass, including the new FS-0027 suite

## 4. Implementation Steps

1. Write `scripts/check-freshness.sh` (awk-based front-matter extraction limited
   to the first `---` block, Bash 3.2-compatible, no associative arrays — the
   same technique feral-fleet PR #127 uses).
2. Register the npm script in `package.json`.
3. Add the CI job to `.github/workflows/lint-docs.yml`.
4. Backfill `updated:` front matter on governed docs: for each file, `git log -1
   --format=%ad --date=short` of trunk, prepend a front-matter block containing
   `updated: <date>` (plus `type:`/`id:` where the file is a governed document
   type; plain `updated:` only where the file has no type). Keep the change
   minimal — the gate needs `updated:`; do not restructure existing docs.
5. Write `test/FS-0027/freshness-gate.bats`.
6. Update `scripts/README.md` (new gate section), `docs/specifications/README.md`
   and `docs/change-plans/README.md` indexes.
7. Run local checks (Section 5).

## 5. Verification

* All success criteria in FS-0027 pass.
* `npm run check:status` reports all status checks passed.
* `npm run lint:docs` reports 0 issues.
* `npm test` passes all suites.

## 6. Rollout

* No rollout risk: the gate is additive, CI-only on a new job, and the corpus is
  backfilled in the same change so the gate goes green immediately.
* The governing FS/PLAN pair (FS-0027/PLAN-0027) is authored in the same change
  as the implementation (PR #95) and must be approved before merge.
