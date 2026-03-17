# Spec 12: harness-update Command (C12)

**Component:** C12 — harness-update Command
**Phase:** 4 (Project Commands)
**Scope:** Small
**Dependencies:** C10 (config reader), C7 (install — manifest)
**References:** [architecture.md](architecture.md), [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md)

---

## 1. Overview

`/harness-update` is a Claude Code command that checks the health of a project's harness configuration against the currently installed harness version. It is primarily informational — it reads config and manifest, compares versions, identifies local overrides, and reports findings. It does not modify any files.

This command answers three questions:
1. **Is my project's schema compatible with the installed harness?**
2. **Am I overriding any global harness files locally?**
3. **Are there new harness features I'm not using?**

---

## 2. Inputs

The command reads two data sources:

### `.claude/harness.yaml` (project)
- `schema_version` — compared against installed harness schema version
- All fields — checked for completeness against current schema

### `~/.claude/.harness-manifest.json` (global)
- `harness_version` — the installed harness semver
- `schema_version` — the schema version the harness expects
- `harness_dir` — path to the harness repo (to read VERSION and check for new features)
- `files` — list of installed global files (for override detection)

---

## 3. Checks Performed

### 3.1 Schema Version Compatibility

Compare `harness.yaml` `schema_version` against manifest `schema_version`.

| Project | Installed | Status |
|---------|-----------|--------|
| 1 | 1 | Compatible |
| 1 | 2 | Upgrade available — project schema is behind |
| 2 | 1 | Incompatible — project schema is ahead of installed harness (should not happen normally) |

**Upgrade available:** Report which schema migrations exist and what they change. Read migration descriptions from `<harness_dir>/lib/migrate.sh` (each migration function has a comment header describing changes).

**Incompatible (ahead):** Warn that the installed harness is older than the project config. Suggest running `./install.sh --update` from the harness repo.

### 3.2 Local Overrides

Scan `.claude/` in the project directory for files that shadow globally installed harness files.

Algorithm:
1. Read `files` array from manifest (e.g., `["commands/work.md", "skills/code-quality.md", ...]`)
2. For each entry, check if the corresponding file exists in the project's `.claude/` directory
3. If it exists, it's a local override — Claude Code will load the project version instead of the global one

Report each override with its path. This is informational, not an error — overrides are a supported customization mechanism.

### 3.3 New Features Available

Compare the project's `harness.yaml` against the current schema to identify unused optional fields.

Checks:
- `review_routing` is empty → suggest configuring review routing
- `anti_patterns` is empty → suggest adding language-specific anti-patterns
- `build.*` commands have empty values → suggest filling in build commands
- `project.description` is empty → suggest adding a description
- `stack.framework` is null → suggest specifying framework if applicable
- `stack.database` is null → suggest specifying database if applicable

Only report fields that are empty/null AND would be useful for the detected language. For example, don't suggest `build.build` for Python projects where a build step is uncommon.

### 3.4 Harness Version

Compare installed `harness_version` from manifest against `VERSION` file in the harness repo (if `harness_dir` is accessible).

| Manifest | Repo VERSION | Status |
|----------|-------------|--------|
| 1.0.0 | 1.0.0 | Up to date |
| 1.0.0 | 1.1.0 | Update available — suggest `./install.sh --update` |
| 1.0.0 | (unreadable) | Harness repo not found at manifest path — suggest re-cloning or updating manifest |

---

## 4. Files to Create

All paths relative to harness repo root.

| File | Purpose |
|------|---------|
| `claude/commands/harness-update.md` | The command file, installed to `~/.claude/commands/` |

No templates, no lib scripts, no hooks. This is a single command file.

---

## 5. Implementation Steps

- [ ] **5.1** Create `claude/commands/harness-update.md` with the full command text (see section 6)
- [ ] **5.2** Verify: command reads both `.claude/harness.yaml` and `~/.claude/.harness-manifest.json`
- [ ] **5.3** Verify: command reports schema version compatibility correctly for all three cases (match, behind, ahead)
- [ ] **5.4** Verify: command detects local overrides by comparing project `.claude/` against manifest `files` list
- [ ] **5.5** Verify: command suggests unused optional features based on current schema
- [ ] **5.6** Verify: command reports harness version status (up to date vs update available)
- [ ] **5.7** Verify: command handles missing harness.yaml gracefully (suggests running `/harness-init`)
- [ ] **5.8** Verify: command handles missing manifest gracefully (suggests running `install.sh`)

---

## 6. Command Text Structure

`claude/commands/harness-update.md`:

```markdown
# /harness-update — Check Project Compatibility

Check this project's harness configuration against the installed harness version.
This command is read-only — it reports status but does not modify any files.

## Pre-flight

1. Check `~/.claude/.harness-manifest.json` exists. If not: report "Harness not installed.
   Run ./install.sh from the harness repo." and stop.
2. Check `.claude/harness.yaml` exists. If not: report "No harness.yaml found.
   Run /harness-init to set up this project." and stop.
3. Read both files.

## Checks

### Schema Version
Compare harness.yaml `schema_version` against manifest `schema_version`.
- If equal: report "Schema version: OK (v<N>)"
- If project < manifest: report "Schema upgrade available: v<project> → v<manifest>.
  Run ./install.sh --update from the harness repo to apply migrations."
- If project > manifest: report "WARNING: Project schema (v<project>) is newer than
  installed harness (v<manifest>). Update the harness: cd <harness_dir> && git pull &&
  ./install.sh --update"

### Harness Version
Read VERSION from harness_dir (manifest.harness_dir). Compare against manifest.harness_version.
- If equal: report "Harness version: OK (<version>)"
- If repo is newer: report "Harness update available: <installed> → <repo>.
  Run ./install.sh --update"
- If repo not readable: report "Harness repo not found at <harness_dir>. Re-clone or
  update manifest."

### Local Overrides
Read manifest.files array. For each, check if .claude/<file> exists in project directory.
Report any found as: "Local override: .claude/<file> (shadows global)"
If none found: "No local overrides."

### Unused Features
Check harness.yaml for empty/null optional fields. Report suggestions for each.
Only suggest fields relevant to the detected stack.language.

## Output Format

Present results in a structured report with section headers and status indicators.
Use checkmarks for passing checks and warnings for actionable items.

## Rules

- **Read-only**: Never modify any files
- **Graceful degradation**: If harness repo is not accessible, skip version check but
  still report other findings
- **Config injection**: Include the directive from spec 00 section 8
```

---

## 7. Interface Contracts

### Exposes

| What | Consumed By | Contract |
|------|------------|----------|
| Informational output only | User (via Claude response) | Structured text report — no file changes |

### Consumes

| What | From | Contract |
|------|------|----------|
| `.claude/harness.yaml` | C11 (harness-init) | Valid v1+ schema per spec 00 section 4 |
| `~/.claude/.harness-manifest.json` | C7 (install.sh) | Valid manifest per spec 00 section 5 |
| `<harness_dir>/VERSION` | C1 (repo scaffold) | Semver string, single line |
| `<harness_dir>/lib/migrate.sh` | C9 (schema migrator) | Migration function comments describe changes |
| Config validation | C10 (config reader) | Validates harness.yaml before reading fields |

---

## 8. Testing Strategy

Manual verification since this is a Claude Code command.

### Manual Test Cases

**TC1: Everything up to date**
1. Install harness, run `/harness-init`, confirm all versions match
2. Run `/harness-update`
3. Verify: all checks pass, no upgrade suggestions

**TC2: Schema version behind**
1. Install harness with schema_version 2 in manifest
2. Keep project harness.yaml at schema_version 1
3. Run `/harness-update`
4. Verify: reports schema upgrade available

**TC3: Local override detected**
1. Create `.claude/rules/workflow.md` in project (shadows global)
2. Run `/harness-update`
3. Verify: reports local override for `rules/workflow.md`

**TC4: Unused features**
1. Create harness.yaml with empty `review_routing` and `anti_patterns`
2. Run `/harness-update`
3. Verify: suggests configuring review routing and anti-patterns

**TC5: No harness.yaml**
1. Remove `.claude/harness.yaml` from project
2. Run `/harness-update`
3. Verify: suggests running `/harness-init`

**TC6: No manifest**
1. Remove `~/.claude/.harness-manifest.json`
2. Run `/harness-update`
3. Verify: suggests running `install.sh`

**TC7: Harness repo moved/deleted**
1. Change `harness_dir` in manifest to a non-existent path
2. Run `/harness-update`
3. Verify: version check skipped with warning, other checks still run

---

## 9. Example Output

### All Healthy
```
$ /harness-update

--- Harness Compatibility Report ---

Schema version:   ✓ OK (v1)
Harness version:  ✓ OK (1.0.0)
Local overrides:  None

Suggestions:
  • review_routing is empty — consider configuring review agents
  • anti_patterns is empty — consider adding code quality patterns

Everything looks good.
```

### Upgrade Available
```
$ /harness-update

--- Harness Compatibility Report ---

Schema version:   ⚠ Upgrade available (project: v1, harness: v2)
                  Run: cd /home/user/src/claude-work-harness && ./install.sh --update
Harness version:  ⚠ Update available (installed: 1.0.0, repo: 1.2.0)
                  Run: cd /home/user/src/claude-work-harness && ./install.sh --update
Local overrides:
  • .claude/rules/workflow.md (shadows global)
  • .claude/skills/code-quality.md (shadows global)

Suggestions:
  • project.description is empty

2 updates available. 2 local overrides detected.
```

---

## 10. Edge Cases and Error Handling

| Scenario | Handling |
|----------|----------|
| Manifest missing | Stop with install suggestion |
| harness.yaml missing | Stop with `/harness-init` suggestion |
| harness.yaml malformed (bad YAML) | Report parse error, suggest fixing or re-running `/harness-init` |
| Manifest has invalid JSON | Report parse error, suggest re-running `install.sh` |
| harness_dir in manifest points to non-existent path | Skip version comparison, report warning, continue with other checks |
| Project schema_version higher than manifest (shouldn't happen) | Warn clearly — user likely needs to update harness |
| All optional fields populated | Report "No suggestions — configuration is complete" |

---

## 11. Acceptance Criteria

1. Command file exists at `claude/commands/harness-update.md`
2. Reports schema version compatibility (match, behind, ahead)
3. Reports harness version status (up to date, update available, repo not found)
4. Detects and lists local overrides by comparing project `.claude/` against manifest files
5. Suggests unused optional features relevant to the project's language
6. Handles missing harness.yaml gracefully (suggests `/harness-init`)
7. Handles missing manifest gracefully (suggests `install.sh`)
8. Never modifies any files (read-only command)
9. Degrades gracefully when harness repo is inaccessible (skips version check)
