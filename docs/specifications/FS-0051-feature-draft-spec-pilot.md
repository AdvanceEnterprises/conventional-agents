---
type: feature-spec
id: FS-0051
status: draft
title: First pilot — an authorized feature draft-spec produces one canonical draft FS PR
owner: ajoeofalltrades
test_required: true
interfaces:
  - "src/collective_agents/"
  - "tests/"
  - "pyproject.toml"
  - "config/instance.example.yml"
  - "grants/"
  - ".github/workflows/engine-tests.yml"
  - "package.json"
  - "README.md"
  - "docs/ARC42.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
related_adrs:
  - ADR-0047
  - ADR-0048
supersedes: []
requires: []
tags: [pilot, dispatch, publication, governance, isolation]
created: 2026-09-29
updated: 2026-10-01
---
<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Nothing in this spec is implemented.
-->
# Feature Spec: First pilot — an authorized feature draft-spec produces one canonical draft FS PR

## Status

- Draft
- Imported from collective-agents (where this was `approved`). The engine
  implementation is **deferred** per ADR-0046: it will be re-extracted as its own
  package when built, not inside conventional-agents. The `interfaces:` below
  describe that future engine, not this repository.
- Amended 2026-10-01 in PR #15: the interface surface is declared (§Interfaces),
  replacing the earlier deliberate empty declaration; stale references to
  pre-merge state were corrected at the same time. The `## Success Criteria`
  are unchanged.

## Summary

The first end-to-end slice of the collective-agents engine: on a scheduled or
on-demand pass, evaluate governed work items against the pinned
conventional-agents contract, and for one work item carrying an explicit human
grant for the bounded `draft-spec` action, dispatch an isolated worker, validate
the evidence it returns, and publish **one** canonical draft FS PR for human
review. The work item's Phase does not advance. Nothing merges automatically.

This spec exists to make the pilot's observable behavior testable. The
architecture that motivates it is in [`docs/ARC42.md`](../ARC42.md) (merged; the
earlier draft PR #2 was the vehicle for its review); the decisions it depends on
are `ADR-0047` (intent identity and the human grant) and `ADR-0048`
(worker/publisher separation).

## Goals

- Prove the reconciliation loop end to end on one narrow, governable action.
- Make authority explicit: a human grant, not inferred from Type or Phase.
- Prove that a retry converges on one proposal instead of creating a second.
- Prove the worker has no usable GitHub write credential.
- Prove no automated actor can cross a human gate.

## Non-Goals

- Not an implementation path. No engine code exists, and none is authorized by
  this spec until its `PLAN` is approved.
- Not a `task` flow. Type-specific task semantics and the In-Review
  criterion are out of scope and are not redefined here.
- Not a second substrate or a second runtime. GitHub work items and Hermes
  execution are the first implementations, not universal requirements.
- Not a promise of exactly-once external writes. See `ADR-0047`.

## Users / Stakeholders

- **Human approver:** grants the action, reviews the draft FS PR, merges or
  rejects.
- **Instance operator:** configures the repository, the substrate, the runtime,
  schedules, budgets, and credentials; sees why a pass stopped.
- **Agent worker:** receives a bounded drafting task and returns evidence.
- **Publisher:** the only automated writer; cannot merge.

## Interfaces

Declared by the 2026-10-01 amendment; the earlier revision deliberately declared
none. The surface is the pilot's implementation footprint: the engine package,
its test suite, its integration points, and the artifacts it reads or syncs. A
plan implementing this spec may touch these paths. Whether it may *self-approve*
is decided by the framework's reserved-path rule (`ADR-0027`), not by this list.

- Type: library + CLI (Python 3.11+; `pytest` for the test suite)
- Details:

  - `src/collective_agents/` — the engine package: reconciler pass, authority
    and grant resolution, intent ledger, dispatcher, evidence validator,
    publisher, work-item and runtime adapters, instance-config loader, CLI.
  - `tests/` — the pytest suite generated from `## Success Criteria`, with the
    module metadata the framework's Python testing guide requires.
  - `pyproject.toml` — packaging and pytest configuration; `pytest` as a dev
    dependency.
  - `config/instance.example.yml` — documented example instance configuration.
    A live instance file is not committed.
  - `grants/` — human-authored grant records (the durable form of the human
    grant in `ADR-0047`). Written only by human commits; the engine reads and
    verifies them, and never writes them.
  - `.github/workflows/engine-tests.yml` — CI running the test suite.
  - `package.json` — npm `test` entry invoking the pytest suite, matching this
    repository's existing npm-based gate entry points.
  - `README.md` and `docs/ARC42.md` — status and architecture updates when the
    pilot lands; both currently describe the pre-implementation state.
  - `docs/specifications/README.md` and `docs/change-plans/README.md` — index
    status syncs that the framework's gates require.

**Approval consequence.** This surface includes reserved paths
(`.github/workflows/`, `package.json`) under this repository's `config/gates.yml`,
so a `PLAN` implementing the pilot cannot self-approve: it must carry
`approved_by:` evidence corroborated by an `Approved-By:` trailer
(`ADR-0026`/`ADR-0027`). That is intended. The surface of a product whose engine
does not exist should not be pre-approved by the same agents that will build it,
and the first engine `PLAN` is therefore human-approved by construction.

Note: `config/gates.yml` remains in this repository's `reserved_paths`, so any
plan touching that file requires human approval regardless of this list.

## Success Criteria

Each bullet is objectively testable.

- Given a `feature` work item at Phase `Approved` with no valid grant, when a pass
  evaluates it, then no worker is dispatched and the pass records why.
- Given a work item whose Type is unset, when a pass evaluates it, then it is
  treated at the most restrictive setting and nothing is dispatched.
- Given a grant naming the work item, the action `draft-spec`, and an explicit
  scope generation, when a pass evaluates it, then exactly one intent is reserved
  before any dispatch-related external write or worker invocation.
- Given two passes evaluating the same authorized intent, when both complete, then
  they converge on the same intent and exactly one reservation exists.
- Given a repeated attempt under an existing intent, when it publishes, then no
  second canonical draft PR is created for that intent.
- Given an edit to the work item's description or an agent comment, when the next
  pass runs, then no new authorization generation is created.
- Given a completed worker run, then the returned evidence contains the patch, the
  changed paths, the base revision, the model and provider actually used, and
  check results attributed to the exact proposed tree.
- Given the worker's effective environment, when a probe enumerates its
  environment variables, mounted files, Git credential helpers, `gh` CLI
  authentication state, and any SSH keys the runtime configuration exposes, then
  no configured GitHub write credential (token, SSH key, or helper-resolved
  credential with write scope) is found.
- Given a publisher about to write, when the grant has been revoked or the work
  item's state has changed since dispatch, then publication is held and the reason
  is recorded on the work item.
- Given the intent reserved but the dispatch acknowledgement lost, when the pass
  continues, then it holds for runtime discovery rather than launching a second
  run.
- Given a PR-creation call whose outcome is unknown, when the pass continues, then
  no second create is attempted before discovery; unresolved ambiguity is reported
  for human inspection.
- Given a completed publication, then the created PR is a **draft** whose head and
  base and proposed tree are read back and recorded, and it is linked to the work
  item without a closing keyword.
- Given the pilot completes, then the work item's Phase remains `Approved` and the
  FS it proposed remains `draft`.
- Given a grant whose scope generation is older than the work item's current
  scope, or an external write whose outcome is unknown, when the pass halts, then
  it posts an `agent-stance` entry explaining the halt and then applies the
  `question` label to the work item.
- Given a rate limit, crash, or exhausted retry budget, then that is recorded as an
  operational hold, and `question` is **not** applied unless a specific human
  decision is needed.
- Given any automated actor in the pilot, when it acts, then it performs no merge,
  no approval, and no ready-for-review transition.

## Edge Cases

- A grant that resolves but whose scope generation is older than the work item's
  current scope: treated as ambiguous, held for human review.
- Two reconciler passes interleaving on one intent: the reservation must serialize
  them; the test asserts one reservation, not one process.
- A publication that succeeded remotely but whose acknowledgement was lost: the
  next pass must discover it rather than create a second PR.
- A search for existing publications that is itself incomplete: absence of a match
  is not proof of absence, and is not permission to create.
- A worker that returns a patch touching paths outside the granted scope: rejected
  by the publisher, recorded, and not published.
- A fallback model substituted at runtime: recorded as the actual model, and any
  independence claim depending on the selected model fails.

## Out of Scope

- Autonomous Phase advancement of any kind.
- The `task` implementation path and its Phase semantics.
- Hermes kanban as a work-item substrate: its candidate is under the framework's
  proposals directory, not the shipped integrations surface.
- Portfolio/instance-repository tooling. A local instance configuration file is
  sufficient for this pilot.
- Any claim of exactly-once external publication.

## Dependencies

- `FS-0018` (work-item schema, origination paths, autonomous gate),
  `ADR-0014` (background-task governance and the activity record), `ADR-0019`
  (Type-keyed gate), `ADR-0020` (suppression while the work-item `question`
  label is set), `ADR-0026` (approval records), `ADR-0028` (level-triggered
  reconciliation), `ADR-0012` (no agent merges).
- Local `ADR-0047` and `ADR-0048`.
- A work-item substrate binding and an agent-runtime adapter. The framework's
  GitHub binding is the first work-item substrate; its limitations are documented
  there and must not be presented as enforcement.
- **Unverified until probed:** the runtime's invocation and lookup behavior, and
  the Git host's behavior for discovering a possibly-created remote publication.
  The pilot's design does not assert these; the `PLAN` must establish them.

## Rollout / Migration

Not applicable for the pilot beyond a single deployed instance. There is nothing
to migrate: no prior engine exists.

## Observability

- Logs: per-pass enumeration results, the stop decision and its reason, intent
  reservation, dispatch, evidence validation, publication, and every hold.
- Metrics: passes run; items skipped by reason; intents reserved; attempts;
  publications; unresolved ambiguities.
- Traces: not required for the pilot.
- Human-visible: every required human decision and every hold is surfaced on the
  **work item itself**, not only in engine logs. A silent scheduler is not a
  healthy one, so a missed pass must be detectable by the operator.

## Security / Privacy

- Data handled: repository content, work-item text, patches, and run evidence.
  All are untrusted input.
- Threats considered: credential inheritance by the worker; prompt injection via
  work-item or repository content; a worker-authored branch executing in a
  privileged CI workflow; a publisher escalating to merge; duplicate publication
  after a lost acknowledgement.
- Mitigations: worker holds no write credential and is probed from inside; the
  publisher is the sole writer and cannot merge; publication revalidates the grant;
  the CI trust boundary for publisher-authored branches is configured separately
  from worker isolation. Secret values live in an instance-managed secret
  mechanism, never in committed configuration.

## Open Questions

These block implementation; the `PLAN` must resolve each before or during its
first steps.

- What is the durable representation and verification of a grant, and how is the
  acting human authenticated against it?
- What are the scope-revision rules that require a new generation rather than
  reusing an intent?
- What is the runtime's invocation, lookup, and cancellation behavior on the
  installed version, and what does an unknown dispatch state look like?
- What is the discovery procedure for a possibly-created remote publication, and
  which incompleteness conditions force a human hold?

The interface-surface question was resolved by the 2026-10-01 amendment
(§Interfaces).
