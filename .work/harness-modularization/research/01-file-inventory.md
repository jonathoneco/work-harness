# File Inventory & Classification

## Scope
Inventoried all `.claude/` files in both gaucho (`/home/jonco/src/gaucho-service-refactor/.claude/`) and dotfiles (`/home/jonco/src/dotfiles/home/.claude/`).

## Classification Summary

| Classification | Gaucho | Dotfiles |
|---------------|--------|----------|
| General | 18 | 31 |
| Must-parameterize | 27 | 4 |
| Project-specific | 3 | 6 |

## General Files (ship as-is in harness)

### Commands (10)
- `work.md` — auto-triage entry point
- `work-fix.md` — Tier 1 single-session fix
- `work-feature.md` — Tier 2 feature
- `work-deep.md` — Tier 3 initiative
- `work-status.md` — display progress
- `work-checkpoint.md` — save session progress
- `work-reground.md` — context recovery
- `work-redirect.md` — dead end documentation
- `work-archive.md` — task archival
- `adversarial-eval.md` — debate framework

### Skills (2 + references)
- `work-harness/SKILL.md` + 4 references (triage-criteria, review-methodology, state-conventions, depth-escalation)
- `serena-activate/SKILL.md`

### Agents (5)
- `work-research.md` — Scout
- `work-review.md` — Auditor
- `work-implement.md` — Builder
- `work-spec.md` — Architect
- `product-strategist.md` — Theo

### Hooks (5)
- `state-guard.sh` — PostToolUse state validation
- `work-check.sh` — Stop checkpoint warning
- `beads-check.sh` — Stop beads issue enforcement
- `review-verify.sh` — Stop review evidence check
- `artifact-gate.sh` — Stop handoff prompt check

### Rules (2)
- `workflow.md` — tier system overview
- `workflow-detect.md` — session-start detection

### Other
- `workflow-meta/SKILL.md` (dotfiles only) — self-modification skill

## Must-Parameterize Files

Key categories needing config-driven content:
1. **Build commands**: `make test`, `make build`, `make lint` in work-fix, work-feature, work-deep, pr-prep
2. **File patterns**: `*.go`, `internal/handlers/*.go` in work-review, review-methodology
3. **Formatter/linter hooks**: `gofmt`, `golangci-lint` in settings.json, pr-gate.sh
4. **Agent tech context**: devops-reviewer, security-reviewer, systems-architect, performance-analyst, ml-engineer, ux-reviewer, stack-tracer all reference specific tech stack
5. **Code quality references**: go-anti-patterns.md, htmx-checklist.md

## Project-Specific Files (never ship in harness)
- `architecture-decisions.md` — agentctl, gaucho domain
- `loan-origination-expert.md` — domain agent
- `settings.local.json` — worktree-specific BEADS_DIR
- `dev-env/` skill — gaucho toolchain
- `tech-deps.yml` — gaucho dependency inventory
- `ama.md` — gaucho project knowledge (though concept is generalizable)
