---
type: architecture
id: ARC42
system: collective-agents
scope: system
stability: evolving
owner: collective-agents maintainers (instance owner assigns)
related_adrs: []
tags: [architecture, arc42, workflow-execution, governance, reconciliation]
created: 2026-09-27
updated: 2026-09-27
---

<!--
PARSING_HINTS:
- Candidate architecture draft. Not an implementation spec, not an accepted ADR,
  not an FS/PLAN. No engine or binding exists (B:README).
- The enforced / detectable / proposed distinction is deliberate and load-bearing:
  read every property claim with its marker.
-->

# Architecture Overview (arc42) — collective-agents

**Status of this document.** Candidate draft, produced independently from the pinned
bootstrap, the pinned vendored contract, and the research memo. It authorizes nothing.
Three product-direction statements it reflects were agreed with the human beforehand
(B:BRIEF §Product direction). Nothing here should be read as a shipped binding: the
GitHub work-item binding and the Hermes kanban mapping are the framework's, and the
Hermes kanban binding is explicitly not shipped (C:docs/specifications/FS-0038).

**Citation legend.** [B:x] = collective-agents bootstrap on trunk (README.md, AGENTS.md,
BRIEF.md). [C:x] = pinned vendored contract, paths relative to
`vendor/conventional-agents/` at `94b784aa022b715bf7dad331a714f786620f961a`.
[R:§n] = `docs/research/engine-boundary-and-failure-modes.md` @ `6d2a94b4` (evidence,
not normative). [X:d] = an external mechanism as recorded by the memo, retrieved
2026-09-26. **Enforced** = the platform technically prevents the alternative;
**detectable** = a violation is visible after the fact; **proposed** = designed here,
demonstrated nowhere.

## 1. Introduction and Goals

### 1.1 Requirements Overview

collective-agents is a reusable workflow executor: it consumes conventional-agents as
its governance contract and implements reconciliation, agent dispatch, outcome
recording, and safe retries against it. It is not a governance framework and not an
org-specific operations desk (B:README).

- **R1** Consume the framework's portable contracts; never restate or weaken them
  (C:ADR-0024; B:AGENTS).
- **R2** Git is the durable artifact authority; work-item state is not (B:README;
  C:integrations/github-issues-projects.md §5).
- **R3** GitHub work items and Hermes Agent execution are the first integration pair,
  neither a mandatory core dependency (B:README).
- **R4** Work-item substrate and agent-runtime invocation stay separate concerns; no
  dispatch API exists today (C:ADR-0039; R:§3 step 6).
- **R5** One authorized action/scope generation on a work item is the unit of a
  canonical proposal (typically one draft PR), stable across retries; runs are
  attempts, not new authorities (B:BRIEF).
- **R6** Workers return evidence (patch, summary, test results) without GitHub write
  credentials; a separate publisher validates current authority and evidence before
  publishing, and never merges (B:BRIEF; R:§5).
- **R7** Ledger-first reservation precedes dispatch. No exactly-once guarantee for
  external GitHub writes is claimed; the publish path must detect existing
  publications and stop on unresolved ambiguity instead of retrying blind
  (B:BRIEF; R:§2, §4).
- **R8** Level-triggered reconciliation is authoritative; events only accelerate
  (C:ADR-0028).
- **R9** `question` parks for genuine human input, not transient failure
  (C:ADR-0020; R:§3 step 10).
- **R10** Selected and actual model must both be attributable; model identities,
  fallback, and budgets are instance policy, not product defaults (B:BRIEF; B:AGENTS).
- **R11** Human approval and merge gates remain in force (C:ADR-0012; B:AGENTS §Safety).

### 1.2 Quality Goals

| # | Goal | Motivation |
| --- | --- | --- |
| 1 | Reconciliation correctness | A missed trigger must cost latency, never correctness (C:ADR-0028) |
| 2 | Governance fidelity | No action exceeds the Type-keyed autonomous gate or merge gate (C:ADR-0019, ADR-0012) |
| 3 | Auditability | Every action attributable; the "why" trail is the engine's own construction (R:§5) |
| 4 | At-most-one outcome published (target) | Duplicate external writes are the costliest failure; the guarantee is a target, not a claim (R:§2) |
| 5 | Least authority / isolation | A misbehaving run cannot write to GitHub if it holds no write credential (R:§5) |
| 6 | Substrate and runtime neutrality | Core stays capability-based; bindings state enforcement honestly (C:ADR-0024) |
| 7 | Operability at portfolio scale | Quiet repos, drifting schedules, and cost must be visible, not assumed (R:§7, §8) |

### 1.3 Stakeholders

- **Instance operator (human):** owns repos, identities, budgets, approvals; wants
  gates enforced and drift visible.
- **Adopters:** need concrete, copyable behavior; neither substrate may be required
  (B:README).
- **Agent workers:** need unambiguous scope, evidence contract, and stop conditions.
- **Reviewers (GitHub-only):** must see what needs human action without Hermes access
  (R:§8).
- **Future binding authors:** need a capability vocabulary to conform to
  (C:integrations/README.md).

## 2. Architecture Constraints

- **Technical.** The framework pins portable rules at precedence level 1-2
  (C:INTEGRATION.md §Precedence Rules); the executor must not need GitHub or Hermes
  specific nouns in its core (C:ADR-0024). Substrate capability floor is the six
  capabilities: work item, Type, Phase, parked state, activity record, enumerability
  (C:integrations/README.md). GitHub offers no per-field ACL, no conditional requests
  on field writes, and deletable comments (C:integrations/github-issues-projects.md
  §2, §5, §7; R:§4, §5).
- **Organizational.** Unattended work carries a distinct actor identity with
  `mode=autonomous` and a specific `session=<job-name>` (C:ADR-0021). Type is
  human-mutable only (C:ADR-0019). Instance data — repos, board IDs, identities,
  schedules, budgets, credentials — never ships in the product (B:AGENTS; direction
  per C:ADR-0032, which is **proposed** at the pinned revision and therefore
  direction, not a binding constraint).
- **Security.** Credentials do not belong in Git (B:BRIEF). A token that can write
  Type or Status has no finer-grained option; Projects v2 permission is resource-level
  only (R:§5). Worker isolation must remove inherited credentials and filesystem or
  network access as an actual mechanism, not an instruction (B:BRIEF).
- **Boundary note.** The framework draws "standards only, never orchestration"
  for itself (C:ADR-0007). The executor is where orchestration deliberately lives;
  it consumes the contract rather than extending it. Any appearance of the framework
  gaining orchestration power through this product is a defect to be named.

## 3. Context and Scope

### 3.1 Business Context

| Partner | Interaction |
| --- | --- |
| Human operator | Approves Type/Phase acts, answers `question`, merges PRs; receives escalations on the work item itself |
| Adopter repositories | Supply work items, instance configuration, and their own reviewer population |
| GitHub | Work-item substrate: Issues, Projects v2 fields, labels, comments, PRs, webhooks, Actions schedule |
| Hermes Agent (first runtime) | Executes workers under a profile; returns run outcome and logs; kanban is a candidate substrate, not shipped (C:FS-0038) |
| Model providers | Serve the models recorded in attribution; billing signals needed for cost views (R:§8) |

### 3.2 Technical Context

- **GitHub access:** `gh` CLI / REST / GraphQL, per-call `gh auth status` verification
  (C:ADR-0012). Enumeration via `gh project item-list`, Issues API, GraphQL
  (C:integrations/github-issues-projects.md §6).
- **Triggers:** webhooks (best-effort, no automatic redelivery; X:webhooks) and
  Actions `schedule:` (best-effort, default-branch-only, auto-disabled after 60 days
  of repository inactivity, per repository; C:integrations/github-issues-projects.md
  §6; R:§4).
- **Runtime invocation:** per-profile Hermes configuration; no documented per-task
  GitHub credential injection and no dispatch API (R:§3 step 7, §5; C:ADR-0039).
- **Instance configuration:** shapes exist at `config/project.example.yml` and
  `config/gates.example.yml`; resolution is caller-relative with fail-closed behavior
  for safety-relevant values (C:ADR-0033).
- **Ledger store:** instance-chosen; small-file or SQLite plausible at single-repo
  scale (R:§7). Shape is the product's own building block (R:§2).

## 4. Solution Strategy

- **Reconciliation is the loop; every invocation is a reconciler.** Read current
  state, compute desired state, act idempotently; never trust that a previous run
  finished (C:ADR-0028; C:ADR-0014).
- **Separate three authorities.** Work-item substrate (where classification and
  parking live), runtime (where execution happens), and Git (where artifacts live).
  The engine joins them; the join is persisted, not inferred (R:§1).
- **Generation-scoped proposals.** Authorization is pinned to a generation key —
  work item + classifying intent + authorized scope — recorded before dispatch;
  retries reuse it, and a changed issue description does not silently mint a new one
  (B:BRIEF; R:§1, §2).
- **Evidence-return workers, single publishing path.** Workers never hold GitHub
  write credentials; the publisher re-validates authority and evidence, then performs
  the write, and never merges (B:BRIEF; R:addendum Q1).
- **Ledger-first, publish-boundary check.** Reservation precedes dispatch; before any
  GitHub write the publisher consults the ledger and refuses to publish twice for one
  reservation; it does not claim exactly-once (B:BRIEF; R:§2). Whether even
  at-most-one holds under every crash interleaving is an open decision (§11.3, OD5).
- **Outcome families are different.** `needs_input` parks with `question`;
  `rate_limited` / `timed_out` / `crashed` get bounded retry with backoff and escalate
  only on budget exhaustion; an ambiguous partial write parks for a human (R:§3 step
  10; C:ADR-0020).
- **Honesty as a property.** Every claim in shipped docs is labeled enforced,
  detectable, or proposed (C:ADR-0037 §6; C:integrations/github-issues-projects.md §7).
- **Instance policy vs product mechanism.** Model choice, budgets, cadence, and
  identities are configuration; the mechanism that honors them is product
  (B:AGENTS; R:§6).

## 5. Building Block View

### 5.1 Whitebox Overall System

| Block | Responsibility | Key interfaces | Property |
| --- | --- | --- | --- |
| Reconciler | Enumerate work items, compute desired state, sequence transitions per pass; idempotent | Substrate adapter read APIs; scheduler entry point | Required (C:ADR-0028) |
| Substrate adapter (GitHub first) | Read Type/Phase/labels/comments; write Phase, labels, comments, PRs; state enforcement per capability | REST/GraphQL/`gh`; binding semantics (C:integrations/github-issues-projects.md) | Detectable for Type/park/comments; enforced only for merge (C:ADR-0024) |
| Authority / generation tracker | Mint and persist generation keys; decide what a work item's current authorization covers | Ledger records; `touches:`/`interfaces:` where documents exist (C:ADR-0027) | Proposed |
| Dispatch gate | Evidence policy check before dispatch — the only thing between "approved" and "a process with real write authority is running" (R:§The three open product decisions #2) | Policy from instance config; ledger reservation | Proposed; scope open (§11.3 OD2) |
| Runtime adapter (Hermes first) | Invoke a worker under a chosen profile; capture run outcome and evidence | Undesigned dispatch interface (C:ADR-0039 is setup-only); Hermes kanban candidate unshipped (C:FS-0038) | Proposed; interface open (§11.3 OD6) |
| Worker environment | Execute with no GitHub write credential, no inherited secrets, bounded filesystem/network (B:BRIEF); returns patch, summary, test results | Evidence bundle format | Proposed; isolation must be demonstrated, not asserted |
| Evidence store | Hold evidence bundles addressable by run id; retention policy | Local/instance storage | Proposed |
| Publisher | Validate current authority + evidence against the generation; perform GitHub writes (draft PR, comments, Phase/label updates); refuse on unresolved ambiguity; never merge (C:ADR-0012) | Ledger; substrate adapter | At-most-one target; enforcement open (R:§2) |
| Ledger | One durable row per (work_item, transition_attempted, dispatch_attempt_id): idempotency key, timestamps, run reference, resulting SHAs/PR, outcome (R:§2) | Instance-chosen store; engine-only writer | Proposed; shape open (§11.3 OD5) |
| Outcome recorder | Classify run outcomes; mirror human-required actions to the work item (`question` per C:ADR-0020); trigger bounded retries | Ledger; substrate adapter; retry policy | Proposed |
| Instance configuration resolver | Resolve repos, boards, identities, profiles, budgets, ledger location from the caller's repository root, never from a vendored tree (C:ADR-0033; C:ADR-0032 direction) | `config/*.yml` shapes | Pattern accepted for gates; extension proposed |
| Observability/reporting | Per-item timeline reconstruction, per-repo schedule liveness, cost views (joined from provider billing) (R:§7, §8) | Ledger + run records | Proposed; cost feed absent from Hermes today (R:§8) |

### 5.2 Notes on Two Blocks That Carry the Most Risk

**Ledger.** It exists because the framework's own prescribed idempotency key — the
activity record — is retractable on GitHub: comments can be edited or deleted
(C:integrations/github-issues-projects.md §5; R:§2). The ledger is a second,
engine-owned layer that survives comment deletion and survives a Hermes board a
GitHub-only reviewer will never see. It does not replace the agent-stance comment,
which remains the mandated human-visible record (C:FS-0018).

**Publisher.** The alternative — letting the worker call `gh pr create` itself —
collapses the blast radius distinction: the worker inherits the ambient identity's
ceiling, identical to the dispatcher's (R:§5). The publisher being the sole writer is
the mitigation; its concurrency behavior (single publisher per instance? per repo?)
is open (§11.3 OD5).

## 6. Runtime View

### 6.1 Candidate End-to-End Flow (first slice, Type per §11.3 OD1)

1. Human opens an Issue with `enhancement`; auto-add lands it at `Status: Backlog`,
   `Issue Type` unset (C:integrations/github-issues-projects.md §3).
2. Reconciler pass enumerates; unset Type is treated at the most restrictive gate, so
   the engine's only autonomous option is a stance entry proposing classification
   (C:FS-0018 §Autonomous Gate).
3. Human sets `Issue Type` and `Status: Approved` — a recorded human-approval act
   (C:ADR-0026).
4. Next pass sees Approved + Type + no `question`. For Type `feature` the gate
   permits drafting and opening a PR but not Phase advancement past Approved; for
   `task` the engine may carry work further (C:FS-0018; C:ADR-0019).
5. Engine mints/reuses the generation key for this authorized action, writes the
   ledger reservation **first** — the safety-critical write — then posts the
   `agent-stance:` comment as the human-visible record (R:§3 step 5, corrected
   ordering).
6. **Dispatch gap, stated plainly:** the hand-off from work-item state to a Hermes
   worker is defined by neither governance layer; FS-0038 explicitly places syncing
   kanban to GitHub out of scope, and ADR-0039 governs runtime setup, not dispatch
   (C:FS-0038 Non-Goals; C:ADR-0039; R:§3 step 6). Any first slice must define a
   minimal dispatch mechanism and can only call it proposed (§11.3 OD6).
7. Runtime adapter invokes a worker under an instance-chosen Hermes profile — the
   natural expression of model policy is `(Type, Label, evidence-so-far) -> profile`,
   not overriding the runtime's internal routing (R:§6).
8. Worker executes with no GitHub write credential (B:BRIEF); its ambient identity,
   if any, must not be reusable for pushes.
9. Worker returns evidence: patch, summary, test results, and the model it actually
   ran as (R:§6; C:ADR-0018 as amended by C:ADR-0029).
10. Publisher re-reads current Type/Phase/labels (closing the check-then-act race as
    far as GitHub permits — there is no optimistic concurrency primitive; R:§4),
    validates evidence against the generation, and consults the ledger.
11. Publisher performs the GitHub write: open a **draft** PR (`draft: true` blocks
    merge but not CI; X:pulls), linked to the Issue by keyword — noting GitHub's
    manual-link auto-close behavior is a documented gap (R:§1).
12. Phase handling per Type: for `task`, In Progress -> In Review on PR-open is the
    explicitly sanctioned autonomous transition ("the PR itself is the human-review
    surface"); for `feature`/`bug`, Phase advancement stays human-held
    (C:FS-0018 §Success Criteria; C:ADR-0019).
13. Outcome family handling: `needs_input`/`blocked` -> ledger record + `question`
    mirrored onto the Issue so a GitHub-only human sees it; transient outcomes ->
    bounded retry with backoff, `question` only after budget exhaustion; ambiguous
    partial write -> park for a human (R:§3 step 10; C:ADR-0020).
14. Merge never happens here, in any flow (C:ADR-0012).
15. The ledger records the outcome, the PR number, and the run reference, so the
    next pass is a no-op on this generation.

### 6.2 Failure-Path Behaviors

| Situation | Behavior | Source of the rule |
| --- | --- | --- |
| Missed event / missed schedule | Next reconciliation pass sees the same state and acts; latency is bounded by interval | C:ADR-0028 |
| Crash after reservation, before dispatch | Safe direction: no dispatch happened; recovery re-reads ledger, honors in-flight reservation | R:§2 |
| Crash after worker returns, before publish | Publisher finds no publication for the reservation; re-validates and publishes once | Proposed |
| Duplicate publisher passes | Publish-boundary ledger check refuses a second publication for the same reservation; ambiguity parks | R:§2; open under OD5 |
| Remote write may have succeeded before ack | Enumerate existing publications (PRs/branches/comments) and stop on unresolved ambiguity; never blind retry | B:BRIEF; R:§2 |
| Human edits concurrently | Re-read immediately before write; abort/replan if changed; human edit wins for Type and Phase | C:FS-0018 §Edge Cases; R:§4 |
| Worker stall | Hermes reclaim (heartbeat + PID liveness) protects its own board only; the engine needs its own dispatch timeout independent of Hermes's | R:§4 |

### 6.3 Crash/Restart Recovery

Restart is harmless for re-evaluation because reconciliation is level-triggered
(C:ADR-0028); the recovery obligation is the "was this already dispatched/published?"
question, answered from the ledger plus a runtime run lookup — never from Issue
comments alone, which are deletable (R:§4).

## 7. Deployment View

- **Single-repo instance (floor).** One `config/project.yml`, one `config/gates.yml`,
  one GitHub credential scoped to the repo plus org-level `Projects:Write`, one
  Hermes profile, the unattended actor alias, branch protection excluding that
  identity, and a ledger beside the instance checkout. No external database required
  at this scale (R:§7).
- **First slice shape.** A scheduled CLI invocation, not an always-on service:
  ADR-0028 requires enumerability and idempotency, not a persistent process, and
  Hermes's recommended dispatcher topology is in-process with its gateway (the
  standalone daemon is deprecated) (R:§8). A persistent worker is a second-slice
  concern once event acceleration is added.
- **Scheduler reliability is load-bearing.** Actions `schedule:` is best-effort,
  default-branch-only, and auto-disabled after 60 days of inactivity per repository;
  the consumer must treat its absence as an outage, and a portfolio needs its own
  per-repo liveness check (C:ADR-0028; C:integrations/github-issues-projects.md §6;
  R:§7).
- **Portfolio instance.** Adds a registry (which repos/boards belong), an identity
  strategy (per-repo vs shared org identity distinguished by `session=`), and
  cross-repo schedule monitoring. A single org-level Projects v2 board can span
  repositories, but nothing gives a "which configured repo is this item" grouping
  for free (R:§7).
- **Topology.** Hermes kanban claim is atomic but single-host; there is no
  coordination primitive across hosts, stated as a non-goal, not a bug (R:§2, §4).
  If the engine ever runs more than one dispatcher, it must supply its own
  cross-host serialization (§11.3 OD5).
- **Secrets.** Instance-scoped, outside Git, held by the instance's infrastructure;
  worker environments must be constructed to contain none (§8.7).

## 8. Cross-Cutting Concepts

### 8.1 Identity and Attribution

Unattended actors use a distinct `user.email`, `mode=autonomous`, and a specific
`session=<job-name>` (never a generic `cron`) (C:ADR-0021). Commits carry
`Agent-Attribution:` trailers with actor, model, role, session; `user.name` carries
the model display form while the trailer carries the canonical provider-qualified id,
and the trailer is authoritative where they disagree (C:ADR-0029). `Co-authored-by:`
is for human collaboration; unattended actors never emit a human co-author trailer
(C:ADR-0036; C:ADR-0021).

### 8.2 Enforcement Honesty

Three labels, used per property: enforced (merge gate via branch protection actor
exclusion — the one substrate-enforced rule), detectable (Type immutability,
`question` suppression, comment retractability, schedule reliability), proposed
(everything this document designs: generation keys, ledger, publisher, dispatch).
A binding or doc claiming prevention where only detection exists is non-conforming
(C:ADR-0024; C:integrations/README.md §Detection over prevention).

### 8.3 Idempotency and Duplicate Suppression

Reconciliation must be idempotent; the engine's ledger is the primary key, the
activity record the secondary one (C:ADR-0028; R:§2). The target property is "at
most one outcome ever published per reservation," checked at the publish boundary;
**no exactly-once guarantee across two independently-failing systems is asserted or
assumed** (B:BRIEF). Whether the target itself holds under all interleavings is open
(§11.3 OD5).

### 8.4 Concurrency

GitHub serializes nothing per issue; consumers may impose Actions `concurrency:`
groups keyed on the issue number (C:integrations/github-issues-projects.md §6).
Runtime-side claim is atomic on one host only (R:§2). Cross-host concurrency is the
engine's problem (§7).

### 8.5 Error Handling

The outcome taxonomy drives behavior: human-decision parks vs operational failures vs
ambiguous partial writes are three distinct responses (R:§3 step 10, §4). Retry
policy is bounded with backoff and an escalation threshold; parks are total
suppression with a single sanctioned exit (C:ADR-0020).

### 8.6 Observability

Run outcome, log path, and a free-text summary live in the runtime's records, with no
cost/token/model field confirmed (R:§2, §8). A GitHub-only human cannot see runtime
failures unless the engine mirrors them onto the work item — a hard requirement, not
a nicety (R:addendum Q5). Cost has to be assembled by the engine from provider
billing joined to the ledger; neither platform provides it (R:§8).

### 8.7 Security and Threat Model

- The credential ceiling is real: any token able to write Projects fields can write
  any field (R:§5). Token scoping is defense-in-depth; branch protection actor
  exclusion is the actual merge-gate enforcement (R:§5).
- Worker isolation must be mechanical: no inherited credentials, bounded filesystem
  and network (B:BRIEF). Content-driven misbehavior inside an enabled toolset is the
  runtime's trusted-local-user model; the boundary is what tools the instance enabled,
  which is a configuration decision, not a platform guarantee (R:§5).
- The prompt-injection-to-authority path runs through work-item content; the only
  meaningful controls are tool enablement per profile and the publisher-only write
  path (§5.2).

### 8.8 Configuration

Instance-first: repos, board IDs, identities, schedules, budgets, ledger location,
and model policy resolve from the caller's repository root; safety-relevant missing
configuration fails closed, low-stakes checks skip visibly (C:ADR-0033 pattern, to be
extended by the product). No instance data inside the product tree (B:AGENTS).

### 8.9 Testing Strategy

Deterministic logic (generation minting, ledger transitions, outcome classification,
containment checks) is unit- and contract-tested against fixtures; platform
interactions are exercised against recorded shapes and isolated homes, not live
substrates (C:FS-0038's bats approach is precedent). Isolation guarantees for workers
require their own adversarial tests — an assertion of isolation that was never
tested is a proposed property.

## 9. Architectural Decisions

### 9.1 Inherited from the pinned contract (statuses at the pinned revision)

| Decision | Status | What it fixes for the engine |
| --- | --- | --- |
| C:ADR-0012 | accepted | Merge gate; identity verification per operation |
| C:ADR-0014 | accepted | Idempotency mechanism; unattended sessions are primaries |
| C:ADR-0018 / 0029 / 0036 | accepted | Attribution layers and their authority ordering |
| C:ADR-0019 / 0020 | accepted | Type immutability; Type-keyed gate; total `question` suppression |
| C:ADR-0021 | accepted | Unattended actor identity markers |
| C:ADR-0024 / 0028 | accepted | Capability model; reconciliation authoritative, events accelerate |
| C:ADR-0026 | accepted | Approval is a recorded act; what is not approval |
| C:ADR-0037 | accepted | Where binding executables live; no shipped trigger that mutates a work item |
| C:ADR-0039 | accepted | Runtime bindings are setup, not a dispatch API |
| C:ADR-0032 | **proposed** | Template/instance separation — direction only at this revision |
| C:FS-0018 | implemented | Lifecycle, origination paths, gates, stance format |
| C:FS-0038 | draft | Kanban candidate, explicitly not shipped; sync out of scope |

### 9.2 Candidate product decisions (none made; each wants its own ADR)

1. Dispatch API and its minimum contract (§11.3 OD6).
2. Generation-key representation and persistence (§11.3 OD4).
3. Ledger schema, store, concurrency, and recovery semantics (§11.3 OD5).
4. Evidence bundle contract and the minimum dispatch evidence policy (§11.3 OD2).
5. Worker isolation mechanism and its acceptance test.
6. Publisher concurrency and single-writer topology.
7. Model policy surface and review-independence rule for fallback (§11.3 OD7).

## 10. Quality Requirements

### 10.1 Overview

The goals in §1.2 are elaborated as scenarios. Measures are stated as observable outcomes, not aspirational adjectives; each scenario names the mechanism that carries it and its honesty label.

### 10.2 Quality Scenarios

| # | Stimulus | Response | Measure | Label |
| --- | --- | --- | --- | --- |
| QS1 | Schedule silently disabled (>60 days quiet repo) | Portfolio liveness check flags the missing run; treated as outage; drift corrected on next pass after restore | Zero silent divergence: alert before drift accumulates | Detectable (monitor proposed) |
| QS2 | Engine crashes between ledger reservation and dispatch | Restart honors in-flight reservation; no dispatch under the old attempt repeats the transition | No duplicate stance entries per transition | Proposed |
| QS3 | Two passes attempt publication for one reservation | Publish-boundary ledger check refuses the second; ambiguity parks | <= 1 draft PR per generation | Target; open under OD5 |
| QS4 | `gh pr create` times out; outcome unknown | Publisher enumerates existing publications; if found, record and stop; if not, park | Zero blind re-creations; park visible on the Issue | Proposed |
| QS5 | Worker compromised or malfunctioning | No GitHub write credential in the worker; publisher is the only writer | Violation impossible-by-isolation (demonstrated in tests), not by instruction | Proposed |
| QS6 | Human moves Phase while a run is in flight | Engine re-reads immediately before any write; aborts/replans on change | No write clobbers a human edit; residual race window documented | Detectable (no optimistic concurrency exists) |
| QS7 | Worker returns `needs_input` | Engine mirrors `question` onto the Issue within one reconciliation interval | GitHub-only reviewer sees the request without Hermes access | Proposed; requirement per R:addendum Q5 |
| QS8 | Preferred model unavailable; runtime falls back | Trailer records actual model; fallback is attributable; independence question is escalated, not silently accepted | Audit query returns actual model per action; fallback never silently breaks a review-seat independence rule | Detectable; resolution open (OD7; C:ADR-0023 interaction per R:§6) |

## 11. Risks and Technical Debt

### 11.1 Risks

- **No ledger exists and it blocks everything safety-relevant.** It should be
  designed before any dispatch code (R:§2, §1 conclusion).
- **Dispatch API undefined.** Neither governance layer defines the hand-off; the
  kanban binding is unshipped and ADR-0039 is narrower than a dispatch interface
  (R:addendum defect 2). Any first slice is a proposed mechanism.
- **No exactly-once, and even at-most-one is unproven.** Crash interleavings around
  reservation, publish, and acknowledgement can leave ambiguity; the design parks on
  ambiguity instead of claiming more (B:BRIEF; R:§2).
- **GitHub write semantics are weak:** last-write-wins fields, no conditional
  requests, deletable comments, best-effort webhooks (R:§4, §5).
- **Hermes is single-host for coordination**, a stated non-goal, not a fixable gap
  (R:§2, §4).
- **Scheduler fragility** (60-day auto-disable; per repository) makes the correctness
  guarantee's carrier the least reliable component (C:ADR-0028; R:§7).
- **Reconciler non-determinism** can oscillate; bounded by the autonomous gate and
  made visible in the activity record, not prevented (C:ADR-0028).
- **Cost and model-usage observability gaps** in the runtime's records must be joined
  externally (R:§8).
- **ADR-0032 is proposed**, so the instance-data discipline it supplies is direction
  here, not binding (C:ADR-0032 frontmatter).
- **Prompt-injection-to-authority** remains a content-vs-tool-enablement decision per
  profile (R:§5).

### 11.2 Technical Debt (accepted knowingly)

- A minimal dispatch mechanism will be built before its ADR exists, or the first
  slice cannot function.
- The portfolio liveness monitor duplicates a property (per-repo schedules) that
  neither platform surfaces.
- Ledger shape will likely need revision after the first real crash exercise.

### 11.3 Open Decisions Register

- **OD1 — First Type/action.** `task` exercises plumbing against the loosest gate;
  `feature` exercises the content path that matters long-term but stresses the
  approval UX first (R:§The three open product decisions #1; R:addendum Q4). Lean
  stated, not a closure.
- **OD2 — Minimum dispatch evidence.** Neither platform supplies an evidentiary
  gate; this is entirely the engine's policy, and it is the only thing between
  "approved in principle" and a running process (R:§The three #2).
- **OD3 — Autonomous Phase transitions.** How much of the room the gate already
  grants (`task`'s sanctioned In Progress -> In Review) should the engine use, for
  which Types (R:§The three #3).
- **OD4 — Stable intent/generation representation.** What exactly a generation key
  contains; how distinct spec, implementation, and follow-up intents map to distinct
  generations; how it is persisted (B:BRIEF).
- **OD5 — Durable ledger and publisher concurrency/recovery.** Store, schema, and
  whether at-most-one publication holds under all crash interleavings; single vs
  concurrent publishers; cross-host serialization if ever needed (B:BRIEF; R:§2).
- **OD6 — Dispatch API and instance configuration resolution.** The invocation
  interface (profile selection, evidence capture, timeout) and how repos, boards,
  ledgers, identities, and budgets are resolved, extending the caller-relative
  pattern (B:BRIEF; C:ADR-0033; C:ADR-0039).
- **OD7 — Model policy and fallback independence.** Where `(Type, Label,
  evidence) -> profile` policy lives; and whether a runtime fallback may break
  `ADR-0023`'s review-independence rule when the fallen-back model also holds a
  review seat (R:§6).
