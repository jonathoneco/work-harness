# Spec 05: Gate Approval Re-Confirmation (C5)

**Component**: C5 | **Scope**: Small–Medium | **Phase**: 1 | **Dependencies**: spec 00

## Overview

Fix ALL state transitions to require explicit user approval before updating state.json. Two observed failure modes:

1. **Discussion-as-approval** (rag-idnu7): Agent answers follow-up questions at a step gate, then advances state without re-confirming.
2. **Presentation-as-approval**: Agent presents review results and updates state.json in the same turn without waiting for user response.

Root cause: The protocol says "STOP and wait for user acknowledgment" but doesn't define what counts as acknowledgment, and the instruction degrades under context pressure.

## Implementation Steps

### Step 1: Replace the approval block in every step transition

Each work command has step transitions with an approval flow at steps `e` through `h`. Replace the approval section with a more explicit protocol.

**Current pattern** (in all three work commands):
```markdown
e. **Present detailed summary to user**: [artifacts]
f. **STOP — wait for user acknowledgment.** User may want to discuss findings or ask questions.
g. **On user approval**: Create gate issue...
```

**New pattern**:
```markdown
e. **Present detailed summary to user**: [artifacts]. End with:
   "Ready to advance to **<next-step>**? (yes/no)"
f. **STOP.** Do NOT update state.json in this turn. Do NOT create gate issues in this turn.
f'. **If the user asks questions or provides feedback**: Answer them. Then re-present the confirmation:
    "Ready to advance to **<next-step>**? (yes/no)"
    Wait for a new response. Do NOT advance state after answering questions.
g. **On explicit approval** — user responds with an affirmative signal (see spec 00 approval definitions):
   Create gate issue, update state.json. These happen in a SEPARATE turn from presenting results.
```

**Transitions to update**:

| Command | Transition | Location |
|---------|-----------|----------|
| work-deep.md | research → plan | Auto-advance block, steps e-h |
| work-deep.md | plan → spec | Auto-advance block, steps e-h |
| work-deep.md | spec → decompose | Auto-advance block, steps e-h |
| work-deep.md | decompose → implement | Auto-advance block, steps e-h |
| work-deep.md | implement → review | Auto-advance block, steps e-h |
| work-feature.md | plan → implement | Auto-advance block |
| work-feature.md | implement → review | Auto-advance block |
| work-fix.md | implement → review | Auto-advance block |

Total: **8 transitions** across 3 files.

**Note on command structure differences**: `work-deep.md` uses the full Phase A/B review protocol with `e-f-g-h` blocks at each transition. `work-feature.md` and `work-fix.md` use simpler inline advance patterns (e.g., "Advance: Update state.json..."). When implementing spec 05 in the simpler commands, adapt the approval pattern to their existing format — add the "Ready to advance?" prompt and "Do NOT update state.json in this turn" instruction without imposing the full `e-f-g-h` block structure where it doesn't exist.

**Acceptance criteria**:
- All 8 transitions use the new approval pattern
- Each transition ends the summary with "Ready to advance to **<next-step>**? (yes/no)"
- The "f'" step (re-confirmation after Q&A) is present in every transition
- The instruction "Do NOT update state.json in this turn" is explicit in every transition
- Gate issue creation and state updates happen in step g, never in step e or f

### Step 2: Update the Inter-Step Quality Review Protocol

The protocol section (shared preamble in work-deep.md) describes the general transition behavior. Update it to match the new approval pattern.

**Current text** (in the "Transition behavior" section):
```markdown
1. **Present a detailed summary** to the user...
2. **STOP and wait for user acknowledgment.**
3. **Only after the user approves**: create the gate issue, update state.json...
```

**New text**:
```markdown
1. **Present a detailed summary** to the user. End with: "Ready to advance to **<next-step>**? (yes/no)"
2. **STOP.** Do NOT update state.json or create gate issues in the same turn as presenting results.
3. **If the user asks questions or gives feedback**: Answer, then re-ask: "Ready to advance to **<next-step>**? (yes/no)". Answering questions is NOT approval.
4. **On explicit approval** (user says yes/proceed/approve/lgtm — see spec 00 approval signals): Create gate issue, update state.json. This MUST be a separate turn from presenting results.
```

Also update the "Critical ordering" note:
```markdown
**Critical ordering**: State updates and result presentation NEVER occur in the same agent turn. Gate issues are created only after an explicit approval signal in a dedicated user message. Answering follow-up questions resets the approval requirement.
```

**Acceptance criteria**:
- The Inter-Step Quality Review Protocol includes explicit approval signal definitions
- The "answering questions is NOT approval" rule is stated clearly
- The "separate turn" requirement is explicit
- The protocol references spec 00 for the canonical approval signal list

### Step 3: Add the same pattern to the implement phase gating

The implement step has internal phase gates (between implementation phases) with a similar approval flow. Update these too.

**Current text** (in implement step):
```markdown
- Present review results to user. **Wait for user acknowledgment** before starting Phase N+1.
- Only proceed to Phase N+1 when user approves and Phase N validation is PASS or ADVISORY
```

**New text**:
```markdown
- Present review results to user. End with: "Phase N complete. Ready to start Phase N+1? (yes/no)"
- **STOP.** Do NOT start Phase N+1 in the same turn as presenting Phase N results.
- If the user asks questions: answer, then re-ask: "Ready to start Phase N+1? (yes/no)"
- On explicit approval: proceed to Phase N+1
```

**Acceptance criteria**:
- Implement phase gates use the same approval pattern as step transitions
- Phase N results and Phase N+1 work never occur in the same agent turn

## Interface Contracts

**Exposes**:
- Fixed approval protocol (consumed by the LLM at runtime across all work commands)

**Consumes**:
- Spec 00: approval signal definitions, state.json contract

## Files to Create/Modify

| File | Action |
|------|--------|
| `~/.claude/commands/work-deep.md` | **Modify** — update 5 transitions + Inter-Step Quality Review Protocol + implement phase gates |
| `~/.claude/commands/work-feature.md` | **Modify** — update 2 transitions |
| `~/.claude/commands/work-fix.md` | **Modify** — update 1 transition |

## Testing Strategy

- **Observational**: In the next step transition after implementation, verify:
  - Summary ends with "Ready to advance?" prompt
  - Asking a follow-up question triggers re-confirmation
  - State.json is not updated until a separate approval turn
- **Regression check**: Review git diff of work commands to ensure no transitions were missed
- **No automated tests**: Behavioral protocol, not executable code

## Key Principles (from spec 00, restated for clarity)

1. Answering questions ≠ approval
2. Presenting results ≠ approval
3. State updates and result presentation NEVER in the same agent turn
4. After any Q&A exchange, re-present the approval prompt
5. The ONLY valid approval: explicit affirmative in a user message AFTER results were presented
