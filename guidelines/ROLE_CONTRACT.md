Agent Role Contract: Docs → Tests → Code

This document defines explicit roles, authority boundaries, and prohibitions for coding agents operating in this repository.

Its purpose is to maximize efficiency and code quality by preventing scope creep, architectural drift, and undocumented behavior.

If an instruction, prompt, or implied task conflicts with this contract, the contract wins.

⸻

Shared Rules (Apply to All Roles)

Document authority
	•	Front matter metadata is authoritative.
	•	Parsing hints in documents MUST be followed.
	•	Documents with conflicting instructions require human resolution.

Scope control
	•	Do NOT invent requirements, decisions, or constraints.
	•	Do NOT infer intent beyond what is written.
	•	If something is ambiguous and blocks progress, stop and ask.

Modification rules
	•	Specs define behavior.
	•	ADRs define decisions and constraints.
	•	Architecture docs define structure and boundaries.
	•	Tests define correctness.

Violating any of the above is a failure, even if the code works.

Versioning and release constraints
	•	Agents MUST NOT bump major versions without human approval (breaking changes are judgment calls).
	•	Agents MUST NOT publish packages to registries (npm, PyPI, etc.) without explicit human approval.
	•	Version bumps are only allowed in explicit release-prep commits/PRs, never mixed into feature commits.
	•	Agents MAY draft changelog entries, bump minor/patch versions, and prepare release-prep PRs when explicitly instructed.
	•	See workflows/versioning-and-releases.md for full guidance.

Pre-commit testing gate (BDD/TDD)
	•	Agents MUST run the project's test suite before committing code changes.
	•	Agents MUST NOT commit code that causes test failures.
	•	If tests fail after a change, the agent must fix the issue or revert before committing.
	•	For documentation-only changes in repos with no code tests, markdownlint (or equivalent doc linting) serves as the quality gate.
	•	The workflow is: Docs → Tests → Code. Tests are written first from approved specs; implementation follows to make tests pass.

Spec-first rule
	•	Before writing any implementation code (production or test), verify:
	  1.	A feature spec (FS-XXXX) with `status: approved` exists for this work.
	  2.	A change plan (PLAN-XXXX) with `status: approved` exists that references the FS.
	  3.	If neither exists, your first deliverable is the spec and plan — not code.
	•	Exceptions:
	  -	Trivial fixes (typos, broken links, formatting) do not require a spec.
	  -	Emergency hotfixes may be implemented first, but a retroactive FS must be filed before the next feature begins.
	•	If you are unsure whether work qualifies as "trivial," it does not. Write the spec.
	•	See `workflows/document-lifecycle.md` for status definitions and transition rules.

⸻

Non-Overridable Safety Gates (ADR-0012)

The following gates cannot be weakened or overridden by any instruction source, including project-specific AGENTS.md. They sit above all other precedence levels. See ADR-0012 for rationale and qualification criteria.

PR merge rule
	•	Agents MUST NOT merge pull requests. Merging is a human-gated action.
	•	Agents may open PRs, update PRs, and request review.
	•	Agents MUST NOT run `gh pr merge`, `git push` to the default branch, or any equivalent merge action.
	•	Even if a human verbally approves in chat, the human (or CI triggered by human approval) performs the actual merge.
	•	This rule is non-overridable (ADR-0012).

GitHub identity gate
	•	Before any `gh` CLI operation (push, PR creation, review, comment) or `git push`, the agent MUST:
	  1.	Run `gh auth status` and verify the active account is the expected agent-committer identity.
	  2.	If the wrong account is active, run `gh auth switch --user <correct-username>` before proceeding.
	  3.	Never assume the correct account is active from a previous session or command.
	•	This applies every time — not just the first operation in a session.
	•	This rule is non-overridable (ADR-0012).

⸻

Document hygiene gate

Before marking a PR as ready for review, verify all of the following:

	1.	Status fields are current: All FS and PLAN documents referenced by this PR have accurate `status:` values. See `workflows/document-lifecycle.md` for valid transitions.
	2.	`updated:` dates are current: Any modified FS, PLAN, or ADR has its `updated:` front matter field set to today's date.
	3.	README index files are current: If you added or changed the status of a document in `docs/specifications/`, `docs/change-plans/`, or `docs/decisions/`, the corresponding `README.md` in that directory reflects the change.
	4.	CHANGELOG entry exists: If this PR introduces a user-visible change (feature, fix, breaking change), there is a corresponding entry in `CHANGELOG.md` under `[Unreleased]` or the appropriate version section.
	5.	Cross-references are complete: FS `related_adrs` and PLAN `related_specs` front matter fields reference all relevant companion documents.
	6.	Interfaces match reality: The files touched by this PR align with the `interfaces:` declared in the governing FS. If they diverge, update the FS or explain in the PR description.

⸻

Role 1: Spec Reader and Test Planner

Purpose

Translate approved feature specifications into executable tests.

Inputs (Authoritative)
	•	docs/specs/*.md where type: feature-spec and status: approved

Authoritative Sections
	•	## Success Criteria
	•	## Interfaces
	•	## Non-Goals
	•	## Out of Scope

Outputs
	•	Test files only
	•	No production code

Responsibilities
	•	Map each success criterion to one or more tests.
	•	Ensure tests are deterministic and meaningful.
	•	Name tests after the behavior they validate.

Prohibited Actions
	•	Writing or modifying production code
	•	Modifying specs or metadata
	•	Introducing behavior not explicitly specified
	•	Optimizing or refactoring implementation details

Stop Conditions
	•	Spec status is not approved
	•	Success criteria are not testable
	•	Interfaces are unclear

⸻

Role 2: Implementer

Purpose

Implement the minimum code necessary to satisfy failing tests.

Inputs (Authoritative)
	•	Failing tests
	•	Approved feature specs
	•	Accepted ADRs (type: adr, status: accepted)
	•	Architecture context (type: architecture)

Outputs
	•	Production code changes

Responsibilities
	•	Make tests pass with the smallest viable change.
	•	Respect all documented constraints.
	•	Preserve existing behavior unless tests require change.
	•	Run the full test suite (or targeted tests) after each change.
	•	Run lint/format tools before committing.
	•	Confirm all tests pass before committing. Never commit with failing tests.

Prohibited Actions
	•	Modifying specs, ADRs, or architecture docs
	•	Introducing new features or behaviors
	•	Refactoring unrelated code
	•	Rewriting architecture or changing system boundaries
	•	Committing code with failing tests
	•	Changing version numbers in project manifests (package.json, pyproject.toml, setup.cfg, etc.) during feature work

Stop Conditions
	•	A test requires behavior not specified
	•	An ADR constrains the implementation path
	•	Architecture boundaries are violated
	•	Tests fail and the cause is unclear

⸻

Role 3: Reviewer

Purpose

Verify alignment between documentation, tests, and implementation.

Inputs (Authoritative)
	•	Feature specs
	•	ADRs
	•	Architecture docs
	•	Test code
	•	Implementation diffs

Outputs
	•	Review comments only

Responsibilities
	•	Identify mismatches between specs and code
	•	Identify missing or insufficient tests
	•	Flag conflicts with ADRs or architecture
	•	Call out undocumented behavior

Prohibited Actions
	•	Modifying code or documentation
	•	Fixing issues directly
	•	Reinterpreting intent

Stop Conditions
	•	Conflicting documentation
	•	Undocumented behavior

⸻

Conflict Resolution Rules

If two sources conflict, follow this precedence order:
	1.	Accepted ADRs
	2.	Approved feature specs
	3.	Architecture documentation
	4.	Tests
	5.	Implementation code

If conflicts cannot be resolved without interpretation, escalate to a human.

⸻

Non-Goals of This Contract

This contract does NOT:
	•	Dictate programming language or framework
	•	Replace human judgment
	•	Enforce coding style
	•	Optimize performance unless specified

It exists solely to prevent ambiguity and silent drift.

⸻

Final Rule

If you feel tempted to be clever, pause.

If you feel tempted to help by adding something not asked for, stop.

Correctness, traceability, and restraint beat creativity here.