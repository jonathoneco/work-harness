---
stream: D
phase: 3
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: L
file_ownership:
  - claude/commands/work-research.md
  - claude/skills/workflow-meta.md
  - claude/rules/workflow.md
---

# Stream D: work-research Command (Phase 3)

## Work Items

| W-ID | Beads ID | Spec | Title |
|------|----------|------|-------|
| W-07 | work-harness-pim.7 | 07 | work-research command |

## W-07: work-research Command (spec 07)

**Files**: `claude/commands/work-research.md` (new), `claude/skills/workflow-meta.md`, `claude/rules/workflow.md`

**Implementation steps** (from spec 07):
1. Define Tier R lifecycle: assess → research → synthesize (assess pre-completed)
2. Define state.json schema for Tier R (tier: "R", no gate files)
3. Create work-research.md command file (YAML frontmatter, config injection, topic argument)
4. Define research step (team dispatch pattern from work-deep.md, scope validation from spec 04)
5. Define synthesize step (reads research handoff, produces deliverable.md with structured format)
6. Define research→synthesize transition (automatic, no Phase A/B review, T2 compaction pattern)
7. Update workflow-meta.md and workflow.md command tables

**Acceptance criteria**: See spec 07 AC-1.1 through AC-7.3.

**Testing**: Command structure, step sequence, tier value ("R" string), no gates, scope validation, deliverable format, command table sync, beads integration (task not epic).

## Dependency Constraints

- Requires Phase 2b (Stream C) to complete — spec 07 depends on C01 (Tier R schema in state-conventions.md) and C04 (explore clarity pattern)
- Runs in parallel with Stream E (no shared files)
