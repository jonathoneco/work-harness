# Spec 02: Code Quality Enhancement (C2)

**Component:** C2 | **Phase:** 1 | **Scope:** M | **Priority:** P2

## Overview

The code-quality skill currently has one reference file (`go-anti-patterns.md`) and 8 universal rules. This spec expands the references library with three new files: security anti-patterns curated for LLM context, AI config linting rules for Claude Code and similar tooling config files, and the parallel review pattern that documents how to run 9 concurrent review agents covering different quality dimensions. These additions make the code-quality skill a more comprehensive foundation for both human-driven and agent-driven code review.

C2 is a prerequisite for Codex Integration (C10, Phase 4), which uses the quality schema to inform Codex output structure.

## Scope

**In scope:**
- Create `claude/skills/code-quality/references/security-antipatterns.md` -- curated security anti-patterns for LLM-generated code
- Create `claude/skills/code-quality/references/ai-config-linting.md` -- curated rules for AI tooling config files
- Create `claude/skills/code-quality/references/parallel-review.md` -- the 9-parallel-review-agents pattern
- Update `claude/skills/code-quality/code-quality.md` to reference the parallel review pattern

**Out of scope:**
- Language-specific anti-pattern files beyond the existing `go-anti-patterns.md` (mentioned in architecture as "under `language-specific/`" but deferred -- the existing convention of `references/<language>-anti-patterns.md` is sufficient and already documented in the skill)
- Codex integration with the quality schema (C10, Phase 4)
- Automated review agent spawning from these references (C8/C9, Phase 3)
- Changes to the universal rules in `code-quality.md` (the 8 rules are stable)

## Implementation Steps

### Step 1: Create security-antipatterns.md

Create `claude/skills/code-quality/references/security-antipatterns.md` following the reference doc format from spec 00 section 6.

This file contains security anti-patterns that LLM-generated code commonly introduces. Each entry has a pattern to detect, the risk it creates, and the fix. Organize into categories that match common LLM failure modes rather than traditional security taxonomy (OWASP, CWE) -- the goal is to catch what agents actually produce, not to be a comprehensive security reference.

**Categories and entries:**

**Authentication and Authorization**
- Hardcoded credentials or API keys in source
- Auth bypass via fallback (e.g., if auth fails, proceed as anonymous)
- Token validation skipped in error paths
- Overly permissive CORS configuration
- Missing rate limiting on auth endpoints

**Input Handling**
- SQL injection via string concatenation (especially in dynamic queries)
- Command injection via unsanitized shell arguments
- Path traversal via user-supplied file paths
- Unvalidated redirect URLs
- Missing input length limits

**Secrets and Configuration**
- Secrets logged in plaintext (structured logging fields containing tokens, passwords)
- Secrets in error messages returned to clients
- Default secrets that "work" in development (e.g., `secret: "changeme"`)
- Environment variable fallbacks that degrade security (e.g., `TLS_ENABLED || false`)

**Error Handling (Security Impact)**
- Stack traces or internal paths exposed in API error responses
- Detailed database error messages returned to clients
- Error responses that leak existence of resources (enumeration)
- Catch-all error handlers that swallow security-critical failures

**Cryptography**
- Weak hash algorithms for passwords (MD5, SHA1 without salt)
- Hardcoded initialization vectors or nonces
- Using `math/rand` (or equivalent non-crypto RNG) for security-sensitive values
- Custom cryptography implementations instead of standard libraries

**AC-01**: `security-antipatterns.md exists at claude/skills/code-quality/references/security-antipatterns.md` -- verified by `file-exists`

**AC-02**: `File contains at least 15 entries across 5 categories, each with Pattern, Risk, and Fix fields` -- verified by `structural-review`

**AC-03**: `No placeholder text -- every Fix field contains a concrete alternative, not "fix this" or "use a better approach"` -- verified by `structural-review`

### Step 2: Create ai-config-linting.md

Create `claude/skills/code-quality/references/ai-config-linting.md` following the reference doc format from spec 00 section 6.

This file contains linting rules for AI tooling configuration files: Claude Code settings (`.claude/settings.json`, `CLAUDE.md`), harness config (`.claude/harness.yaml`), agent definitions, MCP server config, and similar. These are files that agents frequently create or modify and where mistakes have outsized impact.

**Categories and entries:**

**Claude Code Settings**
- Invalid hook event names (must be one of: PreToolUse, PostToolUse, PostCompact, etc.)
- Hook commands referencing non-existent scripts
- Duplicate hook entries (same event + matcher + command)
- Permission patterns that are too broad (e.g., allowing all Bash commands)

**CLAUDE.md and Rules**
- Contradictory instructions (e.g., "always use X" in one rule and "never use X" in another)
- References to files or paths that do not exist
- Instructions that reference deprecated tools or approaches
- Overly long rule files that exceed useful context window budget

**Harness Configuration (.claude/harness.yaml)**
- Missing required fields (schema_version, project.name)
- Stack language/framework values that do not match project reality
- Review routing patterns that reference non-existent agent definitions
- Doc manifest paths pointing outside the project root

**Agent Definitions**
- Agent prompts that include absolute paths (should be project-relative)
- Missing skill references for agents that need them
- Agent names that do not match their described expertise
- Overly broad agent scopes (one agent trying to do everything)

**MCP Configuration**
- MCP server entries with invalid command paths
- Missing environment variables required by MCP servers
- Duplicate server names in the MCP config
- Servers configured but never referenced in skills or rules

**AC-04**: `ai-config-linting.md exists at claude/skills/code-quality/references/ai-config-linting.md` -- verified by `file-exists`

**AC-05**: `File contains at least 15 entries across 5 categories, each with Pattern, Risk, and Fix fields` -- verified by `structural-review`

**AC-06**: `Examples reference concrete file names and field names from the Claude Code ecosystem (settings.json, CLAUDE.md, harness.yaml), not generic placeholders` -- verified by `structural-review`

### Step 3: Create parallel-review.md

Create `claude/skills/code-quality/references/parallel-review.md` following the reference doc format from spec 00 section 6.

This file documents the 9-parallel-review-agents pattern: how to decompose a code review into 9 concurrent agents, each covering a different quality dimension. It is a coordination pattern, not a list of anti-patterns. Use a different structure than the Pattern/Risk/Fix format -- this is a procedure reference.

**Content:**

**Overview**: When reviewing a significant diff (50+ changed lines across 3+ files), spawn 9 review agents in parallel rather than one agent doing sequential review. Each agent specializes in one quality dimension, reads the full diff, and produces findings in a structured format. A lead agent collects and deduplicates findings.

**The 9 Review Dimensions:**

| # | Dimension | Focus | Agent Type |
|---|-----------|-------|------------|
| 1 | Correctness | Logic errors, off-by-one, wrong comparisons, missing null checks | Explore |
| 2 | Error Handling | Swallowed errors, missing error paths, bare returns, panic recovery | Explore |
| 3 | Security | Auth bypass, injection, secrets exposure, crypto misuse (see security-antipatterns.md) | Explore |
| 4 | Performance | N+1 queries, unnecessary allocations, missing indexes, blocking in async paths | Explore |
| 5 | API Contract | Breaking changes, missing validation, inconsistent response shapes, undocumented fields | Explore |
| 6 | Test Coverage | Untested code paths, missing edge cases, test quality (not just existence) | Explore |
| 7 | Maintainability | Dead code, unclear naming, excessive coupling, missing abstractions (or excessive ones) | Explore |
| 8 | Concurrency | Race conditions, missing synchronization, deadlock potential, shared mutable state | Explore |
| 9 | Config and Infra | AI config linting rules (see ai-config-linting.md), environment assumptions, deployment concerns | Explore |

**Agent Prompt Template:**

```
You are reviewing a code diff for [DIMENSION] issues only.

Diff: [DIFF_CONTENT or git diff command]
Specs: [RELEVANT_SPEC_PATHS]

Report findings in the standard work-review format:

### [SEVERITY] Title
- **Category**: [DIMENSION]
- **File**: <relative path>
- **Line**: <line number or "file-level">
- **Description**: <detailed explanation>
- **Suggested fix**: <what to change>

Severity levels: critical | important | suggestion

If you find no issues in your dimension, report "No [DIMENSION] issues found."
Do not report issues outside your assigned dimension.
```

**Lead Agent Responsibilities:**
1. Spawn all 9 agents in parallel with the same diff
2. Collect findings from all agents
3. Deduplicate (same file + line + similar finding = one entry)
4. Sort by severity (critical first)
5. Present consolidated findings to the user

**When to Use:**
- Implementation phase gating reviews (Inter-Step Quality Review Protocol, Phase B)
- `/work-review` command
- Any review where thoroughness matters more than speed

**When NOT to Use:**
- Small changes (under 50 lines, 1-2 files) -- a single review agent is sufficient
- Time-critical hotfixes -- use a single focused review instead
- Pure documentation changes -- only dimensions 5 (API contract) and 7 (maintainability) apply

**AC-07**: `parallel-review.md exists at claude/skills/code-quality/references/parallel-review.md` -- verified by `file-exists`

**AC-08**: `File documents all 9 review dimensions with dimension name, focus area, and agent type` -- verified by `structural-review`

**AC-09**: `File includes a concrete agent prompt template with severity levels and finding format` -- verified by `structural-review`

**AC-10**: `File includes "when to use" and "when not to use" guidance with specific thresholds (line count, file count)` -- verified by `structural-review`

### Step 4: Update code-quality.md to reference parallel review

Add a section to `claude/skills/code-quality/code-quality.md` that references the parallel review pattern. This goes after the existing "How to Use" section and before "Language-Specific Anti-Patterns".

**New section:**

```markdown
## Parallel Review

For substantial diffs (50+ lines across 3+ files), use the 9-parallel-review-agents
pattern instead of a single sequential review. Each agent covers one quality dimension
(correctness, error handling, security, performance, API contract, test coverage,
maintainability, concurrency, config/infra). A lead agent spawns all 9 in parallel,
collects findings, deduplicates, and presents a consolidated report.

See `references/parallel-review.md` for the full pattern, agent prompt template,
and when-to-use guidance.
```

Also add the new reference files to the skill's awareness. The code-quality skill uses a convention where language-specific references are auto-discovered by filename. The new references are not language-specific, so add a "References" section at the end of the file:

```markdown
## References
- **Security Anti-Patterns** -- Common security mistakes in LLM-generated code (path: `references/security-antipatterns.md`)
- **AI Config Linting** -- Rules for Claude Code and harness configuration files (path: `references/ai-config-linting.md`)
- **Parallel Review** -- 9-agent concurrent review pattern (path: `references/parallel-review.md`)
```

**AC-11**: `code-quality.md contains a "Parallel Review" section describing the pattern and referencing parallel-review.md` -- verified by `structural-review`

**AC-12**: `code-quality.md contains a "References" section listing all 3 new reference files with paths` -- verified by `structural-review`

## Interface Contracts

### Exposes

| Interface | Consumer | Description |
|-----------|----------|-------------|
| `references/security-antipatterns.md` | Review agents (via `skills: [code-quality]`), Codex Integration (C10) | Security anti-patterns for LLM-generated code |
| `references/ai-config-linting.md` | Review agents, config validation workflows | Linting rules for AI tooling config files |
| `references/parallel-review.md` | Implementation phase gating, `/work-review`, any review workflow | 9-agent parallel review coordination pattern |
| Parallel review dimensions list | C10 Codex Integration | Codex output schema can map to same 9 dimensions |

### Consumes

| Interface | Provider | Description |
|-----------|----------|-------------|
| Reference doc format | Spec 00 section 6 | Markdown format convention for reference files |
| Skill file format | Spec 00 section 4 | Skill file structure convention |
| Existing code-quality skill | `claude/skills/code-quality.md` | Modified to add references |

## Files

| File | Action | Description |
|------|--------|-------------|
| `claude/skills/code-quality/references/security-antipatterns.md` | Create | Curated security anti-patterns for LLM-generated code |
| `claude/skills/code-quality/references/ai-config-linting.md` | Create | Linting rules for AI tooling configuration files |
| `claude/skills/code-quality/references/parallel-review.md` | Create | 9-parallel-review-agents coordination pattern |
| `claude/skills/code-quality/code-quality.md` | Modify | Add Parallel Review section and References section |

## Testing Strategy

| What | Method | Pass Criteria |
|------|--------|---------------|
| security-antipatterns.md | `structural-review` | 15+ entries, 5 categories, Pattern/Risk/Fix format, no placeholders |
| ai-config-linting.md | `structural-review` | 15+ entries, 5 categories, concrete Claude Code file references |
| parallel-review.md | `structural-review` | 9 dimensions, prompt template, when-to-use thresholds |
| code-quality.md changes | `structural-review` | Parallel Review section present, References section lists all 3 files |
| Reference discoverability | `manual-test` | Spawning an agent with `skills: [code-quality]` makes the references available in agent context |
| Cross-reference integrity | `structural-review` | parallel-review.md references security-antipatterns.md and ai-config-linting.md by correct path |
| Existing references | `structural-review` | go-anti-patterns.md is unchanged and still discoverable via the language-specific convention |

## Deferred Questions Resolution

**No deferred questions from the plan apply directly to this spec.** The architecture's Q4 (C10 output schema design) is downstream -- C10 will consume these references but the schema design is a C10 concern. The parallel review dimensions table in `parallel-review.md` provides the structure that C10 can map its output schema to, but that mapping is specified in spec 10, not here.
