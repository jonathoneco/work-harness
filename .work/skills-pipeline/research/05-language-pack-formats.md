# Language Pack Formats & External Sources Research

**Date**: 2026-03-24
**Context**: Supplementary research for W4 plan step, triggered by user feedback on DD-1

## Research Questions

1. What format works best for AI-consumed language packs?
2. What external libraries exist that we could pull in rather than maintain?
3. What does each language's ecosystem offer (Python, TypeScript, Rust)?
4. How does the agency-agents integration pattern work for replication?

---

## Findings

### 1. Optimal Pack Format

Cross-referencing Clippy's lint format, Cursor .mdc rules, and Claude Code rules conventions:

**Recommended entry structure:**
```markdown
## [Category]: [Rule Name]
**Severity**: error | warn | info

[1-2 sentence description]

**Why**: [Concise rationale]

```language
// BAD
...
```

```language
// GOOD
...
```
```

**Categories** (5 fixed): Anti-pattern, Best Practice, Idiomatic, Performance, Security

**Organization**: Single file per language until exceeding ~400 entries. Categories as H2 sections.

**Key insight**: Clippy's "Why is this bad?" + "Use instead" format is the most effective for AI consumption. Always include BAD/GOOD code pairs — AI responds to examples far better than abstract rules.

### 2. External Libraries (The "Buy" Option)

#### Tier 1: High Viability

**continuedev/awesome-rules** (CC0 — public domain)
- 60+ production-ready rules across 8 languages (Go, Python, Rust, TypeScript, Erlang, Lua, Ruby, Zig)
- Amplified.dev standard format (YAML frontmatter + markdown)
- Includes `rules-cli` for format conversion (`rules render --to claude`)
- 144 stars, actively maintained

**lifedever/claude-rules** (MIT)
- 10 languages: TS, JS, Python, Java, Go, Rust, Swift, Kotlin, HTML, CSS
- Base + Language + Framework hierarchical layering
- Works with Claude Code, Cursor, Copilot
- 138 stars, maintained (Jan 2026)
- Auto-detection of tech stack

#### Tier 2: Supplementary

**PatrickJS/awesome-cursorrules** — 38,700+ stars, 879+ rules, Cursor-focused
**sanjeed5/awesome-cursor-rules-mdc** — 3,300+ stars, auto-generated via LLM + semantic search

### 3. Agency-Agents Integration Pattern (Existing Precedent)

The harness already pulls in an external rule library via `install.sh`:

```bash
AGENCY_REPO="https://github.com/msitarzewski/agency-agents.git"
AGENCY_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/work-harness/agency-agents"

harness_install_agents() {
  # Clone or update from git → copy .md files to ~/.claude/agents/
}
./install.sh --agents  # Optional flag
```

**Pattern**: Optional install, git-based, file-copy model (not submodule), local cache, auto-detection via harness-doctor.

This pattern can be replicated exactly for language packs: `./install.sh --rules`

### 4. Per-Language Research

#### Python
- **Gold standard**: The Little Book of Python Anti-Patterns (40+ patterns, CC-By-NC-SA)
- **Key sources**: PEP 8 (public domain), Google Style Guide (CC-By), Ruff rules (MIT), Hitchhiker's Guide
- **Top 15 AI mistakes**: mutable default args, bare except, unawaited async, string concat in loops, silent exception handling, late binding closures, circular imports, inconsistent return types
- **Linting**: Ruff (900+ rules, replacing Flake8+Pylint), Mypy for type checking. Focus on F + B + S categories.

#### TypeScript
- **Gold standard**: typescript-eslint rules (100+ rules, MIT) + Effective TypeScript book (83 items)
- **Key sources**: Google TS Style Guide (CC-By), Biome (450+ rules), official Do's and Don'ts
- **Top 15 AI mistakes**: `any` abuse, unawaited promises, non-null assertions after `?.`, truthiness filtering valid values, improper type narrowing with `typeof null`, missing exhaustive checking
- **Linting**: typescript-eslint strict-type-checked config + Biome. Focus on type safety rules.

#### Rust
- **Gold standard**: rust-unofficial/patterns repo (MIT/Apache 2.0) + Clippy (500+ lints, MIT/Apache 2.0)
- **Key sources**: Rust API Guidelines, Rust by Example, pretzelhammer's lifetime blog
- **Top 15 AI mistakes**: unnecessary `.clone()`, `.unwrap()` abuse, fighting borrow checker with `unsafe`, manual loops instead of iterators, premature lifetime annotations, String params instead of &str, missing error context
- **Linting**: Clippy categories (Correctness, Complexity, Perf, Style). All permissively licensed.
- **AI generates 1.7x more issues than human code** in Rust specifically (CodeRabbit research)

#### Go (Existing Pack — Baseline)
- 216 lines, 11 rules, BAD/GOOD paired examples
- No severity markers, no categories, no metadata
- Well-structured but ad-hoc — works as starting point but not a template to lock to
- Discovery: `references/<language>-anti-patterns.md` via `stack.language`

### 5. Licensing Summary

| Source | License | AI Use |
|--------|---------|--------|
| continuedev/awesome-rules | CC0 (public domain) | Unrestricted |
| lifedever/claude-rules | MIT | Yes, with attribution |
| PEP 8 | Public domain | Unrestricted |
| Google Style Guides | CC-By 3.0 | Yes, with attribution |
| Ruff, typescript-eslint | MIT | Yes |
| rust-unofficial/patterns | MIT/Apache 2.0 | Yes |
| Clippy | MIT/Apache 2.0 | Yes |
| Little Book of Python Anti-Patterns | CC-By-NC-SA 4.0 | Non-commercial OK |

---

## Implications

### Recommended Approach: Hybrid (Vendor + Extend)

**Phase 1: Vendor external packs** via `install.sh --rules`
- Pull from continuedev/awesome-rules (CC0) and/or lifedever/claude-rules (MIT)
- Follow the agency-agents pattern: git clone → filter → copy to `~/.claude/rules/` or `claude/skills/code-quality/references/`
- Format conversion via `rules-cli` if needed

**Phase 2: Extend with harness-specific rules**
- AI-specific anti-patterns not covered by external packs (the "what LLMs get wrong" layer)
- Harness workflow integration (how rules interact with code-quality skill)
- Go pack refactoring to match the new standard format

**Phase 3: Maintain curated subset**
- Not all external rules are equally valuable — curate which rules to include per language
- Harness-specific overrides or additions stored separately from vendored content

### Impact on Architecture

This changes C01-C03 significantly:
- **Scope reduction**: Much of the content is available externally, not written from scratch
- **New component**: install.sh `--rules` flag + rule vendoring logic
- **Format decision**: Adopt amplified.dev standard (YAML frontmatter + markdown) for consistency with external sources
- **Go pack**: Refactor to match new format standard

### Key Design Decision

The harness should **not maintain language pack content long-term**. Instead:
1. Vendor from external CC0/MIT sources (like agency-agents)
2. Layer harness-specific AI guidance on top
3. Let the community maintain the bulk of language-specific rules

---

## Open Questions

1. Should we vendor from one external source or merge multiple?
2. Where do vendored rules live — `references/` (current) or a new `rules/` directory?
3. Should the Go pack be refactored now or left as-is with new packs using the standard format?
4. How much harness-specific AI guidance do we need on top of external packs?
