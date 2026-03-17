---
name: serena-activate
description: Initialize Serena LSP tools for semantic code navigation. Auto-triggered by SessionStart hook, or run manually after context compaction.
---

# /serena-activate

Initialize Serena's semantic code navigation tools for this session.

## Usage

```
/serena-activate
```

Auto-triggered at session start by the SessionStart hook. Run manually to re-initialize after context compaction or if Serena tools are not responding.

## Workflow

1. **Check onboarding status**: Call `mcp__serena__check_onboarding_performed`.
   - If onboarding has NOT been performed: call `mcp__serena__onboarding` and follow its instructions to explore the project and write memories.
   - If onboarding is complete: proceed to step 2.

2. **Load Serena instructions**: Call `mcp__serena__initial_instructions`. Read the returned system prompt — it contains tool-specific guidance from Serena.

3. **Report status**: Briefly confirm activation. Do NOT dump the full Serena system prompt to the user — just confirm tools are ready.

## When to Use Serena Tools

After activation, prefer Serena's semantic tools over Claude Code builtins in these situations:

| Task | Use Serena Tool | Instead Of |
|------|----------------|------------|
| Find a function/class/method by name | `mcp__serena__find_symbol` | Grep/Glob |
| Find all usages of a symbol | `mcp__serena__find_referencing_symbols` | Grep |
| Understand file structure | `mcp__serena__get_symbols_overview` | Read (full file) |
| Replace an entire function body | `mcp__serena__replace_symbol_body` | Edit |
| Add code before/after a symbol | `mcp__serena__insert_before_symbol` / `mcp__serena__insert_after_symbol` | Edit |
| Rename across files | `mcp__serena__rename_symbol` | Edit replace_all + Grep |

## When NOT to Use Serena Tools

Continue using Claude Code builtins for:
- **Reading file contents**: Use `Read` — Serena's `read_file` is excluded in claude-code context
- **Text search across files**: Use `Grep` — faster and equally capable
- **Finding files by pattern**: Use `Glob` — same capability as Serena's `find_file`
- **Writing new files**: Use `Write` — Serena's `create_text_file` is excluded
- **Shell commands**: Use `Bash` — Serena's `execute_shell_command` is excluded

## Graceful Failure

If Serena tools are not available (server not running, MCP connection failed):
- Do NOT retry repeatedly — report to the user that Serena is unavailable
- Fall back to Claude Code builtins (Read, Grep, Glob, Edit) — they cover all essential functionality
- Suggest the user check server health if Serena was expected to be available
