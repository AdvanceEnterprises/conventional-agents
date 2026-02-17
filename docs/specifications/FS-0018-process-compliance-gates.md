---
type: feature-spec
id: FS-0018
status: approved
title: Process Compliance Gates — Spec-First Enforcement and Document Lifecycle
owner: martenoftheden
test_required: false
interfaces:
  - "guidelines/ROLE_CONTRACT.md"
  - "workflows/document-lifecycle.md (new)"
  - "workflows/README.md"
  - "templates/core/feature-spec.md"
  - "templates/core/change-plan.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "docs/decisions/README.md"
related_adrs: []
supersedes: []
requires: []
tags: [process, compliance, gates, lifecycle]
created: 2026-02-16
updated: 2026-02-16
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

# Feature Spec: Process Compliance Gates — Spec-First Enforcement and Document Lifecycle

## Status

- Approved

## Summary

Agents consistently drift from the agentic-dev-kit process in predictable ways: skipping specs before coding, not updating document statuses after implementation, forgetting to update README index files, and letting front matter metadata go stale.

This spec introduces hard gates and explicit lifecycle rules that make the expected process mechanically clear to agents, reducing the need for human re-direction on each iteration.

## Problem Statement

Observed failure modes (in order of frequency):

1. **Spec-skip**: Agent jumps straight to code when asked to implement something, bypassing FS/PLAN creation.
2. **Status drift**: FS and PLAN documents remain `approved` long after implementation is complete; no transition to `implemented`.
3. **README neglect**: `docs/specifications/README.md`, `docs/change-plans/README.md`, and `docs/decisions/README.md` are not updated when new documents are added.
4. **Front matter staleness**: The `updated:` date in YAML front matter is not bumped when documents are modified.
5. **CHANGELOG omission**: Changes are merged without corresponding CHANGELOG.md entries.
6. **Cross-reference gaps**: New FS/PLAN/ADR documents don't reference related documents in their front matter (`related_adrs`, `related_specs`), making the document graph disconnected.
7. **Interface drift**: FS declares interfaces but the implementation touches files not listed (or misses files that were listed).
8. **Premature implementation**: Agent creates a spec with `status: draft` and immediately starts implementing without waiting for approval.
9. **Unauthorized merges**: Agent merges PRs without waiting for human review and approval. PRs should only be merged by humans or after explicit human approval.
10. **Identity confusion**: When multiple GitHub accounts are logged in via `gh auth`, agents fail to verify the correct identity is active before running `gh` commands (push, PR creation, reviews), resulting in actions attributed to the wrong account.

## Goals

- Add a **spec-first gate** to ROLE_CONTRACT that blocks implementation without an approved FS
- Define an explicit **document status lifecycle** with transition rules and responsible parties
- Add a **pre-commit/PR checklist** that catches status drift, README neglect, and CHANGELOG omission
- Make **README update requirements** explicit for each docs subdirectory
- Add **front matter hygiene rules** (updated dates, cross-references)
- Add a **merge prohibition** to ROLE_CONTRACT: agents must not merge PRs without human approval
- Add a **GitHub identity verification gate**: agents must confirm the active `gh` account before any GitHub CLI operation
- Codify all of the above in a new `workflows/document-lifecycle.md` and updates to ROLE_CONTRACT

## Non-Goals

- Building CI tooling to mechanically enforce these gates (that's a separate effort)
- Changing the FS/PLAN/ADR templates structurally (only adding lifecycle guidance)
- Prescribing specific agent architectures (sub-agents, orchestrators, etc.)
- Retroactively fixing all existing documents (separate cleanup task)

## Users / Stakeholders

- AI agents operating under agentic-dev-kit governance
- Humans directing agent work who want less per-iteration correction
- agentic-dev-kit maintainers

## Interfaces

### New file

- **`workflows/document-lifecycle.md`** — defines status values, transition rules, responsible parties, and the pre-commit/PR checklist for document hygiene

### Modified files

- **`guidelines/ROLE_CONTRACT.md`** — add spec-first gate, merge prohibition, identity verification gate, pre-commit document checklist, and reference to document-lifecycle workflow
- **`workflows/git-and-gh-conventions.md`** — reinforce identity verification and merge prohibition in the standard workflow
- **`workflows/README.md`** — add entry for new document-lifecycle workflow
- **`docs/specifications/README.md`** — add explicit requirement that this file must be updated when specs are added/change status
- **`docs/change-plans/README.md`** — same requirement for change plans
- **`docs/decisions/README.md`** — same requirement for ADRs (may already be partially covered)

## Detailed Design

### 1. Spec-First Gate (ROLE_CONTRACT addition)

Add to "Shared Rules" in ROLE_CONTRACT:

> **Spec-first rule**
>
> Before writing any implementation code (production or test), verify:
>
> 1. A feature spec (FS-XXXX) with `status: approved` exists for this work.
> 2. A change plan (PLAN-XXXX) with `status: approved` exists that references the FS.
> 3. If neither exists, your first deliverable is the spec and plan — not code.
>
> Exceptions:
>
> - Trivial fixes (typos, broken links, formatting) do not require a spec.
> - Emergency hotfixes may be implemented first, but a retroactive FS must be filed before the next feature begins.
>
> If you are unsure whether work qualifies as "trivial," it does not. Write the spec.

### 2. Document Status Lifecycle (new workflow)

Define in `workflows/document-lifecycle.md`:

**Feature Specs (FS):**

| Status | Meaning | Who transitions | When |
|---|---|---|---|
| `draft` | Under development, not ready for implementation | Agent or human creates | Initial creation |
| `approved` | Reviewed and ready for implementation | Human approves (merge of spec PR) | After review |
| `in-progress` | Implementation actively underway | Agent sets when starting PLAN execution | First implementation commit |
| `implemented` | All PLAN steps complete, PR merged | Agent sets in the completing PR | Same PR that finishes implementation |
| `deprecated` | No longer active | Human or agent | When superseded or abandoned |

**Change Plans (PLAN):**

| Status | Meaning | Who transitions | When |
|---|---|---|---|
| `draft` | Under development | Agent or human creates | Initial creation |
| `approved` | Ready for execution | Human approves (merge of plan PR) | After review |
| `in-progress` | Execution underway | Agent sets when starting | First implementation commit |
| `implemented` | All steps complete | Agent sets in the completing PR | Same PR that finishes implementation |

**ADRs** — already defined in `docs/decisions/README.md` (proposed → accepted → deprecated/superseded). No changes needed.

**Transition rules:**

- Only move forward: `draft → approved → in-progress → implemented`. No backward transitions without human approval.
- `draft → approved` requires human review (PR merge).
- `approved → in-progress` is set by the agent when beginning execution.
- `in-progress → implemented` MUST happen in the same PR that completes the work.
- Agents MUST NOT implement a spec with `status: draft`.

### 3. Pre-Commit/PR Document Checklist (ROLE_CONTRACT addition)

Add to ROLE_CONTRACT under a new "Document hygiene gate" section:

> Before marking a PR as ready for review, verify:
>
> 1. **Status fields are current**: All FS and PLAN documents referenced by this PR have accurate `status:` values.
> 2. **`updated:` dates are current**: Any modified FS/PLAN/ADR has its `updated:` front matter field set to today's date.
> 3. **README index files are current**: If you added or changed the status of a document in `docs/specifications/`, `docs/change-plans/`, or `docs/decisions/`, the corresponding `README.md` in that directory reflects the change.
> 4. **CHANGELOG entry exists**: If this PR introduces a user-visible change (feature, fix, breaking change), there is a corresponding entry in `CHANGELOG.md` under `[Unreleased]` or the appropriate version section.
> 5. **Cross-references are complete**: FS `related_adrs` and PLAN `related_specs` front matter fields reference all relevant companion documents.
> 6. **Interfaces match reality**: The files touched by this PR align with the `interfaces:` declared in the governing FS. If they diverge, update the FS or explain in the PR description.

### 4. Merge Prohibition (ROLE_CONTRACT addition)

Add to "Shared Rules" in ROLE_CONTRACT:

> **PR merge rule**
>
> Agents MUST NOT merge pull requests. Merging is a human-gated action.
>
> - Agents may open PRs, update PRs, and request review.
> - Agents MUST NOT run `gh pr merge`, `git push` to the default branch, or any equivalent merge action.
> - Even if a human verbally approves in chat, the human (or CI triggered by human approval) performs the actual merge.
>
> This is non-negotiable and cannot be overridden by project-specific rules.

### 5. GitHub Identity Verification Gate (ROLE_CONTRACT addition)

Add to "Shared Rules" in ROLE_CONTRACT:

> **GitHub identity gate**
>
> Before any `gh` CLI operation (push, PR creation, review, comment) or `git push`, the agent MUST:
>
> 1. Run `gh auth status` and verify the active account is the expected agent-committer identity.
> 2. If the wrong account is active, run `gh auth switch --user <correct-username>` before proceeding.
> 3. Never assume the correct account is active from a previous session or command.
>
> This applies every time — not just the first operation in a session. Identity can change between operations if other tools or agents share the environment.

### 6. README Index Requirements

Each docs subdirectory README should include:

- A table or list of all documents in that directory with their current status
- An explicit note: "Agents MUST update this file when adding new documents or changing document statuses."

## Success Criteria

- Given ROLE_CONTRACT, when reading the "Shared Rules" section, then a "Spec-first rule" subsection exists that requires an approved FS and PLAN before implementation code
- Given ROLE_CONTRACT, when reading it, then a "Document hygiene gate" subsection exists with a 6-item pre-commit/PR checklist
- Given `workflows/document-lifecycle.md`, when reading it, then it defines status values and transition rules for FS, PLAN, and ADR documents in table format
- Given `workflows/document-lifecycle.md`, when reading it, then it specifies who is responsible for each transition and when it must happen
- Given `workflows/document-lifecycle.md`, when reading it, then it explicitly states agents MUST NOT implement a spec with `status: draft`
- Given `workflows/README.md`, when reading it, then it lists the document-lifecycle workflow
- Given `docs/specifications/README.md`, when reading it, then it includes a note requiring agents to update the file when adding specs or changing statuses
- Given `docs/change-plans/README.md`, when reading it, then it includes a note requiring agents to update the file when adding plans or changing statuses
- Given `docs/decisions/README.md`, when reading it, then it includes a note requiring agents to update the file when adding ADRs or changing statuses
- Given ROLE_CONTRACT, when reading it, then a "PR merge rule" subsection exists that prohibits agents from merging PRs and states this cannot be overridden
- Given ROLE_CONTRACT, when reading it, then a "GitHub identity gate" subsection exists that requires `gh auth status` verification before every `gh` or `git push` operation

## Edge Cases

- **Trivial fixes**: The spec-first gate includes an explicit exception for typos, formatting, and broken links to avoid bureaucratic overhead on trivial work.
- **Emergency hotfixes**: Allowed to skip spec-first, but retroactive spec is required.
- **Multi-PR implementations**: A PLAN may span multiple PRs. Status should be `in-progress` until the final PR, which sets `implemented`.
- **Specs that are never implemented**: Should be set to `deprecated` with a note explaining why, not left as `approved` indefinitely.

## Out of Scope

- CI enforcement tooling (lint checks for status consistency, etc.)
- Retroactive cleanup of existing documents (separate task)
- Agent architecture recommendations (sub-agents, orchestrators)
- Changes to FS/PLAN/ADR template structure

## Dependencies

- None (this builds on existing ROLE_CONTRACT and workflow patterns)

## Open Questions

None — all design decisions are made in this spec.
