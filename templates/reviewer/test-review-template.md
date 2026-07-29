<!--
TEST_REVIEW_TEMPLATE:
- Role: Reviewer
- Output: Comments only

PARSING_HINTS:
- Document type: reviewer-template
- Output MUST be comments only.
- Verify 1:1 mapping from Feature Spec Success Criteria to tests.
- Ensure tests are deterministic and avoid real time/network/FS unless explicitly required.
- Flag any tests not traceable to a spec as scope creep.
- If a criterion is ambiguous, prefer xfail over guessing.
-->

# Test Review Summary

- Spec: FS-_____
- Criterion coverage: complete/partial
- Deterministic: yes/no
- Too coupled to implementation: yes/no

## Coverage mapping

- Missing SC tests: `SC list`
- Extra tests not tied to SC: `list`

## Quality concerns

- Uses real time/network/FS when avoidable: `details`
- Poor assertions or weak signals: `details`
- Flaky patterns (randomness, ordering, timing): `details`

## Required changes

1. `action`
