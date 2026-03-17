# Spec 11: harness-init Command (C11)

**Component:** C11 — harness-init Command
**Phase:** 4 (Project Commands)
**Scope:** Medium
**Dependencies:** C10 (config reader), C1 (repo scaffold — templates/ directory)
**Resolves:** DQ6 (harness-init interactive flow)
**References:** [architecture.md](architecture.md), [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md)

---

## 1. Overview

`/harness-init` is a Claude Code command that bootstraps a project for the work harness. It walks the user through a prompted sequence to gather stack information, then generates `.claude/harness.yaml`, initializes beads, and optionally scaffolds architecture rules and domain agent files.

This command is a markdown file interpreted by Claude Code. It contains prompt-level directives that instruct Claude to ask the user questions, auto-detect defaults, and write files. There is no shell logic — Claude is the executor.

---

## 2. Interactive Flow (DQ6 Resolution)

The command instructs Claude to run the following prompt sequence. Each step has a detection strategy for defaults and a fallback if detection fails.

### Step 1: Project Name
- **Prompt:** "Project name?"
- **Default:** basename of current working directory (e.g., `/home/user/src/my-app` -> `my-app`)
- **Validation:** must match `^[a-z0-9][a-z0-9-]*$` (kebab-case, per spec 00 section 4)
- **On invalid:** re-prompt with explanation

### Step 2: Language
- **Prompt:** "Primary language?"
- **Auto-detect:**
  - `go.mod` exists -> `go`
  - `package.json` exists -> `typescript`
  - `Cargo.toml` exists -> `rust`
  - `requirements.txt` or `pyproject.toml` or `setup.py` exists -> `python`
  - None detected -> `other`
- **Display:** "Detected: go (from go.mod). Accept? [Y/n]" — or present choices if no detection
- **Valid values:** `go`, `python`, `typescript`, `rust`, `other`

### Step 3: Framework
- **Prompt:** "Framework?" (only if language is not `other`)
- **Auto-detect by language:**
  - `go`: scan `go.mod` for known imports — `chi` (go-chi/chi), `gin` (gin-gonic/gin), `echo` (labstack/echo), `fiber` (gofiber/fiber)
  - `typescript`: scan `package.json` dependencies — `next` (nextjs), `express`, `fastify`, `hono`, `remix`
  - `python`: scan `requirements.txt`/`pyproject.toml` — `django`, `flask`, `fastapi`, `starlette`
  - `rust`: scan `Cargo.toml` — `actix-web`, `axum`, `rocket`, `warp`
- **Default:** skip (null) if nothing detected or language is `other`
- **Display:** "Detected: chi (from go.mod). Accept? [Y/n]" — or "Framework (optional, press Enter to skip):"

### Step 4: Database
- **Prompt:** "Database?"
- **Auto-detect:** Check for common indicators:
  - `docker-compose.yml`/`docker-compose.yaml`: scan for `postgres`, `mysql`, `mongo`, `redis` image names
  - Go: `go.mod` containing `pgx`, `go-sql-driver/mysql`, `mongo-driver`
  - Python: `requirements.txt` containing `psycopg`, `pymysql`, `pymongo`
  - TypeScript: `package.json` containing `pg`, `mysql2`, `mongoose`, `prisma`
- **Default:** skip (null) if nothing detected
- **Display:** "Detected: postgresql (from pgx in go.mod). Accept? [Y/n]" — or "Database (optional, press Enter to skip):"

### Step 5: Build Commands
- **Prompt:** "Build commands — I'll suggest defaults, adjust as needed:"
- **Defaults by language:**

| Language | test | build | lint | format |
|----------|------|-------|------|--------|
| go | `make test` | `make build` | `make lint` | `gofmt -w .` |
| python | `pytest` | _(empty)_ | `ruff check .` | `ruff format .` |
| typescript | `npm test` | `npm run build` | `npm run lint` | `npx prettier --write .` |
| rust | `cargo test` | `cargo build` | `cargo clippy` | `cargo fmt` |
| other | _(empty)_ | _(empty)_ | _(empty)_ | _(empty)_ |

- **Refinement:** If a `Makefile` exists and language is not `go`, check for `test`, `build`, `lint`, `fmt`/`format` targets and prefer `make <target>` if found
- **Display:** Show all four as a block, ask user to confirm or edit:
  ```
  Build commands (press Enter to accept, or provide alternatives):
    test:   make test
    build:  make build
    lint:   make lint
    format: gofmt -w .
  ```

### Step 6: Review Routing
- **Prompt:** "Generate review routing based on language?"
- **Default:** yes — generate standard routing for the detected language
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

**other:** empty array (user must configure manually)

- If user declines, set `review_routing: []`

### Step Summary
After all prompts, display a summary of all gathered values and ask for final confirmation before writing any files.

---

## 3. Files Created

### Always Created

#### `.claude/harness.yaml`
Generated from the prompted values. Uses `templates/harness.yaml.template` as the structural reference.

Example output for a Go/chi/PostgreSQL project:
```yaml
schema_version: 1

project:
  name: gaucho
  description: ""

stack:
  language: go
  framework: chi
  frontend: null
  database: postgresql

build:
  test: "make test"
  build: "make build"
  lint: "make lint"
  format: "gofmt -w ."

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

extensions: [".go", ".sql"]

anti_patterns: []
```

`extensions` is auto-derived from `stack.language` using defaults from spec 00 section 4 (go: `[".go", ".sql"]`, python: `[".py"]`, typescript: `[".ts", ".tsx", ".js"]`, rust: `[".rs"]`, other: `[]`).

`anti_patterns` starts empty — users add project-specific patterns later.

#### `.claude/rules/beads-workflow.md`
Generated from `templates/beads-workflow.md.template`. Contains the standard beads workflow rules with an empty deprecated approaches table for the project to fill in.

#### `.beads/` (via `bd init`)
Run `bd init` if `.beads/` does not already exist. If it exists, skip with a message: "Beads already initialized, skipping."

### Optionally Created (Prompted)

After writing the required files, prompt:

**Architecture decisions:** "Create `.claude/rules/architecture-decisions.md` with project design principles scaffold? [Y/n]"
- If yes: create a scaffold with section headers (Decision Rules, Deprecated Approaches reference, Agent Operations Surface placeholder)

**Domain agent:** "Create a domain expert agent scaffold? If so, what domain? (e.g., 'loan-originator', 'ml-engineer', press Enter to skip):"
- If provided: create `.claude/agents/<domain>-expert.md` with a scaffold containing role description placeholder, skills list, and domain context section

### Never Created

Commands, skills, workflow agents, hooks — these are global (installed by `install.sh`, specs C2-C7).

---

## 4. Templates

All paths relative to harness repo root.

### `templates/harness.yaml.template`

This is a structural reference, not a literal template engine file. Claude reads it to understand the expected shape and populates values from the prompt session.

```yaml
schema_version: 1

project:
  name: {{project_name}}
  description: ""

stack:
  language: {{language}}
  framework: {{framework}}
  frontend: null
  database: {{database}}

build:
  test: "{{build_test}}"
  build: "{{build_build}}"
  lint: "{{build_lint}}"
  format: "{{build_format}}"

review_routing: {{review_routing}}

extensions: {{extensions}}

anti_patterns: []
```

Placeholders (double-brace) are for documentation — Claude replaces them with actual values. Empty/null values: `framework: null`, `database: null`, build commands use empty string `""`.

### `templates/beads-workflow.md.template`

Standard beads workflow rules. Key sections:
- BEFORE STARTING ANY WORK (bd ready, bd list)
- NEVER EDIT CODE WITHOUT A BEADS ISSUE
- GATHER CONTEXT FROM CLOSED ISSUES FIRST
- Deprecated Approaches table (empty, project fills in)
- Essential Commands
- Complex Work (subtask patterns)
- Session Discipline
- Session End Checklist

The template matches the current beads-workflow.md content in gaucho but with the deprecated approaches table empty:

```markdown
## Deprecated Approaches (Do Not Follow)

These technologies were tried and replaced. Skip closed issues about them unless investigating why they were abandoned.

| Deprecated | Replaced By | When |
|-----------|------------|------|
| _(none yet)_ | | |
```

---

## 5. Implementation Steps

- [ ] **5.1** Create `templates/harness.yaml.template` with documented placeholders
- [ ] **5.2** Create `templates/beads-workflow.md.template` extracted from gaucho's beads-workflow.md, deprecated table emptied
- [ ] **5.3** Create `claude/commands/harness-init.md` with the full command text (see section 6)
- [ ] **5.4** Verify: command text includes all 6 prompt steps with auto-detection directives
- [ ] **5.5** Verify: command text includes "Never creates" guard (commands, skills, workflow agents, hooks)
- [ ] **5.6** Verify: command text references templates/ for structural guidance
- [ ] **5.7** Verify: command text includes validation directive (project name kebab-case, language enum)
- [ ] **5.8** Verify: generated harness.yaml passes C10 config reader validation
- [ ] **5.9** Verify: beads initialization is idempotent (skip if .beads/ exists)
- [ ] **5.10** Verify: optional files are prompted, not auto-created

---

## 6. Command Text Structure

`claude/commands/harness-init.md` contains a markdown document that Claude interprets. It is NOT a shell script. The structure:

```markdown
# /harness-init — Project Setup

Initialize this project for the work harness.

## Pre-flight Checks

1. Verify the harness is installed: check that `~/.claude/.harness-manifest.json` exists.
   If not found, tell the user to run `./install.sh` from the harness repo first and stop.
2. Check if `.claude/harness.yaml` already exists. If so, ask: "harness.yaml already exists.
   Overwrite? [y/N]". If no, stop.

## Interactive Setup

Walk through these prompts in order. For each, auto-detect a default and present it.
Accept Enter as confirmation of the default.

[... steps 1-6 as defined in section 2 ...]

## Summary and Confirmation

Display all gathered values in a formatted summary. Ask for final confirmation.
If declined, ask which values to change (loop back to specific step).

## File Creation

1. Create `.claude/` directory if it doesn't exist
2. Create `.claude/rules/` directory if it doesn't exist
3. Write `.claude/harness.yaml` with gathered values
   - Use `templates/harness.yaml.template` from the harness repo as structural reference
   - Harness repo location: read `harness_dir` from `~/.claude/.harness-manifest.json`
4. Write `.claude/rules/beads-workflow.md` from template
5. Run `bd init` if `.beads/` doesn't exist
6. Prompt for optional files (architecture-decisions.md, domain agent)
7. Write optional files if requested

## Post-Creation

Run validation:
- Verify `.claude/harness.yaml` parses as valid YAML
- Verify `schema_version` is present and equals 1
- Verify `project.name` matches kebab-case pattern
- Verify `stack.language` is a valid enum value

Report success with a summary of files created.

Suggest: "Run `/harness-doctor` to verify full setup."

## Rules

- **Never create** commands, skills, workflow agents, or hooks — those are global
- **Config injection**: include the directive from spec 00 section 8
- **Idempotent beads**: skip `bd init` if `.beads/` exists
```

---

## 7. Interface Contracts

### Exposes

| What | Consumed By | Contract |
|------|------------|----------|
| `.claude/harness.yaml` | C6 (hooks), C10 (config reader), C12 (harness-update), C13 (harness-doctor) | Valid v1 schema per spec 00 section 4 |
| `.claude/rules/beads-workflow.md` | Claude Code (loaded as rule) | Standard beads workflow with empty deprecated table |
| `.beads/` | beads CLI, hooks (C6) | Valid beads repository |

### Consumes

| What | From | Contract |
|------|------|----------|
| `~/.claude/.harness-manifest.json` | C7 (install.sh) | Must exist — pre-flight check. Reads `harness_dir` to locate templates |
| `templates/harness.yaml.template` | C1 (repo scaffold) | Structural reference for YAML generation |
| `templates/beads-workflow.md.template` | C1 (repo scaffold) | Content template for beads rule file |
| Config validation | C10 (config reader) | Post-creation validation of generated harness.yaml |

---

## 8. Testing Strategy

Since this is a Claude Code command (markdown interpreted by Claude, not a shell script), testing is manual verification and `/harness-doctor` checks.

### Manual Test Cases

**TC1: Fresh project (no existing config)**
1. `cd` into a Go project with `go.mod` (uses chi, pgx)
2. Run `/harness-init`
3. Verify: auto-detects go, chi, postgresql
4. Verify: build defaults are `make test`, `make build`, `make lint`, `gofmt -w .`
5. Verify: `.claude/harness.yaml` written with correct values
6. Verify: `.claude/rules/beads-workflow.md` written
7. Verify: `.beads/` initialized
8. Verify: `/harness-doctor` passes

**TC2: Project with existing harness.yaml**
1. Run `/harness-init` in a project that already has `.claude/harness.yaml`
2. Verify: prompted to overwrite
3. On decline: command stops, no files changed
4. On accept: new values written

**TC3: Python project**
1. `cd` into a project with `requirements.txt` containing `fastapi`, `psycopg`
2. Run `/harness-init`
3. Verify: auto-detects python, fastapi, postgresql
4. Verify: build defaults are `pytest`, empty, `ruff check .`, `ruff format .`

**TC4: Unknown language project**
1. `cd` into a project with no recognizable language markers
2. Run `/harness-init`
3. Verify: language defaults to `other`, framework skipped, build commands all empty
4. Verify: `extensions: []`, `review_routing: []`

**TC5: Harness not installed**
1. Remove `~/.claude/.harness-manifest.json`
2. Run `/harness-init`
3. Verify: pre-flight check fails with message directing user to install

**TC6: Beads already initialized**
1. Run `bd init` manually, then `/harness-init`
2. Verify: beads step skipped with "already initialized" message

**TC7: Optional files**
1. Run `/harness-init`, accept architecture-decisions.md, provide "loan-originator" as domain
2. Verify: `.claude/rules/architecture-decisions.md` created with scaffold
3. Verify: `.claude/agents/loan-originator-expert.md` created with scaffold

---

## 9. Example Output

```
$ /harness-init

Checking harness installation... OK (v1.0.0)

--- Project Setup ---

1. Project name [my-app]: my-app
2. Language — detected: go (from go.mod). Accept? [Y/n]: Y
3. Framework — detected: chi (from go.mod: go-chi/chi). Accept? [Y/n]: Y
4. Database — detected: postgresql (from go.mod: jackc/pgx). Accept? [Y/n]: Y
5. Build commands (press Enter to accept defaults):
     test:   make test
     build:  make build
     lint:   make lint
     format: gofmt -w .
   Accept? [Y/n]: Y
6. Generate review routing for Go? [Y/n]: Y

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

Proceed? [Y/n]: Y

Creating files...
  ✓ .claude/harness.yaml
  ✓ .claude/rules/beads-workflow.md
  ✓ .beads/ (bd init)

Optional scaffolds:
  Create .claude/rules/architecture-decisions.md? [Y/n]: Y
  ✓ .claude/rules/architecture-decisions.md

  Create a domain expert agent? Enter domain name (or press Enter to skip): loan-originator
  ✓ .claude/agents/loan-originator-expert.md

--- Done ---

4 files created. Run /harness-doctor to verify setup.
```

---

## 10. Edge Cases and Error Handling

| Scenario | Handling |
|----------|----------|
| Harness not installed (no manifest) | Pre-flight check fails. Direct user to run `install.sh`. |
| `.claude/harness.yaml` already exists | Prompt to overwrite. Never silently replace. |
| `.beads/` already exists | Skip `bd init`, inform user. |
| Invalid project name entered | Re-prompt with validation explanation. |
| No language markers found | Default to `other`, inform user they can set it manually later. |
| Multiple language markers (go.mod + package.json) | Use priority order: go.mod > Cargo.toml > package.json > requirements.txt/pyproject.toml. Inform user of detection and allow override. |
| `bd` not installed | Pre-flight: check `command -v bd`. If missing, warn but continue (skip beads init, note it in output). |
| User cancels mid-flow | No files written. Clean exit. |
| `.claude/` directory doesn't exist | Create it (and `.claude/rules/` subdirectory). |

---

## 11. Acceptance Criteria

1. Command file exists at `claude/commands/harness-init.md`
2. Template files exist at `templates/harness.yaml.template` and `templates/beads-workflow.md.template`
3. Interactive flow covers all 6 steps with auto-detection and defaults
4. Generated `harness.yaml` conforms to v1 schema (spec 00 section 4)
5. Generated `beads-workflow.md` contains empty deprecated approaches table
6. Pre-flight check verifies harness installation before proceeding
7. Existing `harness.yaml` prompts for overwrite confirmation
8. Beads initialization is idempotent (skips if `.beads/` exists)
9. Optional files (architecture-decisions.md, domain agent) are prompted, not auto-created
10. Post-creation validation confirms generated YAML is parseable and schema-compliant
11. Never creates commands, skills, workflow agents, or hooks
