## 1. Executive Summary

As Reviewer, I find the proposed orchestration direction sound but not pilot-ready. The transparency block captures the active mode and primary role, but substitutes a singular `contributor_role` for FS-0015’s required declaration of all supporting roles. It therefore works only when exactly one supporting role exists and does not prove that the complete role stance was declared. (`templates/contributor/contributor-prompt.md` §“Parameters”; §“Claude Code contributor”; `docs/decisions/ADR-0016.md` §“Validation,” measurable signals)

I explicitly disagree with the proposal’s claim that the helper produces three paste-ready prompts through “mechanical substitution; no judgment required.” One parameter object supplies one `contributor_role` and one `structured_output.contract` to every target, while PLAN-0016 assigns different roles and contracts to Claude, Codex, and Gemini. The renderer can render either contract individually, but it cannot render the pilot’s mixed-contract contributor set in one invocation without separate parameter files or operator editing. (`templates/contributor/contributor-prompt.md` §“Render Prompt”; `docs/change-plans/PLAN-0016-multi-model-pilot.md` §“Phase 2 — Contributor prompts”; `scripts/render_contributor_prompt.py` `render()`)

There is also an unresolved classification conflict around Gemini. PLAN-0016 calls Gemini one of the three contributors and requires every contributor’s PR comment to contain the FS-0015 statement, while the contributor template and renderer explicitly classify Gemini as a non-contributor research pass and remove that statement. These assertions cannot all be true simultaneously. (`docs/change-plans/PLAN-0016-multi-model-pilot.md` §“Roles and session mode”; §“Contributors”; §“Success criteria” item 2; `templates/contributor/contributor-prompt.md` §“Gemini contributor (research pass)”)

The three gate verdicts are adequate as decision outcomes, but they do not represent execution failures such as an unreachable evaluator, malformed response, missing inputs, or inability to assess the supplied constraints. Those conditions should be recorded as a separate gate execution status rather than stretched into `HALT`. The synthesis structure also needs a coverage/disposition record: its present definition can turn contributor silence into apparent consensus and can omit singleton findings deemed not “worth carrying forward.” (`templates/contributor/gate-template.md` §“Failure modes”; `templates/contributor/synthesis-template.md` §“1. Consensus”; §“3. Unique Insights”)

## 2. Canonical Concepts

| Concept | Definition | Why it matters here | Source |
| --- | --- | --- | --- |
| Role transparency | A session declares its mode, primary role, and supporting roles. | `contributor_role` does not explicitly represent the complete supporting-role set. | `templates/contributor/contributor-prompt.md` §“Parameters”; `docs/decisions/ADR-0016.md` §“Validation,” measurable signals |
| Contributor classification | A participating model must be classified consistently as either a governed contributor or an external research input. | Gemini is called a contributor by the plan but a non-contributor by the template. | `docs/change-plans/PLAN-0016-multi-model-pilot.md` §“Contributors”; `templates/contributor/contributor-prompt.md` §“Gemini contributor (research pass)” |
| Contract selection | Each contributor receives exactly one output contract. | The selector is clear for one invocation, but not for a mixed-contract contributor set. | `docs/decisions/ADR-0016.md` §“Structured Output Contract”; `scripts/render_contributor_prompt.py` `_render_contract_block()` |
| Contract comparability | Outputs must expose sufficiently comparable claims for synthesis. | Research Brief Markdown and arbitrary task-specific JSON do not inherently have the same claim model. | `docs/decisions/ADR-0016.md` §“Decision Drivers”; §“Structured Output Contract” |
| Per-contributor parameters | Role, attribution, and output contract vary by contributor. | The current parameter object stores each as a single scalar shared across all rendered targets. | `docs/change-plans/PLAN-0016-multi-model-pilot.md` §“Phase 2 — Contributor prompts”; `scripts/render_contributor_prompt.py` `render()` |
| Gate verdict | A completed evaluation returns `PROCEED`, `CONDITIONAL`, or `HALT`. | These categories describe decisions, not whether a valid evaluation occurred. | `templates/contributor/gate-template.md` §“VERDICT”; §“Failure modes” |
| Coverage preservation | Synthesis records who addressed, omitted, or disagreed with each question. | “All contributors who addressed the point” can label partial coverage as consensus. | `templates/contributor/synthesis-template.md` §“1. Consensus” |
| Finding disposition | Every contributor finding receives an incorporated, rejected, deferred, duplicate, or out-of-scope disposition. | The current synthesis retains only selected unique insights, allowing other singleton findings to disappear. | `templates/contributor/synthesis-template.md` §“3. Unique Insights”; `docs/change-plans/PLAN-0016-multi-model-pilot.md` §“Phase 8 — Post-pilot revision” |

## 3. Relevant Standards

| Standard | Scope | Applies here how | Constraint |
| --- | --- | --- | --- |
| FS-0015 | Session modes and explainability | Defines the transparency convention ADR-0016 claims to implement. | Declare mode, primary role, and supporting roles; the current singular contributor-role field is underspecified. |
| ADR-0016 | Proposed orchestration decision | Defines mixed contracts, synthesis, and gate evaluation. | Validation requires prompts accepted without manual rewriting. (`docs/decisions/ADR-0016.md` §“Validation” item 2) |
| PLAN-0016 | Pilot execution | Assigns contributor-specific roles and contracts. | Claude and Gemini use Research Brief; Codex uses JSON schema. (`docs/change-plans/PLAN-0016-multi-model-pilot.md` §“Phase 2 — Contributor prompts”) |
| Research Brief contract | Canonical prose output | Provides five exact sections and citation requirements. | The referenced file now exists and the renderer preflights it. (`references/research-brief-template.md` §“Format”; `scripts/render_contributor_prompt.py` `_render_contract_block()`) |
| Contributor prompt template | Prompt-level governance | Defines transparency, guardrails, attribution, and escalation. | Its Gemini exception conflicts with PLAN-0016’s contributor and success-criteria language. (`templates/contributor/contributor-prompt.md` §“Gemini contributor (research pass)”) |

## 4. Tools and Ecosystem

| Tool / Source | Type | Used for | Status |
| --- | --- | --- | --- |
| `scripts/render_contributor_prompt.py` | Script | Generates vendor prompts | Present; renders either contract individually but lacks per-target role and contract overrides. |
| `references/research-brief-template.md` | Template | Defines the Research Brief | Present; renderer now verifies its existence. |
| `templates/contributor/contributor-review.schema.json` | JSON Schema | Planned Codex output contract | Missing; PLAN-0016 schedules its creation during Phase 2. (`docs/change-plans/PLAN-0016-multi-model-pilot.md` §“Phase 2 — Contributor prompts”) |
| Minimal YAML parser | Script component | Reads orchestration parameters | Present; accepts the pilot YAML’s nonstandard `key: []` followed by list entries, but this syntax is not ordinary YAML and reduces portability. (`scripts/render_contributor_prompt.py` `parse_minimal_yaml()`) |
| Gate prompt | Manual template | Evaluates synthesis | Present but not rendered by the helper, leaving a separate manual substitution step. (`templates/contributor/gate-template.md` §“Operational note”) |
| Contributor output archive | Repository artifacts and PR comments | Preserves raw evidence | Proposed; raw outputs permit later recovery even when synthesis loses information. (`docs/decisions/ADR-0016.md` §“Consequences — Positive”; `docs/change-plans/PLAN-0016-multi-model-pilot.md` §“Phase 3”) |

## 5. Recommendations

1. **Replace `session.contributor_role` with `session.supporting_roles`, while retaining an explicit `active_contributor_role`.** The primary session should own the complete supporting-role list, while each rendered contributor identifies its own active role. This is required before the pilot to satisfy the explainability convention without relying on a one-role assumption. Owner: primary session. (`templates/contributor/contributor-prompt.md` §“Parameters”)

2. **Adopt a `contributors` map keyed by target.** Each entry should contain `role`, `contract`, contract path, attribution label, and whether FS-0015 governance applies. The helper should merge shared task parameters with each target’s entry. This is required before the pilot because the current single-value model cannot implement PLAN-0016’s assignments. Owner: script maintainer. (`docs/change-plans/PLAN-0016-multi-model-pilot.md` §“Phase 2”; `scripts/render_contributor_prompt.py` `render()`)

3. **Resolve Gemini’s status explicitly.** Either make Gemini a governed contributor and include the transparency block, or rename it everywhere as an external research input and exclude it from “each contributor” success criteria. Do not retain the current hybrid classification. Required before the pilot. Owner: ADR/PLAN author. (`docs/change-plans/PLAN-0016-multi-model-pilot.md` §“Contributors”; §“Success criteria” item 2)

4. **Keep the three decision verdicts, but add a separate execution status.** Use statuses such as `COMPLETE`, `NOT_RUN`, and `INVALID`, followed by a verdict only when status is `COMPLETE`. This distinguishes policy rejection from evaluator unavailability or malformed output. Required before relying on gate metrics; it need not block contributor execution. Owner: gate-template author. (`templates/contributor/gate-template.md` §“Failure modes”)

5. **Add a coverage and disposition table to the synthesis.** For each task question and contributor, record `addressed`, `silent`, `unavailable`, or `out_of_scope`; for every finding, record `incorporate`, `reject`, `defer`, `duplicate`, or `out_of_scope` with a reason. This is required for the pilot’s silent-drop check. Owner: synthesis author/template maintainer. (`templates/contributor/synthesis-template.md` §“1. Consensus”; §“3. Unique Insights”; `docs/change-plans/PLAN-0016-multi-model-pilot.md` §“Phase 8”)

6. **Define a shared claim envelope across both contracts.** At minimum, both formats should expose claim identifier, statement, source citation, contributor position, confidence or evidence strength, and recommendation. Without this, the claim that mixed outputs can be mechanically synthesized is unsupported. Required before ADR-0016 acceptance, though the first pilot may be used to validate the envelope. Owner: primary architect. (`docs/decisions/ADR-0016.md` §“Decision Drivers”; §“Structured Output Contract”)

7. **Validate JSON schemas, not merely their existence.** The renderer currently accepts any existing file as `schema_path`; it should parse the file as JSON and verify that it is a JSON Schema before rendering. Required before the Codex phase of the pilot. Owner: script maintainer. (`scripts/render_contributor_prompt.py` `_render_contract_block()` lines handling `json_schema`)
