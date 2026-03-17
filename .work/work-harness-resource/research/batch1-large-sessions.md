# Batch 1: Large Session Analysis

Two high-volume sessions from the gaucho-service-refactor worktree, analyzed for work harness usage patterns, human intervention, and failure modes.

---

## Session 1: 7f1fa079 — Harness Modularization

### A. Session Profile

- **Task**: harness-modularization (Tier 3) — extract the workflow harness into a standalone repo (`claude-work-harness`)
- **Period**: 2026-03-16T22:41 to 2026-03-17T09:06 (~10.4 hours wall time)
- **Messages**: 78 user, 175 assistant
- **Tool usage**: Bash 180, Read 57, Agent 47, Write 44, Edit 39, Grep 6, Glob 5, Skill 2
- **Compactions**: 0 (but session was continued via `/compact` externally 5+ times, visible as "This session is being continued from a previous conversation" messages)

**Harness commands used (in order):**
1. `/work` (interrupted immediately by user)
2. `/work` (second attempt, also user-interrupted quickly)
3. `/work-deep harness-modularization` — initial invocation that stuck
4. `/work-deep` — resume at plan (post-compact)
5. `/work-deep` — resume at spec (post-compact)
6. `/work-deep` — resume at decompose (post-compact)
7. `/work-deep` — resume at implement (interrupted, re-invoked)
8. `/work-deep` — resume at implement (successful)
9. No explicit `/work-checkpoint` or `/work-archive` — archiving was done inline during ad-hoc cleanup

**Agent usage**: 47 agent calls total. Heavy parallel usage throughout:
- Research: 6 parallel agents (gaucho-inventory, dotfiles-inventory, diff, history, hardcoded-audit, settings-analysis)
- Supplemental research: 3 parallel agents (agency-agents, runtime-selection, harness-init-scope)
- Spec writing: 4 parallel agents (one per phase group)
- Implementation: 3 phases, each with parallel agents for streams
- Quality reviews: Phase A + Phase B always launched in parallel
- All gate reviews used the parallel A+B pattern

### B. Human Intervention Patterns

**Early interruptions (scope framing)**:
- User interrupted twice within the first 90 seconds, refining the `/work` invocation with progressively more detailed descriptions. First was bare, second added "inventory harness files across gaucho/.claude/ and dotfiles/home/.claude/, classify general vs project-specific, diff for divergence, audit hard-coded Go/HTMX references, enumerate development history from beads/git/archived .work/ tasks, read workflow-meta skill, document config schema." Third switched to `/work-deep` explicitly.
- Pattern: User front-loads detailed scope into the command invocation itself rather than letting the agent discover scope.

**Scope corrections during research**:
- After research summary, user answered 7 open questions with detailed inline decisions (lines 322-332).
- User pushed back significantly on the "copy at install" model: "if we're installing to the global claude config we can't selectively copy per project's stack, the project needs to declare the stack in a way that informs which agents / rules are used not which are copied." This forced 3 supplemental research agents.
- One supplemental agent's conclusion directly contradicted the user's direction (proposed copying files to project `.claude/` instead of runtime selection). The assistant caught this and noted "I'll reconcile this in the updated research notes."

**Philosophy declarations**:
- "I want to be careful / intentional about context passing and quality of outputs (i.e. there was a time where we weren't passing rules to reference to subagents and that caused issues as they're not loaded automatically)"
- "I like the idea of injecting configs into subagent prompts as well as handoff prompts"
- "I'd like to leverage agency agents (currently cloned at ~/src/agency-agents)"

**Gate interactions**:
- research -> plan: "yes" (after answering open questions and getting architecture model right)
- plan -> spec: "yes"
- spec -> decompose: "yes"
- decompose -> implement: User first said "Let's address the advisory notes" then immediately interrupted and just said "yes"
- Phase 1 gate: "yes"
- Phase 2 gate: "yes" (after ~4 hour gap)
- Phase 3 gate: User explicitly requested addressing advisory notes before advancing
- implement -> review: "yes"

**Scope expansion in late session**:
- After implement/review, user asked for: (1) repo setup at ~/src/work-harness with GitHub private repo, (2) cleanup overlapping files in dotfiles and gaucho, (3) agent overlap audit against agency-agents, (4) move adversarial-eval and ama commands into harness, (5) dev-env skill analysis, (6) move pr-prep command, (7) move harness-scoped .work/ directories
- Then asked about futures folder, then about PostCompact hook recovery
- Pattern: The "review" step became a long ad-hoc cleanup/deployment session that went well beyond what the harness step defines.

**Accidental interrupt**: "Didn't mean to interrupt, continue" (line 1326) — user accidentally hit Ctrl-C during file operations.

### C. Harness Interaction Patterns

**Invocation sequence**: `/work-deep` was called 8 times across the session. Each follows the pattern: `/compact` externally -> new conversation continuation summary -> `/work-deep` invoked -> state detected -> step resumed via handoff prompt.

**Multiple active tasks complexity**: The session started with 3 existing active tasks (service-refactor, wf2-data-model, work-harness-resource). The assistant had to ask which task to work on, and the user said "create a 4th active task." This caused the assistant to ask again on each `/work-deep` resume which Tier 3 task to pick up.

**Duplicate gate issue**: When advancing research -> plan, the user interrupted mid-transition, then re-confirmed. This created two beads gate issues (`rag-uyet2` and `rag-vc3tf`). User caught it: "We may have created two gate issues for this, might have to dedup." Assistant found and closed the duplicate.

**Review gate hook noise**: The stop hook `review-gate.sh` fired 3 times on pre-existing unstaged changes from other tasks in the worktree. The assistant correctly identified these as noise ("Hook is re-firing on pre-existing branch changes") but the user still had to dismiss them.

**Context recovery via compact**: No in-session compactions, but 5+ external `/compact` -> continuation cycles. Each continuation included a conversation summary that was sufficient for the assistant to re-orient. The handoff prompts in `.work/` were the primary recovery mechanism — the assistant always read the handoff prompt first, not the individual research/spec artifacts.

**Step cadence**: research (~25 min active) -> plan (~15 min) -> spec (~25 min) -> decompose (~15 min) -> implement (~5.5 hours including a 4-hour gap between Phase 2 gate approval and Phase 3 start)

### D. Anti-patterns & Failures

**Stow symlink collision**: The harness install.sh wrote files to `~/.claude/` which was stow-managed (symlinks to dotfiles repo). When `git add home/.claude/agents/` was run in dotfiles, it picked up harness files that existed through stow symlinks. Required a corrective commit. The assistant caught it but only after the bad commit was made: "Wait -- I see something wrong in the dotfiles commit."

**yq blocking all hooks**: During the audit phase, the assistant discovered that `config.sh` exits with code 2 when yq is missing, and every hook sources `config.sh`. This meant all 7 hooks were broken in environments without yq. This was a bug in the implemented harness that passed all prior quality reviews. The Phase B reviews during implementation did not catch this because they tested in an environment where yq was available.

**Agent contradicting user direction**: One supplemental research agent proposed copying files to project `.claude/` — the opposite of what the user explicitly requested. The assistant caught this but it wasted agent capacity and could have been prevented by passing the user's stated preference to the agent prompt.

**Late-session scope creep**: The review step morphed into a deployment + cleanup + audit session. None of this was tracked by the harness step state. The work items were closed, but the actual review step deliverables (per the harness spec) were never produced.

**Review gate false positives**: The stop hook fired on pre-existing unstaged changes from other tasks, creating noise on every response. No way to scope the hook to only current-session changes.

### E. Positive Patterns

**Parallel agent execution**: Consistently effective. The 6-agent research sprint completed in ~2 minutes. The 4-agent spec writing sprint completed in ~8 minutes. The parallel Phase A+B review pattern caught issues efficiently.

**Quality reviews catching real issues**: Phase B spec review found 2 blocking issues (file_invites schema redesign, analysis_results FK ambiguity in session 2, and POSIX arithmetic + function signature mismatch in this session). These were fixed before presenting to the user.

**Handoff prompts as recovery mechanism**: Each compact/resume cycle was smooth because the assistant read the handoff prompt first and never re-read raw research notes. The handoff prompt served as the "firewall" described in the rules.

**User-driven advisory resolution**: When the user asked to address advisory notes from Phase 2 and Phase 3 reviews, the assistant made 8 targeted fixes including a round-trip test of install.sh. The user's instinct to fix advisories before advancing prevented technical debt from accumulating.

**Clean beads integration**: Every step got a beads issue. Work items had beads issues with proper dependencies. The `bd ready` pattern was used to find next work. Duplicate gate issue was caught and cleaned up.

**Institutional knowledge mining**: The harness-history agent successfully traced the 4-phase evolution of the harness from closed beads issues and git history, providing context that informed the architecture.

---

## Session 2: ef544af8 — WF2: Data Model & Language Unification

### A. Session Profile

- **Task**: wf2-data-model (Tier 3) — rename entities across entire codebase: `loan` -> `file`, `applicant` -> `borrower`, old `borrower` -> `file`
- **Period**: 2026-03-16T01:41 to 2026-03-16T08:18 (~6.6 hours wall time)
- **Messages**: 43 user, 91 assistant
- **Tool usage**: Bash 51, Agent 50, Write 42, Read 16, Edit 11, Skill 4, ToolSearch 2, Serena 2, Glob 1
- **Compactions**: 0 (but 3 external compact cycles visible)

**Harness commands used (in order):**
1. `/work-deep` — initial invocation (agent executed steps manually instead of invoking skill)
2. User correction: "stop, clean all this up, you should have called the work-deep command explicitly"
3. `/work-deep` — re-invocation (properly via skill this time)
4. `/work-deep` — resume at plan (post-compact)
5. `/work-deep` — resume at spec (post-compact), with `/serena-activate`
6. `/work-deep` — resume at decompose (post-compact)
7. `/work-deep` — resume at implement (post-compact), with `/serena-activate`
8. `/work-checkpoint` — explicit checkpoint save at end

**Agent usage**: 50 agent calls — the highest ratio of agents to user messages (1.16:1):
- Research: 3 parallel agents initially, then 5 parallel agents for open question investigation during spec
- Spec writing: main thread wrote specs directly (not delegated)
- Quality reviews: Always parallel Phase A + Phase B
- Implementation: 1 agent for Phase 1 (W-01+W-02 combined), stopped by user before changes

### B. Human Intervention Patterns

**Critical correction — skill invocation**:
- First `/work-deep` invocation: the assistant executed steps manually (assessment, state init, research agents) without invoking the skill command. The user interrupted and explicitly corrected: "stop, clean all this up, you should have called the work-deep command explicitly"
- The assistant cleaned up the manually-created state and re-invoked properly.
- Pattern: The assistant tried to be "helpful" by doing the work itself rather than following the prescribed command flow.

**Decision gate — open questions**:
- After research summary, user said "Expand on the open questions before we advance." This was a hold on the gate — the user wanted deeper answers before proceeding.
- The assistant expanded all 12 questions with evidence tables, code references, and specific recommendations.
- User responded with detailed inline decisions for each question (Q1 through Q12), using a structured format with the question text followed by indented answers.
- The assistant then captured decisions and launched parallel deep-dive agents on areas flagged for more investigation.

**Session interruption and resumption**:
- At 02:56, user interrupted "for tool use" (likely switching to another terminal/tool).
- 1.5 hours later (04:18), user re-pasted the same decision block. The assistant recognized it as a continuation and picked up where it left off.
- At 05:26, user said "Continue from where you left off" after another gap. Assistant recovered context and continued deep dives.

**Adversarial evaluation invocation**:
- User invoked `/adversarial-eval` to stress-test the decision about whether to restructure 4 domain-specific tables or just rename them.
- Both advocates (Ship-It vs Do-It-Right) returned structured arguments.
- Synthesis produced a per-table verdict. User approved: "This verdict looks good to me, let's make sure we document the wf3 deferred research and work."

**Temporary file for asynchronous decisions**:
- User asked: "Write this to a temporary file for me to respond to"
- Assistant wrote expanded questions to `/tmp/wf2-open-questions.md`
- User edited answers in the file offline and came back: "I added my answers in there"
- Pattern: User preferred editing decisions in their own editor rather than inline in the chat.

**User stopped implementation agent**:
- Phase 1 implementation agent (schema + seed migrations) was stopped by user before it made any changes.
- User then invoked `/work-checkpoint` to save progress.
- Pattern: User recognized the session was getting long and chose to checkpoint rather than continue.

**Gate approvals**: All "yes" responses — no pushback on step transitions themselves (pushback happened within steps, on open questions and advisory items).

### C. Harness Interaction Patterns

**Skill invocation failure and recovery**: The first `/work-deep` was not properly invoked as a skill. The assistant manually executed assessment + state init + research. User caught this and forced a restart. The assistant cleaned up the manual artifacts and re-ran correctly. This wasted ~15 minutes.

**External compact cadence**: The session shows a clear rhythm:
1. Run step to completion
2. Assistant says "Run `/compact` then `/work-deep`"
3. Continuation summary appears
4. `/work-deep` re-invokes and resumes at next step

This happened for: research -> plan, plan -> spec, spec -> decompose, decompose -> implement. Each transition took 3-8 minutes of overhead.

**Serena activation**: `/serena-activate` was triggered twice — once during spec step and once during implement step. Both times it was auto-triggered (SessionStart hook) alongside the `/work-deep` invocation.

**Background agent notifications**: The session shows a distinctive pattern where 5 background agents complete one by one, with task-notification messages interleaved. The assistant processed each result incrementally, synthesizing findings as they arrived rather than waiting for all to complete. This gave the user real-time progress.

**Checkpoint usage**: Only explicit `/work-checkpoint` in either session. The assistant drafted a comprehensive checkpoint covering what was accomplished (spec + decompose + partial implement), files modified, and where to resume. User approved it with "looks good."

### D. Anti-patterns & Failures

**Manual execution instead of skill invocation**: The most significant failure. The assistant bypassed the harness command system and manually executed what the skill would do. This:
- Created state files outside the expected flow
- Required manual cleanup
- Wasted ~15 minutes
- Shows that the assistant's "helpfulness" instinct can override harness discipline

**"Continue" ambiguity after gap**: When user said "Continue from where you left off" after a 30-minute gap, the assistant needed to re-survey context because background agents had completed in the interim. The response was "No response requested" initially (line 215), requiring the user to say "Continue" again. This double-prompt pattern suggests the assistant was confused about whether the first "Continue" was a genuine request.

**Phase 1 agent too ambitious**: The implementation agent was launched to handle W-01 + W-02 combined (read 82 migration files, delete them, write new schema + seeds, run round-trip test). This was too large for a single agent and the user stopped it. The decompose step had separated these into 2 work items for a reason, but the assistant combined them "for efficiency."

**Local command caveat noise**: Multiple `<local-command-caveat>` messages appear (lines 246, 249, 348, 420, etc.) when the user ran local commands. These are metadata noise that the assistant correctly ignored, but they clutter the session flow.

### E. Positive Patterns

**Adversarial evaluation for contested decisions**: The `/adversarial-eval` skill was used to resolve a genuine design tension (rename-only vs restructure). Both sides were argued with specific evidence (table sizes, reference counts, retrofit time estimates). The synthesis produced nuanced per-table verdicts rather than a blanket decision. This prevented the "flip-flopping" problem described in the skill's docs.

**Incremental agent result processing**: As the 5 spec investigation agents completed asynchronously, the assistant processed and summarized each one immediately, giving running commentary on key findings and corrections to prior estimates. This kept the user informed without requiring them to read raw agent output.

**Phase B reviews catching blocking issues**: The spec quality review found 2 blocking issues (file_invites schema and analysis_results FK) that the main-thread spec writing had missed. The assistant fixed both before presenting the gate results. The user never had to deal with the flawed specs.

**Deferred futures documentation**: When the adversarial eval recommended deferring restructuring, the user immediately said "let's make sure we document the wf3 deferred research and work." This was captured in futures.md. The harness facilitated this through its futures artifact convention.

**Temporary file workflow for complex decisions**: The user's request to write questions to `/tmp/` for offline editing, then read them back, was a smooth interaction. It respected the user's preference for editing in their own tools rather than composing long structured responses in chat.

**Clean checkpoint**: The only explicit checkpoint in both sessions was well-structured, covering accomplishments, files modified, and resume instructions. The assistant followed the checkpoint protocol correctly.

---

## Cross-Session Patterns

### Shared Patterns

1. **Gate approval is almost always "yes"**: Pushback happens _within_ steps (on open questions, advisory items, architecture decisions), not at step transitions. The gates serve as natural pause points where the user reviews output quality, but the answer is consistently to advance.

2. **Advisory notes as quality lever**: In both sessions, Phase B quality reviews surfaced advisory notes that the user chose to address before advancing. This turned "advisory" items into de facto requirements. The harness's distinction between BLOCKING and ADVISORY is useful — blocking items get auto-fixed, advisory items get user judgment.

3. **Parallel agent pattern is dominant**: Both sessions relied heavily on launching 3-6 agents in parallel for research, investigation, and quality reviews. The parallel Phase A + Phase B review pattern was used at every gate in both sessions.

4. **External compact is the session boundary**: Neither session had internal compactions. Instead, the user ran `/compact` externally between steps, creating natural session boundaries. The `/work-deep` -> detect -> resume -> handoff-prompt chain worked reliably for recovery.

5. **Late-session scope expansion**: Both sessions expanded scope in their later phases. Session 1's review step became a deployment session. Session 2's user wanted to address all advisory notes before the checkpoint. Users treat active sessions as opportunities to get adjacent work done.

### Key Differences

| Dimension | Session 1 (Harness Modularization) | Session 2 (WF2 Data Model) |
|-----------|------------------------------------|-----------------------------|
| Duration | ~10.4 hours | ~6.6 hours |
| Steps completed | All 7 (research through review) | 5 of 7 (research through partial implement) |
| Agent count | 47 | 50 |
| User corrections | Scope/architecture corrections | Skill invocation correction |
| Decision complexity | 7 open questions + architecture model pushback | 12 open questions + adversarial evaluation |
| Primary failure mode | Stow symlink collision, yq blocking hooks | Manual skill execution, agent too ambitious |
| Checkpoint usage | None (archived inline) | Explicit `/work-checkpoint` at end |

### Recommendations for Usage Guide

1. **Document the skill invocation requirement**: Session 2's biggest failure was the assistant manually executing steps instead of invoking the skill. The guide should emphasize that `/work-deep` must be invoked as a skill, not manually replicated.

2. **Advisory resolution should be a documented pattern**: Both users consistently chose to fix advisory items. The guide should recommend addressing advisories before gate advancement as a best practice, not just an option.

3. **Warn about combined work items**: Session 2's Phase 1 agent combined W-01 + W-02 against the decomposition. The guide should note that decomposed work items should stay separate in implementation unless there's a documented reason to combine.

4. **Document the compact-resume cadence**: The reliable pattern is: complete step -> "Run /compact then /work-deep" -> user compacts -> resume. This should be the documented rhythm for multi-session work.

5. **Multiple active tasks need disambiguation**: Session 1's 4 active tasks caused repeated "which task?" questions. The guide should recommend keeping active task count low or naming tasks distinctively.

6. **Temporary files for complex decisions**: The pattern of writing questions to `/tmp/` for offline editing, then reading back, should be documented as a technique for complex decision gates.

7. **Quality reviews need environment diversity**: The yq bug passed all reviews because they ran in the same environment. The guide should recommend testing hooks in minimal environments as part of the review step.
