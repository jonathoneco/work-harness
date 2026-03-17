# AI Best Practices: Instruction Persistence & Context Management

## Summary

Web research across AI coding tools, multi-agent frameworks, academic research, and Anthropic-specific guidance. Findings strongly validate the 4 proposed mechanisms and suggest additional hook-based approaches.

## Key Findings

### 1. "Lost in the Middle" Effect (Strongest Signal)

LLMs exhibit U-shaped attention: highest performance when relevant info is at the **beginning** (system prompt) or **end** (recent turns) of context. 30%+ accuracy drop for mid-context information (Liu et al., 2024).

**Implication for self-re-invocation**: `Skill()` at step transitions places full command instructions at the END of context — exactly where attention is highest. This is the strongest argument for mechanism #1.

### 2. CLAUDE.md is the Only Compaction Survivor

After compaction, CLAUDE.md is re-read fresh from disk. Everything else (skills loaded mid-session, conversation context, tool results) gets summarized and potentially lossy.

**Implication**: Skills and commands loaded via Skill() during a session are NOT preserved after compaction. Self-re-invocation after compaction is not just nice-to-have — it's essential for instruction fidelity.

### 3. Structured Format Preserves Better

Structured prompts (lists, tables, XML tags) preserve 92% fidelity during compaction vs. 71% for narrative prose.

**Implication**: Our existing frontmatter + structured markdown approach is correct. Adding structured `tech_deps` fields to frontmatter is aligned with best practices.

### 4. Multi-Session Architecture Outperforms Monolithic

3 specialized sessions at 40K tokens each: 94% relevance.
1 saturated session at 180K tokens: 72% relevance.

**Implication**: Validates the compaction protocol at step boundaries. Also validates spawning fresh subagents per work item rather than continuing in one long agent session.

### 5. External State as Ground Truth (Anthropic Pattern)

Anthropic recommends `progress.txt` and `tests.json` as "institutional memory" that survives context resets. Their multi-context-window pattern:
1. First window: establish framework (write tests, create setup scripts)
2. Subsequent windows: iterate on structured todo-list
3. Each window starts with: verify directory, read progress files and git logs, run tests

**Implication**: Our state.json + handoff prompts + manifest.jsonl pattern is aligned. State lives on disk, not in context memory.

### 6. Progressive Disclosure / On-Demand Loading

Cursor's `.cursor/rules/*.mdc` supports 4 activation modes: "always", "auto-attach" (by file pattern), "agent requested", and "manual". Only relevant rules load per request.

**Implication**: Our skill activation by file pattern is the right approach. Don't preload all skills — load them when needed. This keeps context lean.

### 7. PreCompact/PostCompact Hooks (NEW Mechanism)

Claude Code supports hooks at compaction boundaries:
- **PreCompact**: Run scripts before compaction (save state, log modified files)
- **PostCompact**: Inject system messages after compaction (re-grounding reminders)

**Implication**: A PostCompact hook could mechanically remind the agent to re-invoke the current work command. This would be HOOK-DRIVEN (deterministic) rather than PROMPT-DRIVEN (best-effort). Much more reliable than the current "re-read rule files" fallback.

### 8. Freshness Classes (Document Lifecycle)

Glen Rhodes proposes explicit decay rates:
- **Fast-decay**: API docs, release notes (2-4 week review windows)
- **Slow-decay**: Architecture overviews (6-month windows)

Making decay explicit prevents uniform date filtering from over-pruning or under-pruning.

**Implication**: Maps directly to our tiered staleness proposal:
- Rules → slow-decay (quarterly)
- Skills → medium-decay (per Tier-2+ archive)
- Task specs → frozen (never decay, historical record)

### 9. Ownership of Freshness

"Until freshness has an explicit owner with SLA accountability, it will be nobody's job." Technical solutions alone don't work without assigned responsibility.

**Implication**: Archive-time housekeeping assigns ownership to the step transition — the harness IS the owner. This is more reliable than a periodic reminder that nobody acts on.

### 10. Anti-Patterns to Avoid

- **"CRITICAL: MUST" aggressive language**: Claude 4.6+ responds better to normal language. Over-prompting causes overtriggering.
- **LLM summarization for context management**: Paradoxically encourages 13-15% longer agent trajectories. Observation masking (simpler) often matches or exceeds performance.
- **Trusting the model to self-enforce rules**: The "told vs. following" gap is real. External validators (hooks, tests, linters) needed.
- **Large monolithic instruction files (>200 lines)**: Bloats context. Late instructions truncated during compression.

## Tool Comparison Table

| Tool | Persistence Mechanism | Refresh Pattern |
|------|----------------------|-----------------|
| Claude Code | CLAUDE.md (hierarchical), Skills | Re-read from disk after compaction |
| Cursor | .cursor/rules/*.mdc | Auto-attach by file pattern per request |
| Windsurf | Rules + auto-generated memories | Assembly pipeline per prompt |
| Aider | Repository map via AST | Rebuilt per request |
| Continue.dev | .continue/rules/ + MCP | Team-shareable, MCP integration |
| LangGraph | Thread checkpoints + cross-thread stores | Reducer-driven state merging |

## Sources

- Liu et al. "Lost in the Middle" (TACL 2024)
- Chroma Research: "Context Rot"
- arXiv 2509.21361: "Maximum Effective Context Window"
- JetBrains Research: "Cutting Through the Noise"
- Anthropic: "Effective Harnesses for Long-Running Agents"
- Anthropic: Prompting Best Practices
- Glen Rhodes: "Data Freshness Rot in Production RAG Systems"
- Beyond the Vibes (tedivm.com)
- SFEIR: Claude Code Context Management
- decodeclaude.com: Compaction Deep Dive
