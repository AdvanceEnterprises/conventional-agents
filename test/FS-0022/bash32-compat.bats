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
#      available (BASH32_BIN=/path/to/bash, CA_BASH32=/path/to/bash, or
#      `bash-3.2` on PATH), parse AND run with it must succeed too — otherwise
#      the fixture SKIPs loudly rather than silently pretending coverage.

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  CHECK="$REPO_ROOT/scripts/check-status.sh"
  [ -f "$CHECK" ]
}

# scan_nested_case <file> — return 1 when a case statement appears inside a
# command/process substitution. Keep this detector shared by the clean-tree
# scan and the regression canary below.
scan_nested_case() {
  python3 - "$1" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
n = len(text)
stack = []
i = 0
while i < n:
    if text[i:i+2] == '$(' or text[i:i+2] == '<(':
        stack.append((text[i:i+2], i))
        i += 2
        continue
    if text[i] == '(':
        stack.append(('(', i))
    elif text[i] == ')':
        if stack and stack[-1][0] in ('(', '$(', '<('):
            opened = stack.pop()
            if opened[0] in ('$(', '<('):
                content = text[opened[1]+2:i]
                if re.search(r'\bcase\s+\S+\s+in', content):
                    print(f'{opened[0]} at char {opened[1]}')
                    sys.exit(1)
    i += 1
PY
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
  local b32="${BASH32_BIN:-${CA_BASH32:-}}"
  if [ -z "$b32" ]; then
    b32="$(command -v bash-3.2 || true)"
  fi
  if [ -z "$b32" ] || [ ! -x "$b32" ]; then
    skip "no Bash 3.2 binary available (set BASH32_BIN/CA_BASH32 or install bash-3.2 as an opt-in)"
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

@test "bash32: no case statement is nested inside a command or process substitution in any Bash-3.2-claiming script" {
  # Issue #214 was a class bug: Bash 3.2 rejects a `case` nested directly in
  # `$(...)` or `<(...)`. PR #215 removed the known incident; this regression
  # fixture scans the whole class by looking for the `case` keyword inside a
  # substitution. The scan tolerates the unrelated `BASH_SOURCE[0]` token.
  local canary="$BATS_TEST_TMPDIR/bash32-case-canary.sh"
  cat > "$canary" <<'EOF'
#!/usr/bin/env bash
value=word
result=$(case $value in word) printf '%s' "$value";; esac)
EOF
  run scan_nested_case "$canary"
  [ "$status" -eq 1 ]
  [[ "$output" == *'$( at char '* ]]

  local claims=""
  claims=$(grep -RlE 'Bash 3\.2' scripts/ integrations/github/bin/ 2>/dev/null | grep '\.sh$' || true)
  [ -n "$claims" ] || fail "no Bash 3.2 compatibility claims found"
  local f
  for f in $claims; do
    run scan_nested_case "$f"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
  done
}

@test "bash32: every script advertising Bash 3.2 compatibility parses under a real bash 3.2 when available" {
  local b32="${BASH32_BIN:-${CA_BASH32:-}}"
  if [ -z "$b32" ]; then
    b32="$(command -v bash-3.2 || true)"
  fi
  if [ -z "$b32" ] || [ ! -x "$b32" ]; then
    skip "no Bash 3.2 binary available (set BASH32_BIN/CA_BASH32 or install bash-3.2 as an opt-in)"
  fi

  local claims=""
  claims=$(grep -RlE 'Bash 3\.2' scripts/ integrations/github/bin/ 2>/dev/null | grep '\.sh$' || true)
  [ -n "$claims" ] || fail "no Bash 3.2 compatibility claims found"
  local f
  for f in $claims; do
    run "$b32" -n "$f"
    if [ "$status" -ne 0 ]; then
      echo "FAIL: $f"
      echo "$output"
      return 1
    fi
  done
}
