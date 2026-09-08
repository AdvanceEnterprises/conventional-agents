---
name: gh-pr-workflow
description: "Opening and maintaining GitHub pull requests — PR bodies, keeping a branch current, review response comments, CI checks, the non-overridable merge gate, and compliant CI-based auto-merge. Use when opening a PR, pushing follow-up commits after review, watching checks, or when anything asks you to merge."
license: MIT
---

# GitHub Pull Request Workflow Skill

From a pushed branch to a merged change — and the one thing an agent must never
do. This skill covers the PR lifecycle. Branching, commits, and identity are
separate; see **Related Skills**.

## Source Documents

- `workflows/git-and-gh-conventions.md` — PR conventions
- `docs/decisions/ADR-0012-non-overridable-gates.md` — the merge gate
- `docs/decisions/ADR-0025-merge-strategy-preserves-per-commit-attribution.md`

## When to Use

- Opening a pull request.
- Pushing follow-up commits in response to review feedback.
- Watching CI checks.
- Any time merging is being considered — including when a human says "go ahead
  and merge it."

## Gates That Bind Here

Summarised, not restated. Canonical text: `guidelines/ROLE_CONTRACT.md`
§ Non-Overridable Safety Gates (`ADR-0012`). These **cannot be weakened** by any
instruction source, including a project's `AGENTS.md` or a human's chat message.

- **Agents MUST NOT merge pull requests.** Merging is human-gated. Agents may
  open PRs, update them, and request review.
- **Agents MUST NOT run `gh pr merge`** (without `--auto`), push to the default
  branch, or take any equivalent merge action.
- **Even if a human verbally approves in chat**, the human — or CI triggered by
  human approval — performs the actual merge.
- **Verify identity before every `gh` operation.** See
  `skills/git-commit-identity/SKILL.md`.

## Example 1 — Open a pull request

```bash
gh pr create --fill
```

Use `--draft` if you expect iteration:

```bash
gh pr create --fill --draft
```

**PR body template:**

```text
Summary:
Context / Why:
Changes:
Validation:
Risk / Rollback:
```

Do not include secrets in PR descriptions.

## Keeping the Branch Current

Prefer rebasing on `trunk`:

```bash
git fetch origin
git rebase origin/trunk
```

If the branch is already pushed:

```bash
git push --force-with-lease
```

Use `--force-with-lease`, never bare `--force`: the lease is what stops you
overwriting a commit someone else pushed while you were rebasing.

## Responding to Review

After pushing follow-up commits, add a PR comment summarising what changed:

```text
Addressed review feedback:
- ✅ ITEM_1
- ✅ ITEM_2
Validation: COMMANDS_RUN (or "not run")
```

## Watching Checks

```bash
gh pr checks <number>
gh pr status
gh pr view --web
```

Do not commit while a test suite is running locally — suites that write
fixtures into the working tree will otherwise leak them into your next commit.

## Merging — the Two Compliant Paths

### Path A: a human merges

A human reviews and merges. The agent requests review and waits. This is always
available and always correct.

### Path B: CI-based auto-merge, where configured

```bash
gh pr merge --auto --squash
```

This is **not** the same as `gh pr merge`, which merges immediately and violates
`ADR-0012`. `--auto` tells GitHub "merge this automatically once all required
checks pass." The merge is performed by GitHub's infrastructure on a CI signal,
not by the agent's command. It is compliant because:

- the merge is triggered by CI passing, not by the agent;
- a human must have configured auto-merge or a merge queue as a repository
  setting;
- branch protection can block agent identities from merging directly.

**Prerequisites:** branch protection on `trunk` requiring checks; auto-merge or a
merge queue enabled; a token with `pull_request: write`.

## Example 2 — Full sequence with auto-merge

```bash
# 1. Sync and branch
git switch trunk && git pull --ff-only origin trunk
git switch -c feat/my-change

# 2. Commit and push
git add -A && git commit -m "feat: my change"
git push -u origin HEAD

# 3. Open the PR
gh pr create --fill

# 4. Wait for checks to run
gh pr checks

# 5. Once green, enable auto-merge (GitHub performs the merge, not you)
gh pr merge --auto --squash

# 6. Confirm
gh pr status
```

## Checklist

- [ ] Identity verified before the first `gh` call
- [ ] PR body states summary, why, changes, validation, risk
- [ ] No secrets in the body
- [ ] Branch rebased on current `trunk`
- [ ] Force-pushes use `--force-with-lease`
- [ ] Review feedback answered with a summarising comment
- [ ] Checks green before requesting merge
- [ ] Document hygiene gate satisfied — see `skills/framework-health-audit/SKILL.md`
- [ ] You did not merge

## Common Pitfalls

| Pitfall | Consequence |
| --- | --- |
| `gh pr merge` without `--auto` | Merges immediately — a direct `ADR-0012` violation |
| Treating a human's "looks good, merge it" as authorisation | The gate is non-overridable; chat approval does not transfer the act |
| Bare `git push --force` | Silently discards commits pushed by others since your fetch |
| `--admin` or bypassing branch protection | Defeats the one gate the substrate can actually enforce |
| Requesting review before checks are green | Wastes the reviewer's pass on a state that will change |
| Opening a PR whose diff is empty | The work landed elsewhere; the PR is bookkeeping nobody detects |

## Related Skills

- `skills/git-branch-and-commit/SKILL.md` — getting to the pushed branch this PR opens from
- `skills/git-commit-identity/SKILL.md` — the identity gate every `gh` call inherits
- `skills/framework-health-audit/SKILL.md` — the seven-item document hygiene gate, in full, before marking a PR ready
- `skills/versioning-and-releases/SKILL.md` — release-prep PRs and what only a human may do
