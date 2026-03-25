# Pass 1: Agent Frameworks — What's Proven, What's Extractable

## Questions Investigated

1. Frameworks with demonstrated utility (LangGraph, DSPy, PydanticAI) — what can a solo hacker learn?
2. The "just use the API" camp — where's the threshold where a framework pays for itself?
3. Multi-agent evidence — Google DeepMind's scaling science and our delegation model
4. The scaffold matters as much as the model — what does this tell us about harness design?
5. Patterns worth extracting — state persistence, prompt compilation, type contracts, role decomposition
6. Non-Python options — Go-native agent libraries and orchestration patterns

## Findings

### 1. Frameworks With Demonstrated Production Utility

**LangGraph** reached v1.0 in 2025 after powering agents at Uber (automated code migrations), LinkedIn (AI recruiter), and Klarna (AI support assistant serving 85M users, 80% reduction in resolution time). Its core value proposition is state persistence with checkpointing — agents pause, resume, and recover from failures without losing progress. Klarna's implementation pauses execution before high-stakes actions (refunds) for human approval, then resumes. This is the pattern our harness already implements via checkpoint files and handoff prompts, validating that approach.

**DSPy** has production deployments at JetBlue (customer feedback classification, RAG-powered predictive maintenance chatbots), Databricks, Walmart, VMware, Replit, Sephora, and Moody's. Its unique contribution is prompt compilation — the optimizer runs 100-500 LLM calls testing prompt variations ($20-50, 10-30 minutes) to find optimal prompts for a given pipeline. Skylar Payne's critique is instructive: DSPy has 4.7M monthly downloads vs LangChain's 222M because "the abstractions are unfamiliar and force you to think differently." His key insight: "Any sufficiently complicated AI system contains an ad hoc, informally-specified, bug-ridden implementation of half of DSPy." The patterns (typed I/O schemas, prompt-code separation, composable testable units, evaluation infrastructure from day one, model-agnostic abstractions) matter more than the framework itself.

**PydanticAI** v1 shipped September 2025, emphasizing type safety, structured outputs, and native MCP support. In benchmarking against LangChain, CrewAI, AutoGen, and Mastra, PydanticAI won on production reliability. Its value is proving that type contracts between agent steps catch errors early — a pattern that translates to any language with strong typing (including Go).

**CrewAI** observed 1.7 billion agentic workflows in 2025 across enterprise customers. Their core lesson: "The gap isn't intelligence — it's architecture." The winning pattern is a deterministic backbone (Flow) with intelligence sprinkled at specific steps. Role decomposition works when roles are named as domain specialists ("Market Analyst Agent" outperforms "Research Agent") — which aligns with our harness's domain-expert agent naming convention.

### 2. The "Just Use the API" Camp

**Anthropic's official position** (Dec 2024 "Building Effective Agents" guide): "Start by using LLM APIs directly: many patterns can be implemented in a few lines of code." Frameworks "often create extra layers of abstraction that can obscure the underlying prompts and responses, making them harder to debug." They recommend adding complexity "only when it demonstrably improves outcomes."

**The 12-Factor Agents manifesto** (Dexter Horthy, HumanLayer) attracted 10K+ GitHub stars. Core thesis: most successful "AI agents" are "mostly deterministic code, with LLM steps sprinkled in at just the right points." The typical founder journey: reach 70-80% quality with frameworks, discover production reliability requires "reverse-engineering the framework," then start over. The 12 factors include: own your prompts, own your context window, own your control flow, tools are just JSON, make agents stateless reducers, contact humans as first-class operations.

**The law firm CTO case** (HN discussion, 42691946): Built 900+ agents without frameworks using direct chat completion API with structured output. Agents handle client interviews, legal research, document authoring, case financial modeling. All integration done through understanding open-source tool APIs and creating single-purpose agents for specific I/O patterns. Key technique: "method actor prompting" for higher-quality outputs.

**The threshold**: Frameworks pay for themselves when you need (a) durable state across sessions/restarts, (b) complex human-in-the-loop approval flows, or (c) observability/tracing at scale. Below that threshold — single-purpose agents, structured output, clear control flow — raw API calls with good engineering discipline win. Our harness sits right at this boundary: we have state persistence and human-in-the-loop, but through filesystem primitives (JSON state files, git commits, checkpoint prompts) rather than a runtime framework.

### 3. Multi-Agent Evidence: The DeepMind Scaling Paper

Google DeepMind's "Towards a Science of Scaling Agent Systems" (Dec 2025, arxiv:2512.08296) is the most rigorous multi-agent evaluation to date: 180 configurations across 4 benchmarks, 5 architectures, 3 LLM families.

**The headline numbers:**
- Independent agents amplify errors **17.2x** (centralized coordination contains this to 4.4x)
- Sequential constraint-satisfaction tasks degraded **39-70%** under all multi-agent variants
- Hybrid approach costs **515% more tokens** for approximately 2-3% accuracy gain
- Finance (parallelizable): +80.9% with centralized coordination
- Planning (sequential): -39% to -70% across all variants

**Three scaling principles:**
1. **Tool-Coordination Trade-off** (β=-0.330): Tool-heavy tasks suffer disproportionately from multi-agent overhead
2. **Capability Saturation** (β=-0.408): When single-agent baseline exceeds ~45% accuracy, coordination yields negative returns
3. **Topology-Dependent Error Amplification**: Architecture choice fundamentally shapes error propagation

**Their predictive model** (R²=0.513, 87% correct architecture predictions on held-out tasks) uses measurable task properties (tool count, decomposability) to predict which architecture wins.

**Mapping to our harness**: Our "try single first, escalate when needed" model aligns perfectly with the evidence. Our subagent/delegation pattern works because we use centralized coordination (main agent orchestrates) rather than independent agents. The key risk: our parallel agent workloads (Teams protocol) could hit the 17.2x error amplification if tasks have sequential dependencies. The mitigation: our shared task lists and explicit dependency tracking via beads should contain error propagation. The DeepMind data says our harness should bias toward single-agent for anything sequential, and only parallelize truly independent subtasks — which is essentially what the CLAUDE.md rules already say.

### 4. The Scaffold Matters as Much as the Model

This is the most practically important finding for harness design.

**SWE-bench Pro data** (Morph, 2026): Claude Opus 4.5 scores 45.9% with standardized scaffolding but 55.4% as Claude Code — a **9.5 percentage point improvement** from scaffold alone. Three different agent systems (Augment/Auggie, Cursor, Claude Code) running the same Opus 4.5 base model achieved scores of 50.2%, 51.8%, and 55.4% respectively. Same model, different harness, different results.

**Cross-scaffold variance** (Epoch AI analysis): Switching scaffolds produces up to 11% difference for GPT-5 and 15% for Kimi K2 Thinking on SWE-bench Verified. "The choice of scaffold has the single biggest impact on overall performance."

**ETH Zurich agentfile study** (138 configurations): LLM-generated instruction files hurt performance while costing 20%+ more. Human-written ones improved outcomes by ~4%. Agents spent 14-22% more reasoning tokens processing poorly-designed instructions.

**HumanLayer harness engineering analysis**: Claude Opus 4.6 ranked #33 in its native harness but #5 in an unfamiliar harness — models can be "over-fitted to their harness." CLAUDE.md files are most effective under 60 lines. Connecting too many MCP tools floods context and pushes agents into a "dumb zone." Sub-agents as context firewalls maintain coherence "for much, much longer." Hooks surfacing verification only on failure are "the highest-leverage things we have spent time on."

**Implication**: Investing in harness engineering yields returns comparable to upgrading models. Our harness (CLAUDE.md discipline, hooks, skills, sub-agent delegation, progressive disclosure) is exactly the kind of scaffold that produces measurable gains. The ETH Zurich finding about LLM-generated instructions hurting performance is a warning about auto-generating CLAUDE.md content.

### 5. Patterns Worth Extracting

| Pattern | Source Framework | Our Harness Equivalent | Gap |
|---------|-----------------|----------------------|-----|
| State persistence + checkpointing | LangGraph | checkpoint files + state.json + git | None — we have this |
| Prompt compilation / optimization | DSPy | Manual CLAUDE.md iteration | Could automate: binary eval + skill mutation loop |
| Type contracts between steps | PydanticAI | JSON schemas in state.json | Could formalize: Go struct validation of agent outputs |
| Role decomposition by domain | CrewAI | Domain-expert agent naming | Already doing this well |
| Human-in-the-loop as first-class | 12-Factor Agents | review-gate hook, beads workflow | Already doing this |
| Deterministic backbone + LLM steps | CrewAI Flows | hooks + skills + explicit control flow | Already doing this |
| Progressive disclosure | HumanLayer | skills activated on demand | Already doing this |
| Context firewalls via sub-agents | HumanLayer | subagent delegation model | Already doing this |
| Back-pressure (tests/types on failure only) | HumanLayer | review-gate, artifact-gate hooks | Could strengthen: more hooks |
| Evaluation infrastructure from day one | DSPy | adversarial eval skill | Could formalize: continuous eval pipeline |

**Biggest gaps to close:**
1. **Prompt/skill compilation**: Automated optimization of skill instructions via binary evals (DSPy pattern, implemented without DSPy)
2. **Type contracts for agent I/O**: Formalize JSON schema validation for inter-agent communication (PydanticAI pattern, implemented in Go)
3. **Cost tracking**: No framework provides this well, but we need it for budget management

### 6. Non-Python Options: Go Agent Ecosystem

The Go agent ecosystem matured significantly in 2025-2026:

**Google ADK for Go** (March 2026): Official Agent Development Kit, code-first, fine-grained control. Most aligned with our philosophy of owning the control flow.

**LangChainGo** (tmc/langchaingo): Community-driven Go port, most comprehensive provider ecosystem (10+ integrations: OpenAI, Anthropic, Google, AWS Bedrock, Ollama). Built-in vector store integrations. The most feature-complete option but carries LangChain's abstraction-heaviness.

**Eino** (CloudWego): Defines component abstractions (ChatModel, Tool, Retriever, Embedding) with automatic streaming throughout orchestration. Components only implement streaming paradigms that make sense; framework handles the rest.

**Jetify AI SDK**: Go-first SDK inspired by Vercel AI SDK. Single, idiomatic API across multiple LLM providers. Lightest-weight option.

**OpenAI Agents SDK for Go** (nlpodyssey/openai-agents-go): Lightweight multi-agent workflow framework, provider-agnostic.

**The Go advantage** (from go.dev/blog/llmpowered): "LLM-powered applications are a lot like other modern cloud-native applications: they require excellent support for REST and RPC protocols, concurrency and performance. These just so happen to be the areas where Go excels."

**Recommendation**: Don't adopt a Go agent framework wholesale. Instead, selectively extract patterns: use go-openai or the Jetify SDK for API calls, implement state persistence with Go structs + JSON serialization (we already have this), and use goroutines for parallelizable subtasks. The 12-Factor Agent philosophy of "own your control flow" applies doubly in Go where the concurrency primitives are already world-class.

## Implications for Our Harness

**We're already well-positioned.** The evidence consistently shows that the patterns we've implemented — state persistence, sub-agent delegation with domain expertise, progressive disclosure, human-in-the-loop gates, deterministic control flow with LLM steps at key points — are exactly what the framework ecosystem is converging toward. The major frameworks are essentially productizing patterns we've built with filesystem primitives and CLAUDE.md discipline.

**Three high-value improvements to consider:**

1. **Automated skill optimization** (DSPy pattern): Implement a binary eval + mutation loop that runs skill instructions through test cases, measures pass/fail, and iterates on the instructions automatically. This is the single highest-leverage DSPy pattern and requires no framework adoption — just a script that runs evals and feeds results back.

2. **Structured agent I/O contracts** (PydanticAI pattern): Define Go structs for the JSON that flows between parent agents and sub-agents. Validate with `encoding/json` unmarshal into typed structs. Catch malformed agent outputs before they propagate.

3. **JSON over Markdown for structured state** (Anthropic harness finding): Our state.json is already JSON, but any structured data that agents read/write should prefer JSON over Markdown. Anthropic found models are "less likely to inappropriately modify JSON than Markdown."

**One thing NOT to do:** Don't adopt a framework. The evidence overwhelmingly shows that at our scale (personal harness, not enterprise SaaS), the overhead of learning, debugging, and maintaining framework abstractions exceeds the benefit. The law firm CTO built 900 agents with raw API calls. The 12-Factor Agents community confirms production winners are "rolling the stack themselves." Our Go + filesystem + git + hooks approach is the right architecture.

## Open Questions

1. **Cost tracking**: No framework solves this well. How do we instrument our harness to track token usage and cost per task/session? The Anthropic autonomy research tracks tokens per turn — we should too.

2. **Prompt compilation economics**: DSPy's 100-500 LLM call optimization costs $20-50. At what frequency of skill usage does this pay for itself? Need to measure skill invocation rates before investing in automated optimization.

3. **The 45% saturation threshold**: DeepMind found multi-agent hurts when single-agent exceeds 45% baseline accuracy. As models improve, does our entire multi-agent delegation model become counterproductive? Need to monitor whether sub-agent delegation is actually improving outcomes or just adding overhead.

4. **Harness over-fitting**: The finding that Opus 4.6 ranks #33 in its native harness but #5 elsewhere suggests models can become over-fitted to specific scaffolds. Are we over-fitting our harness to Claude's current behavior? How do we test harness portability across model providers?

5. **Go framework maturity**: Google ADK for Go is brand new (March 2026). Worth monitoring for MCP integration patterns and agent-to-agent communication that might be hard to build from scratch.
