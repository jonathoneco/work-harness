# Spec 05: Plan Agent Redesign

**Component**: C05
**Phase**: 2 (Workflow Mechanics)
**Dependencies**: C02 (Spec 02 — verdict system), C04 (Spec 04 — explore phase clarity)
**Cross-cutting contracts**: Spec 00 — plan agent inline research constraints (Contract 3)

## Overview and Scope

**Does**:
1. Update the plan agent template in `step-agents.md` with inline Explore subagent capability
2. Update plan step sections in `work-deep.md` and `work-feature.md` to reference the enhanced plan agent
3. Add "Inline Research Performed" section to the plan handoff prompt template

**Does NOT**:
- Create loopback machinery between plan and research steps (DD-4 decided against this)
- Add new state transitions or step lifecycle changes (DD-7)
- Change which agent type handles plan steps (still uses the Plan agent template)
- Modify the explore clarity protocol (that's Spec 04 — this spec adds *subagent* capability, not *user* pushback)

## Implementation Steps

### Step 1: Add inline research instruction to plan agent template

**Action**: Update the Plan agent template in `step-agents.md` to include the inline research capability.

**Acceptance criteria**:
- [ ] AC-1.1: Plan agent template includes a new section titled "## Inline Research" (or equivalent) with the instruction:
  "If you encounter gaps in the research handoff that you cannot resolve from the provided context, you may spawn up to 3 Explore subagents with targeted questions. Each subagent returns a summary (max 1,500 tokens). Incorporate findings into your architecture document."
- [ ] AC-1.2: The constraints table from Spec 00, Contract 3 is referenced or inlined
- [ ] AC-1.3: The "When NOT to Use" guidance from Spec 00, Contract 3 is included — specifically: emit ASK verdict for user-judgment gaps, don't use for fundamentally insufficient research
- [ ] AC-1.4: The instruction is positioned after the "Instructions" section and before "Output Expectations"

### Step 2: Add "Inline Research Performed" to plan handoff template

**Action**: Update the plan handoff prompt template in `step-agents.md` to include a section for documenting inline research.

**Acceptance criteria**:
- [ ] AC-2.1: Plan handoff prompt template includes an "## Inline Research Performed" section
- [ ] AC-2.2: Section format is:
  ```
  ## Inline Research Performed

  _(none — or list)_

  1. **Gap**: [What was missing from research handoff]
     **Finding**: [What the Explore subagent discovered]
     **Impact**: [How this affected the architecture]
  ```
- [ ] AC-2.3: If no inline research was performed, the section shows `_(none)_`
- [ ] AC-2.4: This section appears after "Items Deferred to Spec" in the handoff prompt

### Step 3: Update work-deep.md plan step for inline research awareness

**Action**: Update the plan step section in `work-deep.md` to reference the enhanced plan agent.

**Acceptance criteria**:
- [ ] AC-3.1: Plan step mentions that the plan agent may spawn Explore subagents for gap-filling
- [ ] AC-3.2: No new dispatcher logic is added — the plan agent handles subagent spawning internally
- [ ] AC-3.3: The plan step still references the same plan agent template from `step-agents.md`

### Step 4: Update work-feature.md plan step for inline research awareness

**Action**: Update the plan step section in `work-feature.md` similarly.

**Acceptance criteria**:
- [ ] AC-4.1: Plan step in `work-feature.md` mentions inline research capability
- [ ] AC-4.2: For T2 (which has no research step), the plan agent may use all 3 subagent slots for initial investigation since there's no prior research handoff
- [ ] AC-4.3: The agent template is the same for T2 and T3 — the difference is what input the plan agent receives (task description for T2, research handoff for T3)

### Step 5: Distinguish inline research from explore clarity

**Action**: Ensure clear boundaries between Spec 04's clarity protocol and Spec 05's inline research.

**Acceptance criteria**:
- [ ] AC-5.1: `work-deep.md` plan step makes the distinction explicit: clarity questions go to the *user* (Spec 04), inline research goes to *Explore subagents* (this spec)
- [ ] AC-5.2: The ordering is: (1) clarity questionnaire (user-facing, optional), then (2) plan agent dispatch with inline research capability (agent-internal)
- [ ] AC-5.3: A plan agent that encounters a gap requiring user judgment emits an ASK verdict rather than spawning a subagent

## Interface Contracts

**Exposes**:
- Enhanced plan agent template in `step-agents.md` — available to any workflow that dispatches plan agents
- "Inline Research Performed" section in plan handoff prompt — consumed by spec agents and plan→spec gate reviewers

**Consumes**:
- Spec 00, Contract 3: Inline research constraints (max subagents, token caps, allowed tools)
- Spec 04: Explore clarity pattern (this spec builds on it, must not conflict)
- Spec 02: ASK verdict (plan agent emits ASK when gaps require user judgment)

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/skills/work-harness/step-agents.md` | Add inline research section to Plan agent template, add "Inline Research Performed" to handoff template |
| Modify | `claude/commands/work-deep.md` | Update plan step to reference enhanced plan agent with inline research |
| Modify | `claude/commands/work-feature.md` | Update plan step to reference enhanced plan agent with inline research |

## Testing Strategy

1. **Template verification**: Read `step-agents.md` Plan agent template — verify inline research section exists with correct constraints
2. **Constraint check**: Verify max 3 subagents, 1,500 token cap, read-only tools are specified
3. **Handoff template**: Verify "Inline Research Performed" section is in the plan handoff prompt template
4. **Distinction check**: Read `work-deep.md` plan step — verify clarity (user) and inline research (subagent) are clearly separated
5. **T2 handling**: Verify `work-feature.md` notes that all 3 subagent slots are available since T2 has no prior research
6. **ASK fallback**: Verify the template instructs the plan agent to emit ASK for user-judgment gaps, not spawn subagents
