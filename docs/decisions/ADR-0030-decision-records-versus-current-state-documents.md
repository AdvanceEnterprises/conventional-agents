---
type: adr
id: ADR-0030
status: proposed
decision_scope: architecture
reversible: yes
related_specs: []
superseded_by: null
---

# ADR-0030: Decision records versus current-state documents

## Status

- Proposed

## Context and Problem Statement

The framework maintains two families of document that both describe how something works.
ADRs in `docs/decisions/` are internal governance. Workflow documents, guidelines,
skills, templates, and integration bindings are exported surface — the material agents
and consumers actually read. `ADR-0009` separates the two by audience, but says nothing
about which one is authoritative when both describe the same rule.

The gap produced a concrete failure. The commit-attribution convention existed
simultaneously in `ADR-0018`, in `workflows/git-and-gh-conventions.md`, and in
`skills/git-gh-workflow/SKILL.md`. When `ADR-0029` changed which field carries the model,
two of those three went stale, and the stale copies were the ones agents read. The ADR
that was correct was the one nobody consults during work.

The first attempted remedy made it worse. To avoid a reader following a link and landing
on a partially-void document, the rule was: an ADR that overrides part of an earlier ADR
must replicate the earlier one in full, and mark it superseded. Applied once, this turned
a 50-line decision into a 290-line document. Applied repeatedly it compounds — each
partial override inherits everything its predecessor inherited, and the ADR log becomes a
chain of increasingly large near-duplicates.

The replication cost is a symptom. The cause is that ADRs are being asked to do two jobs
that pull in opposite directions:

| | Recording a decision | Stating current rules |
| --- | --- | --- |
| Wants to be | Fixed at a point in time | Always now |
| On change | Superseded by a new record | Edited in place |
| Completeness | Complete for its own decision | Complete for the whole convention |

`docs/decisions/README.md` already commits to the first: once accepted, an ADR is
append-only, and only its Status section may evolve. That policy is incompatible with
also being the current statement of a rule. Replication was an attempt to satisfy both,
and satisfying both is what costs.

The question this ADR answers: **when a rule changes, which document is authoritative,
and what must be updated?**

## Decision Drivers

- **A reader must never chase links to learn a current rule.** This was the original
  objection to partial supersession and it is correct.
- **A reader must still be able to learn why a rule is what it is,** including which
  options were rejected.
- **Duplication invites staleness.** Every copy of a rule is a copy that can rot, and the
  copies that rot are the ones not being read at the moment of change.
- **ADR immutability is settled policy.** `docs/decisions/README.md` already makes
  accepted ADRs append-only; this ADR must not quietly reverse that.
- **ROLE_CONTRACT's precedence order is settled policy.** Accepted ADRs sit at level 1.
  Nothing here may demote them.

## Considered Options

### Option A — ADRs are authoritative; exported docs are summaries

Exported documents become short pointers back to the ADR log. One authority, no
ambiguity.

But it requires ADRs to stay current, which contradicts append-only immutability, and it
routes every practical question — "how do I set my git identity" — into internal
governance documents that were never written for that audience.

### Option B — Full replication on partial supersession

The rule tried before this ADR. Every superseding ADR restates its predecessor entirely.

Gives a reader one complete document, at the cost of unbounded growth and N copies of
every long-lived convention. Also produces a subtle trap: two ADRs both claiming
completeness over the same rule, with no way for a reader landing on the earlier one to
know the later exists.

### Option C — ADRs record decisions; exported documents carry current state

Two families, two jobs, no overlap. An ADR states what was decided and why. The exported
document states what to do now, and is updated in place whenever a decision changes it.

### Option D — Merge the families

Abandon ADRs; record decisions inline in the workflow documents they affect.

Removes duplication entirely, and removes the decision log with it. Rejected options,
drivers, and the reasoning behind a rule have nowhere to live, and "why is it this way"
becomes unanswerable — which is the question ADRs exist for.

## Decision Outcome

**Chosen option: Option C — ADRs record decisions; exported documents carry current
state.**

### The two families

| | Decision record | Current-state document |
| --- | --- | --- |
| Answers | Why is it this way? What was rejected? | What do I do? |
| Time frame | Fixed at the decision date | Always now |
| Mutability | Append-only after acceptance | Edited in place |
| Audience | Maintainers, future architects | Agents, contributors, consumers |
| Lives in | `docs/decisions/` | `workflows/`, `guidelines/`, `skills/`, `templates/`, `integrations/` |
| Complete for | Its own decision | The whole convention |

### The rules

1. **One current statement.** Every rule has exactly one current-state document that
   states it. Other documents may reference that document; they may not restate the rule.
2. **ADRs may quote, but do not own.** An ADR states the rule as decided, for legibility.
   It is not the place a reader looks up what the rule is today.
3. **Same-change obligation.** An ADR that changes a rule MUST update the governing
   current-state document in the same change. An ADR that changes a rule without updating
   it is incomplete, and the document hygiene gate should treat it as such.
4. **Supersession is for reversal, not revision.** Mark an ADR `superseded` when its
   decision is abandoned or replaced wholesale. A later ADR revising one rule within an
   earlier decision does not supersede it — both remain accurate records of what was
   decided when.

### Precedence is unchanged

`guidelines/ROLE_CONTRACT.md` places accepted ADRs at precedence level 1, above
architecture documentation and everything below it. **This ADR does not alter that.**

A current-state document is a **materialized view** over the set of accepted ADRs, not a
competing authority. Its correctness is a maintenance obligation created by rule 3, not
a claim that outranks a decision.

The practical consequence for a reader who finds a current-state document disagreeing
with an individual ADR: the likely explanation is that a **later ADR revised that rule**,
and they have read one node of a chain rather than the whole chain. The correct action is
to check for a later ADR on the same subject. If none exists, the current-state document
is stale — a defect to report and fix under rule 3, not a precedence question to resolve
by picking a winner.

### Applied instance

`ADR-0018` and `ADR-0029` are the worked example. ADR-0018 records the single-identity
attribution decision made 2026-07-27 and remains `accepted`; ADR-0029 records the later
decision to move the model into `user.name`. Neither is superseded, because neither
decision was reversed. The convention in force lives in
`workflows/git-and-gh-conventions.md` §"Single-identity workflow with agent
co-attribution", which both ADRs point to and which ADR-0029 updated in the same change.

## Consequences

### Positive

- ADRs stay small and decision-shaped. Replication disappears, and with it the
  compounding growth.
- One place to look for any current rule, which is what the partial-supersession
  objection actually wanted.
- ADR immutability and the decision log's historical value are both preserved.
- The `superseded` status regains meaning. Under replication it was becoming a routine
  bookkeeping flag; it now marks genuine reversal.
- The exported surface becomes the thing agents read, which is what `ADR-0009` intended.

### Negative

- Rule 3 is an obligation with no automated enforcement today. An ADR can be merged
  without its current-state update, and the failure is silent until someone follows stale
  guidance. A `check-status.sh` extension could catch the common case — an ADR whose
  `Links` name a current-state document that the same change did not touch — but that is
  not built here.
- Determining which document governs a rule requires judgment when a rule spans
  surfaces. Commit attribution touches `workflows/`, `skills/`, and `templates/`; rule 1
  says one of them states it and the others reference it, but not which.
- Existing documents do not comply. Several conventions are currently stated in more than
  one place, and reconciling them is unscoped work.

### Neutral

- No change to ROLE_CONTRACT, to the precedence order, or to `docs/decisions/README.md`'s
  immutability policy. This ADR clarifies how those interact rather than amending any of
  them.
- Nothing here dictates how a current-state document is structured. That remains the
  province of whichever document it is.

## Validation

- **Signal:** for any rule changed by an ADR after acceptance of this one, the same
  change updates a current-state document. Checkable by inspecting the diff of any
  rule-changing ADR.
- **Signal:** no ADR authored after this one restates a prior ADR in full for the purpose
  of superseding it in part.
- **Signal:** `superseded` appears only on ADRs whose decision was abandoned or replaced
  wholesale, not on ADRs one of whose rules was later revised.
- **Review checkpoint:** the next time a convention stated in more than one exported
  document goes stale. If rule 1 did not prevent it, the rule needs enforcement rather
  than restatement.
- **Failure condition:** if agents are observed following stale exported guidance because
  an ADR changed a rule without updating its current-state document, rule 3 needs
  automated enforcement and this ADR should be extended rather than merely cited.

## Links

- ADR-0009: Separate exported surface from internal governance — establishes the audience
  split this ADR assigns jobs to.
- ADR-0018 / ADR-0029: the worked instance; neither supersedes the other, and
  `workflows/git-and-gh-conventions.md` carries the convention in force.
- `docs/decisions/README.md` §"Editing Rules and Immutability" — the append-only policy
  this ADR is compatible with.
- `guidelines/ROLE_CONTRACT.md` §"Conflict Resolution Rules" — the precedence order this
  ADR leaves unchanged.
