---
stream: I
phase: 3
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/code-quality/references/typescript-anti-patterns.md
---

# Stream I — TypeScript Anti-Patterns Pack (Phase 3)

## Work Items
- **W-08** (work-harness-alc.8): TypeScript anti-patterns pack

## Spec References
- Spec 00: Contract 1 (pack entry format standard)
- Spec 03: C01 Step 2 (TypeScript pack — 18 entries specified)

## What To Do

Create `claude/skills/code-quality/references/typescript-anti-patterns.md` from scratch.

### Entry Requirements
- Minimum 15 entries, target 18-20
- Every entry follows Spec 00 Contract 1 format
- Code examples use `typescript` code fences
- BAD/GOOD comments use `// BAD` and `// GOOD`

### Required Entries (from spec 03)

See spec 03, C01 Step 2 for the full 18-entry table. Key entries include:
- Abuse of `any` Type (error)
- Unawaited Promise (error)
- Non-null Assertion After Optional Chaining (error)
- Missing Exhaustive Check in Switch (error)
- Validate External Data at Runtime (error)
- Prefer unknown Over any for External Data (warn)

## Acceptance Criteria
- AC-C01-2.1: File exists at specified path
- AC-C01-2.2: At least 15 entries
- AC-C01-2.3: Every entry follows Spec 00 Contract 1
- AC-C01-2.4: Code examples use `typescript` code fence
- AC-C01-2.5: BAD/GOOD use `// BAD` and `// GOOD`

## Dependency Constraints
- Requires Phase 2 Stream D complete (discovery extension in code-quality.md)
