# Spec 03: Context Doc System (C3)

**Component**: C3 | **Scope**: Large | **Phase**: 1 | **Dependencies**: spec 00

## Overview

Introduce a manifest-driven system for declaring, auto-detecting, and injecting project documentation into agent context. Projects declare managed docs in `harness.yaml` under `docs.managed`. When the manifest is empty or absent, the system infers useful doc types from the project's stack config. Agent-spawning logic in commands and the implement agent reads the manifest and includes managed doc paths in agent prompts, so every spawned agent starts with relevant project documentation.

## Scope

**In scope:**
- `harness.yaml` schema extension: `docs.managed` array
- Auto-detection heuristic mapping: stack config fields to suggested doc types
- A new skill (`claude/skills/work-harness/context-docs.md`) that documents the system and provides agent injection instructions
- Modifications to `claude/commands/work-deep.md` and `claude/agents/work-implement.md` to read and inject managed docs
**Out of scope:**
- Automated doc generation or writing (agents do not auto-update managed docs)
- Staleness detection or drift scanning (future enhancement)
- CI/CD integration for doc freshness
- MCP-based doc tools (Storybook MCP, etc.)

## Implementation Steps

### Step 1: Extend `harness.yaml` schema with `docs.managed`

Add the `docs` section to the harness.yaml template and document the schema.

**Schema:**
```yaml
docs:
  managed:
    - type: endpoints       # doc type identifier (lowercase, hyphenated)
      path: docs/endpoints.md  # project-relative path
    - type: components
      path: docs/components.md
    - type: schema
      path: docs/schema.md
```

**Validation rules:**
- `type`: required, lowercase hyphenated string, unique within the array
- `path`: required, project-relative path, must end in `.md`
- Array may be empty (explicit opt-out) or absent (triggers auto-detection)

**AC-01**: `harness.yaml` template includes a commented-out `docs.managed` section with example entries -- verified by `structural-review`

**AC-02**: `lib/config.sh` validation rejects duplicate `type` values within `docs.managed` and paths not ending in `.md` -- verified by `manual-test`

### Step 2: Implement auto-detection heuristics

When `docs.managed` is absent from `harness.yaml` (key not present at all, as distinct from an empty array), suggest doc types based on stack config fields. Auto-detection is advisory only: it produces suggestions, not automatically created files.

**Detection mapping table:**

| Stack Field | Value | Suggested Doc Types |
|-------------|-------|-------------------|
| `language` | `go` | `packages` |
| `language` | `python` | `packages`, `models` |
| `language` | `typescript` | `packages` |
| `framework` | `nextjs` | `components`, `endpoints`, `env-setup` |
| `framework` | `django` | `endpoints`, `models`, `env-setup` |
| `framework` | `rails` | `endpoints`, `models`, `env-setup` |
| `framework` | `gin` | `endpoints` |
| `framework` | `echo` | `endpoints` |
| `framework` | `fiber` | `endpoints` |
| `framework` | `fastapi` | `endpoints`, `models` |
| `framework` | `flask` | `endpoints` |
| `framework` | `react` | `components` |
| `framework` | `vue` | `components` |
| `framework` | `svelte` | `components` |
| `framework` | `htmx` | `endpoints`, `components` |
| `database` | `postgres` | `schema`, `migrations` |
| `database` | `mysql` | `schema`, `migrations` |
| `database` | `sqlite` | `schema` |
| `database` | `mongodb` | `schema` |
| `frontend` | any non-null value | `components` |

**Suggested default paths by type:**

| Doc Type | Default Path |
|----------|-------------|
| `endpoints` | `docs/endpoints.md` |
| `components` | `docs/components.md` |
| `models` | `docs/models.md` |
| `schema` | `docs/schema.md` |
| `migrations` | `docs/migrations.md` |
| `packages` | `docs/packages.md` |
| `env-setup` | `docs/env-setup.md` |

**Behavior:** When a command or skill detects that `docs.managed` is absent, it reads stack fields, applies the mapping table, deduplicates results, and presents the suggestions to the user. The user adds their selections to `harness.yaml` or sets `docs.managed: []` to suppress future suggestions.

**AC-03**: When `docs.managed` key is absent and stack config has `framework: nextjs` and `database: postgres`, auto-detection suggests `components`, `endpoints`, `env-setup`, `schema`, `migrations` with default paths -- verified by `manual-test`

**AC-04**: When `docs.managed` is present (even as empty array `[]`), auto-detection does not run -- verified by `manual-test`

**AC-05**: Duplicate doc types from multiple stack fields are deduplicated (e.g., `framework: nextjs` and `frontend: react` both suggest `components`, but it appears only once) -- verified by `manual-test`

### Step 3: Create the context-docs skill

**File**: `claude/skills/work-harness/context-docs.md`

This skill documents the context doc system and provides instructions for how agents should use managed docs. It is loaded when the work-harness skill activates.

**Sections:**
- When This Activates: `harness.yaml` has `docs.managed` entries
- Reading the manifest: how to parse `docs.managed` from `harness.yaml`
- Auto-detection: when and how to suggest doc types
- Agent context injection: instructions for including managed doc paths in agent prompts
- Doc maintenance: guidance for agents to flag when code changes may affect managed docs (advisory, not enforced)

**AC-06**: Skill file exists at `claude/skills/work-harness/context-docs.md` with valid frontmatter (`name`, `description`) and all four sections -- verified by `structural-review`

### Step 4: Modify agent-spawning logic for context injection

Update commands and agents that spawn subagents to read `docs.managed` from `harness.yaml` and include relevant doc paths in agent prompts.

**Files to modify:**
- `claude/commands/work-deep.md`: In the research, plan, and implement step sections, add an instruction to read `docs.managed` and include managed doc paths in agent context. Specifically:
  - Research agents: receive all managed doc paths (full project context)
  - Plan agents: receive all managed doc paths
  - Implement agents: receive managed doc paths relevant to their stream's file scope (or all, if relevance cannot be determined)
- `claude/agents/work-implement.md`: Add a section instructing the agent to read managed docs from `harness.yaml` before starting implementation, similar to the existing "Config injection" paragraph

**Injection format in agent prompts:**
```
## Managed Project Docs
The following project documents are maintained and should be consulted:
- endpoints: docs/endpoints.md
- components: docs/components.md
```

**AC-07**: `work-deep.md` research step instructions include reading `docs.managed` and passing paths to research agents -- verified by `structural-review`

**AC-08**: `work-deep.md` implement step instructions include reading `docs.managed` and passing paths to implementation agents -- verified by `structural-review`

**AC-09**: `work-implement.md` includes a "Managed Docs" section instructing the agent to read harness.yaml for managed doc paths -- verified by `structural-review`

## Interface Contracts

**Exposes:**
- `harness.yaml` `docs.managed[]` schema -- consumed by agent-spawning logic in commands
- Context-docs skill -- consumed by agents via `skills: [work-harness]`

**Consumes:**
- `harness.yaml` `stack` config -- read by auto-detection heuristics
- Spec 00: naming conventions, path conventions

## Files

| File | Action | Description |
|------|--------|-------------|
| `templates/harness.yaml.template` | Modify | Add commented `docs.managed` section with examples |
| `claude/skills/work-harness/context-docs.md` | Create | Context doc system skill with auto-detection mapping and injection instructions |
| `claude/commands/work-deep.md` | Modify | Add managed doc reading and injection in research, plan, and implement steps |
| `claude/agents/work-implement.md` | Modify | Add managed docs section to agent instructions |

## Testing Strategy

| What | Method | Details |
|------|--------|---------|
| Schema validation | `manual-test` | Create `harness.yaml` with `docs.managed` entries; verify `lib/config.sh` accepts valid configs and rejects duplicates |
| Auto-detection | `manual-test` | Set stack fields in `harness.yaml`, remove `docs.managed`, verify suggestions match mapping table |
| Skill structure | `structural-review` | Verify frontmatter, sections, cross-references |
| Agent injection | `integration-test` | Run `/work-deep` on a test task with `docs.managed` configured; verify spawned agents receive doc paths in their prompts |
| State field | `structural-review` | Verify `state-conventions.md` documents the new field |

## Deferred Questions Resolution

**DQ-1: C3 auto-detection heuristics -- which stack config fields map to which doc types?**

Resolved with the concrete mapping table in Step 2. The mapping covers 5 stack fields (`language`, `framework`, `database`, `frontend`, plus their specific values) across 18 value-to-doctype mappings. The table is extensible: new mappings can be added to the skill file without schema changes.

## Advisory Notes Resolution

**A2: C3 auto-detection concrete examples**

Addressed in Step 2 with the full detection mapping table. Three specific examples from the advisory:
- `framework: nextjs` suggests `components`, `endpoints`, `env-setup`
- `framework: django` suggests `endpoints`, `models`, `env-setup`
- `database: postgres` suggests `schema`, `migrations`
- `language: go` suggests `packages`

The mapping table is documented in both the spec (for implementers) and the context-docs skill (for runtime use).
