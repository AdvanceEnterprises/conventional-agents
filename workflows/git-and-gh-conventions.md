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

Use Conventional Commits (lite) — a framework-specific subset inspired by the [Conventional Commits](https://www.conventionalcommits.org/) spec:

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
- Agent Attribution (only if any agent authored this PR):
  - Hermes Agent — model=ollama-cloud/deepseek-v4-flash, role=Implementer, session=implementation

The Agent Attribution section summarizes the agent actors and their roles
for the PR as a whole. Per-commit model/role metadata lives in
`Agent-Attribution:` trailers on individual commits (see "Single-identity
workflow with agent co-attribution" below).

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

The framework recommends three GitHub identities for projects that have
separate human and agent operators:

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

## Single-identity workflow with agent co-attribution (ADR-0018, ADR-0029)

Most projects — including this repository — operate with one GitHub login
shared across human and agent actors. The single-identity workflow uses
git commit metadata to preserve the audit trail that ADR-0011's three
identities would otherwise provide.

**This section is the convention in force.** ADRs record why it changed;
this document records what it is. Where an ADR and this section appear to
disagree, this section is current and the ADR is historical.

### The convention

All commits, PRs, and reviews are authored under one GitHub login. The
distinguishing layer is git's `user.name` / `user.email`:

| Field | Carries | Example |
| --- | --- | --- |
| `user.name` | Model display name, human-readable | `Opus 5` |
| `user.email` | The actor — agent framework or human — as an alias | `claude-code@tais-den.dev` |

| Commit source | Author line |
| --- | --- |
| Claude Code running Opus 5 | `Opus 5 <claude-code@tais-den.dev>` |
| Hermes running DeepSeek V4 | `DeepSeek V4 <hermes-agent@tais-den.dev>` |
| Joey, unassisted | `Joey Clark <taisden@tais-den.dev>` |

The human row is the exception: a human is not a model, so `user.name`
carries the person's name.

These addresses are aliases under the same login. GitHub renders each
commit's author email as a link to the same profile, but `git log`,
`git shortlog`, and downstream tooling can distinguish actors by email.

`user.name` carries a display form; the `Agent-Attribution:` trailer
carries the canonical provider-qualified model id. Where the two
disagree, the trailer is authoritative.

Note that `git shortlog` without `-e` groups by model and fragments across
model versions. Use `git shortlog -e` to group by actor, or add a
`.mailmap`.

### Per-commit override (recommended for one-off agent sessions)

When authoring a single commit as an agent, override the identity inline
rather than mutating global `git config`:

```bash
git -c user.name="Opus 5" \
    -c user.email="claude-code@tais-den.dev" \
    commit -m "..."
```

For hybrid sessions (human + agent co-authoring a single commit), also add
a `Co-authored-by:` trailer to the commit message:

```text
docs: explain single-identity workflow with agent co-attribution

Co-authored-by: Opus 5 <claude-code@tais-den.dev>
```

GitHub renders `Co-authored-by:` trailers natively as a second author chip
on the commit page.

For local-file agents (Hermes today, future agents that edit files
in this repo), also include an `Agent-Attribution:` trailer recording
the model, role, and session mode:

```text
docs: explain single-identity workflow with agent co-attribution

Co-authored-by: Opus 5 <claude-code@tais-den.dev>
Agent-Attribution: actor=Claude Code; model=anthropic/claude-opus-5; role=Head Architect; session=architecture-planning
```

The `Agent-Attribution:` trailer is not rendered by GitHub but is parsed
by `git log --format=%(trailers)` and verified by
`test/FS-0017/commit-attribution.bats`. It persists the role/session-mode
declaration that ROLE_CONTRACT §"Role and session transparency" requires
at session start, into the commit audit trail. Multiple
`Agent-Attribution:` trailers are permitted when more than one agent
contributed.

### Per-session configuration (recommended for sustained agent runs)

For an agent that will author many commits in one session, set the
identity once via environment or a local include:

```bash
# Bash — export once at session start
export GIT_AUTHOR_NAME="Opus 5"
export GIT_AUTHOR_EMAIL="claude-code@tais-den.dev"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
```

```ini
# ~/.gitconfig — conditional include for agent workspaces
[includeIf "gitdir:~/Developer/projects/agent-workspace/"]
    path = ~/.gitconfig-agent
```

```ini
# ~/.gitconfig-agent
[user]
    name = Opus 5
    email = claude-code@tais-den.dev
```

### When to use each layer

- **Pure-human commit** (Joey wrote the code, the message, the review):
  no special action. Default `user.email` should already be
  `taisden@tais-den.dev`.
- **Pure-agent commit** (agent wrote and committed autonomously):
  set the agent's `user.email` via per-commit override or per-session
  config. Add an `Agent-Attribution:` trailer recording model, role,
  and session mode. No `Co-authored-by:` trailer needed — the email
  alone identifies the actor.
- **Hybrid commit** (human and agent both contributed):
  set the *committer's* `user.email` to whoever ran `git commit`, add a
  `Co-authored-by:` trailer naming the other actor, and add an
  `Agent-Attribution:` trailer for each agent actor with their model
  and role. Both email and trailers are part of the audit trail.

### Forward compatibility with ADR-0011

When this repository (or any project following this convention) is ready to
transition to separate GitHub accounts, the migration path is:

1. Create `taisden-agent-committer` and `taisden-agent-reviewer` accounts.
2. Add the existing emails as additional addresses on each actor's
   GitHub profile so historical commits still link correctly.
3. Switch per-agent sessions from `GIT_AUTHOR_EMAIL` overrides to
   `gh auth switch --user <agent-account>`.
4. The `Co-authored-by:` convention continues unchanged — it now
   represents a cross-account relationship rather than same-account
   co-authorship.

See ADR-0018 for the original rationale and ADR-0029 for the change to
the name-field assignment.
