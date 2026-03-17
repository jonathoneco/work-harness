---
name: workflow-meta
description: "Self-hosting skill — conventions for improving the work harness itself. Activates when working on the claude-work-harness repository."
---

# Workflow Meta

This skill provides conventions for when the harness is used to improve itself.
The claude-work-harness repo is itself a project that uses the harness — this
skill documents how to safely modify its components.

## When This Activates

- Working on the claude-work-harness repository itself
- Modifying commands, skills, agents, rules, or hooks
- Adding new language packs
- Changing the install/update/init scripts

## Component Modification Conventions

### Commands (`claude/commands/`)
- Each command is a markdown file with YAML frontmatter (`description`, `user_invocable: true`)
- All 10 work commands must include the config injection directive
- After modifying a command, verify `claude/rules/workflow.md` command table still matches

### Skills (`claude/skills/`)
- Skills use YAML frontmatter (`name`, `description`)
- Skills may have `references/` subdirectories for supplementary material
- The `code-quality` skill uses a language pack directive — do not hardcode language-specific content in the main skill file

### Agents (`claude/agents/`)
- Each agent specifies: persona, tools allowed/disallowed, permission mode, skill references
- Workflow agents (work-*) are harness-owned; domain expertise agents come from projects
- Agent files must include the config injection directive

### Rules (`claude/rules/`)
- Rules are loaded unconditionally for every session
- The command table in `workflow.md` must stay synchronized with `claude/commands/` contents

### Hooks (`hooks/`)
- POSIX sh, `set -eu`, no bashisms
- Must check for dependencies before first use
- Use standard exit codes: 0 (pass), 1 (warning), 2 (block)

## Adding a New Language Pack

1. Create `claude/skills/code-quality/references/<language>-anti-patterns.md`
2. Include bad/good code examples with clear explanations
3. No other files need to change — `code-quality.md` reads language packs via directive

That is the entire process. The language pack directive in `code-quality.md` dynamically selects the correct file based on `stack.language` from `harness.yaml`.

## Adding a New Hook

1. Create the script in `hooks/<name>.sh` following shell conventions
2. Add hook registration to `install.sh`
3. Document the hook event, matcher, and purpose
4. Update the manifest schema if needed

## Testing Changes

1. Run `./install.sh` to install locally
2. Test in a project with `harness.yaml`
3. Test in a project without `harness.yaml` (graceful degradation)
4. Verify hooks fire correctly
5. Run `/harness-doctor` to check health

## Version Bumping

Follow semver:
- **PATCH**: Bug fixes, language pack additions, documentation updates
- **MINOR**: New commands, new skills, new hooks, new features
- **MAJOR**: Breaking changes to harness.yaml schema, command removal, hook behavior changes

Update the `VERSION` file (single line, no `v` prefix, no trailing newline).

## Sync Points to Verify After Changes

- `workflow.md` command table matches `claude/commands/` inventory
- `install.sh` file list matches `claude/` directory contents
- Manifest schema matches what `install.sh` produces
- Hook registrations match what `install.sh` adds to settings.json
