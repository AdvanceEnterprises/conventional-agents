---
name: git-gh-workflow
description: "Deprecated router. This skill was split into five focused successors covering commit identity and attribution, branching and commits, the GitHub pull-request workflow, versioning and releases, and work-item stance. Use it only to find the successor you need; load that successor for the actual guidance."
license: MIT
---

# Git/GH Workflow Skill — Deprecated

**This skill has been split.** It bundled five distinct topics in one 554-line
file, which `skills/AUTHORING.md` rule 4 identifies as a cohesion defect rather
than a size one, and which `ADR-0038` rule 7 sanctions splitting.

It is retained as a router so that existing references resolve. It carries no
guidance of its own. **Load the successor, not this file.**

## Where the content went

| You need | Load |
| --- | --- |
| Commit identity, `user.name` / `user.email`, the multi-identity and single-identity models, `Agent-Attribution:` trailers, the actor alias table, the `gh auth status` gate | `skills/git-commit-identity/SKILL.md` |
| Branch prefixes, the mandatory feature-branch rule, Conventional Commits, commit bodies, pushing | `skills/git-branch-and-commit/SKILL.md` |
| Opening and updating pull requests, PR bodies, rebasing, review response, CI checks, the merge gate, compliant `--auto` merge | `skills/gh-pr-workflow/SKILL.md` |
| Semantic versioning by project type, changelog conventions, the release process, agent-safe vs human-gated actions, dependency and submodule bumps | `skills/versioning-and-releases/SKILL.md` |
| The `agent-stance:` entry, Type-keyed autonomous checkpoints, `question`-label suppression, unattended actor identity | `skills/work-item-stance/SKILL.md` |
| The seven-item document hygiene gate, in full | `skills/framework-health-audit/SKILL.md` |

## Why this file still exists

`skills/` is exported surface. Consumers vendor this repository as a git
submodule and reference skills by path, so deleting the path outright would be a
breaking change under `workflows/versioning-and-releases.md`. The router is the
migration aid; it is expected to be removed in a future major release once
consumers have moved.

This file is deliberately exempt from `skills/AUTHORING.md` rule 1
(standalone-useful, two runnable examples): it teaches nothing and is not meant
to. A router that carried examples would be a sixth skill competing with the five
it points at.

## Related Skills

- `skills/git-commit-identity/SKILL.md`
- `skills/git-branch-and-commit/SKILL.md`
- `skills/gh-pr-workflow/SKILL.md`
- `skills/versioning-and-releases/SKILL.md`
- `skills/work-item-stance/SKILL.md`
