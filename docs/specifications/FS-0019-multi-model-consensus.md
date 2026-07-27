---
type: feature-spec
id: FS-0019
status: draft
title: Multi-model consensus at workflow gates (optional consumer feature)
owner: ajoeofalltrades
test_required: true
interfaces:
  - "docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md"
  - "guidelines/ROLE_CONTRACT.md"
  - "workflows/document-lifecycle.md"
  - "skills/git-gh-workflow/SKILL.md"
  - "config/consensus.yml (project-level configuration, opt-in)"
  - "docs/consensus/<FS-or-PLAN-id>/<gate>-<timestamp>.yml (consensus round artifact)"
  - "docs/specifications/README.md"
related_adrs:
  - ADR-0018
supersedes: []
requires:
  - FS-0018
tags: [consensus, multi-model, workflow-gates, optional-feature]
created: 2026-07-27
updated: 2026-07-27
---

<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->

# Feature Spec: Multi-Model Consensus at Workflow Gates (Optional Consumer Feature)

## Status

- Draft

## Plan Status

- **Drafted as PLAN-0019** (`status: draft`), as part of the PR #71
  bootstrap package. This is a deliberate, one-time departure from
  the usual ordering in `workflows/document-lifecycle.md`, where
  PLANs are drafted after the FS is approved.
- Requires FS-0018 to be approved first, since the consensus gates
  integrate with the Issue lifecycle defined there. PLAN-0019 cannot
  be approved until both FS-0019 and FS-0018 are approved; its
  Readiness Check records both dependencies.
- Open questions blocking PLAN drafting are listed in the
  "Open Questions" section below.

## Summary

Define how a consumer repo opts into multi-model consensus at the
gates defined in FS-0018, including how to declare consensus on a
project or per-document, what a consensus round produces, what
agreement thresholds apply, and what happens on disagreement.

This is an **optional, consumer-implemented feature**. The framework
*represents* consensus (vocabulary, artifact shape, gate placement,
failure modes) but does not implement the orchestration. Consumer
repos that opt in implement their own consensus machinery and
configure it via project-level config.

**Default**: consensus is **disabled** at the framework level. The
framework's own evolution does not use consensus. Consumer repos
opt in explicitly.

## Goals

- Define the vocabulary and artifact shape for multi-model consensus
  in a consumer repo.
- Define the gates at which consensus applies (draft submission and
  review per the framework's lifecycle).
- Define the different-models requirement: a consensus round must
  invoke at least two *different* models with independent state;
  same-model-with-same-prompt is theater and is forbidden.
- Define the agreement-threshold semantics (default 2-of-2
  unanimous; configurable per consumer).
- Define the failure modes (hard block, soft flag, escalation) and
  how a consumer repo chooses between them.
- Define the role stance for consensus rounds.
- Define the audit trail for consensus rounds (per ADR-0018's
  three-layer convention).
- Make consensus opt-in at the framework level (default false) and
  consumer-implementable.

## Non-Goals

- Implementing consensus orchestration. The framework describes the
  required behavior; consumer repos implement the orchestration
  themselves (e.g., as a webhook handler that calls multiple model
  APIs, compares outputs, and posts results).
- Mandating consensus for the framework's own evolution. The
  framework does not require consensus on its own ADRs, FSs, or
  PLANs. This is a consumer-feature.
- Defining a specific consensus algorithm (e.g., majority vote,
  weighted vote, judge model). The framework describes
  behavior-shape, not algorithms.
- Cross-repo consensus. Each consumer repo runs its own consensus
  configuration.
- Token-cost or latency optimization. Consumer repos may optimize
  their consensus rounds for these concerns; the framework
  prescribes correctness, not efficiency.

## Users / Stakeholders

- **Joey Clark** (`ajoeofalltrades`) — plans to implement consensus
  in multiple consumer repos. Needs a clear, implementable
  contract.
- **Hermes Agent** — will be one of the consensus participants in
  consumer repos that opt in. Needs to know when consensus rounds
  apply and what role stance to assume during them.
- **Future consumer-repo maintainers** — will read this spec to
  decide whether to opt in and how to configure their consensus
  machinery.

## Consensus Vocabulary

- **consensus round**: a single execution of the consensus protocol,
  in which N different models are invoked with the same input and
  their outputs are compared.
- **participant**: a single model invocation in a consensus round.
  Each participant must be a *different* model with *independent*
  state (no shared prompt cache, no shared conversation context).
- **agreement**: semantic agreement between participants' outputs,
  not lexical match. "Same conclusion in different words" is
  agreement; "different conclusions in similar words" is not.
- **threshold**: the minimum number of participants that must agree
  for the round to pass. Default: 2-of-2 (unanimous).
- **gate**: a workflow point at which a consensus round runs.
  Defined per consumer; the framework recommends two gates (see
  below).
- **artifact**: the persisted output of a consensus round, including
  each participant's output, the agreement check, and the verdict
  (pass/fail with rationale).

## Gates

The framework recommends consensus at two gates per
`workflows/document-lifecycle.md`:

### Gate A: Pre-Submission Consensus (Draft → Approved)

Before an FS or PLAN transitions from `approved` (or `draft` for
simple specs) to `in-progress` or `implemented`, the framework
recommends a consensus round on the draft itself.

**Round shape**: N different models are each independently asked
to draft (or assess) the same artifact. Their outputs are
semantically compared. If the threshold is met, the artifact is
considered consensus-validated and may proceed to the next
lifecycle stage.

**Role stance**: participants operate as **independent Drafters**
or **independent Reviewers**, depending on consumer configuration:

- **Drafter mode**: each participant *produces* the artifact. The
  consensus machinery compares the N outputs. This is the
  "many-drafts" pattern.
- **Reviewer mode**: each participant *reviews* a single draft
  produced by a primary agent. The consensus machinery compares
  the N reviews. This is the "many-reviews" pattern.

Both modes are valid; consumers choose based on cost and quality
tradeoffs. The framework requires that the role stance is
declared per round (see "Audit Trail" below).

### Gate B: Review-Time Consensus (In Review → Done)

When a PR is opened against an Issue (and the related FS or PLAN),
the framework recommends a consensus round on the review.

**Round shape**: N different models each independently review the
PR diff. Their outputs are semantically compared. If the threshold
is met, the PR is considered consensus-validated and may be
merged (subject to ADR-0012's human-merge gate).

**Role stance**: participants operate as **independent Reviewers**.

## Different-Models Requirement

A consensus round MUST invoke at least two *different* models with
*independent* state. Same-model-with-same-prompt is forbidden
because it produces statistically correlated outputs that look like
agreement but are noise dressed as consensus.

Concretely:

- Each participant must use a different model identifier (e.g.,
  `kimi-k2.7-code`, `deepseek-v4-flash`, `claude-sonnet-4`).
  Different versions of the same model family do not count as
  different models.
- Each participant's invocation must be *independent*: no shared
  prompt cache, no shared conversation context, no shared
  tool-use history.
- If only one model is available in the consumer repo's
  configuration, consensus cannot run; the round fails with a
  configuration error.

This is the framework's most important consensus constraint.
Same-model consensus is theater, not consensus.

## Relationship to Mixture of Agents (MoA)

Consumer repos may implement consensus rounds using a Mixture of
Agents (MoA) provider, such as the one built into Hermes Agent.
In this pattern:

- The MoA **reference models** serve as independent consensus
  participants. Each receives the same input (the draft or PR
  diff) and produces an independent assessment.
- The MoA **aggregator model** produces the consensus artifact
  (`docs/consensus/<FS-or-PLAN-id>/<gate>-<timestamp>.yml`) as
  structured output, including the agreement check and verdict.
- The different-models requirement above is satisfied by MoA's
  own model-diversity constraint: the reference models must be
  distinct, and the aggregator must be a different model from
  any reference.

This is a consumer-level implementation choice. The framework
describes the required behavior (what consensus looks like);
consumer repos choose the invocation mechanism (how to run the
round). Using MoA as the invocation layer is valid but not
required — a consumer may implement consensus rounds via
independent API calls, a custom orchestrator, or any other
mechanism that satisfies the different-models requirement.

## Threshold and Failure Modes

### Threshold

Default: 2-of-2 unanimous. Configurable per consumer (e.g., 3-of-5
majority).

When the threshold is met, the consensus round passes and the
workflow proceeds. When the threshold is not met, the round fails
and a failure mode applies.

### Failure Modes

Consumers choose one of three failure modes per project, set in
`config/consensus.yml`:

- **`hard_block`** (default if consensus is enabled): the workflow
  does not advance past the gate until consensus is reached. The
  human is informed via Issue comment; the human may override
  (e.g., by editing the artifact directly and posting a
  `consensus-override: <reason>` comment).
- **`soft_flag`**: the workflow advances despite disagreement, but
  the disagreement is recorded on the Issue and the human is
  informed. The artifact is marked with
  `consensus-disagreement: <summary>` in its metadata.
- **`escalation`**: disagreement automatically creates a Type
  `task` Issue titled `Consensus escalation: <round-id>` with the
  failed round's artifact attached (see Audit Trail). The Issue
  transitions through Status (Backlog → Approved → In Review)
  under the Head Architect role. The Head Architect's mediation
  output is the input to a new consensus round on the same
  artifact. The original artifact does not advance past the gate
  until a subsequent consensus round passes.

  **Termination condition**: if the new consensus round also
  disagrees, the escalation repeats. After N consecutive
  escalation rounds (default: 3, configurable per consumer), the
  round fails as `hard_block` and requires a human override
  (`consensus-override: <reason>` comment on the Issue). This
  prevents infinite escalation loops.

## Configuration

Per-project config file: `config/consensus.yml`. Schema:

```yaml
consensus:
  enabled: false                    # default; opt-in
  default_threshold: 2/2            # N-of-M; default 2-of-2 unanimous
  default_failure_mode: hard_block  # hard_block | soft_flag | escalation
  gates:
    pre_submission:
      enabled: false                # per-gate opt-in
      role_mode: drafter            # drafter | reviewer
      threshold: null               # null = use default_threshold
      failure_mode: null            # null = use default_failure_mode
    review_time:
      enabled: false
      role_mode: reviewer           # always reviewer for this gate
      threshold: null
      failure_mode: null
  models:                           # available models for consensus
    - kimi-k2.7-code
    - deepseek-v4-flash
    - claude-sonnet-4
  min_models: 2                     # minimum different models per round
```

**Validation note**: setting `enabled: true` while `models: []` is
empty is a misconfiguration. The consensus machinery MUST validate
at startup (or at the first consensus round) that `models` contains
at least `min_models` distinct entries. If validation fails, the
round fails with a configuration error and the workflow proceeds
without consensus (graceful degradation). Consumer repos should
surface this error in their startup logs or CI output.

Per-document override: an FS or PLAN may set
`consensus_required: true|false` in its front matter. If set, it
overrides the project-level config for that document. Useful for
high-stakes artifacts that warrant consensus even when the project
default is off. This is a front-matter field on the FS or PLAN
document itself, not a config field — see the FS and PLAN templates
(`templates/core/feature-spec.md`, `templates/core/change-plan.md`)
for the canonical field list.

## Role Stance for Consensus Rounds

A consensus round's role stance is declared per round, on the
Issue comment that records the round's initiation:

```text
agent-stance: mode=consensus; role=<role>; model=<model>; session=<session-name>; rationale=<one-line reason>
```

Where `<role>` is the role each participant operates in
(`Document Author`, `Implementer`, `Reviewer`, or `Head Architect`).
The `mode=consensus` is a new value added to the session-mode
vocabulary (see FS-0018 §"Agent Stance on Issue Comments").

The framework treats `consensus` as a *meta-mode*: a consensus round
is a structured invocation of one of the standard modes, with the
constraint that multiple models participate independently.

## Audit Trail

Each consensus round produces a persisted artifact. The artifact
shape:

```yaml
# File path: docs/consensus/<FS-or-PLAN-id>/<gate>-<timestamp>.yml
round:
  fs_or_plan_id: FS-XXXX
  gate: pre_submission | review_time
  initiated_by: <agent-stance metadata>
  initiated_at: <ISO-8601>
  role_mode: drafter | reviewer
  threshold: 2/2
  participants:
    - model: <model-id>
      role: <role>
      output: <output-summary or file-path>
      output_hash: <sha256>
    - model: <model-id>
      role: <role>
      output: <output-summary or file-path>
      output_hash: <sha256>
  agreement_check:
    method: <consumer-implemented>
    result: pass | fail
    rationale: <string>
  verdict: pass | fail
  failure_mode: hard_block | soft_flag | escalation
```

The artifact is committed to the consumer repo's `docs/consensus/`
directory and linked from the Issue that triggered the round.

Per ADR-0018's three-layer convention, the commit producing this
artifact carries the agent's `user.email`, `Co-authored-by:`
(if hybrid), and `Agent-Attribution:` trailer.

## Success Criteria

Each bullet MUST be objectively testable.

**Default and opt-in**:

- Given a fresh consumer repo adopting this framework, when the
  repo is initialized, then `config/consensus.yml` is created with
  `enabled: false` by default.
- Given a consumer repo with `consensus.enabled: false`, when an
  Issue transitions through Status, then no consensus rounds are
  invoked. The workflow proceeds as a single-model flow.

**Different-models requirement**:

- Given a consumer repo with only one model configured in
  `config/consensus.yml.models`, when a consensus round is
  triggered, then the round fails with a configuration error
  (insufficient models).
- Given a consumer repo with two identical models in
  `config.consensus.yml.models` (e.g., both
  `kimi-k2.7-code`), when a consensus round is triggered, then the
  round fails with a configuration error (same-model consensus is
  forbidden).

**Threshold and failure modes**:

- Given a consensus round with `threshold: 2/2` and both
  participants agreeing, when the round completes, then the
  verdict is `pass` and the workflow advances.
- Given a consensus round with `threshold: 2/2` and participants
  disagreeing, when the round completes with
  `failure_mode: hard_block`, then the workflow does not advance
  past the gate.
- Given a consensus round with `threshold: 2/2` and participants
  disagreeing, when the round completes with
  `failure_mode: soft_flag`, then the workflow advances and the
  artifact is marked `consensus-disagreement`.
- Given a consensus round with `threshold: 2/2` and participants
  disagreeing, when the round completes with
  `failure_mode: escalation`, then the Head Architect role is
  invoked and produces a mediation decision.

**Per-document override**:

- Given an FS with `consensus_required: true` in front matter and
  project-level `consensus.enabled: false`, when the FS is
  submitted for review, then a consensus round runs at Gate A
  even though project consensus is disabled.

**Test-harness note**:

- The success criteria above describe behavior in a consumer repo.
  Validation is by fixture-based bats tests against a sample
  consumer-repo fixture (provided by the consumer repo's test
  harness), not by framework unit tests. The framework's
  framework-level tests verify the schema and structural rules
  (artifact shape, configuration schema, mode values), not the
  end-to-end consumer behavior.

**Audit trail**:

- Given a completed consensus round, when the
  `docs/consensus/<FS-or-PLAN-id>/<gate>-<timestamp>.yml` file
  exists, then it conforms to the artifact shape above, including
  participants, agreement check, and verdict.

## Edge Cases

- **Single model in repo**: if the consumer repo's
  `config/consensus.yml.models` has only one entry, consensus
  cannot run. The round fails with a configuration error; the
  workflow proceeds without consensus (graceful degradation).
- **Model unavailability**: if a configured model is unavailable
  during a round, the round may fail or proceed with the
  remaining models, depending on `min_models` and `threshold`.
  Consumers should specify this behavior in
  `config/consensus.yml`.
- **Cost ceiling**: a consumer repo may want to limit
  per-Issue consensus cost. Add a `max_cost_per_issue` field to
  `config/consensus.yml` to enforce.
- **Disagreement persistence**: a soft-flag disagreement may
  accumulate across rounds. The artifact schema should support
  multiple disagreements per Issue; consumers decide whether to
  surface them as a unified Issue comment or a thread.
- **Override without rationale**: a human override of a failed
  consensus round should require a `consensus-override: <reason>`
  comment. The framework recommends but does not enforce this.

## Out of Scope

- Specific consensus algorithms (majority vote, weighted vote,
  judge model, debate, etc.). Consumers choose.
- Cost and latency budgets. Consumers may optimize.
- Cross-Issue consensus (e.g., "all PRs in milestone X must
  reach consensus"). Out of scope; consumer can implement if
  needed.
- Privacy and data-handling rules for consensus round inputs.
  Out of scope; consumer decides.
- Audit-log retention policies for consensus artifacts. Out of
  scope; consumer decides.

## Dependencies

- FS-0018: the Issue lifecycle and three-axis schema that this
  spec extends with consensus gates.
- ADR-0018: the three-layer attribution convention that this spec
  extends to consensus rounds.
- `workflows/document-lifecycle.md`: the FS/PLAN/ADR status state
  machine that consensus gates integrate with.
- `guidelines/ROLE_CONTRACT.md`: the role definitions that
  consensus rounds extend (Document Author, Implementer, Reviewer,
  Head Architect).
- `skills/git-gh-workflow/SKILL.md`: needs an addition for the
  consensus round initiation and audit trail.

## Open Questions

- **Override authority**: who can override a failed consensus
  round? My read: any human actor with repo write access can
  override by posting `consensus-override: <reason>` on the Issue.
  Confirm.
- **Drafter vs Reviewer mode default**: at Gate A, should the
  default be Drafter (more expensive, higher quality) or Reviewer
  (cheaper, faster)? My read: Reviewer default, Drafter opt-in.
  Confirm.
- **Round participation logging**: should participants log their
  full conversation transcripts to `docs/consensus/`, or just the
  summary? My read: summary by default, full transcripts as
  opt-in (they can be large). Confirm.
- **Cross-gate consensus**: can a single round span both Gate A
  and Gate B (e.g., one round for "submit and review")? My read:
  no, gates are independent; one round per gate per document.
  Confirm.

## Rollout / Migration

1. **Framework docs**: this spec becomes the canonical reference
   for the consensus feature. Add to `skills/git-gh-workflow/SKILL.md`
   a section on consensus round initiation.
2. **`config/consensus.yml` schema**: define in this spec; ship
   as a template that consumer repos copy and customize.
3. **Consumer-repo onboarding**: update `INTEGRATION.md` with a
   "Multi-model consensus (optional)" section.
4. **Test harness**: bats tests for:
   - Default `enabled: false` behavior (no rounds invoked).
   - Same-model configuration rejection.
   - Insufficient-models configuration rejection.
   - Artifact-schema validation.
5. **Documentation**: README.md and AGENTS.md should briefly
   reference this spec.

## Notes for Future ADRs

This spec is likely to surface the following binding decisions:

- **Different-models requirement is non-overridable**: consumers
  cannot configure same-model consensus even if they want to.
- **Consensus defaults to false at the framework level**: the
  framework's own evolution does not use consensus; consumer repos
  opt in explicitly.

These should be drafted as ADRs only after this FS is approved
and implementation begins.\n
