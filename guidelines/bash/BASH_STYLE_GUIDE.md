# Bash Style and Documentation Guide

This document provides guidance for writing clear, maintainable Bash scripts with consistent style and documentation. It emphasizes clarity over brevity and follows shell best practices.

**Decision precedence:**
1. Project style
2. Guidelines in this document
3. Community conventions (Google Shell Style, shellcheck recommendations)

---

## Voice and Tone

* Be clear and direct
* Use imperative when describing what the script does: "Start the pod", "Run migrations"
* Avoid jargon; explain technical terms
* Be consistent with terminology used in the project

---

## Comments and Inline Documentation

### File header comment

Every script should begin with a comment explaining its purpose:

```bash
#!/usr/bin/env bash
# pod-up: Start the pod with all services
#
# This script orchestrates the complete pod startup sequence:
# 1. Create pod
# 2. Start Postgres, Redis, Nginx
# 3. Wait for dependencies
# 4. Run migrations
# 5. Start app and worker
#
# Usage:
#   ENV=dev ops/scripts/pod-up
#
# Environment variables:
#   ENV  - Environment: dev, test, or prod

set -euo pipefail
```

### Section comments

Use section headers to divide logical parts of the script:

```bash
# ============================================================================
# Phase 1: Initialization
# ============================================================================

# Load environment
# ============================================================================
```

### Inline comments

Comment **why**, not **what**:

```bash
# Wait 2 seconds before retrying (as per ARCHITECTURE.md)
sleep 2

# Use 'true' to prevent "no such file" errors when nothing matches
rm -f /tmp/myapp-*.log || true

# Only quote if contains spaces or special chars
if [[ $var == *[[:space:]]* ]]; then ...
```

**Avoid:**

```bash
# Loop through the results
for item in "${results[@]}"; do ...

# Increment the counter
((count++))
```

### Function documentation

Document functions with a header comment:

```bash
# Get the pod status and display it.
#
# Environment variables:
#   ENV        - Environment: dev, test, or prod
#   APP_NAME   - Application name
#
# Outputs:
#   Pod status information
#
# Exit code:
#   0 - Success
#   1 - Pod does not exist
pod_status() {
    local env="${ENV:-dev}"
    local app_name="${APP_NAME:?APP_NAME not set}"
    ...
}
```

Format:

* **Line 1**: Short description (imperative)
* **Empty line**
* **Parameters** (if any): Named inputs
* **Environment variables**: Variables read from environment
* **Outputs**: What goes to stdout/stderr
* **Exit code**: What non-zero means
* **Example** (optional): Brief usage example

---

## Naming Conventions

### Variables

* **Environment variables** (read from environment): `UPPERCASE` with underscores
  * Examples: `APP_NAME`, `HTTP_PORT`, `POSTGRES_PASSWORD`
  * Treat as constants once set

* **Local variables** (within functions): `lowercase_with_underscores`
  * Examples: `pod_name`, `env_file`, `backup_dir`
  * Use `local` keyword

* **Global variables** (discouraged): `lowercase_with_underscores` if unavoidable
  * Prefix with script name or context to avoid collisions
  * Example: `pod_up_timeout`

* **Array variables**: Use plural form
  * `volumes`, `containers`, `commands`

### Functions

* Use `lowercase_with_underscores`
* Use **verb first** for imperative functions: `start_pod`, `stop_pod`, `create_backup`
* Use **adjective first** for query/test functions: `is_running`, `has_volume`
* Prefix with context if there are many related functions: `pod_up`, `pod_down`, `pod_status`

Example:

```bash
start_pod() { ... }
stop_pod() { ... }
pod_exists() { ... }
is_healthy() { ... }
```

### Constants

Define constants with `readonly` at the top of the script:

```bash
readonly TIMEOUT_DEV=60
readonly TIMEOUT_TEST=90
readonly TIMEOUT_PROD=180
readonly READINESS_URL="http://localhost:${HTTP_PORT}/readyz"
```

---

## Formatting and Layout

### Indentation

* Use **spaces, not tabs** (4 spaces per indentation level)
* Consistent indentation within blocks

### Line length

* Keep lines under 100 characters when practical
* Split long commands across lines using backslash:

```bash
podman run -d \
    --pod "$POD_NAME" \
    --name postgres \
    --volume "$volume:$mount" \
    --env POSTGRES_PASSWORD="$password" \
    "$POSTGRES_IMAGE"
```

### Conditionals

Use `[[ ]]` (preferred) over `[ ]`:

```bash
# ✅ Good
if [[ -f "$config" ]]; then
    source "$config"
fi

# ✅ Good (for arithmetic)
if (( count > 10 )); then
    error "Too many items"
fi

# ❌ Avoid
if [ -f "$config" ]; then ...
```

### Loops

Clear formatting for readability:

```bash
# Array iteration
for pod in "${pod_list[@]}"; do
    info "Pod: $pod"
done

# Command iteration
while IFS= read -r line; do
    process_line "$line"
done < "$file"

# Arithmetic loop
for (( i = 0; i < 10; i++ )); do
    echo "$i"
done
```

### Error handling patterns

```bash
# Pattern 1: Check before operation
if [[ ! -f "$file" ]]; then
    error "File not found: $file"
fi

# Pattern 2: Use || for fallback
result=$(command) || error "Command failed"

# Pattern 3: Use trap for cleanup
temp_dir=$(mktemp -d) || error "Cannot create temp dir"
trap "rm -rf '$temp_dir'" EXIT

# Pattern 4: Check command exists
if ! command -v podman &>/dev/null; then
    error "podman is not installed"
fi
```

---

## Output Messages

### Message functions

Define consistent output functions:

```bash
error() {
    echo "ERROR: $*" >&2
    exit 1
}

warn() {
    echo "WARN: $*" >&2
}

info() {
    echo "INFO: $*"
}

progress() {
    echo "→ $*"
}
```

### Output examples

```bash
error "Pod does not exist: $POD_NAME"
warn "Timeout waiting for readiness check"
info "Postgres is healthy"
progress "Starting Nginx container"
```

Use emojis sparingly (only if project style includes them):

```bash
info "✓ Pod created successfully"
error "✗ Migration failed"
warn "⚠ High memory usage"
```

---

## Usage and Help

Every non-trivial script should have a `usage()` function:

```bash
usage() {
    cat <<EOF
Usage: pod-up [OPTIONS]

Start the pod with all services.

Environment variables:
  ENV             Environment: dev, test, or prod (required)

Options:
  --help          Show this help message
  --debug         Enable debug output

Examples:
  ENV=dev pod-up
  ENV=test pod-up --debug

EOF
}

# Parse arguments
case "${1:-}" in
    --help|-h)
        usage
        exit 0
        ;;
    *)
        ;;
esac
```

---

## Security and Best Practices

### Quoting

Always quote variables unless you have a specific reason not to:

```bash
# ✅ Good
result="$(command "$input")"
mkdir -p "$dir"

# ❌ Avoid (word splitting, globbing)
result=$(command $input)
mkdir -p $dir
```

### Path handling

Use full paths; don't rely on `cd`:

```bash
# ✅ Good
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../env/${ENV}.env"

# ❌ Avoid (can fail silently)
cd /some/dir
ENV_FILE="../env/${ENV}.env"
```

### Temporary files

Use `mktemp` instead of hardcoded paths:

```bash
temp_file=$(mktemp) || error "Cannot create temp file"
trap "rm -f '$temp_file'" EXIT

# Safe to use $temp_file
```

### Command substitution

Prefer `$( ... )` over backticks:

```bash
# ✅ Good
version=$(podman --version | awk '{print $3}')

# ❌ Avoid
version=`podman --version | awk '{print $3}'`
```

### Pipes

Avoid losing errors in pipes; use `set -o pipefail`:

```bash
# With pipefail, any error in the pipeline fails the whole line
set -o pipefail
output=$(cat file | grep pattern | awk '{print $1}')
```

---

## Testing Considerations

Scripts written for this project should be testable.

### Principles

* Separate logic from I/O
* Use functions rather than long linear scripts
* Accept arguments and return via stdout (testable)
* Use exit codes for success/failure (0 = success)

### Testable example

```bash
# ✅ Testable function (no side effects, pure logic)
normalize_path() {
    local path="$1"
    echo "${path%/}"  # Remove trailing slash
}

# ✅ Testable function (clear output)
get_pod_status() {
    local pod="$1"
    if podman pod exists "$pod"; then
        echo "exists"
    else
        echo "missing"
    fi
}

# ❌ Hard to test (mixes logic with I/O)
process_all_pods() {
    for pod in $(podman pod ls -q); do
        echo "Processing $pod"
        podman pod inspect "$pod" >report.json
    done
}
```

---

## Documentation Template

Use this as a starting point for new scripts:

```bash
#!/usr/bin/env bash
# script-name: Short description of what this does
#
# Longer description explaining the behavior and any important context.
#
# Usage:
#   script-name [OPTION]...
#
# Environment variables:
#   VAR_NAME        Description and whether required
#
# Options:
#   --help          Show this help message
#   --verbose       Verbose output
#
# Examples:
#   script-name
#   script-name --verbose
#
# Exit codes:
#   0   Success
#   1   Error (see stderr)

set -euo pipefail

# Helper functions
error() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
info() { echo "INFO: $*"; }

usage() {
    head -30 "$0" | tail -25
}

# Main logic
main() {
    # Script logic here
    info "Done"
}

# Parse arguments
case "${1:-}" in
    --help|-h)
        usage
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
```

---

## Quick Reference

### Common patterns

```bash
# Check if file exists
if [[ -f "$file" ]]; then ...

# Check if directory exists
if [[ -d "$dir" ]]; then ...

# Check if variable is empty
if [[ -z "$var" ]]; then ...

# Check if variable is not empty
if [[ -n "$var" ]]; then ...

# Check if command exists
if command -v podman &>/dev/null; then ...

# Get script directory (works with symlinks)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source file if it exists
[[ -f "$file" ]] && source "$file"

# Default value for variable
timeout="${TIMEOUT:-30}"

# Make trap safe with quoting
trap "rm -f '$temp_file'" EXIT
```

---

## Tools and Linting

If the project uses tools like `shellcheck`, follow its recommendations:

* Most defaults are sensible (SC2086, SC2181 are common catches)
* Document exceptions with `# shellcheck disable=SC####`
* Fix the warning rather than disabling it when possible

Example:

```bash
# shellcheck disable=SC2086
# (We need word splitting here for $COMMAND_ARGS)
eval "$COMMAND_ARGS"
```

---

## Final Notes

* Clarity over cleverness
* Future maintainers read code more than they write it
* Comments and documentation are worth the effort
* Use existing patterns in the project; consistency beats perfection
