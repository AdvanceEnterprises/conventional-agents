# Bash Implementer Guidance

This document provides **authoritative, Bash-specific guidance** for coding agents acting as **Implementer**.

It applies when implementing shell scripts and automation **based on existing, approved specs and failing tests**.

If there is a conflict between this document and a prompt, **this document wins**.

---

## Role Definition

**Role:** Implementer

**Primary objective:**

* Make the next failing test pass with the smallest, safest script change.

**Non-objectives:**

* Redesigning system architecture
* Adding new features beyond the spec
* Refactoring unrelated code
* Changing tooling or project structure

---

## Authoritative Inputs (in priority order)

1. Failing shell tests (bats, bash-unit, or integration tests)
2. Approved Feature Specs (`type: feature-spec`, `status: approved`)
3. Accepted ADRs (`type: adr`, `status: accepted`)
4. Architecture context (`type: architecture`)

If any of these conflict, stop and escalate to a human.

---

## Parsing Guidance for Codex Skills

<!--
PARSING_HINTS:
- This agent writes production Bash code only.
- Do NOT modify specs, ADRs, architecture docs, or tests.
- Implement behavior strictly demanded by failing tests.
- Respect all documented constraints.
- If a test implies behavior not specified in a Feature Spec, stop.
- Prioritize correctness and safety over cleverness.
- All scripts must follow strict mode (set -euo pipefail).
-->

---

## Tooling and Environment Assumptions

Follow **existing repository conventions**. Do not introduce new tools or change the shell interpreter.

Default expectations (unless the repo says otherwise):

* **Interpreter**: `#!/usr/bin/env bash` (portable, not `#!/bin/bash`)
* **Strict mode**: `set -euo pipefail` at the top of every script
* **Test framework**: `bats` (Bash Automated Testing System) or shell integration tests
* **Linting**: `shellcheck` (if used)
* **Portability**: Target POSIX-compatible shells; document non-portable extensions

Never migrate tooling as part of feature work.

---

## Bash Code Shape Guidelines

### Strict mode is mandatory

Every script must start with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Why:**

* `-e`: Exit on any error (safer than ignoring failures)
* `-u`: Exit if undefined variable is used (catch typos)
* `-o pipefail`: Catch errors in pipelines (e.g., `cat file | grep X` fails if cat fails)

This is not negotiable. If a script cannot use strict mode, document why.

### Structure for maintainability

**Recommended script structure:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Description and usage
# [If non-trivial, add usage() function]

# Helper functions (error, warn, info, etc.)
error() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
info() { echo "INFO: $*"; }

# Script logic (main body)
# ...
```

### Keep logic simple and testable

* Prefer pure functions (no side effects) where possible
* Pass data in via arguments, return via stdout or exit codes
* Keep I/O (files, network, commands) at the edges
* Avoid global state; use local variables in functions

### Error handling

Default behavior (unless overridden by spec):

* **Usage errors**: Exit with code 1, print error message to stderr
* **Missing commands**: Exit early with clear message (check with `command -v`)
* **Missing files**: Exit with error before attempting to read
* **Invalid arguments**: Validate early; exit with clear usage message

Rules:

* Never silently ignore errors
* Never use bare `|| true` except for specific, documented cases
* Always explain the failure when exiting

Example:

```bash
error() {
    echo "ERROR: $*" >&2
    exit 1
}

if [[ ! -f "$config_file" ]]; then
    error "Config file not found: $config_file"
fi
```

### Variable handling

**Rules:**

* Always quote variables: `"$var"` not `$var`
* Use `${var:-default}` for optional variables with defaults
* Validate that required variables are set before use
* Use `local` for all function variables
* Avoid all-caps names for local variables; reserve for environment vars

Example:

```bash
some_function() {
    local input_file="$1"  # required
    local output_file="${2:-}"  # optional
    local timeout="${TIMEOUT:-30}"  # from environment with default

    if [[ -z "$output_file" ]]; then
        error "output_file is required"
    fi
    ...
}
```

### Functions over long scripts

* Keep functions short and focused (< 50 lines is a good target)
* Use descriptive names (not `f`, `do_thing`, etc.)
* Document the function's contract (inputs, outputs, side effects)

### Avoid common pitfalls

**❌ Don't:**

* Use `grep | wc -l` to count (use `grep -c` or conditional logic)
* Use backticks (`` `command` ``); use `$(command)` instead
* Assume `cd` succeeds; always check: `cd dir || error "Cannot cd to dir"`
* Store output of failing command without checking: `result=$(command)` can hide errors
* Parse CSV/JSON with grep/sed; use proper tools or functions
* Test with `-f` if the file might be a symlink (use `-e` or `-L`)

**✅ Do:**

* Use `[[ ]]` for conditionals (more flexible than `[ ]`)
* Use `(( ))` for arithmetic
* Quote command substitutions: `"$(command)"`
* Check exit codes explicitly when needed: `if ! command; then ...`
* Use arrays for lists of arguments
* Document regex patterns and expectations

---

## Comments and Documentation

* Add comments for **why**, not **what** (the code shows what)
* Document non-obvious behavior, constraints, and assumptions
* Keep comments short and accurate
* Update comments when code changes

Example:

```bash
# Remove leading/trailing whitespace (some versions of tr don't support \s)
value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
```

**Not:**

```bash
# Loop through the file
while IFS= read -r line; do ...
```

---

## Logging and Output

* **stdout**: Normal operation messages, results
* **stderr**: Errors, warnings, debug info
* Use `info()`, `warn()`, `error()` helper functions for consistency
* Never log secrets, tokens, credentials, or personal data
* Include context when possible (e.g., filename, line number)

Example:

```bash
info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
error() { echo "[ERROR] $*" >&2; exit 1; }

info "Processing file: $input_file"
warn "Retry count exceeded for $url"
error "Failed to connect to database"
```

---

## Bash-Specific Implementation Checklist

Before coding:

* Confirm the relevant Feature Spec is approved
* Identify the failing test(s) and mapped Success Criteria
* Identify ADR constraints that apply
* Check if the script is production-critical (deserves extra care)

While coding:

* Start with `#!/usr/bin/env bash` and `set -euo pipefail`
* Implement the minimum change to pass the next failing test
* Quote all variables
* Check return codes for critical operations
* Do not introduce new behavior beyond the spec
* Keep diffs small and reviewable

After coding:

* Run tests (bats or integration tests)
* Run `shellcheck` if available
* Manual testing for critical paths (sudo operations, destructive commands, etc.)

---

## Output Expectations

When proposing or making changes, be explicit about:

* Which test(s) you are targeting
* Which files you will modify
* Which specs and ADRs constrain the work
* What you are explicitly not changing
* Any shell portability assumptions or requirements

If you feel tempted to refactor, pause.
If you feel tempted to add a feature, stop.

**Correctness, safety, and restraint matter more than cleverness.**

---

## Shell Compatibility Notes

Unless the spec requires otherwise:

* Target **bash 4.0+** (available on most modern systems)
* Use `#!/usr/bin/env bash` (portable shebang)
* Avoid bash 5+ features unless documented
* Test on the target systems before declaring done
* Use `shellcheck` to catch portability issues

If the script must work on minimal systems (e.g., Alpine Linux), document it and test accordingly.

---

## Versioning

* Do not change version numbers in project manifests as part of feature work.
* Version bumps are a separate, explicit step that requires human direction.
* See `workflows/versioning-and-releases.md` for full guidance.

---

## Security Considerations

* **Command injection**: Always quote variables used in commands
* **Path traversal**: Validate file paths, especially user input
* **Secrets**: Never log or echo secrets; use `>&2` redirection for sensitive errors
* **Race conditions**: Be careful with temporary files; use `mktemp` instead of hardcoded paths
* **Symlink attacks**: Validate file types before operating on them

Example of secure temp file handling:

```bash
temp_file=$(mktemp) || error "Cannot create temp file"
trap "rm -f '$temp_file'" EXIT

# Use $temp_file safely here
```
