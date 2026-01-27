"""
---
type: test-module
language: python
framework: pytest
spec_id: FS-XXXX
scope: unit
---

<!--
PARSING_HINTS:
- This file contains tests only.
- Use spec_id to find the authoritative Feature Spec.
- Generate tests ONLY from the spec's "## Success Criteria".
- Each Success Criterion must appear verbatim in the "Spec mapping" comment block.
- Each test name must include the SC number (e.g., test_sc_1__).
- Do not add tests not traceable to a Success Criterion.
- If criterion is untestable or ambiguous, use pytest.mark.xfail with a reason referencing the spec.
-->

Tests for Feature Spec FS-XXXX <title>

Authority:
- Feature Spec: docs/specs/FS-XXXX-<slug>.md (status: approved)

Rules:
- Tests map 1:1 to Success Criteria.
- Do not invent behavior.
- If a criterion is untestable, mark xfail and reference the spec.
"""

import pytest


# ---------------------------------------------------------------------------
# Spec mapping
# Each Success Criterion MUST appear here verbatim.
# ---------------------------------------------------------------------------

# SC-1: <copy exact success criterion text>
# SC-2: <copy exact success criterion text>


# ---------------------------------------------------------------------------
# Fixtures
# Prefer explicit fixtures over shared state.
# ---------------------------------------------------------------------------

@pytest.fixture
def subject():
"""System under test (SUT)."""
raise NotImplementedError


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@pytest.mark.spec("FS-XXXX")
def test_sc_1__<short_behavior_name>(subject):
"""SC-1: <short criterion summary>"""
# Given
# When
# Then
raise NotImplementedError


@pytest.mark.spec("FS-XXXX")
def test_sc_2__<short_behavior_name>(subject):
"""SC-2: <short criterion summary>"""
raise NotImplementedError