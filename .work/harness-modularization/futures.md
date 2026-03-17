# Futures — Harness Modularization

## Next (this initiative)
- **Language-specific anti-pattern packs**: Ship Go, Python, TypeScript, Rust anti-pattern references as optional add-ons. Users enable per project via `harness.yaml`.
- **Agency-agents deep integration**: Provide a curated subset recommendation per stack in `harness.yaml` (e.g., `recommended_agents: [code-reviewer, security-engineer, devops-automator]` for Go backend projects).

## Quarter
- **Plugin marketplace integration**: If Claude Code's plugin system matures, consider distributing harness as a plugin instead of git repo + install script.
- **Multi-language project support**: Projects using Go + TypeScript (fullstack) need both anti-pattern packs active simultaneously. Config should support `stack.languages: [go, typescript]`.
- **Harness versioning**: As friends use the harness, need a versioning scheme for breaking changes. Semantic versioning on install script + migration notes.

## Someday
- **CI/CD integration**: Harness hooks could run in CI (not just local). Would need a headless mode that doesn't depend on Claude Code session.
- **Shared review agent registry**: Community-contributed review agents (e.g., Rails reviewer, Django reviewer) installable as add-on packs.
- **Harness analytics**: Track which hooks fire most, which commands are used, what tier tasks tend to be — help users optimize their workflow.
