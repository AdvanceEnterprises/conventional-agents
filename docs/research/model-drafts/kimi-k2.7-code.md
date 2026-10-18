---
type: architecture
id: ARC42
system: collective-agents
scope: system
stability: evolving
owner: collective-agents maintainers
related_adrs:
  - ADR-0012
  - ADR-0014
  - ADR-0018
  - ADR-0019
  - ADR-0020
  - ADR-0021
  - ADR-0022
  - ADR-0023
  - ADR-0024
  - ADR-0026
  - ADR-0028
  - ADR-0032
  - ADR-0037
  - ADR-0039
tags: [architecture, arc42, workflow-engine, agent-orchestration]
created: 2026-09-27
updated: 2026-09-27
---

<!--
PARSING_HINTS:
- This is a candidate architecture draft, not an accepted ADR or FS.
- It records proposed structure, quality goals, boundaries, and open decisions.
- Do not implement directly from this document; use it as input to ADRs/FS/PLAN.
-->

# Architecture Overview (arc42): collective-agents

## 1. Introduction and Goals

### 1.1 Requirements Overview

collective-agents is a reusable governed workflow execution product. It consumes the
conventional-agents framework as its contract and implements reconciliation, agent
dispatch, outcome recording, and safe retries against that contract. The first intended
integration pair is GitHub Issues + Projects v2 for work items and Hermes Agent for agent
execution, but neither is a mandatory core dependency.

Primary use cases:

- **Level-triggered reconciliation**: A scheduled reconciler enumerates work items,
  evaluates their Type / Label / Phase state, and dispatches only work that is currently
  authorized, parked-state clear, and not already in flight.
- **Autonomous agent dispatch**: For work items that pass the gate, the engine reserves a
dispatch attempt in its own ledger and hands the work to an agent runtime in a scoped,
attributable way.
- **Evidence-based publishing**: The agent runtime returns evidence (patch, summary, test
  results) to a separate publisher component that validates current authority and evidence
  before any external write.
- **Outcome recording**: The engine records what happened per reservation in a durable
  ledger that survives substrate-side retraction, and mirrors required human actions back
  to the work item substrate.
- **Portfolio operation**: A multi-repo instance can register several repositories, each
  with its own work-item substrate and agent-runtime configuration, without hardcoding
  those facts in the reusable product.

### 1.2 Quality Goals

Prioritized quality attributes:

1. **Human oversight remains decisive.** No automated path merges code or silently
   reauthorizes work. The framework's non-overridable merge gate (`ADR-0012`) is respected
   by construction: the product never ships a merge action.
2. **Attributability over enforcement.** The product operates on substrates that cannot
   technically prevent every misuse (GitHub Projects fields are editable by any token
   that can write the project; Issue comments are deletable) [`integrations/github-issues-projects.md` §7].
   The architecture therefore builds its own durable ledger and treats substrate activity
   records as human-visible signals, not as safety-critical idempotency keys.
3. **Level-triggered correctness.** Reconciliation is the correctness guarantee; events
   and webhooks only accelerate it (`ADR-0028`). A missed event costs latency, not correctness.
4. **Substrate neutrality.** Work-item substrate and agent-runtime bindings are separate.
   The core engine assumes only the six `ADR-0024` capabilities and a dispatch surface
   provided by an `ADR-0039` runtime binding.
5. **Recoverability from crash and ambiguity.** A crash after a GitHub write may leave the
   engine uncertain about whether the write succeeded. The architecture targets
   **at most one published outcome per reservation**, not exactly-once dispatch, and parks
   unresolved ambiguity for a human.
6. **Template/instance hygiene.** The product repository is a template: it ships no board
   IDs, project numbers, credentials, or organization names. Instances supply those via
   caller-relative configuration (`ADR-0032`, `FS-0024` / `ADR-0033`).

### 1.3 Stakeholders

- **Adopter organizations / portfolio operators**: need a governed, multi-repo agent
  workflow without forking the framework.
- **Project maintainers**: need to see why a run happened, what it produced, and what
  requires human input, all on the work item they already watch.
- **Auditors / security reviewers**: need an attributable trail of authority, dispatch,
  and outcome that survives comment deletion and host restart.
- **Agent runtime maintainers**: need a clear, narrow dispatch contract and evidence
  format so their runtime can participate without inheriting external write credentials.
- **conventional-agents framework maintainers**: need the product to stay inside the
  contract and not reintroduce orchestration into a standards layer (`ADR-0007`).

## 2. Constraints

- **Governance constraints:**
  - Agents must not merge PRs (`ADR-0012`).
  - Type is human-mutable only; agents flag misclassification (`ADR-0019`).
  - The `question` parked state suppresses agent actions on the work item (`ADR-0020`).
  - Unattended actors carry a distinct `user.email`, `mode=autonomous`, and a specific
    `session=<job-name>` (`ADR-0021`).
  - Approval is a recorded human act (`ADR-0026`).
  - Reconciliation is level-triggered; events are accelerators (`ADR-0028`).
  - Multi-model collaboration rounds require different models and ship disabled
    (`ADR-0023`).
- **Substrate constraints:**
  - GitHub Issues + Projects v2 provide no per-field access control and no
    field-change history API; concurrent writes are last-write-wins with no optimistic
    concurrency [`engine-boundary-and-failure-modes.md` §2, §5].
  - GitHub Actions `schedule:` is best-effort and disabled after 60 days of repository
    inactivity [`integrations/github-issues-projects.md` §6].
  - Hermes kanban is single-host and offers no cross-host coordination primitive
    [`engine-boundary-and-failure-modes.md` §2].
- **Product-form constraints:**
  - The repository is a template; instance data (board IDs, credentials, identities,
    model choices, budgets) belongs in instance configuration (`ADR-0032`).
  - A runtime binding only sets up a runtime; it does not ship a trigger that mutates
    work items (`ADR-0039`).
- **Binding constraints:**
  - A binding executable that can fail a PR merge lives in `scripts/` and is a Category 1
    gate (`ADR-0015` / `ADR-0037`). Binding executables that provision or report live
    under `integrations/<binding>/`.

## 3. Context and Scope

### 3.1 Business Context

collective-agents sits between a work-item substrate (e.g., GitHub Issues + Projects v2)
and one or more agent runtimes (e.g., Hermes Agent). It does not replace the framework;
it implements the framework's workflow contract.

External actors:

- **Human maintainers** create and classify work items, approve transitions, review and
  merge PRs.
- **Substrate** stores the work item, its Type / Phase / Label state, and an activity
  timeline. It is authoritative for current work-item state only.
- **Agent runtime** executes the actual work (drafting, patching, testing) and returns
  evidence.
- **Git repository** is the durable artifact authority for code and governance documents.
- **Instance configuration** resolves which repositories, boards, credentials, identities,
  schedules, and profiles belong to this deployment.

### 3.2 Technical Context

- **Protocols and APIs:** GitHub REST / GraphQL for work items; Git for artifact
  authority; runtime-specific dispatch interface (Hermes CLI / kanban / delegate_task
  toolset first) for execution.
- **Authentication:** GitHub credential held by the engine/publisher process, scoped to
  repo + org-level Projects write. Agent runtime credential held by the runtime profile,
  scoped to its own tools and, if possible, denied external write access.
- **Data formats:** YAML for instance configuration; JSON / SQLite for ledger; Markdown for
  human-visible records; Git trailers for commit-level attribution.
- **Integration surface:**
  - `integrations/github-issues-projects.md` and the executable layer under
    `integrations/github/` (`ADR-0037`) for the work-item substrate.
  - `integrations/runtimes/hermes/` (future, governed by `ADR-0039`) for the Hermes Agent
    runtime binding. This is a candidate, not a shipped dependency.

## 4. Solution Strategy

- **Separate concerns by lifecycle:** substrate observation, authority evaluation, ledger
  reservation, dispatch, evidence return, outcome publishing, and human-visible mirroring
  are distinct building blocks.
- **Ledger-first reservation:** Before any external dispatch or publication, the engine
  writes a reservation row. The ledger is the engine's durable idempotency key and
  outcome boundary.
- **Worker returns evidence, not credentials:** The agent runtime produces a patch /
  summary / test report and hands it back. A separate publisher, running under the engine's
  substrate credential, performs the actual GitHub write after re-checking authority.
- **Level-triggered with event acceleration:** A periodic reconciler is mandatory; events
  may trigger an early pass but never replace the schedule.
- **Attributability everywhere:** Every reservation, dispatch, and outcome carries
  actor, model, role, session, and mode; commits carry `Agent-Attribution:` trailers per
  `ADR-0018` / `ADR-0029`.
- **Fail-parked on ambiguity:** If a previous dispatch or write cannot be confirmed, the
  engine applies `question` and stops rather than retrying blindly.
- **Instance policy in instance config:** model choice, fallback, budgets, identities,
  board IDs, and schedules are resolved from caller-relative configuration, never from
  vendored templates.

## 5. Building Block View

### 5.1 Engine core

- **Reconciler**
  - Responsibility: enumerate work items, read current Type / Label / Phase, evaluate the
    autonomous gate (`ADR-0019`), and decide whether a dispatch is warranted.
  - Key interfaces: substrate enumeration API; ledger read/write; policy resolver.
  - Invariants: idempotent; reads current state before acting; respects `question`
    suppression (`ADR-0020`).

- **Authority / Policy Evaluator**
  - Responsibility: determine whether a proposed action is authorized for a given work
    item, Type, Phase, and evidence state.
  - Key interfaces: work-item state; ledger; instance policy; framework gate rules
    (`FS-0018`, `ADR-0019`).
  - Invariants: never authorizes a new generation from a changed description alone; one
    authorized action / scope generation is the unit of a canonical proposal
    [BRIEF.md §"Product direction"].

- **Ledger**
  - Responsibility: record one row per `(work_item_id, transition_attempted,
    dispatch_attempt_id)` with idempotency key, timestamp, assigned profile / task_run,
    commit SHAs, PR number, and outcome.
  - Key interfaces: atomic append; outcome publication guard; recovery query.
  - Invariants: append-only from engine perspective; checked immediately before any
    external publish to guarantee **at most one outcome per reservation**
    [`engine-boundary-and-failure-modes.md` §2].

- **Dispatcher**
  - Responsibility: after ledger reservation, hand the scoped work to the agent runtime
    via a runtime-specific dispatch interface.
  - Key interfaces: runtime dispatch API; profile resolver; timeout and heartbeat monitor.
  - Invariants: dispatch only after reservation; record assigned runtime task reference in
    ledger.

- **Outcome Publisher**
  - Responsibility: receive evidence from the worker, re-check current authority and
    ledger state, and perform substrate writes (draft PR, Phase transition, comment).
  - Key interfaces: evidence store; substrate mutation API; ledger publication guard.
  - Invariants: never merges; aborts if authority changed or ledger shows an outcome
    already published.

- **Evidence Store**
  - Responsibility: hold the worker's returned patch, summary, and test results in a form
    the publisher can validate and the auditor can inspect.
  - Key interfaces: write-once per reservation; signed / checksummed retrieval.
  - Invariants: immutable per reservation; not writable by the worker after return.

- **Human Mirror**
  - Responsibility: copy Hermes-side or engine-side blocks back onto the GitHub Issue
    (e.g., as `question`) so a human watching only GitHub can see that action is needed.
  - Key interfaces: Issue label / comment API; outcome classifier.
  - Invariants: `question` is reserved for genuine human-input blocks; operational
    failures use a separate retry policy until budget exhaustion
    [`engine-boundary-and-failure-modes.md` §3 step 10].

### 5.2 Substrate binding layer

- **GitHub Issues + Projects v2 binding**
  - Responsibility: map the six `ADR-0024` capabilities onto GitHub mechanisms.
  - Key interfaces: enumeration, field read/write, label read/write, comment read/write.
  - Enforcement/attributability: Type and parked state are conventional/detectable; Phase
    is native; merge is enforced by branch protection (`ADR-0012`)
    [`integrations/github-issues-projects.md` §7].

### 5.3 Runtime binding layer

- **Hermes Agent runtime binding (candidate)**
  - Responsibility: provision the runtime so it can discover `AGENTS.md`, run framework
    gate scripts, and emit correct `Agent-Attribution:` trailers; provide a dispatch
    interface shape for the engine to use.
  - Key interfaces: profile selection, `kanban_*` or `delegate_task` invocation, evidence
    return channel.
  - Boundaries: the runtime binding is setup only; it does not ship a trigger that
    mutates work items (`ADR-0039`).

### 5.4 Instance configuration

- **Instance registry / config resolver**
  - Responsibility: load repository registries, board IDs, field option IDs, credentials,
    actor identities, schedules, model policy, and budgets from the caller's repository root.
  - Key interfaces: YAML config files (`config/project.yml`, `config/gates.yml`,
    `config/instance.yml`); environment for secrets; validation.
  - Invariants: no instance data in the product template (`ADR-0032`).

## 6. Runtime View

### 6.1 Candidate end-to-end flow: Type `task` Issue reaches draft PR

1. Human opens Issue; `enhancement` label auto-adds it to the board as `Status: Backlog`,
   `Issue Type` unset [`integrations/github-issues-projects.md` §3].
2. Reconciler enumerates the board. Type is unset → gate at most restrictive setting.
   Engine posts an `agent-stance:` comment proposing `Type=task` and transitions to
   `Approved` only if configured to do so for low-risk paths; otherwise it waits.
3. Human sets `Issue Type = task` and `Status = Approved`. This is the human-approval act
   for a `task` [`FS-0018`; `ADR-0026`].
4. Next reconciliation pass sees `Approved` + `task` + no `question`.
5. **Ledger-first reservation:** Engine writes a reservation row with a fresh
   `dispatch_attempt_id`, work-item identity, and intended action, **before** posting any
   `agent-stance:` or dispatching. If the engine crashes here, no dispatch has happened
   [`engine-boundary-and-failure-modes.md` §2, §3 step 5].
6. Engine posts the `agent-stance:` activity-record entry (human-visible, but not the
   safety-critical idempotency key).
7. Engine selects a Hermes profile based on `(Type, Label, evidence-so-far)` mapping from
   instance policy and dispatches via the runtime-specific interface. The selected and
   actual model must be attributable; model fallback is instance policy, mechanism is
   product [`engine-boundary-and-failure-modes.md` §6].
8. Hermes worker executes under a profile with the `kanban_*` toolset if enabled, but
   **does not hold the GitHub write credential**. It returns a patch and summary to the
   evidence store.
9. Publisher re-reads current work-item state and ledger. If state changed or ledger
   already shows an outcome for this reservation, it aborts.
10. Publisher creates a **draft** PR (`draft: true`) linked to the Issue by keyword or
    manual link, records the PR number in the ledger, and records the outcome.
11. For Type `task`, `Status` transitions to `In Review` automatically because the PR is
    the human-review surface [`FS-0018` Success Criteria].
12. Merge never happens in this flow; human review and merge remain outside the engine
    (`ADR-0012`).

### 6.2 Failure handling flow

1. Worker outcome arrives: `completed`, `blocked`/`needs_input`, `crashed`,
   `timed_out`, `rate_limited`, `spawn_failed`, `reclaimed`
   [`engine-boundary-and-failure-modes.md` §2; Hermes kanban.md].
2. `blocked`/`needs_input` → Human Mirror applies `question` to the GitHub Issue and
   records the block reason in the ledger.
3. `crashed` / `timed_out` / `rate_limited` → bounded automatic retry with backoff,
   escalating to `question` only after retry budget is exhausted
   [`engine-boundary-and-failure-modes.md` §3 step 10].
4. Ambiguous partial write (e.g., PR may or may not have been created) → default to
   `question` for human resolution; do not blind-retry.
5. Each outcome is recorded in the ledger; the ledger guard prevents a second publish for
   the same reservation.

### 6.3 Concurrent human-edit race

1. Before any write, the publisher re-reads current Type / Phase / labels.
2. If they differ from the values seen at dispatch, abort and replan.
3. The substrate offers no `If-Match` / conditional PATCH, so this is a check-then-act
   race the engine closes by aborting on any detected change
   [`engine-boundary-and-failure-modes.md` §4].

### 6.4 Recovery after restart

1. Reconciler enumerates work items and reads the ledger.
2. For any reservation without a recorded outcome, it queries the runtime for the
   associated `task_run` and the substrate for any already-created PR / comment.
3. It reconstructs state from durable records (ledger, Git commits / PRs, runtime task
   record) rather than from Issue comments alone, since comments are deletable
   [`engine-boundary-and-failure-modes.md` §2, §5].

## 7. Deployment View

### 7.1 Environments

- **Single-repo instance:** One engine process / cron job reads one GitHub repository,
  one project board, and one Hermes profile. The ledger can be a small SQLite file or
  JSONL store alongside the instance checkout.
- **Portfolio instance:** A registry lists multiple repos/boards; the engine monitors
  each. Adds identity strategy (per-repo actor vs. one shared org-level actor with
  `session=`), cross-repo schedule liveness monitoring, and possibly a shared board vs.
  per-repo boards [`engine-boundary-and-failure-modes.md` §7].

### 7.2 Deployment topology

- **First-slice default:** scheduled CLI invocation, not a persistent daemon.
  `ADR-0028` requires only enumerability and idempotent reconciliation; GitHub Actions
  `schedule:` already documented; Hermes recommends an in-process dispatcher topology with
  standalone daemon mode deprecated [`engine-boundary-and-failure-modes.md` §8].
- **Event-accelerated second slice:** webhooks / project events may trigger an early
  reconciliation pass, but the schedule remains mandatory.
- **Publisher isolation:** the publisher process may run in a separate environment from the
  worker so that the worker cannot inherit the GitHub credential.

### 7.3 Secrets / config strategy

- **Product template ships:** empty / placeholder config files (`config/*.example.yml`)
  and documentation.
- **Instance supplies:** `config/project.yml`, `config/gates.yml`, `config/instance.yml`
  (or equivalent), plus credentials via environment or a secrets manager.
- **Never in Git:** tokens, private keys, actual board IDs, or organization names in the
  product repo (`ADR-0032`).

## 8. Cross-Cutting Concepts

### 8.1 Error handling

- Distinguish transient operational failures (`rate_limited`, `timed_out`, `crashed`
  where diagnosable) from genuine human-decision blocks (`needs_input`).
- Transient failures get bounded automatic retry with backoff.
- Human-decision blocks and ambiguous partial writes default to `question`.
- No silent failure: every worker outcome is recorded and, where relevant, mirrored to
  GitHub.

### 8.2 Logging / observability

- Required signals:
  - Run outcome, log, summary, metadata from the runtime (Hermes `task_runs`).
  - GitHub-side human-required action via `question` label.
  - Decision rationale via `agent-stance:` comment and `Agent-Attribution:` commit trailer.
  - Cost assembled from provider billing signals joined to ledger by work-item key (neither
    platform exposes per-task cost natively) [`engine-boundary-and-failure-modes.md` §8].
- The concrete gap: a GitHub-only human cannot see a Hermes-side block unless the engine
  mirrors it back. This mirroring is a hard requirement, not a nice-to-have
  [`engine-boundary-and-failure-modes.md` §8].

### 8.3 Security

- **Credential ceiling:** A GitHub token that can write `Issue Type` and `Status` has no
  finer-grained option; the real merge enforcement is branch protection excluding the
  automation identity from the push/merge allowlist
  [`engine-boundary-and-failure-modes.md` §5].
- **Worker isolation:** workers return evidence and do not hold the GitHub credential.
  Actual isolation removes inherited credentials and filesystem / network access, not
  merely an instruction or profile name [BRIEF.md §"Product direction"].
- **Prompt-injection boundary:** The runtime's trusted-local-user model means the real
  boundary is which tools are enabled on the profile (`kanban_*`) plus the engine's
  evidence format, not a platform-enforced sandbox
  [`engine-boundary-and-failure-modes.md` §5].

### 8.4 Configuration

- Instance configuration resolves repositories, boards, credentials, identities,
  schedules, model policy, and budgets. The product ships only shape and placeholders.
- Profile selection maps `(Type, Label, evidence-so-far)` to a Hermes profile, keeping
  model choice inside a mechanism the runtime already owns rather than building a parallel
  router [`engine-boundary-and-failure-modes.md` §6].

### 8.5 Testing strategy

- Unit-test ledger idempotency, authority evaluation, and race-detection logic against
  in-memory substrate/runtime fakes.
- Bats probes for CLI entry points, instance config validation, and substrate audit
  command behavior (following `FS-0029` / `ADR-0037` executable-layer pattern).
- Hermetic Hermes tests use an isolated `HERMES_HOME` against a local kanban board where
  possible.
- Live GitHub tests are manual / recorded; never run unbounded writes in CI.

## 9. Architectural Decisions

This draft does not accept new ADRs; it anticipates the following decisions will need
ADRs (or will be constrained by existing accepted ADRs):

- **ADR-0012 (accepted):** Non-overridable merge prohibition and identity gate.
- **ADR-0014 (accepted):** Background tasks are scoped; unattended sessions are primaries,
  not background tasks. Repeating executions must be idempotent.
- **ADR-0018 (accepted):** Single-identity workflow with `Agent-Attribution:` trailers.
- **ADR-0019 (accepted):** Type human-mutable only; Type-keyed autonomous gate.
- **ADR-0020 (accepted):** `question` suppresses agent actions.
- **ADR-0021 (accepted):** Distinct unattended actor identity with `mode=autonomous` and
  specific `session=`.
- **ADR-0023 (accepted):** Multi-model collaboration requires different models and ships
  disabled.
- **ADR-0024 (accepted):** Platform-neutral core with shipped bindings; six capabilities.
- **ADR-0026 (accepted):** Approval is a recorded human act.
- **ADR-0028 (accepted):** Level-triggered reconciliation authoritative; events are
  accelerators.
- **ADR-0032 (proposed):** Template vs. instance repository form; no instance data in the
  product template.
- **ADR-0037 (accepted):** Executable layer for the GitHub binding; bright line between
  binding executables and Category 1 gates.
- **ADR-0039 (accepted):** Runtime bindings are setup only; do not ship triggers that
  mutate work items. Does **not** define a dispatch API.

## 10. Risks and Technical Debt

| Risk / debt item | Severity | Mitigation | Status |
| --- | --- | --- | --- |
| Substrate activity record (Issue comment) is deletable; relying on it for idempotency is unsafe | High | Ledger-first reservation; ledger is the idempotency key; comments are human-visible only | Accepted pattern |
| GitHub has no per-Issue lock; concurrent reconcilers may duplicate dispatch | High | Ledger guard + per-Issue concurrency serialization in the instance's trigger handler; cross-host coordination not provided by either platform | Needs ADR for multi-host dispatch |
| Hermes kanban is single-host; no cross-host coordination | Medium | Treat dispatcher as single-host unless a portfolio instance explicitly designs otherwise | Open decision |
| Stale Hermes worker may be reclaimed by Hermes, but the engine may have already advanced GitHub Phase | Medium | Engine maintains its own dispatch timeout independent of Hermes reclaim; recovery re-reads substrate state | Accepted pattern |
| Partial GitHub writes (PR created but Phase not advanced) are not atomic | High | Ledger records each attempted external write; recovery reconstructs sequence and completes or parks | Accepted pattern |
| Concurrent human edit during a run is a check-then-act race because GitHub lacks optimistic concurrency | Medium | Publisher re-reads Type/Phase/labels immediately before write and aborts on change | Accepted pattern |
| GitHub Actions `schedule:` disabled after 60 days of inactivity; quiet repos silently lose reconciliation | Medium | Portfolio instance monitors schedule liveness per repo; alert when missing | Instance policy |
| Worker may inherit GitHub credential if it runs in the same environment as the publisher | High | Separate publisher process; remove inherited credentials and filesystem/network access from worker | Open decision |
| No per-task dollar budget cap confirmed in Hermes kanban | Medium | Cost assembled from provider billing joined to ledger; instance sets caps where provider supports it | Instance policy |
| Model fallback in Hermes may collide with `ADR-0023` independence requirements in future review-board dispatch | Medium | Record actual model used; separate ADR for review-board dispatch under `ADR-0023` | Open decision |

## 11. Open Decisions

The following decisions are explicitly open and must be resolved before implementation
begins on the relevant slice:

1. **First permissible Type / action.** Whether the first autonomous slice starts with
   Type `task` (loosest gate, PR self-advances to In Review) or Type `feature` (requires
   FS drafting, stresses approval UX early). The framework's gate already permits
   autonomous `task` movement; the product decides how much of that room to use
   [`engine-boundary-and-failure-modes.md` §9 Open Decision 1].
2. **Minimum dispatch evidence bar.** What evidence is required before dispatching a
   worker that will hold real write authority (if the worker model is not fully isolated).
   The platform provides no evidentiary gate; this is entirely the engine's policy
   [`engine-boundary-and-failure-modes.md` §9 Open Decision 2].
3. **Autonomous Phase transitions within existing gates.** How much autonomous Phase
   movement the engine should use for each Type. The gate sanctions `task` In Progress →
   In Review on PR-open; using it is a product choice
   [`engine-boundary-and-failure-modes.md` §9 Open Decision 3].
4. **Dispatch API and runtime invocation surface.** `ADR-0039` governs runtime setup, not
   how the engine programmatically dispatches a run. A separate design (and likely a
   dedicated ADR) is needed for the dispatch interface shape, evidence return channel, and
   status polling / callback contract.
5. **Stable intent / generation representation.** How to represent the authorized action
   / scope generation so that retries and authority checks compare against a canonical,
   versioned record rather than a transient prompt.
6. **Durable ledger implementation.** SQLite, JSONL, or an instance-level database; its
   schema; retention; and how a portfolio instance aggregates or partitions ledgers.
7. **Publisher concurrency and recovery.** How the publisher handles concurrent
   reservations for the same work item, crash between GitHub write and ledger update, and
   detection of already-published outcomes after restart.
8. **Instance configuration resolution.** Exact file names, precedence rules for
   portfolio vs. repo-level overrides, and validation schema for `config/project.yml`,
   `config/gates.yml`, and any new `config/instance.yml`.

## 12. Quality Scenarios

The following scenarios translate the quality goals into testable situations:

1. **Human oversight (merge gate).**
   - Trigger: An autonomous run completes a patch and summary.
   - Stimulus: Publisher receives a request to merge the PR.
   - Response: Publisher refuses; no merge action is implemented in the product; branch
     protection independently denies the automation identity.
   - Measure: No `gh pr merge` or equivalent in product code; CI grep check passes.

2. **Attributability survives comment deletion.**
   - Trigger: A reviewer deletes an `agent-stance:` comment.
   - Stimulus: Auditor queries who authorized a dispatch and what its outcome was.
   - Response: Ledger and `Agent-Attribution:` commit trailers still answer the question.
   - Measure: Recovery test passes after synthetic comment deletion.

3. **Level-triggered correctness.**
   - Trigger: Webhook delivery for a Phase change is dropped.
   - Stimulus: Reconciler runs at the next scheduled interval.
   - Response: Reconciler sees the same unprocessed work item and dispatches it once.
   - Measure: Withheld-event test produces exactly one dispatch.

4. **Substrate neutrality.**
   - Trigger: A second adopter wants to use a different work-item substrate.
   - Stimulus: Engine is configured with a binding that provides the six `ADR-0024`
     capabilities.
   - Response: Engine core requires no code change; only the binding and config differ.
   - Measure: Interface test shows the core depends only on the capability contract.

5. **Recoverability from crash before publish.**
   - Trigger: Engine crashes after writing the ledger reservation but before any GitHub
     write.
   - Stimulus: Engine restarts.
   - Response: Reconciler reads the ledger, sees the uncompleted reservation, and either
     resumes or parks for human resolution; no duplicate PR is created.
   - Measure: Crash-injection test produces at most one PR per reservation.

6. **Mirroring of required human action.**
   - Trigger: A Hermes worker reports `blocked` / `needs_input`.
   - Stimulus: Engine processes the outcome.
   - Response: `question` label is applied to the GitHub Issue within the same
     reconciliation pass.
   - Measure: Label application appears in Issue timeline with a cited reason.

7. **Concurrent human edit does not clobber human intent.**
   - Trigger: A human changes Phase while a run is in flight.
   - Stimulus: Publisher attempts to write Phase.
   - Response: Publisher re-reads state, detects the change, aborts, and parks the Issue
     for replanning.
   - Measure: No Phase overwrite; `question` or retry path taken instead.

8. **Worker isolation (credential).**
   - Trigger: A worker process is compromised or misconfigured.
   - Stimulus: It attempts to call `gh pr create`.
   - Response: The GitHub credential is not available in the worker environment; only the
     separate publisher can write.
   - Measure: Credential absence verified by environment inspection test.

## 13. Citations

- `README.md` / `AGENTS.md` on `AdvanceEnterprises/collective-agents` trunk: product
  boundary, status, and governance bootstrap.
- `BRIEF.md`: independent drafting assignment and product-direction constraints.
- `vendor/conventional-agents/` at `94b784aa022b715bf7dad331a714f786620f961a`:
  - `AGENTS.md`, `INTEGRATION.md`
  - `guidelines/ROLE_CONTRACT.md`
  - `workflows/session-modes.md`, `workflows/document-lifecycle.md`
  - `docs/decisions/ADR-0012`, `ADR-0014`, `ADR-0018`, `ADR-0019`, `ADR-0020`, `ADR-0021`,
    `ADR-0022`, `ADR-0023`, `ADR-0024`, `ADR-0026`, `ADR-0028`, `ADR-0032`, `ADR-0037`,
    `ADR-0039`
  - `docs/specifications/FS-0018`, `FS-0038`
  - `integrations/github-issues-projects.md`
  - `config/project.example.yml`, `config/gates.example.yml`
- `docs/research/engine-boundary-and-failure-modes.md` on
  `AdvanceEnterprises/collective-agents` commit `6d2a94b44545be0aec072c45e3f8bfe83067ed38`:
  research memo used as evidence, not a normative design.

## 14. Document Status

This ARC42 draft is a **candidate architecture document**, not an accepted ADR, feature
spec, or implementation plan. It is intentionally written to inform subsequent ADRs and
FS/PLAN documents. No code should be implemented directly from this draft.
