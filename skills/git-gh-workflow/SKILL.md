# Git/GH Workflow Skill

Encodes the conventional-agents git and GitHub conventions, versioning and release process, and multi-identity model into actionable guidance.

## Source Documents

- `workflows/git-and-gh-conventions.md` — branching, commits, PRs, multi-identity model
- `workflows/versioning-and-releases.md` — semver, changelogs, release process, agent-safe vs human-gated actions
- `docs/decisions/ADR-0011.md` — multi-identity GitHub model (human + agent-committer + agent-reviewer)
- `docs/decisions/ADR-0012.md` — non-overridable safety gates

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

---

## Multi-Identity Model (ADR-0011)

Three GitHub identities:

| Identity | Purpose |
|---|---|
| **Human account** | Interactive ownership, administration, merging |
| **Agent-committer account** | Opens PRs, authors code commits |
| **Agent-reviewer account** | Authors reviews and comments |

Rules:
- PRs created by agents MUST be authored by the agent identity (not the human).
- Commit signing ("Verified") is nice-to-have, not required.
- Git commit author identity (`user.name` / `user.email`) and GitHub PR/review identity (`gh auth status`) are separate concepts.

---

## Defaults

| Setting | Value |
|---|---|
| Default branch | `trunk` |
| Canonical remote | `origin` |
| Merge strategy | Squash-merge |
| GitHub | Required |

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
|---|---|
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
|---|---|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation |
| `chore:` | Tooling/maintenance |
| `refactor:` | Refactor, no behavior change |
| `test:` | Tests only |

Optional scope: `feat(api): ...`

**Commit body (agents):** Include a useful body unless the change is truly trivial:

```
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

```
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

```
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

### 8. Merge (Human-Only)

- Use squash-merge.
- Delete the branch after merge.
- **Agents MUST NOT merge PRs.** This is a non-overridable safety gate (ADR-0012).

---

## Versioning and Releases

### Semantic Versioning by Project Type

| Project Type | Major (breaking) | Minor (feature) | Patch (fix) |
|---|---|---|---|
| **Libraries** | Removing/renaming public exports, changing signatures | Adding new exports, optional params | Bug fixes, internal refactors |
| **Services/APIs** | Removing endpoints, changing response shapes | Adding new endpoints, optional fields | Bug fixes, perf improvements |
| **Doc/Standards Kits** | Removing/renaming exported files, changing vendored mount path | New guidelines, workflows, templates, skills | Typo fixes, clarifications |
| **CLIs** | Removing/renaming commands/flags, changing defaults | New commands/flags, opt-in output formats | Bug fixes, help text improvements |

**General rule:** If unsure whether a change is breaking, treat it as breaking.

### Changelog Conventions

Follow Keep a Changelog format (`vendor/keep-a-changelog/`).

Sections (use only those that apply per release):

| Section | Use |
|---|---|
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
|---|---|---|
| Draft changelog entries | Yes (when instructed) | Append to `[Unreleased]` only |
| Bump minor/patch version | Yes (when instructed) | Release-prep PRs only |
| Bump major version | **No** | Requires human approval |
| Open release-prep PR | Yes (when instructed) | Human merges |
| Prepare tag commands | Yes | In PR description or script |
| Push tags to remote | **No** | Requires human approval |
| Publish to registries | **No** | Requires human approval |
| Merge release PRs | **No** | Requires human approval |
| External announcements | **No** | Requires human approval |

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

## Prohibitions

- **Do NOT** merge pull requests (non-overridable gate).
- **Do NOT** push to the default branch.
- **Do NOT** assume the correct GitHub identity is active — verify every time.
- **Do NOT** bump major versions without human approval.
- **Do NOT** publish packages to registries without explicit human approval.
- **Do NOT** mix version bumps into feature commits — release-prep only.
- **Do NOT** remove or rewrite existing changelog entries.
- **Do NOT** delete or regenerate lockfiles during feature work.
- **Do NOT** run `npm update` or equivalent during feature work unless explicitly instructed.
- **Do NOT** bump submodules during unrelated feature work.
