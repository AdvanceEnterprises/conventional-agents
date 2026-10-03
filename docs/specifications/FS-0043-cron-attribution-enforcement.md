---
type: feature-spec
id: FS-0043
status: draft
title: Cron attribution enforcement — require terminal mode=autonomous after the adoption boundary
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/cross-repo-lint.sh"
  - "scripts/README.md"
  - "workflows/git-and-gh-conventions.md"
  - "test/FS-0043/**"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0021, ADR-0024, ADR-0026, ADR-0027]
supersedes: []
requires: [FS-0017]
tags: [attribution, cron, autonomous, quality-gates, history, detection]
created: 2026-10-03
updated: 2026-10-03
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

# Feature Spec: Cron attribution enforcement — require terminal mode=autonomous after the adoption boundary

## Status

- Draft

## Plan Status

- **PLAN-0049 is `draft`.** The historical window before the adoption boundary
  is grandfathered; this companion enforces the existing ADR-0021 norm for new
  cron-authored commits without rewriting history.
- The implementation touches `scripts/`, so the final revision needs a recorded
  approval under ADR-0026/ADR-0027 before code is written.

## Summary

ADR-0021 requires unattended actors to identify themselves with a dedicated
identity and a terminal `mode=autonomous` marker. FS-0017's structural parser
currently treats the field as optional for every actor, so the cron address can
produce a structurally valid but semantically incomplete trailer.

This companion keeps historical commits intact and adds a boundary-aware rule to
the existing cross-repository attribution audit. Cron identities before the
configured adoption boundary are reported as grandfathered. Cron commits after
the boundary fail the audit unless their parsed `Agent-Attribution:` trailer
ends with `mode=autonomous`.

## Goals

- Enforce the ADR-0021 marker for cron actor identities after a documented,
  configurable adoption boundary.
- Preserve and report pre-boundary history without rewriting it.
- Keep interactive-agent attribution behavior unchanged.
- Make the rule visible in the existing cross-repository audit and its digest
  output.
- Add focused fixtures for pass, fail, grandfathered, malformed, and mixed
  ranges.

## Non-Goals

- Rewriting or amending historical commits.
- Requiring `mode=autonomous` on interactive-agent identities.
- Treating an email address as proof that a commit was unattended when its
  identity is not configured as a cron actor.
- Changing the existing structural field order or canonical vocabulary gate.
- Calling GitHub or a remote service from the attribution audit.

## Interfaces

- `scripts/cross-repo-lint.sh` — boundary-aware cron check and diagnostics.
- `scripts/README.md` — configuration, grandfathering, and remediation.
- `workflows/git-and-gh-conventions.md` — reconcile the conditional field
  description with ADR-0021's mandatory cron rule.
- `test/FS-0043/**` — disposable Git-history attribution fixtures.
- The document indexes and `CHANGELOG.md` track the package.

## Success Criteria

- **SC-1 — post-boundary cron commits require the marker.** A cron-authored
  commit after the adoption boundary with a trailer lacking terminal
  `mode=autonomous` is reported as bad and makes the audit non-zero.
- **SC-2 — terminal shape is enforced.** `mode=autonomous` in the middle of a
  trailer, followed by another field, does not satisfy the rule.
- **SC-3 — pre-boundary history is grandfathered.** A cron-authored commit at or
  before the boundary is reported as grandfathered and does not fail solely for
  lacking the marker.
- **SC-4 — interactive agents remain unchanged.** An interactive-agent commit
  without `mode=` follows the existing structural result and is not rejected by
  this companion rule.
- **SC-5 — configuration is explicit.** The boundary can be overridden by an
  environment variable for consumers and fixtures; an invalid boundary fails
  loudly instead of silently disabling enforcement.
- **SC-6 — existing audit coverage remains.** Missing and malformed trailers,
  README checks, and duplicate checks retain their current behavior.
- **SC-7 — no history mutation.** The source and fixtures prove that the audit
  only reads Git history and emits diagnostics.

## Edge Cases

- The comparison uses commit timestamps and an ISO-8601 boundary; equality is
  grandfathered.
- A cron actor is identified by the configured cron email list, not by a loose
  substring match on commit subject.
- A commit can be reported for both an existing structural problem and a missing
  autonomous marker; the output names both causes.
- A consumer can set `CRON_ATTRIBUTION_BOUNDARY` and `CRON_AGENT_EMAILS` without
  changing the framework source.

## Out of Scope

- Fixing the historical 55 nonconforming commits in place.
- Server-side branch protection or GitHub required-check configuration.
- Cron webhook delivery or Notion mirror delivery.

## Dependencies

- FS-0017 for the existing trailer format and actor allowlist.
- ADR-0021 for the mandatory unattended marker.
- ADR-0024 for detection over prevention.
- ADR-0026/ADR-0027 for approval routing on the script surface.

## Rollout / Migration

The framework adopts the boundary on the implementation revision's date. The
existing history remains auditable and is explicitly labeled grandfathered. New
cron commits must use the terminal marker; the maintenance prompt and any other
cron writer must be updated in the same operational rollout.

## Open Questions

- None blocking.
