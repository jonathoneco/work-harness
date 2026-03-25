---
name: codex-review
description: "Optional Codex integration for second-opinion code review. Activates during /work-review when Codex CLI is available."
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
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

## Diff Preparation

Generate the diff to send to Codex. The diff should include all changes being reviewed:

### For PR review (most common)
```bash
git diff $(gh pr view --json baseRefName -q '.baseRefName')...HEAD
```

### For staged changes
```bash
git diff --cached
```

### For unstaged changes
```bash
git diff
```

### Size limits
- If the diff exceeds 50,000 characters, split by file and make multiple Codex calls
- Each call should include full file context for the files being reviewed
- Combine all findings before verification

## Multi-File Handling

When reviewing changes across many files:

1. **Single invocation** (preferred for <50k chars): Send the full diff. Codex sees cross-file relationships.
2. **Split by file** (for large diffs): Group related files together (e.g., handler + service + test). Send each group as a separate Codex call.
3. **Combine findings**: Merge JSONL output from all calls, deduplicate by file+line, then verify all findings.

Do NOT split a single file's diff across multiple invocations — Codex needs full file context to avoid false positives.

## Integration with /work-review

This skill is consumed by `/work-review` when Codex is available. The integration flow:

1. `/work-review` spawns review agents (per review-methodology)
2. One review agent handles Codex integration (this skill)
3. The Codex agent: prepares diff → calls Codex → verifies findings → returns findings to orchestrator
4. The orchestrator merges Codex findings with other agent findings into `findings.jsonl`

The Codex agent does NOT write to `findings.jsonl` directly — it returns findings to the orchestrating `/work-review` command.

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

## Error Handling

- **Exit code 0**: Parse output as JSONL
- **Non-zero exit code**: Log "Codex review failed (exit code N), skipping" and continue without Codex findings. Do not retry -- Codex failures should not block the review.
- **Unparseable output**: Log "Codex output not valid JSONL, skipping" and continue. Include the first 500 characters of output in the log for debugging.
- **Timeout**: If Codex does not return within 5 minutes, terminate and log "Codex review timed out, skipping". Use the `timeout` parameter on the Bash tool call.

## References

- **findings-schema** -- JSONL schema for review findings (path: `.work/<name>/review/findings.jsonl`)
