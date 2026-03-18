# Code Quality References Research

## Standout Resources

### Drop-in Security References
- **sec-context** (github.com/Arcanum-Sec/sec-context) — 25+ security anti-patterns with VULNERABLE/SECURE pseudocode pairs, designed for LLM context windows. Key stat: 86% of AI code fails XSS defenses.
- **OWASP Top 10 for Agentic Apps 2026** — Covers tool misuse, prompt injection, data leakage specific to autonomous AI agents.

### Curated Harness/Config Collections
- **everything-claude-code** (affaan-m) — Hackathon winner, 16 agents, 65+ skills, AgentShield with 102 security rules. Cross-harness compatible.
- **awesome-claude-code-toolkit** (rohitg00) — 135 agents, 35 skills, 42 commands, 15 coding rules.

### Meta-Tooling
- **agnix** (agent-sh/agnix) — Linter for AI agent configurations. 230+ rules, validates CLAUDE.md/AGENTS.md/SKILL.md. SARIF output for GitHub Code Scanning. Install: `cargo install agnix-cli`.

## Proven Patterns
1. **Linting as hard constraints** — CI linter errors > documentation for enforcement
2. **Security prompts work measurably** — 56% -> 66% secure code with security-priority prompts
3. **Few-shot prompting** — 65% stylistic consistency improvement
4. **Specialist review agents** — 9 parallel subagents each focused on one quality dimension
5. **AI-aware PR checklists** — Error paths, concurrency, validation, password handling

## Common AI Anti-Patterns to Guard Against
- Massive overkill / unnecessary complexity
- "Looks correct" code with subtle logic flaws
- Outdated cryptography, incomplete validation
- 8x more code duplication than human code

## Integration for Harness
- Add sec-context breadth doc as a code-quality reference file
- Consider agnix for validating harness's own configs
- Expand code-quality/references/ with language-specific anti-patterns
- Integrate 9-parallel-review-agents pattern into work-review
