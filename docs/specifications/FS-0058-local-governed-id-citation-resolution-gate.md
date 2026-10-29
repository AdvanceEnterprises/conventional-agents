---
type: feature-spec
id: FS-0058
status: draft
title: Local governed-ID citation resolution gate
owner: ajoeofalltrades
test_required: true
interfaces:
  - "scripts/check-citations.sh"
  - "scripts/README.md"
  - "package.json"
  - "test/FS-0058/**"
  - "docs/specifications/FS-0058-local-governed-id-citation-resolution-gate.md"
  - "docs/change-plans/PLAN-0063-implement-fs-0058.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0015, ADR-0024, ADR-0027, ADR-0033]
supersedes: []
requires: []
tags: [governance-gate, citations, id-registry, offline, detection]
created: 2026-10-27
updated: 2026-10-29
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

# Feature Spec: Local governed-ID citation resolution gate

## Status

- Draft

This spec was renumbered on 2026-10-29 from the previous `FS` sequence number
`0056` to `FS-0058`. An open PR (`#257`, branch `specB-151-fs-0053`) had already
renumbered its own draft spec into that number earlier in registry order, so
this branch — the later claimant — yields it. Nothing else in the spec changed;
the framework's rule-4 duplicate detector would otherwise report two documents
claiming one ID once both PRs merged.

## Summary

Governed documents in this repository cite `FS-NNNN`, `PLAN-NNNN`, and
`ADR-NNNN` IDs in prose and front matter. A citation that does not resolve to
an existing document in the same repository's registries is a latent error:
forward references are sometimes intentional, but an unresolved reference to a
retired or miss-typed ID can persist undetected. This spec defines a local,
read-only, offline governance gate (`scripts/check-citations.sh`) that resolves
citations against the repository's own registries and reports unresolved ones.

This is the **local** citation layer. Cross-PR stale-citation drift after a
pre-merge renumber is explicitly out of scope; that event-driven layer is
specified by FS-0040 and implemented in
`integrations/github/bin/gh-pr-claim-audit.sh`.

## Goals

- Provide a portable, Bash 3.2-compatible script that resolves `FS-NNNN`,
  `PLAN-NNNN`, and `ADR-NNNN` citations against the local registries.
- Fail with a clear `file: token` list when a cited ID does not resolve.
- Allow intentional forward references and preserved historical citations via
  an exemption list (`--exempt` and `CA_CITATION_EXEMPT`).
- Register the gate in `package.json` and document it in `scripts/README.md`.
  It is optional, detection-only tooling, **not** a Category 1 gate: ADR-0015
  reserves that class for scripts wired into CI as a failing check, and this
  gate is unwired and never blocks a merge.
- Keep the default posture detection-only so consumers may opt in once their
  corpus is clean.

## Non-Goals

- Cross-PR or event-driven citation drift. That is FS-0040 territory.
- Rewriting, renumbering, or otherwise mutating documents or IDs.
- Blocking CI by default. The gate is not wired as a required check unless a
  consumer explicitly opts in.
- Network access. The gate is strictly offline.
- Validating the semantic correctness of a citation, only its existence in the
  local registries.

## Users / Stakeholders

- Framework maintainers who want to detect stale or miss-typed citations before
  they merge.
- Consumer repositories that vendor the framework gates and want a local
  citation check they can run without GitHub credentials.
- Reviewers evaluating whether a PR's new citations resolve.

## Interfaces

- Type: CLI + npm script.
- Details:
  - `bash scripts/check-citations.sh [OPTIONS]` from the repository root.
  - `npm run check:citations` registers the script in `package.json`.
  - `--exempt ID[,ID]` and `CA_CITATION_EXEMPT` exempt a comma- or
    space-separated list of IDs from resolution.
  - `CA_TARGET_REPO` resolves a different repository root, per
    FS-0024 / ADR-0033.
- Exit codes: `0` = all citations resolve, `1` = unresolved citation(s),
  `2` = invalid input or missing repository.

## Success Criteria

- Given a repository whose governed documents cite only IDs that exist in
  `docs/specifications/`, `docs/change-plans/`, or `docs/decisions/`, when the
  script runs, then it exits `0` and prints an OK line.
- Given a governed document that cites an `FS-NNNN` ID with no matching file,
  when the script runs, then it exits `1` and reports the file and token.
- Given a governed document that cites a `PLAN-NNNN` ID with no matching file,
  when the script runs, then it exits `1` and reports the file and token.
- Given a governed document that cites an `ADR-NNNN` ID with no matching file,
  when the script runs, then it exits `1` and reports the file and token.
- Given a document that cites itself, when the script runs, then the self-citation
  is allowed and the script exits `0`.
- Given an unresolved citation and an exemption list that contains the cited ID,
  when the script runs, then the ID is ignored and the script exits `0`.
- Given invalid command-line input, when the script runs, then it exits `2` with
  a usage diagnostic.
- Given an exemption token that is not `FS-NNNN`, `PLAN-NNNN`, or `ADR-NNNN`,
  when the script runs, then it exits `2` with a diagnostic naming the token —
  the scan never aborts silently with an empty report.
- Given `CA_CITATION_EXEMPT` holding a comma-separated list, when the script
  runs, then every listed ID is exempt, matching the `--exempt` form.
- Given a non-existent `CA_TARGET_REPO`, when the script runs, then it exits `2`
  with a clear error.
- Given the script is registered in `package.json`, when `npm run check:citations`
  runs, then it invokes `bash scripts/check-citations.sh`.

## Edge Cases

- The script must remain Bash 3.2 compatible: no associative arrays.
- The registry may be empty only if the repository has no governed documents;
  an empty registry in a repository that should have one is an error.
- Exemptions from the command line and environment combine.
- The scan must include directory READMEs under the three registry directories
  and `docs/operations/ARC42.md` if present.
- The scan covers nothing else: the legacy, hand-curated `docs/ARC42.md` carries
  no `id:` front matter and is not governed, and markdown outside the three
  registry directories is out of scope.
- Exemption tokens are validated, not filtered: a token outside the three
  governed namespaces is a usage error (`2`), never a silently dropped entry.

## Out of Scope

- Cross-PR renumber-drift detection (FS-0040 / `gh-pr-claim-audit.sh`).
- Filename-to-front-matter ID agreement; that belongs to `cross-repo-lint.sh`.
- Rewriting historical citations that intentionally name retired IDs.
- Making the gate a required CI check without a separate consumer decision.

## Dependencies

- ADR-0015 (accepted) — governance-gate classes. Category 1 requires CI wiring;
  this gate deliberately does not claim that class (see Non-Goals).
- ADR-0024 (accepted) — detection-over-prevention posture.
- ADR-0027 (accepted) — reserved paths and human approval for reserved-path
  changes.
- ADR-0033 (accepted) — target repository resolution (`CA_TARGET_REPO`).

## Rollout / Migration

- None. The gate is additive; existing unresolved citations in the framework's
  corpus are known and tracked separately. The gate ships detection-only so
  those existing citations do not block the framework's own CI.

## Security / Privacy

- Data handled: only governed document contents and filenames. No credentials,
  no network, no secrets.

## Open Questions

- None that block the initial implementation; future work may wire the gate
  as a required CI step once the corpus is clean.
