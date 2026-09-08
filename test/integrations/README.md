# test/integrations/ — conformance bats for binding changes

Per `skills/binding-authoring/SKILL.md` (Example 2): the conformance bats for
a **purely declarative** binding — a substrate binding with no governing FS —
live here, since only an executable layer earns its own FS (as `FS-0029` did
for GitHub). Bats for an executable layer keep the `test/<FS-id>/` layout of
the FS that governs it. This home is declared by the framework so the
`binding-authoring` skill's example resolves (FS-0022 §1c / check:status
rule 8).

Pattern: `binding-conformance.bats`, modelled on
`test/FS-0016/vendor-boundary.bats`, using the shared helpers under
`test/FS-0001/helpers.bash`.
