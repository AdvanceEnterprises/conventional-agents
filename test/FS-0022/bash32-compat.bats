#!/usr/bin/env bats
# FS-0022 — check-status.sh Bash 3.2 parse compatibility (issue #214)
#
# The script header claims "Bash 3.2+ compatible (no associative arrays)".
# Stock macOS ships Bash 3.2, and a `case` statement nested directly inside a
# command or process substitution failed to PARSE there: the script died before
# any check ran. These fixtures guard the claim two ways:
#
#   1. structural: reproduce Bash 3.2's substitution scanner and refuse a
#      substitution whose fragment does not parse (details in
#      scan_substitution_hazard below);
#   2. executable: `bash -n` must pass under the current shell, and when a
#      verified Bash 3.2 binary is available (BASH32_BIN=/path/to/bash-3.2,
#      CA_BASH32=/path/to/bash-3.2, or `bash-3.2` on PATH) parsing AND running
#      with it must succeed too. Without such a binary the real-shell tests
#      SKIP loudly rather than silently pretending coverage.
#
# Expected verdicts in the detection matrix below were recorded against real
# GNU Bash 3.2.39 and 3.2.57; the two agree on every shape, and the host
# `/usr/bin/bash` is 5.2, so Bash 5 acceptance is never treated as evidence of
# 3.2 compatibility.

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  CHECK="$REPO_ROOT/scripts/check-status.sh"
  CHECK_DIR="${BATS_TEST_TMPDIR:-${TMPDIR:-/tmp}}/bash32-compat"
  mkdir -p "$CHECK_DIR"
  [ -f "$CHECK" ]
}

teardown() {
  rm -rf "$CHECK_DIR"
}

# bats-core ships no fail helper; the suites here report with one (same shape
# as test/FS-0047/exported-boundary.bats). Without it an intended diagnostic
# path fails as `fail: command not found` (status 127) instead.
fail() {
  echo "$*" >&2
  return 1
}

# scan_substitution_hazard <file>
#
# Exit 0: clean. Exit 1: a substitution that Bash 3.2 mis-scans (each hazard
# printed). Exit 2: the scan itself could not run — distinct so a read error is
# never reported as a detection, and a detection is never hidden by one.
#
# Bash 3.2's substitution scanner counts parentheses. It has no notion of a
# `case` pattern, so in `x=$(case $v in a) ... esac)` the pattern's own `)`
# closes the substitution and the remainder (`echo ... ;; esac)`) lands in the
# enclosing command list, which fails to parse. The parenthesized pattern form
# issue #214 prescribes — `case $v in (a) ...` — adds one level of nesting, so
# the scanner stops at the real `)`. That is the whole rule, and it is what the
# review of the previous detector called for: model the parser instead of
# banning the keyword.
#
# So: for every unquoted `$(`/`<(` body, find the `)` Bash 3.2 would pair with
# it (paren depth, quote- and comment-aware) and require the fragment before it
# to parse. A failing fragment means the real closing paren is hidden behind a
# token Bash 3.2 does not recognise as a pattern — a genuine 3.2 parse error.
#
# Deliberate non-verdicts: substitutions opened inside a double-quoted string
# are skipped, because Bash 3.2 scans those for a matching `)` without parsing
# the body and accepts the unparenthesized form there (verified against 3.2.39);
# `$(( ))` arithmetic is skipped as its own construct.
scan_substitution_hazard() {
  python3 - "$1" <<'PY'
import subprocess
import sys

WORD_START = ' \t\n;|&('


def skip_squote(text, i):
    j = text.find("'", i + 1)
    return len(text) if j < 0 else j + 1


def skip_dquote(text, i):
    n = len(text)
    j = i + 1
    while j < n:
        if text[j] == '\\':
            j += 2
            continue
        if text[j] == '"':
            return j + 1
        j += 1
    return n


def skip_comment(text, i):
    j = text.find('\n', i)
    return len(text) if j < 0 else j + 1


def skip_arith(text, i, n):
    """Index after the closing '))' of a '$(( ))' arithmetic expansion."""
    j = i + 3
    depth = 0
    while j < n:
        c = text[j]
        if c == '\\':
            j += 2
            continue
        if c == "'":
            j = skip_squote(text, j)
            continue
        if c == '"':
            j = skip_dquote(text, j)
            continue
        if c == '(':
            depth += 1
        elif c == ')':
            if depth == 0:
                return j + 2
            depth -= 1
        j += 1
    return n


def find_close(text, i, n):
    """Index of the ')' Bash 3.2's paren counter pairs with a body at i."""
    depth = 1
    while i < n:
        c = text[i]
        if c == '\\':
            i += 2
            continue
        if c == "'":
            i = skip_squote(text, i)
            continue
        if c == '"':
            i = skip_dquote(text, i)
            continue
        if c == '#' and (i == 0 or text[i - 1] in WORD_START):
            i = skip_comment(text, i)
            continue
        if text.startswith('$((', i):
            i = skip_arith(text, i, n)
            continue
        if text.startswith('$(', i) or text.startswith('<(', i):
            depth += 1
            i += 2
            continue
        if c == '(':
            depth += 1
            i += 1
            continue
        if c == ')':
            depth -= 1
            if depth == 0:
                return i
            i += 1
            continue
        i += 1
    return -1


def fragments(text):
    """(offset, opener, body) for every substitution Bash 3.2 parses as code."""
    n = len(text)
    out = []
    i = 0
    while i < n:
        c = text[i]
        if c == '\\':
            i += 2
            continue
        if c == "'":
            i = skip_squote(text, i)
            continue
        if c == '"':
            i = skip_dquote(text, i)
            continue
        if c == '#' and (i == 0 or text[i - 1] in WORD_START):
            i = skip_comment(text, i)
            continue
        if text.startswith('$((', i):
            i = skip_arith(text, i, n)
            continue
        if text.startswith('$(', i) or text.startswith('<(', i):
            close = find_close(text, i + 2, n)
            opener = text[i:i + 2]
            if close < 0:
                out.append((i, opener, None))
                i = n
                continue
            out.append((i, opener, text[i + 2:close]))
            i = close + 1
            continue
        i += 1
    return out


def parses(body):
    try:
        proc = subprocess.run(['bash', '-n', '-s'], input=body, text=True,
                              stdout=subprocess.DEVNULL,
                              stderr=subprocess.PIPE)
    except OSError as exc:
        print('detector error: cannot run bash: %s' % exc, file=sys.stderr)
        sys.exit(2)
    # An unterminated here-document is only a warning for `bash -n`, but it
    # means the fragment ended inside the here-document: the substitution was
    # closed at a paren in the body, which is the hazard this scan is for.
    if 'here-document' in proc.stderr:
        return False
    return proc.returncode == 0


def main(path):
    try:
        with open(path, 'r', errors='replace') as fh:
            text = fh.read()
    except OSError as exc:
        print('detector error: cannot read %s: %s' % (path, exc), file=sys.stderr)
        return 2

    cache = {}
    hazards = []
    for offset, opener, body in fragments(text):
        if body is None:
            print('detector error: %s: unterminated %s at char %d'
                  % (path, opener, offset), file=sys.stderr)
            return 2
        if not body.strip():
            continue
        if body not in cache:
            cache[body] = parses(body)
        if cache[body]:
            continue
        line = text.count('\n', 0, offset) + 1
        snippet = ' '.join(body.split())[:70]
        hazards.append('%s:%d: %s closes at a paren inside "%s" — the fragment '
                       'before it does not parse under Bash 3.2'
                       % (path, line, opener, snippet))

    for hazard in hazards:
        print(hazard)
    return 1 if hazards else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
PY
}

# claiming_scripts — every tracked `.sh` file whose text advertises Bash 3.2
# compatibility. The marker is case-insensitive and the roots are every tracked
# script, because four of the thirteen claiming scripts live outside scripts/
# and one spells it "bash 3.2/4.3". Anchored at $REPO_ROOT: Bats inherits the
# caller's working directory, so a relative root silently scans nothing.
claiming_scripts() {
  local f
  git -C "$REPO_ROOT" ls-files -z -- '*.sh' |
    while IFS= read -r -d '' f; do
      grep -qiE 'bash[- ]?3\.2' "$REPO_ROOT/$f" && printf '%s\n' "$REPO_ROOT/$f"
    done
}

# resolve_bash32 — set BASH32 to a verified Bash 3.2 binary and
# BASH32_VERSION to its version string.
#
# Returns 0 on success. Returns 10 when no optional binary is available at all
# (the caller SKIPs, naming the CA_BASH32 opt-in). Returns 11 when a binary was
# configured but is unusable or is not Bash 3.2 — an explicitly configured path
# that does not work is an error, not an absent optional binary (FS-0049), and a
# Bash 5 binary cannot stand in as the 3.2 oracle.
#
# Precedence matches the FS-0040/FS-0041 fixtures: BASH32_BIN, CA_BASH32, then
# `bash-3.2` on PATH.
resolve_bash32() {
  local var="" candidate=""

  if [ -n "${BASH32_BIN:-}" ]; then
    var="BASH32_BIN"
    candidate="$BASH32_BIN"
  elif [ -n "${CA_BASH32:-}" ]; then
    var="CA_BASH32"
    candidate="$CA_BASH32"
  else
    candidate="$(command -v bash-3.2 || true)"
  fi

  if [ -z "$candidate" ]; then
    BASH32_ERROR="no Bash 3.2 binary available (set CA_BASH32=/path/to/bash-3.2 or install bash-3.2 as an opt-in); this run is NOT Bash 3.2 verification"
    return 10
  fi

  if [ ! -x "$candidate" ]; then
    BASH32_ERROR="$var='$candidate' is not an executable file — an explicitly configured Bash 3.2 path must be valid, not skipped (FS-0049)"
    return 11
  fi

  local versions=""
  if ! versions="$("$candidate" -c 'printf "%s %s" "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}"' 2>/dev/null)"; then
    BASH32_ERROR="cannot execute '$candidate' (from ${var:-PATH}) to read its version"
    return 11
  fi

  if [ "$versions" != "3 2" ]; then
    BASH32_VERSION="$("$candidate" --version 2>/dev/null | head -1)"
    BASH32_ERROR="'$candidate' (from ${var:-PATH}) is ${BASH32_VERSION:-not Bash 3.2} — only GNU Bash 3.2 can stand in as the 3.2 oracle"
    return 11
  fi

  BASH32="$candidate"
  BASH32_VERSION="$("$candidate" --version 2>/dev/null | head -1)"
  return 0
}

@test "bash32: no case statement is nested directly inside a process substitution" {
  # The incident shape: `done < <({ ... case ... } | sort -u)` — a group
  # command containing a case inside a process substitution. Keep the
  # extraction in a top-level function instead.
  run grep -nF 'done < <({' "$CHECK"
  [ "$status" -ne 0 ]
  [ -z "$output" ]
}

@test "bash32: check-status.sh parses under the current bash" {
  run bash -n "$CHECK"
  [ "$status" -eq 0 ]
}

@test "bash32: check-status.sh parses and runs under a real bash 3.2 when available" {
  local rc=0
  resolve_bash32 || rc=$?
  if [ "$rc" -eq 10 ]; then
    skip "$BASH32_ERROR"
  fi
  if [ "$rc" -ne 0 ]; then
    fail "$BASH32_ERROR"
  fi
  echo "# using $BASH32_VERSION"

  run "$BASH32" -n "$CHECK"
  [ "$status" -eq 0 ]

  # The full run must also agree with the modern shell: rc=0 and the
  # terminal line for a clean tree. Run from the repo root so the
  # self-check path resolves like CI does.
  cd "$REPO_ROOT"
  run "$BASH32" "$CHECK"
  if [ "$status" -ne 0 ]; then
    echo "$output"
    fail "check-status.sh failed under $BASH32_VERSION (status $status)"
  fi
  [[ "$output" == *"All status checks passed."* ]]
}

@test "bash32: the substitution scan agrees with Bash 3.2 on known shapes" {
  # Positives: real 3.2.39 rejects each of these; the scan must too, or the
  # guard fails open on the bug class of issue #214.
  cat >"$CHECK_DIR/flag-unparenthesized-case.sh" <<'EOF'
result=$(case "$1" in
a) echo y ;;
esac)
EOF
  cat >"$CHECK_DIR/flag-paren-in-string.sh" <<'EOF'
result=$(echo ")"; case "$v" in a) echo ;; esac)
EOF
  cat >"$CHECK_DIR/flag-paren-in-comment.sh" <<'EOF'
result=$(echo hi # ) note
case "$v" in a) echo ;; esac)
EOF
  cat >"$CHECK_DIR/flag-case-word-with-space.sh" <<'EOF'
result=$(case "a b" in "a b") echo y ;; esac)
EOF
  cat >"$CHECK_DIR/flag-unparenthesized-second-pattern.sh" <<'EOF'
result=$(case "$v" in (a) echo ;; b) echo ;; esac)
EOF

  # Negatives: real 3.2.39 accepts each of these. The parenthesized form is
  # the fix issue #214 prescribes, so flagging it would reject the remedy.
  cat >"$CHECK_DIR/clean-parenthesized-case.sh" <<'EOF'
result=$(case "$1" in
(a) echo y ;;
esac)
EOF
  cat >"$CHECK_DIR/clean-parenthesized-alternation.sh" <<'EOF'
result=$(case "$1" in
(a|b) echo y ;;
esac)
EOF
  cat >"$CHECK_DIR/clean-process-substitution.sh" <<'EOF'
result=<(case "$1" in
(a) echo y ;;
esac)
EOF
  cat >"$CHECK_DIR/clean-quoted-substitution.sh" <<'EOF'
result="$(case "$1" in a) echo y ;; esac)"
EOF
  cat >"$CHECK_DIR/clean-top-level-case.sh" <<'EOF'
case "$1" in a) echo y ;; esac
EOF

  local f
  for f in "$CHECK_DIR"/flag-*.sh; do
    run scan_substitution_hazard "$f"
    if [ "$status" -ne 1 ]; then
      echo "$output"
      fail "scan missed the shape in ${f##*/} (exit $status); real Bash 3.2.39 rejects it"
    fi
    [ -n "$output" ]
  done

  for f in "$CHECK_DIR"/clean-*.sh; do
    run scan_substitution_hazard "$f"
    if [ "$status" -ne 0 ]; then
      echo "$output"
      fail "scan rejected ${f##*/} (exit $status); real Bash 3.2.39 accepts it"
    fi
    [ -z "$output" ]
  done

  # An unreadable file is a scan error (2), never a detection (1).
  run scan_substitution_hazard "$CHECK_DIR/does-not-exist.sh"
  [ "$status" -eq 2 ]
  [[ "$output" == *"detector error"* ]]
}

@test "bash32: no command or process substitution is split by Bash 3.2's parser in a Bash-3.2-claiming script" {
  # Issue #214 was a class bug, not one line: any substitution Bash 3.2 closes
  # early takes the rest of the script with it. PR #215 removed the known
  # incident; this scan covers every tracked script that advertises the claim.
  local claims=""
  claims="$(claiming_scripts)"
  [ -n "$claims" ] || fail "no Bash 3.2 compatibility claims found under $REPO_ROOT — the scan roots or the marker are wrong"

  local f
  for f in $claims; do
    run scan_substitution_hazard "$f"
    if [ "$status" -eq 2 ]; then
      echo "$output"
      fail "substitution scan could not read $f"
    fi
    if [ "$status" -ne 0 ]; then
      echo "$output"
      fail "Bash 3.2 would mis-scan a substitution in $f"
    fi
  done
}

@test "bash32: every script advertising Bash 3.2 compatibility parses under a real bash 3.2 when available" {
  local rc=0
  resolve_bash32 || rc=$?
  if [ "$rc" -eq 10 ]; then
    skip "$BASH32_ERROR"
  fi
  if [ "$rc" -ne 0 ]; then
    fail "$BASH32_ERROR"
  fi
  echo "# using $BASH32_VERSION"

  local claims=""
  claims="$(claiming_scripts)"
  [ -n "$claims" ] || fail "no Bash 3.2 compatibility claims found under $REPO_ROOT"

  local f
  for f in $claims; do
    run "$BASH32" -n "$f"
    if [ "$status" -ne 0 ]; then
      echo "FAIL: $f"
      echo "$output"
      fail "$f does not parse under $BASH32_VERSION"
    fi
  done
}
