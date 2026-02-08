---
type: feature-spec
id: FS-0002
status: approved
title: Move workflow skills into agentic-dev-kit (dual-mode)
owner: ajoeofalltrades
test_required: true
interfaces: [Filesystem, CLI]
related_adrs: [ADR-0001, ADR-0002]
supersedes: []
requires: [ADR-0001, ADR-0002]
tags: [skills, tooling, docs, python]
created: 2026-02-05
updated: 2026-02-05
approved: 2026-02-05
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

# Feature Spec: Move workflow skills into agentic-dev-kit (dual-mode)

## Status

Approved

## Summary

Move the existing workflow/dev-process skills currently living under `skill-src/` in this OpenClaw workspace into the `agentic-dev-kit` repository as first-class, portable skills. Refactor their path resolution so they work in both contexts:

1) running inside the `agentic-dev-kit` repo itself, and
2) running from a host repository that vendors `agentic-dev-kit` at `vendor/agent-dev-kit/`.

## Goals

- Make the workflow skills (spec/ADR/CP generators; review scaffolds; instruction lint/router) part of the canonical `agentic-dev-kit` distribution.
- Preserve the stable filesystem contract from ADR-0001/ADR-0002 (`vendor/agent-dev-kit/skills/{name}/...`) for consumers.
- Ensure helper scripts can run in both contexts (inside agentic-dev-kit, or from a host repo with agentic-dev-kit vendored).
- Provide a canonical `skills/index.md` in agentic-dev-kit that documents and routes to the skills.

## Non-Goals

- Publishing these as OpenClaw marketplace skills (this is about agentic-dev-kit content, not ClawHub release).
- Adding networked functionality, API calls, or provider integrations.
- Changing the agentic-dev-kit role contract or universal gates.
- Implementing auto-approval or automation around the FS → CP → ARC42 workflow.

## Users / Stakeholders

- Maintainers of `agentic-dev-kit` (need canonical, portable workflow tooling).
- Contributors (need consistent generators and review scaffolds).
- Consumers who vendor agentic-dev-kit as a submodule (need stable paths).

## Interfaces

### Filesystem (stable paths)

- New canonical location for the moved skills:
  - `skills/{skill-name}/SKILL.md`
  - `skills/{skill-name}/*.py` (helper scripts; optional per skill)
- Canonical skills index:
  - `skills/index.md`

### CLI

Each Python helper script MUST be runnable via `python3` and support `--self-test`.

## Success Criteria

1. Skill content relocation

   - Given a checkout of the `agentic-dev-kit` repo, when listing `skills/`, then the workflow skills (adrgen/specgen/changeplangen/stubgen/instructionlint/skillindex/prreview/specreview/testreview/newskill) exist as directories under `skills/` with a `SKILL.md` in each.

2. Dual-mode template path resolution

   - Given running a generator script from within the `agentic-dev-kit` repo (no `vendor/agent-dev-kit` parent), when executing its `--self-test`, then it succeeds and reads templates from `./templates/...`.
   - Given running the same generator script from a host repo that contains `vendor/agent-dev-kit/`, when executing its `--self-test`, then it succeeds and reads templates from `./vendor/agent-dev-kit/templates/...`.

3. Canonical skills index

   - Given a fresh checkout of `agentic-dev-kit`, when opening `skills/index.md`, then it lists each moved skill with: purpose, location, and the primary invocation (script + key flags).

4. Backward compatibility guidance

   - Given a consumer repo that previously referenced skills at `vendor/agent-dev-kit/skills/{skill-name}/...`, when reading `INTEGRATION.md` (or an equivalent doc chosen during implementation), then there is a section describing the new canonical paths and how to invoke the helper scripts in both contexts.

5. Local validation

   - Given Node/npm is not installed, when running the Python helpers' `--self-test` commands, then all self-tests still work (Python-only).

## Edge Cases

- Repo roots where both `./templates/` and `./vendor/agent-dev-kit/templates/` exist (the script MUST choose the correct one based on whether it is running inside agentic-dev-kit or in a host repo).
- Running scripts from a deep working directory (path discovery should be robust, not cwd-sensitive).

## Out of Scope

- Adding CI to run these Python scripts.
- Converting the Python helpers into an installable package.
- Migrating or changing OpenClaw runtime `skills/` layout conventions outside of agentic-dev-kit.

## Dependencies

- ADR-0001 / ADR-0002: skills are portable markdown modules with a skills index.

## Rollout / Migration

- Phase 1: Land the skills + index + dual-mode pathing in agentic-dev-kit.
- Phase 2: Update downstream repos/workspaces to point to the canonical `vendor/agent-dev-kit/skills/...` paths as needed.

## Observability

- Logs: stdout from `--self-test`.

## Security / Privacy

- Data handled: local filesystem only.
- Mitigations: no network access; refuse to overwrite files unless `--force` is provided (where applicable).

## Open Questions

None.
