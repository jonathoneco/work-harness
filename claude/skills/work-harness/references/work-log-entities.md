# Work Log Entity Schema

Entity types, relations, and observation conventions for the `work-log` MCP Knowledge Graph server. Referenced by the `/handoff` command and available for manual querying.

## Entity Types

| Entity Type | Name Pattern | Observations |
|-------------|-------------|--------------|
| `WorkSession` | `session-YYYY-MM-DD-<project>` | date, project, summary |
| `Decision` | `decision-<short-slug>` | what, why, alternatives_considered, decided_at |
| `Blocker` | `blocker-<short-slug>` | what, status (active/resolved), resolution, reported_at, resolved_at |
| `Accomplishment` | `accomplishment-<short-slug>` | what, beans_ids (comma-separated), completed_at |

### WorkSession

Represents a single work session on a project. One per project per day, with `follows-up` relations for multiple sessions on the same day.

- **Name pattern**: `session-YYYY-MM-DD-<project>` (e.g., `session-2026-03-18-work-harness`)
- **Observations**:
  - `date`: ISO 8601 date (e.g., `2026-03-18`)
  - `project`: Project name matching `harness.yaml` `project.name` or git repo name
  - `summary`: One or two sentence summary of the session

### Decision

A significant technical or process decision made during work.

- **Name pattern**: `decision-<short-slug>` (e.g., `decision-use-jsonl-storage`)
- **Observations**:
  - `what`: The decision itself (one sentence)
  - `why`: Rationale for the decision (one sentence)
  - `alternatives_considered`: What else was evaluated (one sentence)
  - `decided_at`: ISO 8601 timestamp

### Blocker

An obstacle encountered during work, either active or resolved.

- **Name pattern**: `blocker-<short-slug>` (e.g., `blocker-npm-registry-down`)
- **Observations**:
  - `what`: Description of the blocker (one sentence)
  - `status`: `active` or `resolved`
  - `reported_at`: ISO 8601 timestamp
  - `resolution`: How it was resolved (one sentence, added when resolved)
  - `resolved_at`: ISO 8601 timestamp (added when resolved)

### Accomplishment

A completed work item or significant progress milestone.

- **Name pattern**: `accomplishment-<short-slug>` (e.g., `accomplishment-handoff-command`)
- **Observations**:
  - `what`: Description of what was accomplished (one sentence)
  - `beans_ids`: Comma-separated beans issue IDs if applicable (e.g., `work-harness-0nd`)
  - `completed_at`: ISO 8601 timestamp

## Relation Types

| Relation | From | To | Meaning |
|----------|------|------|---------|
| `session-includes` | WorkSession | Decision/Blocker/Accomplishment | This session produced this entity |
| `decision-for-task` | Decision | Accomplishment | This decision was made in service of this work |
| `blocked-by` | Accomplishment | Blocker | This work was blocked by this issue |
| `unblocked-by` | Blocker | Decision | This blocker was resolved by this decision |
| `follows-up` | WorkSession | WorkSession | This session continues work from a prior session |

## Observation Conventions

- **Short and factual**: Each observation is one sentence, stating a fact (not narrative)
- **Separate calls**: Each observation is a separate `add_observation` call, not batched into one long string
- **ISO 8601 dates**: All timestamps use ISO 8601 format (e.g., `2026-03-18T14:30:00Z`)
- **Project names**: Match the `harness.yaml` `project.name` field, or fall back to the git repo name
- **Slugs**: Use lowercase kebab-case, 2-4 words that capture the essence (e.g., `use-jsonl-storage`, `npm-registry-down`)

## Name Pattern Rules

- Entity names are globally unique across all projects (the project name is embedded in session names)
- Slugs should be descriptive enough to identify the entity without reading observations
- Avoid generic slugs like `decision-1` or `blocker-today` — be specific
- When a blocker and its resolving decision are related, their slugs should share vocabulary (e.g., `blocker-npm-auth-failure` and `decision-switch-npm-registry`)
