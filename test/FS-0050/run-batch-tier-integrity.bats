#!/usr/bin/env bats
# FS-0050 — batch-acceptance commits are proposal-only (tier integrity).
#
# Exercises the five Success Criteria: a clean proposal-only batch passes, a
# forbidden path fails, a missing artifact fails, an unaccepted artifact fails,
# and a non-batch commit is out of scope and passes.

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/check-run-batch.sh"

new_repo() {
  local repo="$1"
  mkdir -p "$repo/docs/specifications" "$repo/docs/change-plans" \
           "$repo/docs/decisions" "$repo/scripts"
  git -C "$repo" init -q -b trunk
  git -C "$repo" config user.name "Fixture"
  git -C "$repo" config user.email "fixture@example.test"
}

seed_docs() {
  local repo="$1"
  cat > "$repo/docs/specifications/FS-0001-approved.md" <<'EOF'
---
type: feature-spec
id: FS-0001
status: approved
---
# FS-0001
EOF
  cat > "$repo/docs/specifications/FS-0002-draft.md" <<'EOF'
---
type: feature-spec
id: FS-0002
status: draft
---
# FS-0002
EOF
  cat > "$repo/docs/decisions/ADR-0001-accepted.md" <<'EOF'
---
type: adr
id: ADR-0001
status: accepted
---
# ADR-0001
EOF
  printf '| FS-0001 | one | approved |\n' > "$repo/docs/specifications/README.md"
  printf '| PLAN-0001 | one | FS-0001 | approved |\n' > "$repo/docs/change-plans/README.md"
  printf '| ADR-0001 | one | accepted |\n' > "$repo/docs/decisions/README.md"
  printf '# Changelog\n' > "$repo/CHANGELOG.md"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "seed"
}

# Record a batch-acceptance commit that changes one file and carries the given
# Approved-Artifacts trailer.
batch_commit() {
  local repo="$1" file="$2" trailer="$3"
  printf 'batch change\n' >> "$repo/$file"
  git -C "$repo" add "$file"
  git -C "$repo" commit -q -m "record batch acceptance" \
    -m "Approved-Artifacts: $trailer"
}

@test "proposal-only batch passes (SC1)" {
  local repo="$BATS_TEST_TMPDIR/sc1"
  new_repo "$repo"; seed_docs "$repo"
  batch_commit "$repo" "docs/specifications/FS-0001-approved.md" "FS-0001"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE 'ERROR'
}

@test "forbidden path in a batch fails (SC2)" {
  local repo="$BATS_TEST_TMPDIR/sc2"
  new_repo "$repo"; seed_docs "$repo"
  batch_commit "$repo" "scripts/overreach.sh" "FS-0001"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "forbidden path: scripts/overreach.sh"
}

@test "missing artifact fails (SC3)" {
  local repo="$BATS_TEST_TMPDIR/sc3"
  new_repo "$repo"; seed_docs "$repo"
  batch_commit "$repo" "docs/specifications/FS-0001-approved.md" "FS-9999"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "FS-9999 has no matching proposal-class document"
}

@test "unaccepted artifact fails (SC4)" {
  local repo="$BATS_TEST_TMPDIR/sc4"
  new_repo "$repo"; seed_docs "$repo"
  batch_commit "$repo" "docs/specifications/FS-0002-draft.md" "FS-0002"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "FS-0002 is 'draft'"
}

@test "a commit with no batch trailer is out of scope and passes (SC5)" {
  local repo="$BATS_TEST_TMPDIR/sc5"
  new_repo "$repo"; seed_docs "$repo"
  # Even a reserved-path change without an Approved-Artifacts trailer is out of
  # scope: the check validates batch-acceptance commits only.
  printf 'not a batch\n' >> "$repo/scripts/plain.sh"
  git -C "$repo" add scripts/plain.sh
  git -C "$repo" commit -q -m "plain change"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE 'ERROR'
}

@test "an ADR batch with a proposal-class change passes" {
  local repo="$BATS_TEST_TMPDIR/adr"
  new_repo "$repo"; seed_docs "$repo"
  batch_commit "$repo" "docs/decisions/ADR-0001-accepted.md" "ADR-0001"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 0 ]
}

@test "a batch touching the specifications index README passes" {
  local repo="$BATS_TEST_TMPDIR/index"
  new_repo "$repo"; seed_docs "$repo"
  batch_commit "$repo" "docs/specifications/README.md" "FS-0001"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE 'ERROR'
}

@test "a batch touching CHANGELOG.md passes" {
  local repo="$BATS_TEST_TMPDIR/changelog"
  new_repo "$repo"; seed_docs "$repo"
  batch_commit "$repo" "CHANGELOG.md" "FS-0001"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE 'ERROR'
}
