---
stream: H
phase: 4
isolation: none
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: S
file_ownership:
  - claude/skills/work-harness/codex-review.md
  - claude/skills/code-quality/code-quality.md
  - claude/commands/work-review.md
---

# Stream H: Phase 4 — Codex Review Integration

## Stream Identity

- **Stream:** H
- **Phase:** 4
- **Work Items:**
  - W-11 (work-harness-xv5): Codex review integration — spec 10

## File Ownership

| File | Action | Work Items |
|------|--------|------------|
| `claude/skills/work-harness/codex-review.md` | Create | W-11 |
| `claude/commands/work-review.md` | Modify | W-11 |
| `claude/skills/code-quality/code-quality.md` | Modify | W-11 |

## Dependency Constraints

Stream H depends on:

- **W-04 (work-harness-xu1)** — C2 (Code Quality Enhancement) must be complete. The codex-review skill's verification rules reference code quality patterns, and the code-quality.md skill file must exist before adding the complementary tools reference.

Stream H cannot begin execution until C2 is complete.

---

## W-11: Codex Review Integration (work-harness-xv5)

**Spec reference:** `.work/harness-improvements/specs/10-codex-integration.md` (C10)

### Files

| File | Action | Description |
|------|--------|-------------|
| `claude/skills/work-harness/codex-review.md` | Create | Codex review skill with execution, output schema, verification rules, known hallucination patterns, error handling |
| `claude/commands/work-review.md` | Modify | Add Step 3b for optional Codex second-opinion review with deduplication |
| `claude/skills/code-quality/code-quality.md` | Modify | Add complementary tools reference to codex-review |

### Acceptance Criteria

**AC-01**: `Skill file exists at claude/skills/work-harness/codex-review.md with valid frontmatter and all sections (Prerequisites, Execution, Output Schema, Verification Rules, Known Hallucination Patterns)` -- verified by `file-exists` + `structural-review`

**AC-02**: `work-review.md contains a Step 3b for Codex review that is conditional on codex availability` -- verified by `structural-review`

**AC-03**: `Codex findings are verified by Claude before inclusion -- the step explicitly requires reading actual code and checking against hallucination patterns` -- verified by `structural-review`

**AC-04**: `When codex is not installed, work-review proceeds without error or warning beyond a log message` -- verified by `manual-test`

**AC-05**: `Deduplication rules are documented with specific matching criteria (file, line range, category)` -- verified by `structural-review`

**AC-06**: `Codex execution failures (non-zero exit, bad output, timeout) are handled gracefully with log messages and no blocking` -- verified by `structural-review`

**AC-07**: `code-quality.md references codex-review as a complementary tool in its How to Use section` -- verified by `structural-review`

### Implementation Notes

C10 adds optional OpenAI Codex integration for second-opinion code review. This is a 5-step implementation:

#### Step 1: Create the Codex review skill

Create `claude/skills/work-harness/codex-review.md` following the skill file format from Spec 00.

The skill must contain:
- Valid YAML frontmatter (`name: codex-review`, `description`)
- **Prerequisites**: Check `which codex`, skip silently if unavailable
- **Execution**: `codex exec` with `--output-schema` for structured JSONL and `--sandbox read-only`
- **Output Schema**: JSONL with fields: severity (critical/important/minor), category (security/performance/correctness/style), file, line, message, suggestion. Severity mapping: `minor` maps to `suggestion` in findings.jsonl.
- **Verification Rules**: Every Codex finding MUST be verified by Claude. Read actual code, confirm issue exists, check against hallucination patterns. Classify as CONFIRMED, DISMISSED, or MODIFIED.
- **Known Hallucination Patterns**: Phantom race conditions, misunderstood control flow, framework false positives, missing null checks, imaginary API misuse.

#### Step 2: Add error handling to the skill

Append an Error Handling section to the codex-review skill:
- Exit code 0: parse output as JSONL
- Non-zero exit code: log and skip, no retry
- Unparseable output: log first 500 chars for debugging, skip
- Timeout: 5-minute limit via `timeout` parameter on Bash tool call

#### Step 3: Add Codex integration point to work-review command

Insert Step 3b after existing Step 3 (Collect and Process Findings), before Step 4 (Create Beads Issues):
- Prepare diff input (same diff from Step 1)
- Execute Codex per the codex-review skill
- Parse JSONL output, verify each finding against actual code
- Merge confirmed findings with `found_by: codex`
- Log stats: total, confirmed, dismissed, modified, deduplicated

If `which codex` fails: log "Codex not available, skipping second-opinion review" and continue. No error, no warning.

#### Step 4: Add deduplication logic

Deduplication rules for Step 3b:
- Same file + same line range (within 5 lines) + same category: duplicate. Keep Claude's finding, mark Codex finding as deduplicated.
- Same file + same category but different line: not a duplicate, include both.
- Same file + different category: not a duplicate, include both.

#### Step 5: Add complementary tools reference to code-quality skill

Append a "Complementary Tools" section to `claude/skills/code-quality/code-quality.md` referencing codex-review as a second reviewer that runs automatically during `/work-review` when Codex is available.
