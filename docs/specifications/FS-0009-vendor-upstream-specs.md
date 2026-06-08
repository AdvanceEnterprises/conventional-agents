---
type: feature-spec
id: FS-0009
status: implemented
title: Vendor Upstream Specs (Conventional Commits, Keep a Changelog)
owner: martenoftheden
test_required: false
interfaces:
  - "vendor/conventional-commits/ (new submodule)"
  - "vendor/keep-a-changelog/ (new submodule)"
  - "README.md"
  - "workflows/versioning-and-releases.md"
  - "CHANGELOG.md"
  - "INTEGRATION.md"
related_adrs: [ADR-0010]
supersedes: []
requires: []
tags: [vendoring, upstream, standards]
created: 2026-02-08
updated: 2026-06-08
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

# Feature Spec: Vendor Upstream Specs (Conventional Commits, Keep a Changelog)

## Status

- Implemented

## Summary

agentic-dev-kit builds on two well-established community specifications — Conventional Commits and Keep a Changelog — but currently references them only via external URLs.
By vendoring both as git submodules under `vendor/`, we make them available offline, pin to known versions, and allow our guidelines/templates to reference the canonical spec text directly rather than relying on external links.

Additionally, the joelparkerhenderson/architecture-decision-record resource should be mentioned in the README as a recommended reference for ADR practitioners.

## Goals

- Vendor `conventional-commits/conventionalcommits.org` as a git submodule at `vendor/conventional-commits/`
- Vendor `olivierlacan/keep-a-changelog` as a git submodule at `vendor/keep-a-changelog/`
- Update all guidelines and templates that reference these specs to include local vendor paths alongside (or instead of) external URLs
- Mention joelparkerhenderson/architecture-decision-record in README as a recommended ADR resource

## Non-Goals

- Forking or modifying the upstream specs
- Replacing all external URLs (keep URLs for convenience; add vendor paths for reliability)
- Vendoring MADR or arc42 (separate effort if desired)
- Adding any build tooling from the vendored repos (Hugo, Ruby, etc.)

## Users / Stakeholders

- Agent developers using agentic-dev-kit (offline access, pinned specs)
- agentic-dev-kit maintainers (explicit upstream tracking)

## Interfaces

- **`vendor/conventional-commits/`** (new) — git submodule pointing to `conventional-commits/conventionalcommits.org`, pinned to latest stable tag or commit
- **`vendor/keep-a-changelog/`** (new) — git submodule pointing to `olivierlacan/keep-a-changelog`, pinned to latest stable tag or commit
- **`README.md`** — add "Upstream References" section listing vendored specs and the ADR resource
- **`workflows/versioning-and-releases.md`** — add vendor path references alongside existing URLs
- **`CHANGELOG.md`** — add vendor path reference in the format header
- **`INTEGRATION.md`** — mention vendored upstream specs in the repo structure / best practices section

## Success Criteria

- Given a fresh clone with `--recurse-submodules`, when checking `vendor/conventional-commits/`, then it contains the Conventional Commits specification content (pinned to a known commit; spec text is accessible under `content/`)
- Given a fresh clone with `--recurse-submodules`, when checking `vendor/keep-a-changelog/`, then it contains the Keep a Changelog specification source (pinned to a known commit)
- Given the README.md, when reading it, then an "Upstream References" section lists both vendored specs and the joelparkerhenderson ADR resource
- Given `workflows/versioning-and-releases.md`, when reading changelog or commit convention sections, then vendor paths are referenced alongside external URLs
- Given `CHANGELOG.md`, when reading the format header, then it references the vendored spec
- Given `INTEGRATION.md`, when reading it, then it mentions the vendored upstream specs

## Edge Cases

- Upstream repos may reorganize; submodule pins protect against breakage
- The vendored repos contain website build tooling (Hugo, Ruby) that consumers should ignore

## Out of Scope

- Building or serving the vendored websites
- Vendoring MADR, arc42, or semver.org
- Changing the substance of our own guidelines (this is a referencing change only)

## Dependencies

- None (adding submodules has no build dependencies)

## Open Questions

None.
