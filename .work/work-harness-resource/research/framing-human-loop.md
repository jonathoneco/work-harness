# Framing Note: The Human Loop Is Not Just "Proceed"

Survivorship bias risk: the most common user messages are terse approvals ("Proceed", "Looks good", "Launch them"). But the guide must not frame this as "terse human, busy agents" — the critical moments are when the human intervenes, and those interventions are what make the system work.

## Categories of Human Intervention

### 1. Catching Scope Gaps

Agents don't always see the full picture. The human adds constraints and workstreams:
- "I'm noticing a lack of environment cleanup" — added an entire workstream to strip-api
- "I'd also like to research / plan necessary updates to specs, skills, and context doc" — expanded wf1-cleanup mid-plan

### 2. Probing Before Deciding

The human often asks for more context before committing:
- "Give me more context on items 2 and 3" → then chose options A and C
- "Apply these fixes, but I want to dig a bit more into the auth concern"
- "I lean yes but open to being challenged" — explicitly inviting pushback
- "I'm torn, what does the research suggest"

### 3. Overriding Agent Recommendations

The human overrides when agent defaults are wrong:
- Phase B recommended "report-and-proceed" → "I actually think fail-closed for both"
- "I worry tier 2 being advisory will not be sufficiently thorough"
- "I worry, is there anywhere else this 'trust the llm' pattern being baked in unintentionally"

### 4. Stopping the Train

Hard stops when the harness is violated:
- "Stop, you moved straight from specing to implementation with no check in or handoffs"
- "Roll back state to spec, and undo the changes"
- "You should have checked with me again before proceeding since I never explicitly approved"

### 5. Questioning Design Philosophy

The human holds the vision and checks alignment:
- "Where in our planning did this misunderstanding start"
- "Is there anything else like this that goes against the philosophy I'm going for here"
- "I explicitly don't want silence = proceed"

### 6. Asking for Options

When uncertain, the human requests analysis rather than guessing:
- "what's the 'do it right' approach here"
- "I'm torn, what does the research suggest"
- "I like B, there's a maintenance step but we're considering that here anyways, am I that off base?"

## The Right Framing

The gates exist to create moments for judgment. Sometimes judgment is "looks good" and sometimes it's "stop, roll back." Both are the system working. The terse approvals are the *output* of judgment (the human read the artifact, formed a view, approved), not the absence of it.

The guide should emphasize: **your job at each gate is to read the artifact in your editor and form a view.** If the view is "this is right," say "proceed." If not, push back. The harness is designed for both.
