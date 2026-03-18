# Spec 01: Stream Docs Enhancement (C1)

**Component:** C1 | **Phase:** 1 | **Scope:** M | **Priority:** P1

## Overview

Stream execution documents are the self-contained agent prompts written during the decompose step and consumed during the implement step. Currently they contain work items, spec references, file lists, and acceptance criteria in an ad-hoc format. This spec adds structured metadata fields (`isolation`, `agent_type`, `skills`, `scope_estimate`, `file_ownership`) and documents the hybrid execution strategy so the implement step can make informed routing decisions without requiring the Skill Library (C7) or Dynamic Delegation (C8).

This is the "format and strategy" half of the parallel decomposition improvement. The "operational integration" half ships in Phase 3 as C9.

## Scope

**In scope:**
- Define the enhanced stream doc format with new structured fields
- Document the hybrid execution strategy (subagents vs agent teams vs worktrees)
- Document agent type selection guidance for each isolation mode
- Update `commands/work-deep.md` decompose step instructions to produce enhanced stream docs
- Update `commands/work-deep.md` implement step instructions to consume the new fields

**Out of scope:**
- Automated agent type selection based on metadata (C8/C9, Phase 3)
- Shared skill references in stream docs replacing inline guidance (C9, Phase 3)
- File ownership conflict enforcement at phase boundaries (C9, Phase 3)
- Changes to state.json schema (stream doc fields live in the stream docs, not state.json)

## Implementation Steps

### Step 1: Define the enhanced stream doc format

Add a YAML frontmatter block to stream execution documents. The frontmatter sits between `---` fences at the top of the file, before the existing markdown body.

**Format:**

```markdown
---
stream: A
phase: 1
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/commands/work-deep.md
  - claude/skills/code-quality/references/security-antipatterns.md
---

# Stream A: <Title>
...existing body format unchanged...
```

**Field definitions:**

| Field | Type | Required | Values | Purpose |
|-------|------|----------|--------|---------|
| `stream` | string | yes | Single uppercase letter | Stream identifier |
| `phase` | integer | yes | 1-N | Execution phase (streams in the same phase run in parallel) |
| `isolation` | enum | yes | `inline`, `subagent`, `worktree` | Execution isolation mode |
| `agent_type` | string | yes | `general-purpose`, `Explore`, `Plan`, custom name | Agent type to spawn |
| `skills` | list | yes | Skill slug strings | Skills the agent needs |
| `scope_estimate` | enum | yes | `S`, `M`, `L` | T-shirt size for scheduling decisions |
| `file_ownership` | list | yes | Project-relative file paths | Files this stream may modify |

**AC-01**: `Stream docs in .work/<name>/streams/<letter>.md contain valid YAML frontmatter with all 7 fields` -- verified by `structural-review`

**AC-02**: `No file path appears in file_ownership of more than one stream within the same phase` -- verified by `manual-test` (decompose review agent checks this)

### Step 2: Document the hybrid execution strategy

Add a reference section to the decompose step instructions in `commands/work-deep.md` that describes when to use each isolation mode.

**Isolation mode selection:**

| Mode | Use When | Tradeoffs |
|------|----------|-----------|
| `inline` | Trivial work items (config edits, single-file changes) under scope S. The lead agent executes directly without spawning. | Fastest; no coordination overhead. Blocks the lead while executing. Cannot parallelize. |
| `subagent` | Most work items. Single-session, single-concern work that fits in one agent context window. Scope S or M. | Good parallelism; low coordination cost. Agent cannot persist across sessions. Limited to one context window of work. |
| `worktree` | Multi-session work requiring git isolation. Scope L, or when the stream modifies files that conflict with other active streams across phases. | Full git isolation; survives session boundaries. High coordination cost; requires manual branch management by the user. |

**Selection heuristic (for decompose step):**

1. If scope is S and touches 1-2 files: `inline`
2. If scope is S or M and completable in one session: `subagent`
3. If scope is L, or requires git isolation from concurrent work: `worktree`
4. When in doubt, prefer `subagent` -- it is the most common and has the best effort-to-isolation ratio

**AC-03**: `The decompose step instructions in work-deep.md include the isolation mode selection table and heuristic` -- verified by `structural-review`

### Step 3: Document agent type selection guidance

Add agent type selection guidance to the decompose step, adjacent to the isolation mode reference.

**Agent type selection:**

| Agent Type | Use When | Capabilities |
|------------|----------|-------------|
| `general-purpose` | Default for implementation work. Read-write access to the codebase. | Can create, modify, and delete files. Can run tests and builds. |
| `Explore` | Read-only investigation. Tracing call chains, finding usage sites, understanding code structure. | Read-only. Cannot modify files. Lower risk, can run in parallel without file conflicts. |
| `Plan` | Architecture and design work. Reviewing specs, evaluating tradeoffs, planning approaches. | Read-only. Produces plans and recommendations, not code changes. |
| Custom name | Domain-specific expert (e.g., `database-architect`, `api-designer`). Use when the stream requires specialized knowledge framing. | Same capabilities as `general-purpose` but with a domain-expert identity that primes better reasoning for the domain. |

**Guidance for decompose step:**
- Implementation streams: `general-purpose` (or a custom domain expert name)
- Review/validation streams: `Explore` or `Plan`
- Research sub-tasks discovered during implement: `Explore`
- Match the agent type to the nature of the work, not to the step name

**AC-04**: `The decompose step instructions include the agent type selection table` -- verified by `structural-review`

### Step 4: Update decompose step instructions

Modify the decompose step in `commands/work-deep.md` to produce enhanced stream docs. Changes to existing instructions:

In section "4. Stream execution documents", update the bullet list to include the new fields:

**Current text (approximate):**
> For each stream, write a self-contained agent prompt in `.work/<name>/streams/<stream-letter>.md`:
> - Stream identity and work items (beads IDs)
> - Spec references for each work item
> - Files to create/modify
> - Acceptance criteria per work item
> - Dependency constraints (what must complete before this stream starts)

**Updated text:**
> For each stream, write a self-contained agent prompt in `.work/<name>/streams/<stream-letter>.md` with YAML frontmatter and markdown body:
>
> **Frontmatter** (between `---` fences):
> - `stream`: uppercase letter identifier
> - `phase`: execution phase number (streams in the same phase run in parallel)
> - `isolation`: execution mode -- `inline` (trivial, lead executes directly), `subagent` (single-session, default), or `worktree` (multi-session, git isolation). See isolation mode selection table below.
> - `agent_type`: `general-purpose` (default for implementation), `Explore` (read-only investigation), `Plan` (design/review), or a custom domain expert name. See agent type selection table below.
> - `skills`: list of skill slugs the agent needs (e.g., `[work-harness, code-quality]`)
> - `scope_estimate`: T-shirt size (`S`, `M`, or `L`)
> - `file_ownership`: list of every file this stream may create or modify (project-relative paths). Verify: no file appears in more than one stream within the same phase.
>
> **Body** (markdown, after frontmatter):
> - Stream identity and work items (beads IDs)
> - Spec references for each work item
> - Acceptance criteria per work item
> - Dependency constraints (what must complete before this stream starts)

Also add the isolation mode selection table (from Step 2) and agent type selection table (from Step 3) as reference sub-sections after the stream execution documents section, before the issue manifest section.

**AC-05**: `The decompose step in work-deep.md instructs agents to produce stream docs with YAML frontmatter containing all 7 fields` -- verified by `structural-review`

**AC-06**: `The decompose step includes isolation mode and agent type selection reference tables` -- verified by `structural-review`

### Step 5: Update implement step instructions

Modify the implement step in `commands/work-deep.md` to read and act on the new frontmatter fields.

In section "2. Parallel agent execution", update the instructions:

**Current text (approximate):**
> Spawn one subagent per independent stream from the streams handoff

**Updated text:**
> For each stream in the current phase, read the stream doc frontmatter and execute according to the `isolation` mode:
>
> - **`inline`**: Execute the work items directly in the lead agent context. No subagent spawn.
> - **`subagent`**: Spawn one subagent with the agent type specified in `agent_type` and skills from `skills`. Pass the stream doc as the agent prompt.
> - **`worktree`**: Inform the user that this stream requires a worktree. Provide the stream doc path and let the user manage the worktree lifecycle. Do not attempt to create or manage worktrees.
>
> Within each phase, spawn all `subagent` streams in parallel. Wait for all streams in a phase to complete before starting the next phase. Execute `inline` streams sequentially before spawning parallel `subagent` streams in the same phase.

**AC-07**: `The implement step reads isolation mode from frontmatter and routes execution accordingly` -- verified by `structural-review`

**AC-08**: `The implement step uses agent_type and skills from frontmatter when spawning subagents` -- verified by `structural-review`

### Step 6: Update Phase A decompose validation checklist

Add a validation item to the existing decompose Phase A checklist:

> - Do stream docs have valid YAML frontmatter with all required fields (stream, phase, isolation, agent_type, skills, scope_estimate, file_ownership)?
> - Does file_ownership across streams within the same phase contain no duplicates?

**AC-09**: `The decompose Phase A checklist includes frontmatter validation and file_ownership conflict detection` -- verified by `structural-review`

## Interface Contracts

### Exposes

| Interface | Consumer | Description |
|-----------|----------|-------------|
| Stream doc YAML frontmatter schema | Implement step (this command) | 7 fields read during agent routing |
| Isolation mode enum | Decompose step (author), implement step (consumer) | `inline`, `subagent`, `worktree` |
| File ownership manifest | Decompose Phase A review, future C9 enforcement | Per-stream list of owned files |

### Consumes

| Interface | Provider | Description |
|-----------|----------|-------------|
| Spec component list | Plan step (architecture.md) | Components to decompose into streams |
| Work item dependencies | Beads (`bd dep`) | DAG that determines phase assignment |
| Skill slug list | Existing skills directory | Valid slugs for the `skills` field |

## Files

| File | Action | Description |
|------|--------|-------------|
| `claude/commands/work-deep.md` | Modify | Update decompose step (stream doc format, reference tables) and implement step (routing logic) |

No new files are created. All changes are to the existing command file. The stream docs themselves are task artifacts written at decompose time, not harness source files.

## Testing Strategy

| What | Method | Pass Criteria |
|------|--------|---------------|
| Frontmatter schema | `structural-review` | All 7 fields documented with types, required status, and valid values |
| Isolation mode table | `structural-review` | Table present in decompose step with all 3 modes, use-when, and tradeoffs |
| Agent type table | `structural-review` | Table present with all 4 types and guidance |
| Decompose instructions | `structural-review` | Instructions reference frontmatter fields and validation |
| Implement routing | `structural-review` | Routing logic handles all 3 isolation modes |
| Phase A checklist | `structural-review` | Includes frontmatter validation and file ownership conflict check |
| End-to-end | `integration-test` | Run `/work-deep` through decompose on a test task; verify stream docs contain valid frontmatter |

## Deferred Questions Resolution

**No deferred questions from the plan apply directly to this spec.** The architecture's "Questions Deferred to Spec" list items Q1-Q5; none target C1 specifically.

The question of whether the `skills:` field in agent YAML frontmatter is natively supported by Claude Code (Q3) is relevant to C8, not C1. In C1, the `skills` field in stream doc frontmatter is advisory metadata consumed by the implement step instructions -- the lead agent reads it and passes skills to the spawned agent. Whether skills propagation works via agent YAML or prompt injection is a C8 concern.
