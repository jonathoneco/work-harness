# Stream B: Work Command Updates (C2 + C5)

**Phase**: 1 (parallel) | **Work Items**: W-02 (rag-dk3o5), W-03 (rag-mtm7w) | **Specs**: 02, 05

## Context

Two specs modify the same three files (`work-deep.md`, `work-feature.md`, `work-fix.md`). Combined into one stream to avoid merge conflicts. C2 adds Skill() re-invocation at step gates. C5 fixes the approval protocol to require explicit confirmation and prevent same-turn state updates.

**Important**: These files live in the dotfiles repo at `~/src/dotfiles/home/.claude/commands/`.

## Work Item: W-02 — Add self-re-invocation (spec 02)

**Beads ID**: rag-dk3o5

### Steps

1. **Update Context Compaction Protocol** in each work command. Find the section that says "If the user continues without compacting". Replace with:
   ```
   **If the user continues without compacting** (e.g., responds with "just continue"): Re-invoke this command via `Skill('<command-name>')` to refresh instructions at the end of the context window. Then re-read the handoff prompt and all rule files listed in the transition substep.
   ```
   Use the correct command name per file: `work-deep`, `work-feature`, `work-fix`.

2. **Update each step transition's compaction block** (step h in auto-advance):
   Add: "If user continues without compacting, re-invoke via `Skill('<command>')` before proceeding."
   - work-deep.md: 5 transitions (research→plan, plan→spec, spec→decompose, decompose→implement, implement→review)
   - work-feature.md: 2 transitions (plan→implement, implement→review)
   - work-fix.md: 1 transition (implement→review)

### Acceptance Criteria
- All 3 work commands include Skill() re-invocation in the Context Compaction Protocol
- Each uses the correct command name
- All 8 transition blocks include the re-invocation fallback
- Language is plain (no "CRITICAL" or "MUST")

---

## Work Item: W-03 — Fix gate approval protocol (spec 05)

**Beads ID**: rag-mtm7w

### Steps

1. **Update the Inter-Step Quality Review Protocol** in work-deep.md (the shared preamble). Replace the "Transition behavior" section:
   - Point 1: Add "End with: 'Ready to advance to **<next-step>**? (yes/no)'"
   - Point 2: Change to "STOP. Do NOT update state.json or create gate issues in the same turn as presenting results."
   - Add Point 3: "If the user asks questions or gives feedback: Answer, then re-ask..."
   - Point 4: "On explicit approval..."
   - Update "Critical ordering" note

2. **Replace approval blocks in work-deep.md** — 5 transitions. Change steps e-g:
   - Step e: End summary with "Ready to advance to **<next-step>**? (yes/no)"
   - Step f: "STOP. Do NOT update state.json in this turn."
   - Add f': "If user asks questions: answer, then re-present confirmation"
   - Step g: "On explicit approval..."

3. **Adapt for work-feature.md and work-fix.md** — these use simpler inline advance patterns (no e-f-g-h blocks). Add the "Ready to advance?" prompt and "Do NOT update state.json in this turn" instruction without imposing the full block structure.

4. **Update implement phase gates** in work-deep.md — Phase N results and Phase N+1 work must never be in same agent turn.

### Acceptance Criteria
- All 8 transitions use the "Ready to advance?" prompt
- Every transition includes re-confirmation after Q&A (step f')
- "Do NOT update state.json in this turn" is explicit
- Gate issues and state updates happen only after explicit approval
- work-fix/work-feature adapted to their simpler format
- Inter-Step QR Protocol updated
- Implement phase gates updated

---

## Files to Modify
- `~/src/dotfiles/home/.claude/commands/work-deep.md`
- `~/src/dotfiles/home/.claude/commands/work-feature.md`
- `~/src/dotfiles/home/.claude/commands/work-fix.md`

## Spec References
- `.work/context-lifecycle/specs/02-self-re-invocation.md`
- `.work/context-lifecycle/specs/05-gate-approval.md`
- `.work/context-lifecycle/specs/00-cross-cutting-contracts.md` (approval signal definitions)

## Dependencies
- None (Phase 1, parallel with Streams A and C)

## Implementation Order Within Stream
Do W-03 (approval fix) first, then W-02 (re-invocation). Rationale: The approval fix changes steps e-g; the re-invocation changes step h and the Context Compaction Protocol. Working from the end of each block backward avoids re-reading to find insertion points.

### Claim and Close
```bash
bd update rag-mtm7w --status=in_progress  # W-03 first
# ... implement approval fix ...
bd close rag-mtm7w
bd update rag-dk3o5 --status=in_progress  # W-02 second
# ... implement re-invocation ...
bd close rag-dk3o5
```
