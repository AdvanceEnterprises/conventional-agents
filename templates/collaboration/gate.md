# Gate Template

Renders the prompt for the **gate evaluator** in a gated collaboration
round, and defines the verdict artifact it returns.

Per `ADR-0031`, a round is either **synthesis-only** (participants plus a
synthesis) or **gated** (plus this). Synthesis-only is the default.

---

## Independence is non-negotiable

The gate evaluator MUST be a model that filled no participant slot in the
round it evaluates. This is `ADR-0023` Constraint 3 and cannot be
overridden by configuration, by flag, or by operator judgment.

An overlapping evaluator judges a synthesis containing its own claims. It
is not merely biased toward them — for its own claims it cannot separate
"this synthesis is sound" from "this synthesis agrees with me," because
those are the same observation. That is self-grading with an extra step.

**When no independent evaluator is available**, the round is
synthesis-only and records that. It does not seat an overlapping
evaluator. An ungated synthesis honestly labelled is sound; a gated
synthesis whose gate was a participant is a false claim.

Earlier drafts of this pattern carried an `--allow-gate-overlap` escape
hatch. It is deliberately not provided. See `ADR-0023`.

---

## Execution status is not a verdict

Two fields, two questions:

| Field | Answers | Values |
| --- | --- | --- |
| `execution_status` | Did the gate run and return something usable? | `COMPLETE` / `NOT_RUN` / `INVALID` |
| `verdict` | What did it conclude? | `PROCEED` / `CONDITIONAL` / `HALT` |

`verdict` is present **only** when `execution_status` is `COMPLETE`.

- **`NOT_RUN`** — operator-assigned. The gate was skipped, or a pre-run
  reachability check failed. The evaluator never emits this.
- **`INVALID`** — the gate ran but returned something unusable: a missing
  or unrecognized verdict, or a response that violates the contract below
  by proposing recommendations or contributing content. Also emitted
  **before evaluating** when a required input is missing or unreadable —
  a missing input is not a `HALT`, because nothing has been evaluated yet.
- **`COMPLETE`** — ran and returned a structured response.

Collapsing these into a single pass/fail makes "the evaluator was
unreachable" indistinguishable from "the evaluator rejected this." Those
warrant opposite responses.

### Verdict meanings

- **`PROCEED`** — the synthesis is sound. Not an endorsement of the
  underlying work; see the contract below.
- **`CONDITIONAL`** — specific, enumerated issues must be resolved before
  the synthesis is committed. Not "approve with notes."
- **`HALT`** — the synthesis violates an accepted ADR or approved spec,
  smooths over a divergence, or makes a claim the gate cannot validate
  against the inputs.

### The CONDITIONAL cycle is bounded

After **two** `CONDITIONAL` verdicts on the same round, escalate to a
human rather than revising again. A third revision cycle means the
disagreement is not resolvable by refinement.

---

## What the gate evaluates

**The synthesis — not the underlying work.**

This is the most common way to misuse a gate. A gate reviewing a review
board's findings is checking whether the merge was faithful, not whether
the reviewed artifact is any good. A `HALT` means findings were lost or
contradictions were smoothed; it says nothing about the artifact under
review.

The gate checks:

| Check | Question |
| --- | --- |
| Traceability | Does every synthesis claim trace to a participant output and an input source? |
| Coverage | Is the coverage record complete, accounting for every participant against every point? |
| Fidelity | Did every participant's output reach the synthesis? |
| Divergence | Are disagreements preserved rather than averaged or dropped? |
| Constraints | Does the recommended action conflict with any cited constraint? |

## What the gate MUST NOT do

- Propose new recommendations. A gate that recommends has become a
  participant.
- Resolve a divergence. Preserved disagreement is the round's product;
  resolving it is the primary's or the human's call.
- Contribute analysis of the underlying subject.
- Re-run the round, or ask for different participants.

A response doing any of these is assigned `INVALID` by the operator, not
accepted as a verdict.

---

## Template

Copy the block below and substitute the parameters. Rendered once per
round, not once per participant.

```text
TRANSPARENCY STATEMENT

agent-stance: mode={{mode}}; role=Reviewer; model={{gate_model}}; session={{round_id}}-gate; rationale=independent gate evaluation

You are the INDEPENDENT GATE EVALUATOR for a collaboration round. You did
not participate in this round and must not evaluate it as though you had
a stake in its conclusions.

WHAT YOU ARE EVALUATING

The synthesis below, against the participant outputs it claims to
summarize and the constraints it cites. You are NOT evaluating the
subject matter, and you are not being asked whether you agree with the
recommendation.

  Synthesis:            {{synthesis_path}}
  Participant outputs:  {{participant_output_paths}}
  Constraints cited:    {{constraints}}

If any listed input is missing or unreadable, stop immediately and return
STATUS: INVALID with the missing path named. Do not evaluate partially,
and do not return HALT — you have not evaluated anything.

CHECKS

1. Traceability — every claim traces to a participant output and source.
2. Coverage — the record accounts for every participant on every point.
3. Fidelity — every participant's output reached the synthesis.
4. Divergence — disagreements preserved, not averaged or dropped.
5. Constraints — the recommended action conflicts with none cited.

RETURN EXACTLY THIS SHAPE

STATUS: COMPLETE | INVALID
VERDICT: PROCEED | CONDITIONAL | HALT     (omit unless STATUS is COMPLETE)
RATIONALE: <one paragraph>
ISSUES:                                    (required when CONDITIONAL or HALT)
  - <specific, individually resolvable issue>

Do not add sections. Do not propose alternatives. Do not resolve anything
you find.
```

## Verdict artifact

```yaml
gate:
  round_id: <round-id>
  evaluator: <model-id>          # MUST NOT appear in the round's participants
  evaluated_at: <ISO-8601>
  inputs:
    synthesis: <path>
    participants: [<path>]
  execution_status: COMPLETE | NOT_RUN | INVALID
  status_assigned_by: gate | operator
  verdict: PROCEED | CONDITIONAL | HALT     # only when execution_status is COMPLETE
  rationale: <string>
  issues:                                    # required for CONDITIONAL and HALT
    - <string>
  cycle: <int>                               # escalate to human after 2
```

Committed under `ADR-0018` as amended by `ADR-0029`: actor in
`user.email`, model in `user.name`, `Agent-Attribution:` trailer naming
actor, model, role, and session.

## Pitfalls

- **Do not let the gate model also be a participant** to save an
  invocation. That is the specific shortcut the constraint exists to stop.
- **Do not convert a missing input into `HALT`.** It is `INVALID`, and
  the difference is whether an evaluation happened.
- **Do not treat `PROCEED` as approval of the underlying work.** It says
  the synthesis faithfully represents its inputs. The work still goes
  through whatever review it would otherwise have had, and a human still
  merges (`ADR-0012`).
- **Do not revise past two `CONDITIONAL` cycles.** Escalate.
