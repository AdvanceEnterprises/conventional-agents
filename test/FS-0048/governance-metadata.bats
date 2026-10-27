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
