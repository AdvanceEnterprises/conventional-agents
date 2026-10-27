#!/usr/bin/env bats
# FS-0045 — accepted-ADR authority check for current-state guidance (issue #209).
#
# Current-state / exported-surface documents must not present a proposed,
# rejected, deprecated, or superseded ADR as binding. check-status.sh rule 9
# enforces this; these fixtures guard both the rule presence and its behavior.

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
  CHECK="$REPO_ROOT/scripts/check-status.sh"
}

@test "fs0045: check-status.sh contains an accepted-ADR authority rule" {
  assert_file_contains "$CHECK" "accepted-ADR authority for current-state guidance"
  assert_file_contains "$CHECK" "issue #209"
}

@test "fs0045: a current-state doc citing a proposed ADR with binding language fails" {
  local host="$BATS_TEST_TMPDIR/host"
  mkdir -p "$host/docs/decisions" "$host/workflows"
  ( cd "$host" && git init -q )

  cat > "$host/docs/decisions/ADR-0099-proposed-decision.md" <<'EOF'
---
type: adr
id: ADR-0099
status: proposed
---
# ADR-0099: Proposed decision

## Status

- Proposed
EOF

  cat > "$host/workflows/current-state.md" <<'EOF'
---
updated: 2026-10-27
---
# Current state

This workflow requires ADR-0099 to be followed.
EOF

  ( cd "$host" && git add -A && GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.dev git commit -q -m "fixture" )

  run bash -c "cd '$host' && CA_TARGET_REPO='$host' bash '$CHECK'"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qF "issue #209"
  echo "$output" | grep -qF "ADR-0099"
}

@test "fs0045: a current-state doc describing the same ADR as proposed passes" {
  local host="$BATS_TEST_TMPDIR/host-ok"
  mkdir -p "$host/docs/decisions" "$host/workflows"
  ( cd "$host" && git init -q )

  cat > "$host/docs/decisions/ADR-0099-proposed-decision.md" <<'EOF'
---
type: adr
id: ADR-0099
status: proposed
---
# ADR-0099: Proposed decision

## Status

- Proposed
EOF

  cat > "$host/workflows/current-state.md" <<'EOF'
---
updated: 2026-10-27
---
# Current state

This workflow is consistent with ADR-0099, which is still proposed.
EOF

  ( cd "$host" && git add -A && GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.dev git commit -q -m "fixture" )

  # The only error should be the missing README indexes / CHANGELOG, not #209.
  run bash -c "cd '$host' && CA_TARGET_REPO='$host' bash '$CHECK'"
  ! echo "$output" | grep -qF "issue #209"
}

@test "fs0045: accepted ADRs may still be cited as binding" {
  local host="$BATS_TEST_TMPDIR/host-accepted"
  mkdir -p "$host/docs/decisions" "$host/workflows"
  ( cd "$host" && git init -q )

  cat > "$host/docs/decisions/ADR-0001-accepted.md" <<'EOF'
---
type: adr
id: ADR-0001
status: accepted
---
# ADR-0001: Accepted

## Status

- Accepted
EOF

  cat > "$host/workflows/current-state.md" <<'EOF'
---
updated: 2026-10-27
---
# Current state

This workflow requires ADR-0001 to be followed.
EOF

  ( cd "$host" && git add -A && GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.dev git commit -q -m "fixture" )

  run bash -c "cd '$host' && CA_TARGET_REPO='$host' bash '$CHECK'"
  ! echo "$output" | grep -qF "issue #209"
}
