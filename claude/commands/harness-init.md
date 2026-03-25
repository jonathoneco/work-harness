---
description: "Initialize a project for the work harness with interactive setup"
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# /harness-init -- Project Setup

Initialize this project for the work harness. This command walks through an interactive prompt sequence to gather stack information, generates `.claude/harness.yaml`, initializes beads, and optionally scaffolds architecture rules and domain agent files.

## Pre-flight Checks

Before starting the interactive flow, perform these checks:

1. **Harness installed:** Verify `~/.claude/.harness-manifest.json` exists. If not found, tell the user: "Harness not installed. Run `./install.sh` from the harness repo first." and stop.
2. **Existing config:** Check if `.claude/harness.yaml` already exists. If so, ask: "harness.yaml already exists. Overwrite? [y/N]". If the user declines, stop without modifying anything.
3. **Beads available:** Check if `bd` is available by running `which bd`. If missing, note it -- beads initialization will be skipped later with a warning.

## Interactive Setup

Walk through these 6 prompts in order. For each, auto-detect a default and present it. Accept Enter as confirmation of the default.

### Step 1: Project Name

- **Prompt:** "Project name?"
- **Default:** Derive from the basename of the current working directory (e.g., `/home/user/src/my-app` becomes `my-app`).
- **Validation:** Must match `^[a-z0-9][a-z0-9-]*$` (kebab-case, lowercase alphanumeric with hyphens, must start with a letter or digit).
- **On invalid:** Re-prompt explaining the format requirement.
- **Display:** `Project name [my-app]:`

### Step 2: Language

- **Prompt:** "Primary language?"
- **Auto-detect** by checking for these files in the project root (use first match in priority order):
  1. `go.mod` exists -> `go`
  2. `Cargo.toml` exists -> `rust`
  3. `package.json` exists -> `typescript`
  4. `requirements.txt` or `pyproject.toml` or `setup.py` exists -> `python`
  5. None detected -> `other`
- **If detected:** Display "Detected: go (from go.mod). Accept? [Y/n]"
- **If not detected:** Present the choices: `go`, `python`, `typescript`, `rust`, `other`
- **Valid values:** `go`, `python`, `typescript`, `rust`, `other`

### Step 3: Framework

- **Prompt:** "Framework?" (skip entirely if language is `other`)
- **Auto-detect by language:**
  - `go`: scan `go.mod` for known imports -- `chi` (go-chi/chi), `gin` (gin-gonic/gin), `echo` (labstack/echo), `fiber` (gofiber/fiber)
  - `typescript`: scan `package.json` dependencies -- `next` (nextjs), `express`, `fastify`, `hono`, `remix`
  - `python`: scan `requirements.txt` or `pyproject.toml` -- `django`, `flask`, `fastapi`, `starlette`
  - `rust`: scan `Cargo.toml` -- `actix-web`, `axum`, `rocket`, `warp`
- **If detected:** Display "Detected: chi (from go.mod: go-chi/chi). Accept? [Y/n]"
- **If not detected:** Display "Framework (optional, press Enter to skip):"
- **Default:** null if nothing detected or user skips

### Step 4: Database

- **Prompt:** "Database?"
- **Auto-detect** by checking for common indicators:
  - `docker-compose.yml` or `docker-compose.yaml`: scan for `postgres`, `mysql`, `mongo`, `redis` image names
  - Go: `go.mod` containing `pgx` or `jackc/pgx` -> `postgresql`, `go-sql-driver/mysql` -> `mysql`, `mongo-driver` -> `mongodb`
  - Python: `requirements.txt` containing `psycopg` -> `postgresql`, `pymysql` -> `mysql`, `pymongo` -> `mongodb`
  - TypeScript: `package.json` containing `pg` -> `postgresql`, `mysql2` -> `mysql`, `mongoose` -> `mongodb`, `prisma` -> check prisma schema
- **If detected:** Display "Detected: postgresql (from pgx in go.mod). Accept? [Y/n]"
- **If not detected:** Display "Database (optional, press Enter to skip):"
- **Default:** null if nothing detected or user skips

### Step 5: Build Commands

- **Prompt:** "Build commands -- I'll suggest defaults, adjust as needed:"
- **Defaults by language:**

| Language   | test         | build            | lint              | format              |
|------------|-------------|------------------|-------------------|---------------------|
| go         | `make test` | `make build`     | `make lint`       | `gofmt -w .`        |
| python     | `pytest`    | _(empty)_        | `ruff check .`    | `ruff format .`     |
| typescript | `npm test`  | `npm run build`  | `npm run lint`    | `npx prettier --write .` |
| rust       | `cargo test`| `cargo build`    | `cargo clippy`    | `cargo fmt`         |
| other      | _(empty)_   | _(empty)_        | _(empty)_         | _(empty)_           |

- **Makefile refinement:** If a `Makefile` exists and language is not `go`, check for `test`, `build`, `lint`, `fmt`/`format` targets and prefer `make <target>` if found.
- **Display:** Show all four as a block, ask user to confirm or edit:
  ```
  Build commands (press Enter to accept, or provide alternatives):
    test:   make test
    build:  make build
    lint:   make lint
    format: gofmt -w .
  Accept? [Y/n]:
  ```
- If the user wants to edit, let them provide replacements for individual commands.

### Step 6: Review Routing

- **Prompt:** "Generate review routing based on language?"
- **Default:** Yes -- generate standard routing for the detected language.
- **Generated routing by language:**

**go:**
```yaml
review_routing:
  - patterns: ["*.go"]
    agents: [code-reviewer]
    exclude: ["*_test.go", "vendor/**"]
  - patterns: ["*_test.go"]
    agents: [code-reviewer]
  - patterns: ["*.sql", "migrations/**"]
    agents: [security-reviewer, code-reviewer]
  - patterns: ["Dockerfile", "docker-compose*.yml", ".github/**"]
    agents: [devops-automator]
```

**python:**
```yaml
review_routing:
  - patterns: ["*.py"]
    agents: [code-reviewer]
    exclude: ["test_*.py", "*_test.py", "tests/**"]
  - patterns: ["test_*.py", "*_test.py", "tests/**/*.py"]
    agents: [code-reviewer]
  - patterns: ["*.sql", "migrations/**", "alembic/**"]
    agents: [security-reviewer, code-reviewer]
  - patterns: ["Dockerfile", "docker-compose*.yml", ".github/**"]
    agents: [devops-automator]
```

**typescript:**
```yaml
review_routing:
  - patterns: ["*.ts", "*.tsx"]
    agents: [code-reviewer]
    exclude: ["*.test.ts", "*.test.tsx", "*.spec.ts", "*.spec.tsx"]
  - patterns: ["*.test.ts", "*.test.tsx", "*.spec.ts", "*.spec.tsx"]
    agents: [code-reviewer]
  - patterns: ["*.sql", "migrations/**", "prisma/**"]
    agents: [security-reviewer, code-reviewer]
  - patterns: ["Dockerfile", "docker-compose*.yml", ".github/**"]
    agents: [devops-automator]
```

**rust:**
```yaml
review_routing:
  - patterns: ["*.rs"]
    agents: [code-reviewer]
    exclude: ["tests/**"]
  - patterns: ["tests/**/*.rs"]
    agents: [code-reviewer]
  - patterns: ["*.sql", "migrations/**"]
    agents: [security-reviewer, code-reviewer]
  - patterns: ["Dockerfile", "docker-compose*.yml", ".github/**"]
    agents: [devops-automator]
```

**other:** empty array `[]` (user must configure manually)

- If user declines, set `review_routing: []`

## Summary and Confirmation

After all 6 prompts, display a formatted summary of all gathered values:

```
--- Summary ---

  Project:    my-app
  Language:   go
  Framework:  chi
  Database:   postgresql
  Test:       make test
  Build:      make build
  Lint:       make lint
  Format:     gofmt -w .
  Routing:    4 rules (go, tests, sql, infra)
  Extensions: .go, .sql

Proceed? [Y/n]:
```

If the user declines, ask which values to change and loop back to the specific step. Do not write any files until the user confirms.

## File Creation

Once confirmed, create files in this order:

1. **Create directories** if they do not exist:
   - `.claude/`
   - `.claude/rules/`
   - `.claude/agents/` (only if a domain agent will be created)

2. **Write `.claude/harness.yaml`** with the gathered values. Use `templates/harness.yaml.template` from the harness repo as a structural reference. Locate the harness repo by reading `harness_dir` from `~/.claude/.harness-manifest.json`.

   The generated file must conform to the v1 schema:
   - `schema_version: 1` (always)
   - `project.name` must match `^[a-z0-9][a-z0-9-]*$`
   - `stack.language` must be one of: `go`, `python`, `typescript`, `rust`, `other`
   - `stack.framework`: the detected/chosen framework, or `null`
   - `stack.frontend`: `null` (not prompted in v1)
   - `stack.database`: the detected/chosen database, or `null`
   - Build commands: quoted strings, or `""` for empty
   - `review_routing`: the generated/confirmed routing array, or `[]`
   - `extensions`: auto-derived from language:
     - go: `[".go", ".sql"]`
     - python: `[".py"]`
     - typescript: `[".ts", ".tsx", ".js"]`
     - rust: `[".rs"]`
     - other: `[]`
   - `anti_patterns: []` (starts empty, users add project-specific patterns later)

3. **Write `.claude/rules/beads-workflow.md`** from the template at `templates/beads-workflow.md.template` in the harness repo. This contains the standard beads workflow rules with an empty deprecated approaches table for the project to fill in.

4. **Initialize beads:** Run `bd init` if `.beads/` does not already exist. If it exists, skip with: "Beads already initialized, skipping." If `bd` is not installed, skip with: "bd not found -- skipping beads initialization. Install beads and run `bd init` manually."

5. **Prompt for optional files:**

   **Architecture decisions:** "Create `.claude/rules/architecture-decisions.md` with project design principles scaffold? [Y/n]"
   - If yes: create a scaffold with these section headers:
     - `## Decision Rules` -- with placeholder bullets for the project's design principles
     - `## Agent Operations Surface` -- with placeholder noting agentctl or equivalent if applicable

   **Domain agent:** "Create a domain expert agent scaffold? If so, what domain? (e.g., 'data-engineer', 'api-designer', press Enter to skip):"
   - If a domain is provided: create `.claude/agents/<domain>-expert.md` with a scaffold containing:
     - Role description placeholder
     - Skills list placeholder
     - Domain context section placeholder

6. **Write optional files** if requested.

## Post-Creation Validation

After writing all files, validate the generated `.claude/harness.yaml`:
- Verify it parses as valid YAML
- Verify `schema_version` is present and equals `1`
- Verify `project.name` matches the kebab-case pattern
- Verify `stack.language` is a valid enum value

Report success with a summary of all files created:
```
--- Done ---

N files created:
  - .claude/harness.yaml
  - .claude/rules/beads-workflow.md
  - .beads/ (bd init)
  [- .claude/rules/architecture-decisions.md]
  [- .claude/agents/<domain>-expert.md]

Run /harness-doctor to verify full setup.
```

## Rules

- **Never create** commands, skills, workflow agents, or hooks -- those are global (installed by `install.sh`).
- **Idempotent beads:** Skip `bd init` if `.beads/` already exists.
- **No silent overwrites:** Always prompt before replacing existing files.
- **User cancellation:** If the user cancels at any point during the interactive flow, exit cleanly without writing any files.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory, read it and include a "Project Stack Context" section (language, framework, database, build commands) in all subagent prompts and handoff prompts you produce.

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Harness not installed (no manifest) | Pre-flight check fails. Direct user to run `install.sh`. |
| `.claude/harness.yaml` already exists | Prompt to overwrite. Never silently replace. |
| `.beads/` already exists | Skip `bd init`, inform user. |
| Invalid project name entered | Re-prompt with validation explanation. |
| No language markers found | Default to `other`, inform user they can set it manually later. |
| Multiple language markers (go.mod + package.json) | Use priority order: go.mod > Cargo.toml > package.json > requirements.txt/pyproject.toml. Inform user of detection and allow override. |
| `bd` not installed | Warn but continue (skip beads init, note it in output). |
| User cancels mid-flow | No files written. Clean exit. |
| `.claude/` directory doesn't exist | Create it (and `.claude/rules/` subdirectory). |
