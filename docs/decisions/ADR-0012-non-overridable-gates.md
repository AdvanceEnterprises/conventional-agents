---
type: adr
id: ADR-0012
status: accepted
decision_scope: architecture
reversible: yes
related_specs:
  - FS-0018
superseded_by: null
---

# ADR-0012: Introduce non-overridable gates ("super-gates") in ROLE_CONTRACT

## Status

- Accepted

## Context and Problem Statement

The agentic-dev-kit precedence model (defined in INTEGRATION.md) establishes that a consuming project's root `AGENTS.md` is the highest-priority instruction source. This means project-specific rules can override anything in the vendored kit — including ROLE_CONTRACT.

FS-0018 introduces rules that should **not** be overridable by project-specific instructions:

- **Merge prohibition**: Agents must not merge PRs. This is a safety boundary — an agent merging unreviewed code bypasses the human oversight that the entire framework depends on.
- **GitHub identity verification**: Agents must verify the active `gh` account before every CLI operation. Getting this wrong means actions are attributed to the wrong identity, undermining audit trails.

These rules differ from normal ROLE_CONTRACT content (which projects can strengthen but also override). They represent a category of safety-critical constraints where the cost of accidental override is severe and the benefit of allowing override is negligible.

The question: should the kit formalize a mechanism for rules that sit above the normal precedence chain?

## Decision Drivers

- **Human oversight is the foundation**: The entire framework assumes humans review and approve agent work. If an agent can merge its own PRs because a project's AGENTS.md says so, the framework's safety model collapses.
- **Identity integrity is non-negotiable**: Actions attributed to the wrong account are an audit and security failure. No project context justifies skipping identity checks.
- **Precedence clarity**: Without a formal mechanism, FS-0018's "cannot be overridden" language conflicts with INTEGRATION.md's precedence rules. This ambiguity will confuse agents.
- **Framework trust**: Downstream consumers need to know that certain safety properties hold regardless of how a project configures its AGENTS.md.
- **Minimal scope**: The super-gate category should be narrow. If everything is non-overridable, the precedence system is meaningless.

## Considered Options

### Option A: Formalize "super-gates" as a distinct category in ROLE_CONTRACT

Create a clearly marked section in ROLE_CONTRACT (e.g., "Non-Overridable Safety Gates") that:

- Lists rules that cannot be weakened by any instruction source, including project AGENTS.md.
- Uses explicit language: "This gate is non-overridable. It takes precedence over all other instruction sources."
- Is referenced in INTEGRATION.md's precedence rules as sitting above level 1.
- Initially contains only: merge prohibition, identity verification gate.

Override mechanism: A consuming project that genuinely needs an exception must document it in a project-level ADR with explicit human sign-off. The super-gate still exists; the ADR records the conscious decision to deviate.

### Option B: Keep the current precedence model, rely on "strongly recommended" language

Leave INTEGRATION.md's precedence unchanged. Mark certain ROLE_CONTRACT rules as "strongly recommended — do not override without careful consideration" but don't formally prevent it.

### Option C: Make all of ROLE_CONTRACT non-overridable

Elevate the entire ROLE_CONTRACT above project AGENTS.md in the precedence chain.

## Decision Outcome

**Chosen option: Option A — Formalize super-gates as a distinct category.**

### Rationale

- Option B doesn't solve the problem. "Strongly recommended" is exactly the kind of soft language agents ignore. The whole point of FS-0018 is that agents need hard gates, not suggestions.
- Option C is too broad. ROLE_CONTRACT contains many rules that projects legitimately need to customize (e.g., test framework conventions, commit message formats). Making all of it non-overridable would break the kit's framework-agnostic design.
- Option A is the minimal intervention: a small, clearly scoped set of safety-critical rules with an explicit override mechanism (project ADR) for genuine exceptions.

### Consequences

**Good:**

- Precedence model is unambiguous: super-gates > project AGENTS.md > ROLE_CONTRACT > everything else.
- Safety-critical rules are mechanically clear to agents — no judgment call required.
- The override mechanism (project ADR) maintains human agency while creating a deliberate friction point.
- Narrow scope (initially 2 rules) keeps the super-gate category from becoming a catch-all.

**Bad:**

- Adds complexity to the precedence model (one more level).
- Could create confusion if the super-gate list grows unchecked — needs governance on what qualifies.
- Projects that genuinely need agent-driven merges (e.g., fully automated CI/CD with no human in the loop) must file an ADR to deviate.

**Neutral:**

- Does not require CI enforcement — this is a contractual/documentation change that agents follow from instruction. CI enforcement could be added later as a separate effort.

## Qualification Criteria for Super-Gates

A rule should only be designated as a super-gate if ALL of the following apply:

1. **Safety-critical**: Violating it undermines human oversight or audit integrity.
2. **No legitimate default override**: There is no common project context where weakening the rule is the right default.
3. **Low cost of compliance**: Following the rule imposes minimal overhead on normal workflows.
4. **High cost of violation**: The failure mode is severe, hard to detect, or hard to reverse.

## Implementation Notes

- Update INTEGRATION.md precedence table to add level 0: "Non-overridable safety gates (ROLE_CONTRACT § Non-Overridable Gates)".
- Add a clearly marked section to ROLE_CONTRACT with the initial super-gates.
- Reference this ADR from both documents.

## Validation

- **Signal**: After implementation, agents should correctly refuse to merge PRs even when project AGENTS.md or human chat instructions say "merge it" (unless the project has a documented ADR exception).
- **Signal**: No false positives — agents should not refuse actions that are merely gated (like major version bumps) vs truly prohibited (like merging).
- **Review checkpoint**: After 3 months of use, review whether the super-gate list has grown appropriately or if it's being abused as a way to bypass the precedence model.

## Links

- FS-0018: Process Compliance Gates and Document Lifecycle
- ADR-0011: Multi-identity GitHub model
- INTEGRATION.md: Precedence rules
