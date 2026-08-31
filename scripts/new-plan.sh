#!/usr/bin/env bash
# new-plan.sh — Scaffold a PLAN stub from an ADR markdown file
# Usage: npm run new:plan -- --adr docs/decisions/ADR-0034.md
#        npm run new:plan -- --adr docs/decisions/ADR-0034.md --number PLAN-0035
#        npm run new:plan -- --dry-run --adr docs/decisions/ADR-0034.md
#        npm run new:plan -- --help
#
# Per FS-0024/ADR-0033: REPO_ROOT is resolved from the caller's working directory
# (git rev-parse --show-toplevel) or from CA_TARGET_REPO, so a vendored copy
# creates the PLAN in the host repo, not inside vendor/conventional-agents.

set -euo pipefail

# ----- Paths -----
# FRAMEWORK_HOME: where this script lives (used for self-location only)
FRAMEWORK_HOME="$(cd "$(dirname "$0")/.." && pwd)"

# REPO_ROOT: target repository, resolved per FS-0024/ADR-0033
if [ -n "${CA_TARGET_REPO:-}" ]; then
  REPO_ROOT="$(cd "$CA_TARGET_REPO" 2>/dev/null && pwd)"
  if [ -z "$REPO_ROOT" ]; then
    echo "ERROR: CA_TARGET_REPO='$CA_TARGET_REPO' is not a directory." >&2
    exit 1
  fi
else
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

DOCS_DIR="$REPO_ROOT/docs/change-plans"

# ----- Defaults -----
ADR_FILE=""
PLAN_NUM=""
DRY_RUN=false

# ----- Help -----
show_usage() {
  echo "Usage: npm run new:plan -- --adr DOC.md [--number PLAN-NNNN] [--dry-run]"
  echo ""
  echo "Scaffold a PLAN stub from an ADR markdown file."
  echo ""
  echo "Options:"
  echo "  --adr DOC.md          Path to an ADR markdown file (required)"
  echo "  --number PLAN-NNNN    Specific PLAN number (optional, auto-filled)"
  echo "  --dry-run             Print generated content to stdout only"
  echo "  --help                Show this help message"
}

# ----- Parse arguments -----
while [ $# -gt 0 ]; do
  case "$1" in
    --adr)
      shift
      if [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; then
        ADR_FILE="$1"
        shift
      else
        echo "ERROR: --adr requires a value" >&2
        exit 1
      fi
      ;;
    --number)
      shift
      if [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; then
        PLAN_NUM="$1"
        shift
      else
        echo "ERROR: --number requires a value" >&2
        exit 1
      fi
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      show_usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      show_usage >&2
      exit 2
      ;;
  esac
done

# ----- Validate arguments -----
if [ -z "$ADR_FILE" ]; then
  echo "ERROR: --adr is required." >&2
  show_usage >&2
  exit 1
fi

if [ ! -f "$ADR_FILE" ]; then
  echo "ERROR: ADR file not found: $ADR_FILE" >&2
  exit 1
fi

# Resolve absolute path for the ADR file
ADR_FILE="$(cd "$(dirname "$ADR_FILE")" && pwd)/$(basename "$ADR_FILE")"

# ----- Extract ADR frontmatter -----
# Read between the first pair of --- markers
FRONTMATTER=$(awk '/^---$/{c++;next}c==1' "$ADR_FILE")

if [ -z "$FRONTMATTER" ]; then
  echo "ERROR: No frontmatter found in $ADR_FILE" >&2
  exit 1
fi

# Extract scalar fields from frontmatter using awk
extract_field() {
  local field="$1"
  local val
  val=$(printf '%s\n' "$FRONTMATTER" | grep -E "^${field}:" | sed "s/^${field}: *//" | sed 's/^"//;s/"$//')
  printf '%s' "$val"
}

# Extract YAML list fields (e.g. related_specs: [FS-0018] or related_specs: \n  - FS-0018)
# Portable (no grep -P); returns empty when the field is absent (no set -e exit).
extract_list() {
  local field="$1"
  local val
  # Inline list form: field: [FS-0018, FS-0019]
  val=$(printf '%s\n' "$FRONTMATTER" | grep -E "^${field}:" | sed "s/^${field}: *//" | grep -oE '[A-Z]+-[0-9]+' | tr '\n' ' ' | sed 's/ $//')
  # Multi-line list form: field:\n  - FS-0018\n  - FS-0019
  if [ -z "$val" ]; then
    val=$(printf '%s\n' "$FRONTMATTER" | awk -v f="$field" '
      $0 ~ "^" f ":[[:space:]]*$" { in_list=1; next }
      in_list && /^[[:space:]]*-[[:space:]]+/ { gsub(/^[[:space:]]*-[[:space:]]*/, ""); print; next }
      in_list && !/^[[:space:]]*$/ { exit }
    ' | grep -oE '[A-Z]+-[0-9]+' | tr '\n' ' ' | sed 's/ $//')
  fi
  printf '%s' "$val"
}

ADR_TITLE=$(extract_field "title")
ADR_ID=$(extract_field "id")
ADR_STATUS=$(extract_field "status")

if [ -z "$ADR_ID" ]; then
  echo "ERROR: ADR frontmatter missing 'id' field." >&2
  exit 1
fi

# If ADR frontmatter has no title field, extract from the H1 heading
if [ -z "$ADR_TITLE" ]; then
  ADR_TITLE=$(grep -m1 '^# ' "$ADR_FILE" | sed 's/^# *[A-Z]\+-[0-9]\+: *//;s/^# *//')
fi

if [ -z "$ADR_TITLE" ]; then
  echo "ERROR: Could not determine title from ADR frontmatter or H1 heading." >&2
  exit 1
fi

# Extract related_specs and related_adrs from the ADR
RELATED_SPECS=$(extract_list "related_specs")
RELATED_ADRS=$(extract_list "related_adrs")

# Also include the ADR's own ID if not already in related_adrs
if [ -n "$ADR_ID" ]; then
  if ! echo " $RELATED_ADRS " | grep -q " $ADR_ID "; then
    RELATED_ADRS="${RELATED_ADRS} ${ADR_ID}"
  fi
fi

# Extract context, decision, consequences from the ADR body
# Match exact heading level (##) to avoid capturing subsections
extract_section() {
  local heading="$1"
  local file="$2"
  awk -v h="$heading" '
    $0 ~ "^## " h "$" { found=1; next }
    found && /^## / { exit }
    found { print }
  ' "$file"
}

ADDR_CONTEXT=$(extract_section "Context and Problem Statement" "$ADR_FILE")
ADDR_DECISION=$(extract_section "Decision Outcome" "$ADR_FILE")

# Consequences: most ADRs use a top-level "## Consequences" section; some use
# "### Consequences" as a subsection under "## Decision Outcome". Try the
# top-level form first, then fall back to the subsection form.
extract_consequences() {
  local file="$1"
  local out
  out=$(awk -v h="Consequences" '
    $0 ~ "^## " h "$" { found=1; next }
    found && /^## / { exit }
    found { print }
  ' "$file")
  if [ -z "$out" ]; then
    out=$(awk -v h="Consequences" '
      $0 ~ "^### " h "$" { found=1; next }
      found && /^##/ { exit }
      found && /^### / { exit }
      found { print }
    ' "$file")
  fi
  printf '%s' "$out"
}

ADDR_CONSEQUENCES=$(extract_consequences "$ADR_FILE")

# Use a fallback if any section is empty
: "${ADDR_CONTEXT:=TODO: describe the context}"
: "${ADDR_DECISION:=TODO: describe the decision}"
: "${ADDR_CONSEQUENCES:=TODO: describe the consequences}"

# ----- Slugify from ADR title -----
slugify() {
  local slug
  slug=$(printf '%s\n' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')
  if [ -z "$slug" ]; then
    slug="untitled"
  fi
  printf '%s' "$slug"
}

SLUG=$(slugify "$ADR_TITLE")

# ----- Determine PLAN number -----
if [ -n "$PLAN_NUM" ]; then
  # Validate format PLAN-NNNN
  if ! printf '%s\n' "$PLAN_NUM" | grep -qE '^PLAN-[0-9]{4}$'; then
    echo "ERROR: --number must be PLAN-NNNN (e.g. PLAN-0035)" >&2
    exit 1
  fi
  PLAN_NUM_DIGITS="${PLAN_NUM#PLAN-}"
else
  # Auto-find next PLAN number
  max_plan=0
  for f in "$DOCS_DIR"/PLAN-*.md; do
    if [ -f "$f" ]; then
      basename_str=$(basename "$f" .md)
      num="${basename_str#PLAN-}"
      num="${num%%-*}"
      # Strip leading zeros safely (avoid octal trap)
      num=$(printf '%s\n' "$num" | sed 's/^0*//')
      if [ -z "$num" ]; then
        num=0
      fi
      if [ "$num" -gt "$max_plan" ] 2>/dev/null; then
        max_plan=$num
      fi
    fi
  done
  PLAN_NUM_DIGITS=$(printf "%04d" "$((max_plan + 1))")
fi

PLAN_ID="PLAN-${PLAN_NUM_DIGITS}"
FILENAME="${PLAN_ID}-${SLUG}.md"
FILEPATH="$DOCS_DIR/$FILENAME"

if [ -f "$FILEPATH" ]; then
  echo "ERROR: $FILEPATH already exists." >&2
  exit 1
fi

TODAY=$(TZ=UTC date +%Y-%m-%d)

# Build the related_specs/related_adrs YAML list strings
format_yaml_list() {
  local list="$1"
  if [ -z "$(printf '%s' "$list" | tr -d '[:space:]')" ]; then
    printf '%s' "[]"
  else
    printf '%s\n' "$list" | tr ' ' '\n' | while IFS= read -r item; do
      if [ -n "$item" ]; then
        printf '  - %s\n' "$item"
      fi
    done
  fi
}

SPECS_YAML=$(format_yaml_list "$RELATED_SPECS")
ADRS_YAML=$(format_yaml_list "$RELATED_ADRS")

# Format list fields: use inline if empty, multi-line if non-empty
if [ "$SPECS_YAML" = "[]" ]; then
  SPECS_LINE="related_specs: []"
else
  SPECS_LINE="related_specs:"
fi

if [ "$ADRS_YAML" = "[]" ]; then
  ADRS_LINE="related_adrs: []"
else
  ADRS_LINE="related_adrs:"
fi

# Build the PLAN file content
CONTENT="---
type: change-plan
role: implementer
language: n/a
status: draft
${SPECS_LINE}"
if [ "$SPECS_YAML" != "[]" ]; then
  CONTENT="${CONTENT}
$(printf '%s' "$SPECS_YAML")"
fi
CONTENT="${CONTENT}
${ADRS_LINE}"
if [ "$ADRS_YAML" != "[]" ]; then
  CONTENT="${CONTENT}
$(printf '%s' "$ADRS_YAML")"
fi
CONTENT="${CONTENT}
touches: []
created: ${TODAY}
updated: ${TODAY}
---

# ${PLAN_ID}: ${ADR_TITLE}

## 1. Feature / Issue Reference

* Feature Spec ID(s): ${RELATED_SPECS:-TODO}
* Related ADR ID(s): ${RELATED_ADRS:-TODO}
* Issue / PR Reference: <ID or link>

## 2. Scope of Change

**This change WILL:**

* <bullet derived from ${ADR_ID}'s decision>

**This change will NOT:**

* <explicit non-goal>

## Rationale

${ADR_ID} establishes context that necessitates this plan:

**Context:**

$(printf '%s\n' "$ADDR_CONTEXT")

**Decision:**

$(printf '%s\n' "$ADDR_DECISION")

**Consequences:**

$(printf '%s\n' "$ADDR_CONSEQUENCES")

## 3. Touches

<!-- List paths this plan modifies, one per line: -->

## 4. Gates

- [ ] <!-- Implementation complete -->
- [ ] <!-- Plan content reviewed -->
- [ ] <!-- Stakeholder approval -->

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding
"

if $DRY_RUN; then
  echo ""
  echo "=== DRY RUN — PLAN content preview ==="
  echo "File: $FILENAME"
  echo "---"
  printf '%s\n' "$CONTENT"
  exit 0
fi

# Create directory if needed
mkdir -p "$DOCS_DIR"

printf '%s\n' "$CONTENT" > "$FILEPATH"

echo "$FILEPATH"
exit 0
