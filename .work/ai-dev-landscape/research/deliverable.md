# AI-Assisted Dev Landscape — Research Deliverable

## Executive Summary

We surveyed the AI-assisted development landscape across 8 research passes covering agent frameworks, MCP ecosystem, workflow archetypes, context engineering, tooling, emerging frontier, and comparative analysis. **The central finding: our harness architecture is validated by the field.** Every major framework (LangGraph, DSPy, PydanticAI, CrewAI) is converging on patterns we already implement — state persistence, domain-expert agents, progressive disclosure, deterministic backbone with LLM steps. Custom scaffolding adds 9.5 percentage points on SWE-bench Pro, confirming harness engineering as our highest-leverage investment. The three critical gaps are cost tracking (zero visibility today), security (no prompt injection scanning), and an automated quality flywheel (manual CLAUDE.md updates don't compound). We should not adopt any framework, add any MCP servers, or install session multiplexers. Instead, focus on instrumenting what we have and building the self-improvement loop that makes every session better than the last.

---

## Findings

### 1. The Scaffold Is Worth More Than the Next Model

The most validated finding across all research passes. Same model, different scaffold, wildly different results:

- **SWE-bench Pro**: Claude Opus 4.5 scores 45.9% with standardized scaffolding but 55.4% as Claude Code — **9.5 pp from scaffold alone** (Morph, 2026)
- **Cross-scaffold variance**: Up to 15% difference for the same model across scaffolds (Epoch AI)
- **Harness engineering thesis**: LangChain improved from 52.8% to 66.5% **by only changing the harness** — four core functions: constraining, informing, verifying, correcting
- **ETH Zurich**: LLM-generated instruction files hurt performance while costing 20%+ more tokens. Human-written ones improved outcomes by ~4%.

Our harness maps cleanly to all four functions: hooks (constraining), CLAUDE.md + skills (informing), review agents + adversarial eval (verifying), work-redirect + post-compact reground (correcting). Every improvement to the harness compounds across all future work.

### 2. Our Architecture Is Validated — Don't Add Frameworks

The framework landscape is converging on patterns we already implement with filesystem primitives:

| Framework Pattern | Our Implementation |
|---|---|
| LangGraph state persistence + checkpointing | checkpoint files + state.json + git |
| CrewAI domain-expert role decomposition | agent naming convention ("name agents as domain experts") |
| PydanticAI type contracts | Go struct validation (could formalize) |
| 12-Factor Agents "own your control flow" | hooks + skills + explicit flow |
| DSPy prompt compilation | manual CLAUDE.md iteration (could automate) |
| CrewAI Flows deterministic backbone | hooks + skills + work tiers |

The "just use the API" camp has strong evidence: a law firm CTO built 900+ agents with raw chat completions. 45% of LangChain users never shipped; 23% ripped it out. Anthropic officially recommends raw API calls + simple patterns. The 12-Factor Agents manifesto confirms production winners "roll the stack themselves."

**Go ecosystem note**: Google ADK for Go (March 2026), LangChainGo, and Jetify AI SDK exist but offer nothing we can't build more simply with go-openai + goroutines + our existing architecture.

### 3. Multi-Agent: Centralized Coordination or Nothing

Google DeepMind's "Towards a Science of Scaling Agent Systems" (Dec 2025) is definitive:

- Independent agents amplify errors **17.2x**; centralized coordination contains to **4.4x**
- Parallelizable tasks: **+80.9%** with centralized coordination
- Sequential tasks: **-39% to -70%** across all multi-agent variants
- Hybrid "try single first, escalate when needed" saves **20% cost** for 1-12% accuracy gain

Our lead-agent + subagent model IS centralized coordination. Our "try single first" default is exactly right. The Teams protocol should remain optional for genuinely parallel work — don't force multi-agent on sequential tasks.

### 4. MCP Stack Is Right-Sized — Don't Add More

Token economics are stark (Scalekit benchmarks):

| Operation | CLI Cost | MCP Cost | Multiplier |
|---|---|---|---|
| Simple query | 1,365 tokens | 44,026 tokens | **32x** |
| Complex query | 5,010 tokens | 33,712 tokens | **7x** |
| Monthly (10K ops) | $3.20 | $55.20 | **17x** |

Our 3 MCPs all pass Shankar's test — they manage stateful resources where MCP overhead is justified:
- **Serena**: stateful LSP sessions (no CLI alternative)
- **work-log**: persistent cross-project knowledge graph (bidirectional reads/writes)
- **personal-agent**: persistent project-specific knowledge graph

Context7 (JS framework docs) is irrelevant to Go. GitHub MCP is 17x worse than `gh` CLI. PAL is interesting for cross-model evaluation but not urgent.

**Skills beat MCP for knowledge delivery**: dozens of tokens (skill frontmatter) vs tens of thousands (MCP tool definitions). Our 15+ skills architecture is validated by both Willison and Shankar.

### 5. Workflow Archetypes — We Align with the Best

Five dominant patterns among power users, with our alignment:

| Archetype | Key Practitioner | Our Alignment |
|---|---|---|
| Spec-driven (plan before code) | Reed, Tane, Osmani, Vincent | T2/T3 plan steps. Strong. |
| Parallel-agent (coordinated) | Cherny, Willison, Claude Squad | Subagent delegation. Strong. |
| Continuous/autonomous (fresh context) | GSD, Ralph loops | T1/Fix could adopt. Gap. |
| High-volume human-in-the-loop | Cherny (259 PRs/30 days), Shankar | Review hooks. Moderate. |
| CLAUDE.md flywheel (mistake capture) | Cherny, Shankar | Manual only. Gap. |

**Key innovations worth extracting:**
- **Tane's annotation cycles**: plan.md as shared mutable state with inline human annotations (1-6 revision cycles before implementation). Could enrich our T2/T3 plan step.
- **Van der Herten's context health status line**: green/yellow/red at 40/60/80% context usage. Trivially useful.
- **Shankar's Block-at-Submit**: PreToolUse hook wrapping git commit that runs tests first.
- **Cherny's CLAUDE.md flywheel**: GitHub Action captures PR review feedback → CLAUDE.md updates → future sessions avoid the issue.

### 6. Context Engineering — The Binding Constraint

The 200K context window is a lie. Effective capacity:

| Layer | Token Cost | Note |
|---|---|---|
| System prompt + tool definitions | ~15K | Baseline tax |
| CLAUDE.md + rules | ~2-5K | Our ~8KB is in optimal range |
| Skill frontmatter | ~1-2K | Dozens per skill, on-demand bodies |
| MCP tool definitions | 10-50K | Minimize MCPs |
| **Effective working budget** | **80-100K** | Degradation starts at 50% utilization |

**Key findings:**
- **35-minute performance cliff**: every agent's success rate decreases after 35 minutes of human-equivalent task time
- **Lost-in-the-middle effect**: >30% accuracy drop for information in middle positions
- **"Document & Clear" beats auto-compaction** for complex work (Shankar). External state files are the insurance policy.
- **CLAUDE.md sweet spot**: under 200 lines/file, 3-5 code examples (40% correction reduction), modular via .claude/rules/
- **context-mode**: achieves genuine 98% reduction in tool output tokens via SQLite FTS5 (315 KB → 5.4 KB full session). Extends sessions from ~30 min to ~3 hours. Node.js dependency is a concern for our Go stack.

### 7. Cost Tracking Is Our Biggest Gap

Every power user surveyed tracks costs. We have zero visibility.

- **ccost** (Go binary, zero deps): natural fit for our stack. Parses ~/.claude/projects/ JSONL.
- **The real prize**: cost-per-feature — correlating JSONL timestamps with beads issue boundaries.
- **What power users track**: input/output tokens, cache hits, model distribution, billing window compliance, cost per task.

### 8. Security Is a Real Concern, Not Theoretical

Multiple CVEs (2025-2026) demonstrated prompt injection through project files. Attacks hidden in READMEs, HTML comments, documentation.

- **Lasso hooks** (minimum viable security): PostToolUse scanning, 50+ patterns, warning-based, open source. Low friction, high value.
- **Dippy**: AST-based command approval. Reduces permission fatigue (the #1 cause of users disabling safety).
- **parry-guard**: DeBERTa + Llama ensemble. Overkill for personal harness but worth knowing.

### 9. The Self-Improvement Flywheel Compounds

The single highest-leverage initiative across all findings:

1. **Binary eval runner** (50 lines): pass inputs to skill, collect outputs, run pass/fail assertions
2. **Skill mutation loop**: LLM proposes instruction changes, evaluates against test suite, keeps improvements
3. **Overnight optimization**: can run unattended, every improvement compounds

**Proven implementations**: MindStudio binary eval, DSPy prompt compilation (100-500 calls, $20-50), bokan/claude-skill-self-improvement, Cherny's CLAUDE.md flywheel.

### 10. Optimize for Supervision, Not Trust

Benchmark reality:
- SWE-bench Verified: **contaminated** (OpenAI confirmed training data leakage)
- SWE-bench Pro: **~45%** standardized, **~55%** with custom scaffold
- SWE-bench Live (fresh issues): **18-23%**
- Anthropic's own engineers: **80-100% human oversight** maintained

The pattern: not full autonomy, but **supervised autonomy** — humans shift from per-action approval to strategic oversight. Our hook-based architecture (run silently, surface failures) is exactly right. Experienced Claude Code users (750+ sessions) auto-approve 40% but interrupt MORE strategically.

---

## Recommendations

### Do First (< 1 hour total)

| # | Action | Effort | Impact | Source |
|---|--------|--------|--------|--------|
| 1 | Install ccost for cost visibility | 10 min | HIGH | carlosarraes/ccost — Go binary |
| 2 | Install Lasso security hooks | 30 min | MED-HIGH | PostToolUse scanning, 50+ patterns |
| 3 | Add context health status line | 30 min | MEDIUM | Van der Herten's approach |

### Do Soon (1-2 sessions each)

| # | Action | Effort | Impact | Source |
|---|--------|--------|--------|--------|
| 4 | Build /capture-lesson skill (CLAUDE.md flywheel) | 1 session | HIGH | Cherny, MindStudio |
| 5 | Build cost-per-feature hook (JSONL → beads) | 1 session | HIGH | Novel integration |
| 6 | Build binary eval runner for skills | 1-2 sessions | HIGH (compounds) | DSPy pattern, MindStudio |

### Do Next (1 session each)

| # | Action | Effort | Impact | Source |
|---|--------|--------|--------|--------|
| 7 | TDD enforcement hook (Block-at-Submit) | 1 session | MED-HIGH | Shankar, Vincent, TDD Guard |
| 8 | Add code examples to CLAUDE.md | 20 min | MEDIUM | 40% correction reduction finding |
| 9 | Hook warning mode (surface failures only) | 30 min | MEDIUM | HumanLayer back-pressure |
| 10 | Structured handoff extraction | 1 session | MEDIUM | Continuous-Claude ledger format |

### Plan (multi-session)

| # | Action | Effort | Impact | Source |
|---|--------|--------|--------|--------|
| 11 | Self-improving skill pipeline | 3-5 sessions | VERY HIGH | DSPy + eval runner + mutation |
| 12 | Context-mode integration or Go equivalent | 2-3 sessions | MED-HIGH | mksglu/context-mode |
| 13 | Typed agent I/O contracts | 2 sessions | MEDIUM | PydanticAI pattern in Go |

### Don't Do

- **Don't adopt agent frameworks** — our Go + filesystem + git + hooks IS the framework
- **Don't add MCP servers** — current 3 are right-sized, MCP costs 7-32x CLI
- **Don't install session multiplexers** — native teams are catching up, subagents suffice
- **Don't import skills from the ecosystem** — our custom skills encode our conventions

### Watch List

- Native Agent Teams maturity (monthly check)
- MCP Tasks primitive SEP-1686 (quarterly)
- Skill ecosystem convergence (quarterly)
- context-mode Go port or equivalent (monthly)
- Gemini CLI free tier for quick tasks (try for a week)

---

## Open Questions

1. **Self-improvement economics**: The binary eval loop costs $20-50 per optimization run (100-500 LLM calls). At what skill invocation frequency does this pay for itself? Need usage telemetry before investing.

2. **The 45% saturation threshold**: DeepMind found multi-agent hurts when single-agent exceeds 45% baseline accuracy. As models improve, does our entire delegation model become counterproductive?

3. **Context-mode quality for Go**: The 98% compression is validated for web/JS tooling. Does lossy summarization retain enough fidelity for Go type hierarchies and interface implementation chains?

4. **Harness portability**: The finding that Opus 4.6 ranks #33 in its native harness but #5 elsewhere suggests over-fitting risk. Should we test our harness with Gemini/GPT-5 to ensure provider independence?

5. **Fresh context per T1 task**: GSD's insight (Task 50 = Task 1 quality when context is fresh) suggests our T1/Fix tier should use subagent isolation (fresh context) rather than accumulating in the main session. Worth testing.

6. **Annotation cycle support**: Tane's inline plan annotation workflow is a powerful review pattern. Could our T2/T3 plan step include explicit "annotate and revise" checkpoints?

---

## Sources

### Research Notes (project-relative paths)
- `.work/ai-dev-landscape/research/01-agent-frameworks.md`
- `.work/ai-dev-landscape/research/02-mcp-ecosystem.md`
- `.work/ai-dev-landscape/research/03-workflow-archetypes.md`
- `.work/ai-dev-landscape/research/04-context-engineering.md`
- `.work/ai-dev-landscape/research/05-tooling-layer.md`
- `.work/ai-dev-landscape/research/06-emerging-frontier.md`
- `.work/ai-dev-landscape/research/07-comparative-analysis.md`
- `.work/ai-dev-landscape/research/08-recommendations.md`

### Key External Sources
- Google DeepMind: "Towards a Science of Scaling Agent Systems" (arxiv:2512.08296, Dec 2025)
- Anthropic: "Building Effective Agents" guide (Dec 2024)
- Anthropic: "Measuring Agent Autonomy in Practice" (Feb 2026)
- SWE-bench Pro: morphllm.com/swe-bench-pro (Scale AI, Sep 2025)
- 12-Factor Agents: github.com/humanlayer/12-factor-agents
- Boris Cherny: VentureBeat interview, Pragmatic Engineer interview
- Shrivu Shankar: blog.sshh.io — "How I Use Every Claude Code Feature"
- Simon Willison: simonwillison.net — parallel agents, skills, MCP analysis
- Boris Tane: boristane.com — annotation cycle workflow
- LangChain: "Harness Engineering" thesis (March 2026)
- Scalekit: MCP vs CLI token economics benchmark
