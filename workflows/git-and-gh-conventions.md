# Git + GitHub (gh) conventions

This document is the canonical, copy/pasteable guide for how we use Git + GitHub in this repo set.

Normative requirements are derived from:

- Spec: FS-0003
- ADR: ADR-0011

## Defaults

- Default branch name: `trunk`
- Canonical remote name: `origin`
- GitHub is required (for now)
- Default merge strategy: squash-merge

## Setup (one-time per machine)

### Ensure new repos default to `trunk`

Git’s default branch name for `git init` depends on git version and configuration. To make `trunk` reliable:

- Run: `git config --global init.defaultBranch trunk`

Validation:

- `mkdir /tmp/test-repo && cd /tmp/test-repo && git init && git branch --show-current` returns `trunk`.

## Repo setup (per clone)

### Remote naming

- Keep the canonical remote named `origin`.
- Optionally add `upstream` if you are working from a fork.

If you cloned a repo and the remote is not named `origin`, rename it:

- `git remote rename <current> origin`

## Branching

### Branch naming

Use these prefixes:

- `feat/` — user-visible or functional change
- `fix/` — bug fix
- `docs/` — documentation-only
- `chore/` — tooling/maintenance
- `refactor/` — refactors with no behavior change
- `test/` — tests only

## Commits

Use Conventional Commits (lite) — based on the [Conventional Commits](https://www.conventionalcommits.org/) spec (vendored at `vendor/conventional-commits/`):

- `feat: ...`
- `fix: ...`
- `docs: ...`
- `chore: ...`
- `refactor: ...`
- `test: ...`

Optional scope is allowed:

- `feat(api): ...`

### Commit bodies (agents)

Agent-authored commits SHOULD include a useful body unless the change is truly trivial.

Recommended body fields:

- Why: intent / context
- What: high-level summary
- Risk: what could break
- Validation: what was run (or explicitly "not run")

Do not include secrets (tokens, private keys, credentials) in commit messages.

## Standard workflow

### 0) Verify identity (agents)

Before any `gh` or `git push` operation, verify you are using the correct GitHub account:

- `gh auth status`

If the wrong account is active:

- `gh auth switch --user <correct-username>`

This is a non-overridable safety gate (ADR-0012). Do this every time, not just once per session.

### 1) Sync `trunk`

- `git switch trunk`
- `git pull --ff-only origin trunk`

### 2) Create a feature branch

- `git switch -c feat/<short-slug>`

### 3) Commit your work

- `git add -A`
- `git commit -m "<type>: <summary>"`

### 4) Push

- `git push -u origin HEAD`

### 5) Open a PR

- `gh pr create --fill`

Use `--draft` if you expect iteration:

- `gh pr create --fill --draft`

#### PR body template (agents)

Agent-authored PRs MUST include enough context for review. Use this template (copy/paste):

- Summary:
- Context / Why:
- Changes:
- Validation:
- Risk / Rollback:

Do not include secrets (tokens, private keys, credentials) in PR descriptions.

### 6) Keep your branch updated

Preferred: rebase on `trunk`.

- `git fetch origin`
- `git rebase origin/trunk`

If you already pushed, update the PR branch safely:

- `git push --force-with-lease`

#### PR update comment (agents)

After you push follow-up commits (especially in response to review feedback), add a PR comment summarizing:

- what feedback was addressed
- what changed
- what validation was performed (or explicitly "not run")

Example:

- Addressed review feedback:
  - ✅ ITEM_1
  - ✅ ITEM_2
- Validation: COMMANDS_RUN (or "not run")

### 7) Checks + review

- `gh pr view --web`
- `gh pr status`

### 8) Merge

- Use squash-merge.
- Delete the branch after merge.
- **Agents MUST NOT merge PRs.** Merging is a human-gated action. This is a non-overridable safety gate (ADR-0012). Agents open the PR; humans merge it.

## Multi-identity model (ADR-0011)

We assume three GitHub identities:

1) Human account (interactive ownership/administration)
2) Agent-committer account (opens PRs and authors code commits)
3) Agent-reviewer account (authors reviews/comments)

Rules:

- PRs created by agents MUST be authored by the agent identity (not the human).
- Commit signing (“Verified”) is nice-to-have, not required.

### Practical notes

Git commit author identity and GitHub PR/review identity are separate:

- git author: `user.name` / `user.email`
- GitHub identity: `gh auth status` (active account)

If you use multiple accounts, ensure you explicitly switch contexts before taking actions:

- `gh auth switch -u <username>`
