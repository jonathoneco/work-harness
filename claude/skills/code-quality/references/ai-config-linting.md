# AI Config Linting

Linting rules for AI tooling configuration files. Covers Claude Code settings, harness configuration, agent definitions, and MCP server config. Each entry documents a pattern to detect, the risk it creates, and a concrete fix.

## Claude Code Settings

### Invalid Hook Event Names
- **Pattern**: Hook entries in `.claude/settings.json` with event names that are not recognized by Claude Code (e.g., `PreExec`, `OnSave`, `BeforeToolUse` instead of `PreToolUse`)
- **Risk**: Hooks with invalid event names are silently ignored — the expected behavior never triggers, and there is no error message to indicate the misconfiguration
- **Fix**: Use only valid event names: `PreToolUse`, `PostToolUse`, `Notification`, `Stop`, `SubagentStop`, `SubagentTurn`. Check the Claude Code documentation for the current list

### Hook Commands Referencing Non-Existent Scripts
- **Pattern**: Hook `command` fields that reference scripts not present in the repository (e.g., `hooks/validate.sh` when the file does not exist or has been moved)
- **Risk**: Hook silently fails or produces a confusing error at runtime. The intended validation or side-effect never runs
- **Fix**: Verify that all script paths in hook commands resolve to existing files. Use repository-relative paths. After renaming or moving hook scripts, update all references in `settings.json`

### Duplicate Hook Entries
- **Pattern**: Multiple hook entries in `.claude/settings.json` with the same event name, matcher pattern, and command string
- **Risk**: The same hook runs multiple times per trigger, causing duplicate side effects (duplicate warnings, repeated file writes, or performance degradation)
- **Fix**: Remove duplicate entries. If hooks were added incrementally, audit the full hooks array for redundancy. Use a single entry per unique event+matcher+command combination

### Overly Broad Permission Patterns
- **Pattern**: Permission allowlists that permit all commands for a tool (e.g., `Bash(*)` or `Edit(*)`) instead of scoping to specific operations
- **Risk**: Removes the safety guardrails that prevent accidental destructive operations. An agent can execute any shell command or edit any file without confirmation
- **Fix**: Scope permissions to specific patterns that match actual usage. For Bash, allowlist specific commands (`Bash(npm test)`, `Bash(go build ./...)`). For file operations, scope to project directories

## CLAUDE.md and Rules

### Contradictory Instructions
- **Pattern**: One rule file says "always use X" while another says "never use X", or the same file contains conflicting directives in different sections
- **Risk**: Agent behavior becomes unpredictable — it may follow either instruction depending on which appears closer to the relevant context in its window
- **Fix**: Audit all rule files for contradictions. Use a single source of truth for each behavioral directive. If rules need to vary by context, make the conditions explicit rather than relying on file ordering

### References to Non-Existent Files or Paths
- **Pattern**: Instructions in `CLAUDE.md` or rule files that reference specific file paths, commands, or tools that do not exist in the repository (e.g., "see `docs/api-guide.md`" when the file was deleted)
- **Risk**: Agent attempts to follow instructions that reference phantom resources, producing errors or hallucinated content to fill the gap
- **Fix**: Periodically validate that all file paths, command names, and tool references in rule files resolve to real resources. Remove or update references after renaming, moving, or deleting files

### References to Deprecated Tools or Approaches
- **Pattern**: Instructions that reference tools, libraries, or patterns that the project has moved away from (e.g., "use `mocha` for tests" when the project migrated to `vitest`)
- **Risk**: Agent generates code using the deprecated approach, creating inconsistency and potential compatibility issues with the current stack
- **Fix**: Maintain a deprecation section in project rules (or the beads-workflow deprecated approaches table). When migrating tools, update all rule files that reference the old tool

### Overly Long Rule Files
- **Pattern**: Individual `CLAUDE.md` or rule files exceeding 500 lines, or total rules content exceeding 2000 lines across all loaded files
- **Risk**: Large rule files consume context window budget that would be better used for code and conversation. Rules buried deep in long files may be ignored or lost during compaction
- **Fix**: Keep individual rule files under 300 lines. Extract detailed reference material into skill reference docs that load on demand. Prioritize rules by putting the most critical ones first

## Harness Configuration (.claude/harness.yaml)

### Missing Required Fields
- **Pattern**: `harness.yaml` files missing `schema_version` or `project.name`, or using an unrecognized `schema_version` value
- **Risk**: Harness commands may fail with unhelpful errors or behave unpredictably when required fields are absent. Version mismatches cause silent behavior changes
- **Fix**: Ensure every `harness.yaml` includes at minimum `schema_version: 1` and `project.name`. Validate against the schema after edits. Copy from a working example rather than writing from scratch

### Stack Values That Do Not Match Project Reality
- **Pattern**: `stack.language` or `stack.framework` values that do not match the actual project (e.g., `language: python` in a Go project, or `framework: react` when the project uses Vue)
- **Risk**: Language-specific anti-patterns, review rules, and code generation hints target the wrong language, producing irrelevant or incorrect guidance
- **Fix**: Set `stack.language` and `stack.framework` to match the project's primary language and framework. If the project is polyglot, set the dominant language and note others in comments

### Review Routing Patterns Referencing Non-Existent Agents
- **Pattern**: Review configuration that routes findings to agent definitions that do not exist or whose names have changed
- **Risk**: Review findings are silently dropped or routed to a generic agent that lacks the domain knowledge needed to act on them
- **Fix**: Verify that all agent names in review routing match defined agent configurations. After renaming agents, update all routing references

### Doc Manifest Paths Outside Project Root
- **Pattern**: `docs_manifest` entries with paths that traverse outside the project root (e.g., `../shared-docs/api.md`) or use absolute paths
- **Risk**: Doc loading fails in CI, in worktrees, or on other developers' machines where the external path does not exist
- **Fix**: Keep all doc manifest paths relative to the project root. If shared docs are needed, copy or symlink them into the project tree

## Agent Definitions

### Agent Prompts with Absolute Paths
- **Pattern**: Agent system prompts or instructions containing absolute file paths (e.g., `/home/user/project/src/main.go` instead of `src/main.go`)
- **Risk**: Agents fail or produce incorrect references when run from a different checkout location, worktree, or machine
- **Fix**: Use project-relative paths in all agent prompts. Reference files relative to the repository root, not the filesystem root

### Missing Skill References
- **Pattern**: Agents defined for tasks that require specific domain knowledge (e.g., code review) but without `skills:` entries for the relevant skills (e.g., `code-quality`)
- **Risk**: Agent operates without the domain-specific rules and anti-patterns, producing lower-quality output that misses known issues
- **Fix**: Include `skills: [<relevant-skills>]` in agent definitions. Review agents should include `code-quality`. Harness-aware agents should include `work-harness`

### Agent Names That Do Not Match Expertise
- **Pattern**: Agents named generically (e.g., `helper`, `worker`, `agent-1`) rather than reflecting their domain expertise (e.g., `security-reviewer`, `database-architect`)
- **Risk**: Agent name primes LLM behavior — generic names produce generic output. Named expertise focuses the agent on its intended domain
- **Fix**: Name agents as domain experts: `security-reviewer`, `api-designer`, `performance-analyst`. The name should describe what knowledge the agent brings, not its process role

### Overly Broad Agent Scopes
- **Pattern**: A single agent definition covers too many concerns (e.g., one agent responsible for "review code, write tests, update docs, deploy, and monitor")
- **Risk**: Jack-of-all-trades agents produce shallow results in each area. Domain expertise is diluted across too many responsibilities
- **Fix**: Split broad agents into focused specialists. Each agent should own one domain or quality dimension. Coordinate via a lead agent that delegates to specialists

## MCP Configuration

### Invalid Command Paths
- **Pattern**: MCP server entries in configuration with `command` fields pointing to executables that do not exist at the specified path
- **Risk**: MCP server fails to start, disabling all tools provided by that server. Errors may not surface until the agent tries to use a tool
- **Fix**: Verify that MCP server command paths exist and are executable. Use `which` or `command -v` to validate. For project-local servers, use relative paths from the project root

### Missing Required Environment Variables
- **Pattern**: MCP servers that require environment variables (API keys, database URLs) but the variables are not set in the shell environment or `.env` file
- **Risk**: MCP server crashes on startup or returns authentication errors when tools are invoked, with error messages that may not clearly indicate the missing variable
- **Fix**: Document required environment variables in the MCP server's README or config comments. Validate at startup that required variables are present. Use `.env.example` to list required variables

### Duplicate Server Names
- **Pattern**: Multiple MCP server entries configured with the same `name` field in the MCP configuration
- **Risk**: Only one server instance runs under that name, shadowing the other. Tools from the shadowed server are unavailable with no error
- **Fix**: Use unique, descriptive names for each MCP server entry. Include the server's purpose in the name (e.g., `serena-lsp`, `github-api`) rather than generic names

### Servers Configured but Never Referenced
- **Pattern**: MCP servers defined in configuration that are not referenced by any skill, rule, or agent definition in the project
- **Risk**: Unused servers consume resources (process memory, API connections) and add startup latency without providing value. They also create confusion about what tools are available
- **Fix**: Remove MCP server configurations that are no longer needed. If a server was added for a specific feature that was removed, clean up the configuration entry
