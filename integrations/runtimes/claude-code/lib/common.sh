#!/usr/bin/env bash
# common.sh — shared helpers for the Claude Code runtime binding's report-only
# tools (FS-0030 SC-18..20, ADR-0039). Bash 3.2 compatible: no associative
# arrays, no bashisms beyond what the audit itself already requires.
#
# Source from bin/ scripts with:
#   . "$(cd "$(dirname "${BASH_SOURCE:-$0}")/.." && pwd)/lib/common.sh"

# ca_summary — print the audit summary line and apply --strict exit semantics.
#   ca_summary <ok-count> <warn-count> <info-count> <strict-flag>
ca_summary() {
  local ok="$1" warn="$2" info="$3" strict="$4"
  printf 'summary: %s ok, %s divergences, %s advisory — audit is report-only\n' \
    "$ok" "$warn" "$info"
  if [ "$strict" -eq 1 ] && [ "$warn" -gt 0 ]; then
    return 1
  fi
  return 0
}

# ca_json_summary — one-line machine-readable summary.
#   ca_json_summary <ok-count> <warn-count> <info-count>
ca_json_summary() {
  printf '{"ok":%s,"warn":%s,"info":%s}\n' "$1" "$2" "$3"
}
