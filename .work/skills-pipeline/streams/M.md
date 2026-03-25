---
stream: M
phase: 3
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/commands/workflow-meta.md
  - claude/commands/dev-update.md
  - claude/skills/work-harness/dev-update.md
  - claude/commands/work-dump.md
  - claude/skills/work-harness.md
---

# Stream M — New Commands (Phase 3)

## Work Items
- **W-13** (work-harness-alc.13): New commands (workflow-meta, dev-update, work-dump)

## Spec References
- Spec 00: Contracts 2, 3, 5 (frontmatter, config injection, naming)
- Spec 09: C08 (workflow-meta command)
- Spec 10: C09 (dev-update command + skill)
- Spec 11: C10 (work-dump command)

## What To Do

### 1. Create `/workflow-meta` command (spec 09)

Create `claude/commands/workflow-meta.md`:
- Frontmatter: `skills: [workflow-meta, code-quality]`, meta block
- 5-step flow: Pre-seed context, Understand modification, Pre-check sync, Guided modification, Post-check sync, Report
- Loads existing `workflow-meta` skill — does NOT duplicate its content
- Includes config injection directive

See spec 09 for full step definitions and acceptance criteria.

### 2. Create `/dev-update` skill (spec 10, Step 1)

Create `claude/skills/work-harness/dev-update.md`:
- Artifact reading priority (5 sources: task state, git log, checkpoints, beads, handoffs)
- Update structure template (4 sections: Completed, In Progress, Blocked, Next)
- Time window configuration
- Rules (evidence-based, no speculation, brevity)

### 3. Create `/dev-update` command (spec 10, Step 2)

Create `claude/commands/dev-update.md`:
- Frontmatter: `skills: [dev-update, work-harness]`, meta block
- 4-step flow: Determine time window, Gather artifacts, Synthesize update, Output
- Includes config injection directive
- Output to stdout in markdown

### 4. Create `/work-dump` command (spec 11)

Create `claude/commands/work-dump.md`:
- Frontmatter: `skills: [work-harness]`, meta block
- 6-step flow: Parse input, Identify domains, Decompose, Dependency graph, Output plan, User review
- Advisory only — does NOT auto-create beads issues (DD-3)
- Includes config injection directive
- Outputs `bd create` commands for copy-paste

See spec 11 for full step definitions and domain table.

### 5. Update `work-harness.md` references (spec 10, Step 3)

Add to References:
```markdown
- **dev-update** — Status update generation conventions (path: `claude/skills/work-harness/dev-update.md`)
```

Note: `work-harness.md` was already modified by Stream C (skill-lifecycle ref). This adds a second reference.

## Acceptance Criteria
Spec 09 (workflow-meta):
- AC-C08-2.1 through AC-C08-2.5

Spec 10 (dev-update):
- AC-C09-1.1 through AC-C09-1.4 (skill)
- AC-C09-2.1 through AC-C09-2.6 (command)
- AC-C09-3.1 (work-harness.md ref)

Spec 11 (work-dump):
- AC-C10-2.1 through AC-C10-2.7

## Dependency Constraints
- Requires Phase 1 complete (Stream A adds meta to work-harness.md)
- Requires Stream C complete (W-02 adds skill-lifecycle ref to work-harness.md — this stream adds dev-update ref after it)
