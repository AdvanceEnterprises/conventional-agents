#!/usr/bin/env bats
# FS-0022 — check-status.sh Bash 3.2 parse compatibility (issue #214)
#
# The script header claims "Bash 3.2+ compatible (no associative arrays)".
# Stock macOS ships Bash 3.2, and a `case` statement (plus multiline comments)
# nested directly inside a process substitution `<(...)` — the shape rule 8
# used before the #214 fix — fails to PARSE there: the script died before any
# check ran. These fixtures guard the claim two ways:
#
#   1. structural: the known-bad nesting shape must not reappear;
#   2. executable: `bash -n` must pass, and when a real Bash 3.2 binary is
#      available (CA_BASH32=/path/to/bash or `bash-3.2` on PATH), parse AND
#      run with it must succeed too — otherwise the fixture SKIPs loudly
#      rather than silently pretending coverage.

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  CHECK="$REPO_ROOT/scripts/check-status.sh"
  [ -f "$CHECK" ]
}

@test "bash32: no case statement is nested directly inside a process substitution" {
  # The incident shape: `done < <({ ... case ... } | sort -u)` — a group
  # command containing a case inside a process substitution. Bash 3.2's
  # parser rejects the unparenthesized form at parse time; even the
  # parenthesized form mis-parses when a multiline comment follows the
  # pattern. Keep the extraction in a top-level function instead.
  run grep -nF 'done < <({' "$CHECK"
  [ "$status" -ne 0 ]
  [ -z "$output" ]
}

@test "bash32: check-status.sh parses under the current bash" {
  run bash -n "$CHECK"
  [ "$status" -eq 0 ]
}

@test "bash32: check-status.sh parses and runs under a real bash 3.2 when available" {
  local b32="${CA_BASH32:-}"
  if [ -z "$b32" ]; then
    b32="$(command -v bash-3.2 || true)"
  fi
  if [ -z "$b32" ] || [ ! -x "$b32" ]; then
    skip "no Bash 3.2 binary available (set CA_BASH32 or install bash-3.2 as an opt-in)"
  fi

  run "$b32" -n "$CHECK"
  [ "$status" -eq 0 ]

  # The full run must also agree with the modern shell: rc=0 and the
  # terminal line for a clean tree. Run from the repo root so the
  # self-check path resolves like CI does.
  cd "$REPO_ROOT"
  run "$b32" "$CHECK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"All status checks passed."* ]]
}
