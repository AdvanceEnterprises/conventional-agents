---
name: git-branch-and-commit
description: "Branch naming, the mandatory feature-branch rule, Conventional Commits (lite), commit body structure, and pushing. Use when starting a change, naming a branch, writing a commit message or its body, or pushing work to a remote for the first time."
license: MIT
---

# Git Branch and Commit Skill

Getting from a clean trunk to a pushed branch. This skill covers branching,
committing, and pushing. Identity configuration and pull requests are separate;
see **Related Skills**.

## Source Documents

- `workflows/git-and-gh-conventions.md` — branching, commits, PRs
- `docs/decisions/ADR-0012-non-overridable-gates.md` — the merge gate

## When to Use

- Starting any change, however small.
- Naming a branch.
- Writing a commit message or deciding whether the change needs a body.
- Pushing a branch for the first time.

## Gates That Bind Here

Summarised, not restated. Canonical text: `guidelines/ROLE_CONTRACT.md`
§ Non-Overridable Safety Gates (`ADR-0012`).

- **Never push to the default branch.** Every change goes through a feature
  branch and a pull request.
- **Verify identity before pushing.** See `skills/git-commit-identity/SKILL.md`.
- **Run the test suite before committing.** Never commit a change that leaves
  tests failing.

## Defaults

| Setting | Value |
| --- | --- |
| Default branch | `trunk` |
| Canonical remote | `origin` |
| Merge strategy | Squash-merge |
| GitHub | Required |

## Mandatory Branching Rule

**All changes MUST go through a feature branch and pull request.** Direct pushes
to `trunk` are prohibited for agents. This applies to every change, no matter how
small — including documentation-only changes, typo fixes, and skill updates.

The only exception is an emergency hotfix explicitly authorised by a human, and
even then prefer a PR if at all possible.

## Branch Prefixes

| Prefix | Use |
| --- | --- |
| `feat/` | User-visible or functional change |
| `fix/` | Bug fix |
| `docs/` | Documentation-only |
| `chore/` | Tooling/maintenance |
| `refactor/` | Refactors with no behaviour change |
| `test/` | Tests only |

## Commit Types — Conventional Commits (lite)

| Type | Use |
| --- | --- |
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation |
| `chore:` | Tooling/maintenance |
| `refactor:` | Refactor, no behaviour change |
| `test:` | Tests only |

Optional scope: `feat(api): ...`

## Commit Bodies

Include a body unless the change is truly trivial:

```text
Why: intent / context
What: high-level summary
Risk: what could break
Validation: what was run (or explicitly "not run")
```

Do not include secrets (tokens, private keys, credentials) in commit messages.

## Example 1 — Sync, branch, commit, push

```bash
git switch trunk
git pull --ff-only origin trunk
git switch -c docs/clarify-branching-rule

# make changes, then:
git add -A
git commit -m "docs: clarify the mandatory branching rule"
git push -u origin HEAD
```

## Example 2 — Commit with a body and agent attribution

```bash
git -c user.name="Opus 5" -c user.email="claude-code@tais-den.dev" \
  commit -F - <<'MSG'
fix: reject empty label sets in the provisioning path

Why: an empty set silently no-opped and reported success.
What: fail with a named remediation instead of returning 0.
Risk: a caller relying on the silent no-op now sees a non-zero exit.
Validation: npm test (14/14 suites), npm run check:status.

Agent-Attribution: actor=claude-code; model=anthropic/claude-opus-5; role=Implementer; session=implementation
MSG
```

## Checklist

- [ ] Branched from an up-to-date `trunk`, never committed onto `trunk` itself
- [ ] Branch prefix matches the kind of change
- [ ] Commit type matches the kind of change
- [ ] Body present unless genuinely trivial
- [ ] No secrets in the message
- [ ] Identity verified (`skills/git-commit-identity/SKILL.md`)
- [ ] Test suite run and green before committing
- [ ] Pushed with `-u origin HEAD`, never to `trunk`

## Common Pitfalls

| Pitfall | Consequence |
| --- | --- |
| Committing directly on `trunk` because the change is "just a typo" | Violates the mandatory branching rule; there is no size exemption |
| Committing while a test suite is mid-run | Test fixtures written into the working tree get swept into the commit |
| `git add -A` without reading `git status` first | Unrelated or generated files enter the commit silently |
| A body that says "Validation: tests pass" without naming what ran | Unfalsifiable; state the command or write "not run" |
| Branch prefix chosen by habit rather than by change kind | Misleads reviewers about scope and risk |

## Related Skills

- `skills/git-commit-identity/SKILL.md` — who authors the commit, and the attribution trailer
- `skills/gh-pr-workflow/SKILL.md` — what happens after the push
- `skills/versioning-and-releases/SKILL.md` — why version bumps never ride along in a feature commit
- `skills/framework-health-audit/SKILL.md` — the gates to run before committing
