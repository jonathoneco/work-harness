# Memory Integration Research

## What's Available Now

### Official Anthropic MCP KG Server
- `@modelcontextprotocol/server-memory` — Knowledge graph in JSONL file
- Entities, Relations, Observations as primitives
- Tools: create_entities, create_relations, add_observations, read_graph, search_nodes
- Install: `npx -y @modelcontextprotocol/server-memory`
- Zero infrastructure — single file storage

### Claude Code Built-in
- **CLAUDE.md hierarchy** — project/user/modular rules (already in use)
- **Auto Memory** — `~/.claude/projects/<project>/memory/` with MEMORY.md + topic files
- Machine-local, not shared. First 200 lines loaded at startup.

### Already in Harness
- `.work/` state files — task checkpoints and handoff prompts
- Serena memories — `.serena/memories/` with read/write tools

## Key Frameworks

| Framework | Architecture | Key Finding |
|-----------|-------------|-------------|
| **Mem0** | Hybrid vector + graph | 26% accuracy boost, 91% lower latency |
| **Letta** | Virtual context management | Filesystem-based agent scored 74% on LoCoMo, beating specialized libs |
| **Zep/Graphiti** | Temporal KG | Validity windows on facts, outperforms MemGPT |
| **Google Always On** | SQLite + LLM consolidation | "No vector DB, no embeddings, just an LLM that reads and writes" |
| **Claude-Mem** | Auto-capture + SQLite | 10x token efficiency, progressive disclosure |

## Storage Architecture Decision

| Approach | Fits Harness? | Why |
|----------|--------------|-----|
| Flat files (MD/JSONL) | Best fit | Git-friendly, human-readable, agents trained on filesystem tools |
| SQLite | Good for search | Zero-infra, could augment flat files |
| Vector DB | Overkill | Operational complexity not justified for this use case |
| Graph DB | Maybe later | Good for cross-project knowledge, premature now |

**Letta's key insight**: "Agents today are extremely effective at using filesystem tools" — simpler approaches are surprisingly competitive.

## Recommended Approach
1. **Start with Official MCP KG server** — add to harness MCP config, stores cross-project user knowledge
2. **Leverage existing Auto Memory** — already built into Claude Code, just needs better prompting
3. **Add memory consolidation to checkpoints** — during `/work-checkpoint`, capture key decisions and patterns
4. **Consider Claude-Mem** as a drop-in plugin for automatic session capture
5. **Defer graph DB** — only if cross-project relationship queries prove necessary

## Design Questions to Resolve
- Project-level (git-tracked) vs user-level (machine-local) vs external (MCP)?
- Automatic capture vs explicit writes?
- Consolidation trigger: checkpoint, compact, session end, or scheduled?
