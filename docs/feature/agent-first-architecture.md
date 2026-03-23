# W2: Agent-First Architecture

**Status:** active
**Tier:** 3
**Priority:** P2

## What

The harness executes plan, spec, and decompose steps inline in the lead agent's context window. This consumes context on execution rather than orchestration, prevents parallelization, and makes the lead a bottleneck. W2 shifts these steps to dedicated agents with a formal context seeding contract, audits existing delegation gaps, integrates Agent Teams for naturally parallel steps, and exposes delegation as a user command.

## Components

| ID | Component | Scope | Phase |
|----|-----------|-------|-------|
| C1 | Step Agent Dispatcher | Medium | 1 |
| C2 | Context Seeding Protocol | Small | 1 |
| C3 | Step Agent Prompt Templates | Medium | 1 |
| C4 | Delegation Audit & Fix | Small | 2 |
| C5 | Agent Teams Integration | Medium | 2 |
| C6 | `/delegate` Skill | Small | 3 |

## Key Decisions

- **Draft-and-present** interaction model: agents produce artifacts, lead presents to user
- **Opus everywhere**: no per-step model routing
- **Steps as building blocks**: dispatch pattern applies to all tiers from the start, no migration plan
- **Agent Teams for research and review**: defer implement step Teams integration
- **Phase A validation only**: no schema validation for agent-produced artifacts
- **6-section agent prompt structure**: Identity, Task Context, Rules, Instructions, Output Expectations, Completion
- **Re-spawn with revision**: agents revise partial artifacts in place, never delete and restart
- **Keyword-based delegation routing**: `/delegate` infers task type from first word of description

## Key Files

- `.work/agent-first-architecture/specs/architecture.md` — full architecture document
- `claude/commands/work-deep.md` — primary file modified (C1, C3, C4, C5)
- `claude/skills/work-harness/context-seeding.md` — new (C2)
- `claude/skills/work-harness/step-agents.md` — new (C3)
- `claude/skills/work-harness/teams-protocol.md` — new (C5)
- `claude/commands/delegate.md` — new (C6)
