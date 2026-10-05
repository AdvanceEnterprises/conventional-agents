#!/usr/bin/env bats
# FS-0040 — same-ID rename claims do not create false default-branch collisions.
#
# A PR that renames a governed document without changing its ID vacates the
# previous path: the default-branch owner at that path is replaced by the
# rename, not collided with. A rename that changes the ID stays a renumber
# event for the citation layer (covered in claim-audit-binding.bats).

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

case "$endpoint" in
  repos/example/target)
    printf 'main\n'
    ;;
  repos/example/target/git/trees/main\?recursive=1)
    printf '%s\n' \
      'docs/specifications/FS-0050-old.md'
    ;;
  repos/example/target/pulls\?state=open\&per_page=100)
    printf '1\n'
    ;;
  repos/example/target/pulls/1/files\?per_page=100)
    printf '%s\t%s\t%s\t%s\n' renamed \
      'docs/specifications/FS-0050-new.md' \
      'docs/specifications/FS-0050-old.md' \
      '@@ -1 +1 @@\n+renamed\n'
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

@test "same-ID rename vacates its previous path (no default-branch collision)" {
  run bash "$AUDIT" --json --strict

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.findings | length == 0'
}

@test "array expansions are guarded for Bash 3.2" {
  local unguarded
  unguarded="$(grep -n '\[@\]' "$AUDIT" | grep -v '\[@\]+' | grep -v '\${#' || true)"
  [ -z "$unguarded" ]
}
