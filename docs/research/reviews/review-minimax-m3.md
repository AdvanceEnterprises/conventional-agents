# Review: collective-agents PR #4 and PR #6

**Model:** minimax-m3
**Revisions read:** PR #4 — `8039de5..169794c` (`/workspace/collective-agents-bootstrap`); PR #6 — `169794c..34c0aab` (`/workspace/collective-agents-design`); pre-generated diffs `/workspace/.review/pr4-6/PR4.diff`, `PR6.diff` cross-checked against on-disk files.
**Files read:** PR4 — `config/gates.yml`, `scripts/check-status.sh`, `scripts/README.md`, `docs/decisions/README.md`, `docs/specifications/README.md`, `docs/change-plans/README.md`, `.github/workflows/governance.yml`, `.markdownlint*.yaml`, `package.json`, `AGENTS.md`, `README.md`, `CHANGELOG.md`. PR6 — `docs/decisions/ADR-0001-authorized-intent-identity-and-human-grant.md`, `docs/decisions/ADR-0002-worker-publisher-credential-separation.md`, `docs/specifications/FS-0001-feature-draft-spec-pilot.md`, the three `docs/*/.markdownlint.yml`, README index updates, `CHANGELOG.md` delta. Contract docs — `vendor/conventional-agents/workflows/document-lifecycle.md`, `vendor/conventional-agents/guidelines/ROLE_CONTRACT.md`, `vendor/conventional-agents/docs/decisions/ADR-0026-approval-is-a-recorded-act.md`, `vendor/conventional-agents/docs/decisions/ADR-0027-plan-self-approval-within-declared-interfaces.md`, `templates/core/{adr-full-madr,feature-spec}.md`, upstream `ADR-0001.md` (read in full to confirm what the upstream "ADR-0001" actually is).
**Gate commands run:**
- `cd /workspace/collective-agents-bootstrap && npm run governance` → exit 0 ("All status checks passed.", "0 error(s)")
- `cd /workspace/collective-agents-design && bash scripts/check-status.sh` → exit 0
- `cd /workspace/collective-agents-design && npm run governance` → exit 0

(Each command run from the relevant checkout. `node_modules/markdownlint-cli2` was already present in both worktrees; no `npm install` was re-run because the user-side state was already complete and the question being reviewed is whether the gates as committed pass.)

## Verdict

- PR #4: **approve-with-changes**
- PR #6: **approve-with-changes**

PR #4 lands the governed document surface, the vendored status gate, `config/gates.yml`, the index READMEs, root lint config, and a governance CI workflow. The vendored gate passes locally; `config/gates.yml` is filled in (not "unconfigured-empty"), the workflow restricts its path triggers to docs/config/scripts/package/manifest, and `AGENTS.md`/`README.md` are honest about the no-implementation state. The change is small and the seams it leaves open (no `INTEGRATION.md` update, no `BACKLOG.md` seeding) are intentional.

PR #6 proposes three genuinely cautious documents. `ADR-0001` is honest that "one canonical publication per intent" is a goal with a recovery path, not exactly-once; `ADR-0002` honestly disclaims enforcement at the GitHub layer and locates it in process + environment. The framework conformance is mostly there: four-digit IDs, MADR sections present in both ADRs, README indexes updated, status vocabulary correct (`proposed` for ADR, `draft` for FS). But there are two real contradictions inside FS-0001 (`interfaces: []` front matter vs `config/` prose; `config/` is in `reserved_paths`), the two ADRs are missing `created:`/`updated:` front matter that the framework's hygiene gate requires, and one FS success criterion is not objectively testable. None of these is a reason to throw away the work; each is a small, named fix.

## Findings

### [BLOCKER] FS-0001's `interfaces: []` contradicts its own prose, and `config/` is a reserved path

- **Where:** `docs/specifications/FS-0001-feature-draft-spec-pilot.md` front matter line 8 (`interfaces: []`) vs. §"Interfaces" lines 87–92; cross-reference `config/gates.yml` line 23 (`reserved_paths` includes `config/gates.yml`).
- **What:** Front matter declares zero interfaces. The prose section then explicitly states "the only declared interface" is `config/`. The two cannot both be true; the gate script reads the front matter list, not the prose.
- **Why it matters:** This is worse than a stylistic mismatch. Under `ADR-0027`, a PLAN's `touches:` must fall inside its governing FS's `interfaces:` union. With `interfaces: []`, no PLAN can be approved against FS-0001 — which is what the prose says it wants. But the prose then names `config/` as the declared interface, and `config/gates.yml` is in the repository's `reserved_paths`. So the only interface the prose declares is also a reserved path requiring human approval even if it were added to `interfaces:`. The spec claims it is open for configuration in `config/`, but no self-approvable implementation path exists for that configuration: every PLAN touching `config/` is by design human-only. A reviewer reading the spec cannot tell what the engine's interface surface is, and a future implementer cannot tell which paths they may self-approve against.
- **Smallest acceptable fix:** Pick one. Either (a) drop the `## Interfaces` section's claim that `config/` is "the only declared interface" and replace the prose bullet with an explicit note that interfaces will be declared in a later amendment to this spec — keeping `interfaces: []` honest and acknowledging that the first PLAN must human-approve its `touches:`; or (b) populate `interfaces: []` with the paths actually intended to be in scope (and, if `config/` is among them, document in §"Interfaces" that any PLAN touching `config/` requires human approval because the file is in `reserved_paths`). The kimi review suggested (a)-style; I prefer (a) because the spec is honest that "no implementation surface has been chosen," and adding paths now would be inventing a layout.

### [MAJOR] ADRs are missing `created:` and `updated:` front matter that the framework's hygiene gate requires

- **Where:** `docs/decisions/ADR-0001-authorized-intent-identity-and-human-grant.md` and `docs/decisions/ADR-0002-worker-publisher-credential-separation.md` front-matter blocks (lines 1–9 of each).
- **What:** Both ADRs omit `created:` and `updated:`. `FS-0001` carries them (`created: 2026-09-29`, `updated: 2026-09-29`).
- **Why it matters:** `vendor/conventional-agents/guidelines/ROLE_CONTRACT.md` §"Document hygiene gate" item 2 says "`updated:` dates are current: Any modified FS, PLAN, or ADR has its `updated:` front matter field set to today's date." `vendor/conventional-agents/workflows/document-lifecycle.md` §"Front Matter Hygiene" repeats this. The status-gate script (`scripts/check-status.sh` rule 5b) does not enforce this field, which is why the local gate passes — but the framework contract does, and these documents are being created now. The kimi review flagged this and I agree; the same omission on the two ADRs while the FS in the same PR correctly carries the fields is asymmetric and easy to fix.
- **Smallest acceptable fix:** Add `created: 2026-09-29` and `updated: 2026-09-29` to both ADR front-matter blocks.

### [MAJOR] FS-0001 success criterion "genuine human decision is required" is not objectively testable

- **Where:** `docs/specifications/FS-0001-feature-draft-spec-pilot.md` line 130: "Given a genuine human decision is required, then the explanation is posted on the work item with a preceding `agent-stance` entry, and only then is `question` applied."
- **What:** "Genuine human decision is required" is a judgment about the engine's internal state, not an observable precondition. `vendor/conventional-agents/guidelines/ROLE_CONTRACT.md` Role 2 ("Spec Reader and Test Planner") lists "Success Criteria are not testable" as a stop condition; the section itself says each bullet "MUST be objectively testable." `templates/core/feature-spec.md` says tests are generated from this section alone. A test cannot construct "genuine human decision is required" as an input.
- **Why it matters:** This criterion is the gate between the engine halting and the work item being labeled `question`. It will be used to generate a test, and the test will be either vacuous (passes on any state) or a re-statement of the criterion. Either failure mode is worse than rewriting it now.
- **Smallest acceptable fix:** Rewrite the precondition to an observable engine state — e.g., "Given the engine encounters a grant whose scope generation is older than the work item's current scope, or an external write whose outcome is unknown, when it halts, then it posts an `agent-stance` entry followed by the `question` label." Keep the "operational hold" branch (rate-limit/retry exhaustion) as a separate criterion that explicitly does not apply `question`, which the existing bullet already does well.

### [MAJOR] `CHANGELOG.md` PR #6 delta conflates ADR `proposed` with FS `draft`

- **Where:** `CHANGELOG.md` lines added by PR #6 (top of file, after the existing `[Unreleased]` block).
- **What:** The bullet reads "Proposed `ADR-0001` (authorized intent identity and the human grant), `ADR-0002` (worker/publisher credential separation), and `FS-0001` (the `feature` / `draft-spec` pilot). All three are drafts: none is accepted or approved, and nothing is implemented."
- **Why it matters:** The framework's status vocabulary is not interchangeable. ADR transitions are `proposed → accepted → deprecated/superseded`; FS transitions are `draft → approved → in-progress → implemented → deprecated` (see `workflows/document-lifecycle.md` and `docs/decisions/README.md` §"Status values" / `docs/specifications/README.md` §"Lifecycle"). Calling ADRs "drafts" blurs the vocabulary; a future tool or reviewer reading the CHANGELOG will misread the ADR status. The last sentence ("and nothing is implemented") is also redundant with the existing PR #4 entry and the FS `status: draft` field itself.
- **Smallest acceptable fix:** Change to: "Proposed `ADR-0001` and `ADR-0002`; drafted `FS-0001`. None is accepted or approved." Drop the trailing "and nothing is implemented" — the statuses already say so.

### [MAJOR] ADR-0002 worker constraint includes "no network path that would let it acquire one" — overclaim not bounded

- **Where:** `docs/decisions/ADR-0002-worker-publisher-credential-separation.md` lines 41–46 and 363–365 (Validation).
- **What:** The MUST-NOT list forbids "no network path that would let it acquire [a GitHub write credential]." The Validation section only asserts that a credential probe finds nothing inside the worker's environment (env vars, mounted files, Git helpers). No probe described in the ADR can verify the absence of a network path.
- **Why it matters:** "No network path" is a stronger claim than any practical probe can verify from inside the worker: general outbound internet is normal in an isolated worker; absence of a credential is not the absence of a way to get one. If the intent is "no egress to a credential source," the ADR must name that source or the scope. As written, the ADR asserts a guarantee the mechanism cannot deliver, then offers a Validation section that does not validate it. The kimi review flagged this and I agree.
- **Smallest acceptable fix:** In §"Decision Outcome", split the worker constraint into (a) the observable absence of configured/mounted write credentials in the worker environment, and (b) a separate, named non-goal about general egress until FS-0001 or its PLAN specifies the network boundary. Move the "no network path" claim out of the MUST-NOT list and into the non-goals list.

### [MAJOR] ADR-0001 prose names "upstream ADR-0001" while this repository's ADR-0001 *is* an ADR-0001

- **Where:** `docs/decisions/ADR-0001-authorized-intent-identity-and-human-grant.md` lines 109–115 (## Decision Outcome → ## What this ADR does not change) and `## Links` (line 156).
- **What:** The document says "It does not alter upstream `ADR-0001`, `ADR-0012`, `ADR-0014`, ...". Verified: `vendor/conventional-agents/docs/decisions/ADR-0001.md` is an *accepted* upstream ADR titled "Incorporate cross-tool portable skills as SKILL.md" — a totally different decision. Local readers who reach this section will first read it as a self-reference (this document is `ADR-0001` in this repo). The Links section lists the upstream IDs by short form, which is the same ambiguity.
- **Why it matters:** Future maintenance that edits the local ADR-0001 will read "does not alter upstream ADR-0001" and either be confused or weaken the no-alteration claim to one upstream ADR that has no obvious relationship. The change is one word.
- **Smallest acceptable fix:** In "What this ADR does not change" and in `## Links`, qualify the upstream ID as "upstream framework `ADR-0001`" (or "framework `ADR-0001` (cross-tool portable skills)"). For each ID in the list that has a similarly ambiguous local-future counterpart, prefer the qualified form.

### [MINOR] `docs/decisions/.markdownlint.yml` disables MD024 fully; the rationale's listed cases are siblings

- **Where:** `docs/decisions/.markdownlint.yml` line 11 (`MD024: false`); root `.markdownlint.yml` lines 7–9 (`MD024: { siblings_only: true }`); the per-directory rationale cites "ADR-0015" choosing the title as a heading (a sibling of "Considered Options", already permitted by `siblings_only: true`) and "Examples" appearing multiple times (which are sibling headings under different parents, also covered by `siblings_only: true`).
- **What:** The per-directory config widens MD024 to allow duplicate headings at any depth, but the cases the inline comment names are all already covered by `siblings_only: true`. There is no concrete ADR pattern in the cited examples that needs non-sibling duplicates.
- **Why it matters:** Two configs in one repository, both describing themselves as matching the framework's convention, disagree on the same rule. A future lint reviewer will be unable to predict which is meant, and a reader of `docs/decisions/.markdownlint.yml` will assume MD024 is needed at non-sibling depth without evidence.
- **Smallest acceptable fix:** Change `MD024: false` to `MD024: { siblings_only: true }` and update the rationale comment to point at the cases that actually require siblings-only (the ADR title + chosen option pattern); or, if non-sibling duplicates really are needed for some unstated ADR, add a concrete example to the comment.

### [MINOR] ADR-0002 publishes a Must-not boundary but FS-0001's matching success criterion is underspecified

- **Where:** `FS-0001` line 115: "Given the worker's effective environment, when it is probed from inside the worker, then no usable GitHub write credential is found."
- **What:** "Probed" and "usable" are not bounded. The probe must read env vars, mounted files, Git credential helpers, `gh` auth state, and any SSH keys the runtime's known configuration exposes. "Usable" is not defined: a token that exists but has expired, a token scoped to a read-only endpoint, or a token for a non-GitHub host — each could satisfy or fail "no usable" depending on reading.
- **Why it matters:** The Spec Reader and Test Planner role is required to generate tests from `## Success Criteria` and from nothing else. Without a bounded probe definition, an implementer can satisfy the criterion trivially by checking one env var; a strict reviewer can fail it on any read-only token. The two readings disagree, and the ADR that promises the constraint (ADR-0002) does not give a complete definition either.
- **Smallest acceptable fix:** In FS-0001, replace the criterion with: "Given the worker's effective environment, when a probe enumerates environment variables, mounted files, Git credential helpers, and `gh` CLI authentication state, then no configured GitHub write credential (token, SSH key, or helper-resolved credential with write scope) is found." Reference ADR-0002's MUST-NOT list explicitly.

### [MINOR] `scripts/check-status.sh` last-synced revision is the framework revision hash, not a `v`-prefixed version

- **Where:** `scripts/README.md` line 29: "**Last synced to framework revision:** `94b784aa022b715bf7dad331a714f786620f961a` (v2.1.0-145)."
- **What:** I cannot verify the `(v2.1.0-145)` label without a tag listing I didn't read; the brief says the pin is `94b784aa022b715bf7dad331a714f786620f961a`. The version label may be correct; I haven't independently verified it.
- **Why it matters:** Low. The label is human-facing, and the SHAs are authoritative. If the tag is wrong, the README drifts from the actual pin without breaking the gate.
- **Smallest acceptable fix:** Verify the `(v2.1.0-145)` annotation against the framework's release tags; drop the annotation if it cannot be verified, or replace with the commit date if the tag is unfindable.

### [NIT] PR #6 `CHANGELOG.md` describes `ADR-0001` and `ADR-0002` with parenthetical summaries that will drift

- **Where:** `CHANGELOG.md` PR #6 delta, lines 11-13.
- **What:** The CHANGELOG restates the ADR/FS titles in prose. CHANGELOG entries are historical; if the ADR titles later change (renames are rare but possible at `proposed` status), this line will lie.
- **Why it matters:** Cosmetic. The drift is detectable.
- **Smallest acceptable fix:** Acceptable as written. Skip if other findings are addressed.

## Not verified

- I did not run `npm install`; `node_modules/` was already populated in both worktrees. The pre-existing install is sufficient to verify the gates the PRs commit.
- I did not execute the GitHub Actions workflow `governance.yml` in CI; I reviewed the YAML statically and ran the same commands locally. The CI run would only differ in environment if Node 20 behavior diverges, which I do not expect.
- I did not fuzz `scripts/check-status.sh` against deliberately malformed input (missing front matter, mid-list blank lines, suffixed/non-suffixed filename combinations). The kimi review noted the script has had failures of this shape before; the fixes in the current copy look correct on inspection but were not stress-tested.
- I did not read the upstream `vendor/conventional-agents/CHANGELOG.md` or release tags; the `(v2.1.0-145)` annotation in `scripts/README.md` is therefore unverified.
- The brief mentions the kimi review at `/workspace/.review/pr4-6/review-kimi-k2.7-code.md`. I read it. Where I disagree with it I say so; where I agree I cite it. I did not use it as a substitute for my own reading.

## Where another reviewer may reasonably disagree

- **"One canonical publication per intent" is honestly bounded.** The kimi review's instinct to flag this is reasonable, but on a close reading ADR-0001 §"Consequences → Negative" explicitly says it "remains a goal with a specified recovery path, not an exactly-once guarantee." `FS-0001` §"Non-Goals" and §"Out of Scope" repeat the disclaimer. I read the ADR as honest about the limit; another reviewer focused on the headline phrasing might still flag it. I would not.
- **`ADR-0001` not altering "upstream ADR-0001" is a real concern but a small one.** A reviewer who treats the upstream ADR-0001 as a fixed piece of history and the local ADR-0001 as the same-named local artifact may accept the phrasing as a future-proofing convention and call this a NIT rather than a MAJOR. I think the existence of two ADR-0001s with no shared topic warrants the qualifier; a reasonable colleague may not.
- **Empty `interfaces: []` with prose declaring `config/` may be read as "the prose is aspirational, the front matter is authoritative."** A reviewer who reads the spec through the gate script's eyes will say the prose is wrong; a reviewer who reads the spec as a human artifact may say the prose is right and the front matter is an implementation constraint to be amended. I read the spec-first rule (spec is authoritative, front matter is the machine-readable projection of it) as ruling the prose wrong; a thoughtful colleague could read it the other way.
- **The two ADRs missing `created:`/`updated:` may be read as template mismatch rather than defect.** The `adr-full-madr.md` template does not include these fields, so a strict-template reviewer might say the PR correctly follows the template. I read `ROLE_CONTRACT.md` §"Document hygiene gate" item 2 as overriding the template, and `FS-0001` carrying the fields as evidence the author knows the rule. A colleague who values template fidelity over the hygiene-gate text could disagree.