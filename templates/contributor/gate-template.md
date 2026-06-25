<!--
REVIEWER_TEMPLATE:
- Role: Gate evaluator (independent of all contributors and the primary)
- Inputs: Contributor outputs, synthesis, applicable ADRs/FSs
- Output: Gate execution status (COMPLETE / NOT_RUN / INVALID) and, on COMPLETE,
  gate verdict (PROCEED / CONDITIONAL / HALT), at docs/orchestration/<task-id>-gate.md

PARSING_HINTS:
- Document type: gate-template
- The gate evaluator MUST be a model that did NOT participate as a contributor
  to this task. Self-evaluation is forbidden per ADR-0016. The helper script
  enforces this as a static check; the operator can override with
  --allow-gate-overlap when there is a specific reason.
- The gate has two layers: execution status (whether the gate ran successfully)
  and verdict (the gate's evaluation when status is COMPLETE). NOT_RUN and
  INVALID are NOT verdicts; they signal that no verdict was issued.
- Per PR #62 reviewer finding, separating execution status from verdict avoids
  stretching PROCEED / CONDITIONAL / HALT into states that are not actually
  verdicts (e.g., "evaluator unreachable" or "evaluator produced malformed
  output").
- CONDITIONAL is not "approve with notes" — it is "the synthesis has specific
  issues that must be resolved before commit; here is the list."
- HALT is for synthesis that violates an accepted ADR, papers over a
  divergence, or makes a recommendation that the gate cannot validate.
- The CONDITIONAL cycle is bounded: after two CONDITIONAL re-runs on the same
  task, the operator MUST escalate rather than continuing to revise. (Added
  2026-06-25 per PR #62 reviewer finding.)
-->

# Gate Template

The gate evaluator produces one verdict per task at:
`docs/orchestration/<task-id>-gate.md`

The gate evaluator is invoked per ADR-0016 §"Decision Outcome" §5. It is **independent** of the contributor set and the primary session — typically `deepseek-v4-pro` per the `action-framework-research` skill.

**Operational note:** The operator invokes the gate evaluator manually by pasting the rendered gate prompt into a `hermes chat -m <gate_model> --provider <gate_provider>` invocation (or any equivalent one-shot session on the gate model). The verdict is captured to `docs/orchestration/<task-id>-gate.md` by the operator. The helper script at `scripts/render_contributor_prompt.py` does not currently render gate prompts — a separate render step is fine for the gate, since it is invoked once per task rather than per contributor.

## Pre-run probe (mandatory)

Before invoking the gate evaluator, the operator (or primary session) must run the probe pattern from `action-framework-research`:

```bash
hermes chat -m deepseek-v4-pro --provider ollama-cloud \
  -q "Reply with: ok" -Q
```

If the probe fails (auth error, model not found, timeout), the gate cannot run. Set gate execution status to `NOT_RUN` and document the degraded state in the synthesis's Recommended Action.

## Gate independence (enforced)

The gate model must not appear in the contributor set for the same task. The helper script `scripts/render_contributor_prompt.py` enforces this as a static check at render time. To override, pass `--allow-gate-overlap` to the helper script and document the override reason in the synthesis's Recommended Action.

## The Gate Prompt (rendered)

```
# GATE EVALUATION REQUEST

You are evaluating the synthesis of a multi-model orchestration task.
You MUST be independent — you did not participate as a contributor.
The helper script enforces this; do not produce a verdict if you have
participated in the task in any other role.

Task ID: {task.id}
Task framing: {task.framing}

Contributor outputs to read:
- docs/orchestration/{task.id}/contrib-<attribution_label>.{md,json} (one per contributor)

Synthesis to evaluate:
- docs/orchestration/{task.id}-synthesis.md

Constraints to validate against:
- Accepted ADRs: [list]
- Approved FSs: [list]

# YOUR JOB

Evaluate the synthesis on these five axes. Do NOT redo the work — judge
what the operator produced.

1. Coverage record: Does the synthesis have a Coverage/Disposition Record
   that distinguishes addressed / silent (NOT_ASKED) / silent
   (ASKED_NO_RESPONSE) / out-of-scope / off-topic? Flag missing or
   collapsed categories.

2. Attribution fidelity: Does every claim in the synthesis trace to a
   specific contributor (by attribution_label) and a specific input
   source? Flag any orphan claims or claims missing the shared claim
   envelope fields.

3. Divergence preservation: Are divergent points preserved as divergences
   (each contributor's position attributed), or did the synthesis average
   them into a false consensus? Flag any silent averaging.

4. Constraint compliance: Does the synthesis's Recommended Action conflict
   with any of the listed Accepted ADRs or Approved FSs? Flag any conflict.

5. Synthesis coherence: Is the synthesis internally consistent? Does the
   Recommended Action follow from the Consensus / Divergent / Unique
   Insights sections? Do the Disposition Records in §1 match the body
   claims?

# EXECUTION STATUS AND VERDICT

Reply with EXACTLY ONE execution status. If status is COMPLETE, also
include a verdict.

STATUS: NOT_RUN
REASON: <one sentence explaining why the gate did not run, e.g. probe failure>

STATUS: INVALID
REASON: <one sentence explaining why the gate output is malformed, e.g. missing verdict>

STATUS: COMPLETE
VERDICT: PROCEED
REASON: <one sentence>

STATUS: COMPLETE
VERDICT: CONDITIONAL
REASON: <one sentence>
ISSUES:
- <specific issue 1 that must be resolved before commit>
- <specific issue 2>

STATUS: COMPLETE
VERDICT: HALT
REASON: <one sentence>
CONFLICTS:
- <specific ADR or FS that the synthesis violates>

PROCEED: synthesis is faithful, divergence preserved, no constraint conflicts,
Recommended Action follows from the analysis. Operator may approve and commit.

CONDITIONAL: synthesis is mostly faithful but has specific issues. The list
under ISSUES must be resolved before the primary commits. Resolving them is
the primary's job, not the gate's.

HALT: synthesis violates an accepted ADR or approved FS, papers over a
divergence in a way that hides disagreement, or makes a recommendation
that the gate cannot validate against the listed constraints. Operator
must intervene before any commit.
```

## How the verdict is recorded

The full gate prompt response is written to `docs/orchestration/<task-id>-gate.md`. The execution status and (if COMPLETE) the verdict's first three lines (`STATUS:`, `VERDICT:`, `REASON:` plus `ISSUES:` or `CONFLICTS:` if applicable) are extracted and posted as a PR comment by the operator.

**Decision flow:**

- If execution status is `NOT_RUN`: the operator notes the degraded state in the PR description and the synthesis's Recommended Action. The gate did not produce a verdict; operator judgment is the only check.
- If execution status is `INVALID`: the operator rejects the gate's response, re-runs with a different prompt or model, and treats the response as if status were `NOT_RUN` until a valid response is obtained.
- If execution status is `COMPLETE` and verdict is `HALT`: the operator MUST NOT commit. The operator decides: revise the synthesis, change the recommended action, or escalate the underlying disagreement.
- If execution status is `COMPLETE` and verdict is `CONDITIONAL`: the operator addresses each `ISSUES:` entry in the synthesis (or escalates if an issue cannot be resolved without changing the framing), then re-runs the gate.
  - **Bound on CONDITIONAL re-runs (added 2026-06-25):** after two CONDITIONAL re-runs on the same task, the operator MUST escalate rather than continuing to revise. Escalation options: (a) accept the synthesis with the unresolved CONDITIONAL issues explicitly noted as open questions; (b) halt and revise the task framing; (c) override and commit with an explicit operator note that the gate was not satisfied.
- If execution status is `COMPLETE` and verdict is `PROCEED`: the operator may commit (subject to operator approval per ADR-0013).

## What the gate MUST NOT do

- It MUST NOT propose a different recommended action. The gate validates; the primary decides.
- It MUST NOT smooth over constraint conflicts in order to issue PROCEED.
- It MUST NOT issue CONDITIONAL with vague issues ("consider being more thorough"); each issue must be specific enough for the primary to act on.
- It MUST NOT participate in the synthesis itself. If the gate evaluator's response contains new claims, recommendations, or synthesis content, the operator must reject the verdict and re-run with a different model.

## Failure modes

- **Probe fails (gate evaluator unreachable).** Set execution status to `NOT_RUN`. Operator must explicitly note this in the PR description. The gate is *additional* validation per ADR-0016, not a replacement for operator judgment.
- **Gate evaluator returns a status other than NOT_RUN / INVALID / COMPLETE.** Treat as `INVALID`; operator must reject the response and re-run with a fresh prompt.
- **Gate evaluator returns COMPLETE but a verdict other than PROCEED / CONDITIONAL / HALT.** Treat as `INVALID`; operator must reject and re-run.
- **Gate evaluator returns PROCEED but the synthesis has visible problems the operator can see.** Operator overrides. The gate is a check, not a permission slip.
- **Gate evaluator and primary disagree.** Operator decides. Both views are recorded in PR comments.
- **Two consecutive CONDITIONAL verdicts without convergence.** Operator MUST escalate per the bound rule above.