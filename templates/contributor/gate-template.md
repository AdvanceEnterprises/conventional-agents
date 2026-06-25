<!--
REVIEWER_TEMPLATE:
- Role: Gate evaluator (independent of all contributors and the primary)
- Inputs: Contributor outputs, synthesis, applicable ADRs/FSs
- Output: Gate verdict (PROCEED / CONDITIONAL / HALT) at
  docs/orchestration/<task-id>-gate.md

PARSING_HINTS:
- Document type: gate-template
- The gate evaluator MUST be a model that did NOT participate as a contributor
  to this task. Self-evaluation is forbidden per ADR-0016.
- The verdict is one of PROCEED / CONDITIONAL / HALT. Do not invent other
  categories.
- CONDITIONAL is not "approve with notes" — it is "the synthesis has
  specific issues that must be resolved before commit; here is the list."
- HALT is for synthesis that violates an accepted ADR, papers over a
  divergence, or makes a recommendation that the gate cannot validate.
-->

# Gate Template

The gate evaluator produces one verdict per task at:
`docs/orchestration/<task-id>-gate.md`

The gate evaluator is invoked per ADR-0016 §"Decision Outcome" §5. It is **independent** of the contributor set and the primary session — typically `deepseek-v4-pro` per the `action-framework-research` skill.

**Operational note:** Until Hermes Agent gains direct integration with vendor CLIs, the operator invokes the gate evaluator manually by pasting the rendered gate prompt into a `hermes chat -m deepseek-v4-pro --provider ollama-cloud` invocation (or any equivalent one-shot session on the gate model). The verdict is captured to `docs/orchestration/<task-id>-gate.md` by the operator. The helper script at `scripts/render_contributor_prompt.py` does not currently render gate prompts — a separate render step is fine for the gate, since it is invoked once per task rather than three times.

## Pre-run probe (mandatory)

Before invoking the gate evaluator, the operator (or primary session) must run the probe pattern from `action-framework-research`:

```bash
hermes chat -m deepseek-v4-pro --provider ollama-cloud \
  -q "Reply with: ok" -Q
```

If the probe fails (auth error, model not found, timeout), the gate cannot run. The pattern degrades to synthesis-only; the operator must explicitly note this in the PR description.

## The Gate Prompt (rendered)

```
# GATE EVALUATION REQUEST

You are evaluating the synthesis of a multi-model orchestration task.
You MUST be independent — you did not participate as a contributor.

Task ID: {task.id}
Task framing: {task.framing}

Contributor outputs to read:
- docs/orchestration/{task.id}/contrib-<label>.{md,json} (one per contributor)

Synthesis to evaluate:
- docs/orchestration/{task.id}-synthesis.md

Constraints to validate against:
- Accepted ADRs: [list]
- Approved FSs: [list]

# YOUR JOB

Evaluate the synthesis on these four axes. Do NOT redo the work — judge
what the primary produced.

1. Attribution fidelity: Does every claim in the synthesis trace to a
   specific contributor and a specific input source? Flag any orphan claims.

2. Divergence preservation: Are divergent points preserved as divergences
   (each contributor's position attributed), or did the synthesis average
   them into a false consensus? Flag any silent averaging.

3. Constraint compliance: Does the synthesis's Recommended Action conflict
   with any of the listed Accepted ADRs or Approved FSs? Flag any conflict.

4. Synthesis coherence: Is the synthesis internally consistent? Does the
   Recommended Action follow from the Consensus / Divergent / Unique
   Insights sections?

# VERDICT

Reply with EXACTLY ONE of the following verdicts, in this format:

VERDICT: PROCEED
REASON: <one sentence>

VERDICT: CONDITIONAL
REASON: <one sentence>
ISSUES:
- <specific issue 1 that must be resolved before commit>
- <specific issue 2>

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

The full gate prompt response is written to `docs/orchestration/<task-id>-gate.md`. The first three lines (`VERDICT:`, `REASON:`, `ISSUES:` or `CONFLICTS:`) are extracted and posted as a PR comment by the operator.

If the verdict is `HALT`, the primary session MUST NOT commit. The operator decides: revise the synthesis, change the recommended action, or escalate the underlying disagreement.

If the verdict is `CONDITIONAL`, the primary session addresses each `ISSUES:` entry in the synthesis (or escalates if an issue cannot be resolved without changing the framing), then re-runs the gate. The cycle repeats until `PROCEED` or until the operator overrides.

If the verdict is `PROCEED`, the primary session may commit (subject to operator approval per ADR-0013).

## What the gate MUST NOT do

- It MUST NOT propose a different recommended action. The gate validates; the primary decides.
- It MUST NOT smooth over constraint conflicts in order to issue PROCEED.
- It MUST NOT issue CONDITIONAL with vague issues ("consider being more thorough"); each issue must be specific enough for the primary to act on.
- It MUST NOT participate in the synthesis itself. If the gate evaluator's response contains new claims, recommendations, or synthesis content, the operator must reject the verdict and re-run with a different model.

## Failure modes

- **Probe fails (gate evaluator unreachable).** Pattern degrades to synthesis-only. Operator must explicitly note this in the PR description. The gate is *additional* validation per ADR-0016, not a replacement for operator judgment.
- **Gate evaluator returns a verdict other than PROCEED / CONDITIONAL / HALT.** Operator must reject the verdict and re-run with a fresh prompt.
- **Gate evaluator returns PROCEED but the synthesis has visible problems the operator can see.** Operator overrides. The gate is a check, not a permission slip.
- **Gate evaluator and primary disagree.** Operator decides. Both views are recorded in PR comments.
