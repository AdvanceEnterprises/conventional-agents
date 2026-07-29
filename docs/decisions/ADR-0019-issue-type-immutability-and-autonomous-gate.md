---
type: adr
id: ADR-0019
status: accepted
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0018
superseded_by: null
---

# ADR-0019: Issue Type immutability and the autonomous gate

## Status

- Accepted

## Context and Problem Statement

FS-0018 defines a three-axis Issue schema (Type, Label, Status) as the canonical
entry point for governed work. Of the three axes, **Type** is load-bearing in a way
the other two are not: it determines which safety gate applies to the Issue.

- Type `feature` requires FS + PLAN before implementation. Highest gate.
- Type `bug` may require an FS if the fix involves design. Medium gate.
- Type `task` requires no FS. Lowest gate.

This creates a specific hazard that does not exist for Labels or Status. An agent
that can edit its own Issue's Type can **lower its own safety gate**. An agent
holding an Issue it would rather not write an FS for can reclassify `feature` →
`task` and proceed directly to implementation. Nothing in the framework's existing
rules prevents this, because ADR-0012's gates govern merging and identity, not
Issue metadata.

The second half of the problem is temporal rather than structural. Even with Type
fixed, an agent operating **without a human present** — cron-fired, webhook-
triggered, or delegated as a subagent — can advance an Issue through its entire
Status lifecycle unattended. The merge gate (ADR-0012) still catches the final
step, but by then the agent has drafted, committed, and opened a PR against work
that no human ever authorized. The merge gate becomes the only review point, which
overloads it.

The question this ADR answers: **what stops an unattended agent from
self-authorizing work?**

## Decision Drivers

- **An agent must not be able to lower its own safety gate.** This is the
  structural invariant. Whatever mechanism is chosen must make gate-lowering
  impossible or at minimum detectable and rejectable.
- **Human authorization must occur before substantial work, not only at merge.**
  ADR-0012's merge gate is a backstop, not a workflow. Relying on it alone means
  humans review finished work rather than authorizing proposed work.
- **Autonomous operation must remain useful.** A gate that blocks every autonomous
  action reduces cron-fired agents to notification bots. The framework wants
  agents that can detect drift, investigate, and propose — just not ones that can
  self-authorize.
- **The gate must be proportionate to risk.** A dependency bump and a governance
  change should not face identical friction. Type already encodes risk; the gate
  should key off it.
- **Enforcement may be convention-level.** The framework describes behavior;
  consumer repos implement webhooks. A rule that requires technical enforcement in
  the framework itself is not implementable at this layer.

## Considered Options

### Option A: No restriction on Type; rely on the merge gate

Agents may edit Type freely. ADR-0012's human merge gate is the sole checkpoint.
Any mistake or self-authorization is caught when a human reviews the PR.

### Option B: Type is immutable to everyone after Issue creation

Once set, Type cannot change — not by agents, not by humans. Misclassification
requires closing the Issue and opening a new one.

### Option C: Type is human-mutable only, plus a Type-keyed autonomous gate

Agents may not change Type; they may only *flag* a suspected misclassification via
Issue comment. Separately, an agent operating without a human present may not
advance Status past a checkpoint determined by Type.

### Option D: Type is agent-mutable but only upward (toward higher severity)

Agents may reclassify `task` → `feature` but never `feature` → `task`. A
monotonic ratchet toward stricter gates.

## Decision Outcome

**Chosen option: Option C — Type is human-mutable only, plus a Type-keyed
autonomous gate.**

### Part 1: Type immutability by agents

An agent MUST NOT change the Type field of an Issue.

An agent that believes an Issue's Type is wrong MUST post an Issue comment stating
the suspected correct Type and the reason, in the agent-stance format defined by
FS-0018. The human decides.

This applies to every agent regardless of role, session mode, or whether a human is
present. A Head Architect agent in an interactive session has no more authority to
change Type than a cron-fired agent does. Type is a human-held control.

Where technical enforcement is available (GitHub Projects field permissions,
webhook handler rejection), consumer repos SHOULD enforce this. Where it is not,
the rule is convention-level and the audit trail is the enforcement mechanism: the
attempt is visible in the Issue timeline.

### Part 2: The autonomous gate

An agent operating **without a human present** MUST NOT advance an Issue's Status
past the checkpoint determined by its Type:

| Type | Autonomous agent may advance Status up to | Human approval required to go beyond |
| --- | --- | --- |
| `feature` | Approved | Yes — Status → In Progress needs human authorization |
| `bug` | Approved | Yes — the proposed fix needs human authorization |
| `task` | In Progress | Yes — at the merge gate (ADR-0012) |

"Without a human present" means cron-fired, webhook-triggered, or operating as a
delegated subagent with no interactive human in the loop. An agent in an
interactive session with a human is not subject to this gate — the human's presence
*is* the authorization.

One transition is exempt: for Type `task` at Status In Progress, opening a PR
transitions Status → In Review automatically. This is permitted because the PR
itself is the human-review surface; advancing to In Review creates the review
opportunity rather than bypassing it.

### Composition with ADR-0012

This gate composes with, and does not replace, ADR-0012's merge gate. Even inside
an authorized Status range, an agent MUST NOT merge. The two gates are independent:

- ADR-0012 asks: *may this actor merge?* Answer: never, if it is an agent.
- ADR-0019 asks: *may this actor advance this Issue?* Answer: up to a Type-keyed
  checkpoint, if no human is present.

An autonomous agent working a Type `task` Issue may therefore draft, commit, open a
PR, and move Status to In Review — and then must stop.

### Why not the other options?

**Option A** makes the merge gate the only checkpoint. That is exactly the overload
this ADR exists to prevent: humans end up reviewing completed work rather than
authorizing proposed work, and an agent that lowered its own Type has already done
the work by the time anyone looks.

**Option B** (immutable to everyone) is too rigid. Misclassification is common and
expected — FS-0018's own default rule ("when in doubt, choose the higher-severity
Type") guarantees some Issues start over-classified. Forcing a close-and-reopen
cycle for a routine correction adds friction with no safety benefit, since humans
correcting Type is not the hazard.

**Option D** (upward-only ratchet) is clever but solves the wrong half. It prevents
gate-lowering, which is good, but it leaves the temporal problem entirely
unaddressed: an autonomous agent can still take a correctly-classified `task` Issue
from Backlog to a merged PR without a human authorizing anything before the merge.
It also creates a one-way trap where an agent's over-cautious reclassification
cannot be undone by the agent, only by a human — which means Option D still needs
a human-mutability rule, at which point Option C is simpler.

## Consequences

### Positive

- An agent cannot lower its own safety gate. The structural invariant holds
  regardless of role, model, or session mode.
- Human authorization moves earlier in the lifecycle. Humans authorize proposed
  work at the Type-keyed checkpoint rather than only reviewing finished work at
  merge.
- Friction is proportionate to risk. Type `task` work flows nearly to the merge
  gate autonomously; Type `feature` work stops early.
- The merge gate is decongested. It becomes the last checkpoint rather than the
  only one.
- Misclassification remains cheap to fix — a human edits the field.

### Bad

- Framework-level enforcement is convention-only. The framework cannot technically
  prevent an agent from calling the GitHub API to change Type; it can only require
  that agents not do so and that the attempt be auditable. Consumer repos that want
  hard enforcement must implement it in their webhook handlers.
- "Without a human present" requires the agent to correctly self-assess its own
  context. An agent that misjudges a delegated-subagent invocation as interactive
  would apply the wrong gate.
- Autonomous Type `feature` work stalls at Approved until a human acts. For a
  cron-fired drift detector that finds a governance gap, this means the finding
  sits until reviewed — which is intended, but is latency nonetheless.

### Neutral

- The gate is keyed off Type, which means changing an Issue's Type changes its
  gate. Since Type is human-mutable only, this is a human-held lever: a human can
  deliberately raise or lower the gate for a specific Issue by editing Type.
- Labels and Status remain agent-mutable (subject to the gate and to ADR-0020's
  `question` suppression). Only Type is human-held.
- This ADR does not define how consumer repos represent the Type field. FS-0018
  recommends a GitHub Project single-select field with a title-prefix fallback.

## Validation

We will consider this decision successful if:

1. **No agent-authored Type changes appear in Issue timelines.** Auditing a
   sample of Issues shows Type changes attributed only to human actors.
2. **Type-correction comments exist.** At least one Issue shows an agent posting a
   suspected-misclassification comment rather than editing the field, demonstrating
   the flagging path is used rather than ignored.
3. **Autonomous Type `feature` Issues stall at Approved.** A cron-created or
   cron-advanced Type `feature` Issue does not reach In Progress without a human
   action recorded in its timeline.
4. **Autonomous Type `task` Issues reach In Review.** The permitted
   In Progress → In Review transition on PR-open occurs without human intervention,
   confirming the gate is not over-blocking.
5. **`test/FS-0018/issue-lifecycle.bats` passes**, including the Type-mutability and
   autonomous-gate assertions.

## Links

- FS-0018: Issue lifecycle and autonomous triggers (defines the three-axis schema
  and states these rules as proposed defaults; this ADR ratifies them)
- ADR-0012: Non-overridable gates (the merge gate this gate composes with)
- ADR-0018: Single-identity workflow with agent co-attribution (the attribution
  layers that make Type-change attempts auditable)
- ADR-0020: `question` label suppression (the other agent-action suppression rule
  on the Issue layer)
- ADR-0021: Cron actor identity (defines how "without a human present" actors
  identify themselves)
- `workflows/document-lifecycle.md` (the FS/PLAN/ADR state machine this Issue layer
  sits above)
