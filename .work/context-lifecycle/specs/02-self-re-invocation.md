# Spec 02: Self-Re-Invocation at Step Gates (C2)

**Component**: C2 | **Scope**: Medium | **Phase**: 1 | **Dependencies**: spec 00

## Overview

Modify work commands so that step transitions re-invoke the command via `Skill()` rather than continuing inline. This places the full command instructions at the END of the context window — the highest-attention zone. The PostCompact hook (C3) provides the mechanical backup for the compaction path.

## Implementation Steps

### Step 1: Add re-invocation instruction to the Context Compaction Protocol

The Context Compaction Protocol section (shared across all three work commands) already says "Tell the user: Run `/compact` then `/work-deep`". Add an explicit agent-side re-invocation fallback.

**Current text** (in each work command's Context Compaction Protocol):
```markdown
**If the user continues without compacting** (e.g., responds with "just continue"): Proceed, but re-read the handoff prompt and all rule files listed in the transition substep.
```

**New text**:
```markdown
**If the user continues without compacting** (e.g., responds with "just continue"): Re-invoke this command via `Skill('<command-name>')` to refresh instructions at the end of the context window. Then re-read the handoff prompt and all rule files listed in the transition substep. Note that accumulated context from the completed step increases the risk of instruction drift under context pressure.
```

Where `<command-name>` is `work-deep`, `work-feature`, or `work-fix` depending on the file.

**Acceptance criteria**:
- All three work commands include the Skill() re-invocation instruction
- The instruction uses the correct command name for each file
- Language is direct but not aggressive (no "CRITICAL" or "MUST" — per research finding that Claude 4.6+ responds better to normal language)

### Step 2: Add re-invocation to each step transition's approval block

In each auto-advance block (step `g` or `h` depending on the command), after "On user approval", add the re-invocation instruction before the compaction protocol.

**Insertion point** (in each gate's approval block, after state.json update):
```markdown
h. **Context compaction**: Apply the Context Compaction Protocol — tell the user to run `/compact` then `/<command>` to start **<next-step>** with clean context, then stop. If user continues without compacting, re-invoke via `Skill('<command>')` before proceeding.
```

**Acceptance criteria**:
- Every step transition block includes the re-invocation fallback
- The "if user continues without compacting" path always calls Skill()
- work-deep.md: 5 transitions updated (research→plan, plan→spec, spec→decompose, decompose→implement, implement→review)
- work-feature.md: 2 transitions updated (plan→implement, implement→review)
- work-fix.md: 1 transition updated (implement→review)

## Interface Contracts

**Exposes**:
- Prompt-driven re-invocation instruction (consumed by the LLM at runtime)

**Consumes**:
- Spec 00: file path conventions for work command locations

**Interaction with C3 (PostCompact hook)**:
- C2 handles the "user continues without compacting" path → agent calls Skill()
- C3 handles the "user compacts" path → hook suggests re-invocation
- Together they cover both paths; either alone is incomplete

## Files to Create/Modify

| File | Action |
|------|--------|
| `~/.claude/commands/work-deep.md` | **Modify** — update Context Compaction Protocol + 5 transition blocks |
| `~/.claude/commands/work-feature.md` | **Modify** — update Context Compaction Protocol + 2 transition blocks |
| `~/.claude/commands/work-fix.md` | **Modify** — update Context Compaction Protocol + 1 transition block |

## Testing Strategy

- **Manual verification**: Read each modified command, confirm Skill() instruction is present at every gate
- **Runtime validation**: In the next work session after implementation, observe whether the agent re-invokes when user says "continue" without compacting
- **No automated tests**: These are prompt instructions, not executable code

## Deferred Question Resolution

**Q2 — Self-re-invocation wording**: Use direct, plain language. The instruction reads:
> "Re-invoke this command via `Skill('<command-name>')` to refresh instructions at the end of the context window."

No "CRITICAL", "MUST", "ABSOLUTELY" prefixes. Research showed Claude 4.6+ follows normal-language instructions with equal or better compliance than aggressive framing.
