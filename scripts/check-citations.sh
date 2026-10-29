#!/usr/bin/env bash
# check-citations.sh — resolve FS/PLAN/ADR citations inside governed documents.
#
# Scans the repository's own governed documents for citations of
# FS-NNNN / PLAN-NNNN / ADR-NNNN tokens and fails when a cited ID does not
# resolve to a document in the repository's own registries.
#
# Governance: optional detection-only tooling — NOT a Category 1 gate. ADR-0015
# reserves Category 1 for scripts wired into CI as a failing check; this one is
# referenced by no workflow, is not run by `npm run validate`, and blocks
# nothing (ADR-0024's detection-over-prevention posture). Specified by FS-0058
# and implemented under PLAN-0063. This is the local, offline layer. Cross-PR
# stale-citation drift is handled by FS-0040 / integrations/github/bin/gh-pr-claim-audit.sh.
set -euo pipefail

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
Usage: check-citations.sh [OPTIONS]

Resolve FS-/PLAN-/ADR- citations inside the repository's own governed
registries. Exits non-zero when a cited ID does not resolve to an existing
document in docs/specifications/, docs/change-plans/, or docs/decisions/.

Options:
  --help              Show this help message and exit.
  --exempt ID[,ID]    Comma- or space-separated list of IDs to treat as
                      resolved even when no matching document exists.
                      Combines with CA_CITATION_EXEMPT.

Environment:
  CA_TARGET_REPO      Path to the repository to check (default: caller's
                      Git worktree).
  CA_CITATION_EXEMPT  Comma- or space-separated IDs exempted from resolution.

Exit codes:
  0  all cited governed IDs resolve in the local registries
  1  one or more citations do not resolve
  2  invalid input (including an exemption token that is not FS-NNNN,
     PLAN-NNNN, or ADR-NNNN) or missing repository
EOF
}

# Both exemption sources accept a comma- or space-separated list (FS-0058
# Interfaces). Commas are normalized to spaces up front so the environment and
# command-line forms behave identically.
EXEMPT_LIST="${CA_CITATION_EXEMPT:-}"
EXEMPT_LIST="${EXEMPT_LIST//,/ }"

while (( $# > 0 )); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --exempt)
      (( $# >= 2 )) || { echo "ERROR: --exempt requires a value." >&2; exit 2; }
      EXEMPT_LIST="$EXEMPT_LIST ${2//,/ }"
      shift 2
      ;;
    --exempt=*)
      EXEMPT_LIST="$EXEMPT_LIST ${1#*=}"
      EXEMPT_LIST="${EXEMPT_LIST//,/ }"
      shift
      ;;
    *)
      echo "ERROR: unknown option '$1'; use --help for usage." >&2
      exit 2
      ;;
  esac
done

# Normalized exemption set: one ID per line, sorted uniquely.
#
# Validation is explicit and fatal: an exemption token that is not a governed
# ID is caller error — exit 2 with a diagnostic naming the token, never a
# silent abort. The normalization below is a plain loop on purpose: filtering
# through `grep -E ... | sort -u` returns 1 when nothing matches, and under
# `set -euo pipefail` that assignment failure kills the script before the
# citation scan at the bottom ever runs, producing exit 1 with no output.
EXEMPT_NORMALIZED=""
if [ -n "$EXEMPT_LIST" ]; then
  # No pathname expansion on the caller's raw tokens: `--exempt '*'` must be
  # rejected as an invalid token, not expanded into the current directory.
  set -f
  for exempt_token in $EXEMPT_LIST; do
    case "$exempt_token" in
      FS-[0-9][0-9][0-9][0-9]|PLAN-[0-9][0-9][0-9][0-9]|ADR-[0-9][0-9][0-9][0-9])
        EXEMPT_NORMALIZED="${EXEMPT_NORMALIZED}${exempt_token}
"
        ;;
      *)
        echo "ERROR: invalid exemption '$exempt_token' — expected FS-NNNN, PLAN-NNNN, or ADR-NNNN." >&2
        echo "       Run with --help for usage." >&2
        exit 2
        ;;
    esac
  done
  set +f
  EXEMPT_NORMALIZED="$(printf '%s' "$EXEMPT_NORMALIZED" | sort -u)"
fi

# A token is in the exemption list when it appears in the normalized set.
is_exempt() {
  local id="$1"
  if [ -z "$EXEMPT_NORMALIZED" ]; then
    return 1
  fi
  case $'\n'"$EXEMPT_NORMALIZED"$'\n' in
    *$'\n'"$id"$'\n'*) return 0 ;;
    *) return 1 ;;
  esac
}

# Build a registry of governed IDs. For each registry directory we accept the
# front-matter id: when present, otherwise derive from the filename token.
# Either way, the filename must live in the correct directory for its type.
register_ids() {
  local dir="$1" prefix="$2"
  local file id
  for file in "$dir"/"$prefix"-*.md; do
    [ -f "$file" ] || continue
    id=""
    if [ -r "$file" ]; then
      id="$(sed -nE 's/^id:[[:space:]]*"?([A-Z]+-[0-9][0-9][0-9][0-9])"?.*/\1/p' "$file" | head -n 1 || true)"
    fi
    if [ -z "$id" ]; then
      id="$(basename "$file" | sed -nE 's/^([A-Z]+-[0-9][0-9][0-9][0-9])(-[^/]*)?\.md$/\1/p')"
    fi
    [ -n "$id" ] && printf '%s\n' "$id"
  done
}

REGISTRY_FILE="$(mktemp)"
trap 'rm -f "$REGISTRY_FILE"' EXIT

{
  register_ids "$REPO_ROOT/docs/specifications" "FS"
  register_ids "$REPO_ROOT/docs/change-plans" "PLAN"
  register_ids "$REPO_ROOT/docs/decisions" "ADR"
} | sort -u > "$REGISTRY_FILE"

if [ ! -s "$REGISTRY_FILE" ]; then
  echo "ERROR: no governed IDs found in the local registries." >&2
  exit 2
fi

# Scan the governed corpus for citations: every markdown file at the top level
# of the three registry directories (FS/PLAN/ADR documents plus their index
# READMEs) and docs/operations/ARC42.md when present. Nothing else is scanned —
# the legacy hand-curated docs/ARC42.md carries no `id:` front matter and is not
# governed, and markdown elsewhere in the tree is out of scope for this gate.
# Point CA_TARGET_REPO at another repository to check that one instead.
status=0
UNRESOLVED_FILE="$(mktemp)"
trap 'rm -f "$REGISTRY_FILE" "$UNRESOLVED_FILE"' EXIT

scan_files() {
  # Prefer ripgrep when available; fall back to grep for portability.
  if command -v rg >/dev/null 2>&1; then
    rg --no-heading --with-filename --only-matching -e '\b(FS|PLAN|ADR)-[0-9][0-9][0-9][0-9]\b' "$@" 2>/dev/null || true
  else
    local f
    for f in "$@"; do
      [ -f "$f" ] || continue
      grep -H -o -E '\b(FS|PLAN|ADR)-[0-9][0-9][0-9][0-9]\b' "$f" 2>/dev/null || true
    done
  fi
}

SCAN_TARGETS=(
  "$REPO_ROOT/docs/specifications"
  "$REPO_ROOT/docs/change-plans"
  "$REPO_ROOT/docs/decisions"
)

# Build a list of actual files, including READMEs and any .md under the
# three registry directories.
SCAN_FILES=()
for target in "${SCAN_TARGETS[@]}"; do
  [ -d "$target" ] || continue
  while IFS= read -r f; do
    [ -n "$f" ] && SCAN_FILES+=("$f")
  done < <(find "$target" -maxdepth 1 -type f -name '*.md' | sort)
done

# Also include docs/operations/ARC42.md if it exists — it is governed and
# cross-references decisions and specs.
if [ -f "$REPO_ROOT/docs/operations/ARC42.md" ]; then
  SCAN_FILES+=("$REPO_ROOT/docs/operations/ARC42.md")
fi

if [ "${#SCAN_FILES[@]}" -eq 0 ]; then
  echo "ERROR: no governed documents to scan." >&2
  exit 2
fi

scan_files "${SCAN_FILES[@]}" | sort -u > "$UNRESOLVED_FILE"

# Every citation token that is not in the registry and not exempt is a finding.
# One pass, one process: all registry IDs into a flat word list.
REGISTRY_SET=" $(grep -E '^[A-Z]+-[0-9][0-9][0-9][0-9]$' "$REGISTRY_FILE" | sort -u | tr '\n' ' ') "
while IFS=':' read -r file token; do
  [ -n "$file" ] || continue
  [ -n "$token" ] || continue
  if is_exempt "$token"; then
    continue
  fi
  case "$REGISTRY_SET" in
    *" $token "*) ;;
    *)
      if [ "$status" -eq 0 ]; then
        echo "ERROR: unresolved governed-ID citation(s) found:"
      fi
      echo "  $file: $token"
      status=1
      ;;
  esac
done < "$UNRESOLVED_FILE"

if [ "$status" -eq 0 ]; then
  echo "OK: all governed-ID citations resolve in the local registries."
fi

exit "$status"
