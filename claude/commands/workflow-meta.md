---
description: "Enter harness self-modification mode — pre-seeds context about harness components and validates sync points"
user_invocable: true
skills: [workflow-meta, code-quality]
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-25
---

# /workflow-meta $ARGUMENTS

Enter harness self-modification mode. Pre-seeds context about the harness's own components, guides modifications, and validates sync points.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Step 0: Pre-Seed Context

Before making any changes, gather the current harness inventory:

1. Count files by type:
   ```bash
   echo "Commands:" && ls claude/commands/*.md | wc -l
   echo "Skills:" && find claude/skills -name '*.md' -not -path '*/references/*' | wc -l
   echo "References:" && find claude/skills -name '*.md' -path '*/references/*' | wc -l
   echo "Hooks:" && ls hooks/*.sh | wc -l
   ```

2. Read the workflow-meta skill for modification conventions (loaded via `skills:` frontmatter)

3. Present the inventory summary:
   ```
   --- Harness Inventory ---
   Commands: N files in claude/commands/
   Skills: N files in claude/skills/ (excluding references)
   References: N files in references/ subdirectories
   Hooks: N files in hooks/
   Total: N managed files

   Modification target: $ARGUMENTS
   ```

## Step 1: Understand the Modification

Parse `$ARGUMENTS` to determine what the user wants to change:

| Target Type | Detected By | Guidance Source |
|-------------|-------------|----------------|
| New command | "add command", "new command", "create /..." | workflow-meta skill -> Commands section |
| New skill | "add skill", "new skill" | workflow-meta skill -> Skills section |
| New language pack | "add pack", "language pack", "anti-patterns" | workflow-meta skill -> Adding a New Language Pack |
| New hook | "add hook", "new hook" | workflow-meta skill -> Adding a New Hook |
| Modify existing | Any other target | Read the target file first, then apply conventions |

If the target type is ambiguous, ask the user to clarify.

## Step 2: Pre-Modification Sync Check

Before making changes, validate current sync state:

1. **Command table sync**: Count commands in `claude/commands/` and compare with the command table in `claude/rules/workflow.md` (should list all work commands + `/delegate`)
2. **Install.sh coverage**: Run `(cd claude && find . -type f ! -name '.gitkeep' | wc -l)` and compare with the last installed count
3. **Hook count**: Count hooks in `hooks/*.sh` and compare with hook registrations in install.sh

Report any pre-existing sync issues before proceeding.

## Step 3: Guided Modification

Apply the modification following the conventions from the workflow-meta skill:

- For new commands: create file with frontmatter, verify command table, verify install.sh discovery
- For new skills: create file with frontmatter, update parent skill's References section if applicable
- For new packs: create file in `references/`, verify discovery directive
- For new hooks: create script, add registration to install.sh, document purpose

## Step 4: Post-Modification Sync Validation

After changes are complete, re-run the sync checks from Step 2 and verify:

1. Command table in `workflow.md` includes any new commands
2. install.sh would discover any new files (auto-discovery per Spec 00 Contract 4)
3. If commands were added/removed, the count in `workflow-meta.md` sync points section is updated
4. If hooks were added, they are registered in `harness_hook_entries()`

Report the validation results:
```
--- Sync Validation ---
Command table:  [PASS/FAIL] (N commands in dir, N in table)
Install.sh:    [PASS/FAIL] (N files discoverable)
Hook registry:  [PASS/FAIL] (N hooks in dir, N registered)
```

## Step 5: Report

Summarize what was changed, what sync validations passed, and any manual follow-up needed (e.g., "bump VERSION file if this is a minor release").
