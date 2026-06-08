# Feature Specifications

Feature Specs (FS-XXXX) document the requirements and acceptance criteria for implementing features, tools, and processes in agentic-dev-kit.

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

## Template

All feature specs must use the template defined in `templates/core/feature-spec.md`.

## Current Specifications

| ID | Title | Status |
|---|---|---|
| FS-0001 | Markdownlint Integration | implemented |
| FS-0002 | Move Workflow Skills into agent-dev-kit | approved |
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
