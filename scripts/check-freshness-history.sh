#!/usr/bin/env bash
# check-freshness-history.sh — compare freshness metadata with Git history.
#
# This is a companion to check-freshness.sh, not a replacement. It considers
# only tracked Markdown under workflows/ and guidelines/ (README indexes are
# excluded), ignores merge commits, and treats commits that change only the
# freshness metadata lines as diagnostics. It never fetches or edits anything.
# Bash 3.2 compatible — no associative arrays.
set -euo pipefail

FRAMEWORK_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -n "${CA_TARGET_REPO:-}" ]; then
  if ! REPO_ROOT="$(cd "$CA_TARGET_REPO" 2>/dev/null && pwd)"; then
    echo "ERROR: CA_TARGET_REPO='$CA_TARGET_REPO' is not a directory." >&2
    exit 2
  fi
else
  if ! REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    echo "ERROR: cannot resolve a Git worktree; run from a repository or set CA_TARGET_REPO." >&2
    exit 2
  fi
fi
cd "$REPO_ROOT"

usage() {
  cat <<'EOF'
Usage: check-freshness-history.sh [--strict] [--help]

Compare workflows/ and guidelines/ updated: dates with the latest non-merge
Git commit that changes document content outside freshness metadata.

Modes:
  diagnostic (default)  report substantive drift but exit 0
  --strict              report drift and exit 1

Exit codes:
  0  no substantive drift (metadata-only commits remain diagnostics)
  1  --strict found substantive drift
  2  unavailable history, invalid input, or a non-Git working tree

The command is read-only and never fetches or edits the worktree. A full-history
checkout is required; repair a shallow checkout in the caller before retrying.
EOF
}

strict=false
while (( $# > 0 )); do
  case "$1" in
    --strict) strict=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERROR: unknown option '$1'; use --help." >&2; exit 2 ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: 'git' was not found on PATH — history comparison requires git." >&2
  exit 2
fi
if [ "$(git -C "$REPO_ROOT" rev-parse --is-inside-work-tree 2>/dev/null || true)" != "true" ]; then
  echo "ERROR: '$REPO_ROOT' is not inside a Git working tree." >&2
  echo "       Run from the repository to audit or set CA_TARGET_REPO." >&2
  exit 2
fi

front_matter_field() {
  local file="$1" field="$2"
  awk -v f="$field" '
    /^---[[:space:]]*$/ { n++; if (n == 2) exit; next }
    n == 1 && $0 ~ "^[[:space:]]*" f ":" {
      sub("^[[:space:]]*" f "[[:space:]]*:[[:space:]]*", "")
      sub(/[[:space:]]+#.*$/, "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      gsub(/^["'"'"']|["'"'"']$/, "")
      print
      exit
    }
  ' "$file"
}

date_epoch() {
  local value="$1" epoch
  case "$value" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      if epoch="$(date -j -f "%Y-%m-%d" "$value" "+%s" 2>/dev/null)"; then
        printf '%s\n' "$epoch"
      elif epoch="$(date -d "$value 00:00:00 UTC" "+%s" 2>/dev/null)"; then
        printf '%s\n' "$epoch"
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}

# Remove fields that are explicitly freshness metadata from a front-matter
# comparison. The current contract uses updated:, while the two review aliases
# are accepted for consumers that declare them in their own metadata.
without_freshness_metadata() {
  awk '
    /^---[[:space:]]*$/ { n++; next }
    n == 1 && $0 ~ /^[[:space:]]*(updated|last_reviewed|freshness_checked)[[:space:]]*:/ { next }
    { print }
  ' | awk '
    BEGIN { leading=1 }
    leading && /^[[:space:]]*$/ { next }
    { leading=0; print }
  '
}

# Return 0 when the commit changed only freshness metadata for this path.
metadata_only_commit() {
  local sha="$1" file="$2" before="$3" after="$4"
  : > "$before"
  : > "$after"
  if ! git show "${sha}^:${file}" > "$before" 2>/dev/null; then
    return 1
  fi
  if ! git show "${sha}:${file}" > "$after" 2>/dev/null; then
    return 1
  fi
  if ! without_freshness_metadata < "$before" | diff -u - <(without_freshness_metadata < "$after") >/dev/null; then
    return 1
  fi
  return 0
}

# Git history evidence is an explicit output contract: no empty history may be
# silently interpreted as "clean".
docs=()
while IFS= read -r file; do
  case "$file" in
    */README.md) continue ;;
    workflows/*.md|guidelines/*.md) docs+=("$file") ;;
  esac
done < <(git ls-files -- workflows guidelines)

if [ "${#docs[@]}" -eq 0 ]; then
  echo "check-freshness-history: no tracked governed docs found under workflows/ or guidelines/"
  exit 0
fi

is_shallow="$(git -C "$REPO_ROOT" rev-parse --is-shallow-repository 2>/dev/null || printf 'unknown')"
if [ "$is_shallow" = "true" ]; then
  for file in "${docs[@]}"; do
    echo "ERROR: unavailable history for $file — checkout is shallow." >&2
  done
  echo "       Fetch full history in the caller and retry; this script never fetches." >&2
  exit 2
elif [ "$is_shallow" = "unknown" ]; then
  for file in "${docs[@]}"; do
    echo "ERROR: unavailable history for $file — Git cannot determine shallow-repository state." >&2
  done
  exit 2
fi

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/ca-freshness-history.XXXXXX")"
trap 'rm -rf "$tmp_root"' EXIT

substantive_findings=0
unavailable_findings=0

for file in "${docs[@]}"; do
  declared="$(front_matter_field "$file" "updated")"
  if [ -z "$declared" ]; then
    echo "ERROR: unavailable history comparison for $file — no parseable updated: field." >&2
    unavailable_findings=$((unavailable_findings + 1))
    continue
  fi
  if ! date_epoch "$declared" >/dev/null; then
    echo "ERROR: unavailable history comparison for $file — updated: '$declared' is not YYYY-MM-DD." >&2
    unavailable_findings=$((unavailable_findings + 1))
    continue
  fi

  history="$(git log --follow --no-merges --format='%H%x09%as' -- "$file" 2>/dev/null || true)"
  if [ -z "$history" ]; then
    echo "ERROR: unavailable history for $file — no reachable non-merge commits." >&2
    unavailable_findings=$((unavailable_findings + 1))
    continue
  fi

  before="$tmp_root/before"
  after="$tmp_root/after"
  latest_sha=""
  latest_epoch=""
  while IFS="$(printf '\t')" read -r sha commit_date; do
    [ -n "$sha" ] || continue
    if metadata_only_commit "$sha" "$file" "$before" "$after"; then
      if [[ "$commit_date" > "$declared" ]]; then
        echo "DIAGNOSTIC: $file — commit $sha changed freshness metadata only; excluded from substantive history"
      fi
      continue
    fi
    latest_sha="$sha"
    latest_date="$commit_date"
    break
  done <<< "$history"

  if [ -z "$latest_sha" ]; then
    echo "ERROR: unavailable history for $file — no reachable substantive commit." >&2
    unavailable_findings=$((unavailable_findings + 1))
    continue
  fi

  if [[ "$latest_date" > "$declared" ]]; then
    echo "DRIFT: $file — updated: $declared; latest substantive commit $latest_sha ($latest_date) is newer" >&2
    substantive_findings=$((substantive_findings + 1))
  fi
done

if [ "$unavailable_findings" -gt 0 ]; then
  echo "check-freshness-history: unavailable history for $unavailable_findings document(s)." >&2
  exit 2
fi
if [ "$strict" = true ] && [ "$substantive_findings" -gt 0 ]; then
  echo "check-freshness-history: $substantive_findings substantive freshness finding(s)." >&2
  exit 1
fi
if [ "$substantive_findings" -gt 0 ]; then
  echo "check-freshness-history: $substantive_findings substantive freshness finding(s) (diagnostic mode)"
else
  echo "check-freshness-history: OK — no substantive freshness drift"
fi
exit 0
