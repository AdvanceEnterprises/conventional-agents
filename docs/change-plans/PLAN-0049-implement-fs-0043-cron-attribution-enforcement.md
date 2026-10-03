---
type: change-plan
role: implementer
language: n/a
status: approved
related_specs: [FS-0043]
approved_by: "Joey Clark <administrator@ajoeofalltrades.dev>"
related_adrs: [ADR-0021, ADR-0024, ADR-0026, ADR-0027]
touches:
  - scripts/cross-repo-lint.sh
  - scripts/README.md
  - workflows/git-and-gh-conventions.md
  - test/FS-0043/**
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-10-03
updated: 2026-10-03
---

# PLAN-0049: Implement FS-0043 — Cron attribution enforcement

## 1. Feature / Issue Reference

- Feature Spec: FS-0043
- Related spec: FS-0017
- Related ADRs: ADR-0021, ADR-0024, ADR-0026, ADR-0027
- Issue: #187

## 2. Scope of Change

Extend the existing read-only `scripts/cross-repo-lint.sh` attribution check with
a boundary-aware cron rule. The default boundary is the implementation adoption
instant documented in the script; consumers can override it with
`CRON_ATTRIBUTION_BOUNDARY`. Commits at or before the boundary are reported as
grandfathered. Later commits authored by configured cron identities require the
terminal `mode=autonomous` field.

Update the operator documentation and conventions table, and add real Git
fixtures covering the boundary, terminal position, interactive agents, and
existing structural failures. The workflow already invokes the audit, so no new
network or mutation surface is introduced.

## 3. Approval Routing

The final `touches:` set includes `scripts/cross-repo-lint.sh`, a reserved path.
A recorded human approval must be the most recent commit touching this plan
before implementation begins. No history rewrite is authorized.

## 4. Implementation Steps

1. Add validated boundary and cron-email configuration to the attribution scan.
2. Preserve the existing structural regex while adding a post-boundary terminal
   marker check and grandfather diagnostics.
3. Add focused Bats fixtures built from temporary Git repositories.
4. Correct the conditional/mandatory documentation without changing the ADR.
5. Run the anchored audit over current history and record the grandfathered
   baseline separately from new failures.

## 5. Validation

- `bash -n scripts/cross-repo-lint.sh`
- `bats test/FS-0043`
- `npm run lint:cross-repo` with the repository's prepared range
- `npm run check:status`
- `npm run check:freshness`
- `npm run lint:docs`
- `npm run validate`

## 6. Constraints and Rollback

The audit remains offline and read-only. Rollback removes the boundary check,
fixtures, documentation, index rows, and CHANGELOG entry; existing attribution
validation and all historical commits remain unchanged.

## 7. Readiness Check

- [x] Spec is approved
- [x] Boundary and grandfathering semantics are explicit
- [x] Existing structural attribution behavior is preserved
- [x] No history rewrite is included
