# Handoff Prompt: Plan -> Spec

## What Plan Produced

Architecture document at `.work/harness-improvements/specs/architecture.md` defining 11 components across 4 implementation phases. Updated feature summary at `docs/feature/harness-improvements.md`.

## Architecture Summary

11 components organized into 4 phases:

**Phase 1 — Independent (all parallel, no prerequisites):**
- C1: Stream Docs Enhancement (M) — enhanced stream doc format
- C2: Code Quality Enhancement (M) — reference library expansion
- C3: Context Doc System (L) — manifest-driven doc auto-maintenance
- C4: Gate Protocol (M) — file-based review UX
- C5: Research Protocol (S) — agent self-writing research notes
- C6: Auto-Reground (S) — post-compact handoff injection

**Phase 2 — Foundation:**
- C7: Skill Library (L) — extracted shared skills (task-discovery, step-transition, phase-review) + hooks DRY

**Phase 3 — Integration (requires C7):**
- C8: Dynamic Delegation (M) — step-level agent/skill routing
- C9: Parallel Execution v2 (M) — operational integration with modular skills

**Phase 4 — Extensions (requires Phase 1):**
- C10: Codex Integration (M) — optional headless review (requires C2)
- C11: Memory Integration (L) — work-log MCP KG server (enriched by C6)

## Key Design Decision: Priority vs Dependency

Parallel Decomposition (user priority #1) depends on Command Modularization (#5) and Dynamic Delegation (#4). Resolved by splitting delivery:
- Phase 1 (C1): format and strategy improvements (no dependencies)
- Phase 3 (C9): operational integration (after skills exist)

## Component List for Spec Writing

Each component needs a numbered spec. Suggested spec order follows phase ordering:

| Spec | Component | Dependencies |
|------|-----------|-------------|
| 00 | Cross-cutting contracts | — |
| 01 | Stream Docs Enhancement (C1) | 00 |
| 02 | Code Quality Enhancement (C2) | 00 |
| 03 | Context Doc System (C3) | 00 |
| 04 | Gate Protocol (C4) | 00 |
| 05 | Research Protocol (C5) | 00 |
| 06 | Auto-Reground (C6) | 00 |
| 07 | Skill Library (C7) | 00 |
| 08 | Dynamic Delegation (C8) | 07 |
| 09 | Parallel Execution v2 (C9) | 01, 07, 08 |
| 10 | Codex Integration (C10) | 02 |
| 11 | Memory Integration (C11) | 00, optionally 06 |

## Questions Deferred to Spec

1. C3 auto-detection heuristics — which stack config fields map to which doc types?
2. C7 skill extraction granularity — one `step-transition` skill or split into sub-skills?
3. C8 skills field verification — does agent YAML frontmatter support `skills:` natively?
4. C10 output schema design — structured format for Codex findings
5. C11 entity schema — entities/relations/observations for work-log KG

## Artifacts

- Architecture: `.work/harness-improvements/specs/architecture.md`
- Feature summary: `docs/feature/harness-improvements.md`
- Research handoff (prior step): `.work/harness-improvements/research/handoff-prompt.md`

## Instructions for Spec Step

1. Read this handoff prompt as primary input
2. Write `00-cross-cutting-contracts.md` first — shared schemas, naming conventions, file path conventions
3. Write specs 01-11, one per component
4. Phase 1 specs (01-06) can be written in parallel
5. Phase 2-4 specs (07-11) reference Phase 1 interfaces
6. Each spec needs: overview, implementation steps with acceptance criteria, interface contracts, files to create/modify, testing strategy
7. Track in `.work/harness-improvements/specs/index.md`
