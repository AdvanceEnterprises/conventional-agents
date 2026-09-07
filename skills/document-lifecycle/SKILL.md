---
name: document-lifecycle
description: "Scaffolds, transitions, and maintains governed documents — feature specs (FS), change plans (PLAN), and architecture decision records (ADR) — with correct front matter and cross-references. Use when creating or updating a governed document, changing its status, working from a template, or resolving a check:status violation."
license: MIT
---

# Document Lifecycle Skill

Encodes the conventional-agents document lifecycle, status transition rules, template usage, and front matter hygiene into actionable guidance.

## Source Documents

- `workflows/document-lifecycle.md` — status values, transition rules, front matter hygiene, README index maintenance
- `templates/core/feature-spec.md` — FS template
- `templates/core/change-plan.md` — PLAN template
- `templates/core/adr-full-madr.md` — ADR template
- `templates/core/architecture-arc42.md` — architecture doc template
- `docs/decisions/README.md` — ADR lifecycle details

## Purpose

This skill helps an agent:

1. **Scaffold new governed documents** from the correct templates
2. **Apply correct status transitions** (draft → approved → in-progress → implemented)
3. **Maintain front matter hygiene** (dates, cross-references, metadata)
4. **Keep README index tables in sync**
5. **Run and resolve `npm run check:status` violations**

---

## Document Types Overview

| Type | ID Pattern | Location | Statuses |
| --- | --- | --- | --- |
| Feature Spec | `FS-XXXX` | `docs/specifications/FS-XXXX-<name>.md` | draft → approved → in-progress → implemented → deprecated |
| Change Plan | `PLAN-XXXX` | `docs/change-plans/PLAN-XXXX-<name>.md` | draft → approved → in-progress → implemented |
| ADR | `ADR-XXXX` | `docs/decisions/ADR-XXXX-<name>.md` | proposed → accepted → deprecated → superseded |

---

## Status Transition Rules

### Forward-Only

Statuses move forward through the lifecycle. No backward transitions without human approval.

- FS: `draft → approved → in-progress → implemented`
- PLAN: `draft → approved → in-progress → implemented`
- ADR: `proposed → accepted` (or → deprecated / superseded)

Never: `implemented → approved` or `approved → draft`.

### Draft-to-Approved Requires Human Review

An agent MUST NOT transition a document from `draft` to `approved` on its own. This transition happens when a human merges the PR containing the document.

### Agents MUST NOT Implement Draft Specs

If a spec has `status: draft`, implementation is blocked. The agent's first task is to get the spec reviewed and approved — not to start coding.

### In-Progress Is Set at Execution Start

When an agent begins executing a PLAN, it sets both the FS and the PLAN to `in-progress` in the first implementation commit.

### Implemented Is Set in the Completing PR

When a PR completes the final step of a PLAN:

- Set the PLAN to `status: implemented`
- Set the governing FS to `status: implemented`
- Both status changes MUST be included in that PR — not deferred to a follow-up

### Single-PR Implementations

When a PLAN is fully implemented in a single PR, the status may go directly from `approved` to `implemented` in that PR. Setting `in-progress` as an intermediate step is not required.

### Multi-PR Implementations

- Set `in-progress` in the first PR
- Keep `in-progress` for intermediate PRs
- Set `implemented` only in the final PR

### Stale Documents

If an `approved` spec has not been worked on for an extended period and is no longer planned:

- Set it to `deprecated` with a note explaining why
- Do not leave it as `approved` indefinitely

---

## Template Usage

### Feature Spec (`templates/core/feature-spec.md`)

Required front matter:

```yaml
---
type: feature-spec
id: FS-XXXX
status: draft
title: <title>
owner: <owner>
test_required: true
interfaces: []
related_adrs: []
supersedes: []
requires: []
tags: []
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
---
```text

Key sections to fill:

- **Summary** — one paragraph describing what and why
- **Goals** — bullet list of goals
- **Non-Goals** — hard constraints
- **Success Criteria** — each bullet MUST be objectively testable (Given/When/Then format)
- **Interfaces** — CLI, API, Library, Config, UI, or Infra
- **Out of Scope** — explicit exclusions

### Change Plan (`templates/core/change-plan.md`)

Required front matter:

```yaml
---
type: change-plan
role: implementer
language: <language>
status: draft
related_specs: []
related_adrs: []
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
---
```text

Key sections:

- **Scope of Change** — what this change WILL and will NOT do
- **Tests Driving This Change** — test file paths and target test names
- **Files to Be Modified** — only files that will be changed
- **Implementation Steps** — concrete steps without code
- **Constraints and Guardrails** — from FS Non-Goals, ADRs, architecture
- **Explicit Non-Changes** — what will NOT be modified

### ADR (`templates/core/adr-full-madr.md`)

Required front matter:

```yaml
---
type: adr
id: ADR-XXXX
status: proposed
decision_scope: system
reversible: unknown
related_specs: []
superseded_by: null
---
```text

Key sections:

- **Context and Problem Statement** — what problem are we solving?
- **Decision Drivers** — key factors influencing the decision
- **Considered Options** — at least two options with descriptions
- **Decision Outcome** — chosen option and rationale
- **Consequences** — positive, negative, and neutral
- **Validation** — how will we know this decision was correct?

---

## Front Matter Hygiene

### Updated Dates

When modifying any FS, PLAN, or ADR, update the `updated:` field in YAML front matter to today's date.

### Cross-References

| Document | Field | What to reference |
| --- | --- | --- |
| FS | `related_adrs` | ADRs that informed the spec |
| PLAN | `related_specs` | Governing FS(s) |
| ADR | `related_specs` | Specs that implement the decision |

### ID Assignment

When creating a new document, determine the next available ID by checking the existing files in the relevant directory:

```bash
# Next FS ID
ls docs/specifications/FS-*.md | grep -oP 'FS-\K\d+' | sort -n | tail -1

# Next PLAN ID
ls docs/change-plans/PLAN-*.md | grep -oP 'PLAN-\K\d+' | sort -n | tail -1

# Next ADR ID
ls docs/decisions/ADR-*.md | grep -oP 'ADR-\K\d+' | sort -n | tail -1
```text

Add 1 to the highest existing ID.

---

## README Index Maintenance

Each docs subdirectory has a README.md that serves as an index:

- `docs/specifications/README.md`
- `docs/change-plans/README.md`
- `docs/decisions/README.md`

**Update the relevant README when:**

- Adding a new document to the directory
- Changing a document's status

The README tables typically include: ID, Title, Status, and (for ADRs) Decision.

---

## Status Consistency Check

Run `npm run check:status` before every commit. This validates:

1. **FS↔PLAN status pairing** — if a PLAN references an FS, their statuses should be consistent
2. **README index sync** — index tables match actual document statuses
3. **Cross-reference validity** — referenced documents exist

### Resolving Violations

| Violation | Fix |
| --- | --- |
| FS status is `approved` but PLAN is `implemented` | Set FS to `implemented` |
| PLAN references non-existent FS | Update `related_specs` or create the FS |
| README table missing a document | Add the row to the README |
| README table has wrong status | Update the status in the README |
| `updated:` date is stale | Set `updated:` to today's date |

---

## Document Creation Workflow

When creating a new governed document:

1. **Determine the next ID** (see ID Assignment above)
2. **Copy the template** from `templates/core/`
3. **Fill in front matter** with correct ID, status, dates, and cross-references
4. **Fill in all required sections** — do not omit or invent sections
5. **Update the README index** in the relevant `docs/` subdirectory
6. **Run `npm run check:status`** and resolve any violations
7. **Commit** with a descriptive message (e.g., "docs: add FS-00XX for <title>")

---

## Document Update Workflow

When updating an existing governed document:

1. **Update `updated:`** to today's date
2. **Make the content changes** — follow the template structure
3. **Update cross-references** if the change affects related documents
4. **Update the README index** if the status changed
5. **Run `npm run check:status`** and resolve any violations
6. **Commit** with a descriptive message

---

## Related Skills

- `../role-aware-session/SKILL.md` — session mode, primary/supporting roles, when Document Author leads
- `../git-gh-workflow/SKILL.md` — branch, commit, and PR conventions for landing document changes
- `../framework-health-audit/SKILL.md` — `check:status` interpretation and the document hygiene gate

---

## Prohibitions

- **Do NOT** transition `draft` → `approved` — that is human-only (merge of the PR)
- **Do NOT** modify accepted ADRs beyond the Status section
- **Do NOT** create documents without following the prescribed template
- **Do NOT** commit without running `npm run check:status`
- **Do NOT** implement from a `draft` spec
- **Do NOT** set `implemented` on a PLAN or FS until the completing PR is ready
