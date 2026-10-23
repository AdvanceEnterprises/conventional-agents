---
type: feature-spec
id: FS-XXXX
status: draft
title: `title`
owner: `owner`
test_required: true
interfaces: []
related_adrs: []
supersedes: []
requires: []
# consensus_required: true    # optional per-document override for FS-0019 (off by default)
tags: []
created: `YYYY-MM-DD`
updated: `YYYY-MM-DD`
---
<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- `interfaces:` bounds which change plans may self-approve (ADR-0027) — draw
  it narrowly; a loose `interfaces:` widens agent authority.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->
# Feature Spec: `title`

## Status

- Draft | Approved | Implemented | Deprecated

## Summary

One paragraph describing what this feature does and why it exists.

## Goals

- `goal`

## Non-Goals

- `non-goal`

## Users / Stakeholders

- `who is this for`

## Interfaces

Describe the public or semi-public surface area this feature touches.

- Type: CLI | API | Library | Config | UI | Infra
- Details: `flags/endpoints/signatures/settings`

## Success Criteria

Each bullet MUST be objectively testable.
Use a consistent structure so tests can be generated.

- Given `precondition`, when `action`, then `observable result`
- Given `precondition`, when `action`, then `observable result`

## Edge Cases

- `edge case`

## Out of Scope

- `explicit exclusion`

## Dependencies

- `dependency`

## Rollout / Migration (if applicable)

- `steps`

## Observability (if applicable)

- Logs:
- Metrics:
- Traces:

## Security / Privacy (if applicable)

- Data handled:
- Threats considered:
- Mitigations:

## Open Questions

Only include questions that block implementation.

- `question`
