# 03: Review Verification (`review-verify.sh`)

## Overview

Stop hook that prevents archiving a Tier 2-3 task without evidence that review was actually run. Closes the "mark review completed without running it" gap.

**Scope:** Only Tier 2-3. Tier 1 tasks use `/work-fix` (single-session) with an inline mini-review enforced by `review-gate.sh` (anti-pattern detection in diff). They don't have a discrete review step in their steps array.

## Trigger

- **Event:** Stop
- **Matcher:** `""` (all stops)

## The Problem

Currently, `/work-archive` checks finding triage status but cannot distinguish:
- "Review ran, found 0 critical issues" → OK to archive
- "Review was never run" → NOT OK to archive

Both pass the current gate identically because no findings.jsonl = no untriaged findings = gate passes.

## Solution: `reviewed_at` Timestamp

Add `reviewed_at` field to state.json, set by `/work-review` when it completes.

The hook checks: for Tier 2-3 tasks where `archived_at` is non-null (being archived), `reviewed_at` must also be non-null.

## Validation Rules

### Rule 1: Archived Tier 2-3 tasks must have review evidence

```bash
tier=$(jq -r '.tier' "$state_file")
[ "$tier" -ge 2 ] 2>/dev/null || continue

archived=$(jq -r '.archived_at // "null"' "$state_file")
[ "$archived" != "null" ] || continue

reviewed=$(jq -r '.reviewed_at // "null"' "$state_file")
if [ "$reviewed" = "null" ]; then
  task_name=$(jq -r '.name' "$state_file")
  echo "Review verify: task '$task_name' is archived but review was never run" >&2
  echo "Run /work-review before archiving." >&2
  exit 2
fi
```

> **Note:** Rule 1 catches the archive gate (task is being archived). Rule 2 catches the step gate (review step marked completed during active work). Both validate the same invariant from different angles — belt and suspenders.

### Rule 2: Review step marked completed must have evidence

```bash
review_status=$(jq -r '.steps[] | select(.name == "review") | .status // "not_started"' "$state_file")
if [ "$review_status" = "completed" ]; then
  reviewed=$(jq -r '.reviewed_at // "null"' "$state_file")
  if [ "$reviewed" = "null" ]; then
    echo "Review verify: review step is 'completed' but reviewed_at is not set" >&2
    echo "Run /work-review to set the reviewed_at timestamp." >&2
    exit 2
  fi
fi
```

### `reviewed_at` Lifecycle

- **Initialization:** `null` when state.json is created (field must exist from creation)
- **Set by:** `/work-review` command on successful completion
- **When set:** After all review agents complete and findings are written (even if 0 findings found)
- **Re-runs:** Overwrites previous timestamp (latest review is authoritative)
- **Never set by:** Manual state edits, archive command, or any other command

## Command Changes Required

### `/work-review` Enhancement

After review agents complete and findings are written, add to state.json:
```json
"reviewed_at": "<ISO timestamp>"
```

This is the mechanical evidence that review ran. The hook validates this field.

When `/work-review` sets `reviewed_at`, it must also update `updated_at` to the current ISO timestamp (per the state mutation rule in spec 00).

### `/work-archive` Enhancement

The archive command should also check `reviewed_at` before proceeding (belt + suspenders with the hook).

## Files to Create

- `.claude/hooks/review-verify.sh` (~35 lines)

## Files to Modify

- `.claude/settings.json` — add to Stop hooks array
- `.claude/commands/work-review.md` — add `reviewed_at` state write after review completes
- `.claude/commands/work-archive.md` — add `reviewed_at` check to archive gate

## Error Recovery

If `/work-review` fails mid-execution (agent errors, timeout), `reviewed_at` is NOT set.
The hook will block archive until review succeeds. To recover:
1. Fix the underlying error
2. Re-run `/work-review`
3. Successful completion sets `reviewed_at`

## Testing

1. Archive Tier 2 task without reviewed_at → expect block
2. Archive Tier 2 task with reviewed_at set → expect allow
3. Archive Tier 1 task without reviewed_at → expect allow (Tier 1 exempt)
4. Mark review completed without reviewed_at → expect block
5. Run /work-review, verify it sets reviewed_at → expect timestamp written
