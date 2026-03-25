---
stream: O
phase: 3
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: M
file_ownership:
  - claude/commands/pr-prep.md
---

# Stream O — PR State Machine Refactor (Phase 3)

## Work Items
- **W-16** (work-harness-52s): PR state machine rewrite

## Spec References
- Spec 00: Contracts 2, 3 (frontmatter, config injection)
- Spec 12: C11 (PR state machine)

## What To Do

### 1. Refactor `/pr-prep` state machine (spec 12)

Modify `claude/commands/pr-prep.md`:
- PRESERVE Steps 0-7 (lint/build/fix cycle) unchanged
- REPLACE Steps 8-9 with state machine:
  - Step 8: PR State Detection (8 ordered checks: NO_PR, MERGED, DRAFT, CI_FAIL, NO_DESC, STALE_DESC, NEEDS_REVIEWERS, UP_TO_DATE)
  - Step 9: Execute State Action (action for each state)
- Add force override flags (--create-only, --update-desc, --cleanup)
- Add edge case handling (no gh, not authenticated, no remote, etc.)

See spec 12 for full state detection logic and action definitions.

## Acceptance Criteria
Spec 12 (pr-prep):
- AC-C11-2.1 through AC-C11-2.4 (state detection)
- AC-C11-3.1 through AC-C11-3.6 (state actions)
- AC-C11-4.1 through AC-C11-4.3 (force flags)
- AC-C11-5.1 through AC-C11-5.2 (edge cases)

## Dependency Constraints
- Requires Phase 1 complete (Stream A adds meta to pr-prep.md)
