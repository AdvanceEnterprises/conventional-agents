#!/usr/bin/env bash
# Validates FS/PLAN/ADR status pairings, README index table sync, ADR structural
# completeness, PLAN touches: containment, and consumer-impact CHANGELOG entries.
# Exits non-zero and prints one error per violation.
# Bash 3.2+ compatible (no associative arrays).

# FRAMEWORK_HOME is where this script physically lives — the old (pre-FS-0024)
# REPO_ROOT computation, kept under a new name for exactly what it is good at:
# locating the script's own copy of itself. It was never wrong as a self-locator;
# it was wrong as a target-resolver, because every caller outside this repository
# invokes a vendored copy whose own location is never the repository being checked.
FRAMEWORK_HOME="$(cd "$(dirname "$0")/.." && pwd)"

# REPO_ROOT is what this run checks — the git repository containing the caller's
# working directory, per FS-0024/ADR-0033. `npm run check:status`, every CI job in
# lint-docs.yml, and every bats suite that invokes this script all already run with
# their working directory at the repository they mean to check, so this resolves
# identically to the old computation for every invocation this repository makes of
# itself. A vendored copy invoked from a host repository's root now resolves to the
# host's root instead of the submodule's, because the host's working directory
# never crosses into the submodule boundary. CA_TARGET_REPO overrides both, for a
# caller whose working directory is not inside the repository it means to check.
#
# CA_TARGET_REPO is canonicalized via `cd ... && pwd`, not used as-is: every path
# built from REPO_ROOT below is a direct concatenation ($REPO_ROOT/docs/...), and a
# relative CA_TARGET_REPO would make every one of them relative to whatever the
# caller's working directory happens to be at the moment each is evaluated —
# fragile, and wrong the instant anything in this script changed directories. A
# CA_TARGET_REPO that is not a real directory is a caller error, not something to
# paper over by falling back to git rev-parse — it fails loudly instead.
if [ -n "${CA_TARGET_REPO:-}" ]; then
  REPO_ROOT="$(cd "$CA_TARGET_REPO" 2>/dev/null && pwd)"
  if [ -z "$REPO_ROOT" ]; then
    echo "ERROR: CA_TARGET_REPO='$CA_TARGET_REPO' is not a directory." >&2
    exit 1
  fi
else
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

# The resolved root must be a git work tree (issue #194). The `|| pwd` fallback
# above covers a caller inside a work tree whose top-level resolution needed it;
# outside one it manufactured a root for a directory that is not a repository at
# all — every git-backed rule then failed in silence while the document checks
# warned only, and the script printed the success line: exit 0 for a check that
# enforced nothing. A CI job or maintainer running from the wrong directory must
# see a loud error instead.
if [ "$(git -C "$REPO_ROOT" rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
  echo "ERROR: '$REPO_ROOT' is not inside a git working tree." >&2
  echo "       Run this script from within the repository it should check, or set" >&2
  echo "       CA_TARGET_REPO to that repository's working tree. (issue #194)" >&2
  exit 1
fi
# A CA_TARGET_REPO naming a subdirectory of a work tree satisfies the membership
# check above while every document path below roots at the subdirectory — the
# loops then audit nothing and the script prints the success line (Copilot
# review, PR #198). Resolution is repository-relative (ADR-0033): the target
# names a repository, so it maps to that work tree's top level, exactly as the
# working-directory default does.
REPO_ROOT="$(git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null)"

# True when this run is the framework checking itself — every invocation this
# repository makes of its own scripts, including its own CI and its own bats
# suites. False when a vendored copy is checking a host repository. Rules 6 and 7
# below use this to decide whether to use this repository's own hardcoded
# RESERVED_PATHS/EXPORTED_PREFIXES or to require the host's own config/gates.yml —
# see ADR-0033 for why this repository does not ship a populated config/gates.yml
# for its own use (it would be instance data inside a template repository, per
# ADR-0032).
is_self_check() { [ "$REPO_ROOT" = "$FRAMEWORK_HOME" ]; }

FS_DIR="$REPO_ROOT/docs/specifications"
PLAN_DIR="$REPO_ROOT/docs/change-plans"
ADR_DIR="$REPO_ROOT/docs/decisions"
FS_README="$FS_DIR/README.md"
PLAN_README="$PLAN_DIR/README.md"
ADR_README="$ADR_DIR/README.md"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
GATES_CONFIG="$REPO_ROOT/config/gates.yml"

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

# Same shape as get_list_field, for a plain YAML file with no `---` front-matter
# delimiters — config/gates.yml, per FS-0024/ADR-0033. Consumer-owned; never a path
# inside the vendored tree.
get_flat_list_field() {
  local file="$1" field="$2"
  # An absent file (the common case: no config/gates.yml at all) is not an awk
  # error to surface — it is "nothing configured", handled by the caller. Without
  # this, awk prints "can't open file" to stderr for every unconfigured field on
  # every run against a host with no config/gates.yml, noise indistinguishable
  # from a real problem.
  [ -f "$file" ] || return 0
  awk -v field="$field" '
    $0 ~ "^"field":"{
      in_field=1
      if ($0 ~ /\[/) {
        line=$0
        gsub("^"field":[[:space:]]*\\[", "", line)
        gsub("\\]", "", line)
        gsub(/ /, "", line)
        n2=split(line, parts, ",")
        for (i=1; i<=n2; i++) {
          p = parts[i]
          gsub(/^"/, "", p); gsub(/"$/, "", p)
          if (p != "") print p
        }
        in_field=0
      }
      next
    }
    in_field && /^  - /{
      val=$0; gsub(/^  - /, "", val); gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
      gsub(/^"/, "", val); gsub(/"$/, "", val)
      if (val != "") print val
      next
    }
    in_field && /^[[:space:]]*$/{next}
    in_field && !/^  /{in_field=0}
  ' "$file"
}

# True when $1 (a plain YAML file) exists and contains a top-level "$2:" key at
# all — distinct from get_flat_list_field returning no lines, which is also what
# an explicit "$2: []" produces. Callers need to tell "not configured" from
# "configured as empty" apart; this is how.
has_flat_field() {
  local file="$1" field="$2"
  [ -f "$file" ] && grep -qE "^${field}:" "$file"
}

# Extract every id named by a relationship field in a document's front matter.
# The field name is a parameter rather than a literal so a second relationship is
# a call, not a copy of this parser. FS-0028 defers `amends`/`amended_by` to its
# own spec; this is the seam that work will use.
#
# Handles the three field shapes the ADR template and `docs/decisions/README.md`
# §5 allow: `null` (the empty declaration, yielding no ids), a single inline id,
# and a YAML list in either inline (`[ADR-00XX, ADR-00YY]`) or indented
# (`  - ADR-00XX`) form. Only the front-matter block is read, so the same token
# appearing in prose is never mistaken for the field.
get_relation_ids() {
  local file="$1" field="$2"
  awk -v field="$field" '
    /^---/{n++; if(n==2) exit; next}
    n==1 && $0 ~ "^"field":"{
      line=$0; sub("^"field":[[:space:]]*", "", line)
      if (line ~ /\[/) {
        gsub(/^[[:space:]]*\[|[][[:space:]]*$/, "", line)
        gsub(/[[:space:]]*,[[:space:]]*/, "\n", line)
        gsub(/["'\'']/, "", line)
        if (line != "") print line
        next
      }
      gsub(/^["'\'']|["'\'']$/, "", line)
      if (line != "") print line
      in_list=1
      next
    }
    n==1 && in_list && /^[[:space:]]*-/{
      v=$0; sub(/^[[:space:]]*-[[:space:]]*/, "", v); gsub(/["'\'']/, "", v)
      if (v != "") print v
      next
    }
    n==1 && in_list && !/^[[:space:]]*-/{in_list=0}
  ' "$file" | sed '/^null$/d'
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

# --- rule 4: governed-ID duplicate detection (FS-0040 / #179) ----------------

# A descriptive filename can hide a duplicate front-matter claim, so compare
# the declared IDs and report every file carrying a repeated claim. FS, PLAN,
# and ADR sequences remain independent: FS-0040 and PLAN-0040 are not a
# collision. This uses a temporary tab-delimited evidence file rather than
# associative arrays so the check remains Bash 3.2-compatible.
duplicate_evidence="$(mktemp "${TMPDIR:-/tmp}/ca-governed-id.XXXXXX")"
trap 'rm -f "$duplicate_evidence"' EXIT
for registry_file in "$FS_DIR"/FS-*.md "$PLAN_DIR"/PLAN-*.md "$ADR_DIR"/ADR-*.md; do
  [ -f "$registry_file" ] || continue
  registry_id=$(get_field "$registry_file" "id")
  if [ -z "$registry_id" ]; then
    registry_id=$(basename "$registry_file" | sed -nE \
      's/^(FS|PLAN|ADR)-([0-9][0-9][0-9][0-9])(-.*)?\.md$/\1-\2/p')
  fi
  [ -n "$registry_id" ] || continue
  printf '%s\t%s\n' "$registry_id" "$registry_file" >> "$duplicate_evidence"
done

duplicate_ids="$(awk -F '\t' '{counts[$1]++} END {for (id in counts) if (counts[id] > 1) print id}' "$duplicate_evidence" | sort)"
if [ -n "$duplicate_ids" ]; then
  while IFS= read -r duplicate_id; do
    [ -n "$duplicate_id" ] || continue
    echo "ERROR: duplicate governed ID $duplicate_id is claimed by:"
    awk -F '\t' -v wanted="$duplicate_id" '$1 == wanted {print "  " $2}' "$duplicate_evidence"
    errors=$((errors+1))
  done <<< "$duplicate_ids"
fi
rm -f "$duplicate_evidence"

# --- rule 5: FS/PLAN index title sync (FS-0022 §1a) -------------------------

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

# Bare section names. The heading level is deliberately not pinned: MADR 4.0 — which
# docs/decisions/README.md adopts as the baseline — puts Consequences at H3 nested
# under "## Decision Outcome", while the others sit at H2. Requiring H2 for all of
# them would fail six correctly-structured ADRs in this repository.
REQUIRED_ADR_SECTIONS=(
  "Context and Problem Statement"
  "Considered Options"
  "Decision Outcome"
  "Consequences"
)

for adr_file in "$ADR_DIR"/ADR-*.md; do
  [ -f "$adr_file" ] || continue
  adr_id=$(get_field "$adr_file" "id")
  [ -z "$adr_id" ] && continue
  adr_status=$(get_field "$adr_file" "status")
  [ -z "$adr_status" ] && continue

  # Validation section is required only at accepted (per the spec); flag absent at any status
  # but report higher severity at accepted.
  # Anchored to a whole heading line. An unanchored match accepts "## Validation-old",
  # a "### Validation" subheading, or the words appearing in prose.
  has_validation=$(grep -cE "^#{2,3} Validation[[:space:]]*$" "$adr_file" 2>/dev/null || true)
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
      # grep -qF was unanchored, so "## Consequences-renamed" satisfied the
      # "## Consequences" requirement, as would a "### Consequences" subheading or a
      # mention in prose. Renaming a required section left the check passing.
      # Section names contain no regex metacharacters; anchor to the whole line.
      if ! grep -qE "^#{2,3} ${sec}[[:space:]]*$" "$adr_file"; then
        echo "ERROR: $adr_id (accepted) is missing required section: ## $sec"
        errors=$((errors+1))
      fi
    done
  fi
done

# --- rule 5b: ADR supersession chain (FS-0028) -------------------------------
#
# Every ADR front-matter block carries a `superseded_by:` field (template default
# `null`). `docs/decisions/README.md` §5 defines the supersede process: mark the
# old ADR `status: superseded` and point `superseded_by:` at the replacement;
# the replacement links back in its Links section. This rule makes the field
# machine-checked — previously a superseded ADR with `superseded_by: null`, a
# dangling replacement id, or a replacement declared by an accepted ADR all
# passed silently (FS-0022's "unchecked surface" principle).
#
# Three obligations:
#   1. An ADR at `status: superseded` must name at least one replacement.
#   2. Every non-null `superseded_by` entry must resolve to an existing ADR
#      file (matched by front-matter `id:`, tolerating suffixed filenames).
#   3. A non-null `superseded_by` on an ADR whose status is not `superseded`
#      is flagged: the field means "this ADR is replaced by...", which only a
#      superseded ADR may claim.
#
# The field may name one id (inline `superseded_by: ADR-00XX`) or several (a
# YAML list). `null` is the empty declaration and satisfies none of the three.
# The whole line is matched so a value never bleeds into `related_specs:`.

for adr_file in "$ADR_DIR"/ADR-*.md; do
  [ -f "$adr_file" ] || continue
  adr_id=$(get_field "$adr_file" "id")
  [ -z "$adr_id" ] && continue
  adr_status=$(get_field "$adr_file" "status")
  [ -z "$adr_status" ] && continue

  # Replacement ids named by superseded_by:. Parsing lives in get_relation_ids
  # so the field name stays a parameter (see the helper's note on `amends`).
  superseded_ids=$(get_relation_ids "$adr_file" "superseded_by")

  has_superseded_by=false
  [ -n "$superseded_ids" ] && has_superseded_by=true

  if [ "$adr_status" = "superseded" ]; then
    if [ "$has_superseded_by" = "false" ]; then
      echo "ERROR: $adr_id is 'superseded' but has no replacement — superseded_by: must name the replacing ADR (README §5)."
      errors=$((errors+1))
    fi
  fi

  if [ "$has_superseded_by" = "true" ]; then
    if [ "$adr_status" != "superseded" ]; then
      echo "ERROR: $adr_id (status='$adr_status') declares superseded_by: '$superseded_ids' but only a 'superseded' ADR may declare a replacement (README §5)."
      errors=$((errors+1))
    fi

    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      resolved=""
      for candidate in "$ADR_DIR"/"$entry".md "$ADR_DIR"/"$entry"-*.md; do
        [ -f "$candidate" ] || continue
        [ "$(get_field "$candidate" "id")" = "$entry" ] && resolved="$candidate" && break
      done
      if [ -z "$resolved" ]; then
        echo "ERROR: $adr_id superseded_by: '$entry' does not resolve to any ADR file (matched by id: in $ADR_DIR)."
        errors=$((errors+1))
      fi
    done <<< "$superseded_ids"
  fi
done

# --- rule 6: PLAN touches: containment (FS-0022 §2 / ADR-0027) --------------

# Reserved paths: paths in touches: that always require human approval regardless of FS's
# interfaces: field. Per ADR-0027.
#
# This repository's own reserved set, hardcoded, used only for self-check —
# creating a real config/gates.yml here, populated with this repository's own
# structural facts, would itself be instance data inside a template repository
# (ADR-0032's own test: a second adopter's copy would have to change every one of
# these paths). A vendored copy checking a host repository overrides this from
# the host's own config/gates.yml instead, below; see FS-0024/ADR-0033.
RESERVED_PATHS=(
  "docs/decisions/"
  "guidelines/ROLE_CONTRACT.md"
  "scripts/"
  ".github/workflows/"
  "package.json"
)

RESERVED_PATHS_CONFIGURED=1
if ! is_self_check; then
  RESERVED_PATHS=()
  if has_flat_field "$GATES_CONFIG" "reserved_paths"; then
    while IFS= read -r rp; do
      [ -n "$rp" ] && RESERVED_PATHS+=("$rp")
    done < <(get_flat_list_field "$GATES_CONFIG" "reserved_paths")
  else
    # Absent file or absent key — genuinely unconfigured, not "configured empty".
    # Fail closed per plan below rather than silently treating nothing as reserved.
    RESERVED_PATHS_CONFIGURED=0
  fi
fi

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
  # Scoped to the self-check path (issue #195). The list names THIS repository's
  # historical plans, but it applied in every consumer run too — where PLAN-0001 is
  # not a framework artifact but the first plan a consumer ever writes, so a vendored
  # copy silently skipped containment and reserved-path checks on the first seventeen
  # plan numbers of every host repository: the numbers where a new repository's plans
  # are most likely to propose scope no human sanctioned. A consumer cannot inherit
  # this repository's history; the safe default is to enforce.
  #
  # Add an entry only when a real historical approval needs grandfathering, and say why.
  if is_self_check; then
    case "$plan_name" in
      PLAN-0001-*|PLAN-0002-*|PLAN-0003-*|PLAN-0004-*|PLAN-0005-*|PLAN-0006-*|\
      PLAN-0007-*|PLAN-0008-*|PLAN-0009-*|PLAN-0010-*|PLAN-0011-*|PLAN-0012-*|\
      PLAN-0013-*|PLAN-0014-*|PLAN-0015-*|PLAN-0016-*|PLAN-0017-*)
        # Approved before ADR-0027 existed; these carry no touches: field because the
        # rule did not exist when they were written.
        continue
        ;;
    esac
  fi

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

  # Fail closed: a vendored check with no reserved_paths configured cannot safely
  # certify this plan as self-approved, and must not silently treat an unconfigured
  # reserved set as an empty one. Per FS-0024/ADR-0033 — the ADR-0019 "an agent must
  # not lower its own gate" principle, applied to unconfigured self-approval routing.
  # Does not apply to a plan a human has already approved (approval_ok=ok): nothing
  # here needed the reserved set to reach that determination.
  if [ "$RESERVED_PATHS_CONFIGURED" -eq 0 ] && [ "$approval_ok" != "ok" ]; then
    echo "ERROR: $plan_name cannot be certified for self-approval — 'reserved_paths' is"
    echo "       not configured in $GATES_CONFIG (missing file or missing key)."
    echo "       Copy config/gates.example.yml to config/gates.yml in this repository's"
    echo "       root and set reserved_paths (an empty list is a valid, explicit choice)."
    errors=$((errors+1))
    continue
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
#
# Unlike rule 6, an unconfigured or empty exported_prefixes does not fail closed — it
# skips, visibly. This is not a safety gate: the worst outcome of getting it wrong is a
# missed documentation courtesy, and a repository with genuinely no exported surface
# (ADR-0032 instance form — the concrete case is this framework's own consumer
# `feral-fleet`) has nothing for this rule to check. See FS-0024/ADR-0033.

EXPORTED_PREFIXES=(
  "guidelines/"
  "roles/"
  "skills/"
  "templates/"
  "workflows/"
  "integrations/"
  "runbooks/"
  "scripts/"
  "INTEGRATION.md"
  "AGENTS.md"
)

if ! is_self_check; then
  EXPORTED_PREFIXES=()
  while IFS= read -r ep; do
    [ -n "$ep" ] && EXPORTED_PREFIXES+=("$ep")
  done < <(get_flat_list_field "$GATES_CONFIG" "exported_prefixes")
fi

if [ "${#EXPORTED_PREFIXES[@]}" -eq 0 ]; then
  echo "SKIP: rule 7 (consumer-impact CHANGELOG) — no exported_prefixes configured in"
  echo "      $GATES_CONFIG. Treated as this repository asserting it has no exported"
  echo "      surface (ADR-0032 instance form). If that is wrong, configure it."
else
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
fi

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
#
# FS-0037 extends the rule for the canonical consumer citation form. References of the
# form `vendor/conventional-agents/<path>` are resolved instead of being caught by the
# generic `vendor/*` exclusion: strip-prefix in self-check, the initialised submodule in
# a host. The three exported-surface documents (`README.md`, `AGENTS.md`,
# `INTEGRATION.md`) additionally carry a non-backticked pass over the same prefix — the
# `INTEGRATION.md` phantoms that motivated the spec carried no backticks (issue #163).
# Third-party submodule paths (`vendor/madr/`) keep the exclusion.

# This repository's own exemptions, used only for self-check — each names a
# specific sentence in a specific document here, per FS-0024/ADR-0033's
# classification of REF_EXEMPT as per-repository. A vendored copy sources the
# host's own list from config/gates.yml's ref_exempt field instead — entries
# there carry no inline reason (config is not a place for prose), unlike this
# array, which documents its own reasoning for maintainers reading the script.
REF_EXEMPT=(
  # "<naming document>:<referenced path>  # reason"
  "README.md:roles/session-modes.md"                      # consumer creates this
  "workflows/session-modes.md:roles/session-modes.md"     # consumer creates this
  "roles/README.md:docs/governance/role-contract.md"      # prefixed "in your own repo"
  "scripts/README.md:config/gates.yml"                    # host repo creates this (FS-0024)
  "README.md:config/project.yml"                          # prescriptive — reader copies example to this path
  "README.md:pack-protocol/config/boards/conventional-agents.yml"  # external URL, not a local path
)

if ! is_self_check; then
  REF_EXEMPT=()
  while IFS= read -r rx; do
    [ -n "$rx" ] && REF_EXEMPT+=("$rx")
  done < <(get_flat_list_field "$GATES_CONFIG" "ref_exempt")
fi

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

# FS-0037: whether a host run can resolve `vendor/conventional-agents/` references
# at all — its submodule must actually be checked out. git leaves the directory
# empty when the submodule is not initialised, and that absence is the FS-0022 §1c
# exclusion, not drift. `ls -A` lists hidden entries too, so a partially
# initialised submodule whose only content is `.git` (an interrupted
# `git submodule update --init`) would otherwise count as populated while holding
# no usable checkout — MM3 round-B on PR #193. Probed once, not per reference.
# Self-check always resolves (the prefix strips against this tree) and does not
# use this flag.
host_vendor_ca_populated=""
if [ -d "$REPO_ROOT/vendor/conventional-agents" ] && \
   [ -n "$(ls -A "$REPO_ROOT/vendor/conventional-agents" 2>/dev/null | grep -v '^\.git$')" ]; then
  host_vendor_ca_populated=1
fi

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
      docs/orchestration/*) continue ;;    # preserved evidence (FS-0022 §1c)
    esac
    # FS-0037: the vendor/conventional-agents/ prefix — the documented way a
    # consumer cites a framework file — is resolved instead of being swallowed
    # by the generic vendor/* exclusion below. Self-check strips the prefix and
    # resolves against this tree; a host run resolves through its own
    # vendor/conventional-agents/ checkout, and only skips when that submodule
    # is not initialised (the FS-0022 §1c exclusion this replaces).
    case "$ref" in
      vendor/conventional-agents/*)
        if ! is_self_check && [ -z "$host_vendor_ca_populated" ]; then
          continue
        fi
        ;;
      vendor/*) continue ;;                # uninitialised submodule (FS-0022 §1c)
    esac
    # Consumers reference framework files through vendor/conventional-agents/.
    # The prefix strips only for self-check; in a host run the bare form would
    # resolve against the HOST's own root, so a phantom vendored citation would
    # pass whenever the host happens to carry its own file at the same bare
    # path (Copilot review, PR #193). Host runs resolve through the vendored
    # checkout only.
    [ -e "$REPO_ROOT/$ref" ] && continue
    if is_self_check; then
      bare=${ref#vendor/conventional-agents/}
      [ -e "$REPO_ROOT/$bare" ] && continue
    fi
    [ "$doc_dir" != "." ] && [ -e "$REPO_ROOT/$doc_dir/$ref" ] && continue
    case "$planned_paths_str" in *$'\n'"$ref"$'\n'*) continue ;; esac
    ref_exempt "$doc" "$ref" && continue
    echo "ERROR: $doc references '$ref', which does not resolve (FS-0022 §1c)."
    errors=$((errors+1))
  done < <({
      grep -oE '`[A-Za-z0-9_./@-]+\.(md|sh|yml|yaml|json|py|bats)`' "$REPO_ROOT/$doc" 2>/dev/null | tr -d '`'
      case "$doc" in
        README.md|AGENTS.md|INTEGRATION.md)
          # FS-0037: the three exported-surface documents also resolve
          # non-backticked prefixed citations — the #163 phantoms carried no
          # backticks, so a backtick-only extractor cannot see the incident
          # class this rule exists for. The token shape stays conservative: a
          # required lowercase file extension also excludes placeholders,
          # ellipses, globs, and directory citations.
          grep -oE 'vendor/conventional-agents/[A-Za-z0-9_./@-]+\.[a-z]+' "$REPO_ROOT/$doc" 2>/dev/null
          ;;
      esac
    } | sort -u)
done < <(git -C "$REPO_ROOT" ls-files '*.md')

# --- result ------------------------------------------------------------------

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "Found $errors status consistency error(s). Fix the above before committing."
  exit 1
fi

echo "All status checks passed."
exit 0
