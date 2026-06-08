---
type: change-plan
role: implementer
language: markdown
status: implemented
related_specs:
  - FS-0007
related_adrs: []
created: 2026-02-08
updated: 2026-06-08
---

<!--
PARSING_HINTS:
- Document type: change-plan
- Intended role: Implementer (Role 2)
- This plan covers creating one new workflow document and updating
  four existing governance/guideline files.
- Treat the completed plan as a binding contract for implementation.
- If implementation would exceed this plan, the plan must be revised first.
-->

# Change Plan: Implement FS-0007 — Versioning, Releases, and Packaging Guidance

## 1. Feature / Issue Reference

- Feature Spec ID(s): FS-0007
- Related ADR ID(s): None
- Issue / PR Reference: PR #16 (<https://github.com/Tais-Den/agentic-dev-kit/pull/16>)

## 2. Scope of Change

**This change WILL:**

- Create `workflows/versioning-and-releases.md` covering:
  - Semver semantics for all 4 project types (libraries, services/APIs, documentation/standards kits, CLIs).
  - Changelog conventions (Keep a Changelog format, human-curated, agent role).
  - Release process guidance (tagging, release notes, release-prep PRs).
  - Agent-safe vs human-gated actions (with explicit boundary).
  - Dependency versioning discipline (lockfiles, pinning, agent behavior).
  - Submodule versioning guidance (when/how to bump vendored deps).
  - CalVer acknowledgment as a valid alternative.
  - Monorepo and no-versioning edge cases acknowledged (without prescribing tooling).
- Update `guidelines/ROLE_CONTRACT.md`:
  - Add versioning and release constraints to Shared Rules section.
  - Add "changing version numbers in project manifests" to Role 2 (Implementer) prohibited actions.
- Update `guidelines/bash/BASH_IMPLEMENTATION_GUIDE.md`:
  - Add guidance that agents must not change version numbers in project manifests as part of feature work.
- Update `guidelines/python/PYTHON_IMPLEMENTATION_GUIDE.md`:
  - Add same version-number guidance.
- Update `guidelines/javascript/JS_IMPLEMENTATION_GUIDE.md`:
  - Add same version-number guidance.

**This change will NOT:**

- Implementation will not modify any files under `docs/` (ADRs, specs, change plans, ARC42).
- Prescribe a specific changelog tool, CI/CD pipeline, or release cadence.
- Prescribe package registry publish mechanics.
- Prescribe monorepo tooling.
- Define how agentic-dev-kit itself is versioned.
- Modify `README.md`, `CONTRIBUTING.md`, `INTEGRATION.md`, `AGENTS.md`, `templates/`, `skills/`, or `roles/ROLE_CONTRACT.md`.

## 3. Tests Driving This Change

This is a documentation-only change; there are no code tests.

Quality gates:

- `npx markdownlint-cli2 "workflows/versioning-and-releases.md"` must pass (zero errors).
- `npm run lint:docs` must pass across all doc categories (this runs `lint:adrs`, `lint:specs`, `lint:plans`, `lint:workflows` — see `package.json` scripts).
- Manual review: workflow doc must satisfy all FS-0007 success criteria.

## 4. Files to Be Modified

**New files:**

- `workflows/versioning-and-releases.md`

**Existing files to update:**

- `guidelines/ROLE_CONTRACT.md`
- `guidelines/bash/BASH_IMPLEMENTATION_GUIDE.md`
- `guidelines/python/PYTHON_IMPLEMENTATION_GUIDE.md`
- `guidelines/javascript/JS_IMPLEMENTATION_GUIDE.md`

## 5. Implementation Steps (High-Level)

1. Write `workflows/versioning-and-releases.md`:
   - Follow the voice/tone of existing workflow docs (`workflows/git-and-gh-conventions.md`).
   - Structure: Purpose → Semver by project type → Changelog conventions → Release process → Agent-safe vs human-gated actions → Dependency versioning → Submodule versioning → Edge cases (CalVer, monorepos, no-versioning projects).
   - Keep it prescriptive and concise; no tool-specific recipes.
   - Do NOT prescribe changelog tooling, CI pipelines, or release cadences.

2. Update `guidelines/ROLE_CONTRACT.md`:
   - In the "Shared Rules" section, add a "Versioning and release constraints" block:
     - Agents MUST NOT bump major versions without human approval.
     - Agents MUST NOT publish packages to registries without explicit human approval.
     - Version bumps are only allowed in explicit release-prep commits/PRs, never mixed into feature commits.
     - Agents MAY draft changelog entries, bump minor/patch versions, and prepare release-prep PRs when explicitly instructed.
   - In the "Role 2: Implementer" → "Prohibited Actions" list, add:
     - Changing version numbers in project manifests (`package.json`, `pyproject.toml`, `setup.cfg`, etc.).

3. Update `guidelines/bash/BASH_IMPLEMENTATION_GUIDE.md`:
   - Add a short section (or bullet in the existing checklist) stating:
     - Do not change version numbers in project manifests as part of feature work.
     - Version bumps are a separate, explicit step that requires human direction.

4. Update `guidelines/python/PYTHON_IMPLEMENTATION_GUIDE.md`:
   - Add the same version-number guidance (matching the Bash guide's placement and wording).

5. Update `guidelines/javascript/JS_IMPLEMENTATION_GUIDE.md`:
   - Add the same version-number guidance (matching the Bash and Python guides).

6. Run `npx markdownlint-cli2 "workflows/versioning-and-releases.md"` and fix any errors.

7. Run `npm run lint:docs` to confirm all existing doc linting still passes.

## 6. Constraints and Guardrails

- Spec constraints:
  - FS-0007 Non-Goals: no specific changelog tool, CI/CD pipeline, release cadence, or registry mechanics.
  - FS-0007 Out of Scope: no monorepo tooling, no agentic-dev-kit self-versioning.
  - FS-0007 Edge Cases: must acknowledge CalVer, monorepos, and no-versioning projects.

- Architecture constraints:
  - Workflow docs live in `workflows/` (exported surface).
  - Role Contract updates must not weaken existing gates.
  - Implementation guide updates must be consistent across all three languages.

## 7. Risks and Edge Cases

- **Over-prescriptive workflow doc**: risk of being too opinionated about release process for a framework that should be project-agnostic. Mitigated by: keeping guidance structural ("have a release-prep PR") rather than procedural ("run this exact script").
- **Role Contract bloat**: risk of the Shared Rules section growing too large. Mitigated by: keeping the versioning block concise (4–6 bullets) and referencing the workflow doc for details.
- **Implementation guide inconsistency**: risk of slightly different wording across the three language guides. Mitigated by: using identical phrasing for the core rule, varying only language-specific manifest examples.

## 8. Validation

- Markdownlint passes:
  - `npx markdownlint-cli2 "workflows/versioning-and-releases.md"` returns 0 errors.
  - `npm run lint:docs` returns 0 errors across all categories.
- FS-0007 success criteria spot-check:
  - `workflows/versioning-and-releases.md` exists and covers all 4 project types.
  - Does NOT prescribe changelog tool, CI pipeline, or release cadence.
  - `ROLE_CONTRACT.md` Shared Rules contain version constraints (major bump, publishing, release-prep only).
  - `ROLE_CONTRACT.md` Implementer prohibited actions include version-number changes.
  - All 3 implementation guides contain version-number guidance.

## 9. Explicit Non-Changes

- `docs/` directory (ADRs, specs, change plans, ARC42) — not modified.
- `README.md` — not modified.
- `CONTRIBUTING.md` — not modified.
- `INTEGRATION.md` — not modified.
- `AGENTS.md` — not modified.
- `templates/` — not modified.
- `skills/` — not modified.
- `roles/ROLE_CONTRACT.md` — not modified (the contract being updated is `guidelines/ROLE_CONTRACT.md`).
- `package.json` — not modified.

## 10. Readiness Check

- [x] Spec is approved (FS-0007, status: approved)
- [x] Tests exist or are clearly defined (documentation-only; markdownlint is the quality gate)
- [x] Scope is minimal and explicit
- [x] No architectural changes implied

## Declaration

I affirm that:

- This plan reflects the full intended scope of implementation.
- No additional behavior will be introduced.
- Any deviation will require revising this plan before coding.
