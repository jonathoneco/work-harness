# Diff Analysis: Gaucho vs Dotfiles

## Identical Files (42)
The vast majority of harness files are byte-identical across both locations. This confirms the "copy and sync" pattern — dotfiles is the source of truth, gaucho copies.

Identical categories:
- All 10 work commands
- All 7 hooks
- All 5 work agents + 6 review agents
- Both work-harness and code-quality skills (including references)
- Both workflow rules

## Diverged Files (3)

### 1. `rules/beads-workflow.md`
- **Dotfiles**: Template with `<!-- Project-specific deprecated approaches go here -->`
- **Gaucho**: Populated deprecated approaches table (15 entries)
- **Design implication**: Harness ships the template. Projects fill in their own deprecated table. This is the override pattern working correctly.

### 2. `rules/code-quality.md`
- **Dotfiles**: References both `go-anti-patterns.md` AND `htmx-checklist.md`
- **Gaucho**: References only `go-anti-patterns.md` (HTMX removed after migration to JSON API)
- **Design implication**: Code quality rule file needs to be parameterized — references should come from config, not hard-coded.

### 3. `settings.json`
- **Dotfiles**: User-level paths (`~/.claude/hooks/`), full permissions list, notification hook
- **Gaucho**: Project-level paths (`.claude/hooks/`), PostCompact hook, `enableAllProjectMcpServers`
- **Design implication**: Settings are inherently split — harness installs user-level settings, projects have their own. No single settings.json works for both.

## Unique to Gaucho (7 files)
- `architecture-decisions.md` — project design principles + agentctl
- `settings.local.json` — worktree BEADS_DIR
- `tech-deps.yml` — dependency inventory
- `loan-origination-expert.md` — domain agent
- `dev-env/` skill (2 files) — gaucho toolchain

## Unique to Dotfiles (6 files)
- `CLAUDE.md` — global instructions (mirrors `~/.claude/CLAUDE.md`)
- `bd-CLAUDE.md` — beads agent instructions
- `bd-settings.json` — beads integration settings
- `htmx-debugger.md` — HTMX specialist (removed from gaucho)
- `pr-prep.md` — PR preparation command
- `workflow-meta/SKILL.md` — harness self-modification

## Key Insight
The override pattern already works naturally. Gaucho overrides `beads-workflow.md` and `code-quality.md` with project-specific versions. The harness just needs to formalize this: ship templates, projects override.
