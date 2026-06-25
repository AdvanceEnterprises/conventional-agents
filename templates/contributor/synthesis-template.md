<!--
REVIEWER_TEMPLATE:
- Role: Synthesis author (operator-as-primary in current operational mode)
- Inputs: Contributor outputs in contracted format, task framing, applicable ADRs
- Output: Synthesis document at docs/orchestration/<task-id>-synthesis.md

PARSING_HINTS:
- Document type: synthesis-template
- In operator-driven orchestration (the current operational mode), the
  OPERATOR is the synthesis author. A model session may be used as a
  sounding-board, but the synthesis itself is the operator's artifact.
- The synthesis MUST preserve disagreement; do not average divergent positions.
- Every claim in the synthesis MUST trace to a specific contributor output
  (by attribution label) and to an input source (by path or URL).
- The "Recommended Action" section is the operator's call; it is not derived
  by averaging contributors.
- The synthesis MUST cite the input ADRs/FSs that constrain the recommended
  action; if the action conflicts with a constraint, STOP and escalate.
- The Coverage/Disposition Record is mandatory. Per PR #62 reviewer finding,
  the synthesis must distinguish "contributor not asked" from "asked and
  silent" from "off-topic response" so the gate can validate attribution
  fidelity.
-->

# Synthesis Template (Operator-Driven)

The operator produces one synthesis document per task at:
`docs/orchestration/<task-id>-synthesis.md`

**Operational note:** The synthesis author is the *operator* in the current operational mode (operator-driven orchestration). The operator may use any of the contributor models as a sounding-board while drafting — but the synthesis itself is the operator's artifact and carries the operator's authority. When Hermes gains direct integration, the synthesis author may shift to a primary model session; the template structure below is invariant under that shift.

The synthesis has five mandatory sections, in this order:

1. Coverage/Disposition Record (NEW 2026-06-25)
2. Consensus
3. Divergent Points
4. Unique Insights
5. Recommended Action

Plus an attribution plan at the end.

## 1. Coverage/Disposition Record

A table that records, for every contributor and every question or claim under review, what the contributor did. This is required per PR #62 reviewer finding — without it, "all contributors who addressed the point" can label partial coverage as apparent consensus.

| Question / Claim | claude-contrib-1 | codex-contrib-1 | qwen3-contrib-1 | devstral-contrib-1 |
| --- | --- | --- | --- | --- |
| Q1: <question 1> | addressed | addressed | silent (out-of-scope) | addressed |
| Q2: <question 2> | addressed | addressed | addressed | addressed |
| Q3: <question 3> | addressed | silent (NOT_ASKED) | out-of-scope | addressed |

Coverage codes (per contributor per question):

- `addressed` — the contributor produced content relevant to the question.
- `silent (NOT_ASKED)` — the contributor's prompt did not include this question. Legitimate scoping.
- `silent (ASKED_NO_RESPONSE)` — the contributor was asked but produced no relevant content. Possibly a contributor failure.
- `out-of-scope` — the contributor addressed the question and indicated it was outside their assigned role.
- `off-topic` — the contributor's response does not engage with the question at all.

A separate Disposition Record captures, for **every received claim** (not just the claims that survive into the synthesis), what was done with it. This is required per the pilot's round-2 finding (C-CLAUDE-009, C-CODEX-105, C-CODEX-128) — the original Disposition Record dropped rejected claims and lost envelope fields, making it impossible for the gate to verify that the synthesis considered every contributor output.

The Disposition Record preserves the shared claim envelope fields (per ADR-0016 §"Structured Output Contract") so the gate can validate attribution fidelity without re-reading the contributor briefs:

| Claim ID | Statement (short) | Contributor(s) | Source citation | Position | Confidence | Disposition | Reason | Canonical claim ID |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| C-CLAUDE-001 | <claim statement> | claude-contrib-1 | `docs/decisions/ADR-0016.md §"Decision Outcome"` | disagree | high | incorporate | supported by ADR-0013 | — |
| C-CODEX-002 | <claim statement> | codex-contrib-1 | `templates/contributor/contributor-prompt.md §"Parameters"` | affirm | high | reject | contradicts FS-0014 | — |
| C-QWEN-003 | <claim statement> | qwen3-contrib-1 | `scripts/render_contributor_prompt.py` line 317 | disagree | medium | defer | follow-up needed | — |
| C-DEVSTRAL-004 | <claim statement> | devstral-contrib-1 | `docs/decisions/ADR-0016.md §"Status"` | affirm | high | duplicate | same as C-CLAUDE-001 | C-CLAUDE-001 |

Column descriptions:

- **Claim ID**: the contributor's claim identifier (from the shared claim envelope).
- **Statement (short)**: one-line summary of the claim.
- **Contributor(s)**: the `attribution_label` of the contributor(s) who raised the claim.
- **Source citation**: repo-relative path with section anchor (from the claim envelope's `source_citation` field). Ties every claim to a verifiable input source.
- **Position**: the contributor's stance from the claim envelope (`affirm` / `disagree` / `silent` / `out-of-scope`). Preserved so the gate can verify divergence preservation without re-reading the contributor brief.
- **Confidence**: the contributor's self-rated confidence from the claim envelope (`high` / `medium` / `low`). Preserved so the gate can weight dispositions.
- **Disposition**: what the operator did with the claim (see codes below).
- **Reason**: one-sentence justification for the disposition.
- **Canonical claim ID**: when disposition is `duplicate`, the claim ID of the surviving claim. Empty (`—`) for non-duplicate claims.

Disposition codes (per claim):

- `incorporate` — claim enters the synthesis's body and (if applicable) the commit.
- `reject` — claim is excluded from the synthesis with a reason (e.g., contradicts an accepted ADR).
- `defer` — claim is recorded as an open question for follow-up.
- `duplicate` — claim is the same as another claim already in the synthesis; one survives, the rest are merged. The `canonical_claim_id` column records which claim survives.
- `out-of-scope` — claim is recorded but excluded from this synthesis because it falls outside the task framing.

The Coverage Record is the gate's primary check on attribution fidelity. The Disposition Record is the gate's primary check on whether the synthesis preserves all unique insights rather than silently dropping them, and whether every received claim's envelope fields are carried forward.

## 2. Consensus

Points on which **all** contributors with `addressed` coverage agree.

For each consensus point:
- One sentence stating the consensus.
- Bullet list of contributors who affirmed it (by `attribution_label`).
- Citations to input sources that support it.

If no consensus exists on a given point, write "no consensus" — do not invent consensus by averaging.

## 3. Divergent Points

Points on which contributors disagree. **This section is mandatory even if there are no divergent points.** If empty, write "no divergence" and explain why (e.g., "all contributors were scoped to different sub-questions and did not overlap").

For each divergent point:
- The point itself (one sentence).
- Each contributor's position with attribution label and a one-sentence summary.
- Citation to the input sources each contributor cited (so the divergence is traceable, not editorial).
- The operator's read of the disagreement (one paragraph, separate from the positions).

Do **not** resolve the divergence here. Resolution belongs in Recommended Action or in operator escalation (which may mean revising the task framing, sending the synthesis back for revision, or asking a contributor to weigh in again).

## 4. Unique Insights

Points raised by only one contributor but worth carrying forward.

For each:
- The insight (one or two sentences).
- Contributor who raised it.
- Citation to the input source.
- Operator's read of disposition (incorporate / reject / defer / duplicate / out-of-scope) with a reason.

## 5. Recommended Action

The operator's proposal for what to commit, escalate, or defer.

Must include:
- **Concrete proposal**: a single paragraph stating what artifact(s) to produce, modify, or skip.
- **Constraint check**: explicit citation of every accepted ADR and approved FS that constrains the proposal. If a constraint conflicts with the proposal, the operator MUST stop and escalate rather than override.
- **Open questions**: anything that needs human decision before the proposal can be committed (or, in this manual mode, before the operator opens the PR).
- **Attribution plan**: which contributors' outputs are incorporated, and the `Assisted-By:` and `Contributor-Session:` trailers that will appear in the commit.

The attribution plan uses the render-mode-aware trailer format:

- `external-cli` contributors: `Assisted-By: <model name>`
- `hermes-chat` and `research-pass` contributors: `Assisted-By: hermes (<model name>)`

## What the synthesis MUST NOT do

- It MUST NOT average divergent positions into a compromise without flagging the compromise as such.
- It MUST NOT introduce claims that no contributor raised.
- It MUST NOT silently resolve conflicts with accepted ADRs.
- It MUST NOT commit anything — the synthesis is input to the gate evaluation, then to operator approval, then to the commit per ADR-0013 attribution rules.
- It MUST NOT transition any governed document's status (per ADR-0013 Mode 2).
- It MUST NOT treat `silent (NOT_ASKED)` as `addressed` in the Consensus section.

## Operator-specific guidance

Because the operator is the synthesis author (not a model session), some things to watch for:

- **Editor bias.** The operator has prior beliefs about the task. The synthesis must reflect what the contributors said, not what the operator expected to hear. Where the operator's read diverges from the contributors', that divergence is itself an artifact and goes in §3 (Divergent Points) with the operator's position attributed to "operator" and the contributors' positions attributed to their labels.
- **Synthesis as curation, not generation.** The sections are curation of contributor output. The operator's own voice belongs in the *reads* and the *proposal*, not in §2, §3, or §4 directly. (Exception: §3's "operator's read of the disagreement" is the operator's voice; that is allowed and required.)
- **Tone of authority.** The synthesis is the operator's authoritative artifact for this task. It should read as the operator's synthesis, not as a third-party summary. The contributors are inputs, not co-authors.

## Example structure (illustrative, not template)

```markdown
# Synthesis: multi-model-2026-06-24

## 1. Coverage/Disposition Record

| Question / Claim | claude-contrib-1 | codex-contrib-1 | qwen3-contrib-1 |
| --- | --- | --- | --- |
| Q1: FS-0015 supporting roles | addressed | addressed | out-of-scope |
| Q2: gate verdict taxonomy | addressed | silent (NOT_ASKED) | addressed |

| Claim ID | Statement (short) | Contributor(s) | Source citation | Position | Confidence | Disposition | Reason | Canonical claim ID |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| C-CLAUDE-001 | FS-0015 requires declaring all supporting roles | claude-contrib-1 | `docs/specifications/FS-0015.md §"Explainability Convention"` | affirm | high | incorporate | supported by FS-0015 | — |
| C-CODEX-002 | gate should have INCOMPLETE verdict | codex-contrib-1 | `templates/contributor/gate-template.md §"Failure modes"` | disagree | high | reject | superseded by two-layer status/verdict model | — |
| C-QWEN-003 | (skipped; out-of-scope) | qwen3-contrib-1 | — | out-of-scope | — | out-of-scope | role assignment | — |

## 2. Consensus

- **FS-0015 requires declaring all supporting roles, not a single role.** Affirmed by
  `claude-contrib-1`, `codex-contrib-1`. Supported by `docs/specifications/FS-0015.md`
  §"Explainability Convention."

## 3. Divergent Points

- **Gate verdict taxonomy (separate execution status vs. third verdict).**
  - `claude-contrib-1` argues for adding INCOMPLETE as a third verdict, citing the
    original bug.
  - `codex-contrib-1` argues for separating execution status (COMPLETE/NOT_RUN/INVALID)
    from verdict, citing the action-framework-research skill's pattern.
  - `qwen3-contrib-1` is silent (out-of-scope for the assigned role).
  - Operator's read: codex-contrib-1's framing is more orthogonal to the existing
    verdicts and avoids stretching PROCEED/CONDITIONAL/HALT into execution states.
    Adopt that direction.

## 4. Unique Insights

- **CONDITIONAL loop is unbounded.** Raised by `claude-contrib-1`, citing
  `templates/contributor/gate-template.md` §"Failure modes." Operator's read: defer
  to a follow-up ADR; this pilot does not need an immediate bound, but the framework
  should grow one before the second pilot.

## 5. Recommended Action

Concrete proposal: Adopt ADR-0016's revised direction with the gate execution status
(COMPLETE / NOT_RUN / INVALID) orthogonal to the verdict (PROCEED / CONDITIONAL /
HALT), per codex-contrib-1's framing. Implement in the helper script as a static
check that errors when gate.model is in contributors[].model unless
--allow-gate-overlap is passed.

Constraint check:
- ADR-0013 (proposed): no conflict — ADR-0016's gate is additive per §"What this ADR
  does NOT do."
- FS-0015 (approved): supported — the gate does not introduce a new session mode or
  role.
- FS-0014 (approved): no conflict.

Open questions:
- Should the gate-execution-status be a fourth verdict or a separate field? Codex's
  framing suggests separate; claude's framing suggests fourth. Operator's read: defer
  to gate evaluator's actual output shape; both work in practice.

Attribution plan:
- `Assisted-By: claude-sonnet-4, hermes (codex), hermes (qwen3-coder-next)`
- `Contributor-Session: <session IDs or PR-comment URLs>`
```