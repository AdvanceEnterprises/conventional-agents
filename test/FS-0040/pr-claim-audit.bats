#!/usr/bin/env bats
# Issue #179 — duplicate governed-ID claim detection across open PRs.
#
# check-pr-claims.sh is a strict wrapper around the GitHub binding audit.
# These tests exercise the wrapper surface; the binding's own tests cover
# the cross-PR claim/citation logic in detail.

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/check-pr-claims.sh"

setup() {
  export FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  export REPO_DIR="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$FAKE_BIN" "$REPO_DIR"
  git -C "$REPO_DIR" init -q -b trunk
  git -C "$REPO_DIR" config user.name "Fixture"
  git -C "$REPO_DIR" config user.email "fixture@example.test"
  printf 'x\n' > "$REPO_DIR/fixture"
  git -C "$REPO_DIR" add fixture
  git -C "$REPO_DIR" commit -q -m "fixture"
}

fake_gh_clean() {
  local fake_gh="$1"
  cat > "$fake_gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "auth" && "${2:-}" == "status" ]] && exit 0
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
  repos/*) printf 'main\n' ;;
  repos/*/git/trees/main\?recursive=1) printf '\n' ;;
  repos/*/pulls\?state=open\&per_page=100) printf '\n' ;;
  *) printf 'unexpected: %s\n' "$endpoint" >&2; exit 1 ;;
esac
EOF
  chmod +x "$fake_gh"
}

fake_gh_collision() {
  local fake_gh="$1"
  cat > "$fake_gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "auth" && "${2:-}" == "status" ]] && exit 0
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
  repos/example/target) printf 'main\n' ;;
  repos/example/target/git/trees/main\?recursive=1)
    printf 'docs/specifications/FS-0001-trunk.md\n'
    ;;
  repos/example/target/pulls\?state=open\&per_page=100) printf '1\n2\n' ;;
  repos/example/target/pulls/1/files\?per_page=100)
    printf 'added\tdocs/specifications/FS-0001-one.md\t__CA_EMPTY__\t@@ -0,0 +1 @@\n+one\n'
    ;;
  repos/example/target/pulls/2/files\?per_page=100)
    printf 'added\tdocs/specifications/FS-0001-two.md\t__CA_EMPTY__\t@@ -0,0 +1 @@\n+two\n'
    ;;
  *) printf 'unexpected: %s\n' "$endpoint" >&2; exit 1 ;;
esac
EOF
  chmod +x "$fake_gh"
}

@test "wrapper invokes the binding audit in strict mode" {
  fake_gh_clean "$FAKE_BIN/gh"

  run env CA_GITHUB_REPOSITORY="example/target" CA_TARGET_REPO="$REPO_DIR" \
    PATH="$FAKE_BIN:$PATH" bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "findings=0"
}

@test "wrapper rejects unknown options" {
  run bash "$SCRIPT" --not-a-flag

  [ "$status" -eq 2 ]
  echo "$output" | grep -qF "unknown option"
}

@test "wrapper prints help" {
  run bash "$SCRIPT" --help

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "check-pr-claims.sh"
}

@test "wrapper fails closed when binding is missing" {
  local broken_script="$BATS_TEST_TMPDIR/check-pr-claims-broken.sh"
  cp "$SCRIPT" "$broken_script"
  sed -i 's|AUDIT="\$SCRIPT_DIR/../integrations/github/bin/gh-pr-claim-audit.sh"|AUDIT="/nonexistent/gh-pr-claim-audit.sh"|' "$broken_script"

  run bash "$broken_script"

  [ "$status" -eq 2 ]
  echo "$output" | grep -qF "cannot find the claim audit binding"
}

@test "wrapper passes strict findings through as non-zero" {
  fake_gh_collision "$FAKE_BIN/gh"

  run env CA_GITHUB_REPOSITORY="example/target" CA_TARGET_REPO="$REPO_DIR" \
    PATH="$FAKE_BIN:$PATH" bash "$SCRIPT"

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "claim-collision"
}

@test "wrapper forwards --repository and --target" {
  fake_gh_clean "$FAKE_BIN/gh"

  run env PATH="$FAKE_BIN:$PATH" bash "$SCRIPT" --repository other/repo --target "$REPO_DIR"

  [ "$status" -eq 0 ]
}
