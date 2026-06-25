# Research Brief Template

The canonical Research Brief format used by multi-model orchestration
contributors when `structured_output.contract: research_brief` is set in
their parameter file. This file is the authoritative reference; the
inline list in the rendered contributor prompt is a compact reminder,
not a substitute.

## When to use

A Research Brief is the structured output for **design / review /
research** tasks where the contributor's job is to survey an artifact
or topic and produce a reasoned written response. It is **not** the
contract for code-writing tasks; for those use `json_schema` (see the
contributor prompt template's contract selector).

A Research Brief is the right contract when:

- The contributor is reviewing a proposal (ADR, FS, PLAN) and giving feedback.
- The contributor is surveying a topic for the primary session.
- The contributor is comparing multiple approaches and recommending one.

A Research Brief is the wrong contract when:

- The contributor is writing code (use `json_schema` for structured extraction).
- The contributor's output is a single answer (no need for section structure).
- The contributor's task is highly interactive (Research Brief is one-shot).

## Format

A Research Brief MUST contain these five sections in this order. Section
names are exact; they are anchor names and contributors should not
rename them.

### 1. Executive Summary

3-5 paragraphs. The first paragraph names the contributor's role and
the artifact or topic under review. Subsequent paragraphs state the
contributor's overall read, the strongest point they want the primary
session to consider, and any disagreement with the proposal that
should be preserved (not averaged). When the contributor's reading
conflicts with the task framing, surface that conflict here rather
than complying silently.

### 2. Canonical Concepts

A table. Each row is a concept the contributor considers load-bearing
for the artifact under review. Columns are flexible but typically
include:

| Concept | Definition (1 sentence) | Why it matters here | Source |
| --- | --- | --- | --- |
| ... | ... | ... | `path/to/file.md §"Section"` |

The "Source" column is mandatory. Every claim in the brief must cite
the input source it derives from. Sources are repo-relative paths with
section anchors (e.g., `docs/decisions/ADR-0016.md §"Decision
Outcome" item 5`).

### 3. Relevant Standards

A table. Each row is an existing ADR, FS, or external standard that
constrains the artifact under review. Columns:

| Standard | Scope | Applies here how | Constraint |
| --- | --- | --- | --- |
| ADR-0013 | Multi-session coordination | Yes — contributor must follow Mode 2 (primary + contributor) rules | Cannot commit to primary's branch |
| ... | ... | ... | ... |

If no relevant standards apply, the table is empty and a one-sentence
note explains why. Do not omit the section.

### 4. Tools and Ecosystem

A table. Each row is a tool, skill, repository, or external dependency
the contributor references or relies on. Columns:

| Tool / Source | Type | Used for | Status |
| --- | --- | --- | --- |
| ... | script / skill / repo / external | ... | present / proposed / missing |

This section is where the contributor flags gaps — things the artifact
depends on that don't currently exist (this is how the original
`references/research-brief-template.md` missing-file bug was caught by
Codex in the first pilot).

### 5. Recommendations

Specific, actionable items. Each recommendation names:

- What should change (the artifact, the template, the script, etc.).
- Who owns the change (operator / primary session / contributor / tool maintainer).
- Whether the change is required for the current pilot or a follow-up.

A recommendation is not "consider X" or "might be worth exploring Y."
It is "do X" or "do not do X" with a one-paragraph justification.

## Claim envelope

Every claim in a Research Brief MUST carry the **shared claim envelope**
defined by ADR-0016 §"Structured Output Contract." This applies to every
section above (Executive Summary, Canonical Concepts, Relevant Standards,
Tools and Ecosystem, Recommendations). The envelope has five fields:

| Field | Required | Form | Purpose |
| --- | --- | --- | --- |
| `claim_id` | yes | stable identifier (e.g. `C-CLAUDE-001`) | Namespaces claims per contributor; enables cross-referencing in the synthesis |
| `statement` | yes | the claim itself, one sentence | The contributor's contribution in atomic form |
| `source_citation` | yes | repo-relative path with section anchor (e.g. `docs/decisions/ADR-0016.md §"Decision Outcome" item 5`) | Ties every claim to a verifiable input source |
| `contributor_position` | yes | one of `affirm` / `disagree` / `silent` / `out-of-scope` | Records the contributor's stance; the synthesis uses this to preserve divergence |
| `confidence` | yes | `high` / `medium` / `low` | The contributor's self-rated confidence; used to weight dispositions |

### How the envelope appears in a Research Brief

**In table sections** (Canonical Concepts, Relevant Standards, Tools and
Ecosystem): the envelope fields appear as table columns.

Example (Canonical Concepts):

|| claim_id | Concept | Definition | Why it matters | Source | Position | Confidence |
|| --- | --- | --- | --- | --- | --- | --- |
|| C-CLAUDE-001 | Supporting-roles gap | `contributor_role` field conflates primary and contributor role assignments | Round-1 reviewer finding; needs structural fix | `templates/contributor/contributor-prompt.md §"Parameters"` | disagree | high |
|| C-CLAUDE-002 | FS-0015 not in input_sources | The pilot's parameter file does not include FS-0015 as an input source | Q1 verdict is internally consistent but not verifiable against source | `docs/orchestration/multi-model-pilot-001.yaml §"input_sources"` | disagree | high |

**In prose sections** (Executive Summary, Recommendations): the envelope
fields appear as inline tags or footnote-style annotations.

Example (Executive Summary):

> I disagree with the synthesis's framing of `attribution_label` validation
> (C-CLAUDE-003; disagree; medium). The current implementation validates
> the field but does not render it into the transparency statement...

### Why the envelope is mandatory

Without the envelope, the synthesis can't mechanically extract claims
from prose and can't preserve divergence without flattening. The
synthesis template (`templates/contributor/synthesis-template.md`) §"1.
Coverage/Disposition Record" consumes the envelope directly. A Research
Brief without envelope fields on every claim requires the synthesis
operator to re-derive envelope values from prose, which loses confidence
and position fidelity.

The synthesis's gate evaluator verifies that every claim referenced in
the synthesis's Disposition Record has an envelope field set. Claims
without envelopes are flagged as attribution-fidelity gaps.

## Disagreement handling

If the contributor's reading disagrees with the task framing, with
the artifact under review, or with another contributor's output (the
contributor will not see other outputs, but may anticipate them):

1. Surface the disagreement explicitly in the Executive Summary.
2. Document the contributor's position with citations in Canonical Concepts.
3. Do not soften or hedge. The primary session synthesizes disagreements;
   the contributor's job is to be clear about their position, not to
   pre-resolve it.

## Citation format

Repo-relative paths with section anchors. Examples:

- `docs/decisions/ADR-0016.md §"Decision Outcome" item 5`
- `templates/contributor/contributor-prompt.md §"Parameters" field 3`
- `scripts/render_contributor_prompt.py:_render_contract_block:354`

External citations (web, papers) use full URLs with the URL on its own
line below the claim.

## Length and depth

A Research Brief is not a long document. Aim for:

- 800-2000 words total.
- 5-10 rows per table.
- 3-7 recommendations.

If the brief exceeds 3000 words, the contributor is probably writing
the synthesis instead of the brief. The synthesis is the operator's
job (per ADR-0016); the brief is the contributor's contribution.

## Validation

The primary session's first check on a Research Brief is whether it
contains all five sections in order with the right table columns.
Missing sections, missing columns, or a "Recommendations" section
full of hedges is grounds for re-running the contributor with more
specific framing.

The gate evaluator's check is whether the brief's claims are
attributed and whether disagreements are preserved. The gate does not
judge whether the brief's recommendations are correct — that is the
operator's call.