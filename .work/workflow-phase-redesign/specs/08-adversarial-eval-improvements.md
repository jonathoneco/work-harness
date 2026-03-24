# Spec 08: Adversarial Eval Improvements

**Component**: C08
**Phase**: 3 (New Capabilities)
**Dependencies**: C05 (Spec 05 — plan agent redesign, for skill injection into agent templates)
**Cross-cutting contracts**: None (self-contained capability)

## Overview and Scope

**Does**:
1. Create `claude/skills/adversarial-eval.md` — the adversarial eval skill with pluggable framings and Step 0 position elicitation
2. Update plan and spec agent templates in `step-agents.md` to include adversarial-eval skill injection
3. Define a framing registry with built-in templates and extension points for custom framings

**Does NOT**:
- Make adversarial eval a mandatory step or gate (DD-6 — it's optional, invocable during plan/spec)
- Create a standalone adversarial-eval command (it's a skill invoked by agents, not a user command)
- Add automated framing selection based on decision type (deferred — see futures.md)
- Track adversarial eval outcomes across tasks for learning (deferred — see futures.md)

## Implementation Steps

### Step 1: Define the adversarial eval protocol

**Action**: Establish the full adversarial eval flow, building on the existing `adversarial-eval` skill pattern.

**Acceptance criteria**:
- [ ] AC-1.1: Protocol has 4 phases: (0) Position Elicitation, (1) Opening Arguments, (2) Rebuttal, (3) Synthesis
- [ ] AC-1.2: Phase 0 (Position Elicitation) asks the user: "Before the evaluation begins, what is your current position on [decision]? Options: [derived from framing]. This helps calibrate the debate."
- [ ] AC-1.3: Phase 0 is skippable — user can respond "no position" or "skip" and the eval proceeds without anchoring
- [ ] AC-1.4: User's initial position is recorded and compared to the final recommendation in the synthesis

### Step 2: Define the framing registry

**Action**: Create a registry of named framing templates that shape the adversarial debate.

**Acceptance criteria**:
- [ ] AC-2.1: Each framing is a named template with: `name`, `description`, `position_a` (label + prompt), `position_b` (label + prompt), `evaluation_criteria` (what the synthesis weighs)
- [ ] AC-2.2: Built-in framings include:
  - `ship-vs-polish`: Ship the MVP now vs invest in polish first. Criteria: time-to-value, technical debt, user impact.
  - `build-vs-buy`: Build custom vs use existing tool/library. Criteria: maintenance burden, fit, cost, lock-in.
  - `paradigm-choice`: Approach A vs Approach B for a technical design decision. Criteria: complexity, extensibility, team familiarity.
- [ ] AC-2.3: Framings are defined inline in the skill file (not separate files — keep it simple for 3 built-ins)
- [ ] AC-2.4: Custom framings can be added by the user in `.claude/harness.yaml` under `adversarial_eval.framings` — same schema as built-ins

### Step 3: Define framing selection

**Action**: Specify how the agent selects which framing to use.

**Acceptance criteria**:
- [ ] AC-3.1: Agent selects framing based on the decision type — the skill provides guidance mapping decision categories to framings
- [ ] AC-3.2: If no built-in framing fits, the agent constructs an ad-hoc framing using the `paradigm-choice` template as a base, customizing position labels and criteria
- [ ] AC-3.3: The agent states which framing it chose and why before starting the eval
- [ ] AC-3.4: User can override the framing choice ("use build-vs-buy instead")

### Step 4: Define synthesis output format

**Action**: Specify what the adversarial eval produces.

**Acceptance criteria**:
- [ ] AC-4.1: Synthesis output format:
  ```
  ## Adversarial Eval: [Decision Name]

  **Framing**: [framing name]
  **User's initial position**: [position from Step 0, or "none stated"]

  ### Position A: [label]
  [Summary of strongest arguments]

  ### Position B: [label]
  [Summary of strongest arguments]

  ### Recommendation
  [Which position is stronger and why, referencing evaluation criteria]

  ### Conditions
  [Under what conditions the recommendation would change]

  ### Position Shift
  [Whether the recommendation differs from the user's initial position, and why]
  ```
- [ ] AC-4.2: The synthesis is incorporated into the architecture document (plan) or spec (spec) at the relevant design decision
- [ ] AC-4.3: The synthesis does not replace the agent's decision — it informs it. The agent makes the final call.

### Step 5: Create adversarial-eval.md skill file

**Action**: Write the skill file with YAML frontmatter, protocol, framings, and output format.

**Acceptance criteria**:
- [ ] AC-5.1: YAML frontmatter includes: `name: adversarial-eval`, `description` (mentions optional invocation during plan/spec phases)
- [ ] AC-5.2: Skill file contains: protocol (4 phases), framing registry (3 built-ins), selection guidance, output format, custom framing schema
- [ ] AC-5.3: Skill file includes "When to Invoke" guidance: "Invoke when facing a design decision with meaningful trade-offs where reasonable people could disagree. Do not invoke for clear-cut decisions or implementation details."
- [ ] AC-5.4: Skill file size is reasonable (under 200 lines) — it's a protocol reference, not a manual

### Step 6: Update step-agents.md for skill injection

**Action**: Add adversarial-eval skill reference to the Plan and Spec agent templates.

**Acceptance criteria**:
- [ ] AC-6.1: Plan agent template includes: `skills: [adversarial-eval]` or equivalent reference to make the skill available
- [ ] AC-6.2: Spec agent template includes the same skill reference
- [ ] AC-6.3: The templates include brief guidance: "For non-trivial design decisions with meaningful trade-offs, consider invoking the adversarial-eval skill"
- [ ] AC-6.4: The skill is listed as optional — agents are not required to invoke it for every decision

## Interface Contracts

**Exposes**:
- `adversarial-eval` skill — available to plan and spec agents via skill injection
- Framing registry schema — extensible via `harness.yaml`
- Synthesis output format — embedded in architecture/spec documents

**Consumes**:
- Spec 05: Enhanced plan agent template (skill injection mechanism in `step-agents.md`)
- Existing patterns: Skill frontmatter conventions from `workflow-meta.md`

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/skills/adversarial-eval.md` | New skill: adversarial eval protocol, framings, output format |
| Modify | `claude/skills/work-harness/step-agents.md` | Add adversarial-eval skill reference to Plan and Spec agent templates |

## Testing Strategy

1. **Skill structure**: Verify `adversarial-eval.md` has valid YAML frontmatter
2. **Protocol phases**: Verify all 4 phases (0-3) are documented with clear instructions
3. **Position elicitation**: Verify Phase 0 asks for user's position and supports "skip"
4. **Built-in framings**: Verify exactly 3 framings exist with complete schema (name, description, positions, criteria)
5. **Custom framings**: Verify the `harness.yaml` extension point is documented with schema
6. **Output format**: Verify synthesis output includes all required sections (framing, initial position, arguments, recommendation, conditions, position shift)
7. **Template injection**: Verify both Plan and Spec agent templates in `step-agents.md` reference the skill
8. **Optional invocation**: Verify the skill and templates both emphasize optional, not mandatory, usage
