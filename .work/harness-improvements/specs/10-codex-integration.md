# Spec 10: Codex Integration (C10)

**Component:** C10 -- Phase 4, Scope M, Priority P9
**Requires:** C2 (Code Quality Enhancement)

## Overview

Add optional OpenAI Codex integration for delegated code review with graceful degradation. Codex runs in a read-only sandbox and produces structured findings that Claude verifies before surfacing. This provides a second-opinion review from a different model, catching blind spots that a single-model review misses. The integration is phased: skill-based CLI execution first, MCP server later, dual-review eventually.

## Scope

**In scope:**
- Codex review skill (`claude/skills/work-harness/codex-review.md`) wrapping `codex exec`
- JSONL output schema for Codex findings compatible with existing `findings.jsonl`
- Graceful degradation when Codex is not installed
- Claude verification step for all Codex findings
- Known hallucination pattern documentation
- Integration point in `claude/commands/work-review.md`

**Out of scope:**
- Codex MCP mode (`codex --mcp`) -- future enhancement within C10's lifecycle, not this deliverable
- Dual-review (Claude + Codex in parallel with merged findings) -- future enhancement
- Codex for implementation tasks -- review only
- Installing or distributing Codex itself -- assumes user has it installed
- Changes to the findings.jsonl schema (Codex findings use the existing schema)

## Implementation Steps

### Step 1: Create the Codex review skill

Create `claude/skills/work-harness/codex-review.md` following the skill file format from Spec 00.

```markdown
---
name: codex-review
description: "Optional Codex integration for second-opinion code review. Activates during /work-review when Codex CLI is available."
---

# Codex Review

Delegates code review to OpenAI Codex CLI running in a read-only sandbox. Codex findings are always verified by Claude before surfacing -- never auto-actioned.

## When This Activates

- During `/work-review` when `which codex` succeeds
- Only for review tasks -- never for implementation

## Prerequisites

- Codex CLI installed and on PATH (`which codex`)
- If not available: skip silently, log "Codex not available, skipping second-opinion review"

## Execution

Run Codex in read-only sandbox mode with structured output:

    codex exec \
      --output-schema '{"type":"array","items":{"type":"object","properties":{"severity":{"type":"string","enum":["critical","important","minor"]},"category":{"type":"string","enum":["security","performance","correctness","style"]},"file":{"type":"string"},"line":{"type":"integer"},"message":{"type":"string"},"suggestion":{"type":"string"}},"required":["severity","category","file","message"]}}' \
      --sandbox read-only \
      "Review the following code changes for bugs, security issues, performance problems, and correctness errors. Focus on real issues, not style preferences. For each issue found, provide severity, category, file, line number, message, and suggested fix." \
      < <diff-input>

## Output Schema

Codex returns JSONL where each line matches:

    {
      "severity": "critical|important|minor",
      "category": "security|performance|correctness|style",
      "file": "relative/path/to/file",
      "line": 42,
      "message": "Description of the issue",
      "suggestion": "How to fix it"
    }

Severity mapping to findings.jsonl: `minor` maps to `suggestion`.

## Verification Rules

Every Codex finding MUST be verified by Claude before inclusion in findings.jsonl:

1. **Read the actual code** at the file and line Codex references
2. **Confirm the issue exists** -- Codex may hallucinate issues in code it cannot see
3. **Check against known hallucination patterns** (see below)
4. **Classify the verification result**:
   - CONFIRMED: Issue is real, include in findings
   - DISMISSED: Issue is a hallucination or false positive, discard
   - MODIFIED: Issue is partially correct, rewrite the finding with accurate details

## Known Hallucination Patterns

Codex frequently produces false positives in these categories. Apply extra scrutiny:

- **Phantom race conditions**: Reports data races in single-threaded or mutex-protected code
- **Misunderstood control flow**: Claims a variable is uninitialized or unused when it is set in a branch Codex did not follow
- **Framework false positives**: Reports issues with framework-managed lifecycle (e.g., connection pooling, request scoping) that the framework handles correctly
- **Missing null checks**: Reports missing nil/null checks for values that are guaranteed non-nil by the caller contract
- **Imaginary API misuse**: References API methods or parameters that do not exist in the version being used

## References

- **findings-schema** -- JSONL schema for review findings (path: `.work/<name>/review/findings.jsonl`)
```

**AC-01**: `Skill file exists at claude/skills/work-harness/codex-review.md with valid frontmatter and all sections (Prerequisites, Execution, Output Schema, Verification Rules, Known Hallucination Patterns)` -- verified by `file-exists` + `structural-review`

### Step 2: Add Codex integration point to work-review command

Add an optional Codex review step to `claude/commands/work-review.md` between agent collection (Step 3) and finding output (Step 6).

**Insert after Step 3 (Collect and Process Findings), before Step 4 (Create Beads Issues):**

```markdown
### Step 3b: Codex Second-Opinion Review (optional)

If the `codex-review` skill is available (i.e., `which codex` succeeds):

1. **Prepare diff input**: Use the same diff from Step 1 (scope determination)
2. **Execute Codex**: Run per the codex-review skill's Execution section
3. **Parse Codex output**: Read the JSONL output. For each finding:
   a. Verify against the actual code (per Verification Rules in the skill)
   b. Check against Known Hallucination Patterns
   c. Classify as CONFIRMED, DISMISSED, or MODIFIED
4. **Merge confirmed findings**: For each CONFIRMED or MODIFIED finding:
   - Map to the findings.jsonl schema:
     - `severity`: map Codex `critical` -> `critical`, `important` -> `important`, `minor` -> `suggestion`
     - `category`: pass through from Codex output
     - `found_by`: `codex`
     - All other fields populated per Step 3's existing schema
   - Deduplicate against Claude agent findings: if a Codex finding references the same file+line and same category as an existing Claude finding, skip it (Claude's finding takes precedence)
5. **Log Codex stats**: After processing, log:
   - Total Codex findings: N
   - Confirmed: N, Dismissed: N, Modified: N
   - Deduplicated (already found by Claude): N

If `which codex` fails: log "Codex not available, skipping second-opinion review" and continue to Step 4. No error, no warning -- this is expected when Codex is not installed.
```

**AC-02**: `work-review.md contains a Step 3b for Codex review that is conditional on codex availability` -- verified by `structural-review`

**AC-03**: `Codex findings are verified by Claude before inclusion -- the step explicitly requires reading actual code and checking against hallucination patterns` -- verified by `structural-review`

**AC-04**: `When codex is not installed, work-review proceeds without error or warning beyond a log message` -- verified by `manual-test`

### Step 3: Add Codex findings deduplication logic

Document the deduplication rules to prevent duplicate findings when both Claude agents and Codex identify the same issue.

**Deduplication rules (in Step 3b):**

- **Same file + same line range (within 5 lines) + same category**: Consider a duplicate. Keep the Claude agent finding (it has richer context from the agent's analysis). Mark the Codex finding as deduplicated in the stats.
- **Same file + same category but different line**: Not a duplicate -- both are included. Codex may have found a different instance of the same class of issue.
- **Same file + different category**: Not a duplicate -- include both.

**AC-05**: `Deduplication rules are documented with specific matching criteria (file, line range, category)` -- verified by `structural-review`

### Step 4: Document Codex exit code and error handling

Add error handling for Codex execution failures to the skill.

**Append to the codex-review skill's Execution section:**

```markdown
## Error Handling

- **Exit code 0**: Parse output as JSONL
- **Non-zero exit code**: Log "Codex review failed (exit code N), skipping" and continue without Codex findings. Do not retry -- Codex failures should not block the review.
- **Unparseable output**: Log "Codex output not valid JSONL, skipping" and continue. Include the first 500 characters of output in the log for debugging.
- **Timeout**: If Codex does not return within 5 minutes, terminate and log "Codex review timed out, skipping". Use the `timeout` parameter on the Bash tool call.
```

**AC-06**: `Codex execution failures (non-zero exit, bad output, timeout) are handled gracefully with log messages and no blocking` -- verified by `structural-review`

### Step 5: Add skill reference to code-quality skill

Update `claude/skills/code-quality.md` (or the updated version from C2) to reference the Codex review capability as a complementary tool.

**Append to the "How to Use" section:**

```markdown
## Complementary Tools

- **Codex second-opinion review** -- When available, `/work-review` automatically runs Codex as a second reviewer. Codex findings are verified against these same quality rules before inclusion. See the `codex-review` skill for details.
```

**AC-07**: `code-quality.md references codex-review as a complementary tool in its How to Use section` -- verified by `structural-review`

## Interface Contracts

### Consumes

| Interface | From | Description |
|-----------|------|-------------|
| Quality rules | C2 (code-quality skill) | Universal anti-patterns inform what Codex should look for and how Claude verifies findings |
| findings.jsonl schema | work-review command | Codex findings must conform to the existing finding record format |
| Diff scope | work-review Step 1 | Same diff used for Claude agent review is passed to Codex |

### Exposes

| Interface | To | Description |
|-----------|------|-------------|
| `codex-review` skill | work-review command | Skill document describing execution, output schema, verification rules |
| `found_by: codex` findings | findings.jsonl consumers | Codex findings are distinguishable by their `found_by` field |
| Codex stats log | Review summary | Stats on Codex findings (total, confirmed, dismissed, deduplicated) |

## Files

| File | Action | Description |
|------|--------|-------------|
| `claude/skills/work-harness/codex-review.md` | Create | Codex review skill with execution, schema, verification, hallucination patterns |
| `claude/commands/work-review.md` | Modify | Add Step 3b for optional Codex second-opinion review |
| `claude/skills/code-quality.md` | Modify | Add complementary tools reference to codex-review |

## Testing Strategy

| Test | Method | Covers |
|------|--------|--------|
| Skill file has valid frontmatter and all required sections | `structural-review` | AC-01 |
| work-review Step 3b is conditional on `which codex` | `structural-review` | AC-02, AC-04 |
| Verification step requires reading actual code | `structural-review` | AC-03 |
| Deduplication rules specify file + line range + category | `structural-review` | AC-05 |
| Error handling covers exit codes, bad output, timeout | `structural-review` | AC-06 |
| code-quality references codex-review | `structural-review` | AC-07 |
| End-to-end with Codex installed: run `/work-review`, verify Codex findings appear in findings.jsonl with `found_by: codex` and verification status | `integration-test` | AC-01 through AC-07 |
| End-to-end without Codex: run `/work-review`, verify it completes cleanly with no Codex-related errors | `integration-test` | AC-04 |

## Deferred Questions Resolution

### DQ-4: C10 output schema -- structured format for Codex findings

**Resolution:** Use JSONL format matching the existing `findings.jsonl` schema from work-review. Each Codex finding line contains:

```json
{
  "severity": "critical|important|minor",
  "category": "security|performance|correctness|style",
  "file": "relative/path",
  "line": 42,
  "message": "Description of the issue",
  "suggestion": "How to fix it"
}
```

The `minor` severity maps to `suggestion` in findings.jsonl. The `category` field uses a constrained enum (`security`, `performance`, `correctness`, `style`) rather than free-text, ensuring consistent aggregation. The `line` field is optional (nullable) for file-level findings.

This schema is passed to Codex via `--output-schema` to constrain its output format. After verification by Claude, confirmed findings are mapped to the full findings.jsonl record format (adding `id`, `task_name`, `issue_id`, `status`, timestamps, `found_by: codex`, etc.).

## Advisory Notes Resolution

### A4: Phase 4 timing precision

C10 can start as soon as C2 (Code Quality Enhancement) completes. It does not need to wait for Phase 1 to fully complete -- only the code-quality skill and its references need to exist so the Codex verification step can reference quality rules. C10 has no dependency on C3, C4, C5, or C6.

The phased delivery within C10 itself is:
1. **This deliverable**: Skill-based CLI execution via `codex exec`
2. **Future**: MCP server mode via `codex --mcp` (when Codex MCP support stabilizes)
3. **Future**: Dual-review with parallel Claude + Codex execution and merged findings
