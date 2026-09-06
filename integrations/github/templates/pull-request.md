# Pull Request Template

## Summary

<!-- State the consumer-visible change in one paragraph. -->

## Work item and governed documents

- Issue:
- Feature Spec:
- Change Plan:
- Governing ADR:

## Scope

- [ ] The diff stays within the approved plan's `touches:` set.
- [ ] No consumer repository is changed unless this PR is explicitly a consumer PR.
- [ ] No scheduler or work-item mutation is introduced by a binding command.

## Validation

- [ ] `npm run lint:docs`
- [ ] `npm run check:status`
- [ ] `npm run check:freshness`
- [ ] `npm test`
- [ ] `bash -n` on shipped shell files

### Live substrate evidence

<!-- Record command output or state identifiers only when the change requires a
     live GitHub check. Never paste credentials or token-bearing URLs. -->

## Risks and rollback

<!-- Name the failure mode, the operator-visible symptom, and the rollback. -->

## Review gates

- [ ] CI is green.
- [ ] Required review is complete.
- [ ] Human merge decision is recorded.
