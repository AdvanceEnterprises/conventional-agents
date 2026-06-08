#!/usr/bin/env bash
# Validates FS↔PLAN status pairing and README index table sync.
# Exits non-zero and prints one error per violation.
# Bash 3.2+ compatible (no associative arrays).

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FS_DIR="$REPO_ROOT/docs/specifications"
PLAN_DIR="$REPO_ROOT/docs/change-plans"
FS_README="$FS_DIR/README.md"
PLAN_README="$PLAN_DIR/README.md"

errors=0

# --- helpers -----------------------------------------------------------------

# Extract a single YAML front matter field value from a file.
# Returns empty string if field not found.
get_field() {
  local file="$1" field="$2" value=""
  value=$(awk '/^---/{n++; if(n==2) exit; next} n==1' "$file" \
    | grep "^${field}:" \
    | head -1 \
    | sed "s/^${field}:[[:space:]]*//" \
    | tr -d '"')
  echo "$value"
}

# Extract values from a multi-line YAML list field (  - value) or inline [a, b].
get_related_specs() {
  local file="$1"
  awk '
    /^---/{n++; if(n==2) exit; next}
    n==1 && /^related_specs:/{
      in_field=1
      # handle inline: related_specs: [FS-0001, FS-0002]
      if ($0 ~ /\[/) {
        gsub(/^related_specs:[[:space:]]*\[/, "")
        gsub(/\]/, "")
        gsub(/ /, "")
        n2=split($0, parts, ",")
        for (i=1; i<=n2; i++) { if (parts[i] != "") print parts[i] }
        in_field=0
      }
      next
    }
    n==1 && in_field && /^  - /{
      val=$0; gsub(/^  - /, "", val); gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
      if (val != "") print val
      next
    }
    n==1 && in_field && !/^  /{in_field=0}
  ' "$file"
}

# Look up FS status from pre-built parallel arrays (via function call).
# We store as repeated-lookup from files since bash 3.2 lacks assoc arrays.
get_fs_status_for() {
  local target="$1"
  local i=0
  while [ $i -lt ${#fs_ids[@]} ]; do
    if [ "${fs_ids[$i]}" = "$target" ]; then
      echo "${fs_statuses[$i]}"
      return
    fi
    i=$((i+1))
  done
  echo ""
}

# --- build FS index ----------------------------------------------------------

fs_ids=()
fs_statuses=()

for fs_file in "$FS_DIR"/FS-*.md; do
  [ -f "$fs_file" ] || continue
  id=$(get_field "$fs_file" "id")
  status=$(get_field "$fs_file" "status")
  [ -z "$id" ] && continue
  fs_ids+=("$id")
  fs_statuses+=("$status")
done

# --- rule 1: FS↔PLAN status pairing -----------------------------------------
# Only the FIRST entry in related_specs is the primary governing spec.
# Secondary entries are dependencies, not governance relationships.
# Rules:
#   a) If PLAN=implemented, its primary FS must also be implemented.
#   b) If FS=implemented, at least one PLAN listing it as primary must be implemented.

# Build a map of primary-fs → list-of-plan-files for the reverse check.
primary_fs_list=()   # parallel to primary_plan_list
primary_plan_list=()

for plan_file in "$PLAN_DIR"/PLAN-*.md; do
  [ -f "$plan_file" ] || continue
  plan_name=$(basename "$plan_file")
  plan_status=$(get_field "$plan_file" "status")

  # Get the first (primary) related_spec.
  primary_fs=$(get_related_specs "$plan_file" | head -1 | tr -d '[:space:]')
  [ -z "$primary_fs" ] && continue

  primary_fs_list+=("$primary_fs")
  primary_plan_list+=("$plan_name:$plan_status")

  # Rule a: if PLAN=implemented, primary FS must be implemented.
  if [ "$plan_status" = "implemented" ]; then
    fs_status=$(get_fs_status_for "$primary_fs")
    if [ -z "$fs_status" ]; then
      echo "ERROR: $plan_name references $primary_fs as primary spec but no matching FS file found."
      errors=$((errors+1))
    elif [ "$fs_status" != "implemented" ]; then
      echo "ERROR: $plan_name is 'implemented' but its primary spec $primary_fs is '$fs_status' — both must be 'implemented' together."
      errors=$((errors+1))
    fi
  fi
done

# Rule b: if FS=implemented, at least one PLAN with it as primary must be implemented.
i=0
while [ $i -lt ${#fs_ids[@]} ]; do
  fs_id="${fs_ids[$i]}"
  fs_status="${fs_statuses[$i]}"
  i=$((i+1))

  [ "$fs_status" = "implemented" ] || continue

  found_implemented_plan=0
  j=0
  while [ $j -lt ${#primary_fs_list[@]} ]; do
    if [ "${primary_fs_list[$j]}" = "$fs_id" ]; then
      plan_entry="${primary_plan_list[$j]}"
      plan_st="${plan_entry##*:}"
      if [ "$plan_st" = "implemented" ]; then
        found_implemented_plan=1
        break
      fi
    fi
    j=$((j+1))
  done

  if [ $found_implemented_plan -eq 0 ]; then
    echo "ERROR: $fs_id is 'implemented' but no PLAN with it as primary spec is also 'implemented'."
    errors=$((errors+1))
  fi
done

# --- rule 2: README table sync -----------------------------------------------

check_readme_sync() {
  local readme="$1" doc_dir="$2" prefix="$3"

  for doc_file in "$doc_dir"/${prefix}-*.md; do
    [ -f "$doc_file" ] || continue
    doc_name=$(basename "$doc_file")

    # Extract ID: prefer front matter id:, fall back to filename.
    doc_id=$(get_field "$doc_file" "id")
    if [ -z "$doc_id" ]; then
      doc_id=$(echo "$doc_name" | grep -oE "${prefix}-[0-9]+" | head -1)
    fi
    [ -z "$doc_id" ] && continue

    front_status=$(get_field "$doc_file" "status")
    [ -z "$front_status" ] && continue

    # Find status in README table row for this doc_id.
    # Table format: | ID | Title | status |  (trailing pipe optional)
    readme_row=$(grep "^| ${doc_id} " "$readme" | head -1)
    if [ -z "$readme_row" ]; then
      echo "ERROR: $doc_id has no row in $(basename "$readme") — README index is missing an entry."
      errors=$((errors+1))
      continue
    fi

    # Extract the last non-empty column value.
    readme_status=$(echo "$readme_row" | awk -F'|' '{
      for (i=NF; i>1; i--) {
        val=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
        if (val != "") { print val; exit }
      }
    }')

    if [ "$readme_status" != "$front_status" ]; then
      echo "ERROR: $doc_id front matter status='$front_status' but README shows '$readme_status'."
      errors=$((errors+1))
    fi
  done
}

check_readme_sync "$FS_README"   "$FS_DIR"   "FS"
check_readme_sync "$PLAN_README" "$PLAN_DIR" "PLAN"

# --- result ------------------------------------------------------------------

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "Found $errors status consistency error(s). Fix the above before committing."
  exit 1
fi

echo "All status checks passed."
exit 0
