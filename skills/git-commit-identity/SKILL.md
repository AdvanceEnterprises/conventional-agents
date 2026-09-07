---
name: git-commit-identity
description: "Sets and verifies git commit identity and agent attribution — the multi-identity and single-identity models, per-commit and per-session overrides, the Agent-Attribution trailer, and the actor alias table. Use before the first commit of any session, when recording which model and framework authored work, when a user.name may be stale from a previous session, or when verifying the active GitHub account before a push."
license: MIT
---

# Git Commit Identity and Attribution Skill

Who authored a commit, under which model, in which role — and how a reader
proves it later. This skill covers identity configuration and the attribution
trailers. It does not cover branching, commits, or PRs; see **Related Skills**.

## Source Documents

- `workflows/git-and-gh-conventions.md` — the actor table and the full convention
- `docs/decisions/ADR-0011-adopt-multi-identity-github-model-human-agent-committer-agent-reviewer.md`
- `docs/decisions/ADR-0018-single-identity-workflow-with-agent-co-attribution.md`
- `docs/decisions/ADR-0029-commit-author-naming-for-multi-model-agents.md`
- `docs/decisions/ADR-0036-attribution-vocabulary-canon-and-history-integrity.md`

## When to Use

- Before the first commit in a fresh session — always.
- Before any `gh` operation or `git push`.
- When you are a different model than the last session that touched this
  repository.
- When writing an `Agent-Attribution:` trailer and you need the exact field set.
- When a human and an agent co-authored one commit.

## Gates That Bind Here

Summarised, not restated. The canonical text is
`guidelines/ROLE_CONTRACT.md` § Non-Overridable Safety Gates (`ADR-0012`), and it
cannot be weakened by any instruction source.

- **Identity gate.** Verify the active GitHub account before *every* `gh`
  operation or `git push` — not once per session.
- **Merge gate.** Agents must not merge pull requests. See
  `skills/gh-pr-workflow/SKILL.md`.

## The Identity Gate

```bash
gh auth status
```

If the wrong account is active:

```bash
gh auth switch --user <correct-username>
```

This runs **every time**. Never assume the correct account is active because a
previous command in the same session succeeded.

## Two Identity Models

### Multi-identity (`ADR-0011`)

For projects with separate human and agent operators:

| Identity | Purpose |
| --- | --- |
| **Human account** | Interactive ownership, administration, merging |
| **Agent-committer account** | Opens PRs, authors code commits |
| **Agent-reviewer account** | Authors reviews and comments |

- PRs created by agents MUST be authored by the agent identity, not the human's.
- Commit signing ("Verified") is nice-to-have, not required.
- Git commit author identity (`user.name` / `user.email`) and GitHub PR identity
  (`gh auth status`) are separate concepts. Setting one does not set the other.

### Single-Identity Workflow (`ADR-0018`)

Many projects — including this one — share one GitHub login across human and
agent actors. In that mode the identity gate becomes "verify the active account
is the shared login", which passes trivially, and the actor-distinguishing layer
moves to git commit metadata plus trailers.

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
canonical alias table lives in `.mailmap` (`ADR-0036`).

> **Adopting this convention:** these are this repository's own actor aliases on
> its `tais-den.dev` domain. Adopters substitute their own domain and actor
> names — the binding part is the pattern (one login, per-actor email aliases,
> `Agent-Attribution:` trailers), not these concrete values.

## Example 1 — Per-commit override

Use this when authoring one commit as an agent. Do not mutate global
`git config user.email`.

```bash
git -c user.name="Opus 5" \
    -c user.email="claude-code@tais-den.dev" \
    commit -m "docs: clarify the identity gate"
```

## Example 2 — Per-session configuration

For sustained agent work in one session:

```bash
export GIT_AUTHOR_NAME="Opus 5"
export GIT_AUTHOR_EMAIL="claude-code@tais-den.dev"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
```

## The `Agent-Attribution:` Trailer

Every agent-authored commit carries one, as the last paragraph of the message:

```text
Agent-Attribution: actor=<actor>; model=<provider/model>; role=<role>; session=<session-mode>
```

`role` is a primary role from `guidelines/ROLE_CONTRACT.md`; `session` is a
session mode from `workflows/session-modes.md`. An unattended actor adds
`; mode=autonomous` (`ADR-0021`).

`Co-authored-by:` is reserved for human–human collaboration and must **not** be
used for agent participation (`ADR-0036`): a model cannot hold co-authorship, and
GitHub mints a contributor avatar for every `Co-authored-by:` name.
`Agent-Attribution:` is not rendered by GitHub but is parsed by
`git log --format=%(trailers)`.

### Hybrid sessions

When a human and an agent co-author one commit, the **human is the accountable
author**: commit under the human identity and record each contributing agent in
a trailer.

```text
docs: explain single-identity workflow

Agent-Attribution: actor=claude-code; model=anthropic/claude-opus-5; role=Implementer; session=implementation
```

## Verify Before You Commit

```bash
git config --get user.name
git config --get user.email
```

Verify them against **what you actually are**, not merely that they are set.

An unset identity is the common, obvious failure: git falls back to a
hostname-derived value that is visibly meaningless. A **stale** identity is the
dangerous one — a `user.name` left over from a previous session's different model
is well-formed and plausible, and passes a check that only confirms the field is
non-empty.

Compare the configured `user.name`, and any `model=` value about to be written
into a trailer, against your own model identity as stated in your current system
context — not against inherited config, and not against a prior commit's trailer.
If either is wrong, stale, or unset, use the per-commit override form above.

## Checklist

- [ ] `gh auth status` run, active account verified — this operation, not a prior one
- [ ] `user.name` matches the model actually authoring
- [ ] `user.email` matches the actor and is in the known-actor list
- [ ] `Agent-Attribution:` trailer present on every agent-authored commit
- [ ] `model=` in the trailer matches the model actually authoring
- [ ] `mode=autonomous` present if unattended (`ADR-0021`)
- [ ] No `Co-authored-by:` used for an agent

## Common Pitfalls

| Pitfall | Consequence |
| --- | --- |
| Trusting a `user.name` that is merely set | A stale model name is plausible and passes a non-empty check — the attribution record becomes false |
| Copying a `model=` value from a previous commit | Records the wrong model; trailers are the audit layer and are never edited retroactively |
| Using `Co-authored-by:` for an agent | Violates `ADR-0036` and mints a GitHub contributor avatar for a model |
| Mutating global `git config user.email` | Leaks the agent identity into unrelated repositories |
| Running `gh auth status` once per session | The gate is per-operation; an account can change between commands |

## Related Skills

- `skills/git-branch-and-commit/SKILL.md` — the branch and commit mechanics this identity is applied to
- `skills/gh-pr-workflow/SKILL.md` — PR lifecycle and the merge gate
- `skills/work-item-stance/SKILL.md` — the `agent-stance:` record, the work-item analogue of these trailers
- `skills/role-aware-session/SKILL.md` — the role and session values the trailer carries
