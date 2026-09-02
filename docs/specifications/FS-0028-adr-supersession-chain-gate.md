---
type: feature-spec
id: FS-0028
status: draft
title: ADR supersession chain gate — machine-check superseded_by completeness
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-status.sh"
  - "scripts/README.md"
  - "docs/decisions/README.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "test/FS-0028/adr-supersession-chain.bats"
related_adrs: []
supersedes: []
requires: []
tags: [governance, gates, adr, lifecycle]
created: 2026-09-01
updated: 2026-09-01
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

# Feature Spec: ADR Supersession Chain Gate

## Plan Status

- **PLAN-0028 is `draft`.** It will not advance past approval without a human
  decision (ADR-0019 Type checkpoint: `feature` may not advance past
  `Approved` autonomously).

## Summary

Every ADR in this repository carries a `superseded_by:` front-matter field
(template default `null`), and `docs/decisions/README.md` §5 defines the
supersede process: an ADR is marked `status: superseded` and points at its
replacement; the replacement links back in its Links section. Nothing
machine-checks the field. A superseded ADR with `superseded_by: null`, a
dangling replacement id, or a replacement declared by an accepted ADR all pass
`npm run check:status` silently — an unchecked surface of exactly the kind
FS-0022 exists to close ("an unchecked surface should be a visible gap, not a
silent one").

This spec makes the supersession chain machine-checked.

## Goals

- A gate in `scripts/check-status.sh` (rule 5b) that is silent when the chain
  is complete and fails loudly, naming the ADR, when it is not.
- Three obligations, all enforced:
  1. An ADR at `status: superseded` must name at least one replacement in
     `superseded_by:`.
  2. Every non-null `superseded_by` id must resolve to an existing ADR file
     (matched by front-matter `id:`).
  3. A non-null `superseded_by` on an ADR whose status is not `superseded` is
     flagged — the field means "this ADR is replaced by…", which only a
     superseded ADR may claim per README §5.
- The gate lands with zero backlog: the current corpus is 37/37
  `superseded_by: null` with no supersessions, so it goes green immediately.

## Non-Goals

- **Enforcing the replacement's back-link.** README §5 asks the replacement
  ADR to link back in its Links section; the link lives in prose, not
  front matter, and is a review judgment — this gate covers the front-matter
  chain only.
- **Deprecation enforcement.** `status: deprecated` ADRs are not required to
  name a replacement (deprecation is for decisions that are simply no longer
  relevant).
- **Automated supersession.** The gate reports; it does not edit ADRs.
- **Applying the gate to FS/PLAN documents.** FS files carry their own
  `supersedes:`/`superseded_by:` vocabulary with different semantics and are
  out of scope.

## Users / Stakeholders

- Contributors maintaining the ADR log.
- The `conventional-agents-maintenance` tick, whose proactive check #3
  (ADR chain completeness) has been a standing gap with no owner.
- Consumers who vendor this framework and adopt the gate for their own ADR
  logs.

## Interfaces

- `scripts/check-status.sh` — new rule 5b (Category 1 gate per ADR-0015).
  Follows the script's existing conventions: resolves its target from the
  caller's working directory per FS-0024/ADR-0033 (`git rev-parse
  --show-toplevel`, optional `CA_TARGET_REPO` override), Bash 3.2-compatible,
  `errors=$((errors+1))` on violation.
- `scripts/README.md` — documents rule 5b.
- `docs/decisions/README.md` — §5 notes the machine check.
- `test/FS-0028/adr-supersession-chain.bats` — bats coverage.
- `docs/specifications/README.md`, `docs/change-plans/README.md` — register
  FS-0028/PLAN-0028 in the indexes.

## Success Criteria

1. Given an ADR at `status: superseded` whose `superseded_by:` is `null` or
   absent, when `npm run check:status` runs, it exits non-zero naming the ADR.
2. Given a non-null `superseded_by:` naming an id that resolves to no ADR file
   (by front-matter `id:`), when the check runs, it exits non-zero naming the
   ADR and the dangling id.
3. Given a non-null `superseded_by:` on an ADR whose status is not
   `superseded`, when the check runs, it exits non-zero naming the ADR.
4. Given a `superseded_by:` in any supported field shape (single inline id,
   inline list `[ADR-00XX, ADR-00YY]`, YAML block list), when the field is
   well-formed and the ids resolve, the check reports no supersession error
   for that ADR.
5. The current corpus passes: 37/37 ADRs carry `superseded_by: null` and the
   check reports no supersession errors on a clean tree.
6. Rule 5b is documented in `scripts/README.md` and `docs/decisions/README.md`
   §5, and covered by the bats suite.

## Out of Scope

- Back-link enforcement (see Non-Goals).
- Deprecation semantics.
- Applying the gate to FS/PLAN documents.
