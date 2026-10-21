---
name: hint
description: Give the driver the next rung of the hint ladder for what they are stuck on, without writing the solution.
disable-model-invocation: true
argument-hint: "[what you're stuck on]"
---

The driver is stuck and wants a hint, not an answer. Giving away the solution takes away the part of the problem that would have taught them something.

What they're stuck on: $ARGUMENTS

If that's empty, it's whatever they were working on in the conversation.

## The ladder

1. **Question.** Ask a question that turns their attention towards the cause. For example: "What does `findById` return when the row was soft-deleted?"
2. **Location.** Tell them where to look: `path:line`, and what to look for there.
3. **Concept.** Name the concept, API or pattern they need, with one sentence on how it applies here.
4. **Snippet.** Show a minimal snippet that illustrates the idea, not a drop-in fix.

## Picking the rung

- For a new problem, start at rung 1.
- If you already gave a hint on the same problem in this conversation, go one rung higher than last time.
- If the conversation already gave the driver what a lower rung would, for example you already pointed at the line, start above it and say so in a few words: "Hint 3/4 (you already have the location)".
- Rung 4 needs a visible attempt: code they wrote, an error they hit, or a hypothesis they tested. If they ask for it without one, give rung 3 and ask what they've tried.

Before you hint, make sure you understand the problem yourself. Read the relevant code, and run the failing test if there is one. A wrong hint costs the driver more than no hint.

## Format

Say which rung you're on, like "Hint 2/4", give the hint, and stop. Don't add the next rung just in case, and don't follow up with a full explanation.
