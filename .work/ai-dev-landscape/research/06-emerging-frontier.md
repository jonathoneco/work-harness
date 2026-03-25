# Pass 6: Emerging Frontier

## Questions Investigated

1. Agent-native codebases — what does code designed for agent maintenance look like?
2. Self-improving harnesses — the bugs-to-CLAUDE.md flywheel, can it be automated?
3. Skill/hook ecosystems — is a real sharing ecosystem forming?
4. The autonomy ceiling — does single-agent consistently beat multi-agent? Permanent or temporary?
5. Benchmark reality — what do contaminated benchmarks and fresh-issue performance mean for harness design?

## Findings

### 1. Agent-Native Codebases

**Simon Willison's research repo** (github.com/simonw/research) is the canonical example: 81 projects where every single line of text and code was written by an LLM (primarily Claude Code and Codex). Projects span web technologies, database benchmarks, security research, performance analysis, and CLI tools. Prompts and transcripts are preserved in PRs and commits, creating a fully auditable agent-authored codebase.

**What agent-maintained code looks like:**
- Each project is self-contained in its own directory — isolation by default
- Explicit documentation is embedded inline rather than in separate README files
- Verification procedures are part of the project specification, not afterthoughts
- Projects are disposable research artifacts, not long-lived production systems

**Willison's parallel coding agent workflow** (Oct 2025): He runs multiple agents simultaneously — Claude Code on Sonnet 4.5, Codex CLI on GPT-5-Codex, Codex Cloud for async tasks launched from his phone. Creates fresh checkouts into `/tmp` for isolation rather than using git worktrees. Runs agents in YOLO mode (no approvals) for low-risk tasks. His key insight: **"The fundamental bottleneck remains code review, not agent generation speed."** Code that started from your own specification is far less effort to review than unexpected code.

**Jesse Vincent's architect pattern** (Sep 2025): An architect agent iterates on a plan, which is then reviewed and implemented by fresh Claude Code instances. This maps directly to our Teams protocol with a plan-mode lead and implementation agents.

**The parallel agent explosion** (Feb 2026): Every major tool shipped multi-agent simultaneously — Grok Build (8 agents), Windsurf (5 parallel agents), Claude Code Agent Teams, Codex CLI (Agents SDK), Devin (parallel sessions). This validates the pattern but also creates coordination challenges.

**Implication for agent-native code design**: Code written for agent maintenance should be modular (one concern per file), heavily documented with inline context, have comprehensive tests as the verification mechanism, and use structured formats (JSON > Markdown) for any metadata agents need to read/write. Our harness's emphasis on checkpoint files, structured state.json, and isolated work directories already follows this pattern.

### 2. Self-Improving Harnesses

**The bugs-to-CLAUDE.md flywheel is real and being automated.** Multiple implementations exist:

**bokan/claude-skill-self-improvement** (GitHub): Claude analyzes its own conversation history, identifies what went wrong, and generates CLAUDE.md corrections. This is the direct flywheel: mistake → record → prevent recurrence.

**MindStudio binary evals approach**: Write explicit pass/fail assertions about what good output looks like, then let an autonomous agent run the improvement loop — including overnight while you sleep. A testing harness (50 lines of Python) passes test inputs to your skill, collects outputs, runs assertions, returns pass/fail. The agent then mutates the skill instructions, measures improvement, keeps the better version, and iterates. This is DSPy's prompt compilation pattern without DSPy.

**Addy Osmani's synthesis** (addyosmani.com/blog/self-improving-agents): Documents four persistence channels for the flywheel: git commit history (code diffs), progress logs (chronological), task state files (JSON tracking), and AGENTS.md/CLAUDE.md (semantic knowledge base). The compound learning principle: "each improvement should make future improvements easier." Proven techniques include granular task breakdown with pass/fail criteria, automated validation loops (tests, types, linting as first-class feedback), and context injection via curated files. Still experimental: vector database retrieval for semantic memory, multi-agent swarms, fully autonomous feature generation.

**Christopher Allen's bootstrap seed prompt**: A ~1400 token prompt in .claude/CLAUDE.md bootstraps Claude Code into a self-improving system — capturing learnings, extracting patterns, evolving configuration, getting "meaningfully better with each session."

**What's proven vs theoretical:**
- **Proven**: Recording mistakes in structured files → reduced recurrence. Binary eval loops for skill quality. Test-gated improvement cycles.
- **Theoretical**: Fully autonomous improvement without human review. Vector-based semantic memory for pattern matching. Cost-effective overnight optimization runs.

**The gap in our harness**: We have the manual version (update CLAUDE.md when we notice issues) but not the automated version. Implementing a binary eval runner that iterates on skill instructions would be the single highest-leverage self-improvement mechanism.

### 3. Skill/Hook Ecosystems

**The ecosystem is large but fragmented.** Multiple competing aggregation repos:

- **awesome-claude-code-toolkit** (rohitg00): 135 agents, 35 curated skills (+400K via SkillKit), 42 commands, 150+ plugins, 19 hooks, 15 rules, 7 templates, 8 MCP configs. V1.9.0 (March 2026) added selective install architecture.
- **awesome-agent-skills** (VoltAgent): 1,000+ agent skills compatible with Claude Code, Codex, Cursor, Gemini CLI, and others.
- **antigravity-awesome-skills**: 1,304+ installable agentic skills with CLI installer and bundles.
- **Multiple** awesome-claude-skills repos (travisvn, ComposioHQ, BehiSecc) with overlapping content.

**Is a real sharing ecosystem forming?** Yes and no.

**Yes**: The raw numbers are impressive — 69K+ skills, 100K+ GitHub stars on the main Claude Code project, cross-tool compatibility emerging (skills work across Claude Code, Cursor, Codex, Gemini CLI). The selective-install architecture in v1.9.0 suggests maturation from "dump everything" to "curated installation."

**No**: Most skills are project-specific prompt snippets, not composable building blocks. There's no package manager, no versioning, no dependency resolution, no testing infrastructure. The "400K via SkillKit" number likely inflates thin wrappers around API calls. The fragmentation across 5+ competing repos suggests the ecosystem hasn't converged on standards.

**The enforcement layer is more promising**: Hooks that block unsafe operations, enforce worktree isolation, and gate on test passage are more universally valuable than project-specific skills. Our harness's hooks (state-guard, beads-check, review-gate, artifact-gate, pr-gate, post-compact) represent this more structured approach.

**Implication**: Don't try to consume the skill ecosystem wholesale. Cherry-pick specific hooks and enforcement patterns that solve universal problems. Our custom skills built for our workflow are more valuable than generic imported ones because they encode our specific conventions and constraints.

### 4. The Autonomy Ceiling

**Anthropic's empirical data** (Feb 2026, "Measuring Agent Autonomy in Practice") analyzed millions of interactions across Claude Code and their API:

- New users (<50 sessions): ~20% use full auto-approve
- Experienced users (750+ sessions): >40% use full auto-approve
- **The interruption paradox**: Experienced users interrupt Claude MORE (9% vs 5%) despite approving more. They shifted from per-action approval to strategic monitoring with selective intervention.
- 99.9th percentile turn duration nearly doubled from Oct 2025 to Jan 2026 (under 25 min → over 45 min)
- Claude's success rate on challenging tasks doubled from Aug to Dec 2025
- Human interventions per session dropped from 5.4 to 3.3
- Claude itself asks for clarification over 2x as frequently as humans interrupt

**The "deployment overhang"**: Models can handle significantly more autonomy than users currently grant. This suggests the ceiling is more about trust calibration than capability limitation.

**The DeepMind evidence on the multi-agent ceiling** (covered in Pass 1, but the frontier question): Multi-agent consistently degrades sequential reasoning by 39-70%. But for parallelizable tasks, centralized multi-agent achieves +80.9%. The ceiling isn't "single agent always wins" — it's "architecture must match task structure."

**Anthropic's 2026 Agentic Coding Trends Report findings**:
- Developers use AI in 60% of work but fully delegate only 0-20% of tasks
- Anthropic's own engineers maintain active human oversight on 80-100% of tasks
- Rakuten achieved 99.9% accuracy on 12.5M-line codebase modifications in 7 autonomous hours
- TELUS ships engineering code 30% faster, saving 500K+ hours

**The autonomy frontier**: The ceiling is moving up steadily. The pattern is clear — not full autonomy, but **supervised autonomy** where humans shift from per-action approval to strategic oversight. Our harness's review-gate hooks and beads-check enforcement are exactly the right architecture for this: let agents work autonomously within guardrails, intervene strategically when gates fire.

**Emerging techniques pushing the ceiling:**
- Inference-time scaling (OpenHands SOTA Nov 2025): Critic models reviewing agent outputs before committing
- Back-pressure verification: Tests and type checks running automatically, surfacing only failures
- Session-bounded autonomy: Agents get full autonomy within a session but must checkpoint between sessions
- Progressive trust: Start with tight gates, loosen as track record builds

### 5. Benchmark Reality

**SWE-bench Verified is contaminated and should be ignored for capability assessment.** OpenAI confirmed "every frontier model showed training data contamination." Claude Opus 4.5 scores 80.9% on Verified but 45.9% on Pro. Same model, half the score.

**SWE-bench Pro** (Scale AI, Sep 2025) is the current gold standard:
- 1,865 multi-language tasks (Python, Go, TypeScript, JavaScript)
- Average 107 lines changed, 4.1 files modified per task
- GPL and proprietary codebases creating contamination barriers
- Top scores cluster around 42-46% with standardized scaffolding, 50-57% with custom scaffolds

**SWE-bench Live** (May 2025, arxiv:2505.23419) provides the freshest signal:
- 1,319 tasks from issues created since 2024, spanning 93 repositories
- Best agent-model pair: 22.96% on SWE-bench instances, 18.89% on non-SWE-bench repos
- Continuous refresh prevents contamination accumulation

**SWE-rebench** provides continuous decontaminated evaluation:
- 57 problems from 46 repos (Jan-Mar 2026 window)
- Top scores: Claude Opus 4.6 at 65.3%, GPT-5.2-medium at 64.4%
- Key finding: Claude Opus 4.6 solved 34 identical tasks across all 5 attempts (high consistency)
- Token efficiency varies wildly: Qwen3-Coder-Next averaged 8.12M tokens per problem vs GPT-5.4 achieving top-5 with lowest tokens

**The scaffold gap is the most actionable finding:**

| Configuration | Score |
|--------------|-------|
| Claude Opus 4.5 (standardized scaffold) | 45.9% |
| Claude Code (Opus 4.5 + custom scaffold) | 55.4% |
| GPT-5.3-Codex CLI (custom scaffold) | 57.0% |

Custom scaffolding adds 9-11 percentage points. This is larger than the gap between most model generations.

**What this means for harness design:**

1. **Optimize for supervision, not trust.** At 18-23% on fresh issues and 45% on Pro, agents fail more than they succeed on non-trivial tasks. Our harness should assume agent outputs need review and make review efficient — not try to achieve full automation.

2. **Invest in the scaffold.** The 9.5 pp gain from Claude Code's scaffold over standardized scaffolding is worth more than waiting for the next model. Every improvement to our harness (better hooks, better skills, better context management) compounds.

3. **Consistency matters more than peak performance.** Claude Opus 4.6's 34/57 consistent solves vs higher pass@5 scores from other models suggests that for a personal harness, we want predictable agents we can build workflows around, not lottery-ticket brilliance.

4. **Fresh issues are the real test.** If we want to know how our harness actually performs, we should evaluate on our own fresh tasks (novel features, unfamiliar codebases), not toy benchmarks.

5. **Multi-language matters.** SWE-bench Pro's inclusion of Go alongside Python/TypeScript/JavaScript makes it more relevant to our workflow. Models performing well on Pro are more likely to handle our Go codebase well.

## Implications for Our Harness

**The frontier is moving toward what we've already built, but with more automation.**

Our harness's architecture — structured state files, checkpoint-based continuity, sub-agent delegation with domain expertise, hook-based enforcement gates, progressive disclosure of context — aligns with every major trend identified in this research. The key gaps are:

1. **Automated self-improvement loop**: Implement the binary eval + skill mutation pattern. This is the highest-leverage investment because it compounds: every automated improvement to a skill instruction improves all future invocations of that skill.

2. **Strategic monitoring over per-action approval**: Anthropic's autonomy data shows experienced users shift from gatekeeping to monitoring. Our hooks should support this — run verification silently on success, surface only failures. The back-pressure pattern from HumanLayer.

3. **Consistency tracking**: Track which tasks our harness handles reliably vs which are lottery tickets. Build workflows around the reliable ones; apply extra review to uncertain ones.

4. **Cost instrumentation**: Token usage per session, per task, per sub-agent. The Anthropic data tracks 99.9th percentile turn duration — we should track comparable metrics to catch runaway sessions.

5. **JSON-first for agent-readable state**: Strengthen the preference for JSON over Markdown in all structured data agents need to read/write. Anthropic's harness research explicitly confirmed models corrupt Markdown more than JSON.

## Open Questions

1. **Will the skill ecosystem converge?** Five competing awesome-lists with 69K+ skills suggests either explosive growth or unsustainable fragmentation. If a package manager emerges (with versioning, testing, dependency resolution), it changes the build-vs-buy calculus for skill development. Monitor VoltAgent's cross-tool compatibility as a signal.

2. **Is the self-improvement flywheel economically viable?** The binary eval loop requires LLM calls to test skill variations. At what invocation frequency does optimizing a skill pay for the optimization cost? We need usage data before investing.

3. **How far can supervised autonomy scale?** Anthropic's own engineers maintain 80-100% oversight. If experts can't reduce oversight below 80%, what's the realistic productivity ceiling? The Rakuten case (99.9% accuracy on 12.5M lines, 7 hours) suggests the ceiling depends heavily on task structure — mechanical modifications scale better than creative design.

4. **Will fresh-issue benchmarks track real improvement?** SWE-rebench's 65.3% (Opus 4.6) vs SWE-bench Live's ~19% (best pair) on non-SWE-bench repos is a huge gap. Which number better reflects our daily experience? Probably somewhere between — our harness provides better context than standardized scaffolds but we work on novel code.

5. **Is the parallel agent lifestyle sustainable?** Willison runs 3-4 agents simultaneously, but "the fundamental bottleneck remains code review." If review is the bottleneck and we're generating more code faster, are we just accumulating review debt? Need to measure whether parallel generation actually improves throughput after accounting for review time.

6. **Agent-native codebase design**: Should we restructure our harness's own code to be more agent-maintainable? One concern per file, heavy inline docs, comprehensive test coverage as verification, JSON metadata everywhere. The 81-project research repo is an existence proof but all projects are disposable — would the pattern work for long-lived code?
