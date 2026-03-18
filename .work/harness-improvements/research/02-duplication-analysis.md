# Duplication Analysis

## Summary
~700 lines of identified duplication across 80+ occurrences in 8 distinct patterns.

## Top Duplication Patterns

### 1. State Discovery & Active Task Detection (5 commands, ~100 lines)
Every command repeats "scan .work/ for state.json where archived_at is null" logic.
Files: work.md, work-fix.md, work-feature.md, work-deep.md, work-status.md

### 2. Config Injection Preamble (16 commands, ~64 lines)
Every command repeats the same 4-line config injection directive.

### 3. Step Transition & User Approval (10+ occurrences, ~200 lines)
Present results -> wait for approval -> gate issue -> state update -> compact prompt.
Repeats 5x in work-deep.md alone.

### 4. Phase A/B Review Protocol (5 steps in work-deep.md, ~100 lines)
Near-identical two-phase review at every step transition.

### 5. Beads Issue Patterns (28+ occurrences, ~50 lines)
bd create/update/close with identical structure, varying only in parameters.

### 6. Task Initialization (3 tier commands, ~65 lines)
65% identical across work-fix, work-feature, work-deep. Differs only in tier-specific setup.

### 7. Handoff Prompt Generation (~60 lines)
Same structure repeated across 5 steps + checkpoint command.

### 8. Hook Boilerplate (~60 lines)
Config validation, task discovery loops, jq wrappers repeated across hooks.

## Recommended Modularization (Priority Order)

### Phase 1 — High ROI
1. **task-discovery** skill — Centralize active task finding
2. **step-transition** skill — Handle approval ceremony, state update, gate creation
3. **phase-review** skill — Orchestrate Phase A + Phase B reviews

### Phase 2 — Medium ROI
4. **beads-helper** skill — Wrap common beads CLI patterns
5. **handoff-generator** skill — Template handoff prompt generation
6. **hooks/lib/common.sh** — DRY hook boilerplate

### Phase 3 — Polish
7. Config injection centralized in one source
8. State conventions helper functions
