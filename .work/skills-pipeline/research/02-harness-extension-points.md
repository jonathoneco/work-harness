# Research: Harness Extension Points & Project Customization

**Date:** 2026-03-24
**Researcher:** researcher-02
**Task:** W4: Skills Pipeline — Research phase
**Status:** Complete

---

## Questions

1. Where can projects customize harness behavior today?
2. What extension points exist for adding language-specific rules?
3. How would language-specific anti-pattern packs be loaded?
4. What is the design space for agency-agents integration?
5. How could multi-language project support work?
6. What validation gaps exist in the current extension system?
7. How do projects configure review routing and agent selection?

---

## Findings

### 1. Current Extension Points in Harness

The harness provides customization at **four layers**, from highest-level config to code-driven selection:

#### **Layer 1: Project-Level Configuration (`.claude/harness.yaml`)**

**Location:** `.claude/harness.yaml` (project-local, checked into git)

**Customizable fields:**
```yaml
project:
  name: string
  description: string

stack:
  language: enum [go, python, typescript, rust, other]
  framework: string | null
  database: string | null

build:
  test: command
  build: command
  lint: command
  format: command

review_routing:
  - patterns: [glob patterns]
    agents: [agent names]
    exclude: [glob patterns]

anti_patterns: []  # Unused, reserved for project-specific patterns
docs:
  managed: []      # Unused, reserved for doc management
```

**Extension mechanism:** Configuration-driven. harness.yaml drives:
- Language pack selection (via `stack.language`)
- Build command routing (via `build.*`)
- Agent selection (via `review_routing`)
- File extension tagging (via auto-derived `extensions` field)

#### **Layer 2: Skill-Level Discovery (File Presence Pattern)**

**Language-specific anti-pattern packs:**

Location: `claude/skills/code-quality/references/<language>-anti-patterns.md`

**Discovery:** File-presence driven. The code-quality.md skill contains:
```
Read `references/<language>-anti-patterns.md` where `<language>` is `stack.language`
from `.claude/harness.yaml`. If no `harness.yaml` exists or `stack.language` is `other`,
skip this section.
```

**Implication:** No registration required. Simply adding a new file `typescript-anti-patterns.md` immediately makes it discoverable by all agents that inherit the code-quality skill.

**Current state:**
- `go-anti-patterns.md` exists (~250 lines, well-developed)
- `python-anti-patterns.md`, `typescript-anti-patterns.md`, `rust-anti-patterns.md` do not yet exist
- No versioning system; assumes all packs track main

#### **Layer 3: Agent-Level Customization (`.claude/agents/`)**

**Agent definition:** Projects can create custom agents at `.claude/agents/<name>.md`

**Integration with harness:**
- `review_routing` references agent names directly
- Agent names can come from:
  - Harness built-ins (code-reviewer, security-reviewer, devops-automator)
  - Agency-agents library (160+ agents, installed separately)
  - Project-specific custom agents

**No validation:** harness-doctor does NOT currently check if agents referenced in `review_routing` actually exist. This is a gap.

#### **Layer 4: Runtime Config Injection (Skill Prompts)**

**Pattern:** Commands with "config injection" read `harness.yaml` at runtime and include stack context in generated prompts.

**Examples from commands:**
- `work-feature.md`: "If `.claude/harness.yaml` exists, append the stack context block"
- `pr-prep.md`: "Read build commands from `.claude/harness.yaml` if it exists"
- `work-review.md`: "If `review_routing` is configured in `.claude/harness.yaml`, use the routing table to select agents"

**Implication:** Commands know how to read and apply harness config, but the reading logic is duplicated across multiple command files.

---

### 2. Language-Specific Anti-Pattern Pack Design

**Current architecture:**

```
claude/
  skills/
    code-quality/
      code-quality.md (main skill + 8 universal rules)
      references/
        go-anti-patterns.md (language-specific, ~250 lines)
        security-antipatterns.md (universal, ~400 lines)
        ai-config-linting.md (universal, ~200 lines)
        parallel-review.md (pattern, ~80 lines)
```

**How packs work:**

1. **Skill activation:** Agent inherits code-quality skill
2. **Language detection:** Skill reads `stack.language` from harness.yaml
3. **Pack lookup:** Skill instructs agent to read `references/<language>-anti-patterns.md`
4. **Pack content:** Each pack contains 8-12 anti-pattern sections (pattern title → risk explanation → BAD example → GOOD example)

**Pack organization by domain:**
- **Security & degradation:** Open error handling, fabricated data, failed validation skips
- **Error handling:** Swallowed errors, discarded returns, missing nil-checks
- **Data integrity:** Null pointer dereference, incomplete analysis, divergent interface copies
- **Maintenance:** Shim layers, backward-compatibility hacks, unused abstractions

**Extension mechanism: File-presence discovery**

Per code-quality.md:
> "Adding a new language pack requires only creating one file at `references/<language>-anti-patterns.md` — no changes to this file or any other file are needed."

**Design implications:**
- Zero overhead to add new language support
- No config registration, no manifest, no version tagging
- Discovery is implicit (if file exists, load it)
- **Gap:** No way to express pack dependencies (e.g., "python-anti-patterns assumes security-antipatterns v2+")

---

### 3. Agency-Agents Integration Design

**Agency-agents library:** 160+ domain-specific agents at `/home/jonco/src/agency-agents/`

**Current integration:**

1. **Install mechanism:** Separate installation (not automatic)
   - Users run `scripts/install.sh --tool claude-code`
   - Copies agents to `~/.claude/agents/`

2. **Integration point:** `review_routing` in harness.yaml
   - Agent names map directly to `.claude/agents/<name>.md` files
   - Example:
   ```yaml
   review_routing:
     - patterns: ["*.go"]
       agents: [code-reviewer, security-reviewer, database-optimizer]
   ```

3. **Agent categories:**
   - **Harness-owned workflow agents** (tightly coupled to state machine):
     - work-research, work-review, work-implement, work-spec
   - **Domain-owned review/specialist agents** (composable):
     - code-reviewer, security-reviewer, devops-automator, database-optimizer, etc.

4. **Curation model (proposed but not implemented):**
   - harness-init could suggest a "stack-appropriate agent roster"
   - Example: For Go+chi+postgresql, suggest [code-reviewer, security-reviewer, database-optimizer, devops-automator]
   - User chooses to install agency-agents, then harness auto-populates review_routing defaults

**Design space:**
- **Curation:** Document recommended agent sets per (language, framework, database) tuple
- **Discovery:** harness-doctor could warn if review_routing references agents that don't exist
- **Auto-seeding:** harness-init could generate default review_routing with agency agent references
- **Versioning:** Agency-agents library could version agents, harness could pin to versions

---

### 4. Multi-Language Project Support

**Current state:** `stack.language` is singular. Only one primary language can be declared.

**Enablers already in place:**

1. **Pattern-based routing is language-agnostic:**
   ```yaml
   review_routing:
     - patterns: ["*.go"]
       agents: [code-reviewer]
     - patterns: ["*.ts", "*.tsx"]
       agents: [code-reviewer]
   ```
   Could route Go and TypeScript files to the same or different agents today.

2. **Build commands can invoke multiple tools:**
   ```yaml
   build:
     test: "make test"        # Could run both `go test` and `npm test`
     lint: "make lint"        # Could run both golangci-lint and eslint
   ```

3. **Extensions array is already multi-value:**
   - Currently auto-derived: `extensions: [".go", ".sql"]` for Go projects
   - Could be expanded: `extensions: [".go", ".ts", ".tsx", ".sql"]`

**Path to full multi-language support:**

Would require schema v2:
1. Add `languages: [language, ...]` array (with first element as "primary")
2. Add per-language build commands:
   ```yaml
   build:
     go:
       test: "go test ./..."
       lint: "golangci-lint run"
     typescript:
       test: "npm test"
       lint: "eslint ."
   ```
3. Update code-quality.md to load union of language packs
4. Update extensions array to be union of all language extensions
5. Update harness-init to support "primary + additional languages" input

**Challenge:** Conflicting build semantics (go test vs npm test are incompatible). Would need explicit per-language build command sets, not a unified approach.

---

### 5. Existing Extension Mechanisms Summary

**Pattern-based discovery:**
- Language packs: File-presence pattern (if `go-anti-patterns.md` exists, it's loaded)
- Skills: Referenced in commands via prompt text (no manifest)

**Configuration-driven:**
- `harness.yaml stack` field: Drives language detection → skill loading
- `review_routing` array: Maps file patterns to agents
- `extensions` array: Declares in-scope file extensions
- `anti_patterns` field: Reserved for project-specific rules (unused)
- `docs.managed` field: Reserved for doc management (unused)

**No explicit plugin system:**
- No runtime pack loader (e.g., no "load packs from directory X")
- No registration manifest (e.g., no packs.yaml listing available packs)
- No versioning or version negotiation
- No dependency tracking between packs
- No validation of agent availability at harness-doctor time

---

### 6. Project Customization Patterns

**Pattern 1: Stack Declaration (harness-init)**
```
User runs /harness-init → Interactive prompts → harness.yaml generated
→ Build commands templated → review_routing auto-generated
```

**Pattern 2: Skill Propagation (Config Injection)**
```
Command reads harness.yaml → Generates prompt with stack context
→ Spawned agents inherit language-specific skills
```

**Pattern 3: Agent Routing (review_routing)**
```
Changed files matched against review_routing patterns
→ Agents selected and spawned in parallel
→ Findings collected and reported
```

**Pattern 4: Language Pack Loading (Skill Discovery)**
```
Agent inherits code-quality skill → Skill reads stack.language from harness.yaml
→ Skill loads references/<language>-anti-patterns.md if it exists
```

**Pattern 5: Custom Agents (Local Definition)**
```
Project creates .claude/agents/my-agent.md → Agents can be referenced in review_routing
→ Projects can mix harness agents, agency agents, and custom agents
```

---

## Implications

### For Language-Specific Anti-Pattern Packs

**Short-term (v1, no schema changes):**
- Create `python-anti-patterns.md`, `typescript-anti-patterns.md`, `rust-anti-patterns.md`
- No code changes needed; file-presence discovery works immediately
- Low lift, high value

**Medium-term considerations:**
- Could add explicit pack metadata (version, dependencies) as frontmatter
- Could add pack registry in harness.yaml for discoverability
- Could validate pack availability at harness-doctor time

### For Agency-Agents Integration

**Short-term blockers:** None technical; organizational
- harness-init already handles review_routing generation
- review_routing already supports arbitrary agent names
- Users can manually edit review_routing today

**Deeper integration enablers:**
1. **Curation:** Document "standard rosters" per stack (e.g., "Go+PostgreSQL stack includes code-reviewer, security-reviewer, database-optimizer")
2. **Auto-seeding:** harness-init could detect agency-agents installation and auto-populate review_routing defaults
3. **Validation:** harness-doctor could check if agents in review_routing exist
4. **Versioning:** Could pin agency-agents to specific versions per project

### For Multi-Language Support

**Current workaround:** Extend review_routing to route multiple language file types:
```yaml
review_routing:
  - patterns: ["*.go"]
    agents: [code-reviewer]
  - patterns: ["*.ts", "*.tsx"]
    agents: [code-reviewer]
  - patterns: ["*.sql"]
    agents: [database-optimizer]
```

**Medium-term path:** Schema v2 with `languages: [...]` array and per-language build commands.

**Key challenge:** Build command conflict resolution. How does make/npm/cargo/go test coexist in one config?

### For Project Customization

**Gap: Config validation**
- harness-doctor validates harness.yaml structure, but does NOT:
  - Check if agents in review_routing exist
  - Check if language packs exist for declared language
  - Check if build commands are executable
  - Check for orphaned anti_patterns or docs.managed entries

**Gap: Config discoverability**
- No way to ask "what customization points are available?"
- No way to ask "what language packs are available?"
- No way to list "what anti-pattern packs would apply to my stack?"

---

## Open Questions

1. **Pack versioning & dependencies:**
   - Should language packs be versioned independently, or always track main?
   - How should pack dependencies be expressed? (e.g., "python-anti-patterns requires security-antipatterns ≥ v2")
   - Should packs be pinnable per project?

2. **Agency-agents curation:**
   - Should harness maintain a recommended roster per (language, framework, database) tuple?
   - If curated, who maintains the roster and how often is it updated?
   - How should users discover available agents and their purposes?

3. **Multi-language build commands:**
   - For Go + TypeScript, how should `build.test` be specified?
     - Unified Makefile approach: `test: "make test"` (assumes Makefile handles both)
     - Per-language approach: `languages: {go: {test: "go test"}, typescript: {test: "npm test"}}`
     - Build matrix: `build_matrix: [{language: go, test: "go test"}, {language: typescript, test: "npm test"}]`

4. **Extensions field evolution:**
   - Should `extensions` always be auto-derived, or should it be user-editable?
   - Should users be able to add non-language extensions (e.g., "I want to lint .proto files too")?

5. **Project-specific anti-patterns:**
   - The `anti_patterns: []` field is empty. Should it support:
     - Inline rules in harness.yaml?
     - Reference to `.claude/rules/project-anti-patterns.md`?
     - Integration with project-specific agent instructions?

6. **Config discovery at runtime:**
   - Should harness.yaml be read earlier (e.g., at command invocation) to pre-load and validate all resources?
   - Currently, config injection is duplicated across multiple command files. Should there be a shared config reader?

7. **Pack loading strategy for teams:**
   - Should packs be:
     - Embedded in the harness repo (current)?
     - Fetched from a remote registry?
     - Distributed as `.claude/packs/` submodules?

8. **Skill manifest in harness.yaml:**
   - Should harness.yaml have an explicit skill routing table?
   ```yaml
   skill_routing:
     - steps: [plan, spec]
       skills: [code-quality, work-harness]
     - steps: [implement]
       skills: [code-quality, work-harness]
   ```
   This would reduce duplicated config injection logic across commands.

9. **Config validation scope:**
   - Should harness-doctor validate:
     - Agent existence (referenced in review_routing)?
     - Language pack existence?
     - Build command executability?
     - File extension conflicts (same extension routed to multiple agents)?

10. **Backwards compatibility:**
    - If harness.yaml schema evolves (e.g., language → languages), how should existing single-language projects migrate?
    - Should there be a migration tool or auto-upgrade step?

---

## Summary

**Harness extension points** exist at multiple layers:

1. **Config layer** (`.claude/harness.yaml`): Language, framework, database, build commands, agent routing
2. **Skill layer** (file-presence discovery): Language-specific anti-pattern packs loaded automatically
3. **Agent layer** (`.claude/agents/`): Custom agents can be created and routed via review_routing
4. **Runtime layer** (config injection): Commands inject stack context into spawned agent prompts

**Key strengths:**
- File-presence discovery for language packs is zero-friction
- Review routing is already pattern-agnostic (supports multi-language files)
- Agency-agents can be integrated today via review_routing
- Config-driven approach means commands don't need to know about stack details

**Key gaps:**
- No validation of agent existence or pack availability
- No explicit pack versioning or dependency tracking
- No multi-language stack support (requires schema v2)
- Config injection logic duplicated across commands
- No discovery mechanism to list available customization options

**Immediate opportunities:**
- Add python, typescript, rust anti-pattern packs (file-presence discovery works now)
- Document agency-agents curation per stack
- Add harness-doctor checks for agent existence and pack availability
- Consolidate config injection logic into shared utilities

**Medium-term design work:**
- Schema v2 for multi-language support
- Config-driven skill routing to reduce prompt-level duplication
- Pack registry for discoverability and versioning
