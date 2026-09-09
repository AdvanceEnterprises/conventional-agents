#!/usr/bin/env bash
# ca-runtime-audit.sh — report-only conformance audit for the Claude Code
# runtime binding (FS-0030, ADR-0039, SC-18/19/20).
#
# Tells a consumer whether their .claude/ matches the binding. Non-mutating:
# it reads repository state and prints a report — it never writes .claude/,
# never edits config, never runs a mutating gh/git operation.
#
# Exit semantics:
#   default  — exit 0 whether or not divergences are found (report-only)
#   --strict — exit 1 when divergences exist (for scripts that want a signal)
#
# Resolves its target repository from the caller's working directory, with
# CA_TARGET_REPO overriding (FS-0024/ADR-0033). Bash 3.2 compatible — no
# associative arrays (macOS system bash, per scripts/README.md).

set -u

usage() {
  cat <<'EOF'
ca-runtime-audit.sh — Claude Code runtime binding conformance audit (report-only)

Usage:
  ca-runtime-audit.sh [--strict] [--json]

Flags:
  --strict   exit 1 when divergences are found (default: always exit 0)
  --json     emit a machine-readable summary line as JSON
  -h, --help print this usage and exit 0

Environment:
  CA_TARGET_REPO   repository root to audit (default: current working directory)

The audit compares a repository's .claude/ against the binding described in
integrations/runtimes/claude-code/README.md and prints one line per check:
  [ok]     — the check passes
  [warn]   — a divergence (config present but not matching)
  [info]   — a missing optional artefact (advisory)

Exit code is 0 in default mode regardless of findings; --strict turns any
divergence into exit 1. The audit never modifies anything.
EOF
}

STRICT=0
JSON=0
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    --json) JSON=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "unknown flag: $arg (see --help)" >&2
      exit 2
      ;;
  esac
done

REPO="${CA_TARGET_REPO:-$PWD}"
CLAUDE_DIR="$REPO/.claude"
BINDING_DIR="$REPO/integrations/runtimes/claude-code"

if [ -f "$BINDING_DIR/lib/common.sh" ]; then
  # shellcheck disable=SC1091
  . "$BINDING_DIR/lib/common.sh"
fi

[ -d "$CLAUDE_DIR" ] || {
  echo "[info] no .claude/ directory — nothing to audit (binding not installed)"
  exit 0
}

ok=0
warn=0
info=0
report=""

# --- settings.json: Agent-Attribution / commit identity keys -----------------
SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ]; then
  if grep -qE 'Agent-Attribution|git.*user|statusLine|hooks' "$SETTINGS" 2>/dev/null; then
    ok=$((ok+1))
    report="$report[ok] settings.json carries identity/attribution/hook keys
"
  else
    warn=$((warn+1))
    report="$report[warn] settings.json lacks identity/attribution/hook keys
"
  fi
else
  info=$((info+1))
  report="$report[info] no .claude/settings.json (merge the settings.fragment.json keys)
"
fi

# --- hooks.json: the advisory gate runner ------------------------------------
HOOKS="$CLAUDE_DIR/hooks/hooks.json"
if [ -f "$HOOKS" ]; then
  if grep -qE 'check-status\.sh|check:status|lint:docs|PostToolUse|PreToolUse' "$HOOKS" 2>/dev/null; then
    ok=$((ok+1))
    report="$report[ok] hooks.json references an advisory gate runner
"
  else
    warn=$((warn+1))
    report="$report[warn] hooks.json present but no framework gate hook found
"
  fi
else
  info=$((info+1))
  report="$report[info] no .claude/hooks/hooks.json (advisory hook not installed)
"
fi

# --- CLAUDE.md: imports AGENTS.md ---------------------------------------------
CLAUDE_MD="$REPO/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
  if grep -qE '^@AGENTS\.md' "$CLAUDE_MD" 2>/dev/null; then
    ok=$((ok+1))
    report="$report[ok] CLAUDE.md imports AGENTS.md
"
  else
    warn=$((warn+1))
    report="$report[warn] CLAUDE.md does not import AGENTS.md with the @AGENTS.md form
"
  fi
else
  warn=$((warn+1))
  report="$report[warn] no CLAUDE.md (binding's CLAUDE.md.example not adopted)
"
fi

# --- plugin vs fragment path ---------------------------------------------------
PLUGIN="$CLAUDE_DIR/.claude-plugin/plugin.json"
[ -f "$PLUGIN" ] && {
  ok=$((ok+1))
  report="$report[ok] plugin manifest present ($PLUGIN)
"
}

# --- skills: every shipped binding skill resolvable ---------------------------
if [ -d "$BINDING_DIR/skills" ]; then
  missing=0
  for entry in "$BINDING_DIR"/skills/*/; do
    [ -d "$entry" ] || continue
    name=$(basename "$entry")
    if [ -f "$entry/SKILL.md" ]; then
      ok=$((ok+1))
      report="$report[ok] binding skill $name/SKILL.md present
"
    else
      missing=$((missing+1))
      warn=$((warn+1))
      report="$report[warn] binding skill $name has no SKILL.md
"
    fi
  done
fi

# --- summary ------------------------------------------------------------------
if [ "$JSON" -eq 1 ]; then
  printf '{"ok":%d,"warn":%d,"info":%d}\n' "$ok" "$warn" "$info"
else
  printf '%s' "$report"
  printf 'summary: %d ok, %d divergences, %d advisory — audit is report-only\n' "$ok" "$warn" "$info"
fi

if [ "$STRICT" -eq 1 ] && [ "$warn" -gt 0 ]; then
  exit 1
fi
exit 0
