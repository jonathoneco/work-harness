# claude-work-harness

A workflow harness for Claude Code — commands, skills, agents, hooks, and rules
installed globally to `~/.claude/`. Projects customize behavior via
`.claude/harness.yaml`.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [jq](https://jqlang.github.io/jq/) (JSON processing)
- [yq](https://github.com/mikefarah/yq) (YAML processing)
- [beads](https://github.com/...) (`bd` issue tracker)
- git

## Install

```sh
git clone https://github.com/<user>/claude-work-harness.git
cd claude-work-harness
./install.sh
```

## Update

```sh
cd claude-work-harness
git pull
./install.sh --update
```

## Uninstall

```sh
cd claude-work-harness
./install.sh --uninstall
```

## Project Setup

Inside any project directory:

```
/harness-init
```

This creates `.claude/harness.yaml` with your project's stack configuration.

## Health Check

```
/harness-doctor
```

## License

MIT
