---
name: agency-curation
description: "Per-stack recommendations for agency-agents selection. Consumed by harness-doctor and delegate command for optimal agent routing."
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-25
---

# Agency-Agents Curation

Recommendations for which agency-agents to prioritize based on project stack configuration. The agency-agents collection contains 50+ agents — this curation identifies the highest-value agents per stack to avoid overwhelming context.

## When This Activates

- Running `/harness-doctor` (checks for recommended agents)
- Running `/delegate` (suggests relevant agents for the task)
- Planning review routing in `harness.yaml`

## Agent Recommendations by Stack

### Go Backend
**Essential**: code-reviewer, security-reviewer, devops-automator
**Recommended**: database-architect, api-designer, performance-engineer
**Review routing example**:
```yaml
review_routing:
  - pattern: "**/*.go"
    agents: [code-reviewer]
  - pattern: "**/migrations/**"
    agents: [database-architect]
  - pattern: "Dockerfile|*.yaml"
    agents: [devops-automator]
```

### Python Backend
**Essential**: code-reviewer, security-reviewer
**Recommended**: database-architect, api-designer, ml-expert (if ML project)
**Review routing example**:
```yaml
review_routing:
  - pattern: "**/*.py"
    agents: [code-reviewer]
  - pattern: "**/models/**"
    agents: [database-architect]
```

### TypeScript/React Frontend
**Essential**: code-reviewer, ux-reviewer
**Recommended**: performance-engineer, accessibility-expert
**Review routing example**:
```yaml
review_routing:
  - pattern: "**/*.tsx"
    agents: [code-reviewer, ux-reviewer]
  - pattern: "**/components/**"
    agents: [ux-reviewer]
```

### Fullstack (Go/Python + React/Next.js)
**Essential**: code-reviewer, security-reviewer, ux-reviewer
**Recommended**: database-architect, api-designer, devops-automator
**Review routing example**:
```yaml
review_routing:
  - pattern: "**/*.go"
    agents: [code-reviewer, security-reviewer]
  - pattern: "**/*.tsx"
    agents: [code-reviewer, ux-reviewer]
  - pattern: "**/migrations/**"
    agents: [database-architect]
```

### Rust
**Essential**: code-reviewer, security-reviewer
**Recommended**: performance-engineer
**Review routing example**:
```yaml
review_routing:
  - pattern: "**/*.rs"
    agents: [code-reviewer]
  - pattern: "**/unsafe/**"
    agents: [security-reviewer]
```

## Agent Selection Criteria

When adding agents to `review_routing`, consider:

1. **Relevance**: Does this agent's expertise match the file pattern?
2. **Signal-to-noise**: Too many agents per pattern generates duplicate findings. 2-3 agents per pattern is the sweet spot.
3. **Availability**: Agent must exist at `~/.claude/agents/<name>.md` (installed via `./install.sh --agents`)

## Missing Agent Guidance

If a recommended agent is not installed:
1. Run `./install.sh --agents` to install the full collection
2. Or create a project-specific agent at `.claude/agents/<name>.md`
3. The review will still work without the agent — it just won't have that specialist perspective
