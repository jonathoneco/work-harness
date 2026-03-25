---
stream: C
phase: 2
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/work-harness/skill-lifecycle.md
  - claude/commands/work-skill-update.md
  - claude/skills/work-harness.md
---

# Stream C — Skill Lifecycle + Update Command (Phase 2)

## Work Items
- **W-02** (work-harness-alc.2): Skill lifecycle + update command

## Spec References
- Spec 00: Contract 2 (frontmatter schema)
- Spec 01: C13 Steps 3-5 (create skill-lifecycle.md, create work-skill-update.md, update work-harness.md references)

## What To Do

### 1. Create `claude/skills/work-harness/skill-lifecycle.md`

New file with frontmatter:
```yaml
---
name: skill-lifecycle
description: "Staleness detection rules and skill metadata conventions. Activates when running /work-skill-update or when harness-doctor checks skill health."
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---
```

Content must include:
- When This Activates section
- Staleness Detection Rules (90-day threshold, not configurable in V1)
- Metadata Validation Rules (meta block must exist, stack array non-empty, version positive int, last_reviewed valid date)
- When to Bump Version guidance
- References to Spec 00 Contract 2

See spec 01, C13 Step 3 for full content requirements.

### 2. Create `claude/commands/work-skill-update.md`

New file with frontmatter:
```yaml
---
description: "Scan skills and commands for staleness, report outdated content, suggest updates"
user_invocable: true
skills: [skill-lifecycle]
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---
```

Command behavior:
1. Scan Phase: find all `.md` files under `claude/skills/` (excluding `references/`) and `claude/commands/`
2. Validation Phase: check meta block exists and fields are valid
3. Staleness Phase: calculate days since last_reviewed, mark >90 days as STALE
4. Output: structured Skill Health Report format (see spec 01, C13 Step 4 for exact format)
5. Suggestions: for stale skills, suggest review based on meta.stack

Command is READ-ONLY — does not modify any files.

### 3. Update `claude/skills/work-harness.md` References

Add to the References section:
```markdown
- **skill-lifecycle** — Staleness detection rules and metadata conventions (path: `claude/skills/work-harness/skill-lifecycle.md`)
```

Note: This file already had its `meta` block added by Stream A (Phase 1).

## Acceptance Criteria
- AC-C13-3.1: File exists at `claude/skills/work-harness/skill-lifecycle.md`
- AC-C13-3.2: Frontmatter includes name, description, and meta block
- AC-C13-3.3: Contains staleness threshold definition (90 days)
- AC-C13-3.4: Contains metadata validation rules
- AC-C13-3.5: Contains version bump guidance
- AC-C13-4.1: File exists at `claude/commands/work-skill-update.md`
- AC-C13-4.2: Command scans all skill and command files
- AC-C13-4.3: Reports files missing meta block
- AC-C13-4.4: Reports files with invalid metadata fields
- AC-C13-4.5: Reports files with last_reviewed >90 days
- AC-C13-4.6: Output includes summary count
- AC-C13-4.7: Command is read-only
- AC-C13-5.1: work-harness.md References includes skill-lifecycle
- AC-C13-5.2: Path reference is correct

## Dependency Constraints
- Requires Phase 1 complete (Stream A adds meta blocks to work-harness.md)
