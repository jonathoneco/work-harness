# Architecture: W4 Skills Pipeline

**Task**: skills-pipeline | **Tier**: 3 | **Epic**: work-harness-alc
**Created**: 2026-03-24 | **Revised**: 2026-03-24

---

## Problem Statement

The work harness has a solid foundation of 42 skill+command files (~6400 lines) but the skill layer has not kept pace with the workflow machinery built in W1-W3. The gaps are threefold:

1. **Language packs are thin and Go-only.** Only one anti-pattern pack (Go, 215 lines) exists. The vision is a research-informed **library** of language packs covering not just anti-patterns but good practices and idiomatic recommendations per language. Python, TypeScript, and Rust are the baseline -- the architecture must support an extensible library that grows over time, informed by community research, external sources, and proven material (analogous to how agency-agents are pulled in from an external repo).

2. **Missing commands for documented work items.** Several daily workflows have no command or skill support: dev status updates, work decomposition (dump), active workflow-meta entry point, and full PR lifecycle handling. These are friction multiplied across every session.

3. **No skill lifecycle management.** Skills cannot evolve with projects. There is no metadata on any of the 23 existing skills (stack applicability, version, last review date), no staleness detection, and no update command. This is tech debt that compounds as the skill library grows.

**Why now**: W1-W3 built the core workflow machinery. W4 fills the skill layer that makes that machinery productive across diverse projects and language stacks.

---

## Goals

1. Establish a **language pack library** architecture that supports anti-patterns, good practices, and idiomatic recommendations per language -- informed by research into community usage, external sources, and existing libraries
2. Ship initial packs for Python, TypeScript, and Rust as the baseline library entries
3. Create `/workflow-meta` command as an active entry point with pre-seeded context
4. Create `/work-dump` command to decompose work into scoped workflows
5. Create `/dev-update` command+skill to generate status updates from workflow artifacts
6. Make `/pr-prep` state-driven -- infer the right action from PR state rather than requiring explicit flags
7. Enrich thin skills (AMA, codex-review, context-docs) to production quality
8. Document agency-agents curation per stack and add harness-doctor validation
9. Add proactive skill updating: metadata on **all** 23 existing skills + new ones, staleness detection hook, `/work-skill-update` command

**Non-goals**:

- Multi-language schema v2 (`languages: []` array) -- deferred; `review_routing` by file pattern is the workaround
- Deep Notion exploration -- blocked on OAuth configuration
- Replacing or rewriting existing working commands -- only extending or enriching

---

## Design Decisions

### DD-1: Language and framework packs written from scratch, informed by research

**Decision**: All packs (language and framework) are written from scratch, informed by the per-language/framework research in `05-language-pack-formats.md`. Content is curated from authoritative permissively-licensed sources (PEP 8, Clippy, typescript-eslint, etc.) with emphasis on what AI coding assistants specifically get wrong. External vendor libraries (awesome-rules, etc.) evaluated and rejected as primary dependencies — too young, not AI-specific enough.

**Rationale**: Our research already identified 15+ high-impact patterns per language from authoritative sources. External rule libraries are general coding guidance, not AI-specific. The value of our packs is in curating what matters most for LLM-generated code: mutable default args, `any` abuse, unnecessary `.clone()`, etc. Writing from scratch with research backing produces higher-quality, more focused packs than vendoring generic rules.

**Mechanism**:
1. **Language packs**: `references/<language>-<category>.md` discovered via `stack.language` from `harness.yaml` (existing file-presence discovery)
2. **Framework packs**: `references/<framework>-<category>.md` discovered via `stack.framework` from `harness.yaml` (new discovery directive in `code-quality.md`, same pattern as language packs)
3. **Frontend packs**: `references/<frontend>-<category>.md` discovered via `stack.frontend` from `harness.yaml` (same pattern)
4. **Go pack refactoring**: Existing Go pack refactored to match the standard entry format
5. **Future extensibility**: `install.sh --rules` vendoring architecture reserved for future if community rule libraries mature

**Entry format standard** (informed by Clippy + community research):
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

**Research backing** (see `.work/skills-pipeline/research/05-language-pack-formats.md`):
- Python: PEP 8 (public domain), Google Style Guide (CC-By), Ruff rules (MIT), Little Book of Anti-Patterns
- TypeScript: typescript-eslint (MIT), Google TS Style Guide (CC-By), Effective TypeScript patterns
- Rust: rust-unofficial/patterns (MIT/Apache 2.0), Clippy lints (MIT/Apache 2.0), Rust API Guidelines
- Go: Existing pack + community sources
- React/Next.js: Official docs, community patterns, common AI mistakes in JSX/SSR

### DD-2: Dev updates output markdown files, no external integrations

**Decision**: The `/dev-update` command generates a markdown status update file. No Slack, email, or other push integrations.

**Rationale**: External integrations add authentication complexity, failure modes, and maintenance burden. The user can copy-paste the markdown or pipe it to any delivery mechanism. This follows the harness principle of producing artifacts, not side effects.

**Mechanism**: `/dev-update` reads `.work/*/state.json`, recent git log, and checkpoint files to synthesize a structured markdown update. Output goes to stdout or a file at the user's discretion.

### DD-3: `/work-dump` outputs a plan, does not auto-create beads issues

**Decision**: The dump command outputs a decomposition plan as structured markdown. It does not auto-create beads issues.

**Rationale**: Auto-creating issues from an AI decomposition risks polluting the issue tracker with poorly scoped items. The user should review the decomposition, adjust scope, then explicitly create issues. This matches the harness's advisory-not-autonomous pattern (same as context-docs flagging but not auto-updating docs).

**Mechanism**: `/work-dump` accepts a description, runs decomposition logic (extracted from the T3 decompose step), and outputs a markdown document with suggested issues, dependencies, and tags. The user then runs `bd create` for the items they approve.

### DD-4: Skill metadata added to ALL existing skills now

**Decision**: Add `meta` frontmatter to all 23 existing skills immediately, not just new ones. This is a subagent-friendly task that eliminates tech debt upfront.

**Rationale**: Retroactively tagging skills is straightforward with subagents -- each skill file needs 3-4 lines of frontmatter added. Deferring this creates tech debt that compounds as more skills are added: the staleness detection system would only cover a fraction of skills, and the metadata would be inconsistent across the library. Do it once, do it now.

**Mechanism**: New frontmatter fields in skill/command YAML:

```yaml
meta:
  stack: [go, python]       # which stacks this skill applies to ("all" for universal)
  version: 1                # bumped on significant changes
  last_reviewed: 2026-03-24 # ISO date of last content review
```

The `/work-skill-update` command reads these fields and flags skills where `last_reviewed` is older than a configurable threshold (default: 90 days). C12 scope now includes retroactive tagging of all 23 existing skills.

### DD-5: PR handling is state-driven, not flag-driven

**Decision**: `/pr-prep` infers what to do from the current PR state rather than requiring explicit `--monitor`, `--review`, or `--cleanup` flags. The command examines the PR's existence, labels, description, CI status, and change history to determine the appropriate action.

**Rationale**: Explicit flags add cognitive overhead -- the user has to remember which phase they're in and which flag to pass. The PR itself already encodes its lifecycle state. A state-driven approach means the user just runs `/pr-prep` and the command figures out what needs doing.

**Mechanism**: `/pr-prep` state machine:

| PR State | Detected By | Action |
|----------|-------------|--------|
| No PR exists | `gh pr view` returns not found | Run lint/build/fix cycle, create PR |
| PR exists, no description/labels | `gh pr view --json body,labels` | Generate/update description and labels |
| PR exists, CI failing | `gh run list --json status` | Report failures, offer to fix |
| PR exists, CI passing, no reviewers | `gh pr view --json reviewRequests` | Suggest reviewers based on `review_routing` |
| PR exists, changes since description | Compare HEAD with PR description's basis | Update description to reflect new changes |
| PR merged | `gh pr view --json state` | Branch cleanup, `bd close` |

The user can still force a specific action (e.g., `/pr-prep --create-only`) but the default is state inference.

### DD-6: Config injection consolidation deferred -- tracked in futures

**Decision**: The duplicated config injection pattern across commands is noted as a future item, not consolidated in this wave.

**Rationale**: Config injection works correctly everywhere it appears. Consolidation is a refactoring task that does not deliver new user-facing capability. It belongs in a tech-debt wave, not a skills pipeline initiative.

**Mechanism**: N/A -- deferred. Each command continues to read `harness.yaml` independently. Tracked in `.work/skills-pipeline/futures.md` under "Config Injection Consolidation".

---

## Component Map

| ID  | Component                        | Scope  | Files                                                                                          | Dependencies                                     |
| --- | -------------------------------- | ------ | ---------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| C01 | Language packs (Python, TS, Rust)| Medium | `claude/skills/code-quality/references/{python,typescript,rust}-*.md`                          | None                                              |
| C02 | Framework packs (React, Next.js) | Medium | `claude/skills/code-quality/references/{react,nextjs}-*.md`                                    | None                                              |
| C03 | Go pack refactoring              | Small  | `claude/skills/code-quality/references/go-anti-patterns.md`                                    | None                                              |
| C04 | Pack discovery extension         | Small  | `claude/skills/code-quality.md` (add framework + frontend discovery directives)                | None                                              |
| C05 | AMA skill enrichment             | Small  | `claude/commands/ama.md`                                                                       | None                                              |
| C06 | Codex-review skill enrichment    | Small  | `claude/skills/work-harness/codex-review.md`                                                   | None                                              |
| C07 | Context-docs skill enrichment    | Small  | `claude/skills/work-harness/context-docs.md`                                                   | None                                              |
| C08 | `/workflow-meta` command         | Medium | `claude/commands/workflow-meta.md`, `claude/skills/workflow-meta.md`                           | None                                              |
| C09 | `/dev-update` command+skill      | Medium | `claude/commands/dev-update.md`, `claude/skills/work-harness/dev-update.md`                    | None                                              |
| C10 | `/work-dump` command             | Medium | `claude/commands/work-dump.md`                                                                 | None                                              |
| C11 | PR handling: state-driven        | Medium | `claude/commands/pr-prep.md`                                                                   | None                                              |
| C12 | Agency-agents curation docs      | Medium | `claude/skills/work-harness/agency-curation.md`, `claude/commands/harness-doctor.md`           | None                                              |
| C13 | Skill metadata + update command  | Large  | `claude/commands/work-skill-update.md`, `claude/skills/work-harness/skill-lifecycle.md`, all 23 existing skill/command files | None (retroactive tagging is self-contained)     |
| C14 | install.sh updates               | Small  | `install.sh`                                                                                   | C08, C09, C10, C13 (new commands must be registered) |

**Notes on scope changes from v3**:
- C01 reverted to from-scratch language packs. Content curated from research (PEP 8, Clippy, typescript-eslint, etc.) with AI-specific focus.
- C02 is new: framework packs (React, Next.js, and others per `stack.framework`/`stack.frontend`). Same format and discovery pattern as language packs.
- C03 unchanged: Go pack refactoring to standard entry format.
- C04 is new: extend `code-quality.md` discovery to also load packs via `stack.framework` and `stack.frontend` (currently only `stack.language` is supported).
- C05-C07 renumbered from C04-C06 (skill enrichment).
- C08-C11 renumbered from C07-C10 (new commands).
- C12 renumbered from C11 (agency-agents curation).
- C13 renumbered from C12 (skill metadata — unchanged in scope).
- C14 renumbered from C13 (install.sh — now also registers framework discovery).

---

## Data Flow Diagrams

### Pack Discovery (Language + Framework + Frontend)

```
harness.yaml              code-quality.md              pack files
+-------------------+     +----------------------+     +----------------------------------+
| stack:            |     | 1. Read stack.*      |     | python-anti-patterns.md          |
|   language: python| --> |    from harness.yaml |     | python-idiomatic.md              |
|   framework: chi  |     | 2. For each field:   |     | react-anti-patterns.md           |
|   frontend: nextjs|     |    Glob references/  | --> | nextjs-anti-patterns.md          |
+-------------------+     |    {value}-*.md      |     | (file-presence discovery per     |
                          | 3. Include all       |     |  stack.language, stack.framework, |
                          |    matching files     |     |  stack.frontend)                 |
                          +----------------------+     +----------------------------------+
                                                                 |
                                                                 v
                                                        Agent context (review/impl)
```

### Dev Update Generation

```
.work/*/state.json    git log             checkpoint files
+----------------+    +-------------+     +------------------+
| task state,    |    | recent      |     | session progress |
| step status    |    | commits     |     | notes            |
+-------+--------+    +------+------+     +--------+---------+
        |                    |                     |
        +--------------------+---------------------+
                             |
                    /dev-update command
                             |
                             v
                    Markdown status update
                    (stdout or file)
```

### Proactive Skill Updating

```
skill files (frontmatter)     /work-skill-update command
+------------------------+    +---------------------------+
| meta:                  |    | 1. Scan ALL skill files   |
|   stack: [go]          | -> | 2. Parse meta frontmatter |
|   version: 1           |    | 3. Check last_reviewed    |
|   last_reviewed: date  |    |    against threshold      |
+------------------------+    | 4. Report stale skills    |
                              | 5. Suggest updates        |
All 23 existing skills        +---------------------------+
+ all new skills have                    |
this metadata                            v
                              Staleness report + suggestions
```

### PR Lifecycle (State-Driven)

```
/pr-prep
+---------------------------+
| 1. Detect PR state:       |
|    - gh pr view           |
|    - gh run list          |
|    - Compare HEAD vs desc |
+---------------------------+
            |
    +-------+--------+--------+--------+--------+
    v       v        v        v        v        v
No PR    No desc  CI fail  CI pass  Changes  Merged
exists   /labels           no revw  since
    |       |        |        |      desc       |
    v       v        v        v        |        v
Create   Gen desc  Report   Suggest    v     Cleanup
PR       + labels  + offer  reviewers Update  branch
                   fix               desc    + bd close
```

### Work Dump Flow

```
User description          /work-dump command              Output
+------------------+      +-------------------------+     +------------------+
| "Build auth      |      | 1. Parse description    |     | ## Decomposition |
|  system with     | -->  | 2. Identify domains     | --> | - [Auth] Service |
|  OAuth + RBAC"   |      | 3. Apply decompose      |     | - [API] Endpoints|
+------------------+      |    heuristics            |     | - [UX] Login flow|
                          | 4. Suggest dependencies  |     | Dependencies:    |
                          | 5. Format markdown       |     |   API -> Service |
                          +-------------------------+     +------------------+
```

---

## Phased Implementation

### Phase 1: Skill Metadata + Enrichment + Discovery (C13, C04, C05, C06, C07)

**Rationale**: C13 (retroactive metadata on all skills) is foundational -- it establishes the metadata schema that all subsequent work references. C04 (pack discovery extension) is a small change to `code-quality.md` that enables framework/frontend packs in Phase 2. Skill enrichment (C05-C07) is small and independent, fits naturally alongside. Parallel execution: C13 retroactive tagging can run concurrently with C04-C07.

- C13: Skill metadata schema + retroactive tagging of all 23 skills + `/work-skill-update` command
- C04: Pack discovery extension (add framework + frontend directives to `code-quality.md`)
- C05: AMA enrichment
- C06: Codex-review enrichment
- C07: Context-docs enrichment

### Phase 2: Language + Framework Packs (C01, C02, C03)

**Rationale**: All content packs can be written in parallel — language and framework packs are independent of each other. C03 (Go refactoring) aligns the existing pack with the new standard format. Research is already complete (see `05-language-pack-formats.md`). Each pack is curated from authoritative sources with AI-specific focus.

- C01: Language packs (Python, TypeScript, Rust) — from scratch, research-informed
- C02: Framework packs (React, Next.js, others per project needs) — from scratch
- C03: Go pack refactoring to standard entry format

### Phase 3: New Commands (C08, C09, C10, C11)

**Rationale**: Medium complexity, each adds a new capability. Independent of each other -- can be implemented in parallel. All follow established command patterns. C11 (PR handling) is a revision of an existing command.

- C08: `/workflow-meta` command
- C09: `/dev-update` command+skill
- C10: `/work-dump` command
- C11: PR handling state-driven refactor

### Phase 4: Integration + Registration (C12, C14)

**Rationale**: C12 (agency-agents curation) benefits from the commands and packs existing so curation docs can reference them. C14 (install.sh) must come last since it registers all new commands from Phase 3.

- C12: Agency-agents curation docs + harness-doctor validation
- C14: install.sh updates

---

## Scope Exclusions

1. **Multi-language schema v2** -- `stack.language` remains singular. The `review_routing` by file pattern workaround suffices. Full `languages: []` array support is a separate initiative.
2. **Deep Notion exploration** -- Blocked on OAuth configuration. Not a code problem.
3. **Automated skill testing** -- No test framework for markdown-based skills exists. Building one is a separate initiative.
4. **Skill versioning with migrations** -- The `meta.version` field is informational only. No automated migration between skill versions.
5. **External pack vendoring** -- External rule libraries (awesome-rules, claude-rules) evaluated and rejected as primary dependencies (too young, not AI-specific). Vendoring architecture (`install.sh --rules`) reserved as future extensibility if community libraries mature.

---

## Deferred to Spec

1. **Language pack content per language** -- Which anti-patterns, practices, and idioms to include for Python, TypeScript, Rust. Entry count and depth per pack. Research note `05-language-pack-formats.md` provides source material. (Spec C01)
2. **Framework pack content** -- Which frameworks to cover initially (React, Next.js, others?), what anti-patterns and practices per framework, how framework packs interact with language packs (Spec C02)
3. **Go pack refactoring scope** -- How much of the existing Go pack to preserve vs. rewrite to standard format (Spec C03)
4. **Discovery directive specifics** -- Exact glob patterns for `code-quality.md` framework/frontend discovery, fallback behavior when no pack exists (Spec C04)
5. **AMA enrichment specifics** -- What additional answer strategies, example types, and context sources to add (Spec C05)
6. **Context-docs enrichment specifics** -- What examples and edge case handling to add (Spec C07)
7. **`/workflow-meta` pre-seeded context format** -- What context is injected and how the sync validation works (Spec C08)
8. **`/dev-update` artifact reading strategy** -- Exactly which artifacts to read and how to prioritize/summarize them (Spec C09)
9. **`/work-dump` decomposition heuristics** -- How the command identifies domain boundaries and suggests dependency ordering (Spec C10)
10. **PR state detection reliability** -- Edge cases in state inference (draft PRs, force-pushed branches, stale CI runs), fallback behavior when state is ambiguous (Spec C11)
11. **Agency-agents curation per stack** -- Which agents are recommended for which stack configurations (Spec C12)
12. **Skill metadata schema finalization** -- Exact frontmatter fields, validation rules, threshold configuration, override mechanism (Spec C13)
13. **Cross-cutting contracts** -- Entry format standard, frontmatter schema for new skills/commands, config injection pattern, install.sh registration protocol (Spec 00)
