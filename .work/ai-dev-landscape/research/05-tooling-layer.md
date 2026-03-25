# Pass 5: The Tooling Layer -- What's Worth Installing

## Questions Investigated

1. Session multiplexing: Claude Squad vs agent_farm vs native agent teams vs amux vs parallel-code -- which approach is winning?
2. Cost/observability: ccusage vs ccost vs cccost -- clear winner? What metrics do power users track?
3. Security: parry, Dippy, Lasso hooks -- minimum viable security posture?
4. Code navigation: Serena vs Codebase Memory MCP vs tree-sitter approaches -- still best option?
5. Task decomposition: Claude Task Master vs beads vs built-in TaskCreate
6. Alternative coding agents: what are power users running alongside Claude Code?
7. Harness architectures: learnings from OpenHands, SWE-agent, Aider

## Findings

### 1. Session Multiplexing

The landscape stratifies into three tiers by complexity:

**Tier 1: Manual (tmux, git worktrees)**

Claude Code's own docs recommend git worktrees for parallel sessions. Zero overhead, maximum control. The practical ceiling is 5-7 concurrent agents before rate limits, merge conflicts, and review bottleneck eat the gains.

**Tier 2: Managed Sessions (Claude Squad, NTM, amux)**

- **Claude Squad** (6.6K stars, 89% Go): Manages multiple AI coding assistants via tmux + git worktrees. TUI for navigation, diff review, and session management. Supports Claude Code, Codex, Gemini, Aider. Requires tmux + gh. Our stack alignment is strong (Go-native). The key value: workspace isolation via git worktrees prevents branch conflicts.

- **NTM (Named Tmux Manager)**: Cross-platform, adds named panes, broadcast prompts, conflict detection, TUI dashboard. Free, MIT-licensed. Lighter than Claude Squad but less AI-specific.

- **amux (mixpeek)**: Open-source multiplexer for dozens of parallel agents. Web dashboard, auto-context compaction (watchdog at 20% remaining), SQLite kanban to prevent duplicate work. Designed for minimal human intervention -- "industrial" use case.

**Tier 3: Orchestration Frameworks (agent_farm, Multiclaude/Shipyard)**

- **claude_code_agent_farm** (Dicklesworthstone): Framework for 20-50+ parallel Claude Code agents with lock-based file coordination and real-time tmux monitoring. "Agentmaxxing taken to its industrial extreme." Overkill for personal use.

- **Shipyard/Multiclaude**: Supervisor agent assigns tasks to subagents. "Singleplayer" mode (auto-merge PRs) or "multiplayer" (human review). Expensive and experimental. "Multi-agent workflows don't make sense for 95% of agent-assisted development tasks."

**Native: Claude Code Agent Teams (experimental)**

Released February 2026 with Opus 4.6. Architecture: lead session + teammates + shared task list + mailbox messaging. Teammates get their own context windows. Task dependencies auto-resolve. File-level locking prevents overwrites. Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Key limitations: no session resumption for in-process teammates, one team per session, no nested teams, split panes require tmux/iTerm2.

Comparison with subagents: subagents report results back to caller (one-way), agent teams have shared task list with direct inter-agent messaging (multi-way). Agent teams use "significantly more tokens."

Best practices from the docs: 3-5 teammates for most workflows. 5-6 tasks per teammate. Start with research/review before parallel implementation. Avoid same-file edits across teammates.

**Assessment**: Native agent teams are catching up fast. For our harness:
- We already have specialist agent delegation with context seeding -- this maps to subagents, not agent teams.
- Agent teams add value for genuinely parallel exploration (competing hypotheses, multi-domain review).
- Claude Squad is the strongest external option given our Go stack, but native teams may make it redundant within 6 months.
- **Recommendation**: Use native subagents (our current pattern) for most work. Evaluate agent teams for complex multi-domain tasks. Skip external multiplexers unless we need 5+ concurrent agents regularly.

### 2. Cost/Observability

Three tools parse the same data source: `~/.claude/projects/` JSONL session logs.

**ccusage** (ryoppippi): Node.js CLI. Most mature and widely adopted. Parses JSONL logs, aggregates by date with detailed breakdowns. Has `blocks --live` for billing window tracking. Web interface at ccusage.com. **Downside**: requires Node.js runtime.

**ccost** (carlosarraes): Single Go binary, zero dependencies. Multi-currency support (USD, EUR, GBP, JPY, CNY, BRL). Billing-aligned deduplication. Dual caching for sub-second response times. Created as a lighter alternative to ccusage.

**ccboard**: Rust-based TUI and web dashboard. Real-time 500ms file watcher on `~/.claude/`. Shows model distribution across sessions.

**cccost** (badlogic): Instruments Claude Code to track actual token usage and cost. Different approach -- instruments the process rather than parsing logs.

**Built-in**: `/cost` command shows session-level totals. Limited but zero-friction.

**What power users track**:
- Input/output tokens per request
- Cache creation and read tokens (cache hits = major savings)
- Model-specific usage patterns (which model for which task)
- 5-hour billing window compliance
- Cost per task/feature (not just per session)

**Assessment**: For our Go-native harness:
- **ccost is the natural fit**: Go binary, zero deps, multi-currency, fast. Aligns with our stack.
- Alternatively, a custom hook that reads JSONL and appends to `.work/` state would integrate cost tracking directly into our tiered work system.
- **Recommendation**: Install ccost for immediate visibility. Consider building a harness hook that captures per-task cost by reading JSONL at task boundaries (start/end of beads issues).

### 3. Security

**The threat landscape is real.** Multiple CVEs in 2025-2026 demonstrated prompt injection attacks through Claude Code project files (CVE-2025-59536, CVE-2026-21852). Attacks hidden in READMEs, HTML comments, and documentation can hijack agent behavior.

**parry-guard** (vaporif): Rust-based prompt injection scanner. DeBERTa v3 + Llama Prompt Guard 2 as OR ensemble. Tree-sitter AST analysis for data exfiltration detection: network sinks, command substitution, obfuscation (base64, hex, ROT13), DNS tunneling, 60+ sensitive paths, 40+ exfiltration domains. Early development phase.

**Dippy**: AST-based bash command approval. Auto-approves safe commands, prompts for destructive operations. Solves "permission fatigue" without disabling safety. Supports Claude Code, Gemini CLI, Cursor. Addresses a real daily friction point.

**Lasso claude-hooks**: PostToolUse hook scanning tool outputs for prompt injection. 50+ detection patterns across 5 categories: instruction override, role-playing, encoding/obfuscation, context manipulation, instruction smuggling. Deliberately warns rather than blocks (false positive tolerance). 100% open source.

**jedi4ever/context-filter**: Proof of concept protecting CLAUDE.md from prompt injection at the syscall level (macOS-specific).

**Minimum viable security posture**:

1. **Lasso hooks** (low friction, high value): PostToolUse scanning catches injections in fetched content, file reads, and command output. Warning-based approach avoids blocking legitimate work. Install cost: clone + run installer.

2. **Dippy** (quality-of-life + security): Reduces permission fatigue (the #1 cause of users enabling `--dangerously-skip-permissions`) while maintaining safety for destructive commands. Indirect security benefit: users keep safety enabled.

3. **parry-guard** (defense in depth): Heavier, requires model inference. Worth adding if working with untrusted repos or external PRs. The ensemble approach (two models with different blind spots) is well-designed.

**Assessment**: Lasso hooks are the minimum viable security addition. They're lightweight, open-source, and integrate via the hook system we already use. Dippy is a quality-of-life improvement that indirectly improves security. parry-guard is overkill for personal harness use but worth knowing about.

**Recommendation**: Install Lasso hooks. Evaluate Dippy for permission fatigue reduction.

### 4. Code Navigation

**Serena (LSP-backed)**:
- 40+ language support via real language servers
- Symbol-level read/edit, reference finding, cross-file rename
- Understands types, interfaces, call hierarchies
- Requires language server setup per project
- Persistent LSP session = MCP justified

**Codebase Memory MCP (tree-sitter)**:
- 66 languages via tree-sitter parsing
- Persistent knowledge graph (functions, classes, call chains, HTTP routes)
- 99.2% token reduction vs file-by-file reads (benchmarked)
- Single static binary, zero deps
- LSP-style hybrid type resolution for Go, C, C++ (more coming)
- Faster indexing (Linux kernel in 3 min)

**Repomix (tree-sitter + packing)**:
- Packs entire repos into AI-friendly files
- `--compress` uses tree-sitter to extract key elements
- Claude Code plugins available (MCP, commands, explorer)
- Better for one-shot context injection than ongoing navigation
- Nominated for JSNation 2025 Open Source Awards

**Assessment**: Serena remains the best choice for our use case because:
1. LSP provides deeper semantic understanding than tree-sitter (type resolution, interface implementation tracking)
2. We primarily need interactive navigation during development, not batch indexing
3. Serena's symbol-level editing (replace_symbol_body, rename_symbol) is unique -- Codebase Memory is read-only
4. Go has excellent LSP support via gopls

Codebase Memory would add value for: cross-session persistence of codebase understanding, batch analysis of unfamiliar codebases, or if we needed to query structural patterns across a large monorepo. These aren't current needs.

**Recommendation**: Stay with Serena. Monitor Codebase Memory for the persistent knowledge graph feature -- if it matures, it could complement Serena for cross-session codebase understanding.

### 5. Task Decomposition

**Claude Task Master** (eyaltoledano, 25K+ stars):
- Decomposes PRDs into structured tasks with dependencies, complexity scores, subtasks
- MCP server or CLI interface
- Designed for Cursor/Windsurf/Roo, not Claude Code native
- Tasks include dependency arrays, priority, complexity ratings
- Explosive growth since March 2025 launch

**beads (bd)**:
- Git-synced issue tracking with dependencies
- CRUD operations via CLI (`bd create`, `bd update`, `bd dep add`)
- `bd ready` surfaces unblocked work
- Cross-session persistence (survives across weeks)
- Works with multiple agents via git sync

**Built-in TaskCreate (Claude Code)**:
- Native to Claude Code sessions
- Agent teams use shared task list with file-level locking
- Tasks have three states: pending, in-progress, completed
- Dependency resolution automatic
- Session-scoped (doesn't persist across sessions)

**2026 consensus** (from paddo.dev analysis):
- "Tasks for immediate session work, Beads for longer-term project memory -- they're complementary, not competing."
- Task Master excels at PRD-to-task decomposition (planning phase)
- beads excels at cross-session coordination and dependency tracking
- Built-in TaskCreate excels at intra-session agent team coordination

**Assessment**: Our beads + TaskCreate combination is well-positioned:
- beads handles the persistent, cross-session tracking that Task Master and TaskCreate both lack
- TaskCreate handles intra-session agent coordination natively
- Task Master's PRD decomposition could be replicated as a skill that outputs beads issues

**Recommendation**: No changes needed. If we want PRD-to-task decomposition, build a skill that uses the LLM to decompose a spec into `bd create` commands rather than adding Task Master.

### 6. Alternative Coding Agents

**Morph's 15-agent comparison (March 2026) key findings**:

- **Scaffolding > Model**: Same model (Opus 4.5) scored 17 problems apart across different agents on 731 issues. Architecture matters as much as the underlying model.
- **Claude Code**: Best overall. 80.9% SWE-bench Verified (Opus 4.5). 200K context. Terminal-native. $150-200/month heavy usage.
- **Codex CLI**: Speed champion. 77.3% Terminal-Bench 2.0 (GPT-5.3). 240+ tokens/sec (2.5x faster than Opus). Open-source, Rust-built. ~$20/month.
- **Cursor**: Most polished IDE. 360K paying customers. $29.3B valuation. Trust issues after credit-based billing switch.

**Terminal-native alternatives worth knowing**:

- **Aider** (39K stars): Git-native pair programming. Every edit is a commit. Architect mode for planning. Writes 80% of its own code. Best for developers who think in git. BYOM at $3-8/hour.

- **Gemini CLI**: Only major agent with useful free tier (1,000 requests/day, Gemini 2.5 Pro, 1M token context). Native Google Search grounding mid-task. 63.8% SWE-bench (vs Claude's 80.8%). Good for rapid execution, weaker on complex refactoring. Many developers run hybrid: "Claude for complex planning, Gemini for rapid execution."

- **OpenCode** (120K+ stars): Privacy-first. Terminal CLI + desktop app + IDE extension. 5M+ monthly developers.

- **Codex CLI** (OpenAI): Open-source, Rust. Fastest token throughput. Different reasoning style than Claude -- sometimes catches things Claude misses.

**Emerging multi-tool workflow**: Power users are converging on a pattern:
1. **Claude Code** for complex reasoning, multi-file refactors, architecture decisions
2. **Gemini CLI** (free tier) for quick tasks, prototyping, when context grounding helps
3. **Aider** for git-centric workflows, when every change must be a reviewable commit
4. IDE agent (Cursor/Cline) for visual feedback during UI work

**Assessment**: Claude Code remains the right primary agent for our use case (Go, terminal-native, complex harness work). The interesting question is whether adding Gemini CLI as a "second opinion" tool adds value for the free tier alone. Codex CLI's speed advantage matters for batch operations.

**Recommendation**: Keep Claude Code as primary. Consider Gemini CLI for quick tasks and as a free-tier supplement. Monitor Codex CLI for batch/parallel scenarios where throughput matters more than reasoning depth.

### 7. Harness Architectures

**OpenHands (69K stars, Princeton/Stanford)**:
- **Event-stream architecture**: All actions and observations are immutable events. Agent reads event history, produces next atomic action. Enables replay, recovery, and incremental persistence.
- **Stateless event sourcing**: Single conversation state object records all mutable context. Reliable session recovery.
- **Graceful error recovery**: Replaces hard errors with error state transitions. New messages can be processed even after "agent stuck in loop." Recovery resets relevant state variables.
- **SDK composability**: Four packages (SDK, Tools, Workspace, Server). Runs locally by default, sandboxed when needed.
- **Key lesson**: The event-sourced architecture means any session can be replayed from scratch. This is more resilient than our checkpoint-based approach but more complex to implement.

**SWE-agent (Princeton)**:
- **Agent-Computer Interface (ACI)**: Core insight -- interface design affects agent performance as much as the model. Custom LM-centric commands and feedback formats make it easier for the model to navigate, view, edit, and execute code.
- **Key lesson**: The medium is the message. How you expose tools to the agent matters enormously. This validates our skills-based approach: encoding *how* to use tools (not just *what* tools exist) improves outcomes.

**Aider (39K stars)**:
- **Git-native by design**: Commits pending changes before making edits (never lose work). Every AI edit is a commit you can review, revert, or cherry-pick.
- **Multiple chat modes**: Architect mode (planning), code mode (editing), ask mode (questions). Different modes constrain the agent appropriately.
- **Repository pattern recognition**: Aider detects and applies design patterns without being told. Demonstrates that embedding architectural context in the agent's understanding yields better code.
- **Key lesson**: Git as the undo mechanism is powerful. Our conventional commits and specific-file staging are aligned with this philosophy. Aider's automatic commit-before-edit pattern could be implemented as a hook.

**The "Harness Engineering" thesis (March 2026)**:
LangChain's coding agent improved from 52.8% to 66.5% "by only changing the harness, not the underlying model." Four core harness functions:
1. **Constraining**: Architectural boundaries (what agents can't do)
2. **Informing**: Context engineering via machine-readable docs (CLAUDE.md, AGENTS.md)
3. **Verifying**: Deterministic linters, structural tests, LLM-based auditors
4. **Correcting**: Feedback loops for behavior adjustment

Our harness maps cleanly:
- Constraining: hooks (state-guard, beads-check, review-gate, artifact-gate, pr-gate)
- Informing: CLAUDE.md, skills, handoff prompts, checkpoint files
- Verifying: review agents, adversarial evaluation
- Correcting: work-redirect, post-compact re-grounding

**The rippable harness principle**: "Build rippable harnesses designed for model improvements." Over-engineering breaks when capabilities evolve. Start simple, add constraints incrementally, keep provider-agnostic.

## Implications for Our Harness

1. **Session multiplexing**: Our current subagent delegation pattern is sufficient. Native agent teams (when stable) will handle the cases that need true parallel exploration. Skip external multiplexers.

2. **Cost tracking is the biggest gap**. Install ccost (Go binary, zero deps) immediately. Build a hook that captures per-task cost at beads issue boundaries for cost-per-feature visibility.

3. **Security is a real concern, not theoretical**. Install Lasso hooks as minimum viable security. The PostToolUse scanning approach is low-friction and high-value. Evaluate Dippy for permission fatigue.

4. **Serena is still best-in-class** for our interactive code navigation needs. Codebase Memory is interesting for cross-session persistence but not a current need.

5. **beads + TaskCreate is the right task decomposition architecture**. No need for Claude Task Master. Consider a skill for PRD-to-beads decomposition.

6. **Gemini CLI as a free-tier supplement** is worth exploring for quick tasks and second opinions. No commitment needed.

7. **Our harness architecture validates the "harness engineering" thesis**. Our four-function coverage (constrain, inform, verify, correct) is complete. The main improvement vector is better *informing* (richer context engineering) not more *constraining*.

8. **Event sourcing (OpenHands pattern) and commit-before-edit (Aider pattern)** are architecturally interesting but not worth retrofitting. Our checkpoint/handoff approach achieves similar session resilience with less complexity.

9. **TDD Guard** (nizos) is worth evaluating if we want automated TDD enforcement. Supports Go. Integrates via hooks. Blocks implementation without failing tests. Low-friction way to enforce test-first discipline.

## Open Questions

1. **ccost vs custom hook**: Is ccost sufficient, or should we build a hook that ties cost data directly to beads issues and `.work/` task state?

2. **Lasso hooks false positive rate**: How often do Lasso's 50+ patterns trigger on legitimate code (security research, documentation, test fixtures)?

3. **Agent teams maturity timeline**: When will native agent teams exit experimental? Will they support session resumption? This determines whether Claude Squad is worth installing as a bridge.

4. **Gemini CLI integration**: Can Gemini CLI be used as a subagent from Claude Code (via PAL or direct invocation)? Or is it purely a separate-session tool?

5. **TDD Guard for Go**: How well does TDD Guard work with Go's testing conventions? Does it understand table-driven tests? `_test.go` colocation?

6. **Context-mode + Serena**: Would context-mode's compression layer improve our session longevity when Serena returns large symbol trees? Need to benchmark actual token savings.

7. **Cost-per-feature tracking**: No tool currently provides this. Would require correlating JSONL timestamps with beads issue status changes. Is the engineering effort justified by the visibility?
