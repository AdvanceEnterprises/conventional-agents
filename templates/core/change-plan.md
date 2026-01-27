# Change Plan (Template)

<!--
PARSING_HINTS:
- Document type: change-plan
- Intended role: Implementer (Role 2)
- This is a TEMPLATE, not a guide or essay.
- Fill in all sections succinctly.
- Do not include code blocks unless explicitly requested.
- Treat the completed plan as a binding contract for implementation.
- If implementation would exceed this plan, the plan must be revised first.
-->

---

type: change-plan
role: implementer
language: python
status: draft
related_specs: []
related_adrs: []
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>

---

## 1. Feature / Issue Reference

* Feature Spec ID(s): FS-XXXX
* Related ADR ID(s): ADR-XXXX (if any)
* Issue / PR Reference: <ID or link>

## 2. Scope of Change

**This change WILL:**

* <bullet derived directly from Success Criteria>

**This change will NOT:**

* <explicit non-goal>

## 3. Tests Driving This Change

* Test file(s):

  * tests/test_<feature>.py

* Target test(s):

  * test_sc_1__<name>
  * test_sc_2__<name>

## 4. Files to Be Modified

Only list files that will be changed.

* src/<package>/<module>.py
* src/<package>/errors.py

## 5. Implementation Steps (High-Level)

Describe concrete steps without code.

1. <step>
2. <step>
3. <step>

## 6. Constraints and Guardrails

* Spec constraints:

  * FS-XXXX Non-Goals / Out of Scope

* ADR constraints:

  * ADR-XXXX summary

* Architecture constraints:

  * <layering / boundaries>

## 7. Risks and Edge Cases

* <risk or edge case>
* <error handling concern>

## 8. Validation

* Tests expected to pass:

  * <list>

* Manual checks (if any):

  * <steps or "None">

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
