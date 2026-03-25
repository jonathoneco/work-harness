---
stream: L
phase: 3
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/skills/code-quality/references/nextjs-anti-patterns.md
---

# Stream L — Next.js Anti-Patterns Pack (Phase 3)

## Work Items
- **W-11** (work-harness-alc.11): Next.js anti-patterns pack

## Spec References
- Spec 00: Contract 1 (pack entry format standard)
- Spec 04: C02 Step 2 (Next.js pack — 15 entries specified)

## What To Do

Create `claude/skills/code-quality/references/nextjs-anti-patterns.md` from scratch.

### Entry Requirements
- Minimum 12 entries, target 15
- Every entry follows Spec 00 Contract 1 format
- Code examples use `tsx` or `typescript` code fences
- BAD/GOOD comments use `// BAD` and `// GOOD`
- Entries must be Next.js-specific (not general React — those belong in React pack)
- Entries should reference App Router (current) rather than deprecated Pages Router

### Required Entries (from spec 04)

See spec 04, C02 Step 2 for the full 15-entry table. Key entries include:
- Client Hooks in Server Components (error)
- window/document Access in Server Context (error)
- Using getServerSideProps in App Router (error)
- Mixing use client with Server-Only Imports (error)
- Validate API Route Inputs Server-Side (error)
- fetch() Without Caching Strategy (warn)

## Acceptance Criteria
- AC-C02-2.1: File exists at specified path
- AC-C02-2.2: At least 12 entries
- AC-C02-2.3: Every entry follows Spec 00 Contract 1
- AC-C02-2.4: Code examples use `tsx` or `typescript` code fence
- AC-C02-2.5: Entries are Next.js-specific
- AC-C02-2.6: Entries distinguish App Router (primary) vs Pages Router

## Dependency Constraints
- Requires Phase 2 Stream D complete (discovery extension adds framework/frontend directives)
