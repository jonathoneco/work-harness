# Spec C14: install.sh Updates

**Component**: C14 — install.sh updates
**Phase**: 4 (Integration)
**Status**: complete
**Dependencies**: C08 (workflow-meta command), C09 (dev-update), C10 (work-dump), C13 (work-skill-update)

---

## Overview and Scope

Verifies that all new files from W4 are properly discovered by install.sh and documents any install.sh code changes needed (expected: none, due to auto-discovery).

**What this does**:
- Verifies all new files are in auto-discoverable locations
- Bumps the VERSION file
- Documents the full file inventory added by W4

**What this does NOT do**:
- Add new flags to install.sh (no `--rules` flag -- deferred to futures)
- Change hook registrations (no new hooks in W4)
- Modify the install/update/uninstall logic

---

## Implementation Steps

### Step 1: Verify Auto-Discovery of All New Files

Run `harness_list_content_files` (via `(cd claude && find . -type f ! -name '.gitkeep' | sed 's|^\./||' | sort)`) and confirm all W4 files appear:

**New files to verify** (from all component specs):

| Source Spec | File Path | Type |
|-------------|-----------|------|
| C01 | `skills/code-quality/references/python-anti-patterns.md` | Language pack |
| C01 | `skills/code-quality/references/typescript-anti-patterns.md` | Language pack |
| C01 | `skills/code-quality/references/rust-anti-patterns.md` | Language pack |
| C02 | `skills/code-quality/references/react-anti-patterns.md` | Framework pack |
| C02 | `skills/code-quality/references/nextjs-anti-patterns.md` | Framework pack |
| C08 | `commands/workflow-meta.md` | Command |
| C09 | `commands/dev-update.md` | Command |
| C09 | `skills/work-harness/dev-update.md` | Skill |
| C10 | `commands/work-dump.md` | Command |
| C13 | `commands/work-skill-update.md` | Command |
| C13 | `skills/work-harness/skill-lifecycle.md` | Skill |
| C12 | `skills/work-harness/agency-curation.md` | Skill |

**Total new files**: 12

All are under `claude/` and will be auto-discovered by `harness_list_content_files`. No install.sh code changes needed for file registration.

**Acceptance Criteria**:
- AC-C14-1.1: All 12 new files appear in the output of `harness_list_content_files`
- AC-C14-1.2: No install.sh code changes are needed for file registration

### Step 2: Bump VERSION File

Update the `VERSION` file with a minor version bump (new commands = MINOR per workflow-meta.md conventions).

Read current version, bump the minor component:
```bash
cat VERSION  # e.g., "0.5.0"
# Bump to "0.6.0"
```

**Acceptance Criteria**:
- AC-C14-2.1: VERSION file is updated with a minor version bump
- AC-C14-2.2: VERSION file contains a single line, no `v` prefix, no trailing newline

### Step 3: Update Workflow.md Command Table

The `claude/rules/workflow.md` command table must be updated to include the new commands. Add entries for:

| Command | Purpose |
|---------|---------|
| `/workflow-meta` | Enter harness self-modification mode |
| `/dev-update` | Generate developer status update |
| `/work-dump` | Decompose work into scoped workflows |
| `/work-skill-update` | Scan skills for staleness |

**Acceptance Criteria**:
- AC-C14-3.1: `workflow.md` command table includes all 4 new commands
- AC-C14-3.2: Command descriptions match the `description` field in each command's frontmatter

### Step 4: Verify No Hook Changes Needed

Confirm no new hooks are introduced by W4. The hook registration in `harness_hook_entries()` should remain unchanged.

**Acceptance Criteria**:
- AC-C14-4.1: `harness_hook_entries()` is unchanged from the pre-W4 state

### Step 5: Run Full Install Verification

Run install.sh in a clean test environment to verify:
1. All new files are copied
2. No conflicts with existing files
3. Manifest includes all new files

```bash
CLAUDE_DIR=/tmp/test-install ./install.sh --force
# Verify all 12 new files exist in /tmp/test-install/
```

**Acceptance Criteria**:
- AC-C14-5.1: Clean install succeeds with no errors
- AC-C14-5.2: All 12 new files are present in the target directory
- AC-C14-5.3: Manifest JSON includes all 12 new files in the `files` array

---

## Interface Contracts

### Exposes

- **Updated VERSION**: Reflects the new minor version
- **Updated workflow.md**: Command table includes all new commands
- **Install verification**: Confirmed all W4 files are installable

### Consumes

- **All W4 component specs**: Files created by C01-C13
- **Spec 00 Contract 4**: Auto-discovery convention (verified, not implemented)

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `VERSION` | Minor version bump |
| Modify | `claude/rules/workflow.md` | Add 4 new commands to table |

**Total**: 0 new files, 2 modified files

Note: install.sh itself is NOT modified. All file registration is handled by auto-discovery.

---

## Testing Strategy

1. **File discovery**: Run `(cd claude && find . -type f ! -name '.gitkeep' | sed 's|^\./||' | sort)` and verify all 12 new files appear in the output.

2. **Clean install**: Run `CLAUDE_DIR=/tmp/test-install ./install.sh --force` and verify all files are copied.

3. **Update from previous version**: Run `./install.sh --update` from a previous installation. Verify new files are reported as "added" and existing files as "unchanged" or "changed".

4. **Command table sync**: Count commands in `claude/commands/` and compare with the command table in `workflow.md`. Counts should match.

5. **Hook unchanged**: Compare `harness_hook_entries` output before and after W4. Should be identical.
