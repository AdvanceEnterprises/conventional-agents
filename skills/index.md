# Skills Index

Portable skill modules for agentic development using the conventional-agents framework.

Authoring a skill? See [`AUTHORING.md`](./AUTHORING.md) — the framework's profile
of the [Agent Skills](https://agentskills.io/specification) standard (`ADR-0038`).

| Skill | Purpose | Source Documents |
| --- | --- | --- |
| [role-aware-session](./role-aware-session/SKILL.md) | Infers session mode, primary and supporting roles, and holds role boundaries for every interaction. Use at session start, on phase shifts, or when deciding which role may act | `guidelines/ROLE_CONTRACT.md`, `workflows/session-modes.md` |
| [document-lifecycle](./document-lifecycle/SKILL.md) | Scaffolds, transitions, and maintains governed documents (FS, PLAN, ADR) with correct front matter and cross-references. Use when creating or updating a governed document or resolving a check:status violation | `workflows/document-lifecycle.md`, `templates/core/*` |
| [binding-authoring](./binding-authoring/SKILL.md) | Selecting and authoring a binding under `integrations/` — the six substrate capabilities, the runtime setup-requirement set, the `ADR-0024` ordering rule, the `enforces`/`provisions`/`reports` classification, and grep-shape conformance tests | `integrations/README.md`, `integrations/github-issues-projects.md`, `integrations/github/README.md`, `ADR-0024`, `ADR-0037`, `ADR-0039` |
| [adr-authoring](./adr-authoring/SKILL.md) | Writes ADRs that survive review — artifact selection, argument construction, and stating only claims the repository can back | `docs/decisions/README.md`, `templates/core/adr-full-madr.md`, `ADR-0030`, `ADR-0015` |
| [spec-authoring](./spec-authoring/SKILL.md) | Writes feature specs whose Success Criteria become real tests and whose scope holds under implementation | `templates/core/feature-spec.md`, `docs/specifications/README.md`, `ADR-0026`, `ADR-0027` |
| [git-commit-identity](./git-commit-identity/SKILL.md) | Commit identity and agent attribution — multi-identity and single-identity models, per-commit and per-session overrides, the `Agent-Attribution:` trailer, the actor alias table | `workflows/git-and-gh-conventions.md`, `ADR-0011`, `ADR-0018`, `ADR-0029`, `ADR-0036` |
| [git-branch-and-commit](./git-branch-and-commit/SKILL.md) | Branch naming, the mandatory feature-branch rule, Conventional Commits (lite), commit bodies, pushing | `workflows/git-and-gh-conventions.md`, `ADR-0012` |
| [gh-pr-workflow](./gh-pr-workflow/SKILL.md) | Pull-request lifecycle — bodies, rebasing, review response, CI checks, the human merge gate | `workflows/git-and-gh-conventions.md`, `ADR-0012`, `ADR-0025` |
| [versioning-and-releases](./versioning-and-releases/SKILL.md) | Semantic versioning by project type, changelog conventions, the release process, agent-safe vs human-gated actions, dependency and submodule bumps | `workflows/versioning-and-releases.md`, `ADR-0025` |
| [work-item-stance](./work-item-stance/SKILL.md) | The `agent-stance:` activity entry, Type-keyed autonomous checkpoints, `question`-label suppression, unattended actor identity | `FS-0018`, `ADR-0019`, `ADR-0020`, `ADR-0021`, `ADR-0022` |
| [git-gh-workflow](./git-gh-workflow/SKILL.md) | **Deprecated** — router to the five skills above. Retained so existing references resolve; carries no guidance | — |
| [framework-consumer-integration](./framework-consumer-integration/SKILL.md) | Guides agents through integrating conventional-agents into a host repository — selecting the right pattern, writing AGENTS.md, avoiding common mistakes. Use when vendoring, onboarding, or auditing an integration | `INTEGRATION.md`, `ADR-0016`, `ADR-0017` |
| [framework-health-audit](./framework-health-audit/SKILL.md) | Runs and interprets check:status, performs full framework health audits, and applies the document hygiene gate. Use before marking a PR ready or when a status/lint gate fails | `scripts/check-status.sh`, `FS-0013`, `guidelines/ROLE_CONTRACT.md` |
| [testing-guide](./testing-guide/SKILL.md) | Writes tests from approved specs across Python, JavaScript/TypeScript, and Bash; applies implementer guidance and approved test patterns. Use when translating success criteria into tests or practising TDD | `guidelines/python/*`, `guidelines/javascript/*`, `guidelines/bash/*` |
| [in-cycle-re-review](./in-cycle-re-review/SKILL.md) | Posts a discoverable trace comment when a reviewer re-verifies a changed PR head, without breaking the once-per-PR reviewer dedupe contract. Use during autonomous or consensus review rounds after a head change | `guidelines/ROLE_CONTRACT.md`, `workflows/session-modes.md`, `FS-0054` |

## How to Use

Each skill is a self-contained `SKILL.md` in its own directory. Load the relevant skill at the start of a session or when switching modes:

> Load the `role-aware-session` skill to determine the correct session mode and role stance for this interaction.
