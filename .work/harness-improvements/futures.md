# Futures — Harness Improvements

## Next Horizon

- **Plugin conversion**: Convert harness from global install to Claude Code plugin format for easier distribution. *Why not now*: Current install.sh works; plugin format has security restrictions (no hooks/mcpServers in plugin agents).
- **Agent Teams integration**: Experimental but promising for large parallel work. *Why not now*: Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` flag, no session resumption, API may change.
- **agnix CI integration**: Lint harness configs in CI pipeline. *Why not now*: Need to establish baseline configs first; agnix is new.
- **Storybook MCP**: Expose component patterns as machine-readable context. *Why not now*: Frontend-project-specific, not core harness functionality.

## Quarter Horizon

- **Temporal knowledge graph**: Zep/Graphiti for cross-project knowledge with validity windows. *Why not now*: Infrastructure overhead not justified until simple memory proves insufficient.
- **Traffic-based API docs**: Levo.ai/Treblle for always-in-sync endpoint documentation. *Why not now*: Requires production traffic instrumentation, project-specific setup.
- **DocAgent pattern**: Multi-agent doc generation with topologically sorted dependency order. *Why not now*: Academic (Facebook Research), not yet production-proven in CLI agent context.
- **GitHub Agentic Workflows**: Markdown-defined CI automations. *Why not now*: In technical preview, API not stable.

## Someday

- **Hybrid memory (vector + graph)**: Mem0-style architecture. *Why not now*: Letta benchmark shows filesystem is competitive; complexity not justified.
- **Multi-model review consensus**: Expand beyond Claude+Codex. *Why not now*: Need to prove single Codex integration valuable first.
- **Automated CLAUDE.md drift detection**: CI job comparing codebase structure against context files. *Why not now*: Manual detection (tier 1) is sufficient at current scale.
