---
description: "Scan skills and commands for staleness, report outdated content, suggest updates"
user_invocable: true
skills: [skill-lifecycle]
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# /work-skill-update

Scan all harness skills and commands for metadata health: missing metadata, invalid fields, and staleness. This command is **read-only** — it does not modify any files.

## Execution

### 1. Scan Phase

Find all `.md` files in these locations:

- `claude/skills/**/*.md` — excluding any files under `references/` subdirectories
- `claude/commands/*.md`

For each file, parse the YAML frontmatter and extract the `meta` block.

### 2. Validation Phase

For each file, check the following in order:

1. **`meta` block exists** — If absent, classify as MISSING and skip further checks for this file.
2. **`meta.stack`** — Must be a non-empty array. If empty or absent, classify as INVALID with reason "stack is missing or empty".
3. **`meta.version`** — Must be a positive integer (>= 1). If absent, non-numeric, or < 1, classify as INVALID with reason "version is missing or invalid".
4. **`meta.last_reviewed`** — Must be a valid date in YYYY-MM-DD format. If absent or unparseable, classify as INVALID with reason "last_reviewed is missing or invalid".

A file with multiple invalid fields should report the first failure found.

### 3. Staleness Phase

For each file that passed validation (all metadata fields valid):

- Calculate days elapsed: `today - last_reviewed`
- If elapsed > 90 days, classify as STALE
- Otherwise, classify as HEALTHY

### 4. Output

Report results in this format:

```
--- Skill Health Report ---

STALE (N files, >90 days since review):
  skill-name (last reviewed: YYYY-MM-DD, N days ago)
  ...

MISSING metadata (N files):
  path/to/file.md
  ...

INVALID metadata (N files):
  path/to/file.md: <reason>
  ...

HEALTHY (N files)

--- Summary ---
N total files: N healthy, N stale, N missing, N invalid
```

If a category has 0 files, omit that section (do not print empty categories). The summary line always appears.

### 5. Suggestions

For each STALE skill:

- Note the `meta.stack` value so the reviewer knows which stack context to consider
- Suggest: "Review `<file-path>` — last reviewed N days ago (stack: `<stack-values>`)"

For MISSING or INVALID files:

- Suggest adding or fixing the `meta` block with the required fields

## Rules

- **Read-only**: Never modify any files.
- **Run all checks**: Process every file before producing output — do not short-circuit.
- **Deterministic ordering**: Sort files alphabetically within each category.
- **Relative paths**: Display file paths relative to the project root (e.g. `claude/skills/work-harness.md`, not absolute paths).

## Edge Cases

| Scenario | Handling |
|----------|----------|
| No `.md` files found | Report "No skill or command files found." and exit. |
| File has frontmatter but no `meta` key | Classify as MISSING. |
| `meta.stack` is a string instead of array | Classify as INVALID: "stack must be an array". |
| `meta.version` is 0 or negative | Classify as INVALID: "version must be a positive integer". |
| `meta.last_reviewed` is a future date | Treat as valid (0 days ago, HEALTHY). |
| File cannot be read or parsed | Report as INVALID: "frontmatter parse error". |
