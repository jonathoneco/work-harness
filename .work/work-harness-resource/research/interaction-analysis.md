# Work Harness Interaction Analysis

Extracted from 12 Claude Code sessions across 2 worktrees (agentic-phase-1 and stripped-api), spanning 2026-03-14 08:36 to 2026-03-15 21:21. Total: 279 user messages.

---

## 1. Session Timeline

| # | Session ID | Worktree | Time Range | User Msgs | Opening Command/Intent | Key Activity |
|---|-----------|----------|------------|-----------|----------------------|--------------|
| 1 | c1619c39 | phase-1 | Mar 14 08:36-20:33 | 26 | /workflow-implement code-review-harness | V1 workflow: parallel streams, agent implementation, archiving legacy workflow |
| 2 | 3186d70b | phase-1 | Mar 14 20:33-22:32 | 40 | /work dev-env-silo | V2 harness debut: Tier 3 dev-env-silo initiative, research + planning |
| 3 | 4ba64b10 | phase-1 | Mar 14 21:36-Mar 15 17:38 | 84 | /work-reground code-review-harness | Longest session: harness enforcement workflow, corrections, spec/decompose/implement |
| 4 | ea534a00 | stripped-api | Mar 15 17:54-18:19 | 14 | /work strip-api | Start strip-api initiative, research + planning |
| 5 | 51a71fc6 | stripped-api | Mar 15 18:01-18:25 | 3 | /workflow-meta (gap audit) | Audit harness gaps between dotfiles and project |
| 6 | 84d76495 | stripped-api | Mar 15 18:08-18:23 | 3 | /workflow-meta (tier routing) | Fix /work to call tier-specific commands |
| 7 | d51a15a0 | stripped-api | Mar 15 18:19-19:24 | 16 | /work-deep strip-api | Strip-api spec phase, plan review, checkpoint |
| 8 | d10889e0 | stripped-api | Mar 15 18:58-19:11 | 3 | /workflow-meta (review gaps) | Fix missing inter-step reviews |
| 9 | 4868fe3a | stripped-api | Mar 15 19:11-20:11 | 13 | (implement plan) | Implement inter-step review protocol, corrections about self-driving vs gated |
| 10 | e41b8c95 | stripped-api | Mar 15 19:25-21:47 | 63 | /work-deep strip-api | Main implementation session: all W-items, review, archive, PR prep |
| 11 | 34cc05ea | stripped-api | Mar 15 20:31-21:12 | 10 | /workflow-meta | Fix findings location, compaction, dead code cleanup |
| 12 | 8df2767b | stripped-api | Mar 15 21:12-21:21 | 4 | (implement pr-prep) | Implement PR gate hook and /pr-prep command |

### Concurrency Pattern

Sessions 2 and 3 ran concurrently on the same worktree (phase-1): session 2 did dev-env-silo work while session 3 did harness enforcement work. The user explicitly managed this: "Let's keep phase-2 active and start the harness enforcement workflow here."

Sessions 4-12 on stripped-api show a dense burst: 9 sessions in ~3.5 hours, with multiple concurrent sessions (e.g., sessions 5/6/7 overlapped; sessions 9/10/11 overlapped). Product work and harness improvement ran in parallel.

---

## 2. Command Invocation Patterns

### Primary Harness Commands

| Command | Count | Context |
|---------|-------|---------|
| `/work` | 4 | Entry point. Always with a slug: `dev-env-silo`, `strip-api`. User interrupted once and re-invoked with more context. |
| `/work-deep` | 5 | All for `strip-api`. Re-invoked across sessions to resume the active Tier 3 task. |
| `/work-reground` | 1 | Used to recover context in a new session for `code-review-harness`. |
| `/work-review` | 2 | Invoked at implementation completion to run structured code review. |
| `/work-archive` | 4 | 2 invocations were double-taps (interrupted + retry). Used at task completion. |
| `/workflow-implement` | 4 | Legacy V1 command. Used in earliest session for `code-review-harness`. Modes: default, `parallel`, `stream 9`. |
| `/workflow-archive` | 1 | Legacy V1 command. Used once to archive `code-review-harness`. |
| `/workflow-meta` | 4 | Harness improvement sessions. Used to audit gaps, fix routing, fix review behavior, fix findings location. |
| `/compact` | 1 | Manual compaction after context grew large during harness-enforcement session. |
| `/context` | 2 | Checked context usage at 201k/1000k and 358k/1000k. |
| `/clear` | 1 | Session start housekeeping. |

### Invocation Style

- **Slug-based**: Commands always include a task slug as argument: `/work strip-api`, `/work-deep strip-api`, `/work-reground code-review-harness`
- **Re-invocation after interrupt**: The user frequently re-issues commands after interrupting (e.g., `/work-archive` sent twice in quick succession)
- **Inline context**: Once, the user embedded a full task description in the `/work` args: "strip-api\n\nRight now, we're a golang project that serves frontend via htmx..."
- **/work-checkpoint** was invoked implicitly (via `--step-end` in other commands) rather than directly by the user in these sessions; it appears as injected command content 2 times

### Absent Commands

- `/work-fix` and `/work-feature`: Never directly invoked in these sessions (all work was Tier 3)
- `/work-status`: Never invoked (user relied on `/work-reground` instead)
- `/work-redirect`: Never invoked (though the concept was discussed)

---

## 3. User Feedback & Corrections

### Critical Corrections (in chronological order)

**Correction 1: Harness dropped guardrails during dev-env-silo (Mar 14 22:38)**
> "I just tried my first workflow with the new harness and noticed some issues... previously commands would flow into each other and once a phase would complete, I would be prompted to checkpoint / start the next, the workflow would kind of guide itself. I purposefully didn't push the agent in the right directions to see what would happen. This was determined to be a tier 3 task, but very quickly the agent dropped the workflow guard rails / intended pathing... It kind of weakly 'vibed' through the workflow state rather than the intended experience of this serving as a strict harness for the work. Towards the end, it completely dropped the pretense of being in a workflow... **This is unacceptable**"

**Correction 2: Skipped directly from spec to implementation (Mar 14 23:23)**
> "**Stop, you moved straight from specing to implementation with no check in or handoffs**"

**Correction 3: Code quality degradation under context pressure (Mar 14 23:48)**
> "I worry our code quality bounds are also being less strictly enforced, I just got recommended a compatibility shim"

**Correction 4: Advisory content being degraded by context pressure (Mar 14 23:51)**
> "I worry about any other advisory content that may be being similarly degraded, we should identify if there are any other such potential gaps, and maybe we should incorporate intentional compaction steps at logical intervals to combat this"

**Correction 5: Context recovery in fresh session failed (Mar 15 00:36)**
> "This is an issue, look at the conversation in that fresh session" [pasted an entire session transcript showing the model didn't properly reground and just offered to start making changes]

**Correction 6: Confused about self-driving scope (Mar 15 02:31)**
> "I'm confused, does this mean I won't be briefed and checked with in between steps?"

**Correction 7: Explicit rejection of silence = proceed (Mar 15 02:32)**
> "**I explicitly don't want silence = proceed**"

**Correction 8: Clarifying what "self-driving" means (Mar 15 02:33)**
> "Where in our planning did this misunderstanding start, the 'self-driving' model is about the model sticking to the harness bounds and flowing through the steps accordingly"

**Correction 9: Overcorrection on self-driving (Mar 15 19:39)**
> "Wait I think you've overcorrected, **I don't want self-driving, I want gated check-ins, I only want self-driven reviews**"

**Correction 10: Philosophy alignment check (Mar 15 20:07)**
> "Is there anything else like this that goes against the philosophy I'm going for here"

**Correction 11: Findings location wrong (Mar 15 20:38)**
> "If it wasn't in the command or skill, why did it default to .review/findings.jsonl"

**Correction 12: Compaction not happening (Mar 15 20:49)**
> "I also noticed we're not compacting at logical stages like the harness should be doing, were the instructions for this lost or just not being respected"

### Recurring Themes in Corrections

1. **Harness as guardrail, not suggestion**: The user wants the harness to be a strict system that prevents the AI from skipping steps, not advisory guidance that degrades under context pressure
2. **Gated transitions, not self-driving**: Reviews should be automatic (Phase A + Phase B), but step transitions must wait for user acknowledgment
3. **Context degradation awareness**: Rules and quality standards degrade as context fills up; the user wants mechanical enforcement (hooks, scripts) rather than relying on LLM memory
4. **Hook false positives**: The beads-check hook fired when no code files were modified (just conversation about system config)

---

## 4. Decision-Making Style

### Quick Decisions (most common pattern)
The user makes decisions in 1-5 word responses when presented with clear options:
- "Proceed" / "Proceed with tier 3"
- "Let's go with option 1" / "Let's go with 2"
- "Approved" / "Looks right" / "Looks good"
- "Launch" / "Launch them"
- "Yes 100%" / "Both"
- "5" (selecting a score)
- "I lean 1"

### Directive Decisions
When the user has a specific vision, they give clear directives:
- "Delete them outright" (re: legacy commands)
- "Archive both and start the strip-api initiative"
- "Roll back state to spec, and undo the changes as they're causing issues"
- "Fix everything now before advancing"
- "Let's stop here and do a review phase"

### Interrogative Decisions
The user asks probing questions before deciding:
- "Give me more context on items 2 and 3"
- "what does public invites mean"
- "are these still relevant, some of these feel like ui artifacts"
- "Should the review passes be tied to the workflow itself rather than in .review"

### Multi-Part Decisions
When given multiple decision points, the user addresses each inline:
- Numbered list responses matching the AI's numbered questions (e.g., "1. Delete them outright. 2. I want to be clear, these hooks should be copied not moved... 3. Confirm whether this is the case... 4. Expand... 5. Looks good")
- "for 2 let's go with option A, for 3 let's go with option C"

### Characteristic: Never deliberates at length
The user does not write long deliberative responses. Decisions are made quickly, often in under 10 words. When more context is needed, they ask a focused question first, then decide with a short response.

---

## 5. Session Boundary Patterns

### Session Starts

| Pattern | Frequency | Examples |
|---------|-----------|---------|
| Slash command | 10/12 | `/work strip-api`, `/work-deep strip-api`, `/workflow-meta`, `/work-reground code-review-harness` |
| Interrupt + re-issue | 2/12 | User interrupted initial response and re-invoked with more context |
| Resume from prior session | 3/12 | `/work-deep strip-api` to resume active task, `/work-reground` for context recovery |

### Session Ends

| Pattern | Frequency | Examples |
|---------|-----------|---------|
| Archive command | 3 | `/work-archive` after completing all steps |
| Commit + push directive | 4 | "Commit and push our local changes", "push them in scoped commits" |
| PR preparation | 1 | "Prepare a PR for this branch" |
| Implicit end (last message was short directive) | 4 | "I lean 1", "Yes", etc. |
| Checkpoint | 2 | `/work-checkpoint --step-end` to save progress |

### Context Compaction

- Manual `/compact` was used once (Mar 15 00:11) at 201k/1000k tokens
- The user checked `/context` twice during the longest session to monitor usage
- The user expressed frustration that compaction wasn't happening at logical step transitions: "we're not compacting at logical stages like the harness should be doing"

---

## 6. Agent Coordination

### Task Notification Volume

41 task notifications were received across 5 sessions. The heaviest session (e41b8c95) received 24 notifications from parallel implementation agents.

### User's Interaction with Agent Results

1. **Passthrough on success**: When agents complete successfully, the user typically gives a 1-word acknowledgment ("Launch them", "Fix the suggestions") or the next directive
2. **Permission escalation**: Early sessions (c1619c39, 3186d70b) had agents blocked by tool permission denials (Write, Bash). The user received these notifications and the orchestrator retried or worked around them
3. **Minimal review of agent output**: The user rarely quotes or questions agent output. Trust is high for implementation agents. Review agent findings get more scrutiny
4. **Parallel launch pattern**: User says "launch" or "proceed" and then waits for multiple task notifications to arrive before giving the next instruction
5. **Work while waiting**: "Anything we can do while that's going" -- user asks to be productive while agents execute

### Agent Types Observed

- **Research/audit agents**: Search closed beads, map handler surfaces, map HTMX coupling
- **Implementation agents**: Per work-item (W-01 through W-09), executing in parallel
- **Review agents**: Go reviewer, security reviewer, stack tracer -- spawned in parallel for post-implementation review
- **Fix agents**: Spawned to fix review findings

---

## 7. Harness Iteration Interleaving

### The Dual-Loop Pattern

The user runs product work and harness improvement as interleaved concurrent workstreams:

```
Mar 14 08:36  [HARNESS-V1]  /workflow-implement code-review-harness  (session 1)
                             Implementing the harness itself using the old system

Mar 14 20:33  [PRODUCT]     /work dev-env-silo                       (session 2)
                             First test of new harness on real work
                             ** Harness drops guardrails -- "This is unacceptable" **

Mar 14 21:36  [HARNESS-V2]  /work-reground code-review-harness       (session 3)
                             Start harness-enforcement workflow to fix v2
                             Concurrent with session 2
                             "Stop, you moved straight from specing to implementation"

Mar 15 17:54  [PRODUCT]     /work strip-api                          (session 4)
                             Start strip-api initiative

Mar 15 18:01  [HARNESS]     /workflow-meta (gap audit)                (session 5)
Mar 15 18:08  [HARNESS]     /workflow-meta (tier routing)             (session 6)
Mar 15 18:19  [PRODUCT]     /work-deep strip-api (spec)              (session 7)
Mar 15 18:58  [HARNESS]     /workflow-meta (review gaps)              (session 8)
Mar 15 19:11  [HARNESS]     (implement review protocol)              (session 9)
                             "I don't want self-driving, I want gated check-ins"

Mar 15 19:25  [PRODUCT]     /work-deep strip-api (implement)         (session 10)
                             Full implementation session

Mar 15 20:31  [HARNESS]     /workflow-meta (findings, compaction)     (session 11)
Mar 15 21:12  [HARNESS]     (implement pr-prep)                      (session 12)
```

### Key Observations

1. **Harness problems discovered through product work**: The user ran dev-env-silo (session 2) specifically to test the new harness, discovered it was inadequate, then immediately started a harness-enforcement workflow (session 3) to fix it

2. **Rapid interleaving on Mar 15**: 5 harness sessions and 4 product sessions within 3 hours. Harness fixes were triggered by issues discovered during product work:
   - Product session reveals missing inter-step reviews --> harness session to add them
   - Product session reveals findings in wrong location --> harness session to fix
   - Product session reveals compaction not happening --> harness session to address

3. **Harness work uses the harness itself**: The harness-enforcement work (session 3) used `/work-deep` -- the very system it was trying to fix. This created a recursive improvement loop where bugs in the harness were experienced firsthand during the work to improve the harness

4. **Philosophy crystallized through corrections**: The user's vision became clearer through correcting misinterpretations:
   - First correction: "strict harness, not suggestion system"
   - Second correction: "don't skip steps"
   - Third correction: "self-driving means staying on rails, not autonomous"
   - Fourth correction: "gated transitions + self-driven reviews"

5. **Harness sessions are short and surgical**: Most `/workflow-meta` sessions are 3-4 messages. Product sessions are longer (14-84 messages). The user makes targeted improvements to the harness tooling in focused bursts, then returns to product work to test them.
