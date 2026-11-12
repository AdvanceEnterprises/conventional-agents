---
type: feature-spec
id: FS-0036
status: draft
title: Planning-field conventions for the GitHub binding — Priority, Iteration, Milestone semantics and read-only flow checks
owner: ajoeofalltrades
test_required: true
interfaces:
  - "docs/decisions/ADR-0043-planning-fields-are-binding-policy.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0024, ADR-0026, ADR-0030, ADR-0035, ADR-0042, ADR-0043]
supersedes: []
requires: []
tags: [github, projects, planning, priority, iteration, milestone, flow, binding, governance]
created: 2026-09-16
updated: 2026-10-27
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

# Feature Spec: Planning-field conventions for the GitHub binding

> **Normative language:** `MUST`, `MUST NOT`, `SHALL`, `SHOULD`, and
> `MAY` are used per RFC 2119. Where the body uses sentence-case normative
> phrasing instead (e.g. "the binding defines", "items are untouched"),
> it states the same requirement in prose form for readability; the
> all-caps forms in SC-2/SC-5 are the authoritative statement of those
> requirements. A future lint pass may normalize the remainder.

## Summary

The GitHub Projects v2 binding (`integrations/github-issues-projects.md`,
`integrations/github/`) gains a bounded planning contract for the three
planning fields the framework recognizes — native issue `Milestone`,
project `Priority` (single-select), and project `Iteration` — plus a
**read-only flow report** of planning-field drift. The contract is ratified
by the proposed `ADR-0043`: if accepted, planning fields would be **binding
policy, not framework state**; the GitHub binding conventions below are written
against that proposal and remain provisional until `ADR-0043` is accepted.
agents may recommend and (under an explicit scheduling contract) assign
iterations and backfill UNSET priorities, but the human remains the arbiter
of Milestone and Priority, and no planning field is a lifecycle axis.

## Goals

- Define field semantics for `Priority`, `Iteration`, and `Milestone` in
  binding terms, including the substrate limitation that Milestone is
  repository-native (a cross-repository project cannot uniformly milestone
  all its items).
- Make planning authority explicit and machine-checkable via the audit
  layer: humans create/assign Milestones and arbitrate Priority; agents may
  backfill UNSET Priority from a documented evidence-based mapping, assign
  iterations only under the scheduling contract (whose pull-forward cap and
  ordering are consumer policy, defaulting to 3-with-priority-first), and
  never create/assign/close Milestones.
- Provide a read-only flow report (the `github:board-audit` extension)
  that reports unranked ready work, invalid current-Iteration assignments,
  protected-field changes by agents, missing P0/P1 rationale, and repeated
  rollovers — without mutating any field.
- Keep the framework's own tick-visible conventions substrate-neutral where
  possible (`ADR-0024`, the proposed `ADR-0035`), with the GitHub binding as the
  reference implementation.

## Non-Goals

- A scheduler, planner, or automatic portfolio manager. Replenishment
  cadence, WIP limits, priority *meanings*, and rollover *policy* are
  consumer choices, not framework rules.
- Permission-level prevention of agent field edits (GitHub Projects v2 has
  no per-field ACL — see `ADR-0043`).
- Making `Milestone` a Project custom field or a lifecycle axis.
- Changing `FS-0018`'s three-axis schema (Type/Phase/Parked state).

## Success Criteria

### SC-1: Field semantics and substrate limitations

The binding README documents, for each planning field:

- `Priority` — a Project single-select field (framework option set
  `Urgent / High / Medium / Low`, mapped from consumer P0–P3), used for
  ranking, explicitly not a lifecycle phase.
- `Iteration` — a Project iteration field (repeating time windows), used
  for near-term focus and capacity intent, explicitly not a delivery
  promise.
- `Milestone` — repository-native issue metadata, the enduring outcome to
  which work contributes; explicitly not a release or a planning window.
- The cross-repository limitation: a project board spanning repositories
  cannot assign one Milestone to items in multiple repositories.

### SC-2: Authority matrix and evidence requirement

The binding documents the three write authorities (human primary; agent
read/recommend; the three sanctioned agent writes) matching `ADR-0043`
Decision 2, and requires that every sanctioned agent write:

- is idempotent (repeat application produces the same state),
- is attributable (git/CLI identity + `Agent-Attribution` trailer or
  machine-readable comment), and
- is logged in the actor's digest/record so a reader can trace the write.

Agent writes to non-sanctioned planning state (e.g. changing a set
Priority, assigning a Milestone) are prohibited and must be reported by
the audit layer as protected-field changes.

### SC-3: UNSET-Priority backfill mapping

The binding ships a suggested, documented mapping used ONLY when the field
is UNSET (never overriding a set value):

- `bug` label → Urgent
- open PR or linked-PR issue, or `spec` label → High
- `enhancement` / `feature` → Medium
- otherwise → Low
- `question` label → leave unset

The mapping is advisory by default; a consumer may pin a different mapping
in instance metadata, and any use is subject to SC-2 (attribution + log).

### SC-4: Iteration scheduling contract

The binding defines the iteration scheduling contract the tick implements:

- ACTIVE iteration = the one whose `startDate..startDate+duration` contains
  today (UTC), computed from field configuration, never assumed from a
  title.
- CLOSED/Done items: iteration cleared (roadmap shows open work only).
- New/unset OPEN items: active iteration goes only to in-flight or
  immediate work (open PRs, `bug`-labeled issues, items with linked PRs,
  Status In Progress/Approved, HRA=Awaiting Merge). Future work: High →
  next iteration, Medium → the one after, Low → UNSCHEDULED; `question`
  and Awaiting-Decision items are parked (no iteration, never
  auto-advanced).
- Calendar roll-forward: when today advances into a new active iteration,
  OPEN items still in an expired iteration re-home to the active one.
- Pull-forward on completion: when the ACTIVE iteration holds zero open
  non-human-blocked items, the binding MAY promote unfinished items from
  the NEXT defined iteration (highest priority first, skip human-blocked)
  into the ACTIVE iteration, same day, logged per promotion. The concrete
  cap ("up to 3") and the ordering are **consumer policy defaulting to
  3-with-priority-first**, not core framework policy (proposed `ADR-0043` Decision 1:
  cadence and replenishment policy belongs to the consumer or a higher-level
  convention); the binding ships the *mechanism* only — an item may be
  re-homed across iterations, and every promotion is attributable + logged
  per SC-2.
- If today is outside ALL defined iterations, items are untouched and the
  operator is warned ("iteration config exhausted — extend in the board
  UI"; iteration CRUD is UI-only, no API).

### SC-5: Read-only flow report

`bin/gh-board-audit.sh` gains a `--flow` mode emitting a read-only report
of planning-field health. The report NEVER mutates fields, MUST exit 0 on
findings unless `--strict` is passed, and MUST report at minimum:

- unranked ready work: open items with Status In Progress/Approved/In
  Review and UNSET Priority;
- invalid current-Iteration assignments: items in a non-active, non-next,
  non-pulled-forward iteration;
- protected-field changes: planning fields set by an agent author
  (attribution-stamped) outside the SC-2 exceptions;
- missing P0/P1 (Urgent/High) rationale: Urgent/High items lacking a
  linked evidence reference or rationale comment;
- repeated rollovers: items moved across iterations more than twice in the
  report window without human evidence.

Machine-readable JSON output accompanies the human-readable report for the
same findings.

### SC-6: Tests

The plan implementing this spec adds bats coverage (pattern: `test/FS-0029`
template/registration tests and `test/FS-0016` vendor-boundary tests) for:

- the authority-matrix rules (recommend-only outside the exceptions),
- the UNSET-only backfill mapping,
- the iteration scheduling contract's active-iteration computation and
  roll-forward/pull-forward behavior,
- `--flow` read-only guarantees (no mutation; exit codes),
- the cross-repository Milestone limitation (README content, not live API).

## Out of Scope (explicit)

- Any live mutation of planning fields by the framework's own CI or gates.
- A generic scheduler; per-consumer planning policy (cadence, WIP limits,
  priority meanings, replenishment, rollover rules) stays out of the
  framework core.
- Moving `Milestone`, `Priority`, or `Iteration` into `FS-0018` lifecycle
  scope.

## Interfaces

- `docs/decisions/ADR-0043-planning-fields-are-binding-policy.md` (proposed) — the
  architecture decision this spec depends on once accepted (authority matrix,
  mechanism-vs-policy boundary). Until acceptance the conventions below are
  provisional.
- `docs/specifications/README.md`, `docs/change-plans/README.md` — index
  rows for this spec and its plan.
- `CHANGELOG.md` — consumer-facing entry for the draft contract.

## Plan Status

- Drafting the PLAN alongside this spec is not a departure:
  `workflows/document-lifecycle.md` places PLAN *creation* at "initial
  creation" and constrains only PLAN *approval* to come after the governing
  FS has been reviewed. The PLAN (PLAN-0042) is `draft`.
- Implementation (binding README updates, `--flow` mode, bats tests) is
  blocked until this spec reaches `status: approved` (PARSING_HINTS: "Do
  NOT implement unless status == approved").
