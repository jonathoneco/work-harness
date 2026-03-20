# Agent Tool API Surface

## Core Parameters

| Parameter | Values | Notes |
|-----------|--------|-------|
| `subagent_type` | `Explore`, `Plan`, `general-purpose`, custom strings | Custom strings act as domain experts |
| `prompt` | string | Full task description with context |
| `mode` | `acceptEdits`, `plan`, `default`, `auto`, `dontAsk`, `bypassPermissions` | Controls permission model |
| `isolation` | `worktree` | Git worktree isolation (Agent tool param) |
| `run_in_background` | boolean | Async execution with notification on completion |
| `name` | string | Makes agent addressable via SendMessage |
| `model` | `sonnet`, `opus`, `haiku` | Override default model |

## Communication Patterns

- **Foreground**: Agent returns result directly. Lead blocks until complete.
- **Background**: Agent runs async. Lead gets notification on completion.
- **SendMessage**: Can address named agents. NOT currently used in harness.
- **File-based**: Agents write to `.work/` directories. Lead reads results.

## Current Harness Usage vs Available API

| Feature | Available | Used by Harness |
|---------|-----------|-----------------|
| `run_in_background` | Yes | No — all foreground |
| `name` + SendMessage | Yes | No — no agent naming |
| `model` override | Yes | No — inherits parent |
| `mode: auto` | Yes | No — uses acceptEdits/plan/default |
| Custom subagent_type | Yes | Minimal — mostly Explore/Plan/general-purpose |
| Agent Teams (TeamCreate) | Yes (experimental) | No |

## Skill Propagation

- YAML frontmatter `skills:` field NOT supported by Agent tool
- Path B (prompt injection): inject Read instructions into agent prompt
- Skill routing tables in each tier command define which skills each step gets

## Agent Teams Status

- Available via TeamCreate/TeamDelete tools
- NOT used in harness
- Limitations: experimental flag required, no session resumption, API may change
- Current workaround: manual phase-gated parallelism via stream docs
