<!--
SPEC_REVIEW_TEMPLATE:
- Role: Reviewer
- Output: Comments only

PARSING_HINTS:
- Document type: reviewer-template
- Output MUST be comments only.
- Evaluate specs for testability first.
- Required changes must target making Success Criteria measurable and unambiguous.
- Do not propose implementation details unless the spec explicitly needs an interface clarified.
- Cite specific spec sections (e.g., "Success Criteria SC-2") when requesting changes.
-->

# Spec Review: FS-_____
- Status: draft/approved/etc
- Is Success Criteria testable? yes/no
- Any criteria ambiguous? <SC list>
- Non-Goals / Out of Scope clear? yes/no
- Interfaces defined? yes/no

## Fix before approval
1. <make criterion measurable>
2. <clarify interface>

## Suggested improvements
- <wording / edge case>

<!--
PARSING_HINTS:
- Document type: reviewer-template
- Include this addendum ONLY when the spec or diff touches security/privacy-sensitive areas.
- Focus on data handling, authn/authz, input validation, secrets, and logging.
- Required changes must cite evidence (spec text, ADR constraint, or code location).
-->

## Security / Privacy Addendum (only if applicable)
- Data handled: <what data types are touched>
- Threats considered: authz bypass, injection, leakage, logging PII, secrets exposure
- Tests validating security constraints: present/missing
- Any new dependencies or permissions: <list>