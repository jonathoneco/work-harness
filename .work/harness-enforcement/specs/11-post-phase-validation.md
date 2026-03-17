# 11: Post-Phase Validation Steps

## Overview

After each implementation phase completes, run a validation step against the relevant specs before starting the next phase. Catches implementation drift early — before dependent phases build on a wrong foundation.

## Trigger

Not a hook — orchestrated by the lead agent during the implement step of `/work-deep`.

## Pattern

```
Phase N agents complete their work items
  ↓
Lead spawns validation agent (Explore, read-only)
  ↓
Validation agent reads: specs for Phase N items + implemented code
  ↓
Checks: Do implementations match specs? Contracts satisfied? Edge cases handled?
  ↓
If issues: fix before starting Phase N+1
If clean: proceed to Phase N+1
```

## Phase-Specific Validation Prompts

### After Phase 1 (Hooks + QoL)

```
Validate Phase 1 implementations against their specs.

Hooks:
- Read spec 01 and .claude/hooks/state-guard.sh — does the hook implement all 6 rules?
- Read spec 02 and .claude/hooks/artifact-gate.sh — does step_dir() map correctly?
  Does it check .work/<name>/specs/ (not docs/feature/<name>/)?
- Read spec 03 and .claude/hooks/review-verify.sh — does it skip pre-existing archives?
- Read spec 05 and .claude/hooks/work-check.sh — does it validate ISO 8601 before parsing?
- Read .claude/settings.json — are all hooks registered?

QoL:
- Read arch 07 and work-deep.md — are worktree references removed from decompose/implement?
- Read arch 08 and work-deep.md — does spec step write to .work/<name>/specs/?
- Read arch 09 and work-deep.md/work-feature.md/work-fix.md — do all steps mention futures?

Return: PASS/FAIL per item with specific discrepancies.
```

### After Phase 2 (Hook Registration + Commands)

```
Validate Phase 2 implementations.

- Write a test state.json with invalid current_step → verify state-guard blocks (exit 2)
- Check .claude/commands/work-review.md mentions reviewed_at
- Check .claude/commands/work-archive.md checks reviewed_at
- Verify hooks compose correctly (all Stop hooks can run without conflict)

Return: PASS/FAIL per item.
```

### After Phase 3 (Auto-Advance)

```
Validate auto-advancement implementation in work-deep.md.

- Does each step section end with the auto-advance block (8a-8g)?
- Does the context refresh section re-read rules?
- Is the handoff prompt template followed?
- Does the decompose step mandate the W-NN naming convention?
- Is the review→archive exception preserved (no auto-advance)?

Return: PASS/FAIL per item.
```

### After Phase 4 (Step Output Reviews)

```
Validate step output review integration.

- Does work-deep.md spawn a review agent between handoff write and state advance?
- Is the handoff/review feedback loop documented (fix → update handoff → re-review)?
- Is user override logged to gate issue?
- Do review checklists match spec 06 (plan/spec/decompose-specific)?

Return: PASS/FAIL per item.
```

## Validation Evidence

After each phase validation completes, the validation agent writes results to `.work/<name>/implement/phase-N-validation.jsonl` (one entry per check). This provides mechanical proof that validation ran, tied to the task itself rather than a shared `.review/` directory.

Format:
```json
{"phase": 1, "check": "state-guard rules", "result": "PASS", "timestamp": "2026-03-15T10:00:00Z"}
{"phase": 1, "check": "artifact-gate paths", "result": "FAIL", "detail": "Rule 3 checks old path", "timestamp": "2026-03-15T10:00:00Z"}
```

## Files to Modify

- `.claude/commands/work-deep.md` — add post-phase validation instructions to the implement step section

## Dependencies

None — this is additive text in the implement step. Can be added at any time.

## Testing

The validation prompts themselves are the test. If they return all PASS, the phase is correct. If FAIL, fix before proceeding.
