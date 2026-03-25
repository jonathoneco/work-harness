# Spec 00: Cross-Cutting Contracts

**Component**: Shared contracts referenced by all other specs
**Phase**: N/A (consumed by all phases)
**Status**: complete

---

## Overview and Scope

This spec defines shared schemas, naming conventions, interface contracts, and configuration patterns that multiple component specs reference. It is not a component itself -- it is the contract layer that ensures consistency across all W4 deliverables.

**What this covers**:
- Entry format standard for language/framework packs
- YAML frontmatter schema for skills and commands (including `meta` block)
- Config injection directive (canonical wording)
- install.sh registration protocol for new commands/skills

**What this does NOT cover**:
- Component-specific file content (that belongs in individual specs)
- Discovery logic (Spec C04)
- Metadata retroactive tagging plan (Spec C13)

---

## Contract 1: Pack Entry Format Standard

All language packs, framework packs, and the refactored Go pack use this entry format. Informed by Clippy's "Why is this bad?" + "Use instead" format, which research confirmed is most effective for AI consumption.

### Entry Structure

```markdown
## [Category]: [Rule Name]
**Severity**: error | warn | info

[1-2 sentence description of the problem]

**Why**: [Concise rationale -- what goes wrong in practice]

```language
// BAD
<problematic code>
```

```language
// GOOD
<corrected code>
```
```

### Field Definitions

| Field | Required | Values | Notes |
|-------|----------|--------|-------|
| Category | Yes | One of 5 fixed categories (see below) | H2 heading prefix |
| Rule Name | Yes | Descriptive, title-case | H2 heading suffix |
| Severity | Yes | `error`, `warn`, `info` | Inline bold after heading |
| Description | Yes | 1-2 sentences | Plain text paragraph |
| Why | Yes | 1-3 sentences | Bold label, inline rationale |
| BAD example | Yes | Language-appropriate code block | Must include `// BAD` comment |
| GOOD example | Yes | Language-appropriate code block | Must include `// GOOD` comment |

### Categories (5 Fixed)

| Category | When to Use |
|----------|-------------|
| Anti-pattern | Code that compiles/runs but produces wrong, unsafe, or fragile results |
| Best Practice | Positive patterns that prevent classes of bugs |
| Idiomatic | Language-specific conventions that AI consistently misses |
| Performance | Patterns with measurable performance impact |
| Security | Patterns with security implications (input validation, auth, crypto) |

### Severity Definitions

| Severity | Meaning | AI Behavior |
|----------|---------|-------------|
| `error` | Will cause bugs, data loss, or security issues | Agent must fix before completing |
| `warn` | Likely causes problems in production | Agent should fix, may skip with justification |
| `info` | Style/idiom improvement | Agent may apply at discretion |

### Acceptance Criteria

- AC-00-1.1: Every entry in every pack file has all 7 required fields (Category, Rule Name, Severity, Description, Why, BAD, GOOD)
- AC-00-1.2: Category is one of the 5 fixed values (exact match, case-sensitive)
- AC-00-1.3: Severity is one of `error`, `warn`, `info` (exact match)
- AC-00-1.4: BAD code block contains a comment starting with `// BAD` (or `# BAD` for Python)
- AC-00-1.5: GOOD code block contains a comment starting with `// GOOD` (or `# GOOD` for Python)
- AC-00-1.6: Each entry's BAD and GOOD examples use the correct language identifier on the code fence

---

## Contract 2: YAML Frontmatter Schema

### Existing Fields (Commands)

```yaml
---
description: "One-line description"
user_invocable: true
skills: [skill-name-1, skill-name-2]  # optional
---
```

### Existing Fields (Skills)

```yaml
---
name: kebab-case-name
description: "One-line description"
---
```

### New `meta` Block

Added to ALL skill and command files that have YAML frontmatter. Files without frontmatter (reference files, sub-skill files without `---` delimiters) get frontmatter added first.

```yaml
meta:
  stack: [go, python]       # which stacks this applies to, or ["all"] for universal
  version: 1                # integer, bumped on significant content changes
  last_reviewed: 2026-03-24 # ISO 8601 date of last content review
```

### `meta.stack` Values

Valid values for the `stack` array:
- Language identifiers: `go`, `python`, `typescript`, `rust`, `other`
- Framework identifiers: `react`, `nextjs`, `django`, `fastapi`, `gin`, `htmx`
- Special: `all` (applies regardless of stack -- mutually exclusive with other values)

When `stack` is `["all"]`, the skill/command is universal and activates for every project.

### `meta.version` Rules

- Starts at `1` for existing files (retroactive tagging)
- Starts at `1` for new files
- Bumped to `N+1` when content is materially changed (not for typo fixes or formatting)
- Integer only, no decimal versions

### `meta.last_reviewed` Rules

- Set to the date the `meta` block is added (for retroactive tagging)
- Updated when content is reviewed and confirmed still accurate
- ISO 8601 date format: `YYYY-MM-DD`

### Acceptance Criteria

- AC-00-2.1: Every skill and command file in `claude/skills/` and `claude/commands/` has YAML frontmatter with a `meta` block
- AC-00-2.2: `meta.stack` is a YAML array containing valid identifiers or `["all"]`
- AC-00-2.3: `meta.version` is a positive integer
- AC-00-2.4: `meta.last_reviewed` is a valid ISO 8601 date string
- AC-00-2.5: Files that previously lacked `---` frontmatter delimiters have them added with the `meta` block

---

## Contract 3: Config Injection Directive

The canonical config injection directive is included in all commands that spawn subagents or produce handoff prompts. The exact wording:

```markdown
**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.
```

### When to Include

- All command files (`claude/commands/*.md`) that spawn agents or produce prompts
- NOT in skill files (skills are consumed by agents, not spawning agents)
- NOT in reference files (these are supplementary material)

### Graceful Skip Behavior

When `.claude/harness.yaml` does not exist:
- Commands skip config injection silently
- No error, no warning
- Commands proceed with reduced context (no stack info)

When `.claude/harness.yaml` exists but `stack.framework` or `stack.frontend` is absent:
- Include only the fields that are present
- Do not fail on absent optional fields

### Acceptance Criteria

- AC-00-3.1: All new command files include the config injection directive verbatim
- AC-00-3.2: The directive text matches the canonical wording above (exact paragraph)
- AC-00-3.3: Commands handle absent `harness.yaml` by skipping config injection without error

---

## Contract 4: install.sh Registration Protocol

New commands and skills are registered by adding their files to the `claude/` directory tree. install.sh discovers them automatically via `harness_list_content_files()` which runs `find . -type f` in the `claude/` directory.

### Registration Steps for New Files

1. **Create the file** in the correct location under `claude/`
2. **Verify discovery**: Run `(cd claude && find . -type f ! -name '.gitkeep' | sed 's|^\./||' | sort)` and confirm the new file appears
3. **No code changes needed in install.sh**: The `harness_list_content_files` function auto-discovers all files under `claude/`

### File Placement Conventions

| File Type | Location Pattern | Example |
|-----------|-----------------|---------|
| Command | `claude/commands/<name>.md` | `claude/commands/dev-update.md` |
| Skill (top-level) | `claude/skills/<name>.md` | `claude/skills/code-quality.md` |
| Skill (namespaced) | `claude/skills/<namespace>/<name>.md` | `claude/skills/work-harness/codex-review.md` |
| Reference | `claude/skills/<parent>/references/<name>.md` | `claude/skills/code-quality/references/go-anti-patterns.md` |
| Language pack | `claude/skills/code-quality/references/<language>-<category>.md` | `claude/skills/code-quality/references/python-anti-patterns.md` |
| Framework pack | `claude/skills/code-quality/references/<framework>-<category>.md` | `claude/skills/code-quality/references/react-anti-patterns.md` |

### install.sh Modifications (C14 Only)

The only install.sh changes needed are:
- No new `--flags` (auto-discovery handles file registration)
- Potential hook additions if new hooks are introduced (not in W4 scope)
- Version bump in `VERSION` file

### Acceptance Criteria

- AC-00-4.1: All new files are placed in locations that `harness_list_content_files` discovers
- AC-00-4.2: No install.sh code changes are needed for file registration (auto-discovery)
- AC-00-4.3: New pack files follow the `<identifier>-<category>.md` naming pattern
- AC-00-4.4: File names use kebab-case, no spaces or special characters

---

## Contract 5: Naming Conventions

### File Naming

- All file names: kebab-case, `.md` extension
- Pack files: `<stack-identifier>-<category>.md` where category is one of: `anti-patterns`, `best-practices`, `idiomatic`, `performance`, `security`
- Not all categories are required per language -- include only categories with sufficient content

### Frontmatter `name` Field

- Matches the file's stem (without `.md`)
- Kebab-case
- Example: file `dev-update.md` has `name: dev-update`

### Command `$ARGUMENTS`

- New commands that accept arguments use `$ARGUMENTS` in the H1 heading
- Example: `# /dev-update $ARGUMENTS`

---

## Inventory: Files Requiring `meta` Block

Verified enumeration of all 32 skill/command files (corrected from the architecture's "23" estimate):

### Skills (13 files)

| # | File | Current Frontmatter | Suggested `meta.stack` |
|---|------|--------------------|-----------------------|
| 1 | `claude/skills/adversarial-eval.md` | Has `---` | `["all"]` |
| 2 | `claude/skills/code-quality.md` | Has `---` | `["all"]` |
| 3 | `claude/skills/serena-activate.md` | Has `---` | `["all"]` |
| 4 | `claude/skills/workflow-meta.md` | Has `---` | `["all"]` |
| 5 | `claude/skills/work-harness.md` | Has `---` | `["all"]` |
| 6 | `claude/skills/work-harness/codex-review.md` | Has `---` | `["all"]` |
| 7 | `claude/skills/work-harness/context-docs.md` | Has `---` | `["all"]` |
| 8 | `claude/skills/work-harness/context-seeding.md` | Missing `---` | `["all"]` |
| 9 | `claude/skills/work-harness/phase-review.md` | Has `---` | `["all"]` |
| 10 | `claude/skills/work-harness/step-agents.md` | Missing `---` | `["all"]` |
| 11 | `claude/skills/work-harness/step-transition.md` | Has `---` | `["all"]` |
| 12 | `claude/skills/work-harness/task-discovery.md` | Has `---` | `["all"]` |
| 13 | `claude/skills/work-harness/teams-protocol.md` | Missing `---` | `["all"]` |

### Commands (19 files)

| # | File | Current Frontmatter | Suggested `meta.stack` |
|---|------|--------------------|-----------------------|
| 14 | `claude/commands/adversarial-eval.md` | Has `---` | `["all"]` |
| 15 | `claude/commands/ama.md` | Has `---` | `["all"]` |
| 16 | `claude/commands/delegate.md` | Has `---` | `["all"]` |
| 17 | `claude/commands/handoff.md` | Has `---` | `["all"]` |
| 18 | `claude/commands/harness-doctor.md` | Missing `---` | `["all"]` |
| 19 | `claude/commands/harness-init.md` | Missing `---` | `["all"]` |
| 20 | `claude/commands/harness-update.md` | Missing `---` | `["all"]` |
| 21 | `claude/commands/pr-prep.md` | Has `---` | `["all"]` |
| 22 | `claude/commands/work.md` | Has `---` | `["all"]` |
| 23 | `claude/commands/work-archive.md` | Has `---` | `["all"]` |
| 24 | `claude/commands/work-checkpoint.md` | Has `---` | `["all"]` |
| 25 | `claude/commands/work-deep.md` | Has `---` | `["all"]` |
| 26 | `claude/commands/work-feature.md` | Has `---` | `["all"]` |
| 27 | `claude/commands/work-fix.md` | Has `---` | `["all"]` |
| 28 | `claude/commands/work-redirect.md` | Has `---` | `["all"]` |
| 29 | `claude/commands/work-reground.md` | Has `---` | `["all"]` |
| 30 | `claude/commands/work-research.md` | Has `---` | `["all"]` |
| 31 | `claude/commands/work-review.md` | Has `---` | `["all"]` |
| 32 | `claude/commands/work-status.md` | Has `---` | `["all"]` |

**Note**: All 32 existing files are universal (`stack: ["all"]`). Stack-specific `meta.stack` values will only appear on new files (language packs, framework packs, stack-specific commands).

**Note**: 6 files currently lack `---` frontmatter delimiters and will need them added before the `meta` block can be inserted.
