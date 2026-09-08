# Claude Code runtime binding

Maps the conventional-agents framework's setup requirements onto Claude Code's
configuration surface (`FS-0030`, `ADR-0039`). This is the first runtime
binding; the shared surface it introduces is `integrations/runtimes/` (index:
[`../README.md`](../README.md)).

## What ships

| Artefact | Classifies as | Purpose |
| --- | --- | --- |
| `.claude-plugin/plugin.json` | provisions | Plugin manifest — the installable form (`claude plugin validate` target) |
| `skills/` | provisions | Skill discovery — synced copies of `skills/*/SKILL.md` (source of truth stays the originals; `metadata.hermes.*` dialects are applied here, never written back — `ADR-0038` §5) |
| `hooks/hooks.json` | provisions | Local **advisory** hook that runs the existing `check-status.sh` / `lint:docs` gate scripts at a documented lifecycle event |
| `.mcp.json.example` | documents | Parameterised MCP configuration example — no real server credentials or endpoints (`ADR-0039` §4) |
| `settings.fragment.json` | documents | `.claude/settings.json` keys for commit identity and the `Agent-Attribution:` trailer (`ADR-0018` / `ADR-0029`) |
| `CLAUDE.md.example` | documents | `CLAUDE.md` that imports `AGENTS.md` and adds no authority tier (`ADR-0004`) |
| `bin/ca-runtime-audit.sh` | documents | Report-only `.claude/` conformance audit — never mutates, never blocks |
| `lib/common.sh` | documents | Shared helpers for the audit |

No artefact **enforces** anything (`ADR-0037` §6). The hook is a local
convenience that adds no enforcement the framework's CI does not already have:
if the gate script exits non-zero, the hook surfaces the failure to the
session without blocking it unconditionally — it is advisory, not a `deny`.

## Install

### As a plugin

```bash
# from a framework checkout
npm run sync:claude-skills        # refresh skills/ copies from skills/*
cp -R integrations/runtimes/claude-code/.claude-plugin .claude/
claude plugin validate .claude-plugin  # local check
```

### As a non-plugin fragment

```bash
cp integrations/runtimes/claude-code/CLAUDE.md.example CLAUDE.md
# merge settings.fragment.json into your .claude/settings.json (additive —
# if you already have hooks there, merge the hook entry, don't overwrite)
```

## The advisory hook

`hooks/hooks.json` runs `ca-runtime-audit.sh --strict --json` after `Read`
tool uses. It exists to surface conformance drift in-session. **It is not a
gate**: Claude Code will not refuse work when the audit reports divergences,
and the framework's CI does not run the audit as a blocking check.

## Skills

`sync-skills.sh` copies the shipped skills listed in `skills/index.md` into
this plugin's `skills/`. **Expected plugin warnings:** the source skills still
carry `metadata.hermes.*` dialect keys, so `claude plugin validate` may warn on
them until the `ADR-0038` Category 2 conformance cleanup lands. The warnings
are expected and permitted (`FS-0030` SC-13).

## Identity and attribution

`settings.fragment.json` sets the git identity and `Agent-Attribution:` trailer
keys (`ADR-0018` / `ADR-0029`). Substitute the placeholder
`{{ACTOR_EMAIL}}` with your own actor address before merging.

## MCP

`.mcp.json.example` is parameterised: replace `{{GITHUB_TOKEN}}` with your own
token. An MCP server that would **expand the framework's governance surface**
requires its own approved FS (`ADR-0039` §4) — this example only wires what a
consumer already has.

## Report-only audit

```bash
bash integrations/runtimes/claude-code/bin/ca-runtime-audit.sh        # exit 0 always
bash integrations/runtimes/claude-code/bin/ca-runtime-audit.sh --strict   # exit 1 on divergence
bash integrations/runtimes/claude-code/bin/ca-runtime-audit.sh --json     # machine-readable
bash integrations/runtimes/claude-code/bin/ca-runtime-audit.sh --help     # usage, exit 0
```

The audit reads `CA_TARGET_REPO` (default: current working directory), makes
no writes, and does not call mutating `gh`/`git` operations. It is registered
in `package.json` as a report-only script that CI does not run as a blocking
check.
