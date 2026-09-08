# GitHub Binding Executable Layer

This directory ships the executable part of the reference GitHub binding. The
normative capability mapping remains in
[`integrations/github-issues-projects.md`](../github-issues-projects.md); these
commands provide repeatable mechanisms for the setup and observation work that
document names.

The layer is intentionally not a scheduler or a reconciler. It does not create
or move work items, change project fields, or start itself. Consumer policy may
invoke a command explicitly from CI or an operator shell.

## Enforcement posture

| Command | Posture | What it does not claim |
| --- | --- | --- |
| [`bin/gh-submodule-init.sh`](bin/gh-submodule-init.sh) | **enforces** fail-closed initialisation | It does not make a missing credential usable or mutate repository policy |
| [`bin/gh-label-provision.sh`](bin/gh-label-provision.sh) | **provisions** the framework vocabulary | It does not delete, recolour, or otherwise own consumer labels |
| [`bin/gh-board-audit.sh`](bin/gh-board-audit.sh) | **reports** project drift | It does not reconcile fields, items, Issues, or board membership |

The distinction is deliberate. A binding can provide a mechanism without
pretending that GitHub's permission model enforces a convention. The board audit
is therefore safe to run from an informational CI job; use `--strict` only when a
consumer deliberately wants its own job to fail.

## Commands

### Submodule initialisation

`bin/gh-submodule-init.sh` resolves the framework repository visibility at every
invocation. Public framework repositories are initialised without a credential.
Private repositories require `CA_FRAMEWORK_TOKEN`, `GH_TOKEN`, or
`GITHUB_TOKEN`; absent credentials fail before `git submodule update --init` is
attempted. The private path writes a repository-scoped `insteadOf` rewrite at **`--global`**
git configuration scope. The scope is load-bearing because the child
clone reads global and system configuration.

The command resolves the caller from `git rev-parse --show-toplevel` and accepts
`CA_TARGET_REPO` as an explicit override. It never reads a path containing a
`vendor/` segment and never prints the credential.

### Label provisioning and audit

`bin/gh-label-provision.sh` compares the caller's labels with the six labels
specified by FS-0018: `enhancement`, `bug`, `documentation`, `spec`, `plan`, and
`question`. Default mode creates only missing labels. Existing labels are left
alone, and unexpected consumer labels are never deleted. `--audit` reports
missing and unexpected labels without mutation. `--dry-run` reports exactly the
creates default mode would attempt. Optional consumer extensions come from a
caller-owned text file, not from this framework's source.

The label API needs repository write access only for default provisioning. Audit
and dry-run need read access. Every API operation is preceded by `gh auth status`.

### Project-board audit

`bin/gh-board-audit.sh` reads a Project v2 board and the target repository's open
Issues. It reports three independent categories:

All Project items are included in the field-drift categories, including pull
requests and other non-Issue items. Only open Issues in the target repository
participate in the absent-from-board category.

1. project items without an `Issue Type` value (or the legacy `Doc Type` value on
   boards created from FS-0011);
2. project items without a `Status` value; and
3. open Issues with no item on the selected project.

A repository without a project is reported as `project=absent` and is not an
operational failure; the binding documents label and title-prefix fallbacks for
that case. `--strict` turns findings into a non-zero result, but the framework's
own CI does not wire that mode into a pull-request gate.

The command paces successive GraphQL calls at seven seconds by default. Set
`CA_GRAPHQL_MIN_INTERVAL=0` for a controlled test or an operator who has chosen
a different rate budget. When GitHub returns an explicit rate-limit response,
the shared library honors `Retry-After` or waits through the reported reset
timestamp plus a buffer, then retries a bounded number of times. Set
`CA_GRAPHQL_SERVER_WAIT_MAX_SECONDS` to change the safety ceiling for a
server-directed wait. The separate `unknown owner type` response is treated as
an owner-resolution error, not as a rate-limit signal. The library does not
consult the `rate_limit` endpoint: that endpoint describes the primary quota and
can remain healthy while the secondary limit is failing.

## Shared library contract

[`lib/gh-common.sh`](lib/gh-common.sh) provides command checks, authentication
prechecks, caller-relative target and repository resolution, visibility lookup,
token-free global rewrite configuration, GraphQL pacing, and bounded
rate-limit backoff. Private submodule authentication is supplied through a
temporary process-scoped askpass helper and is never persisted in git config.
It is Bash 3.2 compatible and uses no associative arrays. Callers must not add a
scheduler or a mutating work-item operation around it.

All commands print actionable failures. An unauthenticated invocation names
`gh auth status`; an indeterminate visibility result fails closed; and an
exhausted rate-limit retry identifies the wait-and-retry remediation.

## Operational hazards recorded by this binding

- The submodule's token-free credential rewrite must be **global**, not
  repository-local; the token itself stays process-scoped.
- The GraphQL secondary limit is invisible through the primary quota endpoint;
  `unknown owner type` is a separate owner-resolution failure and is not retried
  as a rate limit.
- `gh pr edit --body` can fail on GitHub's GraphQL deprecation path; the working
  fallback is `gh api -X PATCH` with the pull-request endpoint and an explicit
  body payload.
- `reviewDecision` may be null on a draft pull request, so draft review state
  must not be inferred from that field alone.
- GitHub automatically disables a scheduled workflow after 60 days without
  repository activity. This layer does not create scheduled triggers; consumers
  must monitor any scheduler they choose to own.

## CI and pull-request templates

The copyable fragments are
[`ci-templates/submodule-checkout.yml`](ci-templates/submodule-checkout.yml),
[`ci-templates/governance-gates.yml`](ci-templates/governance-gates.yml), and
[`templates/pull-request.md`](templates/pull-request.md). They contain no
organization, repository, project, node, field-option, or secret instance data.
The framework's own pull-request template is
[`.github/pull_request_template.md`](../../.github/pull_request_template.md),
and its workflow uses the binding's non-mutating label audit.

The submodule fragment requires a full-history checkout (`fetch-depth: 0`) and
calls the shared initializer instead of reproducing credential logic. The
governance-gates fragment is a copyable sequence; consumers decide which
commands their own permissions and policy permit.

## Registration

The commands are available through these npm scripts:

- `npm run github:submodule-init`
- `npm run github:label-provision`
- `npm run github:board-audit`

The integration markdown lint is recursive, so files below this directory are
covered by `npm run lint:integrations` and `npm run lint:docs`.

## References

- [`integrations/github-issues-projects.md`](../github-issues-projects.md) —
  normative capability-to-GitHub mapping and setup checklist.
- [`scripts/README.md`](../../scripts/README.md) — why these mechanisms are
  exported integration commands rather than Category 1 gates.
- [`config/project.example.yml`](../../config/project.example.yml) — consumer
  metadata shape for a Project v2 board.
- `ADR-0037` and `FS-0029` — the decision and success criteria governing this
  layer.
