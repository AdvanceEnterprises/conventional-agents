---
type: change-plan
id: PLAN-0016
status: approved
title: Multi-model orchestration pilot (validate ADR-0016 end-to-end)
related_specs: []
related_adrs:
  - ADR-0013
  - ADR-0016
supersedes: []
superseded_by: null
tags:
  - orchestration
  - pilot
  - multi-model
created: 2026-06-24
updated: 2026-06-25
---

<!--
PARSING_HINTS:

- This document is a change plan. It describes how to execute the pilot
  that validates ADR-0016 before ADR-0016 is accepted.

- The pilot is a prerequisite for ADR-0016 acceptance, not the
  implementation of ADR-0016.

- The original 2026-06-24 version of this plan was materially stale
  relative to the actual pilot run (PR #62). It referenced Gemini
  as a contributor (which was dropped), used task-level contract
  selection (which became per-contributor), used a single
  `session.contributor_role` field (which became `supporting_roles`
  + `active_contributor_role`), and used a three-contributor shape
  (which became four-contributor). The 2026-06-25 update reflects
  the actual pilot that ran.

- This plan was updated 2026-06-25 to reflect the as-run pilot
  sequence. Future pilots should follow this version, not the
  original. Phase numbers match the original where possible.
-->

# PLAN-0016: Multi-model orchestration pilot (revised 2026-06-25)

## Status

- Approved (revised 2026-06-25). Original 2026-06-24 version was materially stale relative to the actual pilot that ran. This version reflects the as-run pilot sequence (four contributors, per-contributor parameters, two render modes, three gate cycles ending in PROCEED).

## Purpose

Validate ADR-0016's multi-model orchestration pattern (structured output + independent gate evaluator + document-driven coordination per ADR-0013) by running it end-to-end against a small, low-stakes task. The pilot's evidence is what unblocks acceptance of ADR-0013 and ADR-0016 — per ADR-0016 §"Validation," both ADRs stay `proposed` until a pilot run has happened.

**Operational note (2026-06-25):** Until Hermes Agent gains direct integration with vendor CLIs, the pilot is **operator-driven** rather than session-driven. The operator (Tai) is the primary — the operator renders the contributor prompts, pastes them into each CLI window or invokes them via `hermes chat`, captures the outputs, writes the synthesis, runs the gate evaluator, and commits the result with `Assisted-By:` trailers. The templates and the helper script make this manual orchestration reproducible. When Hermes gains direct integration, the same pilot can be re-run with the operator's role automated; the templates are invariant under that shift.

**Host note (2026-06-24):** As of this writing, the MacBook Neo (the host where the three external CLIs — Claude Code, Codex CLI — physically run) has been renamed at the macOS level from `hermes` to `gaia` (per feral-fleet ADR-0004, the rename was held-pending and has now been executed manually). Any references in this pilot to the host should use `gaia`, not `hermes`. The Hermes *agent persona* is unaffected by the rename and continues to be referred to as `hermes` regardless of which p-host it runs on. For Tailscale / MagicDNS resolution, the MacBook is reachable as `gaia.local` (mDNS) or `gaia.<tailnet-name>.ts.net` (MagicDNS), not `hermes.local`. SSH / git access from olympus-01 should use `gaia.tailnet.ts.net` (or its tailnet IP) per ADR-0004.

## Pilot target (as-run)

**Task:** Review the proposed multi-model orchestration pattern (ADR-0016, PLAN-0016, the three contributor templates — `contributor-prompt.md`, `synthesis-template.md`, `gate-template.md` — and the helper script `scripts/render_contributor_prompt.py`) from each contributor's role perspective. The artifact under review is internal to conventional-agents; missteps are recoverable without external impact.

**Why this task:** The pilot is *about the orchestration pattern*, not about any specific governance decision. The task itself is a vehicle. Self-reference is acceptable for the pilot because the goal is to surface orchestration friction, not to validate the task.

## Roles and session mode

Per FS-0015 §"Architecture Planning" mode, with `Document Author` supporting:

- **Primary:** the operator (Tai). Writes the synthesis, runs the gate, commits the result.
- **Contributors:** four sessions, two render modes (see below).
- **Gate evaluator:** `deepseek-v4-pro` via `ollama-cloud`. Independent of all four contributors. Invoked via `hermes chat -m deepseek-v4-pro --provider ollama-cloud --toolsets file,web -Q` (one-shot session, file-aware). Verdict is `PROCEED` / `CONDITIONAL` / `HALT`; execution status is `COMPLETE` / `NOT_RUN` / `INVALID`.

Per FS-0014 §"Role 0 — Head Architect": *"Conduct periodic framework health audits... identify when existing roles, gates, or workflows are creating friction or drift and propose corrective ADRs or FS specs."* The operator fills this role in the current operational mode; when Hermes gains direct integration, a primary session may fill it instead.

## Contributors (as-run)

Four contributors in two render modes:

- **Claude Code** (`render_mode: external-cli`, attribution label `claude-contrib-1`). Model: `claude-sonnet-4`. Role: Reviewer supporting. Contract: research_brief. Invoked by pasting the rendered prompt into Claude Code on `gaia`. Output: `contrib-claude.md`.
- **Codex** (`render_mode: external-cli`, attribution label `codex-contrib-1`). Model: `codex`. Role: Implementer supporting. Contract: research_brief (the as-run pilot used the same contract for all four contributors; pilot-002 should add a JSON-schema contributor per the synthesis's U7 follow-up). Invoked by pasting the rendered prompt into Codex CLI on `gaia`. Output: `contrib-codex.md`.
- **Qwen3-Coder-Next** (`render_mode: hermes-chat`, attribution label `qwen3-contrib-1`). Model: `qwen3-coder-next` via `ollama-cloud`. Role: Reviewer supporting. Contract: research_brief. Invoked via `hermes chat -m qwen3-coder-next --provider ollama-cloud --toolsets file,web -Q -q "<rendered prompt>"`. Output: `contrib-qwen3.md`.
- **Devstral-2:123b** (`render_mode: hermes-chat`, attribution label `devstral-contrib-1`). Model: `devstral-2:123b` via `ollama-cloud`. Role: Implementer supporting. Contract: research_brief. Invoked via `hermes chat -m devstral-2:123b --provider ollama-cloud --toolsets file,web -Q -q "<rendered prompt>"`. Output: `contrib-devstral2.md`.

**Note on Gemini:** The original 2026-06-24 plan included Gemini as a third contributor in a `research-pass` render mode. Gemini was dropped from the as-run pilot for two reasons: (a) the `research-pass` render mode was reserved for advisory-only input and didn't fit the gate-evaluator pattern (a research-pass output is not accountable per ADR-0013's Mode 2 rules); (b) focusing the pilot on four accountable contributors (rather than three accountable + one advisory) produced a cleaner attribution and gate trace.

**Per-contributor parameters (replaces task-level contract selection):** Each contributor carries its own `model`, `render_mode`, `role`, `contract`, `provider` (for hermes-chat), `toolsets` (for hermes-chat), `attribution_label`, `active_contributor_role`, `supporting_roles`, `structured_output` block, and `guardrails` block. The parameter file is `docs/orchestration/multi-model-pilot-001/multi-model-pilot-001.yaml`. The helper script renders the prompt per contributor.

## Phase plan (as-run)

### Phase 0 — Pre-flight (operator)

- [x] Confirm ADR-0013 and ADR-0016 are at least `proposed`. (They are.)
- [x] Confirm pilot target and task framing. Lock the artifact path: `docs/decisions/ADR-0016.md` plus the three contributor templates plus the helper script.
- [x] Open a PR titled `feat(orchestration): ADR-0016 + PLAN-0016 + multi-model pilot foundation` with this plan as the PR body. Branch: `feature/multi-model-orchestration-foundation`.
- [x] Render and review the contributor prompts.

### Phase 1 — Pre-run probe (operator)

- [x] Probe each model is reachable:
  - `claude --version` (Claude Code CLI on `gaia`)
  - `codex --version` (Codex CLI on `gaia`; requires PTY per `codex` skill)
  - `hermes chat -m qwen3-coder-next --provider ollama-cloud -q "Reply with: pong" -Q`
  - `hermes chat -m devstral-2:123b --provider ollama-cloud -q "Reply with: ack" -Q`
  - `hermes chat -m deepseek-v4-pro --provider ollama-cloud -q "Reply with: ok" -Q`
- [x] All probes pass; no degraded-but-acceptable mode triggered.

### Phase 2 — Contributor prompts (operator)

- [x] Fill in `docs/orchestration/multi-model-pilot-001/multi-model-pilot-001.yaml` with the parameters from `templates/contributor/contributor-prompt.md` §"Parameters":
  - `task.id`: `multi-model-pilot-001`
  - `task.framing`: "Review the proposed multi-model orchestration pattern (ADR-0016, PLAN-0016, the three contributor templates, and the helper script) from your [role] vantage point..."
  - `task.branch`: `feature/multi-model-orchestration-foundation`
  - `contributors`: list of four contributor entries with per-contributor parameters
  - `gate.model`: `deepseek-v4-pro`
  - `gate.verdict_options`: `[PROCEED, CONDITIONAL, HALT]`
  - `gate.allow_overlap`: `false`
- [x] Render the prompts using `python3 scripts/render_contributor_prompt.py --params docs/orchestration/multi-model-pilot-001/multi-model-pilot-001.yaml --output /tmp/pilot-render.md`.

### Phase 3 — Run contributors (operator)

- [x] **Claude Code:** paste the rendered prompt into Claude Code on `gaia`. Output: `docs/orchestration/multi-model-pilot-001/contrib-claude.md`. (Round 1: 110 lines. Round 2: 12 claims, 87 lines.)
- [x] **Codex:** paste the rendered prompt into Codex CLI on `gaia`. Output: `docs/orchestration/multi-model-pilot-001/contrib-codex.md`. (Round 1: 59 lines. Round 2: 31 claims, 133 lines.)
- [x] **Qwen3-Coder-Next:** invoke via `hermes chat -m qwen3-coder-next --provider ollama-cloud -t file,web -Q -q "<rendered prompt>"`. Output: `docs/orchestration/multi-model-pilot-001/contrib-qwen3.md` (170 lines, 5 claims).
- [x] **Devstral-2:123b:** invoke via `hermes chat -m devstral-2:123b --provider ollama-cloud -t file,web -Q -q "<rendered prompt>"`. Output: `docs/orchestration/multi-model-pilot-001/contrib-devstral2.md` (132 lines, 6 claims).

Each contributor's full output is posted as a PR comment on the pilot branch (mandatory per ADR-0013 attribution rule). All four were posted.

### Phase 4 — Synthesis (operator as primary)

- [x] The operator reads all four contributor outputs and produces `docs/orchestration/multi-model-pilot-001/multi-model-pilot-001-synthesis.md` following `templates/contributor/synthesis-template.md`.

The operator used `minimax-m3` (this Hermes session) as a sounding-board while drafting the synthesis. The synthesis itself is the operator's artifact (carries the operator's review stamp on the second revision).

### Phase 5 — Gate evaluation (independent)

- [x] Pre-run probe (re-check `deepseek-v4-pro` is reachable).
- [x] Invoke gate by pasting the rendered gate prompt (from `templates/contributor/gate-template.md`) into a `hermes chat -m deepseek-v4-pro --provider ollama-cloud --toolsets file,web -Q -q "<rendered gate prompt>"` invocation. Capture stdout.
- [x] Round-1 gate verdict: `docs/orchestration/multi-model-pilot-001-gate.md` — STATUS: COMPLETE, VERDICT: CONDITIONAL (3 issues).
- [x] Round-2 gate verdict: `docs/orchestration/multi-model-pilot-001-gate-r2.md` — STATUS: COMPLETE, VERDICT: CONDITIONAL (2 issues, surfaced after round-1 fixes).
- [x] Round-3 gate verdict: `docs/orchestration/multi-model-pilot-001-gate-r3.md` — STATUS: COMPLETE, VERDICT: **PROCEED**.

### Phase 6 — Operator review and revision

- [x] Round 1 → CONDITIONAL (3 issues). Operator edits synthesis: coverage vocabulary note, Disposition Record envelope expansion (Position, Confidence, Source brief columns), operator review stamp. Commit `5d4c3d3`.
- [x] Round 2 → CONDITIONAL (2 issues). Operator edits synthesis: C-CODEX-104 added to DR, C-CODEX-110 added to Recommended Action. Commit `b8d75b6`.
- [x] Round 3 → PROCEED. Synthesis is gate-clear.

### Phase 7 — Commit, PR, and ADR acceptance

- [x] Operator commits the synthesis, gate outputs, and ADR acceptance transitions.
- [x] Commit `9471212` flips ADR-0013 and ADR-0016 from `proposed` to `accepted` with substantive Status sections citing the pilot evidence.
- [x] PR description summarizes the pilot run (phases 0-6 outcomes, three gate cycles, what worked, what didn't).

### Phase 8 — Post-pilot refinement (separate PR)

- [ ] Open the refinement PR `docs/adr/0016/round2-acceptance` containing the 11 high-priority follow-up items from the synthesis's Recommended Action:
  1. Add explicit claim-envelope section to `references/research-brief-template.md`
  2. Expand Disposition Record to include every received claim and preserve envelope fields
  3. Add explicit missing-input rule to `gate-template.md`; remove `NOT_RUN` from model's reply menu
  4. Make role relationships mandatory in `_validate` (C-CODEX-101, -108, -125)
  5. Render `attribution_label` into transparency statement; use as claim-ID namespace
  6. Add `toolsets` to `_validate` for hermes-chat (already done in pilot series)
  7. Remove dead `_parse_top_level_key` (already done in pilot series)
  8. Reconcile section count wording between ADR-0016 and synthesis-template (already done in pilot series)
  9. Revise PLAN-0016 to current four-contributor state (this revision)
  10. Add `--mixed-contract-warning` flag to helper
  11. Replace basic JSON-schema inspection with `jsonschema` library validation
- [ ] Pilot-002 (future): add a real JSON-schema contributor contract; add `docs/specifications/FS-0015-role-selection-and-session-modes.md` to `input_sources` so Q1 verdict is verifiable against source; add deterministic renderer tests (C-CODEX-131).

## Success criteria

The pilot is successful if:

1. **End-to-end execution.** All seven phases complete. Each phase produces a durable artifact. **Met.**
2. **ADR-0013 compliance.** No contributor commits to the primary's branch. No contributor opens a PR on behalf of the task. No contributor transitions a governed document's status. Each contributor's PR comment includes the FS-0015 transparency statement. **Met.**
3. **Structured output comparability.** Each contributor's output is in the contracted format (Research Brief markdown). The primary synthesis mechanically extracted claims via the shared claim envelope (claim_id, statement, source_citation, contributor_position, confidence). **Met.**
4. **Gate evaluator reachability.** `deepseek-v4-pro` responds to the probe. Gate verdict is in the expected `PROCEED` / `CONDITIONAL` / `HALT` format; execution status is correctly distinguished from verdict. **Met.**
5. **Synthesis faithfulness.** The synthesis preserves divergence (does not silently average). The synthesis's Recommended Action is consistent with the consensus/divergent/unique sections. **Met after round-2 fix.**
6. **Attribution integrity.** Final commit carries `Assisted-By:` and `Contributor-Session:` trailers identifying each contributor. **Met for the as-run pilot. Process note:** the round-2 contributor commit (`c0debd8`) used `Co-Authored-By: Claude Opus 4.8` in its trailer, which conflicts with ADR-0013's `Assisted-By:` convention. This was a process inconsistency from that PR; future contributor sessions use the correct format.

The pilot is **degraded-but-acceptable** if:

- One contributor is unreachable (probe fails). Pilot runs with the remaining contributors. The unreachability is documented in the PR description.
- Gate evaluator is unreachable. Pilot runs in synthesis-only mode. Operator explicitly approves the synthesis without gate validation.

The pilot **fails** if:

- A contributor commits to the primary's branch (ADR-0013 violation).
- A contributor transitions a governed document's status (ADR-0013 violation).
- The synthesis averages a divergence without flagging it.
- The final commit lacks attribution trailers.

The as-run pilot did not enter any failure mode.

## What this plan does NOT do

- It does not run multiple iterations of the pilot beyond what was needed for gate convergence. One pilot run with three gate cycles is sufficient for the pilot's purpose; further iterations are not part of this plan.
- It does not validate the templates against external projects (e.g., feral-fleet). That's out of scope for this plan.
- It does not commit the synthesis or gate verdict to trunk without operator approval. The pilot PR stays in draft until Phase 7 is reviewed.

## Pitfalls

- **Do not skip the pre-run probes.** They are cheap; a mid-pilot model failure mid-synthesis is expensive.
- **Do not let the primary session commit before the operator reviews.** ADR-0013 attribution only works if the operator remains the merge gate.
- **Do not average divergence to make the synthesis "look unified."** Preserved divergence is the value of multi-model work; collapsing it is the failure mode.
- **Do not reuse the pilot PR for unrelated work.** Keep it small. If the pilot surfaces a real framework issue, that's a follow-up PR.
- **Do not let CONDITIONAL gate verdicts accumulate without resolution.** The framework's two-rerun bound on CONDITIONAL cycles is a hard limit; if a third CONDITIONAL appears, the operator must escalate rather than revise.
- **Do not use `Co-Authored-By:` in commit trailers.** ADR-0013 requires `Assisted-By:` and `Contributor-Session:` trailers. Round-2 pilot commit `c0debd8` violated this; future commits must use the correct format.

## Links

- ADR-0013: Multi-model session coordination model (accepted 2026-06-25)
- ADR-0016: Multi-model session orchestration with structured output and gate evaluation (accepted 2026-06-25)
- FS-0014: Role definitions overhaul (implemented)
- FS-0015: Role selection and session modes (implemented)
- `templates/contributor/contributor-prompt.md` (defined by ADR-0016)
- `templates/contributor/synthesis-template.md` (defined by ADR-0016)
- `templates/contributor/gate-template.md` (defined by ADR-0016)
- `scripts/render_contributor_prompt.py` (defined by ADR-0016)
- `references/research-brief-template.md` (canonical Research Brief format)
- `docs/orchestration/multi-model-pilot-001/` (pilot artifacts: contributor briefs, synthesis, three gate cycles)
- `action-framework-research` skill (Research Brief format + `deepseek-v4-pro` evaluator pattern)
- `claude-code` skill (Claude Code CLI invocation)
- `codex` skill (Codex CLI invocation, including worktree batch mode)
- PR #62: the pilot PR
