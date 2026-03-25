# AI-Assisted Dev Landscape — Consolidated Research Notes

## Research Coverage

8 passes completed across 3 parallel research agents + lead synthesis:

| Pass | File | Topic | Agent |
|------|------|-------|-------|
| 1 | `01-agent-frameworks.md` | Agent frameworks — proven patterns, extractable lessons | frameworks-frontier |
| 2 | `02-mcp-ecosystem.md` | MCP ecosystem — durable infrastructure vs demo-ware | mcp-tooling |
| 3 | `03-workflow-archetypes.md` | Workflow archetypes — how power users actually work | workflows-context |
| 4 | `04-context-engineering.md` | Context engineering — the central constraint | workflows-context |
| 5 | `05-tooling-layer.md` | Tooling layer — what's worth installing | mcp-tooling |
| 6 | `06-emerging-frontier.md` | Emerging frontier — what's next | frameworks-frontier |
| 7 | `07-comparative-analysis.md` | Comparative analysis — our harness vs the field | Lead |
| 8 | `08-recommendations.md` | Recommendations — prioritized action list | Lead |

## Cross-Cutting Themes

### 1. Scaffold > Model
The single most validated finding across all passes. Custom scaffolding adds 9.5 pp on SWE-bench Pro. Same model scores 17 problems apart across different harnesses. LangChain improved 14 points by only changing the harness. Our harness engineering is the highest-leverage investment.

### 2. Our Architecture is Validated
Every major framework is converging on patterns we already implement: state persistence (LangGraph = our checkpoints), domain-expert roles (CrewAI = our agent naming), type contracts (PydanticAI = Go structs), deterministic backbone (CrewAI Flows = our hooks + skills), own your control flow (12-Factor = our architecture).

### 3. MCP is Right-Sized
Our 3 MCPs (Serena, work-log, personal-agent) all manage genuinely stateful resources. MCP costs 7-32x more tokens than CLI. Don't add more. Skills beat MCP for knowledge delivery (dozens vs tens of thousands of tokens).

### 4. Cost Tracking is the Biggest Gap
Every power user tracks costs. We have zero visibility. ccost (Go binary) is a 10-minute install.

### 5. The Self-Improvement Flywheel Compounds
Binary eval + skill mutation loops let agents optimize their own instructions. This is the highest-leverage improvement because it compounds: every skill improvement improves all future invocations.

### 6. Optimize for Supervision, Not Trust
Fresh-issue benchmark performance is 18-23%. Agents fail more than they succeed on non-trivial tasks. Make review efficient, not try to eliminate it. The autonomy ceiling is rising but human oversight remains at 80-100% even for experts.

## Key Sources Cited

### Named Practitioners
- Boris Cherny (Claude Code creator): CLAUDE.md flywheel, 259 PRs/30 days, Opus for everything
- Simon Willison: /tmp checkouts, parallel agents, skills > MCP, research repo
- Shrivu Shankar: 13KB CLAUDE.md, token budgets, "Document & Clear", Block-at-Submit
- Boris Tane: annotation cycles, plan.md as shared mutable state
- Harper Reed: spec-first, TDD, waterfall in 15 minutes
- Jesse Vincent: Superpowers framework, architect/implementer, pressure testing
- Addy Osmani: commit-per-task, Claude Code Swarms, self-improving agents
- Freek Van der Herten: context health status line, agent-per-task-type

### Key Research
- Google DeepMind: 17.2x error amplification (independent), 4.4x (centralized), hybrid saves 20% cost
- SWE-bench Pro: 45.9% standardized, 55.4% Claude Code scaffold, 9.5pp scaffold gap
- Anthropic Autonomy Study: experienced users auto-approve 40% but interrupt MORE strategically
- ETH Zurich: LLM-generated instructions hurt performance, cost 20% more tokens
- HumanLayer: hooks surfacing only failures = highest leverage

### Tools Evaluated
- ccost (Go binary, cost tracking) — RECOMMENDED
- Lasso hooks (prompt injection scanning) — RECOMMENDED
- TDD Guard (test enforcement for Go) — EVALUATE
- context-mode (98% token reduction) — WATCH
- Claude Squad (Go-native session multiplexing) — WATCH
- PAL (multi-model proxy) — WATCH
