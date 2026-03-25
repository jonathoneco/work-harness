# Pass 4: Context Engineering -- The Central Constraint

## Questions Investigated

1. Token budgeting: Context Engineering Kit, context-mode (98% reduction), Shankar's 13KB CLAUDE.md with per-tool token budgets
2. Session persistence: Continuous-Claude-v3 (ledgers+handoffs+PostgreSQL), our harness, GSD (fresh context per task)
3. Compaction strategies: Shankar's "Document & Clear" vs. auto-compaction vs. /compact
4. CLAUDE.md optimization: size limits, structure patterns, the improvement flywheel
5. Skills as context delivery: Willison's insight on skills vs. MCP token efficiency

## Findings

### 1. Token Budgeting

The 200K context window is a lie. Effective capacity is 60-120K tokens before degradation, and baseline consumption in a real monorepo leaves even less.

#### The Baseline Tax

**Source:** [blog.sshh.io/p/how-i-use-every-claude-code-feature](https://blog.sshh.io/p/how-i-use-every-claude-code-feature)

Shankar reports that a fresh session in their monorepo costs ~20K tokens (10% of 200K) just for initial context setup: CLAUDE.md, tool definitions, system prompt. This leaves 180K for actual work -- but given degradation starting at 50% utilization, the effective working budget is closer to 80-100K tokens.

Tool definitions alone consume ~15K tokens. A method was discovered to slim the system prompt by ~45%, recovering ~7,300 tokens by patching the CLI bundle to remove redundant instructions.

#### Shankar's Token Allocation Strategy

**Source:** [blog.sshh.io](https://blog.sshh.io/p/how-i-use-every-claude-code-feature)

Shankar's team allocates a max token count for each internal tool's documentation in CLAUDE.md -- "almost like selling 'ad space' to teams." This forcing function ensures teams simplify their tooling to explain it concisely. Only tools used by 30%+ of engineers get documented in the main CLAUDE.md; everything else goes to product-specific files.

This is essentially a token budget at the organizational level, not just the session level. It recognizes that CLAUDE.md is a shared resource with a carrying capacity.

#### Context Engineering Kit: Progressive Disclosure

**Source:** [github.com/NeoLabHQ/context-engineering-kit](https://github.com/NeoLabHQ/context-engineering-kit)

The Context Engineering Kit implements a plugin architecture where each installed plugin loads only its specific agents, commands, and skills. Skills activate only when invoked, preventing unnecessary information bloat. The kit emphasizes "command-oriented skills with sub-agents over general information skills" to minimize context pollution.

**Key patterns:**
- Granular loading -- skills activate on demand
- Sub-agent isolation -- fresh agent launches prevent context rot
- Filesystem-based memory -- persistent state avoids re-loading into context
- MAKER pattern -- clean-state agent launches + filesystem memory + multi-agent voting during critical decisions

The "15K tokens recovered" claim relates to tool definition overhead, not to the kit itself. The kit's contribution is architectural: organizing capabilities so they load on-demand rather than always-on.

#### context-mode: 98% Reduction via SQLite Virtualization

**Source:** [github.com/mksglu/context-mode](https://github.com/mksglu/context-mode), [mksg.lu/blog/context-mode](https://mksg.lu/blog/context-mode)

context-mode is an MCP server that sits between Claude Code and tool outputs. Instead of dumping full outputs into the context window, it stores raw data in SQLite and returns only summaries.

**Measured compression ratios:**
- Batch command execution: 986 KB -> 62 KB
- Code execution (Playwright snapshot): 56 KB -> 299 bytes
- File processing: 45 KB -> 155 bytes
- Markdown indexing: 60 KB -> 40 bytes
- Full session: 315 KB -> 5.4 KB (98% reduction)

**How it works technically:**
1. Raw data stays in a sandboxed subprocess, never enters context
2. Index tool chunks markdown by headings, keeps code blocks intact
3. Stores chunks in SQLite FTS5 virtual table
4. Search uses BM25 ranking for probabilistic relevance
5. When conversation compacts, indexes events into FTS5 and retrieves only what's relevant

**Session impact:** Session time before slowdown extends from ~30 minutes to ~3 hours.

**Privacy design:** Nothing leaves the machine. SQLite lives in user's home directory. "Dies when you're done." If you don't continue, previous session data is deleted immediately.

**Reality check:** The 98% claim is real for tool output compression. The question is whether the summaries retain enough information for the agent to make correct decisions. For structured data (test results, git diffs, logs), summaries work well. For nuanced code analysis, lossy compression may miss critical details.

### 2. Session Persistence

Three fundamentally different approaches exist, each with distinct tradeoffs.

#### Continuous-Claude-v3: Maximum Persistence via PostgreSQL + Ledgers

**Source:** [github.com/parcadei/Continuous-Claude-v3](https://github.com/parcadei/Continuous-Claude-v3)

The most infrastructure-heavy approach. Architecture:
- **Continuity ledgers** (`CONTINUITY_*.md` in `thoughts/ledgers/`): goal/constraints, progress, key decisions, working files. Load automatically after `/clear`.
- **Handoff files** (YAML in `shared/handoffs/`): current task status, agent outputs, learnings, blackboard state, next-step recommendations.
- **PostgreSQL + pgvector**: 4-table schema for sessions, file claims, archival memory (BGE-large-en-v1.5 vectors), handoffs with embeddings.
- **30 lifecycle hooks**: intercept Claude Code events at UserPrompt, PostToolUse, SubagentStop, pre-compaction, SessionStart/End.
- **32 specialized agents**: scout, debug-agent, oracle (Perplexity), plan-agent, kraken (implementation), phoenix (refactoring), arbiter (tests), warden (review), judge (architecture).
- **TLDR Code Analysis (5 layers):** AST (~500 tokens), Call Graph (+440), CFG (+110), DFG (+130), PDG (+150). Total: ~1,200 tokens vs. ~23,000 for raw files -- a 95% token savings for code context.

**Session persistence mechanism:**
1. Pre-compact detection when context fills
2. Auto-handoff extracts state to YAML
3. `/clear` purges context, preserving state references
4. Daemon spawns headless Claude (Sonnet) to analyze thinking blocks, extract learnings to `archival_memory`
5. Next session recalls via pgvector semantic search

**Assessment:** Impressive engineering, but massive complexity (30 hooks, 32 agents, 109 capabilities, PostgreSQL+pgvector dependency). Effectiveness claims are design goals rather than validated metrics. The TLDR layered analysis is the most technically interesting innovation -- 95% token savings for code context is significant if the analysis is accurate.

#### Our Harness: Checkpoint Files + Handoff Prompts + Memory MCPs

Our approach sits in the middle ground:
- Checkpoint files and handoff prompts bridge sessions
- Memory MCPs (work-log, personal-agent) provide cross-session knowledge persistence
- Step transitions serve as natural compaction boundaries
- No database dependency, no daemon processes

**Advantage over Continuous-Claude:** Simplicity. No PostgreSQL, no pgvector, no daemon. File-based state is portable and debuggable.

**Disadvantage:** No semantic search over past sessions. No automated learning extraction. The handoff prompts capture what we explicitly write, not what the agent "learned" implicitly during the session.

#### GSD: Fresh Context Per Task (No Persistence Needed)

**Source:** [github.com/gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done)

GSD takes the opposite approach: instead of persisting state across a degrading session, kill the session and start fresh. Six persistent markdown files (PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md, PLAN.md, research/) maintain state externally. Each task gets a fresh 200K context window.

**Key advantage:** Eliminates the persistence problem entirely. No need for ledgers, handoffs, or databases if you never accumulate state in-session. The orchestrator maintains 30-40% context utilization during entire phase execution.

**Key disadvantage:** Higher token cost per task (each fresh context reloads baseline information). Tasks can't benefit from within-session learning. Complex cross-cutting work that requires understanding multiple subsystems simultaneously may not fit the "one task, one context" model.

#### Comparative Assessment

| System | Persistence mechanism | Complexity | Token efficiency | Best for |
|---|---|---|---|---|
| Continuous-Claude-v3 | PostgreSQL + pgvector + ledgers + handoffs | Very high (30 hooks, 32 agents) | High (TLDR 95% savings) | Long-running, complex projects |
| Our harness | Checkpoint files + handoff prompts + MCPs | Moderate | Moderate | Multi-session features |
| GSD | Fresh context + persistent markdown files | Low | Low (reloads per task) | Task-focused, autonomous |
| Boris Tane | Single session + plan.md | Minimal | Varies (single session) | Single-session brownfield |

### 3. Compaction Strategies

Three schools of thought, with evidence supporting different approaches for different scenarios.

#### Shankar's "Document & Clear" (Preferred)

**Source:** [blog.sshh.io](https://blog.sshh.io/p/how-i-use-every-claude-code-feature)

Shankar's team explicitly avoids auto-compaction and `/compact`, documenting three workflows:

1. **`/compact` (avoided):** "Opaque, error-prone." You don't control what gets kept or discarded.
2. **`/clear` + `/catchup`:** Simple restart with git branch file reading. Works for straightforward continuations.
3. **"Document & Clear" (preferred):** Agent saves progress to markdown, clears state, resumes with external memory. Used for complex features that need nuanced state preservation.

**Rationale:** Auto-compaction is a black box. You don't know what it kept, what it lost, or how it summarized. By explicitly documenting state before clearing, you control the information that bridges sessions.

#### Auto-Compaction (Boris Tane's Experience)

**Source:** [boristane.com](https://boristane.com/blog/how-i-use-claude-code/)

Tane runs single long sessions (research through implementation) and reports no significant performance degradation. He attributes this to Claude's auto-compaction and the persistent `plan.md` file surviving compression. The external plan document serves as an anchor -- even if context degrades, the plan remains the source of truth.

**Key insight:** If your critical state lives in external files (plan.md, research.md), auto-compaction is less risky because the agent can always re-read those files. The danger is when critical state lives only in the conversation history.

#### Our Harness: Step Transitions as Compaction Boundaries

Our current approach uses step transitions as natural compaction boundaries, with handoff prompts bridging the gap. This is structurally similar to Shankar's "Document & Clear" but triggered by workflow milestones rather than context pressure.

**Assessment:** Our approach is sound. The key improvement would be making the handoff prompt capture more systematic -- less "what I remember" and more structured extraction (decisions made, files modified, patterns discovered, remaining work).

#### Evidence-Based Recommendations

The research suggests a hybrid approach:
1. **Never rely solely on auto-compaction** for complex work (Shankar's position is well-supported)
2. **External state files are the best insurance** against compaction loss (Tane, GSD, Continuous-Claude all agree)
3. **Step transitions are natural compaction points** (our approach is validated by GSD's milestone boundaries)
4. **Context health monitoring** is essential for knowing when to compact (Van der Herten's status line approach)

### 4. CLAUDE.md Optimization

#### Size and Structure

**Source:** [code.claude.com/docs/en/best-practices](https://code.claude.com/docs/en/best-practices), [institute.sfeir.com](https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/optimization/)

Optimal parameters from multiple sources:
- **Size limit:** Under 50KB total, under 200 lines per file. Unstructured 300-line CLAUDE.md consumes 4,500 tokens vs. 1,800 after optimization (60% reduction).
- **Code examples:** 3-5 code examples reduce correction requests by 40%. "A 5-line example is more effective than 20 lines of explanation."
- **Modular structure:** Segment directives into `.claude/rules/` files for context-specific activation. This provides progressive disclosure at the rule level.
- **Context utilization warning:** Claude's output starts degrading at 20-40% of the window, not at the limit. Earlier instructions get less attention weight as context fills.

**Anti-patterns (from Shankar):**
- Don't @-mention extensive docs (causes context bloat)
- Never use negative-only constraints ("Never use X flag") -- they're harder for LLMs to follow
- Pitch *why and when* agents should read supplementary files: "For complex usage or if you encounter FooBarError, see path/to/docs.md"

#### The Improvement Flywheel

**Source:** [glenrhodes.com](https://glenrhodes.com/claude-md-pattern-for-persistent-ai-agent-improvement-in-software-development/), [VentureBeat (Cherny)](https://venturebeat.com/technology/the-creator-of-claude-code-just-revealed-his-workflow-and-developers-are)

The flywheel: Bugs -> Improved CLAUDE.md/CLIs -> Better Agent -> Fewer Bugs -> ...

**Cherny's implementation:**
- Single shared CLAUDE.md checked into git, updated multiple times weekly
- GitHub Action: `@claude` in PR reviews triggers CLAUDE.md update
- "Human spots issue, Claude updates the rules, future Claude sessions avoid the issue entirely"
- Personal CLAUDE.md contains just two lines pointing to the team's shared document

**Shankar's enterprise variant:**
- Run `query-claude-gha-logs --since 5d | claude -p 'see what the other claudes were getting stuck on and fix it'`
- Analyze agent failures across the organization to identify systematic improvements
- Data-driven flywheel: aggregate failure patterns -> update rules -> measure improvement

**The simplest version:** After any correction, update a lessons file. Agent reviews lessons at session start. This is externalized memory with feedback discipline.

#### Our CLAUDE.md Assessment

Our current CLAUDE.md is ~8KB across global + project files. This is within the optimal range. The modular `.claude/rules/` structure provides progressive disclosure. However, we lack:
- A systematic flywheel for capturing mistakes into rules
- Per-tool token budgets (Shankar's innovation)
- Code examples for common patterns (the 40% correction reduction finding)

### 5. Skills as Context Delivery

#### Willison's Insight: Skills vs. MCP Token Economics

**Source:** [simonwillison.net/2025/Oct/16/claude-skills](https://simonwillison.net/2025/Oct/16/claude-skills/)

The core argument: MCP tools are token-expensive; skills are token-cheap.

**MCP cost:** "GitHub's official MCP on its own famously consumes tens of thousands of tokens of context." Each MCP tool definition must be loaded into context for the model to know how to call it. Multiple MCPs compound this overhead.

**Skills cost:** "Each skill only takes up a few dozen extra tokens, with the full details only loaded in should the user request a task that the skill can help solve." At session start, only the YAML frontmatter (title + description) loads. The full skill body loads on-demand.

**The deeper point:** "Almost everything I might achieve with an MCP can be handled by a CLI tool instead. LLMs know how to call `cli-tool --help`, which means you don't have to spend many tokens describing how to use them."

Skills have the same advantage as CLI tools, but without needing to implement a CLI tool -- "they can drop a Markdown file in describing how to do a task instead, adding extra scripts only if they'll help make things more reliable or efficient."

#### Is This Strictly Better?

For non-interactive tools, skills are strictly better than MCP on token economics:
- Dozens of tokens (skill frontmatter) vs. tens of thousands (MCP tool definitions)
- On-demand loading vs. always-loaded
- No server process, no protocol overhead, no connection management

**Where MCP still wins:**
- **Real-time data access** (database queries, API calls, live system state) -- skills can't replace actual tool invocation
- **Stateful interactions** (Serena's LSP connection, persistent database connections) -- skills are stateless
- **External service integration** (GitHub, Slack, calendar) -- requires actual API calls

The key distinction: MCP is for **tool access** (doing things), skills are for **knowledge delivery** (knowing how to do things). When a skill can express "use this CLI tool with these flags," it saves the MCP overhead while achieving the same result.

#### shareAI-lab Reverse Engineering

**Source:** [github.com/shareAI-lab/learn-claude-code](https://github.com/shareAI-lab/learn-claude-code)

shareAI-lab reverse-engineered Claude Code v1.0.33 (50,000+ lines of obfuscated JS/TS). Their "learn-claude-code" project rebuilds a nano agent framework in Bash, demonstrating the core mechanisms: structured planning (TodoManager), context compression (3-layer compact), file-based task persistence with dependency graphs, team coordination (JSONL mailboxes), and git worktree isolation.

This confirms that the internal architecture matches the external best practices: progressive disclosure, context isolation, and file-based state management are fundamental to how Claude Code itself works.

#### diet103 Infrastructure Showcase

**Source:** [github.com/diet103/claude-code-infrastructure-showcase](https://github.com/diet103/claude-code-infrastructure-showcase)

A practical showcase of skill auto-activation, hooks, and agents for a real project (React 19, TypeScript, MUI, Prisma, Express, Docker). Demonstrates specialized agent definitions (code-architecture-reviewer, documentation-architect) with domain-specific expertise built into skill files.

Validates the pattern: skills as domain-expert containers with on-demand activation.

### Cross-Cutting Theme: The Context Budget Framework

Synthesizing across all sources, the emerging best practice is a layered token budget:

| Layer | Typical cost | Optimization |
|---|---|---|
| System prompt + tool definitions | ~15K tokens | Patch CLI to remove redundancy (45% reduction possible) |
| CLAUDE.md + rules | ~2-5K tokens | Keep under 200 lines, use examples not explanations |
| Skill frontmatter (all skills) | ~1-2K tokens | Dozens of tokens per skill, on-demand body loading |
| MCP tool definitions | 10-50K tokens | Minimize MCPs; prefer skills + CLI for knowledge |
| Baseline working context | 20-30K total | Leaves 170-180K for work |
| Effective working budget (before degradation) | 80-100K | Start fresh or compact at 50-60% utilization |

This framework explains why Shankar runs `/context` mid-session, why Van der Herten's status line turns red at 60%, and why GSD spawns fresh contexts per task.

## Implications for Our Harness

### Strengths already in place
- **Modular CLAUDE.md** with `.claude/rules/` provides progressive disclosure at the rule level
- **Skills system (15+ slash commands)** aligns with Willison's token-efficient pattern
- **Checkpoint/handoff pattern** matches the "Document & Clear" approach Shankar recommends
- **Step transitions as compaction boundaries** is validated by GSD's milestone model
- **Memory MCPs** provide cross-session persistence without database dependencies

### Actionable improvements

1. **Context health monitoring:** Implement a context usage indicator. Van der Herten uses a shell script in a status line; we could do the same in our terminal environment. Green/yellow/red at 40/60/80% would provide actionable cues.

2. **CLAUDE.md flywheel automation:** After sessions where corrections were needed, capture "what Claude got wrong" into `.claude/rules/` or CLAUDE.md. The simplest version: a `/capture-lesson` command that appends to a lessons file. The sophisticated version: analyze session logs for correction patterns.

3. **Token budget awareness:** Add a note to our CLAUDE.md about token economics -- which MCPs are loaded, what the baseline cost is, when to avoid @-mentioning large files. We currently use Serena MCP which provides real value (LSP access) but has token cost; we should ensure it's worth the budget.

4. **Per-tool token budgets in CLAUDE.md:** Adopt Shankar's pattern of allocating max token counts per documented tool. For our harness, this means being disciplined about how much space beads, work commands, and agent templates consume in instructions.

5. **Evaluate context-mode for long sessions:** The 98% reduction in tool output size could extend our effective session length from ~30 minutes to ~3 hours. This is particularly relevant for T3/Initiative tasks that span long sessions. The SQLite dependency is minimal (single file, local only). However, it's a Node.js MCP server, which may not fit our Go-native preference.

6. **Skills over MCPs where possible:** Audit our MCP usage. Anywhere we're using an MCP purely for knowledge delivery (not tool access), consider replacing with a skill. This preserves context budget for MCPs that need real-time data access (Serena, memory servers).

7. **Structured handoff extraction:** Formalize what our handoff prompts capture: decisions made, files modified, patterns discovered, mistakes made, remaining work. This mirrors Continuous-Claude's ledger format without the infrastructure overhead.

### What to avoid

- **Continuous-Claude-v3's complexity:** 30 hooks, 32 agents, PostgreSQL+pgvector is enterprise infrastructure masquerading as developer tooling. The TLDR code analysis (5-layer, 95% token savings) is interesting but unvalidated, and the maintenance burden is disproportionate for a personal harness.
- **Patching the CLI bundle:** The 45% system prompt reduction by patching Claude Code internals is clever but fragile -- breaks on every update.
- **Over-investing in auto-compaction avoidance:** Shankar's "Document & Clear" is the gold standard, but for T1/Fix tasks, auto-compaction is fine. Match the strategy to the tier.

## Open Questions

1. **context-mode for Go/terminal-native environments:** context-mode is Node.js/npm. Is there a Go-native equivalent, or is the MCP protocol overhead acceptable for the context savings?

2. **TLDR code analysis viability:** Continuous-Claude's 5-layer analysis (AST -> Call Graph -> CFG -> DFG -> PDG) claims 95% token savings. Could we implement a lightweight version using Serena's symbol overview? Serena already provides AST-level information; adding call graph data could be high-value.

3. **Optimal CLAUDE.md size for our workload:** We're at ~8KB across files. Shankar's team is at 13KB (growing to 25KB) for a monorepo. Is there a diminishing-returns threshold where more instructions actually hurt? The research says under 200 lines per file, but our modular structure may change the math.

4. **Skills marketplace economics:** With the Claude Code skills marketplace active, should we publish our harness skills? The token efficiency argument suggests skills will become the dominant way to share capabilities.

5. **Compaction timing for tiered work:** Should T1/Fix tasks use aggressive compaction (or fresh contexts), T2/Feature use "Document & Clear" at step transitions, and T3/Initiative use explicit ledger-style handoffs? The research supports differentiated strategies by task complexity.

6. **MCP token audit:** How many tokens do our current MCPs (Serena, work-log, personal-agent) consume at baseline? Running `/context` would tell us, but we should track this systematically and consider whether each MCP earns its token budget.
