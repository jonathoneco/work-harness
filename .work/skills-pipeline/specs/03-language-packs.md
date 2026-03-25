# Spec C01: Language Packs (Python, TypeScript, Rust)

**Component**: C01 — Language packs
**Phase**: 2 (Content Packs)
**Status**: complete
**Dependencies**: Spec 00 (entry format standard), Spec C04 (discovery works for language packs already)

---

## Overview and Scope

Creates from-scratch language packs for Python, TypeScript, and Rust. Each pack contains curated anti-patterns, best practices, idiomatic patterns, and security rules specifically targeting mistakes that AI coding assistants make. Content is informed by the research in `05-language-pack-formats.md` but written from scratch (DD-1).

**What this does**:
- Creates `references/python-anti-patterns.md` (15-20 entries)
- Creates `references/typescript-anti-patterns.md` (15-20 entries)
- Creates `references/rust-anti-patterns.md` (15-20 entries)

**What this does NOT do**:
- Vendor content from external rule libraries (rejected per DD-1)
- Create `*-best-practices.md`, `*-idiomatic.md`, etc. (deferred -- single anti-patterns file per language for V1, categories used within the file)
- Modify `code-quality.md` (already done in C04)
- Create framework packs (that's C02)

---

## Implementation Steps

### Step 1: Create Python Anti-Patterns Pack

Create `claude/skills/code-quality/references/python-anti-patterns.md`.

All entries follow Spec 00 Contract 1 (entry format standard). Content informed by research sources: PEP 8, Google Style Guide, Ruff rules, Little Book of Python Anti-Patterns.

**Required entries** (minimum 15, target 18-20):

| # | Category | Rule Name | Severity | Source Inspiration |
|---|----------|-----------|----------|-------------------|
| 1 | Anti-pattern | Mutable Default Arguments | error | PEP 8, universal |
| 2 | Anti-pattern | Bare Except Clause | error | Ruff B001 |
| 3 | Anti-pattern | Unawaited Coroutine | error | Common AI mistake |
| 4 | Anti-pattern | String Concatenation in Loop | warn | Ruff PERF401 |
| 5 | Anti-pattern | Silent Exception Swallowing | error | Ruff E722 |
| 6 | Anti-pattern | Late Binding Closures in Loops | error | Common AI mistake |
| 7 | Anti-pattern | Type Checking with isinstance vs type | warn | PEP 8 |
| 8 | Best Practice | Use Context Managers for Resources | warn | PEP 343 |
| 9 | Best Practice | Explicit is Better than Implicit Returns | info | Zen of Python |
| 10 | Idiomatic | Use Enumerate Instead of Range(len()) | info | PEP 279 |
| 11 | Idiomatic | Use f-strings Over format() or % | info | PEP 498 |
| 12 | Idiomatic | Use Pathlib Over os.path | info | PEP 428 |
| 13 | Performance | Avoid Global Variable Lookup in Hot Paths | warn | CPython internals |
| 14 | Security | Use secrets Module for Tokens, Not random | error | CWE-338 |
| 15 | Security | Avoid eval() and exec() on User Input | error | CWE-94 |
| 16 | Anti-pattern | Circular Import via Top-Level Import | warn | Common AI mistake |
| 17 | Anti-pattern | Inconsistent Return Types | warn | Mypy patterns |
| 18 | Best Practice | Use dataclasses or TypedDict for Structured Data | info | Modern Python |

**Acceptance Criteria**:
- AC-C01-1.1: File exists at `claude/skills/code-quality/references/python-anti-patterns.md`
- AC-C01-1.2: Contains at least 15 entries
- AC-C01-1.3: Every entry follows Spec 00 Contract 1 format (all 7 required fields)
- AC-C01-1.4: Code examples use `python` as the code fence language
- AC-C01-1.5: BAD examples use `# BAD` comment (Python-style)
- AC-C01-1.6: GOOD examples use `# GOOD` comment (Python-style)
- AC-C01-1.7: No entry duplicates content from `code-quality.md` universal rules (those are language-agnostic)

### Step 2: Create TypeScript Anti-Patterns Pack

Create `claude/skills/code-quality/references/typescript-anti-patterns.md`.

Content informed by: typescript-eslint, Google TS Style Guide, Effective TypeScript, Biome rules.

**Required entries** (minimum 15, target 18-20):

| # | Category | Rule Name | Severity | Source Inspiration |
|---|----------|-----------|----------|-------------------|
| 1 | Anti-pattern | Abuse of `any` Type | error | typescript-eslint no-explicit-any |
| 2 | Anti-pattern | Unawaited Promise | error | @typescript-eslint/no-floating-promises |
| 3 | Anti-pattern | Non-null Assertion After Optional Chaining | error | Common AI mistake |
| 4 | Anti-pattern | Truthiness Filtering Removes Valid Falsy Values | warn | @typescript-eslint/strict-boolean-expressions |
| 5 | Anti-pattern | typeof null Returns "object" | warn | JS specification gotcha |
| 6 | Anti-pattern | Missing Exhaustive Check in Switch | error | @typescript-eslint/switch-exhaustiveness-check |
| 7 | Anti-pattern | Import Type Used as Value | warn | @typescript-eslint/consistent-type-imports |
| 8 | Best Practice | Use readonly for Immutable Properties | info | Effective TS Item 17 |
| 9 | Best Practice | Prefer unknown Over any for External Data | warn | Effective TS Item 42 |
| 10 | Best Practice | Use Type Guards Over Type Assertions | warn | typescript-eslint |
| 11 | Idiomatic | Use Optional Chaining Over Nested Checks | info | ES2020 |
| 12 | Idiomatic | Use Nullish Coalescing Over Logical OR for Defaults | info | ES2020 |
| 13 | Idiomatic | Use as const for Literal Types | info | TypeScript 3.4+ |
| 14 | Performance | Avoid Unnecessary Re-renders from Object Literals in Props | warn | React-adjacent |
| 15 | Security | Validate External Data at Runtime, Not Just Compile-Time | error | Type erasure |
| 16 | Anti-pattern | Async Function Without Try-Catch or .catch() | warn | Common AI mistake |
| 17 | Anti-pattern | Using delete Operator on Object Properties | warn | V8 deopt |
| 18 | Best Practice | Use Discriminated Unions Over Optional Fields | info | TypeScript patterns |

**Acceptance Criteria**:
- AC-C01-2.1: File exists at `claude/skills/code-quality/references/typescript-anti-patterns.md`
- AC-C01-2.2: Contains at least 15 entries
- AC-C01-2.3: Every entry follows Spec 00 Contract 1 format
- AC-C01-2.4: Code examples use `typescript` as the code fence language
- AC-C01-2.5: BAD/GOOD comments use `// BAD` and `// GOOD` (JS-style)

### Step 3: Create Rust Anti-Patterns Pack

Create `claude/skills/code-quality/references/rust-anti-patterns.md`.

Content informed by: rust-unofficial/patterns, Clippy lints, Rust API Guidelines, pretzelhammer's lifetime blog.

**Required entries** (minimum 15, target 18-20):

| # | Category | Rule Name | Severity | Source Inspiration |
|---|----------|-----------|----------|-------------------|
| 1 | Anti-pattern | Unnecessary clone() | warn | Clippy redundant_clone |
| 2 | Anti-pattern | unwrap() in Production Code | error | Clippy unwrap_used |
| 3 | Anti-pattern | Using unsafe to Fight the Borrow Checker | error | Common AI mistake |
| 4 | Anti-pattern | Manual Loop Instead of Iterator Chain | warn | Clippy manual_map |
| 5 | Anti-pattern | Premature Lifetime Annotations | warn | Common AI mistake |
| 6 | Anti-pattern | String Parameters Instead of &str | warn | Rust API Guidelines |
| 7 | Anti-pattern | Missing Error Context in ? Chains | warn | anyhow/thiserror patterns |
| 8 | Best Practice | Use impl Trait in Argument Position | info | Rust API Guidelines |
| 9 | Best Practice | Derive Common Traits | info | Clippy missing_trait_methods |
| 10 | Best Practice | Use Cow for Flexible Ownership | info | rust-unofficial/patterns |
| 11 | Idiomatic | Use if let for Single-Pattern Matching | info | Clippy single_match |
| 12 | Idiomatic | Use Entry API for HashMap Insert-or-Update | info | std::collections docs |
| 13 | Idiomatic | Use ? Operator Over match on Result | info | Rust 1.13+ |
| 14 | Performance | Avoid Allocation in Hot Loops | warn | Performance patterns |
| 15 | Security | Validate Array Indices Before Access | error | CWE-125 |
| 16 | Anti-pattern | Ignoring Clippy Warnings Without Justification | warn | Project convention |
| 17 | Anti-pattern | Box<dyn Error> Instead of Custom Error Type | warn | thiserror pattern |
| 18 | Idiomatic | Use Default Trait Implementation | info | std::default::Default |

**Acceptance Criteria**:
- AC-C01-3.1: File exists at `claude/skills/code-quality/references/rust-anti-patterns.md`
- AC-C01-3.2: Contains at least 15 entries
- AC-C01-3.3: Every entry follows Spec 00 Contract 1 format
- AC-C01-3.4: Code examples use `rust` as the code fence language
- AC-C01-3.5: BAD/GOOD comments use `// BAD` and `// GOOD`
- AC-C01-3.6: Entries reflect AI-specific mistakes (research found Rust AI code has 1.7x more issues)

---

## Interface Contracts

### Exposes

- **3 language pack files**: Discovered by `code-quality.md` via `stack.language` from `harness.yaml`
- **Entry format**: All entries follow Spec 00 Contract 1, consumable by review and implementation agents

### Consumes

- **Spec 00 Contract 1**: Entry format standard (severity + category + BAD/GOOD)
- **Spec C04**: Language pack discovery directive in `code-quality.md` (already exists, just needs files)
- **Spec 00 Contract 4**: File placement at `claude/skills/code-quality/references/<language>-anti-patterns.md`

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/skills/code-quality/references/python-anti-patterns.md` | Python pack (~200-300 lines) |
| Create | `claude/skills/code-quality/references/typescript-anti-patterns.md` | TypeScript pack (~200-300 lines) |
| Create | `claude/skills/code-quality/references/rust-anti-patterns.md` | Rust pack (~200-300 lines) |

**Total**: 3 new files, 0 modified files

---

## Testing Strategy

1. **Format compliance**: For each pack file, verify every entry has all 7 required fields per Spec 00 Contract 1. Specifically:
   - Each H2 heading follows `## [Category]: [Rule Name]` format
   - A `**Severity**:` line follows each heading
   - A `**Why**:` section exists
   - BAD and GOOD code blocks exist with correct comment markers

2. **Category validation**: Extract all category values and verify each is one of: Anti-pattern, Best Practice, Idiomatic, Performance, Security

3. **Severity validation**: Extract all severity values and verify each is one of: error, warn, info

4. **Code fence validation**: Verify code fences use the correct language identifier (`python`, `typescript`, `rust`)

5. **Discovery integration**: Set `stack.language: python` in a test harness.yaml, read `code-quality.md`, and verify the language directive would load `python-anti-patterns.md`

6. **No universal rule duplication**: Compare entry titles against `code-quality.md` universal rules to ensure no overlap (language packs should be language-specific, not generic)
