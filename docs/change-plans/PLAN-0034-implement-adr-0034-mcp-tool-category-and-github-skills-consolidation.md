---
type: change-plan
role: implementer
language: markdown
status: deprecated
consensus_required: false
related_specs: []
related_adrs:
  - ADR-0034
touches:
  - README.md
  - docs/decisions/README.md
  - docs/change-plans/README.md
  - docs/decisions/ADR-0034-*.md
  - docs/change-plans/PLAN-0034-*.md
  - skills/git-branch-and-commit/SKILL.md
  - skills/gh-pr-workflow/SKILL.md
  - skills/gh-code-review/SKILL.md
  - skills/gh-issues/SKILL.md
  - skills/gh-remote-verification/SKILL.md
  - skills/gh-governed-doc-tracking/SKILL.md
  - skills/gh-stacked-prs/SKILL.md
  - skills/git-gh-workflow/SKILL.md
  - skills/index.md
created: 2026-08-05
updated: 2026-09-05
---

# PLAN-0034: Implement ADR-0034 — MCP tool category and GitHub skills consolidation

> **Deprecated (2026-09-05).** `ADR-0034` was superseded by `ADR-0038` and
> `ADR-0039` (PR #112) before this plan was ever approved or executed. Its Part 2
> skill work is carried by `ADR-0038` (Category 2, no PLAN); its Part 1 MCP
> taxonomy is carried by `ADR-0039` §4. Nothing in this plan was implemented —
> the split-target skills it names (`skills/gh-pr-workflow/` etc.) never existed.
> Issue #107, which claimed this plan's work was done, is corrected and closed.

## 1. Feature / Issue Reference

- Related ADR ID(s): ADR-0034 (superseded by ADR-0038, ADR-0039)
- Issue / PR Reference: PR #79 (ADR-0034 file); deprecated in PR #112

## 2. Scope of Change

**This change WILL:**

- Record the Agent Skills upstream dependency in `README.md` (Phase 0).
- Port two already-agnostic Hermes skills into `skills/` (Phase 1).
- Split the oversize `git-gh-workflow` into focused sub-skills and deprecate the original (Phase 2).
- Add the ADR establishing MCP as a fourth tool category (Phase 3 — delivered in this PR).
- Define the sequencing and prerequisites for future MCP bindings (Phase 4 — deferred).

**This change will NOT:**

- Write any MCP server configuration or binding. Phase 4 is sequenced after a concrete MCP server is adopted.
- Modify any governance gate or CI script. All changes are Category 2 (skills) or documentation.
- Remove the existing `git-gh-workflow` skill. It is deprecated but remains in place as a redirect.
- Modify any Hermes Agent skills or profiles. Framework skills are framework-agnostic by design.

## 3. Tests Driving This Change

No new tests. The existing `npm run lint:docs` and `npm run check:status` gates apply to all new and modified documents.

## 4. Files to Be Modified

| Phase | Files | Action |
| --- | --- | --- |
| 0 | `README.md` | Add Agent Skills to "Upstream References" |
| 1 | `skills/gh-governed-doc-tracking/SKILL.md` | Create (port from Hermes) |
| 1 | `skills/gh-stacked-prs/SKILL.md` | Create (port from Hermes) |
| 1 | `skills/index.md` | Add entries for both new skills |
| 2 | `skills/git-branch-and-commit/SKILL.md` | Create |
| 2 | `skills/gh-pr-workflow/SKILL.md` | Create |
| 2 | `skills/gh-code-review/SKILL.md` | Create |
| 2 | `skills/gh-issues/SKILL.md` | Create |
| 2 | `skills/gh-remote-verification/SKILL.md` | Create |
| 2 | `skills/git-gh-workflow/SKILL.md` | Replace with deprecation notice + redirect |
| 2 | `skills/index.md` | Add entries, mark `git-gh-workflow` deprecated |
| 3 | `docs/decisions/ADR-0034-*.md` | Delivered in this PR |
| 3 | `docs/decisions/README.md` | Add ADR-0034 row (delivered in this PR) |
| 3 | `docs/change-plans/README.md` | Add PLAN-0034 row (delivered in this PR) |
| 4 | (none) | Deferred — see §9 |

## 5. Implementation Steps

### Phase 0 — Record Agent Skills upstream

1. Open `README.md`, locate the "Upstream References" section.
2. Add an entry for Agent Skills matching the format of the existing four:
   - Name: "Agent Skills"
   - URL: `https://agentskills.io/specification`
   - Pointer: `skills/` directory and `skills/index.md`.
3. Commit as `docs: record Agent Skills as adopted upstream standard`.

### Phase 1 — Port agnostic Hermes skills

1. Create `skills/gh-governed-doc-tracking/SKILL.md`:
   - Port from Hermes `github-governed-doc-tracking`.
   - Strip Hermes-specific paths (`$HERMES_HOME`, `~/.hermes/`).
   - Replace Hermes-specific auth detection with framework-agnostic `gh` CLI references.
   - Keep existing framework path references — they are already correct.
   - Front matter: `name: gh-governed-doc-tracking`, `version: 1.0.0`, `author: conventional-agents`, `license: MIT`.
   - Under 500 lines.

2. Create `skills/gh-stacked-prs/SKILL.md`:
   - Port from Hermes `reviewing-stacked-prs` (already framework-agnostic).
   - Add framework-convention front matter.
   - Under 500 lines.

3. Update `skills/index.md` with rows for both new skills.

4. Commit as `feat(skills): port gh-governed-doc-tracking and gh-stacked-prs from Hermes`.

### Phase 2 — Split git-gh-workflow

1. Create `skills/git-branch-and-commit/SKILL.md`:
   - Extract branching rules, commit message format, commit body conventions.
   - Source: `workflows/git-and-gh-conventions.md`, `ADR-0018`, `ADR-0029`.

2. Create `skills/gh-pr-workflow/SKILL.md`:
   - Extract PR lifecycle (create, update, CI monitoring, merge).
   - Source: `workflows/git-and-gh-conventions.md`, `ADR-0012`.
   - Include auto-merge workflow and non-overridable merge gate.

3. Create `skills/gh-code-review/SKILL.md`:
   - Extract code review guidance.
   - Source: `workflows/git-and-gh-conventions.md`, `FS-0004`.
   - Include review checklist, inline comment format, formal review submission.

4. Create `skills/gh-issues/SKILL.md`:
   - Extract issue management guidance.
   - Source: `FS-0018`, `workflows/git-and-gh-conventions.md`.
   - Include issue creation, triage, labeling, `agent-stance:` comment format.

5. Create `skills/gh-remote-verification/SKILL.md`:
   - Extract remote verification guidance.
   - Source: `workflows/git-and-gh-conventions.md`, `ADR-0012`.
   - Include push verification, CI status checking, "never trust local state alone."

6. Deprecate `skills/git-gh-workflow/SKILL.md`:
   - Replace content with deprecation notice and a table mapping each concern to the appropriate sub-skill.
   - Keep the file in place so existing references do not break.

7. Update `skills/index.md` — add rows for all five new skills, mark `git-gh-workflow` as deprecated.

8. Commit as `feat(skills): split git-gh-workflow into five focused sub-skills`.

### Phase 3 — ADR (this PR)

Delivered. `docs/decisions/README.md` updated with ADR-0034 row.

### Phase 4 — MCP bindings (deferred)

No implementation in this PR. Sequencing:

1. A concrete MCP server is proposed for adoption (by the framework or a consumer).
2. Its capabilities are evaluated against ADR-0034's authority model.
3. If within the existing authority baseline, adopted as Category 4 with no FS.
4. If expanding the governance surface, FS and PLAN required before adoption.
5. A binding document is written in `integrations/` following the ADR-0024 pattern.
6. The binding is the first concrete validation of ADR-0034's authority model. If insufficient, a superseding ADR must amend it.

## 6. Constraints and Guardrails

- **ADR-0015 is append-only.** This ADR does not edit it; the four-category taxonomy exists across two ADRs.
- **Skills are Category 2 per ADR-0015.** No FS required. Each must have a `SKILL.md`, be listed in `skills/index.md`, and pass `--self-test` before merging.
- **Framework-agnostic constraint.** All new skills reference only `gh` and `git` as platform tools. No Hermes-specific paths or auth scripts.
- **Agent Skills spec conformance.** `name` matches parent directory. `version`/`author`/`platforms` under `metadata`. No nested maps in `metadata`. Under 500 lines.
- **ADR-0024 ordering rule.** No MCP binding may be merged as a stub. The binding is written first and in full; any generalization is extracted from it.

## 7. Risks and Edge Cases

| Risk | Mitigation |
| --- | --- |
| Skill size creep beyond 500 lines | Use `references/` subdirectories for overflow (per Agent Skills spec) |
| Consumer references to deprecated `git-gh-workflow` | File stays in place; deprecation notice redirects to sub-skills |
| MCP authority model untested against real server | Review checkpoint in ADR-0034 Validation section |
| Ported Hermes skills drift from originals | Document snapshot version in SKILL.md front matter |

## 8. Validation

- `npm run lint:docs` — must pass for all new and modified documents.
- `npm run check:status` — must pass after updating index tables.
- Each new SKILL.md: under 500 lines (`wc -l`), `name` matches parent directory.
- `README.md` contains "Agent Skills" in "Upstream References" after Phase 0.

## 9. Explicit Non-Changes

- No MCP server configuration or binding written in this PR.
- No governance gate or CI script modified.
- No Hermes Agent skills or profiles modified.
- `git-gh-workflow` is not deleted — only deprecated.
- No FS created for any skill in this PLAN (Category 2 per ADR-0015).

## 10. Readiness Check

- [x] ADR-0034 written and included in this PR.
- [ ] Phase 0: README.md updated with Agent Skills upstream reference.
- [ ] Phase 1: Two ported skills created in `skills/`.
- [ ] Phase 2: Five sub-skills created, `git-gh-workflow` deprecated.
- [ ] Phase 2: `skills/index.md` updated with all new entries.
- [ ] Phase 3: `docs/decisions/README.md` updated with ADR-0034 row.
- [ ] Scope is minimal and explicit.
- [ ] No architectural changes implied.

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation.
- No additional behavior will be introduced.
- Any deviation will require revising this plan before coding.
