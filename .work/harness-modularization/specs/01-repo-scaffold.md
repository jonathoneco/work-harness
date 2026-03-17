# Spec 01: Repo Scaffold (C1)

**Component:** C1 — Repo Scaffold
**Phase:** 1 (Foundation)
**Scope:** Small
**Dependencies:** None (everything else depends on this)
**References:** [architecture.md](architecture.md), [00-cross-cutting-contracts.md](00-cross-cutting-contracts.md)

---

## 1. Overview

Create the `claude-work-harness` repository with its full directory structure, top-level files, and placeholder stubs. This component establishes the physical layout that all other components populate. Nothing in C1 contains logic — it is purely scaffolding.

---

## 2. Files to Create

All paths are relative to the harness repo root (`claude-work-harness/`).

### Top-Level Files

| File | Content |
|------|---------|
| `VERSION` | `0.1.0` (single line, no trailing newline, no `v` prefix — per spec 00 section 10) |
| `README.md` | Install instructions, overview, quick-start (see section 5) |
| `LICENSE` | MIT license, year 2026, author placeholder `<Your Name>` |
| `.gitignore` | Standard entries (see section 5) |
| `install.sh` | Stub: `#!/bin/sh` + `set -eu` + `echo "harness: install.sh not yet implemented" >&2; exit 1` |

### Directory Structure

Every directory listed below must exist. Create a `.gitkeep` in any directory that would otherwise be empty.

```
claude-work-harness/
  lib/                          # C8, C9, C10 — install infrastructure
  claude/                       # Mirrors ~/.claude/ — copied on install
    commands/                   # C2, C11-C13
    skills/                     # C3
      code-quality/
        references/             # C3 language packs
    agents/                     # C4
    rules/                      # C5
  hooks/                        # C6 — stay in repo, absolute path refs
  templates/                    # C11 — harness-init templates
```

---

## 3. Implementation Steps

- [ ] **3.1** Create the repo directory and initialize git (`git init`)
- [ ] **3.2** Create `VERSION` containing `0.1.0` (no trailing newline)
- [ ] **3.3** Create `LICENSE` with MIT text, year 2026
- [ ] **3.4** Create `.gitignore` (see content below)
- [ ] **3.5** Create `install.sh` stub (executable, `chmod +x`)
- [ ] **3.6** Create all directories listed in section 2 with `.gitkeep` files where empty
- [ ] **3.7** Create `README.md` with content from section 5
- [ ] **3.8** Verify: `VERSION` is valid semver (`grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' VERSION`)
- [ ] **3.9** Verify: all directories from the repo structure (architecture.md) exist
- [ ] **3.10** Verify: `README.md` contains install instructions section
- [ ] **3.11** Initial commit: `git add -A && git commit -m "chore: scaffold repo structure"`

---

## 4. Interface Contracts

### Exposes

| What | Consumed By | Contract |
|------|------------|----------|
| `VERSION` file | C7 (install.sh), C13 (harness-doctor) | Single line, valid semver `MAJOR.MINOR.PATCH`, no `v` prefix, no trailing newline |
| Directory structure | All components | Directories exist per architecture.md repo structure |
| `install.sh` path | Users | Executable entry point (stub in C1, implemented in C7) |

### Consumes

Nothing. C1 has no dependencies.

---

## 5. File Contents

### `.gitignore`

```
# OS
.DS_Store
Thumbs.db

# Editor
*.swp
*.swo
*~
.vscode/
.idea/

# Temporary
tmp/
*.tmp
```

### `README.md`

```markdown
# claude-work-harness

A workflow harness for Claude Code — commands, skills, agents, hooks, and rules
installed globally to `~/.claude/`. Projects customize behavior via
`.claude/harness.yaml`.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [jq](https://jqlang.github.io/jq/) (JSON processing)
- [yq](https://github.com/mikefarah/yq) (YAML processing)
- [beads](https://github.com/...) (`bd` issue tracker)
- git

## Install

```sh
git clone https://github.com/<user>/claude-work-harness.git
cd claude-work-harness
./install.sh
```

## Update

```sh
cd claude-work-harness
git pull
./install.sh --update
```

## Uninstall

```sh
cd claude-work-harness
./install.sh --uninstall
```

## Project Setup

Inside any project directory:

```
/harness-init
```

This creates `.claude/harness.yaml` with your project's stack configuration.

## Health Check

```
/harness-doctor
```

## License

MIT
```

### `install.sh` (stub)

```sh
#!/bin/sh
# harness: install/update/uninstall the work harness
# Component: C7 (stub — implemented in spec 07)
set -eu

echo "harness: install.sh not yet implemented" >&2
exit 1
```

---

## 6. Testing Strategy

C1 is purely structural. Verification is file-existence checks:

```sh
# VERSION is valid semver
grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' VERSION && echo "PASS: VERSION" || echo "FAIL: VERSION"

# All required directories exist
for dir in lib claude/commands claude/skills claude/skills/code-quality/references claude/agents claude/rules hooks templates; do
  [ -d "$dir" ] && echo "PASS: $dir" || echo "FAIL: $dir"
done

# install.sh is executable
[ -x install.sh ] && echo "PASS: install.sh executable" || echo "FAIL: install.sh not executable"

# README contains install section
grep -q "## Install" README.md && echo "PASS: README install section" || echo "FAIL: README install section"
```

These checks can be run manually or incorporated into a future `/harness-doctor` (C13).

---

## 7. Edge Cases and Error Handling

| Scenario | Handling |
|----------|----------|
| Repo already exists | Not a C1 concern — C1 is initial creation only |
| VERSION with trailing newline | Use `printf '0.1.0'` instead of `echo` to avoid trailing newline |
| Empty directories not tracked by git | `.gitkeep` files ensure directories survive `git clone` |
| install.sh run before C7 is implemented | Stub exits 1 with descriptive message |

---

## 8. Acceptance Criteria

1. All directories from the architecture repo structure exist
2. `VERSION` contains valid semver (`0.1.0`), readable by `cat VERSION`
3. `README.md` contains prerequisites list, install instructions, update instructions, uninstall instructions
4. `LICENSE` contains MIT license text
5. `.gitignore` excludes OS artifacts and editor files
6. `install.sh` is executable (`-x`) and contains POSIX sh shebang
7. All empty directories contain `.gitkeep`
8. `git status` is clean after initial commit
