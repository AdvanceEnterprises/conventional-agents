---
type: adr
id: ADR-0026
status: accepted
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0010
superseded_by: null
---

# ADR-0026: Approval is a recorded act

## Status

- Accepted

## Context and Problem Statement

`workflows/document-lifecycle.md` defines approval as an event that happens at merge. A
feature spec reaches `approved` when a human merges its PR; a change plan reaches
`approved` the same way; an ADR reaches `accepted` when a human merges the ADR PR. The
merge *is* the approval.

That is a good rule for one shape of work: one document, or a small coherent set,
reviewed and merged as a unit. It is unambiguous, human-performed, and recorded in git.

It does not describe how this repository is actually operated, and the gap runs in the
opposite direction from the one usually worried about. The maintainer's workflow is:
architect session drafts, a review happens, **the human approves in session**, an
implementer session executes the approved PLANs, that work is reviewed and marked
implemented, and only then does the PR merge. By merge time every document in it is
already `approved` and `implemented`. The merge is the last step, not the approval.

An agent following the lifecycle document literally would refuse to flip a status its
human had just approved out loud, because the rule says approval happens at merge and
the merge has not happened. The framework's own description of its process is wrong
about the process.

The inverse case also exists and is not covered. A package too large to evaluate as one
yes — many interlocking documents whose value is their coherence — may need to land
before its individual decisions are approved, so that they can be reviewed against each
other rather than in an order dictated by merge mechanics.

Both are departures from merge-as-approval in opposite directions, and both are
currently undocumented. A framework whose central claim is that process gates make
drift visible cannot have its own approval mechanism be folklore.

The question this ADR answers: **what constitutes an approval, and how does an agent
verify one happened before transitioning a status?**

## Decision Drivers

- **Approval must stay a deliberate human act.** Whatever changes, it must not become
  easier to approve something by accident, or for an agent to approve anything at all.
- **An agent must be able to verify approval mechanically.** "The human seemed happy" is
  not a status transition criterion.
- **Merge-as-approval should survive as the default.** It is unambiguous and free.
- **A verbal approval is real and must leave a trace.** Approval that exists only in a
  conversation is not auditable once the conversation ends — the same defect corrected
  in `ADR-0013`'s session declarations.
- **Silence is not approval.** Neither is a merge the agent performed, nor an approval
  given in a prior session for different work.

## Considered Options

### Option A — Merge is the only approval

Status quo. Every status transition to `approved` or `accepted` happens by merge.

Unambiguous, and wrong about the observed workflow. It would force either the
maintainer to change how they work, or agents to violate the documented rule routinely
— and a rule routinely violated by its own author stops constraining anything.

### Option B — Approval is always a separate recorded act

Merging never approves. Every document reaches `approved` through an explicit
subsequent change.

Uniform and explicit. But it doubles the changes required for ordinary
single-document work, and it discards the property that makes merge-as-approval good: a
single unambiguous moment where a human said yes. Approval becomes a status edit, which
is the kind of act an agent could perform unnoticed.

### Option C — Any clear human statement approves

The agent transitions status when the human says to.

Matches the observed workflow exactly and verifies nothing. There is no artifact, no
named approver, and no way to distinguish "the human approved this" from "the agent
believed the human approved this."

### Option D — Merge-as-approval by default, with two recorded departures

Keep the default. Name two departures, each requiring a locatable act that says who
approved what.

## Decision Outcome

**Chosen option: Option D — merge-as-approval by default, with two recorded
departures.**

### The three approval shapes

| Shape | When approval happens | The record |
| --- | --- | --- |
| **Merge approval** (default) | The human merges the document's PR | The merge itself |
| **Recorded approval** | The human approves before merge, in session | A commit transitioning the status, carrying an `Approved-By:` trailer |
| **Deferred approval** | Documents land un-approved; approval comes later | Declared in the PR description, then a later recorded approval |

All three are human acts. None may be performed by an agent on its own initiative.

### Recorded approval

When a human approves a document in session, the agent records that approval as a
commit transitioning the document's status, carrying:

```text
Approved-By: <Human Name> <human@example.dev>
Approved-Artifacts: FS-0018, PLAN-0018
```

The commit is the approval's durable form. It names who approved, what they approved,
and when. Approval that produced no commit did not happen as far as the framework is
concerned, and the next session has no way to know about it.

**The agent may record the approval. The agent may not be the approval.** This is the
whole constraint. An agent authors the commit exactly as it authors any other, under
its own identity per `ADR-0029`; the `Approved-By:` trailer names a human who is not
the commit's author. A commit whose `Approved-By:` matches its own author email is
malformed.

**What does not constitute approval:**

- Silence, or the absence of objection.
- A human approving something else in the same session.
- An approval given in a prior session, for work that has since changed.
- A merge the agent performed. Agents do not merge (`ADR-0012`).
- The agent's own assessment that the work is ready.

If an agent is unsure whether an approval was given, it has not been given. Ask.

### Approved is provisional until merged

A status set before merge describes **intent for trunk**, not fact about it. Trunk is
the shared state; a branch is a proposal about what that state should become.

So an `approved` spec or an `accepted` ADR on an unmerged branch is provisional. The
approval is real — a human performed it and the record proves it — but it takes full
force when the branch merges, and until then the document is treated as a draft by
anyone outside that branch.

This applies to every status, not only acceptance:

- An `approved` FS on an unmerged branch does not authorize implementation against
  trunk. It authorizes implementation on that branch.
- An `accepted` ADR on an unmerged branch is not yet a binding constraint on other
  work. It becomes one at merge.
- An `implemented` PLAN on an unmerged branch has implemented nothing that anyone else
  can see.

**Why this is the right reading rather than a concession.** The alternative is that a
branch can make a decision binding on trunk without anything reaching trunk, which
would let one session constrain another through work nobody has seen. Merge is already
the human-gated moment (`ADR-0012`); making it also the moment status acquires force
keeps a single gate rather than two.

**Practical consequence for current-state documents.** `ADR-0030` rule 3 requires an
exported document to be updated in the change that accepts the ADR. On a branch, that
update is provisional on the same terms as the acceptance — both land together and both
become real at merge. A branch that accepts an ADR and updates its governing document in
one change is correct; the pair is simply not yet in force.

An agent reading a document **on trunk** may trust its status. An agent working on a
branch must know it is on one.

### Deferred approval

A PR may land governed documents without approving them when:

1. **Declared before merge.** The PR description says so and lists every document
   landing un-approved. A merge that turns out to have been deferred afterwards was
   not.
2. **Documents land at `draft` or `proposed`.** Nothing arrives at `approved`,
   `accepted`, `in-progress`, or `implemented`.
3. **Approval is a subsequent recorded approval**, per the rules above.
4. **No implementation may begin.** The spec-first rule applies unchanged: a `draft`
   spec is not implementable. Deferred approval lands documents; it authorizes nothing.

Appropriate when the value of the PR is the coherence of the package rather than any
single document, and the number of independent decisions makes one merge-as-approval act
unreviewable. Rare by construction: if a PR could be split into document-sized PRs
without inventing ordering constraints, split it.

### Enforcement is by audit, not control

Nothing prevents an agent from writing an `Approved-By:` trailer naming a human who
said nothing. This is the same limitation `ADR-0024` documents for work-item Type and
parked state: no substrate offers the control, so the rule is conduct backed by
detection. What the trailer buys is that the claim is *specific and checkable* — a
named human, named artifacts, a timestamp, in an immutable commit — rather than a
status field that changed for reasons nobody recorded.

## Consequences

### Positive

- The framework's documented approval mechanism matches how it is actually operated,
  which is a precondition for anyone trusting the rest of the lifecycle documentation.
- Approval acquires a durable, machine-readable form. `Approved-By:` is greppable,
  auditable, and checkable by a future gate.
- An agent has a mechanical test for whether it may transition a status, instead of a
  judgment call about conversational tone.
- Merge-as-approval survives untouched for ordinary work, with no added ceremony.
- Large interlocking packages can be evaluated as a set rather than in an order
  dictated by merge mechanics.

### Negative

- A third concept in the lifecycle. If "deferred approval" becomes a routine label, the
  default has eroded and the exception has become the rule.
- `Approved-By:` is unenforceable, as stated above. An agent that fabricates one
  produces a commit that looks exactly like a legitimate approval.
- Recorded approval requires the agent to commit at the moment of approval. An approval
  given and then not committed — session ends, context lost — leaves the document
  un-approved with nobody aware.
- Nothing yet checks that `Approved-By:` differs from the commit author, or that named
  artifacts exist.

### Neutral

- No change to `ADR-0012`. Agents still do not merge, under any of the three shapes.
- No change to the spec-first rule. A `draft` spec remains non-implementable however it
  came to be draft.
- `scripts/check-status.sh` already tolerates a merged `draft` document, so deferred
  approval needs no tooling change to be viable — only a statement that it is
  legitimate and bounded.

## Validation

- **Signal:** `workflows/document-lifecycle.md` describes all three shapes, and status
  transitions in this repository use one of them.
- **Signal:** every `draft → approved` or `proposed → accepted` transition not performed
  by a merge carries an `Approved-By:` trailer naming a human.
- **Signal:** no `Approved-By:` trailer matches its own commit's author email.
- **Signal:** PRs using deferred approval declare it before merge with a complete
  document list.
- **Review checkpoint:** at the third deferred-approval PR. Three is enough to tell
  whether it is a genuine exception or a default in disguise.
- **Failure condition:** if documents landed by deferred approval remain `draft` for
  more than one release cycle, the package was not ready to merge and the mechanism is
  being used to defer review rather than sequence it.

## Links

- `workflows/document-lifecycle.md` — the current-state document this ADR updates, per
  `ADR-0030` rule 3.
- `guidelines/ROLE_CONTRACT.md` §"Spec-first rule" — unchanged; a `draft` spec remains
  non-implementable.
- ADR-0012: Non-overridable gates — agents do not merge, under any approval shape.
- ADR-0024: Detection over prevention — why `Approved-By:` is audited rather than
  enforced.
- ADR-0029: Commit-author naming — the identity an agent records an approval under,
  which is never the approver's.
- FS-0010: Process compliance gates and document lifecycle — established the lifecycle
  this ADR extends.
- FS-0022: Gate coverage — the natural home for an `Approved-By:` check, not yet
  specified there.
