# Work Log MCP Server Setup

Configuration guide for the `work-log` MCP Knowledge Graph server, which provides persistent cross-project work journaling.

## Installation

Add to your global MCP configuration (`~/.claude/mcp.json`):

```json
{
  "mcpServers": {
    "work-log": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-knowledge-graph"],
      "env": {
        "GRAPH_PATH": "~/.local/share/claude/work-log.jsonl"
      }
    }
  }
}
```

Ensure the data directory exists:

```sh
mkdir -p ~/.local/share/claude
```

## Key Design Decisions

- **Server name** `work-log` is descriptive, supporting routing by name
- **Graph file** lives in `~/.local/share/claude/` following XDG conventions
- **User-level** configuration (not project-level) so it spans all projects
- **Same KG package** as `personal-agent` for consistency

## Verification

After adding the configuration, restart Claude Code and verify:

```
mcp__work_log__list_entities
```

Should return an empty list on first run. If the tool is not recognized, check that the server name in `mcp.json` is exactly `work-log` (with hyphen).

## Troubleshooting

- **Tool not found**: Ensure `~/.claude/mcp.json` has the correct server name and restart Claude Code
- **Permission errors**: Verify `~/.local/share/claude/` exists and is writable
- **npm/npx not available**: Ensure Node.js is installed (check with `node --version`)
