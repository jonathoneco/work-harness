---
stream: C
phase: 1
isolation: none
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/work-harness/references/gate-protocol.md
  - claude/skills/work-harness/references/state-conventions.md
---

# Stream C: Gate Protocol

## Stream Identity

- **Stream**: C
- **Phase**: 1 (immediately ready, no dependencies)
- **Component**: C4 — Gate Protocol

## Work Items

| ID | Beads ID | Title | Spec |
|----|----------|-------|------|
| W-05 | work-harness-i41 | Gate protocol SOP | 04 |

## File Ownership

| File | Action | Description |
|------|--------|-------------|
| `claude/skills/work-harness/references/gate-protocol.md` | Create | SOP reference: naming, structure, iteration, immutability, rollback |
| `claude/skills/work-harness/references/state-conventions.md` | Modify | Document `gate_file` field in Step Status Object |

**Note**: Spec 04 also calls for modifications to `claude/commands/work-deep.md` (Steps 2, 3, 5) and `claude/skills/work-harness.md` (Step 5). Those files are owned by other streams. This stream owns only the two files listed above — the gate protocol reference and the state conventions update. The `work-deep.md` and `work-harness.md` changes must be coordinated with the streams that own those files, or handled in a later integration pass.

## Work Item: W-05 — Gate Protocol SOP

**Spec reference**: `.work/harness-improvements/specs/04-gate-protocol.md`

### Implementation Steps

#### Step 1: Create the gate protocol SOP reference

**File**: `claude/skills/work-harness/references/gate-protocol.md`

This is the authoritative reference for creating, reviewing, and managing gate files. Commands and skills reference this document rather than inlining gate instructions.

**Contents (six subsections):**

**1.1 Directory convention**
- All gate files live at `.work/<name>/gates/`
- Directory is created during task initialization (Step 3 of work-deep.md)

**1.2 File naming**

| Gate Type | Naming Pattern | Example |
|-----------|---------------|---------|
| Step transition | `<from>-to-<to>.md` | `research-to-plan.md` |
| Implementation phase | `implement-phase-<N>.md` | `implement-phase-1.md` |
| Ad-hoc review | `review-<YYYYMMDD-HHMMSS>.md` | `review-20260317-143022.md` |
| Rollback | `rollback-<to>-from-<from>.md` | `rollback-plan-from-implement.md` |

**1.3 File structure**

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

**1.4 Iteration protocol**

When the user responds with questions or feedback (not approval), the gate file is updated with round markers:

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

**1.5 Immutability rule**

Once a gate file has a decision of "approved", it is never modified again. If the gate needs to be revisited (e.g., scope change during a later step), a rollback gate file is created that references the original.

**1.6 Rollback gates**

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

#### Step 4: Update state-conventions reference

Add `gate_file` field documentation to `claude/skills/work-harness/references/state-conventions.md`, per spec 00 section 2.

Add to the Step Status Object section:

```json
{
  "gate_file": "string|null -- relative path from .work/<name>/ to the gate review file, Tier 3 only"
}
```

### Acceptance Criteria

**AC-01**: Gate protocol reference exists at `claude/skills/work-harness/references/gate-protocol.md` with all six subsections (directory convention, file naming, file structure, iteration protocol, immutability rule, rollback gates) -- verified by `structural-review`

**AC-02**: File naming table covers all four gate types (step transition, implementation phase, ad-hoc review, rollback) with pattern and example -- verified by `structural-review`

**AC-03**: File structure template includes all seven sections (Summary, Review Results with Phase A and Phase B, Advisory Notes, Deferred Items, Next Step, Your Response) -- verified by `structural-review`

**AC-04**: `work-deep.md` Step 3 directory creation list includes `.work/<name>/gates/` -- verified by `structural-review`

**AC-05**: Each of the six auto-advance blocks in `work-deep.md` writes a gate file before presenting results to the user -- verified by `structural-review`

**AC-06**: Gate file paths use the naming conventions from the SOP reference (step transitions: `<from>-to-<to>.md`, phases: `implement-phase-<N>.md`) -- verified by `structural-review`

**AC-07**: Each auto-advance block records `gate_file` in the step's state.json status object on approval -- verified by `structural-review`

**AC-08**: `state-conventions.md` Step Status Object section documents `gate_file` as an optional string field with description matching spec 00 -- verified by `structural-review`

**AC-09**: `work-harness.md` References section lists `gate-protocol` with correct path -- verified by `structural-review`

**AC-10**: `work-harness.md` has a Gate Files subsection explaining the pattern -- verified by `structural-review`

**AC-11**: Existing `plan-to-spec.md` has all seven required sections from the SOP structure, or differences are documented as acceptable variations -- verified by `structural-review`

### Implementation Notes

AC-04 through AC-07 and AC-09 through AC-11 involve files NOT owned by this stream (`work-deep.md`, `work-harness.md`, and the existing `plan-to-spec.md` gate file). This stream implements the deliverables it owns:
- **AC-01, AC-02, AC-03**: Fully owned — create the gate protocol SOP reference
- **AC-08**: Fully owned — update state-conventions.md with `gate_file` field

The remaining ACs (AC-04 through AC-07, AC-09 through AC-11) require changes to files owned by other streams. These should be:
- Handled by the stream that owns `work-deep.md` (AC-04, AC-05, AC-06, AC-07)
- Handled by the stream that owns `work-harness.md` (AC-09, AC-10)
- Verified during final review (AC-11)

All acceptance criteria are listed here for completeness and traceability back to spec 04, even when the implementation responsibility falls outside this stream's file ownership boundary.

## Dependency Constraints

- **Depends on**: Nothing. Phase 1, immediately ready.
- **Depended on by**: No downstream components in the current initiative directly depend on C4's outputs, but the gate protocol is consumed by the `work-deep.md` step transition flow (cross-stream coordination).
- **No file conflicts**: The two files owned by this stream are exclusive to Stream C within Phase 1.
- **Cross-stream coordination**: The gate protocol SOP must exist before `work-deep.md` can reference it. If Stream C and the stream owning `work-deep.md` run in parallel (same phase), the `work-deep.md` stream should read the completed gate-protocol.md as input. This is safe because the SOP is a new file (create, not modify) — no merge conflict risk.

## Out of Scope

- Automated gate file validation hooks (future, could be added as a PostToolUse hook)
- Gate file templates as separate template files (instructions live in the SOP reference)
- Changes to Tier 1 or Tier 2 commands (gate files are Tier 3 only)
- Modifications to `work-deep.md` (owned by another stream)
- Modifications to `work-harness.md` (owned by another stream)
