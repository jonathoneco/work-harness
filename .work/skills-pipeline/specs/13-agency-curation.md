# Spec C12: Agency-Agents Curation Docs

**Component**: C12 — Agency-agents curation docs
**Phase**: 4 (Integration)
**Status**: complete
**Dependencies**: Spec 00 (frontmatter schema), Spec C13 (meta block)

---

## Overview and Scope

Creates curation documentation for the agency-agents collection, recommending which agents are most useful for specific stack configurations. Also adds a harness-doctor validation check for agency-agents installation status.

**What this does**:
- Creates `claude/skills/work-harness/agency-curation.md` skill with per-stack agent recommendations
- Adds an agency-agents health check to `harness-doctor.md`

**What this does NOT do**:
- Modify the agency-agents repository itself
- Change how agency-agents are installed (install.sh --agents remains as-is)
- Make agency-agents required (they remain optional)

---

## Implementation Steps

### Step 1: Create Agency Curation Skill

Create `claude/skills/work-harness/agency-curation.md`:

```yaml
---
name: agency-curation
description: "Per-stack recommendations for agency-agents selection. Consumed by harness-doctor and delegate command for optimal agent routing."
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---
```

Content:

```markdown
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
```

**Acceptance Criteria**:
- AC-C12-1.1: Curation skill exists at `claude/skills/work-harness/agency-curation.md`
- AC-C12-1.2: At least 5 stack profiles have agent recommendations (Go, Python, TS/React, Fullstack, Rust)
- AC-C12-1.3: Each stack profile has Essential and Recommended tiers
- AC-C12-1.4: Each stack profile includes a `review_routing` YAML example
- AC-C12-1.5: Agent selection criteria section exists with 3 criteria

### Step 2: Add Agency Health Check to harness-doctor

Add a new check (Check 8) to `claude/commands/harness-doctor.md`:

```markdown
### Check 8: Agency-Agents Recommendations

Read `stack.language` and `stack.framework` from `.claude/harness.yaml` (skip if check 1 failed). Cross-reference against the agency-curation skill's recommendations for the detected stack.

Steps:
1. Determine the stack profile from harness.yaml (e.g., "Go Backend", "TypeScript/React Frontend")
2. Look up the "Essential" agents for that profile from the agency-curation skill
3. Check if each essential agent exists at `~/.claude/agents/<name>.md`

Results:
- **PASS**: All essential agents for this stack are installed. Report: "Essential agents found for [profile]: [names]"
- **WARN** (missing essentials): "Missing essential agents for [profile]: [names]. Run `./install.sh --agents` to install."
- **PASS** (no profile match): "No specific agent recommendations for this stack configuration"
- **PASS** (no harness.yaml): Skipped (depends on check 1)
```

Update the summary section to reflect 8 checks instead of 7.

**Acceptance Criteria**:
- AC-C12-2.1: Check 8 is added to harness-doctor.md
- AC-C12-2.2: Check reads stack config and cross-references agent recommendations
- AC-C12-2.3: Check reports missing essential agents as WARN
- AC-C12-2.4: Summary section updated from 7 to 8 checks

### Step 3: Update `work-harness.md` References

Add:
```markdown
- **agency-curation** — Per-stack agent recommendations for review routing (path: `claude/skills/work-harness/agency-curation.md`)
```

**Acceptance Criteria**:
- AC-C12-3.1: `work-harness.md` References section includes `agency-curation`

---

## Interface Contracts

### Exposes

- **`agency-curation` skill**: Per-stack agent recommendations
- **harness-doctor Check 8**: Agency-agents health validation

### Consumes

- **Spec 00 Contract 2**: `meta` block in frontmatter
- **`harness.yaml`**: `stack.language`, `stack.framework` for profile detection
- **Agency-agents installation**: Files at `~/.claude/agents/`

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/skills/work-harness/agency-curation.md` | Curation skill |
| Modify | `claude/commands/harness-doctor.md` | Add Check 8 |
| Modify | `claude/skills/work-harness.md` | Add agency-curation reference |

**Total**: 1 new file, 2 modified files

---

## Testing Strategy

1. **Stack profile matching**: Verify that for a project with `stack.language: go`, the curation skill identifies the "Go Backend" profile and lists essential agents.

2. **Agent existence check**: Run the new harness-doctor Check 8. Verify it correctly reports installed vs missing agents.

3. **Review routing validity**: For each stack profile's `review_routing` example, verify the YAML is valid and the patterns are valid glob patterns.

4. **No regression on harness-doctor**: Verify existing checks 1-7 are unchanged and the summary correctly reports 8 checks.
