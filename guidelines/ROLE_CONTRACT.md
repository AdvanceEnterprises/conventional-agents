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

Prohibited Actions
	•	Modifying specs, ADRs, or architecture docs
	•	Introducing new features or behaviors
	•	Refactoring unrelated code
	•	Rewriting architecture or changing system boundaries

Stop Conditions
	•	A test requires behavior not specified
	•	An ADR constrains the implementation path
	•	Architecture boundaries are violated

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