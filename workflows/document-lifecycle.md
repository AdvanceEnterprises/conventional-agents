# Document Lifecycle

This document defines the status values, transition rules, and maintenance responsibilities for all governed documents in projects using conventional-agents.

It is part of the conventional-agents exported surface and applies to any project that vendors the kit.

---

## Feature Specs (FS)

| Status | Meaning | Who transitions | When |
| --- | --- | --- | --- |
| `draft` | Under development, not ready for implementation | Agent or human creates | Initial creation |
| `approved` | Reviewed and ready for implementation | Human approves (merge of spec PR) | After review |
| `in-progress` | Implementation actively underway | Agent sets when starting PLAN execution | First implementation commit |
| `implemented` | All PLAN steps complete, PR merged | Agent sets in the completing PR | Same PR that finishes implementation |
| `deprecated` | No longer active or superseded | Human or agent | When abandoned or replaced |

## Change Plans (PLAN)

| Status | Meaning | Who transitions | When |
| --- | --- | --- | --- |
| `draft` | Under development | Agent or human creates | Initial creation |
| `approved` | Ready for execution | Human approves (merge of plan PR) | After review |
| `in-progress` | Execution underway | Agent sets when starting | First implementation commit |
| `implemented` | All steps complete | Agent sets in the completing PR | Same PR that finishes implementation |

## Architecture Decision Records (ADR)

| Status | Meaning | Who transitions | When |
| --- | --- | --- | --- |
| `proposed` | Under consideration | Agent or human creates | Initial creation |
| `accepted` | Decision made and binding | Human accepts (merge of ADR PR) | After review |
| `deprecated` | No longer relevant | Human or agent | When context changes |
| `superseded` | Replaced by a newer ADR | Human or agent | When new ADR is accepted |

ADR lifecycle details are also documented in `docs/decisions/README.md`.

---

## Transition Rules

### Forward-only

Statuses move forward through the lifecycle. No backward transitions without human approval.

- `draft → approved → in-progress → implemented`
- Never: `implemented → approved` or `approved → draft`

### Draft-to-approved requires human review

An agent MUST NOT transition a document from `draft` to `approved` on its own. This transition happens when a human merges the PR containing the document.

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

### How approval happens (ADR-0026)

Approval is a **human act with a locatable record**. Three shapes, all human-performed:

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

The agent may *record* the approval; the agent may not *be* the approval. The trailer
names a human who is not the commit's author, and a commit whose `Approved-By:` matches
its own author is malformed.

None of the following is an approval: silence, absence of objection, an approval of
something else in the same session, an approval from a prior session for work that has
since changed, or the agent's own view that the work is ready. **If you are unsure
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
