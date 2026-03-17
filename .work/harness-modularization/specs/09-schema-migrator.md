# Spec 09: Schema Migrator (C9)

**Component:** C9 — Schema Migrator (`lib/migrate.sh`)
**Phase:** 2 (Core)
**Scope:** Small
**Dependencies:** C1 (repo scaffold), C10 (config reader)
**References:** [architecture.md](architecture.md), [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md)
**Resolves:** DQ4 (migration function signatures)

---

## 1. Overview

`lib/migrate.sh` provides sequential migration functions that transform `.claude/harness.yaml` between schema versions. When a user runs `install.sh --update` (C7), the install script compares the installed `schema_version` (from the manifest) against the current harness repo's expected schema version. If they differ, it sources `lib/migrate.sh` and calls `harness_migrate` to run all applicable migrations in order.

Migrations are incremental: each function transforms from version N to version N+1. They modify `harness.yaml` in-place using `yq`. Version 1 ships with no migrations (it's the initial schema). The infrastructure exists so that future schema changes have a defined, tested path.

### Why This Exists

Without a migrator, schema changes would require users to manually edit their `harness.yaml` or wipe and regenerate. With the migrator, `install.sh --update` handles it automatically — the user runs `git pull && ./install.sh --update` and their project configs are upgraded.

---

## 2. Architecture

### Data Flow

```
install.sh --update
  │
  ├─ Reads manifest: schema_version = N (installed version)
  ├─ Reads harness repo: CURRENT_SCHEMA_VERSION = M (target version)
  │
  ├─ If N == M → no migration needed
  ├─ If N > M → error (downgrade not supported)
  ├─ If N < M → source lib/migrate.sh
  │   └─ harness_migrate <project-harness-yaml-path> <from-version> <to-version>
  │       ├─ migrate_1_to_2 <path>
  │       ├─ migrate_2_to_3 <path>
  │       └─ ... (sequential, in order)
  │
  └─ Updates manifest: schema_version = M
```

### Schema Version Lifecycle

| Version | Introduced In | Changes |
|---------|--------------|---------|
| 1 | v0.1.0 (initial) | Initial schema (spec 00 section 4) |
| 2+ | Future | Reserved — placeholder migration functions |

---

## 3. Function Signatures (DQ4 Resolution)

### Public API

```sh
# Source the migrator
. "$HARNESS_DIR/lib/migrate.sh"

# Run all migrations from version $from to version $to
# Args:
#   $1 — absolute path to harness.yaml
#   $2 — current schema_version (integer, from manifest)
#   $3 — target schema_version (integer, from harness repo)
# Returns:
#   exit 0 on success
#   exit 2 on failure (malformed yaml, yq error, validation failure)
# Side effects:
#   Modifies harness.yaml in-place
#   Bumps schema_version in the file after each step
harness_migrate "$config_path" "$from_version" "$to_version"
```

### Internal Migration Functions

Each migration function follows this signature:

```sh
# Migrate harness.yaml from version N to N+1
# Args:
#   $1 — absolute path to harness.yaml
# Returns:
#   exit 0 on success
#   exit 2 on failure
# Side effects:
#   Modifies harness.yaml in-place
#   Sets schema_version to N+1 in the file
# Precondition:
#   harness.yaml is valid and has schema_version = N
# Postcondition:
#   harness.yaml is valid and has schema_version = N+1
migrate_N_to_M() {
  config_path="$1"
  # ... yq transformations ...
  yq eval -i '.schema_version = M' "$config_path"
}
```

### Constants

```sh
# The schema version this harness release expects.
# Bump this when adding a new migration function.
HARNESS_CURRENT_SCHEMA_VERSION=1
```

This constant lives in `lib/migrate.sh` and is read by `install.sh` to determine if migration is needed.

---

## 4. Implementation Steps

- [ ] **4.1** Create `lib/migrate.sh` with POSIX sh shebang and header
- [ ] **4.2** Define `HARNESS_CURRENT_SCHEMA_VERSION=1`
- [ ] **4.3** Implement `harness_migrate` orchestrator function
- [ ] **4.4** Implement `migrate_1_to_2` as a placeholder (no-op that bumps schema_version to 2, commented out, with a clear "uncomment when v2 schema is defined" note)
- [ ] **4.5** Add pre-migration validation: verify harness.yaml parses and `schema_version` matches expected `$from_version`
- [ ] **4.6** Add post-migration validation: verify harness.yaml still parses and `schema_version` matches expected `$to_version`
- [ ] **4.7** Add dependency check for `yq` (R1)
- [ ] **4.8** Verify: `shellcheck -s sh lib/migrate.sh` passes
- [ ] **4.9** Verify: sourcing migrate.sh without calling anything has no side effects

---

## 5. Full Implementation

```sh
#!/bin/sh
# harness: schema migration functions for harness.yaml
# Component: C9
set -eu

# The schema version this harness release expects.
# Bump this when adding a new migration.
HARNESS_CURRENT_SCHEMA_VERSION=1

# Run all migrations from $from to $to, sequentially.
# Args: $1=config_path  $2=from_version  $3=to_version
harness_migrate() {
  _hm_config="$1"
  _hm_from="$2"
  _hm_to="$3"

  # Dependency check (R1)
  command -v yq >/dev/null 2>&1 || {
    echo "harness: yq required but not found. Run install.sh to verify." >&2
    return 2
  }

  # Validate inputs
  if [ "$_hm_from" -ge "$_hm_to" ] 2>/dev/null; then
    echo "harness: migrate: from_version ($_hm_from) >= to_version ($_hm_to), nothing to do" >&2
    return 0
  fi

  if [ ! -f "$_hm_config" ]; then
    echo "harness: migrate: config file not found: $_hm_config" >&2
    return 2
  fi

  # Pre-migration validation (R2)
  if ! yq eval '.' "$_hm_config" >/dev/null 2>&1; then
    echo "harness: migrate: harness.yaml is malformed before migration" >&2
    return 2
  fi

  _hm_actual=$(yq eval '.schema_version' "$_hm_config")
  if [ "$_hm_actual" != "$_hm_from" ]; then
    echo "harness: migrate: expected schema_version=$_hm_from but found $_hm_actual" >&2
    return 2
  fi

  # Run each migration step sequentially
  _hm_current="$_hm_from"
  while [ "$_hm_current" -lt "$_hm_to" ]; do
    _hm_next=$(( _hm_current + 1 ))
    _hm_func="migrate_${_hm_current}_to_${_hm_next}"

    # Check that the migration function exists
    if ! type "$_hm_func" >/dev/null 2>&1; then
      echo "harness: migrate: no migration function '$_hm_func' defined" >&2
      return 2
    fi

    echo "harness: migrating schema_version $_hm_current -> $_hm_next" >&2
    "$_hm_func" "$_hm_config" || {
      echo "harness: migrate: $_hm_func failed" >&2
      return 2
    }

    # Post-step validation
    if ! yq eval '.' "$_hm_config" >/dev/null 2>&1; then
      echo "harness: migrate: harness.yaml is malformed after $_hm_func" >&2
      return 2
    fi

    _hm_step_version=$(yq eval '.schema_version' "$_hm_config")
    if [ "$_hm_step_version" != "$_hm_next" ]; then
      echo "harness: migrate: $_hm_func did not set schema_version to $_hm_next (found $_hm_step_version)" >&2
      return 2
    fi

    _hm_current="$_hm_next"
  done

  echo "harness: migration complete (schema_version: $_hm_from -> $_hm_to)" >&2
  return 0
}

# --- Migration Functions ---
# Add new migrations below. Each function:
#   - Takes $1 = absolute path to harness.yaml
#   - Transforms the file in-place using yq
#   - Sets schema_version to the target version
#   - Returns 0 on success, 2 on failure
#
# Example (uncomment when v2 schema is defined):
#
# migrate_1_to_2() {
#   _m12_config="$1"
#   # Example: rename a field
#   # yq eval -i '.new_field = .old_field | del(.old_field)' "$_m12_config"
#   yq eval -i '.schema_version = 2' "$_m12_config"
# }
```

### Variable Naming Convention

All local variables in migrate.sh use a `_hm_` prefix (harness migrate) to avoid collisions when sourced. Migration functions use `_mNM_` prefixes (e.g., `_m12_` for migrate_1_to_2).

---

## 6. Interface Contracts

### Exposes

| What | Consumed By | Contract |
|------|------------|----------|
| `harness_migrate` function | C7 (install.sh, update mode) | `harness_migrate <path> <from> <to>` — returns 0 on success, 2 on failure |
| `HARNESS_CURRENT_SCHEMA_VERSION` | C7 (install.sh) | Integer constant, current expected schema version |
| `migrate_N_to_M` functions | `harness_migrate` (internal) | One function per version step, named `migrate_<N>_to_<N+1>` |

### Consumes

| What | From | Contract |
|------|------|----------|
| `.claude/harness.yaml` | Project | Valid YAML, `schema_version` field present |
| `yq` binary | System | R1: checked before first use |

---

## 7. Testing Strategy

### Unit Testing (manual script)

Create a test helper that exercises migration paths:

```sh
#!/bin/sh
# test-migrate.sh — run from harness repo root
set -eu

. lib/migrate.sh

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Test 1: No migration needed (from == to)
cat > "$TMPDIR/harness.yaml" << 'EOF'
schema_version: 1
project:
  name: test
stack:
  language: go
EOF
harness_migrate "$TMPDIR/harness.yaml" 1 1
echo "PASS: no-op migration"

# Test 2: Missing config file
if harness_migrate "$TMPDIR/nonexistent.yaml" 1 2 2>/dev/null; then
  echo "FAIL: should error on missing file"
else
  echo "PASS: errors on missing file"
fi

# Test 3: Malformed YAML
echo "not: valid: yaml: [" > "$TMPDIR/bad.yaml"
if harness_migrate "$TMPDIR/bad.yaml" 1 2 2>/dev/null; then
  echo "FAIL: should error on malformed yaml"
else
  echo "PASS: errors on malformed yaml"
fi

# Test 4: schema_version mismatch
cat > "$TMPDIR/mismatch.yaml" << 'EOF'
schema_version: 3
project:
  name: test
stack:
  language: go
EOF
if harness_migrate "$TMPDIR/mismatch.yaml" 1 2 2>/dev/null; then
  echo "FAIL: should error on version mismatch"
else
  echo "PASS: errors on version mismatch"
fi

# Test 5: Missing migration function
if harness_migrate "$TMPDIR/harness.yaml" 1 2 2>/dev/null; then
  echo "FAIL: should error on missing migration function"
else
  echo "PASS: errors on missing migration function"
fi

# Test 6: Successful migration (define a test function)
migrate_1_to_2() {
  yq eval -i '.schema_version = 2 | .new_field = "added"' "$1"
}
cat > "$TMPDIR/migrate.yaml" << 'EOF'
schema_version: 1
project:
  name: test
stack:
  language: go
EOF
harness_migrate "$TMPDIR/migrate.yaml" 1 2
result_version=$(yq eval '.schema_version' "$TMPDIR/migrate.yaml")
result_field=$(yq eval '.new_field' "$TMPDIR/migrate.yaml")
if [ "$result_version" = "2" ] && [ "$result_field" = "added" ]; then
  echo "PASS: migration 1->2 applied correctly"
else
  echo "FAIL: migration 1->2 result: version=$result_version field=$result_field"
fi

echo "All tests complete"
```

### Integration Testing

Tested as part of `install.sh --update` (spec 10). The install script exercises migration as part of the update flow.

### What /harness-doctor Checks (C13)

- `schema_version` in `harness.yaml` matches `HARNESS_CURRENT_SCHEMA_VERSION`
- If mismatch, suggests running `install.sh --update`

---

## 8. Edge Cases and Error Handling

| Scenario | Handling |
|----------|----------|
| `from_version == to_version` | Return 0 immediately (no-op) |
| `from_version > to_version` | Return 0 with info message (downgrade not supported, but not an error — the file is already at a higher version) |
| `schema_version` field missing from harness.yaml | yq returns `null` — version mismatch detected, exit 2 |
| `schema_version` is not an integer | yq returns the raw value — arithmetic comparison fails in shell — caught by `[ "$_hm_from" -ge "$_hm_to" ]` which errors on non-integer, handled by set -eu |
| Migration function modifies file but doesn't bump version | Post-step validation catches this — exit 2 |
| Migration function produces invalid YAML | Post-step `yq eval` validation catches this — exit 2 |
| yq not installed | Dependency check at function entry — exit 2 |
| Partial migration (step 2 of 3 fails) | File is left at the version of the last successful step. The user can re-run after fixing the issue. No rollback — migrations are small and inspectable. |
| Concurrent migration (two processes) | Not handled. Migrations are run by install.sh which is a single-user tool. Document that install.sh should not be run concurrently. |
| Very large harness.yaml (unlikely) | yq handles it. No special handling needed. |
| Empty harness.yaml (0 bytes) | yq eval will fail — caught by pre-migration validation |

### No Rollback by Design

Migrations do not support rollback. Rationale:
1. Migrations are small (one version step each) and easily inspectable
2. harness.yaml is committed to git — the user can `git checkout` to restore
3. Rollback logic doubles the surface area for bugs in infrastructure code
4. The pre/post validation catches corruption immediately

---

## 9. Design Decisions

### Why Sequential Functions, Not a Migration Table

A migration table (array of version+function pairs) would require bash arrays or external data. Sequential named functions (`migrate_1_to_2`, `migrate_2_to_3`) are POSIX-compatible and self-documenting. The `harness_migrate` orchestrator just constructs the function name from the version numbers and calls it.

### Why In-Place Modification

Alternatives considered:
- **Copy-on-write (transform to temp, then move):** Safer against crashes, but adds complexity. Since harness.yaml is in git, crash recovery is `git checkout`.
- **Output to stdout:** Would require the caller to redirect. In-place is simpler for the caller.

### Why Schema Version in harness.yaml (Not Just Manifest)

The manifest tracks the installed harness version. But `harness.yaml` lives in the project repo — it may be shared between team members. The `schema_version` in the file itself ensures any tool reading it knows the schema format, regardless of the harness version installed.

---

## 10. Example Invocations

```sh
# Source the migrator
. /home/user/src/claude-work-harness/lib/migrate.sh

# Check if migration is needed
echo "Current schema version: $HARNESS_CURRENT_SCHEMA_VERSION"

# Run migration (called by install.sh --update)
harness_migrate /home/user/project/.claude/harness.yaml 1 2

# Multi-step migration
harness_migrate /home/user/project/.claude/harness.yaml 1 3
# This runs: migrate_1_to_2, then migrate_2_to_3
```
