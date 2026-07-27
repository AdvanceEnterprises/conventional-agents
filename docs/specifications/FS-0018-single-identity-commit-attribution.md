---
type: feature-spec
id: FS-0018
status: implemented
title: Single-identity commit attribution with model, role, and session metadata
owner: taisden
test_required: true
interfaces:
  - "docs/decisions/ADR-0018-single-identity-workflow-with-agent-co-attribution.md"
  - "workflows/git-and-gh-conventions.md"
  - "skills/git-gh-workflow/SKILL.md"
  - "roles/README.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "test/FS-0018/commit-attribution.bats"
related_adrs:
  - ADR-0018
supersedes: []
requires: []
tags: [identity, attribution, workflow, agent-audit]
created: 2026-07-27
updated: 2026-07-27
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

# Feature Spec: Single-identity commit attribution with model, role, and session metadata

## Status

- Implemented

## Summary

When human and agent actors share one GitHub login, the audit trail
needs an attribution layer beyond `user.email`. ADR-0011's
three-identity model is the framework's recommendation for projects
with separate accounts, but most projects (including this repo)
operate with one login.

This spec defines a three-layer attribution convention for single-identity
projects: distinguishing `user.email` per actor, `Co-authored-by:`
trailers for hybrid sessions, and `Agent-Attribution:` trailers
recording model, role, and session mode for any agent actor.

The convention is enforced by `test/FS-0018/commit-attribution.bats`,
which verifies that recent commits on the working branch follow the
layered pattern.

## Goals

- Preserve the audit trail ADR-0011 was designed to provide, using
  git commit metadata rather than separate GitHub accounts.
- Capture agent role and model identity in commits, so a Reviewer-role
  agent is distinguishable from an Implementer-role agent even when
  both commit under the same login.
- Persist the role/session-mode declaration that ROLE_CONTRACT §"Role
  and session transparency" already requires at session start, into
  the commit audit trail.
- Make the convention enforceable with `bats` so drift is caught
  before merge rather than discovered post-hoc.
- Keep `roles/` empty by default so host repos customizing the
  framework start from a clean slate rather than inheriting a
  pre-populated copy of the framework's role contract.

## Non-Goals

- Adding separate GitHub accounts for agents. The convention is
  designed for projects that share one login; the multi-identity
  model in ADR-0011 remains the framework's recommendation for
  projects with separate accounts.
- Replacing or superseding ADR-0011. ADR-0018 coexists with ADR-0011
  as a complementary operational model.
- Forcing the convention on legacy commits. The bats test enforces
  going forward from a recent cutoff; historical commits are
  out of scope.
- Defining a new document type. The convention is a commit-message
  pattern, not a new governed document.
- Pre-populating `roles/` with a customized ROLE_CONTRACT.md. The
  directory ships empty so host repos customize deliberately.

## Interfaces

- **`docs/decisions/ADR-0018-single-identity-workflow-with-agent-co-attribution.md`** —
  documents the convention and the rationale.
- **`workflows/git-and-gh-conventions.md`** — gains a "Single-identity
  workflow with agent co-attribution" section with per-commit override
  and per-session configuration examples, an updated PR body template
  with an "Agent Attribution" section, and "When to use each layer"
  guidance covering all three attribution layers.
- **`skills/git-gh-workflow/SKILL.md`** — learns the convention so
  agents recognize and apply it in interactive sessions.
- **`roles/README.md`** — explains that `roles/` ships empty by
  design and documents the customization workflow for host repos.
- **`docs/specifications/README.md`** — index row for FS-0018.
- **`docs/change-plans/README.md`** — index row for PLAN-0018.
- **`test/FS-0018/commit-attribution.bats`** — enforces the
  convention for recent commits.

## Success Criteria

Each bullet MUST be objectively verifiable, typically by
`test/FS-0018/commit-attribution.bats` or by direct `git log` /
`git config` inspection.

- **Given the workflow doc, when reading the "Single-identity workflow
  with agent co-attribution" section, then it documents the actor
  email table with at least three entries (human, Hermes Agent,
  GitHub Copilot), per-commit override form, per-session configuration
  form, and the three attribution layers (`user.email`,
  `Co-authored-by:`, `Agent-Attribution:`).**

- **Given the workflow doc, when reading the PR body template, then
  it includes an "Agent Attribution" subsection with example entries
  for each agent actor.**

- **Given a hybrid commit, when inspecting the commit message, then it
  includes a `Co-authored-by:` trailer naming the non-primary actor
  AND at least one `Agent-Attribution:` trailer for each agent actor
  recording actor name, model, role, and session mode.**

- **Given a pure-agent commit, when inspecting the commit message,
  then it includes at least one `Agent-Attribution:` trailer recording
  actor name, model, role, and session mode. The `Co-authored-by:`
  trailer is optional in this case.**

- **Given the bats test, when run against recent commits (last N
  commits on the current branch), then it passes without modification
  of the test cutoff anchor. The test must not require knowledge of a
  future merge SHA to function.**

- **Given `roles/`, when listing the directory contents, then it
  contains only `README.md` and no other files. The README explains
  why the directory ships empty and how to populate it for host
  repos.**

- **Given `test/FS-0018/commit-attribution.bats`, when read, then it
  contains assertions for: (a) recent commits have known actor
  emails, (b) recent commits using the default email have
  `Co-authored-by:` trailers, (c) the workflow doc and skill teach
  the convention, (d) ADR-0018 exists with proposed status, (e)
  ADR-0011 cross-references ADR-0018.**

- **Given `npm run check:status` and `npm run lint:docs`, when run,
  both pass without modification.**

## Out of Scope

- Adding separate GitHub accounts (per ADR-0011's full model).
- Backfilling attribution on legacy commits.
- A central registry of "known agent actors" — the convention
  permits any actor name; the bats test asserts that any
  `Co-authored-by:` email matches one of a small allowlist, but
  agent names in `Agent-Attribution:` are freeform.
- Custom tooling that renders `Agent-Attribution:` trailers in
  GitHub's UI — that's GitHub's domain.
- A separate "Agent Attribution" FS for the PR body convention.
  The PR body template lives in `workflows/git-and-gh-conventions.md`
  and is updated as part of this FS.

## Validation

We will consider this feature implemented successfully when:

1. `npm run check:status` passes.
2. `npm run lint:docs` passes (ADRs, specs, plans, workflows).
3. `test/FS-0018/commit-attribution.bats` passes against recent
   commits on the current branch.
4. A reviewer reading ADR-0018, the workflow doc section, and the
   bats test can identify the three attribution layers and understand
   when each applies.
5. `roles/` ships with only `README.md` and no pre-populated
   `ROLE_CONTRACT.md`.
