"""
---
type: test-module
language: python
framework: pytest
spec_id: FS-XXXX
scope: integration
---

<!--
PARSING_HINTS:
- Integration tests cross boundaries (FS, network, DB, subprocess).
- Keep these tests few and deterministic.
- Use tmp_path and fakes where possible.
- Do not introduce new requirements; tie each test to a spec Success Criterion or clearly labeled integration subset.
- Mark module with pytest.mark.integration and each test with pytest.mark.spec(spec_id).
-->

Integration tests for Feature Spec FS-XXXX <title>

These tests cross system boundaries (filesystem, network, DB, subprocess).
Keep them few, deterministic, and high-signal.
"""

import pytest


pytestmark = [
pytest.mark.integration,
pytest.mark.spec("FS-XXXX"),
]


# SC-INT-1: <integration-focused criterion or subset>


def test_sc_int_1__<short_behavior_name>(tmp_path):
raise NotImplementedError