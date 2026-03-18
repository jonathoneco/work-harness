# Research Step Review — Harness Improvements (Round 3)

> Updated with answers to your round 2 feedback. Review and respond at the bottom.

---

## Research Summary (8 Areas)

### 1. Command Modularization

~4,926 lines across 60 files. ~700 lines duplicated in 8 patterns. Top extractions:

- `task-discovery` skill (7 commands repeat active task finding)
- `step-transition` skill (10+ identical approval ceremonies)
- `phase-review` skill (5 identical review blocks in work-deep.md)
- `hooks/lib/common.sh` for hook boilerplate

### 2. Dynamic Delegation

No native conditional activation in Claude Code — routing must be command-level (already the case).
Agents reference skills as inline markdown — needs verification if YAML frontmatter `skills:` works.
Phase-specific guidance should move from rules (always loaded) to skills (on-demand).

### 3. Auto-Reground

SessionStart hook with `resume` matcher. Create `hooks/session-reground.sh` that scans active tasks
and injects handoff prompt as context. Consolidate with existing `post-compact.sh`.

> **Your note**: Sometimes I'll have multiple workflows going so which gets regrounded should be based on what was compacted

**Response**: Good point. The approach should be:

- **On resume/startup**: If multiple active tasks exist, list them with tier/step and ask which to work on (similar to how `/work` already handles this). Don't auto-reground a specific one — present the choice.
- **On compact**: The `PostCompact` hook already knows which conversation was compacted. Since each session works one task at a time, the hook should detect which task's `.work/` files were recently accessed (via `git diff --name-only` or by reading conversation context from stdin). Reground that specific task.
- **Key design**: The compact hook gets JSON context on stdin including the conversation state. We can use that to identify which task was active. The resume hook doesn't have that context, so it should present a choice when multiple tasks are active.

> I actually only want to reground on compact, on resume it should already be grounded and on startup I want choice, I may not be going into a workflow

**Response (R3)**: Clear. Revised design:

- **On compact only**: Auto-reground the task whose `.work/` files appear in recent context. The `PostCompact` hook already exists — extend it to inject the relevant handoff prompt.
- **On startup**: No auto-reground. The existing `workflow-detect.md` rule already shows a notification with active tasks. User chooses whether to `/work-reground` or start fresh.
- **On resume**: No change needed — context is already in the conversation.

This simplifies the implementation to just enhancing the existing `post-compact.sh` hook rather than creating a new `session-reground.sh`.

### 4. Code Quality References

Best drop-ins: **sec-context** (25+ security anti-patterns for LLM context), **agnix** (AI config linter, 230+ rules).
9-parallel-review-agents pattern proven effective. Key insight: CI linter errors > docs AI can ignore.

### 5. Context Doc Lifecycle

> **Your note**: Expand here please, I want more context

**Expanded**:

The idea is that projects accumulate context documents that AI agents need — but these docs go stale as code changes. The harness could help manage this lifecycle. Here's what the research found:

**What kinds of context docs exist:**

- **Dev environment**: Setup instructions, dependency lists, build commands, env var docs. Currently your `harness.yaml` captures some of this (stack, build commands). Could be auto-generated from package.json/go.mod/Dockerfile.
- **API/Endpoint docs**: What endpoints exist, their contracts, auth requirements. Tools like Levo.ai generate OpenAPI specs from live traffic. Code-based tools extract from annotations/comments.
- **Frontend component docs**: Props, usage patterns, visual examples. Storybook Autodocs + the new Storybook MCP server expose these as machine-readable context.
- **Architecture Decision Records (ADRs)**: Why decisions were made. The harness's `architecture-decisions.md` rule file is already a form of this. `cADR` auto-generates them in CI.
- **AI context files**: CLAUDE.md, rules/, skills/. These are the docs most likely to drift from reality.

**Three-tier maintenance strategy:**

1. **Manual** (current state): Human notices wrong AI output, fixes context file
2. **Automated detection**: A hook or CI job compares codebase structure against context file claims, flags drift. Example: "your CLAUDE.md says you use Express, but package.json shows Fastify"
3. **Fully automated**: On PR merge, an agent scans what changed and proposes doc updates. `claude-code-action` does this — it reviews code changes and updates docs in the same PR.

**What this means for the harness:**

- Add a `/doc-check` command or hook that scans for stale context docs
- A `doc-sync` command that uses AI to detect and propose updates
- Hook into `work-review` to check if implementation changes invalidated any context docs
- Template system for common doc types (endpoint registry, component catalog, ADR)

**The question of scope**: The harness could either (a) provide the doc lifecycle infrastructure (commands, hooks, templates) that projects customize, or (b) actually manage specific doc types itself. Option (a) is more appropriate for a general-purpose harness.

> What would project customization looks like, I lean (b) as it seems that customization can be inferred over chats, work, and existing infra, but I'm open to being challenged

**Response (R3)**: You're right that (b) is the better fit. The harness already knows the project stack from `harness.yaml`, can detect frameworks from config files, and accumulates context through work sessions. A manifest-driven approach would look like:

```yaml
# in harness.yaml
docs:
  managed:
    - type: endpoints # auto-detected if stack includes web framework
      path: docs/endpoints.md
    - type: components # auto-detected if stack includes React/Vue/etc
      path: docs/components.md
    - type: env-setup # always relevant
      path: docs/dev-setup.md
    - type: architecture # always relevant
      path: docs/architecture.md
    - type: dependencies # always relevant
      path: docs/dependencies.md
```

The harness would auto-detect which doc types are relevant based on the stack config, then maintain them through hooks:

- After implementation steps, scan changed files against managed doc types
- At `/work-archive`, verify managed docs are current
- At `/work-review`, check if implementation invalidated any managed docs

The manifest also serves as a discovery mechanism for AI context — agents know where to look for specific project knowledge.

> We should make sure to not only manage these docs but leverage them

### 6. Codex Integration

`codex exec --output-schema --sandbox read-only` for headless review. Also `codex --mcp` as MCP server.
Honest assessment: "second opinion" not "categorically better" — better at race conditions/edge cases, 4x cheaper, but hallucinates.
Phased: skill -> MCP -> dual-review.

> **Your note**: Expand on the hallucination concern

**Expanded**:

Codex hallucination in review context means it reports bugs/issues that don't actually exist. Specific patterns observed:

1. **Phantom race conditions**: Codex flags concurrent access to a variable that's actually protected by a mutex it didn't notice, or identifies a race in single-threaded code.

2. **Misunderstood control flow**: Reports that a nil/null check is missing when there's actually a guard clause 20 lines earlier that Codex didn't connect.

3. **Framework-specific false positives**: Flags patterns as unsafe that are actually idiomatic in the framework (e.g., reporting a Go error isn't checked when it's being handled by a deferred function).

4. **Plausible-sounding but wrong severity**: Classifies a cosmetic issue as P1/critical, or invents a security vulnerability that requires conditions impossible in the actual deployment.

**Mitigation approaches:**

- **Structured output schema**: Force Codex to cite the specific line and explain _why_ it's a bug. This makes hallucinations easier to spot since the explanation won't match the code.
- **Claude verification layer**: Claude reads Codex findings and cross-checks against the actual code. "Codex flagged X at line Y — let me verify." This is the dual-review pattern.
- **Confidence scoring**: In the output schema, require a confidence field. Low-confidence findings get flagged for human review rather than auto-actioned.
- **Historical calibration**: Track false positive rate over time. If Codex's false positive rate for a project is >30%, reduce its review scope to areas where it's proven accurate.

**Bottom line**: Codex review findings should always be verified, never auto-actioned. The value is in surfacing things Claude might miss, not in replacing Claude's review.

> I see, agreed on verification

### 7. Parallel Decomposition

Three tiers: subagents (no nesting), agent teams (experimental), worktrees (manual).
Existing streams model validated by harness-modularization task.
Enhance stream docs with: isolation mode, agent type, skills, file ownership manifest.
Hybrid strategy: subagents for small, agent teams for large, worktrees for multi-session.

### 8. Memory Integration

Official MCP KG server — JSONL-based, zero infrastructure. Letta benchmark: filesystem beats specialized libs.
Claude-Mem for automatic capture. Harness already has 3 memory layers (CLAUDE.md, auto memory, .work/ state).
Start with MCP KG for cross-project knowledge, defer graph DB.

> **Your note**: There's a kg mcp in my personal-agent project, if I include one in this harness which gets moved to my global config do those overlap or does the personal agent's stay isolated and get access to both (that's ideal)

**Response**:

MCP servers in Claude Code are configured at two levels:

- **User-level**: `~/.claude/settings.json` → `mcpServers` — active for ALL projects
- **Project-level**: `.claude/settings.json` (in project root) → `mcpServers` — active only in that project

Both levels' MCP servers are available simultaneously in the same session. They don't overlap — each is a separate process with separate state. So:

- **Personal-agent's KG MCP** (configured in that project's `.claude/settings.json`): Only active when you're working in the personal-agent project directory. Uses its own `memory.jsonl` file.
- **Harness KG MCP** (installed to `~/.claude/settings.json` by `install.sh`): Active in ALL projects. Uses a different `memory.jsonl` file (path set via `MEMORY_FILE_PATH` env var).

**If you want both accessible everywhere**, you'd configure both at user-level with different names and different storage paths:

```json
{
  "mcpServers": {
    "memory-personal": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": { "MEMORY_FILE_PATH": "~/.claude/memory/personal.jsonl" }
    },
    "memory-harness": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": { "MEMORY_FILE_PATH": "~/.claude/memory/harness.jsonl" }
    }
  }
}
```

**If you want project-specific + global**: Keep personal-agent's KG at project level, add harness KG at user level. When in personal-agent project, both are available. Everywhere else, only harness KG.

**The ideal setup you described** (personal stays isolated, gets access to both) works naturally with the second option — project-level for personal, user-level for harness. Claude sees both MCP servers and can call either's tools.

> Perfect let's go with that, how will claude know when to call which (especially when it has access to both)

**Response (R3)**: MCP tool routing depends on server naming and tool descriptions. With two KG servers, Claude sees two sets of identically-named tools (`create_entities`, `search_nodes`, etc.) but prefixed by server name:

- `mcp__memory-personal__create_entities`
- `mcp__memory-harness__search_nodes`

To make routing intuitive, you'd need:

1. **Clear server naming**: `memory-personal` vs `memory-harness` (or `memory-work`) makes the intent obvious from the tool name alone.

2. **Rules-based routing**: A rule in the harness or personal-agent that says:

   ```
   When storing/retrieving work harness state, task context, or project patterns, use memory-harness.
   When storing/retrieving personal preferences, cross-project knowledge, or daily handoffs, use memory-personal.
   ```

3. **Skill-level routing**: The harness's skills/commands would explicitly call `mcp__memory-harness__*` tools. The personal agent's skills would call `mcp__memory-personal__*` tools. Ad-hoc Claude interactions default to personal.

4. **In practice**: Claude is generally good at routing by name once the server names are descriptive. "Store this decision in work memory" vs "Remember that I prefer Go for backend services" would naturally route to the right server.

The main risk is ad-hoc queries where Claude picks the wrong one. A rule file that documents the routing policy handles this.

> Looks good, I like this, let's name it personal-agent and work-log

---

## Proposed Additions (from discussion)

### 9. Agent-Written Research Notes

Research agents should write their own `.work/<name>/research/NN-topic.md` files directly,
since they have the richest context. Lead agent provides task framing in agent prompts,
then only synthesizes the handoff prompt (cross-references, dependency mapping, open questions).

### 10. File-Based Review UX

Step transitions and ad-hoc reviews should write to a REVIEW.md file that the user opens
in their editor (proper scrolling, search, split-screen). User writes feedback/approval
in the file, saves, and tells Claude to read it. Applies to every gate, checkpoint, and
approval ceremony in the harness.

> **Your note**: Yes, this should be stored in something akin to `.work/<name>/gates/<gate/review>.md`

**Response**: Agreed. The path structure would be:

- Step transition gates: `.work/<name>/gates/<from>-to-<to>.md` (e.g., `research-to-plan.md`)
- Phase gates: `.work/<name>/gates/implement-phase-N.md`
- Ad-hoc reviews: `.work/<name>/gates/review-<timestamp>.md`
- Final review: `.work/<name>/gates/final-review.md`

Each gate file follows the same template: summary, findings, questions section, response section. The user's response is the approval record — it stays in git as part of the task history.

> Great, there is some weird edge cases that may come up, i.e. needing to go back to planning / researching if things change, what might that look like, it would also be nice to define a standard operating procedure for these files, how they're used, updated, and iterated on

**Response (R3)**:

**Rollback scenarios and gate file lifecycle:**

When things change mid-implementation and you need to go back:

1. **Scope change during implement → back to plan/spec**: Create a new gate file `gates/rollback-implement-to-plan.md` that documents:
   - What triggered the rollback (new requirement, discovered complexity, etc.)
   - What from the original plan/spec is still valid
   - What needs to change
   - The original gate files stay as historical record (not deleted)

2. **Research invalidated during spec → back to research**: Same pattern — `gates/rollback-spec-to-research.md`. The new research builds on the old (doesn't re-do everything).

3. **Mid-phase pivot**: If Phase 2 of implementation reveals Phase 1 was wrong, the gate file for that phase captures the finding and triggers a re-plan.

**Standard Operating Procedure for gate files:**

```
GATE FILE SOP

1. CREATION: Claude writes the gate file when a step completes or a review is needed.
   Path: .work/<name>/gates/<gate-name>.md
   Template: Summary → Findings → Questions → User Response section

2. REVIEW: User opens in editor, reads at their pace, writes inline comments
   and decision at the bottom. Saves file.

3. ITERATION: If user has questions/feedback, Claude reads the file,
   updates with responses (marking round number: "Response (R2)"),
   and user reviews again. Repeat until decision is reached.

4. APPROVAL: User writes "approve" in the Decision field.
   Claude reads the file, creates the beads gate issue,
   advances state.json, and the gate file is committed to git.

5. ROLLBACK: If a later step invalidates this gate's assumptions,
   a rollback gate file is created referencing the original.
   The original is NOT modified — it stays as historical record.

6. HISTORY: Gate files accumulate in .work/<name>/gates/ as a
   decision audit trail. Each file shows who decided what and when.
```

This SOP would live as a reference doc in the harness (e.g., `skills/work-harness/references/gate-protocol.md`) so agents know how to create and manage gate files.

---

## Resolved Open Questions

1. **Modularization scope**: **Refactor existing commands** ✓
2. **Memory scoping**: User-level preferred (cross-project, end-of-day handoffs). See expansion below.
3. **Codex dependency**: **Optional with graceful degradation** ✓
4. **Context doc scope**: See expansion below.
5. **Agent Teams readiness**: **Yes, stable enough** — user uses extensively ✓
6. **Priority ordering**: parallel decomp → code quality refs → context doc lifecycle → dynamic delegation → modularization → file-based review → agent research notes → auto-reground → codex integration → memory ✓

### Memory Scoping — Expanded Options

> **Your note**: I like user-level, thinking about end of day handoffs grounded across all my work

The three scoping options and what they enable:

**User-level (machine-local, `~/.claude/memory/`):**

- Persists across all projects on this machine
- Great for: end-of-day handoffs, personal preferences, cross-project patterns, "yesterday I was working on X"
- Not git-tracked — private to this machine
- The MCP KG server stores here by default
- Claude Code's built-in auto memory (`~/.claude/projects/<project>/memory/`) is already user-level but project-scoped

**Project-level (git-tracked, `.claude/memory/` or `.work/`):**

- Shared with anyone who clones the repo
- Great for: project decisions, architecture context, team knowledge
- The harness's `.work/` state files already do this for task context
- Risk: memory files can contain sensitive info that shouldn't be committed

**External (MCP server with remote storage):**

- Accessible from any machine
- Great for: cross-machine continuity, team-shared memory
- Requires infrastructure (server, auth)
- Not practical for this phase

**Recommendation for end-of-day handoffs**: User-level MCP KG at `~/.claude/memory/work-journal.jsonl`. At session end (or via a `/handoff` command), the agent captures:

- What was accomplished today
- What's in progress and blocked
- Key decisions made
- Suggested starting point for tomorrow

This gets automatically loaded next session. The harness's `/work-reground` command could query this memory to understand broader context beyond just the current task.

> I like this quite a bit

### Context Doc Scope — Expanded

> **Your note**: This is broad and could mean a couple different things

You're right. Here are the two distinct interpretations:

**Interpretation A: "Which doc types should the harness provide lifecycle tooling for?"**
This means: the harness provides commands/hooks/templates that help manage docs, but projects decide which doc types to use. Examples:

- A `/doc-check` command that detects stale docs (generic, works for any doc type)
- A hook that warns if implementation changes touch files covered by a doc that wasn't updated
- Templates for common doc types (endpoint registry, component catalog, ADR)
- A `harness.yaml` `docs:` section where projects declare their doc types and paths

**Interpretation B: "Which context docs should the harness itself maintain about the project?"**
This means: the harness automatically maintains certain docs as part of its workflow. Examples:

- Auto-update `harness.yaml` stack section when dependencies change
- Maintain a component/module inventory as code changes
- Generate a "what changed since last session" summary
- Keep architecture-decisions.md current after each implementation

**These aren't mutually exclusive.** Interpretation A is infrastructure (the harness enables doc management). Interpretation B is behavior (the harness does doc management). The priority ordering suggests starting with A (lower risk, more flexible), then adding B behaviors for specific high-value doc types.

Which interpretation (or both) resonates with what you had in mind?

> I had interpretation b in mind, a standard set of docs (potentially via manifest that dictates which are relevant similar or alongside tech dependencies) seems like it's be easier to explicitly manage, and I'd rather the harness automatically maintain these docs

**Response (R3)**: Understood — going with interpretation B. The harness auto-maintains a manifest-driven set of context docs, auto-detecting relevant doc types from the project stack. See the expanded design in section 5 above.

---

## All Decisions Summary

| Question             | Decision                                                                                                                                 |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Modularization scope | Refactor existing commands                                                                                                               |
| Memory scoping       | User-level, with work-journal for end-of-day handoffs                                                                                    |
| Memory MCP routing   | Descriptive server names + rule-based routing policy                                                                                     |
| Codex dependency     | Optional with graceful degradation                                                                                                       |
| Codex hallucinations | Always verify, never auto-action                                                                                                         |
| Context doc scope    | Interpretation B — harness auto-maintains via manifest                                                                                   |
| Agent Teams          | Stable enough to build on                                                                                                                |
| Auto-reground        | Compact-only (enhance existing post-compact.sh)                                                                                          |
| Gate files           | `.work/<name>/gates/` with SOP for creation, iteration, rollback                                                                         |
| Priority             | parallel decomp → code quality → context docs → delegation → modularization → file review → agent notes → auto-reground → codex → memory |

---

## Your Response

> All questions addressed. Options: **approve** to advance to plan, or add more feedback.

**Decision**:

**Notes**:

> Review the expansions and resolved questions above.
> Options: **approve** to advance to plan, or add more feedback.

**Decision**:

approve

**Notes**:
