# Work Harness Active

This project uses the adaptive work harness. Task state is tracked in `.work/` directories with summary files in `docs/feature/`.

## Available Work Commands

| Command | Purpose |
|---------|---------|
| `/work <description>` | Auto-assess task depth and route to the right tier |
| `/work-fix <description>` | Quick fix — single-session with auto-review |
| `/work-feature <description>` | Feature — plan, implement, review in 1-2 sessions |
| `/work-deep <description>` | Initiative — multi-session with research, specs, phased implementation |
| `/work-research <topic>` | Standalone research — investigate a topic with structured synthesis |
| `/work-review` | Run specialist review agents, track findings |
| `/work-status [name]` | Show active task progress and suggested next action |
| `/work-checkpoint [--step-end]` | Save session progress, optionally advance step |
| `/work-reground [name]` | Recover context after a break or compaction |
| `/work-redirect <reason>` | Record a dead end and pivot |
| `/work-archive [name]` | Archive a completed task |
| `/delegate <description>` | Delegate a sub-task to a specialist agent with context seeding |
| `/workflow-meta` | Enter harness self-modification mode |
| `/dev-update` | Generate developer status update |
| `/work-dump` | Decompose work into scoped workflows |
| `/work-skill-update` | Scan skills for staleness |

## Key Principles

- **Context via files, not memory**: Steps produce handoff prompts and checkpoints for session continuity
- **Handoff prompts are the firewall**: Never re-read raw research notes — use handoff prompt summaries
- **4 tiers**: Fix (T1), Feature (T2), Initiative (T3), Research (R) — auto-detected by triage or explicit command
- **Steps are data**: The `steps` array in state.json defines available phases per tier
- **Beads integration**: Every task has a beads issue; Tier 3 tasks have an epic
- **State committed to git**: `.work/` directory is tracked

## Sync Contract

The command reference table above must stay synchronized with the actual commands in `claude/commands/`. If a command is added, renamed, or removed, this table must be updated to match. The `workflow-meta` skill documents this maintenance requirement.

## When Starting a Session

If `.work/` contains active tasks (state.json where `archived_at` is null), run `/work-reground` to recover context before making changes.
