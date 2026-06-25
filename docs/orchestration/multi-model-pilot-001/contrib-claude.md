# Research Brief: Review of ADR-0016 Multi-Model Orchestration Pattern

**Task ID:** multi-model-pilot-001  
**Contributor role:** Reviewer  
**Contract:** research_brief  
**Date:** 2026-06-24

---

## Executive Summary

The multi-model orchestration pattern proposed in ADR-0016 is architecturally sound and well-motivated. Its core insight — that cross-model consensus is only auditable if every contributor receives an identical prompt and produces output in a contracted shape — is the right framing, and Option C's document-driven approach is the correct choice over real-time orchestration (ADR-0016 §"Considered Options," Option B). However, this review surfaces four specific defects that should be resolved before the pilot run, not after.

**Finding 1 — Transparency statement missing attribution label (script bug).** `session.attribution_label` is required by `_validate()` (`scripts/render_contributor_prompt.py`:462–478) but is never interpolated into either `_FULL_TRANSPARENCY` or `_GEMINI_RESEARCH` (`scripts/render_contributor_prompt.py`:236–315). It is a zombie parameter: validated but silent. The contributor output consequently carries no machine-readable session label linking it back to the synthesis citation (e.g., `claude-contrib-1`). This breaks the attribution trail that ADR-0016 §"Validation" criterion 4 requires.

**Finding 2 — Gemini FS-0015 exemption is architecturally inconsistent.** `templates/contributor/contributor-prompt.md`:242–276 exempts Gemini from the FS-0015 transparency block on the grounds that it is a "research pass, not a contributor session." But neither FS-0015 nor ADR-0016 grants this exemption formally; it is asserted only in the template pitfalls section and a REVIEWER_TEMPLATE comment. Since Gemini's output feeds the synthesis and the gate reads it, Gemini is functionally a contributor without the accountability layer FS-0015 provides. The exemption may be the right engineering tradeoff, but it requires an explicit decision in ADR-0016 — not a comment in a template.

**Finding 3 — Gate verdict categories lack an INCOMPLETE path.** The three categories (PROCEED / CONDITIONAL / HALT) cover the four evaluation axes defined in `templates/contributor/gate-template.md`:64–108. They do not cover the failure mode where the gate cannot evaluate because a contributor output is missing or malformed. Nor does the gate verify that all expected contributors produced output. A real pilot where one contributor timed out would produce a gate-evaluable synthesis built on partial input — and the gate would issue PROCEED or CONDITIONAL without flagging the gap. PLAN-0016 handles this at the operator level (§"The pilot is degraded-but-acceptable if...") but the gate has no corresponding signal.

**Finding 4 — Synthesis structure loses silence semantics and blocks conditional consensus.** The synthesis template (`templates/contributor/synthesis-template.md`:30–50) requires §1 Consensus and §2 Divergent Points but provides no way to distinguish "contributor was not asked about this point" from "contributor was asked and did not respond" from "contributor responded off-topic." The template's own example (`templates/contributor/synthesis-template.md`:104) marks `gemini-contrib-1` as "silent (out of scope for the research-pass prompt)" — but this is prose annotation in an example, not a structural field. If the pilot synthesizes these three silence types into a single "silent" label, information the gate needs to validate attribution fidelity is lost.

**Explicit disagreement with the task framing:** The task framing asks whether the gate verdict categories "cover the failure modes a real pilot run would surface." My reading is that they do not — specifically, the CONDITIONAL-loop termination condition is undefined. `templates/contributor/gate-template.md`:117–119 says CONDITIONAL requires the primary to address each ISSUES entry "then re-runs the gate." There is no maximum re-run count, no escalation path if the CONDITIONAL cycle does not converge, and no mechanism for the gate and the primary to agree that an issue is genuinely irresolvable. A real pilot that hits persistent CONDITIONAL would stall without a defined exit.

---

## Canonical Concepts

| Concept | Definition | Source |
|---|---|---|
| Transparency statement | Mandatory FS-0015 block at the start of each session declaring mode, primary role, and supporting roles | ADR-0016 §"Validation," criterion 5; `templates/contributor/contributor-prompt.md`:77–90 |
| Structured-output contract | Either `research_brief` (markdown) or `json_schema` (machine-parseable); selected per task and per contributor | ADR-0016 §"Structured Output Contract" |
| Gate evaluator | Independent model (default `deepseek-v4-pro`) that validates synthesis on four axes and issues one of three verdicts | `templates/contributor/gate-template.md`:25–119 |
| Research pass (Gemini) | A Gemini invocation without FS-0015 transparency block, treated as a survey input rather than an accountable contributor session | `templates/contributor/contributor-prompt.md`:241–276 |
| Synthesis | Operator-produced four-section document (Consensus / Divergent Points / Unique Insights / Recommended Action) citing contributor outputs | `templates/contributor/synthesis-template.md`:29–73 |
| Gate mode | `synthesis-only` (default) or `full-gate` (independent evaluator required); escalation conditions defined in ADR-0016 | ADR-0016 §"Gate Mode Defaults" |
| Attribution label | Short identifier (`attribution_label`) assigned per contributor for use in synthesis citations | `templates/contributor/contributor-prompt.md`:46; `scripts/render_contributor_prompt.py`:464 |
| Zombie parameter | A parameter that passes validation but is never interpolated into the rendered output | `scripts/render_contributor_prompt.py`:462–478 vs. 331–345 (no `attribution_label` in `ctx`) |
| CONDITIONAL loop | The re-run cycle triggered when the gate issues CONDITIONAL; currently unbounded | `templates/contributor/gate-template.md`:117–119 |
| Degraded-but-acceptable | Pilot state where one contributor or the gate is unreachable but the pilot continues with reduced coverage | PLAN-0016 §"The pilot is degraded-but-acceptable if..." |

---

## Relevant Standards

| Standard | Relevant Section | Status | What it requires here |
|---|---|---|---|
| FS-0015 | Explainability convention | Implemented (per ADR-0016 frontmatter) | Each session must declare mode + primary role + supporting roles at start |
| FS-0014 | Six-role taxonomy | Implemented | `contributor_role` must be one of the six roles; script does not validate this |
| ADR-0013 | Mode 2 contributor rules | Proposed | Contributors must not commit, open PRs, or transition governed document status |
| ADR-0016 | §"Validation" criterion 4 | Proposed | Final commit must carry `Assisted-By:` and `Contributor-Session:` trailers identifying each contributor |
| ADR-0016 | §"Validation" criterion 5 | Proposed | Zero FS-0015 explainability-convention violations in pilot PR descriptions |
| ADR-0016 | §"Decision Outcome" §5 | Proposed | Gate evaluator must be independent of the contributor set; pre-run probe required |
| ADR-0016 | §"What this ADR does NOT do" | Proposed | No new roles or session modes; no real-time orchestrator; ADR-0013 human-escalation rule still applies |

---

## Tools and Ecosystem

| Tool / Artifact | Role | Gap or Risk |
|---|---|---|
| `scripts/render_contributor_prompt.py` | Renders parameterized prompts for Claude, Codex, Gemini from YAML/JSON params | `attribution_label` validated but not rendered (zombie); `schema_path` not checked for existence at render time; `session.mode` and `session.contributor_role` not validated against FS-0015/FS-0014 enumerations |
| `templates/contributor/contributor-prompt.md` | Human-readable template; defines the YAML parameter schema | Gemini FS-0015 exemption stated only in comments/pitfalls, not as a formal decision; Gemini section hardcodes `research_brief` but script respects `contract` param — discrepancy between template prose and script behavior |
| `templates/contributor/synthesis-template.md` | Four-section structure for operator synthesis | No structural field distinguishing silence types; no field for conditional consensus; Recommended Action open-questions have no pre-commit resolution tracking |
| `templates/contributor/gate-template.md` | Gate evaluator prompt and verdict spec | No INCOMPLETE verdict for missing/malformed inputs; CONDITIONAL loop is unbounded; gate independence is honor-system only; format compliance not verified |
| `deepseek-v4-pro` via `ollama-cloud` | Independent gate evaluator | Requires pre-run probe (correctly required by gate-template.md §"Pre-run probe"); if unavailable, degrades silently to synthesis-only without operator notification unless operator checks |
| `docs/orchestration/<task-id>.yaml` | Per-task parameter file | `attribution_label` field is dead code in script rendering; operators who read the template parameter schema will expect it to appear in the rendered output |

---

## Recommendations

**R1 — Fix the `attribution_label` zombie parameter (script bug, high priority).**  
Add `"attribution_label": session["attribution_label"]` to the `ctx` dict in `render()` (`scripts/render_contributor_prompt.py`:331–345) and insert it into `_FULL_TRANSPARENCY` as a line in the transparency statement — e.g., `- Contributor session label: {attribution_label}`. This is the handle synthesis documents use to cite contributor outputs by short name. Without it, the attribution trail is broken at the synthesis-citation step, violating ADR-0016 §"Validation" criterion 4.

**R2 — Formalize the Gemini FS-0015 exemption in ADR-0016, not just in template comments.**  
The exemption is currently asserted in `templates/contributor/contributor-prompt.md`:242–276 and the Pitfalls section. It should be a named sub-decision in ADR-0016 §"Decision Outcome" (add an item 8 or a §"Research Pass Convention"). The exemption should state: (a) Gemini output is treated as an advisory research input, not an accountable contributor session; (b) Gemini output does not carry an `Assisted-By:` trailer individually, only in aggregate via the operator's synthesis commit; (c) the gate evaluator must be told this when reading Gemini output so it does not penalize missing attribution. Leaving this as a comment means the pilot's gate evaluator may flag Gemini's lack of transparency statement as an attribution fidelity failure.

**R3 — Align the Gemini script behavior with the template documentation.**  
The template's Gemini section hardcodes a Research Brief contract in the prose, but `_render_contract_block(so)` in the script will respect whatever `contract` the operator specifies. Decide: is Gemini always a `research_brief` contributor, or can the operator specify `json_schema`? If always `research_brief`, add a special case in `render()` for `target == "gemini"` that forces `research_brief` regardless of params and raises a warning if the operator specified `json_schema`. If variable, update the template prose to show the conditional form. Current ambiguity will create operator confusion on the first pilot run.

**R4 — Add an INCOMPLETE gate verdict for missing or malformed contributor inputs.**  
Add to `templates/contributor/gate-template.md`:

```
VERDICT: INCOMPLETE
REASON: <one sentence>
MISSING:
- <contributor label whose output was not found or is malformed>
```

Define it as: "One or more expected contributor outputs were not present in `docs/orchestration/<task-id>/` or did not conform to the contracted output format. Gate cannot evaluate attribution fidelity or divergence preservation without complete inputs. Operator must supply missing outputs or document the degraded state before re-running the gate." This covers the case PLAN-0016 §"degraded-but-acceptable" describes at the operator level, but that the gate currently has no signal for.

**R5 — Define a maximum CONDITIONAL re-run count and an escalation path.**  
`templates/contributor/gate-template.md`:117–119 leaves the CONDITIONAL cycle unbounded. Add a hard rule: "After two CONDITIONAL re-runs on the same task, the operator MUST escalate rather than continuing to revise the synthesis. Escalation options: (a) accept the synthesis with the unresolved CONDITIONAL issues explicitly noted as open questions; (b) halt and revise the task framing; (c) override and commit with an explicit operator note that the gate was not satisfied." Two re-runs is a reasonable upper bound; the exact count should be decided by the pilot, but the absence of any bound is a protocol gap.

**R6 — Validate `session.mode` and `session.contributor_role` against canonical enumerations in `_validate()`.**  
`scripts/render_contributor_prompt.py`:460–478 validates the presence of required keys but not their values against FS-0015's five session modes or FS-0014's six roles. Add:

```python
VALID_MODES = {"Architecture Planning", "Document Authoring", "Implementation", "Review", "Communications"}
VALID_ROLES = {"Head Architect", "Document Author", "Spec Reader and Test Planner", "Implementer", "Reviewer", "Communications Lead"}
```

and raise `SystemExit` if `session["mode"]` or `session["contributor_role"]` falls outside these sets. This prevents a prompt from being rendered with a typo in these fields — which would be undetected until the contributor reads the prompt and produces unexpected output.

**R7 — Add a `silence_reason` field to the synthesis template's Divergent Points section.**  
Update `templates/contributor/synthesis-template.md`:43–50 to require that each silence annotation carry a reason code: `NOT_ASKED` | `ASKED_NO_RESPONSE` | `OUT_OF_SCOPE` | `FORMAT_MISMATCH`. This is the minimum needed for the gate to distinguish "contributor was research-pass scoped" from "contributor failed to respond." Without this, the gate's attribution fidelity axis (axis 1) cannot distinguish a legitimate gap from a synthesis error.

**R8 — Validate `schema_path` existence at render time for `json_schema` contracts.**  
`scripts/render_contributor_prompt.py`:369–381 raises a `ValueError` if `schema_path` is absent from params, but does not verify the file exists. Add a `Path(schema_path).exists()` check in `_render_contract_block()` and raise `SystemExit` with a clear error if the schema file is missing. A rendered prompt referencing a non-existent schema file produces a contributor error at read time that is hard to diagnose — much better to catch it at render time.
