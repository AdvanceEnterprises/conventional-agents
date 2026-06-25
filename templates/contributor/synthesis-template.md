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
-->

# Synthesis Template (Operator-Driven)

The operator produces one synthesis document per task at:
`docs/orchestration/<task-id>-synthesis.md`

**Operational note:** Until Hermes Agent gains direct integration with vendor CLIs, the synthesis author is the *operator*, not a model session. The operator may use any of the three models (or all three) as sounding-boards while drafting — but the synthesis itself is the operator's artifact and carries the operator's authority. When Hermes gains direct integration, the synthesis author may shift to a primary model session; the template structure below is invariant under that shift.

The synthesis has four mandatory sections, in this order:

## 1. Consensus

Points on which **all** contributors (or, where one contributor is silent, **all contributors who addressed the point**) agree.

For each consensus point:
- One sentence stating the consensus.
- Bullet list of contributors who affirmed it (by `attribution_label`).
- Citations to input sources that support it.

If no consensus exists on a given point, write "no consensus" — do not invent consensus by averaging.

## 2. Divergent Points

Points on which contributors disagree. **This section is mandatory even if there are no divergent points.** If empty, write "no divergence" and explain why (e.g., "all contributors were scoped to different sub-questions and did not overlap").

For each divergent point:
- The point itself (one sentence).
- Each contributor's position with attribution label and a one-sentence summary.
- Citation to the input sources each contributor cited (so the divergence is traceable, not editorial).
- The operator's read of the disagreement (one paragraph, separate from the positions).

Do **not** resolve the divergence here. Resolution belongs in Recommended Action or in operator escalation (which may mean revising the task framing, sending the synthesis back for revision, or asking a contributor to weigh in again).

## 3. Unique Insights

Points raised by only one contributor but worth carrying forward.

For each:
- The insight (one or two sentences).
- Contributor who raised it.
- Citation to the input source.
- Operator's read of whether to incorporate it (yes / no / defer).

## 4. Recommended Action

The operator's proposal for what to commit, escalate, or defer.

Must include:
- **Concrete proposal**: a single paragraph stating what artifact(s) to produce, modify, or skip.
- **Constraint check**: explicit citation of every accepted ADR and approved FS that constrains the proposal. If a constraint conflicts with the proposal, the operator MUST stop and escalate rather than override.
- **Open questions**: anything that needs human decision before the proposal can be committed (or, in this manual mode, before the operator opens the PR).
- **Attribution plan**: which contributors' outputs are incorporated, and the `Assisted-By:` and `Contributor-Session:` trailers that will appear in the commit.

## What the synthesis MUST NOT do

- It MUST NOT average divergent positions into a compromise without flagging the compromise as such.
- It MUST NOT introduce claims that no contributor raised.
- It MUST NOT silently resolve conflicts with accepted ADRs.
- It MUST NOT commit anything — the synthesis is input to the gate evaluation, then to operator approval, then to the commit per ADR-0013 attribution rules.
- It MUST NOT transition any governed document's status (per ADR-0013 Mode 2).

## Operator-specific guidance

Because the operator is the synthesis author (not a model session), some things to watch for:

- **Editor bias.** The operator has prior beliefs about the task. The synthesis must reflect what the contributors said, not what the operator expected to hear. Where the operator's read diverges from the contributors', that divergence is itself an artifact and goes in §2 (Divergent Points) with the operator's position attributed to "operator" and the contributors' positions attributed to their labels.
- **Synthesis as curation, not generation.** The four sections are curation of contributor output. The operator's own voice belongs in the *reads* and the *proposal*, not in §1, §2, or §3 directly. (Exception: §2's "operator's read of the disagreement" is the operator's voice; that is allowed and required.)
- **Tone of authority.** The synthesis is the operator's authoritative artifact for this task. It should read as the operator's synthesis, not as a third-party summary. The contributors are inputs, not co-authors.

## Example structure (illustrative, not template)

```markdown
# Synthesis: multi-model-2026-06-24

## 1. Consensus

- **X is the right approach.** Affirmed by `claude-contrib-1`, `codex-contrib-1`,
  `gemini-contrib-1`. Supported by `docs/specifications/FS-XXXX.md` §3.

## 2. Divergent Points

- **Y vs Z for handling failure mode F.**
  - `claude-contrib-1` argues for Y, citing [source].
  - `codex-contrib-1` argues for Z, citing [source].
  - `gemini-contrib-1` is silent (out of scope for the research-pass prompt).
  - Operator's read: ...

## 3. Unique Insights

- **W is a constraint nobody else mentioned.** Raised by `gemini-contrib-1`,
  citing [source]. Operator's read: incorporate — this is a real concern that
  the other contributors did not surface.

## 4. Recommended Action

Concrete proposal: ...

Constraint check:
- ADR-XXXX (accepted): [relevant section]
- FS-XXXX (approved): [relevant section]
- No conflicts identified.

Open questions:
- ...

Attribution plan:
- `Assisted-By: claude-sonnet-4`, `codex`, `gemini-2.5-pro`
- `Contributor-Session: <session IDs or PR-comment URLs>`
```
