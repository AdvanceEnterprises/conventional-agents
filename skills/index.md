# Skills Index

Portable skill modules for agentic development using the conventional-agents framework.

Authoring a skill? See [`AUTHORING.md`](./AUTHORING.md) — the framework's profile
of the [Agent Skills](https://agentskills.io/specification) standard (`ADR-0038`).

| Skill | Purpose | Source Documents |
| --- | --- | --- |
| [role-aware-session](./role-aware-session/SKILL.md) | Infers session mode, primary and supporting roles, and holds role boundaries for every interaction. Use at session start, on phase shifts, or when deciding which role may act | `roles/ROLE_CONTRACT.md`, `workflows/session-modes.md` |
| [document-lifecycle](./document-lifecycle/SKILL.md) | Scaffolds, transitions, and maintains governed documents (FS, PLAN, ADR) with correct front matter and cross-references. Use when creating or updating a governed document or resolving a check:status violation | `workflows/document-lifecycle.md`, `templates/core/*` |
| [git-gh-workflow](./git-gh-workflow/SKILL.md) | Encodes git branching, commits, pull-request workflow, commit identity and attribution, versioning, changelogs, and the release process. Use before any branch, commit, push, or PR operation | `workflows/git-and-gh-conventions.md`, `workflows/versioning-and-releases.md`, `ADR-0011`, `ADR-0012`, `ADR-0018`, `ADR-0029` |
| [framework-consumer-integration](./framework-consumer-integration/SKILL.md) | Guides agents through integrating conventional-agents into a host repository — selecting the right pattern, writing AGENTS.md, avoiding common mistakes. Use when vendoring, onboarding, or auditing an integration | `INTEGRATION.md`, `ADR-0016`, `ADR-0017` |
| [framework-health-audit](./framework-health-audit/SKILL.md) | Runs and interprets check:status, performs full framework health audits, and applies the document hygiene gate. Use before marking a PR ready or when a status/lint gate fails | `scripts/check-status.sh`, `FS-0013`, `guidelines/ROLE_CONTRACT.md` |
| [testing-guide](./testing-guide/SKILL.md) | Writes tests from approved specs across Python, JavaScript/TypeScript, and Bash; applies implementer guidance and approved test patterns. Use when translating success criteria into tests or practising TDD | `guidelines/python/*`, `guidelines/javascript/*`, `guidelines/bash/*` |

## How to Use

Each skill is a self-contained `SKILL.md` in its own directory. Load the relevant skill at the start of a session or when switching modes:

> Load the `role-aware-session` skill to determine the correct session mode and role stance for this interaction.

When integrating conventional-agents into a host project, load the
`framework-consumer-integration` skill.

Skills are designed to be read and followed by agents — they are not scripts. Some skills may include optional helper scripts in their directory.
