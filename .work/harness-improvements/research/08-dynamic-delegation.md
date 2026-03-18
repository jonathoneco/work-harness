# Dynamic Delegation & Auto-Reground Research

## Dynamic Agent Selection

### Current State
- Claude Code has **no native conditional activation** — everything in `~/.claude/` always loads
- Selection is LLM-based: matches task description to agent description
- Harness commands already function as routers (read tier/step, spawn appropriate agents)

### Recommended Approach: Command-Level Router
Each command already knows tier and step. Map transitions to agents:
- `research` -> spawn `work-research` with `skills: [work-harness]`
- `implement` -> spawn `work-implement` with `skills: [work-harness, code-quality]`
- `review` -> spawn `work-review` with `skills: [code-quality]`

### Skill Propagation Fix
**Current**: Agents reference skills informally in markdown body (`skills: [work-harness]`)
**Should be**: YAML frontmatter `skills:` field — enables official preloading mechanism

Subagents do NOT inherit parent skills — must be listed explicitly in frontmatter.

### Path-Scoped Rules
Rules can include `paths:` YAML frontmatter with glob patterns:
```yaml
paths:
  - "src/api/**/*.ts"
```
Move phase-specific guidance from always-loaded rules into skills (loaded on demand).

## Auto-Reground on Resume

### Mechanism: SessionStart Hook
```json
{"event":"SessionStart","matcher":"resume","command":"hooks/session-reground.sh"}
```

### What the Hook Should Do
1. Scan `.work/*/state.json` for active tasks
2. Read current step and tier
3. Read most recent handoff prompt
4. Output as `additionalContext` for Claude
5. Optionally suggest running `/work-reground`

### SessionStart Matchers
| Matcher | When |
|---------|------|
| `startup` | New session |
| `resume` | --resume, --continue, /resume |
| `clear` | /clear |
| `compact` | Auto or manual compaction |

### Implementation
- Create `hooks/session-reground.sh` — fires on `resume` and `startup`
- Consolidate with existing `post-compact.sh` — both do context recovery
- Register in `install.sh`'s hook entries

### Environment Persistence
SessionStart hooks can write to `$CLAUDE_ENV_FILE` to persist env vars across session.
