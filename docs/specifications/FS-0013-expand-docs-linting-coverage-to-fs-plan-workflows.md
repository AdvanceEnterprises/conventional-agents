# Expand docs linting coverage to FS/PLAN/workflows

Generated: 2026-02-07T14:29:56

---
type: feature-spec
id: FS-0013
status: draft
title: Expand docs linting coverage to FS/PLAN/workflows
owner: Tai
test_required: false
interfaces:
  - .github/workflows/ (CI changes)
  - docs/specifications/FS-*.md
  - docs/change-plans/PLAN-*.md
  - docs/workflows/*.md
related_adrs: []
supersedes: []
requires: []
tags:
  - ci
  - docs
  - markdownlint
created: 2026-02-07
updated: 2026-02-07
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

# Feature Spec: Expand docs linting coverage to FS/PLAN/workflows

## Status
- Draft

## Summary
Extend existing markdown linting checks so CI validates the documentation classes we own (Feature Specs, Change Plans, and Workflows), not just ADRs. This reduces review churn and catches formatting issues early.

## Goals
- Add markdownlint coverage for:
  - `docs/specifications/FS-*.md`
  - `docs/change-plans/PLAN-*.md`
  - `docs/workflows/*.md`
- Keep lint scope limited to the doc classes we own (avoid linting all markdown under `docs/`).

## Non-Goals
- Linting all markdown files under `docs/`.
- Adding content/semantic validation of specs/plans (format-only in this iteration).
- Changing existing ADR lint rules.

## Users / Stakeholders
- Authors: Tai + coding agents
- Reviewers: anyone reviewing doc PRs

## Interfaces
- Type: Infra
- Details:
  - GitHub Actions workflows under `.github/workflows/`
  - markdownlint globs for the owned doc classes

## Success Criteria
- Given a PR that modifies `docs/specifications/FS-*.md`, when CI runs, then markdownlint is executed against those FS files and fails on formatting errors.
- Given a PR that modifies `docs/change-plans/PLAN-*.md`, when CI runs, then markdownlint is executed against those plan files and fails on formatting errors.
- Given a PR that modifies `docs/workflows/*.md`, when CI runs, then markdownlint is executed against those workflow docs and fails on formatting errors.
- Given a PR that only modifies unrelated markdown under `docs/` (outside the owned classes), when CI runs, then the “docs lint” checks do not expand scope to lint all docs.

## Edge Cases
- New doc classes may be added later (e.g., `CP-*.md`); this spec does not require linting them unless explicitly included.
- Files with YAML front matter must remain markdownlint-compatible (front matter at top; single H1; blank lines around lists/headings).

## Out of Scope
- Enforcing FS/ADR/PLAN front matter correctness via schema validation.
- Adding custom markdownlint rule sets beyond what is already used.

## Dependencies
- Existing markdownlint CI setup (currently linting ADRs).

## Rollout / Migration (if applicable)
- Update CI workflows to add additional markdownlint jobs or expand existing globs to include:
  - `docs/specifications/FS-*.md`
  - `docs/change-plans/PLAN-*.md`
  - `docs/workflows/*.md`

## Observability (if applicable)
- CI job results in GitHub Actions.

## Security / Privacy (if applicable)
- N/A.

## Open Questions
- Should `docs/change-plans/CP-*.md` be included as an owned class? (Not required for this iteration.)
