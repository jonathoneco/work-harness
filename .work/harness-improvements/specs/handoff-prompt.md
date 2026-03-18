# Handoff Prompt: Spec -> Decompose

## What Spec Produced

12 specification documents (00-11) at `.work/harness-improvements/specs/`:

- **00**: Cross-cutting contracts — shared schemas, naming conventions, path conventions, error handling, testing strategy
- **01**: Stream Docs Enhancement (C1) — YAML frontmatter schema with 7 fields, hybrid execution strategy, agent type selection
- **02**: Code Quality Enhancement (C2) — 3 new reference docs (security-antipatterns, ai-config-linting, parallel-review)
- **03**: Context Doc System (C3) — harness.yaml docs.managed schema, 18-entry auto-detection mapping, context injection skill
- **04**: Gate Protocol (C4) — SOP reference doc, 4 gate types, invocation point diagram, state.json gate_file field
- **05**: Research Protocol (C5) — agent prompt template, 4-section note format, lead-as-synthesizer pattern
- **06**: Auto-Reground (C6) — 3-tier handoff resolution, corrupt state handling, no memory awareness
- **07**: Skill Library (C7) — 3 extracted skills + hooks/lib/common.sh, 7 steps, 22 acceptance criteria
- **08**: Dynamic Delegation (C8) — blocking skills: verification gate, step-level routing tables, dual implementation paths
- **09**: Parallel Execution v2 (C9) — skill-referenced stream docs, delegation router, file ownership validation
- **10**: Codex Integration (C10) — codex-review skill, JSONL output schema, graceful degradation
- **11**: Memory Integration (C11) — work-log MCP KG, /handoff command, entity schema, routing rule

## Spec Index

`.work/harness-improvements/specs/index.md` — tracks all specs, resolved deferred questions, and addressed advisory notes.

## Key Design Decisions Made During Spec

1. **step-transition stays as one skill** — the approval ceremony, gate file creation, and state update always co-occur
2. **Hook utilities go into hooks/lib/common.sh** — follows existing lib/config.sh sourcing pattern
3. **skills: field verification is a blocking gate** — C8 Step 1 must verify before implementation proceeds
4. **Codex findings use existing findings.jsonl schema** — severity/category/file/line/message/suggestion fields
5. **Work-log KG has 4 entity types** — WorkSession, Decision, Blocker, Accomplishment with 5 relation types
6. **C6 ships without memory awareness** — enrichment path documented in C11 as future capability
7. **C10/C11 can start after specific Phase 1 components** — C10 after C2, C11 independently

## Acceptance Criteria Summary

| Spec | AC Count | Key Verification Methods |
|------|----------|------------------------|
| 01 | 9 | structural-review, manual-test |
| 02 | 12 | structural-review, file-exists |
| 03 | 9 | structural-review, integration-test |
| 04 | 11 | structural-review, file-exists |
| 05 | 6 | structural-review, manual-test |
| 06 | 10 | shellcheck, manual-test |
| 07 | 22 | shellcheck, structural-review, manual-test |
| 08 | 11 | manual-test, integration-test |
| 09 | 9 | structural-review, integration-test |
| 10 | 7 | manual-test, integration-test |
| 11 | 10 | structural-review, integration-test |
| **Total** | **116** | |

## Files Summary

### New Files (across all specs)

| File | Spec |
|------|------|
| `hooks/lib/common.sh` | 07 |
| `claude/skills/work-harness/task-discovery.md` | 07 |
| `claude/skills/work-harness/step-transition.md` | 07 |
| `claude/skills/work-harness/phase-review.md` | 07 |
| `claude/skills/work-harness/context-docs.md` | 03 |
| `claude/skills/work-harness/codex-review.md` | 10 |
| `claude/skills/work-harness/references/gate-protocol.md` | 04 |
| `claude/skills/code-quality/references/security-antipatterns.md` | 02 |
| `claude/skills/code-quality/references/ai-config-linting.md` | 02 |
| `claude/skills/code-quality/references/parallel-review.md` | 02 |
| `claude/skills/work-harness/references/entity-schema.md` | 11 |
| `claude/commands/handoff.md` | 11 |
| `claude/rules/memory-routing.md` | 11 |

### Modified Files (across all specs)

| File | Specs |
|------|-------|
| `claude/commands/work-deep.md` | 01, 05, 08, 09 |
| `claude/skills/code-quality/code-quality.md` | 02, 10 |
| `claude/skills/work-harness.md` | 07 |
| `claude/skills/work-harness/references/state-conventions.md` | 03, 04 |
| `claude/agents/work-implement.md` | 03 |
| `hooks/post-compact.sh` | 06 |
| `hooks/*.sh` (all 8 hooks) | 07 |
| `claude/rules/workflow-detect.md` | 11 |

## Dependency Graph for Decompose

```
Phase 1 (all parallel, no prerequisites):
  C1 (Stream Docs) ─────────────────────────────┐
  C2 (Code Quality) ──────── C10 (Codex)        │
  C3 (Context Docs)                              │
  C4 (Gate Protocol)                             │
  C5 (Research Protocol)                         │
  C6 (Auto-Reground) ──────── C11 (Memory, opt)  │
                                                 │
Phase 2:                                         │
  C7 (Skill Library) ─── C8 (Delegation) ─── C9 (Parallel v2)
```

## Instructions for Decompose Step

1. Read this handoff prompt as primary input
2. Read individual specs only as needed for work item details
3. Group work items into streams — one per independent workstream
4. Respect the phase ordering: Phase 1 (C1-C6 parallel) → Phase 2 (C7) → Phase 3 (C8 → C9) → Phase 4 (C10, C11 parallel)
5. Within Phase 1, each component is an independent stream
6. C7 is large (22 ACs, 7 steps) — consider splitting into 2 streams (hooks/lib + skills)
7. Create beads issues with title format `[<tag>] W-NN: <title> — spec NN`
8. Write stream execution docs as self-contained agent prompts
9. Create manifest.jsonl mapping work items to beads IDs, streams, and phases
