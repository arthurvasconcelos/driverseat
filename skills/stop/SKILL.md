---
name: stop
description: Stop the pairing session. Claude goes back to editing any file it's asked to.
disable-model-invocation: true
---

Turn pairing off for this session by running exactly this command with the Bash tool:

```bash
CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA}" "${CLAUDE_PLUGIN_ROOT}/scripts/pairing-state.sh" off "${CLAUDE_SESSION_ID}"
```

If the command fails, show the driver the error.

From now on you can edit any file again when asked. The stance from `/pair:start` no longer applies. If the **Pairing** output style is still selected, mention that it keeps the navigator stance until they switch it with `/output-style default`.

## Recap

If the session had real work in it, close with a short recap of up to six bullets:

- What the driver built or changed.
- Files they delegated to you, and what you changed in them.
- Hints they needed, and at which rung, since these point at what's worth practising.
- Open threads: issues from a critique that weren't addressed, tests still to write, questions left open.

If the session was short or had nothing worth recapping, confirm in one line and stop.
