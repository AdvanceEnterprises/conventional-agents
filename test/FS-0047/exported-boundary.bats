#!/usr/bin/env bats
#
# FS-0047: exported consumer-boundary regression audit.
#
# Scans the tracked exported Markdown surface for known framework-instance
# identifiers, applies the exact-path/exact-literal allowlist in
# instance-exemptions.tsv, and reports every unexempted match with its file
# and line. Also asserts SC-9 (the exported lint script carries no named
# fleet or instance actors and fails closed unconfigured) and validates the
# allowlist itself (SC-6: malformed exemptions fail closed).
#
# Scan scope (per FS-0047 §Interfaces): root README.md, AGENTS.md,
# CONTRIBUTING.md, INTEGRATION.md, and Markdown under guidelines/, roles/,
# skills/, templates/, workflows/, integrations/, runbooks/, scripts/, and
# benchmark/.
# ADR, FS, PLAN, CHANGELOG, backlog, issue, and test history are excluded —
# internal identity and historical records are preserved (SC-7).

load "../FS-0001/helpers.bash"

# The instance identifiers the audit scans for. Each is matched as a literal
# substring; a hit is a finding unless an exact (path, literal) row exempts
# it. The set intentionally uses the full alias forms rather than bare
# domains, so one appendix line carrying several aliases still yields exactly
# one occurrence per literal. Exemption literals must be entries of this set.
BOUNDARY_IDENTIFIERS=(
  "github.com/Tais-Den"
  "Tais-Den"
  # The instance's current actor domain (advance.enterprises) and its
  # historical domain (tais-den.dev) — both are instance identifiers; a
  # re-leak of either is a finding.
  "hermes-agent@advance.enterprises"
  "hermes-cron@advance.enterprises"
  "claude-code@advance.enterprises"
  "codex@advance.enterprises"
  "codex-cron@advance.enterprises"
  "hermes-agent@tais-den.dev"
  "hermes-cron@tais-den.dev"
  "claude-code@tais-den.dev"
  "codex@tais-den.dev"
  "codex-cron@tais-den.dev"
  "github.marten@fwd.mtnden.org"
  "administrator@ajoeofalltrades.dev"
  "feral-fleet"
  "pack-protocol"
  "/tmp/conventional-agents"
)

setup() {
  REPO_ROOT="$(repo_root)"
  TSV="$REPO_ROOT/test/FS-0047/instance-exemptions.tsv"
}

# bats-core ships no fail helper; the suites here report with one.
fail() { echo "$*" >&2; return 1; }

# boundary_files <root> — the exported-surface file list for a root. For a
# git repository, the inventory comes from `git ls-files` (tracked files
# only, per FS-0047; core.quotepath disabled so non-ASCII paths are emitted
# literally); for a plain fixture directory, from `find`.
boundary_files() {
  local root="$1"
  local f dir
  if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
    for f in README.md AGENTS.md CONTRIBUTING.md INTEGRATION.md; do
      git -C "$root" -c core.quotepath=false ls-files --error-unmatch -- "$f" >/dev/null 2>&1 \
        && echo "$root/$f"
    done
    for dir in guidelines roles skills templates workflows integrations runbooks scripts benchmark; do
      git -C "$root" -c core.quotepath=false ls-files -- "${dir}/*.md" "${dir}/**/*.md" 2>/dev/null \
        | sed "s|^|$root/|"
    done
  else
    for f in README.md AGENTS.md CONTRIBUTING.md INTEGRATION.md; do
      [ -f "$root/$f" ] && echo "$root/$f"
    done
    for dir in guidelines roles skills templates workflows integrations runbooks scripts benchmark; do
      [ -d "$root/$dir" ] && find "$root/$dir" -name '*.md' -type f | sort
    done
  fi
  return 0
}

# literal_is_identifier <literal> — 0 when the literal is a BOUNDARY_IDENTIFIERS
# entry (the only literals the audit can exempt).
literal_is_identifier() {
  local lit="$1" ident
  for ident in "${BOUNDARY_IDENTIFIERS[@]}"; do
    [ "$ident" = "$lit" ] && return 0
  done
  return 1
}

# parse_tsv <tsv> <root> — validate the allowlist and print rows as
# "path<TAB>literal". Exits non-zero (with a diagnostic on stderr) on the
# first malformed row: wildcard path, pattern literal, missing field, empty
# rationale, duplicate row, a pair outside the scanned surface, a literal
# outside the identifier set, a path that escapes the root, a rationale
# that does not attest the non-normative label, or a pair that does not
# match exactly one occurrence in the scanned surface.
parse_tsv() {
  local tsv="$1" root="$2"
  local line no path literal reason count seen="" files=""
  files="$(boundary_files "$root")"
  while IFS= read -r line || [ -n "$line" ]; do
    # strip a trailing carriage return without a pipe
    line="${line%$'\r'}"
    [ -z "$line" ] && continue
    case "$line" in '#'*) continue ;; esac
    no=$(echo "$line" | awk -F '\t' '{print NF}')
    if [ "$no" -ne 3 ]; then
      echo "TSV row has $no fields (need 3): $line" >&2
      return 1
    fi
    path=$(echo "$line" | cut -f1)
    literal=$(echo "$line" | cut -f2)
    reason=$(echo "$line" | cut -f3)
    if printf '%s\n' "$seen" | grep -qxF "${path}"$'	'"${literal}"; then
      echo "TSV duplicate row: $path / $literal" >&2
      return 1
    fi
    seen="${seen}${path}"$'	'"${literal}
"
    if echo "$path" | grep -qE '[*?[]'; then
      echo "TSV path may not contain a glob: $path" >&2
      return 1
    fi
    if echo "$literal" | grep -qE '[*?[]'; then
      echo "TSV literal may not contain a pattern: $literal" >&2
      return 1
    fi
    if ! literal_is_identifier "$literal"; then
      echo "TSV literal is not an audited identifier: $literal" >&2
      return 1
    fi
    case "$path" in
      /*|*'..'*)
        echo "TSV path must be repository-relative without traversal: $path" >&2
        return 1 ;;
    esac
    if [ -z "$reason" ]; then
      echo "TSV row has an empty rationale: $path / $literal" >&2
      return 1
    fi
    case "$reason" in *non-normative*) ;; *)
      echo "TSV rationale must attest the visible non-normative label (SC-4): $path / $literal" >&2
      return 1 ;;
    esac
    if ! printf '%s\n' "$files" | grep -qxF "$root/$path"; then
      echo "TSV path is outside the scanned surface: $path" >&2
      return 1
    fi
    if ! [ -f "$root/$path" ]; then
      echo "TSV path does not resolve: $path" >&2
      return 1
    fi
    count=$(grep -F -o -- "$literal" "$root/$path" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -ne 1 ]; then
      echo "TSV pair must match exactly one occurrence, found $count: $path / $literal" >&2
      return 1
    fi
    label_line=$(grep -F -n -- "$literal" "$root/$path" 2>/dev/null | head -1 | cut -d: -f2-)
    case "$label_line" in
      '>'*) ;; *)
        echo "TSV occurrence is not inside a visibly non-normative blockquote (SC-4): $path / $literal" >&2
        return 1 ;;
    esac
    printf '%s\t%s\n' "$path" "$literal"
  done < "$tsv"
}

# scan_surface <root> <tsv> — print "path:line:identifier" (stdout) for every
# unexempted identifier hit, and "EXEMPT path:line:identifier" (stderr) for
# every accepted exemption. Exits non-zero when the allowlist itself is
# malformed; the caller asserts stdout emptiness.
scan_surface() {
  local root="$1" tsv="$2"
  local rows exempt file ident line hit
  rows=$(parse_tsv "$tsv" "$root") || return 2
  while IFS= read -r file; do
    if [ ! -r "$file" ]; then
      echo "${file#$root/}:0:UNREADABLE-INVENTORY-FILE"
      continue
    fi
    for ident in "${BOUNDARY_IDENTIFIERS[@]}"; do
      while IFS=: read -r line hit; do
        [ -z "$line" ] && continue
        exempt=0
        while IFS=$'\t' read -r _p _l; do
          if [ "$_p" = "${file#$root/}" ] && [ "$_l" = "$ident" ]; then
            exempt=1
          fi
        done <<< "$rows"
        if [ "$exempt" -eq 1 ]; then
          echo "EXEMPT ${file#$root/}:$line:$ident" >&2
        else
          echo "${file#$root/}:$line:$ident"
        fi
      done < <(grep -F -n -- "$ident" "$file" 2>/dev/null)
    done
  done < <(boundary_files "$root")
}

# ── boundary_files contract ────────────────────────────────────────────────

@test "boundary_files: exits 0 for a fixture root with no scanned dirs" {
  local fixture="$BATS_TMPDIR/fs0047-empty"
  rm -rf "$fixture"
  mkdir -p "$fixture"
  run boundary_files "$fixture"
  [ "$status" -eq 0 ]
}

# ── SC-5: the exported surface carries no unexempted instance identifier ────

@test "SC-5: exported surface has no unexempted instance identifiers" {
  local findings
  if ! findings=$(scan_surface "$REPO_ROOT" "$TSV"); then
    fail "allowlist validation failed: $findings"
  fi
  [ -z "$findings" ] || fail "unexempted instance identifiers found:"$'\n'"$findings"
}

# ── SC-5: fixtures — an unmarked leak fails; an exact exemption passes ───────

@test "SC-5: fixture leak without an exemption is reported with file and line" {
  local fixture="$BATS_TMPDIR/fs0047-leak"
  mkdir -p "$fixture/guidelines"
  cat > "$fixture/guidelines/demo.md" <<'EOF'
# Demo

> Non-normative example: `administrator@ajoeofalltrades.dev`.
Clone the private fixture with `git clone https://github.com/Tais-Den/pack-protocol.git`.
EOF
  cat > "$fixture/allow.tsv" <<'EOF'
guidelines/demo.md	administrator@ajoeofalltrades.dev	retained non-normative example
EOF
  local findings
  if ! findings=$(scan_surface "$fixture" "$fixture/allow.tsv"); then
    fail "allowlist validation failed: $findings"
  fi
  echo "$findings" | grep -q '^guidelines/demo.md:4:github.com/Tais-Den$' \
    || fail "expected the unexempted leak to be reported with file and line; got: $findings"
}

@test "SC-5: fixture leak with one exact exemption is reported as exempt" {
  local fixture="$BATS_TMPDIR/fs0047-exempt"
  mkdir -p "$fixture/guidelines"
  cat > "$fixture/guidelines/demo.md" <<'EOF'
# Demo

> Non-normative example: `administrator@ajoeofalltrades.dev`.
EOF
  cat > "$fixture/allow.tsv" <<'EOF'
guidelines/demo.md	administrator@ajoeofalltrades.dev	retained non-normative example
EOF
  local findings
  if ! findings=$(scan_surface "$fixture" "$fixture/allow.tsv"); then
    fail "allowlist validation failed: $findings"
  fi
  [ -z "$findings" ] || fail "exact exemption should suppress the finding; got: $findings"
  run scan_surface "$fixture" "$fixture/allow.tsv"
  [ "$status" -eq 0 ]
  [[ "$output" == *"EXEMPT guidelines/demo.md:3:administrator@ajoeofalltrades.dev"* ]] \
    || fail "the accepted exemption is not reported as exempt; got: $output"
}

@test "SC-4: an unlabelled retained occurrence fails even with a valid rationale" {
  local fixture="$BATS_TMPDIR/fs0047-unlabelled"
  mkdir -p "$fixture/guidelines"
  cat > "$fixture/guidelines/demo.md" <<'EOF'
# Demo

The maintainer's own alias is `administrator@ajoeofalltrades.dev`.
EOF
  printf 'guidelines/demo.md	administrator@ajoeofalltrades.dev	non-normative claim\n' > "$fixture/allow.tsv"
  run parse_tsv "$fixture/allow.tsv" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"non-normative blockquote"* ]]
}

@test "SC-1: generic-command fixture produces no findings" {
  local fixture="$BATS_TMPDIR/fs0047-generic"
  mkdir -p "$fixture/guidelines"
  cat > "$fixture/guidelines/demo.md" <<'EOF'
# Demo

Clone with `git clone "${FRAMEWORK_REPO_URL:-https://github.com/<your-org>/conventional-agents.git}" "$(mktemp -d)/conventional-agents"`.
Commit as `git -c user.email="<actor>@<your-domain>" commit`.
EOF
  : > "$fixture/allow.tsv"
  local findings
  if ! findings=$(scan_surface "$fixture" "$fixture/allow.tsv"); then
    fail "allowlist validation failed: $findings"
  fi
  [ -z "$findings" ] || fail "generic placeholder commands were flagged: $findings"
}

# ── SC-6: malformed exemptions fail closed and name the row ─────────────────

@test "SC-6: wildcard path, pattern literal, missing field, empty rationale fail" {
  local fixture="$BATS_TMPDIR/fs0047-malformed"
  mkdir -p "$fixture/guidelines"
  cat > "$fixture/guidelines/demo.md" <<'EOF'
# Demo

`administrator@ajoeofalltrades.dev`
EOF
  local allow="$fixture/allow.tsv"

  printf 'guidelines/*/demo.md\tadministrator@ajoeofalltrades.dev\tnon-normative example\n' > "$allow"
  run parse_tsv "$allow" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"may not contain a glob"* ]]

  printf 'guidelines/demo.md\tadmin*@example.com\tnon-normative example\n' > "$allow"
  run parse_tsv "$allow" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"may not contain a pattern"* ]]

  printf 'guidelines/demo.md\tadministrator@ajoeofalltrades.dev\n' > "$allow"
  run parse_tsv "$allow" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"need 3"* ]]

  printf 'guidelines/demo.md\tadministrator@ajoeofalltrades.dev\t\n' > "$allow"
  run parse_tsv "$allow" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"empty rationale"* ]]
}

@test "SC-6: duplicate and unmatched rows fail; multiple occurrences are invalid" {
  local fixture="$BATS_TMPDIR/fs0047-dupes"
  mkdir -p "$fixture/guidelines"
  cat > "$fixture/guidelines/demo.md" <<'EOF'
# Demo

> `administrator@ajoeofalltrades.dev`
EOF
  local allow="$fixture/allow.tsv"

  printf 'guidelines/demo.md\tadministrator@ajoeofalltrades.dev\tnon-normative one\nguidelines/demo.md\tadministrator@ajoeofalltrades.dev\tnon-normative two\n' > "$allow"
  run parse_tsv "$allow" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"duplicate row"* ]]

  printf 'guidelines/demo.md\thermes-agent@advance.enterprises\tnon-normative unmatched\n' > "$allow"
  run parse_tsv "$allow" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"exactly one occurrence"* ]]

  cat > "$fixture/guidelines/demo.md" <<'EOF'
# Demo

`administrator@ajoeofalltrades.dev` and again `administrator@ajoeofalltrades.dev`.
EOF
  printf 'guidelines/demo.md\tadministrator@ajoeofalltrades.dev\tnon-normative twice\n' > "$allow"
  run parse_tsv "$allow" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"exactly one occurrence"* ]]
}

@test "SC-6: out-of-scope paths, unknown literals, escaping paths, unlabelled rationale fail" {
  local fixture="$BATS_TMPDIR/fs0047-scope"
  mkdir -p "$fixture/guidelines" "$fixture/docs/decisions"
  cat > "$fixture/guidelines/demo.md" <<'EOF'
# Demo

`administrator@ajoeofalltrades.dev`
EOF
  cat > "$fixture/docs/decisions/ADR-9999.md" <<'EOF'
# ADR-9999

`administrator@ajoeofalltrades.dev`
EOF
  local allow="$fixture/allow.tsv"

  # Path outside the scanned surface (docs/ is excluded history).
  printf 'docs/decisions/ADR-9999.md\tadministrator@ajoeofalltrades.dev\tnon-normative example\n' > "$allow"
  run parse_tsv "$allow" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"outside the scanned surface"* ]]

  # Literal not in the audited identifier set.
  printf 'guidelines/demo.md\tadministrator@ajoeofalltrades.dev.example\tnon-normative example\n' > "$allow"
  run parse_tsv "$allow" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not an audited identifier"* ]]

  # Path escaping the root.
  printf '../guidelines/demo.md\tadministrator@ajoeofalltrades.dev\tnon-normative example\n' > "$allow"
  run parse_tsv "$allow" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"without traversal"* ]]

  # Rationale that does not attest the non-normative label.
  printf 'guidelines/demo.md\tadministrator@ajoeofalltrades.dev\tretained\n' > "$allow"
  run parse_tsv "$allow" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"non-normative"* ]]
}

@test "SC-6: a malformed final row without a terminating newline still fails" {
  local fixture="$BATS_TMPDIR/fs0047-finalrow"
  mkdir -p "$fixture/guidelines"
  cat > "$fixture/guidelines/demo.md" <<'EOF'
# Demo

`administrator@ajoeofalltrades.dev`
EOF
  printf 'guidelines/demo.md\tadministrator@ajoeofalltrades.dev\t' > "$fixture/allow.tsv"
  run parse_tsv "$fixture/allow.tsv" "$fixture"
  [ "$status" -ne 0 ]
  [[ "$output" == *"empty rationale"* ]]
}

# ── SC-7: excluded internal history is not scanned ──────────────────────────

@test "SC-7: instance identifiers in excluded history produce no findings" {
  # A fake root whose excluded history (docs/decisions, test/) carries an
  # identifier must produce no findings — the scan scope skips those paths,
  # so nothing requires rewriting the record.
  local fixture="$BATS_TMPDIR/fs0047-history"
  mkdir -p "$fixture/docs/decisions" "$fixture/test"
  cat > "$fixture/docs/decisions/ADR-9999.md" <<'EOF'
# ADR-9999

The alias `administrator@ajoeofalltrades.dev` is historical record.
EOF
  cat > "$fixture/test/history.bats" <<'EOF'
# fixture history
EOF
  : > "$fixture/allow.tsv"
  local findings
  if ! findings=$(scan_surface "$fixture" "$fixture/allow.tsv"); then
    fail "allowlist validation failed: $findings"
  fi
  [ -z "$findings" ] \
    || fail "excluded history was scanned and reported: $findings"
}

@test "SC-7: untracked scratch files are not scanned, tracked leaks are" {
  # The tracked-surface contract: an untracked file carrying an identifier is
  # ignored; once tracked, the same file is reported.
  local fixture="$BATS_TMPDIR/fs0047-tracked"
  rm -rf "$fixture"
  mkdir -p "$fixture/guidelines"
  git -C "$fixture" init -q -b trunk
  git -C "$fixture" config user.name "Hermes Agent"
  git -C "$fixture" config user.email "hermes-agent@advance.enterprises"
  cat > "$fixture/guidelines/demo.md" <<'EOF'
# Demo
EOF
  git -C "$fixture" add guidelines/demo.md
  git -C "$fixture" commit -q -m "baseline"
  echo "scratch note: hermes-agent@advance.enterprises" > "$fixture/guidelines/scratch.md"
  : > "$fixture/allow.tsv"
  local findings
  if ! findings=$(scan_surface "$fixture" "$fixture/allow.tsv"); then
    fail "allowlist validation failed: $findings"
  fi
  [ -z "$findings" ] \
    || fail "untracked scratch file was reported: $findings"
  git -C "$fixture" add guidelines/scratch.md
  git -C "$fixture" commit -q -m "track the leak"
  if ! findings=$(scan_surface "$fixture" "$fixture/allow.tsv"); then
    fail "allowlist validation failed: $findings"
  fi
  echo "$findings" | grep -q '^guidelines/scratch.md:1:hermes-agent@advance.enterprises$' \
    || fail "tracked leak was not reported; got: $findings"
}

# ── SC-9: the exported script carries no named fleet or instance actors ─────

@test "SC-9: cross-repo-lint.sh defaults are empty and fail closed unconfigured" {
  local script="$REPO_ROOT/scripts/cross-repo-lint.sh"
  # No non-empty CA_SIBLING_NAMES default: the fallback expansion must be
  # empty, never a baked-in fleet.
  ! grep -E 'CA_SIBLING_NAMES:-[[:alnum:]_]' "$script" \
    || fail "CA_SIBLING_NAMES default is non-empty"
  grep -q 'CA_SIBLING_NAMES:-}' "$script" \
    || fail "CA_SIBLING_NAMES fallback missing"
  # No fleet repo names remain anywhere in the script.
  ! grep -E 'feral-fleet|pack-protocol' "$script" \
    || fail "fleet repository names remain in the exported script"
  # Actor-email defaults are empty too.
  grep -q 'AGENT_EMAILS="${AGENT_EMAILS:-}"' "$script" \
    || fail "AGENT_EMAILS default is not empty"
  grep -q 'CRON_AGENT_EMAILS="${CRON_AGENT_EMAILS:-}"' "$script" \
    || fail "CRON_AGENT_EMAILS default is not empty"
  # An unconfigured attribution run fails closed, naming the variables and
  # the explicit opt-out; the opt-out reports SKIP, never "enforced".
  grep -q 'CA_SKIP_ATTRIBUTION=1' "$script" \
    || fail "the explicit attribution opt-out is missing"
  grep -q 'attribution checks cannot run' "$script" \
    || fail "the unconfigured attribution run does not fail closed"
  grep -q 'cron boundary not enforced' "$script" \
    || fail "the skip path does not disclaim enforcement"
}

@test "SC-9: an unconfigured attribution run fails; CA_SKIP_ATTRIBUTION=1 skips" {
  local fixture="$BATS_TMPDIR/fs0047-attribution"
  local script="$REPO_ROOT/scripts/cross-repo-lint.sh"
  rm -rf "$fixture"
  mkdir -p "$fixture/docs/specifications" "$fixture/docs/change-plans" "$fixture/docs/decisions"
  git -C "$fixture" init -q -b trunk
  git -C "$fixture" config user.name "Hermes Agent"
  git -C "$fixture" config user.email "hermes-agent@advance.enterprises"
  printf '# Specs\n' > "$fixture/docs/specifications/README.md"
  printf '# Plans\n' > "$fixture/docs/change-plans/README.md"
  printf '# Decisions\n' > "$fixture/docs/decisions/README.md"
  git -C "$fixture" add -A
  git -C "$fixture" commit -q -m "chore: baseline"
  printf 'x\n' > "$fixture/x.txt"
  git -C "$fixture" add -A
  git -C "$fixture" commit -q -m "fix: no trailer"
  local range="$(git -C "$fixture" rev-parse HEAD~1)..$(git -C "$fixture" rev-parse HEAD)"
  run env CA_TARGET_REPO="$fixture" COMMIT_RANGE="$range" \
    env -u AGENT_EMAILS -u CRON_AGENT_EMAILS -u CA_SKIP_ATTRIBUTION \
    bash "$script"
  [ "$status" -ne 0 ]
  [[ "$output" == *"AGENT_EMAILS and CRON_AGENT_EMAILS are empty"* ]]
  run env CA_TARGET_REPO="$fixture" COMMIT_RANGE="$range" \
    CA_SKIP_ATTRIBUTION=1 \
    env -u AGENT_EMAILS -u CRON_AGENT_EMAILS \
    bash "$script"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SKIP"* ]]
  [[ "$output" != *"cron boundary enforced"* ]]
}

# ── SC-1/SC-2: generic commands and cross-repo documentation ────────────────

@test "SC-1: copy-in examples use FRAMEWORK_REPO_URL and mktemp everywhere" {
  local skill="$REPO_ROOT/skills/framework-consumer-integration/SKILL.md"
  grep -q 'FRAMEWORK_REPO_URL' "$skill" \
    || fail "copy-in example does not parameterize the framework URL"
  grep -q 'mktemp -d' "$skill" \
    || fail "copy-in example still uses a fixed temporary path"
  grep -q 'FRAMEWORK_REPO_URL' "$REPO_ROOT/README.md" \
    || fail "README quick-start does not parameterize the framework URL"
  grep -q '<actor>-cron@<your-domain>' "$REPO_ROOT/INTEGRATION.md" \
    || fail "INTEGRATION.md does not carry the placeholder convention"
  ! grep -q '/tmp/conventional-agents' "$REPO_ROOT/README.md" "$skill" \
    || fail "a fixed instance checkout path survives"
  ! grep -qE 'hermes-cron@advance.enterprises' "$REPO_ROOT/INTEGRATION.md" \
    || fail "INTEGRATION.md still carries the instance cron example"
}

@test "SC-2: scripts/README documents explicit target selection, no fleet" {
  local readme="$REPO_ROOT/scripts/README.md"
  grep -q 'CA_REPO_DIRS' "$readme" && grep -q 'CA_TARGET_REPO' "$readme" \
    || fail "cross-repo documentation does not name the real config inputs"
  ! grep -qE 'Tais-Den|feral-fleet|pack-protocol' "$readme" \
    || fail "cross-repo documentation still enumerates the instance fleet"
}

@test "SC-9: the non-Markdown surface is parameterized and de-fleeted" {
  grep -q '{{MODEL_DISPLAY_NAME}}' "$REPO_ROOT/integrations/runtimes/claude-code/settings.fragment.json" \
    || fail "the Claude settings fragment still carries instance model data"
  ! grep -qE 'Opus 5' "$REPO_ROOT/integrations/runtimes/claude-code/settings.fragment.json" \
    || fail "the Claude settings fragment still carries an instance display name"
  ! grep -qE 'feral-fleet|pack-protocol' "$REPO_ROOT/.github/workflows/lint-docs.yml" \
    || fail "the lint-docs workflow still names the instance fleet"
  # The instance's own CI jobs export the actor allowlists (intentional
  # in-scope configuration, FS-0047 §Interfaces); pin the keys so the block
  # cannot be dropped silently — both jobs must carry them.
  [ "$(grep -c 'AGENT_EMAILS:.*hermes-agent@advance.enterprises' "$REPO_ROOT/.github/workflows/lint-docs.yml")" -eq 2 ] \
    || fail "not both CI jobs export the current actor domain"
  [ "$(grep -c 'CRON_AGENT_EMAILS:.*hermes-cron@advance.enterprises' "$REPO_ROOT/.github/workflows/lint-docs.yml")" -eq 2 ] \
    || fail "not both CI jobs export the current cron domain"
}

@test "SC-9: a half-configured attribution run disclaims the cron boundary" {
  local fixture="$BATS_TMPDIR/fs0047-halfcron"
  local script="$REPO_ROOT/scripts/cross-repo-lint.sh"
  rm -rf "$fixture"
  mkdir -p "$fixture/docs/specifications" "$fixture/docs/change-plans" "$fixture/docs/decisions"
  git -C "$fixture" init -q -b trunk
  git -C "$fixture" config user.name "Hermes Agent"
  git -C "$fixture" config user.email "hermes-agent@advance.enterprises"
  printf '# Specs\n' > "$fixture/docs/specifications/README.md"
  printf '# Plans\n' > "$fixture/docs/change-plans/README.md"
  printf '# Decisions\n' > "$fixture/docs/decisions/README.md"
  git -C "$fixture" add -A
  git -C "$fixture" commit -q -m "chore: baseline"
  printf 'x\n' > "$fixture/x.txt"
  git -C "$fixture" add -A
  git -C "$fixture" commit -q -m "fix: attributed commit

Agent-Attribution: actor=hermes-agent; model=test/model; role=Implementer; session=test"
  local range="$(git -C "$fixture" rev-parse HEAD~1)..$(git -C "$fixture" rev-parse HEAD)"
  run env CA_TARGET_REPO="$fixture" COMMIT_RANGE="$range" \
    AGENT_EMAILS="hermes-agent@advance.enterprises" \
    env -u CRON_AGENT_EMAILS -u CA_SKIP_ATTRIBUTION \
    bash "$script"
  [ "$status" -eq 0 ]
  [[ "$output" == *"cron boundary NOT configured"* ]]
  [[ "$output" != *"cron boundary enforced"* ]]
}
