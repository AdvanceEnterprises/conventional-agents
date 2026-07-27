---
type: adr
id: ADR-0017
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0001
  - FS-0008
  - FS-0009
superseded_by: null
---

# ADR-0017: Framework vendor directory is internal; consumers must not reference nested submodules

## Status

- Proposed

## Context and Problem Statement

conventional-agents vendors several upstream resources as Git submodules:

- `vendor/madr` — MADR markdownlint config and template
- `vendor/conventional-commits` — Conventional Commits specification
- `vendor/keep-a-changelog` — Keep a Changelog specification
- `vendor/arc42-template` — arc42 architecture template

These submodules were originally included to provide provenance, reference,
and in one case a byte-equality test for the framework's own tooling.
However, the boundary between what the framework uses internally and what
consumers may reference has become unclear.

Specifically:

1. Some framework files point consumers at nested submodule paths
   (e.g., "vendored at `vendor/conventional-commits/`"), implying consumers
   should look inside `vendor/conventional-agents/vendor/` for authoritative
   content.
2. Some submodules are not actually used by CI or tooling
   (`conventional-commits`, `keep-a-changelog`, `arc42-template`), yet they
   still get cloned into every consumer's checkout.
3. The only operational submodule, `vendor/madr`, is used for a framework
   byte-equality test, not for consumer reference.

This ADR defines the boundary: the framework's `vendor/` directory is
**framework-internal**, and consumers must not be asked to reference paths
inside it.

This ADR partially supersedes FS-0009, which added
`vendor/conventional-commits/` and `vendor/keep-a-changelog/` as submodules.
Those submodules are now removed from the consumer-facing surface.

**Why FS-0001 and FS-0008 are related:** FS-0001 (markdownlint implementation)
and FS-0008 (self-versioning and changelog) are the framework's quality gates
that help detect future drift between the framework's curated copies and any
remaining upstream references.

## Decision Drivers

- **Exported surface clarity** — Consumers should see only the framework's own
  files as authoritative. `vendor/conventional-agents/vendor/...` paths must
  not leak into consumer documentation, AGENTS.md, or tooling.
- **No wrapper drift** — Where the framework wraps an upstream resource, the
  wrapped copy (in `templates/`, `docs/`, `workflows/`, etc.) is the contract.
  Referencing both the wrapper and the upstream submodule invites drift.
- **No unused dependencies in consumer clones** — Submodules that are not
  operational inside the framework should not be vendored at all.
- **Dogfooding is not consumer exposure** — `vendor/madr` may remain for the
  framework's internal byte-equality test, but that is a framework concern,
  not a consumer concern.

## Considered Options

### Option A: Consumers vendor all four submodules directly

Require consuming projects to vendor `madr`, `conventional-commits`,
`keep-a-changelog`, and `arc42-template` as sibling submodules alongside
`conventional-agents`, so they never need to reference nested paths.

### Option B: Consumers vendor only the submodules they directly use

Similar to Option A, but each consumer chooses which submodules to vendor
based on its needs.

### Option C: Framework's vendor directory is internal; consumers use framework files and URLs (chosen)

- Drop submodules that are not operationally needed by the framework's CI or
  tooling (`conventional-commits`, `keep-a-changelog`, `arc42-template`).
- Keep `vendor/madr` as framework-internal infrastructure for the
  byte-equality test.
- Update all consumer-facing documentation to reference framework files or
  upstream URLs, never nested submodule paths.
- Document in `INTEGRATION.md` that `vendor/conventional-agents/vendor/...` is
  framework-internal and must not appear in consumer docs.

### Option D: Keep status quo

Leave all four submodules in place and continue referencing them in consumer
facing docs.

## Decision Outcome

**Chosen option: Option C — Framework vendor directory is internal; consumers
use framework files and URLs.**

### Rules

1. **The `vendor/` directory inside `conventional-agents` is framework-internal.**
   Consuming projects must not reference paths inside
   `vendor/conventional-agents/vendor/` in their own documentation,
   AGENTS.md, CLAUDE.md, tool configs, or scripts.

2. **Submodules used only for reference or provenance are dropped.**
   `vendor/conventional-commits/`, `vendor/keep-a-changelog/`, and
   `vendor/arc42-template/` are removed from the framework repo.

3. **`vendor/madr/` remains as internal infrastructure.**
   It supports the `test/FS-0001/adr-linting.bats` byte-equality test and
   template provenance. It is not part of the consumer contract.

4. **Consumer-facing references are updated.**
   Where framework docs previously said "vendored at
   `vendor/conventional-commits/`", they now either cite the upstream URL or
   state that the framework follows a curated subset.

### Why not the other options?

**Option A** and **Option B** expose consumers to the upstream submodules
and create version-drift risk between the framework's curated copy and the
consumer's raw upstream read. They also require every consumer to manage
multiple submodules. The boundary problem is better solved by keeping the
submodules internal and exposing only framework files.

**Option D** leaves the boundary unclear and ships unused submodules to every
consumer, increasing clone cost and confusion.

### Consequences

**Good:**

- The consumer contract is clear: `vendor/conventional-agents/` contains the
  framework; nested paths are off-limits.
- Consumers clone fewer unused submodules.
- Framework files become the unambiguous source of truth for consumers.
- No drift risk between framework wrappers and consumer-visible upstream reads.

**Bad:**

- Consumers who want the full upstream spec must consult URLs rather than a
  local submodule copy. This is minor — the framework is a standards kit, not a
  mirror of every upstream spec.
- `vendor/madr` remains the only internal submodule, which is a small
  inconsistency that must be explained.

**Neutral:**

- This ADR is closely related to ADR-0016 (consumer conventions), but the
  scope is different. ADR-0016 is about where *consumer-specific* content
  lives; ADR-0017 is about where *framework-internal* upstream dependencies
  live.

## Validation

We will consider this decision successful if:

1. `git submodule status` in a fresh clone of `conventional-agents` shows only
   `vendor/madr/` (plus any future operational submodules added by later
   decisions).
2. No consumer-facing file in the framework repo references
   `vendor/conventional-agents/vendor/...` paths.
3. The framework's own tests, docs, and workflows still pass after the
   submodule removal and reference updates.
4. Consumers report that the framework's exported surface is easier to
  understand.

## Links

- ADR-0016: Consumer conventions — local adaptations of the framework
- FS-0001: ADR linting and quality gates
- FS-0008: Self-versioning and release process
- INTEGRATION.md § Pattern 4: submodule + consumer conventions repo
- `templates/core/adr-full-madr.md`
- `workflows/git-and-gh-conventions.md`
- `workflows/versioning-and-releases.md`
