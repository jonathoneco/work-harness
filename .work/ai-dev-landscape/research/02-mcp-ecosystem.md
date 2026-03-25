# Pass 2: The MCP Ecosystem -- Durable Infrastructure vs. Demo-Ware

## Questions Investigated

1. MCP servers with proven daily use: Context7, Serena, Playwright, GitHub MCP, PAL -- what's the usage evidence beyond stars?
2. MCP servers for coding harnesses: knowledge-graph memory, Codebase Memory, context-mode, database MCPs -- which solve real problems?
3. MCP vs CLI vs skill -- token economics: actual overhead, when each makes sense
4. MCP protocol direction: where is it heading, underused features power users leverage
5. Our MCP audit: should anything else be MCP, should anything we have become CLI/skill?
6. Building vs consuming MCPs: is building custom Go MCP servers worth the investment?

## Findings

### 1. MCP Servers with Proven Daily Use

**Context7 (44K+ stars, 240K+ weekly npm downloads)**

Context7 is the clear adoption leader. FastMCP data shows it captures nearly 2x the views of the #2 server. ThoughtWorks Technology Radar added it to their "Tools" section. The product-market fit is genuine: it solves a daily friction (LLMs hallucinating outdated API syntax) well enough that adoption grows organically. Server-side document filtering achieved a 65% reduction in token consumption (9,700 to 3,300 tokens) and 38% reduction in latency. Single-library tasks score 9.4/10; cross-library queries drop to 3.5/10, revealing clear scope boundaries.

**Relevance to us**: Low. We write Go, not React/Next.js/Tailwind. Go's standard library is stable and well-known to models. Context7's value is highest for fast-moving JS framework ecosystems.

**Playwright MCP (29K stars, ~6K FastMCP views)**

Second most popular on FastMCP. Shrivu Shankar keeps it as his *only* MCP because Playwright manages complex, stateful browser sessions -- the exact use case where MCP's persistent connection justifies its overhead. Browser automation is the fastest-growing MCP category.

**Relevance to us**: Only if we need browser automation (testing web UIs, scraping). Not a current need.

**GitHub MCP (28K stars)**

The "essential combo" with Context7 according to multiple guides. However, Scalekit benchmarks show GitHub MCP costs 7-32x more tokens than equivalent CLI operations (simple query: 1,365 CLI tokens vs 44,026 MCP tokens). Monthly cost for 10K ops: $3.20 CLI vs $55.20 MCP.

**Relevance to us**: Negative. We already use `gh` CLI effectively. The 17x average token multiplier makes this a clear anti-pattern for our harness.

**Serena (22K stars)**

LSP-backed semantic code navigation across 40+ languages. Provides symbol-level read/edit operations, reference finding, and rename-across-files. The core value proposition is token efficiency through targeted symbol reads instead of full-file reads.

**Relevance to us**: High. We already use it. Serena is the *right* kind of MCP -- it manages stateful LSP server connections that would be impractical as a CLI. The LSP session state justifies the protocol overhead.

**PAL (11K stars)**

Multi-model proxy that orchestrates conversations across GPT-5, Gemini, Grok, Ollama, etc. within a single context. Supports conversation threading, model debates, and collaborative reasoning across providers.

**Relevance to us**: Medium-low. Interesting for "second opinion" code reviews, but adds complexity. Could be useful for the adversarial evaluation pattern we already have -- getting a different model's perspective. Worth watching but not urgent.

### 2. MCP Servers for Coding Harnesses

**Knowledge Graph Memory Servers**

The ecosystem is fragmented. Options include Anthropic's reference implementation, Zep (temporal knowledge graphs), MemoryGraph (graph DB for coding agents), mcp-memory-service (5ms retrieval, local-first), and Omega-memory (claims #1 on LongMemEval at 95.4%). A benchmark of four implementations found that even advanced systems "couldn't separate the contexts of two projects," mixing information across boundaries.

**Our position**: We already run two knowledge graph MCPs (work-log for cross-project, personal-agent for project-specific). This two-server split directly addresses the project separation problem that benchmarks exposed. Our architecture is sound.

**Codebase Memory MCP (DeusData)**

High-performance code intelligence via tree-sitter AST. Claims 99.2% token reduction: five structural queries consumed ~3,400 tokens vs ~412,000 via file-by-file exploration. Indexes the Linux kernel (28M LOC) in 3 minutes. Single static binary, zero dependencies. Supports Go and 65 other languages.

**Relevance to us**: Significant overlap with Serena. Serena uses LSP (deeper semantic understanding, type resolution), while Codebase Memory uses tree-sitter (faster indexing, broader language coverage, persistent graph). The 99% token reduction claim is benchmarked against naive file reading -- Serena achieves similar efficiency via symbol-level reads. **Not worth adding alongside Serena** unless we hit cases where the persistent knowledge graph provides value Serena doesn't (e.g., cross-session codebase understanding without re-indexing).

**context-mode (mksglu)**

Claims 98% context reduction by intercepting tool outputs through a sandboxed subprocess. Architecture: PreToolUse hook routes outputs through a sandbox with SQLite FTS5 for semantic search. Real-world examples: Playwright snapshots 56KB to 299 bytes, GitHub issues 59KB to 1.1KB. Claims session time before slowdown goes from ~30 minutes to ~3 hours.

**Relevance to us**: High potential. This is a *compression layer*, not a tool -- it makes existing MCPs more efficient. The PreToolUse hook integration is elegant. Worth evaluating whether it would improve our Serena token efficiency for large codebases. Main concern: summarization quality -- does it lose important details?

**Database MCPs (Postgres, SQLite)**

Postgres MCP provides full schema introspection with primary keys, foreign keys, indexes, constraints. The real benefit is standardization: "stop explaining your database schema." However, token cost is marked "High" due to schema explosion risk -- enterprise DBs with 200+ tables consume tens of thousands of tokens.

**Relevance to us**: Low. We use beads (Dolt/SQLite). If beads needed AI-assisted querying, a database MCP could help, but our current CLI interface is sufficient.

### 3. MCP vs CLI vs Skill -- Token Economics

**The Numbers (Scalekit benchmark, Claude Sonnet)**

| Operation | CLI Cost | MCP Cost | Multiplier |
|-----------|----------|----------|-----------|
| Simple query | 1,365 tokens | 44,026 tokens | 32x |
| Complex query | 5,010 tokens | 33,712 tokens | 7x |
| Monthly (10K ops) | $3.20 | $55.20 | 17x |

**Simon Willison's framing**: "GitHub's official MCP on its own famously consumes tens of thousands of tokens of context." Skills consume "a few dozen extra tokens" with full details loaded on demand. Skills depend on a "safe coding environment" (filesystem + command execution), which Claude Code provides natively.

**Shrivu Shankar's rule**: Migrated all stateless tools (Jira, AWS, GitHub) to CLIs. Keeps only Playwright MCP (stateful). MCPs should be "simple, secure gateways" managing "auth, networking, and security boundaries" -- not API mirrors.

**MCP's response**: Progressive discovery (January 2026) addressed the worst of the token bloat by not loading all tool definitions upfront. The original context efficiency advantage of skills has narrowed.

**Decision framework**:
- **CLI**: Deterministic operations, high-frequency tasks, stateless integrations. Best token efficiency.
- **Skill**: Reusable agent instructions, workflow templates, prompt engineering. Token-efficient (dozens of tokens). Best for encoding *how* to use tools.
- **MCP**: Stateful environments (LSP sessions, browser automation), bidirectional communication, security boundary management. Higher token cost justified by capability.

### 4. MCP Protocol Direction

**2026 Roadmap priorities** (from the official MCP blog):

1. **Transport Evolution**: Stateless protocol, stateful application sessions. Streamable HTTP for remote deployment. `.well-known` metadata for server discovery without live connections.
2. **Agent Communication**: Tasks primitive (SEP-1686) for inter-agent coordination with retry semantics and expiry policies.
3. **Governance Maturation**: Working Groups accepting SEPs in their domain without full core review.
4. **Enterprise Readiness**: Audit trails, SSO, gateway behavior, configuration portability.

**Underused features that power users leverage**:

- **Sampling**: Servers can request completions from the client-side LLM. Enables reverse-flow patterns where the MCP server offloads reasoning to the client. Almost nobody uses this.
- **Roots**: File URI boundaries that limit server filesystem access. Dynamic root management lets users switch project scope. Security-relevant but ignored.
- **Elicitation**: Servers request missing context mid-session via structured JSON schema forms. Replaces hardcoded context with interactive resolution.
- **Resources**: Read-only persistent data exposure (vs Tools which trigger actions). Enables context-rich browsing without tool execution overhead. Dynamic URI templates like `travel://activities/{city}/{category}`.

**On the horizon**: Triggers/event-driven updates, enhanced security/authorization. MCP gateway servers (like MCP-Gateway with "single-port multiplexing") that aggregate multiple servers behind one interface, saving 95% context window.

### 5. Our MCP Audit

**Current MCP stack**:
- Serena (LSP navigation) -- **Keep**. Stateful LSP sessions are the canonical MCP use case. Token-efficient symbol reads. No CLI alternative.
- work-log (cross-project memory) -- **Keep as MCP**. Persistent knowledge graph requires session state for entity relationships. The bidirectional nature (agent reads + writes) fits MCP well.
- personal-agent (project memory) -- **Keep as MCP**. Same reasoning as work-log.

**Should anything else become MCP?**
- **beads**: No. `bd` CLI is stateless and efficient. Adding MCP would multiply token costs 7-32x with no benefit.
- **Cost tracking**: No. Pure CLI/hook territory. Read JSONL logs, compute costs, return a number.
- **Harness state (.work/ files)**: No. File reads via existing tools are sufficient.
- **Context7**: No. We write Go, not fast-moving JS frameworks.
- **PAL (multi-model)**: Defer. Interesting for adversarial evaluation, but not worth the integration complexity yet.
- **context-mode**: Evaluate. Not as an MCP server addition, but as a hook-based compression layer for existing MCP output. Could extend session longevity significantly.

**Should anything we have as MCP become CLI/skill?**
- Our MCPs are well-chosen: both knowledge graphs and Serena manage genuinely stateful resources. No changes recommended.

### 6. Building vs Consuming MCPs

**Go MCP ecosystem maturity**:
- **mcp-go** (mark3labs): Most popular community SDK. Supports stdio, Streamable HTTP, SSE, in-process transports. Active development.
- **Official SDK** (modelcontextprotocol/go-sdk): For spec compliance. Stdio-focused.
- Go advantages: Single binary, zero runtime deps, millisecond startup, native goroutine concurrency.

**Is building custom MCP servers worth it?**

For our harness, **no** -- at least not yet. The analysis:

1. **beads MCP**: `bd` CLI is sufficient. An MCP wrapper would add complexity and token cost for no benefit. If we needed real-time issue state during agent sessions (e.g., auto-claiming based on context), it could justify MCP, but our hook-based workflow handles this.

2. **Harness state MCP**: The `.work/` files are readable by existing tools. An MCP server that exposes task state, step progress, and handoff prompts could be useful if we had multiple agents needing coordinated access to harness state -- but our current architecture handles this via file reads.

3. **Cost tracking MCP**: Pure computation. A CLI or hook is more appropriate.

4. **When building makes sense**: If we identify a case where (a) the tool needs persistent state across requests, (b) bidirectional communication adds value, and (c) no existing CLI can substitute -- then a custom Go MCP server is a strong option. The Go SDK makes it straightforward.

**The builder's advantage**: Understanding MCP internals lets us make better *consumer* decisions. Even if we never ship a custom server, knowing the protocol helps us configure and optimize the servers we use.

## Implications for Our Harness

1. **Our MCP stack is well-composed**. Serena for stateful LSP, two knowledge graphs for memory. All three are justified by Shankar's rule: they manage stateful environments or security boundaries.

2. **Resist MCP sprawl**. Every MCP server we don't add saves 7-32x tokens vs the CLI equivalent. The awesome-mcp-servers list has 10,000+ entries; 99% are not worth the token tax.

3. **context-mode is the most interesting addition**. As a compression layer (not a new MCP server), it could extend our session longevity from ~30 min to ~3 hours. Evaluate against our actual Serena output sizes.

4. **Skills are our sweet spot**. For stateless workflows (beads integration, harness commands, review patterns), skills consume dozens of tokens vs thousands for MCP. Our existing 15+ skills architecture is validated by both Willison and Shankar's analysis.

5. **Progressive discovery in MCP (Jan 2026) narrows the skill advantage** on token efficiency, but skills still win on simplicity and composability.

6. **Watch MCP Tasks primitive (SEP-1686)**. If this matures, it could replace or complement our beads-based coordination for multi-agent scenarios.

7. **Go MCP SDK is mature enough** if we ever need to build. mcp-go provides all transports; single-binary deployment fits our stack.

## Open Questions

1. **context-mode evaluation**: Does the summarization quality hold up for code-heavy Serena output? Need to test with our actual Go codebases.

2. **MCP gateway servers**: Could a single gateway (like MCP-Gateway) reduce the overhead of running 3 separate MCP servers? What's the actual token savings?

3. **Sampling and Elicitation**: These MCP features are almost universally ignored. Are there harness use cases where Serena could leverage sampling to offload reasoning?

4. **Knowledge graph benchmark**: The benchmark showing project context mixing is concerning. Should we test our two-graph architecture against the same scenarios?

5. **PAL for adversarial evaluation**: Our current adversarial evaluation skill uses the same model. Would routing through PAL to get Gemini/GPT-5 opinions produce genuinely different (and useful) critique?

6. **MCP Tasks vs beads**: As MCP Tasks (SEP-1686) matures, will it subsume beads' coordination role for intra-session work? Our beads advantage is cross-session persistence -- does MCP Tasks provide that?
