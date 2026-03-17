# Self-Driving Workflow Requirement

## User Feedback

The harness must be self-driving — meaning the agent stays on the harness rails and handles all bookkeeping automatically. When a step completes, the workflow should:
1. Create the handoff prompt
2. Run the step output review
3. Create the gate review issue
4. Update state.json
5. Refresh context (re-read rules)
6. Present the summary and **wait for user acknowledgment**

The user interacts via natural language — "looks good, continue", "hold on, I have questions about X", "go back and investigate Y more". They should NOT need to type `/work-checkpoint --step-end` manually.

**Critical clarification:** "Self-driving" means the agent sticks to the harness bounds and flows through the steps accordingly. It does NOT mean "silence = proceed" — every gate requires user input before advancing. The harness drives the mechanics; the user controls the pace.

## Design Requirements

1. `/work-deep` should be a single command that self-routes through all steps
2. Step completion triggers automatic bookkeeping (handoff + gate + state + context refresh)
3. Gate summaries are presented to the user, who must acknowledge before the next step begins
4. Hooks validate that the bookkeeping actually produced required artifacts
5. The agent never needs to be told to "follow the harness" — it just does

## Connection to Enforcement

This is complementary to hook enforcement:
- **Self-driving** ensures the workflow tries to do the right thing (stays on rails)
- **Hooks** ensure it actually did the right thing (validates post-conditions)
- **User gates** ensure the user stays informed and in control (no silent advancement)
