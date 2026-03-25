# Beads Pain Points & Context Costs

## Questions
- How much context window budget does beads consume?
- What's the actual API surface complexity?
- How stable is the daemon?

## Findings

### Context Window Costs
- **Global rules**: `beads-workflow.md` = 126 lines (~600-800 tokens), loaded every session for ALL projects
- **Session start hook**: Additional beads instruction block injected
- **Skills**: 20+ `beads:*` skill entries registered
- **Commands**: 10+ commands embed beads instructions (work-deep.md alone = 594 lines)
- **Total pre-conversation cost**: Estimated 1,500-2,500 tokens of beads-specific context before user says a word

### Data Storage Overhead
- `.beads/beads.db`: 556 KB (SQLite)
- `.beads/beads.db-wal`: 3.0 MB (write-ahead log)
- `.beads/beads.db-shm`: 32 KB
- `.beads/issues.jsonl`: ~75 KB (108 issues)
- **Total disk**: ~3.6 MB of binary + structured data

### Command Complexity
- 9+ core subcommands with multiple flags each
- API surface larger than needed for core use cases
- Many commands rarely used (vc commit, daemon, compact, export/import)

### Daemon Complexity
- RPC socket-based daemon at `.beads/bd.sock`
- SQLite with auto-import/export from JSONL
- Complex state management: auto-import on file changes, export on mutations, git ref detection
- 476+ KB daemon log from Mar 17-25
- Warning patterns: `.gitignore` upgrade failures, uncommitted change warnings, JSONL sync cycles

### Stability Patterns
- No catastrophic errors in logs, but constant sync friction
- Import/export cycles create operational noise
- Daemon state management is overly complex for what amounts to issue CRUD

### Actual Value vs Cost
| Feature | Usage Frequency | Could Be Simplified? |
|---------|----------------|---------------------|
| Issue CRUD | Very high (30+ refs) | Yes — state.json + JSONL |
| Status queries | High (8+ `bd ready` refs) | Yes — jq on JSONL |
| Show details | High (15+ refs) | Yes — jq on JSONL |
| Search | Medium (7 refs) | Yes — grep on JSONL |
| Dependencies | Medium (T3 only) | Yes — JSON field |
| Sync | Low | Unnecessary if git-tracked |
| Dolt/VC | Not actually used | Dead weight |

## Implications
- Beads provides ~$50 of value for ~$500 of complexity
- The daemon, SQLite layer, and sync mechanism are entirely unnecessary if data is just JSONL in git
- Context cost is the biggest pain: 1,500-2,500 tokens per session for rules/skills alone
- A thin shell script wrapping jq operations on a JSONL file could replace 90% of functionality

## Open Questions
- Why does beads use SQLite+JSONL dual storage? Is there a query performance reason?
- Are the beads:* skills actually invoked, or just registered and consuming context?
- Could the global rule file be project-conditional (only load when .beads/ exists)?
