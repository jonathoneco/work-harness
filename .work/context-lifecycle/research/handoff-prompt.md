# Handoff: Research → Plan

## What This Step Produced

3 research notes covering: (1) current harness internals analysis, (2) prior art from closed beads issues, (3) AI best practices from web research including academic papers, Anthropic guidance, and tool comparisons.

### Key Artifacts
- `.work/context-lifecycle/research/01-current-harness-state.md` — gap analysis of current harness
- `.work/context-lifecycle/research/02-prior-art-beads.md` — 5 closed issues + 3 open issues documenting foundations and live staleness examples
- `.work/context-lifecycle/research/03-ai-best-practices.md` — web research with 20+ sources on instruction persistence, context management, document lifecycle

## Key Findings

### Finding 1: Self-re-invocation is highest-impact mechanism
The "Lost in the Middle" effect (Liu et al., 2024) shows 30%+ accuracy drop when instructions are in middle of context. `Skill()` places instructions at the END — highest attention zone. Currently, when user says "proceed" instead of "/work-deep", the agent continues with stale mid-context instructions. The existing fallback ("re-read rule files") is itself a prompt instruction subject to the same drift problem.

### Finding 2: PostCompact hooks are a NEW mechanism worth considering
Claude Code supports PreCompact and PostCompact hooks. A PostCompact hook could mechanically inject a reminder to re-invoke the current work command. This would be **hook-driven** (deterministic, cannot be ignored) rather than **prompt-driven** (best-effort, subject to drift). This is a 5th mechanism not in the original proposal.

### Finding 3: Freshness classes map to document tiers
Glen Rhodes' freshness class pattern maps directly to our document layers:
- **Fast-decay**: API docs, release notes → not applicable (we don't have these)
- **Medium-decay**: Skills + their references → validate per Tier-2+ archive
- **Slow-decay**: Rules, CLAUDE.md → validate quarterly or on deprecation
- **Frozen**: Task specs (.work/) → historical record, never decay

### Finding 4: Archive-time housekeeping fills a complete void
Current archive process includes futures promotion, summary generation, findings summary, beads closure. It does NOT include any scan of skills/rules for staleness or new pattern propagation. The harness is the natural "owner" of freshness (Rhodes: "without explicit owner with SLA accountability, it will be nobody's job").

### Finding 5: Multi-session > monolithic (validates compaction protocol)
Research confirms: 3 sessions at 40K tokens (94% relevance) outperforms 1 session at 180K tokens (72% relevance). This validates step-boundary compaction AND spawning fresh subagents per work item.

### Finding 6: Existing foundations are solid
- state.json as external ground truth → aligned with Anthropic's recommended pattern
- Handoff prompts as session boundary → aligned with multi-context-window workflow
- Skill activation by file pattern → aligned with Cursor's progressive disclosure
- Structured frontmatter → preserves 92% through compaction (vs 71% narrative)

### Finding 7: Gate approval requires explicit re-confirmation after discussion
During this research phase, the agent answered follow-up questions about open items then immediately advanced state without re-confirming. Answering questions ≠ approval. The work-deep.md protocol says "STOP and wait for user acknowledgment" but doesn't handle the case where discussion happens at the gate before approval. Fix: after any discussion at a gate, re-present a brief confirmation prompt before advancing. (Issue: rag-idnu7)

## Decisions Made During Research

1. **PostCompact hook should be considered as mechanism #5** — it's the most mechanically reliable approach for re-grounding after compaction
2. **"Re-read rule files" fallback is architecturally flawed** — a prompt instruction to fix prompt drift is circular; needs mechanical enforcement
3. **Freshness ownership belongs to the harness** — archive-time is the natural trigger point, not a periodic reminder

## Open Questions Resolved

| # | Question | Resolution |
|---|----------|------------|
| 1 | Skill() vs PostCompact | Both |
| 2 | Archive scope | All skills (small set, cheap, deterministic) |
| 3 | Extra frontmatter fields | Yes, lean toward it (challenge during spec if over-engineered) |
| 4 | Deprecated diffing trigger | Archive-time primary, session-start warning optional |
| 5 | Open cleanup issues first? | Yes, before implementing new mechanisms |
| 6 | PostCompact feasibility | Confirmed — supported hook event with manual/auto matchers |

## Additional Scope: Gate Approval Bug Fix (rag-idnu7)

The Inter-Step Quality Review Protocol in work-deep.md needs a fix: after any discussion at a step gate (follow-up questions, clarifications, advisory note discussion), the agent must re-present a brief "ready to proceed?" prompt and wait for explicit affirmative before creating gate issues or updating state.json. This is a behavioral fix to the same commands being modified for self-re-invocation.

## Instructions for Plan Step

1. Read this handoff — do NOT re-read individual research notes
2. Design an architecture that addresses all 5 mechanisms (4 original + PostCompact hook)
3. Include the gate approval bug fix (rag-idnu7) in the scope
4. Consider the tiered freshness model (medium-decay for skills, slow-decay for rules, frozen for specs)
5. Write architecture document at `.work/context-lifecycle/specs/architecture.md`
6. Update `docs/feature/context-lifecycle.md` with component list
