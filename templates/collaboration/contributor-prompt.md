# Contributor Prompt Template

Renders the prompt given to one participant in a collaboration round —
a **participant** in a consensus round (`FS-0019`) or a **seat** on a
review board (`FS-0021`).

**Why a template rather than hand-composed prompts.** Participants must
receive identical framing, differing only in declared per-participant
parameters. Hand-composing each one reintroduces prompt sensitivity:
differences between outputs then reflect how each was asked rather than
what each thinks, and the round's signal is contaminated at the source.
Render every participant from this template or the round is not
comparable.

---

## Parameters

Per round:

| Parameter | Meaning |
| --- | --- |
| `round_id` | Identifier for this round |
| `mode` | `consensus` or `review-board` — never both (`ADR-0022`) |
| `task` | What participants are being asked to do, identically for all |
| `input_sources` | Every path, URL, or artifact participants may read |
| `constraints` | Accepted ADRs and approved specs that bound the answer |
| `gated` | Whether an independent evaluator will review the synthesis |

Per participant:

| Parameter | Meaning |
| --- | --- |
| `participant_id` | Namespace for this participant's claim or finding IDs |
| `model` | Model identifier — must be distinct across participants (`ADR-0023`) |
| `role` | Role stance from `guidelines/ROLE_CONTRACT.md` |
| `render_mode` | Invocation transport. Consumer-defined; see note below |
| `output_contract` | Which output shape this participant returns |

**On `render_mode`:** how a participant is invoked — a CLI session, an
API call, a provider-managed pool — is a transport concern, not a
governance one. The framework does not enumerate transports. Attribution
and output contract are identical regardless of transport, and that is
what makes outputs comparable. Provider-level guidance is specified
separately.

**Composition checks before rendering.** These are `ADR-0023` constraints
and are not advisory:

- All `model` values distinct. Two participants on the same model is not
  a round.
- For `mode: review-board`, at least two distinct `role` values.
- If `gated`, the evaluator's model appears in no participant slot.

A round failing any of these does not render. It fails with a
configuration error and produces no artifact.

---

## Template

Copy the block below and substitute the parameters. Render one per
participant, varying only the per-participant values.

```text
TRANSPARENCY STATEMENT

You are participating in a collaboration round under the
conventional-agents framework.

agent-stance: mode={{mode}}; role={{role}}; model={{model}}; session={{round_id}}; rationale=participant in {{mode}} round

You are ONE OF SEVERAL participants. Others are being asked the same
question, independently, on different models. You will not see their
responses and they will not see yours. Do not attempt to anticipate or
defer to them — your independent judgment is the entire reason you were
invoked.

Your declared role for this round is {{role}}. Its authority boundaries,
prohibited actions and stop conditions in guidelines/ROLE_CONTRACT.md
apply to you here exactly as they would in a standalone session.
Participating in a round grants you no authority that role would not
otherwise have.

TASK

{{task}}

INPUTS

Read only these. Do not assume access to context beyond them, and do not
infer the contents of anything not listed.

{{input_sources}}

CONSTRAINTS

These are binding. An answer that violates one is not a valid answer —
say so rather than working around it.

{{constraints}}

OUTPUT CONTRACT

Return discrete, individually identified items, not prose. The synthesis
step combines items mechanically; anything expressed only in connecting
narrative is lost.

Each item carries:
  id          {{participant_id}}-NNN, numbered from 001
  position    your stance on this item
  confidence  high | medium | low
  claim       one sentence
  source      the input this rests on — path, line, or constraint

{{output_contract}}

If you have nothing to say on a point you were asked about, say so
explicitly. Silence and "I considered this and have no finding" are
different results, and the coverage record distinguishes them.

GUARDRAILS

- Do not modify any artifact. This round produces analysis only.
- Do not open, update, or merge pull requests.
- Do not perform status transitions on governed documents.
- Do not invent inputs. If something you need is missing, report that as
  an item rather than assuming its contents.

ESCALATION

Stop and report rather than proceeding if a constraint conflicts with the
task, a listed input is missing or unreadable, or the task requires
authority your declared role does not have.

ATTRIBUTION

Your output is committed under ADR-0018 as amended by ADR-0029. The
commit carries the actor in user.email, the model in user.name, and an
Agent-Attribution: trailer naming actor, model, role and session. You do
not add trailers yourself.
```

## What this template does not do

- **It does not render the gate prompt.** See
  `templates/collaboration/gate.md`. The gate is invoked once per round
  rather than once per participant, and its independence constraint makes
  it a different artifact.
- **It does not synthesize.** See `consensus-synthesis.md` or
  `review-board-findings.md` depending on mode.
- **It does not choose the participant set.** Model and role selection is
  a consumer configuration decision, subject to the composition checks
  above.

## Pitfalls

- **Do not skip the transparency statement.** `FS-0018` requires the
  stance declaration before any action, and a participant that does not
  know it is one of several will hedge toward an imagined consensus.
- **Do not vary the task text between participants.** Differences in
  framing produce differences in output that look like disagreement.
- **Do not under-list `input_sources`.** Participants have none of the
  operator's context. A participant that cannot see a constraint will
  violate it, and the violation is the operator's error.
- **Do not let a participant fill two seats.** Same model twice is
  forbidden by `ADR-0023`, not merely discouraged.
