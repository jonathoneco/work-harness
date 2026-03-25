# Spec C05: AMA Skill Enrichment

**Component**: C05 — AMA skill enrichment
**Phase**: 1 (Foundation)
**Status**: complete
**Dependencies**: Spec 00 (frontmatter meta block via C13)

---

## Overview and Scope

Enriches `claude/commands/ama.md` from a functional but thin command (64 lines) to production quality by adding answer strategy templates, depth-calibration guidance, and cross-reference patterns.

**What this does**:
- Adds answer strategy templates for common question types
- Adds depth calibration (quick answer vs deep dive)
- Adds cross-reference output patterns (linking to related issues, docs, files)
- Adds handling for "I don't know" scenarios
- Adds `meta` block (handled by C13, referenced here for coordination)

**What this does NOT do**:
- Change the existing answer priority order (context > beads > code exploration)
- Add external integrations
- Change the command's fundamental architecture

---

## Implementation Steps

### Step 1: Add Answer Strategy Templates

After the existing "Response guidelines" section, add a new section with templates for common question types:

```markdown
## Answer Strategies by Question Type

### Architecture Questions
1. Read `harness.yaml` for stack context
2. Check `CLAUDE.md` and `docs/feature/` for documented decisions
3. Search closed beads for architecture-related issues
4. If still unclear, trace the code's module structure
5. Present: stack overview, key abstractions, data flow, design rationale

### "How does X work?" Questions
1. Search beads for issues mentioning X
2. Find the entry point (command, handler, function)
3. Trace the call chain through 2-3 layers maximum
4. Present: entry point → processing → output, with file paths at each step

### "Why was X done this way?" Questions
1. Search closed beads for decision context (most reliable source)
2. Check git log for commits touching the relevant files
3. Look for comments or docs explaining the rationale
4. If no recorded rationale exists, analyze the code and offer a reasoned hypothesis, clearly labeled as inference

### "What's the status of X?" Questions
1. Check `.work/` for active tasks related to X
2. Search open beads issues for X
3. Check `docs/feature/` for completed feature summaries
4. Present: current state, any open work, what's been completed
```

**Acceptance Criteria**:
- AC-C05-1.1: Four answer strategy templates are present (architecture, how, why, status)
- AC-C05-1.2: Each template has a numbered priority order for information sources
- AC-C05-1.3: Templates reference concrete sources (beads, git log, docs/feature, harness.yaml)

### Step 2: Add Depth Calibration

Add a section on matching answer depth to question complexity:

```markdown
## Depth Calibration

Match your answer depth to the question:

| Signal | Depth | Approach |
|--------|-------|----------|
| Single word or yes/no question | Quick | Check 1-2 sources, answer in 2-3 sentences |
| "How does X work?" | Medium | Trace 2-3 layers, include file paths, 1-2 paragraphs |
| "Explain the architecture of..." | Deep | Multi-source research, spawn Explore agents, structured response with sections |
| "Compare X and Y" or "What are the trade-offs..." | Deep | Multi-source, present both sides, reference decision history |

When in doubt, start with a medium-depth answer and ask "Would you like me to go deeper on any part of this?"
```

**Acceptance Criteria**:
- AC-C05-2.1: Depth calibration table with 4 rows is present
- AC-C05-2.2: Each depth level has an approach description

### Step 3: Add Uncertainty Handling

```markdown
## When You Don't Know

If you cannot find the answer after checking all sources:

1. **Say so explicitly**: "I could not find documentation or issue history for this."
2. **Share what you did find**: "The closest related code is in X, and the nearest beads issue is Y."
3. **Suggest next steps**: "The person who last modified this file (check `git log`) may know, or this might be worth creating a beads question issue."

Never fabricate an answer. A clear "I don't know, here's what I found" is always better than a confident but wrong answer.
```

**Acceptance Criteria**:
- AC-C05-3.1: Uncertainty handling section exists with 3 numbered steps
- AC-C05-3.2: Explicitly states "never fabricate an answer"

---

## Interface Contracts

### Exposes

- **Enriched `/ama` command**: Better answer strategies and depth calibration for users

### Consumes

- **Spec 00 Contract 2**: `meta` block added by C13
- **Existing harness infrastructure**: beads, `.work/`, `docs/feature/`, `harness.yaml`

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/commands/ama.md` | Add answer strategies, depth calibration, uncertainty handling |

**Total**: 0 new files, 1 modified file

---

## Testing Strategy

1. **Section presence**: Verify all three new sections exist in the file
2. **No regression**: Verify the existing "How to answer questions" section with its 3 priority steps is unchanged
3. **Consistency**: Verify answer strategies reference the same sources as the existing priority order (harness.yaml, beads, code exploration)
