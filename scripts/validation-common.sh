#!/usr/bin/env bash
# Shared helpers for the framework's bounded validation scripts.
# Bash 3.2-compatible: no associative arrays or wait -n.

validation_resolve_repo_root() {
  local resolved
  if [ -n "${CA_TARGET_REPO:-}" ]; then
    resolved="$(cd "$CA_TARGET_REPO" 2>/dev/null && pwd -P)" || resolved=""
    if [ -z "$resolved" ]; then
      echo "ERROR: CA_TARGET_REPO='${CA_TARGET_REPO}' is not a directory." >&2
      return 1
    fi
  else
    resolved="$(git rev-parse --show-toplevel 2>/dev/null)" || resolved=""
    if [ -z "$resolved" ]; then
      echo "ERROR: current directory is not inside a Git repository; set CA_TARGET_REPO." >&2
      return 1
    fi
    resolved="$(cd "$resolved" && pwd -P)"
  fi
  printf '%s\n' "$resolved"
}

validation_normalize_positive_integer() {
  local raw="$1" value
  case "$raw" in
    ''|*[!0-9]*) return 1 ;;
  esac
  value=$((10#$raw))
  [ "$value" -gt 0 ] || return 1
  printf '%s\n' "$value"
}

validation_terminate_pid() {
  local pid="$1" grouped="$2"
  if [ "$grouped" -eq 1 ]; then
    kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
    sleep 1
    kill -KILL -- "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
  else
    kill -TERM "$pid" 2>/dev/null || true
    sleep 1
    kill -KILL "$pid" 2>/dev/null || true
  fi
}

# Run one command with a wall-clock limit. GNU timeout/gtimeout are preferred;
# the shell fallback uses a dedicated process group when setsid is available.
# A timeout is reported as status 124 so callers can distinguish it from a
# command's own failure.
validation_run_with_timeout() {
  local limit="$1"
  shift
  local seconds
  seconds="$(validation_normalize_positive_integer "$limit")" || {
    echo "ERROR: invalid timeout '$limit'" >&2
    return 2
  }

  if command -v timeout >/dev/null 2>&1; then
    timeout --kill-after=5 "$seconds" "$@"
    return $?
  fi
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout --kill-after=5 "$seconds" "$@"
    return $?
  fi

  local pid grouped=0 started elapsed
  if command -v setsid >/dev/null 2>&1; then
    setsid "$@" &
    pid=$!
    grouped=1
  else
    "$@" &
    pid=$!
  fi
  started=$SECONDS
  while kill -0 "$pid" 2>/dev/null; do
    elapsed=$((SECONDS - started))
    if [ "$elapsed" -ge "$seconds" ]; then
      echo "TIMEOUT: command exceeded ${seconds}s" >&2
      validation_terminate_pid "$pid" "$grouped"
      wait "$pid" 2>/dev/null || true
      return 124
    fi
    sleep 1
  done
  wait "$pid"
}
