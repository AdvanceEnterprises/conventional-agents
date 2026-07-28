# Gate Evaluation: multi-model-pilot-001

**Task ID:** multi-model-pilot-001
**Gate evaluator:** deepseek-v4-pro (independent — not in contributor set)
**Date:** 2026-06-25
**Session:** 20260625_020224_fbd12d (probe); gate evaluation in same session

---

## Evaluation

### Axis 1: Coverage Record

The synthesis has a Coverage table (§1, lines 38–43) and a Disposition Record (§1, lines 47–102). The coverage table correctly shows all four contributors addressed all four framing questions. However, the coverage table uses only the `addressed` code — it does not exercise the full vocabulary (`silent (NOT_ASKED)`, `silent (ASKED_NO_RESPONSE)`, `out-of-scope`, `off-topic`) that the synthesis template requires. The synthesis does note two qualifications on completeness in prose (lines 33–34: Q1 unverifiable against FS-0015 source, Q3 residual divergence), but these are not reflected in the coverage table's codes. The Disposition Record uses disposition codes (`incorporate`, `reject`, `defer`, etc.) rather than coverage codes, which is correct for its purpose — but the coverage table itself is flattened.

**Finding:** Minor gap. The coverage table should use the full code vocabulary even when all entries happen to be `addressed`, to prove the operator considered each category. The prose qualifications should map to coverage-table annotations.

### Axis 2: Attribution Fidelity

Every claim in the Disposition Record traces to a specific contributor by `attribution_label` (e.g., `claude-contrib-1`, `codex-contrib-1`). The Consensus, Divergent Points, and Unique Insights sections all cite specific claim IDs. The mapping from body claims to Disposition Record entries is consistent on spot-check.

Two concerns:

1. **Envelope fields dropped.** The Disposition Record does not preserve `source_citation`, `contributor_position`, or `confidence` from the shared claim envelope. The synthesis itself identifies this (D2, lines 132–142) and recommends fixing it. This is a self-acknowledged attribution fidelity gap — the gate cannot verify that the synthesis's disposition of a claim is consistent with the contributor's stated position and confidence without cross-referencing the raw contributor outputs.

2. **Synthesis authorship.** The synthesis states it was "drafted by minimax-m3 as a sounding-board pass" and "reviewed by: operator-as-primary (Tai) pending" (line 4). The gate template defines the synthesis as "what the operator produced." If the operator's review is still pending, the synthesis is currently a model output, not an operator artifact. This is a process concern rather than a structural defect, but it affects whether the synthesis can be treated as the operator's own work product.

**Finding:** The claim-to-contributor tracing is structurally sound. The envelope-field drop is a known defect (self-identified). The synthesis authorship status (model-drafted, operator-review pending) is a process gap.

### Axis 3: Divergence Preservation

This is the strongest axis. The synthesis has a dedicated Divergent Points section (§3, lines 118–153) with three well-structured divergences (D1, D2, D3). Each divergence:

- Lists every contributor's position with `attribution_label`, stance (`affirm`/`disagree`), and confidence
- Includes the operator's read with explicit reasoning for the chosen direction
- Preserves minority positions (Qwen3's `EVALUATOR_FAILED` proposal, Devstral's sufficiency claim) even when rejecting them

Two claims are explicitly rejected (C-QWEN-003, C-QWEN-004) with stated reasons. No silent averaging detected. Claude's meta-observation about being "overruled with a superior outcome" (C-CLAUDE-006) is preserved in Consensus C1 and Unique Insights U1 — this is exactly the kind of nuance the framework exists to capture.

**Finding:** No issues. Divergence preservation is exemplary.

### Axis 4: Constraint Compliance

The synthesis includes a constraint check (§5, lines 202–208):

| Constraint | Status | Assessment |
|---|---|---|
| ADR-0013 (proposed) | No conflict | Correct — proposed, not binding |
| FS-0014 (implemented) | Supported | Correct — role-relationship enforcement strengthens conformance |
| FS-0015 (implemented) | Supported | Correct — transparency-statement fixes strengthen conformance |
| ADR-0016 (proposed) | No conflict | Correct — refinements are within stated boundaries |
| PLAN-0016 (proposed) | Requires revision | Correct — identified as stale by C-CODEX-103 |

The synthesis notes (line 230) that the round-2 commit used `Co-Authored-By: Claude Opus 4.8` which conflicts with ADR-0013's `Assisted-By:` convention. Since ADR-0013 is `proposed` (not `accepted`), this is not a constraint violation — but it is a process inconsistency worth flagging. The synthesis mentions it in prose but does not include it as an action item in the Recommended Action's numbered list.

**Finding:** No constraint conflicts with accepted ADRs or approved FSs. The `Co-Authored-By` trailer issue is noted but not actioned — minor omission.

### Axis 5: Synthesis Coherence

The synthesis is internally consistent. The Recommended Action (§5) follows directly from the Consensus, Divergent Points, and Unique Insights sections:

- C1 (round-1 defects resolved) → Action item 1 (accept as additive evidence)
- C4 (envelope desync) → Action item 2, bullet 1
- D2 (envelope fields dropped) → Action item 2, bullet 2
- D1 (missing-input handling) → Action item 2, bullet 3
- U6 (role-relationship enforcement) → Action item 2, bullet 4
- D3 (attribution_label rendering) → Action item 2, bullet 5
- U4 (dead code) → Action item 2, bullet 7
- U5 (numbering inconsistency) → Action item 2, bullet 8
- U3 (PLAN-0016 stale) → Action item 2, bullet 9
- U7 (JSON branch unvalidated) → Action item 3, bullet 1

Spot-check of Disposition Record → body mapping confirms consistency (C-CLAUDE-009 → D2, C-CODEX-103 → U3, C-QWEN-003 → D1 with reject disposition, C-DEVSTRAL-004 → D2 with caveat).

One coherence concern: the synthesis's own Recommended Action item 4 (line 200) says "Run the gate evaluator… The expected verdict is CONDITIONAL." The synthesis is pre-judging the gate's verdict, which is the gate's job, not the synthesis's. This is a minor self-reference issue — the synthesis should not predict the gate's verdict.

**Finding:** Internally consistent. The self-prediction of CONDITIONAL verdict is a minor coherence issue.

---

## Execution Status and Verdict

STATUS: COMPLETE
VERDICT: CONDITIONAL
REASON: Synthesis is well-structured, divergence preservation is exemplary, and the Recommended Action follows from the analysis — but three specific issues must be resolved before commit.

ISSUES:
- **Coverage table uses only `addressed` code.** The synthesis template requires distinguishing `silent (NOT_ASKED)`, `silent (ASKED_NO_RESPONSE)`, `out-of-scope`, and `off-topic`. Even when all entries happen to be `addressed`, the table should use the full vocabulary to prove the operator considered each category. The two prose qualifications (Q1 unverifiable, Q3 residual divergence) should map to coverage-table annotations.
- **Disposition Record drops envelope fields (`source_citation`, `contributor_position`, `confidence`).** The synthesis itself identifies this (D2) and recommends fixing it in a follow-up PR. The gate cannot verify attribution fidelity without cross-referencing raw contributor outputs. This is the highest-priority fix — the synthesis should not be committed with known information loss at the disposition layer.
- **Synthesis authorship is model-drafted with operator review pending.** The synthesis header states "reviewed by: operator-as-primary (Tai) pending" (line 4). Per the gate template, the synthesis is "what the operator produced." If the operator has not yet reviewed and claimed the synthesis as their own work product, the gate is evaluating a model draft, not an operator artifact. The operator must complete their review and update the authorship declaration before this synthesis is gate-clear.
