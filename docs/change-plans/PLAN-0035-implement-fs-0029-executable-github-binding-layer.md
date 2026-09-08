---
type: change-plan
role: implementer
language: bash
status: implemented
related_specs: [FS-0029]
approved_by: "Joey Clark <administrator@ajoeofalltrades.dev>"
related_adrs: [ADR-0037]
touches:
  - integrations/github/README.md
  - integrations/github/lib/gh-common.sh
  - integrations/github/bin/gh-submodule-init.sh
  - integrations/github/bin/gh-label-provision.sh
  - integrations/github/bin/gh-board-audit.sh
  - integrations/github/ci-templates/submodule-checkout.yml
  - integrations/github/ci-templates/governance-gates.yml
  - integrations/github/templates/pull-request.md
  - integrations/README.md
  - integrations/github-issues-projects.md
  - .github/pull_request_template.md
  - .github/workflows/lint-docs.yml
  - package.json
  - scripts/README.md
  - test/FS-0029/**
  - docs/specifications/README.md
  - docs/change-plans/README.md
  - CHANGELOG.md
created: 2026-09-03
updated: 2026-09-08
---

# PLAN-0035: Implement FS-0029 — Executable Layer for the GitHub Binding

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-0029
* Related ADR ID(s): ADR-0037 (governing); ADR-0024, ADR-0007, ADR-0012,
  ADR-0015, ADR-0028, ADR-0032, ADR-0033 (constraining)
* Issue / PR Reference: #111 (feature work item — created per FS-0018
  Origination Path 3); implemented by **PR #113 (merged 2026-09-06)** —
  statuses reconciled post-merge by the maintenance tick (issue #125).

## Approval Routing

This plan cannot self-approve. Its `touches:` set includes `scripts/README.md`,
`.github/workflows/lint-docs.yml`, and `package.json` — three of the five
reserved paths under `ADR-0027` — so `check-status.sh` rule 6 required a
recorded human approval regardless of how `FS-0029`'s `interfaces:` are framed.

Human approval is recorded in this change with matching `Approved-By:` and
`Approved-Artifacts:` trailers on the approval commit, and the approving human
is recorded in `approved_by:` above (`ADR-0026`). `ADR-0037` is accepted and
`FS-0029` is now in progress, so implementation is underway from this plan.

## 2. Scope of Change

**This change WILL:**

* Create `integrations/github/` with a shared library, three commands, two CI
  template fragments, and a pull-request template.
* Ship dual-regime submodule initialisation that resolves the framework
  repository's visibility rather than assuming it, and fails closed when the
  regime is indeterminate or under-credentialed.
* Ship idempotent provisioning of the `FS-0018` six labels, plus a read-only
  drift audit that reports missing and unexpected labels without deleting
  anything.
* Ship a read-only project-board drift report carrying the GraphQL pacing and
  secondary-rate-limit discipline.
* Record, in `integrations/github/README.md`, a per-command enforcement
  classification (enforces / provisions / reports) and the operational hazards
  this layer works around.
* Have the framework adopt what it ships: canonical fragments in
  `.github/workflows/lint-docs.yml`, and `.github/pull_request_template.md`.
* Widen `npm run lint:integrations` to cover `integrations/` recursively, and
  register each command as an npm script.
* Cross-reference the executable layer from `scripts/README.md`, stating why
  these are not Category 1 gates.
* Add `test/FS-0029/` bats suites covering every Success Criterion that is
  testable without the live API.

**This change will NOT:**

* Mutate any project field, issue status, or board membership.
* Ship any scheduler, daemon, polling loop, or `schedule:` trigger.
* Edit any consumer repository. `feral-fleet` and `pack-protocol` adopt on their
  own schedule; their existing inline steps keep working untouched.
* Modify the maintenance tick.
* Restructure `integrations/github-issues-projects.md` beyond adding
  cross-references.
* Add any capability to `integrations/README.md`'s six.
* Move or replace `config/project.example.yml`.
* Automate repository settings (branch protection, vulnerability reporting,
  reviewer enablement).
* Introduce `shellcheck` as a gate.

## 3. Tests Driving This Change

* Test file(s):

  * `test/FS-0029/common-lib.bats`
  * `test/FS-0029/submodule-init.bats`
  * `test/FS-0029/label-provision.bats`
  * `test/FS-0029/board-audit.bats`
  * `test/FS-0029/templates-and-registration.bats`

* Target test(s), keyed to `FS-0029` Success Criteria:

  * `test_sc_1_5__shared_behaviour` — help text, auth precheck, caller-relative
    target resolution, `CA_TARGET_REPO` override, no `vendor/` reads, actionable
    failure messages
  * `test_sc_6_11__submodule_init` — public regime uses no credential; private
    regime with no credential fails closed; **`--global` scope asserted
    explicitly**; credential absent from combined output; second run byte-identical;
    indeterminate visibility fails rather than guesses
  * `test_sc_12_17__label_provision` — creates only what is missing; second run
    creates nothing; `--audit` mutates nothing and separates missing from
    unexpected; `--dry-run` mutates nothing and prints the would-create set;
    unexpected labels never deleted; shipped set is exactly the
    `FS-0018` six and contains no `propagation`
  * `test_sc_18_23__board_audit` — source contains no mutating operation; three
    drift categories reported separately; minimum inter-call interval honoured;
    `RATE_LIMIT` waits past the reset timestamp, honours `Retry-After`,
    bounded exponential backoff when no reset is reported, and does not consult
    `rate_limit`; exit 0 on findings, `--strict` non-zero, operational failure
    distinguishable
  * `test_sc_24_27__templates` — no instance data; no `schedule:` anywhere under
    `integrations/github/`; `fetch-depth: 0` present and the credential rewrite
    not inlined; `.github/pull_request_template.md` carries the shipped sections
  * `test_sc_28_33__docs_and_registration` — enforcement table covers every
    command; hazards recorded; npm registration and `scripts/README.md`
    cross-reference present; recursive lint glob; `bash -n` clean

**Test harness note.** The GitHub API is stubbed, not called. Each suite places a
fake `gh` earlier on `PATH` that records its invocations to a trace file and
replays canned responses, so pacing, backoff, idempotency, and argument
construction are all assertable. Suites must opt out of the re-entrancy guard
with `env -u RUN_BATS_ACTIVE` only where they invoke `run-bats.sh` itself; none
of these do.

**Honest limit, restated from `FS-0029`.** Behaviour against the live API is not
covered by these suites. It is verified by the framework using the commands on
itself during step 6 below, and the audit output is recorded in the pull request
as the evidence. This is a weaker guarantee than the rest of the corpus enjoys,
and it is stated rather than implied.

## 4. Files to Be Modified

Created:

* `integrations/github/README.md`
* `integrations/github/lib/gh-common.sh`
* `integrations/github/bin/gh-submodule-init.sh`
* `integrations/github/bin/gh-label-provision.sh`
* `integrations/github/bin/gh-board-audit.sh`
* `integrations/github/ci-templates/submodule-checkout.yml`
* `integrations/github/ci-templates/governance-gates.yml`
* `integrations/github/templates/pull-request.md`
* `.github/pull_request_template.md`
* `test/FS-0029/*.bats`

Modified:

* `integrations/README.md` — binding registry row noting the executable layer
* `integrations/github-issues-projects.md` — setup-checklist items cross-reference
  the commands that perform them
* `.github/workflows/lint-docs.yml` — adopt canonical fragments; recursive
  integrations lint
* `package.json` — npm registration and widened `lint:integrations` glob
* `scripts/README.md` — cross-reference and the not-a-gate rationale
* `docs/specifications/README.md`, `docs/change-plans/README.md` — index rows
* `CHANGELOG.md` — consumer-impact entry (`check-status.sh` rule 7; `integrations/`
  and `scripts/` are both exported prefixes)

## 5. Implementation Steps (High-Level)

1. **Library first.** `lib/gh-common.sh`: `gh` presence and auth precheck, target
   resolution (`git rev-parse --show-toplevel`, `CA_TARGET_REPO` override),
   repository-visibility resolution, GraphQL pacing, reset-timestamp backoff,
   summary formatting, usage printing. Bash 3.2 compatible — no associative
   arrays. Every later step depends on this; nothing else starts until its suite
   is green.
2. **`gh-submodule-init.sh`.** Visibility resolution drives the branch. Public:
   initialise with no credential. Private with credential: `--global` `insteadOf`
   scoped to the framework's host prefix, then `git submodule update --init`.
   Private without credential, or visibility indeterminate: exit non-zero with a
   named remediation. Assert `--global` in the suite before writing the
   implementation — that is the regression this step exists to prevent.
3. **`gh-label-provision.sh`.** Read current labels once; diff against the
   `FS-0018` six; create the missing; report. `--audit` takes the same read path
   and skips the write path entirely rather than short-circuiting inside it.
   Extension labels come from a caller-resolved file; nothing organisation-specific
   is compiled in.
4. **`gh-board-audit.sh`.** Enumerate project items and open Issues through the
   paced call path; classify into unset-Type, unset-Status, and absent-from-board;
   report. No mutating call path exists in the file at all — the suite asserts
   this against the source, so absence is structural rather than conditional.
5. **Templates and documentation.** The two CI fragments, the pull-request
   template, and `integrations/github/README.md` including the enforcement table
   and the hazards record. Every backticked path in that README must resolve —
   `check-status.sh` rule 8 treats `integrations/` as current-state.
6. **Framework adoption.** Wire the canonical fragments into
   `.github/workflows/lint-docs.yml`; add `.github/pull_request_template.md`; run
   `gh-label-provision.sh --audit` and `gh-board-audit.sh` against this repository
   and record their output in the pull-request body as live-API evidence.
7. **Registration and indexes.** npm scripts, widened lint glob,
   `scripts/README.md` cross-reference, the three README index rows, CHANGELOG
   entry.
8. **Full gate run.** `npm run lint:docs`, `npm run check:status`,
   `npm run check:freshness`, `npm test`. Resolve every violation before
   proposing merge.

* Shipped in **PR #113 (merged 2026-09-06)**; the governing FS/PLAN pair
 statuses were reconciled post-merge by the maintenance tick (issue #125).*

## 6. Constraints and Guardrails

* **Spec constraints:** `FS-0029` Non-Goals and Out of Scope, in full. In
  particular: no reconciler, no scheduler, no consumer-repository edits, no
  seventh core capability.
* **ADR constraints:**
  * `ADR-0007` — standards only, never orchestration. Nothing shipped may run
    itself.
  * `ADR-0037` §2 — mechanisms, never a trigger that mutates a work item.
  * `ADR-0037` §3 — anything that can fail a pull request belongs in `scripts/`
    as a Category 1 gate, not here.
  * `ADR-0024` — the binding document stays normative; an executable that
    disagrees with it is a defect in the executable. No generalisation extracted
    from one binding.
  * `ADR-0032` — no instance data: no organisation name, project number, node ID,
    or secret value in any shipped file.
  * `ADR-0033`/`FS-0024` — caller-relative target resolution; never read inside
    `vendor/`.
  * `ADR-0012` — verify `gh auth status` before every operation, not once per
    session.
  * `ADR-0015` — `scripts/` remains the Category 1 gate directory; this change
    adds no gate to it and moves none out of it.
* **Architecture constraints:** `guidelines/bash/BASH_STYLE_GUIDE.md` and
  `BASH_IMPLEMENTATION_GUIDE.md` govern the shell. Bash 3.2 baseline. No new
  runtime dependency beyond `gh`, `git`, `bats`, and `rg`.

## 7. Risks and Edge Cases

* **Fail-open initialisation is the highest-consequence defect available here.** A
  submodule init that proceeds without the framework present yields governance
  gates running against absent documents and reporting green. SC-7 and SC-11
  are the guard; the suite asserts both before the implementation exists.
* **Credential leakage into CI logs.** Mitigated by scoping the rewrite to the
  framework's host prefix and by SC-9's output scan. A reviewer should
  read the rewrite construction directly rather than trusting the test alone.
* **Stubbed `gh` diverging from real `gh`.** The fixtures encode today's response
  shapes. `gh` has already broken compatibility once in a way this layer works
  around (`gh pr edit --body`), so the fixtures are a snapshot, not a contract.
  Step 6's live run is what catches divergence; it is not optional.
* **Pacing making the audit slow enough that nobody runs it.** A seven-second
  interval across a large board is minutes. The interval is configurable and the
  wait is announced; if it proves unusable in practice that is a finding worth
  recording, not a reason to remove the pacing that the failure history
  demonstrates is needed.
* **`ADR-0034` is `proposed` and touches the same neighbourhood** (GitHub skills
  consolidation, `integrations/` for MCP bindings). No file overlap exists today.
  If `ADR-0034` lands first, re-read this plan's step 5 against whatever it
  establishes for `integrations/` structure before writing.
* **The `--strict` flag is one review away from becoming a gate.** Shipping it
  and simultaneously declining to wire it is deliberate. A future change that
  wires it into a pull-request check has moved a gate out of `scripts/` and must
  be caught in review.

## 8. Validation

* Tests expected to pass:

  * All five `test/FS-0029/` suites
  * The existing corpus, unchanged: `npm test` in full
  * `npm run check:status` (rules 2, 3, 4, 7, and 8 all bear on this change)
  * `npm run check:freshness`
  * `npm run lint:docs` with the widened integrations glob
  * `bash -n` on every shipped `.sh`

* Manual checks:

  * `gh-label-provision.sh --audit` run against this repository; output recorded
    in the pull-request body.
  * `gh-board-audit.sh` run against this repository's board; output recorded in
    the pull-request body.
  * `gh-submodule-init.sh` exercised in CI on this repository, which is currently
    private — the private-with-credential path is the one the framework's own CI
    covers. The public path is covered by the suite against a stubbed
    visibility response until the repository is public, and this is stated in
    `integrations/github/README.md` rather than left for a reader to assume.

## 9. Explicit Non-Changes

* The six capabilities in `integrations/README.md`.
* `integrations/github-issues-projects.md`'s capability mapping, conformance
  summary, and §7 non-guarantees.
* `config/project.example.yml`, `config/gates.example.yml`, and every other file
  under `config/`.
* Every existing script in `scripts/` and its behaviour.
* `.github/ISSUE_TEMPLATE/work-item.md`.
* Any label, workflow, board, or setting in any consumer repository.
* The maintenance tick and its skill.
* `ADR-0015`'s tool taxonomy.

## 10. Readiness Check

* [x] `ADR-0037` is `accepted`
* [x] `FS-0029` is `approved`
* [x] Tests are defined against `FS-0029` Success Criteria (§3 above)
* [x] Scope is minimal and explicit
* [x] No architectural changes implied beyond those `ADR-0037` records
* [x] Human approval recorded for the reserved paths in `touches:` (`ADR-0027`)

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding
