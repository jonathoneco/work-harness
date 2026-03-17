# Context-Lifecycle Session Analysis

**Session:** fe7cd6a4-bea3-4d3a-bf1f-ce99c5959528
**Worktree:** gaucho main
**Duration:** ~7 hours (2026-03-16 00:35-07:18 UTC)
**Task:** Context document lifecycle management (Tier 3)
**Compactions:** 5 (one per step transition)

## Stats

- 93 user messages, ~7 hours, full T3 lifecycle (assess through archive)
- 5 compactions at step boundaries
- 3 parallel research agents, 3 implementation stream agents, 3 review agents
- Epic rag-hc9ou with 5 work items + 5 gate issues

## What Was Built

5 components for context document lifecycle management:
1. **Tech manifest** (`.claude/tech-deps.yml`) — YAML mapping context docs to technology deps
2. **Self-re-invocation** — `Skill('<command>')` at step gates to refresh instructions
3. **PostCompact hook** — POSIX sh script suggesting re-grounding after compaction
4. **Archive housekeeping** — deprecated table diff, staleness scan, issue creation
5. **Gate approval re-confirmation** — explicit approval signals, no state changes in presentation turn

## Key Insight: Discussion-as-Approval Failure

**The single biggest harness failure in this session.** User answered 6 follow-up questions about open research items. The agent interpreted answering questions as implicit approval and immediately advanced state from research to plan.

User's correction:
> "You should have checked with me again before proceeding since I never explicitly approved, I just responded and asked for follow up"

This became component C5 and a memory entry. Fix: explicit approval signal definitions ("yes", "proceed", "approve", "lgtm", "go ahead", "continue") and instruction "Do NOT update state.json or create gate issues in the same turn as presenting results."

**Two failure modes identified:**
1. Discussion-as-approval — answering questions interpreted as "proceed"
2. Presentation-as-approval — presenting results and advancing in the same turn

## Patterns (what worked)

1. **`/workflow-meta` as pre-scoping exploration** — User explored problem space conversationally before committing to `/work`. Natural two-phase: brainstorm → scope.

2. **User override of tier assessment** — Score was 4 (borderline T2/T3). User chose T3: "a research phase would also be useful." Harness correctly accepts overrides.

3. **Compaction discipline at every step boundary** — User consistently followed `/compact` then `/work-deep`. Each step started clean with handoff prompt as the only bridge.

4. **Phase B reviews catching real issues** — Caught blocking issue: project-level command copies shadow dotfiles, so changes only applied to dotfiles never take effect.

5. **Closed beads issues as context** — Research started by searching closed issues before code exploration. Found 5 relevant issues, saved significant exploration time.

6. **User override on fail-closed** — Phase B recommended "report-and-proceed" for archive scan errors. User overrode: "I actually think fail-closed for both."

## Anti-Patterns (what went wrong)

### Subagent Permission Failures

All 3 Phase 1 implementation agents hit permission failures — couldn't write files or run bash outside project sandbox (dotfiles was out of scope). Main thread had to complete cross-repo work.

**Lesson:** If implementation spans multiple repos, plan for main-thread handling of cross-repo edits.

### Skill Re-invocation Needed Even Within a Session

User observed: saying "proceed" produces degraded behavior vs "proceed /work-deep". This is the "Lost in the Middle" effect — mid-context instructions get less attention than end-of-context.

**Fix built in this session:** `Skill('<command>')` re-invocation to refresh instructions at end of context window.

### Cross-Repo Divergence

Harness commands exist in both dotfiles (portable) and project repos (team-shared). Changes applied to one but not the other create divergence. Multiple instances discovered and fixed.

**Lesson:** Any harness change must be applied to all locations where the file is consumed.

### Archive Step Edge Cases

Post-archive, user found `docs/feature/context-lifecycle.md` wasn't updated and task still appeared active. Archive step had state management gaps.

## User Decision-Making Style

Same terse pattern as other sessions:
- "let's proceed with tier 3"
- "yes"
- "Continue"
- "Proceed /work-deep"
- "I lean yes but open to being challenged"
- "I like B"

Multi-part decisions addressed inline with numbered responses matching the AI's numbered questions.

## Cross-Repo Portability Concern

> "my hesitation is I want this workflow harness to live outside my dotfiles as well so they transport between my other projects, but I need them to also live in the repo so my teammates can benefit. At the same time, my dotfiles harness shouldn't impose project specific constraints"

Led to choosing project-level tech manifest over modifying portable dotfiles skills.

## Worktree Management

User handled worktree rebasing within the session. frontend-infra was accidentally based off react-migration branch. Several messages needed to explain the situation. The harness has no tooling for this — it was ad-hoc.
