---
type: adr
id: ADR-0022
status: accepted
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0018
  - FS-0019
superseded_by: null
---

# ADR-0022: Autonomous and consensus are meta-modes, not session modes

## Status

- Accepted

## Context and Problem Statement

FS-0015 established five session modes — Architecture Planning, Document Authoring,
Implementation, Review, Communications — each mapping to a primary role from the
six-role model. A session declares its mode, and the mode tells everyone what stance
the agent is taking.

FS-0018 and FS-0019 each introduce a new value into the `mode=` field of the
agent-stance declaration. FS-0018 adds `autonomous` for cron-fired and webhook-fired
agents. FS-0019 adds `consensus` for multi-model rounds. Both are described in their
source specs as extensions to the mode vocabulary, and `workflows/session-modes.md`
now documents them as "meta-modes."

Treating these as ordinary sixth and seventh session modes creates an immediate
contradiction. The five existing modes each answer *what role stance is the agent
taking* — Implementation means Implementer, Review means Reviewer. But `autonomous`
answers a different question entirely: it says a cron job fired this, with no human
watching. It says nothing about role. A cron-fired agent might be drafting a document
(Document Author), investigating a bug (Implementer), or auditing the framework (Head
Architect). Forcing `mode=autonomous` to occupy the same field as `mode=implementation`
means an autonomous session cannot declare which role it holds — the field is already
spent.

`consensus` has the same shape. A consensus round is N models independently doing
something, but the something is still one of the five standard modes. FS-0019 says so
directly: participants operate as "independent Drafters or independent Reviewers."

Left unresolved, this produces stance declarations that are either ambiguous
(`mode=autonomous` with no role information) or ad hoc (`mode=autonomous-implementation`
invented per session). The regex in FS-0018's success criteria accepts any string in
the `mode=` field, so nothing catches the drift.

The question this ADR answers: **are `autonomous` and `consensus` session modes, or
something else?**

## Decision Drivers

- **A stance declaration must always convey role.** The role is what determines
  permitted outputs, prohibited actions, and stop conditions. Losing it makes the
  declaration far less useful.
- **The five-mode model should not be diluted.** FS-0015's modes form a coherent set
  answering one question. Adding values that answer a different question weakens the
  concept.
- **Execution context is real and must be expressible.** Whether a human was present,
  and whether multiple models participated, are genuinely important facts that belong
  in the audit trail.
- **The vocabulary must be closed and checkable.** An open-ended `mode=` field cannot
  be validated, which means drift accumulates silently.
- **ADR-0019 and ADR-0021 depend on `autonomous` having precise meaning.** The
  autonomous gate keys off "no human present"; the cron identity convention requires
  `mode=autonomous` as a mandatory marker.

## Considered Options

### Option A: Treat them as ordinary session modes (six and seven)

Add `autonomous` and `consensus` to FS-0015's list. The `mode=` field accepts seven
values. Role is inferred from context or omitted.

### Option B: Separate orthogonal fields

Keep `mode=` to the five session modes. Add distinct fields — `presence=attended|
unattended` and `participants=single|multi` — to the stance declaration.

### Option C: Meta-modes composed with a declared role

`autonomous` and `consensus` are a distinct category: they describe *how* a session
executes, not *what* stance it takes. When a meta-mode occupies the `mode=` field, the
`role=` field carries the stance, and the underlying session mode is implied by that
role.

### Option D: Compound mode values

Allow hyphenated composites: `mode=autonomous-implementation`,
`mode=consensus-review`. One field, both facts.

## Decision Outcome

**Chosen option: Option C — meta-modes composed with a declared role.**

### The distinction

The framework recognizes two categories of value in the `mode=` field:

**Session modes** (five, from FS-0015) describe the *role stance* of the session:
`architecture-planning`, `document-authoring`, `implementation`, `review`,
`communications`.

**Meta-modes** (three) describe the *execution context* of the session:

- **`autonomous`** — no human is present. The session was fired by cron, by a webhook,
  or delegated as a subagent with no interactive human in the loop.
- **`consensus`** — multiple independent models participate in a structured round at a
  workflow gate, performing the same task, and their outputs are compared for
  agreement (FS-0019).
- **`review-board`** — multiple independent models examine one artifact from *different*
  role stances, and their findings are merged rather than compared (FS-0021).

`consensus` and `review-board` are both multi-model collaboration rounds under
ADR-0031 and are governed by the same integrity constraints (ADR-0023). They are
separate mode values because they answer different questions: whether participants
converged, versus what each perspective caught that the others missed. A session is
never both at once — a round is one or the other.

A meta-mode is not a stance. It is a fact about how the session runs.

### The composition rule

When `mode=` carries a meta-mode, the `role=` field MUST carry a role from the
six-role model, and that role determines the applicable stance, permitted outputs, and
prohibited actions. The underlying session mode is implied by the role.

```text
agent-stance: mode=autonomous; role=Head Architect; model=<model>; session=nightly-audit; rationale=<reason>
agent-stance: mode=consensus; role=Reviewer; model=<model>; session=pr-142-gate-b; rationale=<reason>
agent-stance: mode=review-board; role=Head Architect; model=<model>; session=fs-0020-board; rationale=<reason>
```

Both meta-modes may apply at once. An unattended consensus round declares
`mode=autonomous,consensus` — comma-separated, order-insensitive.

### The closed vocabulary

The `mode=` field accepts exactly eight values: the five session modes and the three
meta-modes, singly or as a comma-separated combination of meta-modes with at most one
session mode. `consensus` and `review-board` are mutually exclusive. Any other value,
or that pairing, is invalid.

This closes the vocabulary. FS-0018's stance regex validates *format*; this ADR
supplies the *value set* that format is checked against.

### What meta-modes do not change

A meta-mode never relaxes a role's constraints. An agent declaring
`mode=autonomous; role=Implementer` is bound by every Implementer prohibition and stop
condition. The meta-mode adds constraints — ADR-0019's autonomous gate, ADR-0021's
identity markers — and removes none.

### Why not the other options?

**Option A** is the contradiction this ADR exists to resolve. It spends the one field
that carries role on a fact that is not a role, leaving autonomous sessions unable to
declare their stance. It also dilutes FS-0015's model, which is coherent precisely
because all five values answer the same question.

**Option B** is the cleanest design in the abstract and the wrong one here. It requires
changing the stance line's shape, which is already specified in FS-0018, embedded in
`Agent-Attribution:` trailers per ADR-0018, asserted by a regex in the bats suite, and
documented in `workflows/session-modes.md`. The gain over Option C is conceptual
tidiness; the cost is a breaking change across four surfaces. Option C expresses the
same two facts within the existing shape.

**Option D** produces a combinatorial vocabulary — five session modes times two
meta-modes times their combination is fifteen compound values, each needing definition
and validation. It also buries the meta-mode inside a composite token, making it harder
to filter for `autonomous` when auditing ADR-0019's gate. The audit query becomes a
substring match rather than a field match.

## Consequences

### Positive

- Every stance declaration conveys role, including autonomous and consensus sessions.
- FS-0015's five-mode model stays coherent and undiluted.
- The vocabulary is closed and therefore checkable — a validator can reject
  non-enumerated values rather than silently accepting drift.
- Auditing ADR-0019's gate is a field match on `mode` containing `autonomous`.
- No change to the stance line's shape; existing regexes, trailers, and tests continue
  to work.

### Bad

- The `mode=` field is now overloaded in the sense that it carries values of two
  different kinds. A reader must know which values are meta-modes to interpret a
  declaration correctly, and `workflows/session-modes.md` must teach that distinction.
- The composition rule is implicit knowledge: `mode=autonomous` alone does not say
  what the session is doing without reading `role=`. This is intentional but requires
  the two fields to be read together.
- Comma-separated combination adds a small parsing burden over a single token.

### Neutral

- Two meta-modes exist today. The category is open — a future execution context (for
  example, a sandboxed or dry-run mode) could be added as a third without disturbing
  the session-mode set.
- Interactive single-model sessions are unaffected. They declare a session mode as
  before and carry no meta-mode.
- Whether a delegated subagent is `autonomous` depends on human presence in the parent
  session, not on the delegation mechanism.

## Validation

We will consider this decision successful if:

1. **Every autonomous stance declaration carries a role.** Sampling declarations with
   `mode` containing `autonomous` shows a populated `role=` field from the six-role
   model in each.
2. **No non-enumerated mode values appear.** Auditing stance declarations and
   `Agent-Attribution:` trailers produces no `mode=` value outside the seven.
3. **No compound values appear.** No declaration uses a hyphenated composite such as
   `autonomous-implementation`.
4. **Gate auditing works as a field match.** Filtering for `mode` containing
   `autonomous` returns the complete set of unattended actions, verifiable against
   ADR-0019's checkpoint table.
5. **`workflows/session-modes.md` documents the distinction**, and a reader can
   determine from it alone which values are meta-modes.

## Links

- FS-0015: Role selection and session modes (defines the five session modes this ADR
  preserves)
- FS-0018: Issue lifecycle and autonomous triggers (introduces `autonomous` and the
  stance declaration format)
- FS-0019: Multi-model consensus at workflow gates (introduces `consensus` and
  describes it as a meta-mode)
- ADR-0019: Issue Type immutability and the autonomous gate (the gate that keys off
  `mode=autonomous`)
- ADR-0021: Cron actor identity (requires `mode=autonomous` as a mandatory marker)
- ADR-0023: Consensus integrity constraints (governs what a `mode=consensus` round
  must satisfy)
- `workflows/session-modes.md` (workflow doc that documents the meta-mode distinction)
- `guidelines/ROLE_CONTRACT.md` (the six roles the `role=` field draws from)
