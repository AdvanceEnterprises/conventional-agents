#!/usr/bin/env bash
# cross-repo-lint.sh — Validate ADR/FS/PLAN consistency across sibling repos
#
# Checks:
#   1. Agent-Attribution trailer format (FS-0017) across recent commits
#   2. README index consistency (all doc files referenced)
#   3. FS/PLAN numbering validity within each repo (no duplicate IDs)
#   4. Post-boundary cron attribution requires terminal mode=autonomous
#      and emits a digest line summarizing cron-attribution coverage.
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
#   COMMIT_RANGE     — git log range for attribution check. The range must already
#                      exist locally; this script never fetches a remote.
#   CRON_ATTRIBUTION_BOUNDARY — ISO-8601 UTC timestamp or epoch seconds. Cron
#                      commits at or before the boundary are grandfathered.
#                      Default: 2026-10-03T00:00:00Z (the adoption boundary).
#   CRON_AGENT_EMAILS — space-separated unattended actor emails. Empty by
#                      default; set explicitly to enable attribution checks.
#   CA_SKIP_ATTRIBUTION — set to 1 to skip the attribution check entirely
#                      when the allowlists are unconfigured; the run reports
#                      SKIP, never "enforced".
set -euo pipefail

FRAMEWORK_HOME="$(cd "$(dirname "$0")/.." && pwd)"
STRICT_TOOLS="${STRICT_TOOLS:-0}"
COMMIT_RANGE="${COMMIT_RANGE:-}"
CRON_ATTRIBUTION_BOUNDARY="${CRON_ATTRIBUTION_BOUNDARY:-2026-10-03T00:00:00Z}"
DIED=false

err() { echo "FAIL: $*" >&2; DIED=true; }
info() { echo "  $*"; }

# ── tool check ────────────────────────────────────────────────────────────────
# Only enforce tool presence when STRICT_TOOLS=1 (default: warn and continue).
# The list covers every command the script uses, including coreutils used
# mid-run (head, sort, uniq, tr, basename, awk, sed, grep).
if [ "$STRICT_TOOLS" = "1" ]; then
  for _tool in git grep sed awk basename head sort uniq tr date; do
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
  # governance stack this script lints. The sibling-name set is empty by
  # default — a caller names its layout explicitly via CA_SIBLING_NAMES
  # (space-separated), or points at the target with CA_REPO_DIRS /
  # CA_TARGET_REPO. The unconfigured heuristic resolves nothing.
  PARENT="$(cd "$FRAMEWORK_HOME/.." && pwd)"
  for _name in ${CA_SIBLING_NAMES:-}; do
    _dir="$PARENT/$_name"
    [ -d "$_dir/.git" ] && REPOS+=("$_dir")
  done
fi

if [ ${#REPOS[@]} -eq 0 ]; then
  echo "ERROR: Could not locate any repos. Set CA_REPO_DIRS or CA_TARGET_REPO, or name siblings via CA_SIBLING_NAMES." >&2
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

# Convert the configured cron adoption boundary to epoch seconds. Accepting
# epoch seconds keeps the check portable on systems whose `date` implementations
# disagree about ISO-8601 parsing; the documented/default form remains UTC ISO.
_parse_cron_boundary() {
  local value="$1" parsed=""
  if printf '%s\n' "$value" | grep -qE '^[0-9]+$'; then
    printf '%s\n' "$value"
    return 0
  fi
  if ! printf '%s\n' "$value" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'; then
    return 1
  fi
  # GNU/coreutils date (Linux) first.
  parsed="$(date -u -d "$value" +%s 2>/dev/null || true)"
  if [ -z "$parsed" ]; then
    # BSD date (macOS) fallback for the documented UTC form.
    parsed="$(date -ju -f '%Y-%m-%dT%H:%M:%SZ' "$value" +%s 2>/dev/null || true)"
  fi
  if printf '%s\n' "$parsed" | grep -qE '^[0-9]+$'; then
    printf '%s\n' "$parsed"
    return 0
  fi
  return 1
}

if ! CRON_BOUNDARY_EPOCH="$(_parse_cron_boundary "$CRON_ATTRIBUTION_BOUNDARY")"; then
  echo "ERROR: invalid CRON_ATTRIBUTION_BOUNDARY '$CRON_ATTRIBUTION_BOUNDARY' — use ISO-8601 UTC (YYYY-MM-DDTHH:MM:SSZ) or epoch seconds" >&2
  exit 1
fi

# ── check 1: Agent-Attribution format ───────────────────────────────────────
echo "─── check 1: Agent-Attribution trailer format (FS-0017) ───"
# FS-0017: actor name is freeform (may contain parentheses, e.g.
# "Hermes Agent (cron)"); ADR-0021 adds a terminal `; mode=autonomous`
# field for unattended actors. The structural regex accepts both; the
# boundary-aware rule below makes it mandatory for post-boundary cron commits.
ATTRIBUTION_RE='^Agent-Attribution:[[:space:]]*actor=[^;]+;[[:space:]]*model=[^;]+;[[:space:]]*role=[^;]+;[[:space:]]*session=[^;]+(;[[:space:]]*mode=[^;]+)?$'
# Body-scan pattern for the MALFORMED diagnosis (#154). A commit whose
# trailer-parser result is empty is MALFORMED only when the message body
# genuinely carries the canonical trailer — this pattern recognises that
# shape. It MUST stay a strict prefix of ATTRIBUTION_RE's required-key
# sequence: if a key is ever added ahead of `actor=` in ATTRIBUTION_RE,
# update this pattern too, or MALFORMED commits silently re-classify as
# MISSING (the wrong remedy). The #170 review pinned this contract.
BODY_TRAILER_RE='^Agent-Attribution:[[:space:]]*actor='
# Actor emails that must carry an Agent-Attribution trailer. Empty by
# default: each instance configures its own actor aliases explicitly via
# AGENT_EMAILS (and CRON_AGENT_EMAILS for unattended actors), and a
# consumer adopts the pattern with its own addresses. Review-posting
# identities never author commits and are deliberately absent. An
# attribution run with both lists empty fails closed (FS-0047 SC-9) —
# set them, or opt out explicitly with CA_SKIP_ATTRIBUTION=1.
AGENT_EMAILS="${AGENT_EMAILS:-}"
# The cron list is separate from the general agent allowlist because the
# semantic rule is conditional on actor identity. It is independently
# overridable for consumers that use a different unattended address.
CRON_AGENT_EMAILS="${CRON_AGENT_EMAILS:-}"
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

  # Resolve default branch and commit range. The validation surface is
  # hermetic: callers must prepare any remote refs before invoking this script.
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

  # Resolve the RANGE itself, not its two endpoints (issue #194). `git rev-parse
  # --verify` accepts a single rev, and the null object hash resolves as one —
  # but `git rev-list "<null>..HEAD"` errors, so an endpoint-wise check passed
  # while the audit loop iterated zero commits and printed OK; that is exactly
  # the shape GitHub produces for `github.event.before` on a new-branch push.
  # `rev-list` parses the whole range, and — unlike rev-parse — needs no output
  # to succeed: `--max-count=1` bounds the walk, and an empty-but-resolvable
  # range (A == B) still exits 0 with no commits, auditing nothing as the
  # caller declared.
  if ! git -C "$REPO" rev-list --max-count=1 "$RANGE" >/dev/null 2>&1; then
    err "$REPO_NAME: commit range $RANGE is unavailable locally — it does not resolve in this checkout; fetch or prepare the refs, or correct the range, before running cross-repo lint"
    continue
  fi

  BAD_COUNT=0
  MISSING_COUNT=0
  MALFORMED_COUNT=0
  # Cron-attribution counters partition the audited set exactly:
  #   audited = missing mode=autonomous + unreadable timestamp
  #             + grandfathered + ok
  # CRON_BAD_COUNT is derived from the two failure buckets after the scan (see
  # below) so the digest can never disagree with the per-commit BAD lines.
  CRON_MISSING_COUNT=0
  CRON_UNREADABLE_COUNT=0
  CRON_GRANDFATHERED_COUNT=0
  CRON_AUDITED_COUNT=0
  if [ -z "${AGENT_EMAILS}${CRON_AGENT_EMAILS}" ]; then
    if [ "${CA_SKIP_ATTRIBUTION:-0}" = "1" ]; then
      echo "  SKIP  $REPO_NAME (attribution unconfigured; CA_SKIP_ATTRIBUTION=1 — cron boundary not enforced)"
      continue
    fi
    err "$REPO_NAME: AGENT_EMAILS and CRON_AGENT_EMAILS are empty — attribution checks cannot run; set them explicitly, or set CA_SKIP_ATTRIBUTION=1 to skip"
    continue
  fi
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    COMMIT_HASH=$(echo "$line" | awk '{print $1}')
    AUTHOR_EMAIL=$(git -C "$REPO" log -1 --format="%ae" "$COMMIT_HASH" 2>/dev/null)
    RAW=$(git -C "$REPO" log -1 --format="%(trailers:key=Agent-Attribution,only,separator=%n)" "$COMMIT_HASH" 2>/dev/null | head -1)
    COMMIT_EPOCH=$(git -C "$REPO" log -1 --format="%ct" "$COMMIT_HASH" 2>/dev/null)

    # Check if this commit is agent-authored
    _is_agent=false
    for _ae in $AGENT_EMAILS $CRON_AGENT_EMAILS; do
      [ "$AUTHOR_EMAIL" = "$_ae" ] && _is_agent=true && break
    done
    _is_cron=false
    for _ce in $CRON_AGENT_EMAILS; do
      [ "$AUTHOR_EMAIL" = "$_ce" ] && _is_cron=true && break
    done
    if $_is_cron; then
      CRON_AUDITED_COUNT=$((CRON_AUDITED_COUNT + 1))
    fi

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
        if $_is_cron; then
          # A cron commit with no trailer, or with one git's parser cannot
          # reach, cannot end in the terminal marker: it fails the same rule
          # the digest summarizes. Count it in the missing bucket so no
          # failing cron commit hides in the implied "ok" remainder.
          CRON_MISSING_COUNT=$((CRON_MISSING_COUNT + 1))
        fi
      fi
    elif ! echo "$RAW" | grep -qE "$ATTRIBUTION_RE"; then
      BAD_COUNT=$((BAD_COUNT + 1))
      TOTAL_BAD=$((TOTAL_BAD + 1))
      echo "  BAD  $REPO_NAME <$COMMIT_HASH> wrong format: $RAW"
    fi

    # ADR-0021 is conditional by actor, not by the generic trailer grammar:
    # cron identities after the adoption boundary must end in the autonomous
    # marker. Equality is intentionally grandfathered so a boundary can be
    # pinned to an exact commit timestamp without an off-by-one surprise.
    # The timestamp comparison uses committer time (%ct) deliberately: the
    # audit checks the commit as landed in this repository, and a rebase that
    # moves a commit across the boundary should be re-evaluated there.
    if $_is_cron && [ -n "$RAW" ]; then
      if ! printf '%s\n' "$COMMIT_EPOCH" | grep -qE '^[0-9]+$'; then
        # Fail closed: a cron commit whose timestamp cannot be read must not
        # be silently grandfathered by a failed `[` comparison (issue #144
        # review; the comparison below is numeric and needs a validated value).
        # This is its own bucket: the marker was never evaluated, so reporting
        # it as "missing mode=autonomous" would misdescribe a commit that
        # carries the marker (issue #254 review).
        CRON_UNREADABLE_COUNT=$((CRON_UNREADABLE_COUNT + 1))
        TOTAL_BAD=$((TOTAL_BAD + 1))
        echo "  BAD  $REPO_NAME <$COMMIT_HASH> cron attribution timestamp unreadable (empty committer time) — cannot evaluate the boundary (boundary: $CRON_ATTRIBUTION_BOUNDARY)"
      elif [ "$COMMIT_EPOCH" -gt "$CRON_BOUNDARY_EPOCH" ]; then
        if ! echo "$RAW" | grep -qE ';[[:space:]]*mode=autonomous$'; then
          CRON_MISSING_COUNT=$((CRON_MISSING_COUNT + 1))
          TOTAL_BAD=$((TOTAL_BAD + 1))
          echo "  BAD  $REPO_NAME <$COMMIT_HASH> cron attribution missing terminal mode=autonomous (boundary: $CRON_ATTRIBUTION_BOUNDARY)"
        fi
      else
        CRON_GRANDFATHERED_COUNT=$((CRON_GRANDFATHERED_COUNT + 1))
        echo "  INFO $REPO_NAME <$COMMIT_HASH> cron attribution grandfathered (commit timestamp: $COMMIT_EPOCH; boundary: $CRON_ATTRIBUTION_BOUNDARY)"
      fi
    fi
  done < <(git -C "$REPO" log --format="%H %s" "$RANGE" 2>/dev/null)
  # Derived once from the two failure buckets — never incremented independently
  # — so `audited = missing + unreadable + grandfathered + ok` is exact.
  CRON_BAD_COUNT=$((CRON_MISSING_COUNT + CRON_UNREADABLE_COUNT))
  _cron_suffix="cron boundary enforced"
  [ -z "$CRON_AGENT_EMAILS" ] && _cron_suffix="cron boundary NOT configured (CRON_AGENT_EMAILS empty)"
  if [ "$BAD_COUNT" -eq 0 ] && [ "$MISSING_COUNT" -eq 0 ] && [ "$MALFORMED_COUNT" -eq 0 ] && [ "$CRON_BAD_COUNT" -eq 0 ]; then
    echo "  OK   $REPO_NAME (all $RANGE commits have correct attribution format; $_cron_suffix)"
  fi
  # Issue #187 digest: one line summarizing cron-attribution coverage so the
  # audit result is not buried in per-commit grandfathered INFO lines. The four
  # counts partition the audited set exactly:
  #   audited = missing mode=autonomous + unreadable timestamp
  #             + grandfathered + ok
  # `missing mode=autonomous` covers every commit whose trailer was evaluated
  # and lacks the terminal marker, plus cron commits with no trailer at all or
  # one git's parser cannot reach. `unreadable timestamp` covers the fail-closed
  # case where the marker could not be evaluated — a distinct fault, so it gets
  # its own bucket rather than inflating the missing count.
  if [ -n "$CRON_AGENT_EMAILS" ]; then
    echo "  DIGEST $REPO_NAME: cron attribution — $CRON_AUDITED_COUNT audited, $CRON_MISSING_COUNT missing mode=autonomous, $CRON_UNREADABLE_COUNT unreadable timestamp, $CRON_GRANDFATHERED_COUNT grandfathered (boundary: $CRON_ATTRIBUTION_BOUNDARY)"
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
