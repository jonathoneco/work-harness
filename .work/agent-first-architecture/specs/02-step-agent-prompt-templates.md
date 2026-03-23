# Spec 02: Step Agent Prompt Templates (C3)

**Component**: C3 — Step Agent Prompt Templates
**Scope**: Medium
**Dependencies**: Spec 00 (cross-cutting contracts), Spec 01 (context seeding protocol)
**Phase**: 1

## Overview

Define complete agent prompts for the three steps being delegated in Phase 1: **plan**, **spec**, and **decompose**. Each template wraps the current inline instructions from `work-deep.md` with the agent prompt structure (spec 00 §1) and context seeding protocol (spec 01).

The templates are stored in a new skill file at `claude/skills/work-harness/step-agents.md`. The dispatcher (spec 03) reads this file to construct the agent prompt at dispatch time — the lead fills in variables from state.json before spawning.

**Source material**: The current inline instructions in `work-deep.md` for plan/spec/decompose define WHAT each step does. The templates add WHO context (agent identity, available tools) and WHERE context (file paths, output locations).

---

## Implementation Steps

### Step 1: Create the step agents skill file

**File**: `claude/skills/work-harness/step-agents.md` (new)

This file contains three complete prompt templates, one per delegated step.

---

### Step 2: Plan Agent Template

```markdown
## Identity
You are a plan agent for the work harness.
Your task: Synthesize research findings into an architecture document for "{title}".

## Task Context
{Standard preamble — filled by dispatcher from state.json}

## Rules
Read and follow these before proceeding:
1. Read `claude/skills/code-quality.md`

## Instructions

### Input
Read `.work/{name}/research/handoff-prompt.md` — this is your primary input.
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
- Instructions for spec step (reference spec 00 for cross-cutting contracts, dependency order for spec writing)

### Futures
If planning reveals deferred enhancements not in scope, append to `.work/{name}/futures.md`:
```
## {Title}
**Horizon**: next | quarter | someday
**Domain**: {domain}
{2-4 sentence description}
```

## Output Expectations
Artifacts:
- `.work/{name}/specs/architecture.md` — architecture document
- `.work/{name}/plan/handoff-prompt.md` — handoff for spec step
- `docs/feature/{name}.md` — updated summary

## Completion
Return:
```
Step: plan
Status: complete
Artifacts:
- .work/{name}/specs/architecture.md: Architecture with N design decisions, M components
- .work/{name}/plan/handoff-prompt.md: Handoff for spec step
- docs/feature/{name}.md: Updated with What, Components, Key Decisions
Summary: {2-3 sentences summarizing the architecture}
Deferred: {items added to futures.md, or "none"}
```
```

---

### Step 3: Spec Agent Template

```markdown
## Identity
You are a spec agent for the work harness.
Your task: Write detailed implementation specifications for each component in "{title}".

## Task Context
{Standard preamble — filled by dispatcher from state.json}

## Rules
Read and follow these before proceeding:
1. Read `claude/skills/code-quality.md`

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
```
| Spec | Title | Status | Dependencies |
|------|-------|--------|-------------|
| 00 | Cross-cutting contracts | complete | — |
| 01 | {slug} | complete | 00 |
| ... | ... | ... | ... |
```

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
```
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
```

---

### Step 4: Decompose Agent Template

```markdown
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
```bash
bd create --title="[<tag>] W-NN: <title> — spec NN" --type=task --priority=2
```

Title MUST reference the spec it implements (e.g., `[Workflow] W-01: context-seeding.md — spec 01`).
Set dependencies between issues to match spec dependency ordering.

Tags: `[Workflow]`, `[API]`, `[UX]`, `[Service]`, `[Refactor]`, `[Feature]`, `[Integration]`

### Concurrency Map
Identify which streams can run in parallel:
- Group work items into streams (one per independent workstream)
- Streams are parallel agent workloads — each becomes a self-contained agent prompt
- Identify phase ordering (which streams must complete before others start)
- Document the DAG and critical path
- **Verify**: No file appears in more than one stream within the same phase

### Stream Execution Documents
For each stream, write `.work/{name}/streams/<stream-letter>.md`:

```yaml
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
```

Body contains:
- Stream identity and work items (beads IDs)
- Spec references for each work item
- Files to create/modify (must match file_ownership)
- Acceptance criteria per work item (reference specs, don't duplicate)
- Dependency constraints (what must complete before this stream starts)

### Issue Manifest
Create `.work/{name}/streams/manifest.jsonl` — one JSON object per line:
```json
{"work_item": "W-01", "beads_id": "{id}", "stream": "A", "phase": 1, "spec": "01", "title": "{title}"}
```

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
```
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
```

---

### Step 5: Register in work-harness skill index

Add a reference to `step-agents.md` in `claude/skills/work-harness.md`.

---

## Interface Contracts

### Exposes
- **Plan agent template**: Used by spec 03 (dispatcher) when `current_step = "plan"`
- **Spec agent template**: Used by spec 03 (dispatcher) when `current_step = "spec"`
- **Decompose agent template**: Used by spec 03 (dispatcher) when `current_step = "decompose"`

### Consumes
- **Spec 00 §1**: Agent prompt structure (section ordering)
- **Spec 00 §2**: Standard preamble template (Task Context section)
- **Spec 00 §3**: Skill injection convention (Rules section)
- **Spec 00 §5**: Retry/feedback protocol (re-spawn prompt structure)
- **Spec 00 §6**: Completion signal format (Completion section)
- **Spec 01**: Per-step context table (what each agent receives as input)

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/skills/work-harness/step-agents.md` | Three complete prompt templates |
| Modify | `claude/skills/work-harness.md` | Add reference to step-agents.md |

---

## Testing Strategy

### Template Validation
- [ ] Each template follows spec 00 §1 section ordering exactly
- [ ] Each template's Task Context matches spec 00 §2 preamble
- [ ] Each template's Rules section matches spec 00 §3 skill matrix
- [ ] Each template's Completion section matches spec 00 §6 format
- [ ] Plan template instructions match current work-deep.md plan step behavior
- [ ] Spec template instructions match current work-deep.md spec step behavior
- [ ] Decompose template instructions match current work-deep.md decompose step behavior

### Behavioral Equivalence
After implementation, running a step via agent delegation should produce artifacts structurally equivalent to running it inline:
- Same files created in same locations
- Same sections in architecture.md, handoff prompts, and spec files
- Same beads issues created (decompose step)

---

## Acceptance Criteria

- [ ] `step-agents.md` exists at `claude/skills/work-harness/step-agents.md`
- [ ] Contains complete prompt templates for plan, spec, and decompose
- [ ] Each template has all 6 required sections from spec 00 §1
- [ ] Plan template produces: architecture.md, handoff prompt, updated feature summary
- [ ] Spec template produces: cross-cutting contracts, numbered specs, index, handoff prompt
- [ ] Decompose template produces: beads issues, stream docs, manifest, handoff prompt
- [ ] Variable placeholders (`{name}`, `{title}`, etc.) are clearly marked for dispatcher substitution
- [ ] `work-harness.md` references `step-agents.md`
