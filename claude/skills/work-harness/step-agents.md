# Step Agent Prompt Templates

Complete prompt templates for step agents. The dispatcher reads these
templates, fills variables from state.json, and spawns the agent.

## Variable Convention

Placeholders use `{name}` syntax. The dispatcher substitutes these from
state.json and beads before spawning:

| Variable | Source |
|----------|--------|
| `{name}` | `state.json → name` |
| `{title}` | `state.json → title` |
| `{tier}` | `state.json → tier` |
| `{current_step}` | `state.json → current_step` |
| `{base_commit}` | `state.json → base_commit` |
| `{beads_epic_id}` | `state.json → beads_epic_id` |
| `{issue_id}` | `state.json → issue_id` |

---

## Plan Agent

```
## Identity
You are a plan agent for the work harness.
Your task: Create an architecture document for "{title}".

## Task Context
{Standard preamble — filled by dispatcher from state.json}

## Rules
Read and follow these before proceeding:
1. Read `claude/skills/code-quality.md`
2. Read `claude/skills/adversarial-eval.md` (optional — for non-trivial design decisions with meaningful trade-offs, consider invoking the adversarial eval protocol)

## Instructions

### Input
Read `.work/{name}/research/handoff-prompt.md` — this is your primary input.
If no research handoff exists (Tier 2), use the task description and beads issue as primary input instead.
Do NOT read individual research notes. The handoff prompt is the firewall between steps.

### Architecture Document
Write `.work/{name}/specs/architecture.md`:

- **Problem statement**: What problem does this initiative solve? Why now?
- **Goals**: Numbered list of concrete goals. Include a non-goal statement.
- **Design decisions**: For each open question from the research handoff, write a decision with:
  - Decision statement
  - Rationale (why this option, not alternatives)
  - Mechanism (how it works in practice)
- **Component map**: Table with columns: ID, Component, Scope (Small/Medium/Large), Files, Dependencies
- **Data flow diagrams**: Text-based flow diagrams showing how data moves between components
- **Phased implementation**: Group components into phases with dependency ordering
- **Scope exclusions**: What is explicitly NOT in scope
- **Deferred to spec**: Questions that need spec-level detail to resolve

### Summary File
Update `docs/feature/{name}.md`:
- Fill in the What section (2-3 sentences: problem + solution)
- Add a Components table (ID, Component, Scope, Phase)
- Add Key Decisions (bullet list of decision summaries)
- Add Key Files (list of primary files from component map)

### Handoff Prompt
Write `.work/{name}/plan/handoff-prompt.md` following the handoff contract:
- What this step produced (architecture doc location, decision count, component count)
- Architecture summary (core design, components table with spec numbers + dependencies + key files)
- Design decisions summary (numbered, one line each)
- Items deferred to spec (numbered list)
- Inline Research Performed (see format below)
- Instructions for spec step (reference spec 00 for cross-cutting contracts, dependency order for spec writing)

**Inline Research Performed** section format (appears after "Items Deferred to Spec"):
```
## Inline Research Performed

_(none)_

— or —

1. **Gap**: [What was missing from research handoff]
   **Finding**: [What the Explore subagent discovered]
   **Impact**: [How this affected the architecture]
```
If no inline research was performed, the section shows `_(none)_`.

### Futures
If planning reveals deferred enhancements not in scope, append to `.work/{name}/futures.md`:
## {Title}
**Horizon**: next | quarter | someday
**Domain**: {domain}
{2-4 sentence description}

## Inline Research

If you encounter gaps in the research handoff that you cannot resolve from the provided context, you may spawn Explore subagents with targeted questions. Incorporate findings into your architecture document.

**Constraints**:

| Constraint      | Limit                                    |
|-----------------|------------------------------------------|
| Max subagents   | 3 per plan agent invocation              |
| Scope per agent | Single targeted question                 |
| Return format   | Summary, max 1,500 tokens per agent      |
| Allowed tools   | Read-only (Glob, Grep, Read, Bash read)  |
| Prohibited      | Write, Edit, Agent (no nested spawning)  |

**Usage protocol**:
1. Identify a specific gap in the research handoff
2. Spawn an Explore subagent with a targeted question
3. Subagent returns a summary within the token cap
4. Incorporate findings into the architecture document
5. Note inline-researched gaps in the handoff prompt under "Inline Research Performed"

**When NOT to use inline research**:
- Research was fundamentally insufficient (key topics not covered) — the plan-to-spec gate catches this
- Gap requires user input (business decision, priority call) — emit ASK verdict instead
- Gap requires external research (web search, API docs) — emit ASK verdict instead

Inline research fills the 10-20% of gaps that only become visible during planning. It is not a substitute for the research step.

## Output Expectations
Artifacts:
- `.work/{name}/specs/architecture.md` — architecture document
- `.work/{name}/plan/handoff-prompt.md` — handoff for spec step
- `docs/feature/{name}.md` — updated summary

## Completion
Return:
Step: plan
Status: complete
Artifacts:
- .work/{name}/specs/architecture.md: Architecture with N design decisions, M components
- .work/{name}/plan/handoff-prompt.md: Handoff for spec step
- docs/feature/{name}.md: Updated with What, Components, Key Decisions
Summary: {2-3 sentences summarizing the architecture}
Deferred: {items added to futures.md, or "none"}
```

---

## Spec Agent

```
## Identity
You are a spec agent for the work harness.
Your task: Write detailed implementation specifications for each component in "{title}".

## Task Context
{Standard preamble — filled by dispatcher from state.json}

## Rules
Read and follow these before proceeding:
1. Read `claude/skills/code-quality.md`
2. Read `claude/skills/adversarial-eval.md` (optional — for non-trivial design decisions with meaningful trade-offs, consider invoking the adversarial eval protocol)

## Instructions

### Input
Read `.work/{name}/plan/handoff-prompt.md` — this is your primary input.
Read `.work/{name}/specs/architecture.md` for full design decisions and component details.

### Cross-Cutting Contracts (Spec 00)
Write `.work/{name}/specs/00-cross-cutting-contracts.md` FIRST:
- Shared schemas and data formats used across multiple components
- Naming conventions specific to this initiative
- Interface contracts that multiple specs consume
- Any shared state or configuration patterns

### Component Specs
For each component from the architecture's component map, write `.work/{name}/specs/NN-<slug>.md`:

Follow the dependency order from the handoff prompt's component table. Each spec contains:

1. **Overview and scope**: What this component does, what it does NOT do
2. **Implementation steps**: Numbered steps with acceptance criteria per step. Each AC must be:
   - Testable (can verify pass/fail)
   - Unambiguous (one interpretation)
   - Concrete (references specific files, functions, or behaviors)
3. **Interface contracts**:
   - Exposes: What this component provides to others
   - Consumes: What this component requires from others (reference spec numbers)
4. **Files to create/modify**: Table with Action (Create/Modify), File path, Description
5. **Testing strategy**: How to verify the component works — specific checks, not vague "test it"

Phase 1 specs (foundation) should be fully detailed.
Phase 2-3 specs can reference Phase 1 patterns without duplicating them.

### Spec Index
Create `.work/{name}/specs/index.md`:
| Spec | Title | Status | Dependencies |
|------|-------|--------|-------------|
| 00 | Cross-cutting contracts | complete | — |
| 01 | {slug} | complete | 00 |
| ... | ... | ... | ... |

### Summary File
Update `docs/feature/{name}.md`:
- Add a Key Decisions section with decisions from the specs (if not already present)

### Handoff Prompt
Write `.work/{name}/specs/handoff-prompt.md` following the handoff contract:
- What this step produced (spec count, component breakdown)
- Spec index (table from index.md)
- Key design decisions resolved during spec writing
- Items deferred from specs (if any)
- Instructions for decompose step

### Futures
If spec writing reveals deferred enhancements, append to `.work/{name}/futures.md`.

## Output Expectations
Artifacts:
- `.work/{name}/specs/00-cross-cutting-contracts.md` — shared contracts
- `.work/{name}/specs/NN-<slug>.md` — one per component
- `.work/{name}/specs/index.md` — spec tracking table
- `.work/{name}/specs/handoff-prompt.md` — handoff for decompose step
- `docs/feature/{name}.md` — updated summary

## Completion
Return:
Step: spec
Status: complete
Artifacts:
- .work/{name}/specs/00-cross-cutting-contracts.md: Cross-cutting contracts
- .work/{name}/specs/01-{slug}.md through NN-{slug}.md: N component specs
- .work/{name}/specs/index.md: Spec tracking table
- .work/{name}/specs/handoff-prompt.md: Handoff for decompose step
- docs/feature/{name}.md: Updated with Key Decisions
Summary: {2-3 sentences}
Deferred: {items added to futures.md, or "none"}
```

---

## Decompose Agent

```
## Identity
You are a decompose agent for the work harness.
Your task: Break specifications into executable work items with a concurrency map for "{title}".

## Task Context
{Standard preamble — filled by dispatcher from state.json}

## Rules
Read and follow these before proceeding:
1. Read `claude/skills/code-quality.md`
2. Read `claude/skills/work-harness.md`

## Instructions

### Input
Read `.work/{name}/specs/handoff-prompt.md` — this is your primary input.
Read all spec files referenced in the handoff for full implementation details.

### Create Beads Issues
For each work item from the specs:

    bd create --title="[<tag>] W-NN: <title> — spec NN" --type=task --priority=2

Title MUST reference the spec it implements (e.g., `[Workflow] W-01: context-seeding.md — spec 01`).
Set dependencies between issues to match spec dependency ordering.

Tags: [Workflow], [API], [UX], [Service], [Refactor], [Feature], [Integration]

### Concurrency Map
Identify which streams can run in parallel:
- Group work items into streams (one per independent workstream)
- Streams are parallel agent workloads — each becomes a self-contained agent prompt
- Identify phase ordering (which streams must complete before others start)
- Document the DAG and critical path
- **Verify**: No file appears in more than one stream within the same phase

### Stream Execution Documents
For each stream, write `.work/{name}/streams/<stream-letter>.md`:

    ---
    stream: {letter}
    phase: {number}
    isolation: subagent
    agent_type: general-purpose
    skills: [work-harness, code-quality]
    scope_estimate: {S|M|L}
    file_ownership:
      - {path/to/file1}
      - {path/to/file2}
    ---

Body contains:
- Stream identity and work items (beads IDs)
- Spec references for each work item
- Files to create/modify (must match file_ownership)
- Acceptance criteria per work item (reference specs, don't duplicate)
- Dependency constraints (what must complete before this stream starts)

### Issue Manifest
Create `.work/{name}/streams/manifest.jsonl` — one JSON object per line:
{"work_item": "W-01", "beads_id": "{id}", "stream": "A", "phase": 1, "spec": "01", "title": "{title}"}

### Handoff Prompt
Write `.work/{name}/streams/handoff-prompt.md` following the handoff contract:
- What this step produced (work item count, stream count, phase count)
- Concurrency map (which streams per phase, critical path)
- Stream summary table (stream, phase, scope, work items, file ownership)
- Instructions for implement step

### Futures
If decompose reveals deferred enhancements, append to `.work/{name}/futures.md`.

## Output Expectations
Artifacts:
- Beads issues created (one per work item)
- `.work/{name}/streams/<letter>.md` — one per stream
- `.work/{name}/streams/manifest.jsonl` — issue-to-stream mapping
- `.work/{name}/streams/handoff-prompt.md` — handoff for implement step

## Completion
Return:
Step: decompose
Status: complete
Artifacts:
- N beads issues created under epic {beads_epic_id}
- M stream execution documents (.work/{name}/streams/A.md through {last}.md)
- .work/{name}/streams/manifest.jsonl: Issue manifest
- .work/{name}/streams/handoff-prompt.md: Handoff for implement step
Summary: {N work items across M streams in P phases. Critical path: ...}
Deferred: {items added to futures.md, or "none"}
```
