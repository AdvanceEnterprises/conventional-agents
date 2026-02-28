---
type: change-plan
role: implementer
status: implemented
related_specs:
  - FS-0019
related_adrs: []
created: 2026-02-28
updated: 2026-02-28
---
<!--
PARSING_HINTS:
- Document type: change-plan
- Intended role: Implementer (Role 2)
- This is a binding contract for implementation.
- If implementation would exceed this plan, the plan must be revised first.
-->

# Change Plan: Adopt GitHub Projects for work tracking

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0019
- Related ADR ID(s): pack-protocol ADR-0001, pack-protocol ADR-0002
- Issue / PR Reference: [#26](https://github.com/Tais-Den/agentic-dev-kit/issues/26)

## 2. Scope of Change

**This change WILL:**

- Create a GitHub Project board for agentic-dev-kit at the Tais-Den org level.
- Configure board columns: Backlog, Approved, In Progress, In Review, Done.
- Add custom field: Doc Type (single-select: FS, PLAN, Task, Bug).
- Create labels `spec` and `plan` in the repo (if they don't already exist).
- Enable the "Auto-add to project" workflow via GitHub UI (manual step).
- Enable built-in workflows: "Item closed → Done", "PR merged → Done" (manual step).
- Create GitHub Issues for all 11 FS documents (FS-0001, FS-0002, FS-0011 through FS-0019) and all 11 PLAN documents (PLAN-0001 through PLAN-0011), totaling 22 issues.
- Add all issues to the project board with correct Status and Doc Type fields.
- Create `config/project.yml` documenting board metadata, field IDs, and column option IDs.
- Update `README.md` with a project board reference.
- Update `docs/specifications/README.md` with FS-0019.
- Update `docs/change-plans/README.md` with PLAN-0011.
- Add a CHANGELOG entry under `[Unreleased]`.

**This change will NOT:**

- Create or modify the org-level rollup board.
- Modify the document lifecycle, ROLE_CONTRACT, or any exported surface.
- Create GitHub Actions or webhooks.
- Sync markdown front-matter statuses to/from board columns automatically.
- Affect any other repo's governance or boards.

## 3. Tests Driving This Change

No automated tests — this is infrastructure/configuration work. Validation is via CLI checks (see Section 8).

## 4. Files to Be Modified

- `docs/specifications/FS-0019-adopt-github-projects-for-work-tracking.md` (new — already drafted)
- `docs/change-plans/PLAN-0011-adopt-github-projects-for-work-tracking.md` (new — this file)
- `docs/specifications/README.md` (add FS-0019 row)
- `docs/change-plans/README.md` (add PLAN-0011 row)
- `config/project.yml` (new)
- `README.md` (add board reference)
- `CHANGELOG.md` (add entry under `[Unreleased]`)

GitHub-side (not file changes):

- GitHub Project board created
- Labels `spec` and `plan` created
- 22 issues created (11 FS + 11 PLAN)
- All issues added to board with correct fields
- Auto-add workflow enabled (manual UI step)
- Built-in close/merge workflows enabled (manual UI step)

## 5. Implementation Steps

### Phase 1: Create the project board

1. Verify identity: `gh auth status`.
2. Create the GitHub Project: `gh project create --owner Tais-Den --title "agentic-dev-kit Development"`.
3. Configure Status field columns: Backlog, Approved, In Progress, In Review, Done.
4. Add custom single-select field: Doc Type with options FS, PLAN, Task, Bug.
5. Create labels `spec` and `plan` in the repo via `gh label create`.
6. Record the project number and field/option IDs.

### Phase 2: Backfill issues

1. Create GitHub Issues for each FS document (FS-0001, FS-0002, FS-0011 through FS-0019; 11 total), labeled `spec`. Issue title format: `[FS-XXXX] <title>`. Issue body references the spec file path and current status.
2. Create GitHub Issues for each PLAN document (PLAN-0001 through PLAN-0011, 11 total), labeled `plan`. Issue title format: `[PLAN-XXXX] <title>`. Issue body references the plan file path and current status.
3. Add each issue to the project board.
4. Set each issue's Status field based on the document's current status:
   - `draft` → Backlog
   - `approved` → Approved
   - `in-progress` → In Progress
   - `implemented` → Done
5. Set each issue's Doc Type field (FS or PLAN).
6. Close issues whose documents are `implemented` (so they land in Done).

### Phase 3: Configuration and documentation

1. Create `config/project.yml` with:
   - Project number and URL
   - Field IDs (Status, Doc Type)
   - Option IDs for each Status column and Doc Type value
2. Add a "Project Board" section to `README.md` with the board URL.
3. Update `docs/specifications/README.md`: add FS-0019 row.
4. Update `docs/change-plans/README.md`: add PLAN-0011 row.
5. Add CHANGELOG entry under `[Unreleased]`.

### Phase 4: Manual UI steps (human-gated) ✅ Complete

These require GitHub UI and cannot be done via CLI. Completed by Tai on 2026-02-28.

1. ✅ Enable "Auto-add to project" workflow for the agentic-dev-kit repo.
2. ✅ Enable built-in "Item closed → Done" workflow.
3. ✅ Enable built-in "PR merged → Done" workflow.

### Phase 5: Validate

1. `gh project item-list <number> --owner Tais-Den` — confirm all 22 items present (11 FS + 11 PLAN), plus issue #26 (23 total).
2. Spot-check: implemented items are in Done, draft items are in Backlog, approved items are in Approved.
3. Create a test issue → confirm it auto-appears on the board (after Phase 4 manual step).
4. Close the test issue → confirm it moves to Done.

## 6. Constraints and Guardrails

- FS-0019 Non-Goals: no org rollup, no webhooks, no automated status sync.
- Board is a dashboard layer; markdown FS/PLAN/ADR files remain authoritative.
- Auto-add workflow configuration is a manual UI step — document it but don't block on it.

## 7. Risks and Edge Cases

- **`gh project` scope:** PAT must have `project` scope. Verify before starting.
- **Auto-add is UI-only:** Cannot be configured via CLI. Phase 4 is human-gated.
- **Draft specs (FS-0012, FS-0013):** Their issues go to Backlog, not Approved.
- **Issue #26 already exists:** Add it to the board as-is; link it to FS-0019.
- **Rate limits:** Creating 22+ issues in rapid succession may hit GitHub rate limits. Add brief pauses if needed.

## 8. Validation

- CLI: `gh project list --owner Tais-Den` returns the agentic-dev-kit project.
- CLI: `gh project item-list <number> --owner Tais-Den` returns 23 items (22 backfilled + #26).
- CLI: `gh project field-list <number> --owner Tais-Den` shows Status and Doc Type fields.
- Visual: board view shows items distributed across correct columns.
- Config: `config/project.yml` is parseable and contains all required IDs.

## 9. Explicit Non-Changes

- No changes to exported surface (guidelines, roles, workflows, templates, skills).
- No changes to document lifecycle or ROLE_CONTRACT.
- No changes to other repos.
- No GitHub Actions or webhooks.

## 10. Readiness Check

- [x] Spec is approved (FS-0019 — approved upon merge of this PR)
- [x] Pack-protocol ADR-0001 and ADR-0002 provide the governing decisions
- [x] `gh` CLI available with project scope
- [x] Scope is minimal and explicit
- [x] No architectural changes implied

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation.
- No additional behavior will be introduced.
- Any deviation will require revising this plan before execution.
