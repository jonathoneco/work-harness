---
stream: F
phase: 2
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: S
file_ownership:
  - claude/skills/work-harness/codex-review.md
---

# Stream F — Codex-Review Enrichment (Phase 2)

## Work Items
- **W-05** (work-harness-alc.5): Codex-review enrichment

## Spec References
- Spec 07: C06 (codex-review enrichment — diff prep, multi-file handling, integration notes)

## What To Do

Enrich `claude/skills/work-harness/codex-review.md` by adding three new sections. The file already has its `meta` block from Stream A (Phase 1).

### 1. Add Diff Preparation section

After existing "Execution" section. Includes:
- 3 diff generation commands (PR review, staged, unstaged)
- Size limit guidance (50k chars, split strategy)

See spec 07, C06 Step 1 for exact content.

### 2. Add Multi-File Handling section

Three strategies: single invocation (<50k), split by file (large diffs), combine findings.
Include: "Do NOT split a single file's diff across multiple invocations."

See spec 07, C06 Step 2 for exact content.

### 3. Add `/work-review` Integration Notes

4-step integration flow explaining how /work-review consumes this skill.
Must state: agent does NOT write to findings.jsonl directly.

See spec 07, C06 Step 3 for exact content.

### Rules
- Do NOT modify existing Execution, Output Schema, Verification Rules, Known Hallucination Patterns, or Error Handling sections

## Acceptance Criteria
- AC-C06-1.1: Diff preparation section with 3 diff generation commands
- AC-C06-1.2: Size limit guidance (50k chars) with split strategy
- AC-C06-2.1: Three strategies documented (single, split, combine)
- AC-C06-2.2: "Do NOT split a single file" guidance present
- AC-C06-3.1: Integration flow with 4 numbered steps
- AC-C06-3.2: Agent does not write to findings.jsonl directly

## Dependency Constraints
- Requires Phase 1 complete (Stream A adds meta block to codex-review.md)
