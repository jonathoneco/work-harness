# Futures

Deferred enhancements organized by horizon, consolidated from per-task futures.

## Next

### Context Lifecycle
- **freshness_class field**: Enum on context documents (slow/medium/fast/frozen) enabling differentiated scan cadences. Currently all documents scanned identically at archive time.
- **last_reviewed field**: ISO date tracking when a document was last validated for accuracy (distinct from git modification history).

### Harness Improvements
- **Plugin conversion**: Convert harness from global install to Claude Code plugin format. *Blocked*: Plugin format has security restrictions (no hooks/mcpServers in plugin agents).
- **Agent Teams integration**: Experimental but promising for large parallel work. *Blocked*: Requires experimental flag, no session resumption, API may change.
- **agnix CI integration**: Lint harness configs in CI pipeline. *Blocked*: Need baseline configs first; agnix is new.
- **Storybook MCP**: Expose component patterns as machine-readable context. *Blocked*: Frontend-project-specific, not core harness.

### Harness Modularization
- **Language-specific anti-pattern packs**: Ship Go, Python, TypeScript, Rust anti-pattern references as optional add-ons via `harness.yaml`.
- **Agency-agents deep integration**: Curated agent subset recommendation per stack in `harness.yaml`.
- **Dev-env skill generalization**: Pull dependency awareness from gaucho's dev-env skill into the harness as a generic feature.

## Quarter

### Context Lifecycle
- **Session-start staleness warnings**: At session start, warn if context documents reference deprecated technologies.

### Harness Improvements
- **Temporal knowledge graph**: Zep/Graphiti for cross-project knowledge with validity windows.
- **Traffic-based API docs**: Levo.ai/Treblle for always-in-sync endpoint documentation.
- **DocAgent pattern**: Multi-agent doc generation with topologically sorted dependency order.
- **GitHub Agentic Workflows**: Markdown-defined CI automations (in technical preview).

### Harness Modularization
- **Plugin marketplace integration**: Distribute harness as a Claude Code plugin if plugin system matures.
- **Multi-language project support**: Projects using Go + TypeScript need both anti-pattern packs active simultaneously.
- **Harness versioning**: Semantic versioning on install script + migration notes for breaking changes.
- **Stow compatibility**: install.sh writes directly to `~/.claude/` which conflicts with GNU Stow directory symlinks.

## Someday

- **Hybrid memory (vector + graph)**: Mem0-style architecture. Filesystem is competitive per Letta benchmark.
- **Multi-model review consensus**: Expand beyond Claude+Codex.
- **Automated CLAUDE.md drift detection**: CI job comparing codebase structure against context files.
- **CI/CD integration**: Harness hooks running in CI with headless mode.
- **Shared review agent registry**: Community-contributed review agents as add-on packs.
- **Harness analytics**: Track hook fires, command usage, task tier distribution.
