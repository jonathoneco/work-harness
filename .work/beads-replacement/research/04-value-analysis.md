# Beads Value Analysis

## Questions
- Which beads features are actually used vs. dead weight?
- How critical is beads for context recovery vs. workflow gating?
- Could dependencies and task gating be replaced by simpler `.work/` state?
- What would actually break without beads?

## Findings

### Usage Frequency (across all commands, skills, rules)
- `bd create` — 37 occurrences (dominant)
- `bd update --status=in_progress` — 11 occurrences
- `bd close` — 9 occurrences
- `bd list` — 8 occurrences
- `bd show` — 4 occurrences
- `bd search` — 4 occurrences
- `bd ready` — 3 occurrences (templates only, never in actual command logic)
- `bd dep add` — 2 occurrences (example syntax only)

### Context Recovery: Aspirational, Not Systematized
- `bd search`/`bd show` documented as best practice but only 4-5 actual invocations
- Agents don't systematically search closed issues for context
- Real context bridge is `.work/<name>/*/handoff-prompt.md`, not beads issues

### Dependencies: Designed But Never Used
- `bd dep add` appears only in example syntax
- `bd ready` documented as "find next unblocked task" but never called by work commands
- Decompose step provides ordering; no active gating via `bd ready`

### Coordination: Courtesy Gate, Not Hard Gate
- `bd update --status=in_progress` for claiming is soft — no lock mechanism
- Two sessions can claim the same issue
- Real multi-session coordination is git worktrees + branch awareness

### What Actually Breaks Without Beads
**Hard dependencies:**
1. beads-check.sh hook — blocks session end without claimed issue
2. Gate issue audit trail — documents step transitions
3. Finding triage — `beads_issue_id` for deferred findings

**Soft/aspirational (replaceable):**
4. Context recovery via search (→ handoff prompts)
5. Dependency gating (→ ordered task array)
6. Epic/subtask tracking (→ decompose specs + numbering)

### The Core Insight
Beads is being used as an **audit log**, not a **task tracker**:
- Most issues are terminal state (closed immediately after gates approved)
- Few issues are active "work in progress"
- No evidence of agents using issues to discover what to work on next

### Feature Essentiality Matrix
| Feature | Used? | Essential? | Replacement |
|---------|-------|-----------|-------------|
| Issue CRUD per task | YES | YES | state.json + audit_trail array |
| Gate issues | YES | SOFT | Gate files + git commits |
| Claiming (in_progress) | YES | SOFT | Branch naming or active task dir |
| Finding triage linking | YES | MEDIUM | deferred-findings.json |
| Epic + subtask tracking | YES | MEDIUM | state.json subtasks array |
| Search closed issues | DOCUMENTED | WEAK | Handoff prompts |
| Dependencies (bd dep) | DESIGNED | WEAK | Ordered task list |
| Ready queries (bd ready) | DESIGNED | WEAK | Task sequencing in state.json |

## Implications
- State duplication is the fundamental problem: task data lives in BOTH state.json AND beads
- The harness could operate without beads if state.json is extended with audit trails and subtask arrays
- Beads provides ~$50 of unique value for ~$500 of complexity/context cost
- The "designed but unused" features (deps, ready) are pure overhead

## Open Questions
- Do you ever actually run `bd list --status=closed` to review history?
- Is the beads audit trail accessed, or is git commit history the real audit trail?
- How often do you use `bd search` for real context recovery?
- Is epic tracking critical for T3, or could numbered decompose specs suffice?
