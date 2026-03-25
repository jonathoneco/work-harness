# Beads Replacement — Synthesize Handoff

## Task Context
- **Name**: beads-replacement
- **Tier**: R (Research)
- **Issue**: work-harness-pd1
- **Step**: synthesize (transitioning from research)

## Research Summary

Four research agents investigated: integration map, pain points, alternatives, and value analysis.

### Key Conclusions

**The Problem**: Beads is a 3.6MB, daemon-backed, SQLite-cached issue tracker consuming 1,500-2,500 tokens of context per session. It provides audit logging and session enforcement but its "designed" features (dependencies, ready queries) are never used. Task data is duplicated between state.json and beads.

**The Insight**: Beads is an audit log masquerading as a task tracker. 80% of its features are overhead. The harness already tracks tasks in state.json — beads is parallel bookkeeping.

### What to Synthesize Into the Deliverable

1. **Executive Summary**: Beads should be replaced. The question is with what.

2. **Three viable paths** (from 03-alternatives.md):
   - **Path A: Custom `wt` shell script** — 200-400 lines, jq on JSONL, 6 commands, near-zero context cost. Build exactly what's needed, nothing more.
   - **Path B: GitHub Issues + `gh`** — Zero context, zero maintenance, but requires network. Best if offline-first isn't hard requirement.
   - **Path C: Hybrid state.json extension** — Eliminate separate tracker for T1/T2 entirely. Only T3 gets lightweight JSONL. Most radical simplification.

3. **Migration plan elements** (from 01-integration-map.md):
   - 14+ files, ~120 CLI invocations to update
   - 3 hooks to rewrite
   - 1 global rule file to replace
   - state.json field mappings
   - Can run old and new in parallel during transition

4. **What to preserve** (from 04-value-analysis.md):
   - Session enforcement (active task required before code changes)
   - Audit trail (timestamps for task/gate lifecycle)
   - Finding triage linking (deferred findings need tracking)
   - Cross-session search (grep-friendly format for prior art)

5. **What to drop** (from 04-value-analysis.md):
   - Daemon and SQLite layer
   - Dolt/VC integration (never used)
   - Dependency graph features (designed but never invoked)
   - 20+ beads:* skills (massive context overhead)
   - Global rule injection for all projects

6. **Open questions for the user**:
   - Is offline-first a hard requirement? (decides between Path A vs Path B)
   - Is the beads audit trail ever actually consulted? Or is git history sufficient?
   - How critical is `bd search` for context recovery in practice?
   - Should the replacement be built in-house or adopted externally?

### Research Note Paths (reference if needed)
- `/home/jonco/src/work-harness/.work/beads-replacement/research/01-integration-map.md`
- `/home/jonco/src/work-harness/.work/beads-replacement/research/02-pain-points.md`
- `/home/jonco/src/work-harness/.work/beads-replacement/research/03-alternatives.md`
- `/home/jonco/src/work-harness/.work/beads-replacement/research/04-value-analysis.md`
- `/home/jonco/src/work-harness/.work/beads-replacement/research/notes.md`
