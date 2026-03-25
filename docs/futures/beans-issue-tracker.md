# Beans — Deferred Enhancements

## F1: `bn edit <id>` — open issue in $EDITOR
Open issue JSON in a temp file for manual editing. Low priority — `bn update` covers most cases.

## F2: `bn stats` — issue counts by status/type
Simple aggregation: `jq -s 'group_by(.status) | ...'`. Not needed for MVP but useful for project health checks.

## F3: `bn import` / `bn export` — bulk data operations
Import issues from external sources (GitHub Issues, CSV). Only if cross-tool migration becomes common.

## F4: `bn gc` — explicit garbage collection / compaction
Force dedup + rewrite without a read operation triggering it. Only needed if the file grows very large.

## F5: Comments/notes on issues
If close_reason + git history proves insufficient for audit trail, add a `notes` array field. Deferred because beads had no comments either and it worked.

## F6: `bn doctor` — data integrity check
Validate all JSON lines parse, all dep references exist, no orphaned blocks. Low priority — JSONL is self-validating.
