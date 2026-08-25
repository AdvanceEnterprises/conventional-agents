#!/usr/bin/env bash
# new-adr.sh — Scaffold a new ADR from the MADR template
# Usage: npm run new:adr -- --title "My Decision Title"
#        npm run new:adr                      # interactive mode
#        npm run new:adr --dry-run            # generate to stdout only
#
# FRAMEWORK_HOME is where this script physically lives.
FRAMEWORK_HOME="$(cd "$(dirname "$0")/.." && pwd)"
DOCS_DIR="$FRAMEWORK_HOME/docs/decisions"
README="$DOCS_DIR/README.md"

set -euo pipefail

# Defaults
DRY_RUN=false
TITLE=""
INTERACTIVE=true

# ----- Parse arguments -----
while [ $# -gt 0 ]; do
  case "$1" in
    --title)
      shift
      if [ -n "$1" ]; then
        TITLE="$*"
        INTERACTIVE=false
        break
      else
        echo "ERROR: --title requires a value" >&2
        exit 1
      fi
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      echo "Usage: npm run new:adr -- --title \"Decision Title\""
      echo "       npm run new:adr                          # interactive"
      echo "       npm run new:adr --dry-run --title \"X\"   # preview"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

# ----- Find next ADR number -----
next_adr_num() {
  local max=0
  for f in "$DOCS_DIR"/ADR-*.md; do
    if [ -f "$f" ]; then
      local basename_str num
      basename_str=$(basename "$f" .md)        # e.g. ADR-0034 or ADR-0001
      # Strip optional slug suffix too: ADR-0034-foo -> 0034
      num="${basename_str#ADR-}"
      num="${num%%-*}"                          # before first dash
      num="${num##+(0)}"                        # strip leading zeros
      if [ -n "$num" ] && [ "$num" -gt "$max" ] 2>/dev/null; then
        max=$num
      fi
    fi
  done
  echo $((max + 1))
}

# ----- Slugify a title -----
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

# ----- Read a value with a default -----
prompt() {
  local prompt="$1" default="$2" result
  read -r -p "$prompt [$default]: " result
  echo "${result:-$default}"
}

# ----- Main -----
if $INTERACTIVE; then
  echo "=== New ADR Scaffolder ==="
  echo ""
  TITLE=$(prompt "Title" "")
fi

if [ -z "$TITLE" ]; then
  echo "ERROR: Title is required." >&2
  exit 1
fi

ADR_NUM=$(next_adr_num)
SLUG=$(slugify "$TITLE")
ADR_NUM_PAD=$(printf "%04d" "$ADR_NUM")
FILENAME="ADR-${ADR_NUM_PAD}-${SLUG}.md"
FILEPATH="$DOCS_DIR/$FILENAME"

if [ -f "$FILEPATH" ]; then
  echo "ERROR: $FILEPATH already exists." >&2
  exit 1
fi

if $INTERACTIVE; then
  echo ""
  echo "--- ADR Context (press Enter for empty) ---"
  CONTEXT=$(prompt "Context and Problem Statement" "")
  DECISION=$(prompt "Decision Outcome" "")
  CONSEQUENCES=$(prompt "Consequences" "")
  DECISION_SCOPE=$(prompt "Decision scope (system / architecture / workflow / process)" "architecture")
  REVERSIBLE=$(prompt "Reversible (yes / no)" "yes")
  RELATED_SPECS=$(prompt "Related FS/PLAN (comma-separated, e.g. FS-0018,PLAN-0010)" "")
  TODAY=$(date +%Y-%m-%d)
else
  CONTEXT=""
  DECISION=""
  CONSEQUENCES=""
  DECISION_SCOPE="architecture"
  REVERSIBLE="yes"
  RELATED_SPECS=""
  TODAY=$(date +%Y-%m-%d)
fi

# Format related_specs as YAML list; use inline [] when empty
if [ -n "$RELATED_SPECS" ]; then
  RELATED_YAML=$(echo "$RELATED_SPECS" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sed 's/^/  - /')
  RELATED_LINE="related_specs:"
else
  RELATED_YAML=""
  RELATED_LINE="related_specs: []"
fi

# Sanitize user input for shell expansion safety
sanitize() {
  echo "$1" | sed 's/"/\\"/g' | sed "s/'/\\'/g"
}

TITLE_SAFE=$(sanitize "$TITLE")
CONTEXT_SAFE=$(sanitize "${CONTEXT:-TODO: Describe the context and problem statement.}")
DECISION_SAFE=$(sanitize "$DECISION")
CONSEQUENCES_SAFE=$(sanitize "$CONSEQUENCES")
DECISION_SCOPE_SAFE=$(sanitize "$DECISION_SCOPE")
REVERSIBLE_SAFE=$(sanitize "$REVERSIBLE")

# Build the ADR file content safely
CONTENT="---
type: adr
id: ADR-${ADR_NUM_PAD}
status: proposed
decision_scope: $DECISION_SCOPE_SAFE
reversible: $REVERSIBLE_SAFE
${RELATED_LINE}
${RELATED_YAML}
superseded_by: null
created: $TODAY
updated: $TODAY
---

# ADR-${ADR_NUM_PAD}: ${TITLE_SAFE}

## Status

- Proposed

## Context and Problem Statement

${CONTEXT_SAFE}

## Decision Drivers

<!-- What forces are at play? Why is this decision needed? -->

## Considered Options

<!-- List the alternatives that were evaluated -->

## Decision Outcome

$(if [ -n "$DECISION_SAFE" ]; then
echo "Chosen option: \"$DECISION_SAFE\""
else
echo "<!-- TODO: describe the chosen option -->"
fi)

### Consequences

$(if [ -n "$CONSEQUENCES_SAFE" ]; then
echo "$CONSEQUENCES_SAFE"
else
echo "<!-- TODO: describe the positive and negative consequences -->"
fi)

## Validation

<!-- How will compliance with this decision be verified in CI or manual review? -->

## Confirmation

<!-- Describe how the decision outcome will be confirmed as implemented. -->
"

if $DRY_RUN; then
  echo ""
  echo "=== DRY RUN — ADR content preview ==="
  echo "File: $FILENAME"
  echo "---"
  echo "$CONTENT"
  exit 0
fi

# Pre-flight check: ensure template directory exists (informational)
if [ ! -f "$FRAMEWORK_HOME/vendor/madr/template/adr-template.md" ]; then
  echo "⚠  Warning: vendor/madr template not found (submodule may not be initialized)."
  echo "   Generate will proceed with built-in template."
fi

echo "$CONTENT" > "$FILEPATH"

echo ""
echo "✅ Created: $FILEPATH"

# Post-generation lint check
if command -v npx &>/dev/null; then
  if npx --yes markdownlint-cli2 "$FILEPATH" 2>/dev/null; then
    echo "✓ Lint pass"
  else
    echo "⚠  Lint check recommended: npm run lint:adrs"
  fi
fi

echo ""
echo "  Next step: add decision drivers, considered options, and confirmation."
echo "  Then update the ADR index in $README"
echo ""
echo "  git add $FILEPATH"
echo "  git commit -m \"docs: add ADR-${ADR_NUM_PAD} ${TITLE}\""
