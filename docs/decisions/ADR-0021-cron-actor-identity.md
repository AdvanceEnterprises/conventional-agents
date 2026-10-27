---
type: adr
id: ADR-0021
status: accepted
decision_scope: workflow
reversible: yes
related_specs:
  - FS-0018
superseded_by: null
updated: 2026-07-28
---

# ADR-0021: Cron actor identity for unattended agents

## Status

- Accepted

## Context and Problem Statement

ADR-0018 established a three-layer attribution convention for a single-GitHub-identity
workflow: `user.email` distinguishes actors, `Co-authored-by:` names non-primary
contributors in hybrid sessions, and `Agent-Attribution:` records model, role, and
session mode. It was written for agents operating in interactive sessions, supervised
by a human.

FS-0018 Path 3 introduces actors that convention does not cover: agents fired by cron
ticks, webhooks, or scheduled detection, with no human in the loop at all. FS-0018
names this an explicit blocker — Paths 1 and 2 are implementable, Path 3 is not, until
this question is answered.

The gap is narrow but consequential. If a cron-fired agent commits as
`hermes-agent@tais-den.dev`, its work is indistinguishable in `git log` from an agent
that a human was actively supervising. The two carry very different warrant. A
supervised commit was watched by a person who could interrupt it. An unattended commit
was not. An auditor reading the history cannot tell them apart, which means the
distinction ADR-0018 exists to create — *who actually did this* — collapses at exactly
the point where it matters most.

This also undermines ADR-0019's autonomous gate. That gate applies only to agents
"operating without a human present." If the audit trail cannot distinguish attended
from unattended actors after the fact, the gate cannot be verified — only trusted.

The question this ADR answers: **how does an unattended actor identify itself so that
its lack of supervision is visible in the record?**

## Decision Drivers

- **Unattended work must be distinguishable from supervised work**, at commit level
  and at Issue-comment level, by reading the artifact alone.
- **The distinction must survive `git log`.** It cannot depend on external systems,
  dashboards, or the memory of whoever configured the cron job.
- **ADR-0019's gate must be auditable after the fact.** Verifying that the autonomous
  gate held requires identifying which actions were autonomous.
- **Which trigger fired must be recoverable.** "Some cron job did this" is not enough
  to debug a misbehaving schedule; the specific job must be named.
- **It must not require new GitHub accounts.** ADR-0018 deliberately deferred
  multi-account setup; this ADR should not silently reintroduce it.
- **Compromise blast radius should be bounded.** An unattended actor's credentials sit
  on a machine unattended by definition.

## Considered Options

### Option A: Reuse the interactive agent identity

Cron-fired Hermes commits as `hermes-agent@tais-den.dev`, the same address used in
interactive sessions. The `Agent-Attribution:` trailer's `session=` field is the only
thing distinguishing the two.

### Option B: Reuse the human identity

Cron jobs run under the repo owner's credentials and commit as
`taisden@tais-den.dev`, since the human configured the schedule and is ultimately
responsible.

### Option C: Distinct email per unattended actor, with mandatory autonomous markers

Unattended actors use a dedicated `user.email` distinct from both human and
interactive-agent addresses. Every unattended action additionally carries
`mode=autonomous` and names its triggering job in `session=`.

### Option D: Separate GitHub account per unattended actor

Create a real GitHub account (e.g., `taisden-cron`) with its own token, per ADR-0011's
multi-identity model, scoped to autonomous work.

## Decision Outcome

**Chosen option: Option C — distinct email per unattended actor, with mandatory
autonomous markers.**

### The actor table

ADR-0018's actor table gains a row per unattended actor:

| Actor | `user.name` | `user.email` |
| --- | --- | --- |
| Human (Joey) | `Joey Clark` | `taisden@tais-den.dev` |
| Hermes Agent (interactive) | `Hermes Agent` | `hermes-agent@tais-den.dev` |
| Hermes Agent (unattended) | `Hermes Agent (cron)` | `hermes-cron@tais-den.dev` |

The pattern generalizes: an unattended actor uses the interactive actor's address with
a trigger-class suffix on the local part. A webhook-fired actor would use
`hermes-webhook@tais-den.dev`. Consumer repos choose their own addresses; the binding
rule is that **the address differs from both the human address and the interactive
agent address**.

### Mandatory markers

Every action by an unattended actor MUST carry two additional markers beyond the
distinguishing email.

On commits, via the `Agent-Attribution:` trailer:

```text
Agent-Attribution: actor=Hermes Agent (cron); model=<provider/model-id>; role=<role>; session=<job-name>; mode=autonomous
```

On Issue comments, via the agent-stance format from FS-0018:

```text
agent-stance: mode=autonomous; role=<role>; model=<model>; session=<job-name>; rationale=<reason>
```

Both markers are required:

- **`mode=autonomous`** is the assertion that no human was present. It is what makes
  ADR-0019's gate auditable — every action carrying this marker was subject to the
  Type-keyed checkpoint.
- **`session=<job-name>`** names the specific trigger: the cron job name, the webhook
  event source, or the delegating parent session. Not a generic label like `cron`.
  `session=nightly-status-check` is compliant; `session=cron` is not.

### Interaction with `Co-authored-by:`

An unattended actor never emits a `Co-authored-by:` trailer naming a human. That
trailer means a human contributed to the commit, which by definition did not happen.
Emitting one would misrepresent supervision that did not occur.

### Credential scope

An unattended actor's token SHOULD be scoped to the minimum required for its work.
Where the platform supports it, this means no merge permission — making ADR-0012's
merge gate technically enforced for unattended actors rather than convention-enforced.
This is a recommendation, not a requirement, because token scoping capability varies by
platform.

### Why not the other options?

**Option A** puts the entire distinction inside one field of one trailer. A commit
missing its `Agent-Attribution:` trailer — through a bug, a misconfiguration, or an
agent that simply forgot — becomes silently indistinguishable from supervised work.
The email is the layer most likely to be set correctly, because it is set once in
config rather than constructed per commit. Putting the load-bearing distinction on the
fragile layer inverts the reliability ordering.

**Option B** is the worst available option and worth stating plainly: it attributes
unattended machine actions to a human who was, at the time, most likely asleep. It
destroys exactly the accountability the attribution convention exists to create, and it
makes the audit trail actively misleading rather than merely incomplete.

**Option D** is the correct long-term destination and premature today, for the same
reason ADR-0018 gave: operational cost is real, enforcement benefit is small while the
number of unattended actors is small. This ADR is deliberately the stepping stone —
the distinguishing email maps directly onto a separate account login when that
transition happens, exactly as ADR-0018 anticipated. Option D also does not remove the
need for `mode=autonomous` and `session=`; a separate account tells you *which actor*,
not *which trigger*.

## Consequences

### Positive

- Unattended work is distinguishable from supervised work by `git log` alone, with no
  external system required.
- ADR-0019's autonomous gate becomes auditable after the fact: filter for
  `mode=autonomous` and verify no action exceeded its Type-keyed checkpoint.
- The specific triggering job is recoverable from any artifact, making a misbehaving
  schedule debuggable.
- FS-0018 Path 3's stated blocker is resolved; autonomous Issue creation becomes
  implementable.
- Where token scoping is available, the merge gate gains technical enforcement for the
  actor class most likely to run unsupervised.

### Bad

- Another email alias must be kept valid per unattended actor, and the
  `tais-den.dev` domain must remain under the repo owner's control.
- Two markers must be emitted correctly on every unattended action. An agent that sets
  its email correctly but omits `mode=autonomous` produces a partially-compliant record
  — better than Option A's failure mode, but still degraded.
- Consumer repos running many distinct schedules face a choice between one address per
  trigger class (more addresses) or one shared unattended address distinguished only by
  `session=` (fewer addresses, more load on the trailer).

### Neutral

- The specific addresses are recommendations. The binding constraint is the
  *distinction*, not the literal strings.
- This ADR does not change interactive-session attribution. ADR-0018's convention is
  unmodified for supervised work.
- Whether a delegated subagent counts as unattended depends on whether a human is in
  the loop for the parent session, not on the delegation mechanism itself.

## Validation

We will consider this decision successful if:

1. **Unattended commits carry a distinct email.**
   `git log --format='%an <%ae>' -n 100 | sort -u` shows the unattended address as
   distinct from both human and interactive-agent addresses.
2. **Every unattended action carries both markers.** Sampling commits and Issue
   comments from the unattended address shows `mode=autonomous` and a specific
   `session=<job-name>` on each.
3. **`session=` values are specific.** No compliant action uses a generic value such
   as `cron` or `automated`.
4. **The autonomous gate is verifiable.** Filtering the Issue timeline for
   `mode=autonomous` and checking Status transitions against ADR-0019's table produces
   no violations.
5. **No unattended commit carries a human `Co-authored-by:` trailer.**

## Links

- FS-0018: Issue lifecycle and autonomous triggers (names cron actor identity as the
  explicit blocker for Path 3; this ADR resolves it)
- ADR-0018: Single-identity workflow with agent co-attribution (the three-layer
  convention this ADR extends to unattended actors)
- ADR-0019: Issue Type immutability and the autonomous gate (the gate whose
  "without a human present" condition this ADR makes auditable)
- ADR-0011: Multi-identity GitHub model (the separate-account model this convention
  maps onto if adopted later)
- ADR-0012: Non-overridable gates (the merge gate that credential scoping can
  technically enforce for unattended actors)
- ADR-0022: Autonomous and consensus meta-modes (defines `mode=autonomous` in the
  session-mode vocabulary)
- `workflows/git-and-gh-conventions.md` (workflow doc updated by this ADR)
