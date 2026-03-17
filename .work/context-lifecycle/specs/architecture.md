# Architecture: Context Document Lifecycle Management

## Problem Statement

Context documents (skills, rules, commands) accumulate stale references as the project evolves. The HTMX checklist surviving in `code-quality` months after HTMX deprecation is the canonical example. Additionally, when users say "proceed" instead of re-invoking work commands at step gates, the agent operates with degraded instruction fidelity due to the "Lost in the Middle" effect — instructions loaded mid-session drift to the low-attention middle zone of the context window.

### Goals

1. **Self-re-invocation**: Work commands mechanically re-place themselves at the end of the context window at step gates and after compaction
2. **Archive-time housekeeping**: When archiving a task, scan all skills/rules for staleness and propagate new patterns
3. **Project-level tech manifest**: Project declares technology dependencies for context documents, enabling automated staleness detection without modifying portable dotfiles skills
4. **Deprecated table diffing**: Detect when skills reference newly deprecated technologies
5. **Gate approval re-confirmation**: Fix the bug where answering follow-up questions or presenting results at gates is treated as approval (rag-idnu7)

### Non-Goals

- Automatic skill content rewriting (human reviews staleness reports)
- Session-start freshness scans (archive-time is the primary trigger; session-start is deferred as a future)
- Changes to CLAUDE.md loading behavior (compaction-survivor behavior is a platform feature)
- Periodic/scheduled staleness checks (the harness owns freshness at natural trigger points)
- Modifying dotfiles skill frontmatter (skills must remain project-agnostic and portable)

---

## Component Map

### C1: Project-Level Tech Manifest
**Scope**: Small | **Files**: New `.claude/tech-deps.yml`

Create a project-level YAML manifest that maps context documents (skills, rules, commands) to their technology dependencies. This keeps skills in dotfiles portable and project-agnostic while letting each project declare its own constraints.

**Design rationale**: Skills live in `~/src/dotfiles/home/.claude/skills/` (portable across projects), while commands and rules live in the project repo (shared with teammates). Adding `tech_deps` to skill frontmatter would impose project-specific constraints on portable skills. Instead, the PROJECT declares the mapping.

**Manifest format** (`.claude/tech-deps.yml`):
```yaml
# Technology dependencies for context documents.
# Used by archive-time housekeeping to detect stale references.
# Keys are document identifiers; values list technology names
# matching the "Deprecated" column in beads-workflow.md.

skills:
  code-quality:
    deps: [go, htmx, postgresql]
    references:
      - go-anti-patterns.md
      - htmx-checklist.md
  work-harness:
    deps: [beads]

rules:
  beads-workflow:
    deps: [workos, textract, tailwind-css]
  code-quality:
    deps: [go]

commands:
  work-deep:
    deps: []
  work-archive:
    deps: []
```

**Schema**:
- Top-level keys: `skills`, `rules`, `commands` — document categories
- Each entry: document name → `deps` (list of technology identifiers) + optional `references` (sub-files to scan)
- Technology identifiers are case-insensitive and match the "Deprecated" column in the deprecated approaches table
- The manifest is committed to the project repo — teammates benefit automatically

**Maintenance**: The manifest is checked and updated during archive-time housekeeping (C4). If the scan finds references not covered by the manifest, it flags them.

**Dependencies**: None (foundational)

---

### C2: Self-Re-Invocation at Step Gates
**Scope**: Medium | **Files**: `work-deep.md`, `work-feature.md`, `work-fix.md`

Modify work commands so that step transitions re-invoke the command via `Skill()` rather than continuing inline. This places the full command instructions at the END of the context window — the highest-attention zone per the "Lost in the Middle" research.

**Current behavior** (when user says "proceed"):
```
[Gate summary] → user: "proceed" → agent continues inline with stale mid-context instructions
```

**New behavior**:
```
[Gate summary] → user: "proceed" → Skill("work-deep") → fresh instructions at context end
```

**Implementation approach**:
Each work command's Inter-Step Quality Review Protocol already says: "tell the user to run `/compact` then `/work-deep`". The change adds a fallback for when the user doesn't compact:

1. After user approval at a gate, if the user says "proceed" / "continue" / "yes" (without explicitly invoking a command):
   - The command text instructs: "Re-invoke yourself via `Skill('work-deep')` to ensure fresh instruction placement"
   - This is a PROMPT instruction (not mechanical) — the PostCompact hook (C3) provides the mechanical backup

2. At step boundary handoff prompts, add explicit re-invocation reminder:
   - "If continuing without compaction, the agent MUST call `Skill('work-deep')` before proceeding to the next step"

**Why prompt + mechanical**: The prompt instruction handles the common case (user says "proceed"). The PostCompact hook handles the compaction case. Together they cover both paths.

**Dependencies**: None (parallel with C1, C3)

---

### C3: PostCompact Hook
**Scope**: Small | **Files**: `.claude/settings.json` (hooks section), new script file

A PostCompact hook that mechanically injects a re-grounding reminder after context compaction. This is HOOK-DRIVEN (deterministic, fires every time) rather than PROMPT-DRIVEN (best-effort, subject to drift).

**Hook configuration** (in `.claude/settings.json`):
```json
{
  "hooks": {
    "PostCompact": [
      {
        "matcher": "auto",
        "command": "scripts/hooks/post-compact.sh"
      }
    ]
  }
}
```

**Hook script behavior**:
1. Check for active task: scan `.work/*/state.json` for `archived_at: null`
2. If active task found:
   - Read `tier` to determine which command to suggest
   - Output: `"Active task: <name> (step: <current_step>). Run /work-deep to re-ground."`
3. If no active task: output nothing (silent — correct behavior, not a fallback)

**Design choice**: The hook outputs a SUGGESTION, not an automatic `Skill()` call. PostCompact hooks inject system messages — they don't execute skills. The message primes the agent to re-invoke, which is reliable because it appears at the END of context (post-compaction position = highest attention).

**Dependencies**: None (parallel with C1, C2)

---

### C4: Archive-Time Housekeeping
**Scope**: Medium | **Files**: `work-archive.md`, new script or inline logic

Extend the archive process with a staleness scan of all skills and rules. This makes the harness the "owner" of document freshness — archive time is the natural trigger point.

**Current archive process** (from work-archive.md):
1. Verify completion criteria
2. Generate summary
3. Promote futures
4. Close beads epic
5. Set `archived_at`

**New archive process** (additions in bold):
1. Verify completion criteria
2. Generate summary
3. Promote futures
4. **Deprecated table diff** (sub-component)
5. **Staleness scan** (using tech manifest + content grep)
6. **Staleness report + beads issues**
7. Close beads epic
8. Set `archived_at`

**Sub-component: Deprecated Table Diff**
1. `git diff <base_commit>...HEAD -- .claude/rules/beads-workflow.md` (or wherever the deprecated table lives)
2. Parse the diff for new rows in the "Deprecated Approaches" table
3. If new deprecated entries found: pass them to the staleness scan as "newly deprecated" items

**Staleness scan algorithm**:
1. Read `.claude/tech-deps.yml` (the project tech manifest from C1)
2. Read the current deprecated approaches table from `beads-workflow.md`
3. For each entry in the manifest:
   a. Check each declared `dep` against the deprecated table
   b. If match found: flag the document as having a stale declared dependency
4. For newly deprecated items (from the diff):
   a. Grep all context document content (skills, rules, commands, reference files) for the deprecated technology name
   b. Flag any matches (catches references not declared in the manifest)
5. Check manifest completeness: if grep finds references not covered by manifest `deps`, flag the manifest as needing an update
6. Produce a staleness report:
   - List of stale documents with specific deprecated references
   - Manifest gaps (references found by grep but not declared in manifest)
   - Suggested action per finding (remove references, update manifest, rewrite section)
7. For each stale finding: create a beads issue tagged `[Housekeeping]`

**Scope**: Scan ALL skills and rules, not just task-relevant ones. The set is small (currently ~4 skills, ~5 rule files, ~12 command files, ~8 reference files) — cheap and deterministic.

**Error handling**: If the staleness scan fails (YAML parse error, git diff failure, missing manifest, etc.), the archive process must STOP — do not silently skip the scan and continue to close the epic. Fail closed: fix the scan error before completing the archive.

**Dependencies**: C1 (needs tech manifest to exist)

---

### C5: Gate Approval Re-Confirmation (Bug Fix)
**Scope**: Small–Medium | **Files**: `work-deep.md`, `work-feature.md`, `work-fix.md`

Fix ALL state transitions to require explicit user approval before updating state.json. Two observed failure modes:

1. **Discussion-as-approval** (rag-idnu7): Agent answers follow-up questions at a step gate, then immediately advances state without re-confirming. Observed during context-lifecycle research→plan transition.
2. **Presentation-as-approval**: Agent presents review results and immediately marks the step completed without waiting for user response. Observed during wf1-cleanup review step — review results were presented and `state.json` was updated to `review: completed` in the same turn.

**Root cause**: The protocol says "STOP and wait for user acknowledgment" but the instruction is prompt-driven and degrades under context pressure. The agent treats its own output (presenting results) as sufficient, or interprets any user response as approval.

**Current protocol** (abbreviated):
```
e. Present detailed summary to user
f. STOP — wait for user acknowledgment
g. On user approval: create gate issue, update state.json
```

**Fixed protocol**:
```
e. Present detailed summary to user
f. STOP — wait for user acknowledgment. Do NOT update state.json in the same turn as presenting results.
f'. If the user asks follow-up questions or provides feedback:
    answer the questions, then re-present a brief confirmation:
    "Ready to advance to <next-step>? (yes/no)"
    Wait for explicit affirmative before proceeding.
g. On EXPLICIT user approval (not just Q&A, not just presenting results):
   create gate issue, update state.json
```

**Key principles**:
- Answering questions ≠ approval
- Presenting results ≠ approval
- The ONLY valid approval signals: explicit "yes", "proceed", "approve", "looks good", or similar affirmative in a user message AFTER results have been presented
- State updates and result presentation must NEVER occur in the same agent turn

**Dependencies**: None (parallel with all other components)

---

## Data Flow

```
                    ┌─────────────────────┐
                    │   Step Gate          │
                    │   (user: "proceed")  │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  C2: Self-Re-Invoke │
                    │  Skill("work-deep") │
                    │  → fresh instrs     │
                    └─────────────────────┘

                    ┌─────────────────────┐
                    │  /compact           │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  C3: PostCompact    │
                    │  hook → "re-invoke" │
                    │  system message     │
                    └─────────────────────┘

                    ┌─────────────────────┐
                    │  /work-archive      │
                    └──────────┬──────────┘
                               │
              ┌────────────────▼────────────────┐
              │  C4: Archive Housekeeping       │
              │                                 │
              │  ┌───────────────────────────┐  │
              │  │ Deprecated table diff     │  │
              │  │ (git diff base..HEAD)     │  │
              │  └─────────────┬─────────────┘  │
              │                │                │
              │  ┌─────────────▼─────────────┐  │
              │  │ Staleness scan            │  │
              │  │ manifest (C1) ←→ depr.    │  │
              │  │ + content grep for new    │  │
              │  └─────────────┬─────────────┘  │
              │                │                │
              │  ┌─────────────▼─────────────┐  │
              │  │ Report + beads issues     │  │
              │  │ Manifest gap detection    │  │
              │  └───────────────────────────┘  │
              └─────────────────────────────────┘
```

---

## Technology Choices

| Choice | Rationale |
|--------|-----------|
| Project-level YAML manifest (not skill frontmatter) | Skills live in dotfiles (portable); project owns its constraints. Teammates get the manifest in the repo. |
| Shell script for PostCompact hook | Hooks require shell commands; POSIX sh for portability per project conventions |
| Prompt instructions for self-re-invocation | Skill() API is the existing mechanism; no new infrastructure needed |
| git diff for deprecated table detection | Deterministic, uses base_commit already stored in state.json |
| Beads issues for staleness findings | Consistent with project workflow; issues are tracked and closeable |
| Scan all documents (not just task-relevant) | Set is small (~30 files); selective scanning adds complexity without meaningful savings |

---

## Cross-Repo Design

Context documents span two repositories:

| Location | Contents | Owned By |
|----------|----------|----------|
| `~/src/dotfiles/home/.claude/skills/` | Skill SKILL.md files + reference docs (go-anti-patterns.md, htmx-checklist.md, etc.) | User (portable) |
| `<project>/.claude/commands/` | Work commands (work-deep.md, work-archive.md, etc.) | Project (shared with team) |
| `<project>/.claude/rules/` | Rule files (architecture-decisions.md, beads-workflow.md, etc.) | Project (shared with team) |
| `<project>/.claude/tech-deps.yml` | Tech manifest (NEW) | Project (shared with team) |

**Key principle**: The manifest lives in the project. Skills live in dotfiles. The manifest references skills by name (not path) — the archive scan resolves skill locations at runtime via Claude Code's skill loading paths.

**Implication**: The archive scan must traverse both `~/.claude/skills/` AND `.claude/rules/` + `.claude/commands/` to find all documents referenced in the manifest. The spec step should define exact glob patterns.

---

## Open Questions Resolved

| # | Question | Resolution |
|---|----------|------------|
| 1 | Skill() vs PostCompact vs both? | Both — Skill() for step gates, PostCompact hook for compaction recovery |
| 2 | Archive scope: all skills or task-relevant? | All — set is small, cheap, deterministic |
| 3 | Extra frontmatter beyond tech_deps? | No — `freshness_class` and `last_reviewed` deferred to futures (premature, no consumer) |
| 4 | Deprecated diffing trigger? | Archive-time primary; session-start deferred as future |
| 5 | Resolve cleanup issues first? | Yes — rag-e690r, rag-odxhb, rag-vzsgp before implementing |
| 6 | PostCompact hook feasibility? | Confirmed — supported hook event with auto/manual matchers |
| 7 | Archive scan error handling? | Fail closed — scan errors block archive completion |
| 8 | Cross-repo skill scanning? | Project-level tech manifest (approach B) — skills stay in dotfiles, project declares deps |

---

## Questions Deferred to Spec

1. **Tech manifest identifier format**: How do technology identifiers in the manifest map to deprecated table entries? Case normalization? Exact match or substring?
2. **Self-re-invocation prompt wording**: Exact wording in work commands for the "re-invoke via Skill()" instruction. Must avoid "CRITICAL/MUST" aggressive language (research finding: Claude 4.6+ responds better to normal language).
3. **PostCompact hook script details**: Error handling, output format, edge cases (multiple active tasks, no active task)
4. **Staleness report format**: Structured output? Markdown table? JSONL?
5. **Skill location resolution**: Exact glob patterns for finding skill files referenced in the manifest. How to handle skills that exist in dotfiles but not in the project.
6. **Interaction between cleanup issues and this initiative**: Should rag-e690r, rag-odxhb, rag-vzsgp be resolved as Phase 0 of this implementation or as prerequisites?
7. **Manifest bootstrapping**: How to generate the initial manifest for an existing project. Manual? Semi-automated scan?

---

## Dependency Graph

```
Phase 1 (parallel, no inter-dependencies):
  C1: Project-Level Tech Manifest
  C2: Self-Re-Invocation at Step Gates
  C3: PostCompact Hook
  C5: Gate Approval Re-Confirmation

Phase 2 (depends on C1):
  C4: Archive-Time Housekeeping
      (includes deprecated table diffing as sub-component)
```

**Critical path**: C1 → C4 (manifest must exist before archive can scan against it)

All Phase 1 components can be implemented in parallel by separate agents. Phase 2 requires C1's schema to be finalized.

---

## Scope Exclusions

- **No changes to CLAUDE.md loading**: Compaction-survivor behavior is a Claude Code platform feature, not ours to modify
- **No session-start freshness scans**: Deferred as future — archive-time is sufficient for now
- **No automatic content rewriting**: The scan produces reports and issues; humans decide what to change
- **No changes to Serena/MCP integration**: These tools are orthogonal to document lifecycle
- **No changes to beads workflow**: beads-workflow.md is a consumer (deprecated table), not a component of this system
- **No modification of dotfiles skill frontmatter**: Skills must remain project-agnostic and portable across repositories

## Deferred to Futures

- `freshness_class` field on documents (premature — all documents scanned identically at archive time; differentiation only matters with session-start or periodic scans, both non-goals)
- `last_reviewed` field on documents (no consumer in current architecture; git history tracks modifications)
- Session-start staleness warnings (optional, lower priority than archive-time)
