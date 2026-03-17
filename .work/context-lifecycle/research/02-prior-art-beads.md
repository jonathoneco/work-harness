# Prior Art: Closed Beads Issues

## Summary

5 relevant closed issues establish patterns this task builds on. 3 open issues demonstrate the staleness problem we're solving.

## Relevant Closed Issues

### rag-g4dv3 — Context compaction at step transitions (P1)
- **Decision**: Added explicit compaction protocol to work-deep.md and work-feature.md
- **Pattern**: 5 transition points instruct user to `/compact` then re-invoke tier command
- **Rationale**: Handoff prompts existed but compaction was never triggered, so LLM ran with accumulated context across steps
- **Relevance**: Foundation for self-re-invocation mechanism — we're automating what this issue made explicit

### rag-ogkz — Deprecated table + Tier 1 compaction (P2)
- **Decision**: Created 13-entry deprecated approaches table in beads-workflow.md
- **Pattern**: Search pattern skips stale technology references during research
- **Results**: 121 candidates, 68 compacted, 53 already minimal
- **Relevance**: Foundation for deprecated table diffing — table exists, cross-referencing doesn't

### rag-enui — Aggressive housekeeping pass (P2)
- **Decision**: Manual pass removing orphan files, stale docs, obsolete references
- **Pattern**: One-time manual cleanup, not systematic
- **Relevance**: Proves the need — this was manual labor that should be automated

### rag-27kz — SSM→.env sync and drift checklist (P1)
- **Decision**: Made drift categories explicit and enumerable
- **Pattern**: Documented expected divergence with verification commands
- **Relevance**: Model for making staleness detectable — enumerate what can drift, provide verification

### rag-7pmy — Config migration to self-contained repo (P1)
- **Decision**: Moved skills/commands/agents/hooks from dotfiles into `.claude/`
- **Impact**: Context documents now co-located with code
- **Relevance**: Enables file-local lifecycle management — everything to manage is in `.claude/`

## Open Issues (Active Staleness Examples)

### rag-e690r, rag-odxhb, rag-vzsgp — Context doc cleanup (P2)
- Remove HTMX/deprecated references from skills, agents, CLAUDE.md
- **Live example**: HTMX was deprecated Mar 2026, but code-quality skill still has `htmx-checklist.md`
- **Relevance**: Exactly the problem deprecated table diffing would catch automatically

## Key Patterns Established

1. **Step-gated compaction**: Boundaries already exist; self-re-invocation builds on them
2. **Deprecated approaches table**: Registry exists; automated cross-referencing is the gap
3. **Colocated context**: All docs in `.claude/`; enables local lifecycle management
4. **Manual housekeeping**: Done ad-hoc; needs systematization
5. **Drift documentation**: Make expected divergence enumerable (from rag-27kz)
