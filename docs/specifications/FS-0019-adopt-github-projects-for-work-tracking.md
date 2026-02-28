---
type: feature-spec
id: FS-0019
status: draft
title: Adopt GitHub Projects for work tracking
owner: Tai
test_required: false
interfaces:
  - GitHub Projects (UI + API)
  - gh CLI
  - config/project.yml
related_adrs: []
supersedes: []
requires: []
tags:
  - workflow
  - tracking
created: 2026-02-28
updated: 2026-02-28
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

# Feature Spec: Adopt GitHub Projects for work tracking

## Status

- Draft

## Summary

Adopt GitHub Projects (v2) for tracking work in the agentic-dev-kit repository. This creates a per-repo GitHub Project board with standardized columns and custom fields, backfills all existing Feature Specs and Change Plans as GitHub Issues, and documents the board configuration. This is a propagation adoption from pack-protocol's ADR-0001 and ADR-0002, which established per-repo boards with an org-level rollup as the Tais-Den tracking standard.

## Goals

- Create a GitHub Project board for agentic-dev-kit with standardized columns (Backlog, Approved, In Progress, In Review, Done).
- Backfill GitHub Issues for all existing FS and PLAN documents (including completed ones) for historical traceability.
- Add a "Doc Type" custom field (FS, PLAN, Task, Bug) for filtering.
- Enable auto-add so new issues automatically appear on the board.
- Document the board ID/URL and field metadata in `config/project.yml`.
- Reference the board in `README.md`.
- Keep FS/PLAN/ADR markdown files as the authoritative governance artifacts; the board is a dashboard layer.

## Non-Goals

- Creating the org-level rollup board (that's pack-protocol's responsibility).
- Modifying the agentic-dev-kit document lifecycle or governance model.
- Building custom GitHub Actions or webhooks for board automation.
- Migrating any non-code tracking (Trello, etc.).
- Automating status sync between markdown front matter and board columns.

## Users / Stakeholders

- Tai — needs at-a-glance status of agentic-dev-kit work items.
- Marten — needs programmatic read/write access to the board via `gh` CLI.
- Future agents working in this repo — will create/update issues as part of governed work.

## Interfaces

- Type: UI
  - Details: GitHub Project board for agentic-dev-kit with board view. Columns: Backlog, Approved, In Progress, In Review, Done.
- Type: CLI
  - Details: `gh project list`, `gh project item-list`, `gh project item-create`, `gh project item-edit`, `gh project field-list`.
- Type: Config
  - Details: `config/project.yml` documenting board number, URL, field IDs, and column option IDs.

## Success Criteria

Each bullet MUST be objectively testable.

**Board structure:**

- Given the agentic-dev-kit GitHub Project exists, when viewing it in the UI, then it shows a board view with columns: Backlog, Approved, In Progress, In Review, Done.
- Given the project board exists, when running `gh project field-list` for the board, then a "Doc Type" single-select field exists with options: FS, PLAN, Task, Bug.

**Backfill:**

- Given all FS documents (FS-0001 through FS-0019, including this spec), when listing project items, then each has a corresponding GitHub Issue on the board with the correct Status column and Doc Type = FS.
- Given all PLAN documents (PLAN-0001 through PLAN-0011, including this plan's companion), when listing project items, then each has a corresponding GitHub Issue on the board with the correct Status column and Doc Type = PLAN.
- Given a completed FS or PLAN (status: implemented), when viewing the board, then its issue appears in the Done column.

**Auto-add:**

- Given auto-add is enabled for the project, when a new issue is created in the agentic-dev-kit repo, then it automatically appears on the board in the Backlog column.

**Configuration:**

- Given `config/project.yml` exists, when read, then it contains the project number, URL, field IDs for Status and Doc Type, and option IDs for each column/doc-type value.

**Documentation:**

- Given `README.md` is read, then it contains a reference to the project board URL.

## Edge Cases

- FS-0012 and FS-0013 are still in `draft` status — their issues should land in the Backlog column, not Approved.
- Some FS documents (FS-0001, FS-0002) are `approved` but have no corresponding PLAN that reached `implemented` — place them in Approved.
- Issue #26 (this propagation issue) already exists — it should be added to the board and linked to this FS.

## Out of Scope

- Org-level rollup board creation or configuration.
- GitHub Actions or webhooks triggered by board changes.
- Automated markdown-to-board status sync tooling.
- Changes to the document lifecycle workflow.
- Sprint planning, velocity metrics, or time tracking.

## Dependencies

- `gh` CLI with `project` scope (PAT or OAuth).
- GitHub org (Tais-Den) supports org-level Projects for private repos.
- pack-protocol ADR-0001 and ADR-0002 as the governing cross-cutting decisions.

## Rollout / Migration

1. Create the GitHub Project board for agentic-dev-kit.
2. Configure columns and custom fields.
3. Enable auto-add workflow via GitHub UI.
4. Create labels (`spec`, `plan`) in the repo if they don't exist.
5. Backfill issues for all existing FS and PLAN documents.
6. Add all issues to the board with correct Status and Doc Type.
7. Create `config/project.yml` with board metadata.
8. Update `README.md` with board reference.
9. Validate via `gh project item-list`.

## Open Questions

None — the pattern is established by pack-protocol's reference implementation.
