# Agency-Agents Overlap Analysis

## What Is agency-agents
A community repo of 160+ specialized AI agent personalities at `/home/jonco/src/agency-agents/`. MIT licensed, supports Claude Code natively (`.md` files with YAML frontmatter → `~/.claude/agents/`). Already has `scripts/install.sh` that copies agents to tool-specific directories.

## Overlap With Harness Agents

### Two distinct agent categories in our harness

**1. Workflow agents** (harness-specific, no overlap):
- `work-research.md`, `work-review.md`, `work-implement.md`, `work-spec.md`
- These are tightly coupled to the work harness state machine (read state.json, follow specs, produce handoff prompts)
- agency-agents has nothing equivalent — `Agents Orchestrator` is superficially similar but doesn't integrate with `.work/` state

**2. Review/specialist agents** (significant overlap):

| Our Agent | Agency Equivalent | Verdict |
|-----------|-------------------|---------|
| go-reviewer | Code Reviewer | Agency is language-agnostic with structured priorities. **Use agency + parameterize via harness.yaml** |
| security-reviewer | Security Engineer | Agency has STRIDE analysis, deeper threat modeling. **Replace with agency version** |
| devops-reviewer | DevOps Automator | Agency has deployment strategies (canary, blue-green). **Replace with agency version** |
| systems-architect | Software Architect | Agency has C4 model, bounded contexts. **Replace with agency version** |
| ml-engineer | AI Engineer | Agency more LLM-specific. **Keep both, different focus** |
| performance-analyst | SRE | Agency broader (SLO, observability). **Complement, don't replace** |
| ux-reviewer | UX Researcher | Agency focuses on research vs review. **Complement** |
| product-strategist | Product Manager | Agency more ops-focused. **Keep ours for strategy** |
| stack-tracer | (none) | **Unique to harness** — cross-layer tracing |
| htmx-debugger | (none) | **Deprecated** — gaucho moved to JSON API |

### Agency agents we lack
- Database Optimizer — query optimization, EXPLAIN ANALYZE
- Technical Writer — documentation specialist
- Incident Response Commander — production ops
- Frontend Developer — React/Vue/TypeScript
- Git Workflow Master — branching strategies
- Testing suite (8 agents) — accessibility, API, performance

## Design Decision

**Don't ship review agents with the harness.** Instead:
1. The harness ships **workflow agents** (work-research, work-review, work-implement, work-spec) and **workflow-meta**
2. The `work-review` command reads `harness.yaml` to determine which specialist agents to invoke
3. Users install agency-agents separately (`agency-agents/scripts/install.sh --tool claude-code`)
4. The harness config maps file patterns to agent names — users can point to agency agents OR custom ones

This avoids maintaining parallel agent definitions. The harness owns the workflow engine, agency-agents (or custom) owns the domain expertise.

## agency-agents Install Script
Already production-ready: `./scripts/install.sh --tool claude-code` copies to `~/.claude/agents/`. Could be a recommended companion install alongside our harness.
