---
type: feature-spec
id: FS-0021
status: implemented
title: Review board collaboration mode
owner: ajoeofalltrades
test_required: true
interfaces:
  - "workflows/session-modes.md"
  - "guidelines/ROLE_CONTRACT.md"
  - "templates/collaboration/review-board-findings.md"
  - "config/review-board.yml"
  - "docs/specifications/README.md"
  - "test/FS-0021/review-board.bats"
related_adrs:
  - ADR-0022
  - ADR-0023
  - ADR-0031
supersedes: []
requires:
  - FS-0018
tags: [collaboration, multi-model, review, optional-feature]
created: 2026-07-28
updated: 2026-08-01
---

<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: Review Board Collaboration Mode

## Status

- Approved

## Plan Status

- **PLAN-0021 is `approved`**, approved in the same session as this FS. `workflows/document-lifecycle.md`
  places PLAN creation at "initial creation" and constrains only its
  *approval*: a PLAN may not reach `approved` while its FS is `draft`.

## Summary

Define the **review board**: a collaboration mode in which several models
examine one artifact from *different role stances* and their findings are
merged rather than compared for agreement.

A review board is the second of the two collaboration modes built on
`ADR-0031`'s three-artifact round. `FS-0019` specifies the first,
consensus, where participants perform the same task and the question is
whether they converged. A review board asks a different question: **what
does each perspective catch that the others miss?**

The distinction is not stylistic. In consensus, divergence is a problem —
it fails a threshold and blocks a gate. In a review board, divergence is
the product. A board whose participants all report the same findings has
told you almost nothing.

Like consensus, this is optional, consumer-implemented, and **disabled by
default** per `ADR-0023` Constraint 2.

## Goals

- Define the review board as a peer of consensus under `ADR-0031`, sharing
  its artifacts and integrity constraints while producing findings rather
  than a verdict.
- Define composition: what makes a set of participants a board rather than
  a consensus round.
- Define the findings artifact — its shape, its disposition vocabulary,
  and the rule that findings are merged and never averaged.
- Define where a board runs and what it may and may not do at each point.
- Define the role stance participants declare, and how it composes with
  `ADR-0022`'s meta-modes.
- Keep the board advisory: a board surfaces, it does not decide.

## Non-Goals

- Replacing the Reviewer role. `guidelines/ROLE_CONTRACT.md` Role 4
  remains the single-session review stance. A board is several stances at
  once, not a new one.
- Deciding anything. A board produces findings; disposition is the
  primary's or the human's.
- Implementing orchestration. The framework describes required behavior;
  consumers implement invocation, exactly as with `FS-0019`.
- Replacing consensus. The two modes answer different questions and a
  consumer may enable either, both, or neither.
- Defining a severity taxonomy for findings beyond the minimum below.
  Consumers may extend it.

## Users / Stakeholders

- **Joey Clark** (`ajoeofalltrades`) — needs review coverage that catches
  what a single reviewing session misses, without a verdict mechanism
  that suppresses the disagreement being sought.
- **Agent actors** — participate in boards under a declared role stance
  and must know what they may report and what they may not do.
- **Future consumer-repo maintainers** — decide whether to enable boards
  and at which gates.

## Review Board Vocabulary

- **board**: a single execution of the review-board protocol over one
  artifact.
- **seat**: one participant in a board — a model paired with a declared
  role stance. Seats are the board's unit of composition.
- **finding**: a single discrete observation from one seat, individually
  identified, carrying severity, claim, and source.
- **merge**: combining seats' findings into one set. Merging deduplicates
  identical findings and preserves everything else, including findings
  that contradict each other.
- **disposition**: what the primary decided about a finding — accepted,
  rejected with reason, deferred, or duplicate-of.
- **gate**: the optional independent evaluation of the merged findings,
  per `ADR-0031`.

## Composition

### Role diversity is what makes it a board

A board MUST seat at least **two distinct role stances** from the
six-role model in `guidelines/ROLE_CONTRACT.md`.

This is the defining constraint. A set of participants all reviewing in
the same stance is a consensus round on a review, and `FS-0019` already
specifies that. Role diversity is what produces complementary rather than
redundant coverage: a Reviewer stance asks whether the artifact matches
its spec; a Head Architect stance asks whether it fits the framework's
decisions; an Implementer stance asks whether it can actually be built.

Not every role is useful at every gate; the useful pairings are a
consumer configuration choice. The floor is two distinct stances.

### Model diversity is required as well

`ADR-0023` Constraint 1 applies unchanged: seats must be different models
with independent state. Two seats filled by the same model in different
role stances do **not** satisfy it.

The reason is worth stating because the intuition cuts the other way.
Role stance changes what a model looks *for*; it does not change what the
model is capable of *seeing*. A single model's blind spots are correlated
across every stance it adopts, so a same-model board produces the
appearance of complementary coverage with none of the substance.

### Minimum viable board

Two seats, two distinct role stances, two distinct models. Below that,
the round is not a board and MUST NOT emit a board artifact.

## Where a Board Runs

The framework recommends two placements. Both are opt-in per consumer.

### Placement A — artifact review

A board reviews a completed draft: an FS, a PLAN, an ADR, or a design
document, before it transitions status. Useful stances: Reviewer, Head
Architect, Spec Reader and Test Planner.

### Placement B — change review

A board reviews a PR diff against its governing FS and the ADRs it cites.
Useful stances: Reviewer, Implementer, Head Architect.

A board at either placement is **advisory**. It does not transition
status, approve, or merge. `ADR-0012`'s merge gate is untouched: a board
may report that a change looks ready, and a human still merges it.

## Findings, Not Verdicts

A board produces a merged findings set. It does not produce a verdict,
a score, an approval, or a recommendation to approve.

### Merging preserves disagreement

Where two seats report contradictory findings, **both are recorded**. The
merge does not adjudicate between them, average them, or drop the
minority position. A contradiction between two role stances is
information about the artifact — usually that it satisfies one concern at
the expense of another — and resolving it silently destroys the finding.

Deduplication is limited to findings that are the *same* observation from
different seats. Those are merged with all raising seats recorded, because
a finding raised independently by three stances carries different weight
than one raised by one.

### Finding shape

Each finding carries at minimum:

| Field | Meaning |
| --- | --- |
| `id` | Identifier namespaced to the raising seat |
| `raised_by` | Seat identifier — model and role stance |
| `severity` | `blocking` / `substantive` / `minor` / `question` |
| `claim` | The observation, one sentence |
| `source` | What in the artifact or its constraints the claim rests on |
| `disposition` | Set by the primary, not the seat |

`severity` is the seat's assessment and is advisory. A seat reporting
`blocking` does not block anything; it asserts that in its stance, the
issue should be resolved before the artifact proceeds.

### Disposition vocabulary

Set by the primary when the findings are acted on:

- `accepted` — the finding stands and will be addressed.
- `rejected` — with a stated reason. A rejected finding is not deleted.
- `deferred` — valid but out of scope for this change; requires a
  destination (work item, BACKLOG entry).
- `duplicate-of` — the same observation as another finding, which is
  named.

Every finding receives a disposition. An undispositioned finding means
the board's output was not fully read.

## Coverage

`ADR-0031`'s Coverage / Disposition Record applies, with the same purpose
as in `FS-0019` and a different failure it prevents.

A board must record, per seat and per review dimension, whether the seat
addressed it. Without that record, a merged findings set with no findings
in some area is ambiguous between "every seat looked and found nothing"
and "no seat looked."

Those are opposite conclusions. The first is evidence of quality; the
second is a coverage hole reported as a clean bill of health.

Unlike consensus, there is no threshold and no `insufficient_coverage`
failure — a board with partial coverage still produces useful findings.
The requirement is that the gaps are **visible**, not that they are
absent.

## The Gate

Per `ADR-0031`, a board may be **synthesis-only** (seats plus merged
findings) or **gated** (plus an independent evaluator). Synthesis-only is
the default.

When gated, the evaluator checks the merge, not the artifact: whether
every seat's findings reached the merged set, whether contradictions were
preserved rather than smoothed, whether the coverage record is complete,
and whether dispositions carry the reasons the vocabulary requires.

`ADR-0023` Constraint 3 applies: the evaluator MUST NOT have filled a
seat. Where no independent evaluator is available the board is
synthesis-only and records that, rather than seating an evaluator that
also reviewed.

The gate's execution status and verdict follow `ADR-0031`:
`COMPLETE` / `NOT_RUN` / `INVALID`, and on `COMPLETE` a verdict of
`PROCEED` / `CONDITIONAL` / `HALT`. A `HALT` means the merge is unsound —
findings lost, contradictions smoothed — not that the artifact under
review is bad. The gate has no opinion about the artifact.

## Role Stance and Meta-Mode

A seat declares its stance in the format `FS-0018` defines:

```text
agent-stance: mode=review-board; role=<role>; model=<model>; session=<session-name>; rationale=<one-line reason>
```

`review-board` is a meta-mode per `ADR-0022`, alongside `autonomous` and
`consensus`: it describes *how* the session executes, not what stance it
takes. The `role=` field carries the seat's stance and determines what
that seat may report and what it may not do.

A seat operating in Reviewer stance inherits Role 4's prohibitions — it
produces observations only and does not modify the artifact under review.
A seat in any stance is bound by that stance's prohibited actions in
`guidelines/ROLE_CONTRACT.md`. Being in a board grants no authority a
single session in that role would not have.

## Artifact

**Path divergence from consensus is deliberate.** `FS-0019` keys its rounds on
the governing document (`docs/consensus/<FS-or-PLAN-id>/…`) because a consensus
round always has one. A board may review a PR diff, a design note, or anything
else, so it keys on an artifact id instead. The cost is that a board reviewing
`FS-0020` is not reachable from `FS-0020` without a backlink; consumers who want
that should record the board's path on the work item that triggered it.

```yaml
# File path: docs/review-boards/<artifact-id>/<placement>-<timestamp>.yml
board:
  artifact_under_review: <FS/PLAN/ADR id, or PR reference>
  placement: artifact_review | change_review
  initiated_by: <agent-stance metadata>
  initiated_at: <ISO-8601>
  seats:
    - model: <model-id>
      role: <role from ROLE_CONTRACT>
      output: <file path or summary>
      output_hash: <sha256>
  coverage:
    - dimension: <what was to be reviewed>
      by_seat:
        <seat-id>: addressed | silent (not asked) | silent (asked) | off-topic
  findings:
    - id: <seat-namespaced id>
      raised_by: <seat-id>
      also_raised_by: [<seat-id>]     # populated on deduplication
      severity: blocking | substantive | minor | question
      claim: <one sentence>
      source: <path, line, or constraint reference>
      contradicts: <finding id>       # present when seats disagree
      disposition: accepted | rejected | deferred | duplicate-of
      disposition_reason: <string>    # required for rejected and deferred
  gate:                               # omitted entirely on synthesis-only boards
    evaluator: <model-id>             # MUST NOT appear in seats
    execution_status: COMPLETE | NOT_RUN | INVALID
    verdict: PROCEED | CONDITIONAL | HALT
    rationale: <string>
```

Per `ADR-0018` as amended by `ADR-0029`, the commit producing this
artifact carries the actor's `user.name`/`user.email`, `Co-authored-by:`
where hybrid, and an `Agent-Attribution:` trailer.

## Success Criteria

Each bullet MUST be objectively testable.

**Default and opt-in**:

- Given a fresh consumer repo, when configuration is read, then review
  boards are disabled.
- Given a consumer with review boards disabled, when an artifact
  transitions status, then no board is invoked.

**Composition**:

- Given a board artifact, when `seats` is read, then it contains at least
  two entries with distinct `role` values.
- Given a board artifact, when `seats` is read, then all `model` values
  are distinct.
- Given a configuration that would seat two identical models, when a
  board is invoked, then it fails with a configuration error and no board
  artifact is written.
- Given a configuration that would seat two identical role stances and no
  others, when a board is invoked, then it fails with a composition error
  and no board artifact is written.

**Findings**:

- Given two seats reporting contradictory findings, when the merged set
  is read, then both findings are present and each names the other in
  `contradicts`.
- Given the same observation raised by three seats, when the merged set
  is read, then one finding is present with the other two seats recorded
  in `also_raised_by`.
- Given a finding with `disposition: rejected` or `deferred`, when the
  artifact is read, then `disposition_reason` is non-empty.
- Given a completed board, when the merged set is read, then every
  finding carries a disposition.

**Coverage**:

- Given a board artifact, when `coverage` is read, then every seat is
  accounted for against every declared review dimension.

**Gate**:

- Given a gated board, when the artifact is read, then `gate.evaluator`
  does not appear in `seats`.
- Given a board where no independent evaluator was available, when the
  artifact is read, then the `gate` block is absent and the board is
  recorded as synthesis-only.

**Advisory boundary**:

- Given a board returning findings of severity `blocking`, when the
  workflow is inspected, then no status transition, approval, or merge
  was performed by the board.

## Edge Cases

- **A seat produces no findings.** Recorded as `addressed` with an empty
  finding set, which is distinct from silence. A seat that looked and
  found nothing is a result.
- **All seats report the same finding.** Valid but suspicious — it may
  indicate the seats are less diverse than configured, or the finding is
  genuinely obvious. Deduplicated with all seats in `also_raised_by`.
- **A seat reports findings outside its stance.** Recorded. Role stance
  shapes what a seat is asked to look for; it does not censor what the
  seat noticed.
- **Contradiction chains.** Three seats each contradicting the next.
  `contradicts` is a list, not a single reference; the merge records the
  chain rather than picking a winner.
- **The artifact changes during review.** The board's findings reference
  the artifact hash they reviewed. Findings against a superseded version
  are marked stale rather than silently reinterpreted.

## Out of Scope

- Orchestration implementation. Consumers invoke seats themselves.
- Automatic remediation of findings.
- Severity taxonomies beyond the four values above.
- Boards spanning multiple artifacts.
- Any authority to approve, transition, or merge.

## Dependencies

- `ADR-0031`: three-artifact round, coverage record, gated versus
  synthesis-only.
- `ADR-0023`: different-models requirement, ships-disabled default, and
  gate-evaluator independence.
- `ADR-0022`: meta-mode composition; requires `review-board` added to the
  mode vocabulary.
- `FS-0018`: the agent-stance entry format and the work item layer boards
  attach to.
- `guidelines/ROLE_CONTRACT.md`: the six role stances seats declare.

## Open Questions

None of the following block approval.

- **Useful stance pairings per placement.** Working answer: the spec
  names candidates without mandating them, and consumers configure.
  Confirm that the framework should not prescribe pairings.
- **Whether `blocking` severity should have any mechanical effect.**
  Working answer: no — a board is advisory and mechanical effect would
  make it a gate. Confirm.
- **Whether a board's findings should feed a consensus round when seats
  contradict.** Working answer: no; chaining collaboration modes is out
  of scope and the contradiction is itself the deliverable. Confirm.

## Rollout / Migration

1. Add `review-board` to the meta-mode vocabulary in `ADR-0022` and
   `workflows/session-modes.md`.
2. Ship `templates/collaboration/review-board-findings.md`.
3. Document the mode and its configuration in `INTEGRATION.md`.
4. Add `test/FS-0021/review-board.bats` covering composition rules, the
   contradiction-preservation rule, disposition completeness, and gate
   independence.
5. Reference this spec alongside `FS-0019` in README.md and AGENTS.md as
   the two collaboration modes.
