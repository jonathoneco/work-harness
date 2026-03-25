# Agent SDK, Workshop & Cookbook Patterns

Research date: 2026-03-25
Sources: anthropics/claude-agent-sdk-python, anthropics/agent-sdk-workshop, anthropics/anthropic-cookbook (claude_agent_sdk/)

---

## Agent SDK Capabilities

### Type System & Options

The SDK's public API surface (exported from `__init__.py`) is substantial and well-typed. Core configuration types:

**ClaudeAgentOptions** — the single configuration object controlling everything:
- `system_prompt` — custom instructions
- `model` — model selection
- `max_turns` — conversation loop limit
- `max_budget_usd` — cost cap per invocation (checked post-call, may slightly overshoot)
- `cwd` — working directory (Path objects accepted)
- `allowed_tools` / `disallowed_tools` — permission allowlist/blocklist
- `permission_mode` — "default", "acceptEdits", "plan", "bypassPermissions"
- `mcp_servers` — dict of MCP server configs (stdio, SSE, HTTP, or SDK in-process)
- `hooks` — dict mapping event types to HookMatcher lists
- `agents` — dict of named AgentDefinitions for subagent delegation
- `can_use_tool` — async callback for programmatic permission decisions
- `setting_sources` — controls config loading: `["user", "project", "local"]` or None for isolation
- `enable_file_checkpointing` — enables rewind_files() undo mechanism
- `plugins` — local plugin extension system
- `env` — environment variable injection
- `resume` / `continue_conversation` — session persistence

**AgentDefinition** — subagent configuration:
- `description` — brief purpose identifier
- `prompt` — system instructions
- `tools` — tool allowlist (subset of parent's tools)
- `model` — can differ from parent ("haiku" for cheap workers, "opus" for complex reasoning)
- `skills`, `memory_scope`, `mcp_servers` — additional scoping

**Key insight**: `ClaudeAgentOptions` is the *entire* API surface for agent configuration. The workshop's `build_options()` pattern makes this explicit — one function that maps toggles to option fields, fully inspectable.

### @tool Decorator (In-Process MCP)

The `@tool` decorator creates MCP tools that run in the same Python process:

```python
@tool(
    name="search_company_news",
    description="Search recent news coverage about a company",
    input_schema={"type": "object", "properties": {"company": {"type": "string"}}, "required": ["company"]}
)
async def search_company_news(input: dict) -> dict:
    return {"content": [{"type": "text", "text": result}]}
```

Tools are bundled into in-process MCP servers via `create_sdk_mcp_server(name, version, tools=[...])`. When registered as `mcp_servers={"research": server}`, tools become `mcp__research__<tool_name>`.

**Advantages over external MCP servers:**
- Zero subprocess overhead (no stdio pipe, no Docker container)
- Direct Python debugging and type hints
- Same MCP protocol semantics — swap mock for real without agent code changes
- Tool contract is identical; only transport differs

**Token economics**: In-process tools appear identically to the model — same tool_use/tool_result message pairs. No token savings vs external MCP, but latency and reliability improve significantly.

**Comparison to our harness**: We define tools via external MCP servers (Serena, work-log, personal-agent). The SDK's `@tool` pattern suggests value in lightweight in-process tools for things like memory injection, state queries, or validation — operations where subprocess overhead is pure waste.

### Permission Model (can_use_tool)

The `can_use_tool` callback enables fine-grained, programmatic permission control:

```python
async def my_permission_callback(
    tool_name: str,
    input_data: dict,
    context: ToolPermissionContext
) -> PermissionResultAllow | PermissionResultDeny:
```

Three response types:
1. **Allow** — `PermissionResultAllow()` — proceed as-is
2. **Allow with modification** — `PermissionResultAllow(updated_input=modified)` — rewrite tool inputs before execution (e.g., redirect file writes to safe directories)
3. **Deny** — `PermissionResultDeny(message="reason")` — block with explanation to model

The example shows a layered policy:
- Read tools (Read, Glob, Grep) → auto-allow
- Write tools → deny system paths, redirect unsafe paths
- Bash → deny dangerous commands (rm -rf, sudo, chmod 777)
- Unknown tools → interactive user approval

**Key capability**: Input rewriting. The callback can silently redirect a `Write` to a different path, or strip dangerous flags from a Bash command, without the model knowing. This is more powerful than binary allow/deny.

**Comparison to our harness**: We use PostToolUse hooks for enforcement (reactive). The SDK's `can_use_tool` is *proactive* — it intercepts before execution and can modify inputs. Our hooks can't rewrite tool inputs.

### Cost Control (max_budget_usd)

Set via `ClaudeAgentOptions(max_budget_usd=0.10)`. Behavior:
- Budget checked after each API call completes (not mid-call)
- Final cost may slightly exceed limit by one call's worth
- When exceeded: `ResultMessage` with `subtype == "error_max_budget_usd"`
- `ResultMessage.total_cost_usd` reports actual spend

Practical: a full 4-stage workshop demo costs under $0.10 with Sonnet. The tight-budget example ($0.0001) demonstrates graceful failure.

**Comparison to our harness**: We have no cost tracking at all. The SDK makes cost a first-class concern — set budgets per agent invocation, get actual costs in results. For subagent delegation (where costs can multiply), this matters.

### File Checkpointing (rewind_files)

```python
async def rewind_files(self, user_message_id: str) -> None
```

Requirements:
- `enable_file_checkpointing=True` in options
- `extra_args={"replay-user-messages": None}` for replay support
- Uses `UserMessage` UUIDs as checkpoint references

Reverts all file changes back to the state at a specific user message. This is a git-independent undo mechanism — useful when agents make bad edits and you want to roll back without git gymnastics.

**Comparison to our harness**: We rely entirely on git for undo (git stash, git checkout). The SDK's checkpointing is more granular — revert to any conversation turn, not just last commit. Worth considering for our implementation work where agents make speculative changes.

### Model/Permission Switching

The `ClaudeSDKClient` supports mid-session dynamic changes:

```python
await client.set_model("claude-haiku-4-5")  # Switch to cheaper model
await client.set_permission_mode("acceptEdits")  # Relax permissions
```

Also supports `PermissionUpdate` for adding/removing permission rules and directory permissions dynamically.

**Comparison to our harness**: We have no equivalent. Our tier system pre-determines the model, but we can't switch mid-session. The SDK's pattern enables cost optimization (start with Opus for planning, switch to Haiku for execution) and progressive trust (start restricted, relax after validation).

### MCP Server Management

Dynamic MCP server control mid-session:
- `get_mcp_status()` — connection states for all servers
- `reconnect_mcp_server(name)` — retry failed connections
- `toggle_mcp_server(name, enabled)` — enable/disable servers
- `stop_task(task_id)` — terminate running subagent tasks

Four transport types: stdio (subprocess), SSE (server-sent events), HTTP, and SDK (in-process Python). The in-process type eliminates the most common failure mode (subprocess crashes).

### Session Management

Built-in session persistence:
- `list_sessions()`, `get_session_info()`, `get_session_messages()`
- `rename_session()`, `tag_session()`
- Resume via `resume=session_id` or `continue_conversation=True`
- Transcripts stored locally (not on remote servers)

**SDKSessionInfo** includes: ID, summary, timestamps, git branch, working directory.

### Hook Event Types

Ten lifecycle events, each with strongly-typed input:
- **PreToolUse** — intercept before tool execution (allow/deny/modify)
- **PostToolUse** — review after successful execution
- **PostToolUseFailure** — handle tool errors
- **UserPromptSubmit** — inject context before processing user input
- **Stop** — control whether to actually stop
- **SubagentStop** — control subagent termination
- **SubagentStart** — intercept subagent spawning
- **PreCompact** — hook before context compaction
- **Notification** — system notifications
- **PermissionRequest** — intercept permission prompts

Hook outputs support:
- `permissionDecision` — "allow" or "deny"
- `additionalContext` — inject instructions invisibly
- `systemMessage` — user-visible notifications
- `continue_` / `async_` — execution flow control
- `stopReason` — halt explanation

**Key pattern**: `UserPromptSubmit` hook with `additionalContext` for invisible context injection. The workshop's memory system uses this — a hook reads persisted memories and injects them as additional context the model sees but the user doesn't. This is how you build "the agent always remembers your preferences" without cluttering the conversation.

---

## Workshop Architecture Philosophy

### Progressive Capability Model

The workshop uses one consistent task (company briefing on "Tinplate Merchant Systems") across four stages:

| Stage | Toggle | Primitive Added | Observable Change |
|-------|--------|-----------------|-------------------|
| 0 | (none) | system_prompt only | Hedges, admits lack of data |
| 1 | ENABLE_TOOLS | @tool + MCP servers | Grounded answers with dates/numbers |
| 2 | ENABLE_SUBAGENTS | AgentDefinition + Task | Delegated research, cleaner context |
| 3 | ENABLE_MEMORY | hooks + persistence tool | Remembers preferences across sessions |

**Design insight**: Same question, same agent, same code — only configuration changes. This demonstrates that agent capability is a *configuration problem*, not a coding problem.

**Mapping to our tier system**:
- Stage 0 = our base Claude Code with system prompt
- Stage 1 = our MCP tool layer (Serena, knowledge graphs)
- Stage 2 = our subagent delegation (/delegate command)
- Stage 3 = our MCP memory layer (work-log, personal-agent)

Our tiers bundle these stages (Fix = 0+1, Feature = 0+1+2, etc.). The SDK suggests they should be independently toggleable, not tier-locked.

### build_options() Pattern

The workshop's central teaching artifact: a single function that maps boolean toggles to `ClaudeAgentOptions` fields.

```
def build_options():
    options = ClaudeAgentOptions(model=MODEL, system_prompt=SYSTEM_PROMPT)
    if ENABLE_TOOLS:    options.mcp_servers["research"] = research_server
    if ENABLE_SUBAGENTS: options.agents = SUBAGENTS; options.allowed_tools.append("Task")
    if ENABLE_MEMORY:   options.mcp_servers["memory"] = memory_server; options.hooks = memory_hooks
    return options
```

Two implementations exist intentionally:
1. **Guided demo version** — maximally readable, inline toggles, comprehensive comments
2. **Breakouts version** (`_build_options()`) — accepts config modules, validates, maps categories

The workshop deliberately duplicates rather than abstracting, because teaching code and extensible code serve different purposes. "Unified implementations would force compromises."

**Implication for our harness**: Our harness.yaml + skills system is the `config.py` equivalent. But we don't have a single inspectable function that translates config → agent capabilities. Our configuration is scattered across CLAUDE.md, harness.yaml, skill files, and hook scripts.

### Edge Cases & Anti-Patterns

The workshop embeds deliberately tricky scenarios in breakout exercises:

**Customer Support (T-1050)**: Customer claims duplicate charges. Obvious answer: issue refund. Real answer: account is past-due, both charges legitimate. Tests whether the agent verifies before acting.

**Account Intelligence (A-2201)**: Healthy usage metrics (up 40%), but executive sponsor just departed. The churn signal is buried in interaction history, not dashboard numbers. Tests whether the agent synthesizes qualitative + quantitative signals.

**SRE Incident (Checkout)**: Deployment at 11:42 correlates with errors at 12:03. Matches runbook RB-001. Tests whether the agent commits to a hypothesis with confidence, or hedges uselessly.

**Design principle**: "Producing *an* answer differs from producing the *correct* answer when obvious choices mislead." Edge cases are designed so straightforward prompting fails — only verification-focused prompts catch the real situation.

**Anti-patterns identified**:
1. **Too cautious** — escalates everything, defeats the point (customer support)
2. **Too confident** — makes commitments it can't keep (timeline promises)
3. **Surface-level analysis** — reports facts without synthesizing intelligence ("usage is up 40%" vs "usage is up 40% but their champion just left")
4. **Hedging without commitment** — in SRE context, solvable incidents need concrete hypotheses, not "it could be several things"

**Workshop philosophy**: "Teaching through *observation* rather than instruction." Attendees experience edge cases, don't just read about them. The friction-free setup (clone → run in 2 min) maximizes time for the actual learning.

### Tools vs Hooks Distinction

A critical conceptual distinction the workshop hammers repeatedly:

| Aspect | Tool | Hook |
|--------|------|------|
| Trigger | Model chooses to call | SDK fires on lifecycle event |
| Model awareness | Visible in tool list | Invisible to model |
| Timing | Mid-turn, model-directed | Fixed events (PreToolUse, UserPromptSubmit, etc.) |
| Purpose | Capabilities the agent needs | Guardrails, context injection, logging |

Memory requires *both*: a tool (for the agent to decide what to save) and a hook (for automatic context restoration on every turn).

**Comparison to our harness**: We conflate these. Our hooks directory contains enforcement scripts (hook behavior), but our "tools" are external MCP servers (tool behavior). We lack the clean separation where some capabilities are invisible to the model (injected context, guardrails) vs visible (callable tools).

### Main Agent vs Sub-Agent

| Aspect | Main Agent | Sub-Agent |
|--------|-----------|-----------|
| Definition | ClaudeAgentOptions | AgentDefinition |
| Invocation | User via client.query() | Main agent via Task(...) |
| Context | Shared, visible to user | Isolated, private |
| History | Full conversation | Only the passed prompt |
| Return | Streams to user | Single message back |

Sub-agents keep the main agent's context clean. Without them, raw search results flood the context window. With them, only synthesized answers return.

Sub-agents use cheaper models by default ("haiku" for research/fact-checking), and the workshop FAQ confirms they run in parallel when the model emits multiple Task calls simultaneously.

---

## Cookbook Agent Patterns

### Chief of Staff (Notebook 01 / Standalone Agent)

The most fully-realized example. Architecture:

**Configuration surface**:
- Model: claude-opus-4-6
- Allowed tools: Task, Read, Write, Edit, Bash, WebSearch
- `setting_sources: ["project", "local"]` — loads `.claude/` directory configs
- Permission and conversation modes configurable per-call

**CLAUDE.md as persistent memory**: Contains company profile (TechStart Inc), financial position, strategic priorities, organizational structure, and available scripts. This is the agent's "long-term memory" — loaded via `setting_sources=["project"]`.

**Subagent delegation**: Financial Analyst and Recruiter subagents execute specialized Python scripts. The main agent orchestrates and synthesizes.

**Hooks for audit trail**: Post-execution hooks log to an audit directory. This is governance — not just logging, but a compliance trail.

**Flow**: User → slash command expansion → Task delegation → subagent execution → results chain → disk write → hook audit → executive summary.

**Key patterns**:
1. CLAUDE.md as structured context (company profile, not just instructions)
2. setting_sources for filesystem integration (load project configs)
3. Audit hooks for governance
4. Slash commands as user interface (not raw prompts)

### Observability Agent (Notebook 02)

GitHub monitoring via MCP:
- Uses Docker-based GitHub MCP server (`ghcr.io/github/github-mcp-server`)
- `disallowed_tools` to force MCP usage over Bash/gh CLI fallback
- Read-only operation pattern (no Write, no Bash)
- Dynamic tool allowlisting with `mcp__` prefix

**Key pattern**: `disallowed_tools` as a forcing function. Rather than trusting the model to use the right tools, explicitly block the wrong ones. This prevents the model from falling back to `gh` CLI when MCP tools are available.

### SRE Agent (Notebook 03 / Workshop Breakout)

The cookbook version (`sre_mcp_server.py`, 97KB) is the most sophisticated safety implementation:

**Path confinement**: Config editing restricted to `config/` subdirectory via `is_relative_to()` check.

**Command allowlisting**: Shell execution limited to specific command+subcommand combinations:
```python
allowed_commands = {
    "docker-compose": {"up", "down", "ps", "logs", "restart"},
    "docker": {"compose", "ps", "logs"}
}
```

**Container name whitelisting**: Log access restricted to known containers.

**Runbook-guided remediation**: Dangerous actions (restarts, rollbacks) presented as runbook procedures requiring explicit user progression, not auto-executed.

**Safety hierarchy**:
1. Input validation (parameter bounds, type checking)
2. Path confinement (relative_to checks)
3. Command allowlisting (explicit permitted operations)
4. Output escaping (html.escape for generated content)
5. Timeout enforcement (10s caps)
6. Conditional tool registration (tools only exist if credentials are available)

**Workshop version** (config.py): Adds the safety-through-prompting layer — "Don't suggest destructive actions without noting risk and asking confirmation."

### Research Agent (Notebook 00)

Minimal agent demonstrating the baseline:
- Model: claude-opus-4-6
- Tools: WebSearch + Read
- System prompt: enforce citations with source URLs
- Multi-turn via continue_conversation

The simplest useful agent pattern: model + web search + citation discipline.

### Migration Guide (Notebook 04)

Architectural comparison between OpenAI and Anthropic SDKs:

| Aspect | OpenAI | Anthropic |
|--------|--------|-----------|
| Tool schema | Auto-introspected from type hints | Explicit schema declaration |
| Guardrails | Framework decorators (@input_guardrail) | Application code or hooks |
| Loop control | Abstracted (Runner.run → result) | Exposed event stream |
| Session state | In-memory or server-managed | Local disk transcripts |
| Multi-agent | Handoffs (transfer control) | Task delegation (orchestrator stays in control) |
| Observability | Built-in dashboard | OpenTelemetry-native |

**Key distinction**: OpenAI uses handoffs (agent A stops, agent B takes over). Anthropic uses delegation (orchestrator spawns worker, gets result back, continues). The Anthropic pattern preserves orchestrator control — critical for our harness model where the main agent coordinates.

---

## Implications for Our Harness

### Adopt: build_options() as Single Configuration Surface

Our configuration is scattered across CLAUDE.md, harness.yaml, skill files, hook scripts, and command definitions. The SDK's pattern of one inspectable function that maps config → capabilities is cleaner. We should consider a single `harness.yaml` → capability mapping that's auditable in one place.

### Adopt: Invisible Context Injection via Hooks

The `UserPromptSubmit` → `additionalContext` pattern is powerful. Our memory MCP servers (work-log, personal-agent) require the model to decide to read them. A hook-based approach would automatically inject relevant context before every turn — the model gets it without asking. This is how "the agent always knows the project state" should work.

### Consider: Proactive Permission Control (can_use_tool)

Our PostToolUse hooks are reactive — they fire after execution. The SDK's `can_use_tool` fires before and can modify inputs. For safety-critical operations (file writes, bash commands), proactive interception with input rewriting is strictly superior. We can't implement this in pure markdown, but our hook scripts could be enhanced.

### Consider: Cost Tracking per Agent

`max_budget_usd` and `ResultMessage.total_cost_usd` give visibility into what each agent invocation costs. For our tiered work system where Tier 3 initiatives can spawn many agents, cost awareness would help detect runaway delegation. Not critical but valuable.

### Consider: In-Process Tools for Low-Latency Operations

Our MCP tools all run as external processes. For operations like "read current work state" or "inject memory context," the subprocess overhead is wasted. The SDK's `@tool` pattern suggests value in lightweight, in-process equivalents — though this requires us to implement the MCP SDK server pattern in Go rather than Python.

### Defer: File Checkpointing

Our git-based undo (stash/checkout) works well enough. The SDK's per-turn file checkpointing is more granular but adds complexity. Worth revisiting if we implement speculative code generation where agents try multiple approaches.

### Defer: Dynamic Model Switching

The SDK can switch models mid-session (`set_model()`). Our tier system pre-selects the model. Dynamic switching (Opus for planning → Haiku for execution) would optimize costs but adds complexity to our tier model. Consider when cost becomes a concern.

### Key Insight: Configuration Over Code

The workshop's core message: agent capability is a configuration problem. The same orchestration code handles all four stages — only `ClaudeAgentOptions` fields change. Our harness already leans this direction (YAML configs, markdown skills), but we should push further. Every behavioral change should be a config change, not a code change.

### Key Insight: Edge Cases Reveal Prompt Quality

The workshop's deliberately tricky scenarios (hidden churn signals, legitimate "duplicate" charges) demonstrate that agent quality is ultimately about prompt quality. Our tier system focuses on workflow structure, but we should invest more in testing prompts against adversarial scenarios where the obvious answer is wrong.

### Key Insight: Tools + Hooks = Complete Memory

The dual mechanism (tool for writing memories, hook for reading them) is elegant. Our current approach (MCP servers that the model queries on demand) means the model must remember to check. The hook-based injection means it always has the context. We should add UserPromptSubmit-equivalent injection for our work state and memory graph content.

### Pattern: disallowed_tools as Forcing Function

The observability agent blocks Bash to force MCP usage. We could use this pattern to prevent model fallback behaviors — e.g., block `Read` when Serena's `find_symbol` should be used, or block `WebSearch` during offline work sessions.
