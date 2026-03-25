---
stream: B
phase: 1
isolation: subagent
agent_type: general-purpose
skills: [work-harness, code-quality]
scope_estimate: S
file_ownership:
  - claude/skills/code-quality/references/go-anti-patterns.md
---

# Stream B — Go Pack Refactor (Phase 1)

## Work Items
- **W-12** (work-harness-alc.12): Go pack standard format

## Spec References
- Spec 00: Contract 1 (pack entry format standard — categories, severity, 7 required fields)
- Spec 05: C03 (Go pack refactoring)

## What To Do

Reformat all entries in `claude/skills/code-quality/references/go-anti-patterns.md` from the current ad-hoc format to the Spec 00 Contract 1 standard entry format.

For each entry, transform:
1. Prefix H2 heading with the appropriate category (Anti-pattern, Best Practice, Idiomatic, Performance, Security)
2. Add `**Severity**: error|warn|info` line after each heading
3. Add `**Why**:` section (extract rationale from existing description or write concise version)
4. Standardize BAD/GOOD comment format (ensure `// BAD` and `// GOOD` markers)

### Entry-to-Category Mapping (from spec 05)

| Current Title | Target Category | Target Severity |
|--------------|-----------------|-----------------|
| Fail closed, never fail open | Security | error |
| Never swallow errors | Anti-pattern | error |
| Never fabricate data | Anti-pattern | error |
| Always handle both branches | Anti-pattern | error |
| Constructor injection only | Best Practice | warn |
| Return complete results | Anti-pattern | warn |
| No divergent copies of the same interface | Anti-pattern | warn |
| No shims, scaffolding, or backward compatibility | Anti-pattern | warn |
| Missing error wrapping | Idiomatic | warn |
| Bare fmt.Println instead of structured logging | Best Practice | warn |

### Rules
- Preserve ALL existing code examples (no content loss)
- Keep the file's opening paragraph as an introductory section above entries
- Entries overlapping with `code-quality.md` universal rules must have Go-specific examples (they should already)

## Acceptance Criteria
- AC-C03-2.1: All entries follow Spec 00 Contract 1 format (all 7 required fields)
- AC-C03-2.2: All existing code examples are preserved
- AC-C03-2.3: Category is one of 5 fixed values per Spec 00
- AC-C03-2.4: Severity is one of error/warn/info
- AC-C03-2.5: File's opening paragraph preserved as introductory section
- AC-C03-3.1: Entries overlapping universal rules have Go-specific examples

## Dependency Constraints
- None — this is a Phase 1 stream, runs in parallel with Stream A
- This file (`references/go-anti-patterns.md`) is NOT touched by metadata tagging (Stream A only touches skill/command files, not reference files)
