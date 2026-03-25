# Spec C04: Pack Discovery Extension

**Component**: C04 — Pack discovery extension
**Phase**: 1 (Foundation)
**Status**: complete
**Dependencies**: Spec 00 (file placement conventions, naming)

---

## Overview and Scope

Extends the `code-quality.md` skill to discover and load framework packs and frontend packs alongside the existing language pack discovery. Currently, `code-quality.md` only reads `references/<language>-anti-patterns.md` based on `stack.language`. This spec adds directives for `stack.framework` and `stack.frontend` using the same file-presence discovery pattern.

**What this does**:
- Adds framework pack discovery directive to `code-quality.md`
- Adds frontend pack discovery directive to `code-quality.md`
- Documents graceful skip behavior when fields are absent from `harness.yaml`

**What this does NOT do**:
- Create the actual pack files (that's C01, C02, C03)
- Change `harness.yaml` schema (framework/frontend fields already exist)
- Change install.sh (auto-discovery handles new files per Spec 00 Contract 4)

---

## Implementation Steps

### Step 1: Add Framework Pack Discovery Directive

In `claude/skills/code-quality.md`, after the existing "Language-Specific Anti-Patterns" section, add a new section:

```markdown
## Framework-Specific Anti-Patterns

Read `references/<framework>-anti-patterns.md` where `<framework>` is `stack.framework`
from `.claude/harness.yaml`. If no `harness.yaml` exists, `stack.framework` is absent,
or no matching file exists, skip this section.

Adding a new framework pack requires only creating one file at `references/<framework>-anti-patterns.md` — no changes to this file or any other file are needed.
```

This mirrors the existing language pack directive structure exactly.

**Acceptance Criteria**:
- AC-C04-1.1: `code-quality.md` contains a "Framework-Specific Anti-Patterns" section
- AC-C04-1.2: The directive references `stack.framework` from `harness.yaml`
- AC-C04-1.3: The directive specifies the file pattern `references/<framework>-anti-patterns.md`
- AC-C04-1.4: Skip behavior is documented for: no harness.yaml, absent field, no matching file

### Step 2: Add Frontend Pack Discovery Directive

In `code-quality.md`, after the framework section, add:

```markdown
## Frontend-Specific Anti-Patterns

Read `references/<frontend>-anti-patterns.md` where `<frontend>` is `stack.frontend`
from `.claude/harness.yaml`. If no `harness.yaml` exists, `stack.frontend` is absent,
or no matching file exists, skip this section.

Adding a new frontend pack requires only creating one file at `references/<frontend>-anti-patterns.md` — no changes to this file or any other file are needed.
```

**Acceptance Criteria**:
- AC-C04-2.1: `code-quality.md` contains a "Frontend-Specific Anti-Patterns" section
- AC-C04-2.2: The directive references `stack.frontend` from `harness.yaml`
- AC-C04-2.3: The directive specifies the file pattern `references/<frontend>-anti-patterns.md`
- AC-C04-2.4: Skip behavior is documented for: no harness.yaml, absent field, no matching file

### Step 3: Generalize Existing Language Directive Wording (Optional Polish)

Update the existing "Language-Specific Anti-Patterns" section to be consistent with the new sections. The current wording already includes skip behavior but could be harmonized. Specifically, ensure it includes the same "no harness.yaml exists" clause:

Current:
> If no `harness.yaml` exists or `stack.language` is `other`, skip this section.

Updated:
> If no `harness.yaml` exists, `stack.language` is absent or `other`, or no matching file exists, skip this section.

This adds the "no matching file exists" clause for consistency with framework/frontend sections.

**Acceptance Criteria**:
- AC-C04-3.1: Language pack directive includes "no matching file exists" skip clause
- AC-C04-3.2: All three directives (language, framework, frontend) use consistent wording

### Step 4: Add `meta` Block to `code-quality.md`

Per Spec 00 Contract 2 and Spec C13, update the `meta` block:

```yaml
meta:
  stack: ["all"]
  version: 2          # bumped from 1 due to discovery extension
  last_reviewed: 2026-03-24
```

**Acceptance Criteria**:
- AC-C04-4.1: `code-quality.md` frontmatter includes `meta` block with version 2

---

## Interface Contracts

### Exposes

- **Framework pack discovery**: Agents reading `code-quality.md` will look for `references/<framework>-*.md` based on `stack.framework`
- **Frontend pack discovery**: Same pattern for `stack.frontend`
- **File-presence convention**: New packs added by creating files require zero changes to discovery logic

### Consumes

- **`harness.yaml`**: Reads `stack.framework` and `stack.frontend` fields (already defined in schema)
- **Spec 00 Contract 4**: File placement conventions for pack files

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/skills/code-quality.md` | Add framework and frontend discovery directives |

**Total**: 0 new files, 1 modified file

---

## Testing Strategy

1. **Directive presence**: Read `code-quality.md` and verify all three sections exist: "Language-Specific Anti-Patterns", "Framework-Specific Anti-Patterns", "Frontend-Specific Anti-Patterns"

2. **Graceful skip**: In a project without `harness.yaml`, verify `code-quality.md` does not cause errors (sections are skipped). In a project with `harness.yaml` but no `stack.framework`, verify the framework section is skipped without error.

3. **File-presence discovery**: Create a test file `references/test-anti-patterns.md` and set `stack.framework: test` in a harness.yaml. Verify the framework directive would load it. Remove the test file after.

4. **Consistency check**: All three directives use the same wording pattern for skip behavior.
