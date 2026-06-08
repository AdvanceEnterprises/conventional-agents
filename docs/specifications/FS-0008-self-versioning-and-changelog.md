---
type: feature-spec
id: FS-0008
status: implemented
title: Apply versioning and changelog to conventional-agents itself
owner: Tai
test_required: false
interfaces:
  - CHANGELOG.md (new file at root)
  - README.md (update version reference)
  - package.json (update version field)
related_adrs: []
supersedes: []
requires:
  - FS-0007
tags:
  - versioning
  - changelog
  - self-hosting
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

# Feature Spec: Apply versioning and changelog to conventional-agents itself

## Status

- Implemented

## Summary

Apply the versioning and release guidance established in FS-0007 and `workflows/versioning-and-releases.md` to the conventional-agents repository itself.
This means creating a `CHANGELOG.md` with retroactive entries for work completed to date, aligning the version in `README.md` and `package.json`, and establishing the repo's first formal release-ready state.

As a documentation/standards kit, conventional-agents follows the "Documentation and Standards Kits" semver semantics defined in `workflows/versioning-and-releases.md`:

- **Major (breaking):** removing/renaming exported surface files, changing vendored mount path, restructuring directories consumers reference.
- **Minor (feature):** adding guideline sets, workflows, templates, skills, roles.
- **Patch (fix):** typos, clarifications, lint config tweaks.

## Goals

- Create `CHANGELOG.md` at the repo root following Keep a Changelog format.
- Include retroactive entries covering all significant work from the initial state through current trunk.
- Set the current version to `1.1.0` (the initial "1.0.0" baseline plus the JS guidelines and versioning workflow as minor features).
- Update `README.md` to reference `1.1.0` instead of `1.0.0`.
- Update `package.json` `"version"` field to `"1.1.0"`.

## Non-Goals

- Creating git tags or GitHub Releases (that is a human-gated action per FS-0007).
- Setting up CI/CD release automation.
- Bumping the submodule pointer in `agentic-bootstrap-constitution` (separate follow-up).

## Users / Stakeholders

- Maintainers of conventional-agents.
- Consumers who vendor the kit and want to know what changed between versions.

## Interfaces

- Type: Documentation + manifest
- Details:
  - New file: `CHANGELOG.md`
  - Updated file: `README.md` (version reference)
  - Updated file: `package.json` (version field)

## Success Criteria

- Given the repo root, when listing files, then `CHANGELOG.md` exists.
- Given `CHANGELOG.md`, when reading it, then it follows Keep a Changelog format with sections: Added, Changed, Fixed (as applicable).
- Given `CHANGELOG.md`, when reading it, then it contains an `[Unreleased]` section at the top and at least one versioned section (`[1.1.0]`).
- Given `CHANGELOG.md`, when reading the `[1.1.0]` section, then it references the JS/TS guidelines addition, the versioning/releases workflow, the BDD/TDD pre-commit gates, and the project rename.
- Given `README.md`, when reading it, then the framework version reference shows `1.1.0`.
- Given `package.json`, when reading it, then the `"version"` field is `"1.1.0"`.

## Edge Cases

None for this spec (it is a one-time bootstrapping action).

## Out of Scope

- Git tags and GitHub Releases.
- CI/CD release automation.
- Template repo submodule bump.
- Future changelog maintenance (covered by FS-0007 workflow guidance).

## Dependencies

- FS-0007 (versioning guidance) must be implemented first (it is).
- `workflows/versioning-and-releases.md` must exist (it does).

## Open Questions

None.
