# Validation Baseline

This baseline records the reproducibility contract's reference validation run.

| Field | Value |
| --- | --- |
| Revision | `bbd7a587a1d63dfe7d38a536cf752937ca9e8c25` |
| Timing | `npm test` 1215s; `lint:docs` 39s; `check:status` 35s; `check:freshness` 1s; `lint:cross-repo` 4s; total 1294s |
| Log | `docs/validation-baseline.log` |
| Final verdict | `VALIDATION PASS` |

The recorded revision is the clean commit under test. The five gates ran in
fixed order with a 1800-second global budget, a 1800-second test budget, and
900-second per-suite Bats bounds. The Bats output includes the serial and
concurrent fixture reproducibility checks.
