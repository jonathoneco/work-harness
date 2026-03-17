# Spec 13: harness-doctor Command (C13)

**Component:** C13 — harness-doctor Command
**Phase:** 4 (Project Commands)
**Scope:** Small
**Dependencies:** C10 (config reader), C7 (install — manifest)
**References:** [architecture.md](architecture.md), [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md)

---

## 1. Overview

`/harness-doctor` is a Claude Code command that runs a suite of health checks to verify the harness installation and project configuration are correct and functional. It checks both the global installation (commands, skills, agents, rules, hooks) and the project-level configuration (harness.yaml, beads, review routing).

Unlike `/harness-update` (which reports version compatibility and suggestions), `/harness-doctor` validates that things actually work — files parse, agents exist, hooks are executable, dependencies are installed.

---

## 2. Health Checks

The command runs 7 checks in order. Each check produces a PASS, WARN, or FAIL result.

| Result | Meaning | Symbol |
|--------|---------|--------|
| PASS | Check passed, no issues | check mark |
| WARN | Non-blocking issue, harness will work but with reduced functionality | warning |
| FAIL | Blocking issue, harness features will not work correctly | cross |

### Check 1: harness.yaml Exists and Parses

**What:** Verify `.claude/harness.yaml` exists in the current project and is valid YAML conforming to v1 schema.

**How:**
1. Check file existence
2. Read the file and verify it parses as valid YAML
3. Validate required fields are present: `schema_version`, `project.name`, `stack.language`
4. Validate `project.name` matches `^[a-z0-9][a-z0-9-]*$`
5. Validate `stack.language` is one of: `go`, `python`, `typescript`, `rust`, `other`
6. Validate `schema_version` is a positive integer

**Results:**
- PASS: file exists, parses, all required fields valid
- FAIL (no file): ".claude/harness.yaml not found. Run /harness-init to create it."
- FAIL (bad YAML): ".claude/harness.yaml is malformed: <parse error>"
- FAIL (missing field): ".claude/harness.yaml missing required field: <field>"
- FAIL (invalid value): ".claude/harness.yaml invalid value for <field>: <value>"

### Check 2: Review Routing Agents Exist

**What:** Verify every agent name referenced in `review_routing[].agents` has a corresponding `.md` file in either `~/.claude/agents/` or `.claude/agents/`.

**How:**
1. Read `review_routing` from harness.yaml
2. Collect unique agent names across all routing entries
3. For each agent name, check:
   - `.claude/agents/<name>.md` exists (project-level), OR
   - `~/.claude/agents/<name>.md` exists (global-level)
4. If neither exists, record as missing

**Results:**
- PASS: all referenced agents found (or review_routing is empty)
- WARN (missing agents): "Agent '<name>' referenced in review_routing but not found. Install from agency-agents or create .claude/agents/<name>.md"
- PASS (no routing): "review_routing is empty — no agents to check"

This is WARN, not FAIL, because the harness functions without review agents — reviews just won't be routed to specialists.

### Check 3: Hooks Executable

**What:** Verify all harness hooks registered in `~/.claude/settings.json` are executable files.

**How:**
1. Read `~/.claude/.harness-manifest.json` to get the `hooks_added` array
2. For each hook entry, check that `command` path:
   - Exists as a file
   - Is executable (`-x` test)
3. If manifest is missing, fall back to scanning `~/.claude/settings.json` for hook commands containing the harness_dir path

**Results:**
- PASS: all hook scripts exist and are executable
- FAIL (not found): "Hook not found: <path>. Harness repo may have moved. Re-run install.sh."
- FAIL (not executable): "Hook not executable: <path>. Run: chmod +x <path>"
- WARN (no manifest): "Manifest not found — cannot verify hooks. Run install.sh."

### Check 4: Beads Initialized

**What:** Verify `.beads/` directory exists in the project root.

**How:**
1. Check `.beads/` directory exists
2. Optionally verify `bd list` runs without error (confirms beads database is valid)

**Results:**
- PASS: `.beads/` exists and `bd list` succeeds
- FAIL: ".beads/ not found. Run: bd init"
- WARN: ".beads/ exists but bd list failed — beads database may be corrupted"

### Check 5: Schema Version Compatibility

**What:** Verify the project's `schema_version` is compatible with the installed harness.

**How:**
1. Read `schema_version` from `.claude/harness.yaml`
2. Read `schema_version` from `~/.claude/.harness-manifest.json`
3. Compare: project version must be <= manifest version

**Results:**
- PASS: versions match or project is at a supported older version
- WARN (behind): "Project schema v<N> is behind installed v<M>. Migrations available via ./install.sh --update"
- FAIL (ahead): "Project schema v<N> is newer than installed harness v<M>. Update the harness."
- WARN (no manifest): "Cannot check schema compatibility — manifest missing"

### Check 6: Required Dependencies

**What:** Verify that all tools required by the harness are installed and accessible.

**How:** For each dependency, run `command -v <name>` (or equivalent check via Claude reading tool output):

| Dependency | Required By | Check |
|-----------|------------|-------|
| `jq` | install.sh, settings merger (C8) | `command -v jq` |
| `yq` | config reader (C10), hooks (C6) | `command -v yq` |
| `git` | beads, install.sh, hooks | `command -v git` |
| `bd` (beads) | workflow commands, hooks | `command -v bd` |

**Results:**
- PASS: all dependencies found
- FAIL (missing): "<tool> not found. Install: <install hint>"

Install hints:
- `jq`: "Available via system package manager (apt/pacman/brew install jq)"
- `yq`: "Install from https://github.com/mikefarah/yq"
- `git`: "Available via system package manager"
- `bd`: "Install beads: see https://github.com/..."

### Check 7: Agency-Agents Suggestion

**What:** If `review_routing` references agents that are not found, check whether agency-agents appears to be installed and suggest it if not.

**How:**
1. Only runs if Check 2 found missing agents
2. Check for agency-agents indicators:
   - `~/.claude/agents/code-reviewer.md` exists (flagship agent from agency-agents)
   - OR more than 10 `.md` files in `~/.claude/agents/` (suggests a large agent collection is installed)
3. If neither indicator found, suggest agency-agents

**Results:**
- PASS (not applicable): review_routing is empty or all agents found
- WARN (suggest): "Missing review agents may be available from agency-agents. See: https://github.com/..."
- PASS (installed): "agency-agents appears to be installed — check agent names match review_routing entries"

---

## 3. Files to Create

All paths relative to harness repo root.

| File | Purpose |
|------|---------|
| `claude/commands/harness-doctor.md` | The command file, installed to `~/.claude/commands/` |

No templates, no lib scripts, no hooks. Single command file.

---

## 4. Implementation Steps

- [ ] **4.1** Create `claude/commands/harness-doctor.md` with the full command text (see section 5)
- [ ] **4.2** Verify: command includes all 7 health checks in order
- [ ] **4.3** Verify: each check has clear PASS/WARN/FAIL output with actionable remediation
- [ ] **4.4** Verify: command handles missing harness.yaml (check 1 fails, remaining checks still attempted where possible)
- [ ] **4.5** Verify: command handles missing manifest gracefully (degrades checks that need it)
- [ ] **4.6** Verify: check 7 (agency-agents) only fires when check 2 found missing agents
- [ ] **4.7** Verify: command produces a summary count at the end
- [ ] **4.8** Verify: exit guidance — on all-pass, report healthy; on failures, prioritize fix order

---

## 5. Command Text Structure

`claude/commands/harness-doctor.md`:

```markdown
# /harness-doctor — Health Check

Run a comprehensive health check on the harness installation and project configuration.

## Execution

Run the following 7 checks in order. For each, report the result as PASS, WARN, or FAIL
with a clear description. Collect all results before reporting.

### Check 1: Configuration File
Verify `.claude/harness.yaml` exists in the current project directory.
If found, verify it is valid YAML. Then validate:
- `schema_version` is present and is a positive integer
- `project.name` is present and matches ^[a-z0-9][a-z0-9-]*$
- `stack.language` is present and is one of: go, python, typescript, rust, other

If harness.yaml is missing, still continue with remaining checks (some will degrade).

### Check 2: Review Routing Agents
Read `review_routing` from harness.yaml (skip if check 1 failed).
For each unique agent name in all `agents` arrays, verify a file exists at either:
- `.claude/agents/<name>.md` (project-level)
- `~/.claude/agents/<name>.md` (global-level)

Report each missing agent as WARN with a suggestion to install it.

### Check 3: Hooks Executable
Read `~/.claude/.harness-manifest.json` to get hook paths. For each `hooks_added[].command`:
- Verify the file exists
- Verify the file is executable

If manifest is missing, report WARN and skip this check.

### Check 4: Beads Initialized
Check that `.beads/` directory exists. If it does, run `bd list --limit 1` to verify
the database is functional.

### Check 5: Schema Compatibility
Compare `schema_version` from harness.yaml against `schema_version` from manifest.
Project version must be <= manifest version.
Skip if either file is missing.

### Check 6: Dependencies
Verify these tools are available (use Bash tool to run `which <tool>`):
- jq (JSON processing)
- yq (YAML processing)
- git (version control)
- bd (beads issue tracker)

For each missing tool, provide an install hint.

### Check 7: Agency-Agents Suggestion
Only run if Check 2 found missing agents. Check whether agency-agents is installed by
looking for `~/.claude/agents/code-reviewer.md` or a large number of agent files in
`~/.claude/agents/`. If not found, suggest installing agency-agents.

## Output Format

Report each check on a separate line with its result. At the end, provide a summary:
- Total checks: <N>
- Passed: <N>
- Warnings: <N>
- Failed: <N>

If any checks failed, list the recommended fix order (fix blocking issues first):
1. Install missing dependencies (check 6) — required for everything else
2. Run install.sh (check 3) — hooks must be functional
3. Run /harness-init (check 1) — project config must exist
4. Run bd init (check 4) — beads must be initialized
5. Install missing agents (check 2) — for review routing

## Rules

- **Read-only**: Never modify any files
- **Run all checks**: Don't stop at first failure — run everything and report all issues
- **Actionable output**: Every WARN/FAIL must include a specific remediation command or action
- **Config injection**: Include the directive from spec 00 section 8
```

---

## 6. Interface Contracts

### Exposes

| What | Consumed By | Contract |
|------|------------|----------|
| Informational output only | User (via Claude response) | Structured health report — no file changes |
| Verification of C11 output | User | Confirms `/harness-init` produced valid configuration |

### Consumes

| What | From | Contract |
|------|------|----------|
| `.claude/harness.yaml` | C11 (harness-init) | Reads and validates against v1 schema (spec 00 section 4) |
| `~/.claude/.harness-manifest.json` | C7 (install.sh) | Reads for hook paths and schema version (spec 00 section 5) |
| `~/.claude/agents/*.md` | C4 (workflow agents), agency-agents (external) | File existence check |
| `.claude/agents/*.md` | C11 (harness-init, optional) | File existence check |
| `.beads/` | beads CLI | Directory existence check |
| Config validation | C10 (config reader) | Schema validation logic (conceptual — Claude implements in-command) |

---

## 7. Testing Strategy

Manual verification since this is a Claude Code command.

### Manual Test Cases

**TC1: Fully healthy project**
1. Install harness, run `/harness-init`, install agency-agents
2. Run `/harness-doctor`
3. Verify: all 7 checks pass, summary shows 7/7 passed

**TC2: Fresh project, no harness.yaml**
1. `cd` into a project without `.claude/harness.yaml`
2. Run `/harness-doctor`
3. Verify: check 1 FAIL, checks 2 and 5 skipped/degraded, check 4 may FAIL
4. Verify: remediation suggests `/harness-init`

**TC3: Missing review agents**
1. Configure `review_routing` with agents: `[code-reviewer, security-reviewer]`
2. Ensure neither agent file exists
3. Run `/harness-doctor`
4. Verify: check 2 WARN for both agents, check 7 suggests agency-agents

**TC4: Non-executable hook**
1. Remove execute permission from a hook script
2. Run `/harness-doctor`
3. Verify: check 3 FAIL with `chmod +x` remediation

**TC5: Beads not initialized**
1. Remove `.beads/` directory
2. Run `/harness-doctor`
3. Verify: check 4 FAIL with `bd init` remediation

**TC6: Missing dependency**
1. Test with `yq` not in PATH (e.g., in a minimal container)
2. Run `/harness-doctor`
3. Verify: check 6 FAIL for yq with install URL

**TC7: Schema version mismatch**
1. Set project `schema_version: 2`, manifest `schema_version: 1`
2. Run `/harness-doctor`
3. Verify: check 5 FAIL (project ahead of harness)

**TC8: Malformed harness.yaml**
1. Write invalid YAML to `.claude/harness.yaml` (e.g., unbalanced quotes)
2. Run `/harness-doctor`
3. Verify: check 1 FAIL with parse error message

**TC9: No manifest (harness not installed globally)**
1. Remove `~/.claude/.harness-manifest.json`
2. Run `/harness-doctor`
3. Verify: checks 3 and 5 degrade to WARN, check 6 still runs

**TC10: Hook file deleted (harness repo moved)**
1. Change `harness_dir` in manifest to non-existent path
2. Run `/harness-doctor`
3. Verify: check 3 FAIL with "harness repo may have moved" message

---

## 8. Example Output

### All Healthy
```
$ /harness-doctor

--- Harness Health Check ---

  1. Configuration     ✓ PASS  .claude/harness.yaml valid (schema v1)
  2. Review agents     ✓ PASS  4 agents found (code-reviewer, security-reviewer, devops-automator)
  3. Hooks             ✓ PASS  7 hooks registered and executable
  4. Beads             ✓ PASS  .beads/ initialized (12 issues)
  5. Schema compat     ✓ PASS  Project v1 matches harness v1
  6. Dependencies      ✓ PASS  jq, yq, git, bd all found
  7. Agency-agents     ✓ PASS  Not applicable (all agents found)

--- Summary ---
7 checks: 7 passed, 0 warnings, 0 failures

Harness is healthy.
```

### Issues Found
```
$ /harness-doctor

--- Harness Health Check ---

  1. Configuration     ✓ PASS  .claude/harness.yaml valid (schema v1)
  2. Review agents     ⚠ WARN  Missing: security-reviewer, devops-automator
  3. Hooks             ✗ FAIL  Not executable: /home/user/src/claude-work-harness/hooks/pr-gate.sh
  4. Beads             ✗ FAIL  .beads/ not found
  5. Schema compat     ✓ PASS  Project v1 matches harness v1
  6. Dependencies      ✓ PASS  jq, yq, git, bd all found
  7. Agency-agents     ⚠ WARN  agency-agents not detected — see https://github.com/...

--- Summary ---
7 checks: 3 passed, 2 warnings, 2 failures

Recommended fix order:
  1. Fix hook permissions: chmod +x /home/user/src/claude-work-harness/hooks/pr-gate.sh
  2. Initialize beads: bd init
  3. Install missing agents: security-reviewer, devops-automator
     (available from agency-agents or create custom in .claude/agents/)
```

---

## 9. Edge Cases and Error Handling

| Scenario | Handling |
|----------|----------|
| harness.yaml missing | Check 1 FAIL. Checks 2 and 5 degrade (skip). Other checks still run. |
| harness.yaml malformed | Check 1 FAIL with parse error. Checks 2 and 5 skip. |
| Manifest missing | Checks 3 and 5 degrade to WARN (cannot verify). Other checks still run. |
| Manifest malformed JSON | Same as missing — degrade checks 3 and 5 with error message. |
| `bd` not installed | Check 6 FAIL for bd. Check 4 degrades (skip `bd list` verification, only check directory). |
| review_routing empty | Check 2 PASS with "no routing configured" note. Check 7 skipped. |
| review_routing references agent found in project but not global | PASS — project-level agents are valid. |
| Hook path contains spaces | Ensure path is properly quoted in checks (unlikely but defensive). |
| Very large number of agents in `~/.claude/agents/` | Don't enumerate all — just check the specific names from review_routing. |
| Harness repo at harness_dir was deleted | Check 3 FAIL (hooks not found). Suggest re-cloning and re-running install. |

---

## 10. Acceptance Criteria

1. Command file exists at `claude/commands/harness-doctor.md`
2. Runs all 7 checks in sequence, reporting each result
3. Check 1 validates harness.yaml existence, YAML syntax, required fields, and field values
4. Check 2 verifies all agents in review_routing exist in `~/.claude/agents/` or `.claude/agents/`
5. Check 3 verifies all manifest-listed hooks are executable files
6. Check 4 verifies `.beads/` exists and is functional
7. Check 5 compares schema versions between project and manifest
8. Check 6 verifies jq, yq, git, and bd are installed
9. Check 7 suggests agency-agents when review agents are missing and agency-agents is not detected
10. Produces a summary count (passed/warnings/failures) at the end
11. Every WARN and FAIL includes a specific remediation action
12. Never modifies any files (read-only command)
13. Continues running all checks even when early checks fail (no short-circuit)
14. Degrades gracefully when manifest or harness.yaml is missing
