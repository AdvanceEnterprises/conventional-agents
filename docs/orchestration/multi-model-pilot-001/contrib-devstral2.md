# Research Brief: Multi-Model Orchestration Pattern Review

**Task ID:** multi-model-pilot-001
**Contributor role:** Implementer
**Contract:** research_brief
**Date:** 2026-06-25
**Model:** devstral-2:123b (via ollama-cloud, hermes-chat render mode)
**Session:** 20260625_012550_0af045

---

## Executive Summary

This Research Brief reviews the proposed multi-model orchestration pattern defined in ADR-0016, PLAN-0016, and the associated contributor templates and helper script. The review is conducted from the Implementer role perspective, focusing on the operational feasibility, clarity, and completeness of the proposed pattern.

The multi-model orchestration pattern introduces a structured approach to coordinating multiple AI models (contributors) under a primary session, ensuring reproducibility, attribution, and quality control. The pattern is designed to be operator-driven, supporting both external CLI and Hermes-internal invocation modes, and includes mechanisms for structured output, synthesis, and gate evaluation.

The review identifies several strengths in the proposed pattern, including its adherence to ADR-0013 and FS-0015 conventions, its support for multiple render modes, and its clear separation of concerns between contributors, synthesis, and gate evaluation. However, it also surfaces areas where the pattern could be improved, particularly in the clarity of the transparency statement, the handling of mixed contract types, and the coverage of failure modes in the gate verdict categories.

The review concludes that the pattern is fundamentally sound and ready for pilot validation, with minor refinements recommended to address the identified gaps.

## Canonical Concepts

| Concept | Definition (1 sentence) | Why it matters here | Source |
| --- | --- | --- | --- |
| Multi-model orchestration | Coordinating multiple AI models as contributors under a primary session to produce structured, comparable outputs | Ensures reproducibility and auditable consensus across models | ADR-0016 §"Context and Problem Statement" |
| Structured output contract | A predefined format (Research Brief or JSON schema) that contributors must follow, including shared claim envelope fields | Enables mechanical synthesis and traceability of claims | ADR-0016 §"Structured Output Contract" |
| Render modes | Different invocation transports for contributors (external-cli, hermes-chat, research-pass) | Supports both external CLI and Hermes-internal contributors under consistent rules | ADR-0016 §"Render Modes" |
| Gate evaluation | Independent assessment of the synthesis by a model not involved in the contributor set | Prevents the primary from "grading its own work" and ensures constraint compliance | ADR-0016 §"Gate Mode and Execution Status" |
| Coverage/Disposition Record | A table tracking which contributors addressed which questions and how their claims were handled | Prevents silent averaging and ensures attribution fidelity | synthesis-template.md §"Coverage/Disposition Record" |
| Shared claim envelope | A set of fields (claim_id, statement, source_citation, contributor_position, confidence) that must accompany every claim | Ensures traceability and comparability across contributors | ADR-0016 §"Structured Output Contract" |

## Relevant Standards

| Standard | Scope | Applies here how | Constraint |
| --- | --- | --- | --- |
| ADR-0013 | Multi-session coordination model | Yes — defines primary/contributor rules, attribution trailers, and escalation rules | Contributors must not commit to the primary's branch; outputs must be posted as PR comments |
| FS-0014 | Role definitions overhaul | Yes — defines the six-role taxonomy used in the contributor prompt template | Roles must be declared per FS-0014 enumeration; active_contributor_role must be validated |
| FS-0015 | Role selection and session modes | Yes — defines the explainability convention and five session modes | Transparency statement must declare session mode, primary role, and all supporting roles |
| ADR-0016 | Multi-model session orchestration | Yes — this is the ADR being reviewed | All components must comply with the pattern defined in ADR-0016 |

## Tools and Ecosystem

| Tool / Source | Type | Used for | Status |
| --- | --- | --- | --- |
| `templates/contributor/contributor-prompt.md` | Template | Defining the contributor prompt structure and render modes | Present |
| `templates/contributor/synthesis-template.md` | Template | Guiding the operator in producing the synthesis document | Present |
| `templates/contributor/gate-template.md` | Template | Defining the gate evaluator's prompt and verdict structure | Present |
| `scripts/render_contributor_prompt.py` | Script | Rendering contributor prompts from a YAML/JSON parameter file | Present |
| `references/research-brief-template.md` | Reference | Defining the canonical Research Brief format | Present |
| Claude Code CLI | External CLI | Invoking Claude Code as a contributor | Present (assumed) |
| Codex CLI | External CLI | Invoking Codex as a contributor | Present (assumed) |
| Hermes Agent | Internal | Invoking Hermes-managed models as contributors | Present (assumed) |
| `deepseek-v4-pro` | Model | Acting as the independent gate evaluator | Present (assumed) |

## Recommendations

### 1. Clarify the Transparency Statement in the Contributor Prompt Template

**Claim ID:** C-IMPLEMENTER-001
**Statement:** The transparency statement in the contributor prompt template should explicitly declare all supporting roles, not just the active contributor role, to fully comply with FS-0015.
**Source Citation:** FS-0015 §"Explainability Convention", ADR-0016 §"Decision Outcome" item 3
**Contributor Position:** Affirm
**Confidence:** High

The current transparency statement in the contributor prompt template includes a line for `supporting_roles`, which is correct. However, the template should emphasize that this field must list *all* supporting roles for the session, not just the roles relevant to the current contributor. This aligns with FS-0015's requirement to declare all supporting roles and prevents the misinterpretation that only the active contributor role needs to be declared.

**Action:** Update the contributor prompt template to clarify that `supporting_roles` must include all roles declared in the session, not just the roles relevant to the current contributor. This can be done by adding a note in the template's documentation or by including an example in the parameter block.

### 2. Ensure the Helper Script Handles Mixed Contract Types Gracefully

**Claim ID:** C-IMPLEMENTER-002
**Statement:** The helper script `render_contributor_prompt.py` should validate that the synthesis template can reconcile mixed contract types (Research Brief and JSON schema) without operator intervention.
**Source Citation:** ADR-0016 §"Structured Output Contract", PLAN-0016 §"Phase 4 — Synthesis"
**Contributor Position:** Affirm
**Confidence:** Medium

The helper script currently validates that each contributor's structured output contract is either `research_brief` or `json_schema`, and it ensures that the necessary files (e.g., `references/research-brief-template.md` or the JSON schema file) exist. However, it does not explicitly validate that the synthesis template can handle mixed contract types. While the shared claim envelope is designed to address this, the helper script could include a note or warning to the operator when mixed contract types are detected, reminding them to ensure the synthesis template is equipped to handle both formats.

**Action:** Add a validation step in the helper script to detect mixed contract types and emit a warning or informational message to the operator, reminding them to ensure the synthesis template can reconcile both formats via the shared claim envelope.

### 3. Expand Gate Verdict Categories to Cover Additional Failure Modes

**Claim ID:** C-IMPLEMENTER-003
**Statement:** The gate verdict categories (PROCEED / CONDITIONAL / HALT) should be supplemented with additional categories or sub-categories to cover failure modes such as incomplete contributor outputs or synthesis gaps.
**Source Citation:** gate-template.md §"Failure modes", ADR-0016 §"Gate Mode and Execution Status"
**Contributor Position:** Disagree
**Confidence:** Medium

The current gate verdict categories (PROCEED / CONDITIONAL / HALT) provide a clear decision framework. The separation of execution status (COMPLETE / NOT_RUN / INVALID) from the verdict itself already addresses many failure modes. Specifically:

- **COMPLETE / PROCEED** — Synthesis is sound, attribution is preserved, no critical gaps.
- **COMPLETE / CONDITIONAL** — Synthesis has minor issues that can be addressed before proceeding.
- **COMPLETE / HALT** — Synthesis has critical issues that prevent proceeding.
- **NOT_RUN** — Gate evaluator was unreachable or skipped; no verdict issued.
- **INVALID** — Gate evaluator ran but produced malformed output.

This two-layer structure is sufficient. Adding more verdict categories would complicate the framework without addressing real failure modes. The Coverage/Disposition Record and the CONDITIONAL-loop bound (two re-runs then escalate) already handle the "incomplete contributor outputs" and "synthesis gaps" cases.

**Action:** No action required.

### 4. Validate the Synthesis Template's Coverage/Disposition Record

**Claim ID:** C-IMPLEMENTER-004
**Statement:** The synthesis template's Coverage/Disposition Record (added 2026-06-25) effectively prevents information loss by tracking which contributors addressed which questions and how their claims were handled.
**Source Citation:** synthesis-template.md §"Coverage/Disposition Record"
**Contributor Position:** Affirm
**Confidence:** High

The Coverage/Disposition Record is well-designed. The five coverage codes (`addressed` / `silent (NOT_ASKED)` / `silent (ASKED_NO_RESPONSE)` / `out-of-scope` / `off-topic`) provide adequate granularity, and the five disposition codes (`incorporate` / `reject` / `defer` / `duplicate` / `out-of-scope`) cover the lifecycle of a claim from initial observation through synthesis integration.

**Action:** No action required. The record works as designed.

### 5. Clarify Gate Overlap Validation in the Contributor Prompt Template

**Claim ID:** C-IMPLEMENTER-005
**Statement:** The gate overlap validation (gate.model must not appear in contributors[].model) is a valuable safety check, but it should be documented more prominently in the contributor prompt template and the synthesis template.
**Source Citation:** ADR-0016 §"Decision Outcome", scripts/render_contributor_prompt.py lines 462-478
**Contributor Position:** Affirm
**Confidence:** Medium

The gate overlap validation is implemented in the helper script but is not surfaced in the contributor prompt template or the synthesis template. Operators may not be aware of this constraint until they encounter the validation error at render time. Better to document it upfront so operators plan their contributor set and gate model accordingly.

**Action:** Add a brief mention of the gate overlap constraint to the contributor prompt template's Parameters block (e.g., a note under the `gate:` field) and to the synthesis template's gate-verdict description.

### 6. Ensure Consistent References to the Research Brief Template

**Claim ID:** C-IMPLEMENTER-006
**Statement:** All references to the Research Brief format should consistently point to `references/research-brief-template.md` as the canonical format, with any deviations explicitly justified in the synthesis.
**Source Citation:** references/research-brief-template.md, templates/contributor/contributor-prompt.md
**Contributor Position:** Affirm
**Confidence:** High

The Research Brief template at `references/research-brief-template.md` is the canonical format. The contributor prompt template references it correctly via `brief_format_path`, and the synthesis template uses a similar structure. However, the synthesis template's "Consensus / Divergent / Unique Insights / Recommended Action" structure differs from the Research Brief's "Executive Summary / Canonical Concepts / Relevant Standards / Tools / Recommendations" structure. This is intentional (different purposes), but operators should be aware that the two formats are not interchangeable.

**Action:** Add a note to the synthesis template clarifying that the synthesis structure differs from the Research Brief structure by design, and that any deviation from either format should be justified in the synthesis's Recommended Action section.

## Conclusion

The pattern is ready for pilot validation as described in PLAN-0016. The recommended refinements are minor and can be incorporated based on the pilot's findings. The Research Brief adheres to the structured output contract and includes the shared claim envelope fields for all claims.

## Attribution

- **Contributor:** Implementer (devstral-2:123b)
- **Session:** 20260625_012550_0af045
- **Render mode:** hermes-chat (ollama-cloud)