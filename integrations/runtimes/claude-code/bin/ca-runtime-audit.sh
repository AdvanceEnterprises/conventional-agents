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
# CA_TARGET_REPO overriding (FS-0024/ADR-0033). The resolved target must be
# inside a git working tree: a directory git disclaims is a hard error naming
# it, not a confident "binding not installed" verdict about a directory that
# is not a repository at all. A subdirectory target maps to the work-tree top
# level, and a bare repository and a missing git binary get their own
# diagnostics (issue #204). Bash 3.2 compatible — no
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
  CA_TARGET_REPO   repository to audit (default: the repository containing
                   the current working directory)

The audit compares a repository's .claude/ against the binding described in
integrations/runtimes/claude-code/README.md and prints one line per check:
  [ok]     — the check passes
  [warn]   — a divergence (config present but not matching)
  [info]   — a missing optional artefact (advisory)

Exit code is 0 in default mode regardless of findings; --strict turns any
divergence into exit 1. Neither is used for target-resolution errors: a
target that cannot be resolved (not a directory, not inside a git working
tree, a bare repository, or a missing git) exits 2, distinct from any
finding. The audit never modifies anything.
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

# ----- Target resolution (issue #204) ----------------------------------------
# Before this guard, the target defaulted to the literal working directory: a
# run from a non-git cwd — or from a checkout subdirectory — reported a
# confident "[info] no .claude/ directory — nothing to audit" about a
# directory that was not the repository at all, even under --strict. A
# directory git disclaims must be a loud error instead (the #194 fail-open
# class, runtime-binding edition). Resolution is repository-relative
# (FS-0024/ADR-0033): the target names a repository, so a subdirectory maps
# to its work-tree top level.
if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: 'git' was not found on PATH — the audit resolves its target with git." >&2
  exit 2
fi
if [ -n "${CA_TARGET_REPO:-}" ]; then
  REPO="$(cd "$CA_TARGET_REPO" 2>/dev/null && pwd)" || {
    echo "ERROR: CA_TARGET_REPO='$CA_TARGET_REPO' is not a directory." >&2
    exit 2
  }
else
  REPO="$PWD"
fi
if [ "$(git -C "$REPO" rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
  if [ "$(git -C "$REPO" rev-parse --is-bare-repository 2>/dev/null)" = "true" ]; then
    echo "ERROR: '$REPO' is a bare git repository — it has no working tree to audit." >&2
  else
    echo "ERROR: '$REPO' is not inside a git working tree." >&2
  fi
  echo "       Run this from within the repository it should audit, or set" >&2
  echo "       CA_TARGET_REPO to that repository's working tree. (issue #204)" >&2
  exit 2
fi
REPO="$(git -C "$REPO" rev-parse --show-toplevel 2>/dev/null)"
CLAUDE_DIR="$REPO/.claude"
BINDING_DIR="$REPO/integrations/runtimes/claude-code"

# Summary-helper sourcing (issue #204). The lib ships next to the script; the
# probe order is binding-dir first (unchanged for framework invocations),
# then the script's own location — the one place guaranteed to hold the lib
# whenever this script runs at all, which is the vendored-copy case — and
# finally inline definitions, so a summary line always prints instead of
# "ca_summary: command not found".
audit_lib=""
if [ -f "$BINDING_DIR/lib/common.sh" ]; then
  audit_lib="$BINDING_DIR/lib/common.sh"
else
  audit_self_dir="$(cd "$(dirname "${BASH_SOURCE:-$0}")/.." && pwd)"
  [ -f "$audit_self_dir/lib/common.sh" ] && audit_lib="$audit_self_dir/lib/common.sh"
fi
if [ -n "$audit_lib" ]; then
  # shellcheck disable=SC1091
  . "$audit_lib"
else
  ca_summary() {
    printf 'summary: %s ok, %s divergences, %s advisory — audit is report-only\n' \
      "$1" "$2" "$3"
    if [ "$4" -eq 1 ] && [ "$2" -gt 0 ]; then
      return 1
    fi
    return 0
  }
  ca_json_summary() {
    printf '{"ok":%s,"warn":%s,"info":%s}\n' "$1" "$2" "$3"
  }
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
  # Verify the hook command actually references a framework gate script.
  # PostToolUse/PreToolUse are schema keys that always match — they are NOT
  # sufficient evidence of a gate hook (SC-14).
  if grep -qE 'check-status\.sh|check:status|lint:docs|ca-runtime-audit\.sh' "$HOOKS" 2>/dev/null; then
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
  printf '%s' "$report"
  ca_json_summary "$ok" "$warn" "$info"
else
  printf '%s' "$report"
  ca_summary "$ok" "$warn" "$info" "$STRICT"
fi

if [ "$STRICT" -eq 1 ] && [ "$warn" -gt 0 ]; then
  exit 1
fi
exit 0
