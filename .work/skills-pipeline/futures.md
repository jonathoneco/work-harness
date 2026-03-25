# Futures: Skills Pipeline

## Multi-Language Schema v2
**Horizon**: next
**Domain**: harness-config
Change `stack.language` from singular string to `languages: []` array in harness.yaml schema. Requires schema migration logic in install.sh, updates to all consumers of `stack.language`, and multi-pack loading in code-quality skill. The `review_routing` by file pattern workaround covers the most common case (mixed Go+TypeScript projects) until this lands.

## Deep Notion Exploration Skill
**Horizon**: next
**Domain**: external-integrations
Push back against shallow Notion exploration by creating a skill that handles pagination, nested blocks, and database queries comprehensively. Blocked on Notion OAuth configuration -- prerequisite is completing OAuth setup and verifying MCP permission model allows subagent access.

## Config Injection Consolidation
**Horizon**: quarter
**Domain**: harness-internals
The config injection pattern (read harness.yaml, inject stack context into agent prompts) is duplicated across all commands. Extract into a shared utility or skill reference that commands include. Reduces maintenance burden as new commands are added. Referenced by DD-6 in the skills-pipeline architecture -- explicitly deferred from W4 scope.

## Automated Skill Testing Framework
**Horizon**: someday
**Domain**: harness-quality
Build a test framework for markdown-based skills and commands -- verify frontmatter schema, check directive references resolve, validate that install.sh registers all commands. Currently manual via `/harness-doctor`; a proper test suite would catch regressions in CI.

## External Pack Vendoring (install.sh --rules)
**Horizon**: next
**Domain**: harness-ecosystem
External rule libraries (`continuedev/awesome-rules` CC0, `lifedever/claude-rules` MIT) were evaluated for W4 but rejected as primary dependencies — too young and not AI-specific enough. If these libraries mature (12+ months, broader adoption, AI-specific content), revisit vendoring via `install.sh --rules` following the agency-agents pattern. The file-presence discovery architecture already supports vendored files alongside first-party packs.
