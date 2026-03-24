---
stream: E
phase: 3
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/adversarial-eval.md
  - claude/skills/work-harness/step-agents.md
---

# Stream E: Adversarial Eval (Phase 3)

## Work Items

| W-ID | Beads ID | Spec | Title |
|------|----------|------|-------|
| W-08 | work-harness-pim.8 | 08 | Adversarial eval improvements |

## W-08: Adversarial Eval Improvements (spec 08)

**Files**: `claude/skills/adversarial-eval.md` (new), `claude/skills/work-harness/step-agents.md`

**Implementation steps** (from spec 08):
1. Define adversarial eval protocol (4 phases: Position Elicitation → Opening Arguments → Rebuttal → Synthesis)
2. Define framing registry (3 built-ins: ship-vs-polish, build-vs-buy, paradigm-choice)
3. Define framing selection (agent selects based on decision type, user can override, ad-hoc from paradigm-choice template)
4. Define synthesis output format (framing, initial position, arguments, recommendation, conditions, position shift)
5. Create adversarial-eval.md skill file (YAML frontmatter, protocol, framings, output format, <200 lines)
6. Update step-agents.md: add adversarial-eval skill reference to Plan and Spec agent templates

**Acceptance criteria**: See spec 08 AC-1.1 through AC-6.4.

**Testing**: Skill structure, protocol phases, position elicitation skip support, 3 built-in framings, custom framing schema, output format, template injection, optional invocation.

## Dependency Constraints

- Requires Phase 2b (Stream C) to complete — spec 08 depends on C05's step-agents.md changes (skill injection mechanism)
- Runs in parallel with Stream D (no shared files)
