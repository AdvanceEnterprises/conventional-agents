---
type: feature-spec
id: FS-0038
status: draft
title: Hermes kanban substrate binding for work item lifecycle
owner: ajoeofalltrades
test_required: true
interfaces:
  - "docs/proposals/hermes-kanban-substrate-binding.md"
  - "integrations/hermes-kanban.md"
  - "integrations/README.md"
  - "workflows/session-modes.md"
  - "workflows/document-lifecycle.md"
  - "guidelines/ROLE_CONTRACT.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "test/FS-0038/hermes-kanban-binding.bats"
related_adrs:
  - ADR-0012
  - ADR-0018
  - ADR-0019
  - ADR-0020
  - ADR-0021
  - ADR-0024
  - ADR-0028
  - ADR-0039
supersedes: []
requires:
  - FS-0018
tags: [workflow, substrate-binding, hermes, kanban, runtime]
created: 2026-09-23
updated: 2026-09-23
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

# Feature Spec: Hermes Kanban Substrate Binding for Work Item Lifecycle

## Status

- Draft

## Plan Status

- **PLAN-0044 is `draft`.** It is drafted alongside this spec, which
  `workflows/document-lifecycle.md` permits. It cannot self-approve because
  it touches the exported surface (`integrations/`); approval is a human act.

## Summary

Investigate a second substrate binding under `ADR-0024`, mapping the six core
workflow capabilities onto the Hermes Agent `kanban` subsystem. Hermes kanban is a
durable, SQLite-backed task board designed for multi-profile agent collaboration.
The incomplete mapping lives in `docs/proposals/hermes-kanban-substrate-binding.md`,
outside the shipped binding surface until conformance is demonstrated.

The binding is substrate mechanics only. Governance rules (Type mutability,
autonomous gate, merge prohibition) remain in `FS-0018`, `ADR-0019`,
`ADR-0020`, `ADR-0021`, and `ADR-0012`. Where a capability is enforceable on
Hermes kanban, the binding says so. Where it is only attributable, it says that
explicitly and names the detection mechanism.

## Goals

- Identify the proof obligations before shipping a complete binding mapping
  all six `ADR-0024` capabilities onto Hermes kanban.
- Define how Type, Phase, Parked state, Activity record, and Enumerability are
  represented in a Hermes kanban board.
- Preserve the substrate-neutrality principle: a project using Hermes kanban has
  a single-source-of-truth work tracker and does not need GitHub.
- Distinguish native claims from governance enforcement; no project hook or
  immutable Type field is supplied by this binding.
- Provide a reference for extracting or validating the platform-neutral core.
- Add hermetic bats probes using an isolated Hermes home; the static binding
  checks run even where the Hermes executable is unavailable.

## Non-Goals

- Implementing a sync or bridge between Hermes kanban and GitHub. That is a
  separate portfolio/reporting concern, not a binding.
- Changing `FS-0018` or the six core capabilities. The binding must map what
  already exists.
- Defining how to host a Hermes kanban board for a team. The binding assumes a
  local or profile-scoped board; multi-tenant hosting is out of scope.
- Mandating Hermes kanban for the framework's own evolution. The framework
  dogfoods the binding as an option, not a requirement.

## Users / Stakeholders

- **Hermes Agent users** who want governed work items without GitHub.
- **Framework maintainers** validating whether the six capabilities are
  genuinely portable across substrates.
- **Future binding authors** who need a second example to generalize from.

## Interfaces

- `hermes kanban` CLI verbs: `init`, `boards create`, `create`, `list`, `show`, `assign`, `link`,
  `comment`, `complete`, `block`, `unblock`, `promote`, `claim`, `heartbeat`,
  `dispatch`, `tail`, `runs`.
- Worker toolset (when spawned by dispatcher): `kanban_show`, `kanban_complete`,
  `kanban_block`, `kanban_heartbeat`, `kanban_comment`, `kanban_create`,
  `kanban_link`.
- SQLite schema surfaced by `hermes kanban`: board, task, task_event, task_link,
  task_attachment, task_run tables.
- Internal proposal: `docs/proposals/hermes-kanban-substrate-binding.md`.
- Future binding, **not yet shipped**: `integrations/hermes-kanban.md`.

## Binding Overview

| # | Core capability | Hermes mechanism | Enforcement |
| --- | --- | --- | --- |
| 1 | Work item | `hermes kanban create` task | Native |
| 2 | Type | `[feature]`, `[bug]`, `[task]` title prefix | **Convention; audit required** |
| 3 | Phase | Task status (`triage`, `todo`, `ready`, `running`, `review`, `done`, `archived`) | Native transitions; claim is atomic |
| 4 | Parked state | `blocked` with `needs_input` reason | Native status; agent suppression by convention |
| 5 | Activity record | Kanban events and comments | **Partial** — verify actor attribution and transition retention |
| 6 | Enumerability | `hermes kanban list` / `show` / SQLite read + reconciler | Native |

## Capability Details

### 1. Work item → Hermes kanban task

A task is the work item. It exists before any FS, PLAN, or ADR.

- **Identity:** board-scoped task ID (for example `t_4e3edff7`) plus the board slug.
- **Brief:** the task title and body.
- **Creation:** `hermes kanban --board <slug> create "[task] ..." --body "..."`.
- **Linkage to governed documents:** governed documents reference the task by
  board slug + task ID in their front matter or body. The task references
  documents by URL or path in comments.

### 2. Type → title-prefix convention

Hermes kanban does not expose a built-in Type field. This binding uses a
convention, not a native single-select field:

- **Options:** `feature`, `bug`, `task`
- **Storage:** one bracketed prefix in the task title. Missing or multiple
  prefixes are invalid; the agent parks the task rather than guessing its gate.
- **Authority:** a human establishes Type. Agents must not alter it; title edits
  through a future CLI or direct SQLite access require an attributable audit.
  A Git pre-commit hook cannot protect a SQLite mutation. No such audit or
  pre-mutation validator ships in this PR, so Type conformance remains **unproven**.

### 3. Phase → task column

Hermes kanban columns map directly to the framework phase axis:

| Framework phase | Hermes column | Meaning |
| --- | --- | --- |
| Backlog | `triage` / `todo` | Triaged or queued, not started |
| Approved | `ready` plus recorded human authorization | Available to claim; `create` defaults to `ready`, so status alone is insufficient |
| In Progress | `running` | Atomically claimed by a profile/worker |
| In Review | `review` | Awaiting review; whether Git review is linked is separate |
| Done | `done` | Completed |

`archived` is a terminal cleanup state, not a phase value.

The `running` status is the most important mapping: Hermes kanban supports
atomic claim (`hermes kanban claim`), which gives the framework an enforceable
"In Progress" transition that GitHub cannot provide. Atomic claim does **not**
by itself prove that a human authorized the `ready` transition.

### 4. Parked state → `blocked` with human-input reason

Hermes kanban has native parked states:

- `blocked` with `needs_input` — awaiting a human decision; suppresses agent
  work until the human clears it. Other block kinds need their own policy.
- `scheduled` is a timed wait, **not** the `question` parked state: a timer
  may release it without human input.

While a task has a human-input block, the autonomous gate suppresses agent work.

### 5. Activity record → `task_event` + comments

The activity record is split across two mechanisms:

- **State transitions** (status moves, claims, completions) are exposed in
  the task event history; verify actor attribution and retention before claiming
  that every transition is non-retractable.
- **Agent commentary** is stored as comments via `hermes kanban comment` and is
  also append-only in the SQLite event stream.

Do not infer that every event records the active Hermes profile: a CLI caller
can supply `--created-by`, and direct database edits bypass CLI attribution.
Agent stance entries SHOULD be
posted as comments in the documented `FS-0018` format before any transition.

### 6. Enumerability → SQLite + CLI

A reconciler can read the whole board with:

```bash
hermes kanban --board <slug> list --json --archived
hermes kanban --board <slug> show <task-id> --json
```

The CLI provides on-demand enumeration (`ADR-0028`); direct SQLite access is
not part of the stable binding contract.

## Success Criteria

- Given an isolated Hermes home and a board created with `hermes kanban
  boards create`, when a prefixed task is created, then `list --json` and
  `show --json` expose its title and current status without touching a real board.
- Given a task in `ready`, when `hermes kanban claim` is invoked, then its
  status becomes `running`; a second claim must not succeed.
- Given a `running` task with no heartbeat within the configured timeout, when
  the dispatcher reclaims it, then the task returns to `ready` and a `reclaim`
  event is appended to the activity record.
- Given a task with a `needs_input` block, the binding requires agents to stop;
  automated suppression is not claimed until a dispatcher-level gate is tested.
- Given a task without a valid Type prefix, the binding treats it as invalid
  rather than silently assigning a lower-safety Type.
- Given the internal proposal at `docs/proposals/hermes-kanban-substrate-binding.md`,
  when `npm run lint:docs` runs, then the document passes markdown lint;
  `integrations/hermes-kanban.md` remains absent until all six capabilities
  have been demonstrated.

## Edge Cases

- A task may be linked to a GitHub Issue for human visibility; the binding does
  not require the link, but documents how to record it in the task body.
- A worker process crash leaves a task `running`; the dispatcher reclaim timeout
  is the recovery path.
- Type mutation attribution needs a tested mechanism before this binding can
  claim complete conformance with capability 2.
- `create` defaults to `ready` without human approval; a profile must not
  treat this as authorization to work. Prove a gate on the authorization record.
- `gc` and direct database modification may affect event retention. Establish
  what is non-retractable under the documented threat model.

## Out of Scope

- Syncing Hermes kanban state to GitHub Issues or Projects.
- Hosting or sharing a kanban board across multiple human users.
- Defining new Hermes CLI verbs or changing the kanban SQLite schema.
- Runtime configuration of Hermes itself (that belongs to the Hermes runtime
  binding under `ADR-0039`).

## Dependencies

- `FS-0018` — work item lifecycle and three-axis classification.
- `ADR-0024` — platform-neutral core with shipped bindings.
- `ADR-0028` — level-triggered reconciliation (enumerability over events).
- `ADR-0039` — runtime bindings; Hermes kanban is the work-tracking substrate
  a Hermes runtime binding would point at.

## Rollout / Migration

- Keep the incomplete candidate in `docs/proposals/`; only publish a conforming
  `integrations/hermes-kanban.md` and index it after proof of all six capabilities.
- Add `test/FS-0038/hermes-kanban-binding.bats` with static + isolated CLI probes.
- Update `docs/specifications/README.md` and `docs/change-plans/README.md`.
- Do not change the framework's default substrate. GitHub remains the substrate
  this repository runs on until explicitly migrated.

## Observability

- `hermes kanban stats --board <slug>` shows per-column counts.
- `hermes kanban diag --board <slug>` lists active diagnostics.
- `hermes kanban watch` streams task events live.

## Security / Privacy

- Kanban SQLite files live in the Hermes home directory (`~/.hermes/` or the
  active profile). Board access follows filesystem permissions.
- No Type-enforcement hook is supplied by the candidate. Any future hook needs
  a verified identity and mutation boundary before it can claim enforcement.

## Open Questions

- Should the binding define a `human_required` field equivalent to the GitHub
  Projects `Human Required Action` field, or is the native `blocked` column
  sufficient?
- Should a project using Hermes kanban mirror any state to git-committed files
  (e.g., `config/project.yml`) for human visibility without Hermes installed?
