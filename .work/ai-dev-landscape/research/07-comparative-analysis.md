# Pass 7: Comparative Analysis — Our Harness vs. The Field

## What We Have That Others Don't

### 1. Beads Issue Tracking with Dependencies
No other personal harness has a git-synced issue tracker with dependency resolution. Claude Task Master (25K stars) decomposes PRDs but doesn't persist across sessions. TaskCreate is session-scoped. agent_farm uses lock files. beads provides `bd ready` (unblocked work), `bd dep add` (dependency chains), cross-session persistence, and multi-agent coordination via git sync. This is a genuine differentiator.

### 2. Tiered Work Routing (Fix/Feature/Initiative/Research)
Most workflows are one-size-fits-all. Harper Reed's spec-driven flow works for greenfield but is overkill for a bug fix. GSD treats every task identically. Our 4-tier system matches workflow complexity to task depth — T1/Fix gets a single-session loop, T3/Initiative gets research-plan-spec-decompose-implement-review. The field is converging on "right-size your workflow" but nobody has formalized it as cleanly.

### 3. Structured Handoffs with Session Continuity
Continuous-Claude-v3 has the most elaborate persistence (PostgreSQL + pgvector + 30 hooks) but it's enterprise-complex. GSD uses fresh context per task (no persistence needed). Our checkpoint files + handoff prompts + memory MCPs hit the middle ground: enough persistence for multi-session work without database dependencies. The handoff prompt as a "context firewall" (read the summary, not the raw notes) is a pattern others are discovering independently.

### 4. Memory Routing (work-log + personal-agent)
Two knowledge graph MCPs with routing rules: cross-project observations → work-log, project-specific patterns → personal-agent. Benchmarks showed single-knowledge-graph systems "couldn't separate the contexts of two projects." Our two-server split directly addresses this. No other personal harness has this architecture.

### 5. Specialist Agent Delegation with Context Seeding
Our CLAUDE.md explicitly directs domain-expert naming ("name agents as domain experts, not process roles") and context seeding protocols. This aligns with CrewAI's finding that "Market Analyst Agent" outperforms "Research Agent" and with Anthropic's finding that sub-agents as context firewalls maintain coherence "for much, much longer."

### 6. Adversarial Evaluation Skill
Two agents argue opposing positions, synthesis produces verdict. No other personal harness has built-in adversarial evaluation. PAL (multi-model proxy) could enable cross-model adversarial evaluation but is a different tool.

### 7. Hook-Based Enforcement Architecture
state-guard, beads-check, review-gate, artifact-gate, pr-gate, post-compact — 6+ hooks that constrain agent behavior at workflow boundaries. This maps to the "Constraining" function in LangChain's harness engineering thesis. Most harnesses have 0-2 hooks; ours has a structured enforcement layer.

## What Others Have That We Don't

### 1. Cost Tracking (Gap: HIGH)
ccost (Go binary), ccusage (Node.js), ccboard (Rust TUI) all parse ~/.claude/projects/ JSONL logs. Power users track input/output tokens, cache hits, model distribution, billing window compliance. We have zero cost visibility. The real prize is cost-per-feature (correlating tokens with beads issues).

### 2. Context Health Monitoring (Gap: MEDIUM)
Van der Herten's status line: green <40%, yellow 40-59%, red 60%+ context usage. Provides visual cue to start fresh before degradation. We have no equivalent. Context health is the single best predictor of session quality.

### 3. TDD Enforcement Hooks (Gap: MEDIUM)
Shankar's "Block-at-Submit" pattern: PreToolUse hook wrapping git commit that runs tests first. Vincent's Superpowers framework enforces RED/GREEN TDD. TDD Guard (nizos) supports Go. Multiple practitioners cite TDD as "the single best quality signal." We have no test enforcement.

### 4. CLAUDE.md Flywheel Automation (Gap: MEDIUM)
Cherny's GitHub Action: `@claude` in PR reviews triggers CLAUDE.md updates. Shankar's: `query-claude-gha-logs | claude -p 'see what the other claudes were getting stuck on and fix it'`. MindStudio's binary eval + skill mutation loop. We update CLAUDE.md manually. The automated version compounds improvements.

### 5. Context Reduction/Virtualization (Gap: MEDIUM-LOW)
context-mode extends sessions from ~30 min to ~3 hours via SQLite FTS5 compression (98% reduction in tool output tokens). Interesting but unvalidated for Go codebases. Node.js dependency doesn't fit our stack.

### 6. Multi-Model Consultation (Gap: LOW)
PAL enables cross-model adversarial evaluation. Gemini CLI provides free-tier second opinions. Neither is urgent but both could improve our adversarial-eval skill.

### 7. Library Doc Injection (Gap: NEGLIGIBLE)
Context7 solves JS framework docs drift. Go's standard library is stable and well-known to models. Not relevant to our stack.

## Where We're Aligned with Best Practice

| Practice | Our Implementation | Validation Source |
|----------|-------------------|-------------------|
| Spec-driven, plan-before-code | T2/T3 plan steps, research steps | Reed, Tane, Osmani, Vincent all converge on this |
| Worktree isolation for parallel work | Teams protocol, subagent delegation | Willison, Claude Squad, native agent teams |
| Hooks for enforcement | 6+ hooks constraining workflow | LangChain harness engineering thesis (constraining function) |
| CLAUDE.md discipline | Modular via .claude/rules/, ~8KB | Under 200 lines/file (optimal), modular (best practice) |
| Sub-agent context firewalls | Domain-expert agent naming, context seeding | HumanLayer finding, Anthropic 90.2% improvement metric |
| External state files as compaction insurance | checkpoint files, handoff prompts, state.json | Shankar "Document & Clear", Tane plan.md, GSD markdown files |
| Progressive disclosure | Skills activate on demand, rules load contextually | Context Engineering Kit, Willison skills insight |
| Centralized coordination (not independent agents) | Lead agent orchestrates subagents | DeepMind: centralized = 4.4x error vs independent = 17.2x |

## Where We Might Be Over-Engineering

### 1. Custom Subagent Orchestration (if native teams suffice)
Native agent teams (Feb 2026) provide shared task lists, inter-agent messaging, dependency resolution. If they stabilize, our custom Teams protocol and context-seeding skill may become redundant. **However**: native teams are experimental, don't support session resumption, and use "significantly more tokens." Our approach is more token-efficient and controllable. **Verdict: Keep for now, monitor native teams maturity.**

### 2. MCP Where CLIs Work
Our MCPs (Serena, work-log, personal-agent) all manage genuinely stateful resources — they pass Shankar's test. No over-engineering here. **Verdict: Current stack is right-sized.**

### 3. Multi-Tier Routing (if most work is features)
If 80%+ of work is T2/Feature, the T1/T3/R tiers add complexity for rare use cases. **However**: the routing is lightweight (a field in state.json) and the tiers genuinely differ in steps. **Verdict: Keep. The complexity cost is minimal; the workflow-matching value is real.**

### 4. Teams Protocol Complexity
The teams-protocol skill defines naming conventions, task schemas, teammate prompts, completion detection, failure handling. For research tasks this pays off. For simpler parallel work, plain subagent calls might suffice. **Verdict: Simplify by making teams optional, not mandatory for all parallel work.**

## Where We Might Be Under-Engineering

### 1. Cost Visibility (CRITICAL gap)
Zero cost tracking. Can't answer "what did that feature cost?" or "is this session burning tokens?" Every power user surveyed tracks costs. ccost (Go binary) is a 10-minute install.

### 2. Security (IMPORTANT gap)
No prompt injection scanning. Multiple CVEs demonstrated real attacks through project files. Lasso hooks (PostToolUse scanning, 50+ patterns) are low-friction, high-value, open source.

### 3. Automated Quality Feedback Loops (IMPORTANT gap)
No flywheel from mistakes → rules → better agents. Cherny and Shankar both automate this. The binary eval + skill mutation pattern is the highest-leverage self-improvement mechanism.

### 4. Context Budget Management (MODERATE gap)
No context health indicator. No per-tool token budgets. No awareness of when sessions are degrading. Research consistently shows degradation starts at 50% and context health monitoring is "trivially useful."

## Framework Patterns We're Missing

| Framework | Pattern | Our Gap | Effort to Extract |
|-----------|---------|---------|-------------------|
| DSPy | Binary eval + prompt compilation | No automated skill optimization | Medium (build eval runner script) |
| PydanticAI | Typed contracts for agent I/O | No schema validation on agent outputs | Low (Go struct unmarshaling) |
| LangGraph | Cost tracking per node | No cost per task/step | Medium (hook + JSONL parsing) |
| CrewAI Flows | Deterministic backbone + LLM steps | Already have this via hooks + skills | None |
| 12-Factor Agents | Own your control flow | Already do this | None |
| HumanLayer | Back-pressure (surface only failures) | Hooks block; could be warning-only | Low (add warning mode to hooks) |
