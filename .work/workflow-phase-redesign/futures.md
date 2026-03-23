# Futures: W3 Workflow Phase Redesign

Deferred enhancements discovered during research.

- **Phase-specific review agents**: Dedicated spec-review vs impl-review agents with different checklists (from topic 02, 05). Not in W3 scope but would improve review quality.
- **Finding auto-expiry**: Auto-expire OPEN findings when code diff covers the reported file/line (from topic 02). Requires deeper integration with git diff analysis.
- **Dispatch routing by domain**: Route spec agents to specialized agents (database architect, API designer) based on spec content (from topic 01). Requires agent registry and routing rules.
- **Conditional verdicts in adversarial eval**: Allow "MVP if X, DEFER if Y" instead of pure binary (from topic 04). Requires verdict format redesign.
