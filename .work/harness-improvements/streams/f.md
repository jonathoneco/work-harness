---
stream: F
phase: 2
isolation: none
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: L
file_ownership:
  - claude/skills/work-harness/task-discovery.md
  - claude/skills/work-harness/step-transition.md
  - claude/skills/work-harness/phase-review.md
  - claude/skills/work-harness.md
  - claude/commands/work-deep.md
  - claude/commands/work-feature.md
  - claude/commands/work-fix.md
  - claude/commands/work-status.md
  - claude/commands/work-reground.md
  - claude/commands/work-checkpoint.md
  - claude/commands/work-archive.md
  - claude/commands/work-redirect.md
  - claude/commands/work-review.md
---

# Stream F: Extracted Skills + Command Refs (C7, Steps 3-7)

**Phase:** 2 (depends on W-01, W-02, W-03)
**Work Items:** W-08 (work-harness-a4i)
**Spec:** 07, Steps 3-7

---

## Overview

Extract ~350 lines of repeated logic from 7+ commands into three shared skills (`task-discovery`, `step-transition`, `phase-review`), then refactor all commands to reference the skills instead of inlining the logic. This is the markdown-side half of C7 (Skill Library). The shell-side (hook utilities) is handled by Stream E.

The three skills make command logic referenceable as discrete, routable units — a prerequisite for Dynamic Delegation (C8) and Parallel Execution v2 (C9).

---

## W-08: Extracted Skills + Command Refs — spec 07, Steps 3-7

**Issue:** work-harness-a4i
**Spec:** `.work/harness-improvements/specs/07-skill-library.md` (Steps 3-7)

### Files

| File | Action | Description |
|------|--------|-------------|
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

### Implementation Notes

#### Step 3: Create `task-discovery` skill

Extract the active-task-finding pattern used by all 7+ commands into a shared skill at `claude/skills/work-harness/task-discovery.md`.

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

#### Step 4: Create `step-transition` skill

Extract the approval ceremony + gate creation + state update pattern into a single skill at `claude/skills/work-harness/step-transition.md`.

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
- **State Update Sequence**: Exact order of mutations (single write, not multiple partial updates)
- **Compaction Prompt**: Tier-to-command mapping for the "run /compact then /work-<cmd>" message
- **Tier Adaptations**: Table showing what differs per tier:
  - Tier 1: No gate issue, no handoff prompt, no compaction prompt (single-session)
  - Tier 2: Gate issue optional, handoff prompt optional, compaction recommended
  - Tier 3: Gate issue required, handoff prompt required, compaction required

#### Step 5: Create `phase-review` skill

Extract the two-phase review pattern into a shared skill at `claude/skills/work-harness/phase-review.md`.

**Pattern currently repeated (5+ occurrences in work-deep, simpler variant in work-fix):**

1. **Phase A — Artifact Validation**: Spawn Explore agent (read-only) with a step-specific checklist to verify structural completeness
2. **Phase B — Quality Review**: Spawn a step-appropriate agent (read-only) with `skills: [code-quality]` and a step-specific quality checklist
3. Apply verdict logic: PASS -> continue, ADVISORY -> log + continue, BLOCKING -> fix + re-review (max 2 attempts, then ask user)
4. Compose findings into the transition summary

**Skill content sections:**

- **When This Activates**: Any step transition that runs the Inter-Step Quality Review Protocol
- **Phase A Template**: What an artifact validation agent receives (agent type, read-only constraint, checklist format)
- **Phase B Template**: What a quality review agent receives (agent type selection per transition, skills to propagate, checklist format)
- **Transition-Agent Mapping**: Table from the Inter-Step Quality Review Protocol (research->plan uses Plan agent, etc.)
- **Verdict Protocol**: PASS/ADVISORY/BLOCKING definitions and handling rules
- **Retry Logic**: Max 2 attempts on BLOCKING before escalating to user
- **Checklist Reference**: Note that each step transition defines its own checklist items — the skill provides the framework, not the checklists themselves. Checklists remain in the command definitions where they are step-specific.

**What stays in commands:** The specific checklist items for each transition (e.g., "Does the architecture cover all goals from the research handoff?"). These are step-specific and belong in the command definition. The skill provides the template and protocol; commands fill in the checklists.

#### Step 6: Update commands to reference skills

Update existing commands to reference the shared skills instead of inlining the logic. This is a refactor — behavior must not change.

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

#### Step 7: Update `work-harness.md` parent skill

Add the three new skills to the parent skill's references section with descriptions and paths.

### Acceptance Criteria

- **AC-07**: Skill file has valid frontmatter with `name: task-discovery` and `description` -- verified by `structural-review`
- **AC-08**: Skill documents all 6 cases from the discovery algorithm (no task, one task, multiple tasks, wrong tier, arguments-as-issue, resume existing) -- verified by `structural-review`
- **AC-09**: Skill references `state-conventions.md` for schema details rather than duplicating the schema -- verified by `structural-review`
- **AC-10**: Skill documents the exact approval signals list (8 signals) -- verified by `structural-review`
- **AC-11**: Skill documents the state update sequence as a single atomic write (not partial updates) -- verified by `structural-review`
- **AC-12**: Skill includes the tier adaptation table showing Tier 1/2/3 differences -- verified by `structural-review`
- **AC-13**: Skill references the Gate Protocol reference doc (`references/gate-protocol.md`) for gate file format, without duplicating it -- verified by `structural-review`
- **AC-14**: Skill documents both Phase A and Phase B with their distinct agent types and purposes -- verified by `structural-review`
- **AC-15**: Skill includes the transition-agent mapping table (6 rows from work-deep's Inter-Step Quality Review Protocol) -- verified by `structural-review`
- **AC-16**: Skill documents the verdict handling protocol including the 2-attempt retry limit for BLOCKING verdicts -- verified by `structural-review`
- **AC-17**: Skill explicitly states that checklists remain in command definitions (not extracted into the skill) -- verified by `structural-review`
- **AC-18**: Each updated command contains at least one explicit skill reference path -- verified by `structural-review`
- **AC-19**: No command duplicates the full task discovery algorithm after refactoring (each delegates to the skill) -- verified by `structural-review`
- **AC-20**: `work-deep.md` references all three skills (`task-discovery`, `step-transition`, `phase-review`) -- verified by `structural-review`
- **AC-21**: Step-specific checklist items remain inline in `work-deep.md` (not moved to skills) -- verified by `structural-review`
- **AC-22**: `claude/skills/work-harness.md` references section lists `task-discovery`, `step-transition`, and `phase-review` with descriptions and paths -- verified by `structural-review`

### Integration ACs from Spec 04 (Gate Protocol)

Stream C (Phase 1) creates the gate-protocol.md reference and updates state-conventions.md, but cannot modify `work-deep.md` or `work-harness.md` (owned by this stream in Phase 2). The following ACs from spec 04 are this stream's responsibility:

- **spec04-AC-04**: `work-deep.md` Step 3 directory creation list includes `.work/<name>/gates/` -- verified by `structural-review`
- **spec04-AC-05**: Each of the six auto-advance blocks in `work-deep.md` writes a gate file before presenting results to the user -- verified by `structural-review`
- **spec04-AC-06**: Gate file paths use the naming conventions from the SOP reference (step transitions: `<from>-to-<to>.md`, phases: `implement-phase-<N>.md`) -- verified by `structural-review`
- **spec04-AC-07**: Each auto-advance block records `gate_file` in the step's state.json status object on approval -- verified by `structural-review`
- **spec04-AC-09**: `work-harness.md` References section lists `gate-protocol` with correct path -- verified by `structural-review`
- **spec04-AC-10**: `work-harness.md` has a Gate Files subsection explaining the pattern -- verified by `structural-review`
- **spec04-AC-11**: Existing `plan-to-spec.md` has all seven required sections from the SOP structure, or differences are documented as acceptable variations -- verified by `structural-review`

**How to implement**: The step-transition skill (AC-13) already references gate-protocol.md. During Step 6 (command updates), integrate gate file writing into `work-deep.md` auto-advance blocks per the gate-protocol SOP. During Step 7, add the gate-protocol reference to `work-harness.md`.

### Dependency Constraints

- **Upstream:** W-01 (work-harness-uzd), W-02 (work-harness-e2h), W-03 (work-harness-fp6) must complete first. Phase 1 command changes from Streams A-C must be done before Step 6 modifies those commands to add skill references.
- **Downstream:** Enables Dynamic Delegation (C8) and Parallel Execution v2 (C9), which depend on skills being referenceable as discrete, routable units.

### Claim and Close

```bash
bd update work-harness-a4i --status=in_progress
# ... implement ...
bd close work-harness-a4i --reason="3 skills extracted, 9 commands refactored to reference skills, parent skill updated"
```
