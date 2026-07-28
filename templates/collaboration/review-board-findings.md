# Review Board Findings Template

The merged findings set for a **review board** (`FS-0021`): several models
examined one artifact from different role stances, and their findings are
combined.

For consensus rounds, see `consensus-synthesis.md`. A board produces
findings and **no verdict** — no score, no approval, no recommendation to
approve.

Written by the **primary**. Seats do not write it.

---

## What merging is and is not

**Merging combines. It does not adjudicate.**

Where two seats report contradictory findings, both are recorded and each
names the other. The merge does not decide between them, average them, or
drop the minority. A contradiction between two role stances is
information about the artifact — usually that it satisfies one concern at
the cost of another — and resolving it silently destroys the finding.

Deduplication is limited to the *same observation* from different seats.
Merge those into one finding recording every raising seat: a finding
raised independently from three stances carries different weight than one
raised from one.

---

## 1. Board composition

| Seat | Model | Role stance |
| --- | --- | --- |
| `seat-a` | … | Reviewer |
| `seat-b` | … | Head Architect |

Both constraints are checkable from this table and both are `ADR-0023`
requirements rather than guidance:

- **Distinct models.** Two seats on one model is not a board.
- **At least two distinct role stances.** Same stance throughout is a
  consensus round on a review, and `FS-0019` covers that.

## 2. Coverage record

Per seat, per review dimension:

| Dimension | `seat-a` | `seat-b` | `seat-c` |
| --- | --- | --- | --- |
| Spec conformance | addressed | addressed | silent (not asked) |
| Constraint conflicts | addressed | addressed | addressed |
| Testability | silent (asked) | addressed | off-topic |

Same disposition values as consensus: `addressed`, `silent (not asked)`,
`silent (asked)`, `off-topic`.

**Why this matters here** is the inverse of why it matters in consensus.
There, missing coverage inflates apparent agreement. Here, a dimension
with no findings is ambiguous between *"every seat looked and found
nothing"* and *"no seat looked."* Those are opposite conclusions — one is
evidence of quality, the other is a hole reported as a clean bill of
health.

Unlike consensus there is **no threshold and no sufficiency rule**. A
board with partial coverage still produces useful findings. The
requirement is that the gaps are visible.

A seat that reviewed a dimension and found nothing is `addressed` with an
empty finding set. That is a result, not silence.

## 3. Findings

| ID | Raised by | Also raised by | Severity | Claim | Source | Contradicts | Disposition | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `a-001` | `seat-a` | `seat-c` | substantive | … | `path#L12` | — | accepted | — |
| `b-002` | `seat-b` | — | blocking | … | `ADR-0012` | `a-004` | accepted | — |
| `a-004` | `seat-a` | — | minor | … | `path#L88` | `b-002` | rejected | … |

**Severity** is the raising seat's assessment and is advisory:
`blocking` / `substantive` / `minor` / `question`. A seat reporting
`blocking` blocks nothing — it asserts that in its stance the issue
should be resolved before the artifact proceeds. Mechanical effect would
make the board a gate, which it is not.

**`contradicts`** is a list, not a single reference. Three seats can form
a contradiction chain, and the merge records the chain rather than
picking a winner.

**Disposition** is set by the primary, never by the seat:

- `accepted` — stands and will be addressed.
- `rejected` — with a stated reason. Rejected findings are **not
  deleted**.
- `deferred` — valid, out of scope for this change. Requires a
  destination: a work item, or a `BACKLOG.md` entry.
- `duplicate-of` — names the finding it duplicates.

`rejected` and `deferred` require a non-empty reason. Every finding gets
a disposition; an undispositioned finding means the board's output was
not fully read.

## 4. Contradictions

Called out separately from the findings table, because a reader scanning
dispositions will miss them.

| Finding | Position | Opposing finding | Position | Resolution |
| --- | --- | --- | --- | --- |
| `b-002` | … | `a-004` | … | primary accepted `b-002`; reason … |

Resolution is the primary's call and is marked as such. "Both stand
unresolved" is a legitimate entry — a contradiction the primary cannot
resolve is escalation material, not something to force.

## 5. Coverage gaps

Dimensions where no seat was `addressed`, listed explicitly rather than
left as absence.

A board that reviewed four of six declared dimensions reviewed four. Say
which two it did not.

---

## What this document does not contain

- A verdict, score, or approval. Boards are advisory (`FS-0021`).
- Any status transition, and no merge. `ADR-0012` is untouched: a board
  may report that a change looks ready, and a human still merges it.
- Fixes. Seats in Reviewer stance inherit Role 4's prohibition on
  modifying what they review, and no stance gains authority from being on
  a board.

## Artifact

Per `FS-0021`, at
`docs/review-boards/<artifact-id>/<placement>-<timestamp>.yml`, carrying
`seats`, `coverage`, `findings`, and — on gated boards — `gate`.

On a gated board the evaluator checks **the merge, not the artifact
under review**: whether findings survived, contradictions were preserved,
coverage is complete, and dispositions carry their required reasons. A
`HALT` means the merge is unsound. It says nothing about the reviewed
artifact.

Committed under `ADR-0018` as amended by `ADR-0029`.

## Pitfalls

- **Do not resolve contradictions during merge.** Record both, then
  resolve explicitly in section 4 if you can.
- **Do not delete rejected findings.** The rejection and its reason are
  part of the record.
- **Do not treat `blocking` as blocking.** It is a seat's assessment.
- **Do not let an empty dimension read as a pass.** Section 5 exists so
  that "nobody looked" cannot be mistaken for "nothing found."
- **Do not seat one model twice** in different stances. Role stance
  changes what a model looks for, not what it can see (`FS-0021`).
