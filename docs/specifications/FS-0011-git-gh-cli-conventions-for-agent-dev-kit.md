# Git + gh CLI conventions for agent-dev-kit

Generated: 2026-02-07T13:34:56

---
type: feature-spec
id: FS-0011
status: approved
title: Git + gh CLI conventions for the kit
owner: Tai
test_required: false
interfaces:
  - docs/ (documentation only)
related_adrs:
  - ADR-0011
supersedes: []
requires: []
tags:
  - git
  - github
  - gh
created: 2026-02-07
updated: 2026-02-07
---
<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: Git + gh CLI conventions for the kit

## Status
- Approved

## Summary
Define opinionated, copy/pasteable Git and GitHub (gh CLI) conventions for Tai’s personal kit, with wording and structure that can later be generalized for public release.

## Goals
- Provide a single, canonical set of Git conventions (branch naming, commit style, sync patterns) that Tai and agentic workflows can follow consistently.
- Standardize GitHub + `gh` usage patterns for PR creation, updates, checks, and merges.
- Document the multi-identity model (human + agent-committer + agent-reviewer) and how authorship/auth are managed.

## Non-Goals
- Enforcing these conventions via CI, server-side hooks, or repo settings (documentation only, for now).
- Supporting non-GitHub forges (GitHub is a requirement in this version).
- Designing a full release-quality public “contributing guide” (this spec targets Tai’s kit first).

## Users / Stakeholders
- Primary: Tai
- Secondary: future contributors/users of the kit
- Operational actors: “agent-committer” and “agent-reviewer” identities (whether one or multiple agents is out of scope)

## Interfaces
- Type: Docs
- Details:
  - Add a documentation section describing:
    - default branch naming
    - canonical remote naming
    - PR + merge workflow
    - identity/authorship rules
    - recommended snippets/aliases

## Conventions (normative)
### Branching
- Default branch name MUST be `trunk` (local and remote).
- Feature branches SHOULD use the prefixes:
  - `feat/`, `fix/`, `docs/`, `chore/`, `refactor/`, `test/`

### Remotes
- Canonical remote name MUST be `origin`.
- Repos MAY add additional remotes (e.g., `upstream`) as needed, but `origin` remains the default.

### Commits
- Use “Conventional Commits (lite)” prefixes:
  - `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`
  - Optional scope MAY be used: `feat(api): ...`

### PR workflow (GitHub required)
- PRs SHOULD be created with `gh pr create --fill` (optionally `--draft`).
- The default merge strategy SHOULD be squash-merge.
- Branches SHOULD be deleted after merge.

### Multi-identity model (GitHub)
- The kit assumes three GitHub identities:
  1) Human account (interactive ownership)
  2) Agent-committer account (opens PRs and authors code commits)
  3) Agent-reviewer account (authors reviews/comments)

- Rule: PRs created by agents MUST be authored by the agent account (not the human).
- Commit signing (GPG/SSH “Verified”) is NICE-TO-HAVE, not required.

## Success Criteria
- Given a new repo initialized locally, when Tai runs `git init`, then the default branch is named `trunk`.
- Given a repo cloned from GitHub, when following the kit’s setup steps, then the canonical remote is named `origin`.
- Given a feature branch, when following the kit’s documented workflow, then a PR can be created using `gh pr create --fill` without additional undocumented steps.
- Given a PR opened by an agent, when viewing the PR in GitHub, then the PR author is the agent account (not the human account).
- Given a merged PR following the kit’s policy, when viewing `trunk` history, then the PR appears as a single squash commit and the feature branch is deleted.

## Edge Cases
- Cloning repos whose default branch is not `trunk` (kit should describe how to adapt, but does not need to support automatically).
- Working across multiple GitHub auth contexts on one machine (kit must emphasize explicit context selection to avoid acting as the wrong identity).

## Out of Scope
- Automated enforcement tooling (pre-commit hooks, server hooks, branch protection rules).
- Supporting GitLab/Bitbucket/Forgejo/etc.
- Defining how agents are provisioned or whether one/many agents exist.

## Dependencies
- `git`
- `gh` (GitHub CLI)
- GitHub accounts/credentials for the three identities

## Rollout / Migration (if applicable)
- Update kit docs to include this guidance.
- For existing repos:
  - keep `origin` as the canonical remote
  - update local default branch expectations where applicable

## Observability (if applicable)
- N/A (docs-only)

## Security / Privacy (if applicable)
- Data handled: GitHub auth tokens/SSH keys (credentials are not stored in the kit; only conventions are documented).
- Threats considered: accidentally performing actions as the wrong GitHub identity.
- Mitigations: require explicit identity/context selection steps in docs; avoid ambiguous remote hostnames where possible.

## Open Questions
- None blocking (this is documentation-first).