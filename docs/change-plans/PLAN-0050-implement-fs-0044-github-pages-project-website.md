---
type: change-plan
role: implementer
language: n/a
status: draft
related_specs: [FS-0044]
approved_by: ""
related_adrs: [ADR-0024, ADR-0026, ADR-0027, ADR-0030]
touches:
  - docs/specifications/FS-0044-github-pages-project-website.md
  - docs/change-plans/PLAN-0050-implement-fs-0044-github-pages-project-website.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-10-03
updated: 2026-10-03
---

# PLAN-0050: Implement FS-0044 — GitHub Pages project website

> **Template note:** this first revision publishes the governance package only:
> FS-0044, this plan, the two index rows, and the CHANGELOG entry. It does not
> add the site source, package dependencies, Pages workflow, tests, or README
> deployment link. The implementation revision must follow human approval of
> FS-0044 and a recorded approval for its exact reserved-path `touches:` set.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0044
* Related ADR ID(s): ADR-0024 (platform-neutral core with shipped bindings),
  ADR-0026 (approval is a recorded act), ADR-0027 (PLAN self-approval and
  reserved paths), ADR-0030 (decision records versus current-state documents)
* Issue / PR Reference: [#207](https://github.com/Tais-Den/conventional-agents/issues/207)

## 2. Scope of Change

**This documentation revision WILL:**

* Publish FS-0044 as a draft specification for a curated, allowlisted,
  adopter-facing GitHub Pages site.
* Publish this draft plan with documentation-only `touches:`.
* Add FS-0044 and PLAN-0050 to their README indexes with `draft` status.
* Add a CHANGELOG entry that names the proposed public guide as draft and does
  not claim the site is implemented or deployed.

**This documentation revision will NOT:**

* Modify `site/`, `package.json`, `package-lock.json`, `.gitignore`,
  `.github/workflows/`, `README.md`, or `test/FS-0044/`.
* Change any FS, PLAN, or ADR status.
* Configure GitHub Pages, create an environment, deploy an artifact, or add a
  custom domain.
* Publish a broad mirror of the repository or expose internal governance and
  test artifacts.

**The later implementation revision WILL, only after FS-0044 is approved and
its own reserved-path approval is recorded:**

* Add the Eleventy source tree under `site/`, including the curated pages,
  shared layout, styles, navigation, content manifest, and offline validators.
* Add pinned Node dependencies and `site:build`, `site:serve`, and `site:check`
  npm entry points; keep generated `_site/` output untracked.
* Add fixture-driven `test/FS-0044/**` coverage for publication boundaries,
  project-site base paths, generated links, accessibility structure, and
  reportable workflow invariants without live GitHub calls.
* Add `.github/workflows/pages.yml` using Node 20, the official Pages actions,
  PR build validation, `trunk`-only deployment, the `github-pages` environment,
  least-privilege permissions, and concurrency cancellation.
* Add the verified live Pages URL to `README.md` only after the first
  successful deployment and browser smoke check.
* Configure GitHub Pages and the environment as a human-controlled launch step;
  those settings are external to the repository and are not automated by the
  implementation workflow.

## 3. Tests Driving This Change

* Test file(s) in the implementation revision:

  * `test/FS-0044/website-content.bats` — fixture-driven validation of the
    manifest, rejected source paths, duplicate routes, path traversal,
    generated project-site links, source-link ownership, and workflow contract.

* Local commands in the implementation revision:

  * `npm run site:build`
  * `npm run site:check`
  * `npm run check:status`
  * `npm run lint:docs`
  * `npm test`
  * `npm run validate`

* Manual verification in the implementation revision:

  * Inspect the generated artifact to confirm only allowlisted content is
    present and `_site/` is not tracked.
  * Use a browser or local server at `/conventional-agents/` to check the home,
    nested route, 404 page, keyboard path, focus states, and narrow layout.
  * After the human configures Pages, read back the live root, deep link, 404,
    CSS/assets, and source links at the exact project URL.

## 4. Files to Be Modified

**This documentation revision:**

* `docs/specifications/FS-0044-github-pages-project-website.md`
* `docs/change-plans/PLAN-0050-implement-fs-0044-github-pages-project-website.md`
* `docs/specifications/README.md`
* `docs/change-plans/README.md`
* `CHANGELOG.md`

**Implementation revision, not this package:**

* `site/**`
* `.github/workflows/pages.yml`
* `package.json`
* `package-lock.json`
* `.gitignore`
* `test/FS-0044/**`
* `README.md`

## 5. Implementation Steps (High-Level)

1. Add the locked Eleventy toolchain and local site commands without changing
   canonical documents or committing generated output.
2. Define and validate the explicit content manifest, navigation data, source
   ownership, excluded-path rules, and project-site base-path configuration.
3. Build the shared semantic layout, responsive styles, no-JavaScript reading
   path, 404 page, metadata, source links, and adopter-facing pages from the
   approved information architecture.
4. Add offline generated-link and artifact checks, plus fixture-driven Bats
   coverage that fails on unsafe publication and base-path regressions.
5. Add the Pages workflow with PR build/upload behavior, `trunk`-only deploy,
   `github-pages` environment, least-privilege permissions, locked install,
   and concurrency cancellation.
6. Run the repository gates and inspect the generated artifact in a draft PR.
7. After the human-controlled Pages settings and merge path complete, verify
   the live deployment and then add its URL to `README.md`.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0044's curated-first scope, explicit manifest, source ownership,
    accessibility, offline validation, and public-publication boundary.
  * FS-0044 Non-Goals and Out of Scope are hard exclusions for the first
    release.

* ADR constraints:

  * ADR-0024: keep the public guide portable and distinct from the framework's
    platform-neutral canonical content; do not introduce a CMS or runtime
    dependency for the guide.
  * ADR-0026: approval is a human act with a locatable record; the implementation
    revision cannot reuse approval for this documentation-only `touches:` set.
  * ADR-0027: `.github/workflows/` and `package.json` are reserved paths, and
    the implementation revision cannot self-approve them.
  * ADR-0030: site summaries may explain current state, but canonical framework
    rules remain in their existing current-state documents.

* Architecture constraints:

  * `site/` is the source tree; `_site/` is generated and must not become a
    second source of truth.
  * The content manifest is the publication boundary; no broad repository glob
    may determine the public site.
  * The Pages workflow must use the official Pages actions and deploy only after
    the build succeeds on `trunk`.
  * Core validation must be offline after dependencies are installed and must
    not require GitHub credentials or a PAT.

## 7. Risks and Edge Cases

* GitHub project-site URLs require a base path; root-relative links can make a
  site appear correct at `/` while breaking every nested page after deployment.
* A canonical source path can disappear or move; validation must fail closed
  rather than leave a stale “Edit/source” link.
* Pages is a public publication channel; a permissive glob or generated log can
  expose internal content. The manifest and negative fixtures must cover this.
* A PR build must upload an artifact without deploying; the deployment job's
  event guard and environment must be checked structurally.
* Site dependencies can drift if CI uses unpinned `npx`; the lockfile and
  `npm ci` are required.
* A successful local build does not prove the repository Pages setting or
  environment is configured; live launch remains a separate human-controlled
  verification step.
* A future canonical-reference expansion must be a separate scope review, not
  an incidental change to the first manifest.

## 8. Validation

* Documentation package:

  * `npm run check:status`
  * `npm run check:freshness`
  * `npm run lint:docs`

* Implementation revision:

  * `npm run site:build`
  * `npm run site:check`
  * `bats test/FS-0044/website-content.bats`
  * `npm test`
  * `npm run validate`
  * Workflow YAML parser and structural assertions

* Manual checks:

  * Confirm `git status` is clean after deleting generated output and that no
    canonical Markdown changed during the site build.
  * Inspect `_site/` for excluded path names and accidental root-relative URLs.
  * Verify project-site deep links and the custom 404 locally and after launch.
  * Read back the Pages deployment URL and compare its commit to the merged
    `trunk` revision before adding the link to `README.md`.

## 9. Explicit Non-Changes

* No changes to the meaning or status of existing FS, PLAN, or ADR documents in
  the implementation revision.
* No migration of canonical framework documents out of their current paths.
* No custom domain, DNS, analytics, search service, CMS, server-side runtime,
  or user-account feature.
* No repository secrets, PAT, GitHub API call, or external-link fetch in the
  offline build and validation path.
* No automatic Pages configuration or deployment from pull-request branches.

## 10. Readiness Check

* [ ] Spec is approved
* [ ] Human approval covers the implementation `touches:` set, including the
  reserved Pages workflow and package paths
* [ ] Tests exist or are clearly defined
* [x] Scope is minimal and explicit
* [x] No implementation files are included in this documentation revision

## Declaration

I affirm that:

* This plan reflects the full intended scope of the website implementation.
* This revision is deliberately documentation-only and does not authorize code,
  workflow, package, or site changes.
* Any deviation or expansion of the public content boundary will require
  revising FS-0044 and this plan before implementation.
