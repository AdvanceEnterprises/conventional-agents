---
type: change-plan
role: implementer
language: bash
status: implemented
related_specs: [FS-0028]
approved_by: ""
related_adrs: []
touches:
  - scripts/check-status.sh
  - scripts/README.md
  - docs/decisions/README.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - test/FS-0028/adr-supersession-chain.bats
  - CHANGELOG.md
created: 2026-09-01
updated: 2026-09-08
---

# PLAN-0028: Implement FS-0028 — ADR Supersession Chain Gate

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0028
* Related ADR ID(s): none (new capability; fills the standing proactive-check
  gap #3, "ADR chain completeness", originating from issue #108)
* Issue / PR Reference: #108, implemented by **PR #109 (merged 2026-09-06)** — statuses reconciled post-merge by the maintenance tick (issue #125).

## 2. Scope of Change

**This change WILL:**

* Add **rule 5b — ADR supersession chain** to `scripts/check-status.sh`,
  enforcing FS-0028's three obligations:
  1. An ADR at `status: superseded` with `superseded_by:` `null`/absent fails,
     naming the ADR.
  2. Every non-null `superseded_by:` id must resolve to an existing ADR file
     (matched by front-matter `id:`, tolerating suffixed filenames); a
     dangling id fails, naming both the ADR and the id.
  3. A non-null `superseded_by:` on an ADR whose status is not `superseded`
     fails, naming the ADR.
  * Field parsing handles the three shapes the template/README allow: `null`
    (empty), a single inline id, and a YAML list (inline `[ADR-00XX, ADR-00YY]`
    or indented list entries starting with a dash). Extraction is awk
    front-matter-scoped
    (first `---` block only), matching the script's existing
    `get_field`/`get_list_field` conventions; Bash 3.2-compatible.
* Document rule 5b in `scripts/README.md` (new numbered check, mirroring the
  existing "What it checks" entries) and add a one-line note to
  `docs/decisions/README.md` §5.
* Add `test/FS-0028/adr-supersession-chain.bats` covering: missing replacement
  on a superseded ADR, dangling replacement id, non-superseded ADR declaring a
  replacement, and a well-formed chain passing (single id + list shapes).
* Register FS-0028 and PLAN-0028 in `docs/specifications/README.md` and
  `docs/change-plans/README.md`.
* Add a CHANGELOG entry naming FS-0028 (exported-surface gate per rule 7).

**This change WILL NOT:**

* Alter any existing rule or gate behavior in check-status.sh.
* Enforce the replacement ADR's prose back-link (review judgment).
* Extend the gate to FS/PLAN `supersedes:`/`superseded_by:` vocabulary.
* Touch `package.json` or CI workflows (rule 5b runs inside the existing
  `check-status` job and npm script).

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0028/adr-supersession-chain.bats` — bats suite asserting the
    missing-replacement failure, the dangling-id failure, the
    non-superseded-declaring failure, and the well-formed chain passing.

* Manual verification:

  * `bash -n scripts/check-status.sh`
  * `npm run check:status` — all status checks passed (clean corpus + README
    indexes synced)
  * `npm run lint:docs` — 0 issues

## 4. Implementation Steps

1. Insert rule 5b into `scripts/check-status.sh` between rule 5 (ADR
   structural completeness) and rule 6 (PLAN touches: containment).
2. Update `scripts/README.md` "What it checks" with the rule 5b entry.
3. Add the §5 note to `docs/decisions/README.md`.
4. Write `test/FS-0028/adr-supersession-chain.bats` (fixture ADRs in a
   temp-created directory under `docs/decisions/`, backed up and restored in
   teardown, mirroring the gate-coverage suite's mutate-run-restore pattern).
5. Register FS-0028/PLAN-0028 in both README indexes.
6. Run local checks (Section 5).
7. `CHANGELOG.md`: add an FS-0028 entry under Unreleased.
8. Push the branch, open a draft PR referencing #108.

## 5. Verification

* All success criteria in FS-0028 pass.
* `npm run check:status` reports all status checks passed.
* `npm run lint:docs` reports 0 issues.
* The bats suite passes where bats is available; the mutate-run-restore tests
  are written to be runnable in CI.

## 6. Rollout

* Shipped in **PR #109 (merged 2026-09-06)**; the governing FS/PLAN pair
  statuses were reconciled post-merge by the maintenance tick (issue #125).
* No rollout risk: the gate is additive inside an existing check, the corpus
  is already compliant (37/37 `superseded_by: null`), and consumers who vendor
  the framework adopt it automatically when they run the vendored
  check-status.sh (FS-0024/ADR-0033).
