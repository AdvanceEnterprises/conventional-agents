---
type: feature-spec
id: FS-0042
status: draft
title: History-aware freshness audit — distinguish substantive document drift from metadata-only updates
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-freshness-history.sh"
  - "scripts/README.md"
  - "package.json"
  - ".github/workflows/lint-docs.yml"
  - "test/FS-0042/**"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0024, ADR-0026, ADR-0027, ADR-0033]
supersedes: []
requires: [FS-0027, FS-0024]
tags: [quality-gates, freshness, git-history, report-only, detection]
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

# Feature Spec: History-aware freshness audit — distinguish substantive document drift from metadata-only updates

## Status

- Draft

## Plan Status

- **PLAN-0048 is `draft`.** This package defines a companion audit to the
  implemented presence/age gate in FS-0027; it does not alter that gate's
  existing behavior.
- The implementation surface includes `scripts/`, `package.json`, and the
  workflow, so the implementation revision requires recorded human approval
  under ADR-0026/ADR-0027 before code is written.

## Summary

FS-0027 verifies that governed workflow and guideline documents carry a current,
parseable `updated:` field and reports age. It does not compare that field with
the document's own Git history. A substantive edit can therefore leave the field
behind, while a commit that only refreshes freshness metadata can look like a
substantive edit if history is interpreted naively.

This spec adds a separate, offline, report-only audit. It compares each covered
document's `updated:` date with the latest non-merge commit that changed content
outside the front-matter freshness metadata. Metadata-only commits are retained
as diagnostics and never create a strict failure. Missing history is an explicit
failure, not a clean result.

## Goals

- Detect substantive history newer than a document's declared `updated:` date.
- Treat commits that only change freshness metadata as diagnostics, not drift.
- Fail closed when a shallow or otherwise unavailable history prevents the
  comparison.
- Keep the audit caller-relative, Git-only, portable, and report-only.
- Provide a strict mode for CI and a diagnostic mode for maintenance scans.
- Leave FS-0027's presence, parseability, and age behavior unchanged.

## Non-Goals

- Automatically editing `updated:` fields or any document content.
- Replacing FS-0027 or changing its age threshold.
- Inferring substantive intent from commit messages, issue numbers, PR titles,
  branch names, or author identity.
- Calling GitHub, Notion, a project board, or another external service.
- Declaring every date mismatch an error when the only intervening commits are
  metadata-only freshness updates.

## Users / Stakeholders

- Framework maintainers who need a truthful freshness signal.
- Consumers running the portable gates from a full-history checkout.
- Reviewers deciding whether a date-only refresh needs a separate content review.
- The maintenance tick, which needs a bounded diagnostic instead of a false
  stale-document table.

## Interfaces

- Type: offline CLI audit + npm entry + CI invocation.
- `scripts/check-freshness-history.sh` — the companion history comparison.
- `scripts/README.md` — evidence model, strict/diagnostic behavior, and limits.
- `package.json` — `check:freshness:history` invokes strict mode.
- `.github/workflows/lint-docs.yml` — runs after a full-history checkout.
- `test/FS-0042/**` — disposable Git-history fixtures; no network calls.
- The indexes and `CHANGELOG.md` track the governed package.

## Success Criteria

- **SC-1 — substantive drift is reported.** Given a covered document whose
  latest substantive commit is newer than `updated:`, strict mode exits non-zero
  and names the path, declared date, and substantive commit date.
- **SC-2 — metadata-only changes are diagnostics.** Given a document whose
  post-update commit changes only freshness metadata, strict mode exits zero and
  emits a diagnostic that the commit was excluded from substantive history.
- **SC-3 — clean history passes.** Given a document whose `updated:` date is at
  least the latest substantive commit date, the audit emits no drift finding.
- **SC-4 — missing history fails closed.** Given a shallow checkout or an
  unavailable commit needed for the comparison, the audit exits with the
  documented unavailable-history code and names the affected path.
- **SC-5 — scope is limited.** Only tracked Markdown files under
  `workflows/` and `guidelines/` participate, matching FS-0027; other paths are
  not reported by this companion.
- **SC-6 — report-only behavior is verifiable.** Before and after a finding,
  the worktree and document bytes are identical.
- **SC-7 — entry points are wired.** `npm run check:freshness:history` invokes
  the same script used by CI, supports caller-relative execution from a clone
  and Git worktree, and `--help` documents exit codes and strict mode.
- **SC-8 — reproducibility.** The focused Bats suite builds real disposable
  history and covers substantive edits, metadata-only edits, shallow history,
  clean history, and no mutation without live GitHub calls.

## Edge Cases

- Merge commits are ignored; their parent commits remain the evidence surface.
- A commit changing both content and `updated:` is substantive.
- A commit changing only `updated:` or other declared freshness metadata is
  diagnostic-only.
- A document with no reachable history cannot be treated as clean.
- A shallow checkout must be repaired by the caller or reported as unavailable;
  the script never fetches implicitly.

## Out of Scope

- Cross-repository history comparison.
- Freshness of ADRs, FS/PLAN files, runbooks, or Notion pages.
- Automatic date refreshes or status transitions.
- Changes to `scripts/check-freshness.sh`'s existing contract.

## Dependencies

- FS-0027 for the existing covered-document set and field syntax.
- FS-0024 / ADR-0033 for caller-relative execution.
- ADR-0024 for detection over prevention.
- ADR-0026 and ADR-0027 for the reserved-path approval boundary.

## Rollout / Migration

The existing freshness gate remains the fast presence/age check. CI adds this
companion after checking out full history. Consumers may run diagnostic mode
locally and strict mode in a full-history CI job. A finding is a review signal;
this audit does not rewrite dates.

## Open Questions

- None blocking.
