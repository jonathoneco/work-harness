# Stream D: Project Commands

**Phase:** 2 (runs after Phase 1 — Stream A must complete)
**Work Items:** W-11 (rag-i8h9z), W-12 (rag-wwpv6), W-13 (rag-nrxsn)
**Execution Order:** Parallel within stream (no inter-dependencies)
**Dependencies:** W-02 (config reader — lib/config.sh must exist)

---

## Overview

This stream creates three project-management commands: harness-init (scaffolds a project), harness-update (checks compatibility), and harness-doctor (health checks). All are Claude Code commands (markdown files) that instruct Claude to read harness.yaml via the config reader functions.

---

## W-11: harness-init Command — spec 11

**Issue:** rag-i8h9z
**Spec:** `.work/harness-modularization/specs/11-harness-init.md`

### Files to Create

```
claude/commands/harness-init.md
templates/harness.yaml.template
```

### Key Requirements

- 6-prompt interactive flow (spec 11 §3, resolves DQ6):
  1. **Project name** — auto-detect from directory name, validate kebab-case
  2. **Language** — auto-detect from go.mod/package.json/Cargo.toml/requirements.txt/pyproject.toml
  3. **Framework** — free-form, suggest based on detected language
  4. **Database** — free-form (postgresql, mysql, sqlite, none)
  5. **Build commands** — test, build, lint, format (per-language defaults)
  6. **Review routing** — file patterns → agent names
- Auto-detection (spec 11 §3.2):
  - `go.mod` → go, `package.json` → typescript, `Cargo.toml` → rust, `requirements.txt`/`pyproject.toml` → python
- Per-language defaults (spec 00 §4):
  - go: extensions `[".go", ".sql"]`
  - python: extensions `[".py"]`
  - typescript: extensions `[".ts", ".tsx", ".js"]`
  - rust: extensions `[".rs"]`
- Creates `.claude/harness.yaml` in project directory
- Creates optional scaffolds: `.claude/rules/beads-workflow.md`, `.claude/rules/architecture-decisions.md`
- Template file used as base for YAML generation

### Acceptance Criteria

1. Command file exists at `claude/commands/harness-init.md`
2. Template file exists at `templates/harness.yaml.template`
3. Interactive 6-prompt flow documented
4. Auto-detection logic for 4 languages specified
5. Per-language defaults match spec 00 §4
6. Output harness.yaml validates against spec 00 §4 schema

### On Completion

```bash
bd close rag-i8h9z --reason="harness-init command with 6-prompt interactive flow and auto-detection"
```

---

## W-12: harness-update Command — spec 12

**Issue:** rag-wwpv6
**Spec:** `.work/harness-modularization/specs/12-harness-update.md`

### Files to Create

```
claude/commands/harness-update.md
```

### Key Requirements

- Read-only compatibility checker (no modifications)
- Reports:
  - Current harness VERSION (from manifest)
  - Project schema_version vs HARNESS_CURRENT_SCHEMA_VERSION
  - Local file overrides (files in `.claude/` that shadow harness files)
  - Hook registration status (are all harness hooks present in settings.json?)
- Suggests actions: "Run install.sh to update" if version mismatch
- Uses config reader functions to check harness.yaml

### Acceptance Criteria

1. Command file exists
2. Reports version, schema, overrides, hooks status
3. Read-only (no modifications to any files)
4. Suggests remediation actions

### On Completion

```bash
bd close rag-wwpv6 --reason="harness-update compatibility checker command"
```

---

## W-13: harness-doctor Command — spec 13

**Issue:** rag-nrxsn
**Spec:** `.work/harness-modularization/specs/13-harness-doctor.md`

### Files to Create

```
claude/commands/harness-doctor.md
```

### Key Requirements

- 7 health checks (spec 13):
  1. **Harness installed** — manifest exists at `~/.claude/.harness-manifest.json`
  2. **Dependencies present** — yq, jq available in PATH
  3. **Config valid** — harness.yaml parses and has required fields
  4. **Hooks registered** — all manifest hooks present in settings.json
  5. **Files synced** — manifest files present in `~/.claude/`
  6. **Schema current** — schema_version matches HARNESS_CURRENT_SCHEMA_VERSION
  7. **Review agents available** — review_routing agent files exist
- Each check produces: PASS, WARN, or FAIL with remediation message
- Summary at end: N/7 checks passed
- If review_routing agents not found: suggest agency-agents as companion

### Acceptance Criteria

1. Command file exists
2. All 7 health checks documented
3. Each check has PASS/WARN/FAIL states
4. Remediation messages provided for WARN/FAIL
5. Agency-agents suggestion for missing agents
6. Summary count at end

### On Completion

```bash
bd close rag-nrxsn --reason="harness-doctor health check command with 7 checks"
```
