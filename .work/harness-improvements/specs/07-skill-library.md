# Spec 07: Skill Library (C7)

## Overview

Extract ~350 lines of repeated logic from 7+ commands into three shared skills (`task-discovery`, `step-transition`, `phase-review`) and DRY ~120 lines of hook boilerplate into `hooks/lib/common.sh`. This is Phase 2 foundational work that enables Dynamic Delegation (C8) and Parallel Execution v2 (C9) by making command logic referenceable as discrete, routable units.

## Scope

### In Scope

- Three new skills under `claude/skills/work-harness/`:
  - `task-discovery.md` -- active task finding, state.json reading, tier-command mapping
  - `step-transition.md` -- approval ceremony, gate file creation, state update, compaction prompt
  - `phase-review.md` -- Phase A + Phase B review template with verdict handling
- Shared hook utility library: `hooks/lib/common.sh`
- Updating existing commands to reference skills instead of inlining logic
- Updating existing hooks to source `hooks/lib/common.sh`

### Out of Scope

- Changes to state.json schema (no new fields)
- Gate Protocol file format (C4 concern, consumed by `step-transition` skill)
- Dynamic Delegation routing tables (C8 concern)
- Review agent selection logic (stays in `/work-review` command)
- `lib/config.sh` modifications (existing lib is stable, not changing)

## Implementation Steps

### Step 1: Create `hooks/lib/common.sh`

Build the shared hook utility library. This file is sourced by hooks, not executed directly.

**Boilerplate to extract** (currently repeated in 7 hooks):

| Boilerplate Pattern | Current Locations | Function Name |
|---------------------|-------------------|---------------|
| jq dependency check + exit 0 | All 7 hooks | `harness_require_jq` |
| Read JSON from stdin, extract `cwd` | 6 hooks (all PostToolUse/Stop) | `harness_read_hook_input` |
| Stop hook infinite-loop guard | 4 hooks (Stop event hooks) | `harness_stop_guard` |
| Harness dir resolution + config.sh sourcing + config validation | 6 hooks | `harness_init_config` |
| Active task scanning (`.work/*/state.json` where `archived_at` null) | 4 hooks | `harness_find_active_tasks` |
| Legacy format detection (string vs object steps) | 3 hooks | `harness_is_legacy_format` |
| Formatted error output to stderr | All 7 hooks | `harness_warn`, `harness_error` |

**Boilerplate that remains per-hook:**

- Tool matcher logic (specific to each hook's purpose)
- Business logic (validation rules, enforcement checks)
- Exit code decisions (pass/warn/block -- hook-specific)

**Sourcing pattern** (follows `lib/config.sh` convention):

```sh
# In hook files:
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"
```

**Function contracts:**

- `harness_require_jq` -- exits 0 if jq missing (hooks must not block on missing optional deps). No output on success.
- `harness_read_hook_input` -- reads stdin into `HOOK_INPUT` global, extracts `HOOK_CWD`. Must be called exactly once per hook invocation.
- `harness_stop_guard` -- checks `stop_hook_active` in `HOOK_INPUT`, exits 0 if true. Call after `harness_read_hook_input`.
- `harness_init_config` -- resolves `HARNESS_DIR`, sources `config.sh` if yq available, validates config if present. Sets `HARNESS_CONFIG_AVAILABLE` (true/false). Exits 0 if no harness.yaml (project not harness-enabled).
- `harness_find_active_tasks` -- prints one state.json path per line for active tasks in `$HOOK_CWD`. Returns 1 if no `.work/` directory or no active tasks.
- `harness_is_legacy_format <state_file>` -- returns 0 if steps array uses string format (legacy), 1 if object format (current).
- `harness_warn <message>` -- prints `harness: <hook-name>: <message>` to stderr. Hook name derived from `$0`.
- `harness_error <message>` -- same format as `harness_warn`.

**AC-01**: `shellcheck hooks/lib/common.sh` passes with no errors -- verified by `shellcheck`.

**AC-02**: Every function in `common.sh` has a comment documenting its contract (inputs, outputs, exit codes) -- verified by `structural-review`.

**AC-03**: `common.sh` uses POSIX sh only (no bashisms) -- verified by `shellcheck -s sh`.

### Step 2: Migrate hooks to use `hooks/lib/common.sh`

Update each existing hook to source `common.sh` and replace inline boilerplate with function calls.

**Migration pattern per hook:**

Before:
```sh
command -v jq >/dev/null 2>&1 || { echo "harness: jq required but not found" >&2; exit 2; }
INPUT=$(cat)
STOP_ACTIVE=$(printf '%s\n' "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then exit 0; fi
CWD=$(printf '%s\n' "$INPUT" | jq -r '.cwd')
HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if command -v yq >/dev/null 2>&1; then
  . "$HARNESS_DIR/lib/config.sh"
  if ! harness_has_config "$CWD"; then exit 0; fi
  if ! harness_validate_config "$CWD"; then
    echo "harness: .claude/harness.yaml is malformed" >&2; exit 2
  fi
fi
```

After:
```sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

harness_require_jq
harness_read_hook_input
harness_stop_guard          # only for Stop event hooks
harness_init_config
```

**Hooks to migrate:**

| Hook | Lines Removed | Functions Used |
|------|---------------|----------------|
| `state-guard.sh` | ~18 | `require_jq`, `read_hook_input`, `init_config` |
| `post-compact.sh` | ~5 | `require_jq`, `find_active_tasks` |
| `work-check.sh` | ~18 | `require_jq`, `read_hook_input`, `stop_guard`, `init_config`, `find_active_tasks` |
| `artifact-gate.sh` | ~18 | `require_jq`, `read_hook_input`, `stop_guard`, `init_config`, `find_active_tasks`, `is_legacy_format` |
| `review-verify.sh` | ~18 | `require_jq`, `read_hook_input`, `stop_guard`, `init_config`, `find_active_tasks`, `is_legacy_format` |
| `review-gate.sh` | ~18 | `require_jq`, `read_hook_input`, `stop_guard`, `init_config` |
| `beads-check.sh` | ~18 | `require_jq`, `read_hook_input`, `stop_guard`, `init_config` |
| `pr-gate.sh` | ~5 | `require_jq`, `read_hook_input` |

**AC-04**: Each migrated hook passes `shellcheck` -- verified by `shellcheck`.

**AC-05**: Each migrated hook produces identical behavior to the pre-migration version when run with the same stdin JSON input -- verified by `manual-test` (pipe mock JSON, compare output and exit code).

**AC-06**: `post-compact.sh` continues to work without `harness_read_hook_input` (PostCompact hooks receive no stdin JSON) -- verified by `manual-test`.

### Step 3: Create `task-discovery` skill

Extract the active-task-finding pattern used by all 7+ commands into a shared skill.

**Pattern currently repeated in commands:**

1. Scan `.work/` for `state.json` files where `archived_at` is null
2. Handle cases: no active task, one active task, multiple active tasks, active task of wrong tier
3. Read `current_step`, `tier`, `title`, `issue_id` from state.json
4. Map tier to command name (1=work-fix, 2=work-feature, 3=work-deep)
5. Detect if `$ARGUMENTS` references a beads issue

**Skill content sections:**

- **When This Activates**: Any work command startup, any status query
- **Discovery Algorithm**: The 6-step process from `state-conventions.md` (scan, read, filter, multiple-handling, one-active, none)
- **Tier-Command Mapping**: Table of tier number to command slug
- **State Reading**: Which fields to extract and how to present them
- **Beads Issue Detection**: How to detect issue IDs in arguments, when to run `bd show`
- **Error Cases**: `.work/` missing, state.json unparseable, multiple active tasks

**What stays in commands:** The tier-specific behavior after discovery (e.g., "Active Tier 2 task exists: resume it" vs "Active task of different tier exists: ask user"). Commands consume the discovery result and apply their own routing logic.

**AC-07**: Skill file has valid frontmatter with `name: task-discovery` and `description` -- verified by `structural-review`.

**AC-08**: Skill documents all 6 cases from the discovery algorithm (no task, one task, multiple tasks, wrong tier, arguments-as-issue, resume existing) -- verified by `structural-review`.

**AC-09**: Skill references `state-conventions.md` for schema details rather than duplicating the schema -- verified by `structural-review`.

### Step 4: Create `step-transition` skill

Extract the approval ceremony + gate creation + state update pattern into a single skill.

**Pattern currently repeated (10+ occurrences across work-deep, work-feature, work-fix, work-checkpoint):**

1. Present detailed summary to user (what step produced, artifacts, review results, advisory notes, deferred items, what next step involves)
2. End with: "Ready to advance to **<next-step>**? (yes/no)"
3. STOP and wait for explicit approval
4. Handle follow-up questions (answer, then re-present confirmation prompt)
5. Recognize approval signals: yes, proceed, approve, approved, looks good, lgtm, go ahead, continue
6. On approval: create gate issue via beads (`bd create --title="[Gate] <name>: <from> -> <to>"`)
7. Update state.json: mark current step `completed` with `gate_id` and `completed_at`, set next step to `active` with `started_at`, update `current_step`, update `updated_at`
8. If C4 Gate Protocol is implemented: write gate file to `.work/<name>/gates/<from>-to-<to>.md` and record `gate_file` in step status
9. Apply Context Compaction Protocol: tell user to run `/compact` then tier command

**Skill content sections:**

- **When This Activates**: Any step transition in any tier command
- **Summary Presentation Template**: What to include in the transition summary (checklist of sections)
- **Approval Ceremony**: The stop-wait-confirm protocol with approval signal list
- **Follow-Up Handling**: How to handle non-approval responses (answer + re-present)
- **Gate Creation**: Beads issue creation pattern, gate file creation (if C4 implemented), state.json update sequence
- **State Update Sequence**: Exact order of mutations (important: single write, not multiple partial updates)
- **Compaction Prompt**: Tier-to-command mapping for the "run /compact then /work-<cmd>" message
- **Tier Adaptations**: Table showing what differs per tier:
  - Tier 1: No gate issue, no handoff prompt, no compaction prompt (single-session)
  - Tier 2: Gate issue optional, handoff prompt optional, compaction recommended
  - Tier 3: Gate issue required, handoff prompt required, compaction required

**AC-10**: Skill documents the exact approval signals list (8 signals) -- verified by `structural-review`.

**AC-11**: Skill documents the state update sequence as a single atomic write (not partial updates) -- verified by `structural-review`.

**AC-12**: Skill includes the tier adaptation table showing Tier 1/2/3 differences -- verified by `structural-review`.

**AC-13**: Skill references the Gate Protocol reference doc (`references/gate-protocol.md`) for gate file format, without duplicating it -- verified by `structural-review`.

### Step 5: Create `phase-review` skill

Extract the two-phase review pattern into a shared skill.

**Pattern currently repeated (5+ occurrences in work-deep, simpler variant in work-fix):**

1. **Phase A -- Artifact Validation**: Spawn Explore agent (read-only) with a step-specific checklist to verify structural completeness
2. **Phase B -- Quality Review**: Spawn a step-appropriate agent (read-only) with `skills: [code-quality]` and a step-specific quality checklist
3. Apply verdict logic: PASS -> continue, ADVISORY -> log + continue, BLOCKING -> fix + re-review (max 2 attempts, then ask user)
4. Compose findings into the transition summary

**Skill content sections:**

- **When This Activates**: Any step transition that runs the Inter-Step Quality Review Protocol
- **Phase A Template**: What an artifact validation agent receives (agent type, read-only constraint, checklist format)
- **Phase B Template**: What a quality review agent receives (agent type selection per transition, skills to propagate, checklist format)
- **Transition-Agent Mapping**: Table from the Inter-Step Quality Review Protocol (research->plan uses Plan agent, etc.)
- **Verdict Protocol**: PASS/ADVISORY/BLOCKING definitions and handling rules
- **Retry Logic**: Max 2 attempts on BLOCKING before escalating to user
- **Checklist Reference**: Note that each step transition defines its own checklist items -- the skill provides the framework, not the checklists themselves. Checklists remain in the command definitions where they are step-specific.

**What stays in commands:** The specific checklist items for each transition (e.g., "Does the architecture cover all goals from the research handoff?"). These are step-specific and belong in the command definition. The skill provides the template and protocol; commands fill in the checklists.

**AC-14**: Skill documents both Phase A and Phase B with their distinct agent types and purposes -- verified by `structural-review`.

**AC-15**: Skill includes the transition-agent mapping table (6 rows from work-deep's Inter-Step Quality Review Protocol) -- verified by `structural-review`.

**AC-16**: Skill documents the verdict handling protocol including the 2-attempt retry limit for BLOCKING verdicts -- verified by `structural-review`.

**AC-17**: Skill explicitly states that checklists remain in command definitions (not extracted into the skill) -- verified by `structural-review`.

### Step 6: Update commands to reference skills

Update existing commands to reference the shared skills instead of inlining the logic. This is a refactor -- behavior must not change.

**Commands to update:**

| Command | Skills Referenced | What Changes |
|---------|-------------------|--------------|
| `work-deep.md` | All three | Task discovery simplified to "Follow the `task-discovery` skill". Review protocol references `phase-review` skill. Each transition references `step-transition` skill. Step-specific checklists remain inline. |
| `work-feature.md` | `task-discovery`, `step-transition` | Discovery and transition logic replaced with skill references. |
| `work-fix.md` | `task-discovery`, `step-transition` | Discovery and transition logic replaced with skill references. |
| `work-status.md` | `task-discovery` | Discovery logic replaced with skill reference. |
| `work-reground.md` | `task-discovery` | Discovery logic replaced with skill reference. |
| `work-checkpoint.md` | `task-discovery`, `step-transition` | Discovery and --step-end transition logic replaced. |
| `work-archive.md` | `task-discovery` | Discovery logic replaced with skill reference. |
| `work-redirect.md` | `task-discovery` | Discovery logic replaced with skill reference. |
| `work-review.md` | `task-discovery` | Discovery logic replaced with skill reference. |

**Refactoring pattern per command:**

Before (inline in each command):
```markdown
## Step 1: Detect Active Task

Scan `.work/` for `state.json` files where `archived_at` is null.

- **Active Tier N task exists**: Resume it...
- **Active task of different tier exists**: ...
- **No active task**: ...
```

After (skill reference):
```markdown
## Step 1: Detect Active Task

Follow the **task-discovery** skill (`claude/skills/work-harness/task-discovery.md`).
This command expects Tier <N>. Apply tier-specific handling:
- **Matching tier**: Resume at `current_step`.
- **Different tier**: Ask user to continue or archive and start new.
- **No active task**: Proceed to assessment.
```

The skill reference replaces the generic algorithm; the command retains only its tier-specific behavior.

**AC-18**: Each updated command contains at least one explicit skill reference path -- verified by `structural-review`.

**AC-19**: No command duplicates the full task discovery algorithm after refactoring (each delegates to the skill) -- verified by `structural-review`.

**AC-20**: `work-deep.md` references all three skills (`task-discovery`, `step-transition`, `phase-review`) -- verified by `structural-review`.

**AC-21**: Step-specific checklist items remain inline in `work-deep.md` (not moved to skills) -- verified by `structural-review`.

### Step 7: Update `work-harness.md` parent skill

Add the three new skills to the parent skill's references section.

**AC-22**: `claude/skills/work-harness.md` references section lists `task-discovery`, `step-transition`, and `phase-review` with descriptions and paths -- verified by `structural-review`.

## Interface Contracts

### Exposes

| Interface | Consumer | Description |
|-----------|----------|-------------|
| `task-discovery` skill | All 9 work commands | Active task finding algorithm, tier-command mapping |
| `step-transition` skill | work-deep, work-feature, work-fix, work-checkpoint | Approval ceremony, gate creation, state update, compaction prompt |
| `phase-review` skill | work-deep (primary), extensible to work-feature | Phase A + Phase B review template with verdict handling |
| `hooks/lib/common.sh` | All 8 hooks | Shared utilities for jq checks, stdin reading, config init, task scanning |

### Consumes

| Interface | Provider | Description |
|-----------|----------|-------------|
| `state-conventions.md` | Existing reference | State.json schema (referenced, not duplicated) |
| `gate-protocol.md` | C4 (if implemented) | Gate file format and SOP |
| `lib/config.sh` | Existing lib | Config reading functions (sourced by `common.sh` via `harness_init_config`) |
| `code-quality` skill | Existing skill | Propagated to Phase B review agents |

## Files

| File | Action | Description |
|------|--------|-------------|
| `hooks/lib/common.sh` | Create | Shared hook utilities: jq check, stdin reading, config init, task scanning, error formatting |
| `claude/skills/work-harness/task-discovery.md` | Create | Skill: active task finding, state reading, tier mapping |
| `claude/skills/work-harness/step-transition.md` | Create | Skill: approval ceremony, gate creation, state update, compaction |
| `claude/skills/work-harness/phase-review.md` | Create | Skill: Phase A + Phase B review template, verdict protocol |
| `claude/skills/work-harness.md` | Modify | Add references to three new skills |
| `claude/commands/work-deep.md` | Modify | Replace inline logic with skill references |
| `claude/commands/work-feature.md` | Modify | Replace inline logic with skill references |
| `claude/commands/work-fix.md` | Modify | Replace inline logic with skill references |
| `claude/commands/work-status.md` | Modify | Replace inline logic with skill references |
| `claude/commands/work-reground.md` | Modify | Replace inline logic with skill references |
| `claude/commands/work-checkpoint.md` | Modify | Replace inline logic with skill references |
| `claude/commands/work-archive.md` | Modify | Replace inline logic with skill references |
| `claude/commands/work-redirect.md` | Modify | Replace inline logic with skill references |
| `claude/commands/work-review.md` | Modify | Replace inline logic with skill references |
| `hooks/state-guard.sh` | Modify | Source common.sh, replace boilerplate |
| `hooks/post-compact.sh` | Modify | Source common.sh, replace boilerplate |
| `hooks/work-check.sh` | Modify | Source common.sh, replace boilerplate |
| `hooks/artifact-gate.sh` | Modify | Source common.sh, replace boilerplate |
| `hooks/review-verify.sh` | Modify | Source common.sh, replace boilerplate |
| `hooks/review-gate.sh` | Modify | Source common.sh, replace boilerplate |
| `hooks/beads-check.sh` | Modify | Source common.sh, replace boilerplate |
| `hooks/pr-gate.sh` | Modify | Source common.sh, replace boilerplate |

## Testing Strategy

### Shell (hooks/lib/common.sh)

1. **Lint**: `shellcheck -s sh hooks/lib/common.sh` -- zero errors
2. **Lint migrated hooks**: `shellcheck hooks/*.sh` -- zero new errors introduced
3. **Unit test each function**: Pipe mock JSON to a test script that sources `common.sh` and calls each function:
   - `harness_require_jq`: verify exit 0 when jq present, exit 0 when jq missing (graceful skip)
   - `harness_read_hook_input`: verify `HOOK_INPUT` and `HOOK_CWD` are populated from mock JSON
   - `harness_stop_guard`: verify exit 0 when `stop_hook_active: true`, continue when false
   - `harness_find_active_tasks`: verify correct filtering with mock `.work/` directories
   - `harness_is_legacy_format`: verify detection of string vs object steps arrays
4. **Regression test**: Run each migrated hook with known-good mock input and compare output/exit code to pre-migration behavior

### Markdown (skills)

1. **Structural review**: Each skill has valid YAML frontmatter, required sections (`When This Activates`, `References`), no placeholder text
2. **Cross-reference check**: All path references in skills resolve to existing files (or files created by this spec)
3. **Content review**: Each skill's algorithm matches the corresponding inline logic it replaces (diff the extracted content against the original commands)

### Integration

1. **Command coherence**: After refactoring, run `/work-deep` on the active `harness-improvements` task and verify it correctly discovers the task, routes to the current step, and presents the expected interface
2. **Hook coherence**: Trigger each hook (write a state.json to fire state-guard, stop to fire Stop hooks) and verify identical behavior to pre-migration

## Deferred Questions Resolution

### Deferred Question 2: C7 skill extraction granularity

**Question**: Should `step-transition` be one skill or split into `approval-ceremony` + `state-update`?

**Resolution**: Keep as ONE skill. The approval ceremony, gate file creation, and state update are always used together in sequence. Every call site follows the same pattern: present summary -> wait for approval -> create gate -> update state -> prompt compaction. Splitting would:
- Create an artificial seam between steps that are always co-invoked
- Require coordination logic to ensure both halves run (defeating the purpose of extraction)
- Add cognitive overhead for command authors who must remember to invoke both

The tier adaptation table within the skill handles the variation (Tier 1 skips gate issues, Tier 3 requires them) without needing separate skills.

### Deferred Question 6 (from A5): Hook utilities scope

**Question**: Should hook utilities be a separate deliverable or integrate into `common.sh`?

**Resolution**: Integrate into `hooks/lib/common.sh`. This follows the existing `lib/config.sh` pattern where shared shell functions live in a `lib/` directory and are sourced by consumers. There is no need for a separate deliverable -- all hook utility functions belong in one file because they share the same lifecycle (sourced at hook startup, used during hook execution) and the same dependency requirements (jq, optional yq).

## Advisory Notes Resolution

### Advisory B1: `hooks/lib/common.sh` MUST follow the existing `lib/config.sh` sourcing pattern

**Resolution**: Addressed in Step 1. The sourcing pattern uses `SCRIPT_DIR` resolution and a shellcheck source directive, matching `lib/config.sh` exactly. The function naming convention (`harness_*`) follows `config.sh`'s established prefix pattern. Variable scoping uses the `lib/config.sh` technique of function-local prefixes (e.g., `hcg_` in `harness_config_get` becomes `hft_` in `harness_find_active_tasks`).

Step 1 enumerates exactly which boilerplate moves into common.sh (7 patterns in the table) and which remains per-hook (tool matchers, business logic, exit code decisions). This satisfies the advisory's requirement to "enumerate which boilerplate portions move into the shared library vs remain per-hook."
