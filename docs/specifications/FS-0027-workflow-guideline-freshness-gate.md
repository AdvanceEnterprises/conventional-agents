---
type: feature-spec
id: FS-0027
status: draft
title: Workflow and guideline doc freshness gate — enforce updated: frontmatter
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-freshness.sh"
  - "package.json"
  - "scripts/README.md"
  - ".github/workflows/lint-docs.yml"
  - "workflows/*.md"
  - "guidelines/**/*.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
related_adrs: []
supersedes: []
requires: []
tags: [governance, freshness, workflows, guidelines, gates]
created: 2026-08-29
updated: 2026-08-29
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

# Feature Spec: Workflow and Guideline Doc Freshness Gate

## Status

- Draft

## Plan Status

- **PLAN-0027 is `draft`.** This spec and its plan are authored together in the
  same change; neither is approved yet. Implementation (PR #95) is in review and
  will be reconciled with this governing spec before merge.

## Summary

The maintenance tick's staleness detection (proactive check #2) cannot measure
the freshness of this framework's own exported workflow and guideline surface:
as of 2026-08-29, **7 of 7 `workflows/*.md` and 10 of 10 `guidelines/**/*.md`
docs carry no `updated:` front-matter field**, so "staleness" is undefined for
them and no gate prevents regression. This spec defines a freshness gate —
`scripts/check-freshness.sh` — that makes `updated:` mandatory on every governed
doc under `workflows/` and `guidelines/` (excluding README index files) and
reports docs whose `updated:` date has gone stale.

This mirrors the runbook pattern already adopted in feral-fleet
(PR #127 / issue #126, `check-runbook-freshness.sh`).

## Goals

- Every governed doc under `workflows/` and `guidelines/` carries a valid
  `updated: YYYY-MM-DD` front-matter field.
- A contributor or CI run can check freshness locally with
  `npm run check:freshness` and remotely via the lint-docs workflow.
- The maintenance tick's staleness detection becomes meaningful for the
  workflow/guideline surface: a doc with `updated:` older than the threshold is
  reported as a candidate for refresh or `status: stale` marking.
- The existing corpus is backfilled with `updated:` values equal to each file's
  last commit date, so the gate goes green immediately without fabricating
  "freshness" that does not exist.

## Non-Goals

- **Automated content refresh.** The gate reports; it does not rewrite docs.
- **A `status: stale` transition.** Flagging a doc as stale (per the document
  lifecycle) remains a human or maintenance-tick decision.
- **Extending the gate to other directories.** `docs/`, `skills/`,
  `templates/`, `integrations/`, `roles/`, `runbooks/` and root-level docs
  already have their own status/freshness conventions (check-status.sh,
  FS-0022); this gate covers exactly `workflows/` and `guidelines/`.
- **Threshold policy changes.** The 90-day default is configurable via
  `DOC_STALE_DAYS` but not per-directory.

## Users / Stakeholders

- Contributors maintaining workflow and guideline documents.
- The `conventional-agents-maintenance` tick, whose staleness detection gains a
  working surface.
- CI, which gains a third doc-hygiene gate alongside check-status and
  lint-docs.

## Interfaces

- `scripts/check-freshness.sh` — the gate script (Category 1 gate per ADR-0015).
- `package.json` — `npm run check:freshness` entry.
- `.github/workflows/lint-docs.yml` — new `check-freshness` job on push and PR.
- `workflows/*.md`, `guidelines/**/*.md` — governed docs; README files excluded.

## Success Criteria

1. `scripts/check-freshness.sh` exits non-zero if any governed doc under
   `workflows/` or `guidelines/` (recursively, excluding `**/README.md`) lacks
   an `updated:` front-matter field, and prints the offending file(s).
2. The script exits non-zero if an `updated:` value is present but not a valid
   `YYYY-MM-DD` date, and prints the offending file(s).
3. The script prints (but does not fail on) docs whose `updated:` date is older
   than the threshold (default 90 days, override via `DOC_STALE_DAYS`), with
   each report line containing the file path, the date, and the age in days.
4. `DOC_STALE_DAYS` validation: a non-integer or negative value is rejected with
   a clear error and exit 1.
5. The existing corpus passes the gate: every doc under `workflows/` and
   `guidelines/` (excluding READMEs) has `updated:` set to its last commit date.
6. `npm run check:freshness` exists in `package.json` and runs the script.
7. The lint-docs workflow runs the gate on push and pull_request and fails CI
   when the gate fails.
8. The hard rule treats a front-matter block only: an `updated:` appearing in
   prose outside the front-matter block is not accepted as the field.

## Out of Scope

- Applying the gate to `docs/`, `skills/`, or other directories (see Non-Goals).
- Automated content refresh or stale-status transitions.
- Backdating: `updated:` reflects when a doc was last actually modified, not
  when the gate was introduced — the backfill used each file's last commit date
  precisely so the field records the real last modification.
