# Runtime Agent/Rule Selection Model

## Key Finding
Claude Code has **NO native conditional activation** for agents, rules, or skills. Everything in `~/.claude/` is always loaded. Selection happens at the **command/prompt level**, not filesystem level.

## Discovery & Precedence

| Category | Global | Project | Precedence |
|----------|--------|---------|-----------|
| Agents | `~/.claude/agents/*.md` | `.claude/agents/*.md` | Project overrides same-name global |
| Rules | `~/.claude/rules/*.md` | `.claude/rules/*.md` | Project overrides same-name global |
| Skills | `~/.claude/skills/*/SKILL.md` | `.claude/skills/*/SKILL.md` | Project overrides same-name global |
| Commands | `~/.claude/commands/*.md` | `.claude/commands/*.md` | Project overrides same-name global |
| Hooks | `~/.claude/settings.json` | `.claude/settings.json` | **MERGE** (both load) |

## Implications for Harness Design

### Ship everything globally
- All harness commands, skills, rules, hooks → `~/.claude/`
- All agents (workflow + whatever specialists the user installs) → `~/.claude/agents/`
- They're always available — Claude sees them all

### Selection happens in commands
- `work-review.md` reads `.claude/harness.yaml` to decide which agents to spawn for review
- `work-fix.md`, `work-feature.md`, `work-deep.md` read `harness.yaml` for build/test/lint commands
- Hooks read `harness.yaml` for language-specific behavior (formatter, anti-pattern regexes)

### Project overrides via filesystem
- Place same-named file in `.claude/` to replace a global default
- This is the native mechanism — no custom code needed
- Example: project places `.claude/rules/code-quality.md` to override the harness default

### Hooks are the runtime gate
- Hooks support shell conditional logic (check `harness.yaml`, exit 0 to skip)
- `pr-gate.sh` can read `harness.yaml` to decide whether to run `gofmt` or `prettier`
- `review-gate.sh` can read `harness.yaml` for language-specific anti-pattern regexes

## What harness-init Does NOT Do
- Does NOT copy commands/skills/agents from global to project (they're already available globally)
- Does NOT selectively install based on stack (everything is always there)
- Only creates the project-level grounding files that the harness reads at runtime
