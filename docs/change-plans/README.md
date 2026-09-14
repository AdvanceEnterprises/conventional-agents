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
5. **Deprecated:** Abandoned before implementation; will not be executed

See `workflows/document-lifecycle.md` for transition rules.

## Template

All change plans must use the template defined in `templates/core/change-plan.md`.

## Current Plans

| ID | Title | Related Spec | Status |
|---|---|---|---|
| PLAN-0001 | Implement FS-0003 Git/GH CLI Conventions | FS-0003 | implemented |
| PLAN-0002 | Implement FS-0004 Agent Commentary Policy | FS-0004 | deprecated |
| PLAN-0003 | Implement FS-0005 Expand Docs Linting | FS-0005 | implemented |
| PLAN-0004 | Markdownlint Integration for ADRs | FS-0001 | implemented |
| PLAN-0005 | Move Workflow Skills into conventional-agents | FS-0002 | deprecated |
| PLAN-0006 | Implement FS-0006 JavaScript Guidelines | FS-0006 | implemented |
| PLAN-0007 | Implement FS-0007 Versioning/Releases | FS-0007 | implemented |
| PLAN-0008 | Implement FS-0008 Self-Versioning | FS-0008 | implemented |
| PLAN-0009 | Vendor Upstream Specs | FS-0009 | implemented |
| PLAN-0010 | Implement FS-0010 Process Compliance Gates | FS-0010 | implemented |
| PLAN-0011 | Adopt GitHub Projects for Work Tracking | FS-0011 | implemented |
| PLAN-0012 | Renumber Feature Specs to Sequential IDs | FS-0012 | implemented |
| PLAN-0013 | Implement FS-0013 Status Consistency Check | FS-0013 | implemented |
| PLAN-0014 | Implement FS-0014 Role Definitions Overhaul | FS-0014 | implemented |
| PLAN-0015 | Implement FS-0015 Role Selection and Session Modes | FS-0015 | implemented |
| PLAN-0016 | Implement FS-0016 Framework Internal Vendor Boundary | FS-0016 | implemented |
| PLAN-0017 | Implement FS-0017 Single-identity commit attribution | FS-0017 | implemented |
| PLAN-0018 | Implement FS-0018 Issue Lifecycle and Autonomous Triggers | FS-0018 | implemented |
| PLAN-0019 | Implement FS-0019 Multi-Model Consensus at Workflow Gates | FS-0019 | implemented |
| PLAN-0020 | Implement FS-0020 SDLC workflows | FS-0020 | implemented |
| PLAN-0021 | Implement FS-0021 Review board | FS-0021 | implemented |
| PLAN-0022 | Implement FS-0022 Gate coverage | FS-0022 | implemented |
| PLAN-0023 | Implement FS-0023 Runbook document type | FS-0023 | implemented |
| PLAN-0024 | Implement FS-0024 Portable governance gates | FS-0024 | implemented |
| PLAN-0026 | Implement FS-0026 ADR and PLAN scaffolding CLI | FS-0026 | implemented |
| PLAN-0034 | Implement ADR-0034 MCP tool category and GitHub skills consolidation | ADR-0034 | deprecated |
| PLAN-0027 | Implement FS-0027 Workflow and guideline freshness gate | FS-0027 | implemented |
| PLAN-0035 | Implement FS-0029 Executable layer for the GitHub binding | FS-0029 | implemented |
| PLAN-0028 | Implement FS-0028 ADR supersession chain gate | FS-0028 | implemented |
| PLAN-0036 | Implement FS-0030 Claude Code runtime binding | FS-0030 | implemented |
| PLAN-0037 | Implement FS-0031 Governed-agent benchmark harness | FS-0031 | draft |
| PLAN-0039 | Implement FS-0033 Governance CI on stacked and non-trunk PRs | FS-0033 | draft |
| PLAN-0041 | Implement FS-0035 Portable flow-report read-model | FS-0035 | draft |
| PLAN-0043 | Implement FS-0037 Vendor-prefixed reference resolution | FS-0037 | draft |
| PLAN-0044 | Implement FS-0038 Hermes kanban substrate binding | FS-0038 | draft |
| PLAN-0045 | Implement FS-0039 Validation reproducibility contract | FS-0039 | implemented |
