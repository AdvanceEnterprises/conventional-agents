---
name: git-gh-workflow
description: "Encodes git branching, commits, pull-request workflow, commit identity and attribution, versioning, changelogs, and the release process. Use before any branch, commit, push, or PR operation on GitHub, when recording agent attribution, and when preparing a release or CI auto-merge."
license: MIT
---

# Git/GH Workflow Skill

Encodes the conventional-agents git and GitHub conventions, versioning and release process, and multi-identity model into actionable guidance.

## Source Documents

- `workflows/git-and-gh-conventions.md` — branching, commits, PRs, multi-identity model
- `workflows/versioning-and-releases.md` — semver, changelogs, release process, agent-safe vs human-gated actions
- `docs/decisions/ADR-0011-adopt-multi-identity-github-model-human-agent-committer-agent-reviewer.md` — multi-identity GitHub model (human + agent-committer + agent-reviewer)
- `docs/decisions/ADR-0012-non-overridable-gates.md` — non-overridable safety gates

## Purpose

This skill helps an agent:

1. **Follow the correct git workflow** — branching, commits, PRs, rebasing
2. **Handle the multi-identity model** — know which identity to use for what
3. **Respect non-overridable gates** — never merge, always verify identity
4. **Apply versioning rules** — know what's agent-safe vs human-gated
5. **Maintain changelog discipline** — append to `[Unreleased]` only, never rewrite

---

## Non-Overridable Safety Gates (ADR-0012)

These gates **cannot be weakened** by any instruction source, including project-specific AGENTS.md or human chat instructions.

### PR Merge Rule

- **Agents MUST NOT merge pull requests.** Merging is a human-gated action.
- Agents may open PRs, update PRs, and request review.
- Agents MUST NOT run `gh pr merge`, `git push` to the default branch, or any equivalent merge action.
- Even if a human verbally approves in chat, the human (or CI triggered by human approval) performs the actual merge.

### GitHub Identity Gate

- Before any `gh` CLI operation (`gh pr`, `gh api`, `gh auth`, etc.) or `git push`, the agent MUST:
  1. Run `gh auth status` and verify the active account is the expected agent-committer identity.
  2. If the wrong account is active, run `gh auth switch --user <correct-username>` before proceeding.
  3. Never assume the correct account is active from a previous session or command.
- This applies **every time** — not just the first operation in a session.

### Single-Identity Mode (ADR-0018)

Many projects — including this one — operate with one GitHub login shared
across human and agent actors. In that mode:

- The Identity Gate above becomes "verify the active account is
  `ajoeofalltrades`" — trivially passes.
- The actor-distinguishing layer is git commit metadata
  (`user.name` / `user.email`) plus `Agent-Attribution:` trailers
  (ADR-0018, amended by ADR-0029 and ADR-0036; `Co-authored-by:` is
  reserved for human–human collaboration).
- See **Single-Identity Workflow** below for the convention.

---

## Multi-Identity Model (ADR-0011)

The framework recommends three GitHub identities for projects that have
separate human and agent operators:

| Identity | Purpose |
| --- | --- |
| **Human account** | Interactive ownership, administration, merging |
| **Agent-committer account** | Opens PRs, authors code commits |
| **Agent-reviewer account** | Authors reviews and comments |

Rules:

- PRs created by agents MUST be authored by the agent identity (not the human).
- Commit signing ("Verified") is nice-to-have, not required.
- Git commit author identity (`user.name` / `user.email`) and GitHub PR/review identity (`gh auth status`) are separate concepts.

## Single-Identity Workflow (ADR-0018)

When you (the agent) operate in single-identity mode — one GitHub login
shared with the human — preserve the audit trail by setting your commit
metadata correctly.

### Per-commit override

```bash
git -c user.name="Opus 5" \
    -c user.email="claude-code@tais-den.dev" \
    commit -m "..."
```

Use this when authoring one commit as an agent. Don't mutate global
`git config user.email`.

### Per-session configuration

For sustained agent work in one session, set once via env or local
config:

```bash
export GIT_AUTHOR_NAME="Opus 5"
export GIT_AUTHOR_EMAIL="claude-code@tais-den.dev"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
```

### Hybrid sessions

When you and the human co-author a commit (e.g., the human wrote the
code, you wrote the commit message, or vice versa), the human is the
accountable author: commit under the human identity and record each
contributing agent in an `Agent-Attribution:` trailer (ADR-0036):

```text
docs: explain single-identity workflow

Agent-Attribution: actor=claude-code; model=anthropic/claude-opus-5; role=Implementer; session=implementation
```

`Co-authored-by:` is reserved for human–human collaboration and must not
be used for agent participation (ADR-0036): a model cannot hold
co-authorship, and GitHub mints a contributor avatar for every
`Co-authored-by:` name. `Agent-Attribution:` is not rendered by GitHub
but is parsed by `git log --format=%(trailers)`.

### Authorship form (this repo)

`user.name` carries the **model** display name; `user.email` carries the
**actor** — the agent framework, or the human:

| Commit source | Author line |
| --- | --- |
| Claude Code running Opus 5 | `Opus 5 <claude-code@tais-den.dev>` |
| Hermes Agent (multi-model framework) | `Hermes Agent <hermes-agent@tais-den.dev>` |
| The human, unassisted | `Joey Clark <administrator@ajoeofalltrades.dev>` |

Known actor emails: `claude-code@tais-den.dev`, `hermes-agent@tais-den.dev`,
`hermes-cron@tais-den.dev`, `codex@tais-den.dev`, `codex-cron@tais-den.dev`,
`github.marten@fwd.mtnden.org`, `administrator@ajoeofalltrades.dev`. The
canonical alias table lives in `.mailmap` (ADR-0036).

> **Adopting this convention:** these are this repository's own actor
> aliases on its `tais-den.dev` domain. Adopters substitute their own
> domain and actor names — the binding part is the pattern (one login,
> per-actor email aliases, `Agent-Attribution:` trailers), not these
> concrete values.

Verify both fields with `git config --get user.name` and
`git config --get user.email` before any commit in a fresh session — and
verify them against what you actually are, not merely that they are set.
An unset identity is the common, obvious failure: git falls back to a
hostname-derived value that is visibly meaningless. A *stale* identity is
the dangerous one: a `user.name` left over from a previous session's
different model is well-formed and plausible, and passes a check that
only confirms the field is non-empty. Compare the configured `user.name`
— and any `model=` value about to be written into an `Agent-Attribution:`
trailer — against your own model identity as stated in your current
system context, not against inherited config or a prior commit's trailer.
If either is wrong, stale, or unset, use the per-commit override form
above.

See `workflows/git-and-gh-conventions.md` for the full convention and
forward-compatibility notes.

---

## Defaults

| Setting | Value |
| --- | --- |
| Default branch | `trunk` |
| Canonical remote | `origin` |
| Merge strategy | Squash-merge |
| GitHub | Required |

---

## Mandatory Branching Rule

**All changes MUST go through a feature branch and pull request.** Direct pushes to the default branch (`trunk`) are prohibited for agents. This applies to every change, no matter how small — including documentation-only changes, typo fixes, and skill updates.

The only exception is an emergency hotfix explicitly authorized by a human, and even then the agent should prefer a PR if at all possible.

---

## Standard Workflow

### 0. Verify Identity (Agents — Every Time)

```bash
gh auth status
```

If the wrong account is active:

```bash
gh auth switch --user <correct-username>
```

### 1. Sync Trunk

```bash
git switch trunk
git pull --ff-only origin trunk
```

### 2. Create a Feature Branch

Use these prefixes:

| Prefix | Use |
| --- | --- |
| `feat/` | User-visible or functional change |
| `fix/` | Bug fix |
| `docs/` | Documentation-only |
| `chore/` | Tooling/maintenance |
| `refactor/` | Refactors with no behavior change |
| `test/` | Tests only |

```bash
git switch -c feat/<short-slug>
```

### 3. Commit Your Work

Use Conventional Commits (lite):

| Type | Use |
| --- | --- |
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation |
| `chore:` | Tooling/maintenance |
| `refactor:` | Refactor, no behavior change |
| `test:` | Tests only |

Optional scope: `feat(api): ...`

**Commit body (agents):** Include a useful body unless the change is truly trivial:

```text
Why: intent / context
What: high-level summary
Risk: what could break
Validation: what was run (or explicitly "not run")
```

Do not include secrets (tokens, private keys, credentials) in commit messages.

```bash
git add -A
git commit -m "<type>: <summary>"
```

### 4. Push

```bash
git push -u origin HEAD
```

### 5. Open a PR

```bash
gh pr create --fill
```

Use `--draft` if you expect iteration:

```bash
gh pr create --fill --draft
```

**PR body template (agents):**

```text
Summary:
Context / Why:
Changes:
Validation:
Risk / Rollback:
```

Do not include secrets in PR descriptions.

### 6. Keep Your Branch Updated

Preferred: rebase on `trunk`.

```bash
git fetch origin
git rebase origin/trunk
```

If already pushed, update the PR branch safely:

```bash
git push --force-with-lease
```

**PR update comment (agents):** After pushing follow-up commits (especially in response to review feedback), add a PR comment summarizing:

```text
Addressed review feedback:
- ✅ ITEM_1
- ✅ ITEM_2
Validation: COMMANDS_RUN (or "not run")
```

### 7. Checks + Review

```bash
gh pr view --web
gh pr status
```

### 8. Merge

**Agents MUST NOT merge PRs.** This is a non-overridable safety gate (ADR-0012).

Two merge paths are available:

#### Path A: Human merges manually

A human reviews the PR and clicks the merge button in the GitHub UI. The agent should request review and wait.

#### Path B: CI-based auto-merge (when configured)

If the repository has GitHub auto-merge or a merge queue enabled, the agent can enable auto-merge on the PR after CI passes:

```bash
# Enable auto-merge with squash strategy after CI checks pass
gh pr merge --auto --squash
```

This is **not** the same as `gh pr merge` (which merges immediately). `--auto` tells GitHub "merge this PR automatically once all required CI checks pass." The actual merge is performed by GitHub's infrastructure, not by the agent. This is compliant with ADR-0012 because:

- The merge is triggered by CI passing, not by the agent's command.
- A human must have configured auto-merge or merge queue as a repo setting.
- The agent can be blocked from merging directly via branch protection rules.

**Recommended workflow for CI auto-merge:**

1. Open the PR (steps 1-5 above).
2. Wait for CI checks to start running.
3. Once CI passes, run `gh pr merge --auto --squash`.
4. GitHub merges the PR automatically when all required checks pass.
5. The branch is deleted automatically (if configured) or the agent cleans up locally.

---

## CI-Based Auto-Merge Workflow (Detailed)

This pattern is the preferred way to get changes merged without requiring a human to click the merge button, while staying within the non-overridable gate.

### Prerequisites

- The repository must have **branch protection** enabled on `trunk` requiring CI checks to pass.
- Either **GitHub auto-merge** or a **merge queue** must be configured in the repo settings.
- The agent's token must have `pull_request: write` scope (to set auto-merge).

### Full Sequence

```bash
# 1. Sync and branch
git switch trunk
git pull --ff-only origin trunk
git switch -c feat/my-change

# 2. Make changes, commit
git add -A
git commit -m "feat: my change"

# 3. Push and open PR
git push -u origin HEAD
gh pr create --fill

# 4. Wait for CI to start and pass
#    (poll with `gh pr status` or `gh pr view <number>`)

# 5. Enable auto-merge once CI is green
gh pr merge --auto --squash

# 6. Confirm merge completed
gh pr status
```

### What the Agent Must Not Do

- **Do NOT** run `gh pr merge` without `--auto` — that merges immediately and violates ADR-0012.
- **Do NOT** push directly to `trunk` — always use a branch and PR.
- **Do NOT** bypass branch protection by using `--admin` or force-pushing to the default branch.

---

## Versioning and Releases

### Semantic Versioning by Project Type

| Project Type | Major (breaking) | Minor (feature) | Patch (fix) |
| --- | --- | --- | --- |
| **Libraries** | Removing/renaming public exports, changing signatures | Adding new exports, optional params | Bug fixes, internal refactors |
| **Services/APIs** | Removing endpoints, changing response shapes | Adding new endpoints, optional fields | Bug fixes, perf improvements |
| **Doc/Standards Kits** | Removing/renaming exported files, changing vendored mount path | New guidelines, workflows, templates, skills | Typo fixes, clarifications |
| **CLIs** | Removing/renaming commands/flags, changing defaults | New commands/flags, opt-in output formats | Bug fixes, help text improvements |

**General rule:** If unsure whether a change is breaking, treat it as breaking.

### Changelog Conventions

Follow Keep a Changelog format (<https://keepachangelog.com>). This framework uses a curated subset.

Sections (use only those that apply per release):

| Section | Use |
| --- | --- |
| **Added** | New features or capabilities |
| **Changed** | Changes to existing functionality |
| **Deprecated** | Features that will be removed in a future release |
| **Removed** | Features removed in this release |
| **Fixed** | Bug fixes |
| **Security** | Vulnerability fixes |

**Ownership:**

- Changelogs are **human-curated**, not auto-generated from commits.
- Agents MAY append entries to the `[Unreleased]` section when explicitly instructed during feature work.
- Humans review and finalize changelog entries as part of the release decision.
- Agents MUST NOT remove or rewrite existing changelog entries.

### Release Process

1. **Feature work** happens on branches, merged to the main branch via PRs.
2. When ready to release, open a **release-prep PR** that:
   - Moves `[Unreleased]` entries to a new version section.
   - Bumps version numbers in project manifests (`package.json`, `pyproject.toml`, etc.).
   - Updates any version references in documentation.
3. A human reviews and merges the release-prep PR.
4. A human (or CI triggered by the merge) creates a git tag and GitHub Release.
5. A human approves package publishing to registries (if applicable).

### Agent-Safe vs Human-Gated Actions

| Action | Agent-safe? | Notes |
| --- | --- | --- |
| Draft changelog entries | Yes (when instructed) | Append to `[Unreleased]` only |
| Bump minor/patch version | Yes (when instructed) | Release-prep PRs only |
| Bump major version | **No** | Requires human approval |
| Open release-prep PR | Yes (when instructed) | Human merges |
| Prepare tag commands | Yes | In PR description or script |
| Push tags to remote | **No** | Requires human approval |
| Publish to registries | **No** | Requires human approval |
| Merge release PRs | **No** | Requires human approval |
| External announcements | **No** | Requires human approval |
| Enable auto-merge on a PR | Yes | Only with `--auto` flag; never `gh pr merge` without it |

### Dependency Versioning

- Always commit lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `Pipfile.lock`, `poetry.lock`).
- Agents MUST NOT delete or regenerate lockfiles as part of feature work.
- Dependency updates should be their own PR, not mixed into feature work.
- Agents MUST NOT run `npm update`, `pip install --upgrade`, or equivalent commands during feature work unless explicitly instructed.
- If a test fails due to a dependency issue, report the failure — do not attempt to fix it by updating dependencies.

### Submodule Versioning

- Submodule bumps should be their own commit or PR.
- When bumping a submodule, reference the target version/tag in the commit message.
- Agents MAY open submodule-bump PRs when instructed.
- Agents MUST NOT bump submodules during unrelated feature work.
- After bumping a submodule, verify that all references to vendored paths still resolve correctly.

---

## Work-Item Stance and Autonomous Gates

The skill applies to PRs and commits, but governed work starts earlier — at the work item.
Per `FS-0018`, every agent action on a work item (label change, phase change, comment) MUST
be preceded by an activity-record entry in the documented stance format:

```text
agent-stance: mode=<mode>; role=<role>; model=<model>; session=<session-name>; rationale=<one-line reason>
```

Where `<mode>` is one of the five session modes from `workflows/session-modes.md`, or one of the
meta-modes `autonomous`, `consensus`, or `review-board` per `ADR-0022`. `<role>` is a primary role
from `guidelines/ROLE_CONTRACT.md`. The value must come from the enumerated set; non-enumerated
values are invalid.

### Type-keyed checkpoints (`ADR-0019`)

An agent operating without a human present MUST NOT transition a work item's phase past the
Type-determined checkpoint without explicit human approval:

| Type | Autonomous checkpoint |
| --- | --- |
| `feature` | phase may not advance past Approved |
| `bug` | phase may not advance past Approved |
| `task` | phase may not advance past In Progress |

A work item whose Type is unset is treated at the most restrictive setting.

### `question` label suppression (`ADR-0020`)

If the `question` label is set on a work item, the agent MUST NOT perform any work-item
transitions (label, phase, or comment) except to remove the `question` label itself when the
human's response resolves the question.

### Cron-fired actor identity (`ADR-0021`)

An unattended agent (cron, webhook, scheduled detection) carries:

- A dedicated `user.email` distinct from both the human and the interactive-agent address.
- A `mode=autonomous` marker in every stance entry and `Agent-Attribution:` trailer.
- A `session=<job-name>` value naming the triggering job.

The actor table in `workflows/git-and-gh-conventions.md` carries the email aliases per actor.

## Document Hygiene Gate (Before Marking PR Ready)

Before marking a PR as ready for review, verify all of the following:

1. **Status fields are current** — All FS and PLAN documents referenced by this PR have accurate `status:` values.
2. **`updated:` dates are current** — Any modified FS, PLAN, or ADR has its `updated:` front matter field set to today's date.
3. **README index files are current** — If you added or changed the status of a document in `docs/specifications/`, `docs/change-plans/`, or `docs/decisions/`, the corresponding `README.md` reflects the change.
4. **CHANGELOG entry exists** — If this PR introduces a user-visible change (feature, fix, breaking change), there is a corresponding entry in `CHANGELOG.md` under `[Unreleased]` or the appropriate version section.
5. **Cross-references are complete** — FS `related_adrs` and PLAN `related_specs` front matter fields reference all relevant companion documents.
6. **Interfaces match reality** — The files touched by this PR align with the `interfaces:` declared in the governing FS. If they diverge, update the FS or explain in the PR description.
7. **Status consistency check passes** — Run `npm run check:status` and resolve all reported violations before marking the PR ready.

---

## Related Skills

- `skills/role-aware-session/SKILL.md` — session mode and role stance before acting on a branch or PR
- `skills/framework-health-audit/SKILL.md` — the hygiene gate and `check:status` run before a PR is marked ready

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
