# Review: collective-agents PR #4 and PR #6

**Model:** kimi-k2.7-code
**Revisions read:** PR #4: 8039de5..169794c; PR #6: 169794c..34c0aab
**Files read:** complete diffs at /workspace/.review/pr4-6/PR4.diff and PR6.diff; all new files in both branches; vendored contract documents listed in BRIEF.md §"The contract you are judging against"
**Gate commands run:** `npm install --no-audit --no-fund` (exit 0); `npm run governance` in /workspace/collective-agents-design (exit 0); `npm run -s lint:adrs && npm run -s lint:specs && npm run -s lint:plans` (exit 0); `npm run check:status` in /workspace/collective-agents-bootstrap (exit 0)

## Verdict

- PR #4: approve-with-changes
- PR #6: approve-with-changes

PR #4 is a solid governance bootstrap: it lands the directory surface, a vendored gate script, a `config/gates.yml`, CI wiring, and document indexes that the framework expects. The repository's own gates pass. PR #6 adds three well-scoped, honest pilot documents that keep the product/framework boundary clean and do not pretend anything is implemented. However, both PRs have small but real gaps in framework conformance and in a couple of safety claims that should be tightened before merge.

## Findings

### [BLOCKER] `CHANGELOG.md` incorrectly declares the proposed ADRs and FS as drafts

- **Where:** `CHANGELOG.md` lines added by PR #6: "Proposed `ADR-0001` ..., `ADR-0002` ..., and `FS-0001` ... All three are drafts"
- **What:** The front matter of `ADR-0001` and `ADR-0002` is `status: proposed`, and `FS-0001` is `status: draft`. The CHANGELOG conflates "proposed" (ADR status) with "draft" (FS status).
- **Why it matters:** The framework's status vocabulary is not interchangeable. A reader relying on the CHANGELOG will misread the ADR status, and a future gate or reviewer may expect different transitions. `workflows/document-lifecycle.md` keeps ADR and FS status vocabularies separate.
- **Smallest acceptable fix:** Change the CHANGELOG line to: "Proposed `ADR-0001` and `ADR-0002`; drafted `FS-0001`. None is approved."

### [MAJOR] `FS-0001` has `interfaces: []` but declares `config/` as its only interface in prose

- **Where:** `docs/specifications/FS-0001-feature-draft-spec-pilot.md` lines 7 and 87-92
- **What:** The front matter says `interfaces: []`, but the `## Interfaces` section explicitly names `config/` as the only declared interface. The gate script does not read prose interfaces; it reads the front-matter list.
- **Why it matters:** `ADR-0027` routes PLAN self-approval through the FS `interfaces:` front matter. With `interfaces: []`, no PLAN can ever be approved against this FS, which the prose itself says is intentional — but the prose then turns around and names `config/` as an interface. This is a contradiction in the document's own authority. Either `config/` is a declared interface or the spec has no declared interfaces and a PLAN is impossible; it cannot be both.
- **Smallest acceptable fix:** Move the `config/` entry into the front matter as `interfaces: ["config/"]` and remove the prose claim that "no implementation surface has been chosen." If the intent is genuinely to keep interfaces empty, remove the `config/` paragraph and keep the explicit `interfaces: []`, with a clearer note that the first PLAN will require a spec amendment.

### [MAJOR] ADR-0002's "MUST NOT" boundary is not testable as stated

- **Where:** `docs/decisions/ADR-0002-worker-publisher-credential-separation.md` lines 80-82 and Validation section
- **What:** The worker is prohibited from holding "no token ... no mounted `gh` login, no SSH push key, no Git credential helper, no publisher secret, and no network path that would let it acquire one." The Validation section only asserts a credential probe finds nothing. It does not bound what "no network path that would let it acquire one" means.
- **Why it matters:** "No network path" is a stronger claim than any practical probe can verify. A worker may have general outbound internet; the absence of a credential is not the absence of a path. If this is meant to forbid egress to a specific credential source, the spec must name it. Otherwise the ADR asserts a guarantee the mechanism cannot deliver.
- **Smallest acceptable fix:** In ADR-0002, split the worker constraint into (a) the observable absence of configured/mounted write credentials, and (b) a separate non-goal or open question about network egress, until a concrete boundary is specified in `FS-0001` or its PLAN.

### [MAJOR] `FS-0001` success criterion for "no usable GitHub write credential" assumes an undefined probe

- **Where:** `docs/specifications/FS-0001-feature-draft-spec-pilot.md` lines 114-115
- **What:** The success criterion says "Given the worker's effective environment, when it is probed from inside the worker, then no usable GitHub write credential is found." It does not say what "probed" means, what "usable" means, or what to do about credentials that are not GitHub write credentials (e.g., a read credential, a different host credential, a future MCP server credential).
- **Why it matters:** This criterion will be used to generate tests. Without a bounded probe, an implementer can satisfy it trivially by checking one environment variable. The criterion should match the honest boundary ADR-0002 should state.
- **Smallest acceptable fix:** Rewrite the criterion as: "Given the worker's effective environment, when a probe enumerates the environment variables, mounted files, Git credential helpers, `gh` CLI authentication state, and SSH keys known to the runtime configuration, then no configured GitHub write credential is found." Or move the detailed probe definition to `FS-0001` and reference it here.

### [MAJOR] ADR-0001 and ADR-0002 are missing the framework-mandated `updated:` front-matter field

- **Where:** `docs/decisions/ADR-0001-authorized-intent-identity-and-human-grant.md` and `docs/decisions/ADR-0002-worker-publisher-credential-separation.md` front matter
- **What:** Both ADRs omit `created:` and `updated:` fields. The framework's template (`templates/core/adr-full-madr.md`) does not include them, but the Document Hygiene gate in `ROLE_CONTRACT.md` requires "`updated:` dates are current: Any modified FS, PLAN, or ADR has its `updated:` front matter field set to today's date." `document-lifecycle.md` §"Front Matter Hygiene" also requires `updated:` on modification.
- **Why it matters:** The gate currently passes because the check script does not enforce this field, but the framework contract does. These documents are being modified/created now and should carry `created:` and `updated:`.
- **Smallest acceptable fix:** Add `created: 2026-09-29` and `updated: 2026-09-29` to both ADR front-matter blocks.

### [MAJOR] `FS-0001` success criterion "given a genuine human decision is required" is not objectively testable

- **Where:** `docs/specifications/FS-0001-feature-draft-spec-pilot.md` lines 130-132
- **What:** The criterion says "Given a genuine human decision is required, then the explanation is posted on the work item with a preceding `agent-stance` entry, and only then is `question` applied." "Genuine human decision is required" is a judgment about the engine's internal state, not an observable precondition.
- **Why it matters:** `ROLE_CONTRACT.md` §"Spec Reader and Test Planner" says tests are generated from success criteria and must be deterministic. A test cannot feed "genuine human decision is required" as an input.
- **Smallest acceptable fix:** Replace with an observable trigger, e.g.: "Given the engine encounters a condition not covered by an approved grant, an ambiguous scope change, or an unresolved external state, when it halts, then it posts an `agent-stance` entry followed by a `question` label on the work item."

### [MINOR] PR #6 `CHANGELOG.md` says "Nothing is implemented" but PR #4 already said "No workflow engine ... is implemented yet"

- **Where:** `CHANGELOG.md` in both branches
- **What:** The PR #6 CHANGELOG addition repeats the "nothing is implemented" disclaimer. PR #4's CHANGELOG already made the same point for the governance surface.
- **Why it matters:** Minor duplication; not a blocker, but a reviewer may ask why the disclaimer is repeated for documents that are explicitly not implementation.
- **Smallest acceptable fix:** In PR #6, drop the "and nothing is implemented" clause; the previous CHANGELOG sentence and the status fields already convey this.

### [MINOR] `docs/decisions/.markdownlint.yml` disables `MD024` globally while the root config only allows sibling duplicates

- **Where:** `docs/decisions/.markdownlint.yml` lines 8-19; `.markdownlint.yml` lines 7-10
- **What:** The per-directory config sets `MD024: false` (all duplicate headings allowed), whereas the root `.markdownlint.yml` uses `siblings_only: true`.
- **Why it matters:** The PR #4 root config was careful to keep duplicate sibling headings allowed (for CHANGELOG sections). The ADR directory config widens the rule without a documented reason beyond "we use 'Examples' multiple times" — that case is already covered by `siblings_only: true`.
- **Smallest acceptable fix:** Change `docs/decisions/.markdownlint.yml` `MD024` to match the root: `siblings_only: true`, or document a concrete ADR heading pattern that requires non-sibling duplicate headings.

### [NIT] ADR-0001 "What this ADR does not change" names upstream `ADR-0001` ambiguously

- **Where:** `docs/decisions/ADR-0001-authorized-intent-identity-and-human-grant.md` lines 111-117
- **What:** The section says "It does not alter upstream `ADR-0001` ..." but this document *is* `ADR-0001` in this repository. The intent is clearly "framework ADR-0001" (cross-tool portable skills), but the phrasing invites confusion.
- **Why it matters:** A reader new to the repository may think there is a typo or that the local ADR is referring to itself.
- **Smallest acceptable fix:** Qualify as "upstream framework `ADR-0001`" or "`vendor/conventional-agents/docs/decisions/ADR-0001.md`".

### [NIT] `FS-0001` Dependencies references `ADR-0020` for "`question` suppression" but the linked upstream ADR is about issue labels

- **Where:** `docs/specifications/FS-0001-feature-draft-spec-pilot.md` line 168
- **What:** The dependency is correct in substance (the `question` label rule is `ADR-0020`), but the local `FS-0001` uses `question` as a label on a work item. A brief note that this is the upstream work-item label would help.
- **Why it matters:** Avoids a reader searching for a local `question` mechanism.
- **Smallest acceptable fix:** Keep the reference; add a parenthetical: "(work-item `question` label suppression; the same label is reused here)."

## Not verified

- The actual content of the vendored `conventional-agents` submodule was not independently checked against the stated pin `94b784aa022b715bf7dad331a714f786620f961a`. I read the files that were present in the worktree and assumed the pin matches the brief.
- The GitHub Actions workflow `governance.yml` was not run in GitHub CI; only the local equivalents were executed. The path filters and job permissions were reviewed statically.
- The behavior of `scripts/check-status.sh` against malformed inputs (e.g., deliberately broken front matter) was not fuzzed; only the existing files were checked.
- Whether the upstream framework's `templates/core/feature-spec.md` has been updated to reflect `ADR-0027`'s promotion of `interfaces:` to an approval boundary could not be verified from the checked-out pin.

## Where another reviewer may reasonably disagree

- The `interfaces: []` versus `config/` issue could be read as intentional tension rather than contradiction: some reviewers may accept that prose can "declare" an interface while front matter stays empty to block premature PLANs. I think that reading makes the document less useful and more likely to be misread by the gate script.
- The absence of `created:`/`updated:` on the new ADRs might be considered a template mismatch rather than a defect, since the ADR template does not include those fields. I read `ROLE_CONTRACT.md` and `document-lifecycle.md` as requiring them for any modified/created governed document.
- The "no network path" and "usable GitHub write credential" language could be defended as deliberately vague at the ADR level, with specifics deferred to `FS-0001`. I believe the ADR should not assert an unverifiable guarantee, even if it later says the mechanism is unspecified.
