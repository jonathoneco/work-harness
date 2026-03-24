# Decompose Handoff: W3 Workflow Phase Redesign

## What This Step Produced

8 work items across 5 streams in 4 phases. Each work item maps 1:1 to a spec. Beads issues created under epic `work-harness-pim` with dependency chains matching spec ordering.

## Concurrency Map

```
Phase 1:   [Stream A: C01 → C02]
              |
Phase 2a:  [Stream B: C03 + C06]
              |
Phase 2b:  [Stream C: C04 → C05]
              |
Phase 3:   [Stream D: C07] ─┐
           [Stream E: C08] ─┘  (parallel)
```

**Critical path**: A → B → C → D (or E, same length)

Phase 2a and 2b are sequential (not parallel) because they share file ownership on `work-deep.md` and `work-feature.md`. Phase 3 streams D and E have no file conflicts and run in parallel.

## Stream Summary

| Stream | Phase | Scope | Work Items | Key Files |
|--------|-------|-------|------------|-----------|
| A | 1 | M | W-01 (spec 01), W-02 (spec 02) | state-conventions.md, phase-review.md, step-transition.md |
| B | 2a | M | W-03 (spec 03), W-06 (spec 06) | step-transition.md, phase-review.md, work-deep.md, work-feature.md |
| C | 2b | M | W-04 (spec 04), W-05 (spec 05) | work-deep.md, work-feature.md, step-agents.md |
| D | 3 | L | W-07 (spec 07) | work-research.md (new), workflow-meta.md, workflow.md |
| E | 3 | M | W-08 (spec 08) | adversarial-eval.md (new), step-agents.md |

## File Ownership Across Phases

Files that appear in multiple streams are separated by phase boundaries:

| File | Stream A (P1) | Stream B (P2a) | Stream C (P2b) | Stream D (P3) | Stream E (P3) |
|------|:---:|:---:|:---:|:---:|:---:|
| state-conventions.md | W | | | | |
| phase-review.md | W | W | | | |
| step-transition.md | W | W | | | |
| work-deep.md | | W | W | | |
| work-feature.md | | W | W | | |
| step-agents.md | | | W | | W |
| work-research.md | | | | W | |
| workflow-meta.md | | | | W | |
| workflow.md | | | | W | |
| adversarial-eval.md | | | | | W |

No file appears in more than one stream within the same phase.

## Instructions for Implement Step

1. **Execute streams sequentially by phase**: Phase 1 (Stream A) → Phase 2a (Stream B) → Phase 2b (Stream C) → Phase 3 (Streams D + E in parallel)

2. **Per stream**: Spawn a general-purpose agent with the stream document as its prompt. The stream document contains work items, file ownership, implementation steps (referencing specs), and acceptance criteria.

3. **Context seeding per agent**: Each stream agent needs:
   - The stream document (`.work/workflow-phase-redesign/streams/{letter}.md`)
   - The relevant spec files (referenced in the stream document)
   - The cross-cutting contracts (spec 00)
   - The current state of files being modified (read before editing)
   - Skills: `[work-harness, code-quality]`

4. **After each stream completes**: Run acceptance tests from the spec testing strategies. Mark beads issues as closed (`bd close <id> --reason="..."`) before starting the next phase.

5. **Phase 3 parallelism**: Streams D and E can run as parallel agents. Stream D creates `work-research.md` and updates command tables. Stream E creates `adversarial-eval.md` and updates `step-agents.md`. No file conflicts.

6. **After all streams complete**: Run `/work-review` for a comprehensive quality review of all changes.

## Beads Issues

| W-ID | Beads ID | Status |
|------|----------|--------|
| W-01 | work-harness-pim.1 | open |
| W-02 | work-harness-pim.2 | open (blocked by W-01) |
| W-03 | work-harness-pim.3 | open (blocked by W-02) |
| W-04 | work-harness-pim.4 | open (blocked by W-02) |
| W-05 | work-harness-pim.5 | open (blocked by W-02, W-04) |
| W-06 | work-harness-pim.6 | open (blocked by W-02) |
| W-07 | work-harness-pim.7 | open (blocked by W-01, W-04) |
| W-08 | work-harness-pim.8 | open (blocked by W-05) |

## Items Deferred

No new items deferred during decompose — all deferred items from specs are already captured in `.work/workflow-phase-redesign/futures.md`.
