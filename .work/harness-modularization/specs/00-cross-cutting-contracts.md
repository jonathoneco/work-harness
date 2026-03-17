# Spec 00: Cross-Cutting Contracts

All component specs reference this document. Changes here propagate to all components.

---

## 1. Path Conventions

### Harness Repo Paths
```
<harness-dir>/                          # Root of claude-work-harness clone
  install.sh                            # Entry point
  VERSION                               # Semver string (e.g., "1.0.0")
  lib/config.sh                         # C10: yq helpers
  lib/merge.sh                          # C8: settings merge/de-merge
  lib/migrate.sh                        # C9: schema migrations
  claude/                               # Mirrors ~/.claude/ — copied on install
    commands/<name>.md                   # C2: work commands + C11-C13
    skills/<name>.md                     # C3: skills
    skills/code-quality/references/      # C3: language packs
    agents/<name>.md                     # C4: workflow agents
    rules/<name>.md                      # C5: rules
  hooks/<name>.sh                       # C6: stay in repo, absolute path refs
  templates/<name>.template             # Templates for harness-init
```

### Install Target Paths
```
~/.claude/
  commands/<name>.md                    # Copied from claude/commands/
  skills/<name>.md                      # Copied from claude/skills/
  skills/code-quality/references/       # Copied from claude/skills/code-quality/references/
  agents/<name>.md                      # Copied from claude/agents/
  rules/<name>.md                       # Copied from claude/rules/
  settings.json                         # Hook entries MERGED (not replaced)
  CLAUDE.md                             # Harness block APPENDED (tagged)
  .harness-manifest.json                # Manifest (created by install)
```

### Project Paths (created by harness-init)
```
<project>/
  .claude/
    harness.yaml                        # Project config (v1 schema)
    rules/beads-workflow.md             # Template with project-specific table
    rules/architecture-decisions.md     # Optional scaffold
    agents/<domain>-expert.md           # Optional domain agent scaffold
  .beads/                               # Initialized by bd init
  .work/                                # Created by workflow commands at runtime
```

---

## 2. Naming Conventions

### Files
- **Commands**: `kebab-case.md` — e.g., `work-deep.md`, `harness-init.md`
- **Skills**: `kebab-case.md` — e.g., `work-harness.md`, `code-quality.md`
- **Agents**: `kebab-case.md` — e.g., `work-research.md`, `work-review.md`
- **Rules**: `kebab-case.md` — e.g., `workflow.md`, `workflow-detect.md`
- **Hooks**: `kebab-case.sh` — e.g., `state-guard.sh`, `pr-gate.sh`
- **Lib scripts**: `kebab-case.sh` — e.g., `config.sh`, `merge.sh`
- **Language packs**: `<language>-anti-patterns.md` — e.g., `go-anti-patterns.md`

### Shell Functions
- Prefix: `harness_` — e.g., `harness_config_get`, `harness_merge_hooks`
- Underscore-separated, lowercase
- No abbreviations in public API functions

### Variables
- **Shell**: `HARNESS_` prefix for exported vars — e.g., `HARNESS_DIR`, `HARNESS_VERSION`
- **Local**: lowercase, underscore-separated — e.g., `config_file`, `hook_entry`

### Error Messages
- Prefix: `harness:` — e.g., `harness: yq required but not found`
- To stderr: `echo "harness: <message>" >&2`

---

## 3. Exit Codes

All hooks and lib functions use these standard exit codes:

| Code | Meaning | When |
|------|---------|------|
| 0 | Success / graceful skip | Normal completion, or harness.yaml not found (skip) |
| 1 | General error | Unexpected failures, runtime errors |
| 2 | Blocked — hard error | Missing dependency, malformed config, corrupted manifest |

**Hook-specific behavior:**
- Claude Code treats exit 0 as pass, exit 2 as block (message shown to user), exit 1 as warning
- Hooks output blocking messages to stderr: `echo "message" >&2; exit 2`

---

## 4. harness.yaml Schema (v1)

Full schema. All fields shown. Required fields marked with `*`.

```yaml
schema_version: 1                      # * integer, always 1 for v1

project:
  name: my-project                     # * string, project identifier
  description: "Brief description"     # optional string

stack:
  language: go                         # * enum: go | python | typescript | rust | other
  framework: chi                       # optional string (free-form)
  frontend: null                       # optional string (e.g., nextjs, react)
  database: postgresql                 # optional string (e.g., postgresql, mysql, sqlite)

build:
  test: "make test"                    # optional string, test command
  build: "make build"                  # optional string, build command
  lint: "make lint"                    # optional string, lint command
  format: "gofmt -w ."                # optional string, format command

# Maps file patterns to review agent names.
# Agents must exist in ~/.claude/agents/ or .claude/agents/.
review_routing:                        # optional array
  - patterns: ["*.go"]                 # * array of glob strings
    agents: [code-reviewer]            # * array of agent name strings (without .md)
    exclude: ["*_test.go"]             # optional array of glob strings

# File extensions considered "code" by hooks (e.g., for formatting checks)
extensions: [".go", ".sql"]           # optional array of strings

# Anti-pattern regexes for review-gate hook
anti_patterns:                         # optional array
  - pattern: "_, _ ="                  # * string (regex)
    description: "Swallowed error"     # * string
```

### Validation Rules
- `schema_version` must be a positive integer
- `project.name` must match `^[a-z0-9][a-z0-9-]*$` (kebab-case)
- `stack.language` must be one of the enum values
- `review_routing[].patterns` must be non-empty if entry exists
- `review_routing[].agents` must be non-empty if entry exists
- `anti_patterns[].pattern` must be a valid regex

### Defaults (applied by harness-init when user skips a prompt)
- `stack.language`: `other`
- `build.*`: empty (no command)
- `review_routing`: empty array
- `extensions`: inferred from `stack.language` — go: `[".go", ".sql"]`, python: `[".py"]`, typescript: `[".ts", ".tsx", ".js"]`, rust: `[".rs"]`, other: `[]`
- `anti_patterns`: empty array

---

## 5. Manifest Schema

`~/.claude/.harness-manifest.json` — tracks what install.sh added.

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
    "agents/work-research.md",
    "rules/workflow.md"
  ],
  "hooks_added": [
    {
      "event": "PostToolUse",
      "matcher": "Write|Edit",
      "command": "/home/user/src/claude-work-harness/hooks/state-guard.sh"
    },
    {
      "event": "Stop",
      "matcher": "",
      "command": "/home/user/src/claude-work-harness/hooks/work-check.sh"
    }
  ],
  "claude_md_tag": "harness"
}
```

### Field Definitions
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `harness_version` | string | yes | Semver from VERSION file at install time |
| `harness_dir` | string | yes | Absolute path to harness repo clone |
| `schema_version` | integer | yes | Schema version at install time |
| `installed_at` | string | yes | ISO 8601 timestamp |
| `updated_at` | string | yes | ISO 8601 timestamp, updated on each install/update |
| `files` | string[] | yes | Paths relative to `~/.claude/` of all copied files |
| `hooks_added` | object[] | yes | Hook entries added to settings.json |
| `hooks_added[].event` | string | yes | Claude Code hook event name |
| `hooks_added[].matcher` | string | yes | Tool matcher pattern (empty string for non-tool events) |
| `hooks_added[].command` | string | yes | Absolute path to hook script |
| `claude_md_tag` | string | yes | Tag name used in CLAUDE.md markers |

### Invariants
- `files[]` entries are relative to `~/.claude/` (no leading slash or `~/`)
- `hooks_added[].command` is always an absolute path
- `claude_md_tag` is always `"harness"` in v1

---

## 6. Claude Code Hook Registration Format

Hooks are registered in `~/.claude/settings.json` under the `hooks` key.

```json
{
  "hooks": {
    "<event>": [
      {
        "matcher": "<tool-pattern>",
        "hooks": [
          {
            "type": "command",
            "command": "<absolute-path-to-script>"
          }
        ]
      }
    ]
  }
}
```

### Events Used by Harness
| Event | Fires When | Matcher Semantics |
|-------|-----------|-------------------|
| `PreToolUse` | Before a tool executes | Pipe-delimited tool names (e.g., `"Edit\|Write"`) |
| `PostToolUse` | After a tool executes | Same as PreToolUse |
| `Stop` | Before session ends | Empty string (always fires) |
| `SessionStart` | Session begins | Empty string |
| `PostCompact` | After context compaction | Empty string |
| `UserPromptSubmit` | Before processing user message | Empty string |

### Merge Rules (for settings merger C8)
- **Hook arrays are append-only**: New entries are appended to existing event arrays
- **Dedup by command path**: If a hook with the same command path already exists under the same event+matcher, skip it
- **Never overwrite**: Existing user hooks are preserved
- **Matcher grouping**: Harness hooks with the same event+matcher MAY be grouped into one entry with multiple hooks, or kept as separate entries. The merger keeps them as separate entries for simpler dedup.

---

## 7. CLAUDE.md Tag Format

Install script appends a tagged block to `~/.claude/CLAUDE.md`:

```markdown
<!-- harness:start -->
## Work Harness

This environment uses the [claude-work-harness](https://github.com/<user>/claude-work-harness).
Commands, skills, agents, and rules are installed globally. Projects customize via `.claude/harness.yaml`.

See `/harness-doctor` to check health. See `/harness-update` to check compatibility.
<!-- harness:end -->
```

### Rules
- Tags use HTML comments: `<!-- harness:start -->` and `<!-- harness:end -->`
- Content between tags is replaced on update (not appended again)
- Uninstall removes everything between and including the tags
- If tags are found but content differs, update replaces content between tags
- If no tags found, append block at end of file
- If CLAUDE.md doesn't exist, create it with just the harness block

---

## 8. Config Injection Pattern

Commands that spawn subagents or produce handoff prompts inject stack context from harness.yaml. This is the standard preamble:

```markdown
## Project Stack Context

_Auto-injected from `.claude/harness.yaml`:_

- **Language**: {{stack.language}}
- **Framework**: {{stack.framework}}
- **Database**: {{stack.database}}
- **Build**: `{{build.test}}`
- **Lint**: `{{build.lint}}`
```

### Resolution Rules
- If `.claude/harness.yaml` doesn't exist: omit the preamble entirely (no error)
- If a field is null/empty: omit that line
- Commands read harness.yaml at invocation time (not cached)
- The preamble is injected into:
  1. Subagent prompts (so spawned agents know the stack)
  2. Handoff prompts (so the next step's reader has context)

### Implementation
Commands include a shell block at the top that reads harness.yaml and constructs the preamble. The exact implementation is a shell snippet that runs before the command's main logic. Since Claude Code commands are markdown files interpreted by Claude, the config injection is a *directive* in the command text:

```markdown
**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.
```

This is a prompt-level directive, not a shell script. Claude reads the config and injects it.

---

## 9. Shell Script Conventions

All shell scripts (hooks, lib, install.sh) follow these conventions:

```sh
#!/bin/sh
# harness: <brief description>
# Component: C<N>
set -eu
```

- **Shebang**: `#!/bin/sh` (POSIX sh, not bash)
- **Header comment**: `harness:` prefix with description
- **Strict mode**: `set -eu` (exit on error, undefined vars)
- **No bashisms**: No arrays, no `[[ ]]`, no `{a,b}` brace expansion. `$(( ))` arithmetic is POSIX-compliant and allowed.
- **Quoting**: All variable expansions quoted (`"$var"`, not `$var`)
- **Dependency check**: Scripts that use jq/yq check for the binary before first use (R1)
- **Config validation**: Scripts that read harness.yaml validate it parses (R2)

### Sourcing Pattern
Hooks source lib scripts:
```sh
HARNESS_DIR="$(harness_dir)"  # or from manifest
. "$HARNESS_DIR/lib/config.sh"
```

---

## 10. VERSION File Format

Single line, semver, no trailing newline:
```
1.0.0
```

- Format: `MAJOR.MINOR.PATCH`
- No `v` prefix
- Read by install.sh: `HARNESS_VERSION=$(cat "$HARNESS_DIR/VERSION")`

---

## 11. Deferred Question Resolutions (Spec 00 Scope)

### DQ1: Hook Registration Format (partial — per-hook details in spec 08)
Resolved in Section 6 above. Format uses the Claude Code `hooks` object in `settings.json` with `event`, `matcher`, and `hooks` array containing `{type: "command", command: "<path>"}` entries.

### DQ3: Config Injection Boilerplate
Resolved in Section 8 above. Commands include a prompt-level directive instructing Claude to read harness.yaml and inject a "Project Stack Context" section into subagent prompts and handoff prompts.
