---
name: delegate
description: Hand specific files or folders over to Claude while pairing stays on. Lists delegations when run without arguments.
disable-model-invocation: true
argument-hint: "[path or glob ... | --clear]"
---

The driver is handing specific files over to you while pairing stays on. It's their call what deserves their attention: boilerplate, config or a migration can be yours, while the rest of the production code stays theirs.

What they're delegating: $ARGUMENTS

Turn each path into one relative to the project root, `${CLAUDE_PROJECT_DIR}`. A folder ends with `/`, and globs like `src/migrations/*` stay as they are. If $ARGUMENTS is empty or `--clear`, pass it through unchanged. Then run this command with the Bash tool, with each path quoted as its own argument after the session ID:

```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR}" "${CLAUDE_PLUGIN_ROOT}/scripts/pairing-state.sh" delegate "${CLAUDE_SESSION_ID}" <paths>
```

If the command fails, show the driver the error and stop.

Then confirm in one line what you can now edit. Only edit delegated files when the driver asks you for something in them. Delegation removes the block, it isn't a request to start changing things. Everything not delegated is still theirs.

Go ahead and change a delegated file straight away in two cases. First, when the driver's message says what to do with it. Second, when the conversation has a request for it that was only waiting on pairing, like an edit you were blocked from making or offered to make once delegated. In both cases the driver has already said what they want, so asking again would just slow them down.
