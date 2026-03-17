# Stream C: Infrastructure

**Phase:** 2 (runs after Phase 1 — Stream A must complete)
**Work Items:** W-08 (rag-cgew8), W-09 (rag-wzlyt)
**Execution Order:** Parallel within stream (no inter-dependencies)
**Dependencies:** W-02 (config reader — lib/config.sh must exist)

---

## Overview

This stream creates the hook scripts and schema migrator. Both depend on `lib/config.sh` (W-02) for config access. The hooks are the critical-path dependency for the install script (W-10).

---

## W-08: Hooks (7 hooks) — spec 08

**Issue:** rag-cgew8
**Spec:** `.work/harness-modularization/specs/08-hooks.md`

### Files to Create

```
hooks/
  state-guard.sh
  work-check.sh
  beads-check.sh
  review-gate.sh
  artifact-gate.sh
  review-verify.sh
  pr-gate.sh
```

### Hook Registration Table (from spec 08 §2, resolves DQ1)

| Hook | Event | Matcher | Description |
|------|-------|---------|-------------|
| state-guard.sh | PostToolUse | `Write\|Edit` | Validate .work/ state after file writes |
| work-check.sh | Stop | (empty) | Check work state before session ends |
| beads-check.sh | Stop | (empty) | Verify beads sync before session ends |
| review-gate.sh | Stop | (empty) | Enforce review findings resolution |
| artifact-gate.sh | Stop | (empty) | Validate work artifacts on stop |
| review-verify.sh | Stop | (empty) | Verify review step completion |
| pr-gate.sh | PreToolUse | `Bash` | Intercept git push, run format/lint/build |

### Common Preamble (all hooks)

```sh
#!/bin/sh
# harness: <description>
# Component: C6
set -eu

# Resolve harness directory
if [ -n "${HARNESS_DIR:-}" ]; then
  _harness_dir="$HARNESS_DIR"
elif [ -f "$HOME/.claude/.harness-manifest.json" ]; then
  _harness_dir=$(jq -r '.harness_dir // empty' "$HOME/.claude/.harness-manifest.json")
else
  exit 0  # Can't find harness, graceful skip
fi

# Source config reader
. "$_harness_dir/lib/config.sh"

# Check for harness config — graceful skip if absent
harness_has_config || exit 0
harness_validate_config
```

### Key Requirements

- POSIX sh (convert from current bash hooks)
- All hooks: graceful skip (exit 0) if no harness.yaml
- All hooks: validate config before proceeding (R2 → exit 2)
- `pr-gate.sh`: read build commands from harness.yaml (`build.format`, `build.lint`, `build.build`)
- `state-guard.sh`: receives hook context via stdin (JSON with tool name, file path)
- `review-gate.sh`: read anti_patterns from harness.yaml config
- Each hook is executable (`chmod +x`)
- Error messages use `harness:` prefix to stderr

### Testing

Per spec 08 testing strategy:
- Test each hook in isolation with fixture harness.yaml
- Verify graceful skip when harness.yaml absent
- Verify exit 2 on malformed config
- Verify pr-gate intercepts git push and runs checks

### Acceptance Criteria

1. All 7 hook files exist and are executable
2. POSIX sh (no bashisms)
3. Common preamble pattern used consistently
4. Graceful skip when harness.yaml absent
5. Config validation before proceeding
6. pr-gate reads build commands from config
7. state-guard processes stdin hook context
8. Error messages use `harness:` prefix

### On Completion

```bash
bd close rag-cgew8 --reason="7 POSIX sh hooks with common config preamble, registration table defined"
```

---

## W-09: Schema Migrator (lib/migrate.sh) — spec 09

**Issue:** rag-wzlyt
**Spec:** `.work/harness-modularization/specs/09-schema-migrator.md`

### Files to Create

```
lib/migrate.sh                     # Sourced library, not executable
```

### Functions to Implement

1. `harness_migrate <harness_yaml_path>` — public API, reads schema_version, runs needed migrations
2. `_harness_migrate_0_to_1 <path>` — (placeholder for future) migrate from v0 to v1
3. `HARNESS_CURRENT_SCHEMA_VERSION=1` — constant

### Key Requirements

- POSIX sh, sources `lib/config.sh` for yq helpers
- Sequential migration: reads current schema_version, applies `migrate_N_to_M` for each step
- Each migration function: yq in-place transform, then bumps schema_version
- No rollback mechanism (git is recovery)
- Exit 2 if schema_version > HARNESS_CURRENT_SCHEMA_VERSION (unknown future version)
- Exit 2 if schema_version is invalid
- v1 ships with no actual migrations needed (current version = 1)
- `$(( ))` arithmetic for version comparison (POSIX-compliant)

### Testing

- Config at schema_version=1, HARNESS_CURRENT_SCHEMA_VERSION=1 → no-op, exit 0
- Config at schema_version=2 → exit 2 (unknown future version)
- Config with missing schema_version → exit 2
- Config with non-integer schema_version → exit 2

### Acceptance Criteria

1. POSIX sh, no bashisms (except `$(( ))`)
2. Sources lib/config.sh
3. harness_migrate reads version and applies sequential migrations
4. Exit 2 on unknown future versions
5. Exit 2 on invalid schema_version
6. v1 ships functional but with no actual migration steps needed
7. Migration framework supports adding new `migrate_N_to_M` functions

### On Completion

```bash
bd close rag-wzlyt --reason="Schema migrator with sequential migration framework, v1 baseline"
```
