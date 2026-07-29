---

type: change-plan
role: implementer
language: bash
status: draft
related_specs: [FS-0022]
related_adrs: [ADR-0008, ADR-0015, ADR-0027, ADR-0030]
touches:
  - scripts/check-status.sh
  - scripts/README.md
  - package.json
  - .github/workflows/lint-docs.yml
  - test/FS-0022/gate-coverage.bats
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - docs/decisions/ADR-0013-multi-model-session-coordination.md
  - docs/decisions/ADR-0014-background-task-governance.md
created: 2026-07-28
updated: 2026-07-28

---

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0022
* Related ADR ID(s): ADR-0008, ADR-0015, ADR-0027, ADR-0030
* Issue / PR Reference: PR #71

## 2. Scope of Change

**This change WILL:**

* Extend `check-status.sh` to validate the ADR index against ADR files —
  presence, title, and status, in both directions.
* Extend the same title/status comparison to the FS and PLAN indexes.
* Check ADR structural completeness, including the Validation section.
* Check that every path a governed document names resolves.
* **Remediate what the new checks find** — see §5a. FS-0022 defers this to
  PLAN work and this is that plan.
* Add the PLAN self-approval check: `touches:` containment against the
  governing FS's `interfaces:`, plus the reserved-path set.
* Add a CI-only job implementing ADR-0030 rule 3.
* Widen lint coverage to every directory containing governed markdown.
* Create `scripts/README.md` documenting every check.
* Add `npm test` and a CI job that executes the `bats` suites.

**This change will NOT:**

* Rewrite `check-status.sh`. Existing FS/PLAN checks are untouched.
* Change any rule being enforced. FS-0022 §Non-Goals.
* Lint `docs/orchestration/multi-model-pilot-001/`.
* Add enforcement for convention-only rules (ADR-0013, ADR-0019,
  ADR-0020, ADR-0026).
* Modify the *content* of any ADR or FS beyond adding missing required
  sections and correcting dangling paths. No decision, rationale, driver,
  option, or consequence changes.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0022/gate-coverage.bats`

* Target test(s), one per FS-0022 success criterion:

  * `test_adr_index__title_mismatch_fails`
  * `test_adr_index__status_mismatch_fails`
  * `test_adr_index__missing_row_fails`
  * `test_adr_index__orphan_row_fails`
  * `test_plan_touches__outside_interfaces_fails`
  * `test_plan_touches__reserved_path_fails`
  * `test_plan_touches__absent_field_fails`
  * `test_lint__covered_directory_violation_fails`
  * `test_lint__orchestration_exempt_passes`
  * `test_npm_test__runs_all_suites`
  * `test_npm_test__missing_bats_fails_loudly`
  * `test_scripts_readme__documents_every_check`

Rule 3 (§3 of the spec) is CI-only and has no bats coverage; it is
verified by the two-PR manual check in §8.

## 4. Files to Be Modified

* `scripts/check-status.sh`
* `scripts/README.md` (new)
* `package.json`
* `.github/workflows/lint-docs.yml`
* `test/FS-0022/gate-coverage.bats` (new)
* `docs/specifications/README.md` — index title regeneration (§5a)
* `docs/change-plans/README.md` — index title regeneration (§5a)
* `docs/decisions/ADR-0013-multi-model-session-coordination.md` — add
  Validation section (§5a)
* `docs/decisions/ADR-0014-background-task-governance.md` — add Validation
  section (§5a)

Deliberately **not** listed, because §5a escalates rather than modifies
them: `docs/decisions/ADR-0015-*.md`, and the seven documents referencing
`roles/ROLE_CONTRACT.md`. A plan that declared them in `touches:` would be
claiming authority it is not exercising.

## 5. Implementation Steps (High-Level)

1. Write the bats suite first, against the current script. Every test
   fails; that is the starting condition.
2. Add ADR index validation to `check-status.sh`, reusing the existing
   `check_readme_sync` shape rather than a parallel implementation.
3. Add the PLAN `touches:` check: resolve each PLAN's governing FS via
   `related_specs`, compare `touches:` against that FS's `interfaces:`,
   then test the reserved-path set. Report the offending path and the
   rule it broke.
4. Add `npm test` invoking `bats` across `test/`, failing with an install
   hint when the binary is absent.
5. Widen the lint globs in `package.json` and `lint-docs.yml`. Confirm the
   orchestration exemption survives by running lint against a
   deliberately malformed file there.
6. Add the CI job for rule 3: for each ADR in the PR diff, parse its
   `## Links` for paths under the current-state directories, and require
   at least one to appear in the same diff.
7. Add a CI job running `npm test`.
8. Write `scripts/README.md` covering every check — existing and new —
   with purpose, when it runs, and what a failure means.
9. Update FS-0022 and this PLAN to `implemented` in the completing PR.

## 5a. Remediation — drift the new checks will find

Audited before this plan was written, so the implementer knows the size of
the failure set rather than discovering it.

**FS index titles — 15 of 22 rows.** Abbreviated rather than fabricated,
unlike the ADR index this PR already corrected. Regenerate every row from
front matter.

**ADR structural completeness — three ADRs.** `ADR-0013`, `ADR-0014`, and
`ADR-0015` have no Validation section, which `docs/decisions/README.md` §2
requires before acceptance.

`ADR-0013` and `ADR-0014` are `proposed`; adding one is ordinary drafting.

**`ADR-0015` is `accepted` and needs a human decision**, not an implementer
judgment. The ADR README permits only Status updates and typo, link, or
formatting fixes on an accepted ADR. Adding a required section is either a
permitted compliance fix or a content change, and this plan does not decide
which. Escalate. If it is a content change, the remedy is a new ADR
superseding it, not an edit — and that is a materially larger piece of work
than this plan carries. **Do not edit it and hope.** This PR already made
that mistake once on this exact document.

**Dangling `roles/ROLE_CONTRACT.md` references — seven documents.**
`PLAN-0017` deleted that file as a byte-identical duplicate of
`guidelines/ROLE_CONTRACT.md` and left every reference standing.
`INTEGRATION.md` alone names it eleven times, once as precedence level 2,
"cannot be weakened."

`roles/README.md` now describes `roles/` as a customization hook that
"starts as an empty directory", so the deletion was intended and the
references are the defect. Repointing them is not mechanical: `README.md`
says `roles/ROLE_CONTRACT.md` "is the project-customizable copy. Start from
the template in `guidelines/`", which under the current model is backwards.
Each of the seven needs reading, and `INTEGRATION.md`'s precedence table
needs a decision about what occupies level 2. **Escalate rather than
find-and-replace.**

Documents in `docs/specifications/` and `docs/change-plans/` that reference
the file historically — FS-0014, FS-0015, PLAN-0014, PLAN-0015, PLAN-0017 —
are records of work performed when it existed. Leave them.

**`vendor/madr/` is not drift.** The submodule is uninitialised in this
working tree. Its files appear after `git submodule update --init`. The
path check must exclude uninitialised submodule contents rather than the
corpus being edited.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0022 Non-Goals. No rule changes, no convention-only enforcement,
    no linting of preserved evidence.
  * FS-0022's Out of Scope defers retroactive drift fixing to "PLAN work".
    This is that plan, and §5a is that work — bounded to the four items
    listed there, two of which escalate rather than execute.

* ADR constraints:

  * ADR-0015 — these are Category 1 governance gates. They live in
    `scripts/`, are registered in `package.json`, and are documented in
    `scripts/README.md`. That is not optional.
  * ADR-0027 — every path in `touches:` above is a reserved path. **This
    PLAN can never self-approve.** It requires human approval by
    construction, which is the correct outcome for a plan that modifies
    the check evaluating self-approval.
  * ADR-0030 — rule 3 applies to this change: `scripts/README.md` is the
    current-state document for what the gates do.
  * ADR-0008 — markdownlint stays the linter; this widens its scope.

* Architecture constraints:

  * `check-status.sh` must remain runnable against a working tree with no
    diff context. Rule 3 needs the change set, so it is CI-only. Do not
    add git-diff dependence to the local script.

## 7. Risks and Edge Cases

* **The corpus is expected to fail on first run.** FS-0022 states this and
  §5a sizes it. Do not weaken a check to make the corpus pass.
* **Two remediation items require escalation, not implementation**:
  ADR-0015's missing Validation section, and the seven dangling
  `roles/ROLE_CONTRACT.md` references. Both are judgment calls with
  governance consequences. An implementer that resolves either
  unilaterally has exceeded this plan.
* A per-directory `.markdownlint.yml` with `default: false` is
  indistinguishable from an accidental one. The lint job reports which
  directories are exempt so the set is visible in CI output.
* A PLAN governing several FSs: `touches:` must be contained in the union
  of their `interfaces:`.
* An ADR whose Links name several current-state documents: modifying any
  one satisfies rule 3. Requiring all would fail legitimate changes.
* `bats` absent locally is the common developer case. It must fail with an
  install hint, never skip silently — a suite that passes by not running
  is the state this PLAN exists to end.
* Widening lint may surface violations in `guidelines/`, `skills/`, and
  `templates/` that have never been linted. Expect a large first-run
  failure set.

## 8. Validation

* Tests expected to pass:

  * All of `test/FS-0022/gate-coverage.bats`.
  * All pre-existing suites, now actually executing:
    `test/FS-0001`, `FS-0016`, `FS-0017`, `FS-0018`, `FS-0019`.

* Manual checks:

  * Rule 3, positive: open a PR modifying an ADR whose Links name a
    `workflows/` path without touching it. The job must fail.
  * Rule 3, negative: add the referenced document to the same PR. The job
    must pass.
  * Introduce a deliberate style violation under
    `docs/orchestration/multi-model-pilot-001/`. Lint must not fail.
  * Run `npm run check:status` against trunk before fixing anything and
    record the failure set — that is the drift baseline. Compare it against
    §5a; a larger set than audited means the audit missed a class, and that
    class needs recording before remediation continues.

## 9. Explicit Non-Changes

* The FS↔PLAN pairing and README-sync checks already in
  `check-status.sh`.
* The `.markdownlint.yml` configs in `docs/decisions/`,
  `docs/specifications/`, `docs/change-plans/`, `workflows/`,
  `guidelines/javascript/`, and `docs/orchestration/multi-model-pilot-001/`.
* The bats suites themselves. This plan runs them; it does not fix what
  they report.
* Any rule text in any ADR or FS.
* Historical references to `roles/ROLE_CONTRACT.md` in FS-0014, FS-0015,
  PLAN-0014, PLAN-0015 and PLAN-0017. Those record work done when the file
  existed.

## 10. Readiness Check

* [ ] FS-0022 is approved
* [x] Tests are clearly defined — §3, one per success criterion
* [x] Scope is minimal and explicit
* [x] No architectural changes implied
* [ ] **Human approval required.** Every path in `touches:` is reserved
      under ADR-0027; this PLAN cannot self-approve.
