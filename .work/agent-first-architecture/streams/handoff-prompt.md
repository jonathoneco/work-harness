# Decompose Handoff: Agent-First Architecture

## What This Step Produced

6 work items across 6 streams in 3 phases, with beads issues, dependency chains, and self-contained stream execution documents.

## Concurrency Map

```
Phase 1 (Foundation — sequential):
  Stream A (W-01, spec 01) → Stream B (W-02, spec 02) → Stream C (W-03, spec 03)

Phase 2 (Optimization — parallel):
  Stream D (W-04, spec 04) ──┐
                              ├── both blocked by Phase 1
  Stream E (W-05, spec 05) ──┘

Phase 3 (User-facing):
  Stream F (W-06, spec 06) ── blocked by Phase 2
```

**Critical path**: A → B → C → {D or E} → F

**Phase 2 file conflict**: Streams D and E both modify `work-deep.md` but own different sections. D owns implement/review agent spawns. E owns research step only. Documented in both stream docs.

**Multi-stream file**: `work-harness.md` is modified by Streams A, B, and E (adding references to new skill files). All edits are sequential and append-only — no concurrent modification risk.

## Stream Summary

| Stream | Phase | Scope | Work Item | Spec | Key Files |
|--------|-------|-------|-----------|------|-----------|
| A | 1 | S | W-01 (work-harness-4ei) | 01 | context-seeding.md (new), work-harness.md |
| B | 1 | M | W-02 (work-harness-rxw) | 02 | step-agents.md (new), work-harness.md |
| C | 1 | M | W-03 (work-harness-gm5) | 03 | work-deep.md, work-feature.md |
| D | 2 | S | W-04 (work-harness-nz6) | 04 | work-deep.md, work-feature.md, work-fix.md |
| E | 2 | M | W-05 (work-harness-h54) | 05 | teams-protocol.md (new), work-deep.md, work-harness.md |
| F | 3 | S | W-06 (work-harness-1bh) | 06 | delegate.md (new) |

## Dependency Graph (beads)

```
work-harness-4ei (W-01)
  └── work-harness-rxw (W-02)
        └── work-harness-gm5 (W-03)
              ├── work-harness-nz6 (W-04)
              │     └── work-harness-1bh (W-06)
              └── work-harness-h54 (W-05)
                    └── work-harness-1bh (W-06)
```

## Key Design Decisions in Decompose

1. **One work item per spec**: Each spec maps to exactly one beads issue. The specs are already at the right granularity for single-agent implementation.
2. **Phase 2 section ownership**: Specs 04 and 05 both modify `work-deep.md`. Resolved by giving each stream exclusive section ownership — 04 owns implement/review, 05 owns research. The research step fix from spec 04 is subsumed by spec 05's full rewrite.
3. **Sequential Phase 1**: Despite being 3 separate streams, Phase 1 is entirely sequential (A→B→C) because each spec builds on the previous. This is the critical path.

## Key Artifacts

- `.work/agent-first-architecture/streams/A.md` through `F.md` — stream execution documents
- `.work/agent-first-architecture/streams/manifest.jsonl` — work item to stream mapping
- 6 beads issues under epic work-harness-ihi with dependency chain

## Instructions for Implement Step

1. Read this handoff prompt as primary input
2. Execute Phase 1 sequentially: Stream A, then B, then C
   - Each stream is one agent session
   - Run Phase A/B validation after all 3 complete
3. Execute Phase 2 in parallel: Streams D and E simultaneously
   - Both agents read Phase 1 output before starting
   - Stream D: do NOT touch research step in work-deep.md
   - Stream E: ONLY touch research step in work-deep.md
   - Run Phase A/B validation after both complete
4. Execute Phase 3: Stream F
   - Run Phase A/B validation after completion
5. Each stream doc is self-contained — pass it as the agent's primary context along with relevant specs
6. Use `bd update <id> --status=in_progress` when starting each work item
7. Use `bd close <id>` when each work item passes acceptance criteria
