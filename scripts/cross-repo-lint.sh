#!/usr/bin/env bash
# cross-repo-lint.sh — Validate ADR/FS/PLAN consistency across all Tais-Den repos
#
# Checks:
#   1. Agent-Attribution trailer format (FS-0017) across recent commits
#   2. FS/PLAN numbering uniqueness across repos (no collisions)
#   3. README index consistency (all doc files referenced)
#
# Usage:
#   ./scripts/cross-repo-lint.sh
#   CA_REPO_DIRS="/path/to/ca:/path/to/ff:/path/to/pp" ./scripts/cross-repo-lint.sh
#
# Environment:
#   CA_REPO_DIRS  — colon-separated list of repo roots (defaults to heuristics)
#   STRICT_TOOLS  — set to 1 to fail on missing tools (default: 0)
#   COMMIT_RANGE  — git log range for attribution check (default: origin/trunk~20..origin/trunk)
set -euo pipefail

FRAMEWORK_HOME="$(cd "$(dirname "$0")/.." && pwd)"
STRICT_TOOLS="${STRICT_TOOLS:-0}"
COMMIT_RANGE="${COMMIT_RANGE:-origin/trunk~20..origin/trunk}"
DIED=false

err() { echo "FAIL: $*" >&2; DIED=true; }

# ── locate repos ─────────────────────────────────────────────────────────────
if [ -n "${CA_REPO_DIRS:-}" ]; then
  IFS=':' read -ra REPOS <<< "$CA_REPO_DIRS"
else
  # Heuristic: walk up from $FRAMEWORK_HOME to find sibling repos
  PARENT="$(cd "$FRAMEWORK_HOME/.." && pwd)"
  REPOS=()
  for name in conventional-agents feral-fleet pack-protocol; do
    dir="$PARENT/$name"
    [ -d "$dir/.git" ] && REPOS+=("$dir")
  done
  if [ ${#REPOS[@]} -eq 0 ]; then
    # Fallback: try known absolute paths
    for dir in \
      "$HOME/Developer/projects/conventional-agents" \
      "$HOME/Developer/projects/feral-fleet" \
      "$HOME/Developer/projects/pack-protocol"; do
      [ -d "$dir/.git" ] && REPOS+=("$dir")
    done
  fi
fi

if [ ${#REPOS[@]} -eq 0 ]; then
  echo "ERROR: Could not locate any Tais-Den repos. Set CA_REPO_DIRS." >&2
  exit 1
fi

echo "==> cross-repo-lint: ${#REPOS[@]} repos = $(echo "${REPOS[@]}" | sed 's|.*/||g')"
echo ""

# ── check 1: Agent-Attribution format ───────────────────────────────────────
echo "─── check 1: Agent-Attribution trailer format (FS-0017) ───"
ATTRIBUTION_RE='^Agent-Attribution:[[:space:]]*actor=[^;]+;[[:space:]]*model=[^;]+;[[:space:]]*role=[^;]+;[[:space:]]*session=[^;]+$'
TOTAL_BAD=0
for REPO in "${REPOS[@]}"; do
  REPO_NAME="$(basename "$REPO")"
  if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
    echo "  SKIP  $REPO_NAME (not a git repo)"
    continue
  fi
  # Fetch trunk if we can
  git -C "$REPO" fetch origin trunk 2>/dev/null || true
  if ! git -C "$REPO" rev-parse --verify "$COMMIT_RANGE" >/dev/null 2>&1; then
    echo "  SKIP  $REPO_NAME (commit range $COMMIT_RANGE unavailable)"
    continue
  fi
  BAD_COUNT=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    COMMIT_HASH=$(echo "$line" | awk '{print $1}')
    RAW=$(git -C "$REPO" log -1 --format="%(trailers:key=Agent-Attribution,only,separator=%n)" "$COMMIT_HASH" 2>/dev/null | head -1)
    if [ -n "$RAW" ]; then
      if echo "$RAW" | grep -qE 'Hermes Agent\s*\('; then
        BAD_COUNT=$((BAD_COUNT + 1))
        TOTAL_BAD=$((TOTAL_BAD + 1))
        echo "  BAD  $REPO_NAME <$COMMIT_HASH> wrapper format: $RAW"
      elif ! echo "$RAW" | grep -qE "$ATTRIBUTION_RE"; then
        BAD_COUNT=$((BAD_COUNT + 1))
        TOTAL_BAD=$((TOTAL_BAD + 1))
        echo "  BAD  $REPO_NAME <$COMMIT_HASH> wrong format: $RAW"
      fi
    fi
  done < <(git -C "$REPO" log --format="%H %s" "$COMMIT_RANGE" 2>/dev/null)
  if [ "$BAD_COUNT" -eq 0 ]; then echo "  OK   $REPO_NAME (all ${COMMIT_RANGE} commits have correct attribution format)"; fi
done
if [ "$TOTAL_BAD" -gt 0 ]; then
  err "$TOTAL_BAD commit(s) with wrong Agent-Attribution format across repos"
fi
echo ""

# ── check 2: FS/PLAN numbering uniqueness ──────────────────────────────────
echo "─── check 2: FS/PLAN numbering uniqueness across repos ───"
declare -A FS_NUMS PLAN_NUMS
for REPO in "${REPOS[@]}"; do
  REPO_NAME="$(basename "$REPO")"
  for spec_dir in "$REPO/docs/specifications" "$REPO/docs/change-plans"; do
    [ -d "$spec_dir" ] || continue
    for f in "$spec_dir"/FS-*.md "$spec_dir"/PLAN-*.md; do
      [ -f "$f" ] || continue
      BASE=$(basename "$f")
      if echo "$BASE" | grep -qE '^FS-[0-9]+'; then
        NUM=$(echo "$BASE" | sed 's/^FS-0*//;s/-.*//')
        KEY="FS-$NUM"
        if [ -n "${FS_NUMS[$KEY]:-}" ] && [ "${FS_NUMS[$KEY]}" != "$REPO_NAME" ]; then
          err "$KEY claimed by $REPO_NAME and ${FS_NUMS[$KEY]}"
        else
          FS_NUMS[$KEY]="$REPO_NAME"
        fi
      elif echo "$BASE" | grep -qE '^PLAN-[0-9]+'; then
        NUM=$(echo "$BASE" | sed 's/^PLAN-0*//;s/-.*//')
        KEY="PLAN-$NUM"
        if [ -n "${PLAN_NUMS[$KEY]:-}" ] && [ "${PLAN_NUMS[$KEY]}" != "$REPO_NAME" ]; then
          err "$KEY claimed by $REPO_NAME and ${PLAN_NUMS[$KEY]}"
        else
          PLAN_NUMS[$KEY]="$REPO_NAME"
        fi
      fi
    done
  done
done
echo "  FS:  ${#FS_NUMS[@]} unique numbers across repos"
echo "  PLAN: ${#PLAN_NUMS[@]} unique numbers across repos"
if ! $DIED; then echo "  OK   No numbering collisions detected"; fi
echo ""

# ── check 3: README index consistency ───────────────────────────────────────
echo "─── check 3: README index consistency ───"
for REPO in "${REPOS[@]}"; do
  REPO_NAME="$(basename "$REPO")"
  for doc_type in decisions specifications change-plans; do
    dir="$REPO/docs/$doc_type"
    [ -d "$dir" ] || continue
    readme="$dir/README.md"
    [ -f "$readme" ] || continue
    # For each ADR/FS/PLAN doc, check it's mentioned in the README
    for f in "$dir"/*.md; do
      [ -f "$f" ] || continue
      BASE=$(basename "$f")
      [ "$BASE" = "README.md" ] && continue
      ID=$(grep -m1 '^id:' "$f" 2>/dev/null | sed 's/^id:[[:space:]]*//')
      [ -z "$ID" ] && continue
      # Try to find the ID in the README
      if ! grep -qF "$ID" "$readme" 2>/dev/null; then
        # Also try base name (some READMEs reference by filename)
        DOC_ID=$(echo "$BASE" | sed 's/\.md$//')
        if ! grep -qF "$DOC_ID" "$readme" 2>/dev/null; then
          err "$REPO_NAME: $ID ($BASE) has no README index entry in $doc_type/README.md"
        fi
      fi
    done
  done
done
if ! $DIED; then echo "  OK   All docs referenced in README indexes"; fi
echo ""

# ── summary ─────────────────────────────────────────────────────────────────
if $DIED; then
  echo "FAIL: One or more cross-repo lint checks failed." >&2
  exit 1
else
  echo "OK: All cross-repo lint checks passed for ${#REPOS[@]} repos."
fi
