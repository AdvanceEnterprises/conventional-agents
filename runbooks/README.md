# Runbooks

A runbook records an operational procedure **as performed against a real substrate** —
not as designed. It is a current-state document under `ADR-0030`.

## How this differs from its neighbours

| Surface | Answers | Tense |
| --- | --- | --- |
| `workflows/` | How work *should* proceed | Prescriptive |
| `integrations/` | How a core capability *maps* onto a substrate | Declarative |
| `runbooks/` | What was *actually done*, and what the substrate did back | Past, observed |

The distinction is load-bearing. `integrations/github-issues-projects.md` concedes that
three of six core capabilities are convention-and-detection rather than enforced, and
that GitHub disables scheduled workflows after 60 days of repository inactivity. Those
are claims about a substrate that changes without telling anyone.

A runbook is where the gap between the binding and the substrate's actual behaviour
gets written down. Its **Deviations Observed** section is the point of the document
type: it converts a one-time provisioning exercise into a correction that flows back
into `integrations/`, instead of folklore held by whoever happened to run the
procedure.

## Naming and identity

- Files are `RB-NNNN-short-description.md`, matching the `FS-NNNN-description.md`
  convention.
- IDs are allocated **first-come-on-merge**, as with every other document type here.
  Two open branches may claim the same number; the one that merges first keeps it.

## Front matter

```yaml
---
type: runbook
id: RB-0001
title: <what this procedure accomplishes>
status: current
substrate: <the system this operates against>
governs: <the integrations/ binding or workflows/ doc this operationalises, if any>
last_verified: YYYY-MM-DD
verified_by: "Name <email>"
related_adrs: []
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

`last_verified:` and `verified_by:` record when someone last executed the procedure end
to end and **observed it work** — not when the file was last edited. That is the field
that separates a runbook from prescriptive documentation.

## Status

| Status | Meaning | Who transitions | When |
| --- | --- | --- | --- |
| `current` | Last execution succeeded; believed to match the substrate | Operator | On successful end-to-end execution |
| `stale` | Substrate known or suspected to have changed; unverified | Anyone | On a failed step, or a substrate change notice |
| `superseded` | Replaced by another runbook; links to its replacement | Operator | When replaced |

Runbooks do **not** use the FS/PLAN `draft → approved → implemented` model. That model
describes work moving toward completion. A runbook describes a procedure that either
still matches reality or does not.

`stale` is deliberately cheap to set and needs no review. A runbook that has quietly
stopped matching its substrate is more dangerous than one flagged unverified — the
failure mode to defend against is the one that leaves things *looking* governed.

## Required sections

Every runbook contains, in order:

1. **Preconditions** — access, credentials, permissions, stated as checkable facts.
2. **Procedure** — numbered steps. Each states the action, the expected observable
   result, and what to do when the result differs.
3. **Deviations Observed** — where the substrate did not behave as its governing
   binding claimed. **Mandatory even when empty**, recorded as "None observed on
   `<date>`". An absent section is indistinguishable from an unexamined one.
4. **Rollback** — how to undo it, or an explicit statement that it is not reversible.
5. **Verification** — how to confirm afterward that the procedure took effect.

Use `templates/core/runbook.md`.

## When a procedure fails partway

Set `status: stale`, record the failing step under Deviations Observed, and leave the
runbook in place. Deleting a runbook that failed destroys the evidence that its binding
is wrong.

## Index maintenance

**Agents MUST update the table below when** adding a runbook or changing a runbook's
status. This is part of the document hygiene gate in `roles/ROLE_CONTRACT.md`.

## Current Runbooks

| ID | Title | Substrate | Status |
| --- | --- | --- | --- |

*No runbooks yet. The first is the GitHub Issues and Projects provisioning procedure —
see `BACKLOG.md`.*
