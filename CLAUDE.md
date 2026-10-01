# CLAUDE.md — conventional-agents

This file imports the framework's canonical entry point. It adds no authority
tier of its own: the precedence hierarchy is `ADR-0004`'s, with `AGENTS.md` at
the top.

@AGENTS.md

Runtime binding: `integrations/runtimes/claude-code/` (FS-0030). The audit is
advisory — run `integrations/runtimes/claude-code/bin/ca-runtime-audit.sh` for
a report of how your `.claude/` matches the binding.
