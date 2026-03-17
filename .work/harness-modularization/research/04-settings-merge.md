# Settings Merge Strategy

## The Problem
The install script must merge hook entries into `~/.claude/settings.json` without clobbering existing user settings. This is identified as the hardest part of the extraction.

## Current State

### User-level (`~/.claude/settings.json`) — 165 lines
- SessionStart: 1 hook (Serena activation)
- PostToolUse: 2 hooks (gofmt for .go files, state-guard.sh)
- PreToolUse: 3 hooks (.env blocking, .review/ blocking, pr-gate.sh)
- Stop: 5 hooks (work-check, beads-check, review-gate, artifact-gate, review-verify)
- Notification: 1 hook (notify-send)
- Flags: alwaysThinkingEnabled, effortLevel, CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
- Plugins: 5 (documentation-generator, beads, frontend-design, gopls-lsp, prompt-improver)
- Permissions: 29 allow, 3 deny

### Project-level (`gaucho/.claude/settings.json`) — 106 lines
- Overlapping hooks with project-relative paths (`.claude/hooks/` vs `~/.claude/hooks/`)
- PostCompact: 1 hook (not in user-level)
- enableAllProjectMcpServers: true (not in user-level)

### They're nearly identical
User-level settings are mature and almost a superset of project-level. The main gaps:
- PostCompact hook exists only in project-level
- enableAllProjectMcpServers flag only in project-level

## Merge Strategy

### What the harness needs to install
1. **Hooks** (the core workflow machinery):
   - PostToolUse: state-guard.sh
   - PreToolUse: .env blocking, .review/ blocking
   - Stop: work-check.sh, beads-check.sh, review-gate.sh, artifact-gate.sh, review-verify.sh
   - Notification: optional desktop notification

2. **NOT hooks** (language-specific, stay in project):
   - PostToolUse: gofmt (Go-specific)
   - PreToolUse: pr-gate.sh (has Go linting)

### Merge algorithm
```
For each hook category (PostToolUse, PreToolUse, Stop, etc.):
  1. Read existing hooks array from user settings
  2. For each harness hook:
     a. Check if hook with same command already exists (substring match)
     b. If not present: append to array
     c. If present: skip (user's version takes precedence)
  3. Write updated array back

For scalar settings (flags, env vars):
  1. Only set if key doesn't already exist
  2. Never overwrite user values
```

### Path resolution
- Harness hooks live in the harness repo (e.g., `~/src/claude-work-harness/hooks/`)
- Install script sets absolute paths in settings.json pointing to harness repo
- Updates after `git pull` work because paths don't change
- Alternative: symlink hooks into `~/.claude/hooks/` at install time

### jq-based implementation sketch
```bash
# Read existing, merge harness hooks, write back
jq --argjson harness "$HARNESS_HOOKS" '
  .hooks.Stop = (.hooks.Stop // []) +
    [$harness.Stop[] | select(
      . as $h | any(.hooks.Stop[]?; .command == $h.command) | not
    )]
' ~/.claude/settings.json > tmp && mv tmp ~/.claude/settings.json
```

## Key Decisions
1. **Hook paths**: Absolute paths to harness repo (not symlinks — simpler, no broken links)
2. **User precedence**: Never overwrite existing hooks or settings
3. **Idempotent**: Running install twice produces same result
4. **Uninstall**: Track which hooks were added by harness (metadata tag or separate manifest)
