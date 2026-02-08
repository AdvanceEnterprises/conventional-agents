---
type: feature-spec
id: FS-0012
status: draft
title: Agent-authored commit + PR commentary policy
owner: Tai
test_required: false
interfaces:
  - docs/ (policy documentation)
related_adrs:
  - ADR-0011
supersedes: []
requires:
  - FS-0011
tags:
  - git
  - github
  - gh
  - agents
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

# Feature Spec: Agent-authored commit + PR commentary policy

## Status

- Draft

## Summary

Define a documentation-only policy for coding agents to produce consistently useful written context on commits, pull requests, and PR update cycles (follow-up pushes after review feedback). This improves review speed, auditability, and handoff quality without adding enforcement.

## Goals

- Standardize what “good commentary” means for agent-created commits and PRs.
- Ensure PRs created by agents include enough context for a reviewer to evaluate intent, risk, and validation.
- Ensure follow-up pushes addressing review feedback are accompanied by a short PR comment summarizing what changed.

## Non-Goals

- Adding CI enforcement for commit messages or PR body structure.
- Requiring commit signing.
- Changing merge strategy or branching conventions (see FS-0011).

## Users / Stakeholders

- Primary: Tai
- Reviewers: agent-reviewer identity + human reviewers
- Authors: agent-committer identity (per ADR-0011)

## Interfaces

- Type: Docs
- Details:
  - Add/update documentation in `workflows/` describing:
    - minimum commit message/body expectations for agents
    - minimum PR description template for agents
    - PR update comment expectations after addressing feedback

## Policy (normative)

### Commit messages (agent commits)

- Subject MUST follow Conventional Commits (lite) used by FS-0011.
- Commit body SHOULD include, when applicable:
  - Why (intent)
  - What (high-level change)
  - Risk (what could break)
  - Validation (what was run / not run)

### PR descriptions (agent-created PRs)

PR body MUST include, at minimum:

- Summary
- Context / Why
- Changes
- Validation
- Risk / Rollback

### PR updates (after review feedback)

After pushing commits that address review feedback, the agent MUST add a PR comment summarizing:

- which review items were addressed
- what changed (high-level)
- validation performed (or explicitly “not run”)

## Success Criteria

- Given an agent-created commit with non-trivial changes, when viewed in `git log`, then it includes a descriptive subject and a body that covers intent and validation (or explicitly states validation was not run).
- Given an agent-created PR, when viewed on GitHub, then the PR body contains the required sections (Summary, Context/Why, Changes, Validation, Risk/Rollback).
- Given review feedback on an agent-created PR, when the agent pushes follow-up commits, then the PR has a new comment summarizing what feedback was addressed and what validation was performed.

## Edge Cases

- Trivial changes (e.g., typo fixes) where risk/rollback is “none” and validation is “not applicable”.
- Squashed merges: commit bodies on `trunk` may be derived from PR description depending on merge settings.

## Out of Scope

- Automated checks that fail PRs missing templates/fields.
- Policies for non-GitHub forges.

## Dependencies

- FS-0011 (Git + gh conventions)
- ADR-0011 (multi-identity model)

## Rollout / Migration (if applicable)

- Update `workflows/git-and-gh-conventions.md` to include:
  - commit message/body expectations
  - PR body template
  - required “PR update” comment pattern

## Observability (if applicable)

- N/A (policy-only)

## Security / Privacy (if applicable)

- Data handled: PR commentary may include operational details; avoid secrets/tokens.
- Threats considered: accidental disclosure in PR descriptions.
- Mitigations: include an explicit “Do not include secrets” note in the template.

## Open Questions

- None blocking.
