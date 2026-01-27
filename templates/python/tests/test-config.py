"""
---
type: test-config
language: python
framework: pytest
scope: global
---

<!--
PARSING_HINTS:
- Keep this file small.
- Put only shared markers and broadly reusable fixtures here.
- Do not embed feature-specific fixtures; those belong in the feature test module.
- Do not change marker semantics without an ADR.
-->
"""

import pytest


def pytest_configure(config):
config.addinivalue_line(
"markers",
"spec(id): link test to a feature spec id, e.g. @pytest.mark.spec('FS-0001')",
)
config.addinivalue_line(
"markers",
"integration: marks tests as integration tests",
)