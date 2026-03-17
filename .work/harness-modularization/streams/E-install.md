# Stream E: Install Script

**Phase:** 3 (runs after Phase 2 — Streams B, C, D must complete)
**Work Items:** W-10 (rag-d4xkc)
**Execution Order:** Single item
**Dependencies:** All Phase 2 items must complete — W-02 (config reader), W-03 (settings merger), W-04 (commands), W-05 (skills), W-06 (agents), W-07 (rules), W-08 (hooks), W-09 (migrator), W-11 (harness-init), W-12 (harness-update), W-13 (harness-doctor). The install script copies `claude/**` content files produced by Streams B and D, sources libraries from Stream A, and registers hooks from Stream C.

---

## Overview

This is the integration point. The install script orchestrates all libraries (config.sh, merge.sh, migrate.sh), copies content files, registers hooks, updates CLAUDE.md, and writes the manifest. It's the largest single spec (827 lines) and the terminal node on the critical path.

---

## W-10: Install Script (install.sh) — spec 10

**Issue:** rag-d4xkc
**Spec:** `.work/harness-modularization/specs/10-install-script.md`

### Files to Create/Modify

```
install.sh                         # Replace stub from W-01
```

### Three Modes (spec 10 §3)

#### Install Mode (`./install.sh` or `./install.sh install`)
1. Check dependencies (jq, yq)
2. Read VERSION file
3. Determine CLAUDE_DIR (`$CLAUDE_DIR` env override or `~/.claude`)
4. Copy content files from `claude/` → `$CLAUDE_DIR/` with conflict detection
5. Register hooks in `$CLAUDE_DIR/settings.json` via `harness_merge_hooks`
6. Append/update CLAUDE.md tagged block (`<!-- harness:start -->` ... `<!-- harness:end -->`)
7. Write manifest to `$CLAUDE_DIR/.harness-manifest.json`

#### Update Mode (`./install.sh update`)
1. Read existing manifest
2. Copy content files (overwrite harness files, skip conflicts)
3. Re-merge hooks (idempotent)
4. Update CLAUDE.md block
5. Update manifest (new version, updated_at, file list)

#### Uninstall Mode (`./install.sh uninstall`)
1. Read manifest
2. Remove manifest-listed files from `$CLAUDE_DIR/`
3. De-merge hooks from settings.json via `harness_demerge_hooks`
4. Remove CLAUDE.md tagged block
5. Remove manifest file

### Conflict Detection (resolves DQ5)
- Before copying each file: check if target exists AND is NOT listed in current manifest
- If conflict: print warning to stderr, skip file
- `--force` flag: overwrite conflicts (user explicitly requested)
- Never silently overwrite user files

### CLAUDE.md Tag Management (resolves DQ2)
- Tags: `<!-- harness:start -->` and `<!-- harness:end -->`
- Install: append block if no tags found, replace content between tags if found
- Uninstall: remove everything between and including tags
- Create file if it doesn't exist

### Key Requirements

- POSIX sh, `set -eu`
- Sources `lib/config.sh`, `lib/merge.sh`, `lib/migrate.sh`
- `CLAUDE_DIR` env var override for testing (default: `~/.claude`)
- Atomic manifest writes (write to temp, mv to target)
- 34 implementation steps (spec 10 §5)
- 32 acceptance criteria (spec 10 §9)

### Acceptance Criteria (critical subset — see spec 10 §9 for full list)

1. All three modes work (install/update/uninstall)
2. Conflict detection warns and skips non-manifest files
3. `--force` overrides conflict detection
4. CLAUDE.md tags work for create/update/remove
5. Manifest tracks all installed files and hooks
6. Hook merge is idempotent
7. Uninstall removes only harness-owned resources
8. CLAUDE_DIR override works for testing
9. Dependencies checked before operations
10. Atomic manifest writes (no partial JSON)

### Testing Strategy

1. Fresh install to empty CLAUDE_DIR → verify all files, hooks, CLAUDE.md, manifest
2. Update existing install → verify files updated, hooks idempotent
3. Install with user conflicts → verify warn + skip
4. Install with `--force` → verify overwrite
5. Uninstall → verify clean removal, user files preserved
6. Round trip: install → uninstall → verify CLAUDE_DIR clean
7. CLAUDE_DIR override → verify no writes to real `~/.claude`

### On Completion

```bash
bd close rag-d4xkc --reason="Install script with 3 modes, conflict detection, CLAUDE.md tags, manifest"
```
