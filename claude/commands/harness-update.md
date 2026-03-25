---
description: "Check project harness configuration against the installed harness version"
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# /harness-update -- Check Project Compatibility

Check this project's harness configuration against the installed harness version. This command is **read-only** -- it reports status but does not modify any files.

This command answers three questions:
1. Is my project's schema compatible with the installed harness?
2. Am I overriding any global harness files locally?
3. Are there new harness features I'm not using?

## Pre-flight

1. Check `~/.claude/.harness-manifest.json` exists. If not: report "Harness not installed. Run `./install.sh` from the harness repo." and stop.
2. Check `.claude/harness.yaml` exists in the current project directory. If not: report "No harness.yaml found. Run `/harness-init` to set up this project." and stop.
3. Read both files. If either fails to parse, report the parse error and suggest remediation (re-run `install.sh` for manifest, re-run `/harness-init` or fix YAML syntax for harness.yaml).

## Checks

Run all of the following checks and collect results before presenting the report.

### Check 1: Schema Version Compatibility

Compare `schema_version` from `.claude/harness.yaml` against `schema_version` from `~/.claude/.harness-manifest.json`.

| Project | Installed | Result |
|---------|-----------|--------|
| Equal | Equal | "Schema version: OK (v*N*)" |
| Lower | Higher | "Schema upgrade available: v*project* -> v*manifest*. Run: `cd <harness_dir> && ./install.sh --update`" |
| Higher | Lower | "WARNING: Project schema (v*project*) is newer than installed harness (v*manifest*). Update the harness: `cd <harness_dir> && git pull && ./install.sh --update`" |

If an upgrade is available, check whether `<harness_dir>/lib/migrate.sh` exists and is readable. If so, note that migrations are available. Do not attempt to describe individual migration contents -- just note their existence.

### Check 2: Harness Version

Read the `VERSION` file from `harness_dir` (the path stored in `manifest.harness_dir`). Compare against `manifest.harness_version`.

| Manifest Version | Repo VERSION | Result |
|-----------------|-------------|--------|
| Equal | Equal | "Harness version: OK (*version*)" |
| Older | Newer | "Harness update available: *installed* -> *repo*. Run: `cd <harness_dir> && ./install.sh --update`" |
| Any | Unreadable | "Harness repo not found at *harness_dir*. Re-clone or update manifest." |

If the harness repo directory (from `harness_dir` in manifest) is not accessible, skip this check with a warning and continue with the remaining checks.

### Check 3: Local Overrides

Read the `files` array from the manifest. For each entry, check if the corresponding file exists in the project's `.claude/` directory.

- If found: report "Local override: `.claude/<file>` (shadows global)"
- If none found: report "No local overrides."

This is informational, not an error. Local overrides are a supported customization mechanism. The report helps the user understand which global files are being shadowed by project-level copies.

### Check 4: Unused Features

Check `.claude/harness.yaml` for empty or null optional fields. Report suggestions for each, but only suggest fields that are relevant to the detected `stack.language`.

Fields to check:
- `review_routing` is empty -> "Consider configuring review agents for automated code review routing"
- `anti_patterns` is empty -> "Consider adding language-specific anti-patterns for the review-gate hook"
- `build.test` is empty -> "Consider setting a test command" (skip for `other`)
- `build.build` is empty -> "Consider setting a build command" (skip for `python` and `other`)
- `build.lint` is empty -> "Consider setting a lint command" (skip for `other`)
- `build.format` is empty -> "Consider setting a format command" (skip for `other`)
- `project.description` is empty -> "Consider adding a project description"
- `stack.framework` is null -> "Consider specifying a framework" (skip for `other`)
- `stack.database` is null -> "Consider specifying a database" (skip if genuinely not applicable)

If all optional fields are populated: "No suggestions -- configuration is complete."

## Output Format

Present results in a structured report:

```
--- Harness Compatibility Report ---

Schema version:   [status]
Harness version:  [status]
Local overrides:  [list or "None"]

Suggestions:
  [bullet list of unused features, or "No suggestions"]

[Summary line]
```

Use checkmarks for passing checks and warning indicators for actionable items.

### Summary Line

- If everything passes and no suggestions: "Everything looks good."
- If updates available: "*N* update(s) available."
- If overrides detected: "*N* local override(s) detected."
- Combine as appropriate: "1 update available. 2 local overrides detected."

## Rules

- **Read-only**: Never modify any files. This command only reads and reports.
- **Graceful degradation**: If the harness repo is not accessible at the `harness_dir` path, skip the version check but still report all other findings.
- **No assumptions**: Do not assume the project is misconfigured just because optional fields are empty. Frame suggestions as opportunities, not problems.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory, read it and include a "Project Stack Context" section (language, framework, database, build commands) in all subagent prompts and handoff prompts you produce.

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Manifest missing | Stop with install suggestion. |
| harness.yaml missing | Stop with `/harness-init` suggestion. |
| harness.yaml malformed (bad YAML) | Report parse error, suggest fixing or re-running `/harness-init`. |
| Manifest has invalid JSON | Report parse error, suggest re-running `install.sh`. |
| harness_dir in manifest points to non-existent path | Skip version comparison, report warning, continue with other checks. |
| Project schema_version higher than manifest | Warn clearly -- user likely needs to update harness. |
| All optional fields populated | Report "No suggestions -- configuration is complete." |
