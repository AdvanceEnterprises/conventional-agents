#!/usr/bin/env bash
# new-plan.sh — Scaffold a PLAN stub from an ADR markdown file
# Usage: npm run new:plan -- --adr docs/decisions/ADR-0034.md
#        npm run new:plan -- --adr docs/decisions/ADR-0034.md --number PLAN-0035
#        npm run new:plan -- --help
#
# FRAMEWORK_HOME is where this script physically lives.
FRAMEWORK_HOME="$(cd "$(dirname "$0")/.." && pwd)"
DOCS_DIR="$FRAMEWORK_HOME/docs/change-plans"

set -euo pipefail

# Defaults
ADR_FILE=""
PLAN_NUM=""
DRY_RUN=false

# ----- Parse arguments -----
while [ $# -gt 0 ]; do
  case "$1" in
    --adr)
      shift
      if [ -n "$1" ] && [ "${1#--}" = "$1" ]; then
        ADR_FILE="$1"
        shift
      else
        echo "ERROR: --adr requires a value" >&2
        exit 1
      fi
      ;;
    --number)
      shift
      if [ -n "$1" ] && [ "${1#--}" = "$1" ]; then
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
      echo "Usage: npm run new:plan -- --adr DOC.md [--number PLAN-NNNN]"
      echo ""
      echo "Scaffold a PLAN stub from an ADR markdown file."
      echo ""
      echo "Options:"
      echo "  --adr DOC.md          Path to an ADR markdown file (required)"
      echo "  --number PLAN-NNNN    Specific PLAN number (optional, auto-filled)"
      echo "  --dry-run             Print generated content to stdout only"
      echo "  --help                Show this help message"
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      echo "Usage: npm run new:plan -- --adr DOC.md [--number PLAN-NNNN]" >&2
      exit 2
      ;;
  esac
done

# ----- Validate arguments -----
if [ -z "$ADR_FILE" ]; then
  echo "ERROR: --adr is required." >&2
  echo "Usage: npm run new:plan -- --adr DOC.md [--number PLAN-NNNN]" >&2
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

# Extract fields from frontmatter using awk
extract_field() {
  local field="$1"
  # Match "field: value" (simple scalar) or "field:|- " (YAML multiline-start)
  # We only handle simple scalar values for the stub.
  local val
  val=$(echo "$FRONTMATTER" | grep -E "^${field}:" | sed "s/^${field}: *//" | sed 's/^"//;s/"$//')
  printf '%s' "$val"
}

ADR_TITLE=$(extract_field "title")
ADR_ID=$(extract_field "id")

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

# Extract context, decision, consequences from the ADR body
# Context: find ## Context and Problem Statement section, read until next ##
extract_section() {
  local heading="$1"
  local file="$2"
  awk -v h="$heading" '
    $0 ~ "^##+ " h "$" { found=1; next }
    found && /^##+ / { exit }
    found { print }
  ' "$file"
}

ADDR_CONTEXT=$(extract_section "Context and Problem Statement" "$ADR_FILE")
ADDR_DECISION=$(extract_section "Decision Outcome" "$ADR_FILE")
ADDR_CONSEQUENCES=$(extract_section "Consequences" "$ADR_FILE")

# Use a fallback if any section is empty
: "${ADDR_CONTEXT:=TODO: describe the context}"
: "${ADDR_DECISION:=TODO: describe the decision}"
: "${ADDR_CONSEQUENCES:=TODO: describe the consequences}"

# ----- Slugify from ADR title -----
slugify() {
  local slug
  slug=$(echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')
  if [ -z "$slug" ]; then
    slug="untitled"
  fi
  echo "$slug"
}

SLUG=$(slugify "$ADR_TITLE")

# ----- Determine PLAN number -----
if [ -n "$PLAN_NUM" ]; then
  # Validate format PLAN-NNNN
  if ! echo "$PLAN_NUM" | grep -qE '^PLAN-[0-9]{4}$'; then
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
      num="${num##+(0)}"
      if [ -n "$num" ] && [ "$num" -gt "$max_plan" ] 2>/dev/null; then
        max_plan=$num
      fi
    fi
  done
  PLAN_NUM_DIGITS=$(printf "%04d" "$((max_plan + 1))")
fi

PLAN_ID="PLAN-${PLAN_NUM_DIGITS}"
FILENAME="${PLAN_ID}-${SLUG}.md"
FILEPATH="$DOCS_DIR/$FILENAME"

# Strip leading "ADR-" from the adr_id for the frontmatter reference
# e.g. ADR-0034 stays as-is
ADR_REF="$ADR_ID"

if [ -f "$FILEPATH" ]; then
  echo "ERROR: $FILEPATH already exists." >&2
  exit 1
fi

TODAY=$(date +%Y-%m-%d)

# Build the PLAN file content
CONTENT="---
status: draft
title: \"${ADR_TITLE}\"
slug: \"${SLUG}\"
adr: ${ADR_REF}
author: autonomous-tick
created: ${TODAY}
updated: ${TODAY}
---

# ${PLAN_ID}: ${ADR_TITLE}

## Scope

## Rationale

The decision recorded in ${ADR_REF} establishes context that necessitates this plan:

**Context:** ${ADDR_CONTEXT}

**Decision:** ${ADDR_DECISION}

**Consequences:** ${ADDR_CONSEQUENCES}

## Touches

<!-- List paths this plan modifies, one per line: -->

## Gates

- [ ] <!-- Implementation complete -->
- [ ] <!-- Plan content reviewed -->
- [ ] <!-- Stakeholder approval -->
"

if $DRY_RUN; then
  echo ""
  echo "=== DRY RUN — PLAN content preview ==="
  echo "File: $FILENAME"
  echo "---"
  echo "$CONTENT"
  exit 0
fi

# Create directory if needed
mkdir -p "$DOCS_DIR"

echo "$CONTENT" > "$FILEPATH"

echo "$FILEPATH"
exit 0
