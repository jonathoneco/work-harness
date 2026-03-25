---
description: "Deep work — multi-session initiative with research, planning, specs, and phased implementation"
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
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
| research | Explore | code-quality, work-harness | beads issues, managed docs |
| plan | general-purpose | code-quality | research handoff prompt |
| spec | general-purpose | code-quality | plan handoff prompt, architecture.md |
| decompose | general-purpose | code-quality, work-harness | spec handoff prompt, all spec files |
| implement | general-purpose | code-quality, work-harness | stream doc, relevant specs, managed docs |
| review | (delegates to /work-review) | code-quality | diff since base_commit |

### Skill Injection (Path B — Prompt-Based)

Claude Code agent YAML frontmatter does not natively support `skills:`. When spawning agents, include explicit skill loading instructions in the prompt. Consult the routing table above for which skills each step requires, then inject them using these fragments:

> **Note**: Dispatched steps (plan, spec, decompose) receive skills via templates in `step-agents.md`. Non-dispatched steps (research, implement, review) use the fragments below.

**research-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/work-harness.md` for work harness conventions (parent skill with all references).
> 2. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the research task below.

**plan-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the planning task below.

**spec-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the spec task below.

**decompose-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/code-quality.md` for quality standards.
> 2. Read `claude/skills/work-harness.md` for work harness conventions (parent skill with all references).
> Then proceed with the decompose task below.

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

Every step transition runs a two-phase review before advancing. Follow the **phase-review** skill (`claude/skills/work-harness/phase-review.md`) for the review framework — agent types, verdict protocol, and retry logic. Each auto-advance block below provides step-specific checklists.

After reviews complete, follow the **step-transition** protocol (`claude/skills/work-harness/step-transition.md`) for risk-based ceremony routing, gate creation, state update, and compaction prompt. The step-transition protocol's **Risk Classification** table determines whether each transition is a hard stop or auto-advance:
- **Research → plan, plan → spec**: high risk — hard stop approval ceremony
- **Spec → decompose, decompose → implement**: medium risk — hard stop approval ceremony
- **Implement phase N → N+1, implement → review**: low risk — auto-advance with notification (no user input)

Tier 3 adaptations apply: gate issues are required, gate files are required, handoff prompts are required, compaction is required.

---

## Context Compaction Protocol

Step transitions are natural compaction boundaries. The **step-transition** protocol (`claude/skills/work-harness/step-transition.md`) handles the compaction prompt — for Tier 3, it tells the user to run `/compact` then `/work-deep` and then stops.

When the user runs `/work-deep` after compacting, it detects the active task, reads `current_step`, and routes to the new step with only the handoff prompt as context.

**If the user continues without compacting** (e.g., responds with "just continue"): Re-invoke this command via `Skill('work-deep')` to refresh instructions at the end of the context window. Then re-read the handoff prompt and all rule files listed in the transition substep.

---

### When current_step = "research"

Structured exploration to build understanding before planning.

**Process:**

1. **Scope Validation** *(optional — not a gate)*: Before dispatching research agents, review the task description and assessment. If the research scope is ambiguous, unclear, or potentially misaligned with the user's intent, present a clarity questionnaire:

   ```
   ## Scope Clarification Needed

   Before proceeding, I need to understand:

   1. **[Topic]**: [Specific question about scope, intent, or constraint]
   2. **[Topic]**: [Specific question]
   ...

   Please answer these so I can research the right topics.
   ```

   **Rules**:
   - Maximum 5 questions per questionnaire
   - Each question must be about scope, intent, constraints, or priorities — not implementation details
   - If no clarification is needed, proceed directly — do not force a questionnaire
   - Incorporate user responses into the research scope: restate the refined scope before dispatching research agents
   - Capture refined scope in the research handoff prompt as a "Scope Refinements" section (only if clarification occurred)

   **Pushback escalation**: If user responses reveal the task needs fundamental re-scoping (e.g., "actually this is two separate features"), present re-scoping choices inline:
   - **Proceed**: Continue with the refined scope as stated
   - **Split**: Break into multiple tasks (create new beads issues, archive or narrow current task)
   - **Escalate tier**: If scope expansion warrants T3 treatment and the task is not already T3, use the existing escalation protocol

   Re-scoping is handled inline — no new state or step is created.

2. **Read the task context**: Review `$ARGUMENTS`, beads issue details, and any conversation context.

3. **Read managed docs**: If `harness.yaml` has `docs.managed` entries, read the manifest. If `docs.managed` is absent, run auto-detection (see `claude/skills/work-harness/context-docs.md`) and suggest doc types to the user.

4. **Plan research topics**: Identify the key areas to investigate. For each topic, assign:
   - A topic number and slug: `NN-<topic-slug>`
   - A target file path: `.work/<name>/research/NN-<topic-slug>.md`

5. **Create research team**: Follow the teams protocol (`claude/skills/work-harness/teams-protocol.md`):
   a. Create team: `TeamCreate("{step}-{name}")`
   b. Create shared tasks (one per topic) using the task schema from the teams protocol. Each task description includes:
      - Topic scope and specific questions to answer
      - Target output file path
      - Expected note format (Questions → Findings → Implications → Open Questions)
      - Managed doc paths (if configured)
   c. Teammates auto-spawn, self-claim topics from the shared task list, and write research notes
   d. **Teammate prompt**: Each teammate receives the prompt template from the teams protocol, with variables filled from state.json. Teammates receive skill injection (code-quality + work-harness) via Read instructions in the Rules section, per the Step Routing Table.

6. **Monitor and verify**: The lead monitors the shared task list for completion:
   a. When all tasks complete: read each research note, verify content quality
   b. If any topic is missing or incomplete: reassign via the task list or investigate inline
   c. Tear down team: `TeamDelete("{step}-{name}")`

7. **Synthesize**: The lead (NOT teammates) generates:
   - `.work/<name>/research/index.md` — topic index with status
   - `.work/<name>/research/handoff-prompt.md` — cross-references, consolidated open questions, research coverage summary
   The lead references note file paths in the handoff — does NOT copy findings inline.

8. **Dead ends and futures**: If any topic is a dead end, document in `.work/<name>/research/dead-ends.md`. If deferred enhancements discovered, append to `.work/<name>/futures.md`.

9. **Auto-advance** (see Inter-Step Quality Review Protocol):
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
      - Are findings consistent with `.claude/rules/architecture-decisions.md` (if it exists)?
      - Are open questions specific enough to drive planning decisions?
      - Does the handoff prompt reference note file paths rather than copying content?
   d. Apply verdict per the `phase-review` skill verdict protocol.
   e. **Write gate file**: Write `.work/<name>/gates/research-to-plan.md` following the gate protocol SOP (`claude/skills/work-harness/references/gate-protocol.md`). Populate all sections from review results.
   f. **Follow the step-transition protocol** (`claude/skills/work-harness/step-transition.md`): Present gate file path and transition summary. STOP and wait for explicit approval. On approval: create gate issue, write state.json in a single atomic update (mark research `completed` with `gate_id` and `gate_file: "gates/research-to-plan.md"`, set plan to `active`, update `current_step` and `updated_at`). Apply context compaction — tell user to run `/compact` then `/work-deep`, then stop. If user continues without compacting, re-invoke via `Skill('work-deep')`, then re-read `.claude/rules/code-quality.md`, `.claude/rules/architecture-decisions.md` (if it exists), and the handoff prompt.

---

### When current_step = "plan"

Synthesize research into an architecture document.

#### Research Handoff Validation *(optional — not a gate)*

Before dispatching the plan agent, review the research handoff prompt (`.work/<name>/research/handoff-prompt.md`). If key topics are missing or research conclusions are unclear, present a clarity questionnaire to the user:

```
## Scope Clarification Needed

Before proceeding, I need to understand:

1. **[Topic]**: [Specific question about research gaps or unclear conclusions]
2. **[Topic]**: [Specific question]
...

Please answer these so I can plan the right approach.
```

**Rules**:
- Maximum 5 questions per questionnaire
- Questions must be about scope, intent, constraints, or priorities — not implementation details
- If no clarification is needed, proceed directly to plan agent dispatch
- Pass user responses to the plan agent as supplementary context in its prompt

**Important distinction**: Clarity questions go to the *user* — they address gaps in understanding that require human judgment. This is separate from the plan agent's inline research capability (which sends targeted questions to *Explore subagents* for codebase-level fact gathering). The ordering is: (1) clarity questionnaire (user-facing, optional), then (2) plan agent dispatch with inline research capability (agent-internal).

A gap requiring user judgment (business decision, priority call, scope question) should always surface as a clarity question or ASK verdict — never as an inline research subagent query.

### Dispatch: Plan Agent

1. **Construct prompt**: Read `claude/skills/work-harness/step-agents.md` for the plan agent template.
   Fill variables from state.json:
   - `{name}` ← state.name
   - `{title}` ← state.title
   - `{tier}` ← state.tier
   - `{current_step}` ← state.current_step
   - `{base_commit}` ← state.base_commit
   - `{beads_epic_id}` ← state.beads_epic_id

2. **Spawn agent**: The plan agent may spawn up to 3 Explore subagents internally for gap-filling (see Inline Research in the plan agent template). No additional dispatcher logic is needed — the plan agent handles subagent spawning per the constraints in `step-agents.md`.
   ```
   Agent(
     description: "plan {name-abbreviated}",
     prompt: {constructed prompt},
     mode: "default",
     subagent_type: "general-purpose"
   )
   ```

3. **Read return**: Parse the agent's completion signal (see completion format in `claude/skills/work-harness/step-agents.md`).

4. **Verify artifacts**: Check that expected artifacts exist:
   - `.work/<name>/specs/architecture.md`
   - `.work/<name>/plan/handoff-prompt.md`
   - `docs/feature/<name>.md`
   If artifacts missing: re-spawn the agent (preserve existing partial artifacts per spec 00 §7).

5. **Present to user**: Show the agent's summary. Include:
   - What the agent produced (artifact list with paths)
   - Key decisions or notable items
   - Any inline research performed (gaps filled via Explore subagents)
   - Ask: "Review the artifacts, or proceed to validation?"

6. **Handle user feedback**:
   - If user approves or says "proceed": continue to auto-advance.
   - If user has feedback: construct re-spawn prompt with a "Previous Attempt" section listing artifacts written and user feedback verbatim, inserted between Rules and Instructions. Re-spawn the agent. Return to step 3.
   - After 2 re-spawns with unresolved feedback, ask the user how to proceed.

7. **Auto-advance** (see Inter-Step Quality Review Protocol):
   a. Write the handoff prompt to `.work/<name>/plan/handoff-prompt.md`
   b. **Phase A — Artifact validation** (see `phase-review` skill) — spawn Explore agent (read-only). Checklist:
      - Does the architecture cover all goals from the research handoff?
      - Are component boundaries clear (no overlapping responsibilities)?
      - Are technology choices justified?
      - Is the dependency order between components correct?
      - Are scope exclusions explicit?
   c. **Phase B — Quality review** (see `phase-review` skill) — spawn Plan agent (read-only). Inject skills per the **Step Routing Table** `review-agent-skills` fragment. Checklist:
      - Do technology choices align with decision rules in `.claude/rules/architecture-decisions.md` (if it exists)?
      - Does component layering follow the project's established architecture?
      - Are all services using constructor injection?
      - Do failure modes fail closed (no silent fallbacks)?
   d. Apply verdict per the `phase-review` skill verdict protocol.
   e. **Write gate file**: Write `.work/<name>/gates/plan-to-spec.md` following the gate protocol SOP (`claude/skills/work-harness/references/gate-protocol.md`). Populate all sections from review results.
   f. **Follow the step-transition protocol** (`claude/skills/work-harness/step-transition.md`): Present gate file path and transition summary. STOP and wait for explicit approval. On approval: create gate issue, write state.json in a single atomic update (mark plan `completed` with `gate_id` and `gate_file: "gates/plan-to-spec.md"`, set spec to `active`, update `current_step` and `updated_at`). Apply context compaction — tell user to run `/compact` then `/work-deep`, then stop. If user continues without compacting, re-invoke via `Skill('work-deep')`, then re-read `.claude/rules/code-quality.md`, `.claude/rules/architecture-decisions.md` (if it exists), and the handoff prompt.

---

### When current_step = "spec"

Write detailed implementation specifications per component.

### Dispatch: Spec Agent

1. **Construct prompt**: Read `claude/skills/work-harness/step-agents.md` for the spec agent template.
   Fill variables from state.json:
   - `{name}` ← state.name
   - `{title}` ← state.title
   - `{tier}` ← state.tier
   - `{current_step}` ← state.current_step
   - `{base_commit}` ← state.base_commit
   - `{beads_epic_id}` ← state.beads_epic_id

2. **Spawn agent**:
   ```
   Agent(
     description: "spec {name-abbreviated}",
     prompt: {constructed prompt},
     mode: "default",
     subagent_type: "general-purpose"
   )
   ```

3. **Read return**: Parse the agent's completion signal (see completion format in `claude/skills/work-harness/step-agents.md`).

4. **Verify artifacts**: Check that expected artifacts exist:
   - `.work/<name>/specs/00-cross-cutting-contracts.md`
   - `.work/<name>/specs/index.md`
   - `.work/<name>/specs/handoff-prompt.md`
   - `docs/feature/<name>.md`
   If artifacts missing: re-spawn the agent (preserve existing partial artifacts per spec 00 §7).

5. **Present to user**: Show the agent's summary. Include:
   - What the agent produced (artifact list with paths)
   - Key decisions or notable items
   - Ask: "Review the artifacts, or proceed to validation?"

6. **Handle user feedback**:
   - If user approves or says "proceed": continue to auto-advance.
   - If user has feedback: construct re-spawn prompt with a "Previous Attempt" section listing artifacts written and user feedback verbatim, inserted between Rules and Instructions. Re-spawn the agent. Return to step 3.
   - After 2 re-spawns with unresolved feedback, ask the user how to proceed.

7. **Auto-advance** (see Inter-Step Quality Review Protocol):
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
   f. **Follow the step-transition protocol** (`claude/skills/work-harness/step-transition.md`): Present gate file path and transition summary. STOP and wait for explicit approval. On approval: create gate issue, write state.json in a single atomic update (mark spec `completed` with `gate_id` and `gate_file: "gates/spec-to-decompose.md"`, set decompose to `active`, update `current_step` and `updated_at`). Apply context compaction — tell user to run `/compact` then `/work-deep`, then stop. If user continues without compacting, re-invoke via `Skill('work-deep')`, then re-read `.claude/rules/code-quality.md`, `.claude/rules/beads-workflow.md`, and the handoff prompt.

---

### When current_step = "decompose"

Break specs into executable work items with a concurrency map.

**Scope expansion check:** If the user requests changes that would add new components or specs beyond what was planned, acknowledge the regression: "This adds new scope. We're currently in decompose but this requires plan/spec work." Present options: (a) roll back to plan/spec, (b) add as lightweight amendment. Document the scope change in the handoff prompt.

### Dispatch: Decompose Agent

1. **Construct prompt**: Read `claude/skills/work-harness/step-agents.md` for the decompose agent template.
   Fill variables from state.json:
   - `{name}` ← state.name
   - `{title}` ← state.title
   - `{tier}` ← state.tier
   - `{current_step}` ← state.current_step
   - `{base_commit}` ← state.base_commit
   - `{beads_epic_id}` ← state.beads_epic_id

2. **Spawn agent**:
   ```
   Agent(
     description: "decompose {name-abbreviated}",
     prompt: {constructed prompt},
     mode: "default",
     subagent_type: "general-purpose"
   )
   ```

3. **Read return**: Parse the agent's completion signal (see completion format in `claude/skills/work-harness/step-agents.md`).

4. **Verify artifacts**: Check that expected artifacts exist:
   - `.work/<name>/streams/manifest.jsonl`
   - `.work/<name>/streams/handoff-prompt.md`
   - At least one stream doc in `.work/<name>/streams/`
   If artifacts missing: re-spawn the agent (preserve existing partial artifacts per spec 00 §7).

5. **Present to user**: Show the agent's summary. Include:
   - What the agent produced (artifact list with paths)
   - Key decisions or notable items
   - Ask: "Review the artifacts, or proceed to validation?"

6. **Handle user feedback**:
   - If user approves or says "proceed": continue to auto-advance.
   - If user has feedback: construct re-spawn prompt with a "Previous Attempt" section listing artifacts written and user feedback verbatim, inserted between Rules and Instructions. Re-spawn the agent. Return to step 3.
   - After 2 re-spawns with unresolved feedback, ask the user how to proceed.

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
   f. **Follow the step-transition protocol** (`claude/skills/work-harness/step-transition.md`): Present gate file path and transition summary. STOP and wait for explicit approval. On approval: create gate issue, write state.json in a single atomic update (mark decompose `completed` with `gate_id` and `gate_file: "gates/decompose-to-implement.md"`, set implement to `active`, update `current_step` and `updated_at`). Apply context compaction — tell user to run `/compact` then `/work-deep`, then stop. If user continues without compacting, re-invoke via `Skill('work-deep')`, then re-read `.claude/rules/code-quality.md`, `.claude/rules/beads-workflow.md`, `.claude/rules/architecture-decisions.md` (if it exists), and the handoff prompt.

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
      - `subagent`: Spawn one subagent with the agent type and skills determined above. The agent prompt MUST include the standard preamble and 6-section structure. See substep (e) for prompt construction.
      - `worktree`: Notify user that worktree isolation is recommended for this stream. Provide the stream doc path and let the user manage the worktree lifecycle. Do not attempt to create or manage worktrees.

   d. Within each phase, execute `inline` streams sequentially first, then spawn all `subagent` streams in parallel. Wait for all streams in a phase to complete before starting the next phase.

   e. **Stream agent prompt construction** (for `subagent` isolation): Each subagent receives a prompt with the standard 6-section structure:

      ```
      ## Identity
      You are an implementation agent for the work harness.
      Your task: {one-line summary from stream doc}

      ## Task Context
      - Task: {name} (Tier {tier})
      - Title: {title}
      - Step: implement (Phase {N}, Stream {letter})
      - Base commit: {base_commit}
      - Epic: {beads_epic_id}
      ```

      If `.claude/harness.yaml` exists, append the stack context block:

      ```
      ## Stack Context
      - Language: {stack.language}
      - Framework: {stack.framework}
      - Database: {stack.database}
      - Build commands: {stack.build_commands}
      ```

      Then include Rules (skill injection per stream doc `skills:` field), Instructions (stream doc body + relevant specs), Output Expectations (from stream doc acceptance criteria), and Completion (standard completion signal format from spec 00 §6).

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
   - Inject skills using the `review-agent-skills` fragment (which always includes `code-quality.md`). Checklist:
     - Does the implementation comply with the relevant spec's acceptance criteria?
     - Are code-quality anti-patterns absent (error swallowing, fabricated data, fail-open)?
     - Do new tests cover the acceptance criteria?
     - Are constructor injection and error wrapping patterns followed?
   - **Finding resolution**: Phase B findings during implementation phases may be resolved immediately per the Immediate Finding Resolution protocol in `phase-review.md`. The protocol defines criteria for which findings can be fixed inline (in-scope, localized, no architectural changes, not design concerns) vs deferred to the review step. Maximum 3 immediate resolutions per transition.
   - Write results to `.work/<name>/implement/phase-N-validation.jsonl`
   - Apply verdict per the `phase-review` skill verdict protocol.
   - **Write gate file**: Write `.work/<name>/gates/implement-phase-<N>.md` following the gate protocol SOP (`claude/skills/work-harness/references/gate-protocol.md`). Populate all sections from phase validation results.
   - **Follow the step-transition protocol** for ceremony routing: Implementation phase transitions are low risk — auto-advance with notification per the Risk Classification table in step-transition.md. Gate file and gate issue are still created. On advance, record `gate_file: "gates/implement-phase-<N>.md"` in step status. Do NOT start Phase N+1 in the same turn as presenting Phase N results (the auto-advance notification is emitted first, then state is updated).
   - Only proceed to Phase N+1 when Phase N validation is PASS (auto-advanced) or user gives explicit approval after a hard stop (when `ceremony: always` is set)

5. **Checkpoints**: Use `/work-checkpoint` at session boundaries. Multi-session implementation is normal for Tier 3.

6. **Verification**: Run the project's test and build commands after each phase or logical unit.

7. **Futures**: If you discover deferred enhancements during implement, append to `.work/<name>/futures.md`.

8. **Scope expansion check**: If the user requests changes that would add new components, specs, or work items beyond what was planned, acknowledge the regression.

9. **Auto-advance** (when all work items closed — see Inter-Step Quality Review Protocol):
   a. **Phase B — Quality pre-screen** (see `phase-review` skill): Spawn review agent (read-only). Inject skills per the **Step Routing Table** `review-agent-skills` fragment. Review full diff (`git diff <base_commit>...HEAD`). Previously-resolved findings from implementation phase gate files are considered resolved — the pre-screen focuses on new issues. Checklist:
      - Are there obvious code-quality anti-patterns in the diff?
      - Do all new functions have error handling?
      - Are there any swallowed errors or fabricated defaults?
      - Do tests exist for new functionality?
   b. Apply verdict per the `phase-review` skill verdict protocol.
   c. **Write gate file**: Write `.work/<name>/gates/implement-to-review.md` following the gate protocol SOP (`claude/skills/work-harness/references/gate-protocol.md`). Populate all sections from review results.
   d. **Follow the step-transition protocol** (`claude/skills/work-harness/step-transition.md`): Present gate file path and transition summary. STOP and wait for explicit approval. On approval: create gate issue, write state.json in a single atomic update (mark implement `completed` with `gate_id` and `gate_file: "gates/implement-to-review.md"`, set review to `active`, update `current_step` and `updated_at`). Apply context compaction — tell user to run `/compact` then `/work-deep`, then stop. If user continues without compacting, re-invoke via `Skill('work-deep')`, then re-read `.claude/rules/code-quality.md` and the latest checkpoint if it exists.

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
