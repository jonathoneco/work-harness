# Research Handoff: Harness Enforcement

## What This Step Produced

Four research notes covering the full enforcement gap landscape:

1. **Hook gaps** — 3 of ~8 specified hooks deployed. Missing: step validation, artifact checks, finding triage, beads integration, findings protection.
2. **Command gaps** — `/work-checkpoint --step-end` doesn't validate artifacts before advancing. `/work-archive` doesn't verify review actually ran.
3. **Enforcement mechanisms** — 3 reliability tiers identified. Hooks (deterministic, ~95-99% reliable) >> commands (prompt-based, ~70%) >> skills (knowledge injection, ~65%).
4. **Failure analysis** — Dev-env-silo showed progressive collapse: research→plan→spec transitions all lacked mechanical gates.

## Key Findings

### The Core Problem
The harness's 3-layer defense is incomplete:
- **Layer 1 (hooks):** Partially deployed — anti-pattern grep and beads-check work, but no step/artifact/review validation hooks exist
- **Layer 2 (skills):** Working as designed — propagates knowledge but cannot enforce behavior
- **Layer 3 (review gate):** Missing mechanical verification — no way to distinguish "review ran, found 0 issues" from "review never ran"

### What Must Be Built
Four categories of enforcement, in priority order:

1. **State mutation validation** (PostToolUse hook on state.json writes) — Validate step machine invariants: current_step in steps array, only one active step, timestamps present, no backwards transitions
2. **Artifact existence gates** (Stop hook) — Block session end if Tier 3 step marked "completed" without required handoff-prompt.md
3. **Review verification gate** (Stop hook + archive command enhancement) — Block archive without review evidence (findings.jsonl entries or explicit reviewed_at timestamp)
4. **Findings protection** (PreToolUse hook) — Block edits to findings.jsonl (only allow appends)

### Design Constraints
- Hooks receive JSON context with `cwd` and can access filesystem, git, beads
- Hooks can only block (exit 2) or allow (exit 0) — cannot modify tool arguments
- Global hooks must defer to project-level hooks if present
- Multiple stop hooks compose independently — any exit 2 blocks
- Hooks must be deterministic (no LLM analysis)

## Decisions Made
- Enforcement should be hook-based (deterministic), not prompt-based (bypassable)
- Commands remain the user-facing API but hooks validate their post-conditions
- The skill layer stays knowledge-only — don't try to make skills enforce

## Open Questions for Planning
1. Should state mutation validation run on PostToolUse (after write) or PreToolUse (before write)? PostToolUse can read the written content; PreToolUse can only see the tool arguments.
2. Should artifact gates be blocking (exit 2) or warning (exit 0 + stderr)? Blocking is safer but may frustrate during experimentation.
3. How to handle the "review ran, found 0 issues" case — add a `reviewed_at` field to state.json, or require an empty findings entry?
4. Should these hooks live globally (~/.claude/hooks/) or project-level (.claude/hooks/)? Project-level allows per-project customization.
5. What about the work-check.sh timestamp comparison bug — fix it as part of this work or separate issue?

## Artifacts and Paths
- Research notes: `.work/harness-enforcement/research/`
- Spec source: `docs/feature/work-harness-v2/09-hook-infrastructure.md`
- Existing hooks: `.claude/hooks/{beads-check,review-gate,work-check}.sh`
- State model spec: `docs/feature/work-harness-v2/01-state-model.md`

## Instructions for Plan Step
Synthesize the 4 enforcement categories into an architecture document at `docs/feature/harness-enforcement/architecture.md`. Define:
- Component map (which hooks, which commands to enhance)
- Hook trigger events (PreToolUse vs PostToolUse vs Stop)
- Blocking vs warning behavior per hook
- Testing strategy (how to verify hooks work)
- Migration plan (how to deploy without breaking existing workflows)
