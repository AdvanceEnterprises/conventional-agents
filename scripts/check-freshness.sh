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
# Target: the resolved root must be a git work tree (issue #199). A directory
#   git disclaims is a hard error — the empty-corpus branch would otherwise
#   certify a run that checked nothing (the #194 fail-open class, one script
#   over). A work tree with no governed docs keeps the empty-corpus message.
#
# Bash 3.2 compatible (macOS default) — no associative arrays.
set -euo pipefail

# FRAMEWORK_HOME is where this script physically lives — the script's own copy
# of itself. It is a self-locator, not a target-resolver: every caller outside
# this repository invokes a vendored copy whose own location is never the
# repository being checked (FS-0024/ADR-0033).
FRAMEWORK_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# REPO_ROOT is what this run checks — the git repository containing the caller's
# working directory, per FS-0024/ADR-0033. `npm run check:freshness`, every CI
# job in lint-docs.yml, and every bats suite that invokes this script all run
# with their working directory at the repository they mean to check, so this
# resolves identically to the old self-location for every invocation this
# repository makes of itself. A vendored copy invoked from a host repository's
# root now resolves to the host's root instead of the submodule's. CA_TARGET_REPO
# overrides both, for a caller whose working directory is not inside the
# repository it means to check. Canonicalized via `cd ... && pwd`; a
# CA_TARGET_REPO that is not a real directory fails loudly rather than silently
# falling back.
if [ -n "${CA_TARGET_REPO:-}" ]; then
  REPO_ROOT="$(cd "$CA_TARGET_REPO" 2>/dev/null && pwd)"
  if [ -z "$REPO_ROOT" ]; then
    echo "ERROR: CA_TARGET_REPO='$CA_TARGET_REPO' is not a directory." >&2
    exit 1
  fi
else
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
cd "$REPO_ROOT"

# The resolved root must be a git work tree (issue #199). The `|| pwd` fallback
# above covers a caller inside a work tree whose top-level resolution needed it;
# outside one it resolves to a directory that is not a repository at all — both
# governed directories then "don't exist", and the empty-corpus branch below
# would print its message and exit 0 for a run that checked nothing (the #194
# fail-open class, one script over). A git work tree that genuinely has no
# workflows/ or guidelines/ — a fresh consumer repository mid-adoption — keeps
# the empty-corpus message; the guard only rejects directories git disclaims.
if [ "$(git -C "$REPO_ROOT" rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
  echo "ERROR: '$REPO_ROOT' is not inside a git working tree." >&2
  echo "       Run this script from within the repository it should check, or set" >&2
  echo "       CA_TARGET_REPO to that repository's working tree. (issue #199)" >&2
  exit 1
fi

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
# Platform-tested branch rather than an inline `||` chain: on a host where
# neither `date -j` (BSD/macOS) nor GNU `date -d` works, the chain would
# silently return empty; the explicit branch makes the failure mode visible.
# The GNU branch pins `00:00:00 UTC` so `date -d "2026-02-08"` cannot be
# interpreted as timezone-relative on any host.
date_epoch() {
  local d="$1" epoch
  case "$d" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      if epoch="$(date -j -f "%Y-%m-%d" "$d" "+%s" 2>/dev/null)"; then
        printf '%s\n' "$epoch"
      elif epoch="$(date -d "$d 00:00:00 UTC" "+%s" 2>/dev/null)"; then
        printf '%s\n' "$epoch"
      else
        return 1
      fi
      ;;
    *)
      return 1
      ;;
  esac
}

# Current time in epoch seconds. DOC_FRESHNESS_NOW overrides the system clock so
# tests can pin the evaluation date and stay deterministic (the stale-count
# assertions depend on how many docs have crossed the threshold).
now_epoch() {
  printf '%s\n' "${DOC_FRESHNESS_NOW:-$(date +%s)}"
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
