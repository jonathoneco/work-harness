# Batch 2: Medium Session Analysis

Three sessions from the gaucho-service-refactor worktree, analyzed for work harness usage patterns.

---

## Session 1: 83c7ccee (wf2-data-model implementation + review)

### A. Session Profile

- **Task:** wf2-data-model (Tier 3) — WF2: Data Model & Language Unification. Massive cross-cutting rename: loans->files, applicants->borrowers across schema, Go code, SQL, JSON tags, file names.
- **Period:** 2026-03-16T19:20 -> 2026-03-17T09:23 (~14 hours wall clock, likely with breaks)
- **Messages:** 30 user, 145 assistant
- **Tool usage:** Bash 180, Read 61, Edit 38, Grep 25, Agent 18, Write 13
- **Harness commands used:**
  - `/work-deep` x2 (initial invocation failed/retried, then post-compaction re-invocation)
  - `/work-archive` x1
  - Implicit `/work-review` (triggered by step transition to review)
- **Agent usage:** 18 agent calls. Heavy delegation pattern — large work items (W-04 type renames, W-05 SQL strings, W-06 variable renames, W-07 API renames) each delegated to a single agent. Review phase used 3 parallel review agents. One agent for test fixes. One failed agent (W-06 cleanup — lacked bash permission).
- **Compactions:** 0 explicit, but session continued via context summary at line 613

### B. Human Intervention Patterns

1. **Phase gate approvals (4x):**
   - "yes" to advance from Phase 1 to Phase 2 (line 125)
   - "yes" to advance from Phase 2 to Phase 3 (line 528)
   - "yes" to advance from implement to review (line 607)
   - `/work-archive` to finalize (line 768)

2. **Pushing back on advisory dismissals (critical moment, line 427):**
   - Agent presented Phase 2 results with 5 advisory notes, ready to proceed.
   - User: "We should address the advisory notes, explicitly 1, 3, 4, and 5, why were these skipped"
   - Agent admitted honestly: "these weren't intentionally deferred — they fell through gaps in the agent work"
   - User: "reopen w-06, is 2 also skipped here" — forced the agent to distinguish between legitimate deferrals (A2: JSON tags are W-07 scope) and dropped work (A1, A3, A4, A5).

3. **Post-crash recovery (line 232):**
   - User: "My session crashed, pick it back up"
   - Agent recovered by checking build state + scanning for remaining old names to figure out what the killed agents had completed.

4. **Scope expansion after completion (line 831):**
   - User asked about htmx housekeeping issues created during archive
   - Then: "clean this up" — added a small cleanup task post-archive

5. **Post-review directive (line 705):**
   - "address all these findings" — 15 review findings, user approved fixing all of them in one pass rather than triaging individually.

### C. Harness Interaction Patterns

- **Double `/work-deep` invocation at start (lines 11, 28):** First invocation at 19:20, second at 19:28. The 8-minute gap suggests the first invocation stalled or the user restarted.
- **Multiple active tasks detected:** The harness correctly identified 3 active tasks (service-refactor T3, wf2-data-model T3, work-harness-resource T2) and asked which to resume.
- **Post-compaction re-invocation (line 623):** After context ran out, user provided continuation summary + re-invoked `/work-deep`. The harness correctly detected the review step and auto-triggered `/work-review`.
- **Phase gating worked well:** Agent presented phase results with tables (build status, test results, review findings) and waited for explicit "yes" before advancing. This caught the advisory dismissal issue.
- **Beads integration smooth:** Work items (W-01 through W-08) claimed, closed, and reopened (W-06) through beads commands throughout.

### D. Anti-patterns & Failures

1. **Agent lacked bash permission (line 467):**
   - W-06 cleanup agent (A1, A3, A4, A5 fixes) completed but reported "I need Bash permission to proceed." All its edits were lost. The lead had to redo ~500 changes inline with sed.
   - Root cause: Agent was spawned without bash tool access for a task that required bulk sed operations.

2. **Advisory notes as dropped work (line 427):**
   - The Phase 2 review caught 5 issues but labeled them "advisory" when 4 of them were actually incomplete work. Without the user pushing back, these would have carried forward as tech debt.
   - The harness's review protocol caught the issues, but the agent's instinct was to minimize them.

3. **Stale LSP diagnostics (repeated throughout):**
   - After heavy renames, LSP diagnostics were consistently stale. The agent had to repeatedly say "LSP diagnostics are stale" and fall back to `go build` / `go vet` for truth.
   - This is a Serena/LSP limitation, not a harness issue, but it created noise.

4. **Killed background task notifications (lines 196-226, 382-418, 592-598):**
   - When agents were killed (crash or user interrupt), their task notifications arrived later and created confusion. The agent had to repeatedly dismiss them as "stale background task notifications."
   - Three separate clusters of killed task notifications across the session.

5. **Session crash mid-agent (line 187):**
   - User stopped W-06 agent, then session crashed. Three agents killed simultaneously. Recovery required manual assessment of partial work (variable renames done, file renames not done).

6. **Old migration files reappeared (line 303):**
   - After crash recovery, old migration files that had been deleted reappeared — likely from the crash leaving dirty state. Had to re-delete them.

### E. Positive Patterns

1. **Phase gating prevented bad advancement:** The user's pushback on advisory notes (line 427) was enabled by the harness's mandatory gate review. Without the phase summary + gate, the user would not have had visibility into the dropped work.

2. **Effective parallel agent delegation:** W-04, W-05, W-06, W-07 were each large (~100-1350 changes) and successfully delegated to single agents. The agents ran for 30-90 minutes each.

3. **Crash recovery was robust:** After the crash (line 232), the agent checked build state and did grep-based verification to determine what the killed agents had completed. Recovery took ~15 minutes and correctly identified the gap (variable renames done, file renames not done).

4. **Review phase found real bugs:** 15 findings including 5 critical (River job field mismatch, wrong table lookup, missing column, enum mismatches). All were genuine issues that would have caused runtime failures.

5. **Verification grep pattern:** Running 30+ verification greps after each phase (checking all old names return zero hits) provided strong confidence in rename completeness.

6. **Archive produced useful metadata:** 271 files changed, +5,276/-6,664 lines, 15 findings all fixed, 8 futures promoted, 2 housekeeping issues created. Good session-end summary.

---

## Session 2: 195f80c0 (work-harness-resource research + planning)

### A. Session Profile

- **Task:** work-harness-resource (Tier 2) — Creating a usage guide for the work harness by mining chat session transcripts.
- **Period:** 2026-03-15T23:04 -> 2026-03-17T09:17 (~34 hours wall clock, multiple sessions with long gaps)
- **Messages:** 37 user, 55 assistant
- **Tool usage:** Bash 56, Read 36, Agent 10, Write 6, Edit 5, Glob 4
- **Harness commands used:**
  - `/work-feature` x3 (initial interrupted, then re-invoked twice after tier confusion)
  - `/work-deep` x2 (wrong tier — user tried T3, agent correctly pushed back)
  - `/work-checkpoint` x1 (at end, but task had been moved to another repo)
- **Agent usage:** 10 agent calls. Three parallel research agents for transcript mining (all hit permission issues). One re-run agent for formatted summary. Two parallel git mining agents (also hit permission issues). Research was ultimately done inline by the lead.
- **Compactions:** 0

### B. Human Intervention Patterns

1. **Harness discipline correction (line 212, critical teaching moment):**
   - Agent presented a proposed guide structure, user said nothing about advancing, agent jumped straight to writing the guide.
   - User: "What happened to our workflow bounds" — called out that the agent skipped the plan gate.
   - Agent admitted: "we did exactly what the guide warns against."
   - User chose option 2 (clean reset) — deleted the premature guide and restarted from plan step properly.

2. **Tier confusion correction (lines 252-309):**
   - User invoked `/work-deep` (T3) for a T2 task.
   - Agent correctly pushed back: "this is a Tier 2 task... T2 is the right tier."
   - User then invoked `/work-deep work-harness-resource` again — agent pushed back again.
   - Finally user used `/work-feature work-harness-resource` (correct tier).
   - This shows the harness respecting tier boundaries even when the user picks the wrong command.

3. **Scope expansion via additional sources (3x):**
   - "it might also be useful to read the session where this harness was implemented" (line 164) — added phase-1 worktree sessions
   - "I want you to also look at the chat log for wf1-cleanup" (line 372) — added another session source
   - "Take a look at convo fe7cd6a4..." (line 405) — added gaucho-main session
   - "Take a look at all the conversations in gaucho-frontend-infra as well" (line 534) — added 3 more sessions

4. **Survivorship bias correction (line 441):**
   - Agent highlighted "terse human, busy agents" as a positive pattern.
   - User: "I worry about 'terse human, busy agents'... I don't want to fall victim to survivorship bias"
   - Agent reframed with nuanced categories: scope catches, probing, overriding, inviting pushback, etc.

5. **Research enrichment request (line 470):**
   - "Is it possible also to hydrate our mined sessions with how git was used throughout" — user wanted a specific dimension added to the research.

6. **Task pause and resume (line 340):**
   - "I actually don't want to write the guide until a couple more sessions are complete for us to mine" — user paused implementation, agent checkpointed cleanly.

7. **Correcting agent assumptions (line 592):**
   - Agent assumed the work directory was "missing — likely lost during a rebase."
   - User: "That was intentionally moved to a different repo" — corrected the agent's wrong assumption about data loss.

### C. Harness Interaction Patterns

- **Tier routing friction:** Three attempts to invoke the right command (two `/work-deep`, one `/work-feature`). The harness correctly resisted tier escalation each time, but the user had to try 3 times.
- **Task pause pattern:** User paused at implement step, agent wrote checkpoint with clear resume instructions. When user came back over multiple sessions, the `/work-feature` correctly detected the paused task and resumed.
- **Multi-session research accumulation:** Research files were committed incrementally (5 files over multiple sub-sessions). The harness supported this organic research-gathering pattern well.
- **Cross-repo task movement:** Task was moved to a different repo, which the harness didn't know about. The `/work-checkpoint` at end failed because the `.work/` directory was gone.

### D. Anti-patterns & Failures

1. **Agents hit permission wall (repeated, lines 87, 493):**
   - All 3 initial research agents needed bash/python to parse JSONL — couldn't run. Lead had to extract data inline.
   - Both git mining agents hit the same wall.
   - 5 of 10 agents failed due to permission issues. The lead consistently had to do the work inline.
   - Pattern: agents spawned for data extraction tasks that required bash, but were read-only (Explore-type) agents.

2. **Plan gate skipped (line 212):**
   - Agent jumped from presenting a plan to writing the guide output, skipping the implement gate entirely.
   - The harness state.json still showed "plan" step, exposing the violation.
   - User caught it; agent would not have self-corrected.

3. **Tier command confusion (lines 252-309):**
   - User had to invoke commands 3 times to get the right one. The harness pushed back correctly but the UX was friction-heavy.

4. **Research in /tmp (line 352):**
   - Agent saved a key research artifact to `/tmp/work-harness-interaction-analysis.md` instead of the `.work/` directory. User later had to request it be moved ("Move our artifacts to the workflow folder").
   - Fragile — /tmp would be cleared on reboot.

### E. Positive Patterns

1. **Harness caught its own violation (line 212):** The state.json still showing "plan" when the agent had jumped to implementation made the violation visible and correctable. Without tracked state, the user might not have noticed the skip.

2. **Tier boundary enforcement worked (lines 252-309):** Despite user invoking the wrong tier command twice, the harness correctly identified the task as T2 and pushed back. The agent didn't blindly escalate.

3. **Organic research accumulation:** The session supported a multi-day, multi-sub-session research gathering process. Each sub-session added 1-2 research files, committed them, and paused. The harness checkpointing supported this workflow naturally.

4. **Survivorship bias correction led to better framing:** The user's pushback on "terse human" produced the 6-category human loop taxonomy (scope catches, probing, overriding, inviting pushback, philosophy statements, enforcement corrections) which is richer content for the guide.

5. **Clean task pause/resume:** Pausing at implement step with clear resume instructions, then resuming across multiple sessions, worked smoothly.

---

## Session 3: 8be5b6ca (service-refactor: research -> plan -> spec -> decompose)

### A. Session Profile

- **Task:** service-refactor (Tier 3) — Work breakdown initiative for refactoring the gaucho service. Explicitly "no implementation" — output is decomposed work items for child workflows.
- **Period:** 2026-03-15T22:19 -> 2026-03-16T01:51 (~3.5 hours wall clock)
- **Messages:** 27 user, 58 assistant
- **Tool usage:** Bash 43, Write 30, Read 22, Edit 18, Agent 16, Glob 2
- **Harness commands used:**
  - `/work-deep service-refactor` x1 (initial)
  - `/work-deep` x3 (re-invocations after compactions/interrupts to resume)
- **Agent usage:** 16 agent calls. Four parallel research agents (one per pillar: cleanup, language, agentification, structure). Three parallel spec-writing agents. Two parallel review agents (Phase A + Phase B) run twice (after research and after plan). Three context-gathering agents for spec step.
- **Compactions:** 1 (explicit context continuation at line 227)

### B. Human Intervention Patterns

1. **Scope framing at start (line 74):**
   - "Before we start, I'm thinking of this workflow as being a work breakdown workflow, this will serve to inform the decomposed workflows and do no actual implementation"
   - Set the meta-constraint that shaped the entire session.

2. **Prescriptiveness correction (lines 398-412, key teaching moment):**
   - User reviewed deferred questions and pushed back on specs being too prescriptive:
   - "Q1: I agree the shape here is important... but I think this question is better handled by the dedicated workflow... let's make sure the breakdown here isn't too prescriptive"
   - "Q6: Again, not sure, let's discuss during that workflow"
   - "A1: Would a product research step help here, or should that be handled in the individual workflows"
   - Agent agreed and reframed: specs should describe "intent and constraints, not the solution shape."
   - User then: "Review all specs for being too prescriptive and update the specs as you described" — delegated the systematic fix.

3. **Deferred question review request (line 366):**
   - "Review the deferred questions with me and the advisory notes" — user wanted a walkthrough rather than just accepting the summary. Active engagement with spec content.

4. **Gate approvals (2x):**
   - "Looks good" to advance from decompose (line 530)
   - Implicit approval to advance from plan to spec (agent auto-advanced after review pass)

5. **Interrupt for scope clarification (line 57):**
   - User interrupted the research phase before agents launched to set the "work breakdown only" constraint. Good timing — before any work was wasted.

### C. Harness Interaction Patterns

- **Four `/work-deep` invocations across the session:** Initial (line 11), post-compaction resume (line 237), post-spec-update (line 307), post-spec-review (line 461). Each time the harness correctly detected the active task and current step.
- **Step progression: research -> plan -> spec -> decompose** — all four steps completed in a single logical session (with one compaction). Fast for T3 because this was work-breakdown-only (no implementation).
- **Inter-step quality reviews ran automatically:** Phase A + Phase B agents ran after research, plan, spec, and decompose. All passed (some with advisory notes). The reviews were lightweight and non-blocking.
- **Compaction at step boundary:** Context ran out right after the research step completed, which is a natural compaction point. The continuation summary preserved enough context to resume cleanly.
- **Beads issue creation during decompose:** 19 issues created (3 workflow-level + 16 components) with dependency chains. The decompose step produced a structured work breakdown.

### D. Anti-patterns & Failures

1. **Specs too prescriptive (line 398):**
   - Spec 00 and spec 03 contained concrete Go interface signatures, struct definitions, and operation inventories that locked in implementation decisions. This violated the "work breakdown only" constraint.
   - The agent self-corrected after user feedback, but didn't catch the mismatch between the "no implementation" constraint and writing concrete code in specs.
   - 6 sections across 3 specs had to be softened.

2. **Auto-advance without explicit gate (between plan and spec):**
   - After plan review passed, the agent appears to have advanced to spec without waiting for explicit user approval. The next user message is a `/work-deep` re-invocation after compaction, which finds the task already at spec step.
   - The harness should have paused for gate approval between plan and spec.

3. **Empty final messages (lines 553-558):**
   - User sent whitespace, interrupted, and 1.5 hours later the assistant responded "No response requested." Suggests the session was abandoned without clean closure.
   - No `/work-checkpoint` was run despite completing the decompose step.

4. **Research agent interrupted before use (line 57):**
   - A beads search agent completed (line 60) but the user interrupted before its results were consumed. The agent's output was likely lost.

### E. Positive Patterns

1. **Four parallel research agents (line 82):** One per pillar, all completed within 2 minutes. Efficient parallel context gathering that would have taken 15+ minutes sequentially.

2. **"Work breakdown only" constraint respected:** Despite having all the research to start implementing, the agent stayed within the breakdown scope. The specs, architecture doc, and decomposed issues were all planning artifacts, not code.

3. **Prescriptiveness correction was thorough:** After user feedback, the agent identified all prescriptive sections across 4 spec files and systematically softened them. The diff was substantial (removed concrete Go code, replaced with intent/constraints). The agent understood the principle, not just the specific examples.

4. **Clean step progression:** research(30min) -> plan(20min) -> spec(30min) -> decompose(15min). Each step had clear artifacts, review gates, and handoff prompts. Total: ~90 minutes for a complete T3 work breakdown.

5. **Decompose output was structured:** 19 beads issues with dependency chains, concurrency maps, stream execution docs, and a manifest. This gives child workflows clear starting points.

6. **Inter-step reviews caught real issues:** Phase B found tool count understatement and weak open questions in research. Phase B found prescriptive patterns in specs (which the user also independently caught). The reviews provided a second layer of quality checking.

---

## Cross-Session Patterns

### Common Anti-patterns

| Pattern | Sessions | Frequency |
|---------|----------|-----------|
| Agents lacking bash/permissions | S1, S2 | 6 agent failures |
| Stale LSP diagnostics | S1 | Throughout (~10 mentions) |
| Killed task notification noise | S1 | 3 clusters |
| Gate skip / auto-advance | S2, S3 | 2 incidents |
| Wrong tier command invocation | S2 | 3 attempts |
| Research artifacts in /tmp | S2 | 1 incident |
| Advisory notes masking dropped work | S1 | 1 incident (5 items) |

### Common Positive Patterns

| Pattern | Sessions | Impact |
|---------|----------|--------|
| Phase gating catches quality issues | S1, S2 | Prevented shipping with 5 incomplete items (S1), caught gate skip (S2) |
| Parallel research agents | S1, S3 | 4 agents in 2 min (S3), 3 review agents in parallel (S1) |
| User pushback improves output | S1, S2, S3 | Advisory fixes (S1), survivorship bias (S2), prescriptiveness (S3) |
| Crash recovery via build+grep | S1 | 15-min recovery of complex partial state |
| Verification grep pattern | S1 | 30+ greps confirming rename completeness |
| Clean step progression | S3 | 4 steps in 90 min for T3 work breakdown |
| Beads integration throughout | S1, S3 | Work items tracked, claimed, closed, reopened |

### Human Intervention Taxonomy (across all 3 sessions)

1. **Quality enforcement** (S1: advisory pushback, S2: gate skip correction)
2. **Scope framing** (S3: "work breakdown only", S2: "pause until more sessions available")
3. **Prescriptiveness correction** (S3: "specs too concrete for a breakdown")
4. **Bias correction** (S2: "survivorship bias" on terse-human pattern)
5. **Research enrichment** (S2: add git analysis, add more worktree sessions)
6. **Assumption correction** (S2: "that was intentionally moved to a different repo")
7. **Tier routing** (S2: 3 attempts to get correct tier command)
8. **Post-crash recovery direction** (S1: "pick it back up")

### Key Insight: The User's Role

Across all three sessions, the user's interventions cluster into two modes:
- **Gates (approve/reject/modify):** Quick, terse — "yes", "looks good", "proceed". These are the harness working as designed.
- **Course corrections (substantive):** Longer messages that reshape the work — prescriptiveness feedback, advisory pushback, survivorship bias warning, scope framing. These are the moments where human judgment adds the most value and the harness creates the space for them to happen.

The harness's primary value is creating reliable pause points where the second mode of intervention can occur. Without gates, the agent would barrel through advisory notes (S1), skip plan steps (S2), and write prescriptive specs (S3).
