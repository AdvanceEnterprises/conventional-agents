---
updated: 2026-07-29
---

# Agent Test Guide (PyTest)

This document provides **authoritative guidance for coding agents** when writing or reviewing tests using **pytest** in this repository.

It applies to **Role 1: Spec Reader and Test Planner** and **Role 3: Reviewer** as defined in the Agent Role Contract.

If there is a conflict between this guide and a prompt, **this guide wins**.

---

## Scope

This guide covers:

* How Codex skills should parse and interpret test files
* How Feature Specs map to tests
* Approved patterns for parametrized tests
* The preferred pattern for handling ambiguity in specs

It does NOT define pytest basics or general Python testing practices.

---

## Parsing Guidance for Codex Skills

### Authoritative signals

Agents MUST rely on the following, in order:

1. Test module docstring metadata (YAML-like block)
2. `PARSING_HINTS` blocks inside test module docstrings
3. Feature Spec front matter and parsing hints
4. The body of the Feature Spec

If these conflict, stop and escalate to a human.

---

### Test module metadata expectations

Each pytest test module SHOULD include a top-level docstring containing:

```text
---
type: test-module
language: python
framework: pytest
spec_id: FS-XXXX
scope: unit | integration
---
```

Agents MUST:

* Use `spec_id` to locate the authoritative Feature Spec
* Refuse to write tests if the spec status is not `approved`
* Treat missing or malformed metadata as a stop condition

---

### Success Criteria mapping rules

* Each bullet in `## Success Criteria` MUST map to at least one test.
* Success Criteria text MUST be copied verbatim into the `Spec mapping` comment block.
* Test names MUST include the corresponding SC identifier (e.g., `test_sc_1__...`).
* Tests MUST NOT validate behavior not explicitly stated in the spec.

If a criterion cannot be tested as written, do NOT guess.

---

## Approved Test Patterns

### Parametrized test pattern

Use parametrization when a single Success Criterion implies multiple concrete cases.

```python
import pytest


@pytest.mark.spec("FS-XXXX")
@pytest.mark.parametrize(
    "input_value, expected",
    [
        pytest.param(<input1>, <expected1>, id="case-1"),
        pytest.param(<input2>, <expected2>, id="case-2"),
    ],
)
def test_sc_3__<short_behavior_name>(subject, input_value, expected):
    actual = subject.<function>(input_value)
    assert actual == expected
```

Rules:

* Parametrization MUST NOT introduce new requirements.
* Each parameter case must still satisfy the same Success Criterion.
* Case IDs SHOULD be descriptive and deterministic.

---

### Preferred pattern for handling ambiguity

If a Success Criterion is ambiguous, incomplete, or untestable:

```python
import pytest


@pytest.mark.spec("FS-XXXX")
@pytest.mark.xfail(reason="Spec unclear: FS-XXXX Success Criteria SC-2")
def test_sc_2__ambiguous(subject):
    raise NotImplementedError
```

Rules:

* Always reference the spec ID and SC number in the xfail reason.
* Do NOT attempt to infer intended behavior.
* This pattern exists to force clarification in the spec.

---

## Integration test guidance

Integration tests SHOULD:

* Be few in number
* Be deterministic
* Use pytest fixtures such as `tmp_path`
* Avoid external dependencies unless explicitly required by the spec

Integration tests MUST:

* Be marked with `@pytest.mark.integration`
* Be traceable to a Feature Spec via `@pytest.mark.spec`

---

## Reviewer checklist (tests)

When acting as Reviewer, agents SHOULD check:

* Every Success Criterion has at least one test
* No test exists without a corresponding spec reference
* No behavior is validated that is not documented
* Ambiguities are surfaced via xfail, not hidden via assumptions

---

## Non-goals

This guide does NOT:

* Optimize test performance
* Enforce coverage thresholds
* Dictate fixture structure beyond minimal guidance
* Replace human judgment

It exists solely to keep tests honest, traceable, and spec-driven.

---

## Final note

If writing a test feels creative, pause.

If writing a test requires guessing, stop.

The test suite is executable documentation. Treat it with the same restraint as specs and ADRs.
