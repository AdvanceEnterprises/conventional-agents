---
type: feature-spec
id: FS-0007
status: approved
title: Versioning, releases, and packaging guidance for agentic development
owner: Tai
test_required: false
interfaces:
  - workflows/ (new file)
  - guidelines/ROLE_CONTRACT.md (update)
  - guidelines/bash/BASH_IMPLEMENTATION_GUIDE.md (update)
  - guidelines/python/PYTHON_IMPLEMENTATION_GUIDE.md (update)
  - guidelines/javascript/JS_IMPLEMENTATION_GUIDE.md (update)
related_adrs: []
supersedes: []
requires: []
tags:
  - versioning
  - releases
  - packaging
  - semver
  - changelog
  - workflow
created: 2026-02-08
updated: 2026-02-08
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

# Feature Spec: Versioning, releases, and packaging guidance for agentic development

## Status

- Approved

## Summary

Add cross-cutting guidance to the agentic-dev-kit framework (repo: `Tais-Den/agentic-dev-kit`, vendored at `vendor/agent-dev-kit/`) for how projects should handle versioning, releases, and packaging when agents are involved in the development workflow.
This includes a new workflow document with prescriptive versioning and release guidance, updates to the Role Contract with version-related agent constraints, and updates to all language-specific implementation guides to establish boundaries around version manipulation during feature work.

## Goals

- Provide a **`workflows/versioning-and-releases.md`** document covering:
  - Semantic versioning semantics for different project types (libraries, services, documentation kits, CLIs).
  - Changelog conventions (format, ownership, agent role).
  - Release process guidance (tagging, release notes, package publishing).
  - Agent-safe vs human-gated release actions.
  - Dependency versioning discipline (lockfiles, pinning, agent behavior when updating dependencies).
  - Submodule versioning guidance (when and how to bump vendored dependencies).

- Update **`guidelines/ROLE_CONTRACT.md`** to add version-related constraints to the Shared Rules and relevant roles:
  - Agents MUST NOT bump major versions without human approval.
  - Agents MAY update changelogs, bump minor/patch versions, and draft release notes when explicitly instructed.
  - Agents MUST NOT publish packages to registries without explicit human approval.
  - Version bumps are only allowed in explicit release-prep commits/PRs, never mixed into feature commits.

- Update **all three language-specific implementation guides** (`BASH_IMPLEMENTATION_GUIDE.md`, `PYTHON_IMPLEMENTATION_GUIDE.md`, `JS_IMPLEMENTATION_GUIDE.md`) to add:
  - "Do not change version numbers in project manifests (`package.json`, `pyproject.toml`, `setup.cfg`, etc.) as part of feature work."
  - "Version bumps are a separate, explicit step that requires human direction."

## Non-Goals

- Prescribing a specific changelog tool (e.g., `conventional-changelog`, `git-cliff`, `release-please`).
- Prescribing a specific CI/CD release pipeline or GitHub Actions workflow.
- Defining a release cadence (weekly, monthly, etc.) — that is project-specific.
- Defining how agentic-dev-kit itself is versioned (that is a separate operational concern, not framework guidance).
- Defining package registry specifics (npm, PyPI, crates.io publish mechanics).

## Users / Stakeholders

- LLM-backed coding agents acting as implementers, test writers, or reviewers on projects that consume agentic-dev-kit.
- Human developers who review agent-produced code and approve releases.
- Project maintainers who define release processes for their repositories.

## Interfaces

- Type: Documentation (workflow + guideline updates)
- Details:
  - New file: `workflows/versioning-and-releases.md`
  - Updated file: `guidelines/ROLE_CONTRACT.md`
  - Updated file: `guidelines/bash/BASH_IMPLEMENTATION_GUIDE.md`
  - Updated file: `guidelines/python/PYTHON_IMPLEMENTATION_GUIDE.md`
  - Updated file: `guidelines/javascript/JS_IMPLEMENTATION_GUIDE.md`

## Background Research

### Why agents need explicit versioning constraints

Agentic developers operate in a Docs → Tests → Code workflow where scope discipline is paramount.
Without explicit constraints, agents will:

1. **Mix version bumps into feature commits** — making rollbacks harder and changelogs meaningless.
2. **Bump major versions for minor changes** — or the reverse — because semver is a judgment call, not a mechanical rule.
3. **Publish packages autonomously** — which is an irreversible, externally-visible action that should always be human-gated.
4. **Update dependency versions during unrelated work** — introducing risk that has nothing to do with the feature being implemented.

These failure modes are well-documented in agentic coding practice and mirror the same "scope creep" concerns that the Role Contract already addresses for code changes.

### Semver semantics vary by project type

What counts as "breaking" depends on context:

- **Libraries**: breaking = public API change (function signatures, exports, types).
- **Services/APIs**: breaking = endpoint removal, response shape change, auth change.
- **Documentation/standards kits** (like agentic-dev-kit): breaking = removing/renaming files in the exported surface, changing the vendored mount path, restructuring directories that consumers reference.
- **CLIs**: breaking = removing/renaming commands or flags, changing default behavior.

The workflow document must acknowledge these differences rather than assuming "library semver" is universal.

### Changelog conventions

The "Keep a Changelog" format (keepachangelog.com) is the most widely adopted standard:

- Sections: Added, Changed, Deprecated, Removed, Fixed, Security.
- Human-curated (not auto-generated from commits).
- Ordered by release date, newest first.
- Unreleased section at top for in-progress work.

This format works well for agentic workflows because:

- Agents can append entries to the Unreleased section during feature work (when instructed).
- Humans review and finalize changelog entries as part of the release decision.
- The format is parseable by agents for context when making decisions about backward compatibility.

### Agent-safe vs human-gated actions

From practitioner experience, the correct boundary is:

**Agent-safe (can do when instructed):**

- Draft changelog entries.
- Bump minor/patch version numbers in manifests.
- Prepare tag commands or propose tags in a release-prep PR (but not push tags to remote).
- Draft release notes.
- Open release-prep PRs.
- Update lockfiles after dependency bumps.

**Human-gated (must not do without explicit approval):**

- Bump major versions (breaking change is a judgment call).
- Publish to package registries (`npm publish`, `twine upload`, etc.).
- Push tags to remote (tags are harder to undo than branches).
- Merge release PRs.
- Announce releases externally.

## Success Criteria

Each bullet MUST be objectively testable.

- Given a checkout of the agentic-dev-kit repo, when listing `workflows/`, then `versioning-and-releases.md` exists.
- Given `workflows/versioning-and-releases.md`, when reading it, then it contains sections covering: semver semantics (with guidance for all 4 project types: libraries, services/APIs, documentation/standards kits, and CLIs), changelog conventions, release process, agent-safe vs human-gated actions, dependency versioning, and submodule versioning.
- Given `workflows/versioning-and-releases.md`, when reading it, then it does NOT prescribe a specific changelog tool, CI/CD pipeline, or release cadence.
- Given `guidelines/ROLE_CONTRACT.md`, when reading it, then it contains version-related constraints in the Shared Rules section that explicitly state: agents must not bump major versions without human approval, agents must not publish to registries without human approval, and version bumps are only allowed in explicit release-prep commits/PRs (never mixed into feature commits).
- Given `guidelines/ROLE_CONTRACT.md`, when reading the Role 2 (Implementer) section, then it lists "changing version numbers in project manifests" as a prohibited action.
- Given `guidelines/bash/BASH_IMPLEMENTATION_GUIDE.md`, when reading it, then it contains guidance that agents must not change version numbers in project manifests as part of feature work.
- Given `guidelines/python/PYTHON_IMPLEMENTATION_GUIDE.md`, when reading it, then it contains guidance that agents must not change version numbers in project manifests as part of feature work.
- Given `guidelines/javascript/JS_IMPLEMENTATION_GUIDE.md`, when reading it, then it contains guidance that agents must not change version numbers in project manifests as part of feature work.
- Given `workflows/versioning-and-releases.md`, when running markdownlint against it, then zero lint errors are reported.
- Given all updated files, when running markdownlint against them, then zero lint errors are reported.

## Edge Cases

- Projects that use CalVer (calendar versioning) instead of SemVer: the workflow doc should acknowledge CalVer as a valid alternative and note that the agent constraints (human-gated major bumps, separate commits) still apply.
- Monorepos with multiple packages at different versions: the workflow doc should acknowledge this pattern exists but should not prescribe monorepo tooling (Lerna, Turborepo, Nx, etc.).
- Projects with no versioning at all (e.g., internal services that deploy from `trunk`): the workflow doc should acknowledge this as valid and note which guidance still applies (changelog, dependency discipline) and which does not (version bumps, tagging).

## Out of Scope

- Specific changelog generation tooling.
- CI/CD pipeline definitions or GitHub Actions workflows for releases.
- Package registry publish mechanics (npm, PyPI, crates.io specifics).
- Release cadence recommendations.
- Versioning of agentic-dev-kit itself (separate operational concern).
- Monorepo tooling guidance.

## Dependencies

- Existing `workflows/` directory and conventions (established in prior work).
- Existing `guidelines/ROLE_CONTRACT.md` structure.
- Existing language-specific implementation guides (Bash, Python, JS/TS).

## Open Questions

None. All design decisions are captured in the Background Research section.
