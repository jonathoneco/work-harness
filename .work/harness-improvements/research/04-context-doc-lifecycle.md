# Context Doc Lifecycle Research

## Production Tools
- **Mintlify** ($300/mo) — Agent monitors codebase, proposes doc updates on code changes
- **DeepDocs** — CI agent that detects documentation drift on PRs, opens fix PRs
- **Continue CLI** — Open-source headless doc-writing agent pipeline
- **claude-code-action** — Free Anthropic GitHub Action, updates docs in same PR as code
- **ai-doc-gen** (divar-ir) — Multi-agent system generating README, CLAUDE.md, AGENTS.md

## Three-Tier Strategy (Zen van Riel)
1. **Manual** — Human notices wrong output, fixes context file
2. **Automated Detection** — Compare codebase structure against context files, flag drift
3. **Fully Automated** — Systems investigate codebase and update context files

## Doc Types and Recommended Approaches

| Doc Type | Approach | Tool |
|----------|----------|------|
| API reference | Auto-generate from traffic/code | Levo.ai, StackHawk |
| Component docs | Auto-generate | Storybook Autodocs + MCP |
| Dev environment | Config IS the doc | DevContainers |
| README/Getting Started | Hybrid (AI drafts, human polishes) | claude-code-action |
| Architecture Decisions | Bidirectional (feeds AI, AI drafts new) | cADR, ADR templates |
| AI context (CLAUDE.md) | Automated detection + human review | Custom hooks |

## Triggers
- PR opened/updated -> GitHub Action
- Push to main -> Post-merge hook / CI
- Scheduled cron -> Full-repo doc audit
- Manual @claude comment -> Ad-hoc
- Agent lifecycle hook -> Context freshness

## Harness Implementation Ideas
- Add a `doc-check` hook that compares modified files against doc references
- Create a `/doc-sync` command that scans for stale docs
- Integrate claude-code-action for doc updates in PR workflow
- Use Storybook MCP for frontend projects
