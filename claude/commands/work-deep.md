---
description: "Deep work — multi-session initiative with research, planning, specs, and phased implementation"
user_invocable: true
---

# /work-deep $ARGUMENTS

Multi-session initiative. Pre-selects Tier 3, runs assessment to confirm, then routes through 7 steps: assess -> research -> plan -> spec -> decompose -> implement -> review.

This command replaces multiple workflow commands with step-based routing.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Step 1: Detect Active Task

Follow the **task-discovery** skill (`claude/skills/work-harness/task-discovery.md`).
This command expects Tier 3. Apply tier-specific handling:
- **Matching tier (Tier 3)**: Resume at `current_step`. Jump to the Step Router.
- **Different tier**: "You have an active Tier <N> task '<name>'. Continue with it, or archive it and start a new one?"
- **No active task**: Proceed to assessment.

## Step 2: Assessment (Tier 3 pre-selected)

Apply the 3-factor depth assessment. If assessment agrees (score 4+): proceed. If disagrees: present mismatch, user decides.

## Step 3: State Initialization

1. Derive name from title (kebab-case, max 40 chars, unique)
2. Capture `base_commit`: `git rev-parse HEAD`
3. Create `.work/<name>/` directory
4. Write `state.json`:
   - `tier`: 3
   - `steps`: array of step objects: `[{"name": "assess", "status": "completed"}, {"name": "research", "status": "active"}, {"name": "plan", "status": "not_started"}, {"name": "spec", "status": "not_started"}, {"name": "decompose", "status": "not_started"}, {"name": "implement", "status": "not_started"}, {"name": "review", "status": "not_started"}]`
   - `current_step`: `research`
   - `assessment`: populated
   - `created_at`: current ISO 8601 timestamp
   - `updated_at`: same as `created_at`
   - `reviewed_at`: `null`
5. Create beads epic and initial issue:
   ```bash
   bd create --title="<title>" --type=epic --priority=1
   bd create --title="[Research] <title>" --type=task --priority=2
   bd update <research-id> --status=in_progress
   ```
6. Create directories:
   - `.work/<name>/research/`
   - `.work/<name>/plan/`
   - `.work/<name>/specs/`
   - `.work/<name>/streams/`
   - `.work/<name>/gates/`
7. Create `docs/feature/<name>.md` summary file with initial content:
   ```markdown
   # <Title>
   **Status:** active | **Tier:** 3 | **Beads:** <epic-id>
   ## What
   <2-3 sentence description — filled in during plan step>
   ```
8. Store `beads_epic_id`, `issue_id` in state.json

## Step Router

Read `current_step` from state.json and execute the matching section below.

---

## Step Routing Table

| Step | Agent Type | Skills | Context Sources |
|------|-----------|--------|-----------------|
| research | Explore | work-harness, code-quality | beads issues, managed docs |
| plan | Plan | work-harness, code-quality | research handoff prompt |
| spec | Plan | work-harness, code-quality | plan handoff prompt, architecture.md |
| decompose | Plan | work-harness, code-quality | spec handoff prompt, all spec files |
| implement | general-purpose | work-harness, code-quality | stream doc, relevant specs, managed docs |
| review | (delegates to /work-review) | code-quality | diff since base_commit |

### Skill Injection (Path B — Prompt-Based)

Claude Code agent YAML frontmatter does not natively support `skills:`. When spawning agents, include explicit skill loading instructions in the prompt. Consult the routing table above for which skills each step requires, then inject them using these fragments:

**research-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/work-harness.md` for work harness conventions (parent skill with all references).
> 2. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the research task below.

**plan-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/work-harness.md` for work harness conventions (parent skill with all references).
> 2. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the planning task below.

**implement-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/work-harness.md` for work harness conventions (parent skill with all references).
> 2. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the implementation task below.

**review-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the review task below.

---

## Inter-Step Quality Review Protocol

Every step transition runs a two-phase review before auto-advancing. Follow the **phase-review** skill (`claude/skills/work-harness/phase-review.md`) for the review framework — agent types, verdict protocol, and retry logic. Each auto-advance block below provides step-specific checklists.

After reviews complete, follow the **step-transition** skill (`claude/skills/work-harness/step-transition.md`) for the approval ceremony, gate creation, state update, and compaction prompt. Tier 3 adaptations apply: gate issues are required, gate files are required, handoff prompts are required, compaction is required.

---

## Context Compaction Protocol

Step transitions are natural compaction boundaries. The **step-transition** skill (`claude/skills/work-harness/step-transition.md`) handles the compaction prompt — for Tier 3, it tells the user to run `/compact` then `/work-deep` and then stops.

When the user runs `/work-deep` after compacting, it detects the active task, reads `current_step`, and routes to the new step with only the handoff prompt as context.

**If the user continues without compacting** (e.g., responds with "just continue"): Re-invoke this command via `Skill('work-deep')` to refresh instructions at the end of the context window. Then re-read the handoff prompt and all rule files listed in the transition substep.

---

### When current_step = "research"

Structured exploration to build understanding before planning.

**Process:**

1. **Read the task context**: Review `$ARGUMENTS`, beads issue details, and any conversation context.

2. **Read managed docs**: If `harness.yaml` has `docs.managed` entries, read the manifest. Pass all managed doc paths to research agents in a `## Managed Project Docs` section. If `docs.managed` is absent, run auto-detection (see `claude/skills/work-harness/context-docs.md`) and suggest doc types to the user.

3. **Plan research topics**: Identify the key areas to investigate. For each topic, assign:
   - A target file path: `.work/<name>/research/NN-<topic-slug>.md`
   - An index entry for `research/index.md`

4. **Spawn Explore agents with structured prompts**: Launch one Explore agent per research topic. Each agent receives a prompt containing all five required fields:

   **Research Agent Prompt Template:**
   ```
   ## Task Context
   <2-3 sentence summary of the initiative, current goals, and what has been explored so far>

   ## Topic Scope
   <Specific area to investigate, bounded by what questions to answer>

   ## Target File Path
   Write your research note to: `.work/<name>/research/NN-<topic-slug>.md`

   ## Index Entry Format
   Append this row to `.work/<name>/research/index.md`:
   | <topic> | <one-line summary> | <explored|dead-end|future> | `NN-<topic-slug>.md` |

   ## Note Format
   Use this structure for your research note:

   # <Topic Title>

   ## Questions
   - <What this research set out to answer>

   ## Findings
   <Structured findings with evidence — code references, file paths, doc citations>

   ## Implications
   - <How findings affect architecture or implementation decisions>

   ## Open Questions
   - <Unresolved items that need further investigation or planning input>
   ```

   **Agent delegation**: Consult the **Step Routing Table** for `research`:
   - **Agent type**: Explore (read-only)
   - **Skills**: Inject per the `research-agent-skills` fragment above
   - **Context**: Provide beads issue details and managed docs (if configured)

   **Agent file-writing responsibilities**: Each Explore agent:
   - Writes its research note to the target file path provided in the prompt
   - Appends its index entry to `.work/<name>/research/index.md`
   - If the agent discovers a dead end, appends to `.work/<name>/research/dead-ends.md` (same format as `/work-redirect`) instead of or in addition to writing a note
   - If the agent discovers a future enhancement, appends to `.work/<name>/futures.md`

   **Agents write files directly. The lead does NOT transcribe agent findings.** If an agent fails to write its file (e.g., crashes, times out), re-spawn it with the same prompt.

5. **Verify coverage and re-spawn if needed**: After agents complete, the lead:
   1. **Verify coverage**: Check that all planned topics have notes in `research/` and entries in `index.md`
   2. **Identify gaps**: If any topic was missed or a note is incomplete, re-spawn the agent
   3. **Synthesize handoff prompt**: Write `.work/<name>/research/handoff-prompt.md` by reading the agent-written notes and producing:
      - Cross-references between topics (connections agents could not see individually)
      - Dependency relationships discovered across notes
      - Consolidated open questions (deduplicated, prioritized)
      - Research coverage summary (what was investigated, what was skipped and why)
   4. The lead does NOT copy findings into the handoff — it **references note file paths** instead of duplicating content

6. **Dead ends and futures**: Dead-end documentation and futures capture are agent responsibilities (see step 4). The lead verifies these files exist and are complete during coverage verification. Do NOT re-investigate documented dead ends.

7. **Auto-advance** (see Inter-Step Quality Review Protocol):
   a. Write the handoff prompt to `.work/<name>/research/handoff-prompt.md`
   b. **Phase A — Artifact validation** (see `phase-review` skill) — spawn Explore agent (read-only). Checklist:
      - Are findings indexed in research/index.md?
      - Do all planned topics have corresponding research notes?
      - Are dead ends documented?
      - Are futures captured in `.work/<name>/futures.md`?
      - Are open questions for planning identified?
   c. **Phase B — Quality review** (see `phase-review` skill) — spawn Plan agent (read-only). Inject skills per the **Step Routing Table** `review-agent-skills` fragment. Checklist:
      - Do findings cover the full task scope (no major areas uninvestigated)?
      - Are findings evidence-based (references to code, docs, or prior art)?
      - Are findings consistent with `.claude/rules/architecture-decisions.md`?
      - Are open questions specific enough to drive planning decisions?
      - Does the handoff prompt reference note file paths rather than copying content?
   d. Apply verdict per the `phase-review` skill verdict protocol.
   e. **Write gate file**: Write `.work/<name>/gates/research-to-plan.md` following the gate protocol SOP (`claude/skills/work-harness/references/gate-protocol.md`). Populate all sections from review results.
   f. **Follow the `step-transition` skill** (`claude/skills/work-harness/step-transition.md`): Present gate file path and transition summary. STOP and wait for explicit approval. On approval: create gate issue, write state.json in a single atomic update (mark research `completed` with `gate_id` and `gate_file: "gates/research-to-plan.md"`, set plan to `active`, update `current_step` and `updated_at`). Apply context compaction — tell user to run `/compact` then `/work-deep`, then stop. If user continues without compacting, re-invoke via `Skill('work-deep')`, then re-read `.claude/rules/code-quality.md`, `.claude/rules/architecture-decisions.md`, and the handoff prompt.

---

### When current_step = "plan"

Synthesize research into an architecture document.

**Process:**

1. **Read research handoff**: Read `.work/<name>/research/handoff-prompt.md` — this is the primary input. Do NOT re-read individual research notes (the handoff is the firewall).

2. **Read managed docs**: If `harness.yaml` has `docs.managed` entries, read the manifest and pass all managed doc paths to any plan subagents in a `## Managed Project Docs` section.

3. **Write architecture document**: Create `.work/<name>/specs/architecture.md`:
   - Problem statement and goals
   - Component map with scope estimates
   - Data flow diagrams (text-based)
   - Technology choices with rationale
   - Open questions resolved from research
   - New questions deferred to spec

4. **Update summary**: Update `docs/feature/<name>.md` — fill in the What section and add a Components list from the architecture.

5. **Handoff prompt**: Generate `.work/<name>/plan/handoff-prompt.md`:
   - What this step produced
   - Architecture document location
   - Component list for spec writing
   - Instructions for spec step

6. **Futures**: If planning reveals deferred enhancements, append to `.work/<name>/futures.md`.

7. **Auto-advance** (see Inter-Step Quality Review Protocol):
   a. Write the handoff prompt to `.work/<name>/plan/handoff-prompt.md`
   b. **Phase A — Artifact validation** (see `phase-review` skill) — spawn Explore agent (read-only). Checklist:
      - Does the architecture cover all goals from the research handoff?
      - Are component boundaries clear (no overlapping responsibilities)?
      - Are technology choices justified?
      - Is the dependency order between components correct?
      - Are scope exclusions explicit?
   c. **Phase B — Quality review** (see `phase-review` skill) — spawn Plan agent (read-only). Inject skills per the **Step Routing Table** `review-agent-skills` fragment. Checklist:
      - Do technology choices align with decision rules in `.claude/rules/architecture-decisions.md`?
      - Does component layering follow the project's established architecture?
      - Are all services using constructor injection?
      - Do failure modes fail closed (no silent fallbacks)?
   d. Apply verdict per the `phase-review` skill verdict protocol.
   e. **Write gate file**: Write `.work/<name>/gates/plan-to-spec.md` following the gate protocol SOP (`claude/skills/work-harness/references/gate-protocol.md`). Populate all sections from review results.
   f. **Follow the `step-transition` skill** (`claude/skills/work-harness/step-transition.md`): Present gate file path and transition summary. STOP and wait for explicit approval. On approval: create gate issue, write state.json in a single atomic update (mark plan `completed` with `gate_id` and `gate_file: "gates/plan-to-spec.md"`, set spec to `active`, update `current_step` and `updated_at`). Apply context compaction — tell user to run `/compact` then `/work-deep`, then stop. If user continues without compacting, re-invoke via `Skill('work-deep')`, then re-read `.claude/rules/code-quality.md`, `.claude/rules/architecture-decisions.md`, and the handoff prompt.

---

### When current_step = "spec"

Write detailed implementation specifications per component.

**Process:**

1. **Read plan handoff**: Read `.work/<name>/plan/handoff-prompt.md`.

2. **Cross-cutting contracts**: Write `.work/<name>/specs/00-cross-cutting-contracts.md` — shared schemas, interfaces, naming conventions consumed by all specs.

3. **Numbered specs**: For each component from the architecture's component map, write `.work/<name>/specs/NN-<slug>.md`:
   - Overview and scope
   - Implementation steps with acceptance criteria
   - Interface contracts (exposes/consumes)
   - Files to create/modify
   - Testing strategy

4. **Spec index**: Track in `.work/<name>/specs/index.md`:
   ```markdown
   | Spec | Title | Status | Dependencies |
   |------|-------|--------|-------------|
   | 00 | Cross-cutting contracts | complete | — |
   | 01 | <slug> | complete | 00 |
   ```

5. **Dependency ordering**: Establish which specs can be written in parallel vs sequentially.

6. **Update summary**: Update `docs/feature/<name>.md` — add a Key Decisions section from the specs.

7. **Futures**: If spec writing reveals deferred enhancements, append to `.work/<name>/futures.md`.

8. **Auto-advance** (see Inter-Step Quality Review Protocol):
   a. Write the handoff prompt to `.work/<name>/specs/handoff-prompt.md`
   b. **Phase A — Artifact validation** (see `phase-review` skill) — spawn Explore agent (read-only). Checklist:
      - Do all specs reference the cross-cutting contracts (spec 00)?
      - Are path conventions consistent across all specs?
      - Are all state.json fields used in specs declared in spec 00?
      - Do code examples match the described behavior?
      - Are testing strategies concrete?
      - Are edge cases for each rule documented?
   c. **Phase B — Quality review** (see `phase-review` skill) — spawn Plan agent (read-only). Inject skills per the **Step Routing Table** `review-agent-skills` fragment. Checklist:
      - Are acceptance criteria testable and unambiguous?
      - Are interface contracts consistent across specs (no divergent copies)?
      - Do specs account for error paths and fail-closed behavior?
      - Are implementation steps ordered correctly (dependencies before dependents)?
      - Do specs avoid over-engineering (no premature abstractions)?
   d. Apply verdict per the `phase-review` skill verdict protocol.
   e. **Write gate file**: Write `.work/<name>/gates/spec-to-decompose.md` following the gate protocol SOP (`claude/skills/work-harness/references/gate-protocol.md`). Populate all sections from review results.
   f. **Follow the `step-transition` skill** (`claude/skills/work-harness/step-transition.md`): Present gate file path and transition summary. STOP and wait for explicit approval. On approval: create gate issue, write state.json in a single atomic update (mark spec `completed` with `gate_id` and `gate_file: "gates/spec-to-decompose.md"`, set decompose to `active`, update `current_step` and `updated_at`). Apply context compaction — tell user to run `/compact` then `/work-deep`, then stop. If user continues without compacting, re-invoke via `Skill('work-deep')`, then re-read `.claude/rules/code-quality.md`, `.claude/rules/beads-workflow.md`, and the handoff prompt.

---

### When current_step = "decompose"

Break specs into executable work items with a concurrency map.

**Scope expansion check:** If the user requests changes that would add new components or specs beyond what was planned, acknowledge the regression: "This adds new scope. We're currently in decompose but this requires plan/spec work." Present options: (a) roll back to plan/spec, (b) add as lightweight amendment. Document the scope change in the handoff prompt.

**Process:**

1. **Read spec handoff**: Read `.work/<name>/specs/handoff-prompt.md`.

2. **Create beads issues**: For each work item from specs:
   ```bash
   bd create --title="[<tag>] W-NN: <title> — spec NN" --type=task --priority=2
   ```
   Title must reference the spec it implements (e.g., `W-01: state-guard.sh — spec 01`). This naming convention is verified by step output review agents.
   Set dependencies between issues to match spec dependency ordering.

3. **Concurrency map**: Identify which streams can run in parallel:
   - Group work items into streams (one per independent workstream)
   - Streams are designed as **parallel agent workloads** — each stream becomes a self-contained agent prompt
   - Identify phase ordering (which streams must complete before others)
   - Document the DAG and critical path
   - Verify: no file appears in more than one stream within the same phase

4. **Stream execution documents**: For each stream, write a self-contained agent prompt in `.work/<name>/streams/<stream-letter>.md` with YAML frontmatter and markdown body:

   **Frontmatter** (between `---` fences):
   - `stream`: uppercase letter identifier
   - `phase`: execution phase number (streams in the same phase run in parallel)
   - `isolation`: execution mode — `inline` (trivial, lead executes directly), `subagent` (single-session, default), or `worktree` (multi-session, git isolation). See isolation mode selection table below.
   - `agent_type`: `general-purpose` (default for implementation), `Explore` (read-only investigation), `Plan` (design/review), or a custom domain expert name. See agent type selection table below.
   - `skills`: list of skill slugs the agent needs (e.g., `[work-harness, code-quality]`)
   - `scope_estimate`: T-shirt size (`S`, `M`, or `L`)
   - `file_ownership`: list of every file this stream may create or modify (project-relative paths). Verify: no file appears in more than one stream within the same phase.

   **Body** (markdown, after frontmatter):
   - Stream identity and work items (beads IDs)
   - Spec references for each work item
   - Acceptance criteria per work item (reference spec ACs by ID, do not duplicate full text)
   - Dependency constraints (what must complete before this stream starts)
   - Do NOT inline skill content — reference skills by slug only. Agents receive skill content via the Skill Injection mechanism at spawn time.

   #### Isolation Mode Selection

   | Mode | Use When | Tradeoffs |
   |------|----------|-----------|
   | `inline` | Trivial work items (config edits, single-file changes) under scope S. The lead agent executes directly without spawning. | Fastest; no coordination overhead. Blocks the lead while executing. Cannot parallelize. |
   | `subagent` | Most work items. Single-session, single-concern work that fits in one agent context window. Scope S or M. | Good parallelism; low coordination cost. Agent cannot persist across sessions. Limited to one context window of work. |
   | `worktree` | Multi-session work requiring git isolation. Scope L, or when the stream modifies files that conflict with other active streams across phases. | Full git isolation; survives session boundaries. High coordination cost; requires manual branch management by the user. |

   **Selection heuristic:**
   1. If scope is S and touches 1-2 files: `inline`
   2. If scope is S or M and completable in one session: `subagent`
   3. If scope is L, or requires git isolation from concurrent work: `worktree`
   4. When in doubt, prefer `subagent` — it is the most common and has the best effort-to-isolation ratio

   #### Agent Type Selection

   | Agent Type | Use When | Capabilities |
   |------------|----------|-------------|
   | `general-purpose` | Default for implementation work. Read-write access to the codebase. | Can create, modify, and delete files. Can run tests and builds. |
   | `Explore` | Read-only investigation. Tracing call chains, finding usage sites, understanding code structure. | Read-only. Cannot modify files. Lower risk, can run in parallel without file conflicts. |
   | `Plan` | Architecture and design work. Reviewing specs, evaluating tradeoffs, planning approaches. | Read-only. Produces plans and recommendations, not code changes. |
   | Custom name | Domain-specific expert (e.g., `database-architect`, `api-designer`). Use when the stream requires specialized knowledge framing. | Same capabilities as `general-purpose` but with a domain-expert identity that primes better reasoning for the domain. |

   **Guidance:**
   - Implementation streams: `general-purpose` (or a custom domain expert name)
   - Review/validation streams: `Explore` or `Plan`
   - Research sub-tasks discovered during implement: `Explore`
   - Match the agent type to the nature of the work, not to the step name

5. **Issue manifest**: Create `.work/<name>/streams/manifest.jsonl` mapping work items to stream metadata. Each line is a JSON object with these fields:
   ```json
   {
     "work_item": "W-01",
     "title": "...",
     "spec": "01",
     "beads_id": "abc123",
     "stream": "a",
     "phase": 1,
     "isolation": "subagent",
     "agent_type": "general-purpose",
     "skills": ["code-quality", "work-harness"],
     "scope_estimate": "S",
     "file_ownership": ["path/to/file.go"]
   }
   ```
   All metadata fields mirror the stream doc YAML frontmatter. This enables cross-referencing and scheduling without re-parsing stream docs.

6. **Futures**: If you discover deferred enhancements during decompose, append to `.work/<name>/futures.md`.

7. **Auto-advance** (see Inter-Step Quality Review Protocol):
   a. Write the handoff prompt to `.work/<name>/streams/handoff-prompt.md`
   b. **Phase A — Artifact validation** (see `phase-review` skill) — spawn Explore agent (read-only). Checklist:
      - Does every spec component map to at least one work item? (Title must reference spec: `W-NN: ... — spec NN`)
      - Are beads issue dependencies consistent with spec dependency ordering?
      - Can claimed "parallel" streams actually run in parallel (no hidden deps)?
      - Do stream execution docs have acceptance criteria?
      - Is the concurrency map consistent with the dependency graph?
      - Do stream docs have valid YAML frontmatter with all required fields (`stream`, `phase`, `isolation`, `agent_type`, `skills`, `scope_estimate`, `file_ownership`)?
      - Do stream doc `skills:` lists reference only slugs that exist in `claude/skills/`?
      - Does `file_ownership` across streams within the same phase contain no duplicates?
      - Is every file in the codebase claimed by at most one stream per phase? Cross-check all stream docs' `file_ownership` lists within each phase. Report any file that appears in multiple streams within the same phase as a conflict.
   c. **Phase B — Quality review** (see `phase-review` skill) — spawn Plan agent (read-only). Inject skills per the **Step Routing Table** `review-agent-skills` fragment. Checklist:
      - Are work items at the right granularity (each completable in one agent session)?
      - Do stream boundaries align with code module boundaries (no file conflicts)?
      - Is phase ordering correct (foundational work before dependent work)?
      - Are parallel streams truly independent (no shared mutable state)?
      - Do file ownership boundaries align with module boundaries? (A stream should not own scattered files across unrelated packages — it should own a cohesive set.)
   d. Apply verdict per the `phase-review` skill verdict protocol.
   e. **Write gate file**: Write `.work/<name>/gates/decompose-to-implement.md` following the gate protocol SOP (`claude/skills/work-harness/references/gate-protocol.md`). Populate all sections from review results.
   f. **Follow the `step-transition` skill** (`claude/skills/work-harness/step-transition.md`): Present gate file path and transition summary. STOP and wait for explicit approval. On approval: create gate issue, write state.json in a single atomic update (mark decompose `completed` with `gate_id` and `gate_file: "gates/decompose-to-implement.md"`, set implement to `active`, update `current_step` and `updated_at`). Apply context compaction — tell user to run `/compact` then `/work-deep`, then stop. If user continues without compacting, re-invoke via `Skill('work-deep')`, then re-read `.claude/rules/code-quality.md`, `.claude/rules/beads-workflow.md`, `.claude/rules/architecture-decisions.md`, and the handoff prompt.

---

### When current_step = "implement"

Execute the implementation plan from decompose.

**Scope expansion check:** If the user requests changes that would add new work items not mapped to existing specs, or architecture changes, acknowledge the regression. Present options: (a) roll back to plan/spec/decompose, (b) add as amendment. Document in the step's handoff prompt.

**Process:**

1. **Read decompose handoff**: Read `.work/<name>/streams/handoff-prompt.md`.

2. **Read managed docs**: If `harness.yaml` has `docs.managed` entries, read the manifest. Pass managed doc paths to implementation agents in a `## Managed Project Docs` section. Pass all paths when relevance to the stream's file scope cannot be determined; otherwise pass only relevant paths.

3. **Parallel agent execution**: For each stream in the current phase, read the stream doc YAML frontmatter to determine execution parameters. Consult the **Step Routing Table** for the `implement` step defaults; stream doc frontmatter overrides these defaults when present.

   a. **Agent type selection** (from stream doc `agent_type` field):
      - `general-purpose`: Spawn with full read/write access (default for implementation)
      - `Explore`: Spawn read-only (for research/validation streams)
      - `Plan`: Spawn in plan mode (for design/decomposition streams)

   b. **Skill propagation**: Include all slugs from the stream doc `skills:` field. Inject skills using the `implement-agent-skills` fragment from the Skill Injection section, replacing skill file paths as needed to match the stream's skill list.

   c. **Isolation mode** (from stream doc `isolation` field):
      - `inline`: Execute the work items directly in the lead agent context. No subagent spawn.
      - `subagent`: Spawn one subagent with the agent type and skills determined above. Pass the stream doc as the agent prompt.
      - `worktree`: Notify user that worktree isolation is recommended for this stream. Provide the stream doc path and let the user manage the worktree lifecycle. Do not attempt to create or manage worktrees.

   d. Within each phase, execute `inline` streams sequentially first, then spawn all `subagent` streams in parallel. Wait for all streams in a phase to complete before starting the next phase.

   e. Each subagent receives: its stream execution doc + relevant specs
   f. Subagents claim work with `bd update <id> --status=in_progress` and close with `bd close <id>`
   g. Lead agent monitors completion and launches next-phase agents when dependencies clear

4. **Phase gating** (enforced — see Inter-Step Quality Review Protocol and `phase-review` skill): After each implementation phase completes:
   - **File ownership validation**: Before running reviews, verify no file appears in more than one stream's `file_ownership` list within the completed phase. If conflicts exist, report them as BLOCKING and list the conflicting files and streams.
   - **Phase A — Artifact validation** (see `phase-review` skill): Spawn Explore agent (read-only) to check implementations match spec file lists and acceptance criteria. Additionally verify:
     - Each stream's modifications are within its declared `file_ownership` list
     - No undeclared files were created or modified by a stream agent
   - **Phase B — Quality review** (see `phase-review` skill): Select review agent using this precedence:
     1. If `review_routing` is configured in `harness.yaml`: match changed file patterns against routing table to select agents
     2. If stream docs specify an `agent_type` override for review: use that
     3. Otherwise: use the `work-review` agent
   - Inject skills from the union of all completed streams' `skills:` lists, using the **Step Routing Table** `review-agent-skills` fragment as the base. Checklist:
     - Does the implementation comply with the relevant spec's acceptance criteria?
     - Are code-quality anti-patterns absent (error swallowing, fabricated data, fail-open)?
     - Do new tests cover the acceptance criteria?
     - Are constructor injection and error wrapping patterns followed?
   - Write results to `.work/<name>/implement/phase-N-validation.jsonl`
   - Apply verdict per the `phase-review` skill verdict protocol.
   - **Write gate file**: Write `.work/<name>/gates/implement-phase-<N>.md` following the gate protocol SOP (`claude/skills/work-harness/references/gate-protocol.md`). Populate all sections from phase validation results.
   - **Follow the `step-transition` skill** for approval ceremony: Present gate file path and review results. End with: "Ready to proceed to Phase N+1? (yes/no)". Do NOT start Phase N+1 in the same turn as presenting Phase N results. On approval, record `gate_file: "gates/implement-phase-<N>.md"` in step status.
   - Only proceed to Phase N+1 when user gives explicit approval and Phase N validation is PASS or ADVISORY

5. **Checkpoints**: Use `/work-checkpoint` at session boundaries. Multi-session implementation is normal for Tier 3.

6. **Verification**: Run the project's test and build commands after each phase or logical unit.

7. **Futures**: If you discover deferred enhancements during implement, append to `.work/<name>/futures.md`.

8. **Scope expansion check**: If the user requests changes that would add new components, specs, or work items beyond what was planned, acknowledge the regression.

9. **Auto-advance** (when all work items closed — see Inter-Step Quality Review Protocol):
   a. **Phase B — Quality pre-screen** (see `phase-review` skill): Spawn review agent (read-only). Inject skills per the **Step Routing Table** `review-agent-skills` fragment. Review full diff (`git diff <base_commit>...HEAD`). Checklist:
      - Are there obvious code-quality anti-patterns in the diff?
      - Do all new functions have error handling?
      - Are there any swallowed errors or fabricated defaults?
      - Do tests exist for new functionality?
   b. Apply verdict per the `phase-review` skill verdict protocol.
   c. **Write gate file**: Write `.work/<name>/gates/implement-to-review.md` following the gate protocol SOP (`claude/skills/work-harness/references/gate-protocol.md`). Populate all sections from review results.
   d. **Follow the `step-transition` skill** (`claude/skills/work-harness/step-transition.md`): Present gate file path and transition summary. STOP and wait for explicit approval. On approval: create gate issue, write state.json in a single atomic update (mark implement `completed` with `gate_id` and `gate_file: "gates/implement-to-review.md"`, set review to `active`, update `current_step` and `updated_at`). Apply context compaction — tell user to run `/compact` then `/work-deep`, then stop. If user continues without compacting, re-invoke via `Skill('work-deep')`, then re-read `.claude/rules/code-quality.md` and the latest checkpoint if it exists.

---

### When current_step = "review"

Mandatory full review before archive.

**Process:**

1. **Run `/work-review`**: This is mandatory for Tier 3. The review command spawns specialist agents, collects findings, and writes to `.work/<name>/review/findings.jsonl`.

2. **Address findings**: All critical findings must be fixed. Important findings must be fixed or have beads issues created for deferred resolution.

3. **Re-review**: After fixes, re-run `/work-review` to reconcile.

4. **On clean review** (no critical OPEN findings): Mark `review` as `completed`.

5. **Futures**: If review reveals deferred enhancements or architectural improvements, append to `.work/<name>/futures.md`.

6. **Archive**: Task remains active until `/work-archive`. The archive gate requires all critical AND important findings to be FIXED or have `beads_issue_id`.

## Escalation Handling

Already Tier 3, so escalation is rare. If needed, the user can manually adjust state.json.

## Skill Propagation

Agent skills are determined by the **Step Routing Table** above. Each step
specifies the exact skills to propagate. The routing table is the single
source of truth for agent configuration — do not hardcode skill lists
in step instructions.

For the skill injection mechanism, see the **Skill Injection (Path B — Prompt-Based)**
section above. Skills are injected via explicit `Read` instructions in agent prompts
because Claude Code agent frontmatter does not support `skills:` natively.

## Session Boundaries

Tier 3 tasks span many sessions. Key patterns:
- **Starting a session**: Run `/work-deep` — it detects the active task and resumes at `current_step`
- **Ending a session**: Run `/work-checkpoint` to save progress
- **Step transitions**: Run `/compact` then `/work-deep` to start the next step with clean context (see Context Compaction Protocol)
- **After compaction**: Run `/work-reground` to recover context
- **Dead ends**: Run `/work-redirect` to document failed approaches
- **Self-driven reviews, gated transitions**: The Inter-Step Quality Review Protocol runs Phase A + Phase B automatically at each transition. The harness handles all bookkeeping (handoff prompts, gate issues, state updates). But every step transition waits for user acknowledgment — reviews are self-driven, advancement is not.
