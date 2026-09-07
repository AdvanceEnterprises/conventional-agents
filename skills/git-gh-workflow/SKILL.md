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

- `../git-commit-identity/SKILL.md`
- `../git-branch-and-commit/SKILL.md`
- `../gh-pr-workflow/SKILL.md`
- `../versioning-and-releases/SKILL.md`
- `../work-item-stance/SKILL.md`
- `../role-aware-session/SKILL.md` — session mode and role stance before acting on a branch or PR
- `../framework-health-audit/SKILL.md` — the hygiene gate and `check:status` run before a PR is marked ready

---

## Prohibitions

- **Do NOT** push to the default branch (`trunk`) — always use a feature branch and PR.
- **Do NOT** merge pull requests (non-overridable gate). Use `gh pr merge --auto` to enable CI-based auto-merge, or request human review.
- **Do NOT** run `gh pr merge` without the `--auto` flag — that merges immediately and violates ADR-0012.
- **Do NOT** assume the correct GitHub identity is active — verify every time.
- **Do NOT** bump major versions without human approval.
- **Do NOT** publish packages to registries without explicit human approval.
- **Do NOT** mix version bumps into feature commits — release-prep only.
- **Do NOT** remove or rewrite existing changelog entries.
- **Do NOT** delete or regenerate lockfiles during feature work.
- **Do NOT** run `npm update` or equivalent during feature work unless explicitly instructed.
- **Do NOT** bump submodules during unrelated feature work.
