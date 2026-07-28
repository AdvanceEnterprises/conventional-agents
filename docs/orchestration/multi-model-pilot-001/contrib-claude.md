# Research Brief: Multi-Model Orchestration Pattern Review (round 2)

**Task ID:** multi-model-pilot-001
**Contributor role:** Reviewer (supporting; primary role Head Architect)
**Contract:** research_brief
**Date:** 2026-06-25
**Model:** claude-sonnet-4 (external-cli render mode)
**Round:** 2 — review of the 2026-06-25 revision that absorbed PR #62 findings

> **Claim envelope convention for this brief.** Per ADR-0016 §"Structured Output Contract,"
> every claim carries the five envelope fields. They appear as columns in the Canonical
> Concepts table (the primary claim register) and inline as `(claim_id; position; confidence)`
> for claims made in prose. `position` ∈ {affirm, disagree, silent, out-of-scope};
> `confidence` ∈ {high, medium, low}.

---

## 1. Executive Summary

This is a second-round review. The 2026-06-25 revision of ADR-0016 explicitly absorbed my PR #62 findings (ADR-0016 §"Status," line 41), and on inspection it did so faithfully: the zombie `attribution_label`, the FS-0015 supporting-roles gap, the gate execution-status gap, the synthesis silence-semantics gap, and the JSON-schema validation gap are all addressed. Notably, the gate fix is *better* than what I originally proposed — I asked for an `INCOMPLETE` fourth verdict, and the authors instead separated execution status (`COMPLETE`/`NOT_RUN`/`INVALID`) from verdict (`PROCEED`/`CONDITIONAL`/`HALT`), which is more orthogonal (C-CLAUDE-006; affirm; high). I record that I was overruled on the mechanism and that the outcome is superior. This brief therefore does not re-litigate resolved findings; it focuses on residual gaps and **new** issues introduced by the revision itself.

**Explicit disagreement with the task framing (item 1).** The task asks whether the transparency statement is "missing fields the framework requires." I cannot fully answer that: FS-0015 — the document that *defines* the explainability convention — is not in my `artifact_scope` or `input_sources`. I can only verify internal consistency between ADR-0016's description of FS-0015 and the templates, not conformance to FS-0015 itself (C-CLAUDE-002; disagree; high). Against the ADR's own restatement of the convention (mode + primary role + all supporting roles, ADR-0016 line 230), the transparency statement is complete. Treat my Q1 verdict as "internally consistent," not "verified against source."

**The strongest new finding is information loss at the synthesis layer (Q4).** The shared claim envelope mandates a `confidence` field on every contributor claim (ADR-0016 §"Structured Output Contract," line 159), but no synthesis section — not the Coverage Record, the Disposition Record, Consensus, Divergent Points, nor Unique Insights — has any slot to carry confidence forward (C-CLAUDE-009; disagree; high). Confidence is collected at the contributor layer and silently dropped at synthesis. If the pilot later asks "was this consensus high-confidence or did everyone hedge?", that signal is unrecoverable. This directly answers the task's Q4: yes, the Coverage/Disposition Record plus the four sections lose information the pilot needs to recover later — specifically, confidence.

**The strongest new contributor-layer finding is a documentation desync (Q2).** The canonical `references/research-brief-template.md` declares itself authoritative (lines 3–7) but says nothing about the claim envelope; its Canonical Concepts columns are `Concept | Definition | Why it matters here | Source` (line 51), with no envelope fields. Meanwhile the rendered prompt and ADR-0016 require the envelope. A contributor reconciling two "authoritative" sources has genuine ambiguity about where envelope fields belong in a Research Brief (C-CLAUDE-005; disagree; high). The ADR resolves this in prose (line 161: "table columns or footnote-style annotations") but the canonical template — the file the contributor is actually pointed at — does not echo it.

Overall: the pattern is materially stronger than the round-1 artifacts and is close to pilot-ready. Two findings (confidence-drop, envelope desync) should be fixed before the pilot produces its synthesis; the rest are follow-ups.

## 2. Canonical Concepts

Primary claim register. Every row is an envelope-complete claim.

| Claim ID | Concept / Statement | Source citation | Position | Confidence |
| --- | --- | --- | --- | --- |
| C-CLAUDE-001 | Supporting-roles gap is resolved: the transparency statement now declares all supporting roles **and** the active contributor role. | `templates/contributor/contributor-prompt.md` lines 105–106; `scripts/render_contributor_prompt.py:_EXTERNAL_CLI` lines 384–385 | affirm | high |
| C-CLAUDE-002 | FS-0015 is not in the provided sources, so "missing fields the framework requires" is verifiable only as internal consistency, not conformance. | task `input_sources`; `docs/decisions/ADR-0016.md` §"Decision Drivers" line 68 | disagree | high |
| C-CLAUDE-003 | `attribution_label` is no longer a zombie (drives file naming, gate refs, synthesis citation) but is still absent from the contributor's own transparency statement, so a posted PR comment is not self-identifying. | `scripts/render_contributor_prompt.py:_validate` line 811; `templates/contributor/gate-template.md` line 68; `_EXTERNAL_CLI` lines 380–392 | affirm | medium |
| C-CLAUDE-004 | Contract is now per-contributor; the script renders research_brief, json_schema, and mixed contributor sets mechanically — the round-1 mixed-contract gap is closed. | `scripts/render_contributor_prompt.py:render_contributor` lines 528–577; `contributor-prompt.md` §"Parameters" lines 66–69 | affirm | high |
| C-CLAUDE-005 | `references/research-brief-template.md` (self-described authoritative) omits the claim envelope that ADR-0016 and the rendered prompt require, creating contributor ambiguity. | `references/research-brief-template.md` lines 3–7, 51; `docs/decisions/ADR-0016.md` line 161 | disagree | high |
| C-CLAUDE-006 | The two-layer gate (execution status vs verdict) covers more failure modes than my PR #62 `INCOMPLETE`-verdict proposal and is the better design. | `templates/contributor/gate-template.md` lines 104–143; `docs/decisions/ADR-0016.md` §"Gate Mode and Execution Status" lines 174–177 | affirm | high |
| C-CLAUDE-007 | No explicit gate instruction for "gate ran but a contributor output it was told to read is missing" — the degraded-contributor case PLAN-0016 permits. | `templates/contributor/gate-template.md` lines 67–68; `docs/change-plans/PLAN-0016-multi-model-pilot.md` §"degraded-but-acceptable" | disagree | medium |
| C-CLAUDE-008 | `NOT_RUN` is listed in the gate **model's** reply menu, but on probe failure the model never runs — `NOT_RUN` is operator-assigned, conflating who emits which status. | `templates/contributor/gate-template.md` lines 48, 109–110, 151 | disagree | medium |
| C-CLAUDE-009 | `confidence` is mandated in the envelope but has no slot in any synthesis section — collected then dropped, unrecoverable later. | `docs/decisions/ADR-0016.md` line 159; `templates/contributor/synthesis-template.md` §§1–4 lines 42–110 | disagree | high |
| C-CLAUDE-010 | The envelope `contributor_position` vocabulary {affirm, disagree, silent, out-of-scope} and the Coverage-Record codes {addressed, silent(NOT_ASKED), silent(ASKED_NO_RESPONSE), out-of-scope, off-topic} don't map cleanly; affirm/disagree both flatten to "addressed." | `docs/decisions/ADR-0016.md` line 158; `templates/contributor/synthesis-template.md` lines 52–58 | disagree | medium |
| C-CLAUDE-011 | `_parse_top_level_key` (lines 317–333) is dead code after the YAML parser was refactored to inline top-level handling (lines 177–201). | `scripts/render_contributor_prompt.py` lines 177–201, 317–333 | affirm | high |
| C-CLAUDE-012 | ADR-0016 says "four mandatory sections … plus a coverage/disposition record" while the synthesis template says "five mandatory sections" — a numbering inconsistency. | `docs/decisions/ADR-0016.md` line 129; `templates/contributor/synthesis-template.md` lines 32–38 | affirm | medium |

## 3. Relevant Standards

| Standard | Scope | Applies here how | Constraint |
| --- | --- | --- | --- |
| ADR-0013 | Multi-session coordination | Contributor operates under Mode 2; output is a PR comment | Cannot commit to primary's branch, open PRs, or transition governed status |
| FS-0014 | Six-role taxonomy | Constrains `active_contributor_role` and `supporting_roles`; script validates against `VALID_ROLES` | Roles must be from the six; script enforces (`_validate` lines 796–801, 839–844) |
| FS-0015 | Session modes + explainability | Defines the transparency convention — **but not provided as a source** | Per ADR restatement: declare mode + primary role + all supporting roles (unverifiable here; C-CLAUDE-002) |
| ADR-0016 | This pattern | The artifact under review; proposed, pending pilot | Self-imposes envelope, render-mode, gate-independence, coverage-record rules |
| references/research-brief-template.md | Output contract for research_brief | The format this very brief must follow | Five named sections in order; **silent on the envelope** (C-CLAUDE-005) |

No accepted ADR is in conflict (ADR-0013 and ADR-0016 are both `proposed`), so escalation trigger 1 does not fire.

## 4. Tools and Ecosystem

| Tool / Source | Type | Used for | Status |
| --- | --- | --- | --- |
| `scripts/render_contributor_prompt.py` | script | Renders per-contributor prompts; validates roles, modes, contracts, gate-overlap; checks schema/brief files exist | present — robust, but carries dead code (C-CLAUDE-011) |
| `templates/contributor/contributor-prompt.md` | template | Parameter schema + three render-mode prompt shapes | present — points contributors at a canonical template that omits the envelope (C-CLAUDE-005) |
| `templates/contributor/synthesis-template.md` | template | Operator synthesis incl. Coverage/Disposition Record | present — no confidence slot (C-CLAUDE-009); vocabulary mismatch with envelope (C-CLAUDE-010) |
| `templates/contributor/gate-template.md` | template | Two-layer gate (status + verdict), bounded CONDITIONAL loop | present — missing-input behavior unspecified (C-CLAUDE-007); NOT_RUN attribution unclear (C-CLAUDE-008) |
| `references/research-brief-template.md` | reference | Canonical Research Brief format | present — needs an envelope section to match ADR-0016 |
| Gate-overlap static check | script feature | Forbids `gate.model` ∈ contributors; `--allow-gate-overlap` override | present — exact-string match on model name, runs only when `gate.enabled` (C-CLAUDE-013; disagree; low) |
| `hermes chat` / `deepseek-v4-pro` | external | hermes-chat render transport + independent gate evaluator | proposed — reachability is a runtime pre-run probe, not verifiable statically |

## 5. Recommendations

1. **Add a claim-envelope section to `references/research-brief-template.md`** (owner: Document Author / operator; **required for pilot**). The canonical template must state that every claim carries `claim_id, statement, source_citation, contributor_position, confidence`, and show where they go (envelope columns on Canonical Concepts, inline tags in prose). Two authoritative sources that disagree on the contract is a defect, not a style choice (C-CLAUDE-005).

2. **Give `confidence` a home in the synthesis, or stop collecting it** (owner: operator/primary; **required for pilot**). Either add a `confidence` column to the Disposition Record and a confidence note to Consensus/Divergent entries, or remove `confidence` from the envelope. Mandating a field at the contributor layer and discarding it at synthesis is the kind of silent information loss the framework exists to prevent (C-CLAUDE-009).

3. **Specify gate behavior when a contributor output is missing** (owner: primary; **required for pilot**, since PLAN-0016 permits degraded runs). State explicitly whether a missing `contrib-<label>` file is a `COMPLETE` verdict with a flagged coverage gap, or grounds for `INVALID`. Without this, a degraded pilot run hits undefined gate behavior (C-CLAUDE-007).

4. **Document the `contributor_position` → Coverage-code mapping, or unify the two vocabularies** (owner: primary; follow-up acceptable). As written, affirm vs disagree both become "addressed" in the Coverage Record, so §1 alone can't tell affirmation from dissent without cross-referencing the body (C-CLAUDE-010).

5. **Clarify that `NOT_RUN` is operator-assigned and remove it from the model's reply menu** (owner: primary; follow-up). The gate model should emit only `COMPLETE` or `INVALID`; the operator writes `NOT_RUN` when the probe fails and the model never runs (C-CLAUDE-008).

6. **Remove the dead `_parse_top_level_key` function** (owner: tool maintainer; follow-up). It is unreachable after the parser refactor and will mislead the next reader (C-CLAUDE-011).

7. **Embed `attribution_label` in the transparency statement** (owner: primary; follow-up). One line — `- My attribution label: {attribution_label}` — makes each contributor's PR comment self-identifying even when separated from its filename (C-CLAUDE-003). Also reconcile the "four sections plus a record" vs "five sections" wording between ADR-0016 and the synthesis template (C-CLAUDE-012).
