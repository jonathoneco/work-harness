---
name: skill-lifecycle
description: "Staleness detection rules and skill metadata conventions. Activates when running /work-skill-update or when harness-doctor checks skill health."
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# Skill Lifecycle

This skill defines metadata conventions and staleness detection rules for all
harness skills and commands. It ensures that documentation stays current and
that every skill/command carries machine-readable metadata for automated health
checks.

## When This Activates

- Running `/work-skill-update`
- Running `/harness-doctor` (future: skill health check)
- Adding new skills or commands to the harness

## Staleness Detection Rules

- **Default threshold**: 90 days since `last_reviewed`
- A skill is **stale** when `today - last_reviewed > threshold`
- Threshold is not configurable in V1 (hardcoded 90 days)
- Stale skills are reported but not auto-updated — the `/work-skill-update` command surfaces them for human review

## Metadata Validation Rules

Every `.md` file under `claude/skills/` (excluding `references/` subdirectories) and `claude/commands/` must include a YAML frontmatter `meta` block with these fields:

| Field | Type | Rule |
|-------|------|------|
| `meta.stack` | array of strings | Must be a non-empty array (e.g. `["all"]`, `["go", "python"]`) |
| `meta.version` | integer | Must be a positive integer (>= 1) |
| `meta.last_reviewed` | date | Must be a valid ISO 8601 date (YYYY-MM-DD) |

### Validation Outcomes

- **MISSING**: File has no `meta` block at all in its frontmatter
- **INVALID**: `meta` block exists but one or more fields fail validation (missing, wrong type, or empty)
- **STALE**: All fields valid but `last_reviewed` exceeds the 90-day threshold
- **HEALTHY**: All fields valid and within the staleness threshold

## When to Bump Version

Bump `meta.version` when making **material content changes**:

- New rules, sections, or behavioral changes
- Changed thresholds, constraints, or validation logic
- Restructured sections that alter how the skill is consumed

Do **NOT** bump version for:

- Typo fixes or grammar corrections
- Formatting-only changes (whitespace, markdown styling)
- Metadata-only updates (e.g. updating `last_reviewed` after a review confirms no changes needed)

When bumping version, also update `last_reviewed` to the current date.

## References

- **Spec 00 — Contract 2**: Skill metadata schema and lifecycle conventions
