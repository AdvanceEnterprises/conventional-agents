# Runbook (Template)

Copy this file to `runbooks/RB-NNNN-short-description.md` and replace everything in
angle brackets. Delete this header block and the guidance comments once filled in.

See `runbooks/README.md` for the convention, and `workflows/document-lifecycle.md`
for how a runbook's status transitions.

---

```yaml
---
type: runbook
id: RB-NNNN
title: <what this procedure accomplishes>
status: current
substrate: <the system this operates against, e.g. "GitHub Issues + Projects v2">
governs: <the integrations/ binding or workflows/ doc this operationalises, or empty>
last_verified: YYYY-MM-DD
verified_by: "Name <email>"
related_adrs: []
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

---

## Preconditions

State each as a **checkable fact**, not an assumption. The operator should be able to
confirm every line before starting.

- <access or role required, and how to confirm you have it>
- <credential or token required, where it lives, and its scopes>
- <state the substrate must already be in>

## Procedure

Numbered steps. Each step states **the action**, **the expected observable result**,
and **what to do when the result differs**. A step whose outcome you cannot observe is
not a step — it is a hope.

1. **<Action.>**
   - Expected: <what you should see>
   - If different: <what that means and what to do>

2. **<Action.>**
   - Expected: <what you should see>
   - If different: <what that means and what to do>

## Deviations Observed

Where the substrate did not behave as its governing binding or workflow claimed.

**This section is mandatory and may not be omitted when empty.** Record "None observed
on `<date>`" instead. An absent section is indistinguishable from an unexamined one.

Each deviation should say what was expected, what happened, and whether the governing
document needs to change. A deviation that does not produce a follow-up is a deviation
you will rediscover.

| Step | Expected | Actual | Governing doc needs change? |
| --- | --- | --- | --- |
| | | | |

## Rollback

How to undo this procedure — or an explicit statement that it is **not reversible**,
which is itself the useful answer.

## Verification

How to confirm afterward that the procedure actually took effect. Prefer a command
whose output an operator can read over a claim that it worked.
