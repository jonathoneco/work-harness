# Project Config Schema Design

## Purpose
`.claude/harness.yaml` parameterizes tech stack so the harness can adapt behavior without modifying harness files.

## Consumers
Files that read config at runtime:
- `hooks/pr-gate.sh` — formatter, linter, build commands
- `hooks/review-gate.sh` — anti-pattern regexes by language
- `hooks/beads-check.sh` — file extension filter
- `commands/work-review.md` — file pattern → agent routing
- `commands/work-fix.md`, `work-feature.md`, `work-deep.md` — test/build commands
- `skills/work-harness/references/review-methodology.md` — layer definitions

## Proposed Schema

```yaml
# .claude/harness.yaml — project-level harness configuration

# Project identity
project:
  name: gaucho
  description: "Mortgage document analysis platform"

# Tech stack
stack:
  language: go          # Primary language
  framework: chi        # Web framework (optional)
  frontend: nextjs      # Frontend framework (optional)
  database: postgresql  # Database (optional)

# Build commands
build:
  test: "make test"
  build: "make build"
  lint: "make lint"
  format: "gofmt -w"

# File patterns for review routing
layers:
  - name: handlers
    patterns: ["internal/handlers/*.go"]
    reviewers: [go-reviewer, security-reviewer]
  - name: services
    patterns: ["internal/services/*.go"]
    reviewers: [go-reviewer, systems-architect]
  - name: database
    patterns: ["internal/database/*.go", "migrations/*.sql"]
    reviewers: [go-reviewer, security-reviewer]
  - name: models
    patterns: ["internal/models/*.go"]
    reviewers: [go-reviewer]
  - name: frontend
    patterns: ["frontend/src/**/*.tsx"]
    reviewers: [ux-reviewer]

# Code file extensions (for beads-check, review-gate)
extensions: [".go", ".sql", ".tsx", ".ts"]

# Optional features
features:
  serena: true          # Enable Serena LSP integration
  beads: true           # Enable beads issue tracking
  notifications: true   # Enable desktop notifications
```

## Runtime Reading
Hooks (bash) can read YAML via:
```bash
# Simple approach: yq (if available)
BUILD_CMD=$(yq '.build.test' .claude/harness.yaml 2>/dev/null || echo "make test")

# Fallback: grep + sed for simple keys
BUILD_CMD=$(grep '^  test:' .claude/harness.yaml | sed 's/.*: *//' | tr -d '"')
```

Commands/skills (markdown prompts) can instruct Claude to read the config file.

## Open Questions
1. Should hooks require `yq` as a dependency, or use simpler parsing?
2. Should the harness provide defaults when no `harness.yaml` exists?
3. How deep should the layer routing config go — just patterns, or full agent prompts?
4. Should `harness.yaml` be in `.claude/` or project root?
