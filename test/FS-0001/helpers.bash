repo_root() {
  git rev-parse --show-toplevel
}

assert_file_exists() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "expected file to exist: $path"
    return 1
  fi
}

assert_dir_exists() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    echo "expected directory to exist: $path"
    return 1
  fi
}

assert_files_equal() {
  local left="$1"
  local right="$2"
  diff -u "$left" "$right" >/dev/null
}

assert_file_contains() {
  local path="$1"
  local pattern="$2"
  # Use fixed-string matching so callers can pass patterns that include regex
  # metacharacters (e.g., "ADR-*.md") without having to escape them.
  if ! rg -F -n -- "$pattern" "$path" >/dev/null 2>&1; then
    echo "expected $path to contain pattern: $pattern"
    return 1
  fi
}
