#!/bin/sh
# harness: install/update/uninstall the work harness
# Component: C7
set -eu

# --- Constants ---

HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
MANIFEST="$CLAUDE_DIR/.harness-manifest.json"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
BLOCK_FILE="$HARNESS_DIR/lib/claude-md-block.txt"
AGENCY_REPO="https://github.com/msitarzewski/agency-agents.git"
AGENCY_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/work-harness/agency-agents"

# --- Usage ---

usage() {
  cat <<'EOF'
Usage: install.sh [MODE] [OPTIONS]

Modes:
  --install     Fresh installation (default)
  --update      Update existing installation
  --uninstall   Remove all harness artifacts

Options:
  --agents      Install/update agency-agents from github.com/msitarzewski/agency-agents
  --force       Force install even if manifest exists (recovery)
  -h, --help    Show this help

Environment:
  CLAUDE_DIR    Override target directory (default: ~/.claude)
EOF
}

# --- Flag Parsing ---

MODE=""
FORCE="false"
INSTALL_AGENTS="false"

while [ $# -gt 0 ]; do
  case "$1" in
    install|--install)   MODE="install" ;;
    update|--update)     MODE="update" ;;
    uninstall|--uninstall) MODE="uninstall" ;;
    agents|--agents)     INSTALL_AGENTS="true" ;;
    --force)             FORCE="true" ;;
    -h|--help)           usage; exit 0 ;;
    *)                   echo "harness: unknown flag: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# Default mode to install unless only --agents was requested
if [ -z "$MODE" ] && [ "$INSTALL_AGENTS" != "true" ]; then
  MODE="install"
fi

# --- Source Libraries ---

# shellcheck source=lib/merge.sh
. "$HARNESS_DIR/lib/merge.sh"
# shellcheck source=lib/migrate.sh
. "$HARNESS_DIR/lib/migrate.sh"
# config.sh requires yq which is checked in harness_check_deps;
# source it after dependency check would be ideal, but set -eu means
# config.sh's source-time yq check will fire. We source after deps check.

# --- Dependency Check ---

harness_check_deps() {
  _hcd_missing=""
  for _hcd_dep in jq yq git bd; do
    if ! command -v "$_hcd_dep" >/dev/null 2>&1; then
      _hcd_missing="$_hcd_missing $_hcd_dep"
    fi
  done
  if [ -n "$_hcd_missing" ]; then
    echo "harness: missing required dependencies:$_hcd_missing" >&2
    echo "harness: install them and retry. See README.md for details." >&2
    return 2
  fi
}

# --- Hook Entries (Single Source of Truth) ---

harness_hook_entries() {
  _hhe_dir="$1"
  cat <<HOOKS_EOF
[
  {"event":"PostToolUse","matcher":"Write|Edit","command":"$_hhe_dir/hooks/state-guard.sh"},
  {"event":"Stop","matcher":"","command":"$_hhe_dir/hooks/work-check.sh"},
  {"event":"Stop","matcher":"","command":"$_hhe_dir/hooks/beads-check.sh"},
  {"event":"Stop","matcher":"","command":"$_hhe_dir/hooks/review-gate.sh"},
  {"event":"Stop","matcher":"","command":"$_hhe_dir/hooks/artifact-gate.sh"},
  {"event":"Stop","matcher":"","command":"$_hhe_dir/hooks/review-verify.sh"},
  {"event":"PreToolUse","matcher":"Bash","command":"$_hhe_dir/hooks/pr-gate.sh"},
  {"event":"PostCompact","matcher":"","command":"$_hhe_dir/hooks/post-compact.sh"},
  {"event":"PreToolUse","matcher":"Edit|Write","command":"FILE=\$(jq -r '.tool_input.file_path // empty'); if echo \"\$FILE\" | grep -qE '(\\\\.env\$|\\\\.env\\\\.)'; then echo 'Blocked: .env files cannot be edited by Claude' >&2; exit 2; fi"},
  {"event":"PreToolUse","matcher":"Edit|Write","command":"FILE=\$(jq -r '.tool_input.file_path // empty'); if echo \"\$FILE\" | grep -q '/\\\\.review/'; then echo 'Blocked: Do not write to .review/ — review findings must go to .work/<task-name>/review/findings.jsonl (see work-review.md Step 6)' >&2; exit 2; fi"}
]
HOOKS_EOF
}

# --- Content File Enumeration ---

harness_list_content_files() {
  (cd "$HARNESS_DIR/claude" && find . -type f ! -name '.gitkeep' | sed 's|^\./||' | sort)
}

# --- File Copy with Conflict Detection ---
# Uses _hcf_manifest_files (newline-separated list) set by caller.
# Args: $1=relative_path
# Returns: 0=copied, 1=skipped (conflict)

harness_copy_file() {
  _hcf_rel="$1"
  _hcf_src="$HARNESS_DIR/claude/$_hcf_rel"
  _hcf_dst="$CLAUDE_DIR/$_hcf_rel"

  if [ -f "$_hcf_dst" ]; then
    # Target exists — is it in the manifest?
    if [ -n "${_hcf_manifest_files:-}" ] && printf '%s\n' "$_hcf_manifest_files" | grep -qxF "$_hcf_rel"; then
      # Harness-managed — safe to overwrite
      :
    elif [ "$FORCE" = "true" ]; then
      echo "harness: overwriting non-managed file: $_hcf_rel" >&2
    else
      echo "harness: conflict: ~/.claude/$_hcf_rel exists but is not harness-managed" >&2
      echo "harness: conflict: skipping (use --force to overwrite)" >&2
      return 1
    fi
  fi

  mkdir -p "$(dirname "$_hcf_dst")"
  cp "$_hcf_src" "$_hcf_dst"
  return 0
}

# --- File Status for Update Mode ---
# Args: $1=relative_path
# Outputs: "new", "changed", "unchanged", or "removed"

harness_file_status() {
  _hfs_rel="$1"
  _hfs_src="$HARNESS_DIR/claude/$_hfs_rel"
  _hfs_dst="$CLAUDE_DIR/$_hfs_rel"

  if [ ! -f "$_hfs_src" ]; then
    printf 'removed\n'
  elif [ ! -f "$_hfs_dst" ]; then
    printf 'new\n'
  elif ! cmp -s "$_hfs_src" "$_hfs_dst"; then
    printf 'changed\n'
  else
    printf 'unchanged\n'
  fi
}

# --- Manifest Operations ---

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

harness_write_manifest() {
  _hwm_files_json="$1"
  _hwm_hooks_json="$2"
  _hwm_installed_at="${3:-}"
  _hwm_version=$(cat "$HARNESS_DIR/VERSION")
  _hwm_now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [ -z "$_hwm_installed_at" ]; then
    _hwm_installed_at="$_hwm_now"
  fi

  _hwm_tmpfile="$CLAUDE_DIR/.harness-manifest.tmp.$$"
  jq -n \
    --arg version "$_hwm_version" \
    --arg dir "$HARNESS_DIR" \
    --arg schema "$HARNESS_CURRENT_SCHEMA_VERSION" \
    --arg installed_at "$_hwm_installed_at" \
    --arg now "$_hwm_now" \
    --argjson files "$_hwm_files_json" \
    --argjson hooks "$_hwm_hooks_json" \
    '{
      harness_version: $version,
      harness_dir: $dir,
      schema_version: ($schema | tonumber),
      installed_at: $installed_at,
      updated_at: $now,
      files: $files,
      hooks_added: $hooks,
      claude_md_tag: "harness"
    }' > "$_hwm_tmpfile" || {
    rm -f "$_hwm_tmpfile"
    echo "harness: failed to write manifest" >&2
    return 1
  }
  mv "$_hwm_tmpfile" "$MANIFEST"
}

# --- CLAUDE.md Operations ---

harness_update_claude_md() {
  if [ ! -f "$BLOCK_FILE" ]; then
    echo "harness: missing lib/claude-md-block.txt" >&2
    return 1
  fi

  if [ ! -f "$CLAUDE_MD" ]; then
    # Create with just the harness block
    cp "$BLOCK_FILE" "$CLAUDE_MD"
    return 0
  fi

  _hucm_tmpfile="$CLAUDE_DIR/.claude-md.tmp.$$"
  if grep -q '<!-- harness:start -->' "$CLAUDE_MD"; then
    # Replace between tags (remove old block, append new)
    sed '/<!-- harness:start -->/,/<!-- harness:end -->/d' "$CLAUDE_MD" > "$_hucm_tmpfile"
    cat "$BLOCK_FILE" >> "$_hucm_tmpfile"
    mv "$_hucm_tmpfile" "$CLAUDE_MD"
  else
    # Append with preceding blank line (atomic via temp+mv)
    { cat "$CLAUDE_MD"; printf '\n'; cat "$BLOCK_FILE"; } > "$_hucm_tmpfile"
    mv "$_hucm_tmpfile" "$CLAUDE_MD"
  fi
}

harness_remove_claude_md() {
  if [ ! -f "$CLAUDE_MD" ]; then
    return 0
  fi

  if ! grep -q '<!-- harness:start -->' "$CLAUDE_MD"; then
    echo "harness: warning: no harness tags found in CLAUDE.md" >&2
    return 0
  fi

  _hrcm_tmpfile="$CLAUDE_DIR/.claude-md.tmp.$$"
  sed '/<!-- harness:start -->/,/<!-- harness:end -->/d' "$CLAUDE_MD" > "$_hrcm_tmpfile"

  # Check if file is now empty (only whitespace)
  if ! grep -q '[^[:space:]]' "$_hrcm_tmpfile" 2>/dev/null; then
    rm -f "$_hrcm_tmpfile"
    rm -f "$CLAUDE_MD"
  else
    mv "$_hrcm_tmpfile" "$CLAUDE_MD"
  fi
}

# --- Agency-Agents Install/Update ---

harness_install_agents() {
  echo "harness: installing agency-agents..." >&2

  if [ -d "$AGENCY_CACHE/.git" ]; then
    echo "harness: updating cached repo..." >&2
    git -C "$AGENCY_CACHE" pull --ff-only >&2 || {
      echo "harness: pull failed, re-cloning..." >&2
      rm -rf "$AGENCY_CACHE"
      mkdir -p "$(dirname "$AGENCY_CACHE")"
      git clone "$AGENCY_REPO" "$AGENCY_CACHE" >&2
    }
  else
    mkdir -p "$(dirname "$AGENCY_CACHE")"
    rm -rf "$AGENCY_CACHE"
    git clone "$AGENCY_REPO" "$AGENCY_CACHE" >&2
  fi

  # Copy all agent .md files to ~/.claude/agents/
  # The repo organizes agents in category subdirectories (engineering/, testing/, etc.)
  mkdir -p "$CLAUDE_DIR/agents"
  _hia_count=$(find "$AGENCY_CACHE" -name '*.md' \
    -not -name 'README.md' -not -name 'CONTRIBUTING.md' -not -name 'LICENSE*' \
    -not -path '*/.git/*' -not -path '*/.github/*' -not -path '*/examples/*' \
    -type f -exec cp {} "$CLAUDE_DIR/agents/" \; -print | wc -l)

  if [ "$_hia_count" -eq 0 ]; then
    echo "harness: warning: no agent files found in repo" >&2
  else
    echo "harness: installed $_hia_count agency-agents to ~/.claude/agents/" >&2
  fi
}

# --- Agency-Agents Companion Check ---

harness_check_agency() {
  if [ -f "$CLAUDE_DIR/agents/code-reviewer.md" ]; then
    return
  fi
  echo "" >&2
  echo "harness: Tip: Install agency-agents for domain-expertise review agents." >&2
  echo "harness: The work harness review routing works best with agents like code-reviewer," >&2
  echo "harness: security-reviewer, and devops-automator from agency-agents." >&2
  echo "harness: See: https://github.com/msitarzewski/agency-agents" >&2
  echo "harness: Run: ./install.sh --agents" >&2
}

# --- Install Mode ---

harness_install() {
  echo "harness: checking dependencies..." >&2
  harness_check_deps
  echo "harness: ok" >&2

  # Check for existing manifest
  if [ -f "$MANIFEST" ] && [ "$FORCE" != "true" ]; then
    echo "harness: already installed (manifest found at $MANIFEST)" >&2
    echo "harness: use --update to update or --force for a fresh install" >&2
    return 2
  fi

  if [ -f "$MANIFEST" ] && [ "$FORCE" = "true" ]; then
    echo "harness: --force: performing fresh install (ignoring existing manifest)" >&2
  fi

  # Create CLAUDE_DIR if needed
  mkdir -p "$CLAUDE_DIR"

  echo "harness: installing to $CLAUDE_DIR/" >&2

  # Read manifest files for conflict detection (empty on fresh install unless --force)
  _hi_manifest_files=""
  if [ -f "$MANIFEST" ] && jq empty "$MANIFEST" 2>/dev/null; then
    _hi_manifest_files=$(jq -r '.files[]' "$MANIFEST" 2>/dev/null) || true
  fi

  # Export for harness_copy_file
  _hcf_manifest_files="$_hi_manifest_files"

  # Copy content files
  _hi_copied=0
  _hi_skipped=0
  _hi_skipped_list=""
  _hi_files_list=""

  for _hi_rel in $(harness_list_content_files); do
    if harness_copy_file "$_hi_rel"; then
      _hi_copied=$(( _hi_copied + 1 ))
      if [ -z "$_hi_files_list" ]; then
        _hi_files_list="$_hi_rel"
      else
        _hi_files_list="$_hi_files_list
$_hi_rel"
      fi
    else
      _hi_skipped=$(( _hi_skipped + 1 ))
      if [ -z "$_hi_skipped_list" ]; then
        _hi_skipped_list="$_hi_rel"
      else
        _hi_skipped_list="$_hi_skipped_list
$_hi_rel"
      fi
    fi
  done

  # Build JSON array safely via jq (handles special chars in filenames)
  if [ -n "$_hi_files_list" ]; then
    _hi_files_json=$(printf '%s\n' "$_hi_files_list" | jq -R . | jq -s .)
  else
    _hi_files_json="[]"
  fi
  echo "harness: copied $_hi_copied content files" >&2

  # Merge hooks
  _hi_hooks_json=$(harness_hook_entries "$HARNESS_DIR")
  harness_merge_hooks "$SETTINGS" "$_hi_hooks_json"
  _hi_hook_count=$(printf '%s' "$_hi_hooks_json" | jq 'length')
  echo "harness: registered $_hi_hook_count hooks in settings.json" >&2

  # Update CLAUDE.md
  harness_update_claude_md
  echo "harness: appended harness block to CLAUDE.md" >&2

  # Write manifest
  harness_write_manifest "$_hi_files_json" "$_hi_hooks_json"
  echo "harness: wrote manifest to .harness-manifest.json" >&2

  # Summary
  _hi_version=$(cat "$HARNESS_DIR/VERSION")
  if [ "$_hi_skipped" -gt 0 ]; then
    echo "harness: install complete. $_hi_copied files installed, $_hi_skipped skipped due to conflicts." >&2
    echo "harness: skipped files:" >&2
    printf '%s\n' "$_hi_skipped_list" | while IFS= read -r _hi_sf; do
      echo "  $_hi_sf" >&2
    done
  else
    echo "harness: install complete (v$_hi_version)" >&2
  fi

  # Check for agency-agents
  harness_check_agency
}

# --- Update Mode ---

harness_update() {
  echo "harness: checking dependencies..." >&2
  harness_check_deps
  echo "harness: ok" >&2

  # Read and validate manifest
  echo "harness: reading manifest..." >&2
  harness_read_manifest
  _hu_old_version=$(jq -r '.harness_version' "$MANIFEST")
  _hu_installed_at=$(jq -r '.installed_at' "$MANIFEST")
  _hu_old_schema=$(jq -r '.schema_version' "$MANIFEST")
  echo "harness: ok (v$_hu_old_version)" >&2

  # Get manifest files for conflict detection
  _hcf_manifest_files=$(jq -r '.files[]' "$MANIFEST" 2>/dev/null) || true

  # Compare repo content vs manifest
  echo "harness: comparing files..." >&2
  _hu_repo_files=$(harness_list_content_files)
  _hu_manifest_file_list=$(jq -r '.files[]' "$MANIFEST" 2>/dev/null) || true

  _hu_added=0
  _hu_changed=0
  _hu_removed=0
  _hu_unchanged=0
  _hu_skipped=0
  _hu_new_files_list=""

  # Process repo files (new, changed, unchanged)
  for _hu_rel in $_hu_repo_files; do
    _hu_status=$(harness_file_status "$_hu_rel")
    case "$_hu_status" in
      new)
        if harness_copy_file "$_hu_rel"; then
          _hu_added=$(( _hu_added + 1 ))
        else
          _hu_skipped=$(( _hu_skipped + 1 ))
        fi
        ;;
      changed)
        # Changed files in manifest are expected updates, not conflicts
        if harness_copy_file "$_hu_rel"; then
          _hu_changed=$(( _hu_changed + 1 ))
        else
          _hu_skipped=$(( _hu_skipped + 1 ))
        fi
        ;;
      unchanged)
        _hu_unchanged=$(( _hu_unchanged + 1 ))
        ;;
    esac

    # Build new files list (all repo files that exist in target)
    if [ -f "$CLAUDE_DIR/$_hu_rel" ]; then
      if [ -z "$_hu_new_files_list" ]; then
        _hu_new_files_list="$_hu_rel"
      else
        _hu_new_files_list="$_hu_new_files_list
$_hu_rel"
      fi
    fi
  done

  # Process manifest files that are no longer in repo (removed)
  # Use for-loop (not piped while) to avoid subshell variable loss
  if [ -n "$_hu_manifest_file_list" ]; then
    for _hu_mf in $_hu_manifest_file_list; do
      if [ -z "$_hu_mf" ]; then
        continue
      fi
      if ! printf '%s\n' "$_hu_repo_files" | grep -qxF "$_hu_mf"; then
        # File removed from repo — delete from target
        if [ -f "$CLAUDE_DIR/$_hu_mf" ]; then
          rm -f "$CLAUDE_DIR/$_hu_mf"
          # Clean up empty parent directories
          _hu_parent=$(dirname "$CLAUDE_DIR/$_hu_mf")
          while [ "$_hu_parent" != "$CLAUDE_DIR" ] && [ -d "$_hu_parent" ]; do
            if ! rmdir "$_hu_parent" 2>/dev/null; then
              break
            fi
            _hu_parent=$(dirname "$_hu_parent")
          done
        fi
        echo "harness: removed: $_hu_mf" >&2
        _hu_removed=$(( _hu_removed + 1 ))
      fi
    done
  fi

  _hu_copied=$(( _hu_added + _hu_changed ))
  echo "harness:   $_hu_added new, $_hu_changed changed, $_hu_removed removed, $_hu_unchanged unchanged" >&2
  if [ "$_hu_copied" -gt 0 ]; then
    echo "harness: copied $_hu_copied files" >&2
  fi

  # Re-merge hooks (de-merge old, merge current)
  _hu_old_hooks=$(jq -c '.hooks_added' "$MANIFEST") || true
  _hu_new_hooks=$(harness_hook_entries "$HARNESS_DIR")
  if [ -n "$_hu_old_hooks" ] && [ "$_hu_old_hooks" != "null" ]; then
    harness_demerge_hooks "$SETTINGS" "$_hu_old_hooks"
  fi
  harness_merge_hooks "$SETTINGS" "$_hu_new_hooks"
  echo "harness: hooks updated" >&2

  # Update CLAUDE.md
  harness_update_claude_md
  echo "harness: CLAUDE.md block up to date" >&2

  # Schema migration check
  if [ "$_hu_old_schema" -lt "$HARNESS_CURRENT_SCHEMA_VERSION" ] 2>/dev/null; then
    echo "harness: schema version upgrade available ($_hu_old_schema -> $HARNESS_CURRENT_SCHEMA_VERSION)" >&2
    echo "harness: project harness.yaml files will be migrated by /harness-update" >&2
  else
    echo "harness: schema version unchanged ($HARNESS_CURRENT_SCHEMA_VERSION)" >&2
  fi

  # Build JSON array safely via jq (handles special chars in filenames)
  if [ -n "$_hu_new_files_list" ]; then
    _hu_new_files_json=$(printf '%s\n' "$_hu_new_files_list" | jq -R . | jq -s .)
  else
    _hu_new_files_json="[]"
  fi
  harness_write_manifest "$_hu_new_files_json" "$_hu_new_hooks" "$_hu_installed_at"
  _hu_new_version=$(cat "$HARNESS_DIR/VERSION")
  echo "harness: updated manifest (v$_hu_new_version)" >&2

  echo "harness: update complete" >&2
}

# --- Uninstall Mode ---

harness_uninstall() {
  echo "harness: checking dependencies..." >&2
  harness_check_deps
  echo "harness: ok" >&2

  # Read and validate manifest
  echo "harness: reading manifest..." >&2
  harness_read_manifest
  echo "harness: ok" >&2

  # Remove content files
  _hx_file_count=$(jq -r '.files | length' "$MANIFEST")
  echo "harness: removing $_hx_file_count content files..." >&2

  jq -r '.files[]' "$MANIFEST" | while IFS= read -r _hx_rel; do
    if [ -z "$_hx_rel" ]; then
      continue
    fi
    _hx_target="$CLAUDE_DIR/$_hx_rel"
    if [ -f "$_hx_target" ]; then
      rm -f "$_hx_target"
    else
      echo "harness: warning: file already missing: $_hx_rel" >&2
    fi
    # Clean up empty parent directories
    _hx_parent=$(dirname "$_hx_target")
    while [ "$_hx_parent" != "$CLAUDE_DIR" ] && [ -d "$_hx_parent" ]; do
      if ! rmdir "$_hx_parent" 2>/dev/null; then
        break
      fi
      _hx_parent=$(dirname "$_hx_parent")
    done
  done

  # De-merge hooks
  _hx_hooks=$(jq -c '.hooks_added' "$MANIFEST") || true
  if [ -n "$_hx_hooks" ] && [ "$_hx_hooks" != "null" ]; then
    harness_demerge_hooks "$SETTINGS" "$_hx_hooks"
  fi
  _hx_hook_count=$(printf '%s' "$_hx_hooks" | jq 'length' 2>/dev/null) || _hx_hook_count=0
  echo "harness: deregistered $_hx_hook_count hooks from settings.json" >&2

  # Remove CLAUDE.md block
  harness_remove_claude_md
  echo "harness: removed harness block from CLAUDE.md" >&2

  # Remove manifest
  rm -f "$MANIFEST"
  echo "harness: removed manifest" >&2

  echo "harness: uninstall complete" >&2
}

# --- Main ---

# Run agents install if requested (standalone or combined with a mode)
if [ "$INSTALL_AGENTS" = "true" ]; then
  harness_install_agents
fi

# Run harness mode if one was specified
if [ -n "$MODE" ]; then
  case "$MODE" in
    install)   harness_install ;;
    update)    harness_update ;;
    uninstall) harness_uninstall ;;
  esac
fi
