---
stream: A
phase: 1
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: L
file_ownership:
  - claude/skills/adversarial-eval.md
  - claude/skills/code-quality.md
  - claude/skills/serena-activate.md
  - claude/skills/workflow-meta.md
  - claude/skills/work-harness.md
  - claude/skills/work-harness/codex-review.md
  - claude/skills/work-harness/context-docs.md
  - claude/skills/work-harness/context-seeding.md
  - claude/skills/work-harness/phase-review.md
  - claude/skills/work-harness/step-agents.md
  - claude/skills/work-harness/step-transition.md
  - claude/skills/work-harness/task-discovery.md
  - claude/skills/work-harness/teams-protocol.md
  - claude/commands/adversarial-eval.md
  - claude/commands/ama.md
  - claude/commands/delegate.md
  - claude/commands/handoff.md
  - claude/commands/harness-doctor.md
  - claude/commands/harness-init.md
  - claude/commands/harness-update.md
  - claude/commands/pr-prep.md
  - claude/commands/work.md
  - claude/commands/work-archive.md
  - claude/commands/work-checkpoint.md
  - claude/commands/work-deep.md
  - claude/commands/work-feature.md
  - claude/commands/work-fix.md
  - claude/commands/work-redirect.md
  - claude/commands/work-reground.md
  - claude/commands/work-research.md
  - claude/commands/work-review.md
  - claude/commands/work-status.md
---

# Stream A — Metadata Tagging (Phase 1)

## Work Items
- **W-01** (work-harness-alc.1): Metadata tagging — 32 files

## Spec References
- Spec 00: Contract 2 (YAML frontmatter schema, `meta` block definition)
- Spec 01: C13 Steps 1-2 (add frontmatter to 6 files lacking it, add `meta` block to 26 files with existing frontmatter)

## What To Do

### Part 1: Add frontmatter to 6 files lacking `---` delimiters
These files currently have no YAML frontmatter. Add `---` delimited frontmatter with appropriate fields plus the `meta` block:

1. `claude/skills/work-harness/context-seeding.md` — add `name: context-seeding`, description, meta
2. `claude/skills/work-harness/step-agents.md` — add `name: step-agents`, description, meta
3. `claude/skills/work-harness/teams-protocol.md` — add `name: teams-protocol`, description, meta
4. `claude/commands/harness-doctor.md` — add `description`, `user_invocable: true`, meta
5. `claude/commands/harness-init.md` — add `description`, `user_invocable: true`, meta
6. `claude/commands/harness-update.md` — add `description`, `user_invocable: true`, meta

Derive `name` (skills) or `description` (commands) from each file's H1 heading and content.

### Part 2: Add `meta` block to 26 files with existing frontmatter
Insert after existing fields but before closing `---`:

```yaml
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
```

Exception: `code-quality.md` gets `version: 2` (bumped due to discovery extension in a later stream).

Wait — no. Stream A sets version 1 for code-quality.md. Stream D (Phase 2) will bump it to 2 when adding discovery directives. So Stream A should set version 1 here.

### Rules
- All 32 files get `stack: ["all"]` (all are universal)
- All files get `version: 1`
- All files get `last_reviewed: 2026-03-24`
- Preserve ALL existing frontmatter fields unchanged
- Preserve ALL content below frontmatter unchanged

## Acceptance Criteria
Reference spec 01 (C13):
- AC-C13-1.1: All 6 files have valid `---` delimited YAML frontmatter
- AC-C13-1.2: Frontmatter parses as valid YAML
- AC-C13-1.3: Existing file content below frontmatter is unchanged
- AC-C13-2.1: All 26 files with existing frontmatter have a `meta` block added
- AC-C13-2.2: Existing frontmatter fields preserved unchanged
- AC-C13-2.3: `meta.stack` is `["all"]` for all 32 files
- AC-C13-2.4: `meta.version` is `1` for all 32 files
- AC-C13-2.5: `meta.last_reviewed` is `2026-03-24` for all 32 files

## Dependency Constraints
- None — this is a Phase 1 stream, runs first
