# Spec Handoff: Harness Enforcement

## What This Step Produced

7 specs at `docs/feature/harness-enforcement/`, covering 6 components. Reviewed twice — first review found 7 blocking issues (all fixed), second review found 5 blocking issues (4 real, all fixed).

| Spec | Component | Type | Blocks? |
|------|-----------|------|---------|
| 00 | Cross-cutting contracts | Conventions | N/A |
| 01 | `state-guard.sh` (Component 1) | PostToolUse hook | Yes |
| 02 | `artifact-gate.sh` (Component 2) | Stop hook | Yes |
| 03 | `review-verify.sh` (Component 3) | Stop hook + command changes | Yes |
| 04 | Command auto-advancement (Component 4) | `/work-deep` edits | N/A |
| 05 | `work-check.sh` fix (Component 6) | Stop hook bugfix | No (warning) |
| 06 | Step output review gates (Component 5) | Integrated into `/work-deep` | N/A |

## Key Design Decisions Made During Spec

1. **Step-to-directory mapping**: `spec` → `specs/` (plural), `decompose` → `streams/` (not `decompose/`)
2. **`reviewed_at` field**: null at creation, set only by `/work-review`, even if 0 findings
3. **`updated_at` field**: set on every state.json mutation
4. **steps[] schema**: `{name, status, gate_id?}` — fully declared in spec 00
5. **Context refresh at gates**: re-read rules from disk at step transitions to combat context degradation
6. **Gate ordering**: handoff → review → fix → gate issue → state advance → context refresh → continue
7. **Handoff is living until advancement**: review can update the handoff; frozen after state advances
8. **Work item naming**: `[<tag>] W-NN: <title> — spec NN` (cross-enforced by decompose review)
9. **User override tracking**: overrides logged as comments on gate issues for audit trail

## Dependency Graph

```
Components 1, 2, 3, 6 — independent, parallel (hooks)
Component 4 — depends on 1, 2, 3 (hooks must validate state transitions)
Component 5 — depends on 4 (integrated into auto-advance flow)
```

## Additional Design Decisions (from scope expansion)

10. **Parallel agent streams** — decompose produces agent prompts, not worktree branches. Implement spawns one subagent per stream.
11. **Docs cleanup** — `docs/feature/<name>/` (directory) becomes `docs/feature/<name>.md` (single summary). Specs move to `.work/<name>/specs/`.
12. **Futures at any step** — storage at `.work/<name>/futures.md`, accessible from all steps in all commands
13. **Doc migration** — 171 files across 11 directories need migration to match new layout. 10+ hardcoded references in commands/skills/agents need updating.
14. **Post-phase validation** — after each implementation phase, validate against specs before starting next phase
15. **Scope expansion detection** — when user adds scope during decompose/implement, agent should acknowledge the step regression rather than silently adding work items
16. **W-02 path alignment** — artifact-gate must implement NEW `.work/<name>/specs/` path checks from day one, not legacy `docs/feature/<name>/`

## Instructions for Implement

Use `bd ready` to find unblocked work. Claim with `bd update <id> --status=in_progress`.
Spec files at `docs/feature/harness-enforcement/0N-*.md` and architecture components 7-12 have implementation details.
Each work item title references its spec for traceability.
After each implementation phase, run post-phase validation before starting the next.
