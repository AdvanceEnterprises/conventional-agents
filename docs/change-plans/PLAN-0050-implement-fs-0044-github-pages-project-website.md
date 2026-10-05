---
type: change-plan
role: implementer
language: n/a
status: approved
related_specs: [FS-0044]
approved_by: "Joey Clark <administrator@ajoeofalltrades.dev>"
related_adrs: [ADR-0024, ADR-0026, ADR-0027, ADR-0030, ADR-0044]
touches:
  - site/**
  - scripts/check-site-publication.mjs
  - scripts/README.md
  - .github/workflows/pages.yml
  - package.json
  - site/package.json
  - site/package-lock.json
  - .gitignore
  - test/FS-0044/**
  - README.md
  - AGENTS.md
  - INTEGRATION.md
  - docs/specifications/FS-0044-github-pages-project-website.md
  - docs/change-plans/PLAN-0050-implement-fs-0044-github-pages-project-website.md
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - docs/decisions/ADR-0044-curated-public-github-pages-derivative.md
  - docs/decisions/README.md
  - CHANGELOG.md
created: 2026-10-03
updated: 2026-10-04
---

# PLAN-0050: Implement FS-0044 — GitHub Pages project website

> **Approval note:** this revision resolves the publication-boundary, runtime,
> private-source, launch-control, and ADR-0027 feedback on PR #208. The complete
> intended implementation `touches:` set is declared above and was approved by
> the status-transition commit carrying the matching `Approved-By:` and
> `Approved-Artifacts:` trailers. The complete implementation may now be added
> to this same draft PR, within that exact set.

The approval record is the status-transition commit defined by
[`ADR-0026`](../decisions/ADR-0026-approval-is-a-recorded-act.md), with
`Approved-By:` and `Approved-Artifacts:` trailers naming the exact governed
artifacts. This commit records the human approval; a PR review or comment alone
would be evidence of discussion, not the approval record that authorizes
implementation.

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0044
* Related ADR ID(s): ADR-0024 (platform-neutral core with shipped bindings),
  ADR-0026 (approval is a recorded act), ADR-0027 (PLAN self-approval and
  reserved paths), ADR-0030 (decision records versus current-state documents),
  ADR-0044 (private-source, public-derivative Pages publication)
* Issue / PR Reference: [#207](https://github.com/Tais-Den/conventional-agents/issues/207)

## 2. Scope of Change

**This governance-and-approval revision WILL:**

* Revise FS-0044 as a draft specification for a curated, allowlisted,
  adopter-facing GitHub Pages derivative sourced from a private repository.
* Publish proposed ADR-0044 and its decision index row.
* Publish this draft plan with the complete intended implementation `touches:`
  set, including all ADR-0027 reserved paths.
* Add the FS-0044 and PLAN-0050 index rows, the ADR-0044 index row, and a
  CHANGELOG entry that names the proposal as draft and does not claim delivery.
* Classify `site/` as internal build source in `AGENTS.md` and `INTEGRATION.md`.
* Record human approval for FS-0044, PLAN-0050, and ADR-0044 against the exact
  implementation `touches:` set.

**This approval revision will NOT:**

* Add `site/`, `scripts/check-site-publication.mjs`, `package.json`,
  `site/package.json`, `site/package-lock.json`, `.gitignore`,
  `.github/workflows/pages.yml`, `README.md`, or `test/FS-0044/`.
* Configure GitHub Pages, create an environment, deploy an artifact, or add a
  custom domain.
* Publish a broad mirror of the repository or expose internal governance and
  test artifacts.

**The implementation revision WILL, within the approved FS-0044, ADR-0044, and
full declared `touches:` set:**

* Add the Eleventy source tree under `site/`, including the curated pages,
  shared layout, styles, navigation, rendered/link-only content manifest,
  reviewed source digests, and base-path data.
* Add the reserved `scripts/check-site-publication.mjs` validator and document
  it in `scripts/README.md`; it must reject unsafe sources and extra artifacts.
* Add a site-scoped Node 24 dependency lockfile and root delegating
  `site:build`, `site:serve`, and `site:check` npm entry points; keep generated
  `_site/` output untracked.
* Add fixture-driven `test/FS-0044/**` coverage for publication boundaries,
  source-digest freshness, exact artifact inventory, project-site base paths,
  generated links, accessibility structure, and reportable workflow invariants
  without live GitHub calls or an Eleventy install.
* Add `.github/workflows/pages.yml` using Node 24, the official Pages actions,
  unfiltered PR build validation, explicit trunk and `workflow_dispatch` ref
  guards, `trunk`-only deployment, the `github-pages` environment,
  least-privilege permissions, and concurrency cancellation.
* Add the verified live Pages URL to `README.md` only after the first
  successful deployment and browser smoke check.
* Configure GitHub Pages, trunk protection, and environment reviewers as a
  human-controlled launch step; those settings are external to the repository
  and are not automated by the implementation workflow.

## 3. Tests Driving This Change

* Test file(s) in the implementation revision:

  * `test/FS-0044/website-content.bats` — fixture-driven validation of the
    validator-owned allowed roots and denied paths, manifest, rejected source
    paths, duplicate routes, path traversal, symlink and case-folding escapes,
    source-digest approval checks, exact artifact inventory, generated
    project-site links, source-link ownership, workflow contract, and the clean
    no-site skip for vendored consumer targets.

* Local commands in the implementation revision:

  * `npm run site:build`
  * `npm run site:check`
  * `node scripts/check-site-publication.mjs --help`
  * `npm run check:status`
  * `npm run lint:docs`
  * `npm test`
  * `npm run validate`

* Manual verification in the implementation revision:

  * Inspect the generated artifact to confirm only allowlisted content is
    present, the artifact inventory matches the manifest, and `_site/` is not
    tracked.
  * Use a browser or local server at `/conventional-agents/` to check the home,
    nested route, nested 404 assets, keyboard path, focus states, no-JavaScript
    path, and narrow layout.
  * Verify the private-repository public-Pages capability, trunk protection,
    and environment reviewers before enabling the first deployment; record the
    readback in a top-level PR #208 comment or a linked launch checklist.
  * After the human configures Pages, read back the live root, deep link, 404,
    CSS/assets, source-link revision, and expected source authorization boundary
    at the exact project URL.

## 4. Files to Be Modified

**This documentation revision:**

* `docs/specifications/FS-0044-github-pages-project-website.md`
* `docs/change-plans/PLAN-0050-implement-fs-0044-github-pages-project-website.md`
* `docs/specifications/README.md`
* `docs/change-plans/README.md`
* `docs/decisions/ADR-0044-curated-public-github-pages-derivative.md`
* `docs/decisions/README.md`
* `CHANGELOG.md`
* `AGENTS.md`
* `INTEGRATION.md`

**Implementation revision, not this package:**

* `site/**`
* `scripts/check-site-publication.mjs`
* `scripts/README.md`
* `.github/workflows/pages.yml`
* `package.json`
* `site/package.json`
* `site/package-lock.json`
* `.gitignore`
* `test/FS-0044/**`
* `README.md`

## 5. Implementation Steps (High-Level)

1. Add the site-scoped Node 24 Eleventy toolchain and root delegating site
   commands without changing canonical documents or committing generated output.
2. Define and validate the explicit rendered/link-only content manifest against
   the validator-owned allowed roots and denied paths, reviewed source digests
   with recorded-publication-approval evidence, navigation data, exact artifact
   inventory, and project-site base-path configuration.
3. Build the shared semantic layout, responsive styles, no-JavaScript reading
   path, visible content-kind marker, 404 page, metadata, SHA-pinned source
   links, and adopter-facing pages from the approved information architecture.
4. Add the reserved offline publication validator and fixture-driven Bats
   coverage that fails on unsafe publication, stale reviewed digests, extra
   artifacts, and base-path regressions without installing Eleventy.
5. Add the Pages workflow with unfiltered PR build/upload behavior,
   `trunk`-only deploy, explicit `workflow_dispatch` ref guard,
   `github-pages` environment, least-privilege permissions, locked site install,
   and concurrency cancellation.
6. Run the repository gates and inspect the generated artifact in a draft PR.
7. After the human-controlled Pages capability, trunk protection, environment
   reviewers, and merge path complete, verify the live deployment and then add
   its URL to `README.md`.

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-0044's curated-first scope, explicit manifest, source ownership,
    source-digest freshness, exact artifact inventory, accessibility, offline
    validation, and private-source/public-derivative publication boundary.
  * FS-0044 Non-Goals and Out of Scope are hard exclusions for the first
    release.

* ADR constraints:

  * ADR-0024: keep the public guide portable and distinct from the framework's
    platform-neutral canonical content; do not introduce a CMS or runtime
    dependency for the guide.
  * ADR-0026 (`docs/decisions/ADR-0026-approval-is-a-recorded-act.md`): approval
    is a human act with a locatable record. The implementation revision requires
    a status-transition commit carrying `Approved-By:` and `Approved-Artifacts:`
    for the exact full `touches:` set; later manifest or digest changes require
    a new recorded approval for the affected publication artifacts.
  * ADR-0027: `.github/workflows/` and `package.json` are reserved paths, and
    `scripts/` is also reserved; the implementation revision cannot self-approve
    any of them.
  * ADR-0030: site summaries may explain current state, but canonical framework
    rules remain in their existing current-state documents.
  * ADR-0044: keep the source repository private, publish only the verified
    public derivative, use Node 24/site-scoped dependencies, and require
    protected trunk plus environment reviewers before launch.

* Architecture constraints:

  * `site/` is the source tree; `_site/` is generated and must not become a
    second source of truth.
  * `site/` is internal governance source, not exported vendoring content;
    `check-conformance` does not inspect or require it.
  * The content manifest is the publication boundary; no broad repository glob
    may determine the public site.
  * The Pages workflow must use the official Pages actions and deploy only after
    the build succeeds on `trunk`.
  * Core validation must be offline after dependencies are installed and must
    not require GitHub credentials or a PAT.
  * The default `npm test` and `npm run validate` paths exercise fixture-only
    site validation and do not require the Eleventy dependency tree; the Pages
    workflow owns the site build/install.

## 7. Risks and Edge Cases

* GitHub project-site URLs require a base path; root-relative links can make a
  site appear correct at `/` while breaking every nested page after deployment.
* A canonical source path can disappear or move; validation must fail closed
  rather than leave a stale “Edit/source” link.
* Pages is a public publication channel; a permissive glob, generated log,
  symlink, or case-folded path can expose private content. The manifest and
  negative fixtures must cover these.
* A PR build must upload an artifact without deploying; the deployment job's
  event guard and environment must be checked structurally.
* Site dependencies can drift if CI uses unpinned `npx`; the lockfile and
  `npm ci --prefix site` are required.
* A successful local build does not prove the repository Pages setting or
  environment is configured; live launch remains a separate human-controlled
  verification step.
* GitHub may not support a public Pages derivative from this private repository
  under the selected account/organization plan; the workflow must not work around
  that by changing repository visibility.
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
  * `node scripts/check-site-publication.mjs --help`
  * `bats test/FS-0044/website-content.bats`
  * `npm test`
  * `npm run validate`
  * Workflow YAML parser and structural assertions

* Manual checks:

  * Confirm `git status` is clean after deleting generated output and that no
    canonical Markdown changed during the site build.
  * Inspect `_site/` for excluded path names and accidental root-relative URLs.
  * Compare the complete `_site/` inventory with the manifest-derived expected
    routes and declared assets.
  * Verify project-site deep links and the custom 404 locally and after launch.
  * Read back the Pages deployment URL, compare its commit to the merged
    `trunk` revision, and verify the expected private-source authorization
    behavior before adding the link to `README.md`.
  * After merge, confirm the rebase-merge preserves the recorded publication
    approval relationship: the implementation commit's `Publication-Approval:`
    trailer must resolve to a commit present in the new `trunk` history with
    its `Approved-By:`/`Approved-Artifacts:` trailers intact (Kimi K2.7 review
    finding 1, PR #208). If GitHub's rebase rewrote the approval commit, record
    a fresh ADR-0026 approval naming the affected artifacts before launch.

## 9. Explicit Non-Changes

* No changes to the meaning or status of existing FS, PLAN, or ADR documents in
  the implementation revision.
* No migration of canonical framework documents out of their current paths.
* No custom domain, DNS, analytics, search service, CMS, server-side runtime,
  or user-account feature.
* No repository secrets, PAT, GitHub API call, or external-link fetch in the
  offline build and validation path.
* No automatic Pages configuration or deployment from pull-request branches.
* No repository-visibility change and no claim that private source links are
  anonymous-public.
* No requirement for Eleventy or site dependencies in the default hermetic
  `npm test` / `npm run validate` path.

## 10. Readiness Check

* [x] Spec is approved
* [x] ADR-0044 is accepted or its proposed status is explicitly approved as the
  governing architecture record
* [x] A status-transition commit under ADR-0026 records human approval with
  `Approved-By:` and `Approved-Artifacts:` for the complete implementation
  `touches:` set, including the reserved validator, workflow, scripts, package,
  and decision paths
* [ ] Tests exist or are clearly defined
* [x] Scope is minimal and explicit for the private-source/public-derivative
  first release
* [x] No implementation files are included in this documentation revision

## Declaration

I affirm that:

* This plan reflects the full intended scope of the website implementation,
  including the reserved publication validator and launch controls.
* This revision is deliberately governance-only but records approval for the
  exact declared implementation surface; implementation may proceed only within
  that surface.
* Any deviation or expansion of the public content boundary will require
  revising FS-0044 and this plan before implementation.
