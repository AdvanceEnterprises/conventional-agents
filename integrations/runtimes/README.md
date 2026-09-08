# Runtime Bindings

A **runtime binding** maps the framework's setup requirements onto one agent
runtime's configuration surface, under `ADR-0039`. This directory is the home
of runtime bindings — distinct from [substrate bindings](../README.md), which
map the six workflow-substrate capabilities onto platforms like GitHub Issues.

Substrate bindings and runtime bindings solve different problems:

| | Substrate binding | Runtime binding |
| --- | --- | --- |
| Binds | the six substrate capabilities (`ADR-0024`) | the framework's *setup* (`AGENTS.md`, gate scripts, skills, identity, MCP) |
| Lives | `integrations/<substrate>/` (`ADR-0024`) | `integrations/runtimes/<runtime>/` (`ADR-0039`) |
| Example | `integrations/github/` | `integrations/runtimes/claude-code/` |

## Available bindings

| Runtime | Status | Binding |
| --- | --- | --- |
| Claude Code | **available** | [`claude-code/`](./claude-code/README.md) — `FS-0030` |
| Hermes Agent | planned — own FS | (none yet) |
| OpenClaw | planned — own FS | (none yet) |
| Codex | planned — own FS | (none yet) |

The planned three have **no configuration content here** until their own
FS/PLAN cycles land (`ADR-0039` §5).

## What a binding is (and is not)

A binding is a **convenience, not a requirement**. A repository with
`AGENTS.md`, `scripts/`, and `skills/` but no runtime binding installed still
runs the governed workflow end to end: the spec-first gate
(`guidelines/ROLE_CONTRACT.md`), the gate scripts under `scripts/`, and the
skill guidance all function without any runtime-specific configuration. To
exercise a no-binding repository against this claim, follow the procedure in
your own repo: run `npm run check:status` (or `./scripts/check`), open a work
item, and complete it — each step is documented in `workflows/` and needs no
`.claude/`, `~/.hermes/`, or `openclaw.json` to exist.
