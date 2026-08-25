#!/usr/bin/env bats
#
# FS-0025: Bats test coverage for cross-cutting governance patterns.
#
# Validates governance consistency rules that are enforced by
# check-status.sh but also have explicit Bats coverage so CI can
# report them independently and development can reproduce them
# locally without running the full check suite.

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
  DECISIONS_DIR="$REPO_ROOT/docs/decisions"
  SPECS_DIR="$REPO_ROOT/docs/specifications"
  PLANS_DIR="$REPO_ROOT/docs/change-plans"
  ALL_DOCS="$(find "$REPO_ROOT/docs" -name '*.md' -type f | sort)"
}

# ── ADR status transitions ──────────────────────────────────────────────────

@test "adr_transitions: every ADR status is a recognised value" {
  local known=("draft" "proposed" "accepted" "rejected" "implemented"
               "deprecated" "superseded")
  for f in "$DECISIONS_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    local status
    status=$(grep -m1 '^status:' "$f" | sed 's/^status:[[:space:]]*//')
    local valid=false
    for s in "${known[@]}"; do
      [ "$status" = "$s" ] && valid=true
    done
    if ! $valid; then
      echo "FAIL: $(basename "$f") has unrecognised status: '$status'"
      return 1
    fi
  done
}

@test "adr_transitions: deprecated or superseded carries a date" {
  for f in "$DECISIONS_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    local status
    status=$(grep -m1 '^status:' "$f" | sed 's/^status:[[:space:]]*//')
    if [ "$status" = "deprecated" ] || [ "$status" = "superseded" ]; then
      if ! grep -qE '^updated:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}$' "$f"; then
        echo "FAIL: $(basename "$f") is $status but has no valid updated: date"
        return 1
      fi
    fi
  done
}

@test "adr_transitions: no ADR filename number mismatches its id: field" {
  for f in "$DECISIONS_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    local basename
    basename=$(basename "$f")
    # Only check slug-style filenames (ADR-NNNN-<slug>.md)
    if ! echo "$basename" | grep -qE '^ADR-[0-9]{4}-'; then
      continue
    fi
    local id_from_name id_from_file
    id_from_name=$(echo "$basename" | sed 's/^ADR-0*//;s/-.*//')
    id_from_file=$(grep -m1 '^id:' "$f" | sed 's/^id:[[:space:]]*//;s/^ADR-0*//')
    [ -z "$id_from_file" ] && continue
    if [ "$id_from_name" != "$id_from_file" ]; then
      echo "FAIL: $basename has id: ADR-$id_from_file (mismatch)"
      return 1
    fi
  done
}

# ── FS/PLAN pairing ─────────────────────────────────────────────────────────

@test "fs_plan_pairing: every implemented/approved FS names a PLAN" {
  for fs in "$SPECS_DIR"/FS-*.md; do
    [ -f "$fs" ] || continue
    local status basename fs_num
    status=$(grep -m1 '^status:' "$fs" | sed 's/^status:[[:space:]]*//')
    [ "$status" != "approved" ] && [ "$status" != "implemented" ] && continue
    basename=$(basename "$fs")
    fs_num=$(echo "$basename" | sed 's/^FS-0*//;s/-.*//')
    # Look for matching PLAN
    local found=$(ls "$PLANS_DIR"/PLAN-$(printf "%04d" "$fs_num")-*.md "$PLANS_DIR"/PLAN-"$fs_num"-*.md 2>/dev/null | head -1)
    if [ -z "$found" ]; then
      echo "FAIL: $basename (status=$status) has no corresponding PLAN"
      echo "       Expected $PLANS_DIR/PLAN-$(printf "%04d" "$fs_num")-*.md"
      return 1
    fi
  done
}

@test "fs_plan_pairing: every PLAN with related_specs references an existing FS" {
  # Checks that related_specs (when non-empty) names a spec file that
  # actually exists on disk. Early PLANs may have numbers that differ from
  # the FS they implement (PLAN-0001 implemented FS-0003) — that's valid.
  # What matters is that the referenced FS file exists.
  #
  # Known exemptions: PLAN-0024 references FS-9001 (a speculative/placeholder
  # FS number in a forward-looking spec).
  local known_exemptions=("FS-9001")
  for plan in "$PLANS_DIR"/PLAN-*.md; do
    [ -f "$plan" ] || continue
    # Skip PLANS with empty related_specs
    local specs_line
    specs_line=$(grep -m1 '^related_specs:' "$plan" || true)
    [ -z "$specs_line" ] && continue
    if echo "$specs_line" | grep -qE '\[\s*\]'; then
      continue
    fi
    # Extract all FS-NNNN references from the frontmatter
    local refs
    refs=$(grep -oE 'FS-[0-9]{4}' "$plan" || true)
    if [ -z "$refs" ]; then
      refs=$(grep -oE 'FS-[0-9]+' "$plan" | grep -v 'FS-[0-9]\{4\}' || true)
    fi
    [ -n "$refs" ] || continue
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      # Check known exemptions
      local exempt=false
      for e in "${known_exemptions[@]}"; do
        [ "$ref" = "$e" ] && exempt=true
      done
      $exempt && continue
      local num
      num=$(echo "$ref" | sed 's/^FS-0*//')
      local found
      found=$(find "$SPECS_DIR" -maxdepth 1 \( -name "${ref}-*.md" -o -name "${ref}.md" -o -name "FS-${num}-*.md" \) 2>/dev/null | head -1)
      if [ -z "$found" ]; then
        echo "FAIL: $(basename "$plan") references $ref but no matching spec file exists"
        return 1
      fi
    done <<< "$refs"
  done
}

# ── README index consistency ────────────────────────────────────────────────

@test "index_consistency: all ADR docs have an ADR README row" {
  local readme="$DECISIONS_DIR/README.md"
  [ -f "$readme" ]
  for f in "$DECISIONS_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    local id
    id=$(grep -m1 '^id:' "$f" | sed 's/^id:[[:space:]]*//')
    [ -z "$id" ] && continue
    if ! grep -qF "$id" "$readme"; then
      echo "FAIL: $id has no README index entry in $readme"
      return 1
    fi
  done
}

@test "index_consistency: all FS docs have an FS README row" {
  local readme="$SPECS_DIR/README.md"
  [ -f "$readme" ]
  for f in "$SPECS_DIR"/FS-*.md; do
    [ -f "$f" ] || continue
    local id
    id=$(grep -m1 '^id:' "$f" | sed 's/^id:[[:space:]]*//')
    [ -z "$id" ] && continue
    # FS ids may use "FS-NNNN" or "FS-NNNN-suffix"
    if ! grep -qF "$id" "$readme"; then
      echo "FAIL: $id has no FS README index entry"
      return 1
    fi
  done
}

@test "index_consistency: all PLAN docs have a PLAN README row" {
  local readme="$PLANS_DIR/README.md"
  [ -f "$readme" ]
  for f in "$PLANS_DIR"/PLAN-*.md; do
    [ -f "$f" ] || continue
    local id
    id=$(grep -m1 '^id:' "$f" | sed 's/^id:[[:space:]]*//')
    [ -z "$id" ] && continue
    if ! grep -qF "$id" "$readme"; then
      echo "FAIL: $id has no PLAN README index entry"
      return 1
    fi
  done
}

@test "index_consistency: ADR README rows have corresponding files" {
  local readme="$DECISIONS_DIR/README.md"
  [ -f "$readme" ] || skip "ADR README not found"
  local ids
  ids=$(grep -oE 'ADR-[0-9]{4}' "$readme" | sort -u || true)
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    # Find matching file: ADR-NNNN-*.md or ADR-NNNN.md
    local found
    found=$(find "$DECISIONS_DIR" -maxdepth 1 \( -name "${id}-*.md" -o -name "${id}.md" \) 2>/dev/null | head -1)
    if [ -z "$found" ]; then
      echo "FAIL: $id has a README row but no matching file in $DECISIONS_DIR"
      return 1
    fi
  done <<< "$ids"
}

# ── Frontmatter field presence ──────────────────────────────────────────────

@test "frontmatter: FS docs have required frontmatter fields" {
  local core_fields=("type" "id" "status" "created" "updated")
  for f in "$SPECS_DIR"/FS-*.md; do
    [ -f "$f" ] || continue
    for field in "${core_fields[@]}"; do
      if ! grep -qE "^${field}:" "$f"; then
        echo "FAIL: $(basename "$f") missing frontmatter field: $field"
        return 1
      fi
    done
  done
}

@test "frontmatter: PLAN docs have required frontmatter fields" {
  # PLAN docs use type: change-plan and have no id: field in frontmatter.
  local plan_fields=("type" "status" "created" "updated" "related_specs")
  for f in "$PLANS_DIR"/PLAN-*.md; do
    [ -f "$f" ] || continue
    for field in "${plan_fields[@]}"; do
      if ! grep -qE "^${field}:" "$f"; then
        echo "FAIL: $(basename "$f") missing frontmatter field: $field"
        return 1
      fi
    done
  done
}

@test "frontmatter: ADR decision_scope is a recognised value" {
  local scopes=("architecture" "workflow" "convention" "infrastructure" "process"
                "system" "cross-cutting")
  for f in "$DECISIONS_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    local scope
    scope=$(grep -m1 '^decision_scope:' "$f" | sed 's/^decision_scope:[[:space:]]*//')
    [ -z "$scope" ] && continue
    local valid=false
    for s in "${scopes[@]}"; do
      [ "$scope" = "$s" ] && valid=true
    done
    if ! $valid; then
      echo "FAIL: $(basename "$f") has unrecognised decision_scope: '$scope'"
      return 1
    fi
  done
}

@test "frontmatter: no doc has a placeholder YYYY-MM-DD date (log only)" {
  # This tests for a known governance hygiene issue. Some docs still
  # have templated placeholder dates (e.g. FS-0023, tracked in #121).
  # Report findings but don't fail the suite — these are pre-existing
  # issues logged as suggest items.
  local found=false
  for f in $ALL_DOCS; do
    local hits
    hits=$(grep -cE 'updated:[[:space:]]*YYYY-MM-DD|created:[[:space:]]*YYYY-MM-DD' "$f" || true)
    if [ "$hits" -gt 0 ]; then
      echo "WARN: $(basename "$f") contains placeholder date YYYY-MM-DD (see #121)"
      found=true
    fi
  done
  $found && skip "Placeholder dates found — see suggest:#121 for the fix"
}

# ── Status consistency ──────────────────────────────────────────────────────

@test "status_consistency: FS README status matches frontmatter status" {
  local readme="$SPECS_DIR/README.md"
  [ -f "$readme" ]
  for f in "$SPECS_DIR"/FS-*.md; do
    [ -f "$f" ] || continue
    local id status row readme_status
    id=$(grep -m1 '^id:' "$f" | sed 's/^id:[[:space:]]*//')
    status=$(grep -m1 '^status:' "$f" | sed 's/^status:[[:space:]]*//')
    row=$(grep "| $id " "$readme" 2>/dev/null || true)
    [ -n "$row" ] || continue
    # Parse the status column (3rd pipe-delimited field after trimming)
    readme_status=$(echo "$row" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}')
    [ -n "$readme_status" ] || continue
    # Check it's a real status value, not a title
    local known=false
    for s in "draft" "proposed" "approved" "in-progress" "implemented" "deprecated" "current" "active"; do
      [ "$readme_status" = "$s" ] && known=true
    done
    $known || continue
    if [ "$status" != "$readme_status" ]; then
      echo "FAIL: $id frontmatter says '$status' but README says '$readme_status'"
      return 1
    fi
  done
}

@test "status_consistency: created: date does not exceed updated: date" {
  for f in $ALL_DOCS; do
    local created updated
    created=$(grep -m1 '^created:' "$f" | sed 's/^created:[[:space:]]*//' 2>/dev/null || echo "")
    updated=$(grep -m1 '^updated:' "$f" | sed 's/^updated:[[:space:]]*//' 2>/dev/null || echo "")
    [ -z "$created" ] || [ -z "$updated" ] && continue
    # Lexical comparison works for YYYY-MM-DD
    if [ "$created" \> "$updated" ]; then
      echo "FAIL: $(basename "$f") created: $created is after updated: $updated"
      return 1
    fi
  done
}

# ── Governance value validation ─────────────────────────────────────────────

@test "governance: no FS or PLAN uses an unapproved status value" {
  local known=("draft" "proposed" "approved" "in-progress" "implemented"
               "accepted" "rejected" "deprecated" "superseded" "current"
               "ready-for-review" "planned" "active")
  for dir in "$SPECS_DIR" "$PLANS_DIR"; do
    for f in "$dir"/*.md; do
      [ -f "$f" ] || continue
      local status
      status=$(grep -m1 '^status:' "$f" | sed 's/^status:[[:space:]]*//')
      [ -z "$status" ] && continue
      local valid=false
      for s in "${known[@]}"; do
        [ "$status" = "$s" ] && valid=true
      done
      if ! $valid; then
        echo "FAIL: $(basename "$f") has unrecognised status: '$status'"
        return 1
      fi
    done
  done
}
