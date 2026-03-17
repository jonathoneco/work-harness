# 02: Artifact Gate (`artifact-gate.sh`)

## Overview

Stop hook that validates required artifacts exist for completed Tier 2-3 steps. Prevents session end when handoff prompts are missing — blocks the "advance without artifacts" failure mode.

## Trigger

- **Event:** Stop
- **Matcher:** `""` (all stops)

## Validation Rules

### Rule 1: Completed Tier 2-3 steps must have handoff prompts

For each active Tier 2-3 task, for each step with `status: "completed"` that requires a handoff prompt:
- The step's handoff prompt must exist and be non-empty at the mapped directory path

Steps with status `skipped` are NOT validated — only `completed` steps require artifacts.

Step-to-directory mapping:
- research -> research/
- plan -> plan/
- spec -> specs/  (plural — matches existing convention)
- decompose -> streams/ (handoff lives with stream docs)

The decompose step's handoff prompt lives at `.work/<name>/streams/handoff-prompt.md` (alongside stream execution documents, not in a separate `decompose/` directory).

If a task has 0 completed steps (all not_started or active), the hook exits 0. Incomplete tasks are caught at archive time.

Tier 2 tasks have fewer steps (plan → implement → review) so only `plan` typically needs a handoff. The hook validates whatever steps exist in the task's `steps[]` array — it doesn't hard-code which tiers have which steps.

```bash
# Map step names to their artifact directories
step_dir() {
  case "$1" in
    research)  echo "research" ;;
    plan)      echo "plan" ;;
    spec)      echo "specs" ;;
    decompose) echo "streams" ;;
  esac
}

steps_needing_handoff=("research" "plan" "spec" "decompose")

for step_name in "${steps_needing_handoff[@]}"; do
  status=$(jq -r --arg s "$step_name" '.steps[] | select(.name == $s) | .status' "$state_file")
  # Only validate completed steps — skipped steps require no artifacts
  [ "$status" = "completed" ] || continue

  dir=$(step_dir "$step_name")
  handoff="$task_dir/$dir/handoff-prompt.md"

  if [ ! -s "$handoff" ]; then
    echo "Artifact gate: step '$step_name' is completed but handoff-prompt.md is missing at $handoff" >&2
    echo "Create the handoff prompt before ending the session." >&2
    exit 2
  fi
done
```

### Rule 2: Completed research must have index (in addition to handoff)

Research requires **both** artifacts when completed:
- `.work/<name>/research/handoff-prompt.md` (caught by Rule 1)
- `.work/<name>/research/index.md` (caught by this rule — the structured findings index)

```bash
research_status=$(jq -r '.steps[] | select(.name == "research") | .status' "$state_file")
if [ "$research_status" = "completed" ]; then
  if [ ! -f "$task_dir/research/index.md" ]; then
    echo "Artifact gate: research is completed but research/index.md is missing" >&2
    exit 2
  fi
fi
```

### Rule 3: Completed spec must have spec files in `.work/`

If spec step is `completed`:
- `.work/<name>/specs/` must contain at least one `.md` file (excluding handoff-prompt.md and index.md)

```bash
spec_status=$(jq -r '.steps[] | select(.name == "spec") | .status' "$state_file")
if [ "$spec_status" = "completed" ]; then
  specs_dir="$task_dir/specs"
  if [ ! -d "$specs_dir" ]; then
    echo "Artifact gate: spec is completed but .work/<name>/specs/ directory missing" >&2
    exit 2
  fi
  # Count spec files (exclude handoff-prompt.md and index.md — those are metadata)
  spec_count=$(find "$specs_dir" -maxdepth 1 -name '*.md' ! -name 'handoff-prompt.md' ! -name 'index.md' 2>/dev/null | wc -l)
  if [ "$spec_count" -eq 0 ]; then
    echo "Artifact gate: spec is completed but no spec files in $specs_dir" >&2
    exit 2
  fi
fi
```

### Rule 4: Completed steps must have gate IDs

For each completed step in [research, plan, spec, decompose], `steps[].gate_id` must be non-null. This validates that the agent actually created a gate issue at each transition rather than silently advancing.

```bash
for step_name in research plan spec decompose; do
  status=$(jq -r --arg s "$step_name" '.steps[] | select(.name == $s) | .status // "not_started"' "$state_file")
  [ "$status" = "completed" ] || continue

  gate_id=$(jq -r --arg s "$step_name" '.steps[] | select(.name == $s) | .gate_id // "null"' "$state_file")
  if [ "$gate_id" = "null" ]; then
    echo "Artifact gate: step '$step_name' is completed but has no gate_id" >&2
    echo "Create a gate issue before advancing." >&2
    exit 2
  fi
done
```

### Rule 5: Spec files must be in `.work/`, not `docs/feature/`

If spec step is `completed`, check that no numbered spec files exist in `docs/feature/<name>/`. This prevents leakage to the old directory layout.

```bash
if [ "$spec_status" = "completed" ]; then
  task_name=$(jq -r '.name' "$state_file")
  old_specs=$(find "$CWD/docs/feature/$task_name" -maxdepth 1 -name '[0-9][0-9]-*.md' 2>/dev/null | wc -l)
  if [ "$old_specs" -gt 0 ]; then
    echo "Artifact gate: spec files found in docs/feature/$task_name/ — move to .work/$task_name/specs/" >&2
    exit 2
  fi
fi
```

**Note:** This rule only applies to tasks created after Component 8 (docs cleanup) is deployed. Existing tasks will be migrated by W-14. The hook should check for a marker (e.g., `updated_at` field exists, indicating the task uses the new schema) before enforcing this rule.

## Scope

- **Tier 2-3 only** — Tier 1 has no handoff prompts (single-session, uses `/work-fix`). Tier 2 tasks use `/work-feature` with fewer steps (plan → implement → review) but still require handoff prompts for completed steps to maintain session continuity.
- **Only active tasks** — skip archived tasks
- **Only completed steps** — don't validate in-progress work
- **Skipped steps** — if all steps in [research, plan, spec, decompose] are skipped or not_started, the hook exits 0

## Files to Create

- `.claude/hooks/artifact-gate.sh` (~50 lines)

## Files to Modify

- `.claude/settings.json` — add to Stop hooks array

## Testing

1. Mark research completed, delete index.md → expect block at session end
2. Mark plan completed, delete handoff-prompt.md → expect block
3. Mark plan completed with handoff-prompt.md present → expect allow
4. Tier 1 task with completed steps, no handoffs → expect allow (Tier 1 exempt)
5. Tier 3 with all steps not_started → expect allow (nothing to validate)
