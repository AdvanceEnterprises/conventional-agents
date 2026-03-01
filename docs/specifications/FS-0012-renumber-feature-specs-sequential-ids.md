---
type: feature-spec
id: FS-0012
status: implemented
title: Renumber feature specs to sequential IDs
owner: Tai
test_required: false
interfaces:
  - docs/specifications/ (filenames + front matter)
  - docs/change-plans/ (filenames + front matter + related_specs)
  - docs/decisions/ (related_specs cross-refs)
  - CHANGELOG.md
  - GitHub Issues on project board #2
related_adrs: []
supersedes: []
requires: []
tags:
  - housekeeping
  - governance
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

# Feature Spec: Renumber feature specs to sequential IDs

## Status

- Implemented

## Summary

Feature spec IDs currently skip from FS-0002 to FS-0003 (IDs 0003–0010 were never used). This creates confusion about how many specs exist and breaks the expectation that IDs are sequential. This spec covers renumbering all FS documents to use contiguous sequential IDs and updating every reference across the repository and GitHub Project board.

## ID Mapping

| Old ID | New ID | Title |
|---|---|---|
| FS-0001 | FS-0001 | Markdownlint Integration for ADR Quality Gates |
| FS-0002 | FS-0002 | Move Workflow Skills into agentic-dev-kit |
| ~~FS-0011~~ | **FS-0003** | Git + gh CLI Conventions |
| ~~FS-0012~~ | **FS-0004** | Agent-Authored Commit/PR Commentary Policy |
| ~~FS-0013~~ | **FS-0005** | Expand Docs Linting Coverage |
| ~~FS-0014~~ | **FS-0006** | JavaScript/TypeScript Guidelines |
| ~~FS-0015~~ | **FS-0007** | Versioning, Releases, and Packaging Guidance |
| ~~FS-0016~~ | **FS-0008** | Apply Versioning and Changelog to agentic-dev-kit Itself |
| ~~FS-0017~~ | **FS-0009** | Vendor Upstream Specs |
| ~~FS-0018~~ | **FS-0010** | Process Compliance Gates and Document Lifecycle |
| ~~FS-0019~~ | **FS-0011** | Adopt GitHub Projects for Work Tracking |
| ~~FS-0020~~ | **FS-0012** | Renumber Feature Specs to Sequential IDs (this spec) |

After renumbering, the next new spec will be **FS-0013**.

## Goals

- Eliminate the ID gap (FS-0003 through FS-0010 unused).
- Ensure all cross-references are updated atomically in a single PR.
- Update GitHub Issues on the project board to reflect new IDs.
- Preserve full traceability (old ID → new ID documented in this spec and CHANGELOG).

## Non-Goals

- Renumbering PLAN or ADR IDs (PLANs reference FS IDs and will be updated, but PLAN numbering itself stays).
- Changing any spec content beyond ID, filename, and cross-references.
- Modifying the ID allocation scheme going forward (sequential from next available remains the convention).

## Users / Stakeholders

- Tai — wants clean sequential IDs.
- Marten — executes the renumbering.
- Future contributors — benefit from non-confusing ID sequence.

## Interfaces

- Type: Files
  - Details: All FS filenames in `docs/specifications/`, all PLAN filenames and `related_specs:` fields in `docs/change-plans/`, all ADR `related_specs:` fields in `docs/decisions/`, `docs/specifications/README.md`, `docs/change-plans/README.md`, `docs/decisions/README.md`, `CHANGELOG.md`, `docs/ARC42.md`.
- Type: GitHub Issues
  - Details: All FS-labeled issues on project board #2 need title updates. All PLAN-labeled issues that reference FS IDs in their titles need title updates.
- Type: GitHub Project
  - Details: No structural board changes; only issue title/body updates.

## Success Criteria

Each bullet MUST be objectively testable.

- Given the renumbering is complete, when listing files in `docs/specifications/`, then filenames use sequential IDs from FS-0001 through FS-0012 with no gaps.
- Given the renumbering is complete, when searching the repo for any old ID (old FS-0011 through old FS-0020), then zero matches are found outside of the mapping table in this spec and the CHANGELOG migration notes.
- Given the renumbering is complete, when reading any PLAN's `related_specs:` front matter, then it references the new FS ID.
- Given the renumbering is complete, when reading any ADR's `related_specs:` front matter, then it references the new FS ID.
- Given the renumbering is complete, when viewing the GitHub Project board, then all FS issue titles use the new IDs.
- Given the renumbering is complete, when viewing PLAN issue titles on the board, then any that referenced old FS IDs now reference the new ones.

## Edge Cases

- CHANGELOG contains historical references to old IDs (e.g., "FS-0014, PLAN-0006" in the 1.1.0 entry). These should be updated with a parenthetical note: e.g., "FS-0006 (formerly FS-0014)".
- PLAN filenames contain FS IDs (e.g., `PLAN-0001-implement-fs-0011-...`). These filenames must be renamed too.
- `docs/implementation-plans/IP-0001.md` may contain FS references — check and update.
- The `test/FS-0001/` directory references FS-0001 which is unchanged, but verify no other test dirs reference old IDs.

## Out of Scope

- Renumbering ADR IDs or PLAN IDs.
- Any content changes beyond ID/filename/cross-reference updates.
- Changes to files outside this repository.

## Dependencies

- FS-0011/PLAN-0011 (GitHub Projects setup) should be merged first so the board exists to update.
- `gh` CLI with project scope for updating issue titles.

## Rollout / Migration

1. Rename all FS files (old filename → new filename).
2. Update front matter `id:` in each renamed FS.
3. Rename all PLAN files whose filenames contain old FS IDs.
4. Update `related_specs:` in all PLANs and ADRs.
5. Update all README index tables.
6. Update CHANGELOG (historical entries get parenthetical old-ID notes).
7. Update `docs/ARC42.md` and any other docs with FS references.
8. Update GitHub Issue titles and bodies via `gh` CLI.
9. Verify: `grep -r 'FS-001[1-9]\|FS-002[0-0]'` returns only the mapping table and CHANGELOG notes.

## Open Questions

None.
