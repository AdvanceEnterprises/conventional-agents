# Skills Index

Portable skill modules for agentic development using the conventional-agents framework.

| Skill | Purpose | Source Documents |
| --- | --- | --- |
| [role-aware-session](./role-aware-session/SKILL.md) | Infers session mode, primary/supporting roles, and enforces role boundaries for every interaction | `roles/ROLE_CONTRACT.md`, `workflows/session-modes.md` |
| [document-lifecycle](./document-lifecycle/SKILL.md) | Scaffolds, transitions, and maintains governed documents (FS, PLAN, ADR) with correct front matter and cross-references | `workflows/document-lifecycle.md`, `templates/core/*` |
| [git-gh-workflow](./git-gh-workflow/SKILL.md) | Encodes git branching, commits, PR workflow, identity and attribution conventions, versioning, and release process | `workflows/git-and-gh-conventions.md`, `workflows/versioning-and-releases.md`, `ADR-0011`, `ADR-0012`, `ADR-0018`, `ADR-0029` |
| [framework-consumer-integration](./framework-consumer-integration/SKILL.md) | Helps host projects integrate conventional-agents correctly | `INTEGRATION.md`, `ADR-0016`, `ADR-0017` |
| [framework-health-audit](./framework-health-audit/SKILL.md) | Runs and interprets `npm run check:status`, performs full framework health audits, enforces the document hygiene gate | `scripts/check-status.sh`, `FS-0013`, `roles/ROLE_CONTRACT.md` |
| [testing-guide](./testing-guide/SKILL.md) | Writes tests from approved specs across Python, JS/TS, and Bash; applies implementer guidance and approved test patterns | `guidelines/python/*`, `guidelines/javascript/*`, `guidelines/bash/*` |

## How to Use

Each skill is a self-contained `SKILL.md` in its own directory. Load the relevant skill at the start of a session or when switching modes:

> Load the `role-aware-session` skill to determine the correct session mode and role stance for this interaction.

When integrating conventional-agents into a host project, load the
`framework-consumer-integration` skill.

Skills are designed to be read and followed by agents — they are not scripts. Some skills may include optional helper scripts in their directory.
