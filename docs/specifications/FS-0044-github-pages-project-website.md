---
type: feature-spec
id: FS-0044
status: draft
title: GitHub Pages project website — curated adopter-facing public guide
owner: ajoeofalltrades
test_required: true
interfaces:
  - "site/**"
  - ".github/workflows/pages.yml"
  - "package.json"
  - "package-lock.json"
  - ".gitignore"
  - "test/FS-0044/**"
  - "README.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0024, ADR-0026, ADR-0027, ADR-0030]
supersedes: []
requires: []
tags: [github-pages, documentation-site, eleventy, public-surface, allowlist, accessibility]
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

# Feature Spec: GitHub Pages project website — curated adopter-facing public guide

## Status

- Draft

## Plan Status

- **PLAN-0050 is `draft`.** This first revision publishes the governance package
  only: this spec, the plan, the two index rows, and the CHANGELOG entry.
- The implementation revision must be created only after human approval. It will
  declare the full `touches:` set for the site, build toolchain, test suite,
  README link, and Pages workflow. The workflow and package files are reserved
  paths under `ADR-0027`, so that revision requires recorded human approval for
  its exact implementation surface.

## Summary

The repository is a documentation and standards kit whose current entry point is
optimized for maintainers and agents already working from a checkout. This
feature adds a curated, adopter-facing static website at the repository's
GitHub Pages project URL. The site explains the framework, guides a new adopter
through integration choices, and links back to canonical repository documents.
It does not replace those documents or publish the repository by broad Markdown
glob; an explicit content manifest defines what the public guide may reference
and render.

## Problem / Evidence

A new adopter currently has to infer the framework's structure and recommended
starting path from root Markdown and internal governance records. That is a
valid source-of-truth arrangement for vendoring, but it is a poor public front
door. A project site can improve discovery without creating a second canonical
copy if it labels summaries as summaries, preserves exact source links, and
keeps publication allowlisted.

The site is a public delivery surface. GitHub Pages is therefore treated as a
publication boundary, not merely as another local build target: content must be
selected intentionally, generated output must be reviewed, and deployment must
be limited to the default branch.

## Goals

- Publish a useful first-visit guide for framework adopters at
  `https://tais-den.github.io/conventional-agents/`.
- Explain the framework's purpose, exported surface, roles, session modes,
  document lifecycle, integration patterns, contribution path, and current
  status using the repository's existing guidance.
- Keep existing Markdown files in their current locations as the canonical
  framework artifact.
- Use an explicit content manifest that distinguishes site-authored summaries
  from canonical-source links and rejects unreviewed or internal paths.
- Build a deterministic static site locally with Eleventy on Node 20 and a
  committed lockfile.
- Build and validate on pull requests, but deploy to GitHub Pages only from
  `trunk` through the `github-pages` environment.
- Provide semantic, keyboard-accessible pages that remain readable without
  JavaScript.
- Keep site validation offline after dependencies are installed, so external
  network availability is not required for the core build.

## Non-Goals

- Migrating canonical framework documents into a new documentation system.
- Mirroring every Markdown file or exposing `test/`, `vendor/`, logs, generated
  output, orchestration evidence, or other internal paths by default.
- Adding a CMS, server-side runtime, client-side single-page application, or
  hosted search service in the first release.
- Adding a custom domain, DNS configuration, or `CNAME` file in this feature.
- Changing the meaning, status, or lifecycle of existing framework documents.
- Making external-link availability a blocking requirement for the offline site
  build.
- Adding a second full governance test suite to the Pages workflow.

## Users / Stakeholders

- New adopters deciding whether and how to integrate conventional-agents.
- Contributors looking for the framework's public structure and contribution
  expectations.
- Maintainers who need the public guide to remain aligned with canonical files.
- Reviewers responsible for the repository's public publication boundary.

## Interfaces

- Type: UI + static build + CI/deployment infrastructure.
- Details:
  - `site/**` — Eleventy source, templates, styles, content manifest,
    navigation data, and offline validation scripts.
  - `.github/workflows/pages.yml` — pull-request build and `trunk`-only Pages
    deployment using the official GitHub Pages Actions.
  - `package.json` and `package-lock.json` — pinned site dependencies and
    `site:build`, `site:serve`, and `site:check` entry points.
  - `.gitignore` — excludes generated `_site/` output and local site caches.
  - `test/FS-0044/**` — fixture-driven validation of the content boundary,
    generated links, and workflow contract without live GitHub calls.
  - `README.md` — published-site link added only after the live deployment is
    verified.
  - The two document indexes and `CHANGELOG.md` — governance package and
    consumer-facing tracking surfaces.

## Success Criteria

Each criterion is objectively testable.

- **SC-1 — clean deterministic build.** Given a clean checkout with the locked
  Node dependencies installed, when `npm run site:build` runs, then it exits
  zero, creates `_site/index.html` and `_site/404.html`, and does not modify
  canonical Markdown or leave generated files tracked by Git.
- **SC-2 — explicit publication boundary.** Given the site content manifest,
  when the site validator runs, then every published or rendered source is
  declared there with a route, title, audience, kind, and repository source
  path, and no site page is generated from an undeclared source.
- **SC-3 — unsafe manifest entries fail closed.** Given a manifest containing a
  missing source, duplicate route, path traversal, or a path under `vendor/`,
  `test/`, `docs/orchestration/`, generated output, or a log file, when the
  validator runs, then it exits non-zero and names the offending entry.
- **SC-4 — project-site paths are correct.** Given
  `SITE_BASE_PATH=/conventional-agents/`, when the site builds and the generated
  HTML is checked, then internal links and asset URLs preserve that base path,
  nested routes work, and no accidental root-relative site link bypasses it.
- **SC-5 — summaries retain source ownership.** Given a site page that explains
  framework behavior, when a reader follows its source link, then the link
  resolves to the exact repository path declared for that page and the page
  identifies the site text as a guide or summary rather than silently claiming
  to be canonical.
- **SC-6 — accessible core layout.** Given the generated home, nested, and 404
  pages, when their HTML is inspected and navigated with a keyboard, then each
  has one document title and one H1, semantic landmarks, a skip link, visible
  focus states, usable headings, and a recovery link from the 404 page; the
  pages remain usable with JavaScript disabled.
- **SC-7 — pull requests build without deployment.** Given a pull request that
  changes the site or its declared source inputs, when the Pages workflow runs,
  then it checks out Node 20, installs the lockfile, runs `npm run site:check`,
  and uploads a Pages artifact without invoking the deployment action.
- **SC-8 — only trunk deploys.** Given a successful build on `trunk`, when the
  Pages workflow runs, then the deployment job targets the `github-pages`
  environment and uses only the least-privilege `pages: write` and
  `id-token: write` permissions required by the official Pages actions; given a
  non-trunk event, then the deployment job is skipped.
- **SC-9 — existing governance remains green.** Given the completed website
  change, when `npm run check:status`, `npm run lint:docs`, and `npm test` run,
  then the existing governance indexes, document lint, and self-test suite pass.
- **SC-10 — live project site is coherent.** Given the repository Pages setting
  is configured for GitHub Actions and a successful `trunk` deployment, when a
  browser requests the project URL, a nested route, and an unknown route, then
  the home page, CSS/assets, deep link, and custom 404 page load over HTTPS and
  the source links point to the same repository revision as the deployment.

## Edge Cases

- A project-site base path must work with and without a trailing slash in the
  build configuration without producing doubled or missing separators.
- A canonical source path can be deleted or renamed; the validator must fail
  rather than silently publishing a stale source link.
- A manifest glob or directory-like entry that expands to no files is invalid;
  publication requires an explicit, existing source path.
- A nested route must load its assets and navigation from a direct request, not
  only after navigating from the home page.
- External links may be present, but the offline build does not fetch them.
- GitHub Pages repository visibility and organization policy may make the live
  site public even when source access differs; launch review must account for
  that publication behavior.

## Out of Scope

- Full canonical-document rendering and search across the entire repository.
- Publishing internal FS, PLAN, ADR, test, orchestration, or vendor history as
  a navigable site section.
- Custom-domain setup, DNS, analytics, comments, or user accounts.
- Automated semantic review of whether a summary still captures every detail of
  its canonical source.
- A hosted link checker that requires GitHub, npm, or another network service at
  build time.

## Dependencies

- Node 20 and the repository's package-lock file.
- Eleventy and the minimum pinned build dependencies selected by the
  implementation revision.
- The canonical `README.md`, `INTEGRATION.md`, exported directories, and
  selected architecture/status documents.
- GitHub Actions, the official Pages actions, repository Pages settings, and the
  `github-pages` environment.
- Human review and approval of the FS/PLAN package and the reserved workflow and
  package paths before implementation.

## Rollout / Migration

- Land the FS/PLAN governance package as a draft and keep the implementation
  blocked until human approval is recorded.
- Implement and validate the curated site on a draft PR; review the generated
  artifact and manifest boundary before enabling deployment.
- Configure GitHub Pages to use GitHub Actions and restrict deployment to
  `trunk` through the `github-pages` environment.
- Deploy the first release from `trunk`, verify the live root, deep link, 404,
  assets, and source links, then add the published URL to `README.md`.
- Treat selected canonical reference pages, search, and custom domains as
  separate follow-up decisions rather than silently expanding this scope.

## Observability

- Logs: workflow build, validation, artifact-upload, and deployment logs name
  the build commit and failing manifest/link entry where applicable.
- Metrics: none required for the first release.
- Traces: none; the generated artifact, workflow run, and Pages deployment URL
  are the evidence chain.

## Security / Privacy

- Data handled: public framework documentation and Git metadata needed for
  source links; no credentials or user-submitted data.
- Threats considered: accidental publication of internal files, stale source
  links, project-site path confusion, and workflows with broader permissions
  than required.
- Mitigations: explicit allowlist validation, excluded-path tests, locked
  dependencies, no secrets or PAT, `contents: read` defaults, Pages-specific
  write/OIDC permissions only in the deployment job, and trunk-only deployment.

## Open Questions

- None blocking for the governed package. Custom domains, search, and the size
  of a future canonical-reference corpus require separate scope decisions.
