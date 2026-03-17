# Research Handoff → Plan

## What This Step Produced
10 research notes covering file inventory, diff analysis, parameterization audit, settings merge, evolution history, workflow-meta skill, config schema design, agency-agents overlap, runtime selection model, and harness-init design.

## Key Findings

### 1. The harness is ~70% general-purpose
- **42 files are byte-identical** between gaucho and dotfiles
- Core workflow engine (commands, state model, hooks, skills) has zero tech-specific references
- The remaining 30% is concentrated in: review agents, code-quality skill, pr-gate hook, settings.json formatter hooks

### 2. Three-tier file classification
- **General (ship as-is)**: 10 commands, 5 hooks, 4 workflow agents, 2 skills + refs, 2 rules, workflow-meta
- **Must-parameterize**: build commands, file patterns, formatter/linter in hooks, review routing, anti-pattern regexes
- **Project-specific (never ship)**: domain agents, architecture-decisions, dev-env skill, tech-deps.yml

### 3. Settings merge is solvable
- Merge algorithm: append-if-not-present for hook arrays, set-if-absent for scalars
- jq-based implementation, idempotent, tracks what harness added for uninstall
- Hook paths: absolute paths to harness repo directory

### 4. Runtime selection model (critical finding)
- Claude Code has **NO native conditional agent activation**
- All files in `~/.claude/` are always loaded and available
- Selection happens at the **command/prompt level**: `work-review.md` reads `harness.yaml` to decide which agents to spawn
- Projects override by placing same-named files in `.claude/` (native precedence)
- Hooks gate language-specific behavior via shell conditionals reading `harness.yaml`

### 5. Don't ship review agents — use agency-agents
- `~/src/agency-agents/` has 160+ agents, MIT licensed, with production `install.sh`
- 10 overlap with our review agents (code-reviewer, security-engineer, devops-automator, etc.) — often better-specified
- **Harness owns workflow agents** (work-research, work-review, work-implement, work-spec, workflow-meta)
- **agency-agents (or custom) owns domain expertise** — users install separately
- `harness.yaml` review_routing maps file patterns → agent names that must exist somewhere in `~/.claude/agents/` or `.claude/agents/`

### 6. harness-init creates project grounding only
- Everything else lives globally in `~/.claude/`
- `harness-init` creates: `harness.yaml`, `rules/beads-workflow.md` template, `.claude/settings.json` (project hooks), beads init
- Does NOT copy commands, skills, agents, or workflow hooks to project
- Prompts for language, framework, database → populates `harness.yaml`

### 7. Override pattern proven
- Gaucho naturally overrides `beads-workflow.md` (filled deprecated table) and `code-quality.md` (removed HTMX ref)
- Claude Code native precedence (project > user) handles this — no custom mechanism needed

### 8. Self-hosting via workflow-meta
- The `workflow-meta` skill ships with the harness for self-modification
- Already general-purpose, no tech references

## Key Artifacts
- Research notes: `.work/harness-modularization/research/01-10*.md`
- Research index: `.work/harness-modularization/research/index.md`
- Futures: `.work/harness-modularization/futures.md`
- Summary: `docs/feature/harness-modularization.md`

## Decisions Made (User-Confirmed)
1. **Repo structure**: Mirror `.claude/` directory structure
2. **Hook dependency**: Require yq (and jq) — install script handles dependencies
3. **Uninstall mechanism**: Manifest tracking what harness added
4. **Beads integration**: Hard dependency, pinned version
5. **CLAUDE.md management**: Append with tagging to detect existing/outdated content
6. **Update strategy**: Versioned `schema_version` in harness.yaml with sequential migration functions
7. **Review agents**: Don't ship — use agency-agents or custom. Harness owns workflow agents only.
8. **Config over templates**: Runtime config reading beats template rendering
9. **Absolute paths for hooks**: Referenced by path to harness repo
10. **Override, not merge, for content files**: Claude Code native project > user precedence
11. **Parameterized info ships**: go-reviewer and similar stack-specific agents ship with harness as available options, selected via harness.yaml routing
12. **Generation commands**: `/harness-init`, `/harness-update`, `/harness-doctor` for project scaffolding and maintenance
13. **Config injection pattern**: Commands inject harness.yaml stack context into BOTH subagent prompts AND handoff prompts — ensures subagents know the project stack and next-step readers have context
14. **Ship all language packs**: `code-quality/references/` ships with all available language anti-pattern packs (Go now, more added over time). Skill text directs to the pack matching `stack.language` from harness.yaml.

## Open Questions Resolved

| # | Question | Resolution |
|---|----------|-----------|
| 1 | Repo structure | Mirror `.claude/` |
| 2 | Hook dependency | Require yq + jq |
| 3 | Uninstall | Manifest file |
| 4 | Beads | Hard dependency |
| 5 | CLAUDE.md | Append with tags |
| 6 | Update strategy | schema_version + migrations |
| 7 | Review agents | Use agency-agents, harness provides routing config |

## Remaining Questions for Planning
1. **agency-agents integration**: Should the harness install script also install agency-agents? Or document as a recommended companion?
2. **Harness repo naming**: `claude-work-harness`? `work-harness`? Something else?
3. **Code-quality skill**: Ships with harness (general principles) but references language packs. How do language packs work with the global model?
4. **pr-gate.sh parameterization**: This hook runs formatter + linter + build. Should it read `harness.yaml` directly, or should it be a project-level hook that harness-init generates?

## Instructions for Plan Step
1. Read this handoff prompt — primary input
2. Design the repo structure (mirroring `.claude/`)
3. Design the install/update/uninstall lifecycle
4. Define what lives in harness repo vs what harness-init creates at project level
5. Resolve the 4 remaining questions
6. Write architecture document at `.work/harness-modularization/specs/architecture.md`
