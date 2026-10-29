#!/usr/bin/env bats
# FS-0058 — local governed-ID citation resolution gate.
#
# check-citations.sh scans governed documents and fails when a cited
# FS/PLAN/ADR ID does not resolve in the repository's own registries.
# This suite is the regression coverage for FS-0058 / PLAN-0063; it does
# not cover cross-PR stale-citation drift (FS-0040 / PLAN-0046).

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/check-citations.sh"

new_repo() {
  local repo="$1"
  mkdir -p "$repo/docs/specifications" "$repo/docs/change-plans" \
           "$repo/docs/decisions"
  git -C "$repo" init -q -b trunk
  git -C "$repo" config user.name "Fixture"
  git -C "$repo" config user.email "fixture@example.test"
}

seed_docs() {
  local repo="$1"
  cat > "$repo/docs/specifications/FS-0001-live.md" <<'EOF'
---
type: feature-spec
id: FS-0001
status: approved
---
# FS-0001
EOF
  cat > "$repo/docs/change-plans/PLAN-0001-live.md" <<'EOF'
---
type: change-plan
id: PLAN-0001
status: approved
---
# PLAN-0001
EOF
  cat > "$repo/docs/decisions/ADR-0001-live.md" <<'EOF'
---
type: adr
id: ADR-0001
status: accepted
---
# ADR-0001
EOF
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "seed"
}

@test "passes when all citations resolve" {
  local repo="$BATS_TEST_TMPDIR/ok"
  new_repo "$repo"
  cat > "$repo/docs/specifications/FS-0001-live.md" <<'EOF'
---
type: feature-spec
id: FS-0001
status: approved
---
# FS-0001
See ADR-0001 and PLAN-0001.
EOF
  cat > "$repo/docs/change-plans/PLAN-0001-live.md" <<'EOF'
---
type: change-plan
id: PLAN-0001
status: approved
---
# PLAN-0001
Implements FS-0001.
EOF
  cat > "$repo/docs/decisions/ADR-0001-live.md" <<'EOF'
---
type: adr
id: ADR-0001
status: accepted
---
# ADR-0001
Driven by FS-0001.
EOF
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "seed"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "OK: all governed-ID citations resolve"
}

@test "fails on unresolved FS citation" {
  local repo="$BATS_TEST_TMPDIR/missing-fs"
  new_repo "$repo"; seed_docs "$repo"
  cat > "$repo/docs/decisions/ADR-0001-live.md" <<'EOF'
---
type: adr
id: ADR-0001
status: accepted
---
# ADR-0001
See FS-9999.
EOF
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "cite missing fs"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT"

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "FS-9999"
}

@test "fails on unresolved PLAN citation" {
  local repo="$BATS_TEST_TMPDIR/missing-plan"
  new_repo "$repo"; seed_docs "$repo"
  cat > "$repo/docs/specifications/FS-0001-live.md" <<'EOF'
---
type: feature-spec
id: FS-0001
status: approved
---
# FS-0001
Tracked by PLAN-9999.
EOF
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "cite missing plan"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT"

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "PLAN-9999"
}

@test "fails on unresolved ADR citation" {
  local repo="$BATS_TEST_TMPDIR/missing-adr"
  new_repo "$repo"; seed_docs "$repo"
  cat > "$repo/docs/specifications/FS-0001-live.md" <<'EOF'
---
type: feature-spec
id: FS-0001
status: approved
---
# FS-0001
Requires ADR-9999.
EOF
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "cite missing adr"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT"

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "ADR-9999"
}

@test "exempted IDs are not reported" {
  local repo="$BATS_TEST_TMPDIR/exempt"
  new_repo "$repo"; seed_docs "$repo"
  cat > "$repo/docs/specifications/FS-0001-live.md" <<'EOF'
---
type: feature-spec
id: FS-0001
status: approved
---
# FS-0001
See FS-9999 for a future spec.
EOF
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "cite exempt fs"

  run env CA_TARGET_REPO="$repo" CA_CITATION_EXEMPT="FS-9999" bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "OK: all governed-ID citations resolve"
}

@test "command-line exemptions combine with environment" {
  local repo="$BATS_TEST_TMPDIR/exempt-cli"
  new_repo "$repo"; seed_docs "$repo"
  cat > "$repo/docs/specifications/FS-0001-live.md" <<'EOF'
---
type: feature-spec
id: FS-0001
status: approved
---
# FS-0001
See FS-9999 and PLAN-9999.
EOF
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "cite two exempt ids"

  run env CA_TARGET_REPO="$repo" CA_CITATION_EXEMPT="FS-9999" \
    bash "$SCRIPT" --exempt PLAN-9999

  [ "$status" -eq 0 ]
}

@test "self-citation is allowed" {
  local repo="$BATS_TEST_TMPDIR/self"
  new_repo "$repo"; seed_docs "$repo"
  cat > "$repo/docs/specifications/FS-0001-live.md" <<'EOF'
---
type: feature-spec
id: FS-0001
status: approved
---
# FS-0001
This is FS-0001.
EOF
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "self cite"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT"

  [ "$status" -eq 0 ]
}

@test "comma-separated environment exemptions are honored" {
  local repo="$BATS_TEST_TMPDIR/exempt-env-comma"
  new_repo "$repo"; seed_docs "$repo"
  cat > "$repo/docs/specifications/FS-0001-live.md" <<'EOF'
---
type: feature-spec
id: FS-0001
status: approved
---
# FS-0001
See FS-9999 and PLAN-9999.
EOF
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "cite two exempt ids"

  run env CA_TARGET_REPO="$repo" CA_CITATION_EXEMPT="FS-9999,PLAN-9999" bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -qF "OK: all governed-ID citations resolve"
}

@test "invalid exemption token exits 2 with a diagnostic" {
  run bash "$SCRIPT" --exempt FOO

  [ "$status" -eq 2 ]
  echo "$output" | grep -qF "invalid exemption 'FOO'"
}

@test "malformed environment exemption exits 2 instead of aborting silently" {
  local repo="$BATS_TEST_TMPDIR/bad-env-exempt"
  new_repo "$repo"; seed_docs "$repo"

  # A filter that matched nothing used to kill the script under
  # `set -euo pipefail` (exit 1, zero bytes) before the scan ran. It must be a
  # usage error naming the offending token, with no silent truncated report.
  run env CA_TARGET_REPO="$repo" CA_CITATION_EXEMPT="FS-9999,not-an-id" bash "$SCRIPT"

  [ "$status" -eq 2 ]
  echo "$output" | grep -qF "invalid exemption 'not-an-id'"
}

@test "invalid input exits with usage" {
  run bash "$SCRIPT" --not-a-flag

  [ "$status" -eq 2 ]
  echo "$output" | grep -qF "unknown option"
}

@test "non-directory CA_TARGET_REPO exits 2" {
  run env CA_TARGET_REPO="/nonexistent/path" bash "$SCRIPT"

  [ "$status" -eq 2 ]
}
