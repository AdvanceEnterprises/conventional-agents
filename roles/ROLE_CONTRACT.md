# Role Contract — Project Copy

**This project adopts the framework role contract unmodified.**

The authoritative text is `guidelines/ROLE_CONTRACT.md`. This document is the
*project's* contract — the file a host repository customizes — and for
`conventional-agents` itself it currently adds nothing.

It exists rather than being absent because the integration path documented in
`README.md` and `INTEGRATION.md` points here: `guidelines/` is the framework
template, `roles/ROLE_CONTRACT.md` is what a project actually operates under,
and `INTEGRATION.md` places this path at precedence level 2. An empty
directory would leave that path unresolvable and give adopters nothing to copy.

It is deliberately **not** a duplicate of `guidelines/ROLE_CONTRACT.md`. A
byte-identical copy drifts, and `ADR-0030` rule 1 requires exactly one current
statement of any rule. Every rule below lives in `guidelines/`; this file
records which of them this project has changed, and the answer is none.

## How to use this file in a host repository

1. Copy it to your repository, or to `roles/ROLE_CONTRACT.md` alongside your
   vendored `vendor/conventional-agents/`.
2. Leave the delegation statement above intact.
3. Under each heading below, add **only** what your project changes or adds.
   Silence means "framework default applies."
4. Never weaken a Non-Overridable Safety Gate. `ADR-0012` places those above
   every other instruction source, including this file.

Additions are the point. If your project needs a Data Steward role, a stricter
merge gate, or a domain-specific stop condition, this is where it goes — not in
`guidelines/`, which is the framework's copy and is overwritten when you update
the submodule.

## Project modifications

### Shared Rules

No project modifications. See `guidelines/ROLE_CONTRACT.md` §"Shared Rules".

### Non-Overridable Safety Gates (ADR-0012)

No project modifications, and none are permitted. The PR merge rule and the
GitHub identity gate cannot be weakened here or anywhere else.

### Document hygiene gate

No project modifications. The seven-item checklist applies as written.

### Role 0 — Head Architect

No project modifications.

### Role 1 — Document Author

No project modifications.

### Role 2 — Spec Reader and Test Planner

No project modifications.

### Role 3 — Implementer

No project modifications.

### Role 4 — Reviewer

No project modifications.

### Role 5 — Communications Lead

No project modifications.

### Conflict Resolution Rules

No project modifications. The precedence order in
`guidelines/ROLE_CONTRACT.md` applies, with `ADR-0012` gates at level 0.

## Related

- `guidelines/ROLE_CONTRACT.md` — the authoritative role contract
- `roles/README.md` — why this directory exists and how host repos use it
- `INTEGRATION.md` — precedence rules; this file is level 2
- `ADR-0012` — non-overridable gates
- `ADR-0030` — why this file delegates rather than duplicates
