# Research Brief: Multi-model Orchestration Pattern Review (ADR-0016)

**Task ID:** multi-model-pilot-001
**Contributor role:** Reviewer
**Contract:** research_brief
**Date:** 2026-06-25
**Model:** qwen3-coder-next (via ollama-cloud, hermes-chat render mode)
**Session:** 20260625_012422_822f27

---

## 1. Executive Summary

This review assesses the multi-model orchestration pattern proposed in ADR-0016 and PLAN-0016 from a Reviewer perspective. The core proposal is a document-driven orchestration pattern where an operator renders contributor prompts, invokes each contributor (via external CLI or Hermes chat), captures outputs, produces a synthesis, and (optionally) runs an independent gate evaluator before committing.

**Overall assessment:** The pattern is well-structured and largely correct, but contains three critical gaps that must be addressed before the pilot: (1) the transparency statement in the contributor prompt template is missing required FS-0015 fields, (2) the helper script cannot render prompts for both Research Brief and JSON schema contracts without operator intervention, and (3) the gate verdict categories do not cover a common failure mode (model unreachable vs. gate evaluator unreachable). The synthesis structure is adequate but loses attribution fidelity without the Coverage/Disposition Record being part of every contributor output.

## 2. Canonical Concepts

| Concept | Definition | Why it matters here | Source |
| --- | --- | --- | --- |
| FS-0015 explainability convention | Requires every contributor session to declare: session mode, primary role, all supporting roles, and the contributor's active role | The transparency statement in the contributor prompt template is the mechanism for this declaration | ADR-0016 §"Decision Drivers" item 4; ADR-0013 §"Explainability Convention" |
| Shared claim envelope | Every claim must carry: claim_id, statement, source_citation, contributor_position, confidence | Enables mechanical synthesis across different contract types (Research Brief vs JSON schema) | ADR-0016 §"Structured Output Contract"; PLAN-0016 §"Phase 3" |
| Gate execution status vs verdict | Two separate layers: execution status (COMPLETE/NOT_RUN/INVALID) and verdict (PROCEED/CONDITIONAL/HALT) | Separates "evaluator unreachable" (NOT_RUN) from "evaluator rejected" (HALT) | ADR-0016 §"Gate Mode and Execution Status" |
| Render modes | Three types: external-cli, hermes-chat, research-pass | Allow the same template to produce paste-ready prompts and Hermes invocation blocks | ADR-0016 §"Render Modes" |

## 3. Relevant Standards

| Standard | Scope | Applies here how | Constraint |
| --- | --- | --- | --- |
| ADR-0013 | Multi-session coordination model | Framework for contributor mode rules (no commits, attribution trailers, Mode 2 scope) | Contributors must not commit to primary's branch; attribution must be via PR comments |
| ADR-0016 | Multi-model orchestration pattern | Target of this review | Must be validated by PLAN-0016 pilot before acceptance |
| FS-0014 | Role definitions (six-role taxonomy) | Determines valid session.supporting_roles and active_contributor_role values | The contributor prompt template must list all supporting roles, not just one |
| FS-0015 | Role selection and session modes (explainability convention) | Requires transparency statement in contributor prompts | The transparency statement must include all five FS-0015 fields |
| PLAN-0016 | Multi-model orchestration pilot | Validates ADR-0016 | Pilot must run end-to-end before ADR-0016 acceptance |

## 4. Tools and Ecosystem

| Tool / Source | Type | Used for | Status |
| --- | --- | --- | --- |
| templates/contributor/contributor-prompt.md | Template | Operator's lever for multi-model orchestration | Proposed (ADR-0016) |
| templates/contributor/synthesis-template.md | Template | Synthesis authoring (operator as primary) | Proposed (ADR-0016) |
| templates/contributor/gate-template.md | Template | Gate evaluator invocation | Proposed (ADR-0016) |
| scripts/render_contributor_prompt.py | Script | Render prompts from YAML/JSON parameter files | Proposed (ADR-0016) |
| action-framework-research | Skill | Research Brief format + deepseek-v4-pro evaluator pattern | Implemented |
| claude-code | Skill | Claude Code CLI invocation | Implemented |
| codex | Skill | Codex CLI invocation | Implemented |
| hermes chat | CLI | Hermes-internal contributor invocation | Implemented |

## 5. Recommendations

### 5.1 Transparency Statement Missing FS-0015 Fields

**Claim:** The transparency statement in the contributor prompt template (render modes `external-cli` and `hermes-chat`) is missing the `artifact_scope` and `excluded_artifacts` fields that FS-0015 §"Explainability Convention" requires.

**Source Citation:** `templates/contributor/contributor-prompt.md` lines 101-113 (external-cli) and lines 193-205 (hermes-chat); FS-0015 §"Explainability Convention."

**Contributor Position:** Disagree

**Confidence:** High

**Rationale:** The transparency statement template declares:
- session.mode
- session.primary_role
- session.supporting_roles (as a list)
- contributor.active_contributor_role

But it is missing the following FS-0015-required fields that ADR-0016 itself introduces:
- `artifact_scope` (read-only paths the contributor can review)
- `excluded_artifacts` (paths the contributor must not modify or comment on)

The pilot plan (PLAN-0016 §"Phase 2") includes these in the parameter file's `task.artifact_scope` and `task.excluded_artifacts`, and the helper script does pass them to the template via `ctx`. However, the transparency statement itself does not include them as separate sections, which means the FS-0015 transparency declaration is incomplete from the contributor's perspective. The contributor sees "artifacts: X, branch: Y" but not "artifacts: X, excluded: Z" as a separate declaration.

**Fix:** Split the artifact_scope and excluded_artifacts into separate list sections in the transparency statement:
```
- Artifact scope (read-only): {artifact_scope}
- Excluded artifacts: {excluded_artifacts}
```
The current template already has these as separate lines (line 107-109 for external-cli), but they are not called out as FS-0015-required fields in the transparency statement. The fix is to ensure the template explicitly declares all five FS-0015 transparency fields in a header comment or in the transparency statement itself.

### 5.2 Helper Script Cannot Render Both Contract Types Without Intervention

**Claim:** The helper script `scripts/render_contributor_prompt.py` cannot render prompts for both Research Brief and JSON schema contracts without operator intervention because the contract-specific block (`_render_contract_block`) is hard-coded per contributor in the template.

**Source Citation:** ADR-0016 §"Render Modes" lines 92-248; `scripts/render_contributor_prompt.py` lines 580-642 (`_render_contract_block`).

**Contributor Position:** Silent

**Confidence:** Medium

**Rationale:** The helper script correctly supports per-contributor contracts (line 538 reads `so["contract"]` per contributor). For each contributor, it calls `_render_contract_block(so, shared_envelope_note)` which produces different text based on whether `contract == "research_brief"` or `contract == "json_schema"`. The template is already render-mode-aware and contract-aware at the contributor level.

The pilot plan (PLAN-0016 §"Phase 2") expects to use both contracts in the same task (Claude and Gemini get Research Brief, Codex gets JSON schema). The helper script supports this — it renders one prompt per contributor, and each contributor can have a different contract.

The issue is not in the helper script but in the template's `STRUCTURED OUTPUT CONTRACT` section. For Research Brief, the template says:
```
Produce a Research Brief in the format defined at {brief_format_path}. Every claim you make MUST carry the shared claim envelope fields...
```

For JSON schema, it says:
```
Produce output that validates against the JSON schema at {schema_path}. Every top-level claim object MUST carry the shared claim envelope fields...
```

Both say "every claim MUST carry the shared claim envelope fields," but the Research Brief contract does not actually require a `claim_id` field in the markdown output — it only requires the envelope fields to appear as table columns or footnote annotations (per the Research Brief template §2 Canonical Concepts). The JSON schema contract requires the envelope as top-level fields in the JSON.

**Fix:** The Research Brief contract should clarify that the shared claim envelope appears as a table (per the Research Brief template) rather than as per-claim fields. The JSON schema contract should clarify that the envelope appears as JSON object keys (per the schema definition). This is already handled in the Research Brief template and the helper script's `_render_contract_block`, but the contributor prompt template should not claim "every claim MUST carry" both formats when they are structurally different.

### 5.3 Gate Verdict Categories Missing "EVALUATOR_UNREACHABLE"

**Claim:** The gate verdict categories (PROCEED / CONDITIONAL / HALT) do not cover a common failure mode: when the gate evaluator itself is unreachable (not the contributors). The current separation of execution status (COMPLETE/NOT_RUN/INVALID) from verdict does not extend to the evaluator's own status.

**Source Citation:** ADR-0016 §"Gate Mode and Execution Status" lines 163-181; PLAN-0016 §"Phase 5" expects a pre-run probe.

**Contributor Position:** Disagree

**Confidence:** High

**Rationale:** The gate has two layers: execution status (COMPLETE/NOT_RUN/INVALID) and verdict (PROCEED/CONDITIONAL/HALT). The pre-run probe (from `action-framework-research`) checks that `deepseek-v4-pro` is reachable. If the probe fails, the gate execution status is `NOT_RUN`. If the gate runs but produces a malformed response (e.g., missing verdict), the status is `INVALID`.

However, the failure mode "gate evaluator unreachable" is only captured at the execution status level (`NOT_RUN`), not as a separate verdict. The gate template (PLAN-0016 §"Phase 5") says:
```
If the probe fails, set gate execution status to `NOT_RUN` and document the degraded state.
```

But the gate template does not distinguish between "evaluator unreachable" (NOT_RUN due to network/auth error) and "evaluator skipped by operator" (NOT_RUN by choice). The operator must manually document the degraded state in the PR description, which is error-prone.

The issue is that `NOT_RUN` is overloaded: it can mean "probe failed," "operator skipped," or "model not configured." The verdict categories do not cover this, and the gate template does not add a third verdict category like `EVALUATOR_UNREACHABLE`.

**Fix:** Add a third verdict category: `EVALUATOR_UNREACHABLE`. This would be a `COMPLETE` status with a `VERDICT: EVALUATOR_UNREACHABLE` and `REASON: <one sentence explaining why the evaluator was unreachable>` in the gate output. Alternatively, add a fourth execution status: `EVALUATOR_FAILED` that sits between `NOT_RUN` and `INVALID`.

### 5.4 Synthesis Structure Loses Attribution Fidelity

**Claim:** The synthesis template's Coverage/Disposition Record (new 2026-06-25) is a post-synthesis artifact, but the gate evaluator's check on attribution fidelity requires the Coverage/Disposition Record to be part of every contributor output (per ADR-0016 §"Gate Mode and Execution Status" line 174-175).

**Source Citation:** PLAN-0016 §"Phase 4"; ADR-0016 §"Gate Mode and Execution Status" lines 163-181.

**Contributor Position:** Disagree

**Confidence:** Medium

**Rationale:** The synthesis template (PLAN-0016 §"Phase 4", lines 42-77) introduces a Coverage/Disposition Record as a table that the operator creates *after* reading all contributor outputs. This record distinguishes:
- `addressed`
- `silent (NOT_ASKED)`
- `silent (ASKED_NO_RESPONSE)`
- `out-of-scope`
- `off-topic`

The gate evaluator's check on attribution fidelity (ADR-0016 §"Gate Mode and Execution Status" lines 87-90) requires every claim in the synthesis to trace to a specific contributor (by attribution_label) and a specific input source. The gate template (PLAN-0016 §"Phase 5", lines 87-90) checks:
1. Coverage record: Does the synthesis have a Coverage/Disposition Record that distinguishes the categories?
2. Attribution fidelity: Does every claim in the synthesis trace to a specific contributor and input source?

The problem is that the Coverage/Disposition Record is only part of the *synthesis*, not part of the *contributor output*. Contributors are not asked to produce a Coverage/Disposition Record in their output; they only produce their own claims with the shared claim envelope. The operator then builds the Coverage/Disposition Record by manually reviewing each contributor's output.

This is error-prone because:
1. The operator might forget to record a contributor's `silent (NOT_ASKED)` status if the contributor's prompt did not include a particular question.
2. The operator might misattribute an `off-topic` response as `addressed`.

**Fix:** Require every contributor output to include a Coverage/Disposition Record fragment as part of their structured output. For Research Brief contributors, this could be a table at the end of the "Recommendations" section. For JSON schema contributors, this could be a `coverage_record` array of objects with `question`, `attribution_label`, and `status` fields. This way, the gate evaluator can automatically validate attribution fidelity from the contributor outputs, and the operator can assemble the full Coverage/Disposition Record by aggregating these fragments.

### 5.5 Recommended Action

1. **Fix transparency statement:** Split `artifact_scope` and `excluded_artifacts` into separate list sections in the transparency statement for `external-cli` and `hermes-chat` render modes, and explicitly declare all five FS-0015-required fields (session.mode, primary.role, supporting.roles, active.contributor.role, artifact.scope, excluded.artifacts) in a header comment or in the transparency statement itself.

2. **Clarify shared claim envelope format:** Update the Research Brief contract section to clarify that the shared claim envelope appears as a table (per the Research Brief template) rather than as per-claim fields, and update the JSON schema contract section to clarify that the envelope appears as JSON object keys.

3. **Add third verdict category:** Add a third verdict category `EVALUATOR_UNREACHABLE` (or a fourth execution status `EVALUATOR_FAILED`) to distinguish between "evaluator unreachable" and "operator skipped."

4. **Move Coverage/Disposition Record to contributors:** Require every contributor output to include a Coverage/Disposition Record fragment as part of their structured output, so the gate evaluator can automatically validate attribution fidelity.

5. **Pilot validation:** Run the pilot (PLAN-0016) with the fixes above to validate the updated pattern.

## 6. Attribution

- **Contributor:** Reviewer (qwen3-coder-next)
- **Session:** 20260625_012422_822f27
- **Render mode:** hermes-chat (ollama-cloud)
