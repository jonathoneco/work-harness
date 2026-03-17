# Futures — Harness Modularization

## Next
- **Language-specific anti-pattern packs**: Ship Go, Python, TypeScript, Rust anti-pattern references as optional add-ons. Users enable per project via `harness.yaml`.
- **Agency-agents deep integration**: Provide a curated subset recommendation per stack in `harness.yaml` (e.g., `recommended_agents: [code-reviewer, security-engineer, devops-automator]` for Go backend projects).
- **Dev-env skill generalization**: Pull the dependency awareness concept from gaucho's dev-env skill into the harness as a generic feature. Add a `tools` section to harness.yaml, generate dependency-inventory.md at init, verify tools in harness-doctor.

## Quarter
- **Plugin marketplace integration**: If Claude Code's plugin system matures, consider distributing harness as a plugin instead of git repo + install script.
- **Multi-language project support**: Projects using Go + TypeScript (fullstack) need both anti-pattern packs active simultaneously. Config should support `stack.languages: [go, typescript]`.
- **Harness versioning**: As friends use the harness, need a versioning scheme for breaking changes. Semantic versioning on install script + migration notes.
- **Stow compatibility**: The install.sh writes directly to `~/.claude/` which conflicts with GNU Stow directory symlinks. Options: support `--no-folding` stow, detect and warn about symlinked dirs, or provide a stow-compatible install mode.

## Someday
- **CI/CD integration**: Harness hooks could run in CI (not just local). Would need a headless mode that doesn't depend on Claude Code session.
- **Shared review agent registry**: Community-contributed review agents (e.g., Rails reviewer, Django reviewer) installable as add-on packs.
- **Harness analytics**: Track which hooks fire most, which commands are used, what tier tasks tend to be — help users optimize their workflow.
