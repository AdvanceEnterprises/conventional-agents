---
type: feature-spec
id: FS-0033
status: draft
title: Governance CI on stacked and non-trunk pull requests
owner: ajoeofalltrades
test_required: true
interfaces:
  - ".github/workflows/lint-docs.yml"
  - "skills/gh-pr-workflow/SKILL.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
related_adrs: [ADR-0012, ADR-0027]
supersedes: []
requires: []
tags: [governance, ci, stacked-pr, pull-request, gates]
created: 2026-09-10
updated: 2026-09-10
---

<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: Governance CI on Stacked and Non-Trunk Pull Requests

## Status

- Draft

## Summary

The repository's governance CI (`.github/workflows/lint-docs.yml`) previously
filtered `pull_request` events to `branches: [trunk]`. Stacked PRs — those whose
base is a non-`trunk` branch — received only the Python analysis check and none
of the normal lint, status, freshness, or Bats checks. A green-looking stacked
PR therefore did not mean "governance checks ran"; it meant "no governance
checks ran." This spec defines the required behavior: every pull request,
regardless of base branch, receives the same documented governance signal as a
trunk-based PR, or fails closed with an explicit actionable status.

## Background

- PR #118 — observed stacked-PR no-CI condition during review.
- `.github/workflows/lint-docs.yml` — the workflow whose trigger was filtered.
- `ADR-0012` — human merge gate; CI must provide truthful evidence before that
  gate.
- `ADR-0027` — `.github/workflows/` is a reserved path requiring human
  approval for changes; this spec and its PLAN document the change so the
  reserved-path gate has a governing artifact to evaluate.
- `skills/gh-pr-workflow/SKILL.md` — documents the PR lifecycle and check
  expectations.

## Requirements

1. **No base-branch filter.** The `pull_request` trigger in
   `.github/workflows/lint-docs.yml` must not filter to `branches: [trunk]`.
   Stacked and non-trunk PRs must receive the same governance jobs as
   trunk-based PRs.

2. **Fork safety preserved.** The workflow must not use secrets or
   `pull_request_target`; fork PRs must continue to run with the read-only
   default token. Removing the base-branch filter must not broaden secret
   exposure.

3. **Base-ref correctness in every job.** Any job that diffs against the base
   branch must resolve the base ref it actually compares against. In
   particular, `lint-cross-repo` must fetch the PR's base ref
   (`origin/${{ github.base_ref }}`) before computing
   `COMMIT_RANGE="origin/${{ github.base_ref }}..HEAD"` — fetching only
   `origin/trunk` leaves the range invalid for stacked PRs whose base is not
   trunk.

4. **Documented expectation.** `skills/gh-pr-workflow/SKILL.md` must state
   that stacked PRs run the same governance chain as trunk-based PRs, and that
   individual jobs must diff against `github.base_ref` rather than hardcoding
   `trunk`.

## Success Criteria

- A stacked PR (base = non-`trunk` branch) triggers the full `lint-docs`
  workflow: lint-adrs, lint-specs, lint-change-plans, lint-workflows,
  lint-docs-widened, check-status, github-binding-audit, check-freshness,
  lint-cross-repo, current-state-update, and test-bats all run and report.
- A fork PR still runs with the read-only default token; no secrets are
  exposed and no `pull_request_target` is introduced.
- `lint-cross-repo` on a stacked PR computes a valid commit range against the
  actual base ref and passes or fails on real evidence, never on an invalid
  range.
- The PR workflow skill documents the stacked-PR expectation so future
  editors do not reintroduce a `branches: [trunk]` filter or a hardcoded
  `trunk` diff target.

## Non-Goals

- Adding new governance checks beyond the existing `lint-docs.yml` job set.
- Changing the `push` trigger's `branches: [trunk]` filter (trunk pushes
  remain the merge path).
- Introducing `pull_request_target` or any secret-bearing workflow for fork
  PRs.

## Out of Scope

- Cross-repo CI behavior for the other Tais-Den repositories (feral-fleet,
  pack-protocol) — this spec governs conventional-agents only.
- Changes to which checks exist; only the trigger filter, base-ref handling,
  and documentation are in scope.

## Interfaces

- `.github/workflows/lint-docs.yml` — trigger filter removal and base-ref
  fetch fix.
- `skills/gh-pr-workflow/SKILL.md` — stacked-PR governance expectation.
- `docs/specifications/README.md`, `docs/change-plans/README.md` — index rows
  for this spec and its PLAN.

## Related Documents

- ADR-0012 (human merge gate), ADR-0027 (reserved-path self-approval rule).
- Issue #139 (enhancement: run governance CI on stacked and non-trunk pull
  requests).
