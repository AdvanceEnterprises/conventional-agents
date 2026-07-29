#!/usr/bin/env bats

load "../FS-0001/helpers.bash"

setup() {
  REPO_ROOT="$(repo_root)"
  SINGLE="$REPO_ROOT/workflows/sdlc-single-model.md"
  MULTI="$REPO_ROOT/workflows/sdlc-multi-model.md"
}

# Helper: extract the spine table from a workflow doc as line count + role column.
# Returns three values on stdout: phase_count, leading_roles, exits_gates — each
# linefeed-separated for easy capture.
extract_spine() {
  local file="$1"
  python3 - "$file" <<'PY'
import sys
text = open(sys.argv[1]).read()
idx = text.find("## The shared spine")
if idx < 0:
    sys.exit(1)
rest = text[idx:]
lines = rest.split("\n")
table = []
started = False
for line in lines:
    if line.startswith("| #"):
        started = True
    if started:
        if line.startswith("|"):
            table.append(line)
        else:
            break
phases = [l for l in table if len(l) > 2 and l[2].strip().isdigit()]
print(len(phases))
for l in phases:
    cols = [c.strip() for c in l.strip().strip("|").split("|")]
    print(cols[2])  # leading role
PY
}

@test "spine: both workflows name seven phases" {
  [ -f "$SINGLE" ]
  [ -f "$MULTI" ]
  local s m
  s=$(extract_spine "$SINGLE" | head -1 | tr -d ' ')
  m=$(extract_spine "$MULTI" | head -1 | tr -d ' ')
  [ "$s" -eq 7 ]
  [ "$m" -eq 7 ]
}

@test "spine: leading role matches across workflows" {
  local s m
  s=$(extract_spine "$SINGLE" | tail -n +2)
  m=$(extract_spine "$MULTI" | tail -n +2)
  [ "$s" = "$m" ]
}

@test "gates: FS approval stated as human-held in both" {
  rg -F "FS approval is human" "$SINGLE" >/dev/null
  rg -F "FS approval is human" "$MULTI" >/dev/null
}

@test "gates: merge stated as human-held in both" {
  rg -F "Merge is human" "$SINGLE" >/dev/null
  rg -F "Merge is human" "$MULTI" >/dev/null
}

@test "gates: draft spec is not implementable in both" {
  rg -F "draft" "$SINGLE" | rg -F "not implementable" >/dev/null
  rg -F "draft" "$MULTI" | rg -F "not implementable" >/dev/null
}

@test "single-model: collaboration rounds are excluded" {
  rg -F "Collaboration rounds are unavailable" "$SINGLE" >/dev/null
}

@test "single-model: exclusion cites ADR-0023" {
  rg -F "ADR-0023" "$SINGLE" >/dev/null
}

@test "multi-model: declares touches: as artifact scope" {
  rg -F "touches:" "$MULTI" >/dev/null
  rg -F "ADR-0013" "$MULTI" >/dev/null
}

@test "multi-model: collaboration placements named" {
  rg -F "Consensus, pre-submission" "$MULTI" >/dev/null
  rg -F "Review board, artifact review" "$MULTI" >/dev/null
  rg -F "Consensus, review-time" "$MULTI" >/dev/null
  rg -F "Review board, change review" "$MULTI" >/dev/null
}

@test "handoff: contract table present in multi-model" {
  rg -F "## Handoff Contract" "$MULTI" >/dev/null
  rg -F "May assume" "$MULTI" >/dev/null
  rg -F "Must verify" "$MULTI" >/dev/null
}

@test "neutrality: no platform nouns in either workflow" {
  # ADR-0024: platform mechanics belong in integrations/ bindings, not in the workflow docs.
  ! rg -i "github" "$SINGLE"
  ! rg -i "github" "$MULTI"
}
