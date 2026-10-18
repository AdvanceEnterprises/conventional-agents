---
type: architecture
id: ARC42
system: collective-agents
scope: system
stability: evolving
status: draft
owner: collective-agents maintainers
related_adrs: []
tags: [architecture, arc42, candidate, governed-execution]
created: 2026-09-27
updated: 2026-09-27
---

# collective-agents: Architecture Overview (arc42)

This is an independent candidate architecture, not an accepted decision, implementation specification, or description of a running engine.
The repository is a governance bootstrap; none of the product components or safeguards proposed below is implemented. [B; P]
The drafting model is `gpt-6-astra`, invoked through provider `openai-codex`.
Only the frozen brief, bootstrap README and AGENTS, pinned framework template and relevant rules, and the specified research memo informed this draft.
No existing collective-agents ARC42 or peer draft was inspected; references to those artifacts inside the permitted memo were not followed.
The pinned template actually ends at section 10; this draft preserves its ten headings and adds section 11 for terminology and source references. [T]
Framework citations resolve to `94b784aa022b715bf7dad331a714f786620f961a`; research citations resolve to memo commit `6d2a94b44545be0aec072c45e3f8bfe83067ed38`.
External platform findings are reported from that memo, not independently reverified here; uncertainty and contradictory claims are retained where consequential.

## 1. Introduction and Goals

### 1.1 Requirements Overview

collective-agents turns a currently authorized piece of governed work into a reviewable proposal, while preserving the distinction between permission, execution, and publication.
Its useful output is not simply a completed agent session: it is an attributable artifact with enough evidence for a human to decide whether it should enter durable project history.
conventional-agents supplies the contract; collective-agents supplies the repeatable execution mechanism; an instance supplies deployment facts and policy choices. [P]

The principal use cases are:

- Enumerate work items and explain why each item is eligible, held, already served, or operationally unavailable.
- Reserve one authorized action/scope generation before requesting agent work, and associate every retry with that same intent.
- Invoke a bounded worker under a declared role and artifact scope, receiving evidence rather than delegating publication authority.
- Validate that evidence against both the original scope and current authority, then create or update a canonical draft proposal.
- Recover after missed triggers, duplicate deliveries, lost acknowledgements, stale workers, and partial publication without silently inventing new authorization.
- Surface genuine human decisions on the work-item substrate, so a reviewer need not inspect runtime-specific logs to discover a block.

One work item may legitimately produce a specification proposal, an implementation proposal, and a later corrective proposal.
Those are distinct authorized actions, not a reason to create a new proposal on every scheduler tick or worker retry. [B]
An initial product slice need not support all origination paths, every Type, collaboration rounds, or cross-repository dependencies.
Supporting a portfolio means operating several repository-local workflows; it does not make one Issue a cross-repository transaction. [F, Out of Scope]

### 1.2 Quality Goals

| Priority | Goal | Architectural consequence |
| --- | --- | --- |
| 1 | Preserve human authority | Eligibility and publication both require scoped evidence; no merge operation exists in the product interface. |
| 2 | Recover without duplicate proposals | Durable intent identity, explicit uncertain states, remote discovery, and conservative replay precede availability. |
| 3 | Bound worker compromise | Workers cannot obtain publisher credentials, host authority, or a privileged execution callback. |
| 4 | Explain every effect | Join authorization, policy, attempts, actual models, evidence, commits, and remote objects by durable references. |
| 5 | Remain portable and adoptable | Keep work-item and runtime adapters independent; permit one configured host before requiring distributed infrastructure. |

These priorities resolve a deliberate tradeoff: an unexplained pause is undesirable, but a well-explained pause is preferable to an unauthorized or duplicate publication.
Section 8 translates the goals into falsifiable candidate quality scenarios rather than claiming service levels already achieved.

### 1.3 Stakeholders

- Human maintainers control Type, approvals, scope changes, and merge; they need a clear proposal and a precise next action.
- Instance operators control identity, schedules, model policy, resource limits, secrets, and recovery; they need observable failure and bounded operational complexity.
- Framework maintainers need the product to consume governance without modifying the framework into an orchestrator.
- Adapter maintainers need small, explicit contracts that expose missing capabilities instead of emulating stronger guarantees silently.
- Auditors and contributors need the reason an action occurred, including the difference between a requested model and the model that actually supplied its content.

## 2. Constraints

### 2.1 Governance and product constraints

Agents do not merge PRs or push to the default branch, and `gh auth status` is required before each `gh` operation or Git push. [G; A12]
A separate publisher is still automation: separating credentials does not confer human approval or create an exception to the merge gate.
A worker's scope cannot exceed its parent's authority; the dispatch declaration includes role, artifact scope, return channel, and explicit commit permission. [A14]
For the initial evidence-only worker contract, commit permission is `no`; the publisher constructs attributed commits from validated evidence.
Implementation requires the applicable approved FS and PLAN; drafting such documents does not approve them. [G; L]
The framework's narrow exceptions do not authorize an executor to infer that any conveniently labeled task is trivial.
PLAN self-approval is not assumed enabled: accepted ADR-0027 explicitly conditions activation on a separate role-contract amendment, while the inspected role contract still prohibits Document Author self-approval. [A27; G]

| Work-item condition | Contract boundary | Conservative candidate handling |
| --- | --- | --- |
| Type unset or invalid | Most restrictive gate; no agent Type edits | No substantive dispatch; expose classification need without reclassifying. |
| `feature` | May draft FS and open a PR; crossing Approved requires human authorization | Demonstration flow drafts only and leaves Phase unchanged. |
| `bug` | Investigation/proposal allowed; proposed fix requires human approval | No fix dispatch based solely on an agent diagnosis. |
| `task` | May advance to In Progress; PR-open permits the specific In Review exception | Supported only if the selected first slice explicitly enables those transitions. |
| `question` present | No Issue comments, other label edits, or Phase changes; narrow human-answer exit | Suppress publication and dispatch too, as a product restriction stronger than Issue-only suppression. |

The Type boundaries above derive from accepted ADR-0019 and the implemented FS-0018, not from treating all Types as one generic pipeline. [A19; F]
Document status, work-item Phase, Issue closure, and PR state are separate facts; none is a universal substitute for another.
An `Approved` board value is not by itself proof of who approved which action: framework origination paths can also set that Phase through agent activity. [F, Origination Paths]
ADR-0026 defines recorded document approval; it does not turn an arbitrary current board value into an immutable action-scoped approval record. [A26]

### 2.2 Technical and evidence constraints

Git remains durable artifact authority; GitHub Issues and Projects are the first work-item substrate, and Hermes Agent is the first intended execution runtime. [P]
No GitHub-to-Hermes dispatch bridge is supplied by the read contract; ADR-0039 governs runtime setup, not a dispatch API. [A39; R3]
The candidate Hermes kanban binding is not shipped and is not a prerequisite the architecture may pretend is already satisfied. [B]
The research reports mutable Issue comments, no Projects field-history retrieval API, and no conditional-write primitive for the relevant field mutations. [R2; R4]
These observations limit enforceability even where a framework document describes stronger audit visibility.
Credentials never belong in Git, whether the instance is a local file or a separate portfolio repository. [B]
There is no selected implementation language, database, runtime transport, or cloud requirement in this draft.

### 2.3 Source status and interpretation

ADR-0032 is `proposed` at the pin; neither its presence in INTEGRATION nor citations from other ADRs make it accepted. [A32]
The product/instance boundary here rests on the bootstrap and frozen brief; accepted ADR-0037 and ADR-0039 independently constrain their binding content. [P; B; A37; A39]
Exported rules and accepted ADRs must be read together; an unresolved contradiction is a hold condition, not permission to choose the more permissive reading. [A30; G]
The research recommendation that a ledger pre-check can ensure one external publication is specifically not adopted as a guarantee. [R2; B]

## 3. Context and Scope

### 3.1 Business Context

The human describes work and supplies the approvals required by its Type and action.
The product reads that authority, spends an instance-controlled execution budget, and offers evidence back through the human's existing review surface.
The runtime produces candidate content; it does not decide whether the human's authority is still valid or whether an artifact may be published.
The instance operator is trusted to configure real isolation and credentials; the system does not claim protection against a malicious host administrator.

| Responsibility | conventional-agents | collective-agents | Instance |
| --- | --- | --- | --- |
| Roles, lifecycle, approval boundaries | Defines portable contract | Evaluates adopted contract | May strengthen, not silently weaken |
| Reconciliation and safe replay | Requires behavior | Implements execution and recovery | Chooses cadence and availability |
| Substrate/runtime mechanisms | Defines binding/setup rules | Implements product adapters and their tests | Selects endpoints and installations |
| Model policy | Constrains truthful attribution and collaboration | Evaluates policy, records actual use | Chooses identities, fallback, limits |
| Repository and actor registry | No deployment registry | Validates and consumes registry shape | Owns repositories, identities, budgets |
| Proposal acceptance | Human-gated | Produces draft and evidence only | Human reviews and merges |

The boundary excludes an organization-specific operations desk, general autonomous project management, automatic merging, and replacement of the governance framework.
It also excludes a universal distributed workflow platform built in anticipation of adapters nobody has exercised. [P; A24]

### 3.2 Technical Context

```text
Human decisions ----> work-item substrate <---- controlled publication
                            |                         ^
                      current observations            |
                            v                         |
Instance policy ---> reconciliation core ---> durable intent/effect ledger
                            |                         |
                            v                         v
                    runtime adapter             isolated publisher
                            |                         |
                            v                         v
                    isolated worker ----evidence--> validator
                            ^                         |
                            |                         v
                     staged Git snapshot       proposal branch / draft PR
```

Arrows describe candidate responsibility boundaries, not a deployed topology; the publisher accesses evidence only through validation and current-authority checks.
The work-item port provides the six current capabilities: work item, attributable Type, Phase, parked state, ordered attributable activity, and enumerability. [I; A24; A28]
Events are optional hints to perform a fresh read, never authoritative commands to execute an old transition.
The runtime port is a separate candidate interface for submission, lookup, cancellation, and evidence retrieval; its final transport remains open.
The Git artifact port stages a pinned source tree, validates content against an expected base, and publishes only allowed proposal refs.
The first substrate adapter maps `Issue Type` to the Projects custom field, not GitHub's similarly named native issue-type feature. [H2]
Pagination completeness, read permission failures, and API throttling must be represented explicitly; an incomplete inventory is not an empty inventory.

### 3.3 Authority by fact

| Fact | Authority | Product's persisted observation |
| --- | --- | --- |
| Governed artifact contents and applicable document status | Named Git commit and branch context | Paths, object IDs, status, approval references, contract pin |
| Current Type, Phase, labels, and open/closed state | Work-item substrate | Snapshot with observation time and provenance |
| Authorized action and scope generation | Locatable human authorization or expressly permitted standing policy | Immutable scope record and source evidence, not a worker assertion |
| Reservation, attempt association, retry and publication progress | Engine ledger | Transactional records with explicit uncertain states |
| Actual runtime outcome and model use | Runtime/provider observations, subject to adapter limits | Raw receipt references plus normalized provenance |
| What is really published | Git refs and remote proposal objects | Verified IDs, revisions, head/base details and timestamps |

The ledger records what the engine knew; it does not grant authority to rewrite Git or overrule a newer human decision.

## 4. Solution Strategy

### 4.1 Separate authorization from inference

Use a deterministic reconciliation shell for eligibility, identity, reservation, retry policy, and effect planning.
Use model reasoning only inside a bounded action, such as drafting an FS, investigating a bug, or producing a scoped patch.
A worker may recommend another action or a broader scope, but that recommendation is evidence for a future decision, not a control-plane instruction.
This confines ADR-0028's non-deterministic oscillation risk: repeated reasoning cannot independently undo and redo workflow transitions. [A28]

The candidate decision procedure is: observe current state; resolve governing evidence; determine a permitted action; find its existing intent; reserve an eligible attempt; dispatch; validate; publish; reconcile.
Every exclusion yields a stable reason code and the evidence needed to explain it; repeated exclusions do not produce repeated Issue comments.

### 4.2 Give the proposal a stable identity

Define a logical intent key as `(instance namespace, substrate item identity, action kind, authorized generation)`.
For GitHub, preserve repository identity and Issue identity as well as the human-readable `owner/repo#number`; renames must not silently create a fresh item. [H1]
The exact encoding is open, but the semantic key cannot contain a run ID, retry count, current timestamp, or mutable description hash.
Scope is an immutable value associated with the generation: allowed artifacts, desired outcome, governing revisions, and explicit exclusions.
A scope digest detects divergence; changing that digest is not an authorization mechanism.
A description edit causes re-evaluation or suspension; only a recorded authorization can issue a new scope generation. [B]
Retries and review revisions within the authorized scope reuse the same intent and canonical proposal.
A closed, abandoned, or merged proposal remains discoverable through a durable terminal record; reopening an Issue does not erase its earlier intent.

### 4.3 Prefer bounded uncertainty to invented exactly-once semantics

Reserve intent and attempt state in a durable transaction before any dispatch or dispatch-related remote stance write.
A unique key can prevent cooperating dispatchers from allocating the same local reservation; it cannot make a remote API call transactional with that reservation.
Persist each publication effect before sending it, and persist its observed result separately.
If the response is lost, the next action is discovery, not a second create request.
An outbox makes an intended effect recoverable; it does not prove whether GitHub already performed it.
The target is one canonical logical proposal per intent, verified remote effects, and an explicit stop on unresolved ambiguity, not exactly-once external writes. [B; R4]

### 4.4 Strengthen only where mechanisms justify it

| Property | Classification in this candidate |
| --- | --- |
| Human merge gate | Existing contractual prohibition; platform-enforceable only with verified branch/ruleset actor restrictions and no bypass. |
| Agent cannot edit Type | Conduct rule on GitHub; proposed publisher API omits Type mutation, but a compromised project-write credential still reaches the field. |
| Worker cannot publish | Proposed OS/process/network isolation property; a profile name or prompt is not enforcement. |
| One live internal reservation | Proposed transactional invariant, dependent on selected ledger and fencing implementation. |
| One remote proposal after any crash | Not guaranteed by ledger pre-check, outbox, deterministic naming, or leases alone. |
| Human edit always wins | Contractual requirement; pre-write reread reduces risk, but GitHub races remain detectable rather than fully preventable. |
| Run uses selected model | Not assumed; actual provider/model chain must be observed and checked. |

“Proposed” means unbuilt; “detectable” requires retained observations and working monitors; neither word may be presented as “enforced.”

## 5. Building Block View

### 5.1 Candidate components

| Component | Responsibility | Principal boundary |
| --- | --- | --- |
| Instance resolver | Select one explicit instance, validate config, retain source and digest | Never discover secrets or policy from a worker checkout |
| Observation collector | Enumerate current items, governing Git objects and known publications | Read failures cannot become missing-object facts |
| Authority evaluator | Explain whether a named action remains within contract and scope | No model-generated output can approve itself |
| Intent coordinator | Register generations, reserve attempts, maintain terminal records | Transactions and uniqueness are internal, not remote locks |
| Runtime adapter | Translate a bounded invocation and normalize lifecycle evidence | No work-item mutation or embedded GitHub mirroring |
| Worker sandbox | Produce patch, summary and test evidence from a staged snapshot | No publication credentials or publisher access |
| Evidence validator | Check provenance, paths, base revision, checks and policy | Untrusted tests execute outside the credentialed publisher |
| Publisher | Perform allowlisted, current-authority-checked effects | No arbitrary commands, approval operation, Type write, or merge |
| Recovery reconciler | Discover uncertain effects, stale attempts and mismatched remote state | Lease expiry alone cannot authorize repeated publication |
| Operator reporting | Expose holds, incomplete scans, budget use and schedule health | Respect parked-item silence while retaining internal diagnostics |

These are logical blocks; a first implementation may put the deterministic blocks in one executable without placing them in the worker's security domain.
The publisher must remain a separately credentialed execution boundary even if it shares a codebase and local ledger with reconciliation.

### 5.2 Persisted record model

| Record | Essential content | Meaning |
| --- | --- | --- |
| Authorization | Actor/policy source, action, scope, generation, validity/revocation evidence, Git context | Why this exact work is permitted |
| Intent | Stable key, authorization reference, canonical proposal reference, lifecycle state | One logical proposal, independent of execution count |
| Attempt | Intent key, attempt ID, reservation epoch, runtime handle, deadline, state | One try at producing acceptable evidence |
| Evidence manifest | Base/tree IDs, patch digest, touched paths, summaries, check results, actual model receipts | What an attempt really returned |
| Effect | Intent, effect kind, revision, request digest, state, remote ID, readback receipt | One planned external mutation and its known outcome |
| Observation | Object identity, observed values, observation time, source and completeness | What the controller saw, not a complete platform history |
| Policy snapshot | Instance revision, routing decision, effective limits, adapter versions | Reproducible explanation of why this route was chosen |

Retain publication and generation terminal records after workspace cleanup; otherwise garbage collection becomes a duplicate-work generator.
Large logs and patches may live in a private durable evidence store, addressed by digest; the ledger holds integrity-checked references, not ephemeral worker paths.
Git becomes authoritative for the published artifact; the operational database is not a competing source tree.
The evidence store and ledger require retention, backup, access control and migration policy before unattended production use.

### 5.3 Dispatch and return envelopes

The proposed dispatch envelope names the intent and attempt, role, read snapshot, allowed output paths, permitted tools, deadline, budget allocation and return channel.
It includes applicable contract/config revisions, the selected model route, permitted fallbacks, and `Commit: no`; it contains no substrate-write secret.
The return envelope includes runtime handle, terminal outcome, evidence manifest, executed checks with exit status and limitations, and observed model/provider usage.
A summary saying “tests pass” without command, revision and result evidence is insufficient for a publication gate.
A runtime receipt must distinguish accepted submission from completed work, and unknown submission from rejected submission.
If the adapter cannot discover whether an unacknowledged submission exists, the attempt becomes `dispatch_unknown`; support for blind resubmission is not implied.
These envelopes are product candidates to exercise against Hermes, not a neutral runtime API attributed to ADR-0039. [A39]

### 5.4 State separation

Intent states describe `eligible`, `held`, `active`, `proposal_present`, and terminal dispositions such as `abandoned` or `merged_observed`.
Attempt states describe `reserved`, `dispatch_unknown`, `running`, `evidence_returned`, `failed`, or `cancelled`; none independently authorizes publication.
Effect states describe `prepared`, `in_flight`, `confirmed`, `unknown`, or `rejected`; a confirmed PR effect does not confirm its Issue-link effect.
Lease epochs reject late internal submissions, but do not cancel an API request already accepted outside the ledger.
A local “completed” flag must therefore never mean “the entire work item is Done.”

## 6. Runtime View

### 6.1 Candidate end-to-end flow: authorized feature specification draft

This flow deliberately chooses Type `feature` with action `draft-spec` to exercise a meaningful approval boundary without writing implementation code.
It is an illustrative candidate, not a decision that the first release must support `feature`; decision D1 remains open.
Assume a human-classified item at Phase Approved, a locatable authorization for this drafting scope, no `question`, and a configured instance with a working dispatch adapter.

1. A scheduled pass enumerates the item; an event, if present, only explains why the pass ran early.
2. The collector reads current Type, Phase, labels, brief, relevant Git context, and existing proposal references; it records incompleteness instead of guessing missing values.
3. The evaluator verifies that the authorized action is drafting, not implementation, and binds the allowed document scope to the human authorization record.
4. The coordinator resolves the existing action/generation intent; it does not mint another generation because the description was edited or an earlier run failed.
5. In one ledger transaction it reserves the attempt, routing decision, budget allocation, and effect identities needed for the dispatch announcement.
6. The publisher rereads suppression and authority, verifies its expected GitHub identity, posts the deduplicated dispatch stance, and reads back the exact comment.
7. The dispatch stance identifies a selected route as planned, not as proof that model has run; an uncertain comment write is discovered before further effects.
8. The runtime adapter launches the isolated worker from the declared snapshot and records its handle; an unacknowledged launch enters `dispatch_unknown` rather than a retry loop.
9. The worker drafts the FS within its allowed paths and returns a patch, scope summary, document-check evidence, and actual model/provider receipts; it performs no GitHub writes.
10. The validator checks the patch base, actual paths, attribution, check results and absence of unauthorized implementation or approval-status changes.
11. The publisher rereads current work-item authority and governing revisions; a human edit, new park, revoked generation or mismatched scope holds the evidence instead of publishing it.
12. It constructs attributed commits in a clean publication workspace, reserves the branch/PR effects, discovers any prior matching publication, and publishes only a proposal ref and draft PR.
13. It reads back the branch head and exact PR to confirm repository, base, head, draft state and intended content, then records the canonical proposal ID against the intent.
14. It records a stance-bearing outcome and non-closing Issue link, separately verifying those effects; failure to link does not cause creation of another PR.
15. It leaves Phase Approved and the FS `draft`; the PR is now a human-review opportunity, not evidence of approved implementation or finished work.
16. Later passes observe the same proposal and perform no duplicate dispatch or comment; any implementation action requires its own applicable approval evidence and intent.

The specification PR uses a reference such as “Related to” rather than a closing keyword, since merging a spec need not finish the feature. [R1]
A human merging the spec changes the durable artifact state; it does not retroactively authorize every action the engine could infer from it.
If a reviewer requests changes within scope, a new attempt can update the same proposal after current-authority validation; expanded scope requires an explicit decision.

### 6.2 Crash during publication

Consider a successful remote PR creation followed by connection loss before the publisher records the PR number.
The effect remains `unknown`; its reservation and request identity survive restart.
Recovery enumerates matching open, draft, closed and merged proposals, checking repository, expected head ref, base, intent marker and commit evidence.
One verified match is adopted as the existing publication; a marker alone is insufficient because remote text can be edited or forged.
Multiple plausible matches produce a conflict hold; the system reports their IDs and does not choose a winner, close one, or create another automatically.
No match is conclusive only if discovery has adequate scope, permissions, pagination and freshness and the earlier publisher/request can no longer be active.
If that cannot be established, uncertainty persists and a human must reconcile it; absence from one search result is not permission to retry.
A deterministic head ref assists discovery but is not a GitHub uniqueness constraint on PR creation. [B; R1; R4]

### 6.3 Outcome handling

| Outcome | Internal response | Work-item response |
| --- | --- | --- |
| `needs_input` | Persist exact unresolved decision and stop that intent | Post the question with stance, then apply `question`; verify each before entering silence |
| Rate limit or recoverable timeout | Backoff within attempt/time/budget bounds; preserve intent | No `question` merely because infrastructure is slow |
| Crash with uncertain dispatch | Query runtime handle/submission evidence before retry | Deduplicated operational visibility when unparked; no implied human decision |
| Authority changed | Cancel where possible; quarantine returned evidence | Explain actual decision needed when permitted; never undo the human's edit |
| Ambiguous remote write | Freeze affected effects and perform discovery | Escalate a concrete reconciliation decision; never blind-retry create |
| Retry budget exhausted | Stop further attempts and expose operator action | Apply `question` only if a genuine human choice is now necessary |
| `question` already set | Observe and retain internal state only | No progress comments, label churn, Phase writes or proposal updates |

Automatic question removal remains disabled in the conservative first slice until its required stance/removal ordering is specified; human removal is already permitted. [A20]
Removing a park resumes evaluation of the same authority, not unconditional execution or a fresh generation.

## 7. Deployment View

### 7.1 Single-repository instance

The proposed minimum deployment is a scheduled CLI pass on one host, a local durable ledger volume, a private evidence directory, and separate worker and publisher identities.
One local instance configuration file names the repository, substrate mapping, runtime endpoint, policy, schedule expectations, and secret references.
A dedicated portfolio configuration repository is not required to run one repository. [B]
The scheduler invokes the same reconciliation entry point as a manual recovery pass; the system must not require an uninterrupted foreground agent conversation.
If workers outlive a CLI pass, the chosen runtime must offer durable run lookup and managed lifetime; process detachment is not assumed to supply those properties.
A local transactional database is a candidate, not a selection; SQLite is plausible only within a tested single-host durability and coordination envelope. [R7]
Use a persistent volume rather than an ephemeral checkout or runner filesystem for the ledger and accepted evidence.

### 7.2 Portfolio instance and later service topology

A portfolio may use an instance-level repository for registry, identities, cadence, policy and budget allocation, versioned separately from product releases.
Repository credentials, workspaces, namespaces and budget accounts remain partitioned even when a board or scheduler is shared.
A future persistent service can accept events for lower latency while retaining periodic full inventory reconciliation and per-repository scan health.
Multi-host execution requires a ledger with demonstrated concurrency semantics, publisher ownership and recovery; a shared SQLite file is not a proposed cluster design.
Hermes kanban's reported atomic claim is local to its board and host; it does not serialize collective-agents publishers or span GitHub effects. [R4]
Prefer one active publisher per instance initially, but do not equate that deployment rule with certainty after process loss or network partition.

### 7.3 Deployment trust boundaries

The worker receives a staged tree, private scratch space and narrowly permitted model-provider egress, not the host checkout or its credential-bearing configuration.
Remove inherited tokens, credential helpers, SSH-agent sockets, home directories, runtime control sockets, host PID access and privileged MCP/tool connections.
A separate UID and containment boundary must deny access to publisher storage and network paths; merely selecting `HERMES_HOME` or a tool profile does not establish this. [B; R5]
Any provider credential needed by a worker should be scoped or brokered so it cannot become a general host capability; secret values are never artifact content.
The publisher runs no worker-supplied shell, Git hooks, build scripts, or tests while holding write credentials.
For private repositories, a trusted staging step supplies source content without passing its fetch credentials onward.

### 7.4 Operations, upgrades and restoration

Startup validates contract pin, adapter compatibility, configuration origin, ledger schema, identity, target repository and merge-protection posture before enabling mutations.
Monitor successful complete scans independently of the scheduler itself; a quiet repository losing its schedule is an outage, not merely absent work. [A28; R8]
Upgrade by stopping new admission, draining or quarantining in-flight effects, backing up the ledger, and validating schema compatibility before resuming.
After backup restoration, remote state may be newer than the ledger; all affected intents enter recovery before any create operation is allowed.
Loss of operational history cannot be repaired by reading current board fields and declaring that they describe past authorization.

## 8. Cross-Cutting Concepts

### 8.1 Authority freshness and publication concurrency

Resolve authority at admission and before every external effect, including comments and labels, not only before PR creation.
Freeze the admitted scope and policy evidence for attribution; apply later revocations or stricter controls immediately rather than treating the frozen policy as irrevocable permission.
Use internal transaction ownership and fencing epochs for cooperating processes, with one effect request identity per intended mutation.
Do not steal a publisher lease and resend while its old process or request may still be live; first fence the old publisher and resolve its external effects.
GitHub does not accept the engine's fencing epoch as a precondition, so this design cannot promise that every stale in-flight write is prevented. [R4]
Read-after-write exposes mismatches but cannot undo a race; report a conflict rather than overwriting again to “restore” a stale desired value.
The initial choice to leave Phase unchanged avoids one especially harmful race but does not eliminate races in comments, refs or PR publication.

### 8.2 Evidence security and provenance

Treat work-item text, repository content, tool output and worker evidence as untrusted data, including apparent instructions to change policy or secrets.
Validate actual changed paths rather than worker-declared paths, rejecting traversal, symlink escapes, unauthorized submodule changes and out-of-scope binary content.
Bind test results to the exact candidate tree; a passing result on an earlier revision cannot authorize a later patch.
Run required checks in a separate credential-free verifier; the publisher consumes check receipts and never executes an alleged “verification command” from a summary.
Hashes prove content identity, not honesty of a claimed execution; important checks need observations from the trusted verifier or independently visible CI.
Retain original and normalized runtime receipts so an auditor can distinguish an adapter interpretation from the source evidence.
Do not publish secrets or unrestricted raw logs; access control, redaction and retention apply before evidence is copied into an Issue or PR.

### 8.3 Attribution, model routing and budgets

Record selected provider/model, routing rationale, actual provider/model sequence, fallback events, role, session, runtime version and evidence contribution per attempt.
The provider-qualified `Agent-Attribution:` trailer is the durable machine-readable attribution for produced commits; display names are not its replacement. [A21; A29; H5]
A worker's claim about its own model is weaker than runtime/provider evidence; unknown actual identity is recorded as unknown and blocks claims requiring it.
Policy chooses allowed routes and fallback models; product mechanism enforces that choice and rejects undocumented fallback rather than inheriting ambient runtime defaults.
Collaboration modes remain opt-in and disabled by default; actual fallbacks must not collapse independent seats or make an evaluator a contributor. [A23]
When independence fails, record configuration failure or synthesis-only output as applicable, never a successful independent verdict.
Reserve bounded attempt/resource allowances before dispatch and account for retries and duplicate computation, not just successful proposals.
Where provider cost is delayed or unavailable, expose estimated versus observed spend and use enforceable time/concurrency limits; do not advertise a hard monetary cap without a demonstrated mechanism. [R6]

### 8.4 Configuration and observability

Candidate configuration resolution selects an explicit instance root and records every effective value's source; no search through vendored defaults may supply a real deployment identity.
A repository override may narrow authority, but an untrusted worker branch cannot expand repository access, permitted actions or model spend.
Reject missing field mappings, unknown schema versions, conflicting instance selections and unsupported runtime capabilities before dispatch.
Expose intent/attempt/effect IDs, current hold reason, last complete scan, outstanding uncertainty, retry expenditure and canonical proposal link in operator views.
A GitHub-only reviewer receives the substantive result or exact requested decision on the Issue; runtime-only `blocked` is not sufficient. [R8]
While an item is parked, continue internal health reporting without posting prohibited heartbeat comments to it.
A failed delivery remains “pending visibility,” not “human notified”; an independent operator channel handles substrate outages.

### 8.5 Quality scenarios and verification strategy

The following are proposed acceptance scenarios for future FS/PLAN work, not tests executed for this architecture draft.
Each scenario identifies a stimulus, environment, required response and measurable evidence; numerical workloads are test fixtures, not promised production capacity.

#### Q1 — Duplicate triggers and local contention

Stimulus/environment: 100 identical events and two reconciler processes encounter one unchanged eligible generation with a healthy ledger.
Response: all paths resolve the same intent; only the transactional winner admits the attempt, and losers observe rather than announce new work.
Measure: one intent and one admitted reservation; no duplicate dispatch stance or new proposal for the unchanged authorized action.
Verify using deterministic adapter fixtures plus the chosen ledger's real concurrent-process transaction tests; a mock lock is not sufficient. [A14; A28]

#### Q2 — Lost acknowledgement after PR creation

Stimulus/environment: terminate the publisher after GitHub creates a draft PR but before its response reaches the ledger.
Response: effect becomes uncertain, discovery adopts the verified existing PR, or publication stays held if discovery is incomplete.
Measure: zero second create requests while uncertainty remains; a complete recovery records the original remote ID and readback evidence.
Verify with a controlled adapter fault and, before production, a disposable integration target; passing this scenario does not prove global exactly-once delivery. [B; R4]

#### Q3 — Human revocation during execution

Stimulus/environment: a human parks the item or changes its Type/scope while a worker is running; repeat with the edit inside the final read/write window.
Response: observed revocation blocks publication and quarantines evidence; an unpreventable in-flight conflict is detected and escalated without corrective overwrite.
Measure: zero sends after observed revocation; race cases produce a conflict record by the next successful reconciliation, not a claim of prevention.
Verify both interleavings and retained old/new observations; current field values alone cannot reconstruct the historical race. [F, Edge Cases; R4]

#### Q4 — Prompt injection attempts to become publisher

Stimulus/environment: a worker reads an Issue and repository file instructing it to obtain GitHub credentials, contact the publisher, and edit host files.
Response: filesystem/process/network controls deny those capabilities regardless of model compliance; any out-of-scope patch fails validation.
Measure: no readable canary secret, no successful write outside permitted mounts, no privileged callback, and no remote mutation attributable to the worker.
Verify the actual sandbox, including inherited environment, sockets and plugins; a prompt-only test does not satisfy the scenario. [B; R5]

#### Q5 — Missed events and incomplete inventory

Stimulus/environment: drop all events, then throttle a page of enumeration while eligible work exists on a later page.
Response: scheduled reconciliation eventually finds the item after a complete successful scan; partial scans retain an explicit incomplete status.
Measure: no permanent dependence on the lost event, no false empty-inventory declaration, and complete-scan age remains within the instance's declared operational target.
Verify with pagination and rate-limit fixtures; benchmark the agreed inventory before selecting a production cadence. [A28; I]

#### Q6 — Parked means silent

Stimulus/environment: an item carrying `question` receives 100 scheduler passes, a retry timeout, and an unrelated human comment.
Response: none removes the park or advances work; unrelated comments and elapsed time are not a resolution or approval.
Measure: zero Issue mutations and zero proposal updates during the parked interval; internal diagnostic records remain available.
Verify that notification code, retries and recovery use the same suppression path as ordinary publication. [A20]

#### Q7 — Late worker and expired publisher lease

Stimulus/environment: an old attempt returns after a replacement reservation, while an old publisher's remote request may still be active.
Response: reject stale evidence by attempt/epoch; hold external replay until old publisher authority and request uncertainty are resolved.
Measure: zero publication from stale evidence and zero resend justified solely by lease expiry; every uncertainty has an operator-visible record.
Verify runtime cancellation failure and partition interleavings, not only graceful process exit. [R4]

#### Q8 — Fallback and budget honesty

Stimulus/environment: a selected model is unavailable; fallback would duplicate a review seat, or runtime receipts omit actual model and cost.
Response: reject false independent validation, retain unknown fields, and stop admission when the configured enforceable allowance is exhausted.
Measure: every accepted artifact has attributable actual model evidence; no fabricated spend, silent fallback, or unsupported hard-cap claim appears.
Verify with multiple fallback hops and provider-reporting gaps; a nominal profile name is not evidence of actual execution. [A23; R6]

#### Q9 — Ledger restoration behind remote reality

Stimulus/environment: restore a backup from before an already-published branch and PR while preserving the remote objects.
Response: recovered instances start in discovery mode, recover known correlations, and hold intents whose authorization or publication cannot be reconstructed.
Measure: zero new create requests for uncertain recovered generations; the recovery report distinguishes restored facts from missing history.
Verify from the actual backup format and retention policy; a restart with an intact live database is not this test.

#### Q10 — A reviewer sees the real stopping point

Stimulus/environment: the worker returns `needs_input`, or PR creation succeeds while the Issue-link write fails.
Response: publish the precise decision before applying `question`, or repair only the missing link; never claim an unavailable message was delivered.
Measure: one identifiable decision/request or verified proposal link on the Issue after recovery, with zero duplicate PR creation and no post-park commentary.
Verify remote readback and ledger progress per effect; a successful runtime outcome alone cannot satisfy the scenario. [A20; R8]

## 9. Architectural Decisions

### 9.1 Inherited decisions and fixed product direction

The read frontmatter confirms A12, A14, A16, A19, A20, A21, A23, A24, A26, A27, A28, A29, A30, A37 and A39 as accepted; FS-0018 is implemented.
Their constraints are consumed here without promoting this draft or the research memo to an accepted decision.
The frozen brief already fixes the reusable-product boundary, Git authority, stable action/generation unit, evidence-only workers, separate publisher, ledger-first dispatch and no merge. [B]
The state machines, record shapes, first-flow choice and topology above are proposed ways of satisfying that direction, not already-ratified product ADRs.

### 9.2 Decisions deliberately left open

| ID | Open decision and alternatives | Candidate leaning and evidence needed |
| --- | --- | --- |
| D1 | First Type/action: narrow `task` hygiene or `feature` specification drafting? | Demonstrate `draft-spec` here; human chooses the release slice after comparing scope, review value and failure exposure. |
| D2 | Minimum dispatch evidence: Type/Phase alone, explicit action approval, or scoped standing policy plus document evidence? | Reject Type/Phase alone; specify authority source, actor, scope, Git context and revocation checks in an approved FS. |
| D3 | Autonomous Phase transitions: read-only Phase or the full Type-permitted subset? | Start read-only; enabling the `task` In Review exception needs race handling and an explicit per-Type transition table. |
| D4 | Intent/generation representation: explicit grant ID, protected Git record, or substrate-linked authorization record? | Choose a durable explicit generation; demonstrate that edits, reopens, retries and repository renames cannot mint authority. |
| D5 | Durable ledger: single-host transactional store or shared database? | Start with one host if recovery and durability tests pass; decide backup, migration, retention and uniqueness semantics before dispatch. |
| D6 | Publisher concurrency and recovery: one active publisher, sharded ownership, or distributed leaders? | Prefer one active publisher initially; define fencing, unknown effects, discovery completeness and human resolution before any failover claim. |
| D7 | Dispatch API: direct managed Hermes invocation or an adapter using Hermes kanban? | Exercise submission/lookup/cancel/evidence on the real runtime; neither ADR-0039 nor a candidate binding decides this interface. |
| D8 | Instance config resolution: explicit local file, portfolio-root registry, or constrained composition? | Require explicit roots and provenance; specify override precedence and reject ambiguous or vendor-relative instance resolution. |
| D9 | Trust level of actual-model and check evidence: runtime receipts, broker observations, independent verifier? | Require evidence adequate for the claim; define behavior for missing identity, fallback chains and unverifiable checks. |
| D10 | Automatic question resolution and stance ordering? | Initially human removal only; resolve required unpark stance versus comment suppression without creating a generic parked-item write exception. |
| D11 | Approval proof retention and missed approval events? | Durable artifact-backed proof is preferable; define how an existing approval can be verified without relying on missing Projects history. |
| D12 | Resource and cost enforcement: admission estimates, runtime hard limits, provider-side caps? | Advertise only demonstrated bounds; choose safe behavior when accounting lags and when two attempts overlap. |

No identifiers above allocate repository ADR numbers or authorize implementation.
Decision closure requires human review, the corresponding current-state contract, approved FS/PLAN where code is implied, and evidence for the claimed mechanism. [L; A30]

## 10. Risks and Technical Debt

| Risk | Consequence | Candidate mitigation and remaining exposure |
| --- | --- | --- |
| Mutable comments mistaken for durable authority | Lost rationale creates duplicate work or false permission | Mirror observations and retain grants; deletion remains possible on the human-facing surface. |
| Lost remote acknowledgement | Duplicate PRs, comments or mismatched board state | Discover before retry; uncertainty can require human reconciliation and reduce availability. |
| Check-then-act race with human changes | A stale but apparently legitimate write lands | Revalidate and avoid unnecessary Phase writes; no atomic GitHub precondition is established by the research. |
| Publisher credential compromise | Attacker bypasses product-level allowlists | Separate process and minimal scopes plus verified branch actor restrictions; project-field ACL granularity remains insufficient. |
| Sandbox is only a runtime profile | Worker reaches host credentials or privileged tools | Test OS, mount, process and egress boundaries; runtime setup compliance is not proof of isolation. |
| Evidence forged or checked against wrong tree | Human reviews an apparently tested but different artifact | Bind receipts to content and independently verify; cryptographic identity alone does not prove test execution. |
| Ledger lost, rolled back or corrupted | Engine forgets canonical intents and prior publication | Durable backups, terminal records and recovery-only startup; missing authority cannot always be reconstructed. |
| Adapter version drift | A field, command or outcome is misinterpreted | Versioned capability checks and integration tests; the memo's findings are dated evidence, not permanent API guarantees. |
| Scheduler quietly stops | Governed work ceases to converge | Independent complete-scan monitoring per repository; event delivery is not a replacement. |
| Cost attributed only to successful runs | Hidden retries and fallback exceed intended spend | Track all attempts and distinguish observed versus estimated billing; provider-side lag may prevent hard caps. |
| Governance sources disagree | Engine chooses a convenient but unauthorized interpretation | Fail closed at the affected capability and request a decision; do not rewrite vendored rules in the product. |
| Premature portable API | Product mirrors one runtime's board while claiming neutrality | Keep adapters separate and exercise the first integration before extracting broader contracts. |

These are architecture risks and unresolved obligations, not defects in an engine claimed to exist.
The principal design debt is the undiscovered runtime hand-off: until D7 is exercised, this is a coherent candidate flow rather than a demonstrated executable path.
The principal safety debt is the publisher's remote-write recovery protocol: until D6 passes fault-injection and real integration checks, unattended publication must remain disabled.
The first release should earn each guarantee independently; a working happy-path PR does not validate concurrent recovery, isolation, or approval provenance.

## 11. Glossary and Source References

### 11.1 Terms used precisely

| Term | Meaning in this draft |
| --- | --- |
| Work item | The substrate entry point carrying a brief, classification and workflow position. |
| Authorized generation | A specific authorized scope/version of an action, not the latest edit or execution attempt. |
| Intent | Stable identity of that work-item action/generation and its canonical proposal. |
| Attempt | One runtime execution under an intent; failure does not create a new authority. |
| Canonical proposal | The recorded review artifact for an intent, normally one draft PR; not a claim that duplicates are impossible externally. |
| Effect | One separately tracked remote mutation, such as branch update, PR creation, stance comment or label application. |
| Unknown effect | A mutation that may have succeeded remotely and whose outcome is not yet established. |
| Park | Human-input suppression on the work item; distinct from operational backoff or exhausted resource allowance. |
| Publisher | Credentialed deterministic boundary validating and performing permitted effects; never a merger. |
| Enforced | A demonstrated technical control prevents the named action within a stated threat model. |
| Detectable | Retained evidence and monitoring can reveal a violation; prevention is not implied. |

### 11.2 Citation key and pinned sources

All framework paths below are relative to `vendor/conventional-agents/` at the stated pin, not to an unpinned upstream branch.
A framework file can be retrieved at `https://github.com/Tais-Den/conventional-agents/blob/94b784aa022b715bf7dad331a714f786620f961a/` followed by its listed relative path.
[B] is `/workspace/collective-agents-model-drafts/BRIEF.md`, the frozen product direction and independent drafting assignment.
[P] is collective-agents `README.md` and `AGENTS.md` at bootstrap commit `e322e5258b8a6f0e66c956eb0f677a266b907dfb` in the supplied research-source checkout.
[T] is `templates/core/architecture-arc42.md`; [G] is `guidelines/ROLE_CONTRACT.md`; [L] is `workflows/document-lifecycle.md`.
[I] is `integrations/README.md`, especially the amended six capabilities and the distinction between work-item and runtime bindings.
[H1], [H2], [H5] refer respectively to sections 1, 2 and 5 of `integrations/github-issues-projects.md`.
[F] is `docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md`, frontmatter `status: implemented`.
[A12] `docs/decisions/ADR-0012-non-overridable-gates.md`; [A14] `docs/decisions/ADR-0014-background-task-governance.md`.
[A16] `docs/decisions/ADR-0016-instance-conventions.md`; [A19] `docs/decisions/ADR-0019-issue-type-immutability-and-autonomous-gate.md`.
[A20] `docs/decisions/ADR-0020-question-label-suppression.md`; [A21] `docs/decisions/ADR-0021-cron-actor-identity.md`.
[A23] `docs/decisions/ADR-0023-collaboration-integrity-constraints.md`; [A24] `docs/decisions/ADR-0024-platform-neutral-core-with-shipped-bindings.md`.
[A26] `docs/decisions/ADR-0026-approval-is-a-recorded-act.md`; [A27] `docs/decisions/ADR-0027-plan-self-approval-within-declared-interfaces.md`.
[A28] `docs/decisions/ADR-0028-level-triggered-reconciliation.md`; [A29] `docs/decisions/ADR-0029-commit-author-naming-for-multi-model-agents.md`.
[A30] `docs/decisions/ADR-0030-decision-records-versus-current-state-documents.md`; [A32] `docs/decisions/ADR-0032-template-and-instance-repository-forms.md` (`proposed`, not binding as an accepted ADR).
[A37] `docs/decisions/ADR-0037-executable-github-binding.md`; [A39] `docs/decisions/ADR-0039-agent-runtime-integration-bindings.md`.
The entry instructions `AGENTS.md`, `INTEGRATION.md`, `workflows/session-modes.md`, and `docs/decisions/README.md` were also read; individual ADR frontmatter, not index inference, determined the statuses stated above.
[R1]–[R8] refer to numbered sections of the permitted research memo: `https://github.com/AdvanceEnterprises/collective-agents/blob/6d2a94b44545be0aec072c45e3f8bfe83067ed38/docs/research/engine-boundary-and-failure-modes.md`.
Its local content was verified against that commit's blob; external findings in the memo carry its own retrieval date and remain secondary evidence in this draft.

### 11.3 Evidence disagreements carried forward

The memo describes ledger-before-dispatch correctly but overstates what a ledger check can guarantee about remote publication; sections 4 and 6 retain the unresolved write window.
The memo describes rereading current fields as closing a concurrency race; this draft treats it as risk reduction because the reported API supplies no matching atomic precondition.
The GitHub binding describes queryable field-value history; the memo reports current values only. Authority reconstruction therefore cannot rely on historical GraphQL access. [H2; R2]
FS-0018 still lists a trigger source in one capabilities table; the accepted amendment and current integration registry make capability six enumerability. [F; A28; I]
ADR-0032 is proposed despite stronger language in INTEGRATION and research references; local product direction and independently explicit accepted binding constraints are cited instead.
These differences are not silently repaired in the source repository and are not grounds to claim this candidate has resolved them by implementation.
