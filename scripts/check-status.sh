#!/usr/bin/env bash
# Validates FS/PLAN/ADR status pairings, README index table sync, ADR structural
# completeness, PLAN touches: containment, and consumer-impact CHANGELOG entries.
# Exits non-zero and prints one error per violation.
# Bash 3.2+ compatible (no associative arrays).

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FS_DIR="$REPO_ROOT/docs/specifications"
PLAN_DIR="$REPO_ROOT/docs/change-plans"
ADR_DIR="$REPO_ROOT/docs/decisions"
FS_README="$FS_DIR/README.md"
PLAN_README="$PLAN_DIR/README.md"
ADR_README="$ADR_DIR/README.md"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

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

# Extract values from a multi-line YAML list field — generic, for interfaces: and touches:.
get_list_field() {
  local file="$1" field="$2"
  awk -v field="$field" '
    /^---/{n++; if(n==2) exit; next}
    n==1 && $0 ~ "^"field":"{
      in_field=1
      if ($0 ~ /\[/) {
        line=$0
        gsub("^"field":[[:space:]]*\\[", "", line)
        gsub("\\]", "", line)
        gsub(/ /, "", line)
        n2=split(line, parts, ",")
        for (i=1; i<=n2; i++) { if (parts[i] != "") print parts[i] }
        in_field=0
      }
      next
    }
    n==1 && in_field && /^  - /{
      val=$0; gsub(/^  - /, "", val); gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
      gsub(/^"/, "", val); gsub(/"$/, "", val)
      if (val != "") print val
      next
    }
    # A blank line inside a block list does not end the field. Without this the
    # parser stopped at the first blank separator and returned one entry, which
    # silently reduced the touches: containment check to its first path.
    n==1 && in_field && /^[[:space:]]*$/{next}
    n==1 && in_field && !/^  /{in_field=0}
  ' "$file"
}

# Resolve a governed document by its ID, tolerating descriptive filename suffixes.
#
#   FS-0018 -> docs/specifications/FS-0018-issue-lifecycle-and-autonomous-triggers.md
#   ADR-0006 -> docs/decisions/ADR-0006.md
#
# Rules 4 and 7 previously built "$dir/$id.md" directly. Every FS and PLAN in this
# repository carries a suffix, so that path never resolved, and both checks hit their
# `[ -f ] || continue` and skipped every document. They passed while enforcing nothing.
# Constructing a filename from an ID is the wrong direction; resolve it instead.
resolve_doc_by_id() {
  local doc_dir="$1" doc_id="$2" f
  for f in "$doc_dir/$doc_id".md "$doc_dir/$doc_id"-*.md; do
    [ -f "$f" ] || continue
    printf '%s\n' "$f"
    return 0
  done
  return 1
}

# Get FS status (helper used by FS↔PLAN rule a).
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
fs_titles=()
fs_paths=()

for fs_file in "$FS_DIR"/FS-*.md; do
  [ -f "$fs_file" ] || continue
  id=$(get_field "$fs_file" "id")
  status=$(get_field "$fs_file" "status")
  title=$(get_field "$fs_file" "title")
  [ -z "$id" ] && continue
  fs_ids+=("$id")
  fs_statuses+=("$status")
  fs_titles+=("$title")
  fs_paths+=("$fs_file")
done

# --- rule 1: FS↔PLAN status pairing -----------------------------------------

primary_fs_list=()
primary_plan_list=()

for plan_file in "$PLAN_DIR"/PLAN-*.md; do
  [ -f "$plan_file" ] || continue
  plan_name=$(basename "$plan_file")
  plan_status=$(get_field "$plan_file" "status")

  primary_fs=$(get_related_specs "$plan_file" | head -1 | tr -d '[:space:]')
  [ -z "$primary_fs" ] && continue

  primary_fs_list+=("$primary_fs")
  primary_plan_list+=("$plan_name:$plan_status")

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

    doc_id=$(get_field "$doc_file" "id")
    if [ -z "$doc_id" ]; then
      doc_id=$(echo "$doc_name" | grep -oE "${prefix}-[0-9]+" | head -1)
    fi
    [ -z "$doc_id" ] && continue

    front_status=$(get_field "$doc_file" "status")
    [ -z "$front_status" ] && continue

    readme_row=$(grep "^| ${doc_id} " "$readme" | head -1)
    if [ -z "$readme_row" ]; then
      echo "ERROR: $doc_id has no row in $(basename "$readme") — README index is missing an entry."
      errors=$((errors+1))
      continue
    fi

    # Extract the last non-empty column value (status).
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

# --- rule 3: ADR index consistency (FS-0022 §1) ------------------------------

# Build set of ADR files.
adr_ids=()
for adr_file in "$ADR_DIR"/ADR-*.md; do
  [ -f "$adr_file" ] || continue
  adr_id=$(get_field "$adr_file" "id")
  [ -z "$adr_id" ] && continue
  adr_ids+=("$adr_id")
done

# Every ADR file should have a row in the ADR README, and the row's title/status must match.
for adr_file in "$ADR_DIR"/ADR-*.md; do
  [ -f "$adr_file" ] || continue
  adr_id=$(get_field "$adr_file" "id")
  [ -z "$adr_id" ] && continue

  # Extract H1: "# ADR-NNNN: <title>"
  h1_title=$(awk '/^# ADR-[0-9]+:/{
    sub(/^# ADR-[0-9]+:[[:space:]]*/, "", $0)
    print
    exit
  }' "$adr_file")
  front_status=$(get_field "$adr_file" "status")

  row=$(grep "^| ${adr_id} " "$ADR_README" | head -1)
  if [ -z "$row" ]; then
    echo "ERROR: $adr_id has no row in docs/decisions/README.md — ADR index is missing an entry."
    errors=$((errors+1))
    continue
  fi

  # Extract title column (col 2) and status (last non-empty).
  readme_title=$(echo "$row" | awk -F'|' '{
    val=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", val); print val
  }')
  readme_status=$(echo "$row" | awk -F'|' '{
    for (i=NF; i>1; i--) {
      val=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
      if (val != "") { print val; exit }
    }
  }')

  if [ "$readme_title" != "$h1_title" ]; then
    echo "ERROR: $adr_id H1 title '$h1_title' but README shows '$readme_title'."
    errors=$((errors+1))
  fi

  if [ "$readme_status" != "$front_status" ]; then
    echo "ERROR: $adr_id front matter status='$front_status' but README shows '$readme_status'."
    errors=$((errors+1))
  fi
done

# Every ADR index row should correspond to a file that exists.
# Match by front matter id:, not by filename — some ADR files have descriptive suffixes
# (ADR-0011-adopt-multi-identity-github-model-...).
if [ -f "$ADR_README" ]; then
  while IFS= read -r row; do
    row_id=$(echo "$row" | awk -F'|' '/^| ADR-[0-9]+ /{gsub(/^ +| +$/, "", $2); print $2}')
    [ -z "$row_id" ] && continue
    found=0
    for adr_file in "$ADR_DIR"/ADR-*.md; do
      [ -f "$adr_file" ] || continue
      file_id=$(get_field "$adr_file" "id")
      if [ "$file_id" = "$row_id" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 0 ]; then
      echo "ERROR: ADR index row references $row_id but no matching ADR file (by id:) exists in $ADR_DIR."
      errors=$((errors+1))
    fi
  done < <(grep "^| ADR-" "$ADR_README")
fi

# --- rule 4: FS/PLAN index title sync (FS-0022 §1a) -------------------------

# For each FS row in docs/specifications/README.md, the title column should match the front
# matter title field. Likewise for PLAN.
# $4 = "yes" to compare titles, "no" for row-resolution only.
#
# PLANs carry no `title:` front-matter field — none of the 23 in this repository has
# one, and templates/core/change-plan.md does not define one. Comparing a PLAN's
# front matter title to its README row therefore compares the empty string to real
# text and reports every plan as drifted. FS-0022 §1a's Success Criteria ask for
# title drift on FS and *row existence* on PLAN, which is what this implements.
check_index_titles() {
  local readme="$1" doc_dir="$2" prefix="$3" compare_titles="$4"

  while IFS= read -r row; do
    row_id=$(echo "$row" | awk -F'|' -v pfx="$prefix" '/^| '"$prefix"'-[0-9]+ /{
      gsub(/^ +| +$/, "", $2); print $2
    }')
    [ -z "$row_id" ] && continue

    if ! doc_file=$(resolve_doc_by_id "$doc_dir" "$row_id"); then
      echo "ERROR: $row_id has a row in $(basename "$readme") but no matching file in $doc_dir."
      errors=$((errors+1))
      continue
    fi

    [ "$compare_titles" = "yes" ] || continue

    front_title=$(get_field "$doc_file" "title")
    readme_title=$(echo "$row" | awk -F'|' '{
      val=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", val); print val
    }')

    if [ "$front_title" != "$readme_title" ]; then
      echo "ERROR: $row_id front matter title '$front_title' but README shows '$readme_title'."
      errors=$((errors+1))
    fi
  done < <(grep "^| ${prefix}-" "$readme")
}

check_index_titles "$FS_README"   "$FS_DIR"   "FS"   "yes"
check_index_titles "$PLAN_README" "$PLAN_DIR" "PLAN" "no"

# --- rule 5: ADR structural completeness (FS-0022 §1b) ----------------------

# Required sections per docs/decisions/README.md §2:
#   "Context and Problem Statement", "Considered Options",
#   "Decision Outcome", "Consequences", "Validation"
# An ADR at `accepted` missing any of these is a higher-severity failure than the same
# omission on a `proposed` ADR.

REQUIRED_ADR_SECTIONS=(
  "## Context and Problem Statement"
  "## Considered Options"
  "## Decision Outcome"
  "## Consequences"
)

for adr_file in "$ADR_DIR"/ADR-*.md; do
  [ -f "$adr_file" ] || continue
  adr_id=$(get_field "$adr_file" "id")
  [ -z "$adr_id" ] && continue
  adr_status=$(get_field "$adr_file" "status")
  [ -z "$adr_status" ] && continue

  # Validation section is required only at accepted (per the spec); flag absent at any status
  # but report higher severity at accepted.
  has_validation=$(grep -c "^## Validation" "$adr_file" 2>/dev/null || true)
  if [ -z "$has_validation" ] || [ "$has_validation" = "0" ]; then
    if [ "$adr_status" = "accepted" ]; then
      echo "ERROR: $adr_id (accepted) is missing required section: ## Validation"
      errors=$((errors+1))
    else
      echo "WARN: $adr_id ($adr_status) is missing section: ## Validation (required before acceptance)"
    fi
  fi

  # Other sections required at accepted.
  if [ "$adr_status" = "accepted" ]; then
    for sec in "${REQUIRED_ADR_SECTIONS[@]}"; do
      if ! grep -qF "$sec" "$adr_file"; then
        echo "ERROR: $adr_id (accepted) is missing required section: $sec"
        errors=$((errors+1))
      fi
    done
  fi
done

# --- rule 6: PLAN touches: containment (FS-0022 §2 / ADR-0027) --------------

# Reserved paths: paths in touches: that always require human approval regardless of FS's
# interfaces: field. Per ADR-0027.
RESERVED_PATHS=(
  "docs/decisions/"
  "guidelines/ROLE_CONTRACT.md"
  "scripts/"
  ".github/workflows/"
  "package.json"
)

for plan_file in "$PLAN_DIR"/PLAN-*.md; do
  [ -f "$plan_file" ] || continue
  plan_name=$(basename "$plan_file")
  plan_status=$(get_field "$plan_file" "status")
  # Check applies to plans at approved or in-progress status — plans seeking (self-)
  # approval now. Implemented plans landed under whatever rule was in force at the time;
  # retroactively failing them would surface historical drift that the plan's §5a did not
  # scope to fix. Per ADR-0027, the rule governs *future* self-approval; historical
  # approval is grandfathered.
  case "$plan_status" in
    approved|in-progress) ;;
    *) continue ;;
  esac

  # Grandfather clause: an explicit allow-list of plans that predate ADR-0027.
  #
  # This was previously a comparison of the plan's `created:` date against ADR-0027's.
  # That is a backdating bypass: `created:` is agent-writable front matter, so any plan
  # could exempt itself by claiming an earlier date. An explicit list cannot be extended
  # from inside a plan file.
  #
  # Add an entry only when a real historical approval needs grandfathering, and say why.
  case "$plan_name" in
    PLAN-0001-*|PLAN-0002-*|PLAN-0003-*|PLAN-0004-*|PLAN-0005-*|PLAN-0006-*|\
    PLAN-0007-*|PLAN-0008-*|PLAN-0009-*|PLAN-0010-*|PLAN-0011-*|PLAN-0012-*|\
    PLAN-0013-*|PLAN-0014-*|PLAN-0015-*|PLAN-0016-*|PLAN-0017-*)
      # Approved before ADR-0027 existed; these carry no touches: field because the
      # rule did not exist when they were written.
      continue
      ;;
  esac

  # The PLAN must have a touches: field — absence is a violation.
  touches_lines=$(get_list_field "$plan_file" "touches")
  if [ -z "$touches_lines" ]; then
    echo "ERROR: $plan_name has no touches: field — ADR-0027 requires one."
    errors=$((errors+1))
    continue
  fi

  # Compute the union of interfaces: for the PLAN's related_specs. Prefix with "|" so
  # that the grep below can match every entry exactly (including the first).
  primary_fs=$(get_related_specs "$plan_file" | head -1 | tr -d '[:space:]')
  [ -z "$primary_fs" ] && continue

  interfaces_union="|"
  while IFS= read -r fs_id; do
    [ -z "$fs_id" ] && continue
    # Match by front matter id, not by filename — FS files have descriptive suffixes
    # (FS-0018-issue-lifecycle-and-autonomous-triggers.md).
    fs_file=""
    for candidate in "$FS_DIR"/${fs_id}*.md; do
      [ -f "$candidate" ] || continue
      [ "$(get_field "$candidate" "id")" = "$fs_id" ] && fs_file="$candidate" && break
    done
    [ -z "$fs_file" ] && continue
    while IFS= read -r iface; do
      [ -z "$iface" ] && continue
      interfaces_union="${interfaces_union}${iface}|"
    done < <(get_list_field "$fs_file" "interfaces")
  done < <(get_related_specs "$plan_file")

  # Read human approval evidence from front matter (per ADR-0026/0027).
  #
  # The front-matter value alone proves nothing — it is agent-writable, so any plan
  # could self-approve by asserting a string. It must be corroborated by an actual
  # approval record in git: the most recent commit touching this plan file must carry
  # an `Approved-By:` trailer whose email matches the front matter, and that email must
  # differ from the commit's own author. ADR-0026: "a commit whose Approved-By: matches
  # its own author email is malformed."
  #
  # "Most recent" is deliberate. If a plan is edited after approval, the approval no
  # longer covers its current content and must be renewed.
  plan_approved_by=$(get_field "$plan_file" "approved_by")
  approval_ok=""
  approval_note=""
  if [ -n "$plan_approved_by" ]; then
    fm_email=$(printf '%s' "$plan_approved_by" | sed -nE 's/.*<([^>]+)>.*/\1/p')
    if [ -n "$fm_email" ]; then
      approving_sha=$(git -C "$REPO_ROOT" log -n 1 \
          --format='%H%x09%ae%x09%(trailers:key=Approved-By,valueonly,separator=%x20)' \
          -- "$plan_file" 2>/dev/null |
        awk -F'\t' -v want="$fm_email" '
          NF >= 3 {
            sha = $1; author = tolower($2); trailer = $3
            if (match(trailer, /<[^>]+>/)) {
              email = tolower(substr(trailer, RSTART + 1, RLENGTH - 2))
              if (email == tolower(want) && author != email) print sha
            }
          }')
      if [ -n "$approving_sha" ]; then
        # An approval covers the touches: set that existed when it was given. If the
        # working tree's touches: differs, the approval does not extend to the change —
        # otherwise an agent could add a reserved path after approval and ride the old
        # record. Compare the two sets rather than trusting the trailer alone.
        rel_path=${plan_file#"$REPO_ROOT"/}
        approved_touches=$(git -C "$REPO_ROOT" show "$approving_sha:$rel_path" 2>/dev/null |
          awk '/^touches:/{f=1;next} f&&/^[a-z_]+:/{exit} f&&/^[[:space:]]*- /{gsub(/^[[:space:]]*- *|"/,"");print}' |
          sort)
        current_touches=$(get_list_field "$plan_file" "touches" | sed 's/^[[:space:]]*//; s/"//g' | sort)
        if [ "$approved_touches" = "$current_touches" ]; then
          approval_ok="ok"
        else
          approval_note="touches: has changed since the approving commit ($approving_sha); the approval does not cover it"
        fi
      fi
    fi
  fi

  # Check each touch against interfaces: union and reserved set.
  while IFS= read -r touch; do
    [ -z "$touch" ] && continue
    # CHANGELOG.md is exempt from containment. Document hygiene gate item 4 obliges
    # every user-visible change to add an entry, so every plan touches it. Listing it
    # in every FS's interfaces: would be noise, and leaving it unlisted creates steady
    # pressure to widen interfaces for a file that is a framework-wide obligation
    # rather than any one spec's surface. It is not a reserved path.
    [ "$touch" = "CHANGELOG.md" ] && continue
    # Reserved path check first.
    reserved_match=""
    for r in "${RESERVED_PATHS[@]}"; do
      case "$touch" in
        "$r"*) reserved_match="$r" ;;
      esac
    done
    if [ -n "$reserved_match" ]; then
      if [ "$approval_ok" = "ok" ]; then
        continue
      fi
      echo "ERROR: $plan_name touches: '$touch' is in ADR-0027's reserved-path set ('$reserved_match') — requires human approval."
      if [ -n "$plan_approved_by" ]; then
        if [ -n "$approval_note" ]; then
          echo "       approved_by: '$plan_approved_by' is set, but $approval_note."
        else
          echo "       approved_by: '$plan_approved_by' is set, but the most recent commit touching this"
          echo "       plan carries no matching Approved-By: trailer from a different author (ADR-0026)."
        fi
      fi
      errors=$((errors+1))
      continue
    fi
    # Interfaces: containment check. Exact match first.
    if echo "$interfaces_union" | grep -qF "|$touch|"; then
      continue
    fi
    # Coarse match: touch is a sub-path of an interface (interfaces are directory roots
    # in spirit; the spec lists files but consumers may treat them as prefixes).
    matched=0
    IFS='|'
    for iface in $interfaces_union; do
      [ -z "$iface" ] && continue
      case "$touch" in
        "$iface"*) matched=1 ;;
      esac
    done
    unset IFS
    if [ "$matched" -eq 0 ]; then
      if [ "$approval_ok" = "ok" ]; then
        continue
      fi
      echo "ERROR: $plan_name touches: '$touch' is outside its governing FS's interfaces: union — requires human approval."
      if [ -n "$plan_approved_by" ]; then
        if [ -n "$approval_note" ]; then
          echo "       approved_by: '$plan_approved_by' is set, but $approval_note."
        else
          echo "       approved_by: '$plan_approved_by' is set, but the most recent commit touching this"
          echo "       plan carries no matching Approved-By: trailer from a different author (ADR-0026)."
        fi
      fi
      errors=$((errors+1))
    fi
  done <<< "$touches_lines"
done

# --- rule 7: consumer-impact declaration (FS-0022 §1d) ----------------------

# An FS at approved or beyond whose interfaces: names an exported-surface path must have a
# CHANGELOG entry naming it. The check verifies presence only; framing is a review judgment.

EXPORTED_PREFIXES=(
  "guidelines/"
  "roles/"
  "skills/"
  "templates/"
  "workflows/"
  "integrations/"
  "runbooks/"
  "INTEGRATION.md"
  "AGENTS.md"
)

i=0
while [ $i -lt ${#fs_ids[@]} ]; do
  fs_id="${fs_ids[$i]}"
  fs_status="${fs_statuses[$i]}"
  # The FS index built fs_paths from the real files; use it rather than rebuilding a
  # filename from the ID, which never resolved for suffixed names.
  fs_file="${fs_paths[$i]}"
  i=$((i+1))

  case "$fs_status" in
    approved|in-progress|implemented) ;;
    *) continue ;;
  esac

  [ -f "$fs_file" ] || continue

  has_exported=0
  while IFS= read -r iface; do
    [ -z "$iface" ] && continue
    for p in "${EXPORTED_PREFIXES[@]}"; do
      case "$iface" in
        "$p"*) has_exported=1 ;;
      esac
    done
  done < <(get_list_field "$fs_file" "interfaces")

  [ "$has_exported" -eq 0 ] && continue

  if ! grep -q "$fs_id" "$CHANGELOG"; then
    echo "ERROR: $fs_id (status=$fs_status) has exported-surface interfaces but no CHANGELOG entry naming it — consumer-framed entry required."
    errors=$((errors+1))
  fi
done

# --- rule 8: referenced-path resolution (FS-0022 §1c) ------------------------
#
# Every path a current-state document names in backticks must resolve, relative to the
# repository root or to the naming document's own directory.
#
# Two scoping decisions the spec left open, both resolved narrower than a literal
# reading, because a literal reading produces false failures:
#
# 1. Current-state documents only. Decision records (ADR, FS, PLAN) describe what was
#    true when they were written. `ADR-0006` naming three role files that were later
#    renamed is history, not drift, and those documents are append-only after
#    acceptance — checking them would force edits to satisfy a linter. `ADR-0030`
#    rule 3 assigns current-state documents the job of carrying present truth, so they
#    are the ones that must resolve. `BACKLOG.md` is excluded for the opposite reason:
#    naming things that do not exist yet is its entire purpose. `CHANGELOG.md` is a
#    historical record.
#
# 2. Only tokens containing a directory separator. A bare `tsconfig.json`,
#    `pnpm-lock.yaml`, or `CLAUDE.md` in a guideline names a file in the *reader's*
#    repository, not this one. Requiring a separator is the cheapest rule that
#    separates "asserting a location here" from "naming a file you will have".
#
# REF_EXEMPT covers the case rule 2 does not: a path-like reference to a file this
# framework instructs a consumer to create in *their* repo is indistinguishable from a
# reference to one of ours. There is no syntax that separates them, so they are listed
# explicitly with reasons rather than the corpus being edited to satisfy the check
# (FS-0022 §1c is explicit that exclusions are the check's job).

REF_EXEMPT=(
  # "<naming document>:<referenced path>  # reason"
  "README.md:roles/session-modes.md"                      # consumer creates this
  "workflows/session-modes.md:roles/session-modes.md"     # consumer creates this
  "roles/README.md:docs/governance/role-contract.md"      # prefixed "in your own repo"
)

ref_exempt() {
  local pair="$1:$2" e
  for e in "${REF_EXEMPT[@]}"; do
    [ "${e%%#*}" = "$pair" ] && return 0
    [ "$e" = "$pair" ] && return 0
  done
  return 1
}

# Paths an approved PLAN declares it will create are not yet expected to exist.
collect_planned_paths() {
  local plan_file st
  for plan_file in "$PLAN_DIR"/PLAN-*.md; do
    [ -f "$plan_file" ] || continue
    st=$(get_field "$plan_file" "status")
    if [ "$st" = "approved" ] || [ "$st" = "in-progress" ]; then
      get_list_field "$plan_file" "touches"
    fi
  done
}
planned_paths=$(collect_planned_paths | sed 's/^[[:space:]]*//; s/"//g' | sort -u)
# Newline-delimited on both ends so membership is a fork-free `case` match below.
# bash 3.2 (macOS system bash) has no associative arrays, and forking one grep per
# referenced path made this check the slowest thing in the suite.
planned_paths_str=$'\n'"$planned_paths"$'\n'

while IFS= read -r doc; do
  [ -f "$REPO_ROOT/$doc" ] || continue
  case "$doc" in
    README.md|AGENTS.md|INTEGRATION.md|CONTRIBUTING.md) ;;
    guidelines/*|roles/*|skills/*|templates/*|workflows/*|integrations/*|runbooks/*|scripts/*) ;;
    *) continue ;;
  esac
  doc_dir=$(dirname "$doc")
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    case "$ref" in
      */*) ;;                              # path-like only
      *) continue ;;
    esac
    case "$ref" in
      *NNNN*|*XXXX*|*'<'*) continue ;;     # template placeholders
      vendor/*) continue ;;                # uninitialised submodule (FS-0022 §1c)
      docs/orchestration/*) continue ;;    # preserved evidence (FS-0022 §1c)
    esac
    # Consumers reference framework files through vendor/conventional-agents/.
    bare=${ref#vendor/conventional-agents/}
    [ -e "$REPO_ROOT/$ref" ] && continue
    [ -e "$REPO_ROOT/$bare" ] && continue
    [ "$doc_dir" != "." ] && [ -e "$REPO_ROOT/$doc_dir/$ref" ] && continue
    case "$planned_paths_str" in *$'\n'"$ref"$'\n'*) continue ;; esac
    ref_exempt "$doc" "$ref" && continue
    echo "ERROR: $doc references '$ref', which does not resolve (FS-0022 §1c)."
    errors=$((errors+1))
  done < <(grep -oE '`[A-Za-z0-9_./@-]+\.(md|sh|yml|yaml|json|py|bats)`' "$REPO_ROOT/$doc" 2>/dev/null | tr -d '`' | sort -u)
done < <(git -C "$REPO_ROOT" ls-files '*.md')

# --- result ------------------------------------------------------------------

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "Found $errors status consistency error(s). Fix the above before committing."
  exit 1
fi

echo "All status checks passed."
exit 0
