# Architecture evidence and decision inventory

**Status:** working research synthesis, not an accepted ADR or an approved FS.
**Updated:** 2026-10-01. This was written independently of PR #1's proposed
arc42; [PR #1](https://github.com/AdvanceEnterprises/collective-agents/pull/1)
is background research, not a prerequisite or source of normative decisions.
The pinned framework documents and the linked platform documentation are
more authoritative than either memo. The first implementation must recheck
version-sensitive API and Hermes claims against its deployed versions.
The five model candidates and a Head Architect comparison are archived on trunk
in [`docs/research/model-drafts/`](model-drafts/) (they reached trunk with
PR #3's merge, `2d5dc77`).
Its reconciliation worksheet is analysis, not a sixth vote or an accepted ADR.
The decisions that followed are recorded separately: `ADR-0001` and `ADR-0002`
are **accepted**, and `FS-0001` is **approved** (unimplemented).

## What the pinned contract actually requires

- `vendor/conventional-agents/integrations/README.md` names six substrate
  capabilities. Its GitHub binding is currently the only shipped work-item
  mapping. The Hermes kanban candidate is under `docs/proposals/`, not a
  conforming second binding.
- `vendor/conventional-agents/docs/decisions/ADR-0028-*.md` requires an
  enumerable, level-triggered path. Webhooks are an optional accelerant;
  scheduler liveness becomes part of correctness.
- `vendor/conventional-agents/workflows/document-lifecycle.md` and
  `docs/specifications/FS-0018-*.md` define Type/Phase/parked-state gates.
  The `question` state suppresses agent transitions; operational retries
  must not be mistaken for requests for a human decision.
- `vendor/conventional-agents/docs/decisions/ADR-0012-*.md` reserves merging
  to humans and requires identity verification for `gh`/push operations.
  This is a conduct rule even where a particular deployment lacks technical
  enforcement.
- `vendor/conventional-agents/docs/decisions/ADR-0039-*.md` governs runtime
  integration *setup*, not a generic dispatch API.
- `vendor/conventional-agents/docs/decisions/ADR-0032-*.md` has
  `status: proposed` in the pinned commit. Its template/instance distinction
  is useful, but should not be cited as an accepted gate.

## Research findings with architectural impact

1. **No free cross-system identity.** A GitHub issue, Hermes run, Git commit,
   and draft PR have different identifiers. Issue-closing keywords are not a
   permanent correlation ledger; a worker run does not natively carry a
   GitHub issue foreign key. See [GitHub's PR/Issue linking guide](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue)
   and [Hermes kanban documentation](https://hermes-agent.nousresearch.com/docs/user-guide/features/kanban).
   Consequence: persist an engine-owned intent/attempt/publication relation.
2. **Reconciliation crosses unrelated authorities.** Git holds artifacts,
   GitHub holds current work-item state, and Hermes holds execution state.
   Neither a comment nor a Hermes board entry is a cross-system transaction.
   GitHub comments may be edited/deleted; Projects field reads describe
   current values, not necessarily the full historical approval trail.
   See the [Projects GraphQL reference](https://docs.github.com/en/graphql/reference/projects)
   and the pinned GitHub binding's activity-record caveat. Do not claim
   GitHub retains *no* historical evidence anywhere: audit logs and webhook
   payloads have different retention and coverage.
3. **A ledger-first reservation prevents a specific dispatch race, not all
   duplicate effects.** If a GitHub PR or comment write succeeds and the
   acknowledgement is lost, the ledger cannot be atomically updated with
   that external write. A pre-publish check or outbox alone does not prove
   exactly-once publication. Use a stable intent/publication identity,
   discover existing artifacts, serialize relevant publishers, and stop for
   inspection where uncertainty cannot be resolved.
4. **Worker credentials are a real security boundary.** A worker with shell
   access to the host's `gh` login or credential helper can bypass a prompt
   that says "return evidence only." [Hermes security guidance](https://hermes-agent.nousresearch.com/docs/user-guide/security)
   documents container isolation and explicit environment/credential-file
   passthrough; the actual worker deployment must verify no GitHub write
   material is passed or mounted. A separate publisher holds constrained
   credentials and validates returned evidence against *current* authority.
5. **GitHub's field permissions are coarse.** Project write access cannot
   express a per-field agent prohibition on Type/Phase changes. Enforcement
   claims need to distinguish authorization policy, detectable violation,
   and technical prevention. See the [Projects API](https://docs.github.com/en/graphql/reference/projects)
   and the pinned GitHub binding's §7 limitations.
6. **Hermes kanban does not solve engine-wide coordination by itself.** Its
   task claims and runs are useful inside its own board, but that board is
   not the framework's shipped work-item substrate and does not create a
   GitHub↔Hermes transaction. Choosing Hermes kanban as the dispatch queue
   versus invoking a Hermes worker another way remains a design choice.
7. **Schedules and human visibility need explicit operation.** [GitHub
   Actions schedules](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule)
   can be delayed or disabled after inactivity. A human viewing GitHub will
   not automatically see a Hermes run's block or cost. Surface a required
   human decision on the chosen work-item surface and monitor scheduler
   health independently of whether one work item is active.
8. **Model selection has three layers.** The framework requires role,
   attribution, and independent participants for opted-in collaboration;
   the engine evaluates task capability/risk and records actual invocation;
   the instance chooses provider/model identifiers and budgets. Hermes
   profile defaults and availability fallbacks do not themselves implement
   a risk-aware selection or prove reviewer independence.

## Agreed design directions from the architecture discussion

- The product is reusable; GitHub work items and Hermes execution form the
  first pair. They are independent adapter axes, not core dependencies.
- A one-project adopter can use local instance configuration. A portfolio
  operator can use a separate, governed instance repository. That repo is
  optional and owns registries, identities, cadence, budgets, and model
  assignments; credentials themselves remain outside Git.
- The publication unit is **one authorized work-item action in an explicit
  scope generation**. Runs are attempts under it; retries do not create a
  new canonical draft PR. Spec, implementation, and follow-up actions may
  be separate intents. Scope changes require an explicit authorization
  event rather than an implicit issue-body edit.
- Workers return evidence without GitHub write credentials. A separate
  publisher checks authority and evidence, writes proposals, and never
  merges. Isolation must be real at the OS/container and credential level.
- Exactly-once external publication is **not** an established guarantee.
  An ambiguous write must be discovered or escalated, not retried blindly.
- The human chose a `feature` / `draft-spec` first pilot. It requires a
  recorded, human-origin grant naming the action and bounded scope generation;
  Type and Approved Phase alone are not evidence of that particular grant.
  The worker proposes a draft FS PR, while the feature's Phase remains
  Approved and the FS remains draft. Neither PR creation nor merging the FS
  authorizes a later implementation action automatically.

These agreed directions led to recorded decisions (`ADR-0001`, `ADR-0002`
accepted; `FS-0001` approved). The implementation mechanisms remain open;
nothing here is a claim that an implementation or its security properties
has been verified.

## Questions to settle before an implementation FS

- What durable record proves the human grant's actor, action, permitted paths,
  Git context, generation and revocation for the `draft-spec` pilot? What
  machine-checkable evidence is required before its first dispatch?
- How are required stance and explanatory comments ordered before setting
  `question`, and how are incomplete external writes recovered without
  violating the parked item's suppression rule?
- How is a scope generation recorded, and how does a second independent
  intent become authorized on an existing work item?
- What ledger store, atomic reservation, lease, and crash-point recovery
  rules suffice for one host? What changes if multiple dispatchers run?
- What is the publication target identity (branch, PR, comment) and how is
  uncertainty after a remote write resolved without a duplicate effect?
- How will an isolated Hermes worker receive repository inputs and return
  a patch without inheriting GitHub credentials, and how is that property
  tested in the actual deployment?
- Which instance policy governs retries, model fallback, runtime/cost
  ceilings, and escalation without weakening human approval?
- For a later `task` path, how will the upstream FS-0018 In Progress to In
  Review on PR-open criterion be satisfied without mistaking the feature
  pilot's no-Phase-write rule for universal policy?

The PR #1 research memo contains more detailed source notes and exploratory
claims. It remains background, not a dependency on PR #1's design or merge.
