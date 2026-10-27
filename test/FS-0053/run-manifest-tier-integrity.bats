#!/usr/bin/env bats
# FS-0050-area — run-manifest / tier-integrity detection for ADR-0049
# (supersedes ADR-0045).
#
# Mirrors the FS-0050 bats style. Detects:
#   (a) a proposal-class document entering an accepted status outside a
#       batch-acceptance commit that names it and records an approver;
#   (b) batch-acceptance commits that overreach into forbidden paths.
#
# SC-a* exercise rule (a)'s transition semantics (drafting is legitimate;
# promotion is not), SC-b* rule (b)'s delegation, SC-r* range handling, and
# SC-m* the merge-commit / root-commit enumeration.

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/check-run-manifest.sh"

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
  cat > "$repo/docs/change-plans/PLAN-0001-approved.md" <<'EOF'
---
type: change-plan
role: implementer
id: PLAN-0001
status: approved
related_specs: [FS-0001]
---
# PLAN-0001
EOF
  cat > "$repo/docs/change-plans/PLAN-0002-draft.md" <<'EOF'
---
type: change-plan
role: implementer
id: PLAN-0002
status: draft
related_specs: [FS-0002]
---
# PLAN-0002
EOF
  cat > "$repo/docs/decisions/ADR-0001-accepted.md" <<'EOF'
---
type: adr
id: ADR-0001
status: accepted
---
# ADR-0001
EOF
  cat > "$repo/docs/decisions/ADR-0002-proposed.md" <<'EOF'
---
type: adr
id: ADR-0002
status: proposed
---
# ADR-0002
EOF
  printf '| FS-0001 | one | approved |\n' > "$repo/docs/specifications/README.md"
  printf '| PLAN-0001 | one | FS-0001 | approved |\n' > "$repo/docs/change-plans/README.md"
  printf '| ADR-0001 | one | accepted |\n' > "$repo/docs/decisions/README.md"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "seed"
}

# Record a plain (non-batch) commit that appends body text; the front-matter
# status is unchanged.
plain_commit() {
  local repo="$1" file="$2"
  printf 'plain change\n' >> "$repo/$file"
  git -C "$repo" add "$file"
  git -C "$repo" commit -q -m "plain change"
}

# Rewrite one document's front-matter status and commit it.
set_status() {
  local repo="$1" file="$2" new_status="$3" msg="${4:-docs: set status}"
  sed "s/^status:.*/status: $new_status/" "$repo/$file" > "$repo/$file.tmp"
  mv "$repo/$file.tmp" "$repo/$file"
  git -C "$repo" add "$file"
  git -C "$repo" commit -q -m "$msg"
}

# Record a batch-acceptance commit that changes one file and carries the given
# Approved-Artifacts trailer, with an Approved-By trailer by default. Both
# trailers live in ONE paragraph: git only parses the final paragraph as trailers.
batch_commit() {
  local repo="$1" file="$2" trailer="$3" with_approver="${4:-yes}"
  printf 'batch change\n' >> "$repo/$file"
  git -C "$repo" add "$file"
  if [ "$with_approver" = "no" ]; then
    git -C "$repo" commit -q -m "record batch acceptance" \
      -m "Approved-Artifacts: $trailer"
  else
    git -C "$repo" commit -q -m "record batch acceptance" \
      -m "$(printf 'Approved-Artifacts: %s\nApproved-By: Approver <approver@example.test>' "$trailer")"
  fi
}

# Record a commit that appends body text (status unchanged) and carries one
# trailer paragraph verbatim.
trailer_edit() {
  local repo="$1" file="$2" trailers="$3"
  printf 'edited body\n' >> "$repo/$file"
  git -C "$repo" add "$file"
  git -C "$repo" commit -q -m "docs: edit body" -m "$trailers"
}

@test "ordinary draft-spec proposal passes (SC-a1)" {
  local repo="$BATS_TEST_TMPDIR/sc-a1"
  new_repo "$repo"; seed_docs "$repo"
  # Adding a new draft spec, revising an existing draft, and aligning the index
  # is exactly the drafting work ADR-0045 steps 5-6 require.
  cat > "$repo/docs/specifications/FS-9001-ordinary.md" <<'EOF'
---
type: feature-spec
id: FS-9001
status: draft
---
# FS-9001
EOF
  printf '| FS-9001 | ordinary | draft |\n' >> "$repo/docs/specifications/README.md"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "docs: draft FS-9001 (proposal)"
  plain_commit "$repo" "docs/specifications/FS-0002-draft.md"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" "HEAD~2..HEAD"

  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE 'ERROR'
}

@test "spec promoted to approved in a plain commit fails (SC-a2)" {
  local repo="$BATS_TEST_TMPDIR/sc-a2"
  new_repo "$repo"; seed_docs "$repo"
  set_status "$repo" "docs/specifications/FS-0002-draft.md" approved

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "promotes proposal-class artifact"
  echo "$output" | grep -qF "docs/specifications/FS-0002-draft.md"
}

@test "plan promoted to approved in a plain commit fails (SC-a3)" {
  local repo="$BATS_TEST_TMPDIR/sc-a3"
  new_repo "$repo"; seed_docs "$repo"
  set_status "$repo" "docs/change-plans/PLAN-0002-draft.md" approved

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "docs/change-plans/PLAN-0002-draft.md"
}

@test "ADR promoted to accepted in a plain commit fails (SC-a4)" {
  local repo="$BATS_TEST_TMPDIR/sc-a4"
  new_repo "$repo"; seed_docs "$repo"
  set_status "$repo" "docs/decisions/ADR-0002-proposed.md" accepted

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "docs/decisions/ADR-0002-proposed.md"
}

@test "editing an accepted document without a status change passes (SC-a5)" {
  local repo="$BATS_TEST_TMPDIR/sc-a5"
  new_repo "$repo"; seed_docs "$repo"
  plain_commit "$repo" "docs/specifications/FS-0001-approved.md"
  plain_commit "$repo" "docs/decisions/README.md"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" "HEAD~2..HEAD"

  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE 'ERROR'
}

@test "non-batch commit touching CHANGELOG is not flagged (SC-a6)" {
  local repo="$BATS_TEST_TMPDIR/sc-a6"
  new_repo "$repo"; seed_docs "$repo"
  printf '# Changelog\n' > "$repo/CHANGELOG.md"
  git -C "$repo" add CHANGELOG.md
  git -C "$repo" commit -q -m "add changelog"
  plain_commit "$repo" "CHANGELOG.md"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE 'ERROR'
}

@test "promotion with a trailer naming an unrelated artifact fails (SC-a7)" {
  local repo="$BATS_TEST_TMPDIR/sc-a7"
  new_repo "$repo"; seed_docs "$repo"
  # FS-0002 is promoted while the trailer names only FS-0001 (already accepted).
  set_status "$repo" "docs/specifications/FS-0002-draft.md" approved \
    "$(printf 'docs: rewrite FS-0002\n\nApproved-Artifacts: FS-0001\nApproved-By: Approver <approver@example.test>')"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "outside a covering batch acceptance"
  echo "$output" | grep -qF "docs/specifications/FS-0002-draft.md"
}

@test "promotion with Approved-Artifacts but no Approved-By fails (SC-a8)" {
  local repo="$BATS_TEST_TMPDIR/sc-a8"
  new_repo "$repo"; seed_docs "$repo"
  set_status "$repo" "docs/specifications/FS-0002-draft.md" approved \
    "$(printf 'docs: rewrite FS-0002\n\nApproved-Artifacts: FS-0002')"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "without an Approved-By"
  echo "$output" | grep -qF "outside a covering batch acceptance"
}

@test "batch claim without Approved-By is reported without a promotion (SC-a9)" {
  local repo="$BATS_TEST_TMPDIR/sc-a9"
  new_repo "$repo"; seed_docs "$repo"
  trailer_edit "$repo" "docs/specifications/FS-0001-approved.md" "Approved-Artifacts: FS-0001"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "without an Approved-By"
}

@test "promotion covered by Approved-Artifacts plus Approved-By passes (SC-a10)" {
  local repo="$BATS_TEST_TMPDIR/sc-a10"
  new_repo "$repo"; seed_docs "$repo"
  set_status "$repo" "docs/specifications/FS-0002-draft.md" approved \
    "$(printf 'docs: record acceptance of FS-0002\n\nApproved-Artifacts: FS-0002\nApproved-By: Approver <approver@example.test>')"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE 'ERROR'
}

@test "clean batch-acceptance commit passes (SC-b1)" {
  local repo="$BATS_TEST_TMPDIR/sc-b1"
  new_repo "$repo"; seed_docs "$repo"
  batch_commit "$repo" "docs/specifications/FS-0001-approved.md" "FS-0001"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE 'ERROR'
}

@test "batch-acceptance commit overreaching into scripts fails (SC-b2)" {
  local repo="$BATS_TEST_TMPDIR/sc-b2"
  new_repo "$repo"; seed_docs "$repo"
  batch_commit "$repo" "scripts/overreach.sh" "FS-0001"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "batch-acceptance commit"
  echo "$output" | grep -qF "forbidden path: scripts/overreach.sh"
}

@test "commit range detects a promotion (SC-r1)" {
  local repo="$BATS_TEST_TMPDIR/sc-r1"
  new_repo "$repo"; seed_docs "$repo"
  set_status "$repo" "docs/specifications/FS-0002-draft.md" approved

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" "HEAD~1..HEAD"

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "docs/specifications/FS-0002-draft.md"
}

@test "commit range detects both violations (SC-r2)" {
  local repo="$BATS_TEST_TMPDIR/sc-r2"
  new_repo "$repo"; seed_docs "$repo"
  set_status "$repo" "docs/specifications/FS-0002-draft.md" approved
  batch_commit "$repo" "scripts/overreach.sh" "FS-0001"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" "HEAD~2..HEAD"

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "docs/specifications/FS-0002-draft.md"
  echo "$output" | grep -qF "forbidden path: scripts/overreach.sh"
}

@test "empty revision range is an error (SC-r3)" {
  local repo="$BATS_TEST_TMPDIR/sc-r3"
  new_repo "$repo"; seed_docs "$repo"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" "HEAD..HEAD"

  [ "$status" -eq 2 ]
}

@test "merge-commit conflict resolution that promotes a document fails (SC-m1)" {
  local repo="$BATS_TEST_TMPDIR/sc-m1"
  new_repo "$repo"; seed_docs "$repo"

  git -C "$repo" checkout -q -b side
  set_status "$repo" "docs/specifications/FS-0002-draft.md" proposed "docs: side proposes"
  git -C "$repo" checkout -q trunk
  set_status "$repo" "docs/specifications/FS-0002-draft.md" withdrawn "docs: trunk withdraws"

  # Conflict on the status line; the resolution promotes FS-0002, which exists in
  # neither parent.
  run git -C "$repo" merge -q side
  [ "$status" -ne 0 ]
  cat > "$repo/docs/specifications/FS-0002-draft.md" <<'EOF'
---
type: feature-spec
id: FS-0002
status: approved
---
# FS-0002
merged
EOF
  git -C "$repo" add docs/specifications/FS-0002-draft.md
  git -C "$repo" commit -q -m "merge side (conflict resolution promotes FS-0002)"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" HEAD

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "docs/specifications/FS-0002-draft.md"
}

@test "root commit that introduces an accepted document fails (SC-m2)" {
  local repo="$BATS_TEST_TMPDIR/sc-m2"
  new_repo "$repo"; seed_docs "$repo"
  local root
  root="$(git -C "$repo" rev-list --max-parents=0 HEAD)"

  run env CA_TARGET_REPO="$repo" bash "$SCRIPT" "$root"

  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "docs/specifications/FS-0001-approved.md"
}
