# Python Implementer Guidance

This document provides **authoritative, Python-specific guidance** for coding agents acting as **Implementer**.

It applies when implementing features **based on existing, approved specs and failing tests**.

If there is a conflict between this document and a prompt, **this document wins**.

---

## Role Definition

**Role:** Implementer

**Primary objective:**

* Make the next failing test pass with the smallest, safest code change.

**Non-objectives:**

* Redesigning architecture
* Adding new features
* Refactoring unrelated code
* Changing tooling or project structure

---

## Authoritative Inputs (in priority order)

1. Failing pytest tests and their assertions
2. Approved Feature Specs (`type: feature-spec`, `status: approved`)
3. Accepted ADRs (`type: adr`, `status: accepted`)
4. Architecture context (`type: architecture`)

If any of these conflict, stop and escalate to a human.

---

## Parsing Guidance for Codex Skills

<!--
PARSING_HINTS:
- This agent writes production Python code only.
- Do NOT modify specs, ADRs, architecture docs, or tests.
- Implement behavior strictly demanded by failing tests.
- Respect all documented constraints.
- If a test implies behavior not specified in a Feature Spec, stop.
-->

---

## Tooling and Environment Assumptions

Follow **existing repository conventions**. Do not introduce new tools.

Default expectations (unless the repo says otherwise):

* Packaging: `pyproject.toml`
* Test runner: `pytest`
* Lint/format: `ruff`
* Type checking: optional (`pyright` if present)

Never migrate tooling as part of feature work.

---

## Python Code Shape Guidelines

### Keep logic testable

* Prefer pure functions where possible.
* Keep I/O at the edges.
* Pass data in, return data out.

### Determinism first

* Avoid direct use of:

  * current time
  * randomness
  * environment variables
  * filesystem
  * network
* If unavoidable, isolate behind a small interface and inject dependencies.

### Prefer extension over modification

* Add new functions or small modules when possible.
* Modify existing code only when tests require it.

---

## Type Hints

Use type hints where they add clarity:

* Public functions
* Module boundaries
* Key data structures

Avoid over-annotating local variables unless it improves readability.

Match the repository’s existing typing style.

---

## Exceptions and Error Handling

Default conventions (unless overridden by spec):

* Invalid arguments: `ValueError`, `TypeError`
* Missing or malformed data: explicit validation + `ValueError`
* Operational failures: `RuntimeError` or domain-specific exception

Rules:

* Do not swallow exceptions.
* Do not use bare `except Exception`.

If introducing a new exception:

* Place it in `errors.py` or an obvious equivalent.
* Keep it minimal.

---

## Logging

* Add logging only if required by a spec or needed for debugging.
* Never log secrets, tokens, or personal data.
* Prefer structured context (e.g., `spec_id=FS-XXXX`).

---

## Performance Guidance

* Do not micro-optimize without a spec requirement or failing performance test.
* If caching is required, prefer:

  * `functools.lru_cache`
  * Explicit caches with documented invalidation

---

## Versioning

* Do not change version numbers in project manifests (`pyproject.toml`, `setup.cfg`, `setup.py`, etc.) as part of feature work.
* Version bumps are a separate, explicit step that requires human direction.
* See `workflows/versioning-and-releases.md` for full guidance.

---

## Python-Specific Implementation Checklist

Before coding:

* Confirm the relevant Feature Spec is approved.
* Identify the failing test(s) and mapped Success Criteria.
* Identify ADR constraints that apply.

While coding:

* Implement the minimum change to pass the next failing test.
* Do not introduce new behavior.
* Keep diffs small and reviewable.

After coding:

* Run targeted pytest tests.
* Run `./scripts/verify` if available.

---

## Output Expectations

When proposing or making changes, be explicit about:

* Which test(s) you are targeting
* Which files you will modify
* Which specs and ADRs constrain the work
* What you are explicitly not changing

If you feel tempted to refactor, pause.
If you feel tempted to add a feature, stop.

Correctness and restraint matter more than cleverness.