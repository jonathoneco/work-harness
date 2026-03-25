---
stream: H
phase: 3
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/code-quality/references/python-anti-patterns.md
---

# Stream H — Python Anti-Patterns Pack (Phase 3)

## Work Items
- **W-07** (work-harness-alc.7): Python anti-patterns pack

## Spec References
- Spec 00: Contract 1 (pack entry format standard — 7 required fields, 5 categories, 3 severities)
- Spec 03: C01 Step 1 (Python pack — 18 entries specified)

## What To Do

Create `claude/skills/code-quality/references/python-anti-patterns.md` from scratch.

### Entry Requirements
- Minimum 15 entries, target 18-20
- Every entry follows Spec 00 Contract 1 format (Category, Rule Name, Severity, Description, Why, BAD example, GOOD example)
- Code examples use `python` code fences
- BAD examples use `# BAD` comment, GOOD use `# GOOD` comment
- No entry duplicates content from `code-quality.md` universal rules

### Required Entries (from spec 03)

See spec 03, C01 Step 1 for the full 18-entry table with categories, rule names, severities, and source inspiration. Key entries include:
- Mutable Default Arguments (error)
- Bare Except Clause (error)
- Unawaited Coroutine (error)
- Late Binding Closures in Loops (error)
- Use secrets Module for Tokens (error)
- Avoid eval() and exec() on User Input (error)

## Acceptance Criteria
- AC-C01-1.1: File exists at specified path
- AC-C01-1.2: At least 15 entries
- AC-C01-1.3: Every entry follows Spec 00 Contract 1 (all 7 fields)
- AC-C01-1.4: Code examples use `python` code fence
- AC-C01-1.5: BAD examples use `# BAD`
- AC-C01-1.6: GOOD examples use `# GOOD`
- AC-C01-1.7: No overlap with code-quality.md universal rules

## Dependency Constraints
- Requires Phase 2 Stream D complete (discovery extension in code-quality.md)
