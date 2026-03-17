# Spec 00: Cross-Cutting Contracts

Shared schemas, interfaces, and conventions consumed by all component specs.

## Technology Identifier Format

Technology identifiers in the tech manifest (`.claude/tech-deps.yml`) map to the **Deprecated** column of the deprecated approaches table in `.claude/rules/beads-workflow.md`.

**Normalization rules:**
- Identifiers are compared case-insensitively
- Manifest values are stored in lowercase kebab-case: `htmx`, `tailwind-css`, `cookie-based-auth`
- Deprecated table values are matched by lowercasing and converting spaces/special chars to hyphens
- Example: deprecated table entry "Tailwind CSS (server-side)" → normalized to `tailwind-css` (parenthetical stripped)

**Matching algorithm:**
1. Normalize both sides: lowercase, strip parentheticals, strip text after `/` (slash separators indicate aliases — use the primary name only), replace spaces with hyphens, collapse consecutive hyphens
2. Exact match after normalization
3. No substring or fuzzy matching — explicit identifiers only

**Slash-separated entries**: Deprecated table entries like "Incus containers / garden-pop" contain aliases. Use the primary name (before the `/`): `incus-containers`. The manifest should list only the primary normalized identifier.

## Tech Manifest Schema

File: `.claude/tech-deps.yml`

```yaml
# Technology dependencies for context documents.
# Used by archive-time housekeeping to detect stale references.

skills:
  <skill-name>:            # matches directory name under ~/.claude/skills/
    deps: [<tech-id>, ...]  # lowercase kebab-case technology identifiers
    references:              # optional: sub-files within the skill directory
      - <filename>.md

rules:
  <rule-name>:              # matches filename (without .md) under .claude/rules/
    deps: [<tech-id>, ...]

commands:
  <command-name>:           # matches filename (without .md) under .claude/commands/
    deps: [<tech-id>, ...]
```

**Constraints:**
- Top-level keys are document categories: `skills`, `rules`, `commands`
- Each entry key is a document name (not a path)
- `deps` is required (may be empty `[]`)
- `references` is optional, only meaningful for skills (lists sub-files to scan)
- File is committed to the project repo

## Document Location Resolution

The staleness scan resolves document names to file paths:

| Category | Name Example | Resolution Path |
|----------|-------------|-----------------|
| skills | `code-quality` | `~/.claude/skills/code-quality/SKILL.md` |
| skills (reference) | `go-anti-patterns.md` | `~/.claude/skills/code-quality/references/go-anti-patterns.md` |
| rules | `beads-workflow` | `.claude/rules/beads-workflow.md` |
| commands | `work-deep` | First match: `.claude/commands/work-deep.md`, then `~/.claude/commands/work-deep.md` |

**Resolution order for commands** (project overrides dotfiles):
1. `<project>/.claude/commands/<name>.md`
2. `~/.claude/commands/<name>.md`

**Resolution failure**: If a name cannot be resolved to an existing file, flag it in the staleness report as "unresolved manifest entry" — do not silently skip.

## Staleness Report Format

The staleness report is printed to the console during archive and includes three sections:

```
## Staleness Report

### Stale Dependencies
| Document | Dep | Deprecated Entry | Action |
|----------|-----|-----------------|--------|
| skill:code-quality | htmx | HTMX partial responses → JSON API | Remove htmx-checklist.md reference |

### Manifest Gaps
| Document | Found Reference | Suggested Dep |
|----------|----------------|---------------|
| rule:beads-workflow | mentions "Tailscale" | tailscale |

### Unresolved Entries
| Category | Name | Expected Path |
|----------|------|---------------|
| skills | old-skill | ~/.claude/skills/old-skill/SKILL.md |
```

Each stale finding becomes a beads issue tagged `[Housekeeping]`.

**Empty report**: If no staleness found, print "Staleness scan: clean (N documents checked)".

## Approval Signal Definitions

Valid approval signals for step gate transitions (consumed by C5):

**Affirmative signals** (case-insensitive, must be the primary intent of the user message):
- "yes", "proceed", "approve", "approved", "looks good", "lgtm", "go ahead", "continue"

**NOT approval** (must NOT advance state):
- Questions about the results ("what about X?", "can you explain Y?")
- Feedback or corrections ("change X to Y", "I'd prefer...")
- Acknowledgment without intent to proceed ("I see", "interesting", "okay let me think")
- Agent's own output (presenting results is never self-approval)

**Re-confirmation required when**:
- User asks follow-up questions after seeing results
- Agent provides additional information in response to questions
- After any exchange that isn't a direct approval signal, re-present: "Ready to advance to <next-step>? (yes/no)"

## State.json Contract

Fields used across specs (subset of full schema):

```json
{
  "current_step": "<step-name>",
  "step_status": {
    "<step>": {
      "status": "not_started|active|completed|skipped",
      "started_at": "ISO 8601 | null",
      "completed_at": "ISO 8601 | null",
      "gate_id": "<beads-issue-id> | null"
    }
  },
  "base_commit": "<git-sha>",
  "updated_at": "ISO 8601"
}
```

**Invariants:**
- Only ONE step may have `status: "active"` at any time
- `current_step` always matches the step with `status: "active"`
- `updated_at` is set on every state.json write
- State updates and result presentation must NEVER occur in the same agent turn (see C5)

## File Path Conventions

| Path | Purpose | Owned By |
|------|---------|----------|
| `.claude/tech-deps.yml` | Tech manifest (C1) | Project repo |
| `.claude/settings.json` | Hook configuration (C3) | Project repo |
| `scripts/hooks/post-compact.sh` | PostCompact hook script (C3) | Project repo |
| `.claude/commands/work-deep.md` | Tier 3 work command (C2, C5) | Dotfiles repo |
| `.claude/commands/work-feature.md` | Tier 2 work command (C2, C5) | Dotfiles repo |
| `.claude/commands/work-fix.md` | Tier 1 work command (C2, C5) | Dotfiles repo |
| `.claude/commands/work-archive.md` | Archive command (C4) | Dotfiles repo |
| `.claude/rules/beads-workflow.md` | Deprecated approaches table (C4) | Project repo |

**Cross-repo note**: C2 and C5 modify dotfiles commands (portable). C1, C3, C4 modify project-level files. The manifest (C1) bridges the two — it lives in the project but references dotfiles skills by name.
