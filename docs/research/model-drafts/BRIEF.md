# Frozen ARC42 drafting brief — collective-agents

This packet is shared unchanged with four independently routed models. It is background, not a request to approve or implement anything.

## Required sources

- The bootstrap on `AdvanceEnterprises/collective-agents` `trunk`: `README.md`, `AGENTS.md`, and the pinned `vendor/conventional-agents/` submodule at `94b784aa022b715bf7dad331a714f786620f961a`.
- The **research memo only** from PR #1: `docs/research/engine-boundary-and-failure-modes.md` on commit `6d2a94b44545be0aec072c45e3f8bfe83067ed38` (https://github.com/AdvanceEnterprises/collective-agents/pull/1). Read it as evidence, not a normative design. **Do not read PR #1's `docs/ARC42.md`, PR #2, or any other model's draft.**
- Framework template `vendor/conventional-agents/templates/core/architecture-arc42.md` and relevant accepted ADRs / lifecycle. Check document-frontmatter status before treating an ADR as accepted; ADR-0032 is `proposed` in the pinned revision.

## Product direction already agreed with the human

- collective-agents is a reusable governed workflow execution product, consuming conventional-agents as the contract. Git is durable artifact authority. GitHub work items and Hermes Agent execution are the first integration pair, not mandatory core dependencies.
- Separate work-item substrate from agent-runtime invocation. ADR-0039 covers runtime setup; it does not define a dispatch API. The candidate Hermes kanban binding is not shipped.
- An adopter may use one local instance configuration file; a portfolio may use a separate instance-level repo for registry, identities, cadence, model policy and budgets. Credentials do not belong in Git.
- One **authorized action/scope generation** on a work item is the unit of a canonical proposal (typically one draft PR), stable across retries. Distinct spec, implementation and follow-up actions can have distinct intents. A changed issue description alone cannot silently authorize a new generation. Runs are attempts, not new authorities.
- Workers return evidence (patch, summary, test results) without GitHub write credentials. A separate publisher validates current authority and evidence before publishing. Actual isolation must remove inherited credentials and filesystem/network access; not just an instruction or profile name. Publisher never merges.
- Ledger-first reservation precedes dispatch, but neither an outbox nor a ledger pre-check provides exactly-once external GitHub writes. A remote write may succeed before acknowledgement; discover existing publications and stop on unresolved ambiguity instead of retrying blind. Do not claim a guarantee not demonstrated.
- Level-triggered reconciliation is authoritative; events only accelerate. `question` parks for genuine human input, not a transient timeout/rate limit. Selected and actual model must be attributable; model identities, fallback and budgets are instance policy, while mechanism belongs in product.
- Human approval/merge gates remain in force. No engine exists yet; this task is a candidate architecture draft, not implementation, accepted ADR, or FS/PLAN.

## Independent drafting assignment

Produce a self-contained arc42 architecture draft using the eleven-section framework template. Prioritize architecture, concrete quality scenarios, boundaries, deployment options, threat/failure modes, and one candidate end-to-end flow. Distinguish enforced vs detectable vs proposed properties. Explicitly list open decisions: first Type/action, minimum dispatch evidence, autonomous Phase transitions, stable intent/generation representation, durable ledger and publisher concurrency/recovery, dispatch API and instance configuration resolution. Include short citations to pinned contract and research sources. Do not copy or revise an existing ARC42, write code, commit, push, open a PR, or edit shared files. Output your complete draft to your assigned unique path and return its path and actual model/provider used.
