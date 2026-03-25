# Spec C13: Skill Metadata + Update Command

**Component**: C13 — Skill metadata + update command
**Phase**: 1 (Foundation)
**Status**: complete
**Dependencies**: Spec 00 (frontmatter schema, `meta` block definition)

---

## Overview and Scope

Adds `meta` frontmatter to all existing skill and command files, creates a staleness detection skill, and adds the `/work-skill-update` command. This is the largest single component in W4 because it touches all 32 existing files plus creates 2 new files.

**What this does**:
- Adds `meta` block (stack, version, last_reviewed) to all 32 existing skill/command files
- Adds `---` frontmatter delimiters to the 6 files that lack them
- Creates `claude/skills/work-harness/skill-lifecycle.md` skill for staleness detection rules
- Creates `claude/commands/work-skill-update.md` command

**What this does NOT do**:
- Automated testing of skill content (futures item)
- Skill versioning with migrations (scope exclusion)
- Content changes to existing skills (that's C05-C07)

---

## Implementation Steps

### Step 1: Add Frontmatter to Files Lacking It (6 files)

Add `---` delimited YAML frontmatter to the 6 files identified in Spec 00 inventory:

1. `claude/skills/work-harness/context-seeding.md`
2. `claude/skills/work-harness/step-agents.md`
3. `claude/skills/work-harness/teams-protocol.md`
4. `claude/commands/harness-doctor.md`
5. `claude/commands/harness-init.md`
6. `claude/commands/harness-update.md`

For each file:
- Add `---` as line 1
- Add `name:` (for skills) or `description:` and `user_invocable: true` (for commands) derived from the file's H1 heading and content
- Add the `meta` block per Spec 00 Contract 2
- Add closing `---`
- Preserve all existing content below

**Acceptance Criteria**:
- AC-C13-1.1: All 6 files have valid `---` delimited YAML frontmatter
- AC-C13-1.2: Frontmatter parses as valid YAML
- AC-C13-1.3: Existing file content below frontmatter is unchanged

### Step 2: Add `meta` Block to Files With Existing Frontmatter (26 files)

For each of the 26 files that already have `---` frontmatter, insert the `meta` block after existing fields but before the closing `---`:

```yaml
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
```

All 32 existing files get `stack: ["all"]` because they are all universal (not stack-specific).

**Acceptance Criteria**:
- AC-C13-2.1: All 26 files with existing frontmatter have a `meta` block added
- AC-C13-2.2: Existing frontmatter fields (name, description, user_invocable, skills) are preserved unchanged
- AC-C13-2.3: `meta.stack` is `["all"]` for all 32 files
- AC-C13-2.4: `meta.version` is `1` for all 32 files
- AC-C13-2.5: `meta.last_reviewed` is `2026-03-24` (implementation date) for all 32 files

### Step 3: Create Skill Lifecycle Skill

Create `claude/skills/work-harness/skill-lifecycle.md`:

```yaml
---
name: skill-lifecycle
description: "Staleness detection rules and skill metadata conventions. Activates when running /work-skill-update or when harness-doctor checks skill health."
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---
```

Content must include:

1. **When This Activates** section:
   - Running `/work-skill-update`
   - Running `/harness-doctor` (future: skill health check)
   - Adding new skills or commands to the harness

2. **Staleness Detection Rules**:
   - Default threshold: 90 days since `last_reviewed`
   - A skill is "stale" when `today - last_reviewed > threshold`
   - Threshold is not configurable in V1 (hardcoded 90 days)
   - Stale skills are reported but not auto-updated

3. **Metadata Validation Rules**:
   - `meta` block must exist in every `claude/skills/**/*.md` and `claude/commands/*.md` file (excluding `references/` subdirectories)
   - `meta.stack` must be a non-empty array
   - `meta.version` must be a positive integer
   - `meta.last_reviewed` must be a valid date

4. **When to Bump Version**:
   - Material content changes (new rules, changed behavior, restructured sections)
   - NOT for: typo fixes, formatting, metadata-only updates

5. **References**: Link back to Spec 00 Contract 2 for the full frontmatter schema

**Acceptance Criteria**:
- AC-C13-3.1: File exists at `claude/skills/work-harness/skill-lifecycle.md`
- AC-C13-3.2: Frontmatter includes `name`, `description`, and `meta` block
- AC-C13-3.3: Contains staleness threshold definition (90 days)
- AC-C13-3.4: Contains metadata validation rules
- AC-C13-3.5: Contains version bump guidance

### Step 4: Create `/work-skill-update` Command

Create `claude/commands/work-skill-update.md`:

```yaml
---
description: "Scan skills and commands for staleness, report outdated content, suggest updates"
user_invocable: true
skills: [skill-lifecycle]
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---
```

Command behavior:

1. **Scan Phase**: Find all `.md` files under `claude/skills/` (excluding `references/`) and `claude/commands/`. Parse YAML frontmatter from each.

2. **Validation Phase**: For each file, check:
   - `meta` block exists (report MISSING if absent)
   - `meta.stack` is a non-empty array (report INVALID if empty/absent)
   - `meta.version` is a positive integer (report INVALID if not)
   - `meta.last_reviewed` is a valid date (report INVALID if not)

3. **Staleness Phase**: For each file with valid metadata:
   - Calculate days since `last_reviewed`
   - If > 90 days, mark as STALE

4. **Output**: Report in structured format:
   ```
   --- Skill Health Report ---

   STALE (N files, >90 days since review):
     skill-name (last reviewed: YYYY-MM-DD, N days ago)
     ...

   MISSING metadata (N files):
     path/to/file.md
     ...

   INVALID metadata (N files):
     path/to/file.md: <reason>
     ...

   HEALTHY (N files)

   --- Summary ---
   N total files: N healthy, N stale, N missing, N invalid
   ```

5. **Suggestions**: For stale skills, suggest what to review based on `meta.stack`:
   - If stack includes a language, suggest checking against latest language version/tooling
   - If stack is `["all"]`, suggest general review for outdated patterns

**Acceptance Criteria**:
- AC-C13-4.1: File exists at `claude/commands/work-skill-update.md`
- AC-C13-4.2: Command scans all skill and command files (32 existing + any new)
- AC-C13-4.3: Reports files missing `meta` block
- AC-C13-4.4: Reports files with invalid metadata fields
- AC-C13-4.5: Reports files with `last_reviewed` older than 90 days
- AC-C13-4.6: Output includes a summary count (total, healthy, stale, missing, invalid)
- AC-C13-4.7: Command is read-only (does not modify any files)

### Step 5: Update `work-harness.md` References

Add `skill-lifecycle` to the References section of `claude/skills/work-harness.md`:

```markdown
- **skill-lifecycle** — Staleness detection rules and metadata conventions (path: `claude/skills/work-harness/skill-lifecycle.md`)
```

**Acceptance Criteria**:
- AC-C13-5.1: `work-harness.md` References section includes `skill-lifecycle`
- AC-C13-5.2: Path reference is correct

---

## Interface Contracts

### Exposes

- **`meta` frontmatter block**: All 32 files now have parseable `meta` blocks that other tools can read
- **`/work-skill-update` command**: Available to users via slash command
- **`skill-lifecycle` skill**: Available to agents via `skills: [skill-lifecycle]`
- **Staleness threshold**: 90 days, hardcoded in skill-lifecycle.md

### Consumes

- **Spec 00 Contract 2**: Frontmatter schema definition (meta block structure)
- **Spec 00 Contract 4**: install.sh registration (auto-discovery of new files)

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/skills/work-harness/skill-lifecycle.md` | Staleness detection skill |
| Create | `claude/commands/work-skill-update.md` | Update command |
| Modify | `claude/skills/work-harness.md` | Add skill-lifecycle reference |
| Modify | 32 existing skill/command files | Add `meta` block to frontmatter |

**Total**: 2 new files, 33 modified files

---

## Testing Strategy

1. **Frontmatter parsing**: For each of the 34 files (32 existing + 2 new), run `head -20 <file>` and verify YAML frontmatter parses correctly with `yq`. Specifically: `yq '.meta.stack' < <file>` should return a valid array.

2. **No content regression**: For each of the 32 modified files, verify that content below the frontmatter is unchanged. Compare the post-frontmatter content (everything after the second `---`) with the original file.

3. **Staleness detection**: After implementation, run the `/work-skill-update` command. All 32 files should report as HEALTHY (since `last_reviewed` will be the implementation date). Verify the output format matches the spec.

4. **Missing metadata detection**: Temporarily remove `meta` from one file's frontmatter and re-run `/work-skill-update`. Verify it reports the file as MISSING.

5. **File inventory completeness**: Run `find claude/skills -name '*.md' -not -path '*/references/*' && find claude/commands -name '*.md'` and verify every file has a `meta` block.
