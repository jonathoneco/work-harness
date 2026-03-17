# Command Enforcement Audit

## Critical Gaps

### 1. `/work-checkpoint --step-end` — No Artifact Validation

**Should do:** Before marking step completed, verify `.work/<name>/<step>/handoff-prompt.md` exists on disk.

**Actually does:** Generates handoff prompt inline, presents for approval, advances state — but no file existence check between generation and advancement. If handoff generation fails silently, step still advances.

**Bypass:** Run `/work-checkpoint --step-end` → approve draft → handoff-prompt.md never written → state advances → next session has no handoff.

### 2. `/work-archive` — No Review Verification

**Should do:** Before archiving Tier 2-3 tasks, verify that `.work/<name>/review/findings.jsonl` exists AND has findings for this task (or explicitly confirm "review found no issues").

**Actually does:** Only checks finding triage status. If findings.jsonl doesn't exist (review never ran), gate passes silently.

**Bypass:** Skip `/work-review` entirely → run `/work-archive` → no findings file → archive succeeds.

**Fix needed:** Distinguish "review ran, found 0 issues" from "review never ran."

### 3. State Machine Violations Allowed

No command validates step_status lifecycle rules:
- Can mark step "completed" without "active" first
- Can have multiple "active" steps
- Can set current_step to a non-existent step name
- No backwards-transition prevention enforced

## Working Commands (No Gaps)

| Command | Enforcement | Status |
|---------|------------|--------|
| `/work` | Detects active tasks, routes correctly | ✓ |
| `/work-fix` | T1 init, assessment validation | ✓ |
| `/work-feature` | T2 init, doc directory creation | ✓ |
| `/work-deep` | T3 init, epic/directory creation | ✓ |
| `/work-review` | Agent spawning, findings.jsonl writes | ✓ |
| `/work-reground` | Read-only, no mutations | ✓ |
| `/work-redirect` | Dead-end documentation | ✓ |
| `/work-status` | Read-only display | ✓ |

## Key Insight

Commands are **prompt-based** — they describe what SHOULD happen but the LLM decides whether to follow. The dev-env-silo failure shows this is insufficient for Tier 3 discipline. Commands need to be backed by hooks that validate the command's post-conditions.
