#!/usr/bin/env bats
# FS-0048 — governance metadata and version source-of-truth reconciliation
# (issue #212).
#
# package.json is the single authoritative framework version. README.md,
# AGENTS.md, and INTEGRATION.md are display markers and must match it.
# ADRs must carry an `updated:` field, the ADR template must include one,
# and the freshness gate must cover the ADR corpus.

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
  CHECK_FRESHNESS="$REPO_ROOT/scripts/check-freshness.sh"
  CHECK_STATUS="$REPO_ROOT/scripts/check-status.sh"
  INTEGRATION_BACKUP="$BATS_TEST_TMPDIR/INTEGRATION.md.orig"
  cp "$REPO_ROOT/INTEGRATION.md" "$INTEGRATION_BACKUP"
}

teardown() {
  if [ -f "${INTEGRATION_BACKUP:-}" ]; then
    cp "$INTEGRATION_BACKUP" "$REPO_ROOT/INTEGRATION.md"
  fi
  find "$REPO_ROOT/docs/decisions" -name '_fs0048_probe.md' -delete 2>/dev/null || true
}

@test "fs0048: package.json version is the canonical framework version" {
  grep -E '^\s*"version":' "$REPO_ROOT/package.json"
}

@test "fs0048: README.md framework version matches package.json" {
  readme_version="$(grep -E 'Framework Version:' "$REPO_ROOT/README.md" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
  pkg_version="$(grep -E '^\s*"version":' "$REPO_ROOT/package.json" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
  [ -n "$readme_version" ]
  [ "$readme_version" = "$pkg_version" ]
}

@test "fs0048: INTEGRATION.md version matches package.json" {
  integration_version="$(grep -E '^Version:' "$REPO_ROOT/INTEGRATION.md" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
  pkg_version="$(grep -E '^\s*"version":' "$REPO_ROOT/package.json" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
  [ -n "$integration_version" ]
  [ "$integration_version" = "$pkg_version" ]
}

@test "fs0048: every ADR file has an updated: field in front matter" {
  local missing=0
  for f in "$REPO_ROOT"/docs/decisions/ADR-*.md; do
    [ -f "$f" ] || continue
    if ! grep -qE '^updated:' "$f"; then
      echo "missing updated: $(basename "$f")"
      missing=$((missing + 1))
    fi
  done
  [ "$missing" -eq 0 ]
}

@test "fs0048: ADR template includes an updated: placeholder" {
  assert_file_contains "$REPO_ROOT/templates/core/adr-full-madr.md" "updated: YYYY-MM-DD"
}

@test "fs0048: document-lifecycle.md lists rejected as an ADR status" {
  assert_file_contains "$REPO_ROOT/workflows/document-lifecycle.md" "| \`rejected\` |"
}

@test "fs0048: FS index has no duplicate or out-of-order IDs" {
  # Numeric sort: ids must increase monotonically through the table.
  local last=0
  local out_of_order=0
  while IFS= read -r line; do
    local id
    id="$(echo "$line" | grep -oE 'FS-[0-9]+' | head -1 | sed 's/FS-//')"
    [ -n "$id" ] || continue
    if [ "$id" -le "$last" ]; then
      echo "out of order or duplicate: FS-$id (last=$last)"
      out_of_order=$((out_of_order + 1))
    fi
    last="$id"
  done < <(sed -n '/## Current Specifications/,/^## /p' "$REPO_ROOT/docs/specifications/README.md" | grep '^| FS-')
  [ "$out_of_order" -eq 0 ]
}

@test "fs0048: PLAN index has no duplicate or out-of-order IDs" {
  local last=0
  local out_of_order=0
  while IFS= read -r line; do
    local id
    id="$(echo "$line" | grep -oE 'PLAN-[0-9]+' | head -1 | sed 's/PLAN-//')"
    [ -n "$id" ] || continue
    if [ "$id" -le "$last" ]; then
      echo "out of order or duplicate: PLAN-$id (last=$last)"
      out_of_order=$((out_of_order + 1))
    fi
    last="$id"
  done < <(sed -n '/## Current Plans/,/^## /p' "$REPO_ROOT/docs/change-plans/README.md" | grep '^| PLAN-')
  [ "$out_of_order" -eq 0 ]
}

# --- SC-2 negative path: an ADR missing updated: is a named-rule failure -----

@test "fs0048: an ADR missing updated: fails check-freshness and names the governing rule" {
  printf -- '---\ntype: adr\nid: ADR-9999\nstatus: proposed\n---\n\n# Probe ADR\n' \
    > "$REPO_ROOT/docs/decisions/_fs0048_probe.md"
  run bash "$CHECK_FRESHNESS"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "docs/decisions/_fs0048_probe.md"
  echo "$output" | grep -qF "FS-0027 rule 1"
}

# --- SC-4 negative path: a disagreeing display marker fails check-status -----

@test "fs0048: a disagreeing version marker makes check-status exit non-zero" {
  # INTEGRATION.md is the display marker with the simplest shape (`Version: X.Y.Z`).
  # Rewrite through a temp file rather than `sed -i`, whose backup-arg syntax differs
  # between GNU sed and BSD sed; teardown restores the backup.
  sed -E 's/^Version: [0-9]+\.[0-9]+\.[0-9]+$/Version: 9.9.9/' \
    "$REPO_ROOT/INTEGRATION.md" > "$BATS_TEST_TMPDIR/INTEGRATION.mod"
  cp "$BATS_TEST_TMPDIR/INTEGRATION.mod" "$REPO_ROOT/INTEGRATION.md"
  run bash "$CHECK_STATUS"
  [ "$status" -eq 1 ]
  echo "$output" | grep -qF "INTEGRATION.md version 9.9.9 disagrees with package.json version"
  echo "$output" | grep -qF "(FS-0048)"
}
