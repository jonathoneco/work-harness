# Extract Work Harness Into Standalone Repo
**Status:** active | **Tier:** 3 | **Beads:** rag-7bfsr

## What
Extract the general-purpose workflow harness from gaucho/.claude/ and dotfiles/home/.claude/ into a standalone git repo (`claude-work-harness`) with an install script for user-level deployment to `~/.claude/`. Projects customize via `.claude/harness.yaml` config and native file override precedence.

## Components
| # | Component | Scope | Description |
|---|-----------|-------|-------------|
| C1 | Repo scaffold | Small | Directory structure, VERSION, README, LICENSE |
| C2 | Commands | Medium | 13 commands (work-*, harness-init/update/doctor) |
| C3 | Skills | Medium | 4 skills + language pack references |
| C4 | Agents | Small | 4 workflow agents (research, review, implement, spec) |
| C5 | Rules | Small | 2 rules (workflow, workflow-detect) |
| C6 | Hooks | Medium | 7 hooks, parameterized via harness.yaml |
| C7 | Install script | Large | Install/update/uninstall with settings merge |
| C8 | Settings merger | Medium | jq-based merge/de-merge for settings.json |
| C9 | Schema migrator | Small | Version-aware harness.yaml migrations |
| C10 | Config reader | Small | Shared yq helpers for hooks |
| C11 | harness-init | Medium | Project scaffolding command |
| C12 | harness-update | Small | Project compatibility check command |
| C13 | harness-doctor | Small | Health check command |

## Key Decisions
1. Repo mirrors `~/.claude/` structure — `claude/` subdir copied on install
2. Hooks stay in repo, referenced by absolute path in settings.json
3. agency-agents documented as recommended companion, not auto-installed
4. Language packs ship globally, selected at runtime via harness.yaml directive
5. All hooks check for harness.yaml and gracefully skip non-harness projects
6. pr-gate.sh reads harness.yaml directly (config over templates)
7. Config injection is a prompt-level directive (not shell template rendering)
8. CLAUDE.md uses HTML comment tags (`<!-- harness:start/end -->`) for idempotent updates
9. Conflict detection: existing non-harness files are warned + skipped (--force to overwrite)
10. Migrations are sequential functions (`migrate_N_to_M`) keyed by schema_version
11. harness-init auto-detects language from project files (go.mod, package.json, etc.)
12. Exit code 2 = blocked (hard error), exit 0 = success/skip, exit 1 = warning
