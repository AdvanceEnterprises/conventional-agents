<!--
REVIEWER_TEMPLATE:
- Role: Reviewer (no code changes)
- Inputs: Spec(s), ADR(s), arc42, tests, diffs, CI results
- Output: Comments only, structured

PARSING_HINTS:
- Document type: reviewer-template
- Output MUST be comments only (no code changes, no doc edits).
- Require traceability: every required change must cite a Spec ID, ADR ID, or failing test/CI signal.
- Separate MUST-FIX from NICE-TO-HAVE.
- If evidence is missing, downgrade to Suggestion.
- If docs conflict, stop and request human resolution.
- Prefer short, actionable bullets over prose.
-->

# Review Summary
- Verdict: ✅ Approve | ⚠️ Request changes | ❌ Block
- Scope assessed: <what spec/ADR this PR claims to implement>
- Confidence: High | Medium | Low (explain why if not High)

## Spec Alignment (Docs)
- Spec(s) referenced: FS-_____
- Status check: approved? yes/no
- Missing/unclear criteria: <list>
- Scope creep detected: yes/no (details)

## Test Coverage (Proof)
- Success Criteria coverage: <complete/partial>
- Missing tests: <list SC numbers>
- Tests that appear to test unstated behavior: <list>
- Ambiguity handled correctly (xfail vs guessing): yes/no

## ADR / Architecture Constraints
- ADR(s) referenced: ADR-_____
- Conflicts with accepted ADRs: none | suspected | confirmed (details)
- Architecture boundary violations: none | suspected | confirmed (details)

## Code Quality (Implementation)
- Minimality: minimal changes | refactor creep | unclear
- Risk areas: <list>
- Observability/security concerns (if applicable): <list>

## CI / Tooling
- `scripts/verify` / CI: pass/fail
- Flaky tests suspected: yes/no (details)

## Required Changes (must fix)
1. <actionable item>
2. <actionable item>

## Suggestions (nice to have)
- <optional improvement>

## Questions for the author
- <only if blocking>