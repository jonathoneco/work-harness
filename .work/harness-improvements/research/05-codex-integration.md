# Codex Integration Research

## What Codex Offers
- **codex exec** — Headless/non-interactive mode for scripting and CI
- **--output-schema** — Structured JSON output conforming to a provided schema
- **--sandbox read-only** — Safe review mode, cannot modify codebase
- **Models**: GPT-5.4, GPT-5.3-Codex, codex-mini-latest

## Honest Assessment: Codex vs Claude for Review

| Dimension | Codex | Claude |
|-----------|-------|--------|
| Race conditions/edge cases | Better | Good |
| Token efficiency | 4x cheaper | Higher usage, more thorough |
| Terminal/DevOps workflows | Better (77.3% Terminal-Bench) | Good (65.4%) |
| Complex multi-file changes | Weaker | Superior (SWE-bench +23%) |
| Hallucinated findings | Known issue | Rare |

**Bottom line**: "Second opinion from a different model" — not categorically better.

## Integration Approaches (Ranked)

### 1. Shell-based via codex exec (Recommended Start)
```bash
codex exec --output-schema schema.json -o review.json --sandbox read-only "Review..."
```
Working example exists: amanhimself.dev `/run-codex` skill.

### 2. MCP Server (More Integrated)
Codex can run as MCP server natively: `codex --mcp`
Config: `{"mcpServers": {"codex": {"command": "codex", "args": ["--mcp"]}}}`
Also: tuannvm/codex-mcp-server, tomascupr/codexMCP

### 3. codex-orchestrator (Parallel/Heavy)
kingbootoshi/codex-orchestrator — tmux-based parallel Codex agents

## Practical Considerations
- **Cost**: codex-mini $1.50/$6.00 per 1M tokens; review tasks mostly input tokens
- **Latency**: 15-45 seconds per review (session startup overhead)
- **Auth**: OPENAI_API_KEY env var required for headless mode
- **Reliability**: Must verify findings — hallucinations are a known issue

## Recommended Phased Approach
1. Create `/codex-review` skill (shell out to codex exec)
2. If valuable, add Codex as MCP server
3. Dual-review in work-review: Claude + Codex in parallel, flag agreement/disagreement
