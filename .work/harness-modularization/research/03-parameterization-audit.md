# Hard-Coded Reference Audit

## Summary
50+ hard-coded references across 8 categories found in both gaucho and dotfiles `.claude/` directories.

## Category Breakdown

### 1. Go-Specific (27 references) — HIGH severity
- **Formatter**: `gofmt -w` in settings.json PostToolUse hook
- **Linter**: `golangci-lint` in pr-gate.sh
- **Build**: `go build ./cmd/server` in pr-gate.sh
- **Test**: `make test` in work-fix, work-feature, work-deep
- **Patterns**: `*.go`, `internal/handlers/*.go` in work-review, review-methodology
- **Anti-patterns**: Entire go-anti-patterns.md with Go code examples
- **Permissions**: `Bash(go build *)`, `Bash(go test *)` in dotfiles settings.json

### 2. HTMX-Specific (18 references) — HIGH severity
- **Agent**: htmx-debugger.md (entire file)
- **Checklist**: htmx-checklist.md (entire file)
- **References**: hx-target, hx-swap in stack-tracer, ux-reviewer
- **File patterns**: `*.html`, `templates/**` in work-review

### 3. Gaucho Domain (13 references) — CRITICAL severity
- **Agent**: loan-origination-expert.md (entire file)
- **Command**: ama.md references "gaucho project" 5 times, mortgage/loan terminology
- **Examples**: triage-criteria.md uses "loan origination feature" example

### 4. Infrastructure (12 references) — HIGH severity
- **AWS**: EC2, RDS, S3, SSM, WorkOS in architecture-decisions, ama, security-reviewer
- **agentctl**: Entire operations surface in architecture-decisions.md
- **Database**: `gaucho_dev`, pgvector, pgxpool references

### 5. Build Commands (8 references) — MEDIUM severity
- `make test`, `make build`, `make lint`, `make fmt` across 5 files
- Assume GNU Make with specific targets

### 6. Path Structure (9 references) — MEDIUM severity
- `cmd/server/`, `internal/handlers/`, `internal/services/` assume Go project layout
- `./cmd/server` build target in pr-gate.sh

### 7. Tech-Deps Manifest (5 references) — MEDIUM severity
- `tech-deps.yml` lists gaucho-specific technologies and deprecated approaches

### 8. Settings Hooks (7 references) — MEDIUM severity
- `gofmt` hook conditional on `.go` extension
- `beads-check.sh` file extension filter: `\.(go|js|ts|py|sql|html|css)$`

## Parameterization Strategy

### Option A: Config file (`harness.yaml`)
Define project stack in a config file, hooks/commands read it at runtime:
```yaml
language: go
formatter: gofmt -w
linter: golangci-lint run
build: make build
test: make test
file_extensions: [.go]
layers:
  - {name: handlers, path: "internal/handlers"}
  - {name: services, path: "internal/services"}
```

### Option B: Template files with placeholders
Ship template versions with `{{language}}` placeholders, install script renders them.

### Option C: Convention-based detection
Hooks detect project type from markers (go.mod, package.json, Cargo.toml) and apply appropriate tools.

### Recommendation
**Option A for explicit config** (build/test/lint commands, layers) + **Option C for auto-detection** as fallback. Templates (Option B) are brittle and hard to maintain. Runtime config reads are simpler.
