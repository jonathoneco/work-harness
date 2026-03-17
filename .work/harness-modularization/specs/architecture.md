# Architecture: claude-work-harness

## Problem Statement

The workflow harness — commands, skills, agents, hooks, and rules that live in `.claude/` — is duplicated between gaucho and dotfiles. Changes require manual sync. It's not shareable: friends would need to copy files and figure out wiring themselves.

## Goals

1. **Single source of truth**: One git repo owns the harness. No duplication.
2. **User-level install**: `./install.sh` deploys to `~/.claude/`. Claude Code discovers everything natively.
3. **Project-level customization**: Projects declare their stack in `.claude/harness.yaml`. Content files override via native precedence (project > user). Hooks read config at runtime.
4. **Shareable**: Friends clone, run install, get a working harness.
5. **Self-hosting**: The harness includes `workflow-meta` for improving itself.
6. **Clean uninstall**: Manifest tracks everything the harness added.

## Non-Goals

- Plugin/marketplace distribution (future)
- CI/CD headless mode (future)
- Multi-language project support in v1 (future — `stack.languages: [go, ts]`)
- Shipping domain-expertise review agents (use agency-agents)

---

## Remaining Questions Resolved

### Q1: agency-agents integration
**Resolution: Document as recommended companion.** The install script checks if agency-agents is installed (`~/.claude/agents/code-reviewer.md` or similar) and prints a suggestion if not found. `harness-init` generates `review_routing` entries referencing agent names — users must have those agents installed from agency-agents or custom. `/harness-doctor` verifies referenced agents exist.

**Rationale:** agency-agents has its own lifecycle, install script, and update mechanism. Auto-installing it couples two independent repos. Users who don't want 160+ agents shouldn't be forced into them.

### Q2: Harness repo naming
**Resolution: `claude-work-harness`.** Descriptive: Claude Code tool, work methodology, harness infrastructure. Distinguishes from agency-agents (which is agent content, not workflow infrastructure).

### Q3: Code-quality language packs
**Resolution: Directive-based selection.** `skills/code-quality.md` contains general principles. It includes a directive: *"Read `references/<language>-anti-patterns.md` where `<language>` is `stack.language` from `.claude/harness.yaml`."* All language pack files ship globally in `~/.claude/skills/code-quality/references/`. Adding a new language means adding one file. The skill text is language-agnostic; the reference file is language-specific.

### Q4: pr-gate.sh parameterization
**Resolution: pr-gate.sh reads harness.yaml directly.** It's a global hook (registered in `~/.claude/settings.json` by install.sh, runs for all projects). On invocation:
1. Checks for `.claude/harness.yaml` in current directory
2. If absent → exit 0 (skip — project not harness-enabled)
3. If present → reads `build.format`, `build.lint`, `build.build` via yq
4. Runs each non-empty command

Consistent with decision #8 (config over templates) and #9 (absolute paths for hooks).

---

## Component Map

### C1: Repo Scaffold
**Scope:** Small
Directory structure, VERSION, README, LICENSE, .gitignore.

### C2: Content Files — Commands
**Scope:** Medium (extract + parameterize)
10 commands shipped to `~/.claude/commands/`:
- `work.md`, `work-deep.md`, `work-feature.md`, `work-fix.md`
- `work-review.md`, `work-checkpoint.md`, `work-reground.md`
- `work-redirect.md`, `work-status.md`, `work-archive.md`

Parameterization: Commands that spawn subagents must inject `harness.yaml` stack context into subagent prompts and handoff prompts (decision #13). This means command text includes a config-reading preamble.

### C3: Content Files — Skills
**Scope:** Medium
4 skills shipped to `~/.claude/skills/`:
- `work-harness.md` — workflow conventions
- `code-quality.md` — general quality principles + language pack directive
- `workflow-meta.md` — self-hosting
- `serena-activate.md` — LSP integration

Plus `skills/code-quality/references/`:
- `go-anti-patterns.md` (ship now)
- Future: `python-anti-patterns.md`, `typescript-anti-patterns.md`, `rust-anti-patterns.md`

### C4: Content Files — Agents
**Scope:** Small
4 workflow agents shipped to `~/.claude/agents/`:
- `work-research.md`, `work-review.md`, `work-implement.md`, `work-spec.md`

These are workflow agents (harness-owned). Domain expertise agents come from agency-agents or custom.

### C5: Content Files — Rules
**Scope:** Small
2 rules shipped to `~/.claude/rules/`:
- `workflow.md` — harness conventions and command reference
- `workflow-detect.md` — active task detection at session start

### C6: Hooks
**Scope:** Medium (parameterize to read harness.yaml)
Shell scripts that stay in the harness repo (referenced by absolute path):
- `state-guard.sh` — prevents state.json corruption
- `work-check.sh` — session start checks
- `beads-check.sh` — beads workflow enforcement
- `review-gate.sh` — review quality gates
- `artifact-gate.sh` — artifact validation
- `review-verify.sh` — review verification
- `pr-gate.sh` — pre-commit formatting/linting/building

All hooks check for `.claude/harness.yaml` and exit 0 if not present (graceful skip for non-harness projects).

### C7: Install Script
**Scope:** Large (hardest component)
`install.sh` handles three modes: install, update, uninstall.

**Install:**
1. Verify dependencies (jq, yq, git, beads)
2. Copy content files (C2-C5) to `~/.claude/` subdirectories
3. Merge hook entries into `~/.claude/settings.json` (pointing to `<harness-dir>/hooks/`)
4. Append harness block to `~/.claude/CLAUDE.md` (tagged with `<!-- harness:start -->` / `<!-- harness:end -->`)
5. Write manifest to `~/.claude/.harness-manifest.json`

**Update:**
1. Read existing manifest
2. Compare repo files vs installed files
3. Copy new/changed files, remove deleted files
4. Re-merge hook entries
5. Check `schema_version` — run migrations if needed
6. Update manifest

**Uninstall:**
1. Read manifest
2. Remove all files listed in manifest from `~/.claude/`
3. De-merge hook entries from `settings.json`
4. Remove harness block from `CLAUDE.md`
5. Remove manifest

### C8: Settings Merger (`lib/merge.sh`)
**Scope:** Medium
jq-based merge/de-merge for `~/.claude/settings.json`:
- **Hooks:** append-if-not-present to hook arrays (e.g., `hooks.PreToolUse`, `hooks.PostToolUse`)
- **Scalars:** set-if-absent (don't overwrite user values)
- **De-merge:** Remove entries that match harness-added patterns
- **Idempotent:** Running twice produces same result

### C9: Schema Migrator (`lib/migrate.sh`)
**Scope:** Small
Sequential migration functions keyed by `schema_version` in `harness.yaml`:
- `migrate_1_to_2()`, `migrate_2_to_3()`, etc.
- Each migration transforms harness.yaml in-place
- Install script runs all applicable migrations on update

### C10: Config Reader (`lib/config.sh`)
**Scope:** Small
Shared shell functions for hooks to read `harness.yaml`:
- `harness_config_get <key>` — read a value via yq
- `harness_config_list <key>` — read an array
- `harness_has_config` — check if `.claude/harness.yaml` exists in cwd
- `harness_dir` — resolve harness repo path (from manifest or env)

### C11: harness-init Command
**Scope:** Medium
Claude Code command (`commands/harness-init.md`) that creates project grounding:

**Always creates:**
- `.claude/harness.yaml` — prompted values (name, language, framework, db, build commands)
- `.claude/rules/beads-workflow.md` — template with empty deprecated approaches table
- `.beads/` — via `bd init` if not already initialized

**Optionally creates (prompted):**
- `.claude/rules/architecture-decisions.md` — project design principles scaffold
- `.claude/agents/<domain>-expert.md` — domain agent scaffold

**Never creates:**
- Commands, skills, workflow agents, hooks (these live globally)

### C12: harness-update Command
**Scope:** Small
Claude Code command that checks project health vs harness version:
- Reports `schema_version` compatibility
- Lists local overrides (project files shadowing global harness files)
- Suggests new features available since last project setup

### C13: harness-doctor Command
**Scope:** Small
Claude Code command that runs health checks:
- `harness.yaml` exists and parses
- All agents in `review_routing` exist in `~/.claude/agents/` or `.claude/agents/`
- All hooks in `settings.json` are executable
- Beads is initialized
- Schema version compatibility

---

## Data Flow

### Install Flow
```
User clones repo → runs ./install.sh
  │
  ├─ Copies commands/ → ~/.claude/commands/
  ├─ Copies skills/   → ~/.claude/skills/
  ├─ Copies agents/   → ~/.claude/agents/
  ├─ Copies rules/    → ~/.claude/rules/
  ├─ Merges hooks into ~/.claude/settings.json
  │   (paths point to <harness-repo>/hooks/)
  ├─ Appends to ~/.claude/CLAUDE.md
  └─ Writes ~/.claude/.harness-manifest.json
```

### Runtime Flow (Claude Code Session)
```
Claude Code starts
  │
  ├─ Loads ~/.claude/rules/ (including workflow.md, workflow-detect.md)
  ├─ Loads ~/.claude/commands/ (work.md, work-deep.md, etc.)
  ├─ Loads ~/.claude/skills/ (work-harness.md, code-quality.md)
  ├─ Loads ~/.claude/agents/ (work-research.md, etc.)
  ├─ Reads ~/.claude/settings.json → registers hooks
  │
  User runs /work or /work-deep
  │
  ├─ Command reads .claude/harness.yaml from project dir
  ├─ Injects stack context into subagent prompts
  ├─ Spawns workflow agents with skills: [work-harness, code-quality]
  │   └─ code-quality skill reads references/<language>-anti-patterns.md
  │       where language comes from harness.yaml stack.language
  └─ Hooks fire on tool use → read harness.yaml → apply project-specific behavior
```

### Project Init Flow
```
User runs /harness-init in project
  │
  ├─ Prompts: name, language, framework, db, build commands
  ├─ Writes .claude/harness.yaml
  ├─ Writes .claude/rules/beads-workflow.md (template)
  ├─ Runs bd init
  └─ Optional: architecture-decisions.md, domain agent scaffold
```

### Override Flow
```
Global: ~/.claude/rules/code-quality.md (harness default)
Project: .claude/rules/code-quality.md (project override)

Claude Code loads project version, ignores global.
No harness mechanism needed — native precedence.
```

---

## Repo Structure

```
claude-work-harness/
├── install.sh                         # Entry point: install/update/uninstall
├── VERSION                            # Harness version (semver)
├── README.md                          # Setup instructions
├── LICENSE                            # MIT
│
├── lib/                               # Install infrastructure (NOT copied to ~/.claude/)
│   ├── config.sh                      # yq helpers for reading harness.yaml
│   ├── merge.sh                       # Settings merge/de-merge (jq-based)
│   └── migrate.sh                     # Schema version migrations
│
├── claude/                            # Mirrors ~/.claude/ — contents copied on install
│   ├── commands/
│   │   ├── work.md
│   │   ├── work-deep.md
│   │   ├── work-feature.md
│   │   ├── work-fix.md
│   │   ├── work-review.md
│   │   ├── work-checkpoint.md
│   │   ├── work-reground.md
│   │   ├── work-redirect.md
│   │   ├── work-status.md
│   │   ├── work-archive.md
│   │   ├── harness-init.md
│   │   ├── harness-update.md
│   │   └── harness-doctor.md
│   │
│   ├── skills/
│   │   ├── work-harness.md
│   │   ├── code-quality.md
│   │   ├── workflow-meta.md
│   │   ├── serena-activate.md
│   │   └── code-quality/
│   │       └── references/
│   │           └── go-anti-patterns.md
│   │
│   ├── agents/
│   │   ├── work-research.md
│   │   ├── work-review.md
│   │   ├── work-implement.md
│   │   └── work-spec.md
│   │
│   └── rules/
│       ├── workflow.md
│       └── workflow-detect.md
│
├── hooks/                             # Stay here — referenced by absolute path
│   ├── state-guard.sh
│   ├── work-check.sh
│   ├── beads-check.sh
│   ├── review-gate.sh
│   ├── artifact-gate.sh
│   ├── review-verify.sh
│   └── pr-gate.sh
│
└── templates/                         # Used by harness-init command
    ├── harness.yaml.template
    └── beads-workflow.md.template
```

### Why `claude/` not root-level commands/skills/agents?
The `claude/` directory mirrors the target `~/.claude/` structure exactly. This makes install.sh trivially simple: `cp -r claude/* ~/.claude/`. It also makes it visually clear what ends up where.

### Why hooks/ is separate from claude/?
Hooks are shell scripts referenced by absolute path in settings.json. They don't need to be in `~/.claude/` for Claude Code to find them — settings.json already points to their location. Keeping them in the repo means updates are instant (git pull) without re-running install.

---

## Technology Choices

| Choice | Rationale |
|--------|-----------|
| **Shell (POSIX sh)** for install script + hooks | Zero additional dependencies. Runs everywhere. |
| **jq** for settings.json merge | Already widely installed. Precise JSON manipulation. Required dependency. |
| **yq** for harness.yaml reading | YAML is more readable than JSON for config. Required dependency. |
| **Git** for distribution | Users know git. No package manager needed. |
| **Beads** for issue tracking | Hard dependency. The harness workflow requires it. Pinned version. |
| **Manifest file** for tracking | Simple, inspectable, no database. JSON file at `~/.claude/.harness-manifest.json`. |

---

## Manifest Schema

`~/.claude/.harness-manifest.json`:
```json
{
  "harness_version": "1.0.0",
  "harness_dir": "/home/user/src/claude-work-harness",
  "schema_version": 1,
  "installed_at": "2026-03-16T18:00:00Z",
  "updated_at": "2026-03-16T18:00:00Z",
  "files": [
    "commands/work.md",
    "commands/work-deep.md",
    "skills/work-harness.md",
    "skills/code-quality.md",
    "skills/code-quality/references/go-anti-patterns.md",
    "agents/work-research.md",
    "rules/workflow.md"
  ],
  "hooks_added": [
    {
      "event": "PreToolUse",
      "matcher": "Edit|Write|NotebookEdit",
      "command": "/home/user/src/claude-work-harness/hooks/state-guard.sh"
    }
  ],
  "claude_md_tag": "harness"
}
```

---

## harness.yaml Schema (v1)

```yaml
schema_version: 1

project:
  name: my-project
  description: "Brief project description"

stack:
  language: go              # go | python | typescript | rust | other
  framework: chi            # optional
  frontend: null            # optional (e.g., nextjs, react)
  database: postgresql      # optional

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
  - patterns: ["Dockerfile", "docker-compose*.yml", ".github/**"]
    agents: [devops-automator]

# Code file extensions for hooks
extensions: [".go", ".sql"]

# Anti-pattern regexes for review-gate (language-specific)
anti_patterns:
  - pattern: "_, _ ="
    description: "Swallowed error return"
  - pattern: '_ = .*\.Exec\('
    description: "Unchecked database exec"
```

---

## Failure Mode Requirements

These are architectural requirements. All components MUST follow them.

### R1: Runtime dependency checking
All hooks and `lib/` functions that invoke `jq` or `yq` MUST check for the binary before use and emit a descriptive error:
```sh
command -v yq >/dev/null 2>&1 || { echo "harness: yq required but not found. Run install.sh to verify." >&2; exit 2; }
```
This applies to C6 (hooks), C10 (config reader), and any shell code in C7 (install).

### R2: Malformed harness.yaml
Hooks distinguish two states:
- **File not found** → exit 0 (graceful skip — project not harness-enabled)
- **File found but malformed YAML** → exit 2 with descriptive error (fail-closed)

C10 (`lib/config.sh`) provides `harness_validate_config` that hooks call after confirming the file exists. It runs `yq eval '.' .claude/harness.yaml > /dev/null 2>&1` and exits 2 on failure.

### R3: Corrupted manifest
If `~/.claude/.harness-manifest.json` is unreadable (invalid JSON, truncated):
- `install.sh --update` → exit with error directing user to run `install.sh --force` (fresh install)
- `install.sh --uninstall` → exit with error directing user to manually remove harness files or run `install.sh --force` then `--uninstall`
- Never silently fall back to fresh install — the user must confirm destructive recovery.

---

## Dependency Order

```
C10 (config reader) ←── C6 (hooks), C7 (install), C9 (migrator)
C8 (settings merger) ←── C7 (install)
C9 (schema migrator) ←── C7 (install, update mode)
C1 (repo scaffold) ←── everything
C2-C5 (content files) ←── C7 (install copies them)
C6 (hooks) ←── C7 (install registers them)
C11-C13 (init/update/doctor) ←── C2 (they're commands, part of content)
```

**Implementation phases:**
1. **Foundation:** C1 (scaffold), C10 (config reader), C8 (settings merger)
2. **Core:** C2-C5 (content files), C6 (hooks), C9 (migrator)
3. **Install:** C7 (install script — depends on C8, C9, C10 and copies C2-C6)
4. **Commands:** C11-C13 (harness-init/update/doctor — content that uses the installed infrastructure)

---

## Scope Exclusions

- **No domain agents ship**: Harness owns workflow agents only. Domain expertise (code-reviewer, security-engineer, etc.) comes from agency-agents or custom.
- **No test framework**: The harness is shell scripts and markdown — tested manually and via `/harness-doctor`.
- **No package manager**: Distribution is git clone + install script.
- **No CI/CD integration**: v1 is local-only.
- **No multi-language support**: v1 supports one `stack.language` per project.
- **No automatic agency-agents install**: Documented as recommended companion.

---

## Questions Deferred to Spec

1. **Exact hook registration format**: Which hook events (PreToolUse, PostToolUse, etc.) does each hook register for? What are the matchers?
2. **CLAUDE.md content**: What exactly gets appended? How much context vs just pointers?
3. **Config injection boilerplate**: The exact preamble text that commands insert for harness.yaml reading.
4. **Migration function signatures**: How do migrations receive/return config data?
5. **Conflict detection**: How does install.sh handle existing files that aren't harness-managed?
6. **harness-init interactive flow**: Exact prompt sequence and defaults per language.
