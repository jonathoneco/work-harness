# Spec C07: Context-Docs Skill Enrichment

**Component**: C07 — Context-docs skill enrichment
**Phase**: 1 (Foundation)
**Status**: complete
**Dependencies**: Spec 00 (frontmatter meta block via C13)

---

## Overview and Scope

Enriches `claude/skills/work-harness/context-docs.md` (100 lines) with concrete examples of the manifest format, edge case handling for missing/stale docs, and guidelines for agents flagging doc impacts.

**What this does**:
- Adds concrete YAML examples for common stack configurations
- Adds edge case handling (missing files, stale docs, conflicting types)
- Adds agent guidelines for doc impact flagging
- Adds `meta` block (handled by C13)

**What this does NOT do**:
- Change the auto-detection mapping table (it is already comprehensive)
- Add new doc types
- Implement automated doc updating (explicitly out of scope -- advisory only)

---

## Implementation Steps

### Step 1: Add Concrete Stack Examples

After the existing "Auto-Detection" section, add examples:

```markdown
## Configuration Examples

### Go API project
```yaml
stack:
  language: go
  framework: gin
  database: postgres
docs:
  managed:
    - type: endpoints
      path: docs/endpoints.md
    - type: schema
      path: docs/schema.md
    - type: packages
      path: docs/packages.md
```

### Next.js fullstack project
```yaml
stack:
  language: typescript
  framework: nextjs
  database: postgres
  frontend: nextjs
docs:
  managed:
    - type: endpoints
      path: docs/endpoints.md
    - type: components
      path: docs/components.md
    - type: schema
      path: docs/schema.md
    - type: env-setup
      path: docs/env-setup.md
```

### Python ML project (explicit opt-out)
```yaml
stack:
  language: python
docs:
  managed: []  # No managed docs -- project uses Sphinx
```
```

**Acceptance Criteria**:
- AC-C07-1.1: Three concrete configuration examples are present
- AC-C07-1.2: Examples cover different stack profiles (API, fullstack, opt-out)
- AC-C07-1.3: Examples use valid YAML that matches the schema defined in the existing spec

### Step 2: Add Edge Case Handling

```markdown
## Edge Cases

### Missing doc file on disk
When a managed doc path does not exist on disk:
- **Agent behavior**: Note it as missing in context injection ("endpoints: docs/endpoints.md [MISSING]")
- **Do not block**: Missing docs should not prevent work from proceeding
- **Do not auto-create**: The user is responsible for creating managed doc files

### Stale docs
When an agent makes code changes that affect a managed doc area (e.g., adding a new endpoint):
- Flag the doc type in the completion message: "Note: endpoints doc may need updating (new `/api/v2/users` endpoint added)"
- Do NOT auto-update the doc file
- Include the specific change that may affect the doc

### Conflicting auto-detection
When multiple stack fields suggest the same doc type:
- Deduplicate: If both `framework: nextjs` and `frontend: nextjs` suggest `components`, include it once
- Use the default path from the mapping table
- This is expected and not an error

### No harness.yaml
When `.claude/harness.yaml` does not exist:
- Skip context-docs entirely
- No error, no warning
- Commands proceed without managed doc context
```

**Acceptance Criteria**:
- AC-C07-2.1: Four edge cases are documented (missing file, stale docs, conflicting detection, no harness.yaml)
- AC-C07-2.2: Each edge case has explicit agent behavior guidance
- AC-C07-2.3: "Do NOT auto-update" is explicitly stated

### Step 3: Add Agent Doc Impact Flagging Guidelines

```markdown
## Agent Doc Impact Flagging

When implementation agents make changes that may affect managed docs, they should flag the impact in their completion output:

### What triggers a flag
- Adding/removing/renaming API endpoints → flag `endpoints`
- Adding/removing/renaming UI components → flag `components`
- Modifying database schema or migrations → flag `schema`, `migrations`
- Adding/removing packages or dependencies → flag `packages`
- Changing environment variables → flag `env-setup`

### Flag format in agent completion
```
Doc impact: [type] may need updating — [specific change description]
```

### What does NOT trigger a flag
- Internal refactoring that doesn't change public interfaces
- Test changes
- Documentation changes (already being updated)
- Configuration changes that don't affect the managed doc types
```

**Acceptance Criteria**:
- AC-C07-3.1: Agent doc impact flagging section exists
- AC-C07-3.2: Trigger conditions are documented with specific mappings
- AC-C07-3.3: Flag format template is provided
- AC-C07-3.4: Non-trigger conditions are explicitly listed

---

## Interface Contracts

### Exposes

- **Enriched context-docs skill**: Better guidance for agents on doc management

### Consumes

- **Spec 00 Contract 2**: `meta` block added by C13
- **`harness.yaml` schema**: `docs.managed` and `stack.*` fields

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/skills/work-harness/context-docs.md` | Add examples, edge cases, flagging guidelines |

**Total**: 0 new files, 1 modified file

---

## Testing Strategy

1. **Section presence**: Verify all three new sections exist
2. **YAML validity**: Verify all YAML examples in the configuration examples parse correctly
3. **No regression**: Verify existing manifest format, auto-detection table, agent context injection, and doc maintenance sections are unchanged
4. **Edge case coverage**: Each of the 4 edge cases has explicit behavior guidance
