#!/usr/bin/env bash
# check-delivery-status.sh — report governed FS/PLAN pairs whose implementation
# surface appears shipped while their documents remain non-terminal.
#
# This is conservative and report-only. It uses tracked local files and Git
# history only; it never changes statuses, files, indexes, or CHANGELOG.md.
# Bash 3.2 compatible — no associative arrays.
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
Usage: check-delivery-status.sh [--help]

Report non-terminal FS/primary-PLAN pairs whose declared implementation surface
has complete post-created: Git evidence, required tests, and required CHANGELOG
evidence. The command is report-only.

Exit codes:
  0  no delivery candidates; incomplete/documentation-only pairs are skipped
  1  one or more delivered-but-non-terminal pairs were reported
  2  history, metadata, or repository evidence was unavailable

The audit is offline and never edits the worktree. It requires a full-history
Git checkout when an eligible implementation surface is evaluated.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    *) echo "ERROR: unknown option '$1'; use --help." >&2; exit 2 ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: 'git' was not found on PATH — delivery evidence requires git." >&2
  exit 2
fi
if [ "$(git -C "$REPO_ROOT" rev-parse --is-inside-work-tree 2>/dev/null || true)" != "true" ]; then
  echo "ERROR: '$REPO_ROOT' is not inside a Git working tree." >&2
  echo "       Run from the repository to audit or set CA_TARGET_REPO." >&2
  exit 2
fi

get_field() {
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

get_list_field() {
  local file="$1" field="$2"
  awk -v field="$field" '
    /^---[[:space:]]*$/ { n++; if (n == 2) exit; next }
    n == 1 && $0 ~ "^[[:space:]]*" field ":" {
      in_field=1
      line=$0
      sub("^[[:space:]]*" field "[[:space:]]*:[[:space:]]*", "", line)
      if (line ~ /^\[/) {
        sub(/^\[/, "", line); sub(/\][[:space:]]*$/, "", line)
        gsub(/[[:space:]]*,[[:space:]]*/, "\n", line)
        gsub(/["'"'"']/, "", line)
        if (line != "") print line
        in_field=0
      }
      next
    }
    n == 1 && in_field && /^[[:space:]]*-[[:space:]]/ {
      value=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^["'"'"']|["'"'"']$/, "", value)
      if (value != "") print value
      next
    }
    n == 1 && in_field && /^[[:space:]]*$/ { next }
    n == 1 && in_field && !/^[[:space:]]/ { in_field=0 }
  ' "$file"
}

get_related_specs() {
  get_list_field "$1" related_specs
}

get_id_from_path() {
  local file="$1"
  basename "$file" | sed -nE 's/^(FS|PLAN)-([0-9][0-9][0-9][0-9])(-.*)?\.md$/\1-\2/p'
}

is_terminal_status() {
  case "$1" in
    implemented|deprecated|superseded) return 0 ;;
    *) return 1 ;;
  esac
}

is_excluded_path() {
  case "$1" in
    docs/*|CHANGELOG.md|README.md|*/README.md) return 0 ;;
    *) return 1 ;;
  esac
}

# Global outputs from qualifying_commit; avoids a pipeline subshell so this is
# portable to Bash 3.2.
QUALIFY_SHA=""
QUALIFY_DATE=""
qualifying_commit() {
  local path="$1" created="$2" history sha commit_date
  QUALIFY_SHA=""
  QUALIFY_DATE=""
  if ! history="$(git log --no-merges --format='%H%x09%cs' -- "$path" 2>/dev/null)"; then
    return 2
  fi
  while IFS="$(printf '\t')" read -r sha commit_date; do
    [ -n "$sha" ] || continue
    if [[ "$commit_date" == "$created" || "$commit_date" > "$created" ]]; then
      QUALIFY_SHA="$sha"
      QUALIFY_DATE="$commit_date"
      return 0
    fi
  done <<< "$history"
  return 1
}

changelog_or_commit_marker() {
  local fs_id="$1" plan_id="$2" created="$3" sha commit_date message history
  if [ -f CHANGELOG.md ] && (grep -F -q -- "$fs_id" CHANGELOG.md || grep -F -q -- "$plan_id" CHANGELOG.md); then
    printf 'CHANGELOG.md\n'
    return 0
  fi
  if ! history="$(git log --no-merges --format='%H%x09%as' -- "${evidence_paths[@]}" 2>/dev/null)"; then
    return 2
  fi
  while IFS="$(printf '\t')" read -r sha commit_date; do
    [ -n "$sha" ] || continue
    [[ "$commit_date" == "$created" || "$commit_date" > "$created" ]] || continue
    message="$(git show -s --format='%B' "$sha" 2>/dev/null || true)"
    if printf '%s\n' "$message" | grep -F -q -- "$fs_id" ||
       printf '%s\n' "$message" | grep -F -q -- "$plan_id"; then
      printf 'commit:%s\n' "$sha"
      return 0
    fi
  done <<< "$history"
  return 1
}

has_exported_interface() {
  local interface
  while IFS= read -r interface; do
    case "$interface" in
      scripts/*|.github/*|package.json|workflows/*|guidelines/*|skills/*|templates/*|roles/*|integrations/*|runbooks/*|AGENTS.md|INTEGRATION.md)
        return 0
        ;;
    esac
  done <<< "$1"
  return 1
}

fs_files=()
while IFS= read -r fs_file; do
  [ -f "$fs_file" ] && fs_files+=("$fs_file")
done < <(git ls-files -- 'docs/specifications/FS-*.md' | sort)
plan_files=()
while IFS= read -r plan_file; do
  [ -f "$plan_file" ] && plan_files+=("$plan_file")
done < <(git ls-files -- 'docs/change-plans/PLAN-*.md' | sort)

if [ "${#plan_files[@]}" -eq 0 ]; then
  echo "check-delivery-status: no tracked PLAN documents found"
  exit 0
fi

is_shallow="$(git rev-parse --is-shallow-repository 2>/dev/null || printf 'unknown')"
reported=0
unavailable=0
eligible=0

for plan_file in "${plan_files[@]}"; do
  plan_id="$(get_field "$plan_file" id)"
  plan_status="$(get_field "$plan_file" status)"
  primary_fs="$(get_related_specs "$plan_file" | head -1 | tr -d '[:space:]')"
  [ -n "$plan_id" ] && [ -n "$primary_fs" ] || continue

  fs_file=""
  for candidate in "${fs_files[@]}"; do
    [ "$(get_field "$candidate" id)" = "$primary_fs" ] || continue
    fs_file="$candidate"
    break
  done
  if [ -z "$fs_file" ]; then
    echo "ERROR: $plan_id references missing primary FS $primary_fs." >&2
    unavailable=$((unavailable + 1))
    continue
  fi

  fs_status="$(get_field "$fs_file" status)"
  if is_terminal_status "$fs_status" && is_terminal_status "$plan_status"; then
    continue
  fi
  eligible=$((eligible + 1))

  created="$(get_field "$plan_file" created)"
  if ! [[ "$created" =~ ^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$ ]]; then
    echo "ERROR: unavailable delivery history for $primary_fs/$plan_id — invalid created: '$created'." >&2
    unavailable=$((unavailable + 1))
    continue
  fi

  touches="$(get_list_field "$plan_file" touches)"
  implementation_paths=()
  unresolved_touch=false
  while IFS= read -r touch; do
    [ -n "$touch" ] || continue
    is_excluded_path "$touch" && continue
    expanded_matches="$(git ls-files -- "$touch")"
    if [ -z "$expanded_matches" ]; then
      unresolved_touch=true
      continue
    fi
    while IFS= read -r expanded; do
      [ -n "$expanded" ] || continue
      is_excluded_path "$expanded" && continue
      already=false
      for existing in "${implementation_paths[@]}"; do
        [ "$existing" = "$expanded" ] && already=true
      done
      [ "$already" = false ] && implementation_paths+=("$expanded")
    done < <(git ls-files -- "$touch")
  done <<< "$touches"

  if [ "$unresolved_touch" = true ]; then
    echo "INFO: SKIP $primary_fs/$plan_id — an implementation-surface touch does not resolve in the tracked current tree"
    continue
  fi

  if [ "${#implementation_paths[@]}" -eq 0 ]; then
    echo "INFO: SKIP $primary_fs/$plan_id — no implementation surface after documentation exclusions"
    continue
  fi

  if [ "$is_shallow" = "true" ]; then
    echo "ERROR: unavailable delivery history for $primary_fs/$plan_id — checkout is shallow; evidence paths cannot be evaluated:" >&2
    for path in "${implementation_paths[@]}"; do echo "  $path" >&2; done
    unavailable=$((unavailable + 1))
    continue
  elif [ "$is_shallow" = "unknown" ]; then
    echo "ERROR: unavailable delivery history for $primary_fs/$plan_id — Git cannot determine shallow state." >&2
    unavailable=$((unavailable + 1))
    continue
  fi

  complete=true
  evidence_shas=()
  evidence_paths=()
  evidence_dates=()
  for path in "${implementation_paths[@]}"; do
    if qualifying_commit "$path" "$created"; then
      evidence_paths+=("$path")
      evidence_shas+=("$QUALIFY_SHA")
      evidence_dates+=("$QUALIFY_DATE")
    else
      rc=$?
      if [ "$rc" -eq 2 ]; then
        echo "ERROR: unavailable delivery history for $primary_fs/$plan_id — cannot read history for $path." >&2
        unavailable=$((unavailable + 1))
      else
        echo "INFO: SKIP $primary_fs/$plan_id — no post-$created history for $path"
      fi
      complete=false
    fi
  done
  [ "$complete" = true ] || continue

  fs_test_required="$(get_field "$fs_file" test_required)"
  if [ "$fs_test_required" = true ]; then
    test_files=()
    while IFS= read -r test_file; do
      [ -n "$test_file" ] && test_files+=("$test_file")
    done < <(git ls-files -- "test/$primary_fs" | grep -E '\.(bats|sh|py|js|ts|yaml|yml)$' || true)
    if [ "${#test_files[@]}" -eq 0 ]; then
      echo "INFO: SKIP $primary_fs/$plan_id — test_required=true but test/$primary_fs/ has no tracked test file"
      continue
    fi
    test_has_history=false
    test_history_unavailable=false
    for test_file in "${test_files[@]}"; do
      if qualifying_commit "$test_file" "$created"; then
        test_has_history=true
        break
      elif [ "$?" -eq 2 ]; then
        test_history_unavailable=true
      fi
    done
    if [ "$test_history_unavailable" = true ]; then
      echo "ERROR: unavailable delivery history for $primary_fs/$plan_id — cannot read history for a required test path." >&2
      unavailable=$((unavailable + 1))
      continue
    fi
    if [ "$test_has_history" != true ]; then
      echo "INFO: SKIP $primary_fs/$plan_id — required test suite has no post-$created history"
      continue
    fi
  fi

  interfaces="$(get_list_field "$fs_file" interfaces)"
  if has_exported_interface "$interfaces"; then
    changelog_marker=""
    if changelog_marker="$(changelog_or_commit_marker "$primary_fs" "$plan_id" "$created")"; then
      :
    else
      rc=$?
      if [ "$rc" -eq 2 ]; then
        echo "ERROR: unavailable delivery history for $primary_fs/$plan_id — cannot inspect implementation commit messages." >&2
        unavailable=$((unavailable + 1))
      else
        echo "INFO: SKIP $primary_fs/$plan_id — exported surface lacks CHANGELOG or implementation-commit marker"
      fi
      continue
    fi
  else
    changelog_marker="not-required"
  fi

  echo "DRIFT: $primary_fs / $plan_id — FS status=$fs_status, PLAN status=$plan_status"
  echo "  evidence: implementation surface has post-$created history"
  for index in "${!evidence_paths[@]}"; do
    echo "  path: ${evidence_paths[$index]} — commit ${evidence_shas[$index]} (${evidence_dates[$index]})"
  done
  echo "  changelog evidence: $changelog_marker"
  if [ "$fs_test_required" = true ]; then
    echo "  test evidence: test/$primary_fs/ has tracked post-$created history"
  else
    echo "  test evidence: not required"
  fi
  echo "  remediation: human review should reconcile the FS/PLAN status after confirming completeness."
  reported=$((reported + 1))
done

if [ "$unavailable" -gt 0 ]; then
  echo "check-delivery-status: unavailable evidence for $unavailable pair/path evaluation(s)." >&2
  exit 2
fi
if [ "$reported" -gt 0 ]; then
  echo "check-delivery-status: $reported delivery candidate(s) require human reconciliation." >&2
  exit 1
fi
if [ "$eligible" -eq 0 ]; then
  echo "check-delivery-status: no non-terminal FS/primary-PLAN pairs eligible for delivery audit"
else
  echo "check-delivery-status: OK — no delivered-but-non-terminal pairs"
fi
exit 0
