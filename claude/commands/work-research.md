---
description: "Standalone research — investigate a topic with structured synthesis"
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# /work-research $ARGUMENTS

Standalone research task. Pre-selects Tier R, creates a lightweight 3-step lifecycle: assess -> research -> synthesize. No implementation, no review gates — just structured investigation and a deliverable.

Use this when you need to investigate a topic without committing to implementation. If the findings warrant implementation, start a new task with `/work-feature` or `/work-deep`.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Step 1: Detect Active Task

Follow the **task-discovery** skill (`claude/skills/work-harness/task-discovery.md`).
This command expects Tier R. Apply tier-specific handling:
- **Matching tier (Tier R)**: Resume at `current_step`. Jump to the Step Router.
- **Different tier**: "You have an active Tier <N> task '<name>'. Continue with it, or archive it and start a new one?"
- **No active task**: Proceed to assessment.

## Step 2: Assessment (Tier R pre-selected)

Tier R does not use the 3-factor depth assessment. Instead, confirm the topic is a research question (not a bug fix or feature request). If `$ARGUMENTS` describes something that should be implemented, suggest `/work-fix`, `/work-feature`, or `/work-deep` instead.

## Step 3: State Initialization

1. Derive name from topic (kebab-case, max 40 chars, unique in `.work/`)
2. Capture `base_commit`: `git rev-parse HEAD`
3. Create `.work/<name>/` directory
4. Create `.work/<name>/research/` subdirectory
5. Write `state.json`:
   - `name`: derived slug
   - `tier`: `"R"` (string, not integer)
   - `title`: topic description from `$ARGUMENTS`
   - `steps`: `[{"name": "assess", "status": "completed", "completed_at": "<now>"}, {"name": "research", "status": "active", "started_at": "<now>"}, {"name": "synthesize", "status": "not_started"}]`
   - `current_step`: `research`
   - `assessment`: `{"tier_selected": "R", "rationale": "Standalone research topic"}`
   - `created_at`: current ISO 8601 timestamp
   - `updated_at`: same as `created_at`
   - `archived_at`: `null`
6. Create beads issue (NOT an epic — Tier R is lightweight):
   ```bash
   bd create --title="[Research] <topic>" --type=task --priority=2
   bd update <id> --status=in_progress
   ```
7. Create `docs/feature/<name>.md` summary file:
   ```markdown
   # <Topic Title>
   **Status:** Research | **Tier:** R | **Beads:** <issue-id>
   ## What
   <2-3 sentence description of the research question>
   ```
8. Store `issue_id` in state.json

## Step Router

Read `current_step` from state.json and execute the matching section below.

---

## Step Routing Table

| Step | Agent Type | Skills | Context Sources |
|------|-----------|--------|-----------------|
| research | Explore | code-quality, work-harness | beads issues, managed docs |
| synthesize | general-purpose | code-quality | research handoff prompt |

### Skill Injection (Path B — Prompt-Based)

**research-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/work-harness.md` for work harness conventions (parent skill with all references).
> 2. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the research task below.

**synthesize-agent-skills:**
> Before starting work, read and follow these skills:
> 1. Read `claude/skills/code-quality.md` for quality standards.
> Then proceed with the synthesis task below.

---

### When current_step = "research"

Structured exploration to build understanding of the research topic.

**Process:**

1. **Scope Validation** *(optional — not a gate)*: Before dispatching research agents, review the topic and assessment. If the research scope is ambiguous, unclear, or potentially misaligned with the user's intent, present a clarity questionnaire:

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

   **Pushback escalation**: If user responses reveal the topic needs fundamental re-scoping (e.g., "actually I need to compare three different approaches"), present re-scoping choices inline:
   - **Proceed**: Continue with the refined scope as stated
   - **Split**: Break into multiple research tasks (create new beads issues, archive or narrow current task)

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
      - Expected note format (Questions -> Findings -> Implications -> Open Questions)
      - Managed doc paths (if configured)
   c. Teammates auto-spawn, self-claim topics from the shared task list, and write research notes
   d. **Teammate prompt**: Each teammate receives the prompt template from the teams protocol, with variables filled from state.json. Teammates receive skill injection (code-quality + work-harness) via Read instructions in the Rules section, per the Step Routing Table.

6. **Monitor and verify**: The lead monitors the shared task list for completion:
   a. When all tasks complete: read each research note, verify content quality
   b. If any topic is missing or incomplete: reassign via the task list or investigate inline
   c. Tear down team: `TeamDelete("{step}-{name}")`

7. **Synthesize findings**: The lead (NOT teammates) generates:
   - `.work/<name>/research/notes.md` — consolidated research notes with cross-references
   - `.work/<name>/research/handoff-prompt.md` — consolidated open questions, research coverage summary, key findings for the synthesize step
   The lead references note file paths in the handoff — does NOT copy findings inline.

8. **Dead ends**: If any topic is a dead end, document in `.work/<name>/research/dead-ends.md`.

9. **Transition to synthesize** (no Phase A/B review — Tier R is lightweight):
   a. Write the handoff prompt to `.work/<name>/research/handoff-prompt.md`
   b. Update state.json in a single atomic write:
      - Mark research step `completed` with `completed_at`
      - Set synthesize step to `active` with `started_at`
      - Update `current_step` to `synthesize`
      - Update `updated_at`
   c. **Context compaction**: Tell the user: "Research complete. Recommend: `/compact` then `/work-research` to start **synthesize** with clean context."
   d. If the user continues without compacting: re-invoke via `Skill('work-research')`, then re-read the handoff prompt.

---

### When current_step = "synthesize"

Read the research handoff and produce a structured deliverable.

**Process:**

1. **Read research handoff**: Read `.work/<name>/research/handoff-prompt.md`. This is the primary input — do NOT re-read raw research notes unless the handoff references them for specific details.

2. **Produce deliverable**: Write `.work/<name>/research/deliverable.md` with the following structure:

   ```markdown
   # <Topic Title> — Research Deliverable

   ## Executive Summary
   <3-5 sentences: what was investigated, key conclusions, recommended actions>

   ## Findings

   ### <Finding Area 1>
   <Evidence-based findings organized by topic. Reference sources.>

   ### <Finding Area 2>
   <Evidence-based findings organized by topic. Reference sources.>

   ...

   ## Recommendations
   <Actionable recommendations based on findings. Each recommendation should be specific and justified.>

   ## Open Questions
   <Questions that remain unanswered or require further investigation. Each should note why it matters.>

   ## Sources
   <Files examined, documentation referenced, prior art consulted. Use project-relative paths.>
   ```

3. **Update docs summary**: Update `docs/feature/<name>.md` with key findings:
   ```markdown
   # <Topic Title>
   **Status:** Complete | **Tier:** R | **Beads:** <issue-id>
   ## What
   <2-3 sentence description of the research question>
   ## Key Findings
   <Bullet points of the most important findings from the deliverable>
   ## Deliverable
   See `.work/<name>/research/deliverable.md` for the full research report.
   ```

4. **Close beads issue**:
   ```bash
   bd close <issue-id> --reason="Research complete — deliverable at .work/<name>/research/deliverable.md"
   ```

5. **Mark synthesize complete**: Update state.json in a single atomic write:
   - Mark synthesize step `completed` with `completed_at`
   - Update `current_step` to `synthesize` (already set, but confirm)
   - Update `updated_at`

6. **Suggest archiving**: Present completion message:
   ```
   Research complete. Deliverable: .work/<name>/research/deliverable.md

   Run `/work-archive` to archive this research task.
   If findings warrant implementation, start a new task with `/work-feature` or `/work-deep`.
   ```

## Escalation Handling

Tier R does not support escalation. Research tasks stay research-only. If the user wants to implement findings, they start a new task — the research deliverable serves as input to the new task's research or plan step.

## Skill Propagation

Agent skills are determined by the **Step Routing Table** above. Each step
specifies the exact skills to propagate. The routing table is the single
source of truth for agent configuration — do not hardcode skill lists
in step instructions.

For the skill injection mechanism, see the **Skill Injection (Path B — Prompt-Based)**
section above. Skills are injected via explicit `Read` instructions in agent prompts
because Claude Code agent frontmatter does not support `skills:` natively.

## Session Boundaries

Tier R tasks typically complete in 1-2 sessions.
- **Starting a session**: Run `/work-research` — it detects the active task and resumes at `current_step`
- **Ending a session**: Run `/work-checkpoint` to save progress
- **Step transitions**: Run `/compact` then `/work-research` to start synthesize with clean context
- **After compaction**: Run `/work-reground` to recover context
- **Dead ends**: Run `/work-redirect` to document failed approaches
