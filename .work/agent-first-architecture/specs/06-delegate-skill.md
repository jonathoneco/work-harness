# Spec 06: `/delegate` Skill (C6)

**Component**: C6 — `/delegate` Skill
**Scope**: Small
**Dependencies**: Spec 00 (cross-cutting contracts), Spec 01 (context seeding), Spec 02 (prompt templates)
**Phase**: 3

## Overview

User-facing command that enables ad-hoc delegation of sub-tasks to agents with proper context seeding. The user describes what they want delegated, and the skill infers the task type, constructs an appropriate agent prompt using the established patterns, and returns the agent's output.

**Use cases**:
- Delegate a sub-task mid-step without full step machinery
- Parallelize something the harness doesn't auto-parallelize
- Quick delegation with proper context seeding (vs raw Agent tool usage)

---

## Implementation Steps

### Step 1: Create the delegate command

**File**: `claude/commands/delegate.md` (new)

#### 1.1 Command Interface

```
/delegate <description>
```

The description is a natural language task description. Examples:
- `/delegate research how Agent Teams handles session resume`
- `/delegate write tests for the context seeding protocol`
- `/delegate review the dispatcher changes for edge cases`

#### 1.2 Context Inference

The command reads current context to build the agent prompt:

1. **Active task** (if any): Read state.json for task context, current step
2. **Recent conversation**: Use the user's description + any recent conversation context
3. **Task type inference**: Match the description to a routing category (see §1.3)

#### 1.3 Routing Table

| Pattern | Route To | Agent Config |
|---------|----------|-------------|
| "research ..." / "investigate ..." / "explore ..." | Explore agent | `subagent_type: "Explore"`, read-only |
| "review ..." / "check ..." / "audit ..." | Review agent | `subagent_type: "general-purpose"`, `mode: "default"` |
| "write ..." / "create ..." / "implement ..." | Implementation agent | `subagent_type: "general-purpose"`, `mode: "default"` |
| "plan ..." / "design ..." / "architect ..." | Plan agent | `subagent_type: "Plan"`, read-only |
| "test ..." | Test agent | `subagent_type: "general-purpose"`, `mode: "default"` |
| (ambiguous) | General agent | `subagent_type: "general-purpose"`, `mode: "default"` |

Pattern matching is keyword-based on the first word(s) of the description. If ambiguous, default to general-purpose.

#### 1.4 Prompt Construction

1. Read context seeding protocol (`claude/skills/work-harness/context-seeding.md`)
2. Build prompt using spec 00 §1 structure:
   - **Identity**: "You are a delegate agent. Your task: {user's description}"
   - **Task Context**: Standard preamble from state.json (if active task) or minimal context
   - **Rules**: Skill injection per spec 00 §3 (at minimum: code-quality)
   - **Instructions**: The user's description, expanded with any relevant context
   - **Output Expectations**: "Write artifacts to appropriate locations. Return a summary of what you did."
   - **Completion**: Spec 00 §6 format
3. Spawn agent with routing config from §1.3
4. Return agent's output to user

#### 1.5 No-Task Mode

If no active task exists:
- Skip Task Context preamble (no state.json to read)
- Include only Rules section (skill injection)
- Use the user's description as-is for Instructions

### Step 2: Register the command

Ensure `claude/commands/delegate.md` is discoverable as a slash command.

---

## Interface Contracts

### Exposes
- **`/delegate` command**: User-facing skill for ad-hoc agent delegation

### Consumes
- **Spec 00 §1**: Agent prompt structure
- **Spec 00 §2**: Standard preamble (when active task exists)
- **Spec 00 §3**: Skill injection
- **Spec 00 §6**: Completion signal format
- **Spec 01**: Context seeding protocol (per-step context rules)
- **Spec 02**: Prompt template patterns (reused for prompt construction)

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/commands/delegate.md` | Delegate command definition |

---

## Testing Strategy

### Routing Validation
- [ ] "research X" routes to Explore agent
- [ ] "review X" routes to general-purpose agent
- [ ] "write X" routes to general-purpose agent
- [ ] Ambiguous descriptions default to general-purpose

### Context Seeding Validation
- [ ] With active task: prompt includes standard preamble from state.json
- [ ] Without active task: prompt works with minimal context
- [ ] Skill injection always includes code-quality.md

---

## Acceptance Criteria

- [ ] `delegate.md` exists at `claude/commands/delegate.md`
- [ ] Command accepts natural language description
- [ ] Routing table covers research, review, implementation, plan, and test categories
- [ ] Prompt construction follows spec 00 §1 structure
- [ ] Context seeding uses spec 01 protocol
- [ ] Works with and without an active task
- [ ] Agent output is returned to user
