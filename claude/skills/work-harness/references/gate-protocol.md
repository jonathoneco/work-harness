# Gate Protocol

Standard operating procedure for creating, reviewing, and managing gate files in the adaptive work harness. Commands and skills reference this document rather than inlining gate instructions. Gate files are Tier 3 only.

## 1. Directory Convention

All gate files live at `.work/<name>/gates/`.

The directory is created during task initialization (Step 3 of `work-deep.md`) alongside `research/`, `plan/`, `specs/`, and `streams/`.

## 2. File Naming

| Gate Type | Naming Pattern | Example |
|-----------|---------------|---------|
| Step transition | `<from>-to-<to>.md` | `research-to-plan.md` |
| Implementation phase | `implement-phase-<N>.md` | `implement-phase-1.md` |
| Ad-hoc review | `review-<YYYYMMDD-HHMMSS>.md` | `review-20260317-143022.md` |
| Rollback | `rollback-<to>-from-<from>.md` | `rollback-plan-from-implement.md` |

Step names in gate file names match the step names in `state.json` (e.g., `research`, `plan`, `spec`, `decompose`, `implement`, `review`).

## 3. File Structure

Every gate file has these sections in order:

```markdown
# Gate: <descriptive title>

## Summary
<What the completed step produced: artifact count, key decisions, scope.>

## Review Results

### Phase A -- Artifact Validation
**Verdict**: PASS | ADVISORY | BLOCKING

<Checklist results. Each item: pass/fail with one-line detail.>

### Phase B -- Quality Review
**Verdict**: PASS | ADVISORY | BLOCKING

<Quality findings. Each item: pass/advisory/blocking with detail.>

## Advisory Notes
<Numbered advisory notes carried forward. Empty section if none.>

## Deferred Items
<Open questions, futures discovered, items explicitly deferred. Empty section if none.>

## Next Step
<What the next step involves: 2-3 sentences of orientation.>

## Your Response
<!-- Review the above and respond here:
     - "approved" to advance
     - Questions or feedback (will trigger discussion)
-->
```

The seven required sections are: Summary, Review Results (containing Phase A and Phase B sub-sections), Advisory Notes, Deferred Items, Next Step, and Your Response.

## 4. Iteration Protocol

When the user responds with questions or feedback (not approval), the gate file is updated with round markers under the "Your Response" section:

```markdown
## Your Response

### Round 1
User: <user's question or feedback>
Response: <agent's answer or changes made>

### Round 2
User: <follow-up>
Response: <answer>

### Decision
approved | rejected | deferred
```

Round markers accumulate. The final round contains the decision.

## 5. Immutability Rule

Once a gate file has a decision of "approved", it is never modified again.

If the gate needs to be revisited (e.g., scope change during a later step), a rollback gate file is created that references the original. The approved gate file remains untouched as a historical record.

## 6. Rollback Gates

A rollback gate is created when stepping backward (e.g., implement reveals that the plan needs revision):

```markdown
# Gate: Rollback to <target-step> from <current-step>

## Reason
<Why the rollback is needed>

## Original Gate
Reference: gates/<original-gate-file>.md

## What Changes
<What will be different in the re-done step>

## Your Response
<!-- "approved" to proceed with rollback -->
```

The rollback gate follows the same iteration and immutability rules as regular gates. Once approved, the rollback proceeds and the original gate file remains unchanged.
