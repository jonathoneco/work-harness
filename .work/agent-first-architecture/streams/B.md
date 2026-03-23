---
stream: B
phase: 1
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/work-harness/step-agents.md
  - claude/skills/work-harness.md
---

# Stream B: Step Agent Prompt Templates

## Work Items

| ID | Beads | Title | Spec |
|----|-------|-------|------|
| W-02 | work-harness-rxw | Step Agent Prompt Templates | 02 |

## Dependency Constraints

- Depends on: Stream A (W-01, work-harness-4ei) — context seeding protocol must exist first
- Must complete before Stream C (dispatcher references these templates)

## Spec Reference

Read `.work/agent-first-architecture/specs/02-step-agent-prompt-templates.md` for full details.
Also read `.work/agent-first-architecture/specs/00-cross-cutting-contracts.md` for prompt structure, preamble, skill injection, completion signal format.

## Files to Create/Modify

| Action | File | What to Do |
|--------|------|------------|
| Create | `claude/skills/work-harness/step-agents.md` | Three complete prompt templates (plan, spec, decompose) |
| Modify | `claude/skills/work-harness.md` | Add reference to `step-agents.md` in the skill index |

## Implementation Notes

1. Write `step-agents.md` containing three complete prompt templates
2. Each template follows the 6-section structure from spec 00 section 1:
   - Identity, Task Context, Rules, Instructions, Output Expectations, Completion
3. Variable placeholders (`{name}`, `{title}`, `{tier}`, etc.) must be clearly marked for dispatcher substitution
4. **Plan template**: Produces architecture.md, handoff prompt, updated feature summary
5. **Spec template**: Produces cross-cutting contracts, numbered specs, index, handoff prompt
6. **Decompose template**: Produces beads issues, stream docs, manifest, handoff prompt
7. Rules section uses spec 00 section 3 skill matrix:
   - Plan/spec: `code-quality` only
   - Decompose: `code-quality` + `work-harness`
8. Add reference in `work-harness.md`

## Acceptance Criteria

Reference spec 02 acceptance criteria:
- `step-agents.md` exists at correct path
- Contains complete templates for plan, spec, and decompose
- Each template has all 6 required sections
- Plan template artifacts match current work-deep.md plan step output
- Spec template artifacts match current work-deep.md spec step output
- Decompose template artifacts match current work-deep.md decompose step output
- Variable placeholders clearly marked
- `work-harness.md` references the new file
