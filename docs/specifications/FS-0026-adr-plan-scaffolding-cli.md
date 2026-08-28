---
type: feature-spec
id: FS-0026
status: draft
title: ADR and PLAN scaffolding CLI — npm run new:adr and npm run new:plan
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/new-adr.sh"
  - "scripts/new-plan.sh"
  - "package.json"
  - "scripts/README.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
related_adrs: []
supersedes: []
requires: []
tags: [cli, scaffolding, adr, plan, developer-experience]
created: 2026-08-28
updated: 2026-08-28
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

# Feature Spec: ADR and PLAN Scaffolding CLI

## Status

- Draft

## Plan Status

- **PLAN-0026 is `draft`.** This spec and its plan are authored together in the
  same change; neither is approved yet. Implementation of the CLI (PR #88) is
  currently in review and will be reconciled with this governing spec before
  merge.

## Summary

Creating a new ADR or PLAN in this framework requires manual template copying,
sequential-ID generation, frontmatter authoring, and index updates. This spec
defines two CLI commands that scaffold governed documents with correct
frontmatter and filenames:

- `npm run new:adr` — scaffolds a new ADR in `docs/decisions/`
- `npm run new:plan` — scaffolds a new PLAN from an existing ADR

## Goals

- A contributor can scaffold a new ADR with correct frontmatter, sequential ID,
  and filename in one command.
- A contributor can scaffold a draft PLAN from an existing ADR, carrying over
  the ADR's context, decision, and consequences.
- Both commands support `--dry-run` (print to stdout, write nothing) and
  non-interactive `--title` mode.
- Generated documents pass `npm run lint:adrs` / `npm run lint:plans` and
  `npm run check:status` (index rows added by the scaffolder or documented as
  a required follow-up step).

## Non-Goals

- **Editing the vendored MADR template.** Generation uses a built-in template
  string so output is stable regardless of submodule state.
- **Automated index updates.** The scaffolder prints the index-update step as a
  follow-up; it does not edit `docs/decisions/README.md` or
  `docs/change-plans/README.md` itself.
- **Interactive editing of existing documents.** These commands create new
  documents only.

## Success Criteria

1. `npm run new:adr -- --title "X"` creates `docs/decisions/ADR-<next>-<slug>.md`
   with `type: adr`, `status: proposed`, `created`/`updated` set to today, and
   the standard section headings.
2. `npm run new:adr --dry-run --title "X"` prints the would-be file content and
   filename without writing anything.
3. `npm run new:plan -- --adr docs/decisions/ADR-0034-*.md` creates a draft
   PLAN referencing the ADR's `related_specs`/`related_adrs` (including
   multi-line YAML list form) and carrying over the ADR's Consequences section
   (whether top-level `## Consequences` or `### Consequences` under Decision
   Outcome).
4. `--title` as the last argument does not crash under `set -u`; it reports a
   clear error.
5. Generated ADR content preserves quotes and apostrophes in user input
   verbatim (no backslash escaping artifacts).
6. The next-ADR-number computation is base-10 and correct for IDs with leading
   zeros (e.g. ADR-0008 → next is ADR-0009, not ADR-00081).

## Out of Scope

- Cross-repo scaffolding (running from a consumer repo that vendors this
  framework).
- PLAN → ADR reverse scaffolding.
- Batch generation of multiple documents in one invocation.
