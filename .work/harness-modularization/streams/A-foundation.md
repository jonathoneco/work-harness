# Stream A: Foundation

**Phase:** 1 (runs first, all other streams depend on this)
**Work Items:** W-01 (rag-nq7ut), W-02 (rag-3rpm0), W-03 (rag-u5br4)
**Execution Order:** Sequential — W-01 → W-02 → W-03
**Dependencies:** None (first stream)

---

## Overview

This stream creates the repo skeleton and the two foundational shell libraries that all other components depend on. Everything runs sequentially because W-02 and W-03 need the directory structure from W-01.

---

## W-01: Repo Scaffold — spec 01

**Issue:** rag-nq7ut
**Spec:** `.work/harness-modularization/specs/01-repo-scaffold.md`

### Files to Create

```
claude-work-harness/
  VERSION                           # "1.0.0" (no trailing newline)
  README.md                         # Project description, install instructions
  LICENSE                           # MIT
  .gitignore                        # OS files, editor files, .env
  install.sh                        # Stub (#!/bin/sh + set -eu + echo placeholder)
  claude/
    commands/.gitkeep
    skills/.gitkeep
    skills/code-quality/references/.gitkeep
    agents/.gitkeep
    rules/.gitkeep
  hooks/.gitkeep
  lib/.gitkeep
  templates/.gitkeep
```

### Acceptance Criteria

1. All directories from spec 00 §1 "Harness Repo Paths" exist
2. VERSION contains `1.0.0` with no trailing newline
3. install.sh is executable (`chmod +x`)
4. .gitignore covers OS files, editor files, .env
5. README.md includes project name, description, install instructions placeholder
6. No empty directories (use .gitkeep where needed)

### On Completion

```bash
bd close rag-nq7ut --reason="Repo scaffold created with all directories, VERSION, README, LICENSE"
```

---

## W-02: Config Reader (lib/config.sh) — spec 02

**Issue:** rag-3rpm0
**Spec:** `.work/harness-modularization/specs/02-config-reader.md`

### Files to Create

```
lib/config.sh                      # Sourced library, not executable
```

### Functions to Implement

1. `_harness_normalize_yq_output` — internal helper, suppresses yq "null"
2. `harness_has_config [<dir>]` — check if `.claude/harness.yaml` exists
3. `harness_validate_config [<dir>]` — validate YAML + required fields (schema_version, project.name)
4. `harness_config_get <key> [<dir>]` — read scalar value
5. `harness_config_list <key> [<dir>]` — read array, one element per line
6. `harness_dir` — resolve harness installation path (HARNESS_DIR env → manifest fallback)

### Key Requirements

- POSIX sh (no bashisms except `$(( ))` which is POSIX)
- yq dependency check at source time: exits 2 if missing (R1)
- All functions use `harness_` prefix (spec 00 §2)
- Exit 2 on malformed YAML (R2)
- `_HARNESS_CONFIG=".claude/harness.yaml"` constant
- All functions accept optional `[<dir>]` param defaulting to `$PWD`
- Sourcing with no args produces no output or side effects

### Testing

Run against test fixtures per spec 02 §7 (12 test cases). Key verifications:
- Source lib without output
- Read scalars, nulls, missing keys
- Read arrays
- Validate good/bad/missing-field configs
- harness_dir with/without HARNESS_DIR env

### Acceptance Criteria

1. POSIX sh, no bashisms
2. Sourcing produces no output
3. yq missing → exit 2 with descriptive stderr
4. harness_has_config returns 0/1 correctly
5. harness_validate_config catches malformed YAML and missing fields
6. harness_config_get returns scalars, empty for null/missing
7. harness_config_list returns one per line, empty for null/empty
8. harness_dir resolves via env then manifest
9. All error messages use `harness:` prefix to stderr

### On Completion

```bash
bd close rag-3rpm0 --reason="Config reader library implemented with all 5 public functions"
```

---

## W-03: Settings Merger (lib/merge.sh) — spec 03

**Issue:** rag-u5br4
**Spec:** `.work/harness-modularization/specs/03-settings-merger.md`

### Files to Create

```
lib/merge.sh                       # Sourced library, not executable
```

### Functions to Implement

1. `harness_merge_hooks <settings_json> <hooks_json>` — append hooks to settings
2. `harness_demerge_hooks <settings_json> <manifest_json>` — remove harness hooks
3. `harness_merge_settings <settings_json> <hooks_json>` — top-level orchestrator

### Key Requirements

- POSIX sh, jq dependency check at source time
- Append-only hook merge: never overwrite user entries
- Dedup by command path (same event+matcher+command = skip)
- Atomic writes: capture to variable, write to temp, `mv` to target
- Exit 2 on jq failures

### Testing

Run against test fixtures per spec 03 §7 (17 test cases). Key verifications:
- Merge into empty settings
- Merge preserving existing user hooks
- Idempotent (merge twice = same result)
- Demerge removes only harness hooks
- Round-trip: merge then demerge = original

### Acceptance Criteria

1. POSIX sh, no bashisms
2. jq missing → exit 2 with descriptive stderr
3. Merge appends hooks without overwriting
4. Dedup prevents duplicate entries
5. Demerge removes only manifest-listed hooks
6. Atomic writes (no partial JSON on failure)
7. All error messages use `harness:` prefix

### On Completion

```bash
bd close rag-u5br4 --reason="Settings merger library implemented with merge/demerge/orchestrator"
```
