# Change Plan (Template)

<!--
PARSING_HINTS:
- Document type: change-plan
- Intended role: Implementer (Role 3)
- This is a TEMPLATE, not a guide or essay.
- Fill in all sections succinctly.
- Do not include code blocks unless explicitly requested.
- Treat the completed plan as a binding contract for implementation.
- If implementation would exceed this plan, the plan must be revised first.
- `touches:` is authoritative for approval routing. See ADR-0027.
-->

---

type: change-plan
role: implementer
language: `language or "n/a" for documentation-only work`
status: draft
related_specs: []
related_adrs: []

# consensus_required: true    # optional per-document override for FS-0019 (off by default)

touches: []
created: `YYYY-MM-DD`
updated: `YYYY-MM-DD`

---

<!--
`touches:` declares every path this plan will modify, as repo-relative paths or
globs. It is compared against the governing FS's `interfaces:` to route approval:

- Entirely within the FS's `interfaces:` → the plan is derivative of an
  already-approved decision and may self-approve.
- Anything outside them → the plan proposes scope no human sanctioned, and
  requires human approval.

Certain paths always require human approval regardless of the FS's `interfaces:`.
See ADR-0027 for the reserved set and the rationale.

Under-declaring here is a process violation, not a shortcut: the document hygiene
gate checks touched files against the FS `interfaces:` at PR time, so an
under-declared plan fails later and louder.
-->

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-XXXX
* Related ADR ID(s): ADR-XXXX (if any)
* Issue / PR Reference: `ID or link`

## 2. Scope of Change

**This change WILL:**

* `bullet derived directly from Success Criteria`

**This change will NOT:**

* `explicit non-goal`

## 3. Tests Driving This Change

* Test file(s):

  * tests/test_`feature`.py

* Target test(s):

  * test_sc_1__`name`
  * test_sc_2__`name`

## 4. Files to Be Modified

Only list files that will be changed.

* src/`package`/`module`.py
* src/`package`/errors.py

## 5. Implementation Steps (High-Level)

Describe concrete steps without code.

1. `step`
2. `step`
3. `step`

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-XXXX Non-Goals / Out of Scope

* ADR constraints:

  * ADR-XXXX summary

* Architecture constraints:

  * `layering / boundaries`

## 7. Risks and Edge Cases

* `risk or edge case`
* `error handling concern`

## 8. Validation

* Tests expected to pass:

  * `list`

* Manual checks (if any):

  * `steps or "None"`

## 9. Explicit Non-Changes

State what will NOT be modified.

* Public API shape
* Config format
* Logging behavior
* Performance characteristics

## 10. Readiness Check

* [ ] Spec is approved
* [ ] Tests exist or are clearly defined
* [ ] Scope is minimal and explicit
* [ ] No architectural changes implied

## Declaration

I affirm that:

* This plan reflects the full intended scope of implementation
* No additional behavior will be introduced
* Any deviation will require revising this plan before coding
