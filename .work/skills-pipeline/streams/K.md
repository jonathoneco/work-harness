---
stream: K
phase: 3
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/code-quality/references/react-anti-patterns.md
---

# Stream K — React Anti-Patterns Pack (Phase 3)

## Work Items
- **W-10** (work-harness-alc.10): React anti-patterns pack

## Spec References
- Spec 00: Contract 1 (pack entry format standard)
- Spec 04: C02 Step 1 (React pack — 15 entries specified)

## What To Do

Create `claude/skills/code-quality/references/react-anti-patterns.md` from scratch.

### Entry Requirements
- Minimum 12 entries, target 15
- Every entry follows Spec 00 Contract 1 format
- Code examples use `tsx` or `jsx` code fences
- BAD/GOOD comments use `// BAD` and `// GOOD`
- Entries must be React-specific (not general JS/TS — those belong in C01 TypeScript pack)

### Required Entries (from spec 04)

See spec 04, C02 Step 1 for the full 15-entry table. Key entries include:
- Hooks Called Conditionally (error)
- Missing Dependency Array in useEffect (error)
- State Updates in Render (error)
- Avoid dangerouslySetInnerHTML with User Input (error)
- Object/Array Literal in JSX Props (warn)
- useEffect as Event Handler (warn)

## Acceptance Criteria
- AC-C02-1.1: File exists at specified path
- AC-C02-1.2: At least 12 entries
- AC-C02-1.3: Every entry follows Spec 00 Contract 1
- AC-C02-1.4: Code examples use `tsx` or `jsx` code fence
- AC-C02-1.5: BAD/GOOD use `// BAD` and `// GOOD`
- AC-C02-1.6: Entries are React-specific (not general JS/TS)

## Dependency Constraints
- Requires Phase 2 Stream D complete (discovery extension adds framework directive)
