# Enforcement Mechanisms — Feasibility Analysis

## Reliability Tiers

### Tier 1: Deterministic (Cannot Bypass) — HOOKS

| Mechanism | Reliability | Cost | Description |
|-----------|-------------|------|-------------|
| PreToolUse file blocking | 99% | LOW | Block specific file edits before execution. Already proven (.env blocking). |
| Stop hooks on git state | 98% | LOW | Block session end on staged changes. Already deployed (beads-check.sh). |
| Stop hooks on diff patterns | 95% | LOW | Block session end on anti-patterns. Already deployed (review-gate.sh). |
| PostToolUse state validation | 92% | MED | Validate state.json after every Write. Parse with jq, check invariants. |

### Tier 2: Strong (Hard to Bypass) — COMMAND + HOOK PAIRS

| Mechanism | Reliability | Cost | Description |
|-----------|-------------|------|-------------|
| Command post-condition + hook verification | 90% | MED | Command generates artifact, hook verifies it exists before allowing advancement |
| Artifact existence gates | 88% | MED | Hook checks file exists before allowing state transition |
| Step lifecycle validation | 90% | MED | Hook enforces not_started → active → completed ordering |

### Tier 3: Weak (Easy to Bypass) — PROMPTS ONLY

| Mechanism | Reliability | Cost | Description |
|-----------|-------------|------|-------------|
| Command-level validation | 70% | LOW | "You MUST do X before Y" in prompt. LLM may skip. |
| Skill injection | 65% | LOW | Anti-patterns propagated but not enforced. |

## Hook Capabilities

**Can do:**
- Block tool execution (PreToolUse) or session end (Stop) via exit code 2
- Parse JSON with jq
- Read/search files (grep, find, cat)
- Run git and beads commands
- Pattern match with regex
- Provide error messages to stderr

**Cannot do:**
- Modify tool arguments (read-only inspection)
- Parse AST (must use text patterns)
- Run LLM analysis (must be deterministic)
- Access model/agent internal state

## Implementation Patterns

### Pattern: State Mutation Guard (PostToolUse on Write)
```bash
# Trigger: PostToolUse when file_path matches .work/*/state.json
# Validate: current_step in steps array, only one active step, timestamps present
```

### Pattern: Artifact Existence Gate (Stop hook)
```bash
# Before session end: check if state.json step is "completed" but handoff missing
# For each completed T3 step in [research, plan, spec, decompose]:
#   verify .work/<name>/<step>/handoff-prompt.md exists
```

### Pattern: Review Verification Gate (embedded in /work-archive command)
```bash
# For T2-3: check .work/<name>/review/findings.jsonl has entries with task_name=<name>
# OR state.json has reviewed_at timestamp
```

## Recommendation

**Deploy new hooks at Tier 1 level** (deterministic, cannot bypass). Don't rely on command prompts for enforcement — back them with hooks.

Priority order:
1. State mutation validation (PostToolUse) — prevents state corruption
2. Artifact existence gate (Stop) — prevents missing handoffs
3. Review verification (Stop + archive command) — prevents skipped review
4. Findings protection (PreToolUse) — prevents finding deletion
