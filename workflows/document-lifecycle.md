---
updated: 2026-10-27
---

# Document Lifecycle

This document defines the status values, transition rules, and maintenance responsibilities for all governed documents in projects using conventional-agents.

It is part of the conventional-agents exported surface and applies to any project that vendors the kit.

---

## Work Items (the entry point)

A **work item** is the canonical entry point for any governed piece of work. It exists before any FS, PLAN, or ADR, and it carries the brief that downstream documents refine. Its three-axis schema, its origination paths, and its autonomous gate are defined in `FS-0018` and ratified by `ADR-0019`, `ADR-0020`, `ADR-0021`, and `ADR-0022`. The rules below are the lifecycle summary; the spec is the source of truth.

Per `ADR-0024`, the framework does not name a substrate platform. A binding under `integrations/` maps these rules onto one. The reference binding is `integrations/github-issues-projects.md`.

### Three-axis schema

Every work item carries exactly three classification axes.

**Axis 1 — Type (single-valued).** Exactly one of:

| Type | Gate | Requires FS? |
| --- | --- | --- |
| `feature` | Highest — requires FS + PLAN | Yes |
| `bug` | Medium — FS required if the fix involves design | Conditional |
| `task` | Lowest — operational, administrative, hygiene | No |

When in doubt, choose the higher-severity Type. Type is **human-mutable only** (`ADR-0019`). An agent that believes the Type is wrong posts an activity-record entry proposing the correct Type and the reason, in the agent-stance format below; the human edits the Type.

**Axis 2 — Label (multi-valued).** Six labels classify content and workflow position. They may be applied by any actor, with the rule that every transition by an agent is preceded by an agent-stance entry:

- `enhancement` — new feature or request, casual description; typically human-applied at work-item opening.
- `bug` — defect report; human- or autonomous-applied (Path 3 of `FS-0018`).
- `documentation` — documentation-only change; often paired with Type `task`.
- `spec` — the work item carries the spec for the work (or references an FS file).
- `plan` — the work item carries the change plan (or references a PLAN file).
- `question` — clarification request. The work item is parked, awaiting human response. While this label is set, the agent MUST NOT perform any work-item transitions (label, phase, or comment) except to remove `question` itself when the human's response resolves it. Ratified by `ADR-0020`.

**Axis 3 — Phase (single-valued).** Exactly one of: `Backlog`, `Approved`, `In Progress`, `In Review`, `Done`. Phase is distinct from any open/closed state the substrate exposes; the binding states how the two are reconciled.

### Origination paths

There are three, each with a documented trigger, first actor, and first action (`FS-0018` §"Origination Paths"):

1. **Human opens a work item with the `enhancement` label.** First actor is an autonomous agent assuming Head Architect role. The agent's first action proposes Type `feature` and label `spec` via an agent-stance entry, transitioning phase → Approved. The Type change itself requires a human.
2. **Head Architect conversation concludes.** First actor is a hybrid-session agent. The agent creates the work item with Type `feature`, label `spec`, and phase Approved, body carrying the Head Architect's summary.
3. **Autonomous agent creates a work item from drift** (cron tick, detection run, scheduled scan). First actor is an unattended agent under the `ADR-0021` actor identity. First artifact is Type `bug` or `task`.

### Agent stance on activity records

Every work-item action by an agent (label change, phase change, comment) MUST be preceded by an activity-record entry in the documented stance format:

```text
agent-stance: mode=<mode>; role=<role>; model=<model>; session=<session-name>; rationale=<one-line reason>
```

Where `<mode>` is one of the five session modes from `workflows/session-modes.md`, or one of the meta-modes `autonomous`, `consensus`, or `review-board` per `ADR-0022`. `<role>` is a primary role from `guidelines/ROLE_CONTRACT.md`. The value must come from the enumerated set; non-enumerated values are invalid.

This is the autonomous-equivalent of the role-transition phrase required by `ROLE_CONTRACT` §"Role and session transparency" for interactive sessions. For commits produced as part of the action, the commit's `Agent-Attribution:` trailer remains the durable record.

### Autonomous gate (Type-keyed)

An agent operating without a human present (scheduled, triggered, or delegated) MUST NOT transition a work item's phase past the Type-determined checkpoint without explicit human approval (`ADR-0019`). Type-keyed checkpoints:

- Type `feature` — phase may not advance past Approved without human approval.
- Type `bug` — phase may not advance past Approved without human approval of the proposed fix.
- Type `task` — phase may not advance past In Progress without human approval.

A work item whose Type is unset has not been classified, and the gate treats it at the most restrictive setting. This gate composes with `ADR-0012`'s merge gate: even within an authorized phase range, the agent MUST NOT execute the merge action. Per `ADR-0024`, the merge gate is the only rule in this section a substrate can technically enforce; the rest are conduct rules backed by detection and audit.

### Audit trail

Every agent transition is attributable per `ADR-0018` as amended by
`ADR-0029` (`ADR-0036` proposes a vocabulary canon that would further
refine this). `Co-authored-by:` is reserved for human–human collaboration
(`ADR-0018`/`ADR-0029`); agent participation is recorded via `Agent-Attribution:`
trailers. The activity timeline is therefore a record of role
transitions, with each entry traceable to a specific model + role +
session combination, subject to the retractability limits noted above.

---
## Feature Specs (FS)

| Status | Meaning | Who transitions | When |
| --- | --- | --- | --- |
| `draft` | Under development, not ready for implementation | Agent or human creates | Initial creation |
| `approved` | Reviewed and ready for implementation | Human approves (merge, recorded, or deferred — ADR-0026) | After review |
| `in-progress` | Implementation actively underway | Agent sets when starting PLAN execution | First implementation commit |
| `implemented` | All PLAN steps complete, PR merged | Agent sets in the completing PR | Same PR that finishes implementation |
| `deprecated` | No longer active or superseded | Human or agent | When abandoned or replaced |

## Change Plans (PLAN)

| Status | Meaning | Who transitions | When |
| --- | --- | --- | --- |
| `draft` | Under development | Agent or human creates | Initial creation |
| `approved` | Ready for execution | Human approves (merge, recorded, or deferred — ADR-0026), or mechanical self-approval where ADR-0027's containment and reserved-path conditions hold | After review |
| `in-progress` | Execution underway | Agent sets when starting | First implementation commit |
| `implemented` | All steps complete | Agent sets in the completing PR | Same PR that finishes implementation |
| `deprecated` | Abandoned before implementation; will not be executed | Human | When the governing FS is deprecated, or the plan is otherwise abandoned |

`deprecated` closes an asymmetry rather than adding a new idea: FS and ADR have had it
since the beginning, and a PLAN whose governing FS is deprecated had no status to move
to. A deprecated PLAN MUST record why in its §2, and is exempt from the `touches:`
containment check — it is not seeking approval.

## Architecture Decision Records (ADR)

| Status | Meaning | Who transitions | When |
| --- | --- | --- | --- |
| `proposed` | Under consideration | Agent or human creates | Initial creation |
| `accepted` | Decision made and binding | Human accepts (merge of ADR PR) | After review |
| `deprecated` | No longer relevant | Human or agent | When context changes |
| `superseded` | Replaced by a newer ADR | Human or agent | When new ADR is accepted |

ADR lifecycle details are also documented in `docs/decisions/README.md`.

## Runbooks (RB)

A runbook records an operational procedure **as performed against a real substrate**.
It is a current-state document under `ADR-0030`, and it does not use the
`draft → approved → implemented` model above. That model describes work moving toward
completion; a runbook describes a procedure that either still matches reality or does
not.

| Status | Meaning | Who transitions | When |
| --- | --- | --- | --- |
| `current` | Last execution succeeded; believed to match the substrate | Operator | On successful end-to-end execution |
| `stale` | Substrate known or suspected to have changed; unverified | Anyone | On a failed step, or a substrate change notice |
| `superseded` | Replaced by a newer runbook | Operator | When replaced |

Because runbooks use their own vocabulary, the `## Transition Rules` below — which
speak in `draft`, `approved`, and `implemented` — do not apply to them. Two rules do
apply, restated here rather than inherited:

- **`stale` is not forward-only.** A runbook returns to `current` when someone executes
  it end to end and it works. Setting `stale` requires no review, deliberately: a
  runbook that has quietly stopped matching its substrate is more dangerous than one
  flagged unverified.
- **`last_verified:` is not an edit date.** It records when a human or agent last
  executed the procedure and observed it work. Editing prose does not advance it.

Runbooks live in `runbooks/` and are indexed in `runbooks/README.md`, which carries the
same index-maintenance obligation as the `docs/` indexes below. See
`runbooks/README.md` for the front matter and required sections, and
`templates/core/runbook.md` for the scaffold.

---

## Transition Rules

### Forward-only

Statuses move forward through the lifecycle. No backward transitions without human approval.

- `draft → approved → in-progress → implemented`
- Never: `implemented → approved` or `approved → draft`

### Draft-to-approved: human review, with one mechanical PLAN path

An agent MUST NOT transition a document from `draft` to `approved` on its own, with one exception: a PLAN whose `touches:` all fall within its governing FS's `interfaces:` (that FS at `status: approved`) and outside ADR-0027's reserved set may self-approve, recording the transition as its approval. Every other document — every FS and ADR included — reaches `approved` only through one of the three ADR-0026 human-approval shapes below.

### Agents MUST NOT implement draft specs

If a spec has `status: draft`, implementation is blocked. The agent's first task is to get the spec reviewed and approved — not to start coding.

### In-progress is set at execution start

When an agent begins executing a PLAN, it sets both the FS and the PLAN to `in-progress` in the first implementation commit.

### Implemented is set in the completing PR

When a PR completes the final step of a PLAN:

- Set the PLAN to `status: implemented`
- Set the governing FS to `status: implemented`
- Both status changes MUST be included in that PR — not deferred to a follow-up

### Single-PR implementations

When a PLAN is fully implemented in a single PR, the status may go directly from `approved` to `implemented` in that PR. Setting `in-progress` as an intermediate step is not required when the entire implementation ships in one PR.

### Multi-PR implementations

Some PLANs span multiple PRs. In this case:

- Set `in-progress` in the first PR
- Keep `in-progress` for intermediate PRs
- Set `implemented` only in the final PR

### How approval happens (ADR-0026, with the ADR-0027 PLAN path)

Approval requiring a human is a **human act with a locatable record**. Three shapes,
all human-performed. One mechanical exception: a PLAN meeting ADR-0027's containment
and reserved-path conditions self-approves, recording the transition as its approval
with no separate marker — everything else in this section is about the human shapes.

| Shape | When | The record |
| --- | --- | --- |
| **Merge approval** (default) | The human merges the document's PR | The merge itself |
| **Recorded approval** | The human approves in session, before merge | A commit transitioning the status, carrying `Approved-By:` |
| **Deferred approval** | Documents land un-approved; approval comes later | Declared in the PR description, then a later recorded approval |

**Recorded approval.** When a human approves in session, the agent commits the status
transition with trailers naming who approved and what:

```text
Approved-By: <Human Name> <human@example.dev>
Approved-Artifacts: FS-0018, PLAN-0018
```

The agent may *record* the approval; the agent may not *be* the approval — except under ADR-0027's mechanical path, where the eligible PLAN's status transition is itself the approval. The trailer
names a human who is not the commit's author, and a commit whose `Approved-By:` matches
its own author is malformed.

None of the following is a human approval: silence, absence of objection, an approval of
something else in the same session, an approval from a prior session for work that has
since changed, or the agent's own view that the work is ready (the ADR-0027 mechanical
path aside). **If you are unsure
whether approval was given, it was not. Ask.**

**Approved is provisional until merged.** A status set before merge describes intent
for trunk, not fact about it. An `approved` spec or `accepted` ADR on an unmerged branch
is real approval — a human performed it — but takes full force at merge, and is treated
as a draft by anyone outside that branch until then. This applies to every status: an
`approved` FS on an unmerged branch authorizes implementation *on that branch*, not
against trunk; an `implemented` PLAN on an unmerged branch has implemented nothing
anyone else can see.

An agent reading a document **on trunk** may trust its status. An agent working on a
branch must know it is on one.

**Deferred approval** lands governed documents un-approved. Valid only when it is
declared in the PR description with a complete list of the documents affected, those
documents land at `draft` or `proposed`, approval follows as a separate recorded
approval, and no implementation begins — the spec-first rule applies unchanged, so a
`draft` spec is not implementable. Use it only when the value of the PR is the coherence
of the package rather than any single document. If the PR could be split into
document-sized PRs without inventing ordering constraints, split it.

### Stale documents

If an `approved` spec has not been worked on for an extended period and is no longer planned:

- Set it to `deprecated` with a note explaining why
- Do not leave it as `approved` indefinitely — this creates false signals about planned work

---

## Front Matter Hygiene

### Updated dates

When modifying any FS, PLAN, or ADR, update the `updated:` field in YAML front matter to today's date.

### Cross-references

- FS documents should populate `related_adrs:` with any ADRs that informed the spec
- PLAN documents should populate `related_specs:` with the governing FS(s)
- ADR documents should populate `related_specs:` with any specs that implement the decision

Keeping cross-references current makes the document graph navigable.

---

## README Index Maintenance

Each docs subdirectory has a README.md that serves as an index:

- `docs/specifications/README.md`
- `docs/change-plans/README.md`
- `docs/decisions/README.md`

**Agents MUST update the relevant README when:**

- Adding a new document to the directory
- Changing a document's status

This is part of the document hygiene gate in ROLE_CONTRACT.
