---
name: framework-health-audit
description: "Runs check:status, performs full framework health audits, and enforces the document hygiene gate."
version: 1.0.0
author: conventional-agents
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [audit, compliance, status-checks, governance, document-hygiene]
    related_skills: [document-lifecycle, role-aware-session, git-gh-workflow]
---

# Framework Health / Audit Skill

Encodes the conventional-agents status consistency check, document hygiene gate, and framework health audit procedures into actionable guidance.

## Source Documents

- `scripts/check-status.sh` — the status consistency check script
- `docs/specifications/FS-0013.md` — status consistency check spec
- `roles/ROLE_CONTRACT.md` — document hygiene gate (7-item checklist)
- `workflows/document-lifecycle.md` — status transition rules
- `docs/decisions/ADR-0012.md` — non-overridable safety gates

## Purpose

This skill helps an agent:

1. **Run and interpret `npm run check:status`** — understand what it checks and how to fix violations
2. **Perform a full framework health audit** — review all governed documents for consistency, stale statuses, and drift
3. **Enforce the document hygiene gate** — the 7-item checklist before marking any PR ready
4. **Detect and resolve common violations** — stale statuses, missing cross-references, out-of-sync README indexes

---

## Status Consistency Check

### How to Run

```bash
npm run check:status
```

This executes `bash scripts/check-status.sh` which validates two rules.

### Rule 1: FS↔PLAN Status Pairing

The *first* entry in a PLAN's `related_specs:` list is its **primary governing spec**. Secondary entries are informational dependencies and are not checked for pairing.

The script enforces:

| Condition | Check |
| --- | --- |
| PLAN is `implemented` | Its primary FS must also be `implemented` |
| FS is `implemented` | At least one PLAN listing it as primary must also be `implemented` |

`draft` and `approved` statuses are not cross-checked — a PLAN may be `approved` while its FS is also `approved`, which is normal pre-execution state.

### Rule 2: README Table Sync

For each FS and PLAN document, the script checks that the status value in the relevant README index table row matches the `status:` field in the document's YAML front matter.

README table format:

```markdown
| FS-XXXX | Title | status-value |
```

### Common Violations and Fixes

| Violation | Likely Cause | Fix |
| --- | --- | --- |
| `PLAN-XXXX is 'implemented' but its primary spec FS-XXXX is '<status>'` | PLAN was marked implemented but FS was not updated | Set FS to `implemented` |
| `FS-XXXX is 'implemented' but no PLAN with it as primary spec is also 'implemented'` | FS was marked implemented but no PLAN was updated | Set the governing PLAN to `implemented` |
| `FS-XXXX has no row in README.md` | Document was added but README index was not updated | Add a row to the README |
| `FS-XXXX front matter status='<status>' but README shows '<other>'` | README index was not updated after a status change | Update the status in the README |
| `PLAN-XXXX references FS-XXXX as primary spec but no matching FS file found` | PLAN references a non-existent FS | Update `related_specs` or create the FS |

### Exit Codes

| Exit Code | Meaning |
| --- | --- |
| 0 | All checks passed |
| 1 | One or more violations found (printed to stdout) |

---

## Document Hygiene Gate

Before marking any PR as ready for review, verify all 7 items:

### 1. Status Fields Are Current

All FS and PLAN documents referenced by this PR have accurate `status:` values.

Valid transitions:

- FS: `draft → approved → in-progress → implemented → deprecated`
- PLAN: `draft → approved → in-progress → implemented`
- ADR: `proposed → accepted → deprecated → superseded`

### 2. `updated:` Dates Are Current

Any modified FS, PLAN, or ADR has its `updated:` front matter field set to today's date.

### 3. README Index Files Are Current

If you added or changed the status of a document in `docs/specifications/`, `docs/change-plans/`, or `docs/decisions/`, the corresponding `README.md` in that directory reflects the change.

### 4. CHANGELOG Entry Exists

If this PR introduces a user-visible change (feature, fix, breaking change), there is a corresponding entry in `CHANGELOG.md` under `[Unreleased]` or the appropriate version section.

For release-prep PRs, also update the framework version in `README.md` and `package.json` (or equivalent manifest).

### 5. Cross-References Are Complete

| Document | Field | What to reference |
| --- | --- | --- |
| FS | `related_adrs` | ADRs that informed the spec |
| PLAN | `related_specs` | Governing FS(s) |
| ADR | `related_specs` | Specs that implement the decision |

### 6. Interfaces Match Reality

The files touched by this PR align with the `interfaces:` declared in the governing FS. If they diverge, update the FS or explain in the PR description.

### 7. Status Consistency Check Passes

Run `npm run check:status` and resolve all reported violations before marking the PR ready.

---

## Framework Health Audit Procedure

A full audit checks the health of the entire governance framework. Run this periodically or when asked.

### Step 1: Run the Automated Checks

```bash
npm run check:status
npm run lint:docs
```

### Step 2: Check for Stale Documents

Look for:

- **Approved specs with no recent activity** — If an `approved` FS or PLAN has not been worked on for an extended period and is no longer planned, set it to `deprecated` with a note explaining why.
- **In-progress specs with no recent commits** — If an `in-progress` FS or PLAN has no recent implementation activity, check whether the work is still active.

### Step 3: Verify Cross-Reference Completeness

For each FS, check that `related_adrs` references all ADRs that informed the spec.
For each PLAN, check that `related_specs` references the governing FS.
For each ADR, check that `related_specs` references any specs that implement the decision.

### Step 4: Check README Index Completeness

For each governed document directory (`docs/specifications/`, `docs/change-plans/`, `docs/decisions/`):

- Every document file has a corresponding row in the README index.
- The status in the README matches the document's front matter.
- The README is sorted consistently (typically by ID).

### Step 5: Verify Document Template Compliance

Spot-check a sample of documents to ensure they follow the prescribed template:

- FS documents follow `templates/core/feature-spec.md`
- PLAN documents follow `templates/core/change-plan.md`
- ADR documents follow `templates/core/adr-full-madr.md`

### Step 6: Report Findings

Produce a summary with:

- **Passed**: checks that passed
- **Violations**: specific issues found, with file paths and suggested fixes
- **Stale documents**: documents that may need deprecation or status updates
- **Recommendations**: process improvements or follow-up actions

---

## Quick Reference: Common Fixes

| Situation | Action |
| --- | --- |
| FS is `implemented` but PLAN is `approved` | Set PLAN to `implemented` |
| PLAN is `implemented` but FS is `approved` | Set FS to `implemented` |
| README missing a document row | Add the row with correct ID, title, and status |
| README has wrong status | Update the status in the README |
| `updated:` date is old | Set `updated:` to today's date |
| Cross-reference points to non-existent doc | Update the reference or create the missing doc |
| Approved spec is no longer planned | Set to `deprecated` with a note |
| Lint errors in governed docs | Run `npm run lint:docs` and fix violations |

---

## Prohibitions

- **Do NOT** auto-fix violations without understanding the context — some status mismatches may be intentional (e.g., multi-PR implementations in progress).
- **Do NOT** change document statuses without ensuring the corresponding PLAN or FS is also updated.
- **Do NOT** mark a PR ready for review if any hygiene gate item is unresolved.
- **Do NOT** set `implemented` on a PLAN or FS until the completing PR is actually ready.
