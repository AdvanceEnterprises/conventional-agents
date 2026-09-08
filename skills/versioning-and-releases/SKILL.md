---
name: versioning-and-releases
description: "Semantic versioning by project type, Keep a Changelog conventions, the release-prep process, and which release actions are agent-safe versus human-gated. Use when classifying a change as major, minor, or patch, writing a CHANGELOG entry, preparing a release PR, or handling dependency and submodule bumps."
license: MIT
---

# Versioning and Releases Skill

Classifying a change, recording it, and shipping it — and the bright line between
what an agent may prepare and what only a human may do.

## Source Documents

- `workflows/versioning-and-releases.md` — semver, changelogs, release process
- `docs/decisions/ADR-0025-merge-strategy-preserves-per-commit-attribution.md`

## When to Use

- Deciding whether a change is major, minor, or patch.
- Writing or reviewing a `CHANGELOG.md` entry.
- Preparing a release PR.
- Bumping a dependency, a lockfile, or a submodule.

## Gates That Bind Here

Summarised, not restated. Canonical text: `guidelines/ROLE_CONTRACT.md`
§ Versioning and release constraints.

- Agents MUST NOT bump **major** versions without human approval.
- Agents MUST NOT publish packages to registries without explicit human approval.
- Version bumps happen only in explicit release-prep commits, never mixed into
  feature work.

## Semantic Versioning by Project Type

| Project Type | Major (breaking) | Minor (feature) | Patch (fix) |
| --- | --- | --- | --- |
| **Libraries** | Removing/renaming public exports, changing signatures | Adding new exports, optional params | Bug fixes, internal refactors |
| **Services/APIs** | Removing endpoints, changing response shapes | Adding new endpoints, optional fields | Bug fixes, perf improvements |
| **Doc/Standards Kits** | Removing/renaming exported files, changing the vendored mount path | New guidelines, workflows, templates, skills | Typo fixes, clarifications |
| **CLIs** | Removing/renaming commands/flags, changing defaults | New commands/flags, opt-in output formats | Bug fixes, help text improvements |

**General rule:** if unsure whether a change is breaking, treat it as breaking.
The cost of an unnecessary major bump is low; the cost of a missed breaking
change is high.

For a documentation and standards kit this bites more often than it looks:
deleting *any* file from the exported surface is a major change, even an empty
one nobody referenced.

## Changelog Conventions

Keep a Changelog format (<https://keepachangelog.com>), curated subset.

| Section | Use |
| --- | --- |
| **Added** | New features or capabilities |
| **Changed** | Changes to existing functionality |
| **Deprecated** | Features that will be removed in a future release |
| **Removed** | Features removed in this release |
| **Fixed** | Bug fixes |
| **Security** | Vulnerability fixes |

**Ownership:**

- Changelogs are human-curated, not auto-generated from commits.
- Agents MAY append entries to `[Unreleased]` when explicitly instructed.
- Humans review and finalise entries as part of the release decision.
- Agents MUST NOT remove or rewrite existing entries.

## Example 1 — Append an `[Unreleased]` entry

```bash
# Read the existing section first; never rewrite what is there.
sed -n '/## \[Unreleased\]/,/^## \[/p' CHANGELOG.md
```

Then add under the correct heading, stating consumer impact honestly:

```text
### Changed

- **Skill frontmatter conformed to the Agent Skills base spec.** Non-spec fields
  removed; runtime dialect moved out of source. Consumer impact: skills load
  identically, but this deletes a file from the exported surface, which is a
  major change for a documentation and standards kit.
```

## Example 2 — Release-prep PR

```bash
git switch trunk && git pull --ff-only origin trunk
git switch -c chore/release-v2.2.0

# Move [Unreleased] entries under a new version heading, then:
npm version minor --no-git-tag-version   # agent-safe for minor/patch only
git add -A && git commit -m "chore: prepare v2.2.0 release"
git push -u origin HEAD
gh pr create --fill
# Stop here. A human merges, tags, and publishes.
```

## Release Process

1. Feature work happens on branches, merged via PRs.
2. A **release-prep PR** moves `[Unreleased]` entries to a new version section,
   bumps version numbers in manifests, and updates version references in docs.
3. A human reviews and merges the release-prep PR.
4. A human (or CI triggered by the merge) creates the git tag and GitHub Release.
5. A human approves publishing to registries.

## Agent-Safe vs Human-Gated

| Action | Agent-safe? | Notes |
| --- | --- | --- |
| Draft changelog entries | Yes (when instructed) | Append to `[Unreleased]` only |
| Bump minor/patch version | Yes (when instructed) | Release-prep PRs only |
| Bump major version | **No** | Requires human approval |
| Open release-prep PR | Yes (when instructed) | Human merges |
| Prepare tag commands | Yes | In the PR description or a script |
| Push tags to remote | **No** | Requires human approval |
| Publish to registries | **No** | Requires human approval |
| Merge release PRs | **No** | Requires human approval |
| External announcements | **No** | Requires human approval |
| Enable auto-merge on a PR | Yes | Only with `--auto`; never `gh pr merge` without it |

## Dependency and Submodule Versioning

- Always commit lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`,
  `Pipfile.lock`, `poetry.lock`).
- Agents MUST NOT delete or regenerate lockfiles during feature work.
- Dependency updates are their own PR, never mixed into feature work.
- Agents MUST NOT run `npm update`, `pip install --upgrade`, or equivalent during
  feature work unless explicitly instructed.
- If a test fails because of a dependency, **report it** — do not fix it by
  updating the dependency.
- Submodule bumps are their own commit or PR, and name the target version or tag
  in the message. Never bump a submodule during unrelated feature work.
- After bumping a submodule, verify that references to vendored paths still
  resolve.

## Checklist

- [ ] Change classified against the right project-type row
- [ ] When unsure, classified as breaking
- [ ] CHANGELOG entry under the correct Keep a Changelog heading
- [ ] Consumer impact stated honestly, not minimised
- [ ] No existing entries rewritten or removed
- [ ] Version bump isolated to a release-prep commit
- [ ] Nothing tagged, published, or merged by the agent

## Common Pitfalls

| Pitfall | Consequence |
| --- | --- |
| Claiming "no consumer impact" for a deleted exported file | Misclassifies a major change as a patch; consumers break on update |
| Mixing a version bump into a feature commit | The release history stops being reconstructable |
| Rewriting an existing changelog entry to "improve" it | Destroys the record consumers already read |
| Regenerating a lockfile to make a test pass | Hides a real dependency failure and ships an unreviewed dependency graph |
| Bumping a submodule alongside unrelated work | Couples two independently reviewable changes |

## Related Skills

- `skills/git-branch-and-commit/SKILL.md` — why version bumps never ride along in a feature commit
- `skills/gh-pr-workflow/SKILL.md` — opening the release-prep PR, and the merge gate that stops there
- `skills/document-lifecycle/SKILL.md` — the document statuses a release closes out
