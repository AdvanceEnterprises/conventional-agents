---
type: change-plan
role: implementer
language: yaml
status: draft
related_specs: [FS-0001]
related_adrs: [ADR-0008, ADR-0010]
created: 2026-01-27
updated: 2026-01-27
---

<!--
PARSING_HINTS:
- Document type: change-plan
- Intended role: Implementer (Role 2)
- This is a TEMPLATE, not a guide or essay.
- Fill in all sections succinctly.
- Do not include code blocks unless explicitly requested.
- Treat the completed plan as a binding contract for implementation.
- If implementation would exceed this plan, the plan must be revised first.
-->

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0001
* Related ADR ID(s): ADR-0008 (Adopt markdownlint for ADR Formatting Consistency), ADR-0010 (Custom Change Plan Template)
* Issue / PR Reference: TBD (will be assigned during implementation)

## 2. Scope of Change

**This change WILL:**

* Create `docs/decisions/.markdownlint.yml` as an exact copy of `vendor/madr/.markdownlint.yml` (MADR v4.0.0)
* Create `.github/workflows/lint-adrs.yml` to run `markdownlint-cli2-action@v17` on all `docs/decisions/ADR-*.md` files
* Create `package.json` with `markdownlint-cli2` in devDependencies and npm script `"lint:adrs": "markdownlint-cli2 \"docs/decisions/ADR-*.md\""`
* Update `docs/decisions/README.md` with linting setup instructions, usage commands, troubleshooting section, and common violation fixes
* Test all existing ADRs (ADR-0000 through ADR-0009) against the configuration and fix any violations
* Verify CI workflow triggers correctly and fails on violations / passes on compliant ADRs

**This change will NOT:**

* Lint non-ADR markdown files (README.md, INTEGRATION.md, docs/decisions/README.md, etc.)
* Create auto-fixing or auto-formatting functionality (lint-only, no auto-corrections)
* Enforce pre-commit hooks (local tooling is optional, not required)
* Create custom markdownlint rules beyond MADR's configuration
* Modify the markdownlint configuration beyond copying from MADR baseline
* Lint code documentation (docstrings, comments in source files)

## 3. Tests Driving This Change

* Test file(s):

  * `.github/workflows/lint-adrs.yml` (CI integration test)
  * Manual verification steps (see Validation section)

* Target test(s):

  * test_sc_1__configuration_exists_and_matches_madr_baseline
  * test_sc_2__ci_workflow_fails_on_adr_violations
  * test_sc_2__ci_workflow_passes_on_compliant_adrs
  * test_sc_2__workflow_uses_correct_action_version_and_globs
  * test_sc_2__non_adr_files_excluded_from_linting
  * test_sc_3__npm_script_installs_and_runs
  * test_sc_3__local_command_uses_correct_config
  * test_sc_4__documentation_includes_setup_and_troubleshooting
  * test_sc_5__all_existing_adrs_pass_linting

## 4. Files to Be Modified

Only list files that will be changed.

* `docs/decisions/.markdownlint.yml` (create – exact copy of `vendor/madr/.markdownlint.yml`)
* `.github/workflows/lint-adrs.yml` (create – GitHub Actions workflow)
* `package.json` (create – with markdownlint-cli2 devDependency)
* `docs/decisions/README.md` (update – add linting setup and troubleshooting sections)
* `docs/decisions/ADR-*.md` (update if violations found – Phase 1 testing may require fixes)
* `docs/specifications/FS-0001-markdownlint-implementation.md` (may need minor clarifications if discovered during implementation)

## 5. Implementation Steps (High-Level)

### Phase 1: Prepare (Pre-CI Enablement)

1. Copy `vendor/madr/.markdownlint.yml` to `docs/decisions/.markdownlint.yml` without modifications
2. Verify file exists and contains exactly two disabled rules (MD013, MD024) with MADR comments intact
3. Test configuration locally: run `markdownlint-cli2 "docs/decisions/ADR-*.md"` against all existing ADRs (ADR-0000 through ADR-0009)
4. Document any violations found; fix ADRs as needed to pass linting
5. Create `package.json` in repository root with markdownlint-cli2 in devDependencies (pinned version, same as action)
6. Add npm script: `"lint:adrs": "markdownlint-cli2 \"docs/decisions/ADR-*.md\"`
7. Verify locally: run `npm install` and `npm run lint:adrs` to confirm script works
8. Update `docs/decisions/README.md` with: setup instructions, how to run locally, what to do if linting fails, and common violation fixes

### Phase 2: Enable CI

1. Create `.github/workflows/lint-adrs.yml` with:
   - Trigger: `on: [push, pull_request]` to main/master branches
   - Trigger paths: only watch `docs/decisions/ADR-*.md` and `docs/decisions/.markdownlint.yml`
   - Step: use `markdownlint-cli2-action@v17` with globs parameter set to `docs/decisions/ADR-*.md`
2. Verify workflow syntax (GitHub Actions will validate on PR)
3. Test with intentional violation in a PR: add a markdown violation to an ADR, verify CI fails with readable error
4. Fix the test violation and verify CI passes on second attempt
5. Merge workflow to main branch

### Phase 3: Validate and Monitor

1. Monitor first 3-5 PRs that include ADRs to ensure linting feedback is clear
2. Collect any contributor feedback on error messages or troubleshooting gaps
3. Update `docs/decisions/README.md` troubleshooting section if new issues are discovered
4. After 2-4 weeks of stable operation with no issues, mark spec status as "Implemented"

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0001 Non-Goals / Out of Scope: No auto-fixing, no non-ADR linting, no pre-commit hooks, no custom rules, no code linting
  * FS-0001 Success Criteria: All 5 criteria must pass (configuration, CI integration, local setup, documentation, backward compatibility)

* ADR constraints:

  * ADR-0008 Implementation section: Configuration must be MADR-derived, linting limited to `docs/decisions/ADR-*.md`, CI gate must fail on violations
  * ADR-0010: This change plan is the binding contract; any deviation requires plan revision first

* Architecture constraints:

  * Linting scope: only `docs/decisions/ADR-*.md` pattern (not other markdown files)
  * Configuration source: exact copy of `vendor/madr/.markdownlint.yml` (no custom modifications)
  * Tool choice: `markdownlint-cli2` for both local and CI (ensures consistency)
  * CI integration: GitHub Actions with action version pinned to `@v17`

## 7. Risks and Edge Cases

* **Risk: Configuration drift over time** – If `vendor/madr/.markdownlint.yml` is updated in a future MADR release, we must decide whether to sync. **Mitigation:** Document in `docs/decisions/README.md` that syncing is manual and requires review.

* **Risk: Contributor frustration with linting failures** – New ADR authors may not understand why linting failed. **Mitigation:** Ensure `docs/decisions/README.md` troubleshooting section is comprehensive; CI error messages are clear.

* **Risk: CI build time overhead** – Adding a linting step to CI increases pipeline time. **Mitigation:** markdownlint-cli2 is very fast (<1 second typically); overhead is negligible.

* **Edge case: Existing ADRs have violations** – Phase 1 testing may reveal that ADRs violate linting rules. **Mitigation:** Fix violations in Phase 1 before enabling CI gate; all ADRs must pass before CI enforcement.

* **Edge case: Non-ADR markdown in `docs/decisions/` directory** – Files like `docs/decisions/README.md` should not be linted. **Mitigation:** Glob pattern `docs/decisions/ADR-*.md` enforces this; no additional config needed.

* **Edge case: Contributor without npm/Node.js installed** – They won't be able to run linting locally. **Mitigation:** Document that CI is authoritative; local tooling is optional; contributor can rely on CI feedback.

* **Edge case: Linting workflow fails to download action** – Network or GitHub Actions issue. **Mitigation:** GitHub Actions will report "error" status; PR cannot merge; retry mechanism is built-in.

## 8. Validation

* Tests expected to pass:

  * Configuration file exists at `docs/decisions/.markdownlint.yml` and matches `vendor/madr/.markdownlint.yml`
  * `.markdownlint.yml` contains exactly two disabled rules: `MD013: false` and `MD024: false`
  * `.github/workflows/lint-adrs.yml` exists and uses `markdownlint-cli2-action@v17`
  * Workflow globs parameter is set to `docs/decisions/ADR-*.md`
  * Workflow trigger paths include only `docs/decisions/ADR-*.md` and `.markdownlint.yml`
  * `package.json` exists with `markdownlint-cli2` in devDependencies
  * npm script `lint:adrs` exists and runs `markdownlint-cli2 "docs/decisions/ADR-*.md"`
  * All existing ADRs (ADR-0000 through ADR-0009) pass linting without violations
  * `docs/decisions/README.md` includes setup instructions, usage, troubleshooting, and common fixes
  * CI workflow fails on PR with ADR violations (intentional test in Phase 2)
  * CI workflow passes on PR with compliant ADRs

* Manual checks (if any):

  * Phase 1: Clone repo fresh; verify `.markdownlint.yml` exists without running any commands; verify it's identical to `vendor/madr/.markdownlint.yml`
  * Phase 1: Run `npm install && npm run lint:adrs` locally; verify all existing ADRs pass
  * Phase 2: Open PR with intentional markdown violation in an ADR; verify CI workflow triggers and fails with readable error message
  * Phase 2: Fix the violation and push again; verify CI workflow passes
  * Phase 3: Monitor first 3-5 PRs with ADRs; verify no false positives or unclear errors

## 9. Explicit Non-Changes

State what will NOT be modified.

* The `vendor/madr/.markdownlint.yml` configuration itself (read-only reference)
* Other ADR templates or structure (only linting, no content changes)
* Non-ADR markdown files or their linting rules (scope explicitly limited to ADRs)
* The markdownlint tool version in CI (pinned to @v17; upgrades require new ADR/change plan)
* Pre-commit hook enforcement or local development requirements
* The way ADRs are written or formatted (linting only catches violations, not style guidance)

## 10. Readiness Check

* [x] Spec is approved (FS-0001 is in draft status; will be approved before implementation)
* [x] Tests exist or are clearly defined (5 success criteria from FS-0001 map to test cases above)
* [x] Scope is minimal and explicit (Phase 1–3 rollout, only config/workflow/docs changes)
* [x] No architectural changes implied (pure CI integration, no code architecture changes)

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation as defined in FS-0001
* No additional behavior will be introduced beyond the 3 phases (Prepare, Enable CI, Validate)
* Any deviation (e.g., auto-fixing, non-ADR linting, pre-commit hooks) will require revising this plan before coding
* Success criteria from FS-0001 are the acceptance criteria for this implementation
