#!/usr/bin/env bats
# FS-0040 — GitHub binding coverage for cross-PR claims/citations.

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  AUDIT="$REPO_ROOT/integrations/github/bin/gh-pr-claim-audit.sh"
  TARGET="$BATS_TEST_TMPDIR/target"
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$TARGET" "$FAKE_BIN"
  git -C "$TARGET" init -q -b main
  git -C "$TARGET" config user.name "Fixture"
  git -C "$TARGET" config user.email "fixture@example.test"
  printf 'fixture\n' > "$TARGET/file"
  git -C "$TARGET" add file
  git -C "$TARGET" commit -q -m "chore: fixture"

  cat > "$FAKE_BIN/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "auth" && "${2:-}" == "status" ]]; then
  if [[ "${FAKE_GH_AUTH:-ok}" == "fail" ]]; then
    printf 'not authenticated\n' >&2
    exit 1
  fi
  exit 0
fi

[[ "${1:-}" == "api" ]] || exit 1
shift
endpoint=""
filter=""
while (( $# > 0 )); do
  case "$1" in
    --jq)
      filter="$2"
      shift 2
      ;;
    --paginate|--silent)
      shift
      ;;
    *)
      if [[ -z "$endpoint" ]]; then endpoint="$1"; fi
      shift
      ;;
  esac
done

if [[ "${FAKE_GH_FAIL:-}" == "1" && "$endpoint" != "repos/example/target" ]]; then
  printf 'simulated API failure\n' >&2
  exit 1
fi

case "$endpoint" in
  repos/example/target)
    printf 'main\n'
    ;;
  repos/example/target/git/trees/main\?recursive=1)
    printf '%s\n' \
      'docs/specifications/FS-0040-trunk.md' \
      'docs/specifications/FS-0041-old.md'
    ;;
  repos/example/target/pulls\?state=open\&per_page=100)
    printf '1\n2\n3\n4\n'
    ;;
  repos/example/target/pulls/1/files\?per_page=100)
    printf '%s\t%s\t%s\t%s\n' added \
      'docs/specifications/FS-0040-one.md' '__CA_EMPTY__' \
      '@@ -0,0 +1 @@\n+one\n'
    ;;
  repos/example/target/pulls/2/files\?per_page=100)
    printf '%s\t%s\t%s\t%s\n' added \
      'docs/specifications/FS-0040-two.md' '__CA_EMPTY__' \
      '@@ -0,0 +1 @@\n+two\n'
    printf '%s\t%s\t%s\t%s\n' modified \
      'docs/notes.md' '__CA_EMPTY__' \
      '@@ -1 +1 @@\n+Reference FS-0041\n'
    ;;
  repos/example/target/pulls/3/files\?per_page=100)
    printf '%s\t%s\t%s\t%s\n' renamed \
      'docs/specifications/FS-0042-new.md' \
      'docs/specifications/FS-0041-old.md' \
      '@@ -1 +1 @@\n+renamed\n'
    ;;
  repos/example/target/pulls/4/files\?per_page=100)
    # Patch text carrying the four escaped forms the @tsv decoder must
    # round-trip exactly: literal backslash (\\), \n, \t, \r. GitHub encodes
    # these as \\, \\n, \\t, \\r in the payload; a %b-style decoder would
    # also honour \c (truncating) and octal sequences (Kimi K2.7 finding 2,
    # PR #206). The claim line must still be found after decoding.
    printf '%s\t%s\t%s\t%s\n' modified \
      'docs/specifications/FS-0040-four.md' '__CA_EMPTY__' \
      '@@ -1 +1 @@\n+backslash \\ and tab \t and return \r and newline\n+claim FS-0040 here\n'
    ;;
  *)
    printf 'unexpected fake endpoint: %s\n' "$endpoint" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "$FAKE_BIN/gh"
  export CA_TARGET_REPO="$TARGET"
  export CA_GITHUB_REPOSITORY="example/target"
  export PATH="$FAKE_BIN:$PATH"
}

@test "claim audit reports claim collision, default collision, and citation drift" {
  run bash "$AUDIT" --json --strict

  [ "$status" -eq 1 ]
  echo "$output" | jq -e '.repository == "example/target"'
  echo "$output" | jq -e '.default_branch == "main"'
  echo "$output" | jq -e '[.findings[].class] | sort == ["citation-drift", "claim-collision", "default-branch-collision"]'
  echo "$output" | jq -e '[.findings[] | select(.class == "claim-collision") | .claims | length] == [3]'
  echo "$output" | jq -e '[.findings[] | select(.class == "default-branch-collision") | .default_paths | length] == [1]'
  echo "$output" | jq -e '[.findings[] | select(.class == "citation-drift") | .old_id, .new_id] == ["FS-0041", "FS-0042"]'
  echo "$output" | jq -e '[.findings[] | select(.class == "citation-drift") | .citations[0].pr] == [2]'
}

@test "the @tsv decoder round-trips literal backslash, tab, and return escapes" {
  # PR 4's patch carries a literal backslash, \t, and \r alongside \n. Its
  # claim must still be discovered (and classified) after decoding — proving
  # the sentinel decoder handles every escape GitHub emits, not just \n
  # (Kimi K2.7 finding 2, PR #206).
  run bash "$AUDIT" --json --strict

  [ "$status" -eq 1 ]
  echo "$output" | jq -e '[.findings[] | select(.class == "claim-collision") | .claims[] | select(.pr == 4) | .path] == ["docs/specifications/FS-0040-four.md"]'
}

@test "claim audit is informational without strict mode" {
  run bash "$AUDIT" --json

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.findings | length == 3'
}

@test "claim audit fails closed when GitHub enumeration fails" {
  export FAKE_GH_FAIL=1

  run bash "$AUDIT"

  [ "$status" -eq 2 ]
  echo "$output" | grep -qF "could not enumerate the default-branch tree"
}

@test "claim audit fails before API access when authentication is unavailable" {
  export FAKE_GH_AUTH=fail

  run bash "$AUDIT"

  [ "$status" -eq 2 ]
  echo "$output" | grep -qF "GitHub CLI is not authenticated"
}
