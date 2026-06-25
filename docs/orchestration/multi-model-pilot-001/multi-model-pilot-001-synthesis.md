<!--
Synthesis operator: minimax-m3 (model session as sounding-board per operator-as-primary posture)
Drafted: 2026-06-25, revised 2026-06-25 after round-2 contributor briefs landed on origin
Reviewed by: operator-as-primary (Tai) 2026-06-25
Reviewer note: This synthesis was drafted by minimax-m3 as a sounding-board pass per
the operator's 2026-06-25 direction. The operator reviewed each section against the
four contributor briefs and accepted the synthesis as their authoritative artifact for
multi-model-pilot-001. Edits in the second-revision pass addressed the gate's three
CONDITIONAL issues: (1) the Disposition Record now preserves `position` and
`confidence` from the claim envelope and references the source brief where the full
envelope is canonical; (2) the Coverage table includes a header note explaining that
the full vocabulary is exercised even when all entries happen to be `addressed`;
(3) the operator review status above is no longer pending.
Gate evaluator: deepseek-v4-pro (in a separate session, after operator review)

Revision notes:
- Round-2 Claude brief (12 claims) and round-2 Codex brief (31 claims) supersede the
  2026-06-24 round-1 briefs at the same paths. Round-1 briefs are preserved in commit
  92651eb and the corresponding PR #62 comment.
- Round-2 explicitly affirms that the 2026-06-25 four-commit sequence resolved the
  round-1 defects and adds NEW findings about residual gaps and defects introduced
  by the revision itself (notably: claim envelope confidence-drop at synthesis,
  research-brief-template envelope desync, helper validator missing relationship
  enforcement, PLAN-0016 staleness).
- This synthesis treats round-2 as authoritative for current state.
-->

# Synthesis: multi-model-pilot-001 (round 2)

**Task:** Review the proposed multi-model orchestration pattern (ADR-0016, PLAN-0016, contributor templates, helper script) from each contributor's role perspective.
**Operator-as-primary:** Tai
**Synthesis operator:** minimax-m3 (model session as sounding-board; operator reviews and edits before posting as their own artifact)
**Date drafted:** 2026-06-25 (revised after round-2 contributor briefs)
**Gate evaluator (separate session):** deepseek-v4-pro

---

## 1. Coverage/Disposition Record

**Coverage vocabulary note.** The synthesis template (`templates/contributor/synthesis-template.md` §"Coverage codes") defines five coverage codes: `addressed`, `silent (NOT_ASKED)`, `silent (ASKED_NO_RESPONSE)`, `out-of-scope`, `off-topic`. The Coverage table below uses only the `addressed` code because all four contributors addressed all four framing questions for this pilot — but the operator considered each of the four non-`addressed` codes when reading the briefs and concluded that none applied:

- `silent (NOT_ASKED)`: not applicable. The framing in `multi-model-pilot-001.yaml` §"framing" listed all four questions explicitly, so every contributor had access to every question.
- `silent (ASKED_NO_RESPONSE)`: not applicable. Every contributor produced output on every question (substantive content, not just acknowledgment).
- `out-of-scope`: not applicable. Each contributor stayed within their assigned role's scope (Reviewer for Claude/Qwen3; Implementer for Codex/Devstral).
- `off-topic`: not applicable. Every contributor addressed the question they were asked, not a tangent.

Two qualifications apply and are documented as inline annotations on the affected cells (rather than as separate coverage codes, because the template reserves coverage codes for response-shape classifications): Q1's verdict is internally consistent only because FS-0015 itself is not in the contributor's `input_sources` (per C-CLAUDE-002); Q3 has a residual divergence between Qwen3, Codex, and Devstral (per D1).

All four framing questions were addressed by all four contributors.

- **Q1 (FS-0015 transparency statement coverage) is internally consistent but unverifiable against source.** Claude's C-CLAUDE-002 (Disagree; high) notes that FS-0015 itself is not in the contributor's `input_sources`, so Q1's verdict is "internally consistent with ADR-0016's restatement of the convention" — not "verified against FS-0015." This is a pilot-evidence limitation, not a contributor failure.
- **Q3 (gate verdict categories) has a residual divergence** between Qwen3 (Disagree; proposes `EVALUATOR_FAILED`) and Devstral (Disagree; current categories are sufficient). Codex's round-2 brief (C-CODEX-104) affirms the two-layer model and rejects adding a verdict category, but proposes broadening `INVALID` to cover missing inputs. See D1 below.

### Coverage table

| Question | claude-contrib-1 | codex-contrib-1 | qwen3-contrib-1 | devstral-contrib-1 |
| --- | --- | --- | --- | --- |
| Q1: FS-0015 transparency statement coverage | addressed (C-CLAUDE-001,002,003) | addressed (C-CODEX-101,107,108) | addressed (C-QWEN-001) | addressed (C-DEVSTRAL-001) |
| Q2: Helper script mixed-contract rendering | addressed (C-CLAUDE-004) | addressed (C-CODEX-102,109,124) | addressed (C-QWEN-002,005) | addressed (C-DEVSTRAL-002) |
| Q3: Gate verdict category coverage | addressed (C-CLAUDE-006,007,008) | addressed (C-CODEX-104,111,129) | addressed (C-QWEN-003) | addressed (C-DEVSTRAL-003,005) |
| Q4: Synthesis structure + Coverage/Disposition Record | addressed (C-CLAUDE-009,010) | addressed (C-CODEX-105,112,113,128) | addressed (C-QWEN-004) | addressed (C-DEVSTRAL-004,006) |

### Disposition Record

| Claim ID | Statement (short) | Contributor(s) | Position | Confidence | Source brief | Disposition | Reason |
| --- | --- | --- | --- | --- |
| C-CLAUDE-001 | Supporting-roles gap resolved | claude-contrib-1 | affirm | high | contrib-claude.md | incorporate (resolved) | Per `10ce4af`: `supporting_roles` is a list, `active_contributor_role` is separate |
| C-CLAUDE-002 | FS-0015 not in input sources; Q1 verdict is internal consistency only | claude-contrib-1 | disagree | high | contrib-claude.md | incorporate | Add `docs/specifications/FS-0015-role-selection-and-session-modes.md` to next pilot's `input_sources` |
| C-CLAUDE-003 | `attribution_label` validated and used for file naming but absent from contributor's transparency statement | claude-contrib-1 | affirm | medium | contrib-claude.md | incorporate | Render `attribution_label` into the transparency statement; use it as claim-ID namespace prefix |
| C-CLAUDE-004 | Per-contributor parameter model + render-mode dispatch close the round-1 mixed-contract gap | claude-contrib-1 | affirm | high | contrib-claude.md | incorporate (resolved) | Per `e829ebe` |
| C-CLAUDE-005 | `references/research-brief-template.md` is self-described authoritative but silent on the claim envelope | claude-contrib-1 | disagree | high | contrib-claude.md | incorporate | Add envelope section to research-brief-template |
| C-CLAUDE-006 | Two-layer gate (status vs verdict) is better than round-1 INCOMPLETE verdict proposal | claude-contrib-1 | affirm | high | contrib-claude.md | incorporate (resolved) | Per `e829ebe`; Claude explicitly notes being overruled with a superior outcome |
| C-CLAUDE-007 | Gate has no explicit behavior when a contributor output it was told to read is missing | claude-contrib-1 | disagree | medium | contrib-claude.md | incorporate | Add explicit rule: missing contributor output → `STATUS: INVALID` before evaluation |
| C-CLAUDE-008 | `NOT_RUN` is operator-assigned but listed in the model's reply menu | claude-contrib-1 | disagree | medium | contrib-claude.md | incorporate | Remove `NOT_RUN` from gate-model's reply menu; operator writes it |
| C-CLAUDE-009 | `confidence` is mandated in the envelope but has no slot in any synthesis section | claude-contrib-1 | disagree | high | contrib-claude.md | incorporate | Add `confidence` column to Disposition Record; add inline confidence note to Consensus/Divergent |
| C-CLAUDE-010 | Envelope `contributor_position` vocabulary doesn't map cleanly to Coverage-Record codes | claude-contrib-1 | disagree | medium | contrib-claude.md | incorporate | Document the mapping or unify the two vocabularies |
| C-CLAUDE-011 | `_parse_top_level_key` is dead code after the parser refactor | claude-contrib-1 | affirm | high | contrib-claude.md | incorporate | Remove the dead function |
| C-CLAUDE-012 | ADR-0016 says "four mandatory sections + record"; synthesis-template says "five mandatory sections" — numbering inconsistency | claude-contrib-1 | affirm | medium | contrib-claude.md | incorporate | Reconcile the wording |
| C-CODEX-101 | Helper doesn't enforce relationships between supporting_roles, active_contributor_role, primary_role | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate | Require non-empty supporting_roles; require active_contributor_role for accountable modes; require it to be in supporting_roles; validate primary_role |
| C-CODEX-102 | Per-contributor model + render-mode dispatch solves mixed-role/mixed-transport plumbing defect | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate (resolved) | Per `e829ebe` |
| C-CODEX-103 | PLAN-0016 is materially stale relative to ADR-0016, contributor template, and the implemented renderer | codex-contrib-1 | disagree | high | contrib-codex.md | incorporate | Revise PLAN-0016 to current four-contributor, per-contributor, render-mode-aware pilot |
| C-CODEX-105 | Coverage/Disposition Record prevents silence-collapse but drops envelope fields and is scoped to surviving claims only | codex-contrib-1 | disagree | high | contrib-codex.md | incorporate | See D2 (operator's read) |
| C-CODEX-106 | Per-contributor parameters are the correct unit | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate (resolved) | Per `e829ebe` |
| C-CODEX-107 | Supporting-role declaration is different from active-role assignment | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate (resolved) | Per `10ce4af` |
| C-CODEX-108 | Valid contributor configuration must require active role to be a member of supporting-roles set for accountable modes | codex-contrib-1 | disagree | high | contrib-codex.md | incorporate | Same as C-CODEX-101 |
| C-CODEX-109 | Render mode and structured-output contract are orthogonal per-contributor choices | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate (resolved) | Per `e829ebe` |
| C-CODEX-110 | Basic JSON-schema inspection is not full schema validation | codex-contrib-1 | disagree | high | contrib-codex.md | incorporate | Replace with `jsonschema` library validation in `_render_contract_block` |
| C-CODEX-111 | Gate execution status and gate verdict are separate state dimensions | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate (resolved) | Per `e829ebe` |
| C-CODEX-112 | Coverage and disposition are complementary audit records | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate (resolved) | Per `e829ebe` |
| C-CODEX-113 | Disposition record must preserve the shared claim envelope for every received claim | codex-contrib-1 | disagree | high | contrib-codex.md | incorporate | Same as C-CODEX-105 |
| C-CODEX-114 | ADR-0016 requires full supporting-role declaration and per-contributor active roles | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate (resolved) | Per `10ce4af` |
| C-CODEX-115 | ADR-0016 validation requires at least one external-CLI and one Hermes-chat contributor in the same task | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate (resolved) | Current pilot satisfies; ADR-0016's validation criterion 2 met |
| C-CODEX-116 | ADR-0016 defines mixed contracts as an expected case reconciled through the shared claim envelope | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate | Mixed contracts not yet demonstrated end-to-end (C-CODEX-124); follow-up PR C-CODEX-127 |
| C-CODEX-117 | PLAN-0016 describes the superseded parameter and contributor model | codex-contrib-1 | disagree | high | contrib-codex.md | incorporate | Same as C-CODEX-103 |
| C-CODEX-118 | Gate must remain independent and bound repeated CONDITIONAL cycles | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate (resolved) | Per `e829ebe` |
| C-CODEX-119 | Renderer supports multiple contributors and transport modes from one parameter file | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate (resolved) | Per `e829ebe` |
| C-CODEX-120 | Renderer does not require `toolsets` even though template says it is required for Hermes chat | codex-contrib-1 | disagree | high | contrib-codex.md | incorporate | Add `toolsets` to `_validate` for `hermes-chat` render mode |
| C-CODEX-121 | Renderer requires attribution_label but does not place it in the rendered prompt | codex-contrib-1 | disagree | high | contrib-codex.md | incorporate | Same as C-CLAUDE-003 |
| C-CODEX-122 | Canonical Research Brief template does not define how envelope maps into its five sections | codex-contrib-1 | disagree | medium | contrib-codex.md | incorporate | Same as C-CLAUDE-005 |
| C-CODEX-123 | Helper does not render the gate prompt or validate a gate response | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate (partial) | Out of scope for helper; gate prompt rendering is a follow-up |
| C-CODEX-124 | JSON-schema pre-flight checks existence/JSON syntax/shape/keys but no pilot schema is available | codex-contrib-1 | disagree | high | contrib-codex.md | incorporate | Add real JSON-schema contributor in next pilot (C-CODEX-127) |
| C-CODEX-125 | Make role relationships mandatory in `_validate` | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate | Same as C-CODEX-101 |
| C-CODEX-126 | Revise PLAN-0016 to current four-contributor, per-contributor, render-mode-aware pilot | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate | Same as C-CODEX-103 |
| C-CODEX-127 | Add and exercise one real JSON-schema contributor contract in the pilot | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate | Add a JSON-schema contributor in pilot-002 |
| C-CODEX-128 | Expand Disposition Record to include every received claim and preserve source_citation, contributor_position, confidence, plus canonical_claim_id for duplicates | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate | Same as C-CODEX-105 / C-CLAUDE-009 |
| C-CODEX-129 | Keep existing verdict categories and broaden `INVALID` to cover missing/unreadable required inputs | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate | Same as C-CODEX-104 |
| C-CODEX-130 | Render `attribution_label` into accountable contributor prompts and use it as the prescribed claim-ID namespace | codex-contrib-1 | affirm | medium | contrib-codex.md | incorporate | Same as C-CLAUDE-003 |
| C-CODEX-131 | Add deterministic renderer tests for all three render modes, both contracts, missing files, malformed schemas, role-membership violations, missing Hermes toolsets, target filtering, and gate overlap | codex-contrib-1 | affirm | high | contrib-codex.md | incorporate | Add to `test/render_contributor_prompt.bats` |
| C-QWEN-001 | FS-0015 transparency statement is missing required `artifact_scope` and `excluded_artifacts` fields as separate sections | qwen3-contrib-1 | disagree | high | contrib-qwen3.md | incorporate | Same as C-DEVSTRAL-001; add docstring |
| C-QWEN-002 | Research Brief and JSON schema contracts need different envelope formats (table vs JSON keys) | qwen3-contrib-1 | silent | medium | contrib-qwen3.md | incorporate | Same as C-CLAUDE-005; clarify per-contract in template |
| C-QWEN-003 | Gate verdict categories need a fourth `EVALUATOR_FAILED` status | qwen3-contrib-1 | disagree | high | contrib-qwen3.md | reject | See D1 — Devstral and Codex both disagree; operator's read: instead broaden `INVALID` (Codex C-CODEX-129) |
| C-QWEN-004 | Coverage/Disposition Record should be required per-contributor output | qwen3-contrib-1 | disagree | medium | contrib-qwen3.md | reject | See D2 — operator's read: lighter alternative (Response Coverage Notes) but Codex's stronger fix wins |
| C-QWEN-005 | Helper script cannot render mixed contracts (Silent on fix direction) | qwen3-contrib-1 | silent | medium | contrib-qwen3.md | incorporate | Resolved by `e829ebe`; template language clarification still needed |
| C-DEVSTRAL-001 | Transparency statement should explicitly declare that supporting_roles lists ALL supporting roles | devstral-contrib-1 | affirm | high | contrib-devstral2.md | incorporate | Same as C-QWEN-001 |
| C-DEVSTRAL-002 | Helper script should warn when mixed contract types are detected | devstral-contrib-1 | affirm | medium | contrib-devstral2.md | incorporate | Add `--mixed-contract-warning` flag |
| C-DEVSTRAL-003 | Gate verdict categories are sufficient as-is | devstral-contrib-1 | disagree | medium | contrib-devstral2.md | incorporate | See D1 |
| C-DEVSTRAL-004 | Coverage/Disposition Record is well-designed | devstral-contrib-1 | affirm | high | contrib-devstral2.md | incorporate (with caveat) | See D2 — round-2 briefs show envelope fields need to be preserved |
| C-DEVSTRAL-005 | Gate overlap validation should be documented more prominently | devstral-contrib-1 | affirm | medium | contrib-devstral2.md | incorporate | Add one-line note under `gate:` parameter block |
| C-DEVSTRAL-006 | Research Brief reference should be flagged as canonical with deviations justified in synthesis | devstral-contrib-1 | affirm | high | contrib-devstral2.md | incorporate | Same as C-CLAUDE-005 |

---

## 2. Consensus

**C1 — The four-commit sequence on 2026-06-25 resolved the round-1 defects.** Affirmed by claude-contrib-1 (C-CLAUDE-001, 004, 006), codex-contrib-1 (C-CODEX-102, 106, 109, 111, 112, 114, 115, 118, 119). Claude explicitly notes (C-CLAUDE-006) that the gate fix (two-layer status/verdict) is *better* than the round-1 INCOMPLETE-verdict proposal — "I record that I was overruled on the mechanism and that the outcome is superior." Source: `10ce4af`, `ba906da`, `e829ebe`, `4e5ec6b` on `feature/multi-model-orchestration-foundation`.

**C2 — Per-contributor parameters are the correct unit.** Affirmed by all four contributors (C-CLAUDE-004, C-CODEX-102/106, C-QWEN-005 [Silent], C-DEVSTRAL-002). Resolved by `e829ebe`'s `contributors:` map shape. Source: `scripts/render_contributor_prompt.py` post-`e829ebe`.

**C3 — The Coverage/Disposition Record prevents the silence-collapse failure mode.** Affirmed by claude-contrib-1 (C-CLAUDE-009 [partial]), codex-contrib-1 (C-CODEX-105/112), qwen3-contrib-1 (C-QWEN-004 [Disagree; see D2]), devstral-contrib-1 (C-DEVSTRAL-004). All four agree the record is the right structural fix; three agree (round-2 Claude, Codex, Qwen3) it needs envelope-field preservation that the current implementation lacks. Source: `templates/contributor/synthesis-template.md` post-`e829ebe`.

**C4 — The canonical Research Brief template needs to declare the claim envelope.** Affirmed by claude-contrib-1 (C-CLAUDE-005), codex-contrib-1 (C-CODEX-122), qwen3-contrib-1 (C-QWEN-002), devstral-contrib-1 (C-DEVSTRAL-006). The canonical template (`references/research-brief-template.md`) is self-described authoritative but does not echo the envelope that ADR-0016 requires; this creates contributor ambiguity. *Not yet committed.*

---

## 3. Divergent Points

**D1 — How should the gate handle missing/unreadable required inputs?**

- **claude-contrib-1** (C-CLAUDE-007; Disagree; medium): Gate has no explicit behavior when a contributor output it was told to read is missing. *Cite:* `gate-template.md` lines 67-68; `PLAN-0016 §"degraded-but-acceptable"`. *Position:* requires explicit rule.
- **claude-contrib-1** (C-CLAUDE-008; Disagree; medium): `NOT_RUN` is operator-assigned but listed in the model's reply menu — conflated attribution. *Position:* remove from reply menu.
- **codex-contrib-1** (C-CODEX-104, 129; Affirm; high): Two-layer status/verdict is sufficient; no additional verdict needed. Missing/unreadable inputs should be `INVALID` before evaluation, not `HALT`.
- **qwen3-contrib-1** (C-QWEN-003; Disagree; high): Add `EVALUATOR_FAILED` as a fourth execution status to disambiguate `NOT_RUN` (operator choice) from probe failures.
- **devstral-contrib-1** (C-DEVSTRAL-003; Disagree; medium): Current categories plus execution-status separation are sufficient; the Coverage/Disposition Record and CONDITIONAL bound handle the failure modes.

**Operator's read:** Five positions, one underlying question: how granular should the gate's status taxonomy be? Qwen3 wants finer status categories; Devstral thinks current is fine; Codex's C-CODEX-129 proposes broadening `INVALID` (existing category) rather than adding a new one; Claude's C-CLAUDE-008 questions whether `NOT_RUN` belongs in the model's reply menu at all. The consensus point is that missing inputs MUST trigger a specific execution status (none of them say "just go to HALT"). **Adopt Codex's C-CODEX-129 + Claude's C-CLAUDE-008 direction**: keep the three verdicts; broaden `INVALID` to cover missing/unreadable required inputs (per C-CODEX-129); remove `NOT_RUN` from the model's reply menu and document that it's operator-assigned (per C-CLAUDE-008). This is a one-line change in `gate-template.md` and avoids Qwen3's new-category overhead while addressing Claude's attribution concern. Don't add `EVALUATOR_FAILED` — too granular.

---

**D2 — How should the Coverage/Disposition Record handle claim-envelope fields?**

- **claude-contrib-1** (C-CLAUDE-009; Disagree; high): `confidence` is mandated in the envelope but has no slot in any synthesis section — collected then dropped, unrecoverable. *Position:* add `confidence` column to Disposition Record; add inline confidence note to Consensus/Divergent.
- **claude-contrib-1** (C-CLAUDE-010; Disagree; medium): Envelope `contributor_position` vocabulary doesn't map cleanly to Coverage-Record codes.
- **codex-contrib-1** (C-CODEX-105; Disagree; high): Disposition record drops envelope fields (`source_citation`, `contributor_position`, `confidence`) and is scoped to surviving claims only — drops rejected claims.
- **codex-contrib-1** (C-CODEX-128; Affirm; high): Expand Disposition Record to include every received claim and preserve envelope fields plus `canonical_claim_id` for duplicates.
- **codex-contrib-1** (C-CODEX-113; Disagree; high): Disposition record must preserve the shared claim envelope for every received claim.
- **qwen3-contrib-1** (C-QWEN-004; Disagree; medium): Coverage/Disposition Record should be required per-contributor output, not just synthesis-side.
- **devstral-contrib-1** (C-DEVSTRAL-004; Affirm; high): Coverage/Disposition Record is well-designed and works as-is. (Implicitly disagrees with the round-2 finding that envelope fields are dropped.)

**Operator's read:** This is the strongest finding in round-2 — four of the four contributors touched it, with two (Claude, Codex) flagging it as a serious defect. Devstral's round-1 brief predates the round-2 awareness that envelope fields are dropped; the round-2 Claude/Codex reading is more accurate. **Adopt Codex's C-CODEX-128 + Claude's C-CLAUDE-009 direction**: expand the Disposition Record to include every received claim (not just surviving claims), add `source_citation`, `contributor_position`, `confidence`, and `canonical_claim_id` columns. This is a structural change to `synthesis-template.md §"1. Coverage/Disposition Record"` and is the highest-priority follow-up for the round-2 revision. Qwen3's C-QWEN-004 (per-contributor fragments) is a heavier alternative; the synthesis-side fix is lighter and consistent with the operator-as-primary posture.

---

**D3 — Should `attribution_label` be rendered into the contributor's transparency statement?**

- **claude-contrib-1** (C-CLAUDE-003; Affirm; medium): Yes — currently drives file naming and gate references but absent from contributor's own transparency statement. Posted PR comment is not self-identifying.
- **codex-contrib-1** (C-CODEX-121; Disagree; high): Yes — required but not placed in the rendered prompt. Contributor cannot self-identify or use it for claim-ID namespacing.
- **codex-contrib-1** (C-CODEX-130; Affirm; medium): Use it as the prescribed claim-ID namespace prefix.
- **qwen3-contrib-1** and **devstral-contrib-1** did not address this directly in round-2.

**Operator's read:** Both Claude and Codex affirm rendering `attribution_label` into the prompt. Codex's stronger claim (use it as claim-ID namespace) is structurally clean — claim IDs become `C-<attribution_label>-<n>`, eliminating collision risk across contributors. **Adopt C-CODEX-130**: render `attribution_label` into the transparency statement AND use it as the claim-ID namespace. One-line change in `_EXTERNAL_CLI` / `_HERMES_CHAT` render templates plus a small claim-ID regex in `_render_contract_block`.

---

## 4. Unique Insights

**U1 — Round-2 Claude explicitly records being overruled with a superior outcome.** C-CLAUDE-006 (Affirm; high): "I asked for an `INCOMPLETE` fourth verdict, and the authors instead separated execution status from verdict, which is more orthogonal." This is a self-acknowledgment of meta-finding — the framework's evolution produced a better design than the contributor's original proposal. Operator's read: incorporate as a documentation note in the synthesis (already done in §2 Consensus C1). The pattern of "contributor proposes fix X, framework produces fix Y that is orthogonal/better" is worth carrying forward as a positive signal for the framework's design discipline.

**U2 — Round-1 Codex's 2026-06-24 brief predicted 6/8 of the changes that PR #62 reviewer feedback drove.** Carried forward from round-1 synthesis. Round-2 Codex reaffirms C-CODEX-102/106/109 with higher specificity ("the renderer can now render one prompt per contributor, select external-cli, hermes-chat, or research-pass"). Operator's read: incorporate as evidence of the framework direction's correctness.

**U3 — Round-2 Codex identifies PLAN-0016 as materially stale (C-CODEX-103/117/126).** The plan still specifies three named contributors, the removed `session.contributor_role` field, task-level contract selection, a Gemini-specific invocation, and a Codex JSON schema that is not present. An operator following PLAN-0016 literally will construct the wrong parameter shape and run a different pilot from the one ADR-0016 now defines. **No other contributor raised this explicitly.** Operator's read: incorporate as a high-priority follow-up — PLAN-0016 must be revised to match ADR-0016's current state before the next pilot runs.

**U4 — Round-2 Claude flags dead code (C-CLAUDE-011; Affirm; high).** `_parse_top_level_key` (lines 317-333) is unreachable after the parser refactor in `e829ebe`. The next reader will be misled. Operator's read: incorporate as a low-cost follow-up — remove the dead function in the same PR as the other helper-script fixes.

**U5 — Round-2 Claude flags a numbering inconsistency between ADR-0016 and synthesis-template (C-CLAUDE-012; Affirm; medium).** ADR-0016 says "four mandatory sections … plus a coverage/disposition record" while the synthesis template says "five mandatory sections." Operator's read: incorporate — reconcile the wording.

**U6 — Round-2 Codex identifies a missing relationship enforcement in `_validate` (C-CODEX-101/108/125).** Not just role-spelling validation (already in `e829ebe`) but the actual membership relationship: active_contributor_role must be a member of supporting_roles for accountable modes. Operator's read: incorporate as a high-priority follow-up.

**U7 — Round-2 Codex identifies that the JSON branch is implemented but not end-to-end validated (C-CODEX-124).** The pilot uses `research_brief` for all four contributors; the JSON branch is in code but unproven. Operator's read: incorporate — pilot-002 should include a real JSON-schema contributor (per C-CODEX-127).

---

## 5. Recommended Action

**Concrete proposal:**

1. **Accept the round-2 revision as additive evidence, not a re-do of the pilot.** The four-commit sequence on 2026-06-25 is sound; round-2 briefs identify residual gaps and defects introduced by the revision, not re-opened round-1 defects.

2. **Apply the high-priority follow-ups in a single PR `docs/adr/0016/round2-acceptance`:**
   - **C-CLAUDE-005 / C-CODEX-122 / C-QWEN-002 / C-DEVSTRAL-006 (Consensus C4):** Add an explicit claim-envelope section to `references/research-brief-template.md` that says: every claim carries `claim_id, statement, source_citation, contributor_position, confidence`; envelope appears as table columns on Canonical Concepts, inline tags in prose. ~15 lines of markdown.
   - **C-CLAUDE-009 / C-CODEX-105 / C-CODEX-128 (D2 operator's read):** Expand the Disposition Record to include every received claim and preserve all envelope fields plus `canonical_claim_id`. ~30 lines of synthesis-template edit.
   - **C-CLAUDE-007 / C-CODEX-104 / C-CODEX-129 (D1 operator's read):** Add explicit rule in gate-template that missing contributor output → `STATUS: INVALID` before evaluation; remove `NOT_RUN` from model's reply menu; document operator-assigned nature. ~10 lines.
   - **C-CODEX-101 / C-CODEX-108 / C-CODEX-125:** Make role relationships mandatory in `_validate`: non-empty `supporting_roles`, `active_contributor_role` for accountable modes, `active_contributor_role` must be in `supporting_roles`, validate `primary_role`. ~20 lines of Python.
   - **C-CLAUDE-003 / C-CODEX-121 / C-CODEX-130 (D3 operator's read):** Render `attribution_label` into the transparency statement AND use it as claim-ID namespace prefix. ~5 lines of template + ~10 lines of script regex.
   - **C-CODEX-120:** Add `toolsets` to `_validate` for `hermes-chat` render mode. ~3 lines.
   - **C-CLAUDE-011:** Remove dead `_parse_top_level_key` function. ~17 lines deleted.
   - **C-CLAUDE-012:** Reconcile "four sections plus record" vs "five sections" wording between ADR-0016 and synthesis-template. ~3 lines.
   - **C-CODEX-103 / C-CODEX-117 / C-CODEX-126 (U3):** Revise PLAN-0016 to current four-contributor, per-contributor, render-mode-aware pilot. ~30 minutes of editing.
   - **C-DEVSTRAL-002:** Add `--mixed-contract-warning` flag to helper. ~15 lines.

3. **Schedule the medium-priority follow-ups for pilot-002:**
   - **C-CODEX-127 / C-CODEX-124 (U7):** Add a real JSON-schema contributor in pilot-002 to validate the JSON branch end-to-end.
   - **C-CLAUDE-010 (D2 sub-finding):** Document or unify the `contributor_position` → Coverage-code mapping.
   - **C-DEVSTRAL-005:** Add gate-overlap documentation to contributor prompt template.
   - **C-CLAUDE-002:** Add `docs/specifications/FS-0015-role-selection-and-session-modes.md` to next pilot's `input_sources` so Q1 verdict is verifiable against source.
   - **C-CODEX-131:** Add deterministic renderer tests for all three render modes, both contracts, missing files, malformed schemas, role-membership violations, missing Hermes toolsets, target filtering, gate overlap. (~50 lines of bats tests.)

4. **Run the gate evaluator (`deepseek-v4-pro` via `ollama-cloud`) in a fresh Hermes session** after operator review of this synthesis. The gate reads this synthesis + the four contributor briefs and emits one of: `PROCEED`, `CONDITIONAL`, `HALT`, plus an execution status (`COMPLETE` / `NOT_RUN` / `INVALID`). The synthesis does not pre-judge the verdict; that is the gate's call.

**Constraint check:**

- **ADR-0013 (proposed):** No conflict. The round-2 findings do not introduce a new role, session mode, or PR/commit flow.
- **FS-0014 (implemented):** Supported. The role-relationship enforcement (C-CODEX-125) strengthens FS-0014 conformance.
- **FS-0015 (implemented):** Supported. The transparency-statement docstring (C-CLAUDE-003, C-QWEN-001) strengthens FS-0015 explainability conformance.
- **ADR-0016 (proposed):** No conflict. The round-2 findings are refinements within the framework's stated boundaries.
- **PLAN-0016 (proposed):** Required to be revised per C-CODEX-126 before next pilot runs.

**Open questions:**

1. **Should `EVALUATOR_FAILED` (Qwen3) be added?** Operator's read: no — broaden `INVALID` instead. Defer to gate evaluator's actual output shape.
2. **Should per-contributor Coverage/Disposition fragments be required (Qwen3 C-QWEN-004) or kept synthesis-side (Codex C-CODEX-128)?** Operator's read: synthesis-side is lighter and consistent with operator-as-primary posture. Adopt Codex.
3. **Should `attribution_label` be the claim-ID namespace (Codex C-CODEX-130)?** Operator's read: yes — eliminates collision risk. Adopt.

**Attribution plan:**

This synthesis is operator-as-primary (Tai) reviewed; it was drafted by minimax-m3 as a sounding-board pass per the operator's 2026-06-25 direction.

Commit trailers for the round-2 acceptance PR:

```
Assisted-By: claude-sonnet-4
Assisted-By: codex
Assisted-By: hermes (qwen3-coder-next)
Assisted-By: hermes (devstral-2:123b)
Contributor-Session: <PR-comment URLs for each brief>
```

Note: the round-2 commit (`c0debd8`) used `Co-Authored-By: Claude Opus 4.8` in its trailer, which conflicts with ADR-0013's attribution rule requiring `Assisted-By:` and `Contributor-Session:` (and not `Co-Authored-By:`). This is a process gap in the round-2 PR. The follow-up PR should use the correct trailer format.

(The gate evaluator's session ID is recorded separately in the gate's own commit trailers when the follow-up PR is gated.)

---

## Attribution

| Role | Model | Attribution Label | Session | Brief File |
| --- | --- | --- | --- | --- |
| Reviewer (round 2) | claude-sonnet-4 | claude-contrib-1 | (round-2 PR #62 comment) | contrib-claude.md |
| Implementer (round 2) | codex | codex-contrib-1 | (round-2 PR #62 comment) | contrib-codex.md |
| Reviewer (round 1) | qwen3-coder-next | qwen3-contrib-1 | 20260625_012422_822f27 | contrib-qwen3.md |
| Implementer (round 1) | devstral-2:123b | devstral-contrib-1 | 20260625_012550_0af045 | contrib-devstral2.md |
| Synthesis operator (sounding-board) | minimax-m3 | synth-minimax-001 | (this session) | (this document) |
| Gate evaluator (separate session, pending) | deepseek-v4-pro | gate-deepseek-001 | (TBD) | (TBD) |
