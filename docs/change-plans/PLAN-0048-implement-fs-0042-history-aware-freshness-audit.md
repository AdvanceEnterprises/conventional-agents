---
type: change-plan
role: implementer
language: n/a
status: approved
related_specs: [FS-0042]
approved_by: "Joey Clark <administrator@ajoeofalltrades.dev>"
related_adrs: [ADR-0024, ADR-0026, ADR-0027, ADR-0033]
touches:
  - scripts/check-freshness-history.sh
  - scripts/README.md
  - package.json
  - .github/workflows/lint-docs.yml
  - test/FS-0042/**
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-10-03
updated: 2026-10-03
---

# PLAN-0048: Implement FS-0042 — History-aware freshness audit

## 1. Feature / Issue Reference

- Feature Spec: FS-0042
- Related implementation: FS-0027 / PLAN-0027
- Related ADRs: ADR-0024, ADR-0026, ADR-0027, ADR-0033
- Issue: #183

## 2. Scope of Change

The implementation adds a separate `scripts/check-freshness-history.sh`
companion. It enumerates the same `workflows/` and `guidelines/` Markdown scope as
FS-0027, checks full Git history, and identifies the latest non-merge substantive
commit after excluding commits that change only freshness metadata. It reports
findings without writing files.

The plan also wires `npm run check:freshness:history` to strict mode, adds the
full-history CI step, documents the contract, and adds disposable Git-history
fixtures. The existing `check:freshness.sh` is not modified.

## 3. Approval Routing

This plan declares its final implementation surface up front. The surface
includes `scripts/`, `package.json`, and `.github/workflows/`, so the plan may not
self-approve. A recorded human approval must be the most recent commit touching
this plan before implementation begins, and the approval covers the exact list
in `touches:`.

## 4. Implementation Steps

1. Add the Bash 3.2-compatible history parser with caller-relative target
   resolution, explicit `--strict`, `--help`, and unavailable-history exit code.
2. Add fixture-driven Bats tests using real commits, including date-only metadata
   updates and a shallow clone.
3. Register the npm command and run it from the full-history documentation
   workflow without weakening existing jobs.
4. Document the evidence model and remediation in `scripts/README.md`.
5. Run the audit against the current corpus, classify any findings, and update
   governed statuses only after evidence is reviewed.

## 5. Validation

- `bash -n scripts/check-freshness-history.sh`
- `bats test/FS-0042`
- `npm run check:freshness:history`
- `npm run check:status`
- `npm run check:freshness`
- `npm run lint:docs`
- `npm run validate`

## 6. Constraints and Rollback

The audit is offline, report-only, and never edits `updated:` fields. A rollback
removes the new script, npm entry, CI step, tests, documentation, index rows, and
CHANGELOG entry; FS-0027 remains intact.

## 7. Readiness Check

- [x] Spec is approved
- [x] Full implementation surface is declared
- [x] Tests and unavailable-history behavior are defined
- [x] Existing FS-0027 behavior remains unchanged
