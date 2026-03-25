# Anthropic Plugins & Self-Usage Patterns

Research date: 2026-03-25
Source: `anthropics/claude-code` repository (GitHub, main branch)

---

## Feature-Dev Plugin (Deep Analysis)

**Author**: Sid Bidasaria (sbidasaria@anthropic.com)

### Seven-Phase Workflow

The feature-dev plugin defines a strict sequential 7-phase workflow for feature development:

| Phase | Name | Purpose | Gate |
|-------|------|---------|------|
| 1 | Discovery | Clarify what needs building | User confirms understanding |
| 2 | Exploration | Launch parallel agents to investigate codebase | Agent findings reviewed |
| 3 | Clarification | Present organized questions about gaps/edge cases | **User answers required** ("DO NOT SKIP") |
| 4 | Architecture | Present 2-3 approaches with trade-off analysis | **User selects approach** |
| 5 | Implementation | Build with codebase conventions | **Explicit approval required** |
| 6 | Review | Launch reviewer agents for quality | User picks which issues to address |
| 7 | Summary | Document accomplishments and next steps | Informational |

### Comparison to Our Tiers

| Aspect | Feature-Dev | Our T2 (Feature) |
|--------|------------|-------------------|
| Phases | 7 sequential | 4 (plan, implement, review, summary) |
| User gates | 3 mandatory approval points | 0 explicit (hook-based enforcement) |
| Exploration | Dedicated phase with parallel agents | Built into plan step |
| Clarification | Explicit separate phase | Implicit in plan |
| Architecture | Multi-option with recommendation | Single plan output |
| State | No persistent state file | state.json with step tracking |

**Key insight**: Feature-dev is _conversation-scoped_ with no persistent state mechanism. It relies entirely on the conversation context to track progress. Our harness persists state to disk, enabling cross-session continuity.

### Specialist Agents

Three agents defined with YAML frontmatter:

**code-explorer** (Sonnet, yellow)
- Tools: Glob, Grep, LS, Read, NotebookRead, WebFetch, TodoWrite, WebSearch, KillShell, BashOutput
- 4-phase methodology: Discovery -> Flow Tracing -> Architecture Analysis -> Implementation Details
- Produces file:line references, execution flows, dependency maps

**code-architect** (Sonnet)
- Same tool set as explorer
- Produces architecture blueprints: patterns with file references, component designs, data flows, phased build sequences
- "Makes confident architectural choices rather than presenting multiple options"

**code-reviewer** (Sonnet, red)
- Confidence-based scoring: 0-100 scale, **only reports issues >= 80 confidence**
- Severity grouping: Critical vs Important
- Reviews against CLAUDE.md guidelines specifically

### Implications
- Our harness has no dedicated "clarification phase" -- we jump from plan to implement. Adding an explicit question-gathering step before architecture could reduce rework.
- The 80% confidence threshold on the reviewer is a strong pattern we already use in our review methodology.
- Their explorer agent is essentially what we do with `/delegate` -- but formalized as a plugin-level agent definition.

---

## Code-Review Plugin (Deep Analysis)

**Author**: Boris Cherny (boris@anthropic.com)

### Multi-Agent Pipeline

The code-review plugin implements a 9-step PR review pipeline:

1. **Eligibility check** (haiku agent): Skip closed, draft, trivial, already-reviewed PRs
2. **CLAUDE.md discovery** (haiku agent): Locate all relevant project guideline files
3. **PR summary** (sonnet agent): View PR and summarize changes
4. **Parallel review** (4 agents simultaneously):
   - 2x Sonnet agents: CLAUDE.md compliance checking
   - 2x Opus agents: Bug detection and logic error hunting
5. **Validation** (subagents): Re-check flagged issues to filter false positives
6. **Filtering**: Retain only validated findings
7. **Terminal output**: Summary of findings
8. **Comment list** (optional, with `--comment` flag)
9. **GitHub posting**: Inline comments via MCP tool

### Key Design Patterns

**Model tiering by task complexity**:
- Haiku for simple yes/no checks (eligibility, file discovery)
- Sonnet for guideline compliance (pattern matching)
- Opus for deep bug detection (reasoning-heavy)

**High-signal-only policy**:
- Flag: compilation errors, definite logic errors, clear CLAUDE.md violations
- Do NOT flag: style concerns, potential issues, linter-catchable problems, subjective improvements

**Deduplication**: "Never post duplicate comments" -- one comment per unique issue.

**Citation format**: Full git SHA links with `L[start]-L[end]` line ranges.

### Comparison to Our work-review

| Aspect | Code-Review Plugin | Our work-review |
|--------|-------------------|-----------------|
| Trigger | Explicit `/code-review` command | Step in workflow |
| Agent count | 4 parallel (2 Sonnet + 2 Opus) | Variable specialist dispatch |
| Model tiering | Yes (haiku/sonnet/opus by task) | No (all agents same model) |
| Validation pass | Yes, separate subagents re-check | No second pass |
| Output | Terminal + optional GitHub inline comments | JSONL findings file |
| Confidence threshold | >= 80 | Severity-based (critical/important/suggestion) |
| False positive handling | Explicit validation step | Manual triage |

**Key insight**: The two-pass validation (flag then validate) is a strong pattern for reducing false positives. Our harness could benefit from a validation sub-step where a second agent confirms findings before they're reported.

---

## Hookify Plugin (Deep Analysis)

**Author**: Not credited in plugin.json

### Architecture

Hookify is the most architecturally sophisticated plugin in the collection. It's a full Python application with:

```
hookify/
  core/
    config_loader.py    # Parses .claude/hookify.*.local.md files
    rule_engine.py      # Evaluates rules against tool inputs
  hooks/
    hooks.json          # Hook registration (4 hook points)
    pretooluse.py       # Pre-execution interceptor
    posttooluse.py      # Post-execution interceptor
    stop.py             # Session stop interceptor
    userpromptsubmit.py # User prompt interceptor
  agents/
    conversation-analyzer.md  # Frustration detection agent
  commands/
    hookify.md          # Main rule creation command
    configure.md        # Interactive enable/disable
    list.md             # List active rules
    help.md             # Help text
  skills/
    writing-rules/SKILL.md  # Documentation for rule format
  examples/
    dangerous-rm.local.md        # Block rm -rf
    console-log-warning.local.md # Warn on console.log
    require-tests-stop.local.md  # Block stop without tests
    sensitive-files-warning.local.md  # Warn on .env edits
```

### Rule Format

Rules are markdown files with YAML frontmatter stored as `.claude/hookify.{name}.local.md`:

```yaml
---
name: block-dangerous-rm
enabled: true
event: bash
pattern: rm\s+-rf
action: block
---

Warning message shown to Claude when rule triggers.
```

### Frustration Signal Detection

The conversation-analyzer agent:
- Scans the last 20-30 messages in reverse chronological order
- Looks for explicit correction requests ("Don't use X", "Stop doing Y")
- Identifies tools that caused issues
- Extracts regex patterns for matching
- Categorizes by severity
- Outputs structured findings for rule generation

### Rule Engine

The `RuleEngine` class supports:

**Condition operators**: `regex_match`, `contains`, `equals`, `not_contains`, `starts_with`, `ends_with`

**Field extraction**: Tool-specific -- Bash `command`, Write `content`, Edit `new_string`, MultiEdit concatenated content, Stop `reason`/`transcript`

**Priority**: Blocking rules take precedence over warning rules. All matching messages are combined.

**Response format**: Different by hook type:
- PreToolUse/PostToolUse: `hookSpecificOutput` with `permissionDecision`
- Stop: `decision` field with `reason`

**Performance**: LRU cache (128 entries) for compiled regex patterns.

**Error handling**: Every hook script exits 0 on error -- hooks never block operations due to their own failures.

### Four Hook Points

| Hook | Script | Event Type | Purpose |
|------|--------|-----------|---------|
| PreToolUse | pretooluse.py | bash, file | Intercept before execution |
| PostToolUse | posttooluse.py | bash, file | Check after execution |
| Stop | stop.py | stop | Gate session termination |
| UserPromptSubmit | userpromptsubmit.py | prompt | Validate user requests |

### Comparison to Our Hooks

| Aspect | Hookify | Our Harness Hooks |
|--------|---------|-------------------|
| Rule storage | `.claude/hookify.*.local.md` (markdown+YAML) | Shell scripts in `hooks/` |
| Rule creation | AI-assisted via conversation analysis | Manual authoring |
| Dynamic rules | Yes, created at runtime | Static, committed to repo |
| Self-improvement | Learns from frustration signals | Manual CLAUDE.md updates |
| Hook types | PreToolUse, PostToolUse, Stop, UserPromptSubmit | PostToolUse (state-guard, beans-check, review-gate, etc.) |
| Language | Python with dataclasses | Shell scripts |
| Condition system | 6 operators, multi-field | Pattern matching in shell |

**Key insight**: Hookify's conversation-analyzer agent that detects frustration signals and auto-generates rules is the closest thing to "self-improving AI behavior" in the plugin ecosystem. Our harness relies on manual CLAUDE.md editing. The auto-generation pattern could dramatically reduce the feedback loop for behavioral correction.

---

## Security-Guidance Plugin (Deep Analysis)

**Author**: David Dworken (dworken@anthropic.com)

### Architecture

Minimal plugin -- a single Python hook with no commands, agents, or skills:

```
security-guidance/
  .claude-plugin/plugin.json
  hooks/
    hooks.json
    security_reminder_hook.py
```

### Hook Configuration

- **Type**: PreToolUse only
- **Triggers on**: Edit, Write, MultiEdit operations
- **Timeout**: 10 seconds

### Security Patterns Monitored (9 total)

| Pattern | Detection Method | Category |
|---------|-----------------|----------|
| GitHub Actions workflow injection | Path check (`.github/workflows/*.yml`) | Command injection |
| child_process.exec | Substring match | Command injection |
| new Function() | Substring match | Code injection |
| eval() | Substring match | Code injection |
| dangerouslySetInnerHTML | Substring match | XSS |
| document.write | Substring match | XSS |
| innerHTML assignment | Substring match | XSS |
| pickle | Substring match | Deserialization |
| os.system | Substring match | Command injection |

### Behavior

- **First encounter**: Blocks execution (exit code 2), shows detailed warning with safe alternatives
- **Repeat encounters**: Silently allows (session-scoped deduplication via state file)
- **State**: `~/.claude/security_warnings_state_{session_id}.json`
- **Cleanup**: 30-day TTL on state files, 10% random chance of cleanup per invocation
- **Disable**: Set `ENABLE_SECURITY_REMINDER=0`

### Key Design Decisions

1. **Block first, then allow**: First time a pattern is seen, it blocks. This forces the developer to acknowledge the risk. Subsequent identical patterns are allowed silently.

2. **Path-based vs content-based**: GitHub Actions uses path detection (any workflow file triggers the warning). All others use content substring matching.

3. **Graceful degradation**: JSON parse failures, missing session IDs -- all result in `sys.exit(0)` (allow).

4. **Codebase-specific guidance**: The `child_process.exec` warning specifically references `src/utils/execFileNoThrow.ts` as the safe alternative -- this is tailored to the claude-code codebase itself.

### Comparison to Our Hooks

| Aspect | Security-Guidance | Our Harness |
|--------|------------------|-------------|
| Hook type | PreToolUse (before execution) | PostToolUse (after execution) |
| Behavior | Block first encounter, then allow | Warn only |
| Patterns | 9 hardcoded security patterns | No security scanning |
| State | Session-scoped dedup | No dedup |
| Scope | File edits only | Step/state enforcement |

**Key insight**: We have no security scanning at all. The block-then-allow pattern is clever -- it forces acknowledgment without becoming annoying. Worth implementing, especially for shell command patterns like `rm -rf`, `chmod 777`, and secrets in code.

---

## Other Plugins (Summary)

### agent-sdk-dev
**Author**: Ashwin Bhat (ashwin@anthropic.com)
**Purpose**: Scaffold and validate Claude Agent SDK applications.
**Pattern**: Command (`/new-sdk-app`) + 2 validation agents (Python and TypeScript verifiers).
**Key feature**: Language-specific validator agents that check SDK integration correctness.

### claude-opus-4-5-migration
**Author**: William Hu (whu@anthropic.com)
**Purpose**: Migrate code and prompts from Sonnet 4.x / Opus 4.1 to Opus 4.5.
**Pattern**: Skill with reference docs (effort estimation, prompt snippets).
**Key feature**: Uses skills system to provide migration knowledge on-demand rather than always-loaded context.

### commit-commands
**Author**: Anthropic (generic)
**Purpose**: Streamline git workflow -- commit, push, PR creation.
**Pattern**: 3 commands: `/commit`, `/commit-push-pr`, `/clean-gone`.
**Key feature**: `/commit-push-pr` does branch creation, commit, push, and PR creation in a single tool-call batch. Uses `allowed-tools` frontmatter to restrict to only git/gh commands.
**Notable**: The command uses `!` backtick interpolation for dynamic context: `!git status`, `!git diff HEAD`, `!git branch --show-current`.

### explanatory-output-style
**Author**: Dickson Tsai (dickson@anthropic.com)
**Purpose**: Adds educational insights about implementation choices (mimics deprecated output style).
**Pattern**: SessionStart hook that injects a system prompt modification via shell script.
**Key feature**: Uses hooks to alter Claude's persona/style at session start. No commands, agents, or skills.

### frontend-design
**Author**: Prithvi Rajasekaran & Alexander Bricken (Anthropic)
**Purpose**: Frontend design skill for UI/UX implementation guidance.
**Pattern**: Single skill (`frontend-design/SKILL.md`).
**Key feature**: Provides design system knowledge to avoid "generic AI aesthetics" -- opinionated about visual design quality.

### learning-output-style
**Author**: Boris Cherny (boris@anthropic.com)
**Purpose**: Interactive learning mode that requests meaningful code contributions at decision points (mimics unshipped output style).
**Pattern**: SessionStart hook (same pattern as explanatory-output-style).
**Key feature**: Instead of writing all code, Claude pauses at decision points and asks the user to contribute code. Educational/pedagogical mode.

### plugin-dev
**Author**: Not credited
**Purpose**: Meta-plugin for creating other plugins. The most comprehensive plugin by file count.
**Pattern**: Command (`/create-plugin`) + 3 agents (creator, validator, reviewer) + 7 skills covering every plugin component type.
**Skills**: plugin-structure, command-development, skill-development, hook-development, agent-development, mcp-integration, plugin-settings.
**Key feature**: This is effectively the "plugin SDK" -- it contains reference docs, examples, validation scripts, and linting tools for every plugin component. The most thorough documentation of the plugin architecture lives here, not in the main README.

### pr-review-toolkit
**Author**: Daisy (daisy@anthropic.com)
**Purpose**: Comprehensive PR review with 6 specialized agents.
**Pattern**: Command (`/review-pr`) dispatches agents based on changed file types.
**Agents**:
- `code-reviewer`: General quality (always runs)
- `comment-analyzer`: Documentation accuracy
- `pr-test-analyzer`: Test coverage quality (rates 1-10 criticality)
- `silent-failure-hunter`: Error handling gaps
- `type-design-analyzer`: Type design quality (rates encapsulation, invariant expression, usefulness, enforcement each 1-10)
- `code-simplifier`: Refactoring for clarity (uses Opus model)

**Key feature**: Conditional agent dispatch -- not all agents run on every PR. The type-design-analyzer's 4-dimensional rating system (encapsulation, invariant expression, usefulness, enforcement) is particularly sophisticated.

### ralph-wiggum
**Author**: Daisy Hollman (daisy@anthropic.com)
**Purpose**: Continuous self-referential AI loops ("while-true loop with the same prompt").
**Pattern**: Stop hook that intercepts session exit + command for setup.
**Key feature**: Uses a Stop hook to block Claude from exiting, feeding the same prompt back repeatedly. Each iteration, Claude can see its previous work (file changes, git history). Includes a `completion_promise` mechanism (a `<promise>` tag in output) to break the loop.
**Notable**: Max iteration safety limit. Designed for well-defined iterative tasks with automatic verification (test suites, linters). Not suitable for judgment-heavy work.

---

## Claude Code Self-Usage

Anthropic uses Claude Code on the claude-code repository itself in several significant ways:

### Custom Commands (`.claude/commands/`)

**triage-issue**: Automated GitHub issue triage
- Uses wrapper scripts (`./scripts/gh.sh`, `./scripts/edit-issue-labels.sh`) for GitHub API access
- Labels-only approach: never posts comments to issues
- Validates scope (filters non-Claude-Code issues as `invalid`)
- Checks for duplicates against open issues
- Applies lifecycle labels (`needs-repro`, `needs-info`) with conservative bias
- Handles comment events: removes stale/autoclose labels on new activity
- Auto-close after 7 days without response for lifecycle-labeled issues

**dedupe**: Duplicate issue detection
- 5 parallel search agents with diverse keyword strategies
- Validation agent filters false positives
- Posts duplicate links via comment script
- Uses haiku agents for cheap pre-checks, sonnet agents for search

**commit-push-pr**: Standard git workflow automation (same as plugin version)

### GitHub Actions Workflows

Anthropic runs **12 workflows** on the claude-code repository:

| Workflow | Trigger | Model | Purpose |
|----------|---------|-------|---------|
| claude-issue-triage | Issue opened, comment created | Claude Opus 4.6 | Auto-triage via `/triage-issue` |
| claude-dedupe-issues | Issue opened, manual dispatch | Claude Sonnet 4.5 | Find duplicate issues via `/dedupe` |
| claude.yml | @claude mentions in issues/PRs/reviews | Claude Sonnet 4.5 | General AI assistance |
| sweep.yml | Twice daily (10am, 10pm UTC) | N/A (Bun script) | Lifecycle timeout enforcement |
| auto-close-duplicates | Daily at 9am UTC | N/A (Bun script) | Close confirmed duplicates |
| issue-lifecycle-comment | Issue labeled | N/A (Bun script) | Post lifecycle comments |
| issue-opened-dispatch | Issue opened | N/A | Event routing |
| lock-closed-issues | Unknown | N/A | Lock stale closed issues |
| log-issue-events | Unknown | N/A | Analytics |
| non-write-users-check | Unknown | N/A | Permission validation |
| remove-autoclose-label | Unknown | N/A | Label cleanup |
| backfill-duplicate-comments | Unknown | N/A | Historical dedup |

### Dogfooding Patterns

1. **Model tiering in production**: Opus 4.6 for triage (needs deep understanding), Sonnet 4.5 for dedup (pattern matching), Sonnet 4.5 for general @claude mentions.

2. **Claude-as-first-responder**: Every new issue gets Claude triage before any human sees it. This is full automation, not assisted triage.

3. **Script wrappers**: Instead of giving Claude direct `gh` CLI access, they wrap it in `./scripts/gh.sh` which presumably adds rate limiting, logging, or permission scoping.

4. **Analytics pipeline**: Statsig integration logs Claude actions (e.g., `github_duplicate_comment_added`) for measuring AI effectiveness.

5. **Labels, not comments**: The triage system deliberately avoids posting comments -- it only manages labels. This avoids noisy bot comments while still routing issues effectively.

6. **Concurrency control**: Workflows use `concurrency: { group: <issue-number> }` to prevent duplicate runs for the same issue.

7. **Lifecycle automation**: Fully automated issue lifecycle -- label -> comment -> timeout -> auto-close. No human intervention required for routine issue management.

### Plugin Architecture as Used Internally

The `.claude/` directory is minimal (3 commands only). Anthropic does NOT use plugins on their own repo -- they use raw commands + GitHub Actions. The plugins are packaged for external consumption, but internally the team uses lighter-weight patterns.

---

## Implications for Our Harness

### High Priority -- Should Adopt

1. **Explicit clarification phase**: Feature-dev's Phase 3 (dedicated question-gathering before design) reduces rework. Our T2 should add a "clarify" step between plan and implement.

2. **Two-pass review validation**: Code-review's pattern of flagging then validating with separate agents dramatically reduces false positives. Our review step should add a validation sub-step.

3. **Model tiering by task**: Using haiku for simple checks, sonnet for pattern matching, opus for deep reasoning. Our harness treats all agent work as same-model. We should tier: lightweight agents for pre-checks, heavyweight for analysis.

4. **Security hook**: We have zero security scanning. The block-first-then-allow pattern with session dedup is immediately adoptable. Start with: `rm -rf`, `chmod 777`, secrets in code, eval patterns.

5. **Frustration-driven rule generation**: Hookify's conversation-analyzer that detects correction patterns and auto-generates rules is the most innovative pattern in the collection. Our manual CLAUDE.md updates could be supplemented with automated behavioral rule extraction.

### Medium Priority -- Worth Exploring

6. **Conditional agent dispatch**: PR-review-toolkit only runs agents relevant to changed file types. Our review currently runs all specialists regardless. Dispatch based on what changed.

7. **Stop hooks for iteration**: Ralph-wiggum's self-referential loop pattern could be useful for our T3 initiatives where iterative refinement is needed. A controlled loop with completion criteria and max iterations.

8. **SessionStart hooks for persona**: The output-style plugins (explanatory, learning) inject behavior modifications at session start. We could use this for tier-specific persona priming.

9. **Confidence scoring on all findings**: Both code-review and feature-dev's reviewer use 0-100 confidence scales with hard cutoffs. Our severity system (critical/important/suggestion) is less precise.

### Low Priority -- Nice to Have

10. **Plugin packaging**: Anthropic's plugin format (plugin.json, commands/, agents/, skills/, hooks/) is clean and distributable. Our harness is monolithic. If we ever want to share components, the plugin format is a good model.

11. **`allowed-tools` frontmatter**: Commands can restrict which tools are available. This is a security/scope mechanism we don't have.

12. **Script wrappers for external tools**: Instead of raw `gh` access, wrapping in scripts that add logging/rate-limiting.

### What We Do Better

- **Cross-session state**: Our `.work/` state persistence is superior to any Anthropic plugin. None of them track state across sessions.
- **Tiered routing**: Our auto-triage into T1/T2/T3/R with step arrays is more sophisticated than feature-dev's one-size-fits-all 7 phases.
- **Issue tracking integration**: Our beans integration gives every task an issue. Anthropic plugins have no task tracking.
- **Handoff protocol**: Our checkpoint/handoff system for session continuity has no equivalent in the plugin ecosystem.
- **Hook enforcement for workflow**: Our state-guard and review-gate hooks enforce workflow discipline. Anthropic's hooks are about tool safety, not workflow enforcement.
