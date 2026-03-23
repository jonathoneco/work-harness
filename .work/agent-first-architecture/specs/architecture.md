# Architecture: Agent-First Step Execution

## Problem Statement

The harness executes plan, spec, and decompose steps **inline** in the lead agent's context window. Only research, implement, and review spawn subagents. This creates three problems:

1. **Context consumption**: The lead spends context executing work instead of orchestrating it
2. **No parallelization**: Inline steps can't decompose into concurrent sub-tasks
3. **Bottleneck**: The lead both executes AND orchestrates, limiting supervisory quality

## Goals

1. Delegate plan, spec, and decompose steps to dedicated agents (Tier 3 first)
2. Define a formal context seeding contract so agents get exactly the right input
3. Audit and fix existing delegation gaps (research, implement, review agents)
4. Integrate Agent Teams for naturally parallel steps (research, review)
5. Create `/delegate` skill for ad-hoc agent routing

**Non-goal**: Change WHAT steps produce. Artifacts, validation, and handoff prompts remain identical.

---

## Design Decisions

### D1: User Interaction Model — Draft-and-Present

**Decision**: Agents produce draft artifacts. The lead presents them to the user. If the user has feedback, the lead re-spawns the agent with the feedback as additional context.

**Rationale**: Foreground agents block the lead and cannot interact with the user directly. Background agents complete asynchronously. Neither supports real-time dialogue. The draft-and-present pattern keeps the lead in the conversation while offloading execution.

**Mechanism**:

1. Lead spawns step agent (foreground) with full context + instructions
2. Agent writes artifacts to `.work/` and returns a summary
3. Lead reads artifacts, presents summary to user
4. If user approves → proceed to Phase A/B validation (unchanged)
5. If user has feedback → lead re-spawns agent with: original context + artifacts written so far + user feedback. Agent revises in place.

**Named agents (SendMessage)**: Not used for step execution. Reason: agents don't persist across sessions, and step agents should be stateless — all state lives in `.work/` files. Re-spawning with feedback is simpler and more resilient than maintaining agent sessions.

### D2: Context Seeding Contract

**Decision**: Every step agent receives a standard context preamble followed by step-specific content. The preamble is defined once and referenced by all step dispatchers.

**Standard Preamble** (injected into every step agent prompt):

```
## Task Context
- Task: {name} (Tier {tier})
- Step: {current_step}
- Base commit: {base_commit}
- Epic: {beads_epic_id}

## Rules
Read and follow these before proceeding:
1. Read `claude/skills/code-quality.md`
2. Read `.claude/rules/architecture-decisions.md` (if exists)

## Stack Context (if harness.yaml exists)
- Language: {stack.language}
- Framework: {stack.framework}
- Database: {stack.database}
- Build commands: {stack.build_commands}
```

**Step-Specific Context**:

| Step      | Receives                                                    | Does NOT Receive                    |
| --------- | ----------------------------------------------------------- | ----------------------------------- |
| Research  | Task description, topic assignments, output format template | Prior step artifacts (none exist)   |
| Plan      | `research/handoff-prompt.md`                                | Individual research notes           |
| Spec      | `plan/handoff-prompt.md`, `specs/architecture.md`           | Research notes, raw plan discussion |
| Decompose | `specs/handoff-prompt.md`, all spec files                   | Research notes, plan notes          |
| Implement | `streams/handoff-prompt.md`, stream doc, relevant specs     | Other streams' docs                 |
| Review    | Full diff, findings template, quality checklist             | Step-internal artifacts             |

**Key rule**: Handoff prompts are the **only** bridge between steps. Step agents never receive raw artifacts from steps before their input step.

### D3: Artifact Format Validation — Phase A Only

**Decision**: Rely on existing Phase A structural checks (Explore agent). No schema validation.

**Rationale**: Phase A already checks that files exist, are indexed, follow naming conventions, and have required sections. Adding formal schemas would be over-engineering — the cost of maintaining schemas exceeds the benefit for a prompt-driven system. Phase B (quality review) catches substance issues.

### D4: Step Agent Mode Selection

**Decision**: All step agents use `mode: "default"`.

| Step      | Why `default`                                           |
| --------- | ------------------------------------------------------- |
| Plan      | Writes files to `.work/` — needs write permission       |
| Spec      | Creates multiple spec files — needs write permission    |
| Decompose | Creates beads issues + stream docs — needs write + bash |
| Research  | Already uses `default` — no change                      |
| Implement | Already uses `default` — no change                      |

No step benefits from `plan` mode (read-only-ish) because all steps produce file artifacts. `bypassPermissions` is unnecessary — agents write to `.work/` which is low-risk.

### D5: Failure/Retry Protocol

**Decision**: Re-spawn with feedback, escalate after 2 attempts.

**Protocol**:

1. Step agent produces artifacts
2. Phase A/B validation runs (unchanged)
3. If BLOCKING:
   - **Attempt 1**: Re-spawn agent with: original context + validation feedback + "Fix these specific issues: ..."
   - **Attempt 2**: Re-spawn with: original context + both rounds of feedback + "These issues persist: ..."
   - **Attempt 3**: Escalate to user. Present: what the agent produced, what validation flagged, suggested manual fix.

This aligns with the existing "max 2 retries, then ask user" pattern used throughout the harness.

### D6: Tier 2 Applicability — Tier 3 Proving Ground

**Decision**: Implement for Tier 3 only. Extend to Tier 2 after 2+ successful Tier 3 initiatives.

> [!NOTE]
> I don't agree, our steps should be modular and like building blocks, a "migration plan" creates divergence that's unnecessary tech debt and goes away from one of the main things we're trying to accomplish with these efforts

**Success criteria for Tier 2 extension**:

1. Two Tier 3 initiatives complete using step agents without systemic failures
2. No pattern of validation failures caused by agent delegation (vs inline execution)
3. User confirms quality parity or improvement

**Tier 2 candidate steps**: Plan step only (T2 has no research/spec/decompose). The plan step is the highest-value target — it's the most context-intensive inline step in Tier 2.

### D7: Agent Teams Integration — Research and Review First

**Decision**: Integrate Agent Teams for research step (Phase 2), then review step. Defer implement step to future work.

**Why research first**:

- Clear task boundaries (independent topics)
- No file mutation conflicts (research notes don't overlap)
- Natural parallelism (3+ topics explored concurrently)
- Self-claiming task list replaces lead-orchestrated topic assignment

**Why review second**:

- Independent reviewers (each specialist checks different aspects)
- No shared mutable state (findings append to separate files)
- Direct mailbox enables reviewers to flag cross-cutting concerns

**Why defer implement**:

- Stream-based parallelism already works via manual subagent spawning
- File ownership partitioning is well-established
- Teams adds complexity without clear benefit over current approach

**Session resumption constraint**: Teams disappear on `/resume`. Mitigated by:

- Scoping team work to complete within a single session/step
- Results persist in `.work/` files (already true)
- Lead can re-create team after resume if needed

---

## Component Map

### C1: Step Agent Dispatcher

**Scope**: Medium | **Files**: `claude/commands/work-deep.md`

Replace inline execution blocks for plan, spec, and decompose with agent-spawning dispatchers. Each dispatcher:

1. Constructs the agent prompt using context seeding protocol (C2)
2. Spawns a foreground agent with `mode: "default"`
3. Reads the agent's return message for status
4. Checks artifacts exist, presents summary to user
5. On user feedback: re-spawns with feedback context

**Does NOT change**: Step routing, Phase A/B validation, state transitions, handoff prompt format.

**Dependencies**: C2 (context seeding protocol must be defined first)

### C2: Context Seeding Protocol

**Scope**: Small | **Files**: `claude/skills/work-harness/context-seeding.md` (new)

Define the standard preamble and per-step context requirements as a referenceable protocol. This is a **documentation artifact** consumed by command files — not executable code.

Contents:

- Standard preamble template (D2 above)
- Per-step context table with exact file paths
- Rule file injection list
- Anti-patterns (what NOT to seed)

**Dependencies**: None (foundational)

### C3: Step Agent Prompt Templates

**Scope**: Medium | **Files**: `claude/commands/work-deep.md`, `claude/skills/work-harness/step-agents.md` (new)

For each delegated step (plan, spec, decompose), define the complete agent prompt. Each template includes:

- Context preamble (from C2)
- Step-specific instructions (extracted from current inline instructions in work-deep.md)
- Output expectations (artifact locations, format requirements)
- Completion signal (what to return to the lead)

The current inline instructions in work-deep.md for plan/spec/decompose are the source material — they define WHAT each step does. The templates wrap these instructions with WHOM context (agent identity, available tools) and WHERE context (file paths, output locations).

**Dependencies**: C2

### C4: Delegation Audit & Fix

**Scope**: Small | **Files**: `claude/commands/work-deep.md`, `claude/commands/work-feature.md`, `claude/commands/work-fix.md`

Audit all current agent spawning patterns against the context seeding protocol (C2) and fix gaps:

**Known gaps from research**:

- Research agents: skill injection inconsistency (some get `work-harness`, some don't)
- Implementation agents: stack context not always included
- Review agents: Phase B agents sometimes missing `architecture-decisions.md`
- Tier 2 plan step: Explore agent searches for context but prompt is ad-hoc

Each fix is a targeted edit to ensure all existing agent spawns follow C2's protocol.

**Dependencies**: C2 (need the protocol to audit against)

### C5: Agent Teams Integration

**Scope**: Medium | **Files**: `claude/commands/work-deep.md`, `claude/skills/work-harness/teams-protocol.md` (new)

Replace manual parallel subagent spawning in the research step with Agent Teams:

**Research step integration**:

1. Lead creates team: `TeamCreate` with team name derived from task name
2. Lead creates shared task list: one task per research topic
3. Teammates self-claim topics, write notes to `.work/<name>/research/`
4. Teammates mark tasks complete when notes are written
5. Lead monitors completion, runs index generation when all tasks done
6. Lead tears down team: `TeamDelete`

**Protocol document** defines:

- Team naming convention
- Task creation and claiming workflow
- File ownership rules (each teammate owns its research note file)
- Completion detection pattern
- Teardown sequence
- Failure handling (teammate hangs, task unclaimed)

**Dependencies**: C1 (dispatcher infrastructure), C2 (context protocol for teammate prompts)

### C6: `/delegate` Skill

**Scope**: Small | **Files**: `claude/commands/delegate.md` (new)

Ad-hoc delegation command that:

1. Reads current context (active task, step, recent conversation)
2. Infers task type from user description
3. Routes to appropriate agent using C2 context seeding + C3 templates
4. Returns agent output to user

**Use cases**:

- User wants to delegate a sub-task mid-step
- User wants to parallelize something the harness doesn't auto-parallelize
- Quick delegation without full step machinery

**Dependencies**: C2, C3 (needs established patterns to route to)

---

## Data Flow

```
User request
    │
    ▼
Lead Agent (orchestrator)
    │
    ├── Read state.json → determine current_step
    │
    ├── Read handoff prompt → previous step's output
    │
    ├── Construct agent prompt:
    │     ├── Standard preamble (C2)
    │     ├── Step instructions (C3)
    │     └── Handoff content
    │
    ├── Spawn step agent (foreground)
    │     │
    │     ├── Agent reads rules, handoff
    │     ├── Agent produces artifacts in .work/
    │     └── Agent returns summary
    │
    ├── Lead presents summary to user
    │     │
    │     ├── User approves → Phase A/B validation (unchanged)
    │     └── User gives feedback → re-spawn with feedback
    │
    └── Phase A/B → transition (unchanged)
```

For Agent Teams (research step):

```
Lead Agent
    │
    ├── TeamCreate("research-{task-name}")
    │
    ├── Create shared tasks (one per topic)
    │
    ├── Teammates auto-spawn and self-claim
    │     ├── Teammate A → topic 1 → .work/.../research/01-*.md
    │     ├── Teammate B → topic 2 → .work/.../research/02-*.md
    │     └── Teammate C → topic 3 → .work/.../research/03-*.md
    │
    ├── Lead monitors task list for completion
    │
    ├── All complete → Lead generates index + handoff
    │
    └── TeamDelete
```

---

## Phased Implementation

### Phase 1: Foundation (C1, C2, C3)

**Goal**: Steps execute as agents with proper context seeding.

| Component                       | Work Items                                                          |
| ------------------------------- | ------------------------------------------------------------------- |
| C2: Context seeding protocol    | Define preamble template, per-step context table, anti-patterns     |
| C3: Step agent prompt templates | Extract plan/spec/decompose instructions into agent-ready templates |
| C1: Step agent dispatcher       | Replace inline execution in work-deep.md with agent spawning        |

**Order**: C2 → C3 → C1 (protocol → templates → dispatcher)

**Validation**: Run a Tier 3 task through plan step using agent delegation. Compare artifact quality to inline execution.

### Phase 2: Optimize & Audit (C4, C5)

**Goal**: Fix existing delegation gaps. Introduce Agent Teams for research.

| Component            | Work Items                                               |
| -------------------- | -------------------------------------------------------- |
| C4: Delegation audit | Audit all agent spawns, fix context gaps                 |
| C5: Agent Teams      | Integrate Teams for research step, define teams protocol |

**Order**: C4 first (quick wins), C5 second (new subsystem)

**Validation**: Run research step using Teams. Verify notes quality matches subagent approach.

### Phase 3: User-Facing Delegation (C6)

**Goal**: Expose delegation as a user command.

| Component             | Work Items                                   |
| --------------------- | -------------------------------------------- |
| C6: `/delegate` skill | Build routing logic on top of C2/C3 patterns |

**Order**: After Phase 1+2 patterns are proven.

**Validation**: User can `/delegate "write tests for X"` and get properly-contexted agent execution.

---

## Scope Exclusions

- **Model routing per step**: Opus everywhere (D5 from research). No per-step model override.
- **Tier 1 changes**: T1 tasks are too small to benefit from agent delegation.
- **Skill injection via YAML frontmatter**: Not supported by the platform. Continue with Read-based injection.
- **Inter-agent communication protocol**: Deferred to future (see futures.md). Named agents + SendMessage is possible but adds complexity without clear need.
- **Agent Teams for implement step**: Deferred until research/review Teams patterns are proven.
- **Nested teams**: Not supported by the platform. Teammates can spawn subagents but not sub-teams.

## Deferred to Spec

1. **Exact prompt templates**: C3 needs full prompt text for each step agent — the architecture defines structure, spec defines content.
2. **Teams task schema**: C5 needs the exact task format for shared task lists — architecture says "one task per topic", spec defines fields.
3. **Delegation routing table for /delegate**: C6 needs task-type-to-agent mapping — architecture says "route based on context", spec defines the routing rules.
4. **Error message format**: When agents fail and escalate to user, what exactly does the lead present? Architecture says "what agent produced + what validation flagged + suggested fix", spec defines the template.
5. **Regression testing strategy**: How to verify agent-delegated steps produce equivalent artifacts to inline execution.
