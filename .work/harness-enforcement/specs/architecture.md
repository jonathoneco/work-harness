# Architecture: Harness Enforcement

## Problem

The work harness relies on LLM discipline for step transitions, artifact creation, and review execution. The dev-env-silo stress test showed progressive discipline collapse: the agent abandoned step gates, skipped artifact creation, and marked review "completed" without running it.

## Goals

1. **Mechanical enforcement** — hooks validate post-conditions that commands are supposed to produce. Cannot be bypassed by the LLM.
2. **Self-driving flow** — commands auto-advance between steps. User interacts with natural language, not manual slash commands.
3. **No false blocks** — hooks must not block legitimate work patterns (experimentation, Tier 1 quick fixes, manual overrides).

## Design Principles

- **Hooks enforce, commands orchestrate** — hooks are the guardrails, commands are the steering wheel
- **Validate post-conditions, not intentions** — check "did the file get created?" not "did the LLM plan to create it?"
- **Blocking for critical, warning for important** — exit 2 for state corruption, stderr message for missing artifacts
- **Project-level hooks** — live in `.claude/hooks/` (committed), not `~/.claude/hooks/` (personal). Global hooks defer to project-level.

## Component Map

### Component 1: State Mutation Guard (`state-guard.sh`)

**Trigger:** PostToolUse — fires after any Write/Edit to `.work/*/state.json`

**Validates:**
- `current_step` is a value in the `steps[].name` array
- Exactly one step has `status: "active"` and it matches `current_step`
- No backwards transitions (completed → active)
- `completed` steps have a timestamp or completion marker
- `tier` field is 1, 2, or 3
- `archived_at` is null for active tasks

**Behavior:** Exit 2 (blocking) — state corruption breaks the entire workflow.

**Cost:** ~50 lines bash + jq. LOW complexity.

### Component 2: Artifact Gate (`artifact-gate.sh`)

**Trigger:** Stop — fires at session end

**Validates (Tier 2-3):**
- For each step in [research, plan, spec, decompose] with `status: "completed"`:
  - `.work/<name>/<step>/handoff-prompt.md` exists and is non-empty
- Research step completed → `research/index.md` exists
- Spec step completed → at least one `.work/<name>/specs/` spec file exists

**Behavior:** Exit 2 (blocking) — missing handoffs break multi-session continuity.

**Cost:** ~40 lines bash. LOW complexity.

### Component 3: Review Verification (`review-verify.sh`)

**Trigger:** Stop — fires at session end (composable with existing stop hooks)

**Validates (Tier 2-3 only):**
- If task `archived_at` is being set (archive in progress):
  - `.work/<name>/review/findings.jsonl` has at least one entry with matching `task_name`
  - OR state.json has `reviewed_at` timestamp (explicit "review ran, found nothing" marker)
- If review step `status: "completed"`:
  - Same validation as above

**Behavior:** Exit 2 (blocking) — prevents archive without review evidence.

**State model addition:** Add `reviewed_at` field to state.json, set by `/work-review` when it runs.

**Cost:** ~30 lines bash + jq. LOW complexity.

### Component 4: Command Auto-Advancement

**Not a hook — changes to command markdown files.**

Modify `/work-deep` step router sections to:
1. After completing step logic, automatically create handoff prompt
2. Automatically create gate issue
3. Present summary to user
4. Advance state.json to next step
5. Continue to next step's logic immediately

**Pattern:**
```
### When current_step = "research"
[... do research ...]
[... create handoff-prompt.md ...]
[... create gate issue ...]
[... present summary ...]
[... advance state to "plan" ...]
[... fall through to plan section ...]
```

The user can interrupt at any gate summary with questions or redirects. Default is forward flow.

**Cost:** Modify 4 step sections in `/work-deep` command. MEDIUM complexity.

### Component 5: Step Output Review Gates

**Not a hook — integrated into the auto-advancement flow (Component 4).**

After each major step completes, before advancing, spawn a critical review agent to validate the step's output. This catches consistency errors, missing fields, path mismatches, and underspecified logic before they compound into implementation failures.

**Steps that get output review:**

| Step | Review Agent Focus |
|------|-------------------|
| plan | Architecture completeness — are all components accounted for? Missing decisions? Unclear scope boundaries? |
| spec | Internal consistency — do specs reference each other correctly? Path conventions match? Fields declared in 00 used consistently? Edge cases covered? |
| decompose | Coverage — does every spec map to a work item? Dependencies correct? Streams parallelizable as claimed? |
| implement | Already exists as step 7 (`/work-review` with specialist agents) |

**Review agent pattern:**
1. Auto-advancement reaches the gate between step A and step B
2. Spawn an Explore agent with read-only access to the step's output artifacts
3. Agent checks for internal consistency, missing fields, edge cases, path mismatches
4. Agent returns findings (issues found or "clean")
5. If issues found: present to user, fix before advancing
6. If clean: present brief "review clean" note, auto-advance

**Not blocking at the hook level** — this is orchestrated by the command, not enforced by a shell hook. The hook layer validates artifacts exist; the review agent validates artifact quality.

**Cost:** ~50 lines added to `/work-deep` command per reviewed step. MEDIUM complexity.

### Component 6: work-check.sh Fix

**Fix the timestamp comparison logic.**

Current: checks if ANY checkpoint exists (binary).
Fixed: checks if latest checkpoint is newer than `updated_at` in state.json.

**Cost:** ~10 line diff. LOW complexity.

## Hook Registration

All new hooks registered in `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": ".claude/hooks/state-guard.sh" }]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/artifact-gate.sh" },
          { "type": "command", "command": ".claude/hooks/review-verify.sh" }
        ]
      }
    ]
  }
}
```

Note: `state-guard.sh` on PostToolUse with Write|Edit matcher will fire on ALL writes, not just state.json. The hook must check the file path internally and exit 0 for non-state files.

## Testing Strategy

Each hook testable independently:
1. Write a deliberately invalid state.json → verify state-guard blocks
2. Mark a step completed without handoff → verify artifact-gate blocks at session end
3. Archive without review → verify review-verify blocks

Integration test: run through a mini Tier 3 workflow end-to-end, verify all gates fire.

## Migration Plan

1. Deploy hooks first (Components 1-3, 6) — immediate enforcement
   - **Note:** W-02 (artifact-gate) must implement the NEW path checks (`.work/<name>/specs/`) per Component 8, not the old `docs/feature/<name>/` path. W-12 (docs cleanup) migrates the data; W-02 validates the new layout.
2. Deploy command auto-advancement with step output reviews (Components 4-5) — improved UX + quality gates
3. Deploy harness QoL (Components 7-9) — parallel agent streams, docs cleanup, futures
4. Doc migration (Component 10) — runs after W-12 changes the commands
5. All backward-compatible — existing active tasks will work with new hooks

## Component 7: Parallel Agent Streams (Decompose/Implement)

**Changes to `/work-deep` decompose and implement steps.**

Decompose currently creates streams as logical groupings with optional worktree-based parallelism. The worktree overhead isn't worth it — streams should be designed as parallel agent workloads instead.

**Decompose changes:**
- Streams become self-contained agent prompts, not worktree branches
- Each stream's execution doc includes everything an agent needs: spec references, file list, acceptance criteria, dependency constraints
- The handoff prompt describes streams as "launch one agent per stream" not "optionally create worktrees"

**Implement changes:**
- Lead agent reads the streams handoff and spawns one subagent per independent stream (same repo, no branch splitting)
- Each subagent gets: stream execution doc + relevant specs + `skills: [work-harness, code-quality]`
- Subagents use `bd update/close` to claim and complete their work items
- Lead monitors completion and manages cross-stream dependencies (Phase 2+ items wait for Phase 1 agents to finish)
- No worktree references anywhere

**Cost:** Modify decompose and implement sections in `/work-deep`. LOW complexity (text changes, no new scripts).

## Component 8: Docs Cleanup — Single Summary File

**Changes to `/work-deep` spec step and `/work-archive`.**

Currently, spec step writes detailed specs to `docs/feature/<name>/` (a directory with multiple files). These are working artifacts that belong in `.work/`, not published docs.

**New layout:**
- Detailed specs written to `.work/<name>/specs/` (already exists as a directory)
- `docs/feature/<name>.md` is a **single summary file** (not a directory) — contains: what, why, status, key decisions
- Summary file created at plan step, updated at spec step, finalized at archive

**Affected references:**
- Component 2 (`artifact-gate.sh`): update spec file existence check from `docs/feature/<name>/` to `.work/<name>/specs/`
- Spec step in `/work-deep`: write specs to `.work/<name>/specs/`, not `docs/feature/<name>/`
- Archive step: ensure summary file at `docs/feature/<name>.md` is up to date

**Cost:** Text changes across spec step, artifact-gate spec, and archive command. LOW complexity.

## Component 9: Futures at Any Step

**Cross-cutting change to all work commands.**

Currently futures can only be captured during the research step and dead-end redirects. But deferred enhancements are discovered at every step — plan, spec, decompose, implement, review. When no futures mechanism is available, agents save to Claude memories instead, which loses the structured format and promotion path.

**Changes:**
- Storage moves from `.work/<name>/research/futures.md` to `.work/<name>/futures.md` (task-level, not research-specific)
- Every step section in `/work-deep` gets: "If you discover deferred enhancements, append to `.work/<name>/futures.md`"
- `/work-feature` and `/work-fix` also get futures guidance (Tier 1-2 tasks can discover futures too)
- `/work-archive` promotion path updated: reads from `.work/<name>/futures.md` instead of `.work/<name>/research/futures.md`
- Format unchanged (title, horizon, domain, identified date, description, context, prerequisites)

**Cost:** One-line additions to each step section + archive path update. LOW complexity.

## Component 10: Doc Migration for Previous Workflows

**One-time migration task — not a command change.**

Component 8 changes the docs layout from `docs/feature/<name>/` (directory, many files) to `docs/feature/<name>.md` (single summary). This applies to NEW tasks. Previous workflows have 171 files across 11 directories that need migration.

**Scope:**

| Directory | Files | Action |
|-----------|-------|--------|
| harness-enforcement | 11 | Move specs to `.work/harness-enforcement/specs/`, create summary `.md` |
| phase-2 | 1 | Already minimal — convert dir to single `.md` |
| dev-env-silo | 1 | Already minimal — convert dir to single `.md` |
| work-harness-v2 | 23 | Archived — move specs under `.workflows/archive/work-harness-v2/specs/`, create summary |
| phase-1-implementation | 30 | Active legacy — move specs under `.workflows/`, create summary |
| shim-removal | 27 | Archived — move under `.workflows/archive/`, create summary |
| phase-0-code-review | 20 | Archived — move under `.workflows/archive/`, create summary |
| phase-1-code-review | 22 | Archived — move under `.workflows/archive/`, create summary |
| tailwind-upgrade | 13 | Active legacy — move under `.workflows/`, create summary |
| agentic-push | 23 | Orphaned (no .work dir) — archive or delete |

**External references to update (10+):**
- `.claude/commands/work.md`, `work-deep.md`, `work-feature.md`, `work-reground.md`
- `.claude/skills/work-harness/references/state-conventions.md`, `depth-escalation.md`
- `.claude/agents/work-spec.md`
- `.claude/rules/workflow.md`

**Ordering:** Runs after W-12 (docs cleanup command changes) is implemented. W-12 changes the harness commands; W-14 migrates existing data to match.

**Cost:** Mechanical file moves + 10 reference updates. MEDIUM complexity (many files, low risk per file).

## Component 11: Post-Phase Validation Steps

**Changes to `/work-deep` implement step.**

After each implementation phase completes (e.g., Phase 1 hooks are all done), run a validation step against the relevant specs before starting the next phase. This catches implementation drift early — before dependent phases build on a wrong foundation.

**Pattern:**
1. Phase N agents complete their work items
2. Lead agent spawns validation agent (Explore, read-only)
3. Validation agent checks: do the implementations match their specs? Are contracts satisfied? Do hooks exit correctly?
4. If issues found: fix before starting Phase N+1
5. If clean: proceed to Phase N+1

**Phase-specific validation:**

| Phase | What to Validate |
|-------|-----------------|
| Phase 1 (hooks) | Each hook handles edge cases from its spec. settings.json has all hooks registered. |
| Phase 2 (hook registration + commands) | Hooks fire correctly on Write/Edit and Stop events. reviewed_at lifecycle works. |
| Phase 3 (auto-advance) | State transitions produce valid state.json. Handoff prompts created. |
| Phase 4 (step reviews) | Review agents spawn correctly. Findings presented. Override tracking works. |
| Phase 5 (e2e) | Already exists as W-09. Full workflow traversal. |

**Cost:** ~20 lines added to `/work-deep` implement step instructions. LOW complexity.

## Component 12: Scope Expansion Detection

**Changes to `/work-deep` step router — cross-cutting concern.**

When a user requests changes that expand the scope of a task (adding new components, new work items, new specs), the agent should detect that it's doing plan/spec-level work while in a later step (decompose/implement). The harness should acknowledge the regression rather than silently adding scope.

**Detection heuristic:**
- Creating new spec files while `current_step` is decompose or later → scope expansion
- Adding new components to architecture while `current_step` is decompose or later → scope expansion
- Creating new beads issues that don't map to existing specs → scope expansion

**Response when detected:**
1. Acknowledge: "This adds new scope. We're currently in [step] but this is [plan/spec] work."
2. Present options:
   - "Roll back to [plan/spec] to properly integrate this" (formal)
   - "Add it as a lightweight amendment and continue" (pragmatic — update architecture + create work items without full step regression)
3. User decides which path

**Not blocking** — this is prompt-level guidance in the command, not a hook. Hooks can't detect semantic scope expansion. But the command text should prime the agent to recognize the pattern.

**Cost:** ~10 lines added to each step section. LOW complexity.

## Scope Exclusions

- Findings.jsonl append-only protection (PreToolUse) — deferred, lower priority
- Beads integration validation (epic_id, gate_id checks) — nice-to-have, not critical
- New state.json schema fields beyond `reviewed_at` — keep minimal
