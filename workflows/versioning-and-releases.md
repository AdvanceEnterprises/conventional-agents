# Versioning and Releases

This document provides prescriptive guidance for how projects should handle versioning, releases, and packaging when LLM-backed agents are involved in the development workflow.

It is part of the conventional-agents exported surface and applies to any project that vendors the kit.

If there is a conflict between this document and project-specific rules in root `AGENTS.md`, the project rules win (see `INTEGRATION.md` for precedence).

---

## Semantic Versioning by Project Type

Use semantic versioning (SemVer) unless the project explicitly adopts an alternative (see CalVer below).

What counts as a "breaking change" depends on the type of project.

### Libraries (packages consumed via import)

- **Major (breaking):** Removing or renaming public exports, changing function signatures, removing or changing types, dropping supported runtime versions.
- **Minor (feature):** Adding new exports, adding optional parameters, new functionality that does not alter existing behavior.
- **Patch (fix):** Bug fixes, documentation corrections, internal refactors that do not change public API.

### Services and APIs

- **Major (breaking):** Removing endpoints, changing response shapes, changing authentication/authorization contracts, removing query parameters or headers.
- **Minor (feature):** Adding new endpoints, adding optional fields to responses, new query parameters.
- **Patch (fix):** Bug fixes, performance improvements, internal refactors.

### Documentation and Standards Kits

- **Major (breaking):** Removing or renaming files in the exported surface, changing the vendored mount path, restructuring directories that consumers reference in their `AGENTS.md` or tool configs.
- **Minor (feature):** Adding new guideline sets, new workflows, new templates, new skills, new roles.
- **Patch (fix):** Typo fixes, clarifications that do not change meaning, lint config tweaks.

### CLIs (command-line tools)

- **Major (breaking):** Removing or renaming commands or flags, changing default behavior, changing output format in a breaking way.
- **Minor (feature):** Adding new commands or flags, new output formats (opt-in), new integrations.
- **Patch (fix):** Bug fixes, help text improvements, performance improvements.

### General Rule

If you are unsure whether a change is breaking, treat it as breaking.
The cost of an unnecessary major bump is low; the cost of a missed breaking change is high.

---

## Changelog Conventions

### Format

Follow the Keep a Changelog format (<https://keepachangelog.com>). This framework uses a curated subset; see the sections below.

Sections (use only those that apply per release):

- **Added** — new features or capabilities.
- **Changed** — changes to existing functionality.
- **Deprecated** — features that will be removed in a future release.
- **Removed** — features removed in this release.
- **Fixed** — bug fixes.
- **Security** — vulnerability fixes.

### Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com).

## [Unreleased]

### Added
- New feature description.

## [1.2.0] - 2026-02-08

### Added
- Feature X.

### Fixed
- Bug Y.
```

### Ownership

- Changelogs are **human-curated**, not auto-generated from commits.
- Agents MAY append entries to the `[Unreleased]` section when explicitly instructed during feature work.
- Humans review and finalize changelog entries as part of the release decision.
- Agents MUST NOT remove or rewrite existing changelog entries.

---

## Release Process

### Recommended workflow

1. **Feature work** happens on branches, merged to the main branch via PRs.
2. When ready to release, open a **release-prep PR** that:
   - Moves `[Unreleased]` entries to a new version section.
   - Bumps version numbers in project manifests (`package.json`, `pyproject.toml`, `setup.cfg`, etc.).
   - Updates any version references in documentation.
3. A human reviews and merges the release-prep PR.
4. A human (or CI triggered by the merge) creates a git tag and GitHub Release.
5. A human approves package publishing to registries (if applicable).

### What agents can do (when instructed)

- Draft changelog entries during feature work.
- Bump minor or patch version numbers in manifests.
- Prepare tag commands or propose tags in a release-prep PR.
- Draft release notes from changelog content.
- Open release-prep PRs.
- Update lockfiles after dependency bumps.

### What requires human approval

- Bumping major versions (breaking change is a judgment call).
- Publishing to package registries (`npm publish`, `twine upload`, etc.).
- Pushing tags to remote (tags are harder to undo than branches).
- Merging release-prep PRs.
- Announcing releases externally (blog posts, social media, mailing lists).

---

## Agent-Safe vs Human-Gated Actions (Summary)

| Action | Agent-safe? | Notes |
| --- | --- | --- |
| Draft changelog entries | Yes (when instructed) | Append to `[Unreleased]` only |
| Bump minor/patch version | Yes (when instructed) | Release-prep PRs only |
| Bump major version | **No** | Requires human approval |
| Open release-prep PR | Yes (when instructed) | Human merges |
| Prepare tag commands | Yes | In PR description or script |
| Push tags to remote | **No** | Requires human approval |
| Publish to registries | **No** | Requires human approval |
| Merge release PRs | **No** | Requires human approval |
| External announcements | **No** | Requires human approval |

---

## Dependency Versioning

### Lockfiles

- Always commit lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`, `Pipfile.lock`, `poetry.lock`).
- Agents MUST NOT delete or regenerate lockfiles as part of feature work.
- Dependency updates should be their own PR, not mixed into feature work.

### Pinning

- Pin direct dependencies to specific versions or ranges as defined by the project.
- Do not change dependency version ranges as part of unrelated feature work.
- If a dependency update is needed to complete a feature, document it explicitly in the PR description and keep it as a separate commit.

### Agent behavior with dependencies

- Agents MUST NOT run `npm update`, `pip install --upgrade`, or equivalent commands during feature work unless explicitly instructed.
- If a test fails due to a dependency issue, the agent should report the failure, not attempt to fix it by updating dependencies.

---

## Submodule Versioning

For projects that vendor conventional-agents (or other kits) as git submodules:

- Submodule bumps should be their own commit or PR.
- When bumping a submodule, reference the target version/tag in the commit message.
- Agents MAY open submodule-bump PRs when instructed.
- Agents MUST NOT bump submodules during unrelated feature work.
- After bumping a submodule, verify that all references to vendored paths still resolve correctly.

---

## Edge Cases

### Calendar Versioning (CalVer)

Some projects use CalVer (e.g., `2026.02`, `26.2.1`) instead of SemVer.
CalVer is a valid choice.
When CalVer is used, the agent constraints in this document still apply:

- Major/breaking releases still require human approval.
- Version bumps are still release-prep only, never mixed into feature work.
- Changelog conventions remain the same.

### Monorepos

Projects with multiple packages at different versions add complexity.
This document does not prescribe monorepo tooling (Lerna, Turborepo, Nx, Changesets, etc.).
The core principles still apply per-package:

- Version bumps are release-prep only.
- Agents follow the project's existing monorepo conventions.
- When in doubt, ask.

### Projects with No Formal Versioning

Some projects (internal services, continuously deployed apps) do not use version numbers.
In these cases:

- **Still applies:** changelog discipline, dependency versioning, agent constraints on publishing/announcing.
- **Does not apply:** version bumps, tagging, SemVer semantics.

The release-prep boundary shifts to deployment decisions, which remain human-gated.
