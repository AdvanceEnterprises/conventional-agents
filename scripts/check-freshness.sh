#!/usr/bin/env bash
# check-freshness.sh — workflow/guideline doc freshness gate for conventional-agents.
#
# Rule 1 (hard — exit non-zero): every governed doc under `workflows/` and
#   `guidelines/` must carry an `updated:` front-matter field. Freshness cannot
#   be measured on a doc that does not say when it was last touched, and without
#   the field the maintenance tick's staleness check silently no-ops on these
#   directories (7/7 workflow docs and 10/10 guideline docs lacked it as of
#   2026-08-29, FS-0027).
#
# Rule 2 (soft — printed, exit 0): a doc whose `updated:` date is older than
#   90 days is reported as a staleness candidate for a human or the maintenance
#   tick to refresh. Deliberately non-fatal: a stale guideline is more dangerous
#   flagged than deleted, and failing CI on every old doc would force mass
#   rewrites of content that may still be accurate.
#
# Scope: `workflows/*.md` and `guidelines/**/*.md` (recursive — bash/JS/Python
#   subdirectories), excluding `**/README.md` index files, which are navigation
#   aids rather than governed docs.
#
# Bash 3.2 compatible (macOS default) — no associative arrays.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

STALE_DAYS="${DOC_STALE_DAYS:-90}"
case "$STALE_DAYS" in
  ''|[!0-9]*)
    echo "ERROR: DOC_STALE_DAYS must be a non-negative integer (got '$STALE_DAYS')" >&2
    exit 1
    ;;
esac

errors=0

fail() {
  echo "ERROR: $*" >&2
  errors=$((errors + 1))
}

# Extract one YAML front-matter field from a file. Empty if absent.
# Only reads the block between the first two `---` lines, so an `updated:`
# appearing in prose cannot be mistaken for the field. Tolerates inline YAML
# comments and surrounding quotes: `updated: "2026-07-13" # refresh` yields
# `2026-07-13`.
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

# Seconds since epoch for a YYYY-MM-DD date. Empty if unparseable.
date_epoch() {
  local d="$1"
  case "$d" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      date -j -f "%Y-%m-%d" "$d" "+%s" 2>/dev/null || date -d "$d" "+%s" 2>/dev/null || return 1
      ;;
    *)
      return 1
      ;;
  esac
}

now_epoch() {
  date +%s
}

# Collect governed docs, excluding README index files.
docs=()
while IFS= read -r f; do
  [[ "$f" == */README.md ]] && continue
  docs+=("$f")
done < <(find workflows guidelines -type f -name '*.md' | sort)

if [ "${#docs[@]}" -eq 0 ]; then
  echo "check-freshness: no governed docs found under workflows/ or guidelines/"
  exit 0
fi

now="$(now_epoch)"

for f in "${docs[@]}"; do
  updated="$(front_matter_field "$f" "updated")"
  if [ -z "$updated" ]; then
    fail "$f has no 'updated:' field in front matter — freshness cannot be measured"
    continue
  fi
  epoch="$(date_epoch "$updated" || true)"
  if [ -z "$epoch" ]; then
    fail "$f has unparseable 'updated:' date '$updated' (expected YYYY-MM-DD)"
    continue
  fi
  age_days=$(( (now - epoch) / 86400 ))
  if [ "$age_days" -gt "$STALE_DAYS" ]; then
    echo "STALE: $f — updated: $updated ($age_days days old, threshold ${STALE_DAYS}d)"
  fi
done

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "check-freshness: $errors doc(s) missing or invalid 'updated:' front matter." >&2
  echo "Add 'updated: YYYY-MM-DD' to the front-matter block of each file." >&2
  exit 1
fi

echo "check-freshness: OK — all governed docs under workflows/ and guidelines/ carry updated:"
