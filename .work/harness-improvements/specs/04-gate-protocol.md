# Spec 04: Gate Protocol (C4)

**Component**: C4 | **Scope**: Medium | **Phase**: 1 | **Dependencies**: spec 00

## Overview

Formalize the file-based review UX pattern used at step transitions into a documented protocol with consistent directory structure, file naming, content sections, and rollback semantics. Today, the gate pattern exists informally (`.work/harness-improvements/gates/plan-to-spec.md` is an example), but there is no reference document, no naming convention enforcement, and no integration with state.json. This spec creates the SOP reference, wires gate files into the step transition flow, and records `gate_file` in state.json alongside the existing `gate_id`.

## Scope

**In scope:**
- Directory convention: `.work/<name>/gates/`
- File naming conventions for step transitions, phase gates, and ad-hoc reviews
- Standardized file structure with required sections
- Rollback gate semantics (new file referencing original, originals immutable post-approval)
- SOP reference document at `claude/skills/work-harness/references/gate-protocol.md`
- Modifications to `claude/commands/work-deep.md` to write gate files at each step transition
- State.json `gate_file` field (per spec 00)
- Iteration protocol: round markers within a single gate file for multi-round review

**Out of scope:**
- Automated gate file validation hooks (future, could be added as a PostToolUse hook)
- Gate file templates as separate template files (instructions live in the SOP reference)
- Changes to Tier 1 or Tier 2 commands (gate files are Tier 3 only, matching the existing gate issue pattern)

## Implementation Steps

### Step 1: Create the gate protocol SOP reference

**File**: `claude/skills/work-harness/references/gate-protocol.md`

This is the authoritative reference for creating, reviewing, and managing gate files. Commands and skills reference this document rather than inlining gate instructions.

**Contents:**

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

**AC-01**: Gate protocol reference exists at `claude/skills/work-harness/references/gate-protocol.md` with all six subsections (directory convention, file naming, file structure, iteration protocol, immutability rule, rollback gates) -- verified by `structural-review`

**AC-02**: File naming table covers all four gate types (step transition, implementation phase, ad-hoc review, rollback) with pattern and example -- verified by `structural-review`

**AC-03**: File structure template includes all seven sections (Summary, Review Results with Phase A and Phase B, Advisory Notes, Deferred Items, Next Step, Your Response) -- verified by `structural-review`

### Step 2: Create `gates/` directory during task initialization

Modify `claude/commands/work-deep.md` Step 3 (State Initialization) to include `gates/` in the list of directories created.

Current directory list (line ~49):
```
- `.work/<name>/research/`
- `.work/<name>/plan/`
- `.work/<name>/specs/`
- `.work/<name>/streams/`
```

Add:
```
- `.work/<name>/gates/`
```

**AC-04**: `work-deep.md` Step 3 directory creation list includes `.work/<name>/gates/` -- verified by `structural-review`

### Step 3: Wire gate file creation into step transitions

Modify each auto-advance block in `claude/commands/work-deep.md` to write a gate file before presenting results to the user. The gate file replaces the inline terminal summary as the primary review artifact.

**For each step transition** (research->plan, plan->spec, spec->decompose, decompose->implement, implement->review):

Insert between the Phase B review completion and the user presentation:

1. Write the gate file to `.work/<name>/gates/<from>-to-<to>.md` following the structure from the SOP reference
2. Populate all sections from the review results already gathered
3. Present the gate file path to the user: "Review file written to `.work/<name>/gates/<from>-to-<to>.md`. Open it in your editor to review, then respond here."
4. On explicit approval: record `gate_file: "gates/<from>-to-<to>.md"` in the step's status object in state.json (alongside existing `gate_id`)

**For implementation phase gates** (between phases within implement step):

1. Write `.work/<name>/gates/implement-phase-<N>.md` after phase validation completes
2. Same structure, with Phase A and Phase B results from the phase validation
3. Present path to user

**Invocation points in command execution flow** (resolves advisory A3):

```
/work-deep
  -> Step Router reads current_step
    -> research step completes
      -> Phase A + Phase B review run
      -> Gate file written: gates/research-to-plan.md    <-- HERE
      -> User reviews in editor
      -> User approves
      -> state.json updated with gate_id + gate_file
    -> plan step completes
      -> Gate file written: gates/plan-to-spec.md        <-- HERE
      -> User reviews, approves, state updated
    -> spec step completes
      -> Gate file written: gates/spec-to-decompose.md   <-- HERE
      -> User reviews, approves, state updated
    -> decompose step completes
      -> Gate file written: gates/decompose-to-implement.md  <-- HERE
      -> User reviews, approves, state updated
    -> implement phase N completes
      -> Gate file written: gates/implement-phase-N.md   <-- HERE
      -> User reviews, approves, next phase starts
    -> implement step completes (all phases done)
      -> Gate file written: gates/implement-to-review.md <-- HERE
      -> User reviews, approves, state updated
```

**AC-05**: Each of the six auto-advance blocks in `work-deep.md` writes a gate file before presenting results to the user -- verified by `structural-review`

**AC-06**: Gate file paths use the naming conventions from the SOP reference (step transitions: `<from>-to-<to>.md`, phases: `implement-phase-<N>.md`) -- verified by `structural-review`

**AC-07**: Each auto-advance block records `gate_file` in the step's state.json status object on approval -- verified by `structural-review`

### Step 4: Update state-conventions reference

Add `gate_file` field documentation to `claude/skills/work-harness/references/state-conventions.md`, per spec 00 section 2.

Add to the Step Status Object section:
```json
{
  "gate_file": "string|null -- relative path from .work/<name>/ to the gate review file, Tier 3 only"
}
```

**AC-08**: `state-conventions.md` Step Status Object section documents `gate_file` as an optional string field with description matching spec 00 -- verified by `structural-review`

### Step 5: Update the work-harness skill to reference gate protocol

Add the gate protocol reference to `claude/skills/work-harness.md` in the References section.

Add:
```markdown
- **gate-protocol** -- Gate file SOP: directory layout, naming, structure, iteration, rollback (path: `claude/skills/work-harness/references/gate-protocol.md`)
```

Also add a brief "Gate Files" subsection to the Key Concepts or Step Transitions section:
```markdown
## Gate Files

Step transitions produce gate files at `.work/<name>/gates/`. These are the primary review artifact -- the user reviews them in their editor rather than scrolling terminal output. See the gate-protocol reference for naming conventions, file structure, and rollback semantics.
```

**AC-09**: `work-harness.md` References section lists `gate-protocol` with correct path -- verified by `structural-review`

**AC-10**: `work-harness.md` has a Gate Files subsection explaining the pattern -- verified by `structural-review`

### Step 6: Migrate existing gate file to match conventions

The existing file `.work/harness-improvements/gates/plan-to-spec.md` already follows most of the conventions. Verify it matches the SOP structure and update if needed. This is a one-time migration task for the active initiative.

**AC-11**: Existing `plan-to-spec.md` has all seven required sections from the SOP structure, or differences are documented as acceptable variations -- verified by `structural-review`

## Interface Contracts

**Exposes:**
- `claude/skills/work-harness/references/gate-protocol.md` -- consumed by all commands that perform step transitions
- `.work/<name>/gates/` directory convention -- consumed by step transition logic, reviewers, archival
- `gate_file` field in step status objects -- consumed by any component reading step history

**Consumes:**
- Spec 00: `gate_file` state.json field schema, gate file naming convention, path conventions
- Inter-Step Quality Review Protocol in `work-deep.md` -- gate files are written after Phase A + Phase B complete
- Existing `gate_id` field -- `gate_file` is recorded alongside it, not replacing it

## Files

| File | Action | Description |
|------|--------|-------------|
| `claude/skills/work-harness/references/gate-protocol.md` | Create | SOP reference: naming, structure, iteration, immutability, rollback |
| `claude/commands/work-deep.md` | Modify | Add gate file writing to each auto-advance block; add `gates/` to initialization directories |
| `claude/skills/work-harness/references/state-conventions.md` | Modify | Document `gate_file` field in Step Status Object |
| `claude/skills/work-harness.md` | Modify | Add gate-protocol reference and Gate Files subsection |

## Testing Strategy

| What | Method | Details |
|------|--------|---------|
| SOP reference structure | `structural-review` | All six subsections present, naming table complete, file template has all seven sections |
| Directory creation | `manual-test` | Initialize a new Tier 3 task; verify `.work/<name>/gates/` directory is created |
| Gate file creation | `integration-test` | Complete a step transition in `/work-deep`; verify gate file is written with correct name and all sections populated |
| Iteration rounds | `manual-test` | Respond to a gate file with a question; verify round marker is added; approve; verify decision is recorded |
| Immutability | `manual-test` | After approval, verify the gate file is not modified by subsequent operations |
| Rollback gate | `manual-test` | Trigger a scope change during implement; verify rollback gate file is created referencing the original |
| State.json field | `manual-test` | After gate approval, read state.json; verify `gate_file` field is populated with correct relative path |
| Existing gate migration | `structural-review` | Compare `plan-to-spec.md` against SOP structure; document any variations |

## Deferred Questions Resolution

No deferred questions from the plan apply specifically to C4.

## Advisory Notes Resolution

**A3: Show where Gate Protocol is invoked in the command execution flow**

Addressed in Step 3 with a full invocation point diagram showing exactly where gate files are written in the `/work-deep` command flow. Each of the six transition points is annotated with the gate file it produces. This diagram is included in both the spec (for implementers) and the SOP reference (for runtime guidance).
