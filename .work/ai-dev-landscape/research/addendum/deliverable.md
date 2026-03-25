# Anthropic Repos Addendum — Research Deliverable

## Executive Summary

Surveyed 9 Anthropic repos (claude-code plugins, agent SDK, workshop, cookbook, skills API, MCP Go SDK, MCP spec, reference servers). **The most actionable findings are architectural patterns, not tools to install.** Anthropic's feature-dev plugin has a mandatory clarification phase we lack. Their hookify plugin auto-generates behavioral rules from frustration signals — the automated CLAUDE.md flywheel we identified as our biggest gap. The Agent SDK reveals `can_use_tool` can *rewrite* tool inputs (not just allow/deny), and `UserPromptSubmit` hooks can invisibly inject context on every turn. The MCP Go SDK is production-ready; building a harness-state MCP server is a 1-2 day project. There is no canonical local-agent skill spec — our format is fine.

---

## Finding 1: Feature-Dev's 7-Phase Workflow Reveals Our Gaps

Anthropic's feature-dev plugin defines 7 sequential phases with **3 mandatory user approval gates**:

| Phase | Name | Gate |
|-------|------|------|
| 1 | Discovery | User confirms understanding |
| 2 | Exploration | Parallel agents investigate codebase |
| 3 | **Clarification** | **User answers required ("DO NOT SKIP")** |
| 4 | **Architecture** | **User selects from 2-3 approaches** |
| 5 | **Implementation** | **Explicit approval required** |
| 6 | Review | 4 parallel agents with validation pass |
| 7 | Summary | Document accomplishments |

**vs our T2 (Feature)**: assess → plan → implement → review

**What we're missing:**
- **Dedicated clarification phase**: They gather questions about gaps/edge cases *before* architecture design. We jump from plan to implement. Adding a "clarify" step between plan and implement would reduce rework.
- **Multi-option architecture proposals**: Phase 4 presents 2-3 approaches with trade-off analysis. Our plan step produces a single plan. Presenting options gives the human meaningful choice.
- **Mandatory user gates**: They require explicit user approval at 3 points. Our hooks enforce structural constraints but don't pause for human judgment.

**What we do better**: Cross-session state persistence, tiered routing (their 7 phases are one-size-fits-all), issue tracking integration.

## Finding 2: Two-Pass Review Validation Reduces False Positives

Anthropic's code-review plugin uses a 9-step pipeline:
1. Eligibility check (haiku — cheap)
2. CLAUDE.md discovery (haiku — cheap)
3. PR summary (sonnet)
4. **Parallel review**: 2 Sonnet agents for CLAUDE.md compliance + 2 Opus agents for bug detection
5. **Validation subagents re-check each finding** before reporting
6. Filter to validated findings only

**Key patterns:**
- **Model tiering**: haiku for pre-checks, sonnet for pattern matching, opus for deep reasoning. We use the same model for everything.
- **Two-pass validation**: Flag → validate → report. Separate agents confirm findings before they're surfaced. We report findings directly without a validation pass.
- **Confidence threshold**: Only reports issues with ≥80 confidence score.
- **High-signal-only**: Never flags style, potential issues, or linter-catchable problems.

**Recommendation**: Add a validation sub-step to our review skill where a second agent confirms findings before they enter findings.jsonl.

## Finding 3: Hookify Is the Automated CLAUDE.md Flywheel

The hookify plugin auto-generates behavioral rules from frustration signals:

1. **conversation-analyzer agent** scans last 20-30 messages
2. Detects correction patterns ("Don't use X", "Stop doing Y")
3. Extracts regex patterns for matching
4. Generates `.local.md` rule files with YAML frontmatter:
   ```yaml
   name: block-dangerous-rm
   enabled: true
   event: bash
   pattern: rm\s+-rf
   action: block
   ```
5. Rules enforced via PreToolUse/PostToolUse/Stop/UserPromptSubmit hooks

**Rule engine supports**: regex_match, contains, equals, not_contains, starts_with, ends_with. LRU cache for compiled patterns. Block or warn modes. Session-scoped dedup.

**vs our harness**: We update CLAUDE.md manually. Hookify automates the mistake→rule→prevention cycle. This is exactly the self-improvement flywheel we identified as our highest-leverage gap.

**Recommendation**: Build a `/capture-lesson` skill that runs a conversation analyzer and generates rule files. Can be simpler than hookify (markdown rules in `.claude/rules/` rather than a Python rule engine) but captures the core pattern.

## Finding 4: Security-Guidance Uses Block-First-Then-Allow

9 security patterns monitored via PreToolUse hook on Edit/Write/MultiEdit:

| Pattern | Category |
|---------|----------|
| GitHub Actions workflow files | Command injection |
| child_process.exec | Command injection |
| new Function() | Code injection |
| eval() | Code injection |
| dangerouslySetInnerHTML | XSS |
| document.write | XSS |
| innerHTML assignment | XSS |
| pickle | Deserialization |
| os.system | Command injection |

**Behavior**: First encounter blocks and shows warning with safe alternatives. Subsequent encounters silently allowed (session-scoped dedup via state file). Graceful degradation — on error, allows.

**vs our harness**: Zero security scanning. This is a simple, proven pattern.

## Finding 5: Agent SDK Reveals Powerful Hidden Capabilities

### can_use_tool Rewrites Inputs (Not Just Allow/Deny)

```python
async def my_permission_callback(tool_name, input_data, context):
    if tool_name == "Write" and "/etc/" in input_data["path"]:
        return PermissionResultAllow(updated_input={"path": "/tmp/safe_copy"})
    return PermissionResultAllow()
```

This is **strictly more powerful** than our PostToolUse hooks, which fire after execution and can only warn/block. Proactive input rewriting catches problems before they happen.

### Invisible Context Injection via UserPromptSubmit

The workshop's memory system injects stored context as `additionalContext` on every turn — invisible to the user but visible to the model.

**vs our MCP memory**: Our work-log and personal-agent MCPs require the model to *decide* to query them. Hook-based injection makes "the agent always knows project state" automatic rather than model-dependent.

**Recommendation**: Add a UserPromptSubmit hook that injects current work state (active task, current step, recent findings) as additionalContext. The model gets it without asking.

### Other Notable SDK Features

- **max_budget_usd**: Cost cap per agent invocation ($0.10 for a 4-stage demo with Sonnet). For Tier 3 initiatives spawning many subagents, this catches runaway delegation.
- **rewind_files()**: Per-conversation-turn file checkpointing, independent of git. More granular than our git-based undo.
- **Dynamic model switching**: `set_model("haiku")` mid-session. Start with Opus for planning, switch to Haiku for repetitive execution.
- **disallowed_tools as forcing function**: Block `Read` to force Serena usage. Block `Bash` to force MCP tools.
- **PreCompact hook**: Fires before context compaction — lets you preserve critical information.
- **setting_sources**: Control which config layers load (`["user", "project", "local"]` or `None` for isolation).

## Finding 6: Workshop's Progressive Capability Model

The workshop teaches agent architecture through 4 stages — same task, same code, different config:

| Stage | Toggle | Primitive Added |
|-------|--------|-----------------|
| 0 | base | system_prompt only |
| 1 | ENABLE_TOOLS | @tool + MCP servers |
| 2 | ENABLE_SUBAGENTS | AgentDefinition + Task |
| 3 | ENABLE_MEMORY | hooks + persistence |

**Mapping to our tiers**: Stage 0 = base, Stage 1 = MCP tools, Stage 2 = subagent delegation, Stage 3 = memory MCPs. Our tiers bundle these stages implicitly. The SDK suggests they should be independently toggleable.

**build_options() pattern**: One function maps boolean toggles to all agent capabilities. Single inspectable configuration surface. Our config is scattered across CLAUDE.md, harness.yaml, skills, hooks, commands. A single auditable mapping would be cleaner.

**Edge case philosophy**: Workshop embeds scenarios where the obvious answer is wrong (healthy metrics masking churn, legitimate "duplicate" charges). Agent quality = prompt quality. We should test prompts against adversarial scenarios.

**Key insight**: OpenAI uses *handoffs* (agent A stops, agent B takes over). Anthropic uses *delegation* (orchestrator spawns worker, gets result, continues). Delegation preserves orchestrator control — which is our model.

## Finding 7: No Canonical Local Skill Spec — Our Format Is Fine

Anthropic's "Skills" are a **server-side API feature** (beta) for uploading code execution packages to sandboxed environments. The SKILL.md format supports only `name` and `description` frontmatter. This is fundamentally different from our local markdown-based skills.

Our extensions (`meta.stack`, `meta.version`, `meta.last_reviewed`) are solving a different problem (agent context injection) and are well-suited for it. We are not "non-conformant" because there is no local-agent skill specification to conform to.

The MCP roadmap mentions "investigating a Skills primitive for composed capabilities" as a future extension — but nothing exists yet.

## Finding 8: MCP Go SDK Is Production-Ready

`modelcontextprotocol/go-sdk` v1.4.1 (4,226 stars, 2026-03-13):

**Typed generic tool handlers** auto-generate JSON Schemas from Go structs:
```go
type IssueInput struct {
    Title    string `json:"title" jsonschema:"issue title"`
    Priority int    `json:"priority" jsonschema:"0-4"`
}
mcp.AddTool(server, &mcp.Tool{Name: "create_issue"}, CreateIssue)
```

- All MCP spec versions through 2025-11-25
- 15+ examples, conformance test suites, middleware support
- All transports (stdio, HTTP, SSE, in-memory)
- slog integration, session management, resource subscriptions
- Go 1.25 requirement (bleeding edge but manageable)

**Building a harness-state MCP server is a 1-2 day project** exposing task state as resources and issue operations as tools.

## Finding 9: MCP Tasks Primitive — Don't Build For It Yet

Tasks (experimental, 2025-11-25 spec) are durable state machines:
- States: `working` → `input_required` → `completed`/`failed`/`cancelled`
- TTL-based lifecycle, poll-based orchestration
- Tool-level granularity via `execution.taskSupport`
- `input_required` maps well to our review gates

**Triggers/Events WG** just chartered (2026-03-24). Will define push notifications replacing polling. SEP RFC target: end of April.

**Recommendation**: Keep architecture compatible but don't build for Tasks yet. When it matures, our harness could expose long-running operations as MCP tasks.

## Finding 10: Anthropic Dogfoods Heavily

12 GitHub Actions workflows on claude-code repo:
- **Every new issue**: Claude Opus 4.6 triage before humans see it
- **Duplicate detection**: 5 parallel agents with diverse keyword strategies
- **Labels-only triage**: Never posts bot comments, only manages labels
- **Script wrappers**: `./scripts/gh.sh` around CLI for rate limiting/logging
- **Lifecycle automation**: label → comment → timeout → auto-close
- **Concurrency control**: One workflow per issue number

**Key insight**: Internally they use raw commands + GitHub Actions, not the plugin system. Plugins are packaged for external consumption. Lighter-weight patterns win for their own use.

---

## Prioritized Recommendations

### Immediate (< 1 session)

| # | Action | Source |
|---|--------|--------|
| A1 | Add UserPromptSubmit hook injecting active task state as additionalContext | SDK workshop memory pattern |
| A2 | Add security PreToolUse hook (block-first-then-allow, 9 patterns) | security-guidance plugin |
| A3 | Add `disallowed_tools` to force Serena over Read for Go files | SDK observability agent |

### Short-term (1-2 sessions)

| # | Action | Source |
|---|--------|--------|
| A4 | Build /capture-lesson conversation analyzer (hookify pattern) | hookify plugin |
| A5 | Add review validation sub-step (flag → validate → report) | code-review plugin |
| A6 | Add explicit clarification checkpoint to T2 plan step | feature-dev Phase 3 |

### Medium-term (multi-session)

| # | Action | Source |
|---|--------|--------|
| A7 | Build harness-state MCP server in Go (task state + issues as tools/resources) | MCP Go SDK + memory server pattern |
| A8 | Implement model tiering (haiku pre-checks, sonnet pattern matching, opus reasoning) | code-review plugin |
| A9 | Single auditable config mapping (harness.yaml → capabilities) | SDK build_options() pattern |

### Watch

| # | Item | Timeline |
|---|------|----------|
| W1 | MCP Tasks primitive stabilization | 3-6 months |
| W2 | Triggers/Events WG (push notifications) | 6+ months |
| W3 | MCP-level Skills primitive | Unknown |

---

## Sources

### Research Notes
- `.work/ai-dev-landscape/research/addendum/01-plugins-and-self-usage.md`
- `.work/ai-dev-landscape/research/addendum/02-sdk-and-workshop.md`
- `.work/ai-dev-landscape/research/addendum/03-skills-and-mcp.md`

### Repos Analyzed
- anthropics/claude-code (plugins: feature-dev, code-review, hookify, security-guidance, + 10 others; .claude/ commands; .github/workflows)
- anthropics/claude-agent-sdk-python (type definitions, @tool decorator, can_use_tool, hooks)
- anthropics/agent-sdk-workshop (DESIGN.md, progressive stages, breakout exercises)
- anthropics/anthropic-cookbook (claude_agent_sdk/ notebooks 00-04)
- anthropics/anthropic-cookbook (skills/ — API-level skills, not local agent skills)
- modelcontextprotocol/go-sdk v1.4.1
- modelcontextprotocol/specification (2025-11-25 spec, roadmap, Tasks, Triggers WG)
- modelcontextprotocol/servers (memory, sequential-thinking, filesystem, git, fetch, everything)
