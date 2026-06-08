---
type: feature-spec
id: FS-0001
status: implemented
title: Markdownlint Integration for ADR Quality Gates
owner: ajoeofalltrades
test_required: true
interfaces: [CI, Config]
related_adrs: [ADR-0008]
supersedes: []
requires: [ADR-0008]
tags: [tooling, quality-gates, ci, linting, adr]
created: 2026-01-27
updated: 2026-06-08
---

<!--
PARSING_HINTS:
- This document defines desired behavior for implementing ADR-0008.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: Markdownlint Integration for ADR Quality Gates

## Status

Implemented

## Summary

Implement automated markdown linting for ADRs using markdownlint, as decided in ADR-0008. This spec documents the configuration, CI integration, local development tooling, and documentation updates required to enforce consistent markdown formatting on all ADRs via a GitHub Actions quality gate. The linting scope is limited to `docs/decisions/ADR-*.md` files, configured with a MADR-derived ruleset that disables MD013 (line length) and MD024 (duplicate headings).

## Goals

- Enforce consistent, professional markdown formatting for all ADRs via automated linting
- Provide early feedback to contributors before PR review through both CI and optional local tooling
- Align with MADR upstream best practices and community conventions
- Enable optional local linting for contributors with npm installed
- Create a reusable pattern for applying linting to other markdown files in the future

## Non-Goals

- Auto-fixing violations (lint-only, no auto-format or auto-correction)
- Linting non-ADR markdown files (README.md, INTEGRATION.md, etc.)
- Enforcing pre-commit hooks or local development requirements
- Creating custom markdownlint rules beyond MADR's recommended configuration
- Linting code documentation (docstrings, comments in source files)

## Users / Stakeholders

- **ADR authors:** Get linting feedback before submitting PRs
- **PR reviewers:** Reduced manual formatting review burden
- **CI maintainers:** Responsible for maintaining the lint-adrs workflow
- **New contributors:** Can run linting locally to self-correct before PR submission
- **Repository maintainers:** Ensure consistent ADR quality across all contributors

## Tooling Choice: markdownlint-cli2

This spec uses `markdownlint-cli2` (both locally and in CI) for both purposes:

**Why cli2 (not plain cli):**

- MADR upstream uses `markdownlint-cli2-action@v17` in their reference CI workflow
- cli2 is the current recommended tool from markdownlint maintainers
- cli2 has better performance and configuration handling than cli v0.x
- Consistent tool across local and CI environments reduces friction

**How the MADR baseline is respected:**

- Configuration: `docs/decisions/.markdownlint.yml` is an exact copy of `vendor/madr/.markdownlint.yml`
- Tool invocation respects the config file in the same directory as targets
- CLI: `markdownlint-cli2 "docs/decisions/ADR-*.md"` automatically finds and uses `docs/decisions/.markdownlint.yml`
- Action: GitHub Actions with globs parameter uses the config via the action's default behavior

This is NOT a deviation from ADR-0008; it's the concrete implementation of "markdownlint with MADR config" using the MADR-recommended tool.

## Interfaces

### CI Workflow

- **Type:** CI (GitHub Actions)
- **File:** `.github/workflows/lint-adrs.yml`
- **Trigger:** On push and pull_request to the default branch (`trunk`)
- **Trigger paths:** Only watch for changes in `docs/decisions/ADR-*.md` and `docs/decisions/.markdownlint.yml`
- **Target:** Only files matching `docs/decisions/ADR-*.md` (using glob pattern)
- **Action:** `markdownlint-cli2-action@v17` with globs parameter set to `docs/decisions/ADR-*.md`
- **Failure behavior:** CI check fails with readable error output (line numbers, rule violations)

### Configuration

- **Type:** Config (YAML)
- **File:** `docs/decisions/.markdownlint.yml`
- **Provenance:** Exact copy of `vendor/madr/.markdownlint.yml` (pinned to MADR v4.0.0 per submodule)
- **Base:** `default: true` (all markdownlint rules enabled by default)
- **Disabled rules:** MD013 (line length), MD024 (duplicate headings) – same as MADR baseline
- **Maintenance:** If `vendor/madr/.markdownlint.yml` changes in future updates, manual review required before syncing

### Local Development (Optional)

- **Type:** Config (package.json) + CLI
- **Setup:** `npm install` (one-time, optional)
- **Tooling choice:** `markdownlint-cli2` (same tool as GitHub Actions, ensures consistency)
- **Usage:** `npm run lint:adrs` (runs `markdownlint-cli2 "docs/decisions/ADR-*.md"`)
- **Config:** Both CLI and Action use the same `.markdownlint.yml` configuration
- **Requirements:** Node.js and npm installed locally
- **Failure behavior:** Reports violations to console with line numbers and rule names, exits with status code 1 on errors

### Documentation

- **File:** `docs/decisions/README.md`
- **Contents:** Setup instructions, usage commands, troubleshooting for common violations

## Success Criteria

Each criterion is objectively testable and verifiable:

### 1. Configuration Management

- **Given** a fresh clone of the repository without running any installation commands, **when** checking `docs/decisions/.markdownlint.yml`, **then** the file exists and is an exact copy of `vendor/madr/.markdownlint.yml` (MADR v4.0.0).
- **Given** the configuration file, **when** examining it, **then** it contains exactly two disabled rules: `MD013: false` and `MD024: false`, with comments explaining each.

### 2. CI Integration

- **Given** a new pull request that modifies an ADR with markdown violations (e.g., missing blank line before heading, incorrect list formatting), **when** the CI workflow runs, **then** the lint-adrs GitHub Actions check fails with status "failure" and displays readable error output including line numbers and rule names.
- **Given** a new pull request with ADRs that comply with all linting rules, **when** the CI workflow runs, **then** the lint-adrs GitHub Actions check passes with status "success".
- **Given** the CI workflow configuration, **when** examining `.github/workflows/lint-adrs.yml`, **then** the workflow uses `markdownlint-cli2-action@v17` (pinned version, not @latest) with globs parameter set to `docs/decisions/ADR-*.md`.
- **Given** a PR that only modifies non-ADR files (e.g., README.md, `docs/decisions/examples.md`, or other markdown not matching `ADR-*.md`), **when** CI runs, **then** the lint-adrs workflow is skipped (trigger paths: only watch `docs/decisions/ADR-*.md` and `.markdownlint.yml`).
- **Given** a non-ADR markdown file in `docs/decisions/` (e.g., `docs/decisions/README.md`), **when** the CI workflow runs on a PR that touches only ADRs, **then** the non-ADR file is excluded from linting (only `ADR-*.md` pattern matched).

### 3. Local Development Setup

- **Given** a contributor with Node.js and npm installed, **when** they run `npm install` in the repository root, **then** markdownlint-cli2 is installed in `node_modules/` and available via `npx`.
- **Given** markdownlint-cli2 installed locally, **when** running `npm run lint:adrs`, **then** the script executes `markdownlint-cli2 "docs/decisions/ADR-*.md"` and reports violations to stdout with line numbers and rule names.
- **Given** markdownlint-cli2 run with the npm script, **when** examining the linting rules applied, **then** the tool uses the `.markdownlint.yml` configuration in `docs/decisions/` (same config as CI workflow).
- **Given** no npm or Node.js installed locally, **when** a contributor opens a PR with an ADR, **then** CI still enforces linting (local tooling is optional and not required for contribution).

### 4. Documentation

- **Given** a new contributor unfamiliar with the linting process, **when** reading `docs/decisions/README.md`, **then** they find a section explaining: (a) how to install markdownlint locally, (b) how to run linting before submitting a PR, (c) what to do if linting fails.
- **Given** a linting failure with output like "MD010: Hard tabs", **when** a contributor consults the troubleshooting section in `docs/decisions/README.md`, **then** they find an explanation of the violation and how to fix it (e.g., "replace tabs with spaces").

### 5. Backward Compatibility

- **Given** all existing ADRs in the repository (ADR-0000 through ADR-0009), **when** markdownlint is run against them, **then** all pass without violations or warnings (no reformatting required before CI is enabled).
- **Given** the markdownlint configuration scoped to `docs/decisions/ADR-*.md`, **when** other markdown files in the repository (README.md, INTEGRATION.md, docs/*.md) are checked, **then** they are not affected by the linting rules (scope enforced at CI level).

## Edge Cases

- **New ADR with violations:** A contributor submits an ADR that violates linting rules. The PR CI check fails with a helpful error message. The contributor fixes the violations locally and pushes again. CI passes on the second attempt.
- **Revert of configuration:** If `docs/decisions/.markdownlint.yml` is accidentally deleted or corrupted, CI fails on the next ADR check with a clear error ("config file not found" or "invalid YAML"). The workflow does not silently fall back to defaults.
- **MADR config drift:** If `vendor/madr/.markdownlint.yml` is updated in a future MADR release, we can choose to sync `docs/decisions/.markdownlint.yml` or maintain our own configuration. This is a manual decision, not automatic.
- **Non-standard ADR filenames:** A file named `docs/decisions/my-decision.md` or `docs/decisions/decisions-log.md` (not matching `ADR-*.md` pattern) is ignored by linting even if it's in the decisions directory. The glob pattern enforces this scope boundary.
- **Linting tool failures:** If markdownlint-cli2-action fails to download or execute (e.g., network error, action bug), the GitHub Actions workflow status is reported as "error" or "failure", and the PR cannot be merged (blocking is intentional; cannot proceed with unknown linting status).

## Out of Scope

The following are explicitly excluded from this specification:

- **Non-ADR markdown files:** Linting rules do not apply to README.md, INTEGRATION.md, docs/decisions/README.md, or any other non-ADR files
- **Auto-fixing or auto-formatting:** This spec covers linting (checking) only; no code that automatically fixes violations or reformats files
- **Pre-commit hooks:** No requirement to set up or enforce git pre-commit hooks; CI is the enforcement point
- **Custom markdownlint rules:** No custom rules beyond the MADR-derived config; only built-in markdownlint rules are used
- **Linting configuration files themselves:** Files like `.markdownlint.yml` and workflow YAML are not subject to markdownlint linting
- **Code documentation:** Docstrings in source code or inline comments are not linted by this tool
- **Alternative markdown files in docs/decisions/:** Only `ADR-*.md` pattern; other decision documents (e.g., decision logs, templates) are out of scope unless explicitly named ADR-XXXX.md

## Dependencies

### Upstream (Must be complete before this spec)

- **ADR-0008:** "Adopt markdownlint for ADR Formatting Consistency" – The decision that this spec implements
- **vendor/madr/.markdownlint.yml:** Reference configuration file (already present in repository)
- **templates/core/feature-spec.md:** Template for this spec document
- **GitHub Actions:** CI platform (assumed available; no additional setup required)

### Downstream (Work that depends on this spec)

- Future ADRs (ADR-0010 and beyond) are subject to linting requirements once this is implemented
- Future CI workflows may reference the lint-adrs pattern as an example for linting other file types
- docs/decisions/README.md will be updated to include linting instructions (implementation task, not this spec)

### External Dependencies

- **markdownlint-cli2:** Open-source linting tool (MIT license, actively maintained)
- **Node.js / npm:** For optional local tooling (not required for CI or reading the repository)
- **GitHub Actions:** For CI integration (no additional dependencies)

## Rollout / Migration

### Phase 1: Prepare (Pre-CI Enablement)

1. Create `docs/decisions/.markdownlint.yml` as an exact copy of `vendor/madr/.markdownlint.yml` (MADR v4.0.0)
2. Test configuration against all existing ADRs (ADR-0000 through ADR-0009) using command: `markdownlint-cli2 "docs/decisions/ADR-*.md"`
3. Fix any violations found in existing ADRs to ensure they pass linting (if needed)
4. Create `package.json` with markdownlint-cli2 in devDependencies and npm script: `"lint:adrs": "markdownlint-cli2 \"docs/decisions/ADR-*.md\""`
5. Document linting setup in `docs/decisions/README.md` with installation, usage (`npm run lint:adrs`), and troubleshooting instructions

### Phase 2: Enable CI

1. Create `.github/workflows/lint-adrs.yml` with:
   - Trigger: `on: [push, pull_request]` to `trunk`
   - Trigger paths: Only watch `docs/decisions/ADR-*.md` and `docs/decisions/.markdownlint.yml` (skip if unchanged)
   - Step: `markdownlint-cli2-action@v17` with globs: `docs/decisions/ADR-*.md`
2. Merge workflow to main branch
3. Test workflow with an intentional violation in a PR to verify the gate works and error messages are clear (then fix and re-push to verify passing)

### Phase 3: Validate and Monitor

1. Monitor first 3-5 PRs that include ADRs to ensure linting feedback is clear and actionable
2. Collect feedback from contributors on error messages and troubleshooting
3. Update `docs/decisions/README.md` troubleshooting section if common issues are found
4. After 2-4 weeks of stable operation, mark spec as "Implemented"

## Observability

### Logs

- **GitHub Actions logs:** Each workflow run logs full markdownlint output (file paths, line numbers, rule violations, explanations)
- **CLI output:** When run locally, `npm run lint:adrs` outputs violations in human-readable format with line numbers and fix suggestions
- **PR feedback:** GitHub Actions provides a summary comment or check failure with violation details linked to the PR

### Metrics

- **PR lint failure rate:** Monitor percentage of PRs that fail linting on first attempt (should be low after docs are clear)
- **Lint fix cycle time:** Track average number of commits needed to fix lint issues per PR (target: 1, indicating clear feedback)
- **All ADRs pass status:** Post-Phase 1, all ADRs should continuously pass linting (no regressions)

### Traces

Not applicable. This is static analysis with no runtime tracing needed.

## Security / Privacy

### Data Handled

- **Configuration:** `docs/decisions/.markdownlint.yml` contains no sensitive data (YAML configuration only)
- **CI logs:** Markdownlint output is text (file paths and violation details) with no PII or secrets
- **GitHub Actions token:** CI workflow uses default `GITHUB_TOKEN` which provides read-only access for PR checks

### Threats Considered

- **Supply chain:** The markdownlint-cli2-action could be compromised or updated maliciously
  - **Mitigation:** Pin action version to `@v17` (not `@latest`) to prevent unexpected updates; review release notes before updating
- **CI token misuse:** The GITHUB_TOKEN could be extracted and used outside workflow scope
  - **Mitigation:** GitHub Actions automatically limits token scope; token is read-only for PR checks and not exposed in logs

### Mitigations

- **Action pinning:** Use `markdownlint-cli2-action@v17` (exact version) instead of `@latest` or `@main`
- **Configuration review:** Configuration file contains no secrets and is committed to the repository (public)
- **No credentials:** Linting process does not require API keys, passwords, or authentication

## Open Questions

None blocking implementation. ADR-0008 provides sufficient detail on the decision, configuration, and scope.

**Non-blocking considerations (optional to address during implementation):**

- Should we create a `.markdownlintignore` file to explicitly list excluded files? (Decision: Defer unless needed; glob pattern in CI is sufficient)
- Should the npm script be called `lint:adrs` or `lint:decisions`? (Decision: `lint:adrs` for clarity, matching ADR-specific scope)

## Links

- **ADR-0008:** [Adopt markdownlint for ADR Formatting Consistency](../decisions/ADR-0008.md)
- **MADR repository:** <https://github.com/adr/madr>
- **MADR configuration reference:** `vendor/madr/.markdownlint.yml`
- **MADR CI example:** `vendor/madr/.github/workflows/lint.yaml`
- **markdownlint documentation:** <https://github.com/DavidAnson/markdownlint>
- **Feature spec template:** `templates/core/feature-spec.md`
- **ADR process documentation:** `docs/decisions/README.md` (to be updated)
