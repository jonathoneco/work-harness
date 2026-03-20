# Current Harness Architecture

## 3-Tier System

| Tier | Command | Steps |
|------|---------|-------|
| 1 Fix | `/work-fix` | assess → implement → review |
| 2 Feature | `/work-feature` | assess → plan → implement → review |
| 3 Initiative | `/work-deep` | assess → research → plan → spec → decompose → implement → review |

## Step Router Pattern

All commands use same data-driven pattern:
1. Read `current_step` from state.json
2. Route to step handler
3. Execute step logic
4. Auto-advance via step-transition protocol (Phase A + B review, user approval gate)

## Agent Delegation Inventory

**Key pattern**: Steps are executed INLINE by the lead agent (plan, spec, decompose). Only research, implement, and review spawn subagents.

| Step | Agent Type | Spawned? |
|------|-----------|----------|
| research | Explore (parallel per topic) | Yes |
| plan | Inline (lead) | No |
| spec | Inline (lead) | No |
| decompose | Inline (lead) | No |
| implement | Per stream doc (general-purpose, custom) | Yes |
| review | Via /work-review (specialist agents) | Yes |
| Phase A/B gates | Explore + Plan | Yes (at every transition) |

**Current gaps**: plan, spec, decompose all run inline — not as dedicated agents. This is the core opportunity for W2.

## State Management

- `state.json` per task, validated by `hooks/state-guard.sh`
- Invariant: exactly 1 active step (unless archived)
- Only commands write state.json (not subagents)
- Atomic writes required

## Worktree Usage

Stream docs support `isolation: worktree` but it's manual — lead notifies user, user manages lifecycle. No auto-management.

## Pain Points

1. **Skill injection verbosity** — Path B (prompt-based) requires copy-pasting skill fragments into every agent prompt
2. **Serial step execution** — plan/spec/decompose run inline, can't parallelize
3. **No parallel research context** — research agents can't express inter-topic dependencies
4. **Phase sequencing bottleneck** — all streams in a phase must complete before next phase starts
5. **Worktree isolation is manual** — no auto-management
6. **Handoff prompt maintenance** — manually synthesized, risk of incompleteness
