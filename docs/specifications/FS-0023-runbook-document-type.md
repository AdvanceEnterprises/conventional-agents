---
type: feature-spec
id: FS-0023
status: implemented
title: Runbook document type — operational procedures recorded as performed
owner: ajoeofalltrades
test_required: true
interfaces:
  - "runbooks/README.md"
  - "templates/core/runbook.md"
  - "workflows/document-lifecycle.md"
  - "README.md"
  - "AGENTS.md"
  - "docs/specifications/README.md"
  - "scripts/check-status.sh"
  - "package.json"
  - ".github/workflows/lint-docs.yml"
  - "test/FS-0023/runbook-convention.bats"
related_adrs:
  - ADR-0024
  - ADR-0027
  - ADR-0030
supersedes: []
requires: []
tags: [documentation, operations, runbooks, exported-surface]
created: 2026-07-29
updated: 2026-08-01
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

# Feature Spec: Runbook Document Type

## Status

- Approved

## Plan Status

- **PLAN-0023 is `approved`**, approved in the same session as this FS.

## Summary

The framework has no runbook convention. The word appears in exactly one file —
`BACKLOG.md` — where the next planned unit of work is "implement the GitHub guidance
on this repository, and write the runbook." There is no location, no template, no
lifecycle, and no entry in `workflows/document-lifecycle.md`, which recognises work
items, FS, PLAN, and ADR and nothing else.

That is a gap with a deadline. The next session performs the
`integrations/github-issues-projects.md` Setup Checklist against a live repository and
produces a runbook from it. Absent a convention, that session invents one under
delivery pressure, and the framework acquires a fifth document type by accident —
the precise failure `ADR-0030` exists to prevent.

**A runbook is a current-state document under `ADR-0030`.** It records an operational
procedure *as performed against a real substrate*, not as designed. This distinguishes
it from the two neighbouring surfaces:

| Surface | Answers | Tense |
| --- | --- | --- |
| `workflows/` | How work *should* proceed | Prescriptive |
| `integrations/` | How a core capability *maps* onto a substrate | Declarative |
| `runbooks/` | What was *actually done*, in order, and what the substrate did back | Past, observed |

The distinction is load-bearing rather than taxonomic. `integrations/github-issues-projects.md`
already concedes that three of six capabilities are "convention + detection" rather
than enforced, and its §6 documents that GitHub Actions schedules are disabled after
60 days of repository inactivity. Those are claims about a substrate that changes
without notice. A runbook is where the difference between the binding and the
substrate's actual behaviour gets recorded — so deviations become findings that flow
back into the binding, rather than folklore held by whoever ran the procedure.

## Goals

1. Establish `runbooks/` at the repository root as an **exported surface**, sibling to
   `workflows/` and `integrations/`, so host repositories that vendor the framework
   receive runbooks and can copy them as starting points.
2. Define a runbook's front matter, status vocabulary, and identity scheme (`RB-NNNN`).
3. Ship `templates/core/runbook.md` so the next session scaffolds rather than invents.
4. Add a Runbooks section to `workflows/document-lifecycle.md` alongside the existing
   FS / PLAN / ADR sections.
5. Extend the framework's own definition of its exported surface to include
   `runbooks/`, in **every** place that definition is enumerated.
6. Bring `runbooks/` under the lint chain and CI path triggers.

## Non-Goals

- **Automated staleness detection.** A runbook goes stale when its substrate changes
  underneath it, and the framework currently has zero runbooks. Building a check for a
  drift pattern nobody has observed would be guessing. Deferred to `BACKLOG.md`,
  revisited once real runbooks exist. `last_verified:` is recorded so the data is
  available when the check is written; nothing reads it yet, and this spec does not
  claim otherwise.
- **Writing any actual runbook.** This spec establishes the type. The GitHub
  provisioning runbook is the next unit of work and is authored against a live
  repository, not from this document.
- **A runbook index consistency check** in `scripts/check-status.sh` equivalent to the
  FS/PLAN/ADR index checks. Same reasoning: deferred until there is more than one row
  to keep in sync.
- Retrofitting existing operational prose scattered through `workflows/` into runbooks.

## Users / Stakeholders

- **Operators** (human or agent) executing a provisioning or recovery procedure against
  a live substrate.
- **Consumer repositories** vendoring the framework, which copy a runbook as the
  starting point for their own provisioning and adapt the deviations.
- **Role 0 (Head Architect)**, for whom a runbook's recorded deviations are the
  evidence that a binding in `integrations/` needs revision.

## Behavior

### 1. Location and identity

Runbooks live in `runbooks/` at the repository root. Filenames follow
`RB-NNNN-short-description.md`, matching the `FS-NNNN-description.md` convention.
IDs are allocated first-come-on-merge, as with every other document type in this
framework.

`runbooks/README.md` is the index, carrying the same obligations as
`docs/specifications/README.md`: agents MUST update it when adding a runbook or
changing a runbook's status.

### 2. Front matter

```yaml
---
type: runbook
id: RB-0001
title: <what this procedure accomplishes>
status: current
substrate: <the system this operates against, e.g. "GitHub Issues + Projects v2">
governs: <the integrations/ binding or workflows/ doc this operationalises, if any>
last_verified: YYYY-MM-DD
verified_by: "Name <email>"
related_adrs: []
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

`last_verified:` and `verified_by:` are the fields that distinguish a runbook from
prescriptive documentation. They record when a human or agent last executed the
procedure end to end and observed it work — not when the file was last edited.

### 3. Status vocabulary

A runbook does not use the FS/PLAN `draft → approved → implemented` model. That model
describes work moving toward completion; a runbook describes a procedure that either
still matches reality or does not.

| Status | Meaning | Who transitions | When |
| --- | --- | --- | --- |
| `current` | Last execution succeeded; believed to match the substrate | Operator | On successful end-to-end execution |
| `stale` | Substrate is known or suspected to have changed; unverified | Anyone | On a failed step, or a substrate change notice |
| `superseded` | Replaced by another runbook; links to its replacement | Operator | When replaced |

`stale` is deliberately cheap to set and requires no review. A runbook that silently
stops matching its substrate is more dangerous than one flagged as unverified, and the
framework's own `ADR-0028` reasoning applies: the failure mode to defend against is the
one that leaves things *looking* governed.

### 4. Required sections

Every runbook contains, in order:

1. **Preconditions** — access, credentials, and permissions required, stated as
   checkable facts.
2. **Procedure** — numbered steps. Each step states the action, the expected
   observable result, and what to do when the result differs.
3. **Deviations observed** — where the substrate did not behave as the governing
   binding or workflow claimed. **This section is mandatory and may not be omitted
   when empty**; it is recorded as "None observed on `<date>`". An absent section is
   indistinguishable from an unexamined one.
4. **Rollback** — how to undo the procedure, or an explicit statement that it is not
   reversible.
5. **Verification** — how to confirm afterward that the procedure took effect.

The Deviations section is the point of the document type. It is what converts a
one-time provisioning exercise into a correction that flows back into
`integrations/`.

### 5. Exported-surface registration

`runbooks/` is consumer-facing. The framework enumerates its exported surface in five
places, with no single source of truth:

| Location | Form |
| --- | --- |
| `README.md` | "Exported surface" table |
| `AGENTS.md` | Two-column surface table |
| `docs/specifications/README.md` | Prose list in the consumer-impact rule |
| `scripts/check-status.sh` | `EXPORTED_PREFIXES` array |
| `package.json` + `.github/workflows/lint-docs.yml` | Lint globs and CI path triggers |

All five MUST list `runbooks/`. Updating four of five would produce exactly the class
of silent inconsistency this PR has spent its length removing: a directory that is
exported for humans reading `README.md` but invisible to the consumer-impact gate.

That five-way duplication is itself a defect. Recording it here rather than fixing it
is deliberate — collapsing it to one source of truth is a change to
`scripts/check-status.sh` and every document that reads from it, which is its own spec.
It is filed in `BACKLOG.md`.

### 6. Lint coverage

`runbooks/` inherits the root `.markdownlint.yml` (`default: true`) and carries no
per-directory config. `package.json` gains `lint:runbooks`, added to the `lint:docs`
chain. `.github/workflows/lint-docs.yml` gains `runbooks/**/*.md` to both path
trigger lists.

## Success Criteria

1. **Given** the repository, **when** listing the root, **then** `runbooks/` exists and
   contains `README.md`.
2. **Given** `runbooks/README.md`, **when** read, **then** it states the `RB-NNNN`
   naming convention and contains an index table with the header
   `| ID | Title | Substrate | Status |`.
3. **Given** `templates/core/runbook.md`, **when** read, **then** it contains front
   matter with `type: runbook`, `status:`, `substrate:`, `last_verified:`, and
   `verified_by:` keys.
4. **Given** `templates/core/runbook.md`, **when** read, **then** it contains all five
   required section headings: Preconditions, Procedure, Deviations Observed, Rollback,
   Verification.
5. **Given** `workflows/document-lifecycle.md`, **when** read, **then** it contains a
   `## Runbooks (RB)` section with a status table naming `current`, `stale`, and
   `superseded`.
6. **Given** `scripts/check-status.sh`, **when** read, **then** `EXPORTED_PREFIXES`
   contains `runbooks/`.
7. **Given** `README.md`, **when** read, **then** its exported-surface table lists
   `runbooks/`.
8. **Given** `AGENTS.md`, **when** read, **then** its surface table lists `runbooks/`.
9. **Given** `docs/specifications/README.md`, **when** read, **then** its
   exported-surface prose list names `runbooks/`.
10. **Given** `package.json`, **when** read, **then** a `lint:runbooks` script exists
    and `lint:docs` invokes it.
11. **Given** `.github/workflows/lint-docs.yml`, **when** read, **then**
    `runbooks/**/*.md` appears in both the `push` and `pull_request` path lists.
12. **Given** `npm run lint:docs`, **when** run, **then** it exits zero with
    `runbooks/` included in the chain.

## Edge Cases

- **A runbook whose procedure is never re-run.** `last_verified:` ages indefinitely and
  nothing flags it. Accepted for now — this is the deferred staleness check, and the
  field exists so that check has data to read when written.
- **A runbook for a substrate the framework ships no binding for.** `governs:` is
  optional and may be empty. A consumer's runbook for their own infrastructure is a
  legitimate use of the type.
- **Consumer runbooks colliding with framework runbook IDs.** A consumer vendoring the
  framework gets `vendor/conventional-agents/runbooks/`, and their own runbooks live in
  their own `runbooks/`. The paths do not collide because the vendored copy is nested;
  per `ADR-0017` consumers must not reference nested vendor paths, so a consumer
  copying `RB-0001` into their repository owns the copy and its numbering.
- **A procedure that fails partway.** The operator sets `status: stale`, records the
  failing step under Deviations Observed, and leaves the runbook in place. Deleting a
  runbook that failed destroys the evidence that the binding is wrong.
