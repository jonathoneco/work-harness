# Spec 04: Explore Phase Clarity

**Component**: C04
**Phase**: 2 (Workflow Mechanics)
**Dependencies**: C02 (Spec 02 — verdict system redesign)
**Cross-cutting contracts**: Spec 00 — ASK verdict format (used for pushback that surfaces as ASK)

## Overview and Scope

**Does**:
1. Add a pre-research clarity protocol to `work-deep.md` (T3) — the research step starts with scope validation and pushback questions
2. Add a pre-plan clarity protocol to `work-feature.md` (T2) — the plan step starts with task understanding validation
3. Define the pushback mechanism: structured questionnaire, user response, scope refinement
4. Define the feedback loop: answers are incorporated before the agent proceeds

**Does NOT**:
- Create a new step in the lifecycle (clarity is a protocol within existing steps, not a separate step)
- Block research/planning from starting (the agent starts, validates, and pushes back if needed — not a gate)
- Apply to T1 (work-fix has no research or plan step)
- Change inter-step review or verdicts (those are handled by Specs 02/03)

## Implementation Steps

### Step 1: Define the clarity questionnaire format

**Action**: Establish a structured format for pushback questions that agents use to validate scope before proceeding.

**Acceptance criteria**:
- [ ] AC-1.1: Questionnaire format is defined as:
  ```
  ## Scope Clarification Needed

  Before proceeding, I need to understand:

  1. **[Topic]**: [Specific question about scope, intent, or constraint]
  2. **[Topic]**: [Specific question]
  ...

  Please answer these so I can {research the right topics / plan the right approach}.
  ```
- [ ] AC-1.2: Maximum 5 questions per questionnaire (same cap as ASK verdicts for consistency)
- [ ] AC-1.3: Each question must be about scope, intent, constraints, or priorities — not implementation details

### Step 2: Add pre-research clarity protocol to work-deep.md

**Action**: Update the research step section in `work-deep.md` to include a clarity phase at the start.

**Acceptance criteria**:
- [ ] AC-2.1: Research step instructions include a "Scope Validation" sub-step as the first action
- [ ] AC-2.2: Scope validation reads: "Before dispatching research agents, review the task description and assessment. If the research scope is ambiguous, unclear, or potentially misaligned with the user's intent, present a clarity questionnaire."
- [ ] AC-2.3: If the agent has no clarification questions, it proceeds directly to research (no forced questionnaire)
- [ ] AC-2.4: User responses to the questionnaire are incorporated into the research scope — the agent restates the refined scope before dispatching research agents
- [ ] AC-2.5: Refined scope is captured in the research handoff prompt as a "Scope Refinements" section (only if clarification occurred)

### Step 3: Add pre-plan clarity protocol to work-feature.md

**Action**: Update the plan step section in `work-feature.md` to include task understanding validation.

**Acceptance criteria**:
- [ ] AC-3.1: Plan step instructions include a "Task Understanding Check" sub-step as the first action
- [ ] AC-3.2: The check reads: "Before dispatching the plan agent, review the task description. If the task scope, success criteria, or constraints are unclear, present a clarity questionnaire to the user."
- [ ] AC-3.3: If the agent has no clarification questions, it proceeds directly to plan agent dispatch
- [ ] AC-3.4: User responses are captured and passed to the plan agent as additional context in its prompt

### Step 4: Define pushback escalation

**Action**: Define what happens when pushback questions reveal fundamental scope issues.

**Acceptance criteria**:
- [ ] AC-4.1: If user responses reveal the task needs re-scoping (e.g., "actually this is two separate features"), the agent presents the re-scoping as an explicit choice: proceed with refined scope, split into multiple tasks, or escalate tier
- [ ] AC-4.2: Re-scoping choices are presented inline — no new state or step is created
- [ ] AC-4.3: If tier escalation is chosen (T2→T3), the existing escalation protocol in `work-feature.md` handles it

### Step 5: Add pre-research clarity to work-deep.md plan step

**Action**: The plan step in `work-deep.md` also gets a clarity check — but scoped to validating the research handoff rather than the original task.

**Acceptance criteria**:
- [ ] AC-5.1: Plan step in `work-deep.md` includes: "Before dispatching the plan agent, review the research handoff prompt. If key topics are missing or research conclusions are unclear, present a clarity questionnaire about the research gaps."
- [ ] AC-5.2: This is distinct from the plan agent's inline research capability (Spec 05) — clarity questions go to the *user*, inline research goes to *subagents*
- [ ] AC-5.3: User responses to plan-step clarity questions are passed to the plan agent as supplementary context

## Interface Contracts

**Exposes**:
- Clarity questionnaire format — reused by Spec 07 (work-research) for its research scope validation
- Pre-step validation pattern — the concept of "validate before proceeding" that Spec 05 builds on

**Consumes**:
- Spec 02: ASK verdict format (the questionnaire format mirrors ASK for consistency, though clarity questions are not verdicts)

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/commands/work-deep.md` | Add scope validation to research step, add research handoff validation to plan step |
| Modify | `claude/commands/work-feature.md` | Add task understanding check to plan step |

## Testing Strategy

1. **Protocol presence**: Verify `work-deep.md` research step starts with "Scope Validation" sub-step
2. **Protocol presence**: Verify `work-feature.md` plan step starts with "Task Understanding Check" sub-step
3. **Optional path**: Verify both protocols include explicit "if no questions, proceed directly" language
4. **Refinement capture**: Verify `work-deep.md` documents capturing refined scope in the research handoff
5. **Escalation path**: Verify re-scoping choices are defined for fundamental scope issues
6. **Distinction check**: Verify `work-deep.md` plan step clarity (user questions) is distinct from inline research (subagent questions in Spec 05)
