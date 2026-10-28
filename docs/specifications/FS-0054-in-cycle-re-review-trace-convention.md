---
type: feature-spec
id: FS-0054
status: draft
title: In-cycle re-review trace convention for changed PR heads
owner: Head Architect
test_required: true
interfaces:
  - guidelines/ROLE_CONTRACT.md
  - workflows/session-modes.md
  - skills/in-cycle-re-review/SKILL.md
related_adrs:
  - ADR-0018
  - ADR-0022
  - ADR-0029
  - ADR-0036
  - ADR-0050
supersedes: []
requires: []
tags:
  - audit
  - review
  - governance
  - traceability
created: 2026-10-27
updated: 2026-10-27
---
<!--
PARSING_HINTS:
- This document defines desired behavior.
- Generate tests ONLY from the section titled "Success Criteria".
- Treat "Non-Goals" and "Out of Scope" as hard constraints.
- Do NOT infer requirements not explicitly stated.
- `interfaces:` bounds which change plans may self-approve (ADR-0027) — draw
  it narrowly; a loose `interfaces:` widens agent authority.
- Do NOT implement unless status == approved.
- Interfaces listed here define allowed surface area for code changes.
-->
# Feature Spec: In-cycle re-review trace convention for changed PR heads

## Status

- Draft

## Summary

When an implementer revises a PR head in response to reviewer feedback, the
second and subsequent reviewer rounds must leave a discoverable trace on the
PR. This spec adds a bounded convention — a one-line delta-review comment per
model per changed head — so a human triaging the PR can see that re-verification
happened, on which commit, and with what verdict, without breaking the
reviewer-contract deduplication that keeps a model from reviewing the same PR
repeatedly.

## Goals

- Make in-cycle re-reviews of changed heads auditable from the PR thread.
- Preserve the "review a given PR exactly once" dedupe contract used by reviewer
dispatch.
- Avoid turning every fix commit into a full new review round.
- Keep the trace machine-discoverable for tick digest and board reconciliation
consumers.

## Non-Goals

- Re-designing the reviewer contract itself.
- Requiring human reviewers to re-approve after every head change.
- Persisting session-local review packets in a new substrate.
- Changing how promotion gates evaluate head age.

## Users / Stakeholders

- Human maintainer triaging ready-to-merge PRs.
- Autonomous maintenance tick compiling cross-repo digest.
- Multi-model review dispatcher tracking review coverage.

## Interfaces

- Type: Convention
- Details:
  - A new subsection in `guidelines/ROLE_CONTRACT.md` under the reviewer role
    describing the in-cycle delta-review obligation.
  - A new subsection in `workflows/session-modes.md` under autonomous/consensus
    modes describing when and how to post the trace comment.
  - A new skill `skills/in-cycle-re-review/SKILL.md` giving the exact comment
    template and the once-per-head dedupe rule.

## Success Criteria

- Given a PR whose head has changed since the most recent review comment from
  model M, when the applying session completes a new review round for M, then a
  one-line trace comment is posted on the PR before any further status change.
- Given a posted trace comment, when the tick digest generator reads the PR, then
  it can extract the model, commit SHA, round number, and verdict from the
  comment text.
- Given the reviewer contract dedupe rule, when a model has already posted both
  an initial review and a delta trace for head H, then no additional trace comment
  for head H is posted for that model.
- Given a PR whose head has not changed since a model's last review or trace,
  when the next tick runs, then no new trace comment is posted for that model.

## Edge Cases

- A head change that is purely a rebase with no content change still triggers
  the trace convention because the digest must reflect the exact SHA that was
  reviewed.
- A force-push that rewrites history resets the round counter for the affected
  model because the prior review SHA is no longer reachable.
- If a model's review packet is discarded or cannot be reconstructed, the trace
  comment states that the round was skipped and the reason.

## Out of Scope

- Backfilling trace comments for historical PRs (e.g. PR #206).
- Attaching session-local review packet files to the PR comment.
- Changing GitHub branch protection or required check configuration.
- Generalizing the convention beyond in-cycle head changes (e.g. post-merge
  audits).

## Dependencies

- ADR-0018: Single-identity workflow with agent co-attribution.
- ADR-0022: Autonomous and consensus meta-modes.
- ADR-0029: Commit-author naming for multi-model agents.
- ADR-0036: Attribution vocabulary canon and history-integrity policy.
- ADR-0050: Re-approval flow for reviewer-feedback commits on approved PLANs
  (shared concern: audit trail of agent actions on a PR).

## Rollout / Migration

- Update `guidelines/ROLE_CONTRACT.md` and `workflows/session-modes.md` in the
  same PR that lands the new skill.
- Add the skill to `skills/index.md`.
- The convention applies to PRs created or revised after the skill lands;
  in-flight PRs are not retroactively patched.

## Observability

- Logs: each autonomous session logs whether a trace comment was posted, skipped,
  or failed.
- Metrics: tick digest carries a count of "delta-review traces" per PR.
- Traces: n/a.

## Security / Privacy

- Data handled: PR numbers, commit SHAs, model names, verdict labels. All already
  public in the repository.
- Threats considered: an agent could suppress a negative delta trace to make a PR
  look ready. Mitigation: the promotion gate still requires the latest commit to
  be newer than each reviewer's most recent comment; a missing trace is itself a
  signal.
- Mitigations: trace comment format is versioned and parsed by the tick; a trace
  whose format does not match is flagged as an exception.

## Open Questions

- Should the trace comment be posted by the reviewer model's own session or by
  the implementer session on the reviewer's behalf? The convention leaves this
  to the dispatcher, but the attribution trailer must name the reviewing model.
