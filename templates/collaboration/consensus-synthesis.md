# Consensus Synthesis Template

The synthesis for a **consensus** round (`FS-0019`): participants
performed the same task, and the question is whether they converged.

For review boards, see `review-board-findings.md`. The two are not
interchangeable — consensus produces an agreement result, a board
produces merged findings.

Written by the **primary**: the operator, or an agent session holding the
primary role per `ADR-0013`. Participants do not write it.

---

## Five sections, in order

1. Coverage record
2. Consensus
3. Divergent points
4. Unique insights
5. Recommended action

Section 1 is not optional and not last. Writing it first is what stops
partial coverage from being read as agreement.

---

## 1. Coverage record

For every participant, against every point evaluated:

| Point | `participant-a` | `participant-b` | `participant-c` | Addressed | Sufficient |
| --- | --- | --- | --- | --- | --- |
| P1: … | addressed | addressed | silent (asked) | 2 | yes |
| P2: … | addressed | silent (not asked) | off-topic | 1 | **no** |

Disposition values:

- **`addressed`** — gave a position on this point.
- **`silent (not asked)`** — the point was outside what this participant
  received.
- **`silent (asked)`** — in scope, and the participant did not address it.
- **`off-topic`** — responded, but not to this point.

**The sufficiency rule.** A point where `addressed` is fewer than
`min_models` **cannot reach consensus**, whatever the threshold says. It
is recorded as `insufficient_coverage` and appears in neither section 2
nor section 3.

This is the rule the section exists for. Without it, "both participants
who addressed this agreed" and "both participants agreed" read
identically, and the second is false.

Then every received claim:

| Claim ID | Summary | From | Position | Confidence | Source | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| `a-001` | … | `participant-a` | affirm | high | `path#L12` | incorporate |
| `b-004` | … | `participant-b` | disagree | medium | `path#L40` | divergent |

Every claim received appears here, including ones not carried into later
sections. A claim absent from this table was not read.

## 2. Consensus

Points where participants converged, with the coverage that supports the
claim of convergence.

State the count explicitly: "3 of 3 addressed, 3 affirm" — not
"participants agreed." The bare phrasing is what the coverage record
exists to prevent, and it should not reappear one section later.

Agreement is **semantic**, not lexical. The same conclusion in different
words is agreement; different conclusions in similar words are not.

## 3. Divergent points

Where participants disagreed. **Preserved, never averaged.**

Each divergence records every position and who held it. Do not resolve
them here — resolution, if any, belongs in section 5 and is the primary's
call, clearly marked as such.

A round with an empty section 3 deserves suspicion before celebration.
Either the participants lack genuine diversity, or divergence was
smoothed during synthesis. Both void the round.

## 4. Unique insights

Claims raised by one participant that no other addressed. Distinct from
divergence: nobody disagreed, nobody else saw it.

These frequently carry the round's highest value and are the easiest to
lose, because a single-source claim looks weak next to a converged one.
Record it with its source and let the reader weigh it.

## 5. Recommended action

The primary's call. **Not derived by averaging participants**, and not a
majority vote.

Must cite the constraints — accepted ADRs, approved specs — that bound
it. **If the recommended action conflicts with any constraint, stop and
escalate.** Do not recommend against a constraint, and do not reinterpret
the constraint to fit the recommendation.

Where the recommendation departs from participant consensus, say so and
say why. That is a legitimate outcome; concealing it is not.

---

## Artifact

Per `FS-0019`, the round artifact at
`docs/consensus/<FS-or-PLAN-id>/<gate>-<timestamp>.yml` carries the
`coverage`, `agreement_check`, and — on gated rounds — `gate` blocks. The
`agreement_check.produced_by` field names the synthesizing model, which is
**not** an evaluator. On gated rounds the evaluator is a separate model
that filled no participant slot (`ADR-0023`).

## Pitfalls

- **Do not write sections 2–5 before section 1.** The coverage record
  changes what the other sections may claim.
- **Do not average divergent positions.** The midpoint of two positions
  is usually a position nobody holds.
- **Do not promote the aggregator's agreement check to a verdict.** In a
  Mixture-of-Agents setup the aggregator is the synthesizing primary, not
  the gate. See `FS-0019` §"Relationship to Mixture of Agents".
- **Do not drop a claim because it is inconvenient.** Every received claim
  gets a row and a disposition.
