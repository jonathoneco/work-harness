# Spec C03: Go Pack Refactoring

**Component**: C03 — Go pack refactoring
**Phase**: 2 (Content Packs)
**Status**: complete
**Dependencies**: Spec 00 (entry format standard)

---

## Overview and Scope

Refactors the existing `go-anti-patterns.md` (216 lines, 11 rules) to match the Spec 00 Contract 1 entry format standard. The existing content is high quality but uses an ad-hoc format without severity markers or categories.

**What this does**:
- Reformats all 11 existing entries to the standard entry format
- Adds severity and category to each entry
- Preserves all existing code examples (they already use BAD/GOOD pattern)
- Optionally adds 1-2 new entries if gaps are identified during reformatting

**What this does NOT do**:
- Delete or substantially rewrite existing content (it works well)
- Change file location (stays at `references/go-anti-patterns.md`)
- Add separate Go files for other categories (single file remains)

---

## Implementation Steps

### Step 1: Map Existing Entries to Standard Format

Current entries and their target metadata:

| # | Current H2 Title | Target Category | Target Severity |
|---|-----------------|-----------------|-----------------|
| 1 | Fail closed, never fail open | Security | error |
| 2 | Never swallow errors | Anti-pattern | error |
| 3 | Never fabricate data | Anti-pattern | error |
| 4 | Always handle both branches | Anti-pattern | error |
| 5 | Constructor injection only | Best Practice | warn |
| 6 | Return complete results | Anti-pattern | warn |
| 7 | No divergent copies of the same interface | Anti-pattern | warn |
| 8 | No shims, scaffolding, or backward compatibility | Anti-pattern | warn |
| 9 | Missing error wrapping | Idiomatic | warn |
| 10 | Bare fmt.Println instead of structured logging | Best Practice | warn |

Note: Only 10 entries enumerated. The file header counts as the 11th "rule" but is actually a preamble. Verify during implementation -- the actual entry count is 10.

### Step 2: Reformat Each Entry

For each entry, transform from:

```markdown
## [Title]

[Description paragraph]

```go
// BAD — [annotation]
...
```

```go
// GOOD — [annotation]
...
```
```

To the standard format:

```markdown
## [Category]: [Title]
**Severity**: [severity]

[Description paragraph]

**Why**: [Extracted from description or added]

```go
// BAD
...
```

```go
// GOOD
...
```
```

Changes per entry:
- Prefix H2 with category
- Add `**Severity**:` line after heading
- Add `**Why**:` section (extract rationale from existing description or write concise version)
- Standardize BAD/GOOD comment format (remove ` — annotation` suffix if present, keep it on the line below as context)

**Acceptance Criteria**:
- AC-C03-2.1: All entries follow Spec 00 Contract 1 format (all 7 required fields)
- AC-C03-2.2: All existing code examples are preserved (no content loss)
- AC-C03-2.3: Category is one of the 5 fixed values per Spec 00
- AC-C03-2.4: Severity is one of error/warn/info per Spec 00
- AC-C03-2.5: The file's opening paragraph is preserved as an introductory section above the entries

### Step 3: Remove File Header Duplication

The existing Go pack's first 5 rules overlap with `code-quality.md` universal rules (fail closed, never swallow errors, never fabricate data, always handle both branches, constructor injection only). These are in both places.

**Decision**: Keep them in the Go pack with Go-specific examples. The universal rules in `code-quality.md` use language-agnostic descriptions. The Go pack versions add Go-specific code examples and nuance. This is additive, not duplicative -- the Go pack shows *how* the universal rule manifests in Go specifically.

**Acceptance Criteria**:
- AC-C03-3.1: Entries that overlap with universal rules have Go-specific examples that differ from the universal rule descriptions

---

## Interface Contracts

### Exposes

- **Reformatted go-anti-patterns.md**: Same file, same location, now follows the standard format

### Consumes

- **Spec 00 Contract 1**: Entry format standard

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/skills/code-quality/references/go-anti-patterns.md` | Reformat to standard entry format |

**Total**: 0 new files, 1 modified file

---

## Testing Strategy

1. **Format compliance**: Verify every entry follows Spec 00 Contract 1 (all 7 fields present)

2. **Content preservation**: Compare code examples before and after -- all BAD/GOOD code blocks must be preserved. Use `diff` focused on code blocks to verify no example was lost.

3. **Entry count**: Verify the reformatted file has at least 10 entries (same as original)

4. **Category/severity validation**: Extract all categories and severities, verify they are valid values per Spec 00
