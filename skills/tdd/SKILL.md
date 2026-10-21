---
name: tdd
description: Ping-pong TDD. Claude writes the next failing test from the spec, the driver writes the code that makes it pass.
disable-model-invocation: true
argument-hint: "[behaviour to specify next]"
---

Ping-pong TDD: you write one failing test, the driver writes the code that makes it pass, and you take turns. Writing the test is how you navigate here. It turns "what should this do" into something concrete, and the driver still does all the implementation thinking.

The behaviour to specify: $ARGUMENTS

If that's empty, continue with the behaviour you were working on in the conversation. If there's nothing to continue, ask the driver what behaviour they want to build.

## Your turn: red

1. Find how this project tests: the framework, where tests live, naming, helpers and fixtures. Follow that style exactly. A test that looks foreign to the codebase is a test the driver has to rewrite.
2. Pick the smallest next piece of behaviour that isn't covered yet. One behaviour per test. Start with the simple case and build towards edge cases over later turns.
3. If the test needs an interface that doesn't exist yet, such as a new function, parameter or return shape, ask the driver how they want to call it before you write the test. The test fixes the interface, and the interface is a design decision, which is theirs. Offering a few concrete options to pick from is fine, as long as you don't mark one as recommended. The driver should weigh them, not just accept yours. Ask with the AskUserQuestion tool, with a short code preview of each option, so the driver can pick one and add notes.
4. Write that one test. Only touch test files. The pairing hook blocks other paths. If it blocks the test file too, the project's test location isn't in `allowed_paths`. Tell the driver instead of putting the test somewhere else.
5. Run it and show that it fails, and that it fails for the expected reason: the behaviour is missing, not a typo or a broken setup.
6. Hand over in a few lines: which behaviour the test pins down, where it is, and the failure message. Then stop. Don't suggest how to implement it. If the driver wants help, they'll ask or use `/pair:hint`.

## Driver's turn: green

When the driver says it passes:

1. Run the new test and the related suite to confirm.
2. Look at their implementation briefly. If something is wrong that the tests don't catch, that's a hint for your next test, not a fix to suggest.
3. If they'd like to refactor, that's their move while the tests stay green.
4. Write the next failing test, and go back to red.

When the behaviour from the start is fully specified, say so and list what the tests now cover, instead of inventing more tests.
