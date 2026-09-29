# Python Testing

Language-specific detail for the `testing-guide` skill. Load this when the work
is in Python. The shared principles — authoritative signals, Success Criteria
mapping, ambiguity handling, test file metadata — are in `SKILL.md` and apply
here unchanged.

Source: `guidelines/python/PYTHON_TESTING_GUIDE.md`,
`guidelines/python/PYTHON_IMPLEMENTATION_GUIDE.md`,
`guidelines/python/PYTHON_STYLE_GUIDE.md`.

## Framework

- **Test runner**: pytest
- **Lint/format**: ruff
- **Type checking**: optional (pyright if present)
- **Packaging**: `pyproject.toml`

## Approved Test Patterns

**Parametrized test:**

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

**Ambiguity handling:**

```python
import pytest


@pytest.mark.spec("FS-XXXX")
@pytest.mark.xfail(reason="Spec unclear: FS-XXXX Success Criteria SC-2")
def test_sc_2__ambiguous(subject):
    raise NotImplementedError
```

**Integration test:**

```python
import pytest


@pytest.mark.integration
@pytest.mark.spec("FS-XXXX")
def test_sc_1__<behavior>():
    # Use tmp_path for isolation
    ...
```

## Python Implementer Guidance

**Primary objective:** Make the next failing test pass with the smallest, safest code change.

**Authoritative inputs (in priority order):**

1. Failing pytest tests and their assertions
2. Approved Feature Specs (`status: approved`)
3. Accepted ADRs (`status: accepted`)
4. Architecture context

**Code shape guidelines:**

- Prefer pure functions where possible.
- Keep I/O at the edges.
- Avoid direct use of current time, randomness, env vars, filesystem, network — isolate behind injectable interfaces.
- Prefer extension over modification (add new functions/modules when possible).
- Use type hints on public functions and module boundaries.

**Error handling defaults:**

- Invalid arguments: `ValueError`, `TypeError`
- Missing/malformed data: explicit validation + `ValueError`
- Operational failures: `RuntimeError` or domain-specific exception
- Do not swallow exceptions. Do not use bare `except Exception`.

**Implementation checklist:**

- [ ] Confirm the relevant Feature Spec is approved
- [ ] Identify the failing test(s) and mapped Success Criteria
- [ ] Identify ADR constraints that apply
- [ ] Implement the minimum change to pass the next failing test
- [ ] Run targeted pytest tests
- [ ] Run `./scripts/verify` if available
