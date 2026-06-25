## 1. Executive Summary

**claim_id:** C-CODEX-101
**statement:** From the Implementer perspective, the revised contributor prompt now expresses the FS-0015 explainability fields correctly—mode, primary role, all supporting roles, and active contributor role—but the helper does not enforce the relationships that make those fields truthful.
**source_citation:** `templates/contributor/contributor-prompt.md` §"Parameters"; §"Render mode: external-cli"; `scripts/render_contributor_prompt.py:_validate`
**contributor_position:** affirm
**confidence:** high

The rendered transparency statement now has the necessary shape, and the helper validates role names against the FS-0014 enumeration. However, `session.supporting_roles` is optional, `active_contributor_role` is optional, and the helper does not require an accountable contributor's active role to appear in the declared supporting-role set. This is an implementation defect because the documented relationship can be violated while pre-flight validation still succeeds. (`templates/contributor/contributor-prompt.md` §"Parameters"; `scripts/render_contributor_prompt.py:_validate`)

**claim_id:** C-CODEX-102
**statement:** The per-contributor parameter model and render-mode dispatch solve the previous mixed-role and mixed-transport plumbing defect, but the current pilot does not demonstrate both structured-output contracts.
**source_citation:** `docs/decisions/ADR-0016.md` §"Decision Outcome" items 1-3; §"Render Modes"; §"Structured Output Contract"; `scripts/render_contributor_prompt.py:render_contributor`; `docs/change-plans/PLAN-0016-multi-model-pilot.md` §"Phase 2 — Contributor prompts"
**contributor_position:** affirm
**confidence:** high

The helper can now render one prompt per contributor, select `external-cli`, `hermes-chat`, or `research-pass`, and apply a contributor-specific contract without operator rewriting. I explicitly disagree, however, with treating implementation of both branches as validation of the Research Brief-versus-JSON requirement: PLAN-0016 says Codex must use a JSON schema and that the schema will be created during Phase 2, but no reviewed input contains that schema or evidence of a validated JSON output. The script's JSON branch exists, but the governed pilot plan has not demonstrated it. (`scripts/render_contributor_prompt.py:_render_contract_block`; `docs/change-plans/PLAN-0016-multi-model-pilot.md` §"Phase 2 — Contributor prompts")

**claim_id:** C-CODEX-103
**statement:** PLAN-0016 is materially stale relative to ADR-0016, the contributor template, and the implemented renderer, so the pilot cannot be evaluated reproducibly from the governed plan as written.
**source_citation:** `docs/change-plans/PLAN-0016-multi-model-pilot.md` §"Roles and session mode"; §"Contributors"; §"Phase 2 — Contributor prompts"; §"Phase 3 — Run contributors"; `docs/decisions/ADR-0016.md` §"Render Modes"; §"Validation" item 2; `templates/contributor/contributor-prompt.md` §"Parameters"
**contributor_position:** disagree
**confidence:** high

The plan still specifies three named contributors, the removed `session.contributor_role` field, task-level contract selection, a Gemini-specific invocation, and a Codex JSON schema that is not present. The revised architecture is model-agnostic, uses a `contributors` list, supports multiple transports, and validates per-contributor contracts. This mismatch is not editorial dust: an operator following PLAN-0016 literally will construct the wrong parameter shape and run a different pilot from the one ADR-0016 now defines.

**claim_id:** C-CODEX-104
**statement:** The gate's two-layer status/verdict model is sufficient; no additional verdict category is needed, but incomplete or unreadable gate inputs need an explicit execution-status rule.
**source_citation:** `templates/contributor/gate-template.md` §"EXECUTION STATUS AND VERDICT"; §"Decision flow"; §"Failure modes"; `docs/decisions/ADR-0016.md` §"Gate Mode and Execution Status"
**contributor_position:** affirm
**confidence:** high

`COMPLETE`, `NOT_RUN`, and `INVALID` cleanly describe execution, while `PROCEED`, `CONDITIONAL`, and `HALT` describe evaluation. Adding another verdict would mix those axes again. The remaining ambiguity is that `INVALID` is described mainly as malformed evaluator output; the gate prompt does not state what status applies when expected contributor files, the synthesis, or the constraint list are missing or unreadable. That case should be classified as `INVALID` before evaluation, not converted into `HALT`.

**claim_id:** C-CODEX-105
**statement:** The Coverage/Disposition Record prevents the earlier silence-collapse failure, but it still loses claim-envelope data and can silently omit claims because its scope is limited to claims that “survive into the synthesis.”
**source_citation:** `templates/contributor/synthesis-template.md` §"1. Coverage/Disposition Record"; `docs/decisions/ADR-0016.md` §"Structured Output Contract"; `templates/contributor/gate-template.md` §"YOUR JOB" items 1-2
**contributor_position:** disagree
**confidence:** high

The coverage codes correctly distinguish not asked, asked without response, out of scope, and off-topic. The disposition table, however, drops `source_citation`, `contributor_position`, and `confidence` from the shared claim envelope, and its instructions cover only unique claims that “survive into the synthesis.” Rejected and out-of-scope claims are precisely the claims that may not survive, yet they must remain recoverable for the gate and later audit. The record also lacks explicit `unavailable` and `invalid-output` coverage codes for the degraded-pilot cases already recognized by PLAN-0016.

## 2. Canonical Concepts

| claim_id | statement | source_citation | contributor_position | confidence | Why it matters |
| --- | --- | --- | --- | --- | --- |
| C-CODEX-106 | Per-contributor parameters are the correct unit for role, transport, attribution, contract, and guardrails. | `templates/contributor/contributor-prompt.md` §"Parameters"; `docs/decisions/ADR-0016.md` §"Decision Outcome" item 1 | affirm | high | They allow one task to contain heterogeneous contributors without manual prompt edits. |
| C-CODEX-107 | Supporting-role declaration is different from active-role assignment. | `templates/contributor/contributor-prompt.md` §"Parameters" notes; §"Render mode: external-cli" | affirm | high | The session declares the complete supporting set; each contributor declares which role it fills. |
| C-CODEX-108 | A valid contributor configuration must require the active role to be a member of the supporting-role set for accountable contributor modes. | `templates/contributor/contributor-prompt.md` §"Parameters" field `active_contributor_role`; `scripts/render_contributor_prompt.py:_validate` | disagree | high | The template states the relationship, but the helper currently validates only role spelling. |
| C-CODEX-109 | Render mode and structured-output contract are orthogonal per-contributor choices. | `docs/decisions/ADR-0016.md` §"Render Modes"; §"Structured Output Contract"; `scripts/render_contributor_prompt.py:render_contributor` | affirm | high | External and Hermes contributors can use either contract without vendor-specific branching. |
| C-CODEX-110 | Basic JSON-schema inspection is not full schema validation. | `scripts/render_contributor_prompt.py:_render_contract_block` JSON branch | disagree | high | Accepting any JSON object with `type`, `$schema`, or `properties` does not prove schema validity or claim-envelope enforcement. |
| C-CODEX-111 | Gate execution status and gate verdict are separate state dimensions. | `templates/contributor/gate-template.md` §"EXECUTION STATUS AND VERDICT" | affirm | high | Reachability and format failures should not be represented as policy judgments. |
| C-CODEX-112 | Coverage and disposition are complementary audit records. | `templates/contributor/synthesis-template.md` §"1. Coverage/Disposition Record" | affirm | high | Coverage records response behavior; disposition records what the operator did with claims. |
| C-CODEX-113 | A disposition record must preserve the shared claim envelope for every received claim. | `docs/decisions/ADR-0016.md` §"Structured Output Contract"; `templates/contributor/synthesis-template.md` §"1. Coverage/Disposition Record" | disagree | high | Otherwise the synthesis cannot reconstruct confidence, stance, or source without reopening raw outputs. |

## 3. Relevant Standards

| claim_id | statement | source_citation | contributor_position | confidence | Constraint |
| --- | --- | --- | --- | --- | --- |
| C-CODEX-114 | ADR-0016 requires full supporting-role declaration and per-contributor active roles. | `docs/decisions/ADR-0016.md` §"Decision Drivers" FS-0014/0015 compliance; §"Decision Outcome" items 1-2 | affirm | high | The renderer must reject configurations that cannot truthfully express that relationship. |
| C-CODEX-115 | ADR-0016 validation requires at least one external-CLI and one Hermes-chat contributor in the same task. | `docs/decisions/ADR-0016.md` §"Validation" item 2 | affirm | high | The current renderer and pilot parameter shape satisfy the transport portion of this criterion. |
| C-CODEX-116 | ADR-0016 defines mixed contracts as an expected case reconciled through the shared claim envelope. | `docs/decisions/ADR-0016.md` §"Structured Output Contract" | affirm | high | A pilot using only Research Brief outputs does not validate this architectural promise. |
| C-CODEX-117 | PLAN-0016 remains the executable pilot authority but describes the superseded parameter and contributor model. | `docs/change-plans/PLAN-0016-multi-model-pilot.md` §"Phase 2 — Contributor prompts"; §"Phase 3 — Run contributors"; `templates/contributor/contributor-prompt.md` §"Parameters" | disagree | high | The plan and implementation must describe the same pilot before its evidence can support ADR acceptance. |
| C-CODEX-118 | The gate must remain independent and bound repeated CONDITIONAL cycles. | `templates/contributor/gate-template.md` §"Gate independence"; §"Decision flow" | affirm | high | The overlap check and two-rerun bound cover the originally identified operational failures. |

## 4. Tools and Ecosystem

| claim_id | statement | source_citation | contributor_position | confidence | Tool / Status |
| --- | --- | --- | --- | --- | --- |
| C-CODEX-119 | The renderer successfully supports multiple contributors and transport modes from one parameter file. | `scripts/render_contributor_prompt.py:main`; `render_contributor` | affirm | high | `scripts/render_contributor_prompt.py` — present and operationally exercised. |
| C-CODEX-120 | The renderer does not require `toolsets` even though the template says it is required for Hermes chat. | `templates/contributor/contributor-prompt.md` §"Parameters" field `toolsets`; `scripts/render_contributor_prompt.py:_validate` | disagree | high | Validation checks `provider` but not `toolsets`, allowing incomplete invocation blocks. |
| C-CODEX-121 | The renderer requires an attribution label but does not place it in the rendered prompt. | `templates/contributor/contributor-prompt.md` §"Parameters" field `attribution_label`; `scripts/render_contributor_prompt.py:render_contributor`; `_validate` | disagree | high | The label controls expected output naming but is not available to the contributor for self-identification or claim-ID namespacing. |
| C-CODEX-122 | The canonical Research Brief template does not define how the shared claim envelope maps into its five sections. | `references/research-brief-template.md` §"Format"; `templates/contributor/contributor-prompt.md` §"Render mode: external-cli" Research Brief contract | disagree | medium | The prompt overlays an additional contract, leaving models to choose inconsistent annotations or columns. |
| C-CODEX-123 | The helper does not render the gate prompt or validate a gate response. | `templates/contributor/gate-template.md` §"Operational note"; `scripts/render_contributor_prompt.py:main` | affirm | high | Gate execution status remains an operator-maintained artifact rather than a mechanically checked output. |
| C-CODEX-124 | JSON-schema pre-flight checks existence, JSON syntax, object shape, and schema-like keys, but no pilot schema is available in the reviewed artifacts. | `scripts/render_contributor_prompt.py:_render_contract_block`; `docs/change-plans/PLAN-0016-multi-model-pilot.md` §"Phase 2 — Contributor prompts" | disagree | high | The JSON branch is implemented but not end-to-end validated by this pilot. |

## 5. Recommendations

**claim_id:** C-CODEX-125
**statement:** Make role relationships mandatory in `_validate`: require non-empty `session.supporting_roles`, require `active_contributor_role` for `external-cli` and `hermes-chat`, require it to appear in `supporting_roles`, and validate `session.primary_role`.
**source_citation:** `templates/contributor/contributor-prompt.md` §"Parameters"; `scripts/render_contributor_prompt.py:_validate`
**contributor_position:** affirm
**confidence:** high

Owner: script maintainer. Required before the current pilot is treated as valid. `research-pass` may omit an active role because ADR-0016 explicitly treats it as advisory rather than an accountable contributor session.

**claim_id:** C-CODEX-126
**statement:** Revise PLAN-0016 to the current four-contributor, per-contributor, render-mode-aware pilot before using the run as acceptance evidence.
**source_citation:** `docs/change-plans/PLAN-0016-multi-model-pilot.md` §"Contributors"; §"Phase 2 — Contributor prompts"; §"Phase 3 — Run contributors"; `docs/decisions/ADR-0016.md` §"Validation"
**contributor_position:** affirm
**confidence:** high

Owner: primary session / Document Author. Required for the current pilot. Remove the old `session.contributor_role` instructions, named Gemini path, three-CLI assumptions, and obsolete output paths; document the actual contributor parameter file and transport-specific invocation flow.

**claim_id:** C-CODEX-127
**statement:** Add and exercise one real JSON-schema contributor contract in the pilot rather than claiming mixed-contract validation from implementation inspection alone.
**source_citation:** `docs/decisions/ADR-0016.md` §"Structured Output Contract"; `docs/change-plans/PLAN-0016-multi-model-pilot.md` §"Phase 2 — Contributor prompts"; `scripts/render_contributor_prompt.py:_render_contract_block`
**contributor_position:** affirm
**confidence:** high

Owner: primary session / script maintainer. Required before ADR-0016 acceptance. The schema must require the shared claim envelope on each claim object, and the produced JSON must be validated against that schema after contributor execution.

**claim_id:** C-CODEX-128
**statement:** Expand the Coverage/Disposition Record to include every received claim and preserve `source_citation`, `contributor_position`, and `confidence`, plus `canonical_claim_id` for duplicates.
**source_citation:** `templates/contributor/synthesis-template.md` §"1. Coverage/Disposition Record"; `docs/decisions/ADR-0016.md` §"Structured Output Contract"
**contributor_position:** affirm
**confidence:** high

Owner: synthesis-template maintainer. Required for the current pilot's recovery requirement. Replace “every unique claim that survives into the synthesis” with “every received claim,” and add coverage codes for `unavailable` and `invalid-output`.

**claim_id:** C-CODEX-129
**statement:** Keep the existing verdict categories and broaden `INVALID` execution status to cover missing or unreadable required inputs before evaluation.
**source_citation:** `templates/contributor/gate-template.md` §"EXECUTION STATUS AND VERDICT"; §"Failure modes"
**contributor_position:** affirm
**confidence:** high

Owner: gate-template maintainer. Required before the full-gate phase. The gate prompt should list the expected contributor labels explicitly and state that absent contributor outputs, absent synthesis, or unreadable constraints produce `STATUS: INVALID` with no verdict.

**claim_id:** C-CODEX-130
**statement:** Render `attribution_label` into accountable contributor prompts and use it as the prescribed claim-ID namespace.
**source_citation:** `templates/contributor/contributor-prompt.md` §"Parameters" field `attribution_label`; `scripts/render_contributor_prompt.py:render_contributor`
**contributor_position:** affirm
**confidence:** medium

Owner: script and prompt-template maintainer. Required for reliable mechanical synthesis, though not for FS-0015 compliance itself. This makes the contributor output self-identifying and prevents accidental claim-ID collisions.

**claim_id:** C-CODEX-131
**statement:** Add deterministic renderer tests for all three render modes, both contracts, missing files, malformed schemas, role-membership violations, missing Hermes toolsets, target filtering, and gate overlap.
**source_citation:** `scripts/render_contributor_prompt.py` `VALID_RENDER_MODES`; `_render_contract_block`; `_validate`; `docs/decisions/ADR-0016.md` §"Validation" items 2-3
**contributor_position:** affirm
**confidence:** high

Owner: script maintainer. Required before ADR-0016 acceptance; it may follow the current contributor phase but must precede declaring the helper reproducible.
