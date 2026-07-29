---
type: adr
id: ADR-0020
status: accepted
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0018
superseded_by: null
---

# ADR-0020: The `question` label suppresses agent Issue actions

## Status

- Accepted

## Context and Problem Statement

FS-0018 defines six Issue labels, five of which classify content or workflow
position. The sixth, `question`, is different in kind: it does not describe the
work, it describes the *state of the conversation about* the work. An Issue
carrying `question` is parked, waiting on a human to answer something.

Without a rule, an agent encountering a parked Issue behaves exactly as it would on
any other Issue. It reads the Issue, forms a view, and acts — posting comments,
adjusting labels, advancing Status. This produces a specific and corrosive failure:
the agent answers its own question.

The sequence is unremarkable in isolation and bad in aggregate. An agent asks a
clarifying question and applies `question`. A later invocation of the same agent
(or a peer session) reads the Issue, sees an unanswered question, reasons about it,
and posts what looks like a resolution. A third invocation reads that resolution as
settled context and proceeds to implement against it. No human ever answered. The
Issue timeline shows a question being raised and resolved, but the resolution is
the agent's own inference wearing the costume of an answer.

The autonomous gate (ADR-0019) does not prevent this, because the gate constrains
*Status advancement by Type*, not commenting or label changes. An agent can churn
indefinitely inside an authorized Status range while a question sits unanswered.

The question this ADR answers: **what makes a parked Issue actually stay parked?**

## Decision Drivers

- **A question must be answered by its intended audience.** The value of asking a
  human is that a human answers. An agent-generated answer to an
  agent-generated question is a closed loop with no external input.
- **Parked must mean parked.** If a label signals "waiting on human," the framework
  must give that signal force, or the label is decoration.
- **The suppression must be escapable.** A rule that traps Issues in `question`
  forever is worse than no rule. There must be a defined exit.
- **The mechanism must work without technical enforcement.** Consumer repos may or
  may not implement webhook rejection. The primary mechanism must be agent-side and
  checkable.
- **Suppression should be narrow.** It should stop agent action on the parked
  Issue, not halt unrelated work or block humans.

## Considered Options

### Option A: No suppression; `question` is advisory

The label documents that a question was asked. Agents may continue to act. Humans
are expected to notice and respond.

### Option B: Full suppression until a human removes the label

While `question` is present, agents perform no Issue actions at all. Only a human
may remove the label, which un-parks the Issue.

### Option C: Suppression with agent-side self-removal on resolution

While `question` is present, agents perform no Issue actions **except** removing
the `question` label itself, and only when a human's response in the Issue timeline
resolves the question.

### Option D: Time-boxed suppression

Suppression expires after a configured interval (e.g., 72 hours), after which
agents may resume acting and treat the question as implicitly waived.

## Decision Outcome

**Chosen option: Option C — suppression with agent-side self-removal on
resolution.**

### The rule

While the `question` label is present on an Issue, an agent MUST NOT perform any
Issue action on that Issue. Specifically prohibited: posting comments, adding or
removing other labels, and changing Status.

The single permitted action is **removing the `question` label itself**, and only
when a human comment in the Issue timeline answers the outstanding question.

### The mechanism

Suppression is **agent-side and precondition-checked**. Before any Issue action, an
agent reads the Issue's current label set. If `question` is present, the agent skips
the action and takes no further steps on that Issue in that invocation.

This ordering matters: the check happens *before* the action, not as a rollback
after. An agent that has already drafted a comment discards it rather than posting
it.

Consumer repos MAY additionally enforce suppression by rejecting agent-originated
Issue mutations at the webhook handler while `question` is present. This is
defense in depth, not the primary mechanism.

### The exit

The Issue un-parks when the `question` label is removed. Two actors may remove it:

- **A human**, at any time, for any reason — including deciding the question is
  moot.
- **An agent**, only after a human comment in the timeline answers the question.
  The agent removing the label MUST post its agent-stance comment recording that it
  is un-parking the Issue and citing the human comment that resolved it.

The second path is what prevents the trap. Without it, every parked Issue would
require a human to both answer *and* perform label bookkeeping. With it, the human
answers and the agent resumes — but only on the strength of a real human answer.

### Why not the other options?

**Option A** is the status quo that motivates this ADR. An advisory label does not
prevent the self-answering loop; it only documents that a question existed before
the agent talked itself into an answer.

**Option B** is safe but creates the trap. Every question requires two human
actions — answering and un-labeling — and the second is pure bookkeeping that a
human will forget. Issues accumulate in a parked state with answers sitting in the
timeline, unread by any agent because the label was never cleared.

**Option D** converts human silence into consent. This is precisely backwards: the
questions most likely to go unanswered for 72 hours are the ones touching decisions
the human finds hard, ambiguous, or consequential. Auto-waiving exactly those is
the worst possible default. Silence is not an answer, and a timeout that treats it
as one launders inattention into authorization.

## Consequences

### Positive

- The self-answering loop is closed. An agent cannot resolve its own question,
  because it cannot act on the Issue at all while the question stands.
- Parked Issues stay parked without trapping them. The agent-side exit removes the
  bookkeeping burden from the human.
- The rule is cheap to implement — one label-set read before acting — and requires
  no infrastructure.
- The audit trail is legible. The Issue timeline shows the question, the human
  answer, and the agent's explicit un-parking comment citing that answer.

### Bad

- The agent must judge whether a human comment actually resolves the question.
  A partial or tangential human reply might be read as resolution. This is a
  judgment call the framework cannot eliminate, only constrain by requiring the
  agent to cite the specific comment it relied on.
- Suppression is per-Issue and does not propagate. A question on Issue A does not
  suppress agent action on dependent Issue B, even when the answer would change
  B's approach. Cross-Issue dependency handling is out of scope.
- An agent that applies `question` liberally can park its own work indefinitely,
  awaiting answers to questions it did not need to ask.

### Neutral

- Humans are never suppressed. The rule constrains agents only; a human may comment,
  relabel, or advance a parked Issue freely.
- `question` composes with the other labels. An Issue may carry `enhancement` and
  `question` simultaneously; the suppression applies regardless of what else is
  present.
- The rule is independent of Type and of the ADR-0019 autonomous gate. A parked
  Type `task` Issue is suppressed just as fully as a parked Type `feature` Issue,
  and suppression applies whether or not a human is present in the session.

## Validation

We will consider this decision successful if:

1. **No agent comments appear between a `question` label application and its
   removal.** Auditing parked Issues shows a gap in agent activity spanning the
   parked interval.
2. **Un-parking comments cite a human comment.** Every agent-performed `question`
   removal is accompanied by an agent-stance comment referencing the resolving human
   comment.
3. **Parked Issues do not accumulate.** The count of Issues carrying `question` with
   an answered-but-uncleared state trends to zero, demonstrating the agent-side exit
   is functioning.
4. **No self-answered questions.** Review of a sample of previously-parked Issues
   shows no case where the resolving comment was agent-authored.
5. **`test/FS-0018/issue-lifecycle.bats` passes**, including the `question` label
   assertions.

## Links

- FS-0018: Issue lifecycle and autonomous triggers (defines the six labels and
  states this suppression rule as a proposed default; this ADR ratifies it)
- ADR-0019: Issue Type immutability and the autonomous gate (the other agent-action
  constraint on the Issue layer; this ADR's suppression applies independently of
  Type and of human presence)
- ADR-0021: Cron actor identity (cron-fired agents are subject to this suppression
  like any other agent)
- `guidelines/ROLE_CONTRACT.md` §"Role and session transparency" (the agent-stance
  declaration required on the un-parking comment)
