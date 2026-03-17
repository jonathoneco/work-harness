# harness-init Design

## Philosophy
The harness lives globally (`~/.claude/`). Projects just need minimal grounding files that tell the harness "I'm here, here's my stack." `harness-init` creates these grounding files.

## What harness-init Creates

### Required (always created)
```
.claude/
  harness.yaml              # Project stack declaration (the key file)
  rules/
    beads-workflow.md        # Template with empty deprecated approaches table
  settings.json              # Project-specific hooks only (formatter, project MCP servers)
.beads/                      # Via `bd init` — issue tracking store
```

### Prompted (based on answers)
```
.claude/
  rules/
    architecture-decisions.md   # If user wants project design principles
    code-quality.md             # If user wants project-specific quality overrides
  agents/
    <domain>-expert.md          # Scaffolded if user specifies a domain
```

### Never created (lives globally)
- Commands (work.md, work-fix.md, etc.)
- Skills (work-harness, code-quality, serena-activate, workflow-meta)
- Workflow agents (work-research, work-review, work-implement, work-spec)
- Hooks (state-guard, work-check, beads-check, review-gate, artifact-gate, review-verify)
- Rules (workflow.md, workflow-detect.md)

## harness.yaml — The Key File

```yaml
schema_version: 1

project:
  name: my-project
  description: "Brief project description"

stack:
  language: go
  framework: chi
  frontend: nextjs
  database: postgresql

build:
  test: "make test"
  build: "make build"
  lint: "make lint"
  format: "gofmt -w"

# Maps file patterns → agent names for work-review
# Agents must exist in ~/.claude/agents/ or .claude/agents/
review_routing:
  - patterns: ["*.go"]
    agents: [code-reviewer]
    exclude: ["*_test.go", "vendor/**"]
  - patterns: ["*_test.go"]
    agents: [code-reviewer]
  - patterns: ["*.sql", "migrations/**"]
    agents: [security-reviewer, code-reviewer]
  - patterns: ["*.tsx", "*.ts"]
    agents: [frontend-developer, ux-researcher]
  - patterns: ["Dockerfile", "docker-compose*.yml", ".github/**"]
    agents: [devops-automator]

# Code file extensions for hooks (beads-check, review-gate)
extensions: [".go", ".sql", ".tsx", ".ts"]

# Anti-pattern regexes for review-gate.sh (language-specific)
anti_patterns:
  - pattern: "_, _ ="
    description: "Swallowed error return"
  - pattern: '_ = .*\.Exec\('
    description: "Unchecked database exec"
```

## What harness-init Prompts

Interactive mode (default):
1. "Project name?" → `project.name`
2. "Brief description?" → `project.description`
3. "Primary language? (go/python/typescript/rust/other)" → `stack.language`
4. "Framework?" → `stack.framework`
5. "Database?" → `stack.database`
6. "Build command?" → `build.build` (auto-suggests based on language)
7. "Test command?" → `build.test`

Non-interactive: `harness-init --language go --framework chi --database postgresql`

## /harness-update Command

Reads `harness.yaml` and:
1. Regenerates `tech-deps.yml` from config
2. Reports which global harness files have been overridden locally
3. Checks `schema_version` compatibility
4. Suggests new agents/features available since last update

## /harness-doctor Command

Health check:
1. Verifies `harness.yaml` exists and parses
2. Checks all agents referenced in `review_routing` exist in `~/.claude/agents/` or `.claude/agents/`
3. Verifies hooks referenced in settings.json are executable
4. Checks beads is initialized
5. Reports mismatches between harness version and project schema version
