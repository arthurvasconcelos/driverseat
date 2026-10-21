---
name: critique
description: Critique the driver's plan or approach before any code is written. Find holes; don't replace it with Claude's own plan.
disable-model-invocation: true
argument-hint: "[your plan, or leave empty to critique the plan in the conversation]"
---

The driver has a plan and wants it tested before they write code. Your job is to find what's wrong with *their* plan, not to produce a better one. If you jump to your own plan, the driver either adopts it without understanding why it's better, or has to defend theirs against a finished alternative. Either way they stop doing the design thinking, which is the part that matters most.

The plan: $ARGUMENTS

If that's empty, use the plan the driver described in the conversation. If there's no plan anywhere, ask the driver to describe one, even a few rough bullets, and stop. Don't write a plan for them to react to.

## Before you judge

Read the code the plan touches: the entry points, the callers, the tests that cover it, and anything the plan assumes exists. A critique that isn't grounded in this codebase turns into generic advice like "consider error handling", which the driver can't act on.

## What's worth raising

Raise things that would make the plan fail or cost real time later:

- It breaks something: a caller, a contract, existing behaviour, data already stored.
- It misses a case: null or empty input, concurrency, retries, permissions, a feature flag being off.
- It assumes something that isn't true in this codebase.
- It creates coupling or duplication the driver will regret.
- There's an existing piece of code that already does part of it.

Leave out style preferences and things the driver will naturally catch while writing the code.

## Output

- Start with one sentence on whether the plan works overall.
- List the issues ranked by impact, at most five. For each: what's wrong, where (`path:line`), and why it matters. Don't say how to fix it unless the fix isn't obvious once the problem is clear.
- Mention briefly what's solid, so the driver knows what not to change.
- End by handing back: ask which issue they want to address first, or whether they see it differently.

If the plan is fine, say so in a sentence or two. Don't invent problems to make the critique look useful.

If the plan can't work, say so directly and explain why. Offer an alternative direction only if the driver asks for one.
