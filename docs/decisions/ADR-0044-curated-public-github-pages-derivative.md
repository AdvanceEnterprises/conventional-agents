---
type: adr
id: ADR-0044
status: proposed
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0044
superseded_by: null
---
<!--
PARSING_HINTS:
- This document records a decision and its rationale.
- Treat accepted ADRs as binding constraints.
- Do NOT modify implementation choices that conflict with this ADR.
- Do NOT invent new options or reinterpret the decision.
- Use this document only to constrain or explain behavior, not to generate code.
-->

# ADR-0044: Curated public GitHub Pages derivative from a private source repository

## Status

- Proposed

## Context and Problem Statement

`FS-0044` introduces a public adopter-facing website for a repository that is
currently private. The website is useful as a public guide, but the repository's
canonical Markdown, governance history, and source links must not become public
merely because a Pages artifact is published. GitHub organization and account
capabilities differ, so the repository cannot assume that a public Pages site
from a private source repository is available.

The feature also introduces a publication boundary and a new Node toolchain to a
framework whose canonical artifact is Markdown and whose own governance scripts
are protected by reserved-path rules in `ADR-0027`. Those choices need one
architecture record rather than being inferred from a site implementation.

## Decision Drivers

- Keep canonical framework documents and internal governance history private.
- Provide a useful public guide when the selected GitHub capability supports it.
- Make the publication boundary explicit, reviewable, and fail closed.
- Avoid treating a generated website as a second canonical framework surface.
- Use a supported runtime and keep site dependencies separate from the framework's
  existing root dependency tree.
- Prevent direct or unreviewed trunk changes from becoming public deployments.

## Considered Options

### Option A — Make the source repository public

GitHub Pages and repository source links would have the same public access model.
This is simple, but it exposes the complete repository, including internal
history and governance documents that are intentionally not part of the site's
public information architecture.

### Option B — Publish a curated Pages derivative from the private repository

Keep the source repository private and publish only the allowlisted static
artifact when the GitHub organization/account plan explicitly supports a public
Pages site from a private source. Rendered pages retain source ownership through
SHA-pinned metadata and links, but the site does not claim that anonymous readers
can open private repository URLs.

### Option C — Defer the Pages launch

Implement and validate the site locally and in pull requests, but do not enable
Pages until the access capability and launch controls are verified. This avoids
an unsupported or misleading deployment, at the cost of delaying public
availability.

## Decision Outcome

**Chosen option: Option B, with Option C as the fail-closed fallback.**

1. The source repository remains private for the first release.
2. GitHub Pages may publish a public derivative only after the Tais-Den
   organization/account capability is verified for this exact repository and
   access model. If that capability is unavailable or ambiguous, Pages remains
   disabled; repository visibility is not changed as a workaround.
3. `site/` is an internal governance build input. The generated Pages artifact is
   a public derivative, not an exported framework path that consumers should
   reference or vendor as canonical content.
4. The manifest distinguishes `rendered` and `link-only` entries. Every entry
   names an exact source path; rendered guide/summary entries carry a reviewed
   source digest. The validator rejects internal paths, traversal, symlink
   escapes, case-folded collisions, and undeclared artifact files.
5. Source URLs are pinned to the deployment commit and visibly state that
   repository authorization may be required. Public pages remain useful without
   following a private source URL.
6. The site uses Node 24 LTS through a site-scoped package and lockfile. The root
   package exposes only delegating `site:build`, `site:serve`, and `site:check`
   commands.
7. The Pages workflow builds pull requests without deploying and deploys only
   from `trunk`. First launch requires both protected-trunk review/check rules
   and required reviewers on the `github-pages` environment.

## Consequences

### Positive

- The public surface is deliberately smaller than the private source repository.
- Adopters can use the guide without the framework's internal governance history
  becoming a navigable public section.
- SHA-pinned source metadata makes each deployment reproducible and preserves
  ownership even when source access requires authentication.
- A supported Node LTS and site-scoped lockfile reduce runtime and dependency
  coupling with the framework's governance tooling.
- Protected trunk and environment reviewers make the public deployment boundary
  explicit and human-controlled.

### Negative

- Public readers cannot necessarily open the repository source links anonymously.
  The site must explain that boundary rather than pretending the links are public.
- The launch depends on a GitHub organization/account capability that must be
  verified outside the repository files.
- The manifest, source digests, and artifact inventory add maintenance work.
- The implementation touches reserved paths and therefore cannot rely on
  `ADR-0027` self-approval.

### Neutral

- Making the repository public remains a separate human decision and is not
  implied by this ADR.
- A future decision may publish a broader canonical-reference corpus, change the
  repository visibility model, or use another hosting provider.
- `export-ignore` is not used to define the consumer boundary because submodule
  consumers receive a checkout rather than a `git archive`; classification and
  integration guidance remain the authoritative controls.

## Validation

- The FS-0044 validator rejects an undeclared page or asset, an internal source
  path, a traversal or symlink escape, and a case-insensitive collision.
- The manifest records `rendered` versus `link-only`, `content_kind`, and the
  reviewed source digest; the build emits the deployment revision in source URLs.
- The Pages workflow structurally proves PR build-without-deploy, trunk-only
  deployment, explicit `workflow_dispatch` ref guarding, least-privilege deploy
  permissions, and the `github-pages` environment.
- Before launch, a human reads back the GitHub Pages capability, trunk protection,
  environment reviewers, and the live public site's access behavior.
- Revisit this ADR if the private-source/public-derivative capability cannot be
  verified, if source links are expected to be anonymous, or if the site becomes
  an exported framework surface.

## Links

- FS-0044: GitHub Pages project website — curated adopter-facing public guide.
- ADR-0024: Platform-neutral core with shipped bindings.
- ADR-0027: PLAN self-approval within declared interfaces.
- ADR-0030: Decision records versus current-state documents.
- [GitHub Pages documentation](https://docs.github.com/en/pages)
- [Node.js release schedule](https://nodejs.org/en/about/previous-releases)
