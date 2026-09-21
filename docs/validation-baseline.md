# Validation Baseline

This baseline records the reproducibility contract's reference validation run.

| Field | Value |
| --- | --- |
| Revision | `bbd7a587a1d63dfe7d38a536cf752937ca9e8c25` |
| Recording commit | `221c7c0ad128c91ce1861f5ba0954fb6075280b4` |
| Timing | `npm test` 1215s; `lint:docs` 39s; `check:status` 35s; `check:freshness` 1s; `lint:cross-repo` 4s; total 1294s |
| Log | `docs/validation-baseline.log` |
| Final verdict | `VALIDATION PASS` |

The recorded revision is the clean commit under test — the run it names is the
run in the log. It is deliberately *not* the commit that records this file: the
baseline is captured before the recording commit exists, and the delta between
the two is documentation-only (this file, the log, and the FS/PLAN status
rows), so the run stays representative of the code at the tip. Re-run the
baseline only when the validation surface itself changes; the log's
`VALIDATION START` line is the authoritative revision for any given run. The
five gates ran in fixed order with a 1800-second global budget, a 1800-second
test budget, and 900-second per-suite Bats bounds. The Bats output includes the
serial and concurrent fixture reproducibility checks.
