# AI-Assisted Dev Landscape — Agent Frameworks, MCP, Claude Code Patterns
**Status:** Complete | **Tier:** R | **Beads:** work-harness-gli
## What
Evaluate the AI-assisted development landscape — agent frameworks, MCP ecosystem, and Claude Code power-user patterns — to identify what we should integrate into our work harness. Focus on evidence-backed patterns, not hype. Weight recommendations toward Go/terminal-native/personal harness context.
## Key Findings
- **Scaffold > Model**: Custom scaffolding adds 9.5pp on SWE-bench Pro — larger than most model-generation improvements. Our harness engineering is the highest-leverage investment.
- **Architecture validated**: Every major framework converges on patterns we already implement (state persistence, domain-expert agents, progressive disclosure, deterministic backbone).
- **MCP right-sized**: Our 3 MCPs (Serena, work-log, personal-agent) all justified. MCP costs 7-32x more tokens than CLIs. Don't add more.
- **Multi-agent**: Centralized coordination (our model) contains errors to 4.4x vs 17.2x for independent agents. Our "try single first" default is exactly right.
- **Critical gaps**: Cost tracking (ccost, 10 min), security (Lasso hooks, 30 min), automated quality flywheel (CLAUDE.md capture skill, 1 session).
- **Self-improvement flywheel**: Binary eval + skill mutation is the highest-leverage initiative — every improvement compounds across all future invocations.
- **Optimize for supervision**: 18-23% fresh-issue performance means review is non-negotiable. Make review efficient, not try to eliminate it.
## Top 3 Recommendations
1. Install ccost (Go binary) for cost visibility — 10 minutes, zero deps
2. Install Lasso security hooks — PostToolUse scanning, 50+ patterns
3. Build /capture-lesson skill for CLAUDE.md flywheel automation
## Addendum: Anthropic Repos Survey
- **Feature-dev plugin**: 7-phase workflow with 3 mandatory user gates; dedicated clarification phase we lack
- **Hookify**: Auto-generates behavioral rules from frustration signals — the automated CLAUDE.md flywheel
- **Agent SDK**: `can_use_tool` rewrites inputs (not just allow/deny); `UserPromptSubmit` invisibly injects context
- **MCP Go SDK**: Production-ready (v1.4.1); building harness-state server is 1-2 day project
- **No canonical local skill spec**: Our format is fine; MCP roadmap hints at future Skills primitive
## Deliverable
- Main report: `.work/ai-dev-landscape/research/deliverable.md`
- Anthropic addendum: `.work/ai-dev-landscape/research/addendum/deliverable.md`
