---
type: adr
id: ADR-0031
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0019
  - FS-0021
superseded_by: null
---

# ADR-0031: Structured multi-model collaboration

## Status

- Proposed

## Context and Problem Statement

`ADR-0013` establishes who holds authority when multiple sessions work together:
parallel primaries on disjoint scopes, or a primary with contributors on one task. It
answers *who decides*. It does not answer what a contributor's output looks like, how
the primary combines several of them, or who checks the result.

Without answers, multi-model collaboration degrades into a predictable shape. The
operator poses a question to several models, reads several essays, and writes up an
impression of where they agreed. That impression is the operator's editorial judgment
wearing the costume of a multi-model signal. Three failure modes follow, and all three
are invisible in the output:

- **Prompt-sensitivity contamination.** Models given differently-framed prompts produce
  differences that reflect the framing, not the question. Apparent divergence is noise.
- **Partial coverage reading as agreement.** If two of four contributors addressed a
  point and both agreed, a summary that says "contributors agreed" is true and
  misleading. The two who were silent are invisible.
- **Self-grading.** The party that produced the synthesis is the party that judges
  whether the synthesis is sound.

`FS-0019` (consensus) and `FS-0021` (review board) are both multi-model collaboration
modes, and both need the same underlying primitives: comparable inputs, a synthesis
that can be checked, and a check performed by someone who did not write it.

This is not a hypothetical design problem. `docs/orchestration/multi-model-pilot-001/`
records a run of exactly this pattern against this framework — four contributors across
two invocation transports, 54 claims tracked, three gate rounds ending in `PROCEED`. The
decision below is extracted from that run rather than designed ahead of one, per
`ADR-0024`'s ordering rule.

The question this ADR answers: **what artifacts does a multi-model collaboration round
produce, and what shape must they have for the result to mean anything?**

## Decision Drivers

- **Comparability.** Contributors must receive the same framing and produce the same
  output shape, or differences between them cannot be attributed to the question.
- **Mechanical synthesis.** The primary should combine claims, not re-derive them from
  prose. Synthesis quality should not depend on the synthesizer's reading skill.
- **Disagreement must survive.** Averaging divergent positions destroys the most
  valuable thing a multi-model round produces.
- **Traceability.** Every claim in a synthesis must trace to a named contributor output
  and an input source.
- **Independent checking.** Whoever produced the synthesis must not be the one who
  validates it.
- **Cost proportionality.** Multi-model rounds are expensive. The pattern must degrade
  to something cheaper when the stakes do not justify a full round.

## Considered Options

### Option A — Ad-hoc orchestration

The operator poses the question in several sessions, reads the responses, and writes a
summary. No template, no contract, no check.

Zero infrastructure and it works today. But reproducibility is operator-dependent,
outputs cannot be re-derived, cross-model prompt sensitivity contaminates any claim of
agreement, and there is no attribution trail beyond the operator's assertion. It does
not survive a contributor count above about three.

### Option B — Structured output, no gate

Contributors write to a declared output contract, so synthesis becomes mechanical. No
independent evaluation of the synthesis.

Fixes comparability and traceability. Leaves self-grading intact: the synthesizer's
judgment about its own synthesis is the only check.

### Option C — Structured output with independent gate evaluation

Contributors write to a declared contract; the primary synthesizes; an evaluator that
participated in no contributor slot returns a verdict on the synthesis.

### Option D — Adopt an orchestration framework

Use an existing multi-model evaluation library to run the round.

Rejected on the same grounds as `ADR-0013`'s Option C: it introduces machinery and a
privileged coordinator that sit outside the six-role model, for a pattern the framework
needs to describe rather than execute. It also makes the framework depend on a runtime,
against `docs/ARC42.md` §2.

## Decision Outcome

**Chosen option: Option C — structured output with independent gate evaluation.**

### Three artifacts per round

| Artifact | Count | Produced by |
| --- | --- | --- |
| Contributor output | One per participant | Each participant, to a declared output contract |
| Synthesis | One per round | The primary |
| Gate verdict | One per round | An evaluator outside the participant set |

A round that produces fewer than three artifact kinds is not a round under this ADR. A
synthesis with no contributor outputs behind it is an opinion; contributor outputs with
no synthesis are raw material; a synthesis with no gate is unchecked.

### The output contract

Contributors receive identical framing — task, inputs, output contract, guardrails,
attribution, escalation — differing only in per-contributor parameters. Framing is
rendered from a template rather than composed per contributor, because hand-composed
prompts reintroduce the prompt-sensitivity problem the contract exists to remove.

Each contributor emits discrete, individually-identified claims rather than prose. A
claim carries at minimum an identifier namespaced to its contributor, a position, a
confidence, and the source it rests on. What the synthesis consumes is claims, not
paragraphs.

### The synthesis

Five mandatory sections, in order:

1. **Coverage / Disposition Record** — for every contributor and every question, what
   that contributor did: addressed, silent because not asked, silent though asked, or
   off-topic. Then every received claim with its disposition.
2. **Consensus** — positions contributors converged on, with the coverage that supports
   the claim of convergence.
3. **Divergent Points** — where they disagreed. **Preserved, never averaged.**
4. **Unique Insights** — claims raised by one contributor that no other addressed.
5. **Recommended Action** — the primary's call, which is *not* derived by averaging.

Section 1 is the load-bearing one, and is the pilot's most important finding. Without
it, "all contributors who addressed this point agreed" is indistinguishable from "all
four agreed" in the reader's eye. It is what stops partial coverage from being
laundered into consensus.

Every claim in sections 2–4 traces to a contributor output and to an input source. A
synthesis whose Recommended Action conflicts with a constraint in an accepted ADR or
approved FS is a stop condition, not a finding: the primary escalates rather than
recommending against a constraint.

### The gate

An evaluator outside the participant set returns a verdict on the synthesis. Its
independence is an integrity constraint and is specified in `ADR-0023`, alongside the
different-models requirement, because both exist for the same reason: an artifact that
claims independent validation must have had it.

The gate evaluates the synthesis against its contributor outputs and the constraints it
cites. It does not propose new recommendations, resolve divergences, or contribute
content — a gate that writes synthesis has become a participant.

### Cost proportionality

The default round is **synthesis-only**: contributors and a synthesis, no gate. A
**gated** round adds the independent evaluator and is used when the stakes justify the
additional model invocation. Consumers choose per task; the framework does not mandate
gating.

When a gated round is intended but the evaluator cannot run, the round degrades to
synthesis-only rather than failing. The degraded state must be recorded explicitly —
an unchecked synthesis that does not say it is unchecked is the failure this ADR
exists to prevent.

### Who fills the primary slot

The pilot ran operator-driven: the human authored the synthesis, using models as
sounding boards. That is an operational fact about the run, not a property of the
pattern. The three artifacts and their required shapes are invariant under an agent
primary, which is what `FS-0018` Path 3 anticipates. Specifications building on this
ADR should describe both, and neither is privileged here.

## Consequences

### Positive

- Synthesis becomes a mechanical operation over claims rather than an editorial
  operation over prose, so its quality stops depending on the synthesizer's reading.
- Partial coverage cannot be presented as agreement, because the Coverage Record makes
  silence visible.
- Disagreement survives to the reader, which is the output multi-model work exists to
  produce.
- Both collaboration modes — consensus and review board — build on one set of
  primitives instead of two.
- The pattern has been executed end-to-end, so the specifications extracted from it can
  be checked against something that happened.

### Negative

- Three artifacts per round is real overhead, and it is disproportionate for small
  questions. The synthesis-only default reduces but does not remove this.
- The output contract constrains what a contributor can say. A model with an insight
  that does not fit the claim envelope must either force it in or lose it — the pilot's
  own disposition record shows claims dispositioned as off-topic that may have been
  contract mismatches rather than genuinely off-topic.
- Rendering per-contributor prompts is operator work that scales linearly with
  participants, and there is no framework tooling for it. The branches this was
  extracted from carried a helper script; adopting it is a separate decision.
- A gate is one more model invocation per round, on top of N contributors.

### Neutral

- Nothing here changes `ADR-0013`. This ADR sits on top of it: ADR-0013 says who may
  commit and who may not, this one says what the artifacts look like.
- The specific claim-envelope fields, coverage vocabulary, and gate status values are
  specified in `FS-0019` and `FS-0021` and their templates, not fixed here. This ADR
  fixes that there is a contract, not its field list.

## Validation

- **Signal:** every collaboration round committed to a consuming repository produces
  contributor outputs, a synthesis, and — when gated — a verdict, each as a separate
  artifact.
- **Signal:** every synthesis contains a Coverage / Disposition Record accounting for
  every contributor against every question, including silence.
- **Signal:** no synthesis presents a Consensus claim whose supporting coverage is
  partial without saying so.
- **Signal:** gated rounds that degrade to synthesis-only say so in the artifact and in
  the PR that carries it.
- **Review checkpoint:** after the first round run by an agent primary rather than an
  operator. The claim that the pattern is invariant under that shift is untested.
- **Failure condition:** if syntheses are observed whose Divergent Points section is
  routinely empty, either the contributor set lacks genuine diversity or divergence is
  being smoothed during synthesis. Both void the round; investigate before trusting
  further output.

## Links

- `docs/orchestration/multi-model-pilot-001/` — the run this decision is extracted
  from, preserved as evidence.
- ADR-0013: Multi-model session coordination — primary/contributor authority; this ADR
  sits on top of it.
- ADR-0023: Collaboration integrity constraints — the different-models requirement and
  gate-evaluator independence.
- ADR-0024: Platform-neutral core with shipped bindings — the extract-don't-imagine
  ordering rule this ADR follows.
- FS-0019: Multi-model consensus — one collaboration mode built on these primitives.
- FS-0021: Review board — the other.
