#!/bin/sh
# harness: config reader — shared functions for reading .claude/harness.yaml
# Component: C10
set -eu

# Ensure mise-managed tools are on PATH (hooks run in minimal shell environments)
if [ -d "${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims" ]; then
  PATH="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims:$PATH"
fi

# R1: yq dependency check at source time
command -v yq >/dev/null 2>&1 || {
  echo "harness: yq required but not found. Run install.sh to verify." >&2
  exit 2
}

# Internal: config file path relative to project directory
_HARNESS_CONFIG=".claude/harness.yaml"

# Internal: normalize yq output — suppress "null" for missing values
_harness_normalize_yq_output() {
  _hno_value=$(cat)
  case "$_hno_value" in
    null|"") return 0 ;;
    *) printf '%s\n' "$_hno_value" ;;
  esac
}

# Check whether .claude/harness.yaml exists in a project directory.
# Usage: harness_has_config [<dir>]
# Returns: 0 if file exists, 1 if not. No output.
harness_has_config() {
  hhc_dir="${1:-$PWD}"
  [ -f "$hhc_dir/$_HARNESS_CONFIG" ]
}

# Validate that .claude/harness.yaml parses as valid YAML and contains required fields.
# Assumes harness_has_config already passed (caller's responsibility).
# Usage: harness_validate_config [<dir>]
# Returns: 0 on valid config. Exit 2 on any validation failure.
harness_validate_config() {
  hvc_dir="${1:-$PWD}"
  hvc_file="$hvc_dir/$_HARNESS_CONFIG"

  # Check YAML parses
  if ! yq eval '.' "$hvc_file" > /dev/null 2>&1; then
    echo "harness: .claude/harness.yaml is malformed YAML" >&2
    return 2
  fi

  # Check schema_version exists and is a positive integer
  hvc_sv=$(yq eval '.schema_version' "$hvc_file" 2>/dev/null) || {
    echo "harness: .claude/harness.yaml missing or invalid schema_version" >&2
    return 2
  }
  case "$hvc_sv" in
    null|"")
      echo "harness: .claude/harness.yaml missing or invalid schema_version" >&2
      return 2
      ;;
    *)
      if ! echo "$hvc_sv" | grep -qE '^[0-9]+$'; then
        echo "harness: .claude/harness.yaml missing or invalid schema_version" >&2
        return 2
      fi
      if [ "$hvc_sv" -le 0 ]; then
        echo "harness: .claude/harness.yaml missing or invalid schema_version" >&2
        return 2
      fi
      ;;
  esac

  # Check project.name exists
  hvc_pn=$(yq eval '.project.name' "$hvc_file" 2>/dev/null) || {
    echo "harness: .claude/harness.yaml missing project.name" >&2
    return 2
  }
  case "$hvc_pn" in
    null|"")
      echo "harness: .claude/harness.yaml missing project.name" >&2
      return 2
      ;;
  esac

  # Validate docs.managed if present
  hvc_dm=$(yq eval '.docs.managed // ""' "$hvc_file" 2>/dev/null) || true
  if [ -n "$hvc_dm" ] && [ "$hvc_dm" != "null" ] && [ "$hvc_dm" != "[]" ]; then
    # Check for non-.md paths
    hvc_bad_paths=$(yq eval '.docs.managed[].path | select(test("\\.md$") | not)' "$hvc_file" 2>/dev/null) || true
    if [ -n "$hvc_bad_paths" ]; then
      echo "harness: docs.managed contains non-.md path: $(echo "$hvc_bad_paths" | head -1)" >&2
      return 2
    fi

    # Check for duplicate types
    hvc_types=$(yq eval '.docs.managed[].type' "$hvc_file" 2>/dev/null) || true
    hvc_dupes=$(printf '%s\n' "$hvc_types" | sort | uniq -d)
    if [ -n "$hvc_dupes" ]; then
      echo "harness: docs.managed has duplicate type: $(echo "$hvc_dupes" | head -1)" >&2
      return 2
    fi
  fi

  return 0
}

# Read a scalar value from a project's .claude/harness.yaml.
# Usage: harness_config_get <key> [<dir>]
# Returns: value on stdout. Exit 0 on success. Exit 2 if config exists but yq fails.
harness_config_get() {
  hcg_key="$1"
  hcg_dir="${2:-$PWD}"

  if ! harness_has_config "$hcg_dir"; then
    return 0
  fi

  hcg_file="$hcg_dir/$_HARNESS_CONFIG"
  hcg_result=$(yq eval "$hcg_key" "$hcg_file" 2>/dev/null) || {
    echo "harness: failed to read key '$hcg_key' from $hcg_file" >&2
    return 2
  }

  printf '%s\n' "$hcg_result" | _harness_normalize_yq_output
}

# Read an array from harness.yaml, one element per line.
# Usage: harness_config_list <key> [<dir>]
# Returns: array elements on stdout (newline-separated). Exit 0 on success. Exit 2 if yq fails.
harness_config_list() {
  hcl_key="$1"
  hcl_dir="${2:-$PWD}"

  if ! harness_has_config "$hcl_dir"; then
    return 0
  fi

  hcl_file="$hcl_dir/$_HARNESS_CONFIG"
  hcl_result=$(yq eval "$hcl_key | .[]" "$hcl_file" 2>/dev/null) || {
    # yq errors on null arrays with .[] — check if key is null/missing
    hcl_check=$(yq eval "$hcl_key" "$hcl_file" 2>/dev/null) || {
      echo "harness: failed to read key '$hcl_key' from $hcl_file" >&2
      return 2
    }
    case "$hcl_check" in
      null|""|"[]") return 0 ;;
      *)
        echo "harness: failed to list key '$hcl_key' from $hcl_file" >&2
        return 2
        ;;
    esac
  }

  printf '%s\n' "$hcl_result" | _harness_normalize_yq_output
}

# Resolve the absolute path to the harness repo installation.
# Usage: harness_dir
# Returns: absolute path on stdout. Exit 2 if unresolvable.
harness_dir() {
  # 1. Check HARNESS_DIR env var
  if [ -n "${HARNESS_DIR:-}" ]; then
    printf '%s\n' "$HARNESS_DIR"
    return 0
  fi

  # 2. Fall back to manifest
  hd_manifest="$HOME/.claude/.harness-manifest.json"
  if [ -f "$hd_manifest" ]; then
    # jq needed for manifest reading — check before use
    if ! command -v jq >/dev/null 2>&1; then
      echo "harness: jq required to read manifest but not found" >&2
      return 2
    fi

    hd_dir=$(jq -r '.harness_dir // empty' "$hd_manifest" 2>/dev/null) || {
      echo "harness: failed to read harness_dir from manifest" >&2
      return 2
    }

    if [ -n "$hd_dir" ]; then
      printf '%s\n' "$hd_dir"
      return 0
    fi
  fi

  # 3. Unresolvable
  echo "harness: cannot resolve harness directory — set HARNESS_DIR or run install.sh" >&2
  return 2
}
