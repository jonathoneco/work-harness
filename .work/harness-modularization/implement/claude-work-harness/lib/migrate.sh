#!/bin/sh
# harness: schema migration functions for harness.yaml
# Component: C9
set -eu

# The schema version this harness release expects.
# Bump this when adding a new migration.
# shellcheck disable=SC2034  # Consumed by install.sh after sourcing
HARNESS_CURRENT_SCHEMA_VERSION=1

# Run all migrations from $from to $to, sequentially.
# Args: $1=config_path  $2=from_version  $3=to_version
# Returns: 0 on success, 2 on failure
# Side effects: modifies harness.yaml in-place, bumps schema_version after each step
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
