---
type: feature-spec
id: FS-0016
status: implemented
title: Framework Internal Vendor Boundary
owner: ajoeofalltrades
test_required: true
interfaces:
  - ".gitmodules"
  - "vendor/madr/"
  - "workflows/git-and-gh-conventions.md"
  - "workflows/versioning-and-releases.md"
  - "CHANGELOG.md"
  - "skills/git-gh-workflow/SKILL.md"
  - "README.md"
  - "AGENTS.md"
  - "INTEGRATION.md"
  - "docs/ARC42.md"
  - "docs/decisions/ADR-0003.md"
  - "docs/specifications/FS-0009-vendor-upstream-specs.md"
  - "docs/change-plans/PLAN-0009-vendor-upstream-specs.md"
related_adrs:
  - ADR-0017
supersedes: []
requires: []
tags: [vendoring, boundary, upstream, consumer-contract]
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

# Feature Spec: Framework Internal Vendor Boundary

## Status

- Implemented

## Summary

Define and enforce the boundary between the framework's internal `vendor/`
directory and the files that consuming projects may reference. The framework
vendors upstream material for its own operational needs (provenance,
byte-equality tests, template sources), but consumers must treat the
framework's `vendor/` directory as an internal implementation detail. Consumers
receive the contract through the framework's own exported files and through
upstream URLs, never through nested paths such as
`vendor/conventional-agents/vendor/...`.

## Goals

- Make the consumer contract unambiguous: only files in the framework's
  exported surface are available for host repos to reference.
- Remove submodules from the framework repo that are not used operationally by
  the framework's CI or tooling.
- Keep `vendor/madr/` as the single remaining internal submodule because it
  supports a real operational test (`test/FS-0001/adr-linting.bats`).
- Update all consumer-facing documentation to stop pointing at nested vendor
  paths.
- Update historical documents that referenced the removed submodules so they
  do not mislead future readers.

## Non-Goals

- Change the substance of the framework's commit-message or changelog
  contracts; only the provenance references change.
- Add new build tooling or dependencies.
- Force consumers to vendor additional submodules.
- Modify accepted ADR bodies; historical ADRs receive append-only status
  notes.

## Users / Stakeholders

- Projects consuming conventional-agents as a submodule.
- Agents writing or reviewing host-repo `AGENTS.md` files.
- Framework maintainers updating upstream references.

## Interfaces

- **`.gitmodules`** — modified to remove `vendor/conventional-commits/`,
  `vendor/keep-a-changelog/`, and `vendor/arc42-template/`; keep
  `vendor/madr/`.
- **`vendor/madr/`** — remains as the only internal operational submodule.
- **Consumer-facing docs** — `workflows/git-and-gh-conventions.md`,
  `workflows/versioning-and-releases.md`, `CHANGELOG.md`,
  `skills/git-gh-workflow/SKILL.md`, `README.md`, `AGENTS.md`,
  `INTEGRATION.md` — updated to reference framework files or upstream URLs.
- **Historical docs** — `docs/ARC42.md`, `docs/decisions/ADR-0003.md`,
  `docs/specifications/FS-0009-vendor-upstream-specs.md`,
  `docs/change-plans/PLAN-0009-vendor-upstream-specs.md` — annotated with a
  status note linking to ADR-0017.

## Success Criteria

- Given a fresh clone of the framework repo, when listing submodules under
  `vendor/`, then only `vendor/madr/` is present.
- Given `workflows/git-and-gh-conventions.md`, when reading the commit
  conventions section, then it describes a framework-specific lite profile and
  cites the Conventional Commits URL instead of a vendored submodule path.
- Given `workflows/versioning-and-releases.md`, when reading the changelog
  conventions section, then it cites the Keep a Changelog URL instead of a
  vendored submodule path.
- Given `README.md`, when reading "Upstream References", then it lists URLs
  as canonical and notes the framework's curated subsets.
- Given `INTEGRATION.md`, when reading the integration patterns or
  troubleshooting sections, then no consumer pattern references
  `vendor/conventional-agents/vendor/...` paths.
- Given `AGENTS.md`, when reading the "Exported Surface vs Internal
  Governance" table, then `vendor/` is listed as framework-internal.
- Given `docs/ARC42.md`, when reading the `vendor/` description, then only
  `vendor/madr/` is listed and a note references ADR-0017.
- Given `docs/specifications/FS-0009-vendor-upstream-specs.md`, when reading
  the Status section, then it includes a note that the Conventional Commits and
  Keep a Changelog submodule scope was subsequently superseded by ADR-0017.
- Given `docs/change-plans/PLAN-0009-vendor-upstream-specs.md`, when reading
  the Scope of Change section, then it includes a note that the submodule scope
  was subsequently superseded by ADR-0017.
- Given `docs/decisions/ADR-0003.md`, when reading the Status section, then it
  includes a note that `vendor/arc42-template/` was removed per ADR-0017.

## Edge Cases

- A host repo may already reference a dropped submodule path. The framework
  must provide clear migration guidance in `INTEGRATION.md` and the new
  `framework-consumer-integration` skill.
- A host repo may need the full upstream spec. The framework must provide the
  upstream URL, not a local submodule path.

## Out of Scope

- Renaming or moving `vendor/madr/`.
- Changing the MADR template or lint config copies in `templates/` and
  `docs/decisions/`.
- Adding new skills beyond the `framework-consumer-integration` skill needed to
  document the boundary.

## Dependencies

- ADR-0017: Framework vendor directory is internal.
- `test/FS-0001/adr-linting.bats` continues to assert byte-equality between
  `docs/decisions/.markdownlint.yml` and `vendor/madr/.markdownlint.yml`.

## Rollout / Migration

- Host repos that referenced `vendor/conventional-agents/vendor/...` paths must
  update their `AGENTS.md` or tooling to use framework files or upstream URLs.
- This is a breaking change for the framework's exported surface; the framework
  version advances from 2.0.0 to 2.1.0.

## Open Questions

None.
