# Spec 10: Install Script (C7)

**Component:** C7 — Install Script (`install.sh`)
**Phase:** 3 (Install)
**Scope:** Large (hardest component)
**Dependencies:** C1 (scaffold), C8 (settings merger), C9 (schema migrator), C10 (config reader), C2-C6 (content + hooks to install)
**References:** [architecture.md](architecture.md), [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md), [08-hooks.md](08-hooks.md), [09-schema-migrator.md](09-schema-migrator.md)
**Resolves:** DQ2 (CLAUDE.md appended content), DQ5 (conflict detection)

---

## 1. Overview

`install.sh` is the single entry point for installing, updating, and uninstalling the work harness. It operates in three modes selected by flags:

| Flag | Mode | Description |
|------|------|-------------|
| (none) or `--install` | Install | Fresh installation to `~/.claude/` |
| `--update` | Update | Diff-based update of existing installation |
| `--uninstall` | Uninstall | Clean removal of all harness artifacts |
| `--force` | Modifier | Forces install mode even if manifest exists (recovery from corruption) |

The script is self-contained at the harness repo root. It sources helper libraries from `lib/` and operates on the content in `claude/` and `hooks/`.

### Key Design Principles

1. **Idempotent install:** Running `./install.sh` twice produces the same result as running it once.
2. **Clean uninstall:** After `--uninstall`, no harness artifacts remain in `~/.claude/`.
3. **Conflict-safe:** Never overwrites files that exist but aren't harness-managed.
4. **Manifest-driven:** Every installed artifact is tracked in the manifest for reliable update/uninstall.
5. **Fail-closed:** Dependency failures, corrupted manifests, and parse errors are hard errors, not silent fallbacks.

---

## 2. Mode Details

### 2.1 Install Mode (default / `--install`)

**Precondition:** No manifest exists at `~/.claude/.harness-manifest.json`, OR `--force` is passed.

**Flow:**

```
1. Verify dependencies (jq, yq, git, bd)
2. Check for existing manifest
   ├─ If exists and no --force → error: "already installed, use --update"
   └─ If exists and --force → warn, continue (treats as fresh install)
3. Create ~/.claude/ if it doesn't exist
4. Copy content files (claude/ → ~/.claude/)
   ├─ For each file in claude/**:
   │   ├─ Compute target: ~/.claude/<relative-path>
   │   ├─ If target exists and not in manifest → CONFLICT (see section 4)
   │   └─ Otherwise → mkdir -p parent, cp file
   └─ Record all copied files in files[] for manifest
5. Merge hooks into ~/.claude/settings.json
   ├─ Source lib/merge.sh
   ├─ Call harness_merge_hooks (adds hook entries per spec 08 table)
   └─ Record added hooks in hooks_added[] for manifest
6. Append harness block to ~/.claude/CLAUDE.md (see section 3)
7. Write manifest to ~/.claude/.harness-manifest.json
8. Print summary: N files installed, M hooks registered
9. Check for agency-agents and print suggestion if not found
```

### 2.2 Update Mode (`--update`)

**Precondition:** Manifest exists and is valid JSON.

**Flow:**

```
1. Verify dependencies
2. Read manifest
   ├─ If missing → error: "not installed, run install.sh first"
   ├─ If malformed JSON → error: "manifest corrupted, run install.sh --force" (R3)
   └─ If valid → continue
3. Compare repo content vs manifest
   ├─ New files (in repo but not in manifest.files) → copy, add to manifest
   ├─ Removed files (in manifest.files but not in repo) → delete from ~/.claude/, remove from manifest
   ├─ Changed files (in both, content differs) → overwrite in ~/.claude/
   ├─ Unchanged files → skip
   └─ Conflict check: if a new file's target exists and isn't in manifest → CONFLICT
4. Re-merge hooks
   ├─ Remove old harness hooks (from manifest.hooks_added)
   ├─ Add current harness hooks (from spec 08 table)
   └─ Update manifest.hooks_added
5. Update CLAUDE.md block (replace content between tags)
6. Check schema_version — run migrations if needed
   ├─ Source lib/migrate.sh
   ├─ manifest.schema_version < HARNESS_CURRENT_SCHEMA_VERSION → migrate
   └─ This migrates project harness.yaml files, NOT global files
7. Update manifest (version, updated_at, files, hooks_added)
8. Print summary: N added, M removed, K updated, J unchanged
```

**Schema migration scope clarification:** `install.sh --update` migrates the harness infrastructure (global files, hooks). It does NOT automatically find and migrate all project `harness.yaml` files. Project-level migration happens when the user runs `/harness-update` inside a project (C12), or when a hook encounters an outdated `schema_version` and warns.

The manifest's `schema_version` tracks the installed harness's expected schema version — it's updated to `HARNESS_CURRENT_SCHEMA_VERSION` after install/update so that `/harness-doctor` can compare it against each project's `harness.yaml`.

### 2.3 Uninstall Mode (`--uninstall`)

**Precondition:** Manifest exists and is valid JSON.

**Flow:**

```
1. Read manifest
   ├─ If missing → error: "nothing to uninstall"
   ├─ If malformed → error: "manifest corrupted, remove manually or run install.sh --force then --uninstall" (R3)
   └─ If valid → continue
2. Remove all files in manifest.files from ~/.claude/
   ├─ For each file: rm -f ~/.claude/<file>
   ├─ Remove empty parent directories (rmdir if empty)
   └─ Warn (don't fail) if a file is already missing
3. De-merge hooks from ~/.claude/settings.json
   ├─ Source lib/merge.sh
   ├─ Call harness_demerge_hooks (removes entries matching manifest.hooks_added)
   └─ If settings.json has no remaining hooks, leave the empty hooks object
4. Remove harness block from ~/.claude/CLAUDE.md
   ├─ Remove everything between <!-- harness:start --> and <!-- harness:end --> inclusive
   ├─ If CLAUDE.md becomes empty, remove it
   └─ If tags not found, warn but continue
5. Remove manifest file
6. Print summary: N files removed, M hooks deregistered, harness uninstalled
```

---

## 3. CLAUDE.md Management (DQ2 Resolution)

### Content Appended

The exact block appended to `~/.claude/CLAUDE.md`:

```markdown
<!-- harness:start -->
## Work Harness

This environment uses the [claude-work-harness](https://github.com/<user>/claude-work-harness).
Commands, skills, agents, and rules are installed globally. Projects customize via `.claude/harness.yaml`.

See `/harness-doctor` to check health. See `/harness-update` to check compatibility.
<!-- harness:end -->
```

This matches spec 00 section 7 exactly.

### Operations

| Operation | Behavior |
|-----------|----------|
| **Install** (no CLAUDE.md) | Create `~/.claude/CLAUDE.md` with just the harness block |
| **Install** (CLAUDE.md exists, no tags) | Append block at end of file with a preceding blank line |
| **Install** (CLAUDE.md exists, tags present) | Replace content between tags (idempotent) |
| **Update** | Replace content between tags |
| **Uninstall** | Remove lines from `<!-- harness:start -->` through `<!-- harness:end -->` inclusive. If file becomes empty (only whitespace), remove it. |

### Implementation

Tag-based operations use `sed`:

```sh
# Check for existing tags
if grep -q '<!-- harness:start -->' "$claude_md"; then
  # Replace between tags (inclusive of content, exclusive of tags, then replace tags too)
  # Use temp file for portability
  sed '/<!-- harness:start -->/,/<!-- harness:end -->/d' "$claude_md" > "$tmpfile"
  # Then append the new block
  cat "$HARNESS_DIR/lib/claude-md-block.txt" >> "$tmpfile"
  mv "$tmpfile" "$claude_md"
else
  # Append
  printf '\n' >> "$claude_md"
  cat "$HARNESS_DIR/lib/claude-md-block.txt" >> "$claude_md"
fi
```

The harness block content lives in a separate file (`lib/claude-md-block.txt`) so it's easy to update without modifying install.sh logic. This file is not copied to `~/.claude/` — it's a build resource.

---

## 4. Conflict Detection (DQ5 Resolution)

A **conflict** occurs when install.sh would copy a file to a target path that:
1. Already exists in `~/.claude/`, AND
2. Is NOT listed in the manifest's `files[]` array

This means the file was put there by the user (or another tool), not by a previous harness install.

### Behavior

| Mode | Conflict Handling |
|------|-------------------|
| **Install** (no `--force`) | Warn per file, skip it, continue with remaining files. Print summary of skipped files at end. |
| **Install** (`--force`) | Overwrite. The old file is lost. Warn that files were overwritten. |
| **Update** | Same as install without --force: warn and skip conflicts for new files. Changed files that are in the manifest are NOT conflicts — they're expected updates. |

### Example Output

```
harness: conflict: ~/.claude/rules/workflow.md exists but is not harness-managed
harness: conflict: skipping (use --force to overwrite)
...
harness: install complete. 15 files installed, 2 skipped due to conflicts.
harness: skipped files:
  rules/workflow.md
  skills/code-quality.md
```

### Post-Conflict State

Skipped files are NOT added to the manifest. This means:
- `--update` will attempt to copy them again (and skip again if still conflicting)
- `--uninstall` will NOT remove them (they're not harness-managed)
- `/harness-doctor` should report files that exist locally but differ from harness versions

---

## 5. Implementation Steps

### Phase A: Script Skeleton

- [ ] **5.1** Create `install.sh` at repo root (replace stub from C1)
- [ ] **5.2** Add POSIX shebang, header, `set -eu`
- [ ] **5.3** Parse flags: `--install` (default), `--update`, `--uninstall`, `--force`
- [ ] **5.4** Resolve `HARNESS_DIR` from script location: `HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"`
- [ ] **5.5** Define constants: `CLAUDE_DIR="$HOME/.claude"`, `MANIFEST="$CLAUDE_DIR/.harness-manifest.json"`
- [ ] **5.6** Source `lib/config.sh`, `lib/merge.sh`, `lib/migrate.sh`
- [ ] **5.7** Implement dependency verification function

### Phase B: Install Mode

- [ ] **5.8** Implement manifest existence check (error if exists without --force)
- [ ] **5.9** Implement file copy with conflict detection
- [ ] **5.10** Implement hook merge (call `harness_merge_hooks`)
- [ ] **5.11** Implement CLAUDE.md append
- [ ] **5.12** Implement manifest write
- [ ] **5.13** Implement agency-agents suggestion check
- [ ] **5.14** Implement summary output

### Phase C: Update Mode

- [ ] **5.15** Implement manifest read with corruption handling (R3)
- [ ] **5.16** Implement repo-vs-manifest diff (new, removed, changed, unchanged)
- [ ] **5.17** Implement file copy for new/changed files with conflict detection
- [ ] **5.18** Implement file removal for removed files
- [ ] **5.19** Implement hook de-merge + re-merge
- [ ] **5.20** Implement CLAUDE.md tag replacement
- [ ] **5.21** Implement schema version check + migration call
- [ ] **5.22** Implement manifest update
- [ ] **5.23** Implement summary output (added/removed/updated/unchanged counts)

### Phase D: Uninstall Mode

- [ ] **5.24** Implement manifest read with corruption handling (R3)
- [ ] **5.25** Implement file removal with empty directory cleanup
- [ ] **5.26** Implement hook de-merge
- [ ] **5.27** Implement CLAUDE.md tag removal
- [ ] **5.28** Implement manifest removal
- [ ] **5.29** Implement summary output

### Phase E: Hardening

- [ ] **5.30** Test idempotent install (run twice, same result)
- [ ] **5.31** Test install → uninstall → install (clean round-trip)
- [ ] **5.32** Test conflict detection (pre-existing user file)
- [ ] **5.33** Test corrupted manifest handling for --update and --uninstall
- [ ] **5.34** Test missing dependencies error messages
- [ ] **5.35** Verify `shellcheck -s sh install.sh` passes
- [ ] **5.36** Create `lib/claude-md-block.txt` with harness block content

---

## 6. Dependency Verification

### Required Dependencies

| Dependency | Used By | Check |
|-----------|---------|-------|
| `jq` | Manifest read/write, settings merge | `command -v jq` |
| `yq` | Config reading, migrations | `command -v yq` |
| `git` | Version detection, diff for updates | `command -v git` |
| `bd` (beads) | Beads workflow enforcement | `command -v bd` |

### Verification Function

```sh
harness_check_deps() {
  _missing=""
  for _dep in jq yq git bd; do
    if ! command -v "$_dep" >/dev/null 2>&1; then
      _missing="$_missing $_dep"
    fi
  done
  if [ -n "$_missing" ]; then
    echo "harness: missing required dependencies:$_missing" >&2
    echo "harness: install them and retry. See README.md for details." >&2
    return 2
  fi
}
```

**Dependency check timing:** Run at the start of every mode (install, update, uninstall). Even uninstall needs jq (to read the manifest) and potentially yq.

### Optional Dependencies

| Dependency | Used By | Behavior When Missing |
|-----------|---------|----------------------|
| `gh` (GitHub CLI) | pr-gate.sh (at runtime) | Hook skips PR check, exits 0 |
| `shellcheck` | Development only | Not required for install |

---

## 7. Manifest Management

### Writing the Manifest

```sh
harness_write_manifest() {
  _version=$(cat "$HARNESS_DIR/VERSION")
  _now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  _files_json="$1"      # JSON array string of file paths
  _hooks_json="$2"      # JSON array string of hook entries

  jq -n \
    --arg version "$_version" \
    --arg dir "$HARNESS_DIR" \
    --arg schema "$HARNESS_CURRENT_SCHEMA_VERSION" \
    --arg now "$_now" \
    --argjson files "$_files_json" \
    --argjson hooks "$_hooks_json" \
    '{
      harness_version: $version,
      harness_dir: $dir,
      schema_version: ($schema | tonumber),
      installed_at: $now,
      updated_at: $now,
      files: $files,
      hooks_added: $hooks,
      claude_md_tag: "harness"
    }' > "$MANIFEST"
}
```

On update, preserve `installed_at` from the existing manifest and only update `updated_at`.

### Reading the Manifest

```sh
harness_read_manifest() {
  if [ ! -f "$MANIFEST" ]; then
    echo "harness: not installed (no manifest found at $MANIFEST)" >&2
    return 2
  fi
  if ! jq empty "$MANIFEST" 2>/dev/null; then
    echo "harness: manifest is corrupted (invalid JSON)" >&2
    echo "harness: run 'install.sh --force' for a fresh install" >&2
    return 2
  fi
}
```

---

## 8. File Copy Logic

### Enumerating Repo Content

The install script enumerates all files under `claude/` in the repo:

```sh
# Find all files (not directories) under claude/
# Produces paths relative to claude/ (e.g., "commands/work.md")
harness_list_content_files() {
  (cd "$HARNESS_DIR/claude" && find . -type f ! -name '.gitkeep' | sed 's|^\./||' | sort)
}
```

### Copy with Conflict Detection

```sh
# Copy a file from repo to target, checking for conflicts.
# Args: $1=relative_path (e.g., "commands/work.md")
# Returns: 0=copied, 1=skipped (conflict), 2=error
harness_copy_file() {
  _rel="$1"
  _src="$HARNESS_DIR/claude/$_rel"
  _dst="$CLAUDE_DIR/$_rel"

  if [ -f "$_dst" ]; then
    # Target exists — is it in the manifest?
    if [ -n "$_manifest_files" ] && echo "$_manifest_files" | grep -qxF "$_rel"; then
      # Harness-managed — safe to overwrite
      :
    elif [ "$FORCE" = "true" ]; then
      echo "harness: overwriting non-managed file: $_rel" >&2
    else
      echo "harness: conflict: ~/.claude/$_rel exists but is not harness-managed" >&2
      echo "harness: conflict: skipping (use --force to overwrite)" >&2
      return 1
    fi
  fi

  # Create parent directory and copy
  mkdir -p "$(dirname "$_dst")"
  cp "$_src" "$_dst"
  return 0
}
```

### Diff Detection for Update Mode

```sh
# Compare repo file against installed file
# Returns: "new", "changed", "unchanged", or "removed"
harness_file_status() {
  _rel="$1"
  _src="$HARNESS_DIR/claude/$_rel"
  _dst="$CLAUDE_DIR/$_rel"

  if [ ! -f "$_src" ]; then
    echo "removed"
  elif [ ! -f "$_dst" ]; then
    echo "new"
  elif ! cmp -s "$_src" "$_dst"; then
    echo "changed"
  else
    echo "unchanged"
  fi
}
```

---

## 9. Hook Registration Data

The install script needs a definitive list of hooks and their registrations. This is defined as a function that outputs JSON, used by both manifest writing and merge.sh:

```sh
# Output the hook registration entries as a JSON array.
# Uses the harness directory to construct absolute paths.
harness_hook_entries() {
  _hdir="$1"  # harness directory
  cat <<HOOKS_EOF
[
  {"event":"PostToolUse","matcher":"Write|Edit","command":"$_hdir/hooks/state-guard.sh"},
  {"event":"Stop","matcher":"","command":"$_hdir/hooks/work-check.sh"},
  {"event":"Stop","matcher":"","command":"$_hdir/hooks/beads-check.sh"},
  {"event":"Stop","matcher":"","command":"$_hdir/hooks/review-gate.sh"},
  {"event":"Stop","matcher":"","command":"$_hdir/hooks/artifact-gate.sh"},
  {"event":"Stop","matcher":"","command":"$_hdir/hooks/review-verify.sh"},
  {"event":"PreToolUse","matcher":"Bash","command":"$_hdir/hooks/pr-gate.sh"}
]
HOOKS_EOF
}
```

This is the single source of truth for hook registrations, matching spec 08 section 2.

---

## 10. Interface Contracts

### Exposes

| What | Consumed By | Contract |
|------|------------|----------|
| `install.sh` CLI | Users | `./install.sh [--install\|--update\|--uninstall] [--force]` |
| `~/.claude/.harness-manifest.json` | C12 (harness-update), C13 (harness-doctor), hooks (via config.sh) | JSON per spec 00 section 5 |
| Installed content files | Claude Code runtime | Files at `~/.claude/{commands,skills,agents,rules}/` |
| Hook registrations | Claude Code runtime | Entries in `~/.claude/settings.json` per spec 08 |
| CLAUDE.md block | Claude Code runtime | Tagged block in `~/.claude/CLAUDE.md` per spec 00 section 7 |

### Consumes

| What | From | Contract |
|------|------|----------|
| `lib/merge.sh` | C8 | `harness_merge_hooks`, `harness_demerge_hooks` |
| `lib/migrate.sh` | C9 | `harness_migrate`, `HARNESS_CURRENT_SCHEMA_VERSION` |
| `lib/config.sh` | C10 | `harness_has_config`, `harness_validate_config` |
| `claude/**` | C2-C5 | Content files to copy |
| `hooks/*.sh` | C6 | Hook scripts (referenced by absolute path, not copied) |
| `VERSION` | C1 | Semver string for manifest |
| `lib/claude-md-block.txt` | Self | CLAUDE.md block content |
| `jq`, `yq`, `git`, `bd` | System | R1: verified at startup |

---

## 11. Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `install.sh` | Replace (stub from C1) | Full install/update/uninstall script |
| `lib/claude-md-block.txt` | Create | CLAUDE.md harness block content |

---

## 12. Testing Strategy

### Automated Test Script

```sh
#!/bin/sh
# test-install.sh — run from harness repo root
# Requires: jq, yq, git, bd
# WARNING: Operates on real ~/.claude/ — back up first or use CLAUDE_DIR override
set -eu

HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR=$(mktemp -d)
CLAUDE_DIR="$TEST_DIR/claude"
MANIFEST="$CLAUDE_DIR/.harness-manifest.json"
export CLAUDE_DIR  # install.sh reads this

trap 'rm -rf "$TEST_DIR"' EXIT

pass=0
fail=0
report() {
  if [ "$1" = "PASS" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
  echo "$1: $2"
}

# --- Test: Fresh install ---
./install.sh
[ -f "$MANIFEST" ] && report PASS "manifest created" || report FAIL "manifest missing"
[ -f "$CLAUDE_DIR/commands/work.md" ] && report PASS "command installed" || report FAIL "command missing"
[ -f "$CLAUDE_DIR/settings.json" ] && report PASS "settings.json exists" || report FAIL "settings.json missing"
jq -e '.hooks.PostToolUse' "$CLAUDE_DIR/settings.json" >/dev/null && report PASS "hooks registered" || report FAIL "hooks not in settings"
grep -q 'harness:start' "$CLAUDE_DIR/CLAUDE.md" && report PASS "CLAUDE.md block" || report FAIL "CLAUDE.md block missing"

# --- Test: Idempotent install ---
./install.sh --force
file_count=$(jq '.files | length' "$MANIFEST")
[ "$file_count" -gt 0 ] && report PASS "idempotent install" || report FAIL "idempotent install"

# --- Test: Update (no changes) ---
./install.sh --update
report PASS "update with no changes"

# --- Test: Update (added file) ---
mkdir -p claude/commands
echo "test" > claude/commands/_test_file.md
./install.sh --update
[ -f "$CLAUDE_DIR/commands/_test_file.md" ] && report PASS "update adds new file" || report FAIL "update missed new file"
rm claude/commands/_test_file.md

# --- Test: Update (removed file) ---
./install.sh --update
[ ! -f "$CLAUDE_DIR/commands/_test_file.md" ] && report PASS "update removes file" || report FAIL "update didn't remove file"

# --- Test: Conflict detection ---
echo "user content" > "$CLAUDE_DIR/rules/user-custom.md"
mkdir -p claude/rules
echo "harness content" > claude/rules/user-custom.md
./install.sh --update 2>&1 | grep -q "conflict" && report PASS "conflict detected" || report FAIL "conflict not detected"
grep -q "user content" "$CLAUDE_DIR/rules/user-custom.md" && report PASS "conflict preserved user file" || report FAIL "conflict overwrote user file"
rm claude/rules/user-custom.md

# --- Test: Uninstall ---
./install.sh --uninstall
[ ! -f "$MANIFEST" ] && report PASS "manifest removed" || report FAIL "manifest remains"
[ ! -f "$CLAUDE_DIR/commands/work.md" ] && report PASS "files removed" || report FAIL "files remain"
grep -q 'harness:start' "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null && report FAIL "CLAUDE.md block remains" || report PASS "CLAUDE.md block removed"

# --- Test: Corrupted manifest (R3) ---
echo "not json" > "$MANIFEST"
./install.sh --update 2>&1 | grep -q "corrupted" && report PASS "R3: update rejects corrupt manifest" || report FAIL "R3: update accepted corrupt manifest"
./install.sh --uninstall 2>&1 | grep -q "corrupted" && report PASS "R3: uninstall rejects corrupt manifest" || report FAIL "R3: uninstall accepted corrupt manifest"
rm "$MANIFEST"

# --- Summary ---
echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
```

**Testing override:** `install.sh` should support a `CLAUDE_DIR` environment variable override (defaulting to `$HOME/.claude`). This enables testing without modifying the user's real `~/.claude/`.

### Manual Verification Checklist

- [ ] Fresh install on a machine with no `~/.claude/`
- [ ] Fresh install on a machine with existing `~/.claude/settings.json` (user has custom hooks)
- [ ] Update after adding a new command to `claude/commands/`
- [ ] Update after removing a skill from `claude/skills/`
- [ ] Uninstall + verify no traces remain
- [ ] Install → user creates overlapping file → update → conflict detected
- [ ] Install → corrupt manifest → update → error with recovery instructions
- [ ] Install → corrupt manifest → --force → clean recovery

---

## 13. Edge Cases and Error Handling

| Scenario | Mode | Handling |
|----------|------|----------|
| `~/.claude/` doesn't exist | Install | Create it (`mkdir -p`) |
| `~/.claude/settings.json` doesn't exist | Install | Create it with just the hooks object |
| `~/.claude/settings.json` has no `hooks` key | Install | Add `hooks` key with harness entries |
| `~/.claude/settings.json` has existing user hooks | Install | Preserve them, append harness hooks (C8 merge) |
| `~/.claude/CLAUDE.md` doesn't exist | Install | Create it with harness block |
| `~/.claude/CLAUDE.md` exists, no tags | Install | Append harness block at end |
| `~/.claude/CLAUDE.md` exists, has tags | Install | Replace between tags (idempotent) |
| Manifest exists, no `--force` | Install | Error: "already installed, use --update or --force" |
| Manifest doesn't exist | Update | Error: "not installed, run install.sh first" |
| Manifest is corrupted | Update | Error: "manifest corrupted, run install.sh --force" (R3) |
| Manifest is corrupted | Uninstall | Error: "manifest corrupted, remove manually or --force then --uninstall" (R3) |
| Manifest `harness_dir` differs from current `$HARNESS_DIR` | Update | Update `harness_dir` in manifest (user moved the repo) |
| File in manifest but missing from `~/.claude/` | Update | Re-copy it (self-healing) |
| File in manifest but missing from repo | Update | Remove from `~/.claude/` and manifest (content was deleted upstream) |
| Hook in manifest but script missing from repo | Update | Remove hook registration, warn |
| `settings.json` is malformed JSON | All | Error: "settings.json is not valid JSON — fix manually" |
| `CLAUDE_DIR` env var set | All | Use it instead of `$HOME/.claude` (for testing) |
| No write permission to `~/.claude/` | All | `mkdir -p` or `cp` fails — `set -eu` catches it |
| Very long file paths | All | No special handling; shell handles it |
| Interrupted install (Ctrl+C) | Install | Partial state. `--force` recovers. Manifest may not exist yet. |
| Disk full during copy | Install | `cp` fails, `set -eu` exits. Partial state. `--force` recovers. |
| Read-only `~/.claude/settings.json` | All | Write fails, `set -eu` exits. User must fix permissions. |

---

## 14. Script Structure

### Flag Parsing

```sh
MODE="install"
FORCE="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --install)   MODE="install" ;;
    --update)    MODE="update" ;;
    --uninstall) MODE="uninstall" ;;
    --force)     FORCE="true" ;;
    -h|--help)   usage; exit 0 ;;
    *)           echo "harness: unknown flag: $1" >&2; usage; exit 2 ;;
  esac
  shift
done
```

### Main Dispatch

```sh
case "$MODE" in
  install)   harness_install ;;
  update)    harness_update ;;
  uninstall) harness_uninstall ;;
esac
```

### Function Organization

```
install.sh
├── usage()                    — help text
├── harness_check_deps()       — verify jq, yq, git, bd
├── harness_install()          — install mode
├── harness_update()           — update mode
├── harness_uninstall()        — uninstall mode
├── harness_copy_file()        — copy one file with conflict check
├── harness_file_status()      — compare repo vs installed
├── harness_write_manifest()   — write manifest JSON
├── harness_read_manifest()    — read + validate manifest
├── harness_update_claude_md() — append/replace CLAUDE.md block
├── harness_remove_claude_md() — remove CLAUDE.md block
├── harness_hook_entries()     — JSON array of hook registrations
└── harness_check_agency()     — check for agency-agents companion
```

---

## 15. Agency-Agents Companion Check

At the end of install, the script checks for agency-agents:

```sh
harness_check_agency() {
  if [ -f "$CLAUDE_DIR/agents/code-reviewer.md" ]; then
    return  # agency-agents appears installed
  fi
  echo "" >&2
  echo "harness: Tip: Install agency-agents for domain-expertise review agents." >&2
  echo "harness: The work harness review routing works best with agents like code-reviewer," >&2
  echo "harness: security-reviewer, and devops-automator from agency-agents." >&2
  echo "harness: See: https://github.com/..." >&2
}
```

This is informational only — never blocks install.

---

## 16. Example Invocations

### Fresh Install

```sh
cd ~/src/claude-work-harness
./install.sh

# Output:
# harness: checking dependencies... ok
# harness: installing to /home/user/.claude/
# harness: copied 20 content files
# harness: registered 7 hooks in settings.json
# harness: appended harness block to CLAUDE.md
# harness: wrote manifest to .harness-manifest.json
# harness: install complete (v0.1.0)
#
# harness: Tip: Install agency-agents for domain-expertise review agents.
```

### Update After git pull

```sh
cd ~/src/claude-work-harness
git pull
./install.sh --update

# Output:
# harness: checking dependencies... ok
# harness: reading manifest... ok (v0.1.0)
# harness: comparing files...
# harness:   2 new, 1 changed, 0 removed, 17 unchanged
# harness: copied 3 files
# harness: hooks unchanged
# harness: CLAUDE.md block up to date
# harness: schema version unchanged (1)
# harness: updated manifest (v0.2.0)
# harness: update complete
```

### Uninstall

```sh
cd ~/src/claude-work-harness
./install.sh --uninstall

# Output:
# harness: checking dependencies... ok
# harness: reading manifest... ok
# harness: removing 20 content files...
# harness: deregistered 7 hooks from settings.json
# harness: removed harness block from CLAUDE.md
# harness: removed manifest
# harness: uninstall complete
```

### Force Recovery

```sh
# Manifest got corrupted somehow
./install.sh --update
# harness: manifest is corrupted (invalid JSON)
# harness: run 'install.sh --force' for a fresh install

./install.sh --force
# harness: checking dependencies... ok
# harness: --force: performing fresh install (ignoring existing manifest)
# harness: installing to /home/user/.claude/
# ...
```

### Conflict

```sh
# User has a custom rules/workflow.md
./install.sh
# harness: conflict: ~/.claude/rules/workflow.md exists but is not harness-managed
# harness: conflict: skipping (use --force to overwrite)
# ...
# harness: install complete. 19 files installed, 1 skipped due to conflicts.
# harness: skipped files:
#   rules/workflow.md
```

---

## 17. Acceptance Criteria

### Install Mode
- [ ] **AC-I.1** Creates `~/.claude/` if it doesn't exist
- [ ] **AC-I.2** Copies all files from `claude/` to `~/.claude/`
- [ ] **AC-I.3** Registers all 7 hooks in `~/.claude/settings.json`
- [ ] **AC-I.4** Preserves existing user hooks in `settings.json`
- [ ] **AC-I.5** Appends harness block to `~/.claude/CLAUDE.md`
- [ ] **AC-I.6** Writes manifest with correct file list and hook entries
- [ ] **AC-I.7** Errors if manifest already exists (without --force)
- [ ] **AC-I.8** With --force, overwrites despite existing manifest
- [ ] **AC-I.9** Detects and skips conflict files (warns user)
- [ ] **AC-I.10** With --force, overwrites conflict files
- [ ] **AC-I.11** Idempotent: running twice produces same result
- [ ] **AC-I.12** Prints agency-agents suggestion if not found

### Update Mode
- [ ] **AC-U.1** Reads and validates manifest
- [ ] **AC-U.2** Copies new files
- [ ] **AC-U.3** Removes deleted files
- [ ] **AC-U.4** Overwrites changed files
- [ ] **AC-U.5** Skips unchanged files
- [ ] **AC-U.6** Detects conflicts for new files
- [ ] **AC-U.7** Re-merges hooks (handles added/removed hooks between versions)
- [ ] **AC-U.8** Updates CLAUDE.md block content
- [ ] **AC-U.9** Runs schema migrations when needed
- [ ] **AC-U.10** Updates manifest timestamps and version
- [ ] **AC-U.11** Errors on missing manifest (R3)
- [ ] **AC-U.12** Errors on corrupted manifest with recovery instructions (R3)

### Uninstall Mode
- [ ] **AC-X.1** Removes all files listed in manifest
- [ ] **AC-X.2** Cleans up empty directories
- [ ] **AC-X.3** De-merges hooks from settings.json
- [ ] **AC-X.4** Removes harness block from CLAUDE.md
- [ ] **AC-X.5** Removes manifest file
- [ ] **AC-X.6** Leaves non-harness files untouched
- [ ] **AC-X.7** Errors on missing manifest
- [ ] **AC-X.8** Errors on corrupted manifest with recovery instructions (R3)

### Cross-Cutting
- [ ] **AC-C.1** Verifies all dependencies before any mode
- [ ] **AC-C.2** All error messages prefixed with `harness:`
- [ ] **AC-C.3** Exits 2 on any failure (per spec 00 exit codes)
- [ ] **AC-C.4** `CLAUDE_DIR` env var override works (for testing)
- [ ] **AC-C.5** No bashisms — `shellcheck -s sh install.sh` passes
- [ ] **AC-C.6** `--help` prints usage
