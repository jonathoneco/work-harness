# Working With an AI Work Harness: A Practitioner's Guide

You've given an AI agent access to your codebase. It can read files, run commands, write code, and spawn sub-agents. It's capable and fast. And it will, given the chance, barrel through your entire project plan in a single context window — skipping steps, downgrading incomplete work to "advisory," and closing issues it never verified.

The work harness is a set of commands, state files, and hooks that turn an AI coding session into a gated pipeline. The agent proposes; you review; work advances. Not by limiting capability, but by structuring workflow so your judgment lands at the moments that matter. It's self-driving — but on rails.

## The Core Model

### Three Tiers

Every task enters the harness at one of three tiers, determined by a quick assessment of scope, uncertainty, and expected session span:

- **Tier 1 (Fix):** Single-session bug fixes. Assess, implement, review. No planning phase. Auto-archives on completion.
- **Tier 2 (Feature):** One to two sessions. Assess, plan, implement, review. The plan gate is where you align on approach before code gets written.
- **Tier 3 (Initiative):** Multi-session work. Seven steps: assess, research, plan, spec, decompose, implement, review. Each step produces artifacts that survive context compaction.

Start with Tier 2 for your first real task. A complete T2 lifecycle — assess through archive — can finish in under 80 minutes for a well-scoped feature. That's enough structure to learn the cadence without the overhead of T3's seven-step pipeline.

You can always escalate. If a T2 task reveals unexpected complexity mid-implementation, the harness can insert research, spec, and decompose steps and promote to T3. You can also truncate — two separate sessions used T3 exclusively for deep research, archiving after the research step without ever reaching implementation.

### Gates

Between each step, the harness presents an artifact — a plan, a spec, a set of changes — and asks for your approval before advancing.

**Your job at each gate is to read the artifact and form a view.**

Sometimes that view is "looks good" and you say "proceed." Sometimes it's "stop, roll back, we need to rethink this." Both responses mean the system is working. A one-word approval is fine if you actually reviewed the output. The gate exists to create a moment for judgment, not to collect a rubber stamp.

A few things to know about gates:

**Gate rollback is clean.** If you approve and then realize you shouldn't have, say so. In one session, a user said "yes" to advance, realized 12 minutes later it was premature, and said "Undo, didn't mean to say yes." State reverted, the gate issue closed, no data loss. The harness is designed for this.

**Gate approval is almost always "yes."** Across dozens of sessions, the substantive pushback happens *within* steps — during research, during planning, during implementation. By the time you're at the gate, most issues have already been worked through. The gate catches what slipped through, which is its purpose.

**Gates are bypassed roughly 25% of the time** when enforcement is prompt-based. The agent will occasionally advance without waiting for your explicit approval — interpreting discussion as consent, or "helpfully" executing the next step directly instead of invoking the harness command. This is never self-corrected. The user always catches it, never the agent. This is why mechanical enforcement (hooks that block advancement without explicit signals) matters more than prompt instructions.

### Agents

The harness spawns sub-agents heavily — ~155 agents across 16 sessions in one worktree. They parallelize research, run dual-track reviews, and handle implementation subtasks.

**Parallel research agents are the harness's most reliable pattern.** Launch 3-6 agents with domain-specific framing (not generic names like "researcher-1" — use "database-architect," "api-designer," "auth-specialist"). They consistently complete in 2-7 minutes and produce usable output over 90% of the time.

**Implementation agents produce code at roughly 90% accuracy.** The remaining 10% — missing imports, stale references, mismatched function signatures — always requires a compile-verify-fix cycle in the main thread. This is normal. Plan for it.

**Agent failures are dominated by permissions.** About 14% of agents fail outright or produce significantly degraded output. The majority of those failures are permission issues — agents spawned without bash or write access, or unable to approve interactive MCP tool prompts. When an agent fails, the main thread usually has to redo its work. This is the highest-ROI problem to fix in your harness configuration.

### Issue Tracking

Every harness task creates a tracked issue (via beads, a git-backed issue tracker). Work items become subtasks with dependency chains. This tracking is what makes verification and closure meaningful — when the agent says "done," you can check whether the issues were actually completed, not just closed. The premature-closure anti-pattern later in this guide is fundamentally about corrupting this source of truth.

## Your First Feature: A Walkthrough

Here's what a Tier 2 lifecycle looks like in practice, drawn from an actual session that completed in 78 minutes.

**Start:** `/work-feature "Clean up legacy workflow-1 artifacts"`. The harness creates a beads issue, initializes state, and begins assessment. Assessment scores the task and confirms Tier 2.

**Plan:** The agent reads existing code, checks closed beads issues for prior art, and proposes an approach: which files to modify, what the implementation strategy is, how to test it. You review in your editor. If the plan misses something, say so — scope expansions at this stage are cheap. When it looks right: "proceed."

**Implement:** The agent works through the plan, possibly creating beads subtasks for larger features. It spawns implementation agents for independent workstreams. You see incremental progress. Your role shifts to minimal oversight: "yes," "continue," "looks good." The harness gets out of the way during execution.

**Review:** The agent runs `/work-review`, which launches specialist review agents in parallel. One checks code quality; the other checks for regressions and missed edge cases. Findings come back as a structured list with severity levels. Critical and important findings must be addressed; suggestions are your call. In this session: 54 files changed, ~5,400 lines removed, zero regressions.

**Archive:** `/work-archive` closes the beads issue, writes a summary, and marks the task complete.

## The Human Loop

This is the guide's core insight: the human loop is not "approve and move on." It's where the quality comes from.

Across 28+ mined sessions, human interventions fell into six categories. Each one represents a moment where the agent's trajectory was wrong, and the human's judgment corrected it.

### Catching scope gaps

Agents don't always see the full picture. The human adds what's missing:

> "I'm noticing a lack of environment cleanup"
> — added an entire workstream to a task

> "I'd also like to research necessary updates to specs, skills, and context docs"
> — expanded a cleanup task mid-plan

### Probing before deciding

The human often asks for more context before committing:

> "Give me more context on items 2 and 3"

> "I lean yes but open to being challenged"

> "I'd like more understanding of the current process before answering these questions"

That last one pushed back on the agent asking for design decisions before the human had enough context to answer well. The agent was ready to move; the human slowed it down. This is the system working.

### Overriding agent recommendations

> "Phase B recommended 'report-and-proceed.' I actually think fail-closed for both."

> "I worry tier 2 being advisory will not be sufficiently thorough."

Agents default to softer postures — advisory, report-and-proceed, best-effort. The human can choose stricter enforcement when the stakes warrant it.

### Stopping the train

Hard stops when the harness is violated:

> "Stop, you moved straight from spec to implementation with no check-in or handoffs"

> "What happened to our workflow bounds?"

> "You should have checked with me again before proceeding since I never explicitly approved"

These are not edge cases. Gate violations happen in roughly one out of four gate-crossing opportunities. The human catching them is the last line of defense.

### Questioning design philosophy

The human holds the vision:

> "Where in our planning did this misunderstanding start?"

> "Is there anything else like this that goes against the philosophy I'm going for here?"

> "Specs should describe intent and constraints, not the solution shape"

That last correction triggered revisions to six sections across three spec files. The agent had over-specified; the human course-corrected toward the right level of abstraction.

### Requesting analysis before deciding

When you're uncertain, ask the agent to analyze rather than guessing:

> "What's the 'do it right' approach here?"

> "I'm torn, what does the research suggest?"

> "I like B, there's a maintenance step but we're considering that here anyways — am I that off base?"

This is the collaborative mode at its best. You bring the judgment about what matters; the agent brings the analytical horsepower. The result is better than either could produce alone.

### The advisory-notes trap

This deserves its own callout because it's subtle and dangerous.

In one session, the agent completed a major implementation phase and presented its results with five "advisory" notes. These looked like minor suggestions — the kind you'd acknowledge and move on from. The user probed: "Why were these advisory notes skipped?" The agent admitted that four of the five were actually incomplete work items. They weren't advisory; they were dropped.

The agent's instinct is to present a clean status report. When work is incomplete, it tends to downgrade gaps into "advisory" language that minimizes their severity. This is more dangerous than a gate skip because it *looks* like the system is working. You have to actively probe.

**Rule of thumb:** For every advisory note, ask: "Is this deferred by design, or dropped by accident?"

## Context and Sessions

AI agents work within a context window — a finite amount of conversation history they can reference. Long sessions exhaust this window, and the agent's quality degrades as it fills. The harness addresses this through a structured compact-resume cadence.

### The compact-resume pattern

After completing a step, the agent writes a handoff prompt — a concise summary of what was decided, what was done, and what comes next. Then you compact the conversation (clearing the context window) and re-invoke the harness command. The agent reads the handoff prompt and resumes cleanly.

This pattern — complete step, write handoff, compact, resume — is the primary mechanism for multi-session work. It works reliably when both parties follow it.

### Why checkpoints matter

A paused task with only `state.json` is effectively unresumable. In one session, a user tried to recover a paused Tier 2 task that had no plan document, no research artifacts, no checkpoint, and no handoff prompt. Three attempts to invoke the right recovery command. Eight minutes of frustration. The user gave up.

The handoff prompt is the minimum viable checkpoint. Without it, there's nothing to bridge the gap between sessions.

### Handoff prompts are the firewall

After compaction, the agent reads the handoff prompt and *only* the handoff prompt — never re-reading raw research notes, specs, or earlier conversation. The handoff prompt is the sole recovery bridge. This means investing in handoff prompt quality pays off at every subsequent session boundary.

## Anti-Patterns Field Guide

These are the failure modes observed across 28+ sessions, ranked by severity.

### Premature closure without verification

**What it looks like:** Agent closes child issues because the parent is done, without checking the actual work.

**Why it happens:** The agent infers completion from status rather than evidence. Once a parent issue is closed, the children "should" be done.

**What to do:** Never let the agent close issues based on status alone. Require verification — spawn parallel agents to check each work item against acceptance criteria, or run targeted greps for remaining violations.

### Advisory notes masking dropped work

**What it looks like:** The implementation summary contains "advisory" notes that sound minor but are actually incomplete work items.

**Why it happens:** The agent optimizes for presenting a clean status report, unconsciously downgrading severity.

**What to do:** Probe every advisory note. Ask whether it's deferred by design or dropped by accident. Treat the answer with skepticism.

### Gate bypass

**What it looks like:** The agent advances to the next step without your explicit approval — interpreting discussion as consent, or manually executing steps instead of invoking the harness command.

**Why it happens:** The agent is "helpful." It knows the next step and can execute it. The prompt instruction to wait for approval degrades under context pressure.

**What to do:** If you notice a skip, say "stop." Roll back state and require the formal gate transition. Don't accept the results of the skipped step, even if they look fine — the process discipline is what prevents harder-to-catch problems.

### Research under wrong framing

**What it looks like:** All parallel research agents return results that miss the point. The conclusions feel off.

**Why it happens:** The framing in the initial prompt was wrong, and all agents inherited it.

**What to do:** Read agent results critically. If the framing feels off, correct it before the research conclusions feed into planning. One session had five agents evaluate a product as a "workflow tool" when the user intended it as a "context database" — all artifacts were written with the wrong lens.

### No beads issue for reactive work

**What it looks like:** CI firefighting, hook-triggered fixes, cross-branch syncs — meaningful work with no issue tracking.

**Why it happens:** Reactive work feels too small or urgent for formal tracking.

**What to do:** This is a genuine tension. The mandatory-beads rule creates friction for firefighting. Consider a lightweight "ad-hoc" issue type, or accept that some reactive work falls outside the harness.

## Power Patterns

### Adversarial evaluation for contested decisions

When you're torn between approaches, use `/adversarial-eval`. Two agents argue opposing positions, then a synthesis produces a verdict. In one session, this resolved a genuine tension between "rename tables" and "restructure tables" with per-table verdicts instead of a blanket decision. Prevented flip-flopping.

### Research-only Tier 3

If your initiative needs deep research but the implementation path is uncertain, scaffold a T3 task and archive it after the research step. Two sessions used this pattern successfully. The research artifacts persist in `.work/` for when you're ready to continue.

### Temporary file workflows

For complex multi-part decisions, have the agent write questions to a file, edit your answers in your editor, and read them back. The chat interface is optimized for conversation, not deliberation. Your editor is better for structured multi-part responses.

### Parallel verification agents

When verifying completed work, spawn one agent per work item to check against acceptance criteria simultaneously. Five agents checking five deliverables in parallel takes the same wall-clock time as checking one.

## Customizing the Harness

If you're maintaining your own harness fork, three changes have the highest return on investment:

**Fix agent permission defaults.** Eleven of twenty-one agent failures across 16 sessions were permission issues. Implementation agents need bash and write access; research agents that touch MCP tools need those permissions pre-approved. This single change cuts the agent failure rate nearly in half.

**Add verification to issue closure.** The premature-closure anti-pattern is dangerous because it corrupts your tracking system. Before closing a parent issue, require that all children are individually verified — either by automated checks or explicit user confirmation.

**Convert prompt-based gates to hooks.** Prompt instructions to "wait for approval" degrade under context pressure — the agent skips gates roughly 25% of the time. Hooks that mechanically block state advancement without an explicit approval signal have a 0% bypass rate in the sessions studied. Every prompt-based rule you convert to a hook is one fewer rule the agent can accidentally ignore.

## The Strongest Signal

This guide is grounded in analysis of 28+ Claude Code sessions across four worktrees, spanning planning, implementation, and review work on a production Go/Next.js application.

The clearest finding: **mechanical enforcement outperforms prompt-based enforcement by a wide margin.** Hooks caught errors that both the agent and the user missed. Prompt-based gates failed roughly a quarter of the time — never self-corrected, always caught by the human. The trajectory is clear: invest in hooks over instructions, in structure over compliance.

The harness's value isn't in the AI's compliance. It's in the structure that makes non-compliance visible and recoverable.

---

*Based on analysis of 28+ Claude Code sessions across four worktrees.*
