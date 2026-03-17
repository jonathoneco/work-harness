# Spec 02: Config Reader (C10)

**Component:** C10 — Config Reader (`lib/config.sh`)
**Phase:** 1 (Foundation)
**Scope:** Small
**Dependencies:** C1 (repo scaffold)
**Depended on by:** C6 (hooks), C7 (install script), C9 (schema migrator)
**References:** [architecture.md](architecture.md), [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md)

---

## 1. Overview

`lib/config.sh` provides shared shell functions for reading `.claude/harness.yaml`. It is **sourced** (not executed) by hooks (C6), the install script (C7), and the schema migrator (C9). All functions use `yq` for YAML parsing and follow the naming convention `harness_` prefix (spec 00 section 2).

This is the foundational config access layer. Every component that needs project configuration goes through these functions. Getting the contract right here propagates to all consumers.

---

## 2. Files to Create

| Path (repo-relative) | Description |
|----------------------|-------------|
| `lib/config.sh` | Config reader library (sourced, not executed) |

---

## 3. Function Specifications

### 3.1 `harness_config_get <key> [<dir>]`

Read a scalar value from a project's `.claude/harness.yaml`.

**Parameters:**
- `key` — yq expression path (e.g., `.stack.language`, `.build.test`, `.schema_version`)
- `dir` — (optional) project directory to read from. Defaults to `$PWD` if omitted.

**Behavior:**
1. Set `config_dir="${2:-$PWD}"` — use provided dir or fall back to PWD
2. Check `"$config_dir/.claude/harness.yaml"` exists (via `harness_has_config "$config_dir"`)
3. Run `yq eval '<key>' "$config_dir/.claude/harness.yaml"`
4. If value is `null` or empty string, output nothing (empty stdout) and return 0
5. Otherwise output the value to stdout and return 0

**Returns:** Value on stdout. Exit 0 on success. Exit 2 if config file exists but yq fails (malformed YAML — R2).

**Examples:**
```sh
lang=$(harness_config_get '.stack.language')              # uses $PWD
fw=$(harness_config_get '.stack.framework' "/path/to/proj")  # explicit dir
ver=$(harness_config_get '.schema_version')               # "1"
```

---

### 3.2 `harness_config_list <key> [<dir>]`

Read an array from harness.yaml, one element per line.

**Parameters:**
- `key` — yq expression path to an array (e.g., `.extensions`, `.review_routing[].agents[]`)
- `dir` — (optional) project directory. Defaults to `$PWD`.

**Behavior:**
1. Set `config_dir="${2:-$PWD}"`
2. Resolve config file via `harness_has_config "$config_dir"`
3. Run `yq eval '<key> | .[]' "$config_dir/.claude/harness.yaml"`
4. If the key resolves to `null` or the array is empty, output nothing and return 0
5. Output one element per line to stdout

**Returns:** Array elements on stdout (newline-separated). Exit 0 on success. Exit 2 if yq fails on existing file (R2).

**Examples:**
```sh
harness_config_list '.extensions'                          # uses $PWD
harness_config_list '.review_routing[0].agents' "$CWD"    # explicit dir
```

---

### 3.3 `harness_has_config [<dir>]`

Check whether `.claude/harness.yaml` exists in a project directory.

**Parameters:**
- `dir` — (optional) project directory. Defaults to `$PWD`.

**Behavior:**
1. Set `config_dir="${1:-$PWD}"`
2. Check if `"$config_dir/.claude/harness.yaml"` exists as a regular file
3. Return 0 if found, return 1 if not found
4. No output on either path

**Returns:** Exit 0 if file exists, exit 1 if not. No stdout/stderr output.

**Usage pattern (by hooks):**
```sh
harness_has_config || exit 0         # Graceful skip (uses $PWD)
harness_has_config "$CWD" || exit 0  # Explicit dir
harness_validate_config "$CWD"       # Fail-closed if malformed
```

---

### 3.4 `harness_validate_config [<dir>]`

Validate that `.claude/harness.yaml` parses as valid YAML and contains required fields.

**Parameters:**
- `dir` — (optional) project directory. Defaults to `$PWD`.

**Behavior:**
1. Set `config_dir="${1:-$PWD}"`
2. Assume `harness_has_config "$config_dir"` already passed (caller's responsibility)
3. Run `yq eval '.' "$config_dir/.claude/harness.yaml" > /dev/null 2>&1`
4. If yq exits non-zero: print `harness: .claude/harness.yaml is malformed YAML` to stderr and exit 2 (R2)
5. Check `schema_version` field exists and is a positive integer:
   - `yq eval '.schema_version' "$config_dir/.claude/harness.yaml"` must produce a non-null, non-empty, positive integer
   - If missing or invalid: print `harness: .claude/harness.yaml missing or invalid schema_version` to stderr and exit 2
5. Check `project.name` field exists:
   - If missing: print `harness: .claude/harness.yaml missing project.name` to stderr and exit 2
6. Return 0 if all checks pass

**Returns:** Exit 0 on valid config. Exit 2 on any validation failure (with descriptive stderr message).

---

### 3.5 `harness_dir`

Resolve the absolute path to the harness repo installation.

**Parameters:** None.

**Behavior (resolution order):**
1. If `$HARNESS_DIR` is set and non-empty, use it
2. Else if `~/.claude/.harness-manifest.json` exists and is valid JSON, read `harness_dir` field via jq
3. Else print `harness: cannot resolve harness directory — set HARNESS_DIR or run install.sh` to stderr and exit 2

**Returns:** Absolute path to harness repo on stdout. Exit 0 on success. Exit 2 if unresolvable.

**Note:** This function requires `jq` (for manifest reading). It checks for jq only if it falls through to step 2 (no `HARNESS_DIR` set).

---

## 4. Implementation Steps

- [ ] **4.1** Create `lib/config.sh` with file header per spec 00 section 9
- [ ] **4.2** Add yq dependency check at the top of the file (R1): `command -v yq >/dev/null 2>&1 || { echo "harness: yq required but not found. Run install.sh to verify." >&2; exit 2; }`
- [ ] **4.3** Implement `harness_has_config`
- [ ] **4.4** Implement `harness_validate_config`
- [ ] **4.5** Implement `harness_config_get`
- [ ] **4.6** Implement `harness_config_list`
- [ ] **4.7** Implement `harness_dir`
- [ ] **4.8** Verify: sourcing the file with no arguments does not produce output or side effects
- [ ] **4.9** Verify: each function works against a valid test harness.yaml
- [ ] **4.10** Verify: malformed YAML triggers exit 2 with descriptive error

---

## 5. Interface Contracts

### Exposes

| Function | Consumers | Contract |
|----------|-----------|----------|
| `harness_has_config` | C6 (all hooks), C7, C9 | Returns 0 if `.claude/harness.yaml` exists in cwd, 1 otherwise. No output. |
| `harness_validate_config` | C6 (all hooks), C7 | Exits 2 with stderr message if config is invalid. Caller must call `harness_has_config` first. |
| `harness_config_get <key>` | C6, C7, C9 | Outputs scalar value to stdout. Empty output for null/missing keys. Exit 2 on malformed YAML. |
| `harness_config_list <key>` | C6, C7 | Outputs array elements, one per line. Empty output for null/empty arrays. Exit 2 on malformed YAML. |
| `harness_dir` | C6 (hooks, for sourcing lib scripts), C7 | Outputs absolute path to harness repo. Exit 2 if unresolvable. |

### Consumes

| What | Source | Contract |
|------|--------|----------|
| `yq` binary | System PATH | Must be installed. Checked at source-time (R1). |
| `jq` binary | System PATH | Only needed by `harness_dir` when manifest fallback is used. Checked before use. |
| `.claude/harness.yaml` | Project directory (cwd) | Schema per spec 00 section 4 |
| `~/.claude/.harness-manifest.json` | Install target | Schema per spec 00 section 5 (read by `harness_dir`) |

### Sourcing Contract

This file is **sourced**, not executed. Consumers use:
```sh
. "$HARNESS_DIR/lib/config.sh"
```

The yq dependency check runs at source time. If yq is missing, the sourcing script exits immediately with code 2. This is intentional: no config function can work without yq, so fail-fast is correct.

---

## 6. Implementation Notes

### yq Null Handling

yq outputs the literal string `null` for missing keys. All functions must normalize this:

```sh
_harness_normalize_yq_output() {
  # Read from stdin, suppress yq's "null" for missing values
  value=$(cat)
  case "$value" in
    null|"") return 0 ;;
    *) printf '%s\n' "$value" ;;
  esac
}
```

This internal helper is prefixed with `_harness_` (underscore = private) per naming convention.

### Config File Path

All functions use a consistent path resolution. The config file is always `.claude/harness.yaml` relative to `$PWD`. This is not configurable — hooks run in the project directory, and that is where the config lives.

```sh
_HARNESS_CONFIG=".claude/harness.yaml"
```

### POSIX Compliance

No bashisms. Specifically:
- Use `[ ]` not `[[ ]]`
- Use `$(command)` not backticks
- No arrays (use newline-separated strings)
- No `local` keyword (use subshells or unique variable names if needed)

**Note on `local`:** While `local` is technically a bashism, it is supported by every modern POSIX-compatible shell (dash, ash, busybox sh, etc.) and is widely used in POSIX sh scripts. If strict POSIX compliance is required, avoid it. Otherwise, it is pragmatically acceptable. This spec uses function-scoped variables with unique prefixes instead.

---

## 7. Testing Strategy

Manual testing via shell invocations against fixture files.

### Test Fixtures

Create a temporary directory with test configs:

```sh
# Valid config
mkdir -p /tmp/harness-test/.claude
cat > /tmp/harness-test/.claude/harness.yaml <<'EOF'
schema_version: 1
project:
  name: test-project
  description: "A test project"
stack:
  language: go
  framework: chi
  frontend: null
  database: postgresql
build:
  test: "make test"
  build: "make build"
  lint: "make lint"
  format: "gofmt -w ."
extensions: [".go", ".sql"]
review_routing:
  - patterns: ["*.go"]
    agents: [code-reviewer]
anti_patterns:
  - pattern: "_, _ ="
    description: "Swallowed error"
EOF

# Malformed config
mkdir -p /tmp/harness-bad/.claude
echo "schema_version: [invalid yaml" > /tmp/harness-bad/.claude/harness.yaml

# Missing required fields
mkdir -p /tmp/harness-missing/.claude
echo "schema_version: 1" > /tmp/harness-missing/.claude/harness.yaml
```

### Test Cases

| # | Test | Command | Expected |
|---|------|---------|----------|
| 1 | Config exists | `cd /tmp/harness-test && harness_has_config; echo $?` | `0` |
| 2 | Config missing | `cd /tmp && harness_has_config; echo $?` | `1` |
| 3 | Valid config validates | `cd /tmp/harness-test && harness_validate_config; echo $?` | `0` |
| 4 | Malformed YAML fails | `cd /tmp/harness-bad && harness_validate_config 2>&1; echo $?` | stderr message + `2` |
| 5 | Missing project.name fails | `cd /tmp/harness-missing && harness_validate_config 2>&1; echo $?` | stderr message + `2` |
| 6 | Read scalar | `cd /tmp/harness-test && harness_config_get '.stack.language'` | `go` |
| 7 | Read null field | `cd /tmp/harness-test && harness_config_get '.stack.frontend'` | empty output |
| 8 | Read missing key | `cd /tmp/harness-test && harness_config_get '.nonexistent'` | empty output |
| 9 | Read array | `cd /tmp/harness-test && harness_config_list '.extensions'` | `.go\n.sql` |
| 10 | Read empty array | create config with `extensions: []`, list it | empty output |
| 11 | harness_dir with HARNESS_DIR set | `HARNESS_DIR=/tmp/foo harness_dir` | `/tmp/foo` |
| 12 | harness_dir with neither env nor manifest | `unset HARNESS_DIR && harness_dir 2>&1; echo $?` | stderr message + `2` |

These tests can also be validated by `/harness-doctor` (C13) once implemented.

---

## 8. Edge Cases and Error Handling

| Scenario | Handling |
|----------|----------|
| yq not installed | Source-time exit 2 with message (R1). All consumers fail immediately. |
| `.claude/harness.yaml` not found | `harness_has_config` returns 1. Caller decides behavior (hooks exit 0, install may error). |
| `.claude/harness.yaml` exists but is empty file | `harness_validate_config` fails on missing `schema_version` — exit 2. |
| `.claude/harness.yaml` has valid YAML but missing required fields | `harness_validate_config` catches missing `schema_version` and `project.name` — exit 2. |
| `schema_version` is not an integer (e.g., `"1"` as string) | yq returns it as-is. Validate with a numeric check: `echo "$val" \| grep -qE '^[0-9]+$'`. |
| `harness_config_get` called with invalid yq expression | yq exits non-zero. Function exits 2 with error message. |
| `harness_config_list` on a scalar (not an array) | yq errors. Function exits 2. Consumer gets a clear failure, not garbage output. |
| `harness_dir` — manifest exists but is invalid JSON | jq fails. Function exits 2 with descriptive message. |
| `harness_dir` — manifest exists but `harness_dir` field missing | jq outputs `null`. Function treats as unresolvable, exits 2. |
| Concurrent reads (multiple hooks sourcing simultaneously) | Not a concern — shell sourcing is per-process. No shared mutable state. |
| Config file is a symlink | `[ -f ]` follows symlinks. This is fine — symlinked configs are valid. |
| Config file has restrictive permissions | yq will fail to read it. Error propagates naturally as exit 2. |

---

## 9. Acceptance Criteria

1. `lib/config.sh` exists and is a valid POSIX sh file (no bashisms)
2. Sourcing the file when yq is present produces no output and no side effects
3. Sourcing the file when yq is missing exits 2 with a descriptive stderr message (R1)
4. `harness_has_config` returns 0 when `.claude/harness.yaml` exists, 1 when absent
5. `harness_validate_config` exits 2 with stderr message for malformed YAML (R2)
6. `harness_validate_config` exits 2 for configs missing `schema_version` or `project.name`
7. `harness_config_get` returns scalar values, empty string for null/missing keys
8. `harness_config_list` returns one element per line, empty output for null/empty arrays
9. `harness_dir` resolves via `$HARNESS_DIR` env var first, manifest fallback second
10. All error messages use the `harness:` prefix and write to stderr
11. All exit codes follow spec 00 section 3 (0 = success/skip, 1 = not found, 2 = blocked)
