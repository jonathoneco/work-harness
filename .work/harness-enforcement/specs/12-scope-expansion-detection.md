# 12: Scope Expansion Detection

## Overview

When a user requests changes that expand the scope of a task (new components, new work items, new specs), the agent should detect it's doing plan/spec work while in a later step and acknowledge the regression rather than silently adding scope.

## The Problem

During the harness-enforcement workflow, the user requested 3 QoL improvements while at the decompose step. The agent in the other session:
- Added Components 7-9 to the architecture (plan-level work)
- Wrote specs 07-09 (spec-level work)
- Created beads issues W-11-W-13 (decompose-level work)

**Meta-note:** This spec (12) is itself an example of scope expansion — it was added to the harness-enforcement task during decompose, along with specs 10 and 11. The difference: this expansion was acknowledged by the user and documented as an intentional amendment to the plan.
- Did all of this without acknowledging it was regressing through earlier steps

This is the same progressive discipline collapse pattern — the agent "vibes" through state rather than following the harness.

## Detection Heuristic

Add to each step section in `/work-deep`:

```markdown
**Scope expansion check:** If the user requests changes that would add new components,
specs, or work items beyond what was planned in the previous steps, acknowledge the
regression:

1. "This adds new scope. We're currently in [step] but this requires [plan/spec] work."
2. Present options:
   a. **Formal:** Roll back current_step to plan/spec, properly integrate, then re-advance
   b. **Amendment:** Add to architecture + specs + decompose as an amendment, note the
      scope change in the handoff prompt, continue
3. User decides which path
4. Either way, document the scope change in the handoff prompt for this step
```

## When to Trigger

| Current Step | User Requests | Detection |
|-------------|--------------|-----------|
| decompose | New spec files | Creating `.work/<name>/specs/*.md` while `current_step` ≠ spec |
| decompose | Architecture changes | Modifying `.work/<name>/specs/architecture.md` while `current_step` ≠ plan |
| implement | New work items not in decompose | Creating beads issues not mapped to existing specs |
| implement | Architecture changes | Modifying architecture while `current_step` = implement |
| review | Any scope addition | Adding new code while `current_step` = review |

## Response Options

### Option A: Formal Rollback

```
Agent: "This adds 3 new components. Rolling back to spec step to properly integrate."
→ Update state.json: current_step = "spec", spec status = "active"
→ Write specs for new components
→ Run spec review
→ Advance through decompose (create work items)
→ Resume implement
```

### Option B: Lightweight Amendment

```
Agent: "This adds 3 new components. Adding as amendments to the current plan."
→ Update architecture.md with new components
→ Write brief spec notes (can be in architecture, don't need full numbered specs)
→ Create beads issues
→ Update streams handoff
→ Note the scope change: "Scope expanded during [step]: added Components N-M"
→ Continue in current step
```

## Not Hook-Enforced

This is **prompt-level guidance**, not a hook. Hooks can't detect semantic scope expansion (they can't tell if a new spec file is a planned deliverable or scope creep). The command text primes the agent to recognize the pattern.

## Files to Modify

- `.claude/commands/work-deep.md` — add scope expansion check to decompose, implement, and review step sections

## Dependencies

None — this is additive text. Can be added at any time.

## Testing

1. During decompose step, request a new component → expect agent acknowledges scope expansion
2. During implement step, request architecture changes → expect agent presents options
3. Verify scope change is documented in the step's handoff prompt
