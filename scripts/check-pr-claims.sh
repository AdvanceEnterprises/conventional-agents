#!/usr/bin/env bash
# check-pr-claims.sh — detect duplicate FS/PLAN/ADR claims across open PRs.
#
# A local Category 1 gate that invokes the read-only GitHub binding audit
# in strict mode. The binding enumerates open pull requests (drafts included),
# extracts governed IDs from changed files, and reports:
#   - same ID claimed under different paths across open PRs
#   - an open PR claiming an ID that already exists on the default branch
#     under a different path
#   - sibling PRs citing a retired ID after an open governed-document rename
#
# This script is a thin wrapper so the detection logic stays in one place
# (integrations/github/bin/gh-pr-claim-audit.sh) while the gate surface lives
# under scripts/ with the rest of the Category 1 gates.
#
# Requires a GitHub CLI token with read access to the target repository.
# Bash 3.2 compatible: no associative arrays.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT="$SCRIPT_DIR/../integrations/github/bin/gh-pr-claim-audit.sh"

usage() {
  cat <<'EOF'
Usage: check-pr-claims.sh [OPTIONS]

Detect duplicate FS/PLAN/ADR ID claims across the repository's open pull
requests. Wraps integrations/github/bin/gh-pr-claim-audit.sh in strict mode.

Options:
  --repository OWNER/NAME   Target repository; overrides CA_GITHUB_REPOSITORY
  --target PATH             Caller repository path; overrides CA_TARGET_REPO
  --help                    Show this help message

Environment:
  CA_GITHUB_REPOSITORY      Target repository owner/name override
  CA_TARGET_REPO            Caller repository path override
  GH_TOKEN / GITHUB_TOKEN   GitHub CLI authentication

Exit codes:
  0  no duplicate claims detected
  1  one or more duplicate/colliding claims detected
  2  usage, authentication, repository, or GitHub API failure
EOF
}

# Forward the same options the underlying audit accepts, plus --help.
args=()
while (( $# > 0 )); do
  case "$1" in
    --repository)
      (( $# >= 2 )) || { echo "ERROR: --repository requires owner/name." >&2; exit 2; }
      args+=("$1" "$2")
      shift 2
      ;;
    --repository=*)
      args+=("$1")
      shift
      ;;
    --target)
      (( $# >= 2 )) || { echo "ERROR: --target requires a path." >&2; exit 2; }
      args+=("$1" "$2")
      shift 2
      ;;
    --target=*)
      args+=("$1")
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option '$1'; use --help for usage." >&2
      exit 2
      ;;
  esac
done

if [ ! -x "$AUDIT" ]; then
  echo "ERROR: cannot find the claim audit binding at '$AUDIT'." >&2
  exit 2
fi

exec bash "$AUDIT" --strict "${args[@]}"
