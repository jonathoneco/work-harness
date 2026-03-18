# Depth Escalation

When and how to escalate a task from a lower tier to a higher one. Escalation happens when implementation reveals complexity that exceeds the current tier's scope.

## When to Escalate

Recognition signals:

- "This is more complex than expected"
- Implementation reveals unknown dependencies
- Scope expands beyond original assessment
- Single-session fix requires multi-session planning
- A Tier 1 task needs research or design decisions
- A Tier 2 task needs phased decomposition

Escalation is a **manual recognition**, not an automatic re-assessment. The original triage assessment is preserved — escalation appends to it.

## Escalation Process

Step-by-step:

1. **Detect**: During implementation, recognize the task exceeds current tier scope
2. **Update tier**: Change `tier` field (e.g., 1 → 2, or 2 → 3)
3. **Expand steps**: Insert new steps before `implement` in the `steps` array, following canonical order
4. **Initialize step_status**: Add new entries as `not_started` for each inserted step
5. **Reset existing steps**: Set `implement` and `review` back to `not_started`
6. **Rewind current_step**: Set `current_step` to the first new step (typically `plan` for 1→2, `research` for 1→3)
7. **Create epic** (if escalating to Tier 3): Create beads epic, set `beads_epic_id`
8. **Create docs directory** (if escalating to Tier 2-3): Create `docs/feature/<name>/`, set `docs_path`
9. **Append rationale**: Add escalation note to `assessment.rationale`

## What Changes on Escalation

- `tier` field updated
- `steps` array expanded with new steps in canonical order
- `step_status` gains new entries; `implement` and `review` reset to `not_started`
- `current_step` rewound to first new step
- `docs_path` may be set (if escalating to Tier 2-3 and was null)
- `beads_epic_id` may be set (if escalating to Tier 3)
- `assessment.rationale` gets escalation note appended

## What Does NOT Change

- **Task name** — no rename
- **`.work/` directory location** — same path
- **`assess` step status** — remains `completed`
- **Original assessment scoring** — factors and score are preserved unchanged
- **`base_commit`** — still the original commit at task creation
- **`issue_id`** — same beads issue

## Example: Tier 1 → Tier 3

### Before escalation

```json
{
  "tier": 1,
  "steps": [
    {"name": "assess", "status": "completed", "started_at": "2026-03-14T10:00:00Z", "completed_at": "2026-03-14T10:01:00Z"},
    {"name": "implement", "status": "active", "started_at": "2026-03-14T10:01:00Z"},
    {"name": "review", "status": "not_started"}
  ],
  "current_step": "implement"
}
```

### After escalation

```json
{
  "tier": 3,
  "steps": [
    {"name": "assess", "status": "completed", "started_at": "2026-03-14T10:00:00Z", "completed_at": "2026-03-14T10:01:00Z"},
    {"name": "research", "status": "not_started"},
    {"name": "plan", "status": "not_started"},
    {"name": "spec", "status": "not_started"},
    {"name": "decompose", "status": "not_started"},
    {"name": "implement", "status": "not_started"},
    {"name": "review", "status": "not_started"}
  ],
  "current_step": "research"
}
```

No format translation. No file migration. Same schema, same `.work/<name>/` directory.
