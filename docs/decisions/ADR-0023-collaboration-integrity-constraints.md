---
type: adr
id: ADR-0023
status: accepted
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0019
  - FS-0021
superseded_by: null
updated: 2026-07-28
---

# ADR-0023: Collaboration integrity constraints

## Status

- Accepted

## Context and Problem Statement

FS-0019 defines multi-model consensus at workflow gates as an optional,
consumer-implemented feature. The framework supplies vocabulary, artifact shape, gate
placement, and failure modes; consumer repos supply the orchestration.

Two properties of that design are load-bearing in a way the rest is not, and FS-0019
flags both as needing ratification.

The first concerns what a consensus round must be made of. A round that invokes the
same model twice, or two versions of one model family, produces outputs that agree at
a rate far above what independent judgment would yield — not because the answer is
right, but because identical weights fed identical prompts produce correlated results.
The round returns `pass`, an artifact is written to `docs/consensus/`, and the Issue
advances through its gate carrying documentary evidence of a validation that never
happened. This is worse than having no consensus at all, because it manufactures
justified confidence. FS-0019 names it directly: same-model consensus is theater.

The hazard is that this failure mode is attractive. Same-model rounds are cheaper, run
faster, need one API key, and always agree. A consumer under cost or latency pressure
has every practical incentive to configure exactly the thing that voids the feature's
meaning, and the artifact it produces is indistinguishable from a real one.

The second property concerns the default. Consensus is expensive, and the framework's
own development does not use it. If the shipped configuration enabled consensus, every
consumer would inherit a cost and latency burden they did not choose, and the
framework would be prescribing a workflow it does not itself follow.

The question this ADR answers: **what minimum properties must hold for something to
count as consensus in this framework, and what ships on by default?**

## Decision Drivers

- **A consensus artifact must mean what it claims.** A `pass` verdict should represent
  independent agreement, not correlated sampling.
- **The integrity constraint must survive cost pressure.** If it is configurable, it
  will eventually be configured away by exactly the consumers who most need it.
- **The framework should not prescribe what it does not practice.** Its own evolution
  runs single-model; the shipped default should reflect that.
- **Opt-in must be deliberate.** A consumer enabling consensus should be making a
  choice, not discovering an inherited default.
- **Misconfiguration must fail loudly.** A round that cannot satisfy its constraints
  should say so, not silently degrade into something weaker.
- **Consumers retain implementation freedom.** The framework constrains what consensus
  *is*, not how it is orchestrated.

## Considered Options

### Option A: Both properties configurable

`min_models` and same-model permission are ordinary configuration. Consumers choose.
Consensus ships enabled with sensible defaults.

### Option B: Different-models required, but overridable with explicit acknowledgment

Same-model consensus is forbidden by default but permitted via an explicit escape
hatch (e.g., `allow_same_model: true` with a required justification string).

### Option C: Different-models is non-overridable; consensus ships disabled

The different-models requirement cannot be configured away by any means. Consensus is
disabled in the shipped configuration and must be explicitly enabled.

### Option D: Different-models non-overridable; consensus ships enabled

Same integrity constraint, but consensus is on by default for consumers who adopt the
framework.

## Decision Outcome

**Chosen option: Option C — different-models is non-overridable; consensus ships
disabled.**

### Scope: both collaboration modes

The framework defines two multi-model collaboration modes, and these constraints govern
both. `FS-0019` specifies **consensus** — participants perform the same task and their
outputs are compared for agreement. `FS-0021` specifies the **review board** —
participants examine one artifact from complementary role stances and their findings are
merged. `ADR-0031` supplies the primitives both are built from.

The modes differ in what they produce: consensus yields a verdict, a review board yields
findings. They do not differ in what makes them honest. A same-model review board has
the same defect as a same-model consensus round — correlated outputs presented as
independent judgement — so the constraints below say "collaboration round" and mean
both.

### Constraint 1: The different-models requirement is non-overridable

A collaboration round MUST invoke at least two participants that are **different models
with independent state**. This constraint cannot be relaxed by configuration, by
per-document front matter, by instruction file, or by any other mechanism.

Concretely, all three must hold:

- **Distinct model identifiers.** Different versions of the same model family do not
  count as different models.
- **Independent invocation state.** No shared prompt cache, no shared conversation
  context, no shared tool-use history between participants.
- **At least two participants.** `min_models` may be raised above 2; it may not be
  lowered below it.

This joins the small set of framework rules that no instruction source can weaken,
alongside ADR-0012's gates. The reasoning is the same in both cases: the rule exists
to prevent a specific self-serving shortcut, and a rule against a self-serving shortcut
that the shortcut-taker may disable is not a rule.

When the constraint cannot be satisfied — one model configured, duplicate identifiers,
a model unavailable at round time — the round **fails with a configuration error**. It
does not fall back to a single-model check and report success. The workflow proceeds
without the round (graceful degradation, per FS-0019), and the failure is surfaced.
The distinction that matters: the workflow may continue, but no artifact claiming
independent judgement is produced.

### Constraint 2: Collaboration modes ship disabled

Shipped configuration for both modes is disabled: `enabled: false`, every gate
independently `enabled: false`, and an empty model list. A consumer opts in by editing
the file. `config/consensus.yml` is the shipped template for consensus; `FS-0021`
defines the equivalent for review boards.

The framework's own repository enables neither. Its FSs, PLANs, and ADRs — including
this one — are produced without collaboration rounds.

Per-document override (`consensus_required: true` in FS or PLAN front matter) remains
available and can raise consensus for a specific high-stakes artifact even when the
project default is off. Override can turn consensus *on* for a document; it cannot
turn the different-models constraint off.

### Constraint 3: A gate evaluator may not have participated in the round it evaluates

`ADR-0031` defines the gated round: contributors produce outputs, a primary synthesizes
them, and an evaluator returns a verdict on the synthesis. The evaluator MUST be a model
that filled no contributor slot in that round. This constraint is non-overridable on the
same terms as Constraint 1.

An overlapping evaluator judges a synthesis that incorporates its own claims. It is not
merely biased toward them — it cannot distinguish "this synthesis is sound" from "this
synthesis agrees with me," because for its own claims those are the same observation.
That is self-grading with an extra step, and it is exactly what the gate exists to
prevent.

**When no independent evaluator is available**, the round degrades to **synthesis-only**
per `ADR-0031` and the degraded state is recorded. It does not run an overlapping gate.
This parallels Constraint 1's failure behaviour: the workflow continues, but no artifact
claiming independent validation is produced. An ungated synthesis honestly labelled
is sound; a gated synthesis whose gate was a participant is a false claim.

**Rejecting the escape hatch.** The material this constraint is extracted from
implemented independence as a static check with an `--allow-gate-overlap` override "when
there is a specific reason." That override is this ADR's Option B failure mode, one layer
down: an exception that looks principled, is taken under exactly the pressure the rule
guards against — a small model pool, a third invocation that costs money — and produces
an artifact the framework appears to endorse. The constraint is kept and the override is
not carried over. Consumers who cannot field an independent evaluator run ungated rounds,
which is a supported configuration.

### What remains configurable

Everything else. Threshold (subject to the two-participant floor), failure mode,
per-gate opt-in, role mode at Gate A, model list contents, escalation depth, cost
ceiling, whether a round is gated at all, and the entire orchestration mechanism. FS-0019's Open Questions on drafter
versus reviewer defaults and override authority are unaffected by this ADR.

### Why not the other options?

**Option A** leaves the integrity constraint exposed to precisely the pressure that
will remove it. The consumer most tempted to configure `min_models: 1` is the one
running tight on budget, and that consumer ends up with an artifact trail asserting
validations that never occurred. Configurable integrity is not integrity.

**Option B** is the option that looks reasonable and is not. An escape hatch with a
required justification field appears to preserve the constraint while allowing informed
exceptions. In practice the justification is written once, copied forever, and read by
no one; the hatch becomes the default path for anyone who finds the constraint
inconvenient. Worse, it makes same-model rounds *sanctioned* — they produce artifacts
the framework endorses, which is exactly the manufactured confidence this ADR exists to
prevent. If same-model comparison is useful to a consumer, they may build it; they may
not call it consensus or emit a consensus artifact for it.

**Option D** gets the integrity constraint right and the default wrong. Shipping
consensus enabled imposes multi-model API cost and latency on every consumer at
adoption, including those who never wanted the feature, and prescribes a workflow the
framework does not itself run. Defaults should reflect practice.

## Consequences

### Positive

- A `pass` verdict in a consensus artifact means independent agreement. The artifact
  trail is trustworthy because the weakest configuration that could produce it is still
  a real multi-model round.
- The integrity constraint cannot erode under cost pressure, which is the only pressure
  that would erode it.
- Consumers adopt the framework without inheriting API cost or latency they did not
  choose.
- The framework does not prescribe a workflow it declines to follow.
- Misconfiguration is loud. A consumer who enables consensus with one model gets an
  error, not a silently weaker check.
- A gate verdict means a model outside the round read the synthesis. Constraint 3 makes
  that inference safe, which is the only thing that makes a verdict worth recording.
- One rule set covers both collaboration modes, so a review board cannot be introduced
  as a way around consensus's integrity requirements.

### Bad

- A consumer with genuine single-model constraints — air-gapped, one provider
  contract, cost-capped — cannot use the consensus feature at all. There is no degraded
  mode available to them. This is intended, and it means the feature is simply
  unavailable to some consumers rather than available in a diminished form.
- Non-overridable rules accumulate. Each one narrows what consumers may configure, and
  the framework should be reluctant to add more. This one earns its place because
  configurability defeats its entire purpose.
- Shipping disabled means the feature sees less real-world exercise, so bugs in the
  artifact schema or gate placement surface more slowly.
- Constraint 3 raises the floor on a gated round to three distinct models — two
  contributors plus an evaluator. Consumers with a two-model pool can run ungated rounds
  only. This is intended, and it is a real narrowing of who can use gating.

### Neutral

- The framework does not enforce these constraints at runtime — it does not implement
  orchestration. Enforcement lives in the consumer's consensus machinery. The framework
  supplies the binding rule and the schema; a consumer whose implementation violates it
  is out of compliance, detectably so from the artifact.
- "Different models" is judged by model identifier, which is a proxy for independence
  rather than a proof of it. Two distinct models sharing a base checkpoint are more
  correlated than the identifier suggests. The identifier test is the practical
  approximation available.
- Consumers remain free to run same-model comparison for their own purposes. The
  constraint governs what may be called consensus and what may emit a consensus
  artifact.

## Validation

We will consider this decision successful if:

1. **The shipped configuration is disabled.** `config/consensus.yml` in a fresh
   checkout has `enabled: false`, all gates disabled, and `models: []`.
2. **No same-model consensus artifact exists.** Any `docs/consensus/**/*.yml` artifact
   in a consuming repo lists at least two distinct model identifiers in
   `participants`.
3. **Insufficient-model configurations produce errors.** A consumer configuring
   `models` with fewer than two distinct entries and enabling consensus sees a
   configuration error, and no consensus artifact is written.
4. **The framework's own history shows no consensus rounds.** No
   `docs/consensus/` directory exists in this repository.
5. **`test/FS-0019/consensus-schema.bats` passes**, including the same-model
   rejection and default-disabled assertions.
6. **No gate verdict names an evaluator that appears in its own round's participant
   list.** Checkable directly from any round's artifacts.
7. **Rounds that could not field an independent evaluator are recorded as
   synthesis-only**, not as gated rounds with an overlapping evaluator.

## Links

- FS-0019: Multi-model consensus at workflow gates (defines the feature and flags both
  constraints for ratification; this ADR ratifies them)
- FS-0018: Issue lifecycle and autonomous triggers (the Issue layer consensus gates
  integrate with)
- ADR-0012: Non-overridable gates (the precedent for rules no instruction source may
  weaken; the different-models constraint joins this category)
- ADR-0031: Structured multi-model collaboration (defines the three-artifact round and
  the gated/synthesis-only distinction these constraints govern)
- FS-0021: Review board (the second collaboration mode brought under these constraints)
- ADR-0022: Autonomous and consensus meta-modes (defines `mode=consensus` and the
  role composition rule for collaboration rounds)
- ADR-0018: Single-identity workflow with agent co-attribution (the attribution layers
  carried by commits producing consensus artifacts)
- `config/consensus.yml` (the shipped consumer-copy template this ADR governs)
