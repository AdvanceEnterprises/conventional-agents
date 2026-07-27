# `roles/` — project-customizable role contracts

This directory is the framework's hook for **host-repo customization** of
the role model defined in `guidelines/ROLE_CONTRACT.md`.

## How it works

`guidelines/ROLE_CONTRACT.md` is the **framework-level standard** —
maintained inside the kit, demonstrating the intended role structure.
When a host repo vendors `conventional-agents` (typically as
`vendor/conventional-agents/`), `guidelines/` is a reference template,
not the live contract for that project.

The live, project-customizable contract for a host repo **starts as an
empty directory** and grows as the project adapts roles to its own team,
domain, and constraints. See `AGENTS.md` §"Exported Surface vs Internal
Governance" for where this fits in the framework's structure.

## Recommended workflow

1. **Start from the guideline.** Copy `guidelines/ROLE_CONTRACT.md`
   from the vendored framework into a working location in your host
   repo (e.g., `docs/governance/role-contract.md` or your own
   `roles/ROLE_CONTRACT.md` if you maintain that path).
2. **Customize for your project.** Add domain-specific constraints,
   additional stop conditions, project-specific prohibited actions, or
   narrowed role boundaries. Keep changes traceable to a PR so future
   contributors can understand why the contract differs from the
   framework's default.
3. **Reference the customized copy from your `AGENTS.md`.** Update the
   Foundation Standards section to point at your customized file rather
   than `vendor/conventional-agents/guidelines/ROLE_CONTRACT.md`.
4. **Re-sync periodically.** When you bump the framework submodule,
   review the diff between your customized copy and the new
   `guidelines/ROLE_CONTRACT.md`. Adopt upstream improvements; resolve
   conflicts deliberately, not by accident.

## Why this directory is empty

The framework ships `roles/` empty rather than pre-populated with a
copy of the guideline. Two reasons:

- **Customization is the point.** A pre-populated copy implies the
  framework has already customized the contract for you, which it has
  not. Every project's role contract needs its own constraints,
  stop conditions, and authority boundaries.
- **Avoids stale drift.** A copy that ships with the framework can fall
  behind `guidelines/ROLE_CONTRACT.md` over time. Host repos that
  imported the stale copy would inherit the drift. An empty directory
  forces the project to make a deliberate choice.

## What goes here

This directory should contain whatever files your project needs to
document its customized role model. Common patterns:

- `ROLE_CONTRACT.md` — your project's customized role contract
  (recommended).
- `role-additions.md` — additional roles beyond the framework's six
  (rare; usually means a new ADR is warranted).
- `session-modes.md` — project-specific session modes that extend or
  replace `workflows/session-modes.md`.

If you don't yet know what to put here, **leave the directory empty**
until you have a customization to make. Empty is the correct initial
state for a vendored framework.

## Related

- `guidelines/ROLE_CONTRACT.md` — the framework's normative role model.
- `AGENTS.md` §"Exported Surface vs Internal Governance" — directory
  placement and the framework's exported-surface rules.
- `INTEGRATION.md` — vendor patterns and customization workflows.