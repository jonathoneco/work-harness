# Spec 01: Project-Level Tech Manifest (C1)

**Component**: C1 | **Scope**: Small | **Phase**: 1 | **Dependencies**: spec 00

## Overview

Create `.claude/tech-deps.yml` — a project-level YAML manifest mapping context documents to their technology dependencies. This enables the archive-time staleness scan (C4) to detect when documents reference deprecated technologies, without modifying portable dotfiles skills.

## Implementation Steps

### Step 1: Create the manifest file

**File**: `.claude/tech-deps.yml`

**Acceptance criteria**:
- File exists at `.claude/tech-deps.yml`
- Follows the schema defined in spec 00
- Contains entries for all current skills, rules, and commands that have technology dependencies
- Technology identifiers are lowercase kebab-case
- File includes a header comment explaining its purpose

### Step 2: Populate initial entries

Scan existing context documents and populate the manifest. This is the bootstrapping step (resolves deferred question #7).

**Process** (manual, one-time):
1. List all skills: `ls ~/.claude/skills/*/SKILL.md`
2. List all rules: `ls .claude/rules/*.md`
3. List all commands: `ls .claude/commands/*.md` and `ls ~/.claude/commands/*.md`
4. For each, identify technology references by reading content
5. Cross-reference against the deprecated approaches table in `beads-workflow.md`
6. Add entries to the manifest

**Acceptance criteria**:
- Every context document with technology-specific content has a manifest entry
- Documents with no tech deps have an entry with `deps: []` OR are omitted (omission = no deps)
- `references` field is populated for skills with sub-files (e.g., `code-quality` has `go-anti-patterns.md`, `htmx-checklist.md`)

### Step 3: Validate manifest completeness

**Acceptance criteria**:
- Manifest parses as valid YAML
- All `deps` values are lowercase kebab-case strings
- All document names resolve to existing files per spec 00 resolution rules
- No duplicate entries within a category

## Interface Contracts

**Exposes** (consumed by C4):
- `.claude/tech-deps.yml` — read by archive-time housekeeping scan

**Consumes**:
- Spec 00: technology identifier format, document location resolution rules

## Files to Create/Modify

| File | Action |
|------|--------|
| `.claude/tech-deps.yml` | **Create** |

## Testing Strategy

- **Manual validation**: Parse YAML, verify all names resolve to files, verify identifier format
- **No automated tests**: This is a static configuration file; validation happens at archive time (C4)

## Deferred Question Resolution

**Q7 — Manifest bootstrapping**: Manual creation during implementation. The archive-time scan (C4) will catch gaps going forward by grepping document content for technology references not declared in the manifest. A `generate-manifest` script is deferred as a future (not worth automating for ~30 files).
