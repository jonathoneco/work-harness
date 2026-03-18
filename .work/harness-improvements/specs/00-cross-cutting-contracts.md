# Spec 00: Cross-Cutting Contracts

Shared conventions, schemas, and interface patterns consumed by all component specs.

## 1. Path Conventions

All paths are project-relative (from repo root). No absolute paths in specs, skills, or commands.

### New Paths Introduced

| Path | Component | Purpose |
|------|-----------|---------|
| `claude/skills/work-harness/task-discovery.md` | C7 | Shared skill: active task detection |
| `claude/skills/work-harness/step-transition.md` | C7 | Shared skill: step approval ceremony |
| `claude/skills/work-harness/phase-review.md` | C7 | Shared skill: Phase A + B review template |
| `claude/skills/work-harness/references/gate-protocol.md` | C4 | Gate file SOP reference |
| `claude/skills/code-quality/references/security-antipatterns.md` | C2 | Security anti-patterns reference |
| `claude/skills/code-quality/references/ai-config-linting.md` | C2 | AI config linting reference |
| `claude/skills/code-quality/references/parallel-review.md` | C2 | Parallel review pattern reference |
| `claude/skills/work-harness/codex-review.md` | C10 | Codex review skill |
| `hooks/lib/common.sh` | C7 | Shared hook utilities |
| `.work/<name>/gates/<from>-to-<to>.md` | C4 | Gate review files |

### Existing Paths Modified

| Path | Component | Change |
|------|-----------|--------|
| `hooks/post-compact.sh` | C6 | Add handoff prompt injection |
| `claude/commands/work-deep.md` | C1, C5, C8, C9 | Stream doc format, research protocol, delegation routing |
| `claude/skills/code-quality.md` | C2 | Reference parallel review pattern |
| `claude/skills/work-harness/references/state-conventions.md` | C4 | Document new state.json fields |

## 2. State.json Extensions

New **optional** fields. No existing fields are modified or removed.

### Step Status Extensions

```json
{
  "name": "plan",
  "status": "completed",
  "gate_id": "work-harness-abc",
  "gate_file": "gates/research-to-plan.md"
}
```

- `gate_file`: Relative path (from `.work/<name>/`) to the gate review file created at step transition (C4). Added alongside existing `gate_id`.

### Stream Doc Metadata (in stream docs, not state.json)

See Spec 01 for the enhanced stream doc format with `isolation`, `agent_type`, `skills`, `scope_estimate`, and `file_ownership` fields.

## 3. Naming Conventions

| Entity | Convention | Example |
|--------|-----------|---------|
| Skill files | Kebab-case `.md` | `task-discovery.md` |
| Skill slugs | Kebab-case | `work-harness`, `code-quality` |
| Reference docs | Kebab-case `.md` under `references/` | `security-antipatterns.md` |
| Hook files | Kebab-case `.sh` | `post-compact.sh` |
| Hook lib files | Kebab-case `.sh` under `hooks/lib/` | `common.sh` |
| Gate files | `<from>-to-<to>.md` | `research-to-plan.md` |
| Spec files | `NN-<slug>.md` | `01-stream-docs.md` |
| Stream docs | `<letter>.md` | `a.md`, `b.md` |
| Doc types | Lowercase, hyphenated | `endpoints`, `env-setup` |
| Component IDs | `C` + number | `C1`, `C2` |

## 4. Skill File Format

All new skills follow the established pattern from `claude/skills/work-harness.md`:

```markdown
---
name: <kebab-case-slug>
description: "<one-line description>"
---

# <Title>

<What this skill provides and when it activates.>

## When This Activates
- <trigger conditions>

## <Functional Sections>
<domain-specific content>

## References
- **<ref-name>** — <description> (path: `<relative-path>`)
```

## 5. Hook File Format

All hooks follow POSIX sh conventions from existing hooks:

```sh
#!/bin/sh
# harness: <one-line description>
# Component: C<N>
# Event: <PostToolUse|PostCompact|PreToolUse>
set -eu

# Dependency checks — exit 0 (pass silently) if optional dep missing
command -v jq >/dev/null 2>&1 || exit 0

# Read input from stdin (JSON for PostToolUse hooks)
INPUT=$(cat)

# Extract fields via jq
CWD=$(printf '%s\n' "$INPUT" | jq -r '.cwd')

# Business logic

# Exit codes:
# 0 = pass (silent)
# 1 = non-blocking warning (message shown)
# 2 = blocking failure (action prevented)
```

### Hook Lib Pattern (C7)

Shared utilities sourced from `hooks/lib/common.sh`. Follows the existing `lib/config.sh` pattern:

```sh
# In hooks/lib/common.sh:
harness_find_active_task() { ... }
harness_read_state() { ... }
harness_log() { ... }

# In hook files:
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"
```

## 6. Reference Doc Format

Reference docs are markdown files under a skill's `references/` directory. They are loaded as agent context when the skill is referenced.

```markdown
# <Title>

<Brief description of what this reference covers.>

## <Category>

### <Item>
- **Pattern**: <what to look for>
- **Risk**: <why it matters>
- **Fix**: <what to do instead>
```

## 7. Error Handling Contracts

### Hooks
- **Missing optional dependency** (e.g., `yq`): Exit 0 with no output. Never block on optional tools.
- **Missing required dependency** (e.g., `jq`): Exit 0 with warning to stderr. Hooks should not block agent work.
- **Unparseable state.json** (C6, advisory B2): Log warning to stderr, exit 0. Never block compaction for corrupt state.
- **Missing files**: Exit 0. If a handoff prompt or state file doesn't exist, skip gracefully.

### Skills
- Skills are advisory — they provide instructions, not enforcement.
- Error paths documented as "if X is unavailable, proceed without it" rather than hard failures.

### Commands
- Commands validate prerequisites at the start of each step.
- Missing prerequisites produce a clear message and stop (don't guess defaults).

## 8. Testing Strategy

This is a shell/markdown project. Testing approaches by component type:

| Type | Testing Approach |
|------|-----------------|
| Shell hooks (`.sh`) | `shellcheck` lint; manual dry-run with mock JSON on stdin |
| Skills/commands (`.md`) | Structural review: frontmatter valid, sections present, cross-refs correct |
| Reference docs (`.md`) | Content review: entries non-empty, examples concrete, no placeholder text |
| State extensions | Validate via `state-guard.sh` — new fields must not break existing validation |
| Integration | End-to-end: run `/work-deep` on a test task, verify correct step routing |

### Acceptance Criteria Pattern

All acceptance criteria in specs follow the form:

> **AC-NN**: `<observable behavior>` — verified by `<method>`

Methods: `shellcheck`, `manual-test`, `structural-review`, `integration-test`, `file-exists`.

## 9. Dependency Between Specs

```
Spec 00 (this doc)
  ├── 01 Stream Docs Enhancement (C1) ── Phase 1
  ├── 02 Code Quality Enhancement (C2) ── Phase 1
  ├── 03 Context Doc System (C3) ── Phase 1
  ├── 04 Gate Protocol (C4) ── Phase 1
  ├── 05 Research Protocol (C5) ── Phase 1
  ├── 06 Auto-Reground (C6) ── Phase 1
  ├── 07 Skill Library (C7) ── Phase 2
  │     ├── 08 Dynamic Delegation (C8) ── Phase 3
  │     │     └── 09 Parallel Execution v2 (C9) ── Phase 3 (also depends on 01)
  ├── 10 Codex Integration (C10) ── Phase 4 (depends on 02)
  └── 11 Memory Integration (C11) ── Phase 4 (optionally enriched by 06)
```

## 10. Advisory Notes Carried Forward

These notes from the plan→spec gate review are addressed in the relevant specs:

| Note | Spec | Resolution |
|------|------|------------|
| A1: C8 `skills:` field verification as Phase 3 blocking gate | 08 | Verification step in spec |
| A2: C3 auto-detection concrete examples | 03 | Example mapping table |
| A3: Gate Protocol in data flow | 04 | Invocation point documented |
| A4: Phase 4 timing precision | 10, 11 | "After C2 completes" / "After C6 completes" |
| A5: C7 hook utilities scope | 07 | Integrated into hooks/lib/common.sh |
| B1: C7 follows lib/config.sh pattern | 07 | Sourcing pattern documented |
| B2: C6 corrupt state.json behavior | 06 | Warn-and-proceed |
| B3: C11/C6 enrichment deferred | 06, 11 | C6 ships without memory; C11 documents future enrichment |
