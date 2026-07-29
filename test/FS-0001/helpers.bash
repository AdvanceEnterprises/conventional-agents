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
  # A missing file is a different failure from a missing pattern, and saying so
  # saves the reader from grepping a file that is not there.
  #
  # -r, not -f: callers pass process substitutions (`<(echo "$submodules")`), which
  # are /dev/fd entries rather than regular files. Readability is the property that
  # actually matters here.
  if [[ ! -r "$path" ]]; then
    echo "expected file to exist (checking for pattern: $pattern): $path"
    return 1
  fi
  # grep -F, not rg. Fixed-string matching so callers can pass patterns containing
  # regex metacharacters (e.g. "ADR-*.md") without escaping them — but via grep,
  # which is POSIX and present everywhere.
  #
  # This used `rg -F -n -- ... >/dev/null 2>&1`. ripgrep is not installed on stock
  # GitHub Actions runners, and the redirect swallowed the "command not found"
  # error, so a missing binary was indistinguishable from a missing pattern. Every
  # assertion in the suite failed on CI claiming files did not contain strings they
  # plainly contained. Do not reintroduce a dependency on a non-POSIX tool here.
  if ! grep -F -q -- "$pattern" "$path"; then
    echo "expected $path to contain pattern: $pattern"
    return 1
  fi
}
