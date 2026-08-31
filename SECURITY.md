# Security Policy

## Reporting a vulnerability

If you find a security issue in this framework — a gate that fails open,
an audit-trail gap, a template that leaks secrets, or anything else that
undermines the trust model — **do not open a public issue**.

Report it privately to the maintainers via GitHub's private vulnerability
reporting: on this repository, open the **Security** tab and choose
**Report a vulnerability**.

Reports are acknowledged within **5 business days**. We will coordinate
disclosure, and will credit the reporter (unless anonymity is requested).

## What counts as a security issue here

This is a documentation / standards kit, not a runtime service. The
security-relevant surfaces are:

- **Governance gates** (`scripts/`, `.github/workflows/`) — a gate that
  silently enforces nothing (see CONTRIBUTING "Changing a Governance Gate"
  for the failure mode history)
- **Approval and provenance checks** — any path that lets a decision be
  backdated, self-approved outside its scope, or approved without a human
  gate (ADR-0012, ADR-0026, ADR-0027)
- **Templates and example configs** — anything that could steer a consumer
  into committing secrets or weakening a safety gate
- **Agent-Attribution and identity handling** (ADR-0018, ADR-0021) — spoofable
  or ambiguous attribution that breaks audit

## Supported versions

Only the current `trunk` and the latest tagged release receive security
fixes. Security fixes ship as the next tagged framework version, or are
backported to the most recent `vX.Y.Z` tag at maintainer discretion.
Older tags are unsupported.

## Coordinated disclosure

We prefer a 30-day disclosure window from fix-publication to full public
disclosure. We will work with you if you need a different timeline.
