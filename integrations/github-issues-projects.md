# Binding: GitHub Issues and Projects

This document maps the framework's workflow-substrate capabilities onto GitHub Issues
and GitHub Projects v2. It is normative for any project that uses GitHub as its
workflow substrate, and it is the substrate `conventional-agents` itself runs on.

Per `ADR-0024`, the framework's core describes *capabilities*; a binding describes the
*mechanisms* that satisfy them on one platform. This is the reference binding, written
first; the core vocabulary was extracted from it.

**Scope.** This binding covers substrate mechanics only — how work items are
represented, classified, moved, and observed. It does not restate the governance rules
that operate on them. Those live in `FS-0018` (lifecycle and gates), `ADR-0019` (type
immutability), `ADR-0020` (parked-state suppression), `ADR-0021` (unattended actor
identity), and `ADR-0012` (the merge gate).

---

## Conformance Summary

| # | Core capability | GitHub mechanism | Enforcement |
| --- | --- | --- | --- |
| 1 | Work item | Issue | Native |
| 2 | Type (agent-immutable) | Projects v2 single-select field `Issue Type` | **Convention + detection** |
| 3 | Phase | Projects v2 built-in `Status` field | Native |
| 4 | Parked state | `question` label | **Convention + detection** |
| 5 | Append-only activity record | Issue comment timeline | **Partial** — see §5 |
| 6 | Enumerability | `gh project item-list`, Issues API, GraphQL | Native |

Three of six capabilities are not technically enforceable on GitHub. Section 7 states
exactly what that means and what compensates. A binding that claimed otherwise would be
lying about its substrate.

---

## 1. Work Item → GitHub Issue

The Issue is the work item. It exists before any FS, PLAN, or ADR; the Issue body is
the free-text brief.

- **Identity:** the Issue number, repository-scoped (`owner/repo#123`).
- **Brief:** the Issue body. Markdown, no required structure.
- **Linkage to governed documents:** governed documents reference the Issue by URL in
  their front matter or body. The Issue references documents by path or PR link in
  comments. The framework does not require a machine-readable link in either direction.
- **Closure:** an Issue closes when its work merges or is abandoned. Closure is not a
  phase value; see §3.

Issues are local to a repository. Cross-repository work items are out of scope
(`FS-0018` Out of Scope).

---

## 2. Type → Projects v2 Single-Select Field

**Field name:** `Issue Type`. **Options:** `feature`, `bug`, `task`. Single-select,
exactly one value.

This is a *custom project field*, not a label and not GitHub's own issue-type feature.
It is created once per project board, parallel to the `Doc Type` field established by
`FS-0011`.

### Setup

```bash
gh project field-create <project-number> --owner <owner> \
  --name "Issue Type" --data-type SINGLE_SELECT \
  --single-select-options "feature,bug,task"
```

Requires a token with the `project` scope. Verify with `gh auth status` before running
— per `ADR-0012` this verification is required before every `gh` operation, not once
per session.

### Agent-immutability is not enforceable

`ADR-0019` requires that agents never modify Type, because Type keys the safety gate
and an agent must not be able to lower its own gate. **GitHub cannot enforce this.**
Projects v2 has no per-field access control: any token that can write to the project
can write to any field on it, including `Issue Type`. There is no permission scope that
grants "edit Status but not Issue Type."

What this binding provides instead:

- **Convention.** Agents do not write the `Issue Type` field. An agent that believes a
  Type is wrong posts an Issue comment proposing the correct value and stops.
- **Detection.** Projects v2 field changes emit `projects_v2_item.edited` webhook
  events carrying the changed field and the actor. A consumer implementing this binding
  SHOULD subscribe to that event and alert when the actor is a known agent identity and
  the changed field is `Issue Type`.
- **Audit.** The project item's field-value history records who changed what and when,
  and is queryable via GraphQL.

Detection is after-the-fact. A determined or malfunctioning agent can change Type and
proceed; the binding guarantees the change is *visible*, not that it is *prevented*.
Consumers for whom that gap is unacceptable should hold Type outside the project — see
the fallback below, where a branch-protected file is enforceable in a way a project
field is not.

### Fallback for repositories without Projects v2

Projects v2 requires an organization or user-level project. Where that is unavailable
or unwanted, either substitute:

- **Label namespace:** `type/feature`, `type/bug`, `type/task`. Single-valued by
  convention only — GitHub will happily apply two. A repository ruleset or Action can
  reject Issues carrying more than one `type/*` label.
- **Title prefix:** `[feature] …`, `[bug] …`, `[task] …`. Parseable, visible without
  API access, and awkward to change silently.

Both fallbacks are weaker than the project field for querying and reporting, and no
stronger for enforcement.

---

## 3. Phase → Projects v2 `Status` Field

**Field:** the built-in `Status` single-select. **Values** (per `FS-0011`):

| Value | Meaning |
| --- | --- |
| `Backlog` | Triaged, no work started |
| `Approved` | Authorized for work |
| `In Progress` | Active work; expect commits and PRs |
| `In Review` | A PR is open against this work item |
| `Done` | Closed — merged or abandoned |

`Done` is a phase value and is distinct from GitHub's Issue open/closed state. An Issue
may be closed while its project item is not yet `Done`, and vice versa; the project
field is authoritative for phase. Consumers SHOULD reconcile the two with a workflow
that sets `Status: Done` on Issue close.

### Transitions

```bash
gh project item-edit --id <item-id> --field-id <status-field-id> \
  --project-id <project-id> --single-select-option-id <option-id>
```

Item and field IDs are node IDs, not numbers, and are obtained via
`gh project item-list --format json` or the GraphQL API. They are stable per project.

Status is agent-mutable within the limits `FS-0018`'s autonomous gate imposes. Those
limits are governance, not substrate: this binding provides the mechanism, and the gate
decides when an agent may use it.

### Auto-add

`FS-0011` enables the project's auto-add workflow, so new Issues land on the board
automatically. Auto-added items receive `Status: Backlog` and **no** `Issue Type` —
Type is unset until a human sets it. An Issue with unset Type has not been classified,
and the autonomous gate treats unclassified work at the most restrictive setting.

---

## 4. Parked State → `question` Label

The `question` label is the parked state. While present, agents perform no actions on
the Issue except removing the label itself when the human's response resolves the
question (`ADR-0020`).

- **Check:** before any Issue action, an agent reads the label set and skips if
  `question` is present.
- **Enforcement:** convention, same as §2. Labels carry no per-label write permission.
  A consumer MAY additionally reject agent-authored mutations in a webhook handler when
  the target Issue carries `question`.

The full label vocabulary — `enhancement`, `bug`, `documentation`, `spec`, `plan`,
`question` — is defined in `FS-0018` §"Axis 2". Labels are multi-valued; only
`question` has substrate significance.

---

## 5. Activity Record → Issue Comment Timeline

Agent stance declarations are Issue comments, in the format `FS-0018` defines:

```text
agent-stance: mode=<mode>; role=<role>; model=<model>; session=<session>; rationale=<reason>
```

The timeline orders them, and every label change, field change, and comment appears in
it with an actor.

### Append-only is only partly true

The framework's core calls for an append-only activity record. GitHub's timeline is
append-only for *events* — a label change or field edit cannot be retracted from
history — but **not** for comments. A comment author can edit or delete their own
comments, and a user with `maintain` or `admin` can delete anyone's. Edits leave a
visible history; deletions do not leave a recoverable body.

Consequence: an agent could post a stance comment, act, then delete the stance comment.
The action's timeline event survives; its stated justification does not.

What compensates:

- **Commit trailers are the durable layer.** `ADR-0018` makes per-commit
  `Agent-Attribution:` trailers the authoritative attribution record. Commits are
  content-addressed; rewriting them on a merged branch is detectable. Where an action
  produced a commit, the attribution survives comment deletion.
- **Comment edit history** is retained and visible in the UI for edited comments.
- Consumers needing durable Issue-level attribution SHOULD mirror stance comments into
  a commit or an external log at write time.

Issue comments are the *convenient* record. Commits are the *authoritative* one. Where
the two disagree, commits win.

---

## 6. Enumerability → Issues API, and Triggers → Webhooks and Scheduled Actions

**Enumeration** is the conforming capability: `gh project item-list --format json`, the
Issues REST API, and the GraphQL API all return work items and their field values on
demand. A reconciler reads current state from any of them.

**Triggers** invoke the reconciler. GitHub provides both shapes, and per `ADR-0028`
they are not peers — the schedule carries correctness and events reduce latency.

### Event-driven

| Event | Fires on |
| --- | --- |
| `issues` | opened, edited, labeled, unlabeled, closed, reopened |
| `issue_comment` | created, edited, deleted |
| `projects_v2_item` | created, edited, archived — carries field changes |
| `pull_request` | opened, ready_for_review, closed |

Delivered to a consumer-implemented endpoint or consumed by a GitHub Actions workflow
`on:` trigger. Handler implementation is explicitly out of scope (`FS-0018` Non-Goals);
this binding names the events, not the handlers.

### Scheduled

```yaml
on:
  schedule:
    - cron: "0 6 * * *"
```

GitHub Actions `schedule:` is the cron mechanism. Under `ADR-0028` this is the
**correctness guarantee**, not a backstop — so its reliability characteristics are
load-bearing rather than trivia:

- Scheduled runs execute on the **default branch** only.
- Delivery is best-effort. Runs can be delayed during high load.
- **Schedules are disabled automatically after 60 days without repository activity.**

That last one is the dangerous one. A quiet repository silently loses its
reconciliation loop while continuing to look governed — no error, no alert, and the
next drift goes uncorrected indefinitely. Consumers SHOULD monitor that the scheduled
workflow is still running and treat its absence as an outage, not a delay.

A reconciler must be idempotent and must not assume it ran. `ADR-0014` gives the
mechanism: read the activity record, find your own prior entry for that transition,
skip.

An agent invoked by either path is unattended and declares `mode=autonomous`, under the
actor identity `ADR-0021` requires. That identity is a distinct `user.email`, not the
human maintainer's, and `session=` carries the workflow or job name.

### Race conditions

Concurrent webhook deliveries can act on one Issue simultaneously (`FS-0018` Edge
Cases). GitHub does not serialize handler invocations. Consumers SHOULD serialize per
Issue — an Actions `concurrency:` group keyed on the Issue number is the least-effort
approach:

```yaml
concurrency:
  group: issue-${{ github.event.issue.number }}
  cancel-in-progress: false
```

---

## 7. What This Binding Does Not Guarantee

Stated plainly, because the core's conformance checklist is only meaningful if
non-conformance is admitted:

| Requirement | Status on GitHub |
| --- | --- |
| Agents cannot modify Type (`ADR-0019`) | **Not enforceable.** No per-field ACL. Detectable after the fact. |
| Agents take no action while parked (`ADR-0020`) | **Not enforceable.** Agent-side check plus optional handler rejection. |
| Activity record is append-only | **Partial.** Events are; comments are editable and deletable. |
| Scheduled triggers fire reliably | **No.** Best-effort; auto-disabled after 60 days of inactivity. |
| Concurrent actions are serialized | **No.** Consumer must impose it. |

Every one of these is a convention backed by detection rather than a control backed by
permissions. That is a property of GitHub, not a defect in the framework — but a
consumer choosing a substrate should know which guarantees they are buying and which
they are only promising themselves.

The merge gate (`ADR-0012`) is the exception: branch protection *does* enforce it, via
required reviews and by denying agent identities push access to `trunk`. It is the one
governance rule this substrate can actually guarantee, which is a reasonable argument
for why it is the one rule the framework made non-overridable.

---

## Setup Checklist

- [ ] Project board exists with the five `Status` values (`FS-0011`)
- [ ] `Issue Type` single-select field created with `feature`, `bug`, `task`
- [ ] Auto-add workflow enabled
- [ ] Label vocabulary created: `enhancement`, `bug`, `documentation`, `spec`, `plan`, `question` — run `integrations/github/bin/gh-label-provision.sh`
- [ ] Unattended actor identity provisioned with its own `user.email` (`ADR-0021`)
- [ ] Branch protection on `trunk`: required review, agent identities denied direct push
- [ ] Webhook endpoint or Actions workflows subscribed to the §6 events
- [ ] Per-Issue concurrency serialization configured
- [ ] `projects_v2_item.edited` alerting for agent-authored `Issue Type` changes

The checklist's executable, read-only parts are shipped by the GitHub binding layer:
`integrations/github/bin/gh-submodule-init.sh` performs dual-regime submodule
initialisation, `integrations/github/bin/gh-label-provision.sh` provisions or audits
the label vocabulary, and `integrations/github/bin/gh-board-audit.sh` reports board
drift without changing it. Consumer adoption remains an explicit repository choice.

## References

- `ADR-0024` — platform-neutral core with shipped bindings; defines the six capabilities
- `FS-0018` — work-item lifecycle, three-axis schema, autonomous gate
- `FS-0011` — GitHub Projects board structure and the five Status values
- `ADR-0012` — non-overridable gates: merge rule, identity verification
- `ADR-0018` — three-layer commit attribution
- `ADR-0019` / `ADR-0020` / `ADR-0021` — type immutability, parked-state suppression, unattended actor identity
