---
name: testing-guide
description: "Writes tests from approved specs across Python, JavaScript/TypeScript, and Bash; applies implementer guidance and approved test patterns. Use when translating success criteria into tests, choosing a test layout, practising TDD, or working with pytest, vitest, or bats."
license: MIT
---

# Testing Guide Skill

Turning an approved Feature Spec into tests that define the correctness boundary
for implementation. The language-agnostic rules are here; per-language patterns
and implementer guidance are in `references/`, loaded on demand.

## Source Documents

- `guidelines/python/PYTHON_TESTING_GUIDE.md`, `guidelines/python/PYTHON_IMPLEMENTATION_GUIDE.md`, `guidelines/python/PYTHON_STYLE_GUIDE.md`
- `guidelines/javascript/JS_TESTING_GUIDE.md`, `guidelines/javascript/JS_IMPLEMENTATION_GUIDE.md`, `guidelines/javascript/JS_STYLE_GUIDE.md`
- `guidelines/bash/BASH_TESTING_GUIDE.md`, `guidelines/bash/BASH_IMPLEMENTATION_GUIDE.md`, `guidelines/bash/BASH_STYLE_GUIDE.md`

## When to Use

- An FS has reached `status: approved` and its Success Criteria need translating
  into executable tests.
- You are implementing against failing tests and need the language's implementer
  guidance.
- A Success Criterion is ambiguous and you need the pattern that surfaces it
  rather than guessing.
- You are reviewing tests and need the acceptance checklist.

## Gates That Bind Here

Summarised, not restated. Canonical text: `guidelines/ROLE_CONTRACT.md`
§ Spec-first rule and § Pre-commit testing gate.

- **No tests before the FS is `approved`.** If it is `draft`, the first
  deliverable is the spec, not the test.
- **Run the suite before committing.** Never commit a change that leaves tests
  failing.
- Role boundaries: Spec Reader and Test Planner writes tests only; Implementer
  writes production code only. See `skills/role-aware-session/SKILL.md`.

## Language Guides

Load the one you need. Each carries that language's framework choice, approved
test patterns, and implementer guidance.

| Language | Reference |
| --- | --- |
| Python — pytest, ruff | `references/python.md` |
| JavaScript / TypeScript — Vitest, Jest | `references/javascript-typescript.md` |
| Bash — bats, shell integration | `references/bash.md` |

---

## Shared Principles (All Languages)

### Authoritative Signals (in order)

1. Test file metadata (YAML-like block in docstring/header)
2. `PARSING_HINTS` blocks inside test files
3. Feature Spec front matter and parsing hints
4. The body of the Feature Spec

If these conflict, stop and escalate to a human.

### Success Criteria Mapping Rules

- Each bullet in `## Success Criteria` MUST map to at least one test.
- Success Criteria text MUST be referenced in the test (verbatim in a comment or metadata).
- Test names MUST be descriptive and include the SC identifier when clear.
- Tests MUST NOT validate behavior not explicitly stated in the spec.

### Ambiguity Handling

If a Success Criterion is ambiguous, incomplete, or untestable:

| Language | Pattern |
| --- | --- |
| Python | `@pytest.mark.xfail(reason="Spec unclear: FS-XXXX SC-N")` with `raise NotImplementedError` |
| JavaScript/TypeScript | `it.todo("SC-N: spec is ambiguous, needs clarification (see FS-XXXX SC-N)")` |
| Bash | `skip "Spec does not define ..."` with descriptive reason |

Rules:

- Always reference the spec ID and SC number.
- Do NOT attempt to infer intended behavior.
- This pattern forces clarification in the spec.

### Test File Metadata

Each test file SHOULD include metadata at the top:

**Python (pytest):**

```python
"""
---
type: test-module
language: python
framework: pytest
spec_id: FS-XXXX
scope: unit | integration
---
"""
```

**JavaScript/TypeScript (Vitest/Jest):**

```javascript
/**
 * @module test
 *
 * ---
 * type: test-module
 * language: javascript
 * framework: vitest
 * spec_id: FS-XXXX
 * scope: unit | integration
 * ---
 */
```

**Bash (bats):**

```bash
#!/usr/bin/env bats
#
# Test suite for <feature>
#
# ---
# type: test-module
# language: bash
# framework: bats
# spec_id: FS-XXXX
# scope: unit | integration
# ---
```

---

## Example 1 — Map a Success Criterion to a test

Given this criterion in an approved spec:

```text
SC-7. Given the framework repository is private and no credential is present,
      when the command runs, then it exits non-zero without initialising the
      submodule, and the message names the expected environment variable.
```

The test carries the SC identifier in its name and the criterion text verbatim
in a comment, so the mapping survives a reader who has not opened the spec:

```bash
@test "sc_7: private repo with no credential fails closed and names the variable" {
    # SC-7: private + no credential -> exit non-zero, submodule not initialised,
    # message names the expected environment variable.
    CA_FAKE_VISIBILITY=private run bash "$SCRIPT" --no-credential
    [ "$status" -ne 0 ]
    [[ "$output" == *"CA_FRAMEWORK_TOKEN"* ]]
}
```

## Example 2 — Surface an ambiguous criterion instead of guessing

When a criterion does not say enough to test, do not infer. Encode the gap so it
fails visibly and names what is missing:

```python
import pytest


@pytest.mark.spec("FS-0029")
@pytest.mark.xfail(reason="Spec unclear: FS-0029 SC-21 does not define the retry ceiling")
def test_sc_21__rate_limit_backoff(subject):
    raise NotImplementedError
```

The `xfail` is the deliverable. It routes the question back to the spec author
rather than freezing a guess into the test suite.

---

## Reviewer Checklist (Tests)

When reviewing tests, check:

- [ ] Every Success Criterion has at least one test
- [ ] No test exists without a corresponding spec reference
- [ ] No behavior is validated that is not documented
- [ ] Ambiguities are surfaced via xfail/skip/it.todo, not hidden via assumptions
- [ ] Tests are deterministic (same result every run)
- [ ] Tests are isolated (no shared mutable state between tests)
- [ ] Tests clean up after themselves
- [ ] Test names are clear and describe what is tested
- [ ] All async tests properly `await` or return promises (JS/TS)
- [ ] Mocking is done via framework utilities, not manual monkey-patching (JS/TS)
- [ ] Scripts use `set -euo pipefail` (Bash)
- [ ] Variables are quoted and properly scoped (Bash)

## Common Pitfalls

| Pitfall | Consequence |
| --- | --- |
| Inferring intent from an ambiguous criterion | Freezes a guess into the suite; the spec never gets corrected |
| Testing behaviour the spec does not state | The test becomes the specification, and nobody approved it |
| Writing tests against a `draft` spec | The spec-first gate exists because criteria change before approval |
| A test that mutates tracked files without restoring them | Concurrent runs collide, and an interrupt leaves the repository dirty |
| Depending on wall-clock time, randomness, or network | Non-deterministic failures get retried rather than diagnosed |
| Asserting a command "succeeds" without asserting what it produced | A no-op implementation passes |

---

## Related Skills

- `skills/document-lifecycle/SKILL.md` — the FS `status: approved` gate that must hold before tests are written
- `skills/role-aware-session/SKILL.md` — Spec Reader / Test Planner vs Implementer stance
- `skills/git-branch-and-commit/SKILL.md` — the pre-commit testing gate this skill's output feeds

---

## Prohibitions

- **Do NOT** write tests for a spec that is not `approved`.
- **Do NOT** validate behavior not explicitly stated in the spec.
- **Do NOT** infer intent when a Success Criterion is ambiguous — use the ambiguity pattern.
- **Do NOT** write production code when acting as Spec Reader and Test Planner.
- **Do NOT** modify specs, ADRs, or architecture docs when acting as Implementer.
- **Do NOT** introduce new features or behaviors not required by failing tests.
- **Do NOT** refactor code unrelated to the failing test.
- **Do NOT** change version numbers in project manifests during feature work.
- **Do NOT** commit code with failing tests.
