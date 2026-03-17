# Decompose Handoff: Harness Enforcement

## What This Step Produced

16 beads work items across 5 streams with dependency ordering.

## Streams

### Stream A: Hooks (parallel — implement first)

| ID | Title | Spec | Deps |
|----|-------|------|------|
| rag-6f76 | W-01: state-guard.sh — state mutation validation — spec 01 | 01 | — |
| rag-s03u | W-02: artifact-gate.sh — handoff/artifact existence check — spec 02 | 02 | — |
| rag-1fqo | W-03: review-verify.sh — review evidence validation — spec 03 | 03 | — |
| rag-yd57 | W-04: work-check.sh — fix checkpoint staleness detection — spec 05 | 05 | — |
| rag-u53z | W-05: Register new hooks in settings.json | 00 (registration section) | W-01, W-02, W-03 |

**Note:** W-02 must implement the NEW path checks (`.work/<name>/specs/`) per Component 8, not the legacy `docs/feature/<name>/` path.

### Stream B: Command Changes (depends on Stream A)

| ID | Title | Spec | Deps |
|----|-------|------|------|
| rag-ai6c | W-07: /work-review — set reviewed_at in state.json — spec 03 | 03 | — |
| rag-n1z6 | W-08: /work-archive — add reviewed_at gate check — spec 03 | 03 | W-07 |
| rag-vp1c | W-06: /work-deep auto-advancement rewrite — spec 04 | 04 | W-05 |
| rag-gqwk | W-10: Step output review gates in /work-deep — spec 06 | 06 | W-06 |

### Stream D: Harness QoL (independent — can run in parallel with A+B)

| ID | Title | Spec | Deps |
|----|-------|------|------|
| rag-opnw | W-11: Parallel agent streams — rewrite decompose/implement — spec 07 | 07 | — |
| rag-0e56 | W-12: Docs cleanup — specs to .work, summary to docs/feature — spec 08 | 08 | — |
| rag-so65 | W-13: Futures at any step — cross-cutting command updates — spec 09 | 09 | — |

### Stream E: Migration + Scope Handling (depends on D)

| ID | Title | Spec | Deps |
|----|-------|------|------|
| rag-smhg | W-14: Doc migration for previous workflows — spec 10 | 10 | W-12 |
| rag-t7v6 | W-15: Scope expansion detection — cross-cutting command text — spec 12 | 12 | — |

### Stream C: Validation (depends on all other streams)

| ID | Title | Spec | Deps |
|----|-------|------|------|
| rag-d4xg | W-09: End-to-end validation | all | all prior W-items |

## Concurrency Map

```
Phase 1 (parallel):  W-01  W-02  W-03  W-04  W-07  W-11  W-12  W-13  W-15
                       ↓     ↓     ↓           ↓
Phase 2:             W-05 (register hooks)    W-08    W-14 (doc migration, after W-12)
                       ↓
Phase 3:             W-06 (auto-advance)
                       ↓
Phase 4:             W-10 (step output reviews)
                       ↓
Phase 5:             W-09 (end-to-end validation)
```

**Post-phase validation:** After each phase completes, a validation agent checks implementations against their specs before the next phase starts (Component 11). This catches drift before dependent phases build on it.

## Instructions for Implement

Phase 1 items are all immediately ready. The lead agent spawns one subagent per independent stream:
- **Stream A agent**: W-01, W-02, W-03, W-04 (hooks)
- **Stream B agent**: W-07 (parallel with A, no deps)
- **Stream D agent**: W-11, W-12, W-13 (harness QoL, parallel with A+B)
- **Stream E agent**: W-15 (scope detection, parallel)

After Phase 1, run **post-phase validation** against specs before starting Phase 2.

Each subagent receives: its stream's work items + relevant spec/architecture docs + `skills: [work-harness, code-quality]`.
Subagents claim work with `bd update <id> --status=in_progress` and close with `bd close <id>`.
Lead monitors completion and launches Phase 2+ agents when dependencies clear.

Spec files at `docs/feature/harness-enforcement/0N-*.md` and architecture components 7-12 have implementation details.
