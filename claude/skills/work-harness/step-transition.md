---
name: step-transition
description: "Step transition protocol -- approval ceremony, gate file creation, state update, and context compaction. Used by tier commands and work-checkpoint at every step boundary."
---

# Step Transition

Shared protocol for transitioning between steps. Covers the approval ceremony, gate file/issue creation, state.json update, and context compaction prompt. Every step boundary in every tier follows this protocol, with tier-specific adaptations.

## When This Activates

- Any step transition in any tier command (`/work-fix`, `/work-feature`, `/work-deep`)
- `/work-checkpoint --step-end` advancing to the next step
- Any point where state.json `current_step` changes from one step to another

## Summary Presentation Template

Before requesting approval, present a detailed summary covering these sections (include all that apply):

1. **What the step produced** -- artifacts created, key decisions made, component/item counts
2. **Review results** -- Phase A and Phase B verdicts (if the inter-step quality review protocol ran)
3. **Advisory notes** -- full text of all advisory notes (do not abbreviate or hide them)
4. **Deferred items** -- open questions, futures discovered, items explicitly deferred to later steps
5. **What the next step involves** -- 2-3 sentences orienting the user on what comes next

End with: **"Ready to advance to `<next-step>`? (yes/no)"**

## Approval Ceremony

**This is a hard stop.** Do NOT update state.json, create gate issues, or write gate files in the same turn as presenting the summary.

### Stop and Wait

After presenting the summary, STOP. Wait for the user to respond.

### Follow-Up Handling

If the user responds with anything that is NOT an approval signal:
1. Answer the question or address the feedback
2. Re-present the confirmation prompt: "Ready to advance to **`<next-step>`**? (yes/no)"

Repeat until the user gives an explicit approval signal or decides not to advance.

### Approval Signals

Recognize these 8 signals as explicit approval:

1. `yes`
2. `proceed`
3. `approve`
4. `approved`
5. `looks good`
6. `lgtm`
7. `go ahead`
8. `continue`

Any other response is NOT approval -- treat it as a question or feedback.

## Gate Creation

On explicit approval, perform gate creation according to the tier:

### Gate Issue (Beads)

Create a beads gate issue to record the transition:

```bash
bd create --title="[Gate] <name>: <from> -> <to>" --type=task --priority=2
```

If there are ADVISORY notes, include them in the issue description.

### Gate File (Tier 3 only)

Write a gate file following the gate protocol SOP. See `claude/skills/work-harness/references/gate-protocol.md` for the full file structure, naming conventions, iteration protocol, and immutability rules.

- **Step transition gate file**: `.work/<name>/gates/<from>-to-<to>.md`
- **Implementation phase gate file**: `.work/<name>/gates/implement-phase-<N>.md`

The gate file is written BEFORE presenting results to the user. It becomes the primary review artifact -- the user reviews it in their editor.

Present the gate file path: "Review file written to `.work/<name>/gates/<from>-to-<to>.md`. Open it in your editor to review, then respond here."

## State Update Sequence

Perform the state.json update as a **single atomic write** (read the full object, mutate all fields, write once). Do NOT perform multiple partial updates.

Update these fields in one write:

1. Current step's status object: set `status` to `"completed"`, set `completed_at` to current ISO 8601 timestamp
2. Current step's `gate_id`: set to the beads gate issue ID (if gate issue was created)
3. Current step's `gate_file`: set to relative path from `.work/<name>/` (e.g., `"gates/research-to-plan.md"`) -- Tier 3 only
4. Current step's `handoff_prompt`: set to relative path if a handoff prompt was written -- Tier 3 only
5. Next step's status object: set `status` to `"active"`, set `started_at` to current ISO 8601 timestamp
6. Top-level `current_step`: set to the next step's name
7. Top-level `updated_at`: set to current ISO 8601 timestamp

If this was the **last step** and Tier 1: also set `archived_at` to current timestamp (auto-archive).

## Compaction Prompt

After state is updated, prompt for context compaction based on the tier:

| Tier | Command | Compaction Message |
|------|---------|-------------------|
| 1 | `/work-fix` | No compaction prompt (single-session, auto-archives on review completion) |
| 2 | `/work-feature` | "Recommend: `/compact` then `/work-feature` to start **`<next-step>`** with clean context." |
| 3 | `/work-deep` | "Run `/compact` then `/work-deep` to start **`<next-step>`** with clean context." Then **stop**. |

If the user continues without compacting (Tier 2-3): re-invoke via `Skill('work-<cmd>')` to refresh instructions, then re-read relevant rule files and the handoff prompt.

## Tier Adaptations

| Aspect | Tier 1 (Fix) | Tier 2 (Feature) | Tier 3 (Initiative) |
|--------|-------------|------------------|---------------------|
| Gate issue (beads) | Not created | Optional | Required |
| Gate file | Not created | Not created | Required |
| Handoff prompt | Not created | Optional | Required |
| Compaction prompt | Not shown | Recommended | Required (then stop) |
| `gate_file` in state | Not set | Not set | Set to relative path |

## References

- **gate-protocol** -- Gate file SOP: directory layout, naming, file structure, iteration, immutability, rollback (path: `claude/skills/work-harness/references/gate-protocol.md`)
- **state-conventions** -- State.json schema, step lifecycle, step status object (path: `claude/skills/work-harness/references/state-conventions.md`)
