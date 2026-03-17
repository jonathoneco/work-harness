# /harness-doctor -- Health Check

Run a comprehensive health check on the harness installation and project configuration. This command is **read-only** -- it verifies that things work but does not modify any files.

Unlike `/harness-update` (which reports version compatibility and suggestions), `/harness-doctor` validates that things actually function -- files parse, agents exist, hooks are executable, dependencies are installed.

## Execution

Run the following 7 checks in order. For each, report the result as PASS, WARN, or FAIL with a clear description. **Run all checks regardless of earlier failures** -- do not short-circuit. Collect all results before reporting.

| Result | Meaning | Symbol |
|--------|---------|--------|
| PASS | Check passed, no issues | checkmark |
| WARN | Non-blocking issue, harness will work but with reduced functionality | warning |
| FAIL | Blocking issue, harness features will not work correctly | cross |

### Check 1: Configuration File

Verify `.claude/harness.yaml` exists in the current project directory and is valid.

Steps:
1. Check file existence.
2. If found, read the file and verify it parses as valid YAML.
3. Validate required fields:
   - `schema_version` is present and is a positive integer
   - `project.name` is present and matches `^[a-z0-9][a-z0-9-]*$`
   - `stack.language` is present and is one of: `go`, `python`, `typescript`, `rust`, `other`

Results:
- **PASS**: File exists, parses, all required fields valid. Report: "`.claude/harness.yaml` valid (schema v*N*)"
- **FAIL** (no file): "`.claude/harness.yaml` not found. Run `/harness-init` to create it."
- **FAIL** (bad YAML): "`.claude/harness.yaml` is malformed: *parse error*"
- **FAIL** (missing field): "`.claude/harness.yaml` missing required field: *field*"
- **FAIL** (invalid value): "`.claude/harness.yaml` invalid value for *field*: *value*"

If this check fails, checks 2 and 5 will degrade (skip config-dependent validation) but other checks still run.

### Check 2: Review Routing Agents

Read `review_routing` from `.claude/harness.yaml` (skip if check 1 failed).

Steps:
1. Collect all unique agent names across all `review_routing[].agents` arrays.
2. For each agent name, check if a file exists at either:
   - `.claude/agents/<name>.md` (project-level)
   - `~/.claude/agents/<name>.md` (global-level)
3. If neither exists, record as missing.

Results:
- **PASS** (all found): "*N* agent(s) found (*names*)"
- **PASS** (no routing): "`review_routing` is empty -- no agents to check"
- **WARN** (missing agents): "Missing: *agent-name-1*, *agent-name-2*. Install from agency-agents or create `.claude/agents/<name>.md`"

This is WARN, not FAIL, because the harness functions without review agents -- reviews just will not be routed to specialists.

Record whether any agents are missing -- this determines whether check 7 runs.

### Check 3: Hooks Executable

Verify all harness hooks registered in `~/.claude/settings.json` are executable files.

Steps:
1. Read `~/.claude/.harness-manifest.json` to get the `hooks_added` array.
2. For each hook entry, check that the `command` path:
   - Exists as a file
   - Is executable (run `test -x <path>` via the Bash tool)

Results:
- **PASS**: All hook scripts exist and are executable. Report: "*N* hook(s) registered and executable"
- **FAIL** (not found): "Hook not found: *path*. Harness repo may have moved. Re-run `install.sh`."
- **FAIL** (not executable): "Hook not executable: *path*. Run: `chmod +x <path>`"
- **WARN** (no manifest): "Manifest not found -- cannot verify hooks. Run `install.sh`."

### Check 4: Beads Initialized

Verify `.beads/` directory exists in the project root.

Steps:
1. Check `.beads/` directory exists.
2. If it exists and `bd` is available, run `bd list --limit 1` to verify the beads database is functional.

Results:
- **PASS**: "`.beads/` initialized" (and if bd ran successfully, include issue count or note it works)
- **FAIL** (no directory): "`.beads/` not found. Run: `bd init`"
- **WARN** (directory exists but bd fails): "`.beads/` exists but `bd list` failed -- beads database may be corrupted"

If `bd` is not installed, just check directory existence and note that `bd` availability is checked in check 6.

### Check 5: Schema Compatibility

Compare `schema_version` from `.claude/harness.yaml` against `schema_version` from `~/.claude/.harness-manifest.json`.

Skip if either file is missing or unparseable (report WARN noting the skip reason).

Results:
- **PASS** (match): "Project v*N* matches harness v*M*"
- **WARN** (behind): "Project schema v*N* is behind installed v*M*. Migrations available via `./install.sh --update`"
- **FAIL** (ahead): "Project schema v*N* is newer than installed harness v*M*. Update the harness."
- **WARN** (skipped): "Cannot check schema compatibility -- *reason*"

### Check 6: Dependencies

Verify that all tools required by the harness are installed and accessible. For each dependency, run `which <tool>` via the Bash tool.

| Dependency | Required By | Install Hint |
|-----------|------------|--------------|
| `jq` | install.sh, settings merger | "Available via system package manager (`apt`/`pacman`/`brew install jq`)" |
| `yq` | config reader, hooks | "Install from https://github.com/mikefarah/yq" |
| `git` | beads, install.sh, hooks | "Available via system package manager" |
| `bd` | workflow commands, hooks | "Install beads: see beads documentation" |

Results:
- **PASS**: All dependencies found. Report: "*tool1*, *tool2*, *tool3*, *tool4* all found"
- **FAIL** (missing): "*tool* not found. Install: *hint*"

Report each missing tool individually with its install hint.

### Check 7: Agency-Agents Suggestion

Only run this check if check 2 found missing agents. If all agents were found or `review_routing` is empty, report PASS (not applicable) and move on.

Steps:
1. Check for agency-agents indicators:
   - `~/.claude/agents/code-reviewer.md` exists (flagship agent from agency-agents)
   - OR count `.md` files in `~/.claude/agents/` -- more than 10 suggests a large agent collection is installed
2. Based on findings, report:

Results:
- **PASS** (not applicable): "Not applicable (all review agents found or no routing configured)"
- **WARN** (suggest install): "Missing review agents may be available from agency-agents. See: https://github.com/anthropics/agency-agents"
- **PASS** (installed but names mismatch): "agency-agents appears to be installed -- check that agent names in `review_routing` match available agent filenames"

## Output Format

Present the results in a structured report:

```
--- Harness Health Check ---

  1. Configuration     [symbol] [RESULT]  [detail]
  2. Review agents     [symbol] [RESULT]  [detail]
  3. Hooks             [symbol] [RESULT]  [detail]
  4. Beads             [symbol] [RESULT]  [detail]
  5. Schema compat     [symbol] [RESULT]  [detail]
  6. Dependencies      [symbol] [RESULT]  [detail]
  7. Agency-agents     [symbol] [RESULT]  [detail]

--- Summary ---
7 checks: N passed, N warnings, N failures

[Conclusion or remediation guidance]
```

### Conclusion

- **All passed:** "Harness is healthy."
- **Warnings only:** "Harness is functional with *N* warning(s). See above for recommendations."
- **Any failures:** List the recommended fix order (fix blocking issues first):
  1. Install missing dependencies (check 6) -- required for everything else
  2. Run `install.sh` (check 3) -- hooks must be functional
  3. Run `/harness-init` (check 1) -- project config must exist
  4. Run `bd init` (check 4) -- beads must be initialized
  5. Install missing agents (check 2) -- for review routing

## Rules

- **Read-only**: Never modify any files.
- **Run all checks**: Do not stop at first failure -- run everything and report all issues.
- **Actionable output**: Every WARN and FAIL must include a specific remediation command or action.
- **Continue on degradation**: If check 1 fails (no config), still run checks 3, 4, 6, and 7. Skip checks 2 and 5 that depend on config data, noting the skip reason.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory, read it and include a "Project Stack Context" section (language, framework, database, build commands) in all subagent prompts and handoff prompts you produce.

## Edge Cases

| Scenario | Handling |
|----------|----------|
| harness.yaml missing | Check 1 FAIL. Checks 2 and 5 degrade (skip). Other checks still run. |
| harness.yaml malformed | Check 1 FAIL with parse error. Checks 2 and 5 skip. |
| Manifest missing | Checks 3 and 5 degrade to WARN (cannot verify). Other checks still run. |
| Manifest malformed JSON | Same as missing -- degrade checks 3 and 5 with error message. |
| `bd` not installed | Check 6 FAIL for bd. Check 4 degrades (skip `bd list` verification, only check directory). |
| `review_routing` empty | Check 2 PASS with "no routing configured" note. Check 7 skipped. |
| review_routing references agent found in project but not global | PASS -- project-level agents are valid. |
| Harness repo at harness_dir was deleted | Check 3 FAIL (hooks not found). Suggest re-cloning and re-running install. |
