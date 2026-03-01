# Change Plans

Change Plans (PLAN-XXXX) define the concrete implementation steps for approved feature specs.

**Agents MUST update this file when adding new plans or changing plan statuses.**

## Naming Convention

Change Plans follow the pattern: `PLAN-XXXX-descriptive-name.md`

- **Prefix:** `PLAN`
- **ID:** Sequential 4-digit number (PLAN-0001, PLAN-0002, etc.)
- **Description:** Kebab-case, descriptive title
- **Location:** This directory (`docs/change-plans/`)

## Lifecycle

Change Plans progress through the following statuses:

1. **Draft:** Under development
2. **Approved:** Ready for execution
3. **In-progress:** Execution underway
4. **Implemented:** All steps complete

See `workflows/document-lifecycle.md` for transition rules.

## Template

All change plans must use the template defined in `templates/core/change-plan.md`.

## Current Plans

| ID | Title | Related Spec | Status |
|---|---|---|---|
| PLAN-0001 | Implement FS-0003 Git/GH CLI Conventions | FS-0003 | approved |
| PLAN-0002 | Implement FS-0004 Agent Commentary Policy | FS-0004 | draft |
| PLAN-0003 | Implement FS-0005 Expand Docs Linting | FS-0005 | draft |
| PLAN-0004 | Markdownlint Integration for ADRs | FS-0001 | approved |
| PLAN-0005 | Move Workflow Skills into agent-dev-kit | FS-0002 | approved |
| PLAN-0006 | Implement FS-0006 JavaScript Guidelines | FS-0006 | approved |
| PLAN-0007 | Implement FS-0007 Versioning/Releases | FS-0007 | approved |
| PLAN-0008 | Implement FS-0008 Self-Versioning | FS-0008 | approved |
| PLAN-0009 | Vendor Upstream Specs | FS-0009 | approved |
| PLAN-0010 | Implement FS-0010 Process Compliance Gates | FS-0010 | implemented |
| PLAN-0011 | Adopt GitHub Projects for Work Tracking | FS-0011 | implemented |
| PLAN-0012 | Renumber Feature Specs to Sequential IDs | FS-0012 | implemented |
