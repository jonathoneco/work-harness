# Spec C06: Codex-Review Skill Enrichment

**Component**: C06 — Codex-review skill enrichment
**Phase**: 1 (Foundation)
**Status**: complete
**Dependencies**: Spec 00 (frontmatter meta block via C13)

---

## Overview and Scope

Enriches `claude/skills/work-harness/codex-review.md` from its current functional state (77 lines) to include diff input strategies, multi-file handling, and clearer integration instructions for the `/work-review` command.

**What this does**:
- Adds diff input preparation guidance (how to generate the diff to send to Codex)
- Adds multi-file diff handling strategy (split vs single invocation)
- Adds integration section clarifying how `/work-review` calls this skill
- Adds `meta` block (handled by C13)

**What this does NOT do**:
- Change the verification rules (they are already well-specified)
- Add new hallucination patterns (add those as discovered in practice)
- Change the output schema

---

## Implementation Steps

### Step 1: Add Diff Input Preparation

After the existing "Execution" section, add guidance on how to prepare the diff:

```markdown
## Diff Preparation

Generate the diff to send to Codex. The diff should include all changes being reviewed:

### For PR review (most common)
```bash
git diff $(gh pr view --json baseRefName -q '.baseRefName')...HEAD
```

### For staged changes
```bash
git diff --cached
```

### For unstaged changes
```bash
git diff
```

### Size limits
- If the diff exceeds 50,000 characters, split by file and make multiple Codex calls
- Each call should include full file context for the files being reviewed
- Combine all findings before verification
```

**Acceptance Criteria**:
- AC-C06-1.1: Diff preparation section with 3 diff generation commands exists
- AC-C06-1.2: Size limit guidance (50k chars) with split strategy is documented

### Step 2: Add Multi-File Handling

```markdown
## Multi-File Handling

When reviewing changes across many files:

1. **Single invocation** (preferred for <50k chars): Send the full diff. Codex sees cross-file relationships.
2. **Split by file** (for large diffs): Group related files together (e.g., handler + service + test). Send each group as a separate Codex call.
3. **Combine findings**: Merge JSONL output from all calls, deduplicate by file+line, then verify all findings.

Do NOT split a single file's diff across multiple invocations — Codex needs full file context to avoid false positives.
```

**Acceptance Criteria**:
- AC-C06-2.1: Three strategies (single, split, combine) are documented
- AC-C06-2.2: "Do NOT split a single file" guidance is present

### Step 3: Add `/work-review` Integration Notes

```markdown
## Integration with /work-review

This skill is consumed by `/work-review` when Codex is available. The integration flow:

1. `/work-review` spawns review agents (per review-methodology)
2. One review agent handles Codex integration (this skill)
3. The Codex agent: prepares diff → calls Codex → verifies findings → returns findings to orchestrator
4. The orchestrator merges Codex findings with other agent findings into `findings.jsonl`

The Codex agent does NOT write to `findings.jsonl` directly — it returns findings to the orchestrating `/work-review` command.
```

**Acceptance Criteria**:
- AC-C06-3.1: Integration flow with 4 numbered steps exists
- AC-C06-3.2: Explicitly states agent does not write to findings.jsonl directly

---

## Interface Contracts

### Exposes

- **Enriched codex-review skill**: More complete guidance for agents performing Codex review

### Consumes

- **Spec 00 Contract 2**: `meta` block added by C13
- **review-methodology**: Referenced for how review agents are spawned
- **findings.jsonl schema**: Referenced for output format

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Modify | `claude/skills/work-harness/codex-review.md` | Add diff prep, multi-file handling, integration notes |

**Total**: 0 new files, 1 modified file

---

## Testing Strategy

1. **Section presence**: Verify all three new sections exist
2. **No regression**: Verify existing Execution, Output Schema, Verification Rules, Known Hallucination Patterns, and Error Handling sections are unchanged
3. **Command accuracy**: Verify the `git diff` commands in diff preparation are syntactically correct
