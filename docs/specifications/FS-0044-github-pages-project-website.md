---
type: feature-spec
id: FS-0044
status: draft
title: GitHub Pages project website — curated adopter-facing public guide
owner: ajoeofalltrades
test_required: true
interfaces:
  - "site/**"
  - "scripts/check-site-publication.mjs"
  - "scripts/README.md"
  - ".github/workflows/pages.yml"
  - "package.json"
  - "site/package.json"
  - "site/package-lock.json"
  - ".gitignore"
  - "test/FS-0044/**"
  - "README.md"
  - "AGENTS.md"
  - "INTEGRATION.md"
  - "docs/specifications/README.md"
  - "docs/change-plans/README.md"
  - "docs/change-plans/PLAN-0050-implement-fs-0044-github-pages-project-website.md"
  - "docs/decisions/ADR-0044-curated-public-github-pages-derivative.md"
  - "docs/decisions/README.md"
  - "CHANGELOG.md"
related_adrs: [ADR-0024, ADR-0026, ADR-0027, ADR-0030, ADR-0044]
supersedes: []
requires: [FS-0022, FS-0039]
tags: [github-pages, documentation-site, eleventy, public-surface, allowlist, accessibility]
created: 2026-10-03
updated: 2026-10-04
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

- **PLAN-0050 is `draft`.** This revision resolves review feedback and declares
  the complete intended implementation `touches:` set, including the reserved
  validator, workflow, package, and decision paths.
- FS-0044, PLAN-0050, and ADR-0044 remain draft/proposed. No implementation is
  authorized until a human approves the final documents and the exact declared
  `touches:` set. The eventual implementation may remain in this PR (#208), as
  long as that approval is recorded before implementation files are added.
- The first launch assumes a private source repository and a public Pages
  derivative. The required GitHub organization/account capability, trunk
  protection, and `github-pages` environment reviewers are launch preconditions,
  not assumptions hidden in the implementation.

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
- Use an explicit content manifest that distinguishes rendered summaries from
  link-only canonical sources and rejects unreviewed or internal paths.
- Build a deterministic static site locally with Eleventy on Node 24 LTS and a
  site-scoped committed lockfile.
- Build and validate on pull requests, but deploy to GitHub Pages only from
  `trunk` through the `github-pages` environment.
- Keep the source repository private while publishing only the allowlisted
  derivative, and label repository source links as requiring source access.
- Treat `site/` as an internal governance build input and the generated Pages
  artifact as a public derivative; consumers must not treat `site/` as exported
  framework content.
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
- Changing repository visibility, or claiming that anonymous visitors can read
  private repository source links.
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
  - `site/**` — internal Eleventy source, templates, styles, content manifest,
    navigation data, and site-scoped dependency metadata. It is not an
    exported framework path for consumers.
  - `scripts/check-site-publication.mjs` — reserved-path validator for manifest
    entries, source digests, symlink/case-folding safety, and artifact inventory.
  - `scripts/README.md` — the validator's Category 1 gate contract.
  - `.github/workflows/pages.yml` — pull-request build and `trunk`-only Pages
    deployment using the official GitHub Pages Actions.
  - `package.json` — root delegating `site:build`, `site:serve`, and `site:check`
    entry points. `site/package.json` and `site/package-lock.json` hold the
    Eleventy dependency tree without changing the framework's root lockfile.
  - `.gitignore` — excludes generated `_site/` output and local site caches.
  - `test/FS-0044/**` — fixture-driven validation of the content boundary,
    generated links, artifact inventory, and workflow contract without live
    GitHub calls or an Eleventy install.
  - `README.md` — published-site link added only after the live deployment is
    verified.
  - `AGENTS.md` and `INTEGRATION.md` — classify `site/` as internal source and
    state that vendored consumers must not reference it; `check-conformance`
    continues to inspect only consumer anchors and framework gate wiring.
  - The two document indexes and `CHANGELOG.md` — governance package and
    consumer-facing tracking surfaces.
  - `docs/decisions/ADR-0044-curated-public-github-pages-derivative.md` and
    its index row — the proposed architecture decision for the private-source,
    public-derivative publication channel and Node toolchain.

## Success Criteria

The structural criteria are checked offline; the manual browser criterion is an
explicit acceptance procedure rather than an assertion hidden in a shell test.

- **SC-1 — clean deterministic build.** Given a clean checkout with the locked
  Node 24 dependencies installed under `site/`, when `npm run site:build` runs,
  then it exits zero, creates `_site/index.html` and `_site/404.html`, and does
  not modify canonical Markdown or leave generated files tracked by Git.
- **SC-2 — explicit publication boundary.** Given the site content manifest,
  when the site validator runs, then every page is declared with a route, title,
  audience, `kind` (`rendered` or `link-only`), and exact repository source
  path. A `rendered` entry also declares `content_kind` (`guide` or `summary`)
  and `reviewed_source_digest`; no page is generated from an undeclared source.
- **SC-3 — unsafe manifest entries fail closed.** Given a manifest containing a
  missing source, duplicate route, path traversal, a symlink whose target is
  outside the allowed source roots, a case-folded path collision, or a path
  under `vendor/`, `test/`, `docs/decisions/`, `docs/specifications/`,
  `docs/change-plans/`, `docs/proposals/`, `docs/orchestration/`,
  `docs/validation-baseline*`, `BACKLOG.md`, `.claude/`, `.github/`, `config/`,
  `benchmark/`, generated output, or a log file, when the validator runs, then
  it exits non-zero and names the offending entry.
- **SC-4 — artifact inventory is exact.** Given a successful build, when the
  validator compares `_site/` with the manifest-derived route set, `404.html`,
  and the manifest's explicit asset list, then every generated file is expected
  and every expected file exists; any extra file, passthrough copy, or undeclared
  asset fails the check.
- **SC-5 — project-site paths are correct.** Given
  `SITE_BASE_PATH=/conventional-agents/`, when the site builds and the generated
  HTML is checked, then internal links and asset URLs preserve that base path,
  nested routes work, the nested 404 page uses base-prefixed assets, and no
  accidental root-relative site link bypasses it.
- **SC-6 — summaries retain source ownership.** Given a site page that explains
  framework behavior, when the generated HTML is inspected, then its visible
  and machine-readable marker identifies it as a `guide` or `summary`, its
  source URL is SHA-pinned to the build revision and uses the exact manifest
  path, and its page states that repository access may be required. Anonymous
  access to the private GitHub source URL is not treated as a launch failure;
  the public page must remain useful without following it.
- **SC-7a — accessible core structure.** Given the generated home, nested, and
  404 pages, when their HTML is inspected, then each has one document title and
  one H1, semantic landmarks, a skip link, a required content-kind marker, and a
  recovery link from the 404 page; the pages contain no required JavaScript.
- **SC-7b — accessible browser path.** In a manual browser acceptance check with
  JavaScript disabled, a reviewer can keyboard-navigate the home, nested route,
  and 404 page, observe visible focus, and use the headings and recovery link.
- **SC-8 — pull requests build without deployment.** Given a pull request that
  is opened or updated, when the Pages workflow runs without a path filter, then
  it checks out Node 24, installs `site/package-lock.json`, runs
  `npm run site:check`, and uploads a Pages artifact without invoking the
  deployment action. Running on every pull request prevents a required check
  from remaining in an expected-but-skipped state.
- **SC-9 — only trunk deploys.** Given a successful build on `trunk`, when the
  Pages workflow runs, then the deployment job targets the `github-pages`
  environment and uses only the least-privilege `pages: write` and
  `id-token: write` permissions required by the official Pages actions; given a
  non-trunk push, pull request, or `workflow_dispatch` ref, then the deployment
  job is skipped. The deployment guard checks the ref, not only the event name.
- **SC-10 — existing governance remains green without site dependencies.** Given
  the completed website change, when `npm run check:status`, `npm run lint:docs`,
  `npm test`, and `npm run validate` run, then the existing governance gates pass.
  `test/FS-0044/**` exercises the validator with fixtures and does not require
  Eleventy; only the Pages workflow's site build installs the site dependency
  tree.
- **SC-11 — live private-source/public-derivative site is coherent.** Before
  launch, the organization/account capability for a public Pages site sourced
  from this private repository is verified, trunk protection requires a PR with
  the required checks, and the `github-pages` environment requires reviewers.
  After a successful `trunk` deployment, a browser requests the project URL, a
  nested route, and an unknown route; the home page, CSS/assets, deep link, and
  custom 404 page load over HTTPS, and source URLs identify the same deployment
  revision while honestly requiring repository authorization where applicable.

## Edge Cases

- A project-site base path must work with and without a trailing slash in the
  build configuration without producing doubled or missing separators.
- A canonical source path can be deleted or renamed; the validator must fail
  rather than silently publishing a stale source link.
- A manifest glob or directory-like entry that expands to no files is invalid;
  publication requires an explicit, existing source path.
- A nested route must load its assets and navigation from a direct request, not
  only after navigating from the home page.
- A `404.html` request from a nested route must still resolve its CSS and
  recovery link through the project-site base path.
- External links may be present, but the offline build does not fetch them.
- The repository remains private while the site is public only if the selected
  GitHub organization/account capability is explicitly verified; otherwise the
  deployment is blocked rather than silently changing repository visibility.
- A source link may be inaccessible to an anonymous reader because the source
  repository is private; the rendered page must state that boundary and remain
  readable without the link.

## Out of Scope

- Full canonical-document rendering and search across the entire repository.
- Publishing internal FS, PLAN, ADR, test, orchestration, or vendor history as
  a navigable site section.
- Treating `site/` or the generated Pages artifact as part of the framework's
  exported vendoring surface. A submodule consumer may receive the source tree,
  but consumer guidance must not reference it; archive `export-ignore` is not
  used as a substitute for that contract.
- Custom-domain setup, DNS, analytics, comments, or user accounts.
- Automated semantic review of whether a summary still captures every detail of
  its canonical source.
- A hosted link checker that requires GitHub, npm, or another network service at
  build time.

## Dependencies

- Node 24 LTS and the site-scoped `site/package-lock.json` file.
- Eleventy and the minimum pinned build dependencies selected by the
  implementation revision.
- The canonical `README.md`, `AGENTS.md`, `INTEGRATION.md`, and explicitly
  allowlisted exported directories named by the manifest.
- A verified GitHub organization/account capability for a public Pages site
  sourced from a private repository, plus the official Pages actions, trunk
  protection, and the `github-pages` environment with required reviewers.
- Human review and approval of the FS/PLAN package and the reserved workflow and
  package paths before implementation.

## Rollout / Migration

- Land the FS/PLAN governance package as a draft and keep the implementation
  blocked until human approval is recorded for the final full `touches:` set.
- Implement and validate the curated site in the same draft PR (#208); review
  the generated artifact, manifest boundary, source-link access behavior, and
  workflow guard before enabling deployment.
- Before the first deployment, verify that the private repository's
  organization/account configuration supports a public GitHub Pages site,
  protect `trunk` with pull-request review and required CI checks, and configure
  required reviewers on the `github-pages` environment. If any precondition is
  unavailable, do not change repository visibility and do not deploy.
- Configure GitHub Pages to use GitHub Actions and restrict deployment to
  `trunk` through the protected `github-pages` environment.
- Deploy the first release from `trunk`, verify the live root, deep link, 404,
  assets, source-link revision, and the expected private-source access boundary,
  then add the published URL to `README.md`.
- Treat selected canonical reference pages, search, and custom domains as
  separate follow-up decisions rather than silently expanding this scope.

## Observability

- Logs: workflow build, validation, artifact-inventory, upload, and deployment
  logs name the build commit and failing manifest/source entry where applicable.
- Metrics: none required for the first release.
- Traces: none; the generated artifact, workflow run, and Pages deployment URL
  are the evidence chain.

## Security / Privacy

- Data handled: allowlisted public-guide content and Git metadata needed for
  SHA-pinned source links; no credentials or user-submitted data.
- Threats considered: accidental publication of private files, stale summaries,
  symlink/case-folding escapes, project-site path confusion, anonymous readers
  being misled about private source access, and workflows with broader
  permissions than required.
- Mitigations: explicit rendered/link-only manifest validation, source-digest
  checks, exact artifact inventory, rejected paths and symlinks, locked
  site-scoped dependencies, no secrets or PAT, `contents: read` defaults,
  Pages-specific write/OIDC permissions only in the deployment job, protected
  trunk, and required environment reviewers.

## Open Questions

- **Blocking launch precondition:** does the Tais-Den GitHub organization/account
  have the Pages capability and access configuration required to publish a
  public site from this private repository? Verify this before enabling Pages;
  the fallback is to hold deployment, not to make the repository public.
- Source links in the public derivative are SHA-pinned and honest about source
  authorization; changing that to public source links would require a separate
  repository-visibility decision.
- Custom domains, search, and the size of a future canonical-reference corpus
  require separate scope decisions.
