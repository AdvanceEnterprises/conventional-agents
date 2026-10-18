---
type: architecture
id: ARC42
system: collective-agents
scope: system
stability: draft
owner: project maintainers
related_adrs:
  - ADR-0047
  - ADR-0048
tags: [architecture, workflow, governance]
created: 2026-09-26
updated: 2026-10-01
---
<!--
PARSING_HINTS:
- This document provides architectural context and boundaries.
- Prefer ADRs for explicit decisions and FSs for behavior and requirements.
- Candidate components and flows below are not implemented.
- Do not treat an architecture sketch as authorization to dispatch agents.
-->

> **Note — imported and deferred.** This arc42 describes the operations engine
> (the former `collective-agents` product). That engine is deferred per ADR-0046
> and will be re-extracted as its own package when built, not inside
> conventional-agents. References to its decisions and spec were renumbered on
> import: ADR-0001→ADR-0047, ADR-0002→ADR-0048, FS-0001→FS-0051.

# Architecture Overview (arc42): collective-agents

## 1. Introduction and Goals

### 1.1 Requirements Overview

collective-agents is a **reusable workflow execution product**. It applies the
pinned conventional-agents governance contract to a set of projects by
reconciling work, dispatching bounded agent runs, and reporting their outcomes.
It neither defines the governance contract nor runs an organization's portfolio
without instance configuration. Git is the durable source for code and governed
documents; GitHub and Hermes Agent are the intended *first* work-item and
execution integrations, not required dependencies of the product core.

This is an architecture proposal. The repository currently has a governance
bootstrap only: no reconciler, dispatcher, publisher, or adapter exists.
Implementation requires project ADRs where decisions are needed, followed by
approved FS/PLAN documents. Background evidence and unresolved questions are
recorded in [the research synthesis](research/architecture-evidence.md).

The human-selected **first pilot** is one `feature` work item with the bounded
action `draft-spec`: an explicit human authorization of that action and its
scope, an evidence-return-only worker, and a draft FS PR for human review.
The pilot leaves the work item's Phase at Approved and the FS at draft. This
selects the first architectural scenario, **not** a dispatch permission or
approval of an implementation specification. The comparison that informed it
is archived with the five candidates in
[`docs/research/model-drafts/`](research/model-drafts/).

The decisions this architecture motivated are now records, not drafts:
`ADR-0047` (authorized intent identity and the human grant) and `ADR-0048`
(worker/publisher credential separation) are **accepted**, and `FS-0051`
(the `feature` / `draft-spec` pilot) is **approved**. None is implemented:
`FS-0051`'s interface surface was declared by its 2026-10-01 amendment, and
that surface includes reserved paths, so its first `PLAN` carries its own
human-approval evidence. All three live under `docs/decisions/` and
`docs/specifications/`.

### 1.2 Quality Goals

1. **Authority preservation.** No worker or publisher can merge a PR or
   interpret a missing approval as permission to cross an autonomous gate.
2. **Recoverability.** Repeated and missed triggers converge on current state;
   ambiguous external writes pause rather than blindly duplicate proposals.
3. **Attributability.** An operator can relate an authorization, intent,
   attempts, selected and actual model, evidence, and publication.
4. **Portability.** Replacing the work-item substrate and agent runtime
   independently does not change the governed core's rules.
5. **Operability.** A human using the chosen work-item surface sees required
   decisions and failures; scheduling outages and exhausted budgets are visible.
6. **Adoptability.** One project can run with local instance configuration; a
   portfolio can manage its configuration in a separate instance repository.

These are goals, not claims that the present bootstrap satisfies them.

Candidate acceptance scenarios to refine into a feature spec:

<!-- markdownlint-disable MD013 -->
| Stimulus | Required observable response | Claim maturity |
| --- | --- | --- |
| Two passes find the same authorized action | One internal intent is selected; attempts do not mint authority | Proposed ledger invariant; not a remote-write guarantee |
| Human revokes the grant or parks the item during a run | Evidence is held; publisher does not intentionally publish under stale authority | Proposed; a reread does not eliminate the remote check-then-write race |
| PR creation succeeds but acknowledgement is lost | Discover the possible remote effect; unresolved ambiguity halts a second create | Proposed recovery target; fault and integration tests required |
| Worker can reach the host's `gh` login | Isolation check fails and unattended dispatch is disabled | Deployment requirement, not a Hermes-profile property |
| A draft proposal triggers CI with privileged secrets | Keep untrusted code outside privileged jobs before publishing | Separate CI threat model and validation required |
| Worker requests a human decision | Explain it on the work item with a preceding stance, then park; no further agent actions while parked | Upstream stance and `question` constraints, with local effect ordering to specify |
| Schedule is disabled or a model fallback changes reviewer identity | Operator sees a missing pass; selected and actual models remain distinguishable | Proposed monitoring and attestation, not existing engine behavior |
<!-- markdownlint-enable MD013 -->

### 1.3 Stakeholders

- **Project maintainers and human approvers:** review evidence and retain
  decisions and merges reserved to humans.
- **Instance operators:** choose repositories, substrates, runtimes, schedules,
  credentials, model policy, and budgets without forking the product.
- **Agent workers:** receive bounded tasks and return evidence without holding
  work-item publishing credentials.
- **Framework maintainers:** see gaps in the portable contract surfaced rather
  than silently redefined by this executor.

## 2. Constraints

- The pinned `vendor/conventional-agents/` defines the role contract,
  work-item lifecycle, Type-keyed autonomous gate, and agent attribution.
  Accepted ADR-0012 prohibits agent PR merges and requires GitHub identity
  verification before `gh` operations or `git push`.
- Accepted ADR-0024 requires a conforming work-item substrate to map all six
  capabilities: work item, Type, Phase, parked state, ordered attributable
  activity record, and enumerability. Only the GitHub binding is shipped in
  the pinned framework; its limitations must not be presented as enforcement.
- Accepted ADR-0028 makes level-triggered reconciliation the correctness
  path. Events can reduce latency but cannot replace enumeration and a
  reliably monitored scheduled/on-demand pass.
- Accepted ADR-0039 concerns **runtime setup**. It does not specify a
  programmatic agent-dispatch API. This product must design that interface.
- Keep template and instance information apart. ADR-0032 in the pinned
  framework is **proposed**, not an accepted mandate; the separation is also
  this product's explicit design direction. Its configuration mechanism and
  precedence still need a project decision.
- The first integrations must not quietly depend on a Hermes kanban work-item
  binding: its candidate is under the framework's `docs/proposals/`, not the
  shipped `integrations/` surface.

## 3. Context and Scope

### 3.1 Business Context

```text
conventional-agents (pinned contract)
          |
          v
collective-agents (reusable engine) <--- instance configuration
          |                              local file OR portfolio repo
          +-- work-item substrate -----> GitHub first
          +-- agent runtime -----------> Hermes first
          +-- durable Git artifacts ----> project repositories
          |
          +-- proposals/evidence ------> human approvers
```

conventional-agents and project repositories can themselves be projects in a
configured portfolio. collective-agents must also govern its own changes as a
consumer of the pinned framework. No special-case rules for either repository
belong in the engine.

### 3.2 Technical Context and Authority

- **Git** holds source, governed documents, and commit attribution.
- **The chosen work-item substrate** holds current Type, Phase, parked state,
  and activity. It may not provide an immutable history of every field edit.
- **The runtime** executes a bounded task and returns run evidence. Runtime
  task status is not the authoritative governance Phase.
- **The engine** owns correlation and recovery state: one authorized intent
  can have multiple run attempts and one canonical publication target.
- **The instance** owns deployment choices and credentials, whether supplied
  by a local configuration file or a separate portfolio instance repository.
  A repository of instance policy is optional, not a prerequisite for a
  single-project installation.

These ownership assignments describe the target boundary. Ledger storage,
retention, and conflict handling remain to be specified and tested.

## 4. Solution Strategy

Use a deterministic gate evaluation before model-driven work: enumerate
current work items, inspect Type/Phase/parked state and approval evidence,
then decide whether a narrowly scoped action is eligible. Do not let the
worker decide its own authority. Keep a work-item adapter separate from the
agent-runtime adapter; the engine's dispatch interface is still undefined.

For the selected `feature`/`draft-spec` pilot, a human-origin grant must name
the work item, the **draft-spec action**, and the permitted artifact/scope
generation. The publisher checks that grant and current state again before
writing. Type and Phase alone do not prove who approved this action and scope;
an issue-body edit or a worker recommendation cannot issue a new grant. The
grant's durable representation, actor verification, revocation handling, and
Git snapshot binding are still FS/ADR questions. These requirements narrow
the pilot without pretending GitHub's current field values provide immutable
approval history.

The agreed *design direction* for publication is **one canonical draft PR per
authorized action**, not per issue and not per Hermes run. Identify an intent
by project/work item, governed action, and explicit authorization/scope
generation. Retries share that intent; separate spec, implementation, or
follow-up actions may have distinct intents. An issue-body edit alone cannot
silently create a new authorization generation. Details of identity,
reservation, and generation transitions need an ADR and crash-point tests.

The agreed *credential direction* is **evidence-return-only workers**. A
separate publisher checks the current authorization and returned patch,
summary, and test evidence before writing to the work-item substrate or
creating a draft PR. The worker must not have usable GitHub write credentials;
this is a process/filesystem/network boundary, not a prompt instruction or
Hermes profile name. The publisher must never merge.

## 5. Building Block View

All blocks below are **candidates**, not shipped components:

- **Reconciler:** enumerates work and rechecks gates and prior intents;
  webhook notifications may accelerate a pass.
- **Authority evaluator and intent ledger:** validate a scoped human grant;
  correlate its generation, attempts, progress, and canonical proposal. An
  atomic intent reservation precedes dispatch-related external effects or
  worker invocation. A durable reservation alone does *not* prove exactly-once
  publication to GitHub. Record effect intent separately from an observed
  remote result so a lost acknowledgement remains `unknown`.
- **Dispatcher and runtime adapter:** issues a scoped run and captures the
  actual runtime/model used, including any fallback. ADR-0039 does not supply
  the invocation interface.
- **Evidence validator and publisher:** checks outputs against the authorized
  scope, base revision, changed paths, and check evidence; rechecks current
  authority, discovers existing publications, and writes through a
  constrained work-item/Git publisher identity. Reported worker test results
  are claims until verified against the exact artifact; untrusted checks must
  not execute in the credentialed publisher's security domain.
- **Work-item adapter:** maps the six framework capabilities and documents
  which are technically enforced versus detectable. GitHub is first.
- **Instance configuration resolver:** accepts a local config for a single
  project or a portfolio-owned config and registry. Live secrets are supplied
  through an instance-managed secret mechanism, not committed defaults.

No cross-system transaction exists merely because these blocks are separate.
An external write that succeeded but whose acknowledgement was lost is an
ambiguous state requiring discovery or human inspection, not an automatic
second write.

## 6. Runtime View

### 6.1 First pilot: authorized `feature` to draft FS PR (candidate)

1. A scheduled or on-demand pass enumerates work items. An event can
   accelerate it but does not establish eligibility. Read the `feature` Type,
   Approved Phase, `question` state, governing Git revision, scoped human
   grant, and any prior intent and proposal. An unset Type or missing grant
   stops dispatch; do not infer approval from the worker or an agent comment.
2. Check that the grant authorizes **draft-spec**, its scope and generation;
   resolving the exact record and actor proof is still a design dependency.
   Reuse the existing intent for retries or in-scope review revisions. An
   issue-body edit cannot silently mint another generation.
3. Atomically reserve the intent and attempt before any dispatch-related
   external write or runtime invocation. Prepare a separate record for each
   intended remote effect. If this reservation cannot be made, stop.
4. For a work-item action, place the required `agent-stance:` entry *before*
   that action. Read the activity record as the upstream idempotency signal;
   use the ledger for the stronger internal reservation and correlation.
   Neither a mutable comment nor the ledger alone resolves an ambiguous
   external write. An uncertain stance write must be discovered before a
   dependent action or dispatch, not repeated blindly.
5. Invoke an isolated Hermes worker through the still-to-be-designed runtime
   adapter. Pass a bounded FS-drafting scope and Git snapshot, not GitHub
   publishing credentials. A lost dispatch acknowledgement requires runtime
   discovery or a hold, not an automatic second launch.
6. Collect patch, summary, check results, actual model/provider, and their
   provenance. Validate the changed paths, base revision, draft FS status,
   absence of unapproved implementation/approval changes, and evidence tied
   to the exact proposed tree. The worker cannot declare its own tests
   independently verified.
7. The publisher rechecks the human grant, current Type/Phase/parked state,
   scope and Git context, and verifies its GitHub identity before any `gh`
   operation or push. A changed or revoked grant holds the evidence. This
   reread reduces but does not eliminate a later human-edit race.
8. Persist the intended publication effect, then discover matching branches
   and PRs, including closed ones, before creating anything. If an earlier
   write's outcome cannot be determined, hold it for inspection. A missing
   result from an incomplete search is not proof that no PR exists.
9. Publish at most the intended **draft FS proposal** under the still-valid
   grant; read back its repository, head/base, draft state and proposed tree,
   then record the observed effect. Link it to the work item without a
   closing keyword. Give work-item updates their own preceding stance and
   readback; a failed link does not justify another PR.
10. Leave the FS in draft and the feature's Phase at Approved. A human reviews
    the proposal and performs any merge. Neither PR creation nor a merged FS
    is blanket authorization for a distinct implementation intent.

An append-only record of attempts may contain more than one run. The goal of
one canonical publication per intent is **not yet an exactly-once guarantee**:
GitHub and the ledger cannot be atomically committed together. An ADR/FS must
specify the recoverable windows and the conditions that force manual review.

### 6.2 Human revision (candidate)

A reviewer requesting edits to an existing draft PR does not by itself
create another intent or PR. The publisher updates the canonical proposal
only when the governed scope permits it. A separate phase or an explicitly
authorized scope generation can create a new intent.

### 6.3 Failure and park behavior (candidate)

- For a genuine `needs_input`, record a preceding stance and a concrete
  human-facing question **before** applying `question`, with a preceding
  stance for the label action too. Once `question` is present, suppress agent
  work-item actions under ADR-0020; the exception for removing that label
  must follow its own accepted rule. A partial sequence requires recovery,
  not an unrecorded label write.
- A rate limit, crash, or exhausted retry budget is an operational hold. It
  becomes `question` only if a specific human decision is needed, not merely
  because automation failed. Surface the operator action without violating
  suppression on a parked item.
- Lost remote acknowledgements, conflicting proposals, a stale publisher,
  or incomplete discovery remain uncertain effects. Do not retry a create
  call or close another PR merely to make the ledger look consistent.
- For a future `task` path, the implemented FS-0018 success criterion
  explicitly calls for an In Progress task to move to In Review when its PR
  opens. The feature-spec pilot does not exercise that path. Task conformance
  and any other Phase automation need an explicit transition design; the
  pilot's no-Phase-write rule must not be generalized to silently contradict
  the upstream criterion.

## 7. Deployment View

The first deployment is expected to use a scheduled/on-demand process with
GitHub work items and a Hermes worker. Its exact scheduler, host topology,
ledger store, and Hermes invocation mechanism have **not** been selected.
Do not equate Hermes kanban claiming with a cross-host engine lock.

A worker runs in an isolated execution environment with only a scoped
workspace and necessary model-provider access. Do not forward GitHub tokens,
mount a `gh` login, SSH push key, Git credential helper, or publisher secret.
The separate publisher holds a narrowly scoped credential and is prevented
from merging by the host's protection rules. These are deployment
requirements to verify, not properties provided by a Hermes profile alone.
Before enabling unattended dispatch, test the effective process/container
environment and egress from **inside** the worker. Also assess what CI runs
on a publisher-authored proposal branch: a worker without credentials can
still propose code that later executes in a privileged workflow. Restrict
that CI trust boundary separately; path filters alone are not proof.

A local instance file suffices for one project; a portfolio may use its own
repository for registries and reviewable policy. Neither form can override
framework safety gates. A production instance must monitor that reconciliation
is actually running; a missed scheduled pass is an operational incident.

## 8. Cross-Cutting Concepts

- **Model selection:** the framework governs roles, independence, and
  attribution; this product evaluates capabilities, risk, and budget and
  records the selected *and actual* model; the instance chooses named models,
  provider credentials, fallback order, and budget limits. A fallback must
  not silently defeat an independent-review requirement.
- **Trust:** work-item text, generated patches, and agent recommendations
  are untrusted inputs. Credentials and approval evidence are evaluated
  outside the worker. Tool allowlists and secret redaction are defense in
  depth, not credential isolation. A publisher's ability to create a draft
  PR is not permission to mark it ready, approve it, or merge it.
- **Attribution:** correlate work item, intent, attempts, commit trailers,
  runtime evidence, and PR. The work-item activity record is human-visible,
  but editable comments cannot be the sole safety-critical idempotency key.
- **Observability:** surface human-required action on the chosen work-item
  surface, not only in Hermes logs; expose retries, scheduler health, and
  uncertain publications to the instance operator.
- **Testing:** simulate crash points around reservation, dispatch, response,
  external write, and acknowledgement. Exercise both allowed and forbidden
  transitions, missing approvals, duplicate runs, and credential isolation.
  Search for closed as well as open proposals; test that an incomplete search
  cannot license a second create and that a missing model receipt cannot
  establish an independent review.

## 9. Architectural Decisions

Accepted *upstream* constraints include ADR-0012, ADR-0014, ADR-0024,
ADR-0028, and ADR-0039 in the pinned conventional-agents submodule.
ADR-0032 is proposed upstream; the product/instance split here is our own
stated direction, not a claim that it is accepted upstream.

**Local decisions.** This repository now has two accepted ADRs recording the
architecture's load-bearing choices, and one approved spec:

- `ADR-0047` (accepted) — authorized intent identity and the human grant. The
  unit of deduplication and publication is the *authorized intent*: work item +
  governed action + explicit authorization/scope generation. Authority comes
  from a human grant, never from a work item's current Type or Phase.
- `ADR-0048` (accepted) — worker/publisher credential separation. Evidence-only
  workers hold no GitHub write credential; a separate publisher revalidates
  authority, writes at most one canonical draft proposal per intent, and never
  merges.
- `FS-0051` (approved, unimplemented) — the `feature` / `draft-spec` pilot's
  observable behavior and success criteria. Its interface surface was declared
  by the 2026-10-01 amendment; because that surface includes reserved paths
  (`.github/workflows/`, `package.json`), its first `PLAN` cannot self-approve
  and carries its own human-approval evidence.

Those acceptance conditions are recorded in each document's Validation section.
Neither ADR claims a platform guarantee: one canonical publication per intent is
a goal with a recovery path, not exactly-once.

**Open design questions** that remain for implementation, and are expected to
become their own ADRs or FSs rather than being settled by this architecture:
the grant's durable representation and verification; minimum evidence *format*
for dispatch; the dispatch API and runtime lookup; ledger, effect identity, and
lock topology; publisher discovery and recovery; future Type-specific Phase
transitions; and local versus portfolio configuration resolution. The
feature-spec pilot does not settle a future `task` path's upstream In Review
criterion.

## 10. Risks and Technical Debt

- **Duplicate effects:** a GitHub write can succeed just before a publisher
  crash. A ledger pre-check or outbox alone cannot guarantee exactly once;
  use a stable publication target and stop on unresolved ambiguity.
- **Stale authority:** a human may change Type or Phase during a run. A
  pre-publication re-read narrows but cannot eliminate check-then-write races
  on an API without a matching conditional update.
- **Unverifiable grant:** current Type/Phase alone cannot reconstruct the
  human actor, action, scope and revocation history. Missing evidence stops
  dispatch; a mutable body or model recommendation cannot become approval.
- **Credential leakage:** Hermes profile names and tool restrictions do not
  isolate host credentials. Verify OS/container mounts, environment, and
  egress for each worker deployment.
- **Privileged CI:** a credential-free worker's proposal may run code in CI
  with secrets. Validate the workflow and branch trust boundary separately.
- **Contract drift:** the pinned governance version may evolve; compatibility
  checks must fail closed rather than silently reinterpret changed gates.
- **Premature neutrality:** one GitHub/Hermes slice cannot prove every adapter
  seam. Validate the first slice end to end before promising other bindings.

## 11. Glossary

- **Authorized intent:** one governed action on a work item in an explicit
  scope/authorization generation; stable across retries.
- **Attempt:** one invocation or recovery pass under an intent; many attempts
  may exist without creating a new authorization.
- **Canonical publication:** the intended human-review artifact for that
  intent, such as one draft PR; not every log entry or activity comment.
- **Instance:** a concrete deployment and its policy/configuration, supplied
  by a local file or an optional portfolio repository.
