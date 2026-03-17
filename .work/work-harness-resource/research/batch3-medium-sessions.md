# Batch 3: Medium Session Analysis

**Sessions analyzed:** 4
**Total user messages:** 89
**Total assistant responses:** 210
**Session date range:** 2026-03-15 to 2026-03-17

---

## Session 1: 380ab6e5 — Evaluate OpenViking Dependency

### A. Session Profile

- **Task:** evaluate-openviking (Tier 3)
- **Work:** Research whether OpenViking library is a suitable dependency for the gaucho platform
- **Duration:** ~1h20m (23:36 to 00:55)
- **Messages:** 26 user / 49 assistant
- **Harness commands used:** `/work` (initial invocation), `/work-deep` (delegated to T3 flow)
- **Agent usage:** 12 agents total
  - 5 parallel research agents (OpenViking external, product analyst, Notion researcher, harness analyst, beads archaeologist)
  - 2 parallel review agents (Phase A artifact validation, Phase B quality review)
  - 1 re-review agent (Phase B quality re-review after Notion data added)
  - 3 Notion reading agents (PRD reader, UI/UX spec reader, remaining PRD sections)
  - 1 retry of Notion search (direct, after agent permission failure)

### B. Human Intervention Patterns

1. **Accidental gate approval + undo** (00:08): User said "yes" to advance from research to plan, then 12 minutes later said "Undo, didn't mean to say yes." The assistant rolled back the state transition and reopened the gate issue. This is the clearest example of the gate mechanism protecting against premature advancement.

2. **Blocking on Notion access** (00:25): User declared "The notion context is crucial, we're blocked until that exploration is done" — overriding the assistant's suggestion to proceed without Notion data. This established a hard dependency the assistant hadn't recognized.

3. **Scope correction on category mismatch** (00:51): After the assistant delivered its "pass" verdict on OpenViking (calling it a workflow tool mismatch), the user corrected: "We're considering it for a context database for the ai agents driving the work." The assistant had misunderstood the evaluation framing. It re-evaluated with the corrected framing but reached the same conclusion (pass, but for different reasons).

4. **Pivot and close** (00:54): User initiated early closure: "Let's pivot, close with finding." The assistant archived the task, closed beads, and wrote a decision document in one move.

### C. Harness Interaction Patterns

- **Two-command startup:** `/work` triggered assessment, user confirmed, then `/work-deep` was invoked to route into the T3 flow. This two-step invocation (assess then route) is the standard pattern.
- **Research step was the entire task.** The T3 flow defined 7 steps (assess -> research -> plan -> spec -> decompose -> implement -> review) but the task never left research. The user closed it with findings after research completed — a "research-only initiative" pattern.
- **Gate rollback worked cleanly.** State was reverted from plan back to research:active, gate issue was closed as reverted. No data loss.
- **No checkpoint usage.** Despite the session spanning 1h20m with a Notion blocker in the middle, no explicit `/work-checkpoint` was used.

### D. Anti-patterns & Failures

1. **Agent permission failure:** The Notion researcher agent was denied MCP tool permissions because sub-agents can't approve interactive permission prompts. The assistant had to retry Notion searches in the main thread. This is a known limitation of delegating MCP-gated tools to agents.

2. **Notion token debugging consumed ~15 minutes.** The token was `${NOTION_TOKEN}` (unexpanded shell variable), then had a missing closing quote after user fix. Two rounds of "I fixed it, try again" before it worked.

3. **Category misunderstanding persisted through all research.** Five parallel agents researched OpenViking under the wrong framing (workflow tool vs. context database). The user only corrected this after reading the final verdict. All research artifacts were written with the wrong lens. The harness didn't prevent this because the original task description was ambiguous.

4. **PRD agent was blocked on bash permissions.** The Notion PRD was 87K chars and the agent that tried to parse the JSON couldn't run bash. The assistant had to extract it manually in the main thread, consuming context.

### E. Positive Patterns

1. **5 parallel research agents** completed efficiently — 4 of 5 returned within ~2 minutes, the 5th (web search) within ~4 minutes. This is the harness research pattern working as designed.
2. **Two-phase review (Phase A + Phase B) ran in parallel**, catching the Notion gap as an advisory.
3. **Gate rollback was smooth and non-destructive.** The "undo" request was handled in 2 assistant messages — state reverted, gate issue closed, all artifacts preserved.
4. **Clean archive with decision document.** The task ended with a concrete artifact (`docs/feature/evaluate-openviking.md`) documenting the finding for future reference.

---

## Session 2: a7f2fd38 — Work Harness Resource Guide (Initial Research + Plan)

### A. Session Profile

- **Task:** work-harness-resource (Tier 2)
- **Work:** Create a blog-post-style guide documenting how to use the work harness, based on real session transcripts
- **Duration:** ~3h8m (23:04 to 02:12), but with a ~1h50m gap (task paused at 00:14, resumed at 01:53 for a meta-fix)
- **Messages:** 22 user / 50 assistant
- **Harness commands used:** `/work-feature` (initial, interrupted), `/work-feature` (with description), `/work-deep` (misfire — wrong tier), `/work-deep` (with task name — corrected), `/work-feature` (correct re-invocation), `/workflow-meta` (harness fix)
- **Agent usage:** 5 agents total
  - 3 parallel research agents (user interaction patterns, assistant harness actions, harness iteration work)
  - 1 formatted summary agent (re-run after initial agents hit permission issues)
  - 1 technical writer agent (started then cancelled)

### B. Human Intervention Patterns

1. **"What happened to our workflow bounds"** (00:01): The assistant skipped the plan gate — presented a plan, then jumped straight to writing the guide without getting explicit approval. The user caught this immediately. The assistant acknowledged: "We did exactly what the guide warns against." This is ironic given the guide itself was about workflow discipline.

2. **Clean reset chosen over retroactive correction** (00:02): Given the choice between (1) retroactive correction (pretend the gate was followed) and (2) clean reset (delete the guide, re-present plan), the user chose option 2. The guide was deleted and the plan was re-presented.

3. **Scope expansion — additional source material** (23:33): "It might also be useful to read the session where this harness was implemented" — user directed the assistant to also mine the phase-1 worktree sessions, expanding the research scope.

4. **Scope reduction — pause for more data** (00:10): "I actually don't want to write the guide until a couple more sessions are complete for us to mine, should we pause here until that's done." User deferred the implementation step to accumulate more source material.

5. **Cross-branch commit request** (01:57): "Commit this to main (careful not to throw away the active changes on main) and make sure it stays reflected here." This is a git workflow directive — cherry-pick to main without disturbing either branch.

### C. Harness Interaction Patterns

- **Command misfire cascade (00:04-00:07):** User invoked `/work-deep` for a T2 task. Assistant correctly pushed back: "This is a Tier 2 task. T2 is the right tier. Should I continue with `/work-feature` routing instead?" User then invoked `/work-deep work-harness-resource` (with task name). Assistant pushed back again. User finally invoked `/work-feature work-harness-resource` which worked. Three invocations to get the right command — friction from having both `/work-deep` and `/work-feature` as separate entry points.

- **Plan gate violation detected by user, not harness.** The harness had no enforcement mechanism to prevent the assistant from skipping from plan to implement. The user's vigilance was the only safeguard. This is the "prompts = 65% reliable" problem the harness docs describe.

- **Session forked into meta-work.** After pausing the resource task, the user invoked `/workflow-meta` to fix the research artifact persistence bug discovered during this session. The session served dual purposes: product work + harness improvement.

- **Research artifacts written to `/tmp/` instead of `.work/`.** This was the bug discovered and fixed via `/workflow-meta` — agents had no output path directive and defaulted to ephemeral locations.

### D. Anti-patterns & Failures

1. **Step skip (plan -> implement without gate).** The most significant failure in this batch. The assistant presented a plan, the user didn't explicitly approve it, and the assistant started writing the guide. The harness state still showed `current_step: "plan"` — the state machine and the actual behavior diverged.

2. **Agents hit permission issues.** All three research agents were blocked on bash permissions (needed to parse JSONL). The assistant had to extract data directly in the main thread, then later re-run a single agent with the correct approach.

3. **Research artifacts in `/tmp/`.** The interaction analysis was written to `/tmp/work-harness-interaction-analysis.md`, which would be lost on reboot. This was identified as a systemic issue and fixed via `/workflow-meta`.

4. **Three command invocations to resume correctly.** The user had to try `/work-deep`, then `/work-deep work-harness-resource`, then `/work-feature work-harness-resource` before the right command matched. The command surface has ambiguity around which tier command to use for an existing task.

### E. Positive Patterns

1. **User caught the step skip immediately.** The "what happened to our workflow bounds" correction demonstrates the human-in-the-loop value. The guide being deleted and re-planned is exactly the discipline the harness aims to enforce.

2. **Clean pause + resume design.** The task was parked at the implement step with all research artifacts preserved. The assistant provided clear resume instructions: "Run `/work-feature` — it'll detect the active task and resume at implement."

3. **Dual-loop productivity.** The session produced both progress on the resource guide (research complete, plan approved) and a harness fix (research artifact persistence). The `/workflow-meta` command enabled seamless context-switching.

4. **Cherry-pick to main worked cleanly.** The cross-branch commit was executed correctly — cherry-picked to main worktree without disturbing either branch's uncommitted state.

---

## Session 3: 700a5928 — Agentic Baseline Research (Product-Agent-Scope)

### A. Session Profile

- **Task:** agentic-baseline, later renamed to product-agent-scope (Tier 3)
- **Work:** Deep research on agentic AI-native platform design — product vision, workflow harness transferability, agentification plan alignment
- **Duration:** ~6h (02:23 to 08:26), likely with significant idle gaps
- **Messages:** 24 user / 51 assistant
- **Harness commands used:** `/work` (initial), `/work-deep` (T3 routing)
- **Agent usage:** 9 agents total
  - 3 parallel research agents (Notion researcher, harness analyst, plan analyst)
  - 2 parallel review agents (Phase A, Phase B)
  - 1 UX spec re-research agent
  - 1 DB research agent
  - 1 agent memory research agent
  - 1 agent for UX spec reading (from background)

### B. Human Intervention Patterns

1. **Missing research coverage** (03:00): "It seems like the notion research is missing some context, we should also be looking at the MVP UI/UX Spec." The research agent found but didn't fully read the UX spec. User caught the gap.

2. **Multi-message product brain dump** (03:45): User provided extensive product design notes — flag anatomy, chat context persistence, calendar integration — as design constraints to capture. The assistant dutifully recorded them as research artifacts.

3. **Scope reduction + rename** (07:03): "I actually just want this workflow to have been this research step, rename it to product-agent-scope, and clean it up / archive it appropriately." The user decided the 7-step T3 flow was overkill — the research itself was the deliverable. The task was renamed, archived directly from research, skipping plan/spec/decompose/implement/review.

4. **Accidental interrupts** (07:03-07:04): Three rapid interrupts + "pink" (likely touchpad/keyboard accident) followed by "Continue, didn't mean to interrupt." The assistant handled these gracefully — no state corruption.

5. **Post-archive addition** (07:43): After archiving, user requested "I'd like to add a research step for potential memory integrations." The assistant added a new research note to the archived task's artifacts without reopening the task. This is an ad-hoc "append to closed work" pattern.

6. **Cross-artifact update request** (08:24): "Update the scope workflow with these learnings" — user directed the assistant to propagate the memory research findings across all related artifacts (synthesis, handoff prompt, feature summary).

### C. Harness Interaction Patterns

- **Research-only T3 task.** Like Session 1, the full T3 pipeline was set up but only the research step was used. The user explicitly truncated: "I actually just want this workflow to have been this research step." This suggests a pattern: T3 is being used as a "research initiative" tier, not always a full implementation pipeline.

- **Task rename during archival.** The task was created as `agentic-baseline` and renamed to `product-agent-scope` at archive time. The assistant handled the rename by updating state.json, renaming the `.work/` directory, and updating the beads issue.

- **Post-archive modification.** The user added research to an archived task. The assistant didn't reopen the task — just appended artifacts and updated docs. This suggests the archive boundary is soft; users treat archived tasks as living documents.

- **Parallel research -> synthesize -> review** pipeline ran smoothly. Three agents researched in parallel (all completed within ~7 minutes), synthesis was written, two-phase review ran in parallel (completed within ~2 minutes). The entire research step's automated pipeline took ~12 minutes.

### D. Anti-patterns & Failures

1. **Research agent under-read the UX spec.** The Notion researcher found the page but only read the first page of blocks (API pagination). The user had to flag this gap explicitly. The agent should have paginated through all blocks.

2. **Accidental interrupts caused noise.** Three interrupts + "pink" in rapid succession. No state corruption, but the assistant had to wait for clarification. Not a harness failure, but a usability concern with how interrupts interact with multi-step operations.

3. **Task was over-scaffolded.** A T3 7-step pipeline was created for what turned out to be a research-only task. The assess step consumed time scoring factors that weren't relevant (the user knew they wanted research). A "research sprint" tier or command would have been more efficient.

### E. Positive Patterns

1. **Research artifacts are durable and useful.** Nine research notes were produced, indexed, and committed. The handoff prompt contained 13 open questions — actionable for future planning sessions. The user later used these artifacts as input for other work.

2. **Parallel agent research was efficient.** All three agents completed within 7 minutes, producing ~1,040 lines of research across 4 files. The human's wall-clock cost was minimal.

3. **Post-archive enrichment worked.** Adding the memory research to an already-archived task was smooth — the assistant updated synthesis, handoff, and feature summary docs without ceremony.

4. **Product brain dump was captured as structured artifacts.** The user's freeform notes about flags, chat context, and calendar integration were distilled into specific open questions, design constraints, and futures items. The harness provided a natural place for each type of insight.

---

## Session 4: f392cd9a — WF1 Cleanup (Implementation + Review + Archive)

### A. Session Profile

- **Task:** wf1-cleanup (Tier 2), subtask of service-refactor (T3)
- **Work:** Remove dead code — HTMX routes, dead pipeline artifacts (~4200 lines), fix error patterns, expand constructor injection, clean up context docs
- **Duration:** ~1h18m (00:18 to 01:36)
- **Messages:** 17 user / 60 assistant
- **Harness commands used:** `/work-feature` (initial with beads ID), `/serena-activate` (2x), `/work-review`, `/work-archive`
- **Agent usage:** 16 agents total
  - 4 parallel research/context agents (specs sweep, skills sweep, context doc sweep, agent sweep)
  - 2 parallel implementation agents (1A dead routes + 1D pipeline artifacts)
  - 2 parallel implementation agents (1B constructor + 1C error patterns)
  - 3 parallel review agents (security, cross-layer, code quality)
  - 5 remaining agents (various reading/checking tasks)

### B. Human Intervention Patterns

1. **Scope expansion at implementation start** (00:31): "I'd also like to research / plan necessary updates to specs, skills, and context docs." The user expanded scope to include documentation cleanup alongside the code cleanup — adding component 1F.

2. **Terse approvals dominate.** "Proceed with implementation," "Looks good to me, proceed," "Proceed." The user's interaction style during implementation is minimal oversight — trust the plan, approve quickly.

3. **Serena status check** (00:48): "Is serena working?" — the user noticed Serena reporting a file as not found and asked about tool health. The assistant diagnosed correctly: the file was already deleted from disk (1A completed by a parallel agent).

4. **Suggestion follow-through** (01:24): "I'd like to address the suggestions you brought up." After the review produced 2 suggestion-level findings (not critical), the user chose to fix them rather than skip. Demonstrates quality orientation even for cosmetic issues.

5. **Multiple interrupts during implementation.** Three `[Request interrupted by user]` entries. In one case, the user appears to have been doing 1A edits manually in parallel with the assistant, then confirmed with "Looks good to me, proceed /work-feature."

### C. Harness Interaction Patterns

- **Full T2 lifecycle completed in one session.** assess -> plan -> implement -> review -> archive, all within 1h18m. This is the cleanest T2 execution in the batch.

- **Beads ID passed directly to `/work-feature`.** The user invoked `/work-feature rag-wcfuo` — passing the beads issue ID as an argument. The assistant used this to pull the spec and absorbed issues for context.

- **`/work-review` ran structured review.** Three specialized agents (security, cross-layer, code quality) reviewed 54 changed files in parallel. Produced 0 critical, 0 important, 2 suggestions. Findings were tracked with IDs (f-20260315-001, f-20260315-002).

- **`/work-archive` ran verification checks.** Verified all 4 steps completed, checked finding triage status (2 suggestions both FIXED), confirmed T2 doesn't need archive summary, then committed everything.

- **Serena activated twice.** First activation at session start, second when it wasn't finding symbols. The LSP indexing wasn't ready, so the assistant fell back to direct file reads. Serena worked correctly for the rest of the session.

- **Parallel implementation in pairs.** 1A+1D launched as first pair (independent file sets), then 1B+1C as second pair. The assistant correctly identified independence constraints.

### D. Anti-patterns & Failures

1. **Agent-produced code had compiler errors.** Both the 1D agent and the 1B/1C agents left incomplete import rewrites or mismatched function signatures. The assistant had to fix compiler errors after agents completed. This is a recurring pattern: implementation agents produce ~90% correct code, requiring cleanup in the main thread.

2. **Serena LSP indexing lag.** Serena couldn't find handler symbols on first activation, requiring a re-activation and eventual fallback to direct reads. The LSP server needed time to index after the session started.

3. **Stale diagnostics confusion.** After agents completed their work, Serena reported compiler errors that were already fixed. The assistant had to verify the build was actually clean, wasting a few exchanges on phantom errors.

4. **User working in parallel caused confusion.** The user had already completed some 1A edits manually (deleted workspace.go, modified main.go). The assistant didn't realize this until checking git status, leading to redundant work attempts.

### E. Positive Patterns

1. **Complete T2 lifecycle in ~78 minutes** with 6 components, 54 files changed, ~5,448 net lines removed. The harness provided structure without excessive overhead.

2. **Structured review caught real issues.** The 2 suggestions were cosmetic but legitimate. The user chose to fix them, and the review process tracked them through to FIXED status.

3. **Clean archive with verification.** The archive step verified all steps complete, all findings resolved, and produced a single commit with all changes. No loose ends.

4. **Parallel agents for independent components.** The 1A+1D and 1B+1C pairing was effective — different file sets, no merge conflicts, both pairs completed within minutes.

5. **Documentation cleanup was part of the implementation plan.** The 4-agent context doc sweep (specs, skills, agents, context docs) identified 2 deletions and 8 updates needed. This prevented stale references from surviving the code cleanup.

---

## Cross-Session Patterns

### Research-Only T3 Tasks

Sessions 1 and 3 both used the full T3 pipeline but only completed the research step. In both cases, the user explicitly truncated the pipeline ("Let's pivot, close with finding" / "I actually just want this workflow to have been this research step"). This suggests a need for a lighter "research sprint" command that doesn't scaffold 7 steps for what ends up being 1 step.

### Agent Permission Failures

Sessions 1, 2, and 3 all experienced agent permission failures — MCP tool permissions (Notion), bash permissions (JSONL parsing), and Notion API pagination. Sub-agents consistently struggle with tools that require interactive approval or have complex API pagination. Workaround: the assistant retries in the main thread.

### Gate Enforcement is Human-Dependent

Session 2's step skip (plan -> implement without approval) was caught by the user, not the harness. The harness tracks state but doesn't enforce gates — the assistant can bypass them. The "prompts = 65% reliable" statistic from the harness docs is validated here.

### Terse User Interaction During Implementation

Across all 4 sessions, user messages during implementation are overwhelmingly short: "Proceed," "Looks good to me," "Yes," "Continue." The detailed interaction happens during research review and plan approval. Once implementation starts, the user trusts the plan and delegates.

### Post-Completion Modifications

Sessions 1 and 3 both had post-archive work (Session 1: scope correction discussion; Session 3: added memory research to archived task). The archive boundary is porous — users treat completed tasks as living documents they can append to.

### Parallel Agent Research is Reliable

The parallel research pattern (3-5 agents launched simultaneously) worked well in all sessions. Completion times were consistent (2-7 minutes for all agents to return). The pattern is: launch agents -> collect results -> synthesize -> review. This is the harness's strongest automated workflow.

### Implementation Agents Need Cleanup

Session 4 showed that implementation agents produce code with ~90% accuracy — missing imports, stale references, mismatched signatures. The main thread always needs a compilation-verification-fix cycle after agent implementation. This is expected and manageable but should be documented as a known pattern.

### Command Surface Friction

Session 2's three-invocation cascade (`/work-deep` -> `/work-deep task-name` -> `/work-feature task-name`) reveals friction in the command surface. When an existing task exists at a different tier than the invoked command, the user has to navigate pushback messages and re-invoke. A unified `/work resume` command might reduce this friction.
