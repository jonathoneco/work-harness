# Spec 03: Step Agent Dispatcher (C1)

**Component**: C1 — Step Agent Dispatcher
**Scope**: Medium
**Dependencies**: Spec 00 (cross-cutting contracts), Spec 01 (context seeding), Spec 02 (prompt templates)
**Phase**: 1

## Overview

Replace inline execution blocks for plan, spec, and decompose steps with agent-spawning dispatchers. Steps are modular building blocks — the same dispatch pattern applies regardless of tier. This means Tier 2's plan step uses the same dispatcher as Tier 3's.

Each dispatcher constructs the agent prompt using the context seeding protocol (spec 01) and prompt templates (spec 02), spawns a foreground agent, handles the draft-and-present interaction (D1), and integrates with existing Phase A/B validation.

**Does NOT change**: Step routing logic, Phase A/B validation protocol, state transitions, handoff prompt format, or what steps produce. Only HOW they execute changes — from inline to agent-delegated.

---

## Implementation Steps

### Step 1: Define the dispatch function

The dispatcher is not code — it's a prompt pattern in `work-deep.md`. For each delegated step, the current inline instructions are replaced with a dispatch block.

**Dispatch block structure** (replaces inline instructions for plan/spec/decompose):

```markdown
### Dispatch: {step} Agent

1. **Construct prompt**: Read `claude/skills/work-harness/step-agents.md` for the {step} template.
   Fill variables from state.json:
   - `{name}` ← state.name
   - `{title}` ← state.title
   - `{tier}` ← state.tier
   - `{current_step}` ← state.current_step
   - `{base_commit}` ← state.base_commit
   - `{beads_epic_id}` ← state.beads_epic_id

2. **Spawn agent**:
   ```
   Agent(
     description: "{step} {name-abbreviated}",
     prompt: {constructed prompt},
     mode: "default",
     subagent_type: "general-purpose"
   )
   ```

3. **Read return**: Parse the agent's completion signal (spec 00 §6).

4. **Verify artifacts**: Check that all expected artifacts exist (quick file existence check).
   - If artifacts missing: treat as crash (spec 00 §7), re-spawn.

5. **Present to user**: Show the agent's summary. Include:
   - What the agent produced (artifact list with paths)
   - Key decisions or notable items from the summary
   - Ask: "Review the artifacts, or proceed to validation?"

6. **Handle user feedback**:
   - If user approves or says "proceed": run Phase A/B validation (unchanged).
   - If user has feedback: construct re-spawn prompt per spec 00 §5.
     Re-spawn the agent with feedback. Return to step 3.
   - Track attempt count. After 2 re-spawns with feedback, escalate per spec 00 §5.
```

### Step 2: Replace plan step inline instructions

**File**: `claude/commands/work-deep.md`

**Current** (when current_step = "plan"):
The plan step currently has ~40 lines of inline instructions telling the lead agent to:
- Read research handoff
- Write architecture.md
- Update feature summary
- Write plan handoff prompt
- Run Phase A/B validation

**New**: Replace the inline instructions between "When current_step = plan" and the auto-advance block with the dispatch block from Step 1, parameterized for the plan step.

**Preserve**: The auto-advance block (Phase A/B validation, verdict handling, state transition, context compaction) remains unchanged. It runs AFTER the dispatch block completes successfully.

### Step 3: Replace spec step inline instructions

**File**: `claude/commands/work-deep.md`

Same pattern as Step 2, but for the spec step:
- Replace inline instructions with dispatch block parameterized for spec
- Preserve auto-advance block

### Step 4: Replace decompose step inline instructions

**File**: `claude/commands/work-deep.md`

Same pattern as Steps 2-3, but for the decompose step:
- Replace inline instructions with dispatch block parameterized for decompose
- Preserve auto-advance block

**Note**: The decompose agent creates beads issues (via `bd create` in bash). This is the one exception to the "agents don't create beads issues" rule in spec 00 §8. The decompose template (spec 02) explicitly includes these bash commands.

### Step 5: Replace Tier 2 plan step inline instructions

**File**: `claude/commands/work-feature.md`

Same dispatch block as Step 2, using the plan agent template. Steps are building blocks — the plan dispatch is identical regardless of whether it runs in a Tier 2 or Tier 3 context. The agent template handles both (the preamble includes tier, but the plan instructions are the same).

### Step 6: Preserve research and implement steps

The research and implement steps already use subagent delegation. They are NOT modified by this spec. Changes to these steps are handled by spec 04 (delegation audit) and spec 05 (Agent Teams).

---

## Dispatch Flow Diagram

```
Lead reads current_step from state.json
    │
    ├── "plan" / "spec" / "decompose"
    │       │
    │       ├── Read step-agents.md for template
    │       ├── Fill variables from state.json
    │       ├── Spawn foreground agent (mode: default)
    │       │       │
    │       │       ├── Agent reads rules, handoff, context
    │       │       ├── Agent produces artifacts in .work/
    │       │       └── Agent returns completion signal
    │       │
    │       ├── Parse completion signal
    │       ├── Verify artifacts exist
    │       │       │
    │       │       ├── Missing → re-spawn (crash protocol)
    │       │       └── Present → continue
    │       │
    │       ├── Present summary to user
    │       │       │
    │       │       ├── User approves → Phase A/B validation
    │       │       ├── User feedback → re-spawn with feedback
    │       │       └── 2 failures → escalate to user
    │       │
    │       └── Phase A/B validation (unchanged)
    │
    ├── "research" → existing subagent pattern (unchanged)
    ├── "implement" → existing stream pattern (unchanged)
    └── "review" → existing /work-review delegation (unchanged)
```

---

## Interface Contracts

### Exposes
- **Dispatch block pattern**: Reusable pattern for spawning step agents with feedback loop
- **Variable substitution convention**: How state.json fields map to template variables

### Consumes
- **Spec 00 §1**: Agent prompt structure (section ordering for constructed prompts)
- **Spec 00 §5**: Retry/feedback protocol (re-spawn prompt construction)
- **Spec 00 §6**: Completion signal format (parsing agent returns)
- **Spec 00 §7**: Crash handling (missing artifacts, agent errors)
- **Spec 01**: Context seeding protocol (what to pass per step)
- **Spec 02**: Step agent prompt templates (actual prompt text)
- **Existing Phase A/B protocol**: `claude/skills/work-harness/phase-review.md`

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/commands/work-deep.md` | Replace inline plan/spec/decompose instructions with dispatch blocks |
| Modify | `claude/commands/work-feature.md` | Replace inline plan step instructions with dispatch block |

**Lines affected** (approximate, based on current file structure):
- `work-deep.md` plan step: Replace process instructions (between "When current_step = plan" header and "Auto-advance" header)
- `work-deep.md` spec step: Replace process instructions (between "When current_step = spec" header and "Auto-advance" header)
- `work-deep.md` decompose step: Replace process instructions (between "When current_step = decompose" header and "Auto-advance" header)
- `work-feature.md` plan step: Replace process instructions with same dispatch block

**Not affected**:
- Step Router (reads current_step, unchanged)
- Auto-advance blocks (Phase A/B, verdict, state transition, compaction)
- Research step (separate delegation pattern, addressed in spec 05)
- Implement step (stream-based delegation, unchanged)
- Review step (delegates to /work-review, unchanged)
- Inter-Step Quality Review Protocol section
- Context Compaction Protocol section

---

## Testing Strategy

### Structural Verification
- [ ] Plan step in work-deep.md contains dispatch block, not inline instructions
- [ ] Spec step in work-deep.md contains dispatch block, not inline instructions
- [ ] Decompose step in work-deep.md contains dispatch block, not inline instructions
- [ ] Each dispatch block references step-agents.md for the template
- [ ] Each dispatch block lists all variable substitutions from state.json

### Behavioral Verification
- [ ] Running plan step spawns a foreground agent (not inline execution)
- [ ] Agent produces architecture.md, handoff prompt, and feature summary
- [ ] Agent's completion signal is parseable by the lead
- [ ] User feedback triggers re-spawn with feedback context
- [ ] Phase A/B validation runs after successful agent completion
- [ ] State transition occurs only after user approval (unchanged behavior)

### Regression Check
- [ ] Research step still works (not modified)
- [ ] Implement step still works (not modified)
- [ ] Review step still works (not modified)
- [ ] Phase A/B validation still receives the same artifacts (just produced by agent instead of inline)

---

## Acceptance Criteria

- [ ] `work-deep.md` plan step uses dispatch block instead of inline instructions
- [ ] `work-deep.md` spec step uses dispatch block instead of inline instructions
- [ ] `work-deep.md` decompose step uses dispatch block instead of inline instructions
- [ ] Dispatch block reads template from `step-agents.md`
- [ ] Dispatch block fills variables from state.json
- [ ] Dispatch block spawns agent with `mode: "default"`, `subagent_type: "general-purpose"`
- [ ] Feedback loop supports 2 re-spawns before escalation
- [ ] Crash handling follows spec 00 §7
- [ ] Auto-advance blocks (Phase A/B, state transition) are unchanged
- [ ] Research, implement, and review steps are not modified
