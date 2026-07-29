# Feature Specifications

Feature Specs (FS-XXXX) document the requirements and acceptance criteria for implementing features, tools, and processes in conventional-agents.

**Agents MUST update this file when adding new specs or changing spec statuses.**

## Purpose

Feature Specs serve as the bridge between:

- **Architecture Decisions (ADRs):** Document the "why" of decisions (what we've decided and why)
- **Implementation:** Document the "what" of features (requirements, success criteria, rollout plan)

Unlike ADRs which record decisions made, feature specs document the concrete requirements and behaviors needed to implement those decisions.

## Naming Convention

Feature Specs follow the pattern: `FS-XXXX-descriptive-name.md`

- **Prefix:** `FS` (Feature Spec)
- **ID:** Sequential 4-digit number (FS-0001, FS-0002, etc.)
- **Description:** Kebab-case, descriptive title
- **Location:** This directory (`docs/specifications/`)

## Lifecycle

Feature Specs progress through the following statuses:

1. **Draft:** Initial creation, under development and review
2. **Approved:** Reviewed and ready for implementation
3. **In-progress:** Implementation actively underway
4. **Implemented:** Implementation work is complete
5. **Deprecated:** Spec is no longer active or has been superseded

Only specs with `status: approved` should be actively implemented. See `workflows/document-lifecycle.md` for transition rules.

## Does this spec change the exported surface?

Every spec must answer this before it is approved. It is the counterpart to
`docs/decisions/README.md` §1a: that section asks whether an ADR obliges someone to
write code, this one asks whether a spec obliges someone downstream to change.

**The answer is derivable, not declared.** A spec is consumer-affecting when its
`interfaces:` names any path in the exported surface — `guidelines/`, `roles/`,
`skills/`, `templates/`, `workflows/`, `integrations/`, `INTEGRATION.md`, or
`AGENTS.md`. Those are the paths host repositories vendor. No new front-matter field:
`interfaces:` already declares the surface area a spec may touch, and this reads it.

| The spec's `interfaces:` name | Requires |
| --- | --- |
| Internal governance only — `docs/`, `scripts/`, `package.json`, `test/`, CI | Nothing beyond the ordinary CHANGELOG entry |
| Any exported-surface path | A **consumer-framed** CHANGELOG entry in the PR that implements it |

**Consumer-framed** is the operative word, and it is `guidelines/ROLE_CONTRACT.md`
Role 5's standard: describe the change by its effect on the reader, not by the
governance ID that produced it. *"Agent commits now carry the model in the author
name, so `git log` shows which model wrote what"* is a consumer-framed entry.
*"ADR-0029 landed"* is not, and tells a downstream maintainer nothing about whether
their tooling breaks.

Worked examples from this repository:

- **`FS-0021`** (review board) names `templates/collaboration/`,
  `workflows/session-modes.md`, and `guidelines/ROLE_CONTRACT.md`. Consumer-affecting:
  a host repo vendoring the framework gets a new collaboration mode and a new mode
  value in its stance vocabulary. Requires an entry.
- **`FS-0022`** (gate coverage) names `scripts/`, `package.json`,
  `.github/workflows/`, and the docs indexes. Internal only: consumers vendor the
  documents, not this repository's CI. No consumer-framed entry required.

## Why this is symmetric with §1a

Both rules exist because a document can imply obligations it does not name. An ADR
deciding a check should exist has not authorized anyone to write it — §1a. A spec
changing something host repositories vendor has not told them it changed — this
section.

The failure modes mirror each other, and both are silent. An ADR implying code
without a governing FS produces a gate that entered CI without architectural review.
A spec changing exported surface without a consumer note produces a downstream break
whose cause is discoverable only by reading this repository's internal governance —
which is precisely what `ADR-0009`'s separation exists to spare consumers.

## Template

All feature specs must use the template defined in `templates/core/feature-spec.md`.

## Current Specifications

| ID | Title | Status |
| --- | --- | --- |
| FS-0001 | Markdownlint Integration | implemented |
| FS-0002 | Move Workflow Skills into conventional-agents | approved |
| FS-0003 | Git + GitHub CLI Conventions | implemented |
| FS-0004 | Agent-Authored Commit/PR Commentary Policy | draft |
| FS-0005 | Expand Docs Linting Coverage | implemented |
| FS-0006 | JavaScript/TypeScript Guidelines | implemented |
| FS-0007 | Versioning, Releases, and Packaging Guidance | implemented |
| FS-0008 | Self-Versioning and Changelog | implemented |
| FS-0009 | Vendor Upstream Specs | implemented |
| FS-0010 | Process Compliance Gates and Document Lifecycle | implemented |
| FS-0011 | Adopt GitHub Projects for Work Tracking | implemented |
| FS-0012 | Renumber Feature Specs to Sequential IDs | implemented |
| FS-0013 | Status Consistency Check | implemented |
| FS-0014 | Role Definitions Overhaul | implemented |
| FS-0015 | Role Selection and Session Modes | implemented |
| FS-0016 | Framework Internal Vendor Boundary | implemented |
| FS-0017 | Single-identity commit attribution with model, role, and session metadata | implemented |
| FS-0018 | Work item lifecycle and autonomous triggers for governed work | draft |
| FS-0019 | Multi-model consensus at workflow gates (optional consumer feature) | draft |
| FS-0020 | SDLC workflows — single-model and multi-model | draft |
| FS-0021 | Review board collaboration mode | draft |
| FS-0022 | Gate coverage — extend consistency, lint, and test enforcement to the whole corpus | draft |
