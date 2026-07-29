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
  - CONTRIBUTING.md
  - INTEGRATION.md
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
* Check that a spec touching exported surface has a CHANGELOG entry naming
  it — presence only; framing is a review judgment, not a script's.
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
  * `test_consumer_impact__exported_interfaces_require_changelog_entry`
  * `test_consumer_impact__internal_only_spec_not_flagged`

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
* `CONTRIBUTING.md` — lint remediation (§5a)
* `INTEGRATION.md` — lint remediation, whitespace only (§5a)

Deliberately **not** listed: the seven documents that reference
`roles/ROLE_CONTRACT.md`. They are correct as written and are fixed by the
file existing, not by editing them. `ADR-0015` is also absent — its
Validation section was written in this PR, not by this plan.

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

**Widened lint — 173 violations, concentrated in two files.** Measured, not
estimated, by running markdownlint against each currently-unlinted surface:

| Surface | Violations |
| --- | --- |
| `guidelines/`, `skills/`, `templates/`, `integrations/`, `roles/` | 0 |
| `CONTRIBUTING.md` | 6 |
| `INTEGRATION.md` | **165** |
| `docs/decisions/README.md` | 2 |

`INTEGRATION.md` is the whole problem: 86 MD010 (hard tabs), 44 MD032 (list
spacing), 17 MD022 (heading spacing). Mechanical whitespace, no prose changes,
and `markdownlint --fix` handles all three rule classes.

The exported directories being clean is the useful finding — widening coverage
is nearly free everywhere except one file that has never been linted and shows
it.

`docs/decisions/README.md`'s 12 MD060 errors are already fixed in this PR. Its
remaining 2 MD036 are pre-existing and trivial.

**FS index titles — 15 of 22 rows.** Abbreviated rather than fabricated,
unlike the ADR index this PR already corrected. Regenerate every row from
front matter.

**ADR structural completeness — resolved.** `ADR-0013`, `ADR-0014`, and
`ADR-0015` all lacked the Validation section `docs/decisions/README.md` §2
requires. All three are written in this PR. Nothing remains for the
implementer.

**`ADR-0015` — resolved.** Its Validation section is written in this PR.
`ADR-0015` is `proposed`, so this was ordinary drafting; an earlier draft of
this plan escalated it as an append-only problem on the mistaken belief that
it was accepted.

Its Validation §1 depends on this plan: "each executable in `scripts/` is
registered in `package.json`, described in `scripts/README.md`, and traceable
to an approved FS" is checkable only once `scripts/README.md` exists and the
Category 1 check is written. §5 of this plan delivers both.

**`roles/ROLE_CONTRACT.md` — resolved.** The file is written in this PR as a
delegating document, and all seven references now resolve. The reasoning below
is retained because it is what the implementer must not undo.

Original finding: `PLAN-0017` deleted it as a byte-identical duplicate of
`guidelines/ROLE_CONTRACT.md`, leaving seven documents pointing at nothing —
`INTEGRATION.md` alone names it eleven times, once as precedence level 2,
"cannot be weakened."

The maintainer's direction: the structure `README.md` describes is the
structure to support. `guidelines/ROLE_CONTRACT.md` is the framework
template; `roles/ROLE_CONTRACT.md` is the project's contract, started from
it. The seven references are correct and the missing file is the defect.

**Restore it as a delegating document, not a copy.** A byte-identical
duplicate is what PLAN-0017 correctly objected to, and reinstating one would
also violate `ADR-0030` rule 1 — one current statement per rule. Instead
`roles/ROLE_CONTRACT.md` states that this project adopts the framework
contract unmodified, names `guidelines/ROLE_CONTRACT.md` as its source, and
provides the section headings a host repo would extend. That satisfies the
documented structure, keeps one statement of each rule, and gives consumers
a worked example of their own `roles/ROLE_CONTRACT.md` rather than an empty
directory and a paragraph about one.

No reference changes. All seven resolve once the file exists, including
`INTEGRATION.md`'s precedence level 2, which is then a real document that a
host repo genuinely customizes.

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
* Both items previously escalated are now resolved by maintainer direction:
  ADR-0015's Validation section is written, and `roles/ROLE_CONTRACT.md` is
  restored as a delegating document. Neither remains an open judgment call.
* **`roles/ROLE_CONTRACT.md` must not become a copy.** The failure mode is
  re-creating the byte-identical duplicate PLAN-0017 removed, which would
  restore the drift risk and violate ADR-0030 rule 1. If it can be
  meaningfully diffed against `guidelines/ROLE_CONTRACT.md` beyond its
  delegation preamble and headings, it has gone wrong.
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
