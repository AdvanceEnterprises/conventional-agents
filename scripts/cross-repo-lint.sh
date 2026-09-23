#!/usr/bin/env bash
# cross-repo-lint.sh — Validate ADR/FS/PLAN consistency across sibling repos
#
# Checks:
#   1. Agent-Attribution trailer format (FS-0017) across recent commits
#   2. README index consistency (all doc files referenced)
#   3. FS/PLAN numbering validity within each repo (no duplicate IDs)
#
# Bash 3.2+ compatible (no associative arrays).
#
# Usage:
#   ./scripts/cross-repo-lint.sh                    # heuristic repo discovery
#   CA_REPO_DIRS="/path/to/ca:/path/to/ff:/path/to/pp" ./scripts/cross-repo-lint.sh
#   CA_TARGET_REPO="/path/to/ca" ./scripts/cross-repo-lint.sh   # single repo
#
# Environment:
#   CA_REPO_DIRS     — colon-separated list of repo roots (defaults to heuristics)
#   CA_TARGET_REPO   — single repo path override (takes precedence over CA_REPO_DIRS)
#   STRICT_TOOLS     — set to 1 to fail on missing tools (default: 0)
#   COMMIT_RANGE     — git log range for attribution check (default: origin/trunk~20..origin/trunk)
set -euo pipefail

FRAMEWORK_HOME="$(cd "$(dirname "$0")/.." && pwd)"
STRICT_TOOLS="${STRICT_TOOLS:-0}"
COMMIT_RANGE="${COMMIT_RANGE:-}"
DIED=false

err() { echo "FAIL: $*" >&2; DIED=true; }
info() { echo "  $*"; }

# ── tool check ────────────────────────────────────────────────────────────────
# Only enforce tool presence when STRICT_TOOLS=1 (default: warn and continue).
# The list covers every command the script uses, including coreutils used
# mid-run (head, sort, uniq, tr, basename, awk, sed, grep).
if [ "$STRICT_TOOLS" = "1" ]; then
  for _tool in git grep sed awk basename head sort uniq tr; do
    if ! command -v "$_tool" >/dev/null 2>&1; then
      echo "ERROR: required tool '$_tool' not found" >&2
      exit 1
    fi
  done
fi

# ── locate repos ─────────────────────────────────────────────────────────────
REPOS=()
if [ -n "${CA_TARGET_REPO:-}" ]; then
  [ -d "$CA_TARGET_REPO/.git" ] && REPOS=("$CA_TARGET_REPO")
elif [ -n "${CA_REPO_DIRS:-}" ]; then
  IFS=':' read -ra _repos <<< "$CA_REPO_DIRS"
  for _r in "${_repos[@]}"; do
    [ -d "$_r/.git" ] && REPOS+=("$_r")
  done
else
  # Heuristic: walk up from $FRAMEWORK_HOME to find sibling repos of the
  # governance stack this script lints. Override the stack with
  # CA_SIBLING_NAMES (space-separated) for other layouts.
  PARENT="$(cd "$FRAMEWORK_HOME/.." && pwd)"
  for _name in ${CA_SIBLING_NAMES:-conventional-agents feral-fleet pack-protocol}; do
    _dir="$PARENT/$_name"
    [ -d "$_dir/.git" ] && REPOS+=("$_dir")
  done
fi

if [ ${#REPOS[@]} -eq 0 ]; then
  echo "ERROR: Could not locate any repos. Set CA_REPO_DIRS or CA_TARGET_REPO." >&2
  exit 1
fi

# Print repo names using basename
_repo_names=""
for _r in "${REPOS[@]}"; do
  [ -n "$_repo_names" ] && _repo_names="$_repo_names, "
  _repo_names="$_repo_names$(basename "$_r")"
done
echo "==> cross-repo-lint: ${#REPOS[@]} repos = $_repo_names"
echo ""

# ── helper: resolve default branch ───────────────────────────────────────────
_resolve_default_branch() {
  local repo="$1"
  local result
  # origin/HEAD symbolic-ref returns e.g. "refs/remotes/origin/trunk"; strip to bare name
  result="$(git -C "$repo" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)" || result=""
  result="${result##refs/remotes/origin/}"
  if [ -z "$result" ]; then
    # Try common branch names
    for _try in trunk main master; do
      if git -C "$repo" rev-parse --verify "origin/$_try" >/dev/null 2>&1; then
        result="$_try"
        break
      fi
    done
  fi
  echo "${result:-trunk}"
}

# ── check 1: Agent-Attribution format ───────────────────────────────────────
echo "─── check 1: Agent-Attribution trailer format (FS-0017) ───"
# FS-0017: actor name is freeform (may contain parentheses, e.g.
# "Hermes Agent (cron)"); ADR-0021 adds an optional `; mode=autonomous`
# field for unattended actors. The structural regex accepts both.
ATTRIBUTION_RE='^Agent-Attribution:[[:space:]]*actor=[^;]+;[[:space:]]*model=[^;]+;[[:space:]]*role=[^;]+;[[:space:]]*session=[^;]+(;[[:space:]]*mode=[^;]+)?$'
# Body-scan pattern for the MALFORMED diagnosis (#154). A commit whose
# trailer-parser result is empty is MALFORMED only when the message body
# genuinely carries the canonical trailer — this pattern recognises that
# shape. It MUST stay a strict prefix of ATTRIBUTION_RE's required-key
# sequence: if a key is ever added ahead of `actor=` in ATTRIBUTION_RE,
# update this pattern too, or MALFORMED commits silently re-classify as
# MISSING (the wrong remedy). The #170 review pinned this contract.
BODY_TRAILER_RE='^Agent-Attribution:[[:space:]]*actor='
# Known agent emails that must carry an Agent-Attribution trailer.
# Must stay in sync with the actor table in workflows/git-and-gh-conventions.md
# and the allowlist in test/FS-0017/commit-attribution.bats.
# Overridable via AGENT_EMAILS for adopting repos with different actors.
# Note: kimi-code-review@tais-den.dev is deliberately absent — Kimi K2.7
# reviews are comment-only (posted under the authenticated user), so that
# address never authors commits.
AGENT_EMAILS="${AGENT_EMAILS:-hermes-agent@tais-den.dev hermes-cron@tais-den.dev codex@tais-den.dev codex-cron@tais-den.dev claude-code@tais-den.dev github.marten@fwd.mtnden.org}"
# Floor for the anchored attribution audit (parity with
# ATTRIBUTION_MIN_ANCHOR in test/FS-0017/commit-attribution.bats): the
# audited range never shrinks below this boundary even if a release tag is
# moved/deleted. Only applies when the floor resolves in the linted repo —
# untagged consumer repos fall back to their ~20 window.
ATTRIBUTION_MIN_ANCHOR="${ATTRIBUTION_MIN_ANCHOR:-v2.1.0}"
TOTAL_BAD=0
for REPO in "${REPOS[@]}"; do
  REPO_NAME="$(basename "$REPO")"
  if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
    echo "  SKIP  $REPO_NAME (not a git repo)"
    continue
  fi

  # Resolve default branch and commit range
  DEFAULT_BRANCH="$(_resolve_default_branch "$REPO")"
  # Anchored audit (work item #141): the default range starts at the OLDER
  # of the newest v*-tagged release reachable from the default branch and
  # the ATTRIBUTION_MIN_ANCHOR floor (when it resolves in this repo) — a
  # missing trailer outside a fixed ~20-commit window can no longer pass,
  # and a moved/deleted tag cannot silently shrink the audited set.
  # `--first-parent` keeps the tag anchor deterministic on the release line.
  # Repos without release tags or a resolvable floor fall back to the
  # ~20 window. On pull_request, CI overrides COMMIT_RANGE to the PR's own
  # commits (see lint-docs.yml).
  if [ -n "${COMMIT_RANGE:-}" ]; then
    RANGE="$COMMIT_RANGE"
  else
    _anchor="$(git -C "$REPO" describe --first-parent --tags --match 'v*' --abbrev=0 "origin/$DEFAULT_BRANCH" 2>/dev/null || true)"
    _floor=""
    if [ -n "$ATTRIBUTION_MIN_ANCHOR" ] && git -C "$REPO" rev-parse --verify --quiet "$ATTRIBUTION_MIN_ANCHOR" >/dev/null 2>&1; then
      _floor="$ATTRIBUTION_MIN_ANCHOR"
    fi
    if [ -n "$_anchor" ] && [ -n "$_floor" ]; then
      if git -C "$REPO" merge-base --is-ancestor "$_anchor" "$_floor"; then
        RANGE="$_anchor..origin/$DEFAULT_BRANCH"
      else
        RANGE="$_floor..origin/$DEFAULT_BRANCH"
      fi
    elif [ -n "$_anchor" ]; then
      RANGE="$_anchor..origin/$DEFAULT_BRANCH"
    elif [ -n "$_floor" ]; then
      RANGE="$_floor..origin/$DEFAULT_BRANCH"
    else
      RANGE="origin/$DEFAULT_BRANCH~20..origin/$DEFAULT_BRANCH"
    fi
  fi

  # Fetch default branch if we can
  git -C "$REPO" fetch origin "$DEFAULT_BRANCH" 2>/dev/null || true

  # Test range endpoints separately (git rev-parse --verify only accepts single revs)
  RANGE_START="${RANGE%..*}"
  RANGE_END="${RANGE##*..}"
  if ! git -C "$REPO" rev-parse --verify "$RANGE_START" >/dev/null 2>&1 || \
     ! git -C "$REPO" rev-parse --verify "$RANGE_END" >/dev/null 2>&1; then
    echo "  SKIP  $REPO_NAME (commit range $RANGE unavailable)"
    continue
  fi

  BAD_COUNT=0
  MISSING_COUNT=0
  MALFORMED_COUNT=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    COMMIT_HASH=$(echo "$line" | awk '{print $1}')
    AUTHOR_EMAIL=$(git -C "$REPO" log -1 --format="%ae" "$COMMIT_HASH" 2>/dev/null)
    RAW=$(git -C "$REPO" log -1 --format="%(trailers:key=Agent-Attribution,only,separator=%n)" "$COMMIT_HASH" 2>/dev/null | head -1)

    # Check if this commit is agent-authored
    _is_agent=false
    for _ae in $AGENT_EMAILS; do
      [ "$AUTHOR_EMAIL" = "$_ae" ] && _is_agent=true && break
    done

    if [ -z "$RAW" ]; then
      # In-scope offenders so far were all reported as "missing". Two distinct
      # failure modes hide behind that word, and they need opposite responses:
      # a commit that genuinely lacks the trailer needs it written; a commit
      # whose trailer is syntactically present but unreachable by git's trailer
      # parser needs it MOVED — the two confirmed shapes are a trailer
      # displaced by a following paragraph, and a value wrapped across a
      # continuation line. Body-scan separates them.
      # The failing set is unchanged — only the diagnosis differs (issue #154).
      # The scan matches the canonical trailer shape — the `actor=` key directly
      # following the token — so a typo'd or unrelated line (`Agent-Attribution :`,
      # lowercase, missing actor key) is still reported MISSING: the remedy there
      # is still "write it". Only a line that IS the canonical trailer but that
      # git's parser cannot reach is MALFORMED: the remedy is "move it".
      if $_is_agent; then
        if git -C "$REPO" log -1 --format=%B "$COMMIT_HASH" 2>/dev/null | grep -qE "$BODY_TRAILER_RE"; then
          MALFORMED_COUNT=$((MALFORMED_COUNT + 1))
          TOTAL_BAD=$((TOTAL_BAD + 1))
          echo "  BAD  $REPO_NAME <$COMMIT_HASH> malformed Agent-Attribution trailer (present in the message body but unreachable by git's trailer parser — displaced by a following paragraph, or wrapped across lines)"
        else
          MISSING_COUNT=$((MISSING_COUNT + 1))
          TOTAL_BAD=$((TOTAL_BAD + 1))
          echo "  BAD  $REPO_NAME <$COMMIT_HASH> missing Agent-Attribution trailer (agent-authored: $AUTHOR_EMAIL)"
        fi
      fi
    elif ! echo "$RAW" | grep -qE "$ATTRIBUTION_RE"; then
      BAD_COUNT=$((BAD_COUNT + 1))
      TOTAL_BAD=$((TOTAL_BAD + 1))
      echo "  BAD  $REPO_NAME <$COMMIT_HASH> wrong format: $RAW"
    fi
  done < <(git -C "$REPO" log --format="%H %s" "$RANGE" 2>/dev/null)
  if [ "$BAD_COUNT" -eq 0 ] && [ "$MISSING_COUNT" -eq 0 ] && [ "$MALFORMED_COUNT" -eq 0 ]; then
    echo "  OK   $REPO_NAME (all $RANGE commits have correct attribution format)"
  fi
done
if [ "$TOTAL_BAD" -gt 0 ]; then
  err "$TOTAL_BAD commit(s) with agent-attribution issues across repos"
fi
echo ""

# ── check 2: README index consistency ───────────────────────────────────────
echo "─── check 2: README index consistency ───"
for REPO in "${REPOS[@]}"; do
  REPO_NAME="$(basename "$REPO")"
  for doc_type in decisions specifications change-plans; do
    dir="$REPO/docs/$doc_type"
    [ -d "$dir" ] || continue
    readme="$dir/README.md"
    [ -f "$readme" ] || continue
    for f in "$dir"/*.md; do
      [ -f "$f" ] || continue
      BASE=$(basename "$f")
      [ "$BASE" = "README.md" ] && continue
      # Extract ID from frontmatter (between --- delimiters)
      ID=$(awk '/^---$/{f=1; next} f&&/^---$/{exit} f&&/^id:/{print $2; exit}' "$f" 2>/dev/null)
      [ -z "$ID" ] && continue
      if ! grep -qF "$ID" "$readme" 2>/dev/null; then
        DOC_ID="${BASE%.md}"
        if ! grep -qF "$DOC_ID" "$readme" 2>/dev/null; then
          err "$REPO_NAME: $ID ($BASE) has no README index entry in $doc_type/README.md"
        fi
      fi
    done
  done
done
if ! $DIED; then echo "  OK   All docs referenced in README indexes"; fi
echo ""

# ── check 3: FS/PLAN numbering validity within each repo (no duplicates) ────
echo "─── check 3: FS/PLAN numbering validity within each repo (no duplicates) ───"
UNIQUE_OK=true
for REPO in "${REPOS[@]}"; do
  REPO_NAME="$(basename "$REPO")"
  for spec_dir in "$REPO/docs/specifications" "$REPO/docs/change-plans"; do
    [ -d "$spec_dir" ] || continue
    for f in "$spec_dir"/FS-*.md "$spec_dir"/PLAN-*.md; do
      [ -f "$f" ] || continue
      [ -f "$f" ] || continue
      BASE=$(basename "$f")
      _is_fs=false; _is_plan=false
      echo "$BASE" | grep -qE '^FS-[0-9]+' && _is_fs=true
      echo "$BASE" | grep -qE '^PLAN-[0-9]+' && _is_plan=true
      $_is_fs || $_is_plan || continue

      # Extract the ID prefix from filename (with original zero-padding)
      _fn_id="$(echo "$BASE" | sed -n 's/^\(FS-[0-9][0-9]*\|PLAN-[0-9][0-9]*\).*$/\1/p')"
      [ -z "$_fn_id" ] && continue

      # Check frontmatter id: field matches filename ID
      _fm_id=$(awk '/^---$/{f=1; next} f&&/^---$/{exit} f&&/^id:/{print $2; exit}' "$f" 2>/dev/null)
      if [ -n "$_fm_id" ] && [ "$_fm_id" != "$_fn_id" ]; then
        err "$REPO_NAME: $BASE has frontmatter id: $_fm_id but filename suggests $_fn_id"
      fi
    done
  done
done
# Check for intra-repo collisions using sort/uniq (Bash 3.2 compatible)
for REPO in "${REPOS[@]}"; do
  REPO_NAME="$(basename "$REPO")"
  for spec_dir in "$REPO/docs/specifications" "$REPO/docs/change-plans"; do
    [ -d "$spec_dir" ] || continue
    _collisions=$(for f in "$spec_dir"/FS-*.md "$spec_dir"/PLAN-*.md; do
      [ -f "$f" ] || continue
      BASE=$(basename "$f")
      echo "$BASE" | grep -qE '^(FS|PLAN)-[0-9]+' || continue
      # Extract just the FS-#### / PLAN-#### prefix so FS-0017-foo.md and
      # FS-0017-bar.md collide correctly.
      echo "$BASE" | sed -n 's/^\(FS-[0-9][0-9]*\|PLAN-[0-9][0-9]*\).*$/\1/p'
    done | sort | uniq -d)
    if [ -n "$_collisions" ]; then
      err "$REPO_NAME: duplicate IDs in $spec_dir: $(echo "$_collisions" | tr '\n' ' ')"
      UNIQUE_OK=false
    fi
  done
done
if $UNIQUE_OK && ! $DIED; then echo "  OK   No duplicate IDs within repos"; fi
echo ""

# ── summary ─────────────────────────────────────────────────────────────────
if $DIED; then
  echo "FAIL: One or more cross-repo lint checks failed." >&2
  exit 1
else
  echo "OK: All cross-repo lint checks passed for ${#REPOS[@]} repos."
fi
