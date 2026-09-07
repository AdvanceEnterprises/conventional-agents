---
name: work-item-stance
description: "Declaring agent stance on a governed work item and respecting the autonomous gates — the agent-stance activity entry, Type-keyed phase checkpoints, question-label suppression, and unattended actor identity. Use before any label, phase, or comment action on a work item, and whenever running unattended from cron, a webhook, or a scheduled trigger."
license: MIT
---

# Work-Item Stance and Autonomous Gates Skill

Governed work starts before the first commit — at the work item. This skill
covers what an agent must record before acting on one, and how far an unattended
agent may take it.

## Source Documents

- `docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md` — work-item schema, stance format, autonomous gate
- `docs/decisions/ADR-0019-issue-type-immutability-and-autonomous-gate.md`
- `docs/decisions/ADR-0020-question-label-suppression.md`
- `docs/decisions/ADR-0021-cron-actor-identity.md`
- `docs/decisions/ADR-0022-autonomous-and-consensus-meta-modes.md`
- `integrations/github-issues-projects.md` — how these map onto GitHub

## When to Use

- Before any label change, phase change, or comment on a work item.
- When running unattended — cron, webhook, or scheduled detection.
- When a work item's Type is unset and you must decide how far to proceed.
- When a work item carries the `question` label.

## Gates That Bind Here

Summarised, not restated. Canonical texts are `FS-0018` and the ADRs above.

- **Never modify a work item's Type.** Type keys the safety gate; an agent that
  can lower its own gate has defeated it (`ADR-0019`). Propose a correction in a
  comment and stop.
- **Never act on a parked item.** While `question` is set, take no action except
  removing that label once the human's answer resolves it (`ADR-0020`).
- **Never advance past your Type's checkpoint unattended** (below).

These are conventions backed by **detection, not prevention**. GitHub cannot
enforce any of the three — see `integrations/github-issues-projects.md` §7. The
audit trail is what makes a violation visible, which is why the stance entry is
mandatory rather than courteous.

## The Stance Entry

Every agent action on a work item MUST be preceded by an activity-record entry:

```text
agent-stance: mode=<mode>; role=<role>; model=<model>; session=<session-name>; rationale=<one-line reason>
```

- `<mode>` — one of the five session modes in `workflows/session-modes.md`, or a
  meta-mode: `autonomous`, `consensus`, `review-board` (`ADR-0022`).
- `<role>` — a primary role from `guidelines/ROLE_CONTRACT.md`.

Values must come from the enumerated sets. A non-enumerated value is invalid, not
a free-text note.

This is the work-item analogue of the `Agent-Attribution:` commit trailer: an
interactive session declares its role in conversation, an unattended one declares
it here. Note the durability difference — Issue comments are editable and
deletable by their author, so where an action produced a commit, the commit
trailer is the authoritative record and the stance comment is the convenient one.

## Type-Keyed Checkpoints (`ADR-0019`)

An agent operating **without a human present** MUST NOT transition a work item's
phase past the Type-determined checkpoint without explicit human approval:

| Type | Autonomous checkpoint |
| --- | --- |
| `feature` | phase may not advance past Approved |
| `bug` | phase may not advance past Approved |
| `task` | phase may not advance past In Progress |

A work item whose Type is **unset** is treated at the most restrictive setting.
Unset means unclassified, not permissive.

## Unattended Actor Identity (`ADR-0021`)

An agent fired by cron, a webhook, or scheduled detection carries:

- a dedicated `user.email` distinct from both the human's and the
  interactive-agent's address;
- a `mode=autonomous` marker in every stance entry **and** every
  `Agent-Attribution:` trailer;
- a `session=<job-name>` value naming the triggering job.

The actor table in `workflows/git-and-gh-conventions.md` carries the aliases.

## Example 1 — Check the parked state, then post an interactive stance

```bash
# 1. Never act on a parked item. Check first.
gh issue view 115 --json labels --jq '.labels[].name' | grep -qx question \
  && { echo "parked: question label set, taking no action"; exit 0; }

# 2. Post the stance BEFORE the action it justifies.
gh issue comment 115 --body \
'agent-stance: mode=implementation; role=Implementer; model=anthropic/claude-opus-5; session=implementation; rationale=PLAN-0036 approved; beginning step 1 of the library-first sequence'

# 3. Now act.
```

## Example 2 — Unattended stance, stopping at the Type checkpoint

```bash
# Read Type before any phase change; unset is treated as most restrictive.
gh issue view 118 --json labels,title

gh issue comment 118 --body \
'agent-stance: mode=autonomous; role=Head Architect; model=anthropic/claude-opus-5; session=nightly-drift-scan; rationale=check:status reported an FS/PLAN status mismatch; opening a bug work item'

# Type is `bug` -> the checkpoint is Approved. Stop here; a human advances it.
echo "left at Approved per ADR-0019; human approval required to proceed"
```

## Checklist

- [ ] Stance entry posted **before** the action, not after
- [ ] `mode` and `role` drawn from the enumerated sets
- [ ] `model` matches the model actually acting
- [ ] `question` label checked and absent before acting
- [ ] Type read before any phase change
- [ ] Unattended run carries `mode=autonomous`, a distinct actor email, and a job name in `session=`
- [ ] Phase not advanced past the Type checkpoint without recorded human approval
- [ ] Type not modified

## Common Pitfalls

| Pitfall | Consequence |
| --- | --- |
| Posting the stance after acting | The record no longer shows the action was reasoned before it was taken |
| Treating unset Type as permissive | Unclassified work gets advanced past a gate nobody set |
| Editing Type because it "looks wrong" | Lowers your own safety gate; propose in a comment instead |
| Acting on a parked item because the request seems unrelated | `question` suppresses *all* transitions, not just the questioned one |
| Reusing the interactive actor email for a cron run | The autonomous gate keys on the actor address; the run is indistinguishable from an attended one |
| Deleting a stance comment after acting | The action's timeline event survives; its stated justification does not |

## Related Skills

- `skills/git-commit-identity/SKILL.md` — the commit-side attribution trailer this parallels
- `skills/role-aware-session/SKILL.md` — the modes and roles the stance entry draws from
- `skills/document-lifecycle/SKILL.md` — the FS/PLAN/ADR documents a work item precedes
- `skills/gh-pr-workflow/SKILL.md` — the PR a work item eventually produces
