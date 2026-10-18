---
type: architecture
id: ARC42
system: collective-agents
scope: system
stability: draft
owner: ajoeofalltrades (template inherited; collective-agents owner TBD)
status: candidate draft (independent model pass)
related_adrs:
  - ADR-0024
  - ADR-0028
  - ADR-0019
  - ADR-0020
  - ADR-0021
  - ADR-0012
  - ADR-0014
  - ADR-0026
  - ADR-0039
related_specs:
  - FS-0018
  - FS-0038
related_research:
  - docs/research/engine-boundary-and-failure-modes.md (PR #1, commit 6d2a94b4)
tags: [architecture, arc42, candidate, independent-draft]
created: 2026-09-27
updated: 2026-09-27
---

<!--
PARSING_HINTS:
- This is an independent ARC42 candidate draft for collective-agents.
- It was produced by one model (minimax-m3 via ollama-cloud) without consulting
  any other model's draft or PR #1 / PR #2 ARC42.
- It treats accepted ADRs as binding constraints, ADR-0032 (proposed in the
  pinned revision) as a candidate, and FS-0038 (draft) as evidence of
  direction, not as binding.
- It distinguishes enforced vs detectable vs proposed properties and lists
  open decisions explicitly.
-->

# Architecture Overview (arc42) — collective-agents (independent candidate draft)

## Status and provenance

This document is an **independent candidate draft** for the
`AdvanceEnterprises/collective-agents` `docs/ARC42.md`. It was produced from
the bootstrap packet only:

- The repo `README.md` and `AGENTS.md`
- The vendored `vendor/conventional-agents` governance contract pinned at
  `94b784aa022b715bf7dad331a714f786620f961a` (see `git submodule status`)
- The framework template `vendor/conventional-agents/templates/core/architecture-arc42.md`
- Accepted ADRs (frontmatter verified): `ADR-0012`, `ADR-0014`, `ADR-0019`,
  `ADR-0020`, `ADR-0021`, `ADR-0026`, `ADR-0028`, `ADR-0029`, `ADR-0037`,
  `ADR-0039` — and the relevant specifications `FS-0018` (implemented) and
  `FS-0038` (draft)
- The research memo `docs/research/engine-boundary-and-failure-modes.md`
  (commit `6d2a94b44545be0aec072c45e3f8bfe83067ed38`), read as **evidence,
  not as a normative design**
- `vendor/conventional-agents/integrations/github-issues-projects.md` (the
  reference GitHub substrate binding)

It deliberately does **not** read PR #1's `docs/ARC42.md`, PR #2, or any
peer model's draft. It does not propose changes to the vendored framework,
commit, push, open a PR, or alter shared files.

The candidate architecture draft respects the agreed product direction
recorded in the bootstrap (`README.md`, `AGENTS.md`) and the frozen brief:
Git is durable artifact authority; GitHub work items and Hermes Agent
execution are the first integration pair but are not mandatory core
dependencies; work-item substrate and agent-runtime invocation are kept
separate; credentials never live in Git; one authorized action/scope
generation is the canonical proposal unit, stable across retries; human
approval and PR merge gates remain in force; this is **not** an
implementation, accepted ADR, or FS/PLAN.

ADR-0032 ("template and instance repository forms") is **`proposed`** in the
pinned revision. This draft treats its template/instance distinction as a
**candidate** rule and would not treat it as accepted without an ADR
promotion. FS-0038 is `draft`; it is read as evidence of where a Hermes
kanban binding is heading, not as a binding contract.

---

## 1. Introduction and Goals

### 1.1 Requirements Overview

collective-agents is a reusable governed workflow-execution product that
consumes `conventional-agents` as its governance contract (per
`ADR-0024`). It must implement four things and must not implement two more:

| # | Must implement (in scope) | Source of truth |
| - | ------------------------- | --------------- |
| 1 | Reconciliation against the work-item substrate — level-triggered, idempotent, scheduler-authoritative | `ADR-0028` |
| 2 | Agent dispatch and outcome recording that respect the three-axis schema, the autonomous gate, the parked-state suppression, and the unattended-actor identity | `FS-0018`, `ADR-0019`, `ADR-0020`, `ADR-0021` |
| 3 | Durable evidence and audit trail that survive Issue-comment deletion and partial GitHub writes | `FS-0018` audit section, `ADR-0018` attribution canon, research memo §2 |
| 4 | Substrate-neutral binding model so GitHub is the first integration, not the only one | `ADR-0024`, `FS-0038` (draft) |

| # | Must **not** implement (out of scope) | Source |
| - | -------------------------------------- | ------ |
| 5 | Replacing conventional-agents as a contract — collective-agents is a consumer, not a peer | `README.md` boundary |
| 6 | Bypassing the human approval and merge gates | `ADR-0012` (non-overridable) |

The product is **governed workflow execution**, not workflow definition. The
contract that defines what governs what is `conventional-agents`; this
repository is the engine that does the governed work.

### 1.2 Quality Goals

Prioritized, drawn from the framework's own quality table
(`vendor/conventional-agents/roles/ROLE_CONTRACT.md`, ARC42 §1.2) and
narrowed by the research memo's actual failure findings:

1. **Governance fidelity (top priority).** The engine never lowers its own
   gate. An unattended agent never modifies Type, never advances Phase past
   the Type-keyed checkpoint without an explicit, attributable human act,
   and never merges. If a property cannot be enforced technically, the
   candidate design states the detection mechanism and the property is
   bounded by it. *(enforced on merge branch via branch protection +
   `ADR-0012`; detectable-but-not-enforced elsewhere, per the binding
   contract.)*
2. **Level-triggered correctness.** A missed event is a latency cost, not
   a correctness loss. The schedule is authoritative; events only
   accelerate. *(enforced by the reconciliation loop being the
   single-pass-of-truth, per `ADR-0028`.)*
3. **Durable auditability.** Every agent action attributable to model +
   role + session survives Issue-comment deletion. *(enforced at the
   commit layer per `ADR-0018` / `ADR-0029`; **detectable but not
   enforced** at the activity-record layer, which is the GitHub Issue
   comment timeline.)*
4. **Substrate neutrality (with a working first binding).** A second
   consumer on a different substrate pays nothing the binding model did
   not already account for. *(enforced at the contract level by
   `ADR-0024`; the candidate must not couple implementation to a single
   substrate's API surface.)*
5. **Bounded blast radius of a misbehaving worker.** A compromised or
   malfunctioning worker cannot publish to GitHub on its own authority.
   *(**enforced** in this candidate only if the worker is evidence-return
   only; see §4 strategy and §6 flow.)*
6. **Human-visible required action.** A human watching only the GitHub
   Issue sees every required action. Hermes-side blocks are mirrored back
   onto the Issue, never silently held in a non-GitHub log.
   *(**enforced** by the engine's GitHub-mirror step; **detectable** that
   it happened because the Issue timeline records the action.)*
7. **Idempotent recovery.** Engine restart is harmless for re-evaluating
   desired state; the engine does not redispatch a work item it has
   already begun. *(**detectable but not enforced** by any GitHub-native
   primitive; the engine must build this itself.)*

Quality goals that the framework ranks above these (Tool Neutrality,
Submodule Friendliness, Enforceability — see `roles/ROLE_CONTRACT.md`) are
inherited and not relisted.

### 1.3 Stakeholders

- **Human maintainer (repository owner).** Authorizes Type, approves
  transitions past the autonomous gate, performs merge. Cares about
  governance fidelity and human-visible required action.
- **Unattended / scheduled agents.** Run the engine. Cares about clear
  gate semantics, unambiguous role-stance, and an authoritative trigger
  source.
- **Worker runtimes (e.g., Hermes Agent).** Receive evidence-return-only
  tasks. Cares about clear scope, no inherited GitHub write authority,
  and bounded retry on transient failures.
- **Work-item substrate (first: GitHub Issues + Projects v2).** Provides
  enumerability, append-mostly events, best-effort webhook delivery, and
  no field-level access control. Cares about realistic
  enforced-vs-conventional distinctions.
- **Future consumer repo operators (second adopters).** Cares about a
  substrate-neutral contract and an instance-configuration file that
  travels separately from the product.
- **Auditors (post-hoc).** Cares about a reconstruction of *why a run
  happened* that survives comment deletion, project-field history loss,
  and engine restart.

## 2. Constraints

### 2.1 Technical constraints

- **Git is the durable artifact authority.** Commits, trailers, and
  branch history are the only durable record GitHub guarantees. The
  Issue comment timeline is *convenient* but **not durable** — comments
  are editable and deletable (per
  `integrations/github-issues-projects.md` §5; reconfirmed in the
  research memo §2).
- **The vendored governance contract is read-only.** The
  `vendor/conventional-agents` submodule at
  `94b784aa022b715bf7dad331a714f786620f961a` cannot be edited from this
  repository. The candidate engine conforms to it; it does not extend
  it.
- **No Projects v2 per-field access control.** A token that can write
  any field can write every field, including `Issue Type`. Agents must
  not lower their own gate by editing Type, but the substrate cannot
  prevent that — only detect it (`integrations/github-issues-projects.md`
  §2; research memo §5).
- **GitHub Actions `schedule:` is best-effort and auto-disables after
  60 days of repository inactivity.** Engine correctness cannot depend
  on a single scheduler surviving forever
  (`integrations/github-issues-projects.md` §6; `ADR-0028`).
- **Webhook delivery is best-effort.** GitHub does not automatically
  redeliver failed deliveries by default; delivery IDs exist for dedup
  if the consumer redrives them (research memo §4).
- **Hermes kanban is single-host by design.** The Hermes docs explicitly
  state there is no cross-host coordination primitive (research memo §2).
  Cross-host dispatch coordination must be built by collective-agents,
  not assumed from Hermes.
- **Hermes exposes no per-task GitHub credential injection.** A worker
  invoking `gh` inherits ambient host-level `gh auth status` (research
  memo §5). This is the single largest reason the candidate architecture
  defaults to evidence-return-only workers (see §4 and §6).

### 2.2 Organizational constraints

- **Human approval and merge authority are not delegated by automated
  dispatch.** `AGENTS.md` Safety section; `ADR-0012` non-overridable
  gate.
- **Work-item substrate and agent-runtime bindings are separate.** The
  dispatch API and the GitHub binding are distinct surfaces; a Hermes
  kanban binding is one possible runtime, not a dependency of the
  GitHub binding (`AGENTS.md` Project Boundary; research memo §1
  emphasis).
- **Per `ADR-0032` (proposed, not accepted):** *if accepted,* a template
  repository carries no instance data; an instance repository owes no
  one a template. Repository registries, board IDs, identities,
  schedules, and credentials live in instance configuration. The
  candidate draft adopts this rule **conditionally** — it is implemented
  in the design, but it is not yet an accepted constraint in this
  pinned revision. An ADR promotion in `conventional-agents` (or a
  consumer-repo-level ADR) is required to make it binding here.
- **Credentials never live in Git.** A work item, FS, ADR, or repo file
  is never the right home for a credential (bootstrap `README.md`,
  `AGENTS.md`).
- **`gh auth status` is verified before every `gh` operation**, not
  once per session (`ADR-0012`, `integrations/github-issues-projects.md`
  §2).

### 2.3 Compliance / governance constraints

- **Conventional-agents precedence rules apply.** Lower-number wins; the
  project root `AGENTS.md` is project-level authority; universal gates
  in `roles/ROLE_CONTRACT.md` cannot be weakened; a project may
  strengthen, not weaken (`INTEGRATION.md` §3).
- **The non-overridable gates of `ADR-0012`** govern merge and identity
  verification in every mode and at every priority level. No source may
  weaken them.
- **The framework's `vendor/` directory is framework-internal.**
  `AGENTS.md` and runtime stubs in this repository must not reference
  `vendor/conventional-agents/vendor/...` paths (`ADR-0017`,
  `INTEGRATION.md` §4).
- **Approval is a recorded act.** `ADR-0026` requires a traceable
  approval marker (a commit trailer, an Issue comment with the agent's
  stance line, or an explicit `Approved-By:` trailer on the merge
  commit). "The human seemed happy" is not an approval.

## 3. Context and Scope

### 3.1 Business context

```text
       ┌─────────────────────────────────────────────┐
       │  Human maintainer                           │
       │  (authorizes Type, approves transitions,    │
       │   performs merge)                           │
       └─────────────────┬───────────────────────────┘
                         │ reads, comments, sets Type,
                         │ approves, merges
                         ▼
       ┌─────────────────────────────────────────────┐
       │  Work-item substrate (first: GitHub Issues  │
       │  + Projects v2; later: others per ADR-0024)│
       │  ─ durable artifacts: commits, trailers     │
       │  ─ best-effort: webhooks, schedules         │
       │  ─ current-only: Projects v2 field history  │
       └──────┬──────────────────────────┬───────────┘
              │ reads                    │ writes (PRs,
              │ enumerates               │ comments, field
              │                          │ updates)
              ▼                          ▲
       ┌─────────────────────────────────────────────┐
       │  collective-agents engine                   │
       │  ─ reconciliation loop (schedule + events) │
       │  ─ dispatch boundary (to workers)          │
       │  ─ outcome recorder (ledger + publisher)   │
       └──────┬──────────────────────────┬───────────┘
              │ dispatch                 │ evidence return
              │ (no GitHub credential    │ (patch, summary,
              │  inheritance)            │  test results)
              ▼                          ▲
       ┌─────────────────────────────────────────────┐
       │  Worker runtime (first: Hermes Agent)       │
       │  ─ executes within declared scope           │
       │  ─ returns evidence; no GitHub write        │
       └─────────────────────────────────────────────┘
```

External entities the engine integrates with in the first slice:

- **GitHub Issues / Projects v2 / REST + GraphQL APIs.** Best-effort,
  no per-field ACL, current-only field history, Projects v2 permissions
  granted at the resource level (per `permissions-required-for-fine-grained-personal-access-tokens`
  docs cited in research memo §5).
- **Hermes Agent** (or another worker runtime, per `ADR-0039`).
  Profile-scoped credentials, host-level `gh auth status` ambient
  unless deliberately stripped. The candidate architecture does **not**
  assume Hermes; it picks Hermes as the first concrete binding per the
  bootstrap `README.md`.
- **GitHub Actions `schedule:`** as the first correctness guarantee
  trigger (per `ADR-0028`), with webhook accelerators on the
  `issues`, `issue_comment`, `projects_v2_item`, `pull_request` events
  (per `integrations/github-issues-projects.md` §6).
- **Git.** Branch protection with the unattended-actor identity
  excluded from the push/merge allowlist is the only mechanism that
  technically enforces the merge gate. Branch protection's
  actor-exclusion is the actual lever; the `ADR-0021` "no merge
  permission" credential scoping is defense-in-depth, not the
  enforcement layer (research memo §5 corrective note on `ADR-0021`).

### 3.2 Technical context

- **Substrate contract.** The substrate must provide six capabilities
  per `ADR-0024` (work item, Type, Phase, parked state, activity
  record, enumerability). The GitHub binding maps these; three of six
  are conventional-with-detection (Type, parked state, activity record)
  and three are native (work item, Phase, enumerability), per
  `integrations/github-issues-projects.md` Conformance Summary.
- **Triggers.** A scheduler (first: Actions `schedule:`) carries
  correctness. Webhooks accelerate. The engine never relies on
  webhooks alone (`ADR-0028`).
- **Concurrency.** Per-Issue serialization is the consumer's job, not
  the substrate's. The first slice uses an Actions `concurrency:`
  group keyed on the Issue number (`integrations/github-issues-projects.md`
  §6).
- **Dispatch API.** Undefined at the time of this draft. The brief and
  the research memo are explicit: `ADR-0039` is *runtime setup* — anchor
  files, config, skills, hooks, MCP, commit identity — not a
  programmatic dispatch interface. The candidate architecture names
  the dispatch API as **undesigned**, an explicit open decision (§10).
- **Worker credential isolation.** A worker does **not** hold the
  GitHub write credential. Isolation is enforced by *not giving the
  worker the credential*, not by a profile name or an instruction.
- **Identification on the wire.** The unattended actor identity is a
  distinct `user.email` (`ADR-0021`), with `mode=autonomous` and
  `session=<job-name>` in every activity-record entry. The merge gate
  is enforced by branch protection excluding this identity from the
  push/merge allowlist.

## 4. Solution Strategy

The core architectural approach in seven bullets:

1. **Level-triggered reconciliation is authoritative.** The schedule
   fires on a fixed cadence. Webhooks may start a reconciliation pass
   early but never replace it. (`ADR-0028`.)
2. **One durable ledger per instance, written before any GitHub write.**
   The engine owns the key `(work_item_id, dispatch_attempt_id) →
   outcome`. The ledger is the primary idempotency key; the Issue
   comment timeline stays as the framework-mandated, human-visible
   record but is **not** the safety-critical one (research memo §2).
3. **Workers are evidence-return-only.** A worker returns patch,
   summary, and test results without a GitHub credential. A separate
   publisher process holds the credential, checks the ledger
   immediately before any GitHub write, and refuses to publish twice
   for the same reservation. The publisher never merges. (Research
   memo §5 recommendation; `ADR-0012`.)
4. **The guarantee is "at most one outcome is ever published per
   reservation," not "no duplicate agent run."** Duplicate dispatch is
   a cost; duplicate publication is a correctness loss. The ledger
   buys the cheaper, achievable guarantee at the publish boundary
   rather than claiming a stronger one no platform primitive
   provides (research memo §2).
5. **The GitHub Issue is the human-visible surface.** Every required
   action — including a Hermes-side block, a worker failure, and an
   ambiguous partial write — is mirrored onto the Issue so a human
   watching only GitHub sees it. The `question` label is reserved for
   genuine human-decision parks (`needs_input`), not applied to
   transient operational failures (`rate_limited`, `timed_out`, and
   diagnosable `crashed`); the latter follow a bounded retry with
   backoff and escalate to `question` only on budget exhaustion
   (research memo §3 step 10, correction).
6. **Type is human-mutable; agents flag.** The engine does not edit
   `Issue Type`. It posts an `agent-stance:` comment proposing the
   change if it believes the Type is wrong and stops (`ADR-0019`).
7. **Substrate and runtime are separate bindings.** The dispatch API
   does not know whether the substrate is GitHub; the GitHub binding
   does not know whether the runtime is Hermes. A second substrate
   binding (per `FS-0038` direction) and a second runtime binding
   (per `ADR-0039`) plug in without changing the engine
   (`integrations/github-issues-projects.md`, `FS-0038` Non-Goals).

The strategy is deliberately not a "fully distributed lock" or "exactly
once dispatch" — both are overclaims for the primitives GitHub and
Hermes actually provide. The strategy is the standard practical answer
to this class of problem: outbox at the publish boundary, with the
ledger consulted *immediately before* any GitHub write.

## 5. Building Block View

The engine decomposes into seven blocks. Boundaries are explicit; the
table names what each block owns, what it does **not** own, and which
contract it conforms to.

| # | Block | Responsibility | Does **not** own | Conforms to |
| - | ----- | -------------- | ---------------- | ----------- |
| 1 | **Reconciler** | Enumerate work items, evaluate desired state vs current state, decide whether dispatch is needed for this pass. The schedule fires it; events may accelerate it. | The actual GitHub write. The dispatch payload contents. | `ADR-0028` |
| 2 | **Ledger (engine-owned)** | Durable record of `(work_item_id, dispatch_attempt_id, state, outcome, gh_published_at?)`. Primary idempotency key. | The GitHub Issue timeline. The merge authority. | `ADR-0014` (superseded by engine-owned key for safety, per research memo §2); `ADR-0018` attribution canon at the commit layer. |
| 3 | **Gate Evaluator** | Given a work item's current state, return whether the autonomous gate permits the candidate action; which `agent-stance:` line to post if so; which outcome family the previous action was in (`needs_input`, transient, ambiguous). | The action itself. | `FS-0018` Autonomous Gate, `ADR-0019`, `ADR-0020`, `ADR-0021` |
| 4 | **Dispatcher** | Format the dispatch payload (substrate- and runtime-neutral), invoke the worker runtime, capture evidence. Does **not** hold the GitHub credential. | The publication step. | `ADR-0039` (runtime setup layer; the dispatch API itself is undesigned — see §10) |
| 5 | **Worker Runtime (first: Hermes profile)** | Execute within declared scope; return evidence (patch, summary, test results). Operates under profile-scoped credentials with no GitHub write. | The GitHub write. The next reservation. | `ADR-0014` scoped role; `ADR-0021` unattended actor markers |
| 6 | **Publisher** | Hold the GitHub write credential. Before any write: re-read current Type / Phase / labels; consult the ledger; refuse to publish twice for one reservation; post the `agent-stance:` comment after the ledger write; open a draft PR with the worker's evidence. **Never merges.** | Deciding what to dispatch. The merge. | `ADR-0012`, `ADR-0019`, `ADR-0020`, `ADR-0021`; research memo §2/§5 |
| 7 | **Observer / Mirror** | Map runtime signals to GitHub-Issue-visible labels and comments so a GitHub-only human sees every required action. Apply `question` for `needs_input` only (per §4 strategy). Surface cost / token / model-used fields by joining provider billing to the ledger row, because neither substrate records them (research memo §8). | The dispatch decision. | `ADR-0020` suppression rule; `FS-0018` agent-stance format |

Three boundaries are load-bearing and worth naming once:

- **Reconciler ↔ Dispatcher.** The reconciler produces a
  *reservation* (a ledger write); the dispatcher consumes a
  reservation, never produces one. The reconciler never sees worker
  output. This keeps the schedule-driven side deterministic enough to
  be reconciled again after a crash.
- **Dispatcher ↔ Worker.** The dispatcher is the only path through
  which a worker can be invoked. The worker is the only path through
  which evidence returns. There is no side-channel "worker writes to
  GitHub directly," because that path bypasses the ledger and the
  publisher.
- **Publisher ↔ GitHub.** The publisher is the only path through
  which the engine writes to GitHub. The ledger is consulted
  immediately before each write. This is the outbox boundary.

### 5.1 Key interfaces (sketch only — full interfaces are FS work)

- `Reconciler.tick(now)` → list of `(work_item, candidate_action)`:
  enumerates, evaluates gates, returns what *could* happen this pass.
- `Ledger.reserve(work_item_id, dispatch_attempt_id)` → reservation_id
  (atomic; uniqueness is the safety property).
- `Ledger.publish_attempted(reservation_id, gh_object_refs)` →
  committed (or refused if already published for this reservation).
- `Dispatcher.dispatch(reservation_id, payload)` → evidence bundle
  (no GitHub credential visible to the worker).
- `Publisher.publish(reservation_id, evidence)` → side effects on
  GitHub (Issue comment, draft PR, field update). Returns success only
  if all writes succeeded and the ledger now records
  `gh_published_at`.
- `Observer.mirror_to_github(signal)` → Issue label change or
  comment that makes the signal visible to a GitHub-only human.

The interfaces are deliberately described as shapes, not signatures;
signatures are FS work, not ARC42 work.

## 6. Runtime View

Two flows are written here: one end-to-end happy path and one failure
path that exercises every load-bearing boundary. Both flows are
**candidate**, against an undesigned dispatch API — the §10 open
decisions refine what is concrete.

### 6.1 Flow: a Type `task` work item from Approved to a draft PR

**Setup.** Human opens an Issue. Auto-add workflow places it on the
Projects board at `Status: Backlog`, `Issue Type` unset (per
`integrations/github-issues-projects.md` §3 and `FS-0011`).

**Step 1 — Human classifies.** A human sets `Issue Type = task` and
`Status = Approved`. Per `ADR-0026`, the human's Issue comment or
field change is the recorded approval act. Per `FS-0018`'s
Autonomous Gate table for Type `task`, an unattended agent may now
draft and open a PR autonomously; Phase `In Progress → In Review` on
PR-open is the one transition an unattended agent may perform past
the Type-keyed checkpoint, because the PR is the human-review surface
(`FS-0018` Autonomous Gate and Success Criteria).

**Step 2 — Reconciler tick.** A scheduled Actions workflow runs the
reconciler. It enumerates the board (Projects v2 GraphQL
`item-list`). For this Issue, it sees `Approved` + `task` + no
`question` label. The gate evaluator returns: dispatch is permitted
within the autonomous gate.

**Step 3 — Ledger reservation (safety-critical, first write).**
The reconciler writes a new row to the engine ledger with
`(work_item_id = owner/repo#123, dispatch_attempt_id = uuid(),
state = "reserved")`. **This write happens before any GitHub write.**
If the engine crashes between this step and step 4, no dispatch has
happened yet, and the next reconciler tick will see no
in-progress reservation and may safely re-evaluate. (This ordering is
a deliberate correction to an earlier draft of the research memo, per
research memo §3 step 5.)

**Step 4 — `agent-stance:` comment (framework-mandated, human-visible,
second write).** The publisher posts
`agent-stance: mode=autonomous; role=Implementer; model=<model-id>;
session=<job-name>; rationale=<one-line>`. The activity-record entry
is the human-visible trace; it is **not** the idempotency key.

**Step 5 — Dispatch (no GitHub credential).** The dispatcher formats
a runtime-neutral payload referencing the Issue URL, the `user.email`
alias of the unattended actor (`ADR-0021`), and the scope the worker
is allowed to act in. It invokes a Hermes worker under a profile whose
permissions do **not** include GitHub write. The worker has no
`GITHUB_TOKEN` env var, no host `gh auth status` write authority, no
network egress to GitHub beyond what the engine itself has. The
profile is configured so the `kanban_*` toolset is enabled for
dispatch receipt but `gh` is not on `PATH` for the worker (research
memo §5).

**Step 6 — Worker returns evidence.** The worker produces a patch
(diff), a free-text summary, and test results. These are returned to
the dispatcher over the runtime's evidence-return channel.

**Step 7 — Publisher validates and writes.** The publisher:
1. Re-reads current `Issue Type` and `Status` (research memo §4
   check-then-act race mitigation: GitHub has no optimistic
   concurrency on Issue field writes, so the only race-mitigation is
   re-read immediately before write).
2. Consults the ledger; confirms this `dispatch_attempt_id` has no
   `gh_published_at` recorded yet.
3. Creates a **draft** PR (`draft: true`), linked to the Issue by
   keyword (per research memo §1: GitHub PR↔Issue linkage is
   keyword-based or a manual Development link; auto-close-on-merge
   behavior on the manual link is undocumented in GitHub's docs and
   is a known documentation gap).
4. Records `gh_published_at` on the ledger row.
5. Returns success only after step 4 commits.

**Step 8 — Phase advancement (Type `task`, sanctioned).** Because
the work item is `Type: task` and the publisher opened a draft PR,
the engine advances `Status: Approved → In Progress → In Review`.
This is the one transition `FS-0018`'s success criteria explicitly
sanction for autonomous agents — the PR is the human-review surface.
For `Type: feature` and `Type: bug`, the publisher must **not**
advance past Approved autonomously; the human's act at the merge gate
or explicit approval is required (`FS-0018` Autonomous Gate;
`ADR-0019`).

**Step 9 — Human review and merge.** A human reviews the draft PR.
If approved, the human marks the PR ready-for-review and merges.
Branch protection's push/merge allowlist excludes the unattended
actor identity, so the unattended actor cannot merge regardless of
its token scopes (`ADR-0012`, research memo §5 correction).

**Step 10 — Status: Done.**` `Status: In Review → Done` is a
human-driven transition. The engine observes the merge event and may
mirror it via the observer block, but does not itself write `Status:
Done` without an attributable human act.

### 6.2 Flow: a Hermes-side `needs_input` block

This flow exercises the GitHub-mirror requirement (§4 strategy §5,
`ADR-0020`) and the `question`-label reservation.

1. Reconciler tick → ledger reservation → dispatch as in steps
   2–6 above.
2. The worker hits a genuine human-decision moment (e.g., "which of
   these two APIs should I extend?") and reports outcome
   `needs_input` with a clarifying question in the summary.
3. The publisher does **not** open a PR. The observer block applies
   the `question` label to the GitHub Issue and posts a comment with
   the agent-stance line and the worker's question. (This is the
   **only** outcome for which `question` is applied; transient
   `rate_limited` / `timed_out` / diagnosable `crashed` outcomes do
   **not** apply `question` — they follow a bounded retry with
   backoff and escalate to `question` only on budget exhaustion;
   research memo §3 step 10, correction.)
4. While `question` is present, the gate evaluator returns
   "suppress all Issue actions" for any future reconciler tick on
   this Issue (`ADR-0020` — the suppression is total, not scoped to
   the failed transition).
5. A human answers in an Issue comment.
6. The next reconciler tick sees `question` absent (either human
   removed it, or the agent removed it citing the human's resolving
   comment per `ADR-0020`'s escape), and may re-evaluate the
   dispatch decision.

### 6.3 Flow: transient `rate_limited` retry

1. Worker outcome is `rate_limited`. No PR is opened.
2. The observer block does **not** apply `question`. It posts a
   short Issue comment with the agent-stance line and the outcome.
3. The ledger row records `state = "rate_limited_retried"`.
4. The next reconciler tick within the bounded retry budget
   (instance-configured; default suggestion: 3 attempts with
   exponential backoff, no human in the loop) re-dispatches.
5. On budget exhaustion, the observer block applies `question` and
   a human is now needed.

### 6.4 Flow: an ambiguous partial write

A crash, a network partition, or a worker returning partial evidence
may leave the engine uncertain whether the GitHub side was updated.
Per the research memo §4:

1. On the next reconciler tick, the engine re-reads the GitHub side:
   - Is there a draft PR linked to this Issue? If yes, the publisher
     may have completed the publish before crashing on the ledger
     update.
2. Consults the ledger: does the reservation have
   `gh_published_at` set?
3. If `gh_published_at` is unset **and** a draft PR exists, the
   engine marks the reservation `state = "ambiguous_partial"` and
   applies `question` with a comment explaining the partial state.
   A human resolves.
4. If `gh_published_at` is set, the publish is recorded as complete
   and the engine proceeds normally.

The default for an ambiguous partial write is **park for a human**,
not blind retry and not silent resolution (research memo §3 step 10,
§4).

## 7. Deployment View

### 7.1 Environments

- **First-slice instance.** A single GitHub repository using GitHub
  Issues + Projects v2 as the work-item substrate and a single host
  running a scheduled Actions workflow as the reconciler trigger.
  Hermes Agent (or another worker runtime) runs on the same host as
  the dispatcher, under a profile whose credential scope does **not**
  include GitHub write.
- **Portfolio instance (later).** A separate instance-level
  configuration repository holding the registry (which repos / boards
  are in the portfolio), identity strategy (per-repo or shared
  unattended actor), cross-repo schedule monitoring (so a quiet
  repo's auto-disabled Actions schedule is noticed before drift
  accumulates, research memo §7), and shared conventions. This is
  where the `ADR-0016` / Pattern 4 consumer-conventions repo starts
  earning its cost; it is **not** mandatory at single-repo scale
  (research memo §7).

### 7.2 Deployment topology

- **Reconciler trigger.** GitHub Actions `schedule:` is the
  correctness trigger. Auto-disable after 60 days of repo inactivity
  is the documented foot-gun; the engine treats scheduler absence as
  an outage and mirrors that observation to an Issue label or a
  comment so a GitHub-only human sees it. Webhooks are accelerators,
  not the schedule.
- **Reconciler execution.** Scheduled workflow runs the reconciler on
  the default branch, in a runner with the engine binary and the
  ledger file accessible. The ledger file's location is instance
  configuration; the simplest first slice keeps it as a file in the
  runner's ephemeral storage, with a durable backup to the repo's
  own storage as a commits file (instance configuration).
- **Worker execution.** Workers run in-process with the dispatcher
  (Hermes's own recommended dispatcher topology, per research memo
  §8: standalone daemon mode is deprecated). The worker's process
  inherits no `GITHUB_TOKEN` and no `gh auth status` write authority;
  isolation is by *not providing the credential*, not by a profile
  name or an instruction.
- **Publisher execution.** The publisher runs in the same Actions
  workflow that triggered the reconciler. It holds the GitHub
  write credential as an Actions secret; `gh auth status` is
  verified before every `gh` operation per `ADR-0012`.

### 7.3 Secrets and configuration strategy

- **GitHub write credential.** Actions secret, scoped to the
  unattended actor's email alias (`ADR-0021`). Token scopes include
  `repo` and `project` per `INTEGRATION.md` Path A; the actual
  enforcement lever is branch protection's actor exclusion (research
  memo §5), not the token's scopes.
- **Worker runtime credentials.** Profile-scoped (`HERMES_HOME`
  config, profile `config.yaml`), per Hermes's documented model.
  The profile is configured so it cannot reach GitHub — `gh` is
  removed from `PATH` for the worker process, or the worker runs in
  a network namespace that denies GitHub egress (the precise
  mechanism is FS/PLAN work, not ARC42 work).
- **Instance configuration.** A separate file (single-repo) or
  separate instance-level repo (portfolio), per `ADR-0032`
  (proposed, treated as candidate) and `ADR-0016` Pattern 4.
  Configuration contents: project and board identifiers, the
  unattended actor email alias, the worker profile name, the
  schedule cadence, retry budgets, model policies. **Never** in
  Git: the credential itself. **Never** in a template repo:
  identifiers that only one instance owns.
- **Ledger location.** Instance configuration. At single-repo scale,
  a small SQLite file alongside the instance's checkout is plausibly
  sufficient (research memo §7). At portfolio scale, a portfolio-
  scoped durable store; the precise substrate is FS/PLAN work.

### 7.4 Branch protection (the only technically enforced governance)

Branch protection on `trunk`:

- Required reviews (Code Owners or equivalent).
- Push restriction: the unattended actor identity is **excluded**
  from the push/merge allowlist. (This is the actual lever; token
  scoping is defense-in-depth.)

This is the only governance rule GitHub can technically enforce, per
`integrations/github-issues-projects.md` §7. The engine's design
must not pretend otherwise.

## 8. Cross-Cutting Concepts

### 8.1 Error handling

Outcome families are distinct, and the engine treats them distinctly.
The research memo §3 step 10 correction is reflected throughout:

- **`needs_input`** — Apply `question` immediately; do not retry
  automatically; gate evaluator suppresses all future Issue actions
  on this Issue while the label is present (`ADR-0020`).
- **Transient (`rate_limited`, `timed_out`, diagnosable `crashed`)**
  — Bounded automatic retry with exponential backoff; do **not**
  apply `question` until the retry budget is exhausted; on
  exhaustion, escalate to `needs_input`.
- **`spawn_failed`** — Treat as transient; same retry policy.
- **`completed`** — Proceed to publisher per §6.1.
- **`blocked` / `reclaimed` / `stale`** — These are Hermes-side
  internal-state transitions. The observer mirrors them back onto
  the Issue as a comment + (where appropriate) a `question` apply
  if a human decision is required.
- **Ambiguous partial write** — Park for a human via `question`;
  do not retry blind; do not silently resolve (research memo §4).
- **Publisher GitHub-side failure** — The publisher is atomic per
  `reservation_id`: either all GitHub writes succeed and the ledger
  is updated, or the reservation is marked `state = "publish_failed"`
  and a bounded retry resumes from the ledger's last-known state.

### 8.2 Logging

- **Engine-owned structured log.** One record per
  `(work_item_id, dispatch_attempt_id, step, decision, evidence_ref)`.
  The log is a second source of truth alongside the ledger; it is
  not a substitute for the ledger's safety property.
- **Worker evidence.** Returned by the worker; stored alongside the
  ledger row it corresponds to.
- **GitHub-side audit.** The Issue timeline + the commit's
  `Agent-Attribution:` trailer are the framework-mandated record;
  they are convenient, not durable. The engine-owned log is the
  durable record (research memo §2).

### 8.3 Observability

| Signal | Where it lives | Visible to a GitHub-only reviewer? |
| ------ | -------------- | ----------------------------------- |
| Reconciliation pass outcome | Engine log | No — mirrored as an Issue comment on each tick's `state_changed` items |
| Run outcome (`completed` / `blocked` / etc.) | Hermes `task_runs` row + engine log | **No** unless explicitly mirrored onto the Issue (the §4 strategy §5 requirement) |
| Human-required action (`needs_input`) | Issue `question` label + agent-stance comment | Yes |
| Decision rationale | `agent-stance:` comment (deletable) + `Agent-Attribution:` commit trailer (durable) | Yes, both are GitHub-native |
| Cost / token / model-used | Engine log joined to ledger by `dispatch_attempt_id`; **not** natively on either platform (research memo §6/§8) | No — must be assembled by the engine and optionally mirrored as an Issue comment |
| Scheduled run health | Actions workflow run history | Yes (the GitHub Actions UI) |

The concrete observability gap to name: a GitHub-only human cannot
see a Hermes-side block or run failure unless the engine mirrors it.
This mirroring is the engine's responsibility, not a substrate
guarantee (research memo §8).

### 8.4 Security

- **Worker isolation is enforced, not configured.** A worker process
  inherits no `GITHUB_TOKEN`, has no host `gh auth status` write
  authority, and runs without network egress to GitHub. The blast
  radius of a compromised or malfunctioning worker is bounded to
  "produced evidence a human can review," not "wrote to GitHub."
- **Unattended actor identity.** Distinct `user.email`, mandatory
  `mode=autonomous`, mandatory `session=<job-name>` in every
  `agent-stance:` line (`ADR-0021`). The identity is branch-protected
  out of merge authority.
- **Branch protection is the enforcement lever.** Token scoping is
  defense-in-depth (research memo §5 corrective note on
  `ADR-0021`).
- **Pre-trust-of-content boundary.** Hermes's own docs are candid
  about this: the worker is trusted-local-user on a local
  filesystem; nothing in the kanban docs validates task-body
  content (research memo §5). The engine treats a worker run as
  trusted-local; the publisher does *not* treat the worker's
  evidence as a privileged instruction. The publisher validates
  the evidence against the reservation before publishing (e.g.,
  the patch is applied as-is, not as an instruction to the
  publisher).

### 8.5 Configuration

- **Instance configuration.** The smallest single-repo instance
  configuration is:
  - `project.yml` — project number/id/url/owner, Status field id
    and 5 option ids, Issue Type field id and 3 option ids.
  - `gates.yml` — `reserved_paths`, `exported_prefixes`,
    `ref_exempt` (per `config/gates.example.yml`).
  - One GitHub credential (Actions secret) plus one Hermes profile
    with `model.default` set.
  - The unattended actor's `user.email` alias.
  - Branch protection excluding that identity from
    push/merge allowlist.
- **Portfolio instance adds** (research memo §7): a registry of
  which repos / boards belong to the portfolio; an identity
  strategy (per-repo or shared org-level distinguished by
  `session=`); cross-repo schedule monitoring; one shared
  portfolio board (the binding supports it; "which configured repo
  does this item belong to" is a portfolio-level join).
- **`ADR-0032` is proposed, not accepted.** The template/instance
  rule is followed in this candidate but should not be treated as
  binding until the ADR is promoted.

### 8.6 Testing strategy

- **Unit tests** on the gate evaluator: every Type × every Phase
  combination returns the expected decision.
- **Integration tests** on the ledger: reservation
  atomicity; idempotent re-dispatch; publisher's
  refuse-second-iff-twice invariant.
- **Failure-mode drills** (research memo §4):
  - Reconciler crash before ledger write → no dispatch, no orphan.
  - Reconciler crash after ledger write, before GitHub write →
    next tick sees in-progress reservation, resumes safely.
  - Worker transient `rate_limited` → bounded retry, no
    `question`.
  - Worker `needs_input` → `question` applied immediately.
  - Publisher GitHub write succeeds, ledger `gh_published_at` write
    fails → next tick discovers ambiguous partial; parks for human.
  - Two reconciler ticks race on the same Issue → Actions
    `concurrency:` group on the Issue number serializes.
- **Audit reconstruction drill:** given an arbitrary past Issue,
  reconstruct "why this PR was opened" from the ledger + commit
  trailers + Issue comment timeline. The reconstructed record
  should not depend on a single GitHub-natively-deletable
  artifact (comment body) alone.
- **No webhook-only drift test:** an Issue deliberately left in an
  inconsistent state with no events fired is corrected by the next
  scheduled pass (`ADR-0028` validation signal).

## 9. Architectural Decisions

This candidate inherits the architecture decisions made by
`conventional-agents`; it does **not** re-litigate them. The
inheritance is recorded here so the next reader knows which ADRs
constrain the engine.

| Decision | Source | Status |
| -------- | ------ | ------ |
| Substrate-neutral core + bindings shipped alongside | `ADR-0024` | accepted |
| Level-triggered reconciliation; events are accelerator only | `ADR-0028` | accepted |
| Type is human-mutable only; autonomous gate keyed by Type | `ADR-0019` | accepted |
| `question` label suppresses all agent Issue actions | `ADR-0020` | accepted |
| Distinct email per unattended actor + `mode=autonomous` markers | `ADR-0021` | accepted |
| Merge gate non-overridable; identity verification non-overridable | `ADR-0012` | accepted |
| Approval is a recorded act (commit trailer or agent-stance) | `ADR-0026` | accepted |
| Background tasks operate under declared scoped role | `ADR-0014` | accepted |
| Activity-record idempotency as the framework's prescribed mechanism | `ADR-0014` | accepted but **superseded for safety** by the engine-owned ledger (research memo §2) |
| Runtime integrations are bindings under `integrations/runtimes/`; anchor files, config, skills, hooks, MCP | `ADR-0039` | accepted — but **does not define a dispatch API**; that surface is undesigned |
| Template vs instance repository forms | `ADR-0032` | **proposed**; treated as candidate in this draft |
| GitHub Issues + Projects v2 as the first substrate | `integrations/github-issues-projects.md` | reference binding, normative for first slice |
| Hermes kanban as a second substrate (six-capability mapping) | `FS-0038` | **draft**; direction evidence only |
| Sync between Hermes kanban and GitHub | `FS-0038` Non-Goals | out of scope |

Decisions the candidate architecture **makes itself** (and would
become candidate ADRs if accepted by a human reviewer):

- **D-CAND-1.** Workers are evidence-return-only; the publisher
  holds the GitHub credential and never merges. *(Candidate; see
  §4, §6.1, §8.4.)*
- **D-CAND-2.** The engine owns a durable ledger per instance; the
  ledger is the primary idempotency key, consulted immediately
  before any GitHub write. *(Candidate; see §4, §5 block 2,
  §8.1.)*
- **D-CAND-3.** The publish-side guarantee is "at most one outcome
  is ever published per reservation," not "no duplicate agent
  run." *(Candidate; see §4, §8.1.)*
- **D-CAND-4.** `question` is reserved for `needs_input`; transient
  failures follow a bounded retry policy before escalating.
  *(Candidate; see §4 strategy §5, §6.3.)*
- **D-CAND-5.** Ambiguous partial writes park for a human; never
  retry blind, never silently resolve. *(Candidate; see §6.4.)*
- **D-CAND-6.** Re-read current Type / Phase / labels immediately
  before any GitHub write; abort or replan if they changed.
  *(Candidate; see §6.1 step 7.)*

These are stated as candidate decisions because they are not yet
covered by accepted ADRs; promoting them to binding is a separate
human act.

## 10. Risks and Technical Debt

### 10.1 Risks

| # | Risk | Where it bites | Mitigation in this candidate |
| - | ---- | -------------- | ----------------------------- |
| R-1 | **No GitHub field-history API.** A work item's Type / Phase at time T is unrecoverable from GitHub later. | Any audit, any debugging of "when did this change." | Engine logs are the only durable record of phase transitions and field writes; Issue timeline + commit trailers supplement. |
| R-2 | **No cross-host dispatch coordination from Hermes.** A second reconciler on a second host can race the first. | Duplicate reservations or duplicate publishes. | The engine's own ledger is the cross-host serialization point if the engine ever runs more than one dispatcher (research memo §4). Per-host Actions `concurrency:` keyed on Issue number for the first slice. |
| R-3 | **`scheduled` is not a Hermes block-reason kind.** FS-0038's internal proposal claims `scheduled` is a non-human block kind; the real Hermes docs refute this — it is a separate `scheduled_at` field (research memo correction at end of §"Correction flagged for the vendored proposal"). | Confusion between "task delayed" and "task blocked." | The engine does not rely on `scheduled` as a block-reason kind; any such usage in `FS-0038`'s draft is corrected upstream before the engine reads it. |
| R-4 | **`question` suppression is total.** Applying `question` to a transient failure blocks all agent action until a human resolves it. | Operational noise; human-park queue saturation. | `question` is reserved for `needs_input` (§4 strategy §5); transient failures get bounded retry. |
| R-5 | **Worker holds ambient GitHub credentials via host `gh auth`.** | A compromised or malfunctioning worker has real write authority. | Worker is evidence-return-only; isolation is by *not providing the credential* (§8.4). |
| R-6 | **`ADR-0023` independence can silently break under fallback.** If a profile's preferred model fails over via Hermes's `fallback_model` and that model was also assigned as an independent reviewer, the independence requirement may silently collapse (research memo §6). | Review-board integrity in unattended single-work-item dispatches. | Not yet relevant to the first slice (no review board yet); flagged as a candidate ADR when review rounds arrive. |
| R-7 | **60-day scheduler auto-disable on a quiet repo.** | The reconciliation loop silently stops. | Engine treats scheduler absence as an outage and mirrors it onto the Issue; portfolio instance adds cross-repo schedule monitoring. |
| R-8 | **No cost / token / model-used field on `task_runs`.** | Cost attribution is invisible to the engine. | Engine joins provider billing signal to ledger by `dispatch_attempt_id`; no substrate gives this for free. |
| R-9 | **Auto-close-on-merge for manual Development-link PR↔Issue binding is undocumented by GitHub.** | A PR may merge without auto-closing the linked Issue. | The engine re-reads Issue state on every reconciler tick; it does not depend on auto-close behavior. |
| R-10 | **Webhook delivery is best-effort, no automatic redelivery.** | Missed events. | Reconciler is level-triggered; events only accelerate. |
| R-11 | **Oscillation: agent reconcilers are non-deterministic.** Same state in can produce different action out; two passes may undo each other (`ADR-0028` "non-determinism is bounded, not eliminated"). | Visible: same transition applied and reversed on the timeline. | Bounded by the autonomous gate; visible via the agent-stance timeline. Watched for; ADR revisited if observed. |
| R-12 | **Engine never built → framework risk.** Like `packs/` and `integrations/` before, "arc42 may map building blocks" can become a never-realized plan. | Drift between the candidate and a working engine. | The candidate is written to be testable; the §8.6 testing strategy and §10.2 open-decision list exist precisely so the gap from arc42 to engine is concrete. |

### 10.2 Open decisions (explicit)

These are the decisions the brief and the research memo both
flagged as open. The candidate architecture does **not** resolve them;
they are for a human to decide and an ADR to record.

| # | Open decision | What choosing either way costs |
| - | ------------- | ------------------------------ |
| O-1 | **First Type / action category.** Start with `task` (the loosest autonomous-gate checkpoint; cheaper place to find design mistakes) or `feature` (exercises the FS-drafting content path the product cares about long-term). | `task` stresses plumbing against the lightest gate; `feature` stresses the human-approval UX before plumbing is proven. Both legitimate for different reasons (research memo final §"Positions on the review's five follow-up questions" Q4). |
| O-2 | **Minimum evidence required before dispatch.** A gate entirely the engine defines; neither substrate provides one. | Higher bars slow the autonomous gate; lower bars make the blast-radius of a misbehaving worker the relevant risk. |
| O-3 | **How much autonomous Phase movement the engine should use within the room the gate already grants.** The gate permits `task` to advance on PR-open; does the engine take only that, or also use other room? | Wider use means less human load, narrower use means more human checkpoints. `FS-0018`'s success criteria sanction only the `task` PR-open transition today. |
| O-4 | **Stable intent / generation representation.** "One authorized action/scope generation is the unit of a canonical proposal." A changed Issue description alone does not silently authorize a new generation. | Need a content-addressed representation of {spec, scope, intent} that survives rewording but flags real change. This is FS/PLAN work; the candidate architecture requires it but does not specify the representation. |
| O-5 | **Durable ledger location and concurrency / recovery model.** SQLite file alongside the instance checkout (research memo §7) is the floor; portfolio scale needs more. | Single-file is simple; a portfolio store adds cross-instance consistency concerns. The exact concurrency / recovery model for the publisher is FS work. |
| O-6 | **Dispatch API shape.** `ADR-0039` covers runtime *setup* (anchor files, config, skills, hooks, MCP, commit identity, gate-script wiring) — not a programmatic dispatch API. The dispatch API is undesigned. | An API that takes a reservation and returns evidence is a candidate; the exact surface is FS work. |
| O-7 | **Instance configuration resolution.** A single file is the floor; a separate instance-level repo (Pattern 4 / `ADR-0016`) becomes useful at portfolio scale. Per-repo identity strategy (one unattended actor per repo, or shared org-level distinguished by `session=`) is an instance choice. | Simpler instance config vs. multi-repo governance at scale. |
| O-8 | **Model-selection policy expression.** Neither substrate provides a risk-aware per-work-item model policy (research memo §6). The natural expression given what exists is `engine maps (Type, Label, evidence-so-far) → which Hermes profile to assign` at dispatch time. | The engine owns the policy; the runtime owns the mechanism. This is consistent with the "model identities, fallback, budgets are instance policy; mechanism belongs in product" agreement in the brief. |
| O-9 | **Auto-classification of Type on Path 1.** `FS-0018`'s Path 1 says the first agent action is to *propose* `Type=feature` via an `agent-stance:` comment and stop; the human then sets Type. The candidate architecture follows this. Whether the engine should *also* propose `Type=task` or `Type=bug` based on body heuristics is an open policy choice. | Faster triage vs. lower false-positive rate. The conservative default (propose only on explicit cues; default `feature`) is the safer first slice. |
| O-10 | **`ADR-0032` adoption in this candidate.** The template/instance rule is followed in this candidate design but is `proposed` in the pinned revision. | Following it as a candidate is cheap; treating it as binding without an ADR promotion in `conventional-agents` (or a consumer-repo ADR) is the riskier move. |
| O-11 | **Whether the engine ever mutates a Phase field autonomously for `Type: bug`.** `FS-0018` says a `bug`'s autonomous agent may investigate and propose; the fix PR requires human authorization. The candidate architecture preserves this. Whether the engine should additionally surface a "fix proposed" Phase intermediate (e.g., `Approved → In Progress` to mean "investigation underway, not yet a fix") is open. | Cleaner state visibility vs. Phase proliferation. |
| O-12 | **Hermes kanban binding status.** `FS-0038` is draft; the engine's first-slice design is GitHub-only. Whether to begin a Hermes kanban binding alongside the GitHub binding or after the first slice ships is a portfolio decision. | Two bindings in flight costs coordination; one at a time costs latency to a second-adopter story. |

### 10.3 Technical debt the candidate carries

- **Two sources of truth for "what happened"**: the Issue timeline
  (deletable) and the ledger + commit trailers (durable). The
  candidate reduces the dependency on the timeline but does not
  eliminate it. The framework's `ADR-0014` activity-record idempotency
  remains the framework-mandated record; the engine's ledger is the
  engine-owned safety record. This is acceptable but not zero debt.
- **Mirroring required for human visibility** (§4 strategy §5,
  §8.3). Every required action must be reflected on the Issue for a
  GitHub-only human to see it. The engine pays this mirroring cost on
  every dispatch. It is a known cost, not an accident.
- **Per-substrate binding maintenance.** The candidate treats substrate
  bindings as a real surface area. Two bindings in flight
  (`integrations/github-issues-projects.md`, draft `FS-0038`) is the
  minimum useful spread; both must be kept honest about enforced vs.
  conventional properties (§3.1, §10.1 R-1, R-9).
- **First-slice scope discipline.** The brief and the research memo
  are explicit that no engine exists yet and this is a candidate
  architecture draft, not an FS/PLAN/ADR. The candidate resists the
  pull to widen scope (no review-board integration in the first
  slice; no consensus-mode in the first slice; no cross-host
  dispatch in the first slice).

## 11. Glossary

| Term | Meaning | Source |
| ---- | ------- | ------ |
| **Action / scope generation** | The unit of canonical authorization — typically one draft PR — stable across retries. | Brief |
| **Activity record** | The work-item-level timeline of agent actions. On GitHub: the Issue comment timeline. Deletable. | `FS-0018`; `integrations/github-issues-projects.md` §5 |
| **Agent-Attribution:** | Commit trailer recording actor, model, role, session. The durable attribution layer. | `ADR-0018`, `ADR-0029`, `ADR-0036` |
| **agent-stance:** | `agent-stance: mode=...; role=...; model=...; session=...; rationale=...` — the work-item-level equivalent of agent stance. | `FS-0018` |
| **Approved** | Phase value. The work item is authorized for work. | `FS-0018` Axis 3 |
| **Autonomous gate** | An unattended agent may not advance Phase past the Type-keyed checkpoint without human authorization. | `ADR-0019` |
| **Backlog** | Phase value. Triaged, no work started. | `FS-0018` Axis 3 |
| **Binding** | A substrate's normative mapping onto the six `ADR-0024` capabilities. GitHub binding is the first; Hermes kanban binding is in draft. | `ADR-0024`, `FS-0038` |
| **Branch protection** | GitHub mechanism that excludes identities from the push/merge allowlist. The actual enforcement lever for `ADR-0012`. | `integrations/github-issues-projects.md` §7; research memo §5 |
| **Capacity / capability** | Six substrate capabilities: work item, Type, Phase, parked state, activity record, enumerability. | `ADR-0024` |
| **Dispatch attempt** | One unit of work sent to a worker runtime, identified by a `dispatch_attempt_id` and tied to one ledger row. | Candidate; §5 block 2 |
| **Dispatch API** | The undesigned programmatic surface by which the engine hands a reservation to a worker runtime. | Open decision O-6 |
| **Done** | Phase value. Closed — merged or abandoned. | `FS-0018` Axis 3 |
| **Effect / proven** | A property the platform technically prevents the alternative of. | Research memo header definition |
| **Effect / detected** (or *conventional*) | A property the platform only makes a violation visible after the fact. | Research memo header definition |
| **Engine-owned ledger** | The candidate architecture's per-instance durable store of `(work_item_id, dispatch_attempt_id, state, outcome, gh_published_at?)`. Primary idempotency key. | Candidate; §5 block 2 |
| **FS** | Feature spec — the contract for a piece of governed work. | `workflows/document-lifecycle.md` |
| **In Progress** | Phase value. Active work; expect commits and PRs. | `FS-0018` Axis 3 |
| **In Review** | Phase value. A PR is open against this work item. | `FS-0018` Axis 3 |
| **Issue Type** | GitHub Projects v2 single-select field with options `feature`, `bug`, `task`. Keys the autonomous gate. | `integrations/github-issues-projects.md` §2 |
| **Instance configuration** | The non-product data describing one deployment: project / board identifiers, identities, schedules, credentials, model policy. | `ADR-0032` (proposed), treated as candidate |
| **Level-triggered reconciliation** | Reconcile state on a schedule; missed events cost latency, not correctness. | `ADR-0028` |
| **Merge gate** | The non-overridable rule that no agent may merge. Enforced by branch protection. | `ADR-0012` |
| **Mode (autonomous / hybrid / interactive)** | A session-level marker. Autonomous agents run without a human in the loop. | `ADR-0021`, `ADR-0022` |
| **`needs_input`** | Outcome family: a genuine human decision is required. Apply `question` immediately. | Research memo §3 step 10 |
| **Outbox pattern** | The standard practical pattern for "at most one outcome published": consult the durable store immediately before the external write. | Research memo §2 |
| **Parked state / `question`** | While `question` is present on an Issue, agents perform no Issue actions. Total suppression. | `ADR-0020` |
| **Publisher** | The engine's GitHub-write-bearing process; consults the ledger immediately before any GitHub write; never merges. | Candidate; §5 block 6 |
| **Questionable action** | An action that should require a human decision. Reserve `question` for these. | Candidate; §4 strategy §5 |
| **Reservation** | A ledger row recording `(work_item_id, dispatch_attempt_id, state = "reserved")`. The safety-critical write that precedes any GitHub write. | Candidate; §6.1 step 3 |
| **Substrate** | The work-item tracking platform. First: GitHub Issues + Projects v2. | `ADR-0024` |
| **Transient outcome** | `rate_limited`, `timed_out`, and diagnosable `crashed`. Bounded retry, do **not** apply `question` until budget exhausted. | Research memo §3 step 10 correction |
| **Type (axis)** | `feature`, `bug`, or `task`. Human-mutable only. | `FS-0018` Axis 1; `ADR-0019` |
| **Unattended actor identity** | Distinct `user.email` carrying `mode=autonomous` and `session=<job-name>` in every action. | `ADR-0021` |
| **Work item** | The brief; the entry point for all governed work. | `FS-0018`; `ADR-0024` |

---

## Sources cited (unnumbered appendix)

### Internal (vendored, read directly)

- `vendor/conventional-agents/INTEGRATION.md` (Precedence Rules,
  Pattern 4, template/instance rule, cron actor provisioning)
- `vendor/conventional-agents/integrations/github-issues-projects.md`
  (Conformance Summary, §2 Type enforcement, §3 Phase, §4 parked
  state, §5 activity record, §6 triggers, §7 unenforceability
  table)
- `vendor/conventional-agents/templates/core/architecture-arc42.md`
  (template shape inherited)
- `vendor/conventional-agents/docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md`
  (three-axis schema, three origination paths, agent-stance format,
  Autonomous Gate, success criteria, edge cases)
- `vendor/conventional-agents/docs/specifications/FS-0038-hermes-kanban-substrate-binding.md`
  (status: draft; read as evidence of direction; Non-Goals used
  directly)
- `vendor/conventional-agents/docs/decisions/ADR-0012-non-overridable-gates.md` (status: accepted)
- `vendor/conventional-agents/docs/decisions/ADR-0014-background-task-governance.md` (status: accepted)
- `vendor/conventional-agents/docs/decisions/ADR-0019-issue-type-immutability-and-autonomous-gate.md` (status: accepted)
- `vendor/conventional-agents/docs/decisions/ADR-0020-question-label-suppression.md` (status: accepted)
- `vendor/conventional-agents/docs/decisions/ADR-0021-cron-actor-identity.md` (status: accepted)
- `vendor/conventional-agents/docs/decisions/ADR-0026-approval-is-a-recorded-act.md` (status: accepted)
- `vendor/conventional-agents/docs/decisions/ADR-0028-level-triggered-reconciliation.md` (status: accepted)
- `vendor/conventional-agents/docs/decisions/ADR-0032-template-and-instance-repository-forms.md` (status: **proposed** — treated as candidate in this draft)
- `vendor/conventional-agents/docs/decisions/ADR-0039-agent-runtime-integration-bindings.md` (status: accepted; runtime-setup scope confirmed)

### Internal (research-source, read directly)

- `docs/research/engine-boundary-and-failure-modes.md` (PR #1, commit `6d2a94b44545be0aec072c45e3f8bfe83067ed38`) — read as evidence, not as normative design. Specifically relied on for §2 (durable ledger + publish-boundary outbox), §3 step 5 (ledger-before-comment ordering), §3 step 10 (outcome families — `needs_input` vs transient vs ambiguous), §4 (failure semantics table), §5 (correction that branch protection is the actual merge-gate lever, not token scopes), §6 (model policy expression), §7 (instance configuration floor and portfolio additions), §8 (the GitHub-only-human observability gap), and the corrections for `FS-0038` proposal inaccuracies.
- `README.md`, `AGENTS.md` of `AdvanceEnterprises/collective-agents` (the bootstrap's stated boundary and product direction)

### External (research memo only, not independently re-verified by this draft)

All GitHub and Hermes citations are reproduced from the research
memorably rather than re-fetched here. See the memo's `Sources`
section for the full URL list (retrieved 2026-09-26): webhooks
(about-webhooks, handling-failed-webhook-deliveries), Actions
schedule event docs, Projects GraphQL reference, REST API best
practices (conditional requests), REST and GraphQL rate limits,
GitHub Apps rate limits, pull request creation (`draft`), linking a
pull request to an issue, fine-grained PAT permissions, protected
branches, `projects_v2_item` webhook payload + GitHub Blog
changelog (2024-06-27), Actions concurrency control, the public
Hermes Agent repo metadata, Hermes kanban docs, credential-pools,
provider-routing, and SQLite WAL/locking references.