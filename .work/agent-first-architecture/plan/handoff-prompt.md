# Plan Handoff: Agent-First Architecture

## What This Step Produced

Architecture document at `.work/agent-first-architecture/specs/architecture.md` covering:

- 7 design decisions resolving all open questions from research
- 6-component map with scope estimates and dependency ordering
- 3-phase implementation plan
- Data flow diagrams for standard step delegation and Agent Teams
- Explicit scope exclusions and items deferred to spec

## Architecture Summary

### Core Design: Draft-and-Present

Step agents run foreground, produce artifacts in `.work/`, and return a summary. The lead presents to the user. If user has feedback, the lead re-spawns the agent with feedback context. Named agents (SendMessage) are not used for step execution — agents are stateless, all state lives in files.

### Components for Spec Writing

| Spec | Component                       | Scope  | Dependencies | Key Files                                                                            |
| ---- | ------------------------------- | ------ | ------------ | ------------------------------------------------------------------------------------ |
| 01   | C2: Context Seeding Protocol    | Small  | None         | `claude/skills/work-harness/context-seeding.md` (new)                                |
| 02   | C3: Step Agent Prompt Templates | Medium | C2           | `claude/skills/work-harness/step-agents.md` (new)                                    |
| 03   | C1: Step Agent Dispatcher       | Medium | C2, C3       | `claude/commands/work-deep.md`                                                       |
| 04   | C4: Delegation Audit & Fix      | Small  | C2           | `claude/commands/work-deep.md`, `work-feature.md`, `work-fix.md`                     |
| 05   | C5: Agent Teams Integration     | Medium | C1, C2       | `claude/commands/work-deep.md`, `claude/skills/work-harness/teams-protocol.md` (new) |
| 06   | C6: `/delegate` Skill           | Small  | C2, C3       | `claude/commands/delegate.md` (new)                                                  |

### Design Decisions Summary

1. **D1 — Draft-and-present**: Agents produce artifacts, lead presents, re-spawn on feedback
2. **D2 — Context seeding contract**: Standard preamble (task context + rules + stack) + per-step content
3. **D3 — Phase A validation only**: No schema validation for agent-produced artifacts
4. **D4 — All agents use `mode: "default"`**: No step needs plan mode or bypass
5. **D5 — Retry protocol**: Re-spawn with feedback (2 attempts), then escalate to user
6. **D6 — Tier 3 proving ground**: Extend to Tier 2 after 2+ successful initiatives
7. **D7 — Teams for research and review first**: Defer implement Teams integration

### Phase Plan

- **Phase 1** (C2 → C3 → C1): Foundation — context protocol, templates, dispatcher
- **Phase 2** (C4, C5): Optimize — delegation audit, Agent Teams for research
- **Phase 3** (C6): User-facing — `/delegate` skill

## Deferred to Spec

1. Exact prompt text for each step agent template
2. Teams task schema (fields for shared task list entries)
3. Delegation routing table for `/delegate` command
4. Error message format for agent failure escalation
5. Regression testing strategy (agent vs inline artifact quality)

## Instructions for Spec Step

1. Read this handoff prompt as primary input
2. Read `specs/architecture.md` for full design decisions and component details
3. Write `specs/00-cross-cutting-contracts.md` first — shared schemas, naming conventions, context preamble format
4. Write one spec per component (01 through 06) following the dependency order in the component table above
5. Each spec needs: overview, implementation steps with acceptance criteria, interface contracts, files to create/modify, testing strategy
6. Specs 01-03 (Phase 1) should be fully detailed — they're the foundation
7. Specs 04-06 (Phase 2-3) can reference Phase 1 patterns without duplicating them
