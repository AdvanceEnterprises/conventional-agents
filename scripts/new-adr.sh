#!/usr/bin/env bash
# new-adr.sh — Scaffold a new ADR from the MADR template
# Usage: npm run new:adr -- --title "My Decision Title"
#        npm run new:adr                      # interactive mode
#
# FRAMEWORK_HOME is where this script physically lives.
FRAMEWORK_HOME="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$FRAMEWORK_HOME/vendor/madr/template/adr-template.md"
DOCS_DIR="$FRAMEWORK_HOME/docs/decisions"
README="$DOCS_DIR/README.md"

set -e

# ----- Find next ADR number -----
next_adr_num() {
  local max=0
  for f in "$DOCS_DIR"/ADR-*.md; do
    if [ -f "$f" ]; then
      local num; num=$(basename "$f" | sed 's/^ADR-0*//;s/-.*//')
      if [ "$num" -gt "$max" ] 2>/dev/null; then
        max=$num
      fi
    fi
  done
  echo $((max + 1))
}

# ----- Slugify a title -----
slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

# ----- Read a value with a default -----
prompt() {
  local prompt="$1" default="$2" result
  read -r -p "$prompt [$default]: " result
  echo "${result:-$default}"
}

# ----- Main -----
if [ "$1" = "--title" ] && [ -n "$2" ]; then
  TITLE="$2"
  INTERACTIVE=false
else
  echo "=== New ADR Scaffolder ==="
  echo ""
  TITLE=$(prompt "Title" "")
  INTERACTIVE=true
fi

if [ -z "$TITLE" ]; then
  echo "ERROR: Title is required." >&2
  exit 1
fi

ADR_NUM=$(next_adr_num)
SLUG=$(slugify "$TITLE")
ADDR_NUM_PAD=$(printf "%04d" "$ADR_NUM")
FILENAME="ADR-${ADDR_NUM_PAD}-${SLUG}.md"
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
  DECISION_SCOPE=$(prompt "Decision scope (architecture / workflow / convention)" "architecture")
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

# Format related_specs as YAML list
if [ -n "$RELATED_SPECS" ]; then
  RELATED_YAML=$(echo "$RELATED_SPECS" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sed 's/^/  - /')
else
  RELATED_YAML="[]"
fi

# Build the ADR file
cat > "$FILEPATH" << ADR_EOF
---
type: adr
id: ADR-${ADDR_NUM_PAD}
status: proposed
decision_scope: $DECISION_SCOPE
reversible: $REVERSIBLE
related_specs:
$RELATED_YAML
superseded_by: null
created: $TODAY
updated: $TODAY
---

# ADR-${ADDR_NUM_PAD}: ${TITLE}

## Status

- Proposed

## Context and Problem Statement

${CONTEXT:-TODO: Describe the context and problem statement.}

$(if [ -n "$DECISION" ]; then
echo "## Decision Outcome"
echo ""
echo "Chosen option: \"$DECISION\""
echo ""
fi)

$(if [ -n "$CONSEQUENCES" ]; then
echo "### Consequences"
echo ""
echo "$CONSEQUENCES"
echo ""
fi)

$(if [ -z "$DECISION" ]; then
echo "<!-- TODO: Add Decision Outcome, Considered Options, and Consequences -->"
fi)
ADR_EOF

echo ""
echo "✅ Created: $FILEPATH"
echo ""
echo "  Next step: add context, decision drivers, considered options, and consequences."
echo "  Then update the ADR index in $README"
echo ""
echo "  git add $FILEPATH"
echo "  git commit -m \"docs: add ADR-${ADDR_NUM_PAD} ${TITLE}\""
