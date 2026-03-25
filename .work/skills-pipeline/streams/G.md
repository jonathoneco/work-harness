---
stream: G
phase: 2
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: S
file_ownership:
  - claude/skills/work-harness/context-docs.md
---

# Stream G — Context-Docs Enrichment (Phase 2)

## Work Items
- **W-06** (work-harness-alc.6): Context-docs enrichment

## Spec References
- Spec 08: C07 (context-docs enrichment — examples, edge cases, doc impact flagging)

## What To Do

Enrich `claude/skills/work-harness/context-docs.md` by adding three new sections. The file already has its `meta` block from Stream A (Phase 1).

### 1. Add Configuration Examples section

After existing "Auto-Detection" section. Three concrete YAML examples:
- Go API project (gin, postgres)
- Next.js fullstack project (typescript, nextjs, postgres)
- Python ML project (explicit opt-out with `managed: []`)

See spec 08, C07 Step 1 for exact content.

### 2. Add Edge Cases section

Four edge cases with explicit agent behavior:
- Missing doc file on disk (note as missing, don't block, don't auto-create)
- Stale docs (flag in completion message, do NOT auto-update)
- Conflicting auto-detection (deduplicate, not an error)
- No harness.yaml (skip entirely, no error)

See spec 08, C07 Step 2 for exact content.

### 3. Add Agent Doc Impact Flagging section

- Trigger conditions (endpoint, component, schema, package, env changes)
- Flag format template: `Doc impact: [type] may need updating — [description]`
- Non-trigger conditions (internal refactoring, tests, docs, config)

See spec 08, C07 Step 3 for exact content.

### Rules
- Do NOT modify existing manifest format, auto-detection table, agent context injection, or doc maintenance sections

## Acceptance Criteria
- AC-C07-1.1: Three configuration examples present
- AC-C07-1.2: Examples cover different stack profiles
- AC-C07-1.3: Valid YAML matching existing schema
- AC-C07-2.1: Four edge cases documented
- AC-C07-2.2: Each has explicit agent behavior guidance
- AC-C07-2.3: "Do NOT auto-update" explicitly stated
- AC-C07-3.1: Doc impact flagging section exists
- AC-C07-3.2: Trigger conditions with mappings
- AC-C07-3.3: Flag format template provided
- AC-C07-3.4: Non-trigger conditions listed

## Dependency Constraints
- Requires Phase 1 complete (Stream A adds meta block to context-docs.md)
