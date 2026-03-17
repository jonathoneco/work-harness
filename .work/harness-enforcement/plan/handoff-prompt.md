# Plan Handoff: Harness Enforcement

## What This Step Produced

Architecture document at `docs/feature/harness-enforcement/architecture.md` with 5 components:

1. **state-guard.sh** — PostToolUse hook validating state.json mutations (blocking)
2. **artifact-gate.sh** — Stop hook verifying handoff prompts exist for completed steps (blocking)
3. **review-verify.sh** — Stop hook preventing archive without review evidence (blocking)
4. **Command auto-advancement** — /work-deep self-drives between steps (UX)
5. **work-check.sh fix** — Timestamp comparison bug in existing hook

## Key Decisions

- Hooks are project-level (`.claude/hooks/`), committed to git
- `reviewed_at` field added to state.json to distinguish "review found nothing" from "review never ran"
- state-guard uses PostToolUse on Write|Edit with internal path filtering
- Blocking (exit 2) for all enforcement hooks — this is a strict harness
- Scope excludes: findings.jsonl append-only protection, beads integration validation

## Instructions for Spec Step

Write specs for each component:
1. `00-cross-cutting-contracts.md` — shared conventions (hook structure, exit codes, JSON parsing, path conventions)
2. `01-state-guard.md` — state mutation validation spec
3. `02-artifact-gate.md` — handoff/artifact existence spec
4. `03-review-verify.md` — review verification spec
5. `04-command-auto-advance.md` — /work-deep self-driving flow spec
6. `05-work-check-fix.md` — timestamp comparison fix spec

Components 1-3 are independent (can implement in parallel). Component 4 depends on 1-3 (hooks must exist before commands rely on them). Component 5 is independent.
