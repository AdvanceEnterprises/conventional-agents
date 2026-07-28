---
type: adr
id: ADR-0026
status: proposed
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0010
superseded_by: null
---

# ADR-0026: Bootstrap merges

## Status

- Proposed

## Context and Problem Statement

`workflows/document-lifecycle.md` defines approval as an event that happens at merge. A
feature spec reaches `approved` when a human merges its PR; a change plan reaches
`approved` the same way; an ADR reaches `accepted` when a human merges the ADR PR. The
merge *is* the approval. That coupling is deliberate and it works: it gives approval a
single unambiguous moment, performed by a human, recorded in git.

It assumes a shape of PR the framework has since outgrown. One document, or a small
coherent set, reviewed and merged as a unit. Under that shape, merging is a considered
act about a specific decision.

PR #71 is not that shape. It carries two feature specs, two change plans, and a growing
set of ADRs, and it exists precisely to bootstrap the workflows that everything after it
depends on. Its own description states that nothing in it is approved or accepted and
that every status transition past `draft`/`proposed` is left to human review.

That intent and `workflows/document-lifecycle.md` cannot both be right. Either merging
PR #71 approves every document in it — collapsing a dozen independent decisions into one
click, on a package too large to evaluate as a single yes — or the lifecycle document is
describing a rule the framework is about to break without saying so.

Neither outcome is acceptable undocumented. A framework whose central claim is that
process gates make drift visible cannot have its largest PR quietly violate its own
lifecycle rule.

The question this ADR answers: **may a merge land governed documents without approving
them, and if so, under what constraints?**

## Decision Drivers

- **Approval must remain a deliberate human act.** Whatever changes, it must not become
  easier to approve something by accident.
- **Merge-as-approval is a good default.** It is unambiguous, human-performed, and
  recorded. It should survive.
- **Large coherent packages are legitimate.** Some work genuinely does not decompose into
  reviewable single-document PRs, and forcing it to would produce artificial
  dependencies between PRs that must land in order.
- **Silence is the failure mode.** The risk is not landing documents un-approved; it is
  landing them un-approved while the lifecycle document says otherwise.

## Considered Options

### Option A — Enforce merge-as-approval without exception

Split PR #71 into a dozen sequential PRs, each approved on merge.

Preserves the rule exactly. Costs a long serialized chain where every PR depends on its
predecessor, and the review burden is not actually reduced — the same decisions get made,
in an order dictated by mechanics rather than by reasoning. Also loses the ability to
evaluate an interlocking set of decisions against each other, which for a bootstrap
package is much of the point.

### Option B — Merging never approves; approval is always a separate act

Decouple entirely. Every document lands as `draft`/`proposed` and a subsequent change
flips status.

Uniform and explicit. But it doubles the number of changes for ordinary single-document
work, and it removes the property that makes merge-as-approval good: a single moment
where a human unambiguously said yes. Approval becomes a status edit, which is exactly
the kind of act an agent could perform without anyone noticing.

### Option C — Merge-as-approval by default, with a declared exception

Keep the default. Permit a **bootstrap merge** — a merge that lands documents without
approving them — when it is declared in advance and its scope is stated.

## Decision Outcome

**Chosen option: Option C — merge-as-approval by default, with a declared exception.**

### The default is unchanged

Merging a PR approves the feature specs and change plans in it and accepts the ADRs in
it, exactly as `workflows/document-lifecycle.md` describes. This is the rule for ordinary
work and no ceremony is added to it.

### Bootstrap merges

A **bootstrap merge** lands governed documents without approving them. It is valid only
when all of the following hold:

1. **Declared before merge.** The PR description states that it is a bootstrap merge and
   lists every document landing un-approved. A merge that turns out to have been a
   bootstrap merge afterwards is not one.
2. **Documents land at `draft` or `proposed`.** Nothing in a bootstrap merge arrives at
   `approved`, `accepted`, `in-progress`, or `implemented`.
3. **Approval is a subsequent, separate change.** Each document's transition to
   `approved` or `accepted` happens in a later change that a human authors or explicitly
   sanctions, and that change touches status fields and index tables only.
4. **No implementation may begin.** ROLE_CONTRACT's spec-first rule applies unchanged: a
   `draft` spec is not implementable. A bootstrap merge lands documents; it authorizes
   nothing.

### When a bootstrap merge is appropriate

When the value of the PR is in the coherence of the package rather than in any single
document, and the number of independent decisions makes a single merge-as-approval act
unreviewable. This is rare by construction. If a PR could reasonably be split into
document-sized PRs without inventing ordering constraints, it should be.

### Why the status quo already half-supports this

`scripts/check-status.sh` does not treat a merged `draft` document as a violation; it
checks FS↔PLAN status *pairing* and index sync. A `draft` FS paired with a `draft` PLAN
passes today. Bootstrap merges therefore need no tooling change — only a statement that
they are legitimate and bounded.

## Consequences

### Positive

- PR #71's intent and the lifecycle document stop contradicting each other, and the
  contradiction is resolved in writing rather than by precedent.
- Approval stays a deliberate act with a named moment, for ordinary work and for
  bootstrap packages alike — in the second case, a later explicit one.
- Large interlocking packages can be evaluated as a set, which is how their decisions
  actually relate.

### Negative

- A new concept in the lifecycle, and concepts are where drift starts. If "bootstrap
  merge" becomes a routine label, the default has been eroded and the exception has
  become the rule.
- Rule 1 (declare in advance) has no automated enforcement. Nothing prevents a PR
  description from claiming bootstrap status after the fact, or from omitting a document
  from its list.
- Between a bootstrap merge and its approval change, trunk carries governed documents
  that look authoritative but are not. A reader who does not check `status:` may act on
  a `draft`.

### Neutral

- No tooling change required; `check-status.sh` already tolerates merged drafts.
- `workflows/document-lifecycle.md` gains a subsection describing the exception. That
  document remains the current-state authority per `ADR-0030`.
- PR #71 is the first and, at time of writing, only instance.

## Validation

- **Signal:** `workflows/document-lifecycle.md` describes bootstrap merges, and any PR
  using one declares it before merge with a complete document list.
- **Signal:** documents landed by a bootstrap merge carry `draft` or `proposed` on trunk
  until an explicit approval change flips them.
- **Signal:** no implementation commit references a spec that is still `draft` after a
  bootstrap merge.
- **Review checkpoint:** at the third bootstrap merge. Three is enough to tell whether
  this is a genuine exception or a default in disguise.
- **Failure condition:** if documents landed by a bootstrap merge remain `draft` for more
  than one release cycle, the package was not ready to merge and the exception is being
  used to defer review rather than to sequence it.

## Links

- `workflows/document-lifecycle.md` — the current-state document this ADR updates, per
  `ADR-0030` rule 3.
- `guidelines/ROLE_CONTRACT.md` §"Spec-first rule" — unchanged; a `draft` spec remains
  non-implementable.
- FS-0010: Process compliance gates and document lifecycle — established the lifecycle
  this ADR carves an exception in.
- ADR-0030: Decision records versus current-state documents — why the rule statement
  lives in the workflow document rather than here.
