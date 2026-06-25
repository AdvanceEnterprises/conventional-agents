---
type: change-plan
id: PLAN-0016
status: proposed
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
updated: 2026-06-24
---

<!--
PARSING_HINTS:

- This document is a change plan. It describes how to execute the pilot
  that validates ADR-0016 before ADR-0016 is accepted.

- The pilot is a prerequisite for ADR-0016 acceptance, not the
  implementation of ADR-0016.

- Do NOT start the pilot until ADR-0013 and ADR-0016 are at least
  proposed (they are); the operator must explicitly authorize the pilot
  in a PR review before Phase 1 begins.

-->

# PLAN-0016: Multi-model orchestration pilot

## Status

- Proposed

## Purpose

Validate ADR-0016's multi-model orchestration pattern (structured output + independent gate evaluator + document-driven coordination per ADR-0013) by running it end-to-end against a small, low-stakes task. The pilot's evidence is what unblocks acceptance of ADR-0013 and ADR-0016 — per ADR-0016 §"Validation," both ADRs stay `proposed` until a pilot run has happened.

**Operational note (2026-06-24):** Until Hermes Agent gains direct integration with vendor CLIs, the pilot is **operator-driven** rather than session-driven. The operator (Tai) is the primary — the operator renders the contributor prompts, pastes them into each CLI window, captures the outputs, writes the synthesis, runs the gate evaluator, and commits the result with `Assisted-By:` trailers. The templates and the helper script make this manual orchestration reproducible. When Hermes gains direct integration, the same pilot can be re-run with the operator's role automated; the templates are invariant under that shift.

## Pilot target (proposed)

**Task:** Review and revise the contributor prompt template (`templates/contributor/contributor-prompt.md`) itself, using the very pattern it describes. Self-referential but bounded — the artifact under review is small (one template, ~250 lines), the failure modes are obvious, and the operator can read the diff and judge synthesis quality without expert review.

**Why this task and not PR #73 (feral-fleet ADR-0004/0005/FS-0007):**

- PR #73 is already in the operator's hands; piling a multi-model review on top creates noise on a real artifact.
- The contributor prompt template is internal to conventional-agents; missteps are recoverable without external impact.
- The pilot is *about the orchestration pattern*, not about any specific governance decision. The task itself is a vehicle.
- Self-reference is acceptable for the pilot because the goal is to surface orchestration friction, not to validate the task.

The operator may swap the target for another small artifact before Phase 1 begins. The constraint is: **the pilot target must be small, low-stakes, and the operator must be willing to discard the result if the orchestration fails.**

## Roles and session mode

Per FS-0015 §"Architecture Planning" mode, with `Document Author` supporting:

- **Primary:** the operator (Tai). Writes the synthesis, runs the gate, commits the result.
- **Contributors:** the three CLI sessions (Claude, Codex, Gemini). Each produces an output in the contracted format and posts it as a PR comment.
- **Gate evaluator:** `deepseek-v4-pro`, invoked by the operator via `hermes chat -m deepseek-v4-pro --provider ollama-cloud` (one-shot session, file-aware).
- **Session mode:** Architecture Planning.

Per FS-0014 §"Role 0 — Head Architect": *"Conduct periodic framework health audits... identify when existing roles, gates, or workflows are creating friction or drift and propose corrective ADRs or FS specs."* The operator fills this role in the current operational mode; when Hermes gains direct integration, a primary session may fill it instead.

## Contributors

- **Claude Code** (contributor, Architect perspective). Fills Head Architect supporting role. Output: Research Brief format (`action-framework-research`).
- **Codex** (contributor, Implementer perspective). Fills Document Author supporting role. Output: JSON schema (machine-parseable suggested edits).
- **Gemini** (contributor, Research perspective). Fills Reviewer-style contributor. Output: Research Brief format. Invoked via the `action-framework-research` skill's `hermes chat` pattern.
- **deepseek-v4-pro** (gate evaluator). Independent of all three. Invoked via `hermes chat -m deepseek-v4-pro --provider ollama-cloud` per ADR-0016 §"Decision Outcome" §5. Verdict is `PROCEED` / `CONDITIONAL` / `HALT`.

## Phase plan

### Phase 0 — Pre-flight (operator)

- [ ] Confirm ADR-0013 and ADR-0016 are at `proposed`. (They are.)
- [ ] Confirm pilot target and task framing. Lock the artifact path: `templates/contributor/contributor-prompt.md`.
- [ ] Open a PR titled `chore: pilot multi-model orchestration (ADR-0016 validation)` with this plan as the PR body. Branch: `pilot/multi-model-001`.
- [ ] Confirm worktree convention: `git worktree add -b pilot/multi-model-001 /tmp/pilot-multi-model-001 main`.

### Phase 1 — Pre-run probe (operator)

- [ ] Probe each model is reachable:
  - `claude --version` (Claude Code CLI)
  - `codex --version` (Codex CLI; requires PTY per `codex` skill)
  - `hermes chat -m gemini-2.5-pro --provider <gemini-provider> -q "Reply with: ok" -Q`
  - `hermes chat -m deepseek-v4-pro --provider ollama-cloud -q "Reply with: ok" -Q`
- [ ] If any probe fails, the pilot degrades: that contributor's slot is skipped and the failure is recorded in the PR description. The pilot still runs with the remaining contributors.

### Phase 2 — Contributor prompts (operator)

- [ ] Fill in `docs/orchestration/multi-model-pilot-001.yaml` with the parameters from `templates/contributor/contributor-prompt.md` §"Parameters":
  - `task.id`: `multi-model-pilot-001`
  - `task.framing`: "Review and propose revisions to `templates/contributor/contributor-prompt.md`. Output must be in the contracted format. Focus on: (a) whether the transparency statement captures FS-0015 correctly, (b) whether the structured-output contract selection is unambiguous, (c) whether the guardrails prevent the contributor from doing things ADR-0013 forbids."
  - `session.mode`: `Architecture Planning`
  - `session.primary_role`: `Head Architect`
  - `session.contributor_role`: varies per contributor (Head Architect supporting / Document Author supporting / Reviewer supporting)
  - `structured_output.contract`: `research_brief` for Claude and Gemini; `json_schema` for Codex (schema: `templates/contributor/contributor-review.schema.json` — to be created during this phase)
  - `guardrails.must_not_modify`: list of governed artifacts the contributors cannot touch
  - `attribution_trailers`: per contributor
- [ ] Create `templates/contributor/contributor-review.schema.json` (the JSON schema Codex will output against). This is itself a small artifact and is committed in the pilot PR.

### Phase 3 — Run contributors (operator)

Each contributor runs in a separate worktree or one-shot session:

- **Claude Code:** `claude -p "<rendered prompt>" --output-format json --allowedTools "Read,WebSearch,WebFetch" --worktree .claude/worktrees/contrib-pilot-001 --max-turns 1 > /tmp/contrib-claude-pilot.json`
- **Codex:** `codex exec --full-auto --output-schema templates/contributor/contributor-review.schema.json "<rendered prompt>"` from the worktree at `/tmp/contrib-pilot-001-codex`.
- **Gemini:** `hermes chat -m gemini-2.5-pro --provider <gemini-provider> --toolsets file -q "<rendered prompt without FS-0015 transparency block>" -Q > /tmp/contrib-gemini-pilot.md`

Output captured to:
- `docs/orchestration/multi-model-pilot-001/contrib-claude.json`
- `docs/orchestration/multi-model-pilot-001/contrib-codex.json`
- `docs/orchestration/multi-model-pilot-001/contrib-gemini.md`

Each contributor's full output is posted as a PR comment on the pilot branch (mandatory per ADR-0013 attribution rule).

### Phase 4 — Synthesis (operator as primary)

The operator reads all three contributor outputs and produces:
- `docs/orchestration/multi-model-pilot-001-synthesis.md` following `templates/contributor/synthesis-template.md`.

The operator may use any of the three CLIs (or all three) as sounding-boards while drafting the synthesis, but the synthesis itself is the operator's artifact. If synthesis reveals a divergence that the operator cannot resolve, the operator stops and posts an escalation comment rather than averaging.

### Phase 5 — Gate evaluation (independent)

- [ ] Pre-run probe (re-check `deepseek-v4-pro` is reachable).
- [ ] Invoke gate by pasting the rendered gate prompt (from `templates/contributor/gate-template.md`) into a `hermes chat -m deepseek-v4-pro --provider ollama-cloud --toolsets file -q "<rendered gate prompt>" -Q` invocation. Capture stdout.
- [ ] Save gate verdict to `docs/orchestration/multi-model-pilot-001-gate.md`.
- [ ] Post the verdict (first three lines) as a PR comment.

### Phase 6 — Operator review

- [ ] Operator reads synthesis, gate verdict, and all three contributor outputs.
- [ ] Operator decides: accept synthesis as-is, send back for revision, or override.
- [ ] If accepted: operator proceeds to Phase 7.
- [ ] If `HALT`: the pilot does not commit. The orchestration failure is documented in the PR description and used as input to revise ADR-0016 before another pilot run.

### Phase 7 — Commit and PR

- [ ] Operator applies any template revisions per the synthesis.
- [ ] Operator commits with trailers:
  ```
  Assisted-By: claude-sonnet-4, codex, gemini-2.5-pro
  Contributor-Session: <session IDs or PR-comment URLs>
  ```
  (Per ADR-0013 attribution rule. The operator is the committer; the contributors' sessions are referenced via PR-comment URLs.)
- [ ] PR description summarizes the pilot run (phases 0-6 outcomes, gate verdict, what worked, what didn't).
- [ ] Operator reviews the PR. If accepted, the pilot run is the evidence that unblocks acceptance of ADR-0013 and ADR-0016.

### Phase 8 — Post-pilot revision

- [ ] Open a follow-up PR that revises ADR-0013 and ADR-0016 based on the pilot's findings. Specific things to evaluate:
  - Did the contributor prompt template work as designed? If not, which parameters were unclear?
  - Did the synthesis template's section structure (Consensus / Divergent / Unique / Recommended) actually help, or did the primary fight it?
  - Did the gate evaluator's PROCEED / CONDITIONAL / HALT verdicts align with the operator's read?
  - Did ADR-0013's attribution rules hold up? Did any contributor accidentally commit to the primary's branch?
  - Did any contributor's output get silently dropped (i.e., the synthesis ignored it without explanation)?
- [ ] The follow-up PR either accepts ADR-0013 and ADR-0016 as drafted, or revises them with evidence from the pilot.

## Success criteria

The pilot is successful if:

1. **End-to-end execution.** All seven phases complete. Each phase produces a durable artifact.
2. **ADR-0013 compliance.** No contributor commits to the primary's branch. No contributor opens a PR on behalf of the task. No contributor transitions a governed document's status. Each contributor's PR comment includes the FS-0015 transparency statement.
3. **Structured output comparability.** Each contributor's output is in the contracted format (Research Brief markdown or JSON document). The primary synthesis can mechanically extract claims because the format is consistent.
4. **Gate evaluator reachability.** `deepseek-v4-pro` responds to the probe. Gate verdict is in the expected `PROCEED` / `CONDITIONAL` / `HALT` format.
5. **Synthesis faithfulness.** The synthesis preserves divergence (does not silently average). The synthesis's Recommended Action is consistent with the consensus/divergent/unique sections.
6. **Attribution integrity.** Final commit carries `Assisted-By:` and `Contributor-Session:` trailers identifying each contributor.

The pilot is **degraded-but-acceptable** if:

- One contributor is unreachable (probe fails). Pilot runs with the remaining two. The unreachability is documented in the PR description.
- Gate evaluator is unreachable. Pilot runs in synthesis-only mode. Operator explicitly approves the synthesis without gate validation.

The pilot **fails** if:

- A contributor commits to the primary's branch (ADR-0013 violation).
- A contributor transitions a governed document's status (ADR-0013 violation).
- The synthesis averages a divergence without flagging it.
- The final commit lacks attribution trailers.

A failed pilot is not a framework failure — it is data. The follow-up revision uses the failure modes to revise ADR-0013 and ADR-0016 before another pilot run.

## What this plan does NOT do

- It does not accept ADR-0013 or ADR-0016. Acceptance happens after the pilot produces evidence.
- It does not run multiple iterations of the pilot. One pilot run, one revision PR, then operator decision.
- It does not validate the templates against external projects (e.g., feral-fleet). That's out of scope for this plan.
- It does not commit the synthesis or gate verdict to trunk without operator approval. The pilot PR stays in draft until Phase 7 is reviewed.

## Pitfalls

- **Do not skip the pre-run probes.** They are cheap; a mid-pilot model failure mid-synthesis is expensive.
- **Do not let the primary session commit before the operator reviews.** ADR-0013 attribution only works if the operator remains the merge gate.
- **Do not average divergence to make the synthesis "look unified."** Preserved divergence is the value of multi-model work; collapsing it is the failure mode.
- **Do not reuse the pilot PR for unrelated work.** Keep it small. If the pilot surfaces a real framework issue, that's a follow-up PR.
- **Do not declare the pilot successful without all six success criteria met.** Degraded-but-acceptable is honest; "mostly worked" is not.

## Links

- ADR-0013: Multi-model session coordination model (proposed)
- ADR-0016: Multi-model session orchestration with structured output and gate evaluation (proposed)
- FS-0014: Role definitions overhaul (implemented)
- FS-0015: Role selection and session modes (implemented)
- `templates/contributor/contributor-prompt.md` (new, defined by ADR-0016)
- `templates/contributor/synthesis-template.md` (new, defined by ADR-0016)
- `templates/contributor/gate-template.md` (new, defined by ADR-0016)
- `action-framework-research` skill (Research Brief format + `deepseek-v4-pro` evaluator pattern)
- `claude-code` skill (Claude Code CLI invocation)
- `codex` skill (Codex CLI invocation)
