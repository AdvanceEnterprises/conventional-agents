---
type: change-plan
role: implementer
status: implemented
related_specs:
  - FS-0012
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

# Change Plan: Renumber feature specs to sequential IDs

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0012
- Related ADR ID(s): None
- Issue / PR Reference: TBD (will be created on the project board)

## 2. Scope of Change

**This change WILL:**

- Rename 9 FS files (FS-0003 through FS-0011 → FS-0003 through FS-0003).
- Rename this spec (FS-0012 → FS-0004) and this plan accordingly.
- Update `id:` front matter in all renamed FS documents.
- Rename PLAN files whose filenames contain old FS IDs (7 files).
- Update `related_specs:` front matter in all PLANs that reference renamed FS IDs.
- Update `related_specs:` front matter in all ADRs that reference renamed FS IDs.
- Update `docs/specifications/README.md`, `docs/change-plans/README.md`, `docs/decisions/README.md`.
- Update `CHANGELOG.md` — historical entries get "(formerly FS-XXXX)" annotations.
- Update `docs/ARC42.md` if it contains FS references.
- Check and update `docs/implementation-plans/IP-0001.md`.
- Update all GitHub Issue titles and bodies on project board #2 via `gh` CLI.
- Add a CHANGELOG entry documenting the renumbering.

**This change will NOT:**

- Renumber PLAN IDs or ADR IDs.
- Change any spec content beyond IDs, filenames, and cross-references.
- Modify the project board structure (columns, fields, etc.).
- Touch files outside this repository.

## 3. Tests Driving This Change

No automated tests. Validation via grep (see Section 8).

## 4. Files to Be Modified

**FS renames (9 files renamed + front matter updated):**

| Old filename | New filename |
|---|---|
| ~~`FS-0011-git-gh-cli-conventions-for-agent-dev-kit.md`~~ | `FS-0003-git-gh-cli-conventions-for-agent-dev-kit.md` |
| ~~`FS-0012-agent-authored-commit-pr-commentary-policy.md`~~ | `FS-0004-agent-authored-commit-pr-commentary-policy.md` |
| ~~`FS-0013-expand-docs-linting-coverage-to-fs-plan-workflows.md`~~ | `FS-0005-expand-docs-linting-coverage-to-fs-plan-workflows.md` |
| ~~`FS-0014-javascript-guidelines.md`~~ | `FS-0006-javascript-guidelines.md` |
| ~~`FS-0015-versioning-releases-packaging-guidance.md`~~ | `FS-0007-versioning-releases-packaging-guidance.md` |
| ~~`FS-0016-self-versioning-and-changelog.md`~~ | `FS-0008-self-versioning-and-changelog.md` |
| ~~`FS-0017-vendor-upstream-specs.md`~~ | `FS-0009-vendor-upstream-specs.md` |
| ~~`FS-0018-process-compliance-gates.md`~~ | `FS-0010-process-compliance-gates.md` |
| ~~`FS-0019-adopt-github-projects-for-work-tracking.md`~~ | `FS-0011-adopt-github-projects-for-work-tracking.md` |

Plus this spec and plan rename themselves (~~FS-0020~~ → FS-0012, plan filename updated).

**PLAN renames (7 files whose filenames contain FS IDs):**

| Old filename | New filename |
|---|---|
| ~~`PLAN-0001-implement-fs-0011-git-gh-cli-conventions.md`~~ | `PLAN-0001-implement-fs-0003-git-gh-cli-conventions.md` |
| ~~`PLAN-0002-implement-fs-0012-agent-commentary-policy.md`~~ | `PLAN-0002-implement-fs-0004-agent-commentary-policy.md` |
| ~~`PLAN-0003-implement-fs-0013-expand-docs-linting-coverage.md`~~ | `PLAN-0003-implement-fs-0005-expand-docs-linting-coverage.md` |
| ~~`PLAN-0006-implement-fs-0014-javascript-guidelines.md`~~ | `PLAN-0006-implement-fs-0006-javascript-guidelines.md` |
| ~~`PLAN-0007-implement-fs-0015-versioning-releases.md`~~ | `PLAN-0007-implement-fs-0007-versioning-releases.md` |
| ~~`PLAN-0008-implement-fs-0016-self-versioning.md`~~ | `PLAN-0008-implement-fs-0008-self-versioning.md` |
| ~~`PLAN-0010-implement-fs-0018-process-compliance-gates.md`~~ | `PLAN-0010-implement-fs-0010-process-compliance-gates.md` |

**Other files updated (cross-references):**

- All PLAN `related_specs:` front matter
- All ADR `related_specs:` front matter (check ADR-0000 through ADR-0012)
- `docs/specifications/README.md`
- `docs/change-plans/README.md`
- `docs/decisions/README.md`
- `docs/ARC42.md`
- `docs/implementation-plans/IP-0001.md`
- `CHANGELOG.md`

**GitHub-side:**

- Update titles and bodies of all affected issues on project board #2 (FS issues + PLAN issues that reference FS IDs in titles).

## 5. Implementation Steps

### Phase 1: File renames and front matter updates

1. Verify identity: `gh auth status`.
2. Create branch from trunk.
3. For each FS in the mapping table:
   a. `git mv` old filename to new filename.
   b. Update `id:` in front matter.
   c. Update `## Status` section if it mentions the ID.
4. Rename this spec (FS-0012 → FS-0004) and update its own front matter.
5. For each PLAN whose filename contains an old FS ID:
   a. `git mv` old filename to new filename.
6. Update `related_specs:` in every PLAN's front matter.
7. Update `related_specs:` in every ADR's front matter.

### Phase 2: Cross-reference updates

1. `grep -rn 'FS-001[1-9]\|FS-002[0-0]'` across all `.md` files to find every old-ID reference.
2. Update each reference to the new ID.
3. Special handling for `CHANGELOG.md`: add "(formerly FS-XXXX)" to historical entries so the audit trail is preserved.
4. Update README index tables in specs, plans, and decisions directories.
5. Update `docs/ARC42.md`.
6. Check and update `docs/implementation-plans/IP-0001.md`.

### Phase 3: Update GitHub Issues

1. For each renamed FS: update the corresponding GitHub Issue title from `[FS-00XX]` to `[FS-00YY]` via `gh issue edit`.
2. Update issue bodies if they reference old FS IDs.
3. For each PLAN issue whose title references an old FS ID: update the title.

### Phase 4: Validate

1. `grep -rn 'FS-001[1-9]\|FS-002[0-0]' docs/ guidelines/ roles/ skills/ templates/ workflows/ CHANGELOG.md README.md INTEGRATION.md` — should return only:
   - The mapping table in this spec (FS-0004 after rename).
   - "(formerly FS-XXXX)" annotations in CHANGELOG.md.
2. Verify all FS filenames in `docs/specifications/` are sequential FS-0001 through FS-0004.
3. `gh project item-list 2 --owner Tais-Den` — spot-check that issue titles use new IDs.

### Phase 5: Update this plan

1. Rename this plan's filename if it references FS-0012 (update to reference FS-0004).
2. Update `related_specs:` in this plan to FS-0004.
3. Set both FS-0004 and this plan to `implemented`.

## 6. Constraints and Guardrails

- This is a purely mechanical rename — no content changes to any spec.
- The entire rename MUST be atomic (single PR) to avoid broken cross-references.
- Old IDs must remain findable via CHANGELOG annotations for historical traceability.

## 7. Risks and Edge Cases

- **Git history:** `git mv` preserves rename detection. Verify with `git log --follow` on a renamed file.
- **Merge conflicts:** If other PRs are in flight that reference old FS IDs, they'll conflict. Coordinate timing.
- **External references:** Other repos (pack-protocol, deploy-ducky) may reference agentic-dev-kit FS IDs. Those are out of scope but should be noted for follow-up.
- **PLAN-0009 and PLAN-0010 reference FS-0009 and FS-0010 via `related_specs:`** — these must be updated to FS-0009 and FS-0010 respectively.

## 8. Validation

- Grep check: no old IDs outside mapping table and CHANGELOG annotations.
- File listing: `ls docs/specifications/FS-*.md` shows FS-0001 through FS-0004 sequentially.
- GitHub Issues: spot-check 3–4 issue titles on the project board.

## 9. Explicit Non-Changes

- PLAN IDs stay as-is (PLAN-0001 through PLAN-0012).
- ADR IDs stay as-is.
- No spec content changes.
- No board structure changes.
- No changes to other repos.

## 10. Readiness Check

- [ ] FS-0012 is approved (becomes FS-0004 upon execution)
- [ ] PLAN-0011 (GitHub Projects) is merged so the board exists
- [ ] No other PRs in flight that would conflict with mass renames
- [x] Scope is explicit and mechanical
- [x] No architectural changes implied

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation.
- No additional behavior will be introduced.
- Any deviation will require revising this plan before execution.
