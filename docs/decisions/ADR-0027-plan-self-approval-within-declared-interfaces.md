---
type: adr
id: ADR-0027
status: accepted
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0018
  - FS-0022
superseded_by: null
created: 2026-07-27
updated: 2026-07-28
---

# ADR-0027: PLAN self-approval within declared interfaces

## Status

- Accepted

## Context and Problem Statement

`guidelines/ROLE_CONTRACT.md` §"Spec-first rule" requires two approved documents before
any implementation begins: a feature spec with `status: approved`, and a change plan
with `status: approved` referencing it. `workflows/document-lifecycle.md` makes both
approvals human-only, granted by merging the document's PR.

Two human approvals per unit of work is the framework's main throughput constraint, and
it is the specific thing that makes `FS-0018`'s Path 3 — autonomous work origination —
mostly theoretical. A cron-fired agent can detect drift, open a work item, draft a
spec, and draft a plan, and then must stop for two separate human merges before it can
act on any of it.

The question is whether the second approval earns its cost. The FS is the contract: it
states what will be built, what will not, and which interfaces are in scope. The PLAN is
execution strategy: it states how. Approving the *what* and then separately approving
the *how* is double-gating, and the second gate is the weaker one — a human reviewing a
plan is reviewing a prediction about work that has not happened, with less information
than they will have when the PR arrives.

That argument is not the whole picture, and the counter-argument identifies something
real. The PLAN is where scope expands. An FS says "add X." A plan can say "add X, by
restructuring these forty files." The FS's `interfaces:` field declares the sanctioned
surface area — `templates/core/feature-spec.md` carries the parsing hint that
*"interfaces listed here define allowed surface area for code changes"* — but nothing
checks a plan against it. The document hygiene gate checks touched files against FS
`interfaces:` only at PR time, when the work is already spent.

So the PLAN gate is protecting against something. The question is whether a human is
the right instrument, or whether the thing it protects against is mechanically
checkable.

There is a second exposure that no version of this reasoning covers. `ADR-0019`
establishes that an agent must not modify a work item's Type, because Type keys the
agent's own safety gate and an agent must not be able to lower its own gate. The same
hazard exists one layer up: an agent that can self-approve a plan modifying
`scripts/check-status.sh` can self-approve the removal of the check that would have
caught the plan. Any relaxation of the PLAN gate has to close that hole explicitly.

The question this ADR answers: **when may a change plan be approved without a human,
and what must never be?**

### A note on who is proposing this

This ADR was drafted by an agent, and it proposes to expand the circumstances under
which agents approve their own change plans. That is a conflict-of-interest shape
regardless of how carefully the reasoning is constructed, and the reserved-path list
below is exactly the kind of mitigation a self-interested proposal would include.

The mitigation is real — `scripts/`, `.github/workflows/`, and `package.json` are
reserved precisely so that an agent cannot self-approve a change to the check that
would have caught it — but a reader should not treat its presence as evidence of good
faith. It is evidence that the hazard was identified, nothing more.

This ADR therefore warrants closer human scrutiny than its reasoning alone invites,
and it takes effect only through an amendment to `guidelines/ROLE_CONTRACT.md` that is
deliberately not included here. Approving this ADR does not enable self-approval; a
separate, human-authored change to the role contract does.

## Decision Drivers

- **The gate should target the risk, not proxy it.** The exposure is scope expansion
  beyond an approved FS, not "plans are dangerous."
- **The criterion must be mechanical.** A gate that requires judgment to evaluate is a
  human gate wearing a different hat.
- **Blast radius must stay bounded.** ADR-0012's merge gate is untouched by anything
  here; the worst outcome of a bad self-approved plan is wasted agent effort.
- **An agent must not weaken its own constraints.** The ADR-0019 principle applies to
  enforcement machinery, not only to work-item metadata.
- **Autonomous operation is a stated goal.** `FS-0018` Path 3 is not worth specifying if
  every path through it stops at two human merges.

## Considered Options

### Option A — Status quo: human approves every PLAN

Predictable and safe. Keeps the framework's strongest claim — that every unit of work
was sanctioned twice — fully intact. Costs the autonomous path entirely, and spends
human review on the lower-information of the two gates.

### Option B — Remove PLAN approval entirely

Any PLAN referencing an approved FS may proceed. Maximum throughput. Removes the only
check on scope expansion before work is performed, and leaves the ADR-0019 hazard wide
open — an agent could self-approve a plan gutting `check-status.sh`.

### Option C — Route by work-item Type

Reuse `FS-0018`'s three-axis Type: `task` self-approves, `bug` and `feature` need a
human. Composes with machinery that already exists.

But Type is a proxy for risk, not a measure of it. A `task` can touch anything; a
`feature` confined to one file is safer than a `task` that rewrites the lint
configuration. It also inherits Type's weakness — `ADR-0024` established that no
substrate can prevent an agent from editing the Type field, so routing approval by Type
means routing approval by a field the agent can reach.

### Option D — Route by declared interfaces, with reserved paths

A PLAN self-approves when its declared touched-file set falls entirely within the
governing FS's `interfaces:` **and** touches nothing in a reserved set. Otherwise a
human approves.

Mechanical, targets scope expansion directly, and reuses a field the framework already
treats as authoritative.

## Decision Outcome

**Chosen option: Option D — route by declared interfaces, with reserved paths.**

### The rule

A change plan may transition to `status: approved` without human action when **both**
conditions hold:

1. **Containment.** Every entry in the plan's `touches:` front matter falls within the
   governing FS's `interfaces:` set.
2. **No reserved paths.** No entry in `touches:` matches the reserved set below.

If either fails, the plan requires human approval, exactly as today. A plan that
self-approves records this in its status transition; there is no separate marker.

### Reserved paths — always human, regardless of `interfaces:`

| Path | Why |
| --- | --- |
| `docs/decisions/` | ADRs are binding constraints. Self-approving a change to a constraint dissolves the constraint. |
| `guidelines/ROLE_CONTRACT.md` | Defines what every role may and may not do, including the role executing the plan. |
| `scripts/` | Contains `check-status.sh` — the check that evaluates this very rule. |
| `.github/workflows/` | CI enforcement. A plan that disables a job disables its own gate. |
| `package.json` | Defines the `lint:*` and `check:status` entry points CI invokes. |

The first two protect documents that constrain agents. The last three protect the
machinery that enforces those constraints, and they exist for the reason `ADR-0019`
gives one layer down: an agent must not be able to lower its own gate. A weakened
constraint document is at least legible to the next reader; a weakened check fails
silently and looks like success.

### What is unchanged

ADR-0012's merge gate is untouched. A self-approved plan still produces a PR that a
human must merge. Self-approval moves *when* a human looks, not *whether* one does —
from a prediction about unstarted work to a diff of finished work.

FS approval is untouched and remains human-only. This ADR relaxes the second gate on
the strength of the first; it does not relax the first.

### Enforcement

`scripts/check-status.sh` gains a check: for any PLAN with `status: approved` whose
history shows no human approval, verify containment and the reserved set, and fail if
either is violated. The `touches:` field this depends on is defined in
`templates/core/change-plan.md`.

Under-declaring `touches:` is a process violation rather than an exploit. The document
hygiene gate already compares a PR's actually-touched files against the FS's
`interfaces:`, so an under-declared plan fails at PR time — later and more visibly than
it would have failed here.

## Adversarial review

Requested by the maintainer after a reviewer flagged this ADR as an
agent-authored proposal to expand agent authority. The analysis below was
performed by the same agent that wrote the ADR, which is a real limit on it: an
author attacking their own proposal will find the objections they already
thought of. It is offered as a starting point for human scrutiny, not a
substitute.

### The load-bearing safeguard, and the cost it hides

Containment works because `interfaces:` is declared in the FS and **the FS is
human-approved**. The agent does not draw its own boundary; it stays inside one
a human already drew. That is the single thing making this decision defensible,
and it holds.

But it relocates scrutiny without naming the relocation. A human approving an FS
is now also approving the self-approval envelope for every plan under it.
`interfaces:` was previously a scoping hint checked at PR time; under this ADR it
is a security boundary checked at plan time. Approving an FS with a loose
`interfaces:` grants more than it used to, and nothing in the FS template or the
approval flow says so.

### Under-declaration is the exploit path, not a process violation

The Enforcement section calls under-declared `touches:` "a process violation
rather than an exploit." That framing is too kind, and it is the framing a
self-interested proposal would choose. An agent that wants to self-approve work
outside its FS's interfaces under-declares `touches:`; that is the attack, and
calling it a process violation does not make it one.

What actually bounds it: the PR diff shows the real files, hygiene gate item 6
compares them to the FS's `interfaces:`, and `ADR-0012` requires a human to
merge. So the payoff is wasted work plus a PR that fails review.

The residual is that item 6 is a manual checklist item until `FS-0022` lands. As
of this ADR's acceptance, under-declaration is caught by a human reading a diff
carefully, and by nothing else.

### "Blast radius is wasted agent effort" is conditional

The Decision Drivers claim the worst outcome of a bad self-approved plan is
wasted agent effort. That is true only if merge review catches the scope
violation. If it does not, the work reaches trunk and the blast radius is
whatever the plan did. The claim should be read as *bounded by merge review
quality*, not as bounded absolutely.

### The reserved list is fixed and will go stale

`scripts/`, `.github/workflows/` and `package.json` cover today's enforcement
machinery. Machinery added later is not automatically reserved. The Consequences
section acknowledges this; acknowledgment is not mitigation, and there is no
mechanism that notices when a new gate appears outside the list.

### The gain is latency, not less human review

The throughput argument is sound but narrower than it reads. This ADR does not
reduce the amount of human review — it moves it from plan time to merge time,
where the reviewer has more information. What it buys is that an agent does not
block mid-flight waiting for an approval. That is a real benefit for `FS-0018`
Path 3 and it is the honest description of it.

### What a human should check before accepting

- That `interfaces:` on the specs they approve are drawn tightly enough to serve
  as a security boundary, now that they are one.
- That they are willing to review PR diffs against `interfaces:` manually until
  `FS-0022` provides the mechanical check.
- That the reserved-path list matches the enforcement machinery as it stands at
  acceptance, rather than as it stood when this ADR was drafted.

### The relocation must be surfaced where specs are reviewed

The finding above — that this ADR promotes `interfaces:` from a scoping hint to
a security boundary — is currently documented only here. An ADR is not what
someone reads while approving a spec, so a warning that lives only in this
document will not reach the moment it matters.

Two current-state documents must therefore change **in the same change that
accepts this ADR**, per `ADR-0030` rule 3:

- **`templates/core/feature-spec.md`** — `interfaces:` is presented as a bare
  empty list. It needs a note stating that under this ADR the field bounds
  which change plans may self-approve, so a loosely-drawn `interfaces:` widens
  agent authority rather than merely describing scope.
- **`templates/reviewer/spec-review-template.md`** — its checklist asks
  "Interfaces defined? yes/no", which tests existence rather than tightness.
  It needs to ask whether they are drawn narrowly enough to serve as an
  approval boundary.

Both are named in Links below so that `FS-0022`'s rule 3 check catches their
omission if this ADR is accepted without them.

## Consequences

### Positive

- `FS-0018` Path 3 becomes viable: an autonomous agent can carry bounded, in-scope work
  from detection to open PR without a human in the middle.
- Human review concentrates where information is highest — the FS beforehand, the diff
  afterward — rather than on a plan in between.
- The scope-expansion check moves earlier, from PR time to plan time, where acting on it
  costs nothing.
- The ADR-0019 principle gets stated at the layer where it actually bites.

### Negative

- **In this repository, self-approval will rarely fire.** conventional-agents is almost
  entirely governance documents and exported surface; most plans here touch
  `docs/decisions/`, `guidelines/`, `workflows/`, or `scripts/`. What remains eligible is
  roughly `docs/specifications/`, `docs/change-plans/`, `test/`, and `CHANGELOG.md`. This
  is a property of the framework being an unusual consumer of itself, not a defect in
  the rule — a typical consumer's plans touch application source, where the reserved set
  does not reach. But the feature is being shipped for consumers, and its author will
  seldom use it.
- Correctness now depends on `touches:` being declared honestly. Detection is at PR
  time, not plan time.
- One more check in `check-status.sh`, which is itself in the reserved set — changes to
  it always require human approval, by design.

### Neutral

- The reserved set is path-based and will need revisiting when the repository grows new
  enforcement machinery. That is a maintenance cost, not a design flaw.
- Exported-surface paths (`guidelines/` beyond ROLE_CONTRACT, `skills/`, `templates/`,
  `workflows/`, `integrations/`) are deliberately **not** reserved. They were considered
  and rejected: reserving them would restate "this repository is all exported surface" in
  path form, and can be added later if self-approval proves too permissive in practice.

## Validation

- **Signal:** a PLAN whose `touches:` exceeds its FS's `interfaces:` and which carries
  `status: approved` without human approval fails `npm run check:status`.
- **Signal:** a PLAN touching any reserved path and carrying `status: approved` without
  human approval fails `npm run check:status`.
- **Signal:** over a sample of merged PRs from self-approved plans, actually-touched
  files match declared `touches:`. Divergence means the declaration is not being taken
  seriously.
- **Review checkpoint:** after the first ten self-approved plans, or six months,
  whichever is first. The question is whether any self-approved plan produced a PR that
  a human rejected for scope reasons — that is the failure this rule exists to prevent.
- **Failure condition:** if self-approved plans are routinely rejected at the merge gate
  for reasons an approving human would have caught, containment is the wrong criterion
  and this ADR should be superseded.

## Links

- ADR-0012: Non-overridable gates — the merge gate this ADR does not touch.
- ADR-0019: Issue type immutability and the autonomous gate — the "an agent must not
  lower its own gate" principle, applied here to enforcement machinery.
- ADR-0024: Platform-neutral core with shipped bindings — establishes that Type is
  agent-reachable on any substrate, which is why Option C was rejected.
- FS-0018: Issue lifecycle and autonomous triggers — Path 3 is the workflow this ADR
  makes viable.
- FS-0022: Gate coverage — the governing spec for the `check-status.sh` check this
  ADR requires.
- `templates/core/change-plan.md`: defines the `touches:` field.
- `templates/core/feature-spec.md`: presents `interfaces:`, which this ADR turns
  into an approval boundary. **Must be updated in the change that accepts this
  ADR** (`ADR-0030` rule 3).
- `templates/reviewer/spec-review-template.md`: its interfaces check tests
  existence, not tightness. **Must be updated in the change that accepts this
  ADR.**
- `guidelines/ROLE_CONTRACT.md` §"Spec-first rule": requires amendment to admit
  self-approval as a valid route to `status: approved`.
