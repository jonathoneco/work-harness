---
stream: C
phase: 2b
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/commands/work-deep.md
  - claude/commands/work-feature.md
  - claude/skills/work-harness/step-agents.md
---

# Stream C: Clarity + Plan Agent (Phase 2b)

## Work Items

| W-ID | Beads ID | Spec | Title |
|------|----------|------|-------|
| W-04 | work-harness-pim.4 | 04 | Explore phase clarity |
| W-05 | work-harness-pim.5 | 05 | Plan agent redesign |

## Internal Ordering

W-04 (spec 04) MUST complete before W-05 (spec 05). C05 depends on C04's clarity protocol to distinguish user-facing pushback from agent-internal inline research.

## W-04: Explore Phase Clarity (spec 04)

**Files**: `claude/commands/work-deep.md`, `claude/commands/work-feature.md`

**Implementation steps** (from spec 04):
1. Define clarity questionnaire format (max 5 questions, scope/intent/constraints only)
2. Add "Scope Validation" sub-step to research step in work-deep.md
3. Add "Task Understanding Check" sub-step to plan step in work-feature.md
4. Define pushback escalation (re-scoping choices: proceed, split, escalate tier)
5. Add research handoff validation to plan step in work-deep.md (distinct from inline research)

**Acceptance criteria**: See spec 04 AC-1.1 through AC-5.3.

**Testing**: Protocol presence in both files, optional path verification, refinement capture in handoff, escalation path, distinction between clarity (user) and inline research (subagent).

## W-05: Plan Agent Redesign (spec 05)

**Files**: `claude/skills/work-harness/step-agents.md`, `claude/commands/work-deep.md`, `claude/commands/work-feature.md`

**Implementation steps** (from spec 05):
1. Add "Inline Research" section to Plan agent template in step-agents.md (max 3 subagents, 1500 token cap, read-only)
2. Add "Inline Research Performed" section to plan handoff prompt template in step-agents.md
3. Update work-deep.md plan step to reference enhanced plan agent with inline research
4. Update work-feature.md plan step (T2 gets all 3 subagent slots since no prior research)
5. Make clarity vs inline research distinction explicit in work-deep.md plan step

**Acceptance criteria**: See spec 05 AC-1.1 through AC-5.3.

**Testing**: Template verification, constraint check, handoff template check, distinction check, T2 handling, ASK fallback for user-judgment gaps.

## Dependency Constraints

- Requires Phase 1 (Stream A) — both specs depend on C02's verdict system
- Requires Phase 2a (Stream B) to complete — file ownership conflict on `work-deep.md` and `work-feature.md`
- Must complete before Phase 3 (Streams D+E) — Stream E (C08) depends on C05's step-agents.md changes
