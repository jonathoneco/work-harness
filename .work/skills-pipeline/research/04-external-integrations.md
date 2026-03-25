# External Integrations Research (PR, Notion, Dev Updates)

## Research Questions

1. **PR Handling**: What does `/pr-prep` currently cover? What gaps exist for a full PR review/CI/merge workflow?
2. **Notion Integration**: What MCP tools or references to Notion exist in the codebase? What does "push back against shallow exploration" mean?
3. **Dev Updates**: What workflow artifacts exist that could feed status updates for Richard? What format would dev updates take?
4. **MCP Configuration**: What MCP servers are configured? How are they discoverable and activatable?
5. **External Integration Architecture**: Should new integrations follow the skill pattern or MCP server pattern?

---

## Findings

### 1. PR Handling — Current State & Gaps

**File Examined**: `claude/commands/pr-prep.md` (9-step workflow)

**Current Coverage (What pr-prep Does)**:
- **Lint/Build Fixes** (Steps 1-3): Reads build commands from harness.yaml, runs lint, parses and fixes errors (unused functions, variables, error checks, ineffectual assignments)
- **Build Verification** (Step 4): Runs build check, stops if build fails
- **Optional Tests** (Step 5): Runs tests if `--test` flag, fixes failures
- **Optional Format** (Step 6): Runs formatter if `--format` flag
- **Code Commit** (Step 7): Stages modified files, commits with "fix: resolve lint issues for PR"
- **PR Lifecycle** (Steps 8a-8c):
  - Checks if PR exists via `gh pr view`
  - Reviews existing PR: compares title/body against actual commits, updates if needed
  - Creates new PR: drafts title/body, waits for user approval, creates via `gh pr create`
- **Reporting** (Step 9): Reports fixes by category, whether PR was created/updated, any unfixable issues

**What pr-prep Does NOT Cover**:
- **CI/Continuous Integration**: No step to wait for GitHub Actions checks, monitor status, or handle check failures
- **Review Setup**: No assignment of reviewers, no label tagging, no linking to beads issues
- **Code Review**: Does not spawn code review agents (separate `/work-review` handles this)
- **Approval Handling**: Does not detect reviewer responses, blockers, or conflicts
- **Merge Coordination**: Does not rebase/merge, handle conflicts, or coordinate merge timing
- **Draft Mode**: Does not support creating draft PRs (though `gh pr create --draft` is available)
- **Post-Merge Cleanup**: Does not close beads issue or clean up branch after merge
- **Review Monitoring**: No integration to track PR status changes or auto-retry on failures

**Architectural Notes**:
- Works with generic `gh` CLI commands — no custom abstraction layer
- Step 8c (PR creation) asks for user approval before creating — safe but blocks automation
- No mechanism to wait for CI checks before merge (external requirement)

**Skill/Command Integration**:
- Triggered via `/pr-prep` (user-invocable command)
- References `code-quality` skill for lint/build understanding
- Used after implementation when code is ready for review
- No integration with work-harness state machine (doesn't read/write state.json)
- Blocks on user approval for PR title/description — good safety, but prevents batch automation

### 2. Notion Integration — Current State & Obstacles

**MCP Server Status**:
- **Serena LSP server**: Provides 19 code navigation tools (find_symbol, find_referencing_symbols, etc.)
- **Notion OAuth setup**: Documented as **pending** in harness-roadmap.md (W1 quick-wins)
- **No native Notion MCP server**: Codebase references Notion but no MCP server is configured yet

**Configuration Files Checked**:
- `.claude/settings.local.json`: Allows Serena MCP tools, beads shell commands, no Notion MCP configured
- No `.github/workflows/` directory — no CI/Actions configured in this repo
- `.serena/project.yml`: Bash language server configured for Serena LSP

**Notion References in Codebase**:
- Found in `.work/skills-pipeline/research/05-prior-art.md`:
  - Sessions 6 & 8 attempted Notion exploration with documented failures
  - **Pagination failure**: Notion researcher only read first page of blocks; user explicitly caught the gap
  - **MCP Permission Blocking**: Sub-agents cannot approve interactive MCP tool permissions (OAuth flow)
  - **Token Debugging**: Consumed 15 minutes on shell variable expansion issues (${NOTION_TOKEN} unexpanded)
  - Harness-roadmap.md: "Notion pending OAuth setup" — flagged as blocked item

**"Push Back Against Shallow Exploration" Context**:
- Work item #8 in skills-pipeline.md: "Skill: deep Notion exploration"
- Framing: Pushback against **shallow** exploration implies systematic, comprehensive reading needed
- Lessons from S6/S8 failures:
  - Incomplete pagination (only first page read)
  - MCP permissions prevent sub-agent delegation (OAuth token requires main-thread approval)
  - Token handling fragile (unexpanded shell variables, missing quotes)

**Implications**:
- A "deep Notion exploration" skill would need to:
  - Enforce pagination: read all pages/blocks, not just first set
  - Handle OAuth token configuration robustly (likely via `.claude/settings.local.json` or harness.yaml)
  - Run in main thread (can't delegate to sub-agents due to permission requirements)
  - Include validation: confirm all blocks were read, detect pagination errors, audit coverage
  - Possibly include a "Notion pagination audit" companion step

### 3. Dev Update Generation — Artifacts & Format

**Work Item**: Skills-pipeline.md item #2 — "Skill: dev update dump for Richard"
**Context**: W5 (Human-in-the-Loop Reporting) depends on W4 infrastructure

**Workflow Artifacts Available for Status Updates**:
- **state.json** (per task): tier, current_step, assessment scores, created_at, updated_at, reviewed_at, issue_id, base_commit
- **findings.jsonl** (append-only): finding ID, status (OPEN/FIXED/PARTIAL), severity, category, file, line, message, agent
- **Checkpoints** (markdown): resumption prompt, progress summary, blockers, decisions
- **Handoff prompts** (markdown): step-specific context for next session
- **Feature docs** (`docs/feature/<name>.md`): Summary file auto-created per task
- **Beads issues** (tracked in `.beads/issues.jsonl`): Title, description, status, priority, dependencies

**What Richard Likely Needs**:
- Digestible status artifacts (not raw JSON)
- Transformation of structured workflow data into narrative format
- Current findings summary (what's open, what's blocked, severity breakdown)
- Progress tracking (assessment scores, step transitions, estimated time to completion)
- Risk/blocker highlights (critical findings, escalations, decision points)
- Output format likely: markdown document or email-friendly narrative

**Format Precedent**:
- Handoff prompts use markdown narrative with explicit sections (problem, solution, blockers)
- Gate files (Tier 3 review artifacts) use markdown with structured sections
- Pattern suggests skill should produce markdown summaries, possibly with JSON export option

**Status Update Scope**:
- Summarize state.json: What tier? Current step? When started?
- Findings snapshot: Count by severity, list blockers, highlight fixes
- Recent decisions: What changed? Why?
- Next action: What's the user supposed to do now?

### 4. MCP Server Configuration & Discovery

**Configured MCP Servers** (from investigation):
- **work-log** — Cross-project work journaling (Knowledge Graph, accessed via `mcp__work_log__*` tools)
- **personal-agent** — Project-specific memory (Knowledge Graph, accessed via `mcp__personal_agent__*` tools)
- **Serena** — LSP-backed code navigation (19 tools: find_symbol, find_referencing_symbols, etc.)

**How Discovery Works**:
- MCP tools appear in available tools list with `mcp__<server>__<operation>` naming
- Runtime discovery: Check if `mcp__<server>__*` tools exist (e.g., `/handoff` checks for `mcp__work_log__*`)
- Settings-based allowlisting: `.claude/settings.local.json` has `permissions.allow` list with tool names
- Fallback pattern: If MCP server not configured, gracefully document requirement (e.g., `/handoff` with unavailable work-log)

**Configuration Locations**:
- `.serena/project.yml` — LSP server (Serena) configuration
- `.beads/config.yaml` — Beads issue tracker configuration
- `.claude/settings.local.json` — MCP permissions allowlist
- `.claude/harness.yaml` — Project stack context (language, build commands, optional MCP configs)

**No Notion MCP Yet**:
- Notion would require OAuth token setup (documented as pending in roadmap)
- Would likely follow pattern: `.claude/settings.local.json` allowlist + OAuth token in `.claude/settings.local.json` or harness.yaml
- Cannot use interactive OAuth approval flow in sub-agents (blocking issue from prior attempts)

### 5. Integration Architecture — Skills vs MCP Servers

**Observed Pattern** (from examining work-harness structure):

| Integration Type | When to Use | Example | Activation |
|---|---|---|---|
| **MCP Server** | External APIs, knowledge graphs, LSP servers, structured data access | work-log KG, Serena LSP, future Notion API | Configured in settings.json, tools auto-discovered |
| **Skill (markdown)** | Procedural guidance, logic/reasoning, agent instruction | code-quality, adversarial-eval, work-harness | Referenced via `skills: [name]` in command/agent prompt |
| **Command (.md)** | User-invocable workflows, state machine logic, tier routing | /work-fix, /pr-prep, /delegate | User runs via CLI, spawns agents with skills injected |

**For New External Integrations**:
1. **Notion deep exploration** → Skill (procedural guidance on pagination, token handling, validation)
   - Why: Not a new API endpoint, but a systematic workflow improvement
   - Activation: Referenced in commands/agents that do document research
2. **Dev update dump for Richard** → Skill (transforms artifacts into narrative)
   - Why: Logic/reasoning task, not a new external API
   - Activation: User invokes `/pr-prep` or other commands that trigger status generation
3. **PR review/CI/merge workflow** → Command + Skill
   - Why: New user-invocable workflow (command) + procedural guidance (skill)
   - Activation: User runs `/pr-review` or similar; command seeds agents with skill

**Config Injection Pattern** (mandatory for all commands):
```markdown
**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section in all subagent prompts.
```

All commands must read harness.yaml if available — documented in pr-prep.md, work-feature.md, work-fix.md, etc.

---

## Implications

### For PR Handling (Item #4)

1. **New Command Opportunity**: Current `pr-prep` covers lint/build/PR creation. A new `/pr-review` or `/pr-monitor` command could handle:
   - Waiting for CI checks (with configurable timeout)
   - Fetching and displaying check results
   - Detecting failures and offering retry/escalate options
   - Integration with code review agents (already provided by `/work-review`)
   - Merge coordination (detecting approval, conflicts, ready-to-merge state)

2. **Skill Architecture**: If a comprehensive PR workflow is needed, could be:
   - **Option A (Monolithic)**: One `pr-lifecycle` skill with all steps (creation → CI → review → merge)
   - **Option B (Layered)**: Separate skills per phase (`pr-creation`, `pr-review-monitoring`, `pr-merge`)
   - **Current**: `pr-prep` is command-only; `/work-review` handles code review separately

3. **Critical Gaps**:
   - CI monitoring: None (external requirement — GitHub Actions checks not integrated)
   - Reviewer assignment: Manual via gh CLI, no automation
   - Merge safety: No conflict detection, no rebase strategy
   - Beads linking: Not automatic (could improve tracking)

### For Notion Deep Exploration (Item #8)

1. **Blocker**: Notion OAuth token not yet configured in harness
   - Prerequisite: Set up Notion MCP server OAuth flow
   - Location: `.claude/settings.local.json` or harness.yaml (design decision needed)
   - Test: Verify token works, pagination succeeds, recursive traversal works

2. **Skill Requirements**:
   - Enforce pagination: Loop until all pages read
   - Recursive traversal: Follow child blocks, all nesting levels
   - Coverage audit: Report pages/blocks count, detect early termination
   - Error handling: Token expiry, permission errors, malformed responses
   - Failure modes: Catch shallow reading, incomplete pagination, lost context

3. **Implementation Note**:
   - Sub-agents cannot do OAuth approval (permission blocking issue)
   - Skill must run in main thread or with pre-approved token
   - Could pair with automated token refresh mechanism (future item)

### For Dev Updates Skill (Item #2)

1. **Data Sources Ready**: state.json, findings.jsonl, checkpoints, feature docs, beads issues all available
   - No new MCP integration needed
   - Skill can transform existing artifacts into narrative

2. **Output Format Decision**:
   - Markdown narrative (email-friendly) vs. structured JSON export
   - Likely both: MD for human reading, JSON for downstream processing
   - Should include: task status, findings summary, recent decisions, next action

3. **Integration Point**:
   - Could be triggered at task archive (`/work-archive`)
   - Could be triggered on-demand via new command (`/dev-update <task-name>`)
   - Could be auto-generated and stored in `.work/<name>/artifacts/`

4. **Richard Context**:
   - Richard is project stakeholder receiving status updates
   - Needs digestible summaries, not raw data dumps
   - Format: Likely weekly/milestone status emails
   - Skill should focus on narrative clarity, finding severity highlighting, risk surfacing

### For Command Structure

1. **New Commands Needed** (to fulfill W4 items):
   - `/pr-review` — PR review/CI monitoring/merge coordination
   - `/work-dump` or `/work-decompose` — Standalone work decomposition (currently only in Tier 3 decompose step)
   - `/dev-update` — Generate and export status updates for stakeholders

2. **Pattern for Adding Commands**:
   - Create markdown file with YAML frontmatter (`name`, `description`, `user_invocable`, optional `skills`)
   - Implement step-by-step logic with agent spawning where needed
   - Update `claude/rules/workflow.md` command table (sync contract with workflow-meta)
   - Include config injection directive (read harness.yaml if available)
   - Test with `harness-doctor` to verify integration

3. **Skills to Create**:
   - `pr-lifecycle` — For PR review/merge coordination (new)
   - `notion-explorer` — For deep Notion exploration with pagination enforcement (new)
   - `status-generator` — For dev update transformation (new)
   - Possibly `status-approval` — For Richard's approval/review of generated updates (future)

---

## Open Questions

### For PR Handling

1. **CI Integration Scope**: Should `/pr-review` wait for all checks, or let user decide retry/merge despite failures?
2. **Reviewer Assignment**: Auto-assign based on beads issue, or require manual specification?
3. **Merge Strategy**: Squash vs. merge commit vs. rebase? Configurable per project?
4. **Conflict Handling**: Offer to rebase/resolve conflicts automatically, or escalate to user?
5. **Post-Merge Cleanup**: Auto-close beads issue and branch, or manual confirmation needed?

### For Notion Deep Exploration

1. **Token Configuration**: Where should Notion OAuth token live — `.claude/settings.local.json`, harness.yaml, or environment variable?
2. **Notion Scope**: What Notion spaces/pages should the "deep exploration" skill cover — all shared docs, or specific playbooks/specs?
3. **Coverage Validation**: Should skill produce a coverage report showing % of blocks read, or just binary pass/fail?
4. **Permission Errors**: If sub-agent hits Notion permission error, should main thread automatically retry, or escalate?
5. **Token Expiry**: Should skill handle token refresh, or assume admin keeps it fresh?

### For Dev Updates

1. **Richard's Update Frequency**: Weekly status? Per-task completion? On-demand? Affects batch vs. streaming logic.
2. **Confidentiality/Filtering**: Should all findings be included, or filter by severity/priority?
3. **Historical Comparison**: Should updates compare progress to prior week/sprint (trend analysis)?
4. **Approval Workflow**: Does Richard approve updates before sending, or auto-distribute?
5. **Distribution Channel**: Email, Slack, Notion doc, or rendered markdown file?

### For Architecture

1. **Skill Lifecycle**: Should skills auto-update as code changes (proactive skill updating — W4 item #3)?
2. **Language Packs Activation**: When projects use multiple languages (Go + TypeScript), how to activate all relevant anti-pattern packs?
3. **Agency Integration**: Should the harness include curated agent subsets per stack (W4 item #10)?
4. **MCP Standardization**: Should all external integrations be MCP servers, or is skill + MCP hybrid acceptable?

---

## Next Steps (Recommended for Implementation)

### Short-term (Tier 2)
1. **Define PR monitoring requirements** — Scope /pr-review command with exact CI check handling logic
2. **Create notion-explorer skill** — Implement pagination enforcement, coverage audit, error handling
3. **Create status-generator skill** — Transform state.json/findings.jsonl into narrative format

### Medium-term (Tier 3)
1. **Implement /pr-review command** — Full PR lifecycle from CI monitoring through merge
2. **Implement /dev-update command** — On-demand status generation for Richard
3. **Set up Notion OAuth** — Configure MCP server in settings, test with harness-doctor

### Long-term (W5+)
1. **Artifact approval pipeline** — Richard reviews and approves status updates before distribution
2. **Status update scheduling** — Auto-generate weekly summaries on cadence
3. **Dashboard integration** — Notion doc with live status tiles, findings summary, trend charts
