---
stream: J
phase: 3
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/code-quality/references/rust-anti-patterns.md
---

# Stream J — Rust Anti-Patterns Pack (Phase 3)

## Work Items
- **W-09** (work-harness-alc.9): Rust anti-patterns pack

## Spec References
- Spec 00: Contract 1 (pack entry format standard)
- Spec 03: C01 Step 3 (Rust pack — 18 entries specified)

## What To Do

Create `claude/skills/code-quality/references/rust-anti-patterns.md` from scratch.

### Entry Requirements
- Minimum 15 entries, target 18-20
- Every entry follows Spec 00 Contract 1 format
- Code examples use `rust` code fences
- BAD/GOOD comments use `// BAD` and `// GOOD`
- Entries should reflect AI-specific mistakes (research found Rust AI code has 1.7x more issues)

### Required Entries (from spec 03)

See spec 03, C01 Step 3 for the full 18-entry table. Key entries include:
- unwrap() in Production Code (error)
- Using unsafe to Fight the Borrow Checker (error)
- Validate Array Indices Before Access (error)
- Unnecessary clone() (warn)
- Missing Error Context in ? Chains (warn)
- String Parameters Instead of &str (warn)

## Acceptance Criteria
- AC-C01-3.1: File exists at specified path
- AC-C01-3.2: At least 15 entries
- AC-C01-3.3: Every entry follows Spec 00 Contract 1
- AC-C01-3.4: Code examples use `rust` code fence
- AC-C01-3.5: BAD/GOOD use `// BAD` and `// GOOD`
- AC-C01-3.6: Entries reflect AI-specific mistakes

## Dependency Constraints
- Requires Phase 2 Stream D complete (discovery extension in code-quality.md)
