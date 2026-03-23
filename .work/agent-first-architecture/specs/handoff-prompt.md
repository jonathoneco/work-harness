# Spec Handoff: Agent-First Architecture

## What This Step Produced

7 specification documents (00-06) covering the full agent-first architecture:

- **1 cross-cutting contracts spec** (00): Shared schemas, prompt structure, retry protocol, crash handling, regression testing strategy
- **3 Phase 1 foundation specs** (01-03): Context seeding protocol, step agent prompt templates, step agent dispatcher — fully detailed
- **3 Phase 2-3 specs** (04-06): Delegation audit, Agent Teams integration, `/delegate` skill — reference Phase 1 patterns

## Spec Index

| Spec | Title | Component | Phase | Dependencies |
|------|-------|-----------|-------|-------------|
| 00 | Cross-cutting contracts | — | — | — |
| 01 | Context Seeding Protocol | C2 | 1 | 00 |
| 02 | Step Agent Prompt Templates | C3 | 1 | 00, 01 |
| 03 | Step Agent Dispatcher | C1 | 1 | 00, 01, 02 |
| 04 | Delegation Audit & Fix | C4 | 2 | 00, 01 |
| 05 | Agent Teams Integration | C5 | 2 | 00, 01, 03 |
| 06 | `/delegate` Skill | C6 | 3 | 00, 01, 02 |

## Key Design Decisions Resolved During Spec Writing

1. **Agent prompt structure**: 6 required sections (Identity, Task Context, Rules, Instructions, Output Expectations, Completion) — spec 00 §1
2. **Re-spawn prompt structure**: "Previous Attempt" section inserted between Rules and Instructions — spec 00 §5
3. **Completion signal format**: Structured text with Step, Status, Artifacts, Summary, Deferred — spec 00 §6
4. **Failure handling**: Case-by-case, preserve partial artifacts, 2-retry limit then escalate — spec 00 §7
5. **Regression testing**: Phase A/B gates are the measurement, no prescribed thresholds — spec 00 §9
6. **Teams task schema**: Title + description + status, with output file path embedded in description — spec 05 §1.2
7. **Steps as building blocks**: Dispatch pattern applies to all tiers, not Tier 3 only (D6 override) — spec 03 Step 5
8. **Delegate routing**: Keyword-based on first word (research → Explore, review → general-purpose, etc.), ambiguous defaults to general-purpose — spec 06 §1.3
9. **Decompose agent exception**: Only agent allowed to create beads issues (via `bd create`) — spec 03 Step 4 note

## Deferred Items (from spec writing)

No new items deferred. All 5 items from the plan handoff were resolved:
1. Exact prompt text → spec 02 (full templates for plan, spec, decompose)
2. Teams task schema → spec 05 §1.2 (title, description, status)
3. Delegation routing table → spec 06 §1.3 (5 categories + default)
4. Error message format → spec 00 §5 (retry limit, lead uses judgment)
5. Regression testing strategy → spec 00 §9 (Phase A/B gates are the measurement, no prescribed thresholds)

Phase B advisory notes from plan→spec gate were also addressed:
- Agent failure handling → spec 00 §7 (case-by-case, preserve partial artifacts)
- Teams failure handling → spec 05 §1.5 (case-by-case, fall back to sequential if systemic)

Architecture insight integrated (D6 override):
- Steps are modular building blocks — dispatch pattern applies to all tiers, not Tier 3 only
- Spec 03 updated: dispatcher also applies to Tier 2's plan step in work-feature.md
- No "proving ground" or migration plan — avoids divergence and tech debt

## Key Artifacts

- `.work/agent-first-architecture/specs/00-cross-cutting-contracts.md`
- `.work/agent-first-architecture/specs/01-context-seeding-protocol.md`
- `.work/agent-first-architecture/specs/02-step-agent-prompt-templates.md`
- `.work/agent-first-architecture/specs/03-step-agent-dispatcher.md`
- `.work/agent-first-architecture/specs/04-delegation-audit-fix.md`
- `.work/agent-first-architecture/specs/05-agent-teams-integration.md`
- `.work/agent-first-architecture/specs/06-delegate-skill.md`
- `.work/agent-first-architecture/specs/index.md`

## Instructions for Decompose Step

1. Read this handoff prompt as primary input
2. Read all spec files for full implementation details
3. Create beads issues for each work item — titles MUST reference spec number: `[<tag>] W-NN: <title> — spec NN`
4. Group work items into streams following the 3-phase structure:
   - **Phase 1**: Specs 01, 02, 03 (foundation — must complete before Phase 2)
   - **Phase 2**: Specs 04, 05 (can be parallel within phase, but after Phase 1)
   - **Phase 3**: Spec 06 (after Phase 2 patterns are proven)
5. Within Phase 1, respect dependency order: 01 → 02 → 03 (sequential)
6. Within Phase 2, specs 04 and 05 can be parallel streams (no shared files)
7. Write stream execution documents with YAML frontmatter per decompose step conventions
8. Verify: no file appears in more than one stream within the same phase
9. Key file ownership boundaries:
   - Spec 01: `claude/skills/work-harness/context-seeding.md` (new)
   - Spec 02: `claude/skills/work-harness/step-agents.md` (new)
   - Spec 03: `claude/commands/work-deep.md` + `work-feature.md` (modify — plan/spec/decompose dispatch blocks)
   - Spec 04: `claude/commands/work-deep.md` + `work-feature.md` + `work-fix.md` (modify — agent spawn patterns)
   - Spec 05: `claude/skills/work-harness/teams-protocol.md` (new) + `claude/commands/work-deep.md` (modify — research step)
   - Spec 06: `claude/commands/delegate.md` (new)
   - **Conflict**: Specs 03, 04, 05 all modify `work-deep.md` — phase ordering resolves this (03 in Phase 1, 04+05 in Phase 2)
