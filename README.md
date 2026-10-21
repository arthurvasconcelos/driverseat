<p align="center"><img src="assets/icon.svg" alt="" width="120"></p>

# driverseat

**You drive. Claude navigates.**

A pairing mode for [Claude Code](https://code.claude.com). You write the code. Claude scouts the codebase, critiques your plan, gives hints instead of answers, and writes failing tests for you to make pass.

> Status: early work in progress (v0.1). Not yet tested in real sessions.

## Why

Writing code is both creative and strategic. In the AI age, it is easy to fall into the trap of letting AI do the thinking for you; little by little, you lose control and knowledge of your codebase. Still, we cannot ignore the benefits AI can bring to the table.

This plugin aims to give you that control back while still letting you benefit from AI's capabilities. You will no longer outsource your thinking to AI, but you will have a second pair of eyes to help you navigate the codebase, critique your plan, and give hints when you're stuck.

## Install

```bash
claude plugin marketplace add arthurvasconcelos/driverseat
claude plugin install pair@driverseat
```

## Updating

Updates aren't installed automatically for marketplaces like this one. Either:

- **Turn on auto-update:** run `/plugin`, go to **Marketplaces**, select **driverseat** and choose **Enable auto-update**. Claude Code then checks for updates in the background and tells you when one is installed.
- **Update by hand:** `claude plugin update pair@driverseat`

Then run `/reload-plugins`, or start a new session, to load the new version. See [CHANGELOG.md](CHANGELOG.md) for what changed.

## Usage

| Command | What it does |
|---|---|
| `/pair:start [task]` | Turns pairing on for this session. Claude can only edit test files. |
| `/pair:stop` | Turns pairing off. |
| `/pair:hint [problem]` | Next rung of the hint ladder: question → where to look → concept → snippet. |
| `/pair:critique [plan]` | Finds the holes in your plan before you write code. |
| `/pair:tdd [behaviour]` | Ping-pong TDD: Claude writes a failing test, you make it pass. |
| `/pair:delegate [paths \| --clear]` | Hands specific files or folders to Claude while pairing stays on. Without arguments, lists what's delegated. |

Select the `pair:Pairing` output style with `/output-style` for the navigator stance across the whole session. It works mid-session too.

## Configuration

Set when you enable the plugin:

| Option | Default | Meaning |
|---|---|---|
| `enforce_edits` | `true` | While pairing is on, block Claude from editing project files that don't match `allowed_paths`. |
| `allowed_paths` | common test file patterns | Comma-separated bash globs relative to the project root. `*` also matches across directories. |

Files outside the project, such as plans and scratch files, are never blocked.

## Requirements

- `jq` for the hook scripts. Without it, edits are not blocked and a warning is shown.
- bash 3.2 or later. The version macOS ships with works.

## Known limitations

- The hook covers Claude's edit tools only. Claude could still write files through the shell, or run the pairing scripts itself to change what's allowed. The output style and the deny message tell it not to.
- `/clear` starts a new session, and pairing is off in it. Run `/pair:start` again after clearing.
- If Claude Code exits abruptly, for example when the terminal is closed or the process is killed, the session's pairing state file is left behind. It's harmless: it's only read again if you resume that exact session.

## Wishlist

Ideas we plan to work on. Suggestions are welcome.

- **Session goals.** Choose between learning and delivery when starting. A learning session keeps the hint ladder strict. A delivery session moves faster: problems Claude spots come with their cause, and hints start higher up the ladder.
- **Keep pairing on across `/clear`.** Restore pairing in the new session instead of switching it off.
- **Clean up leftover state files** from sessions that exited abruptly.
- **Guard shell writes too.** Catch file writes through the shell while pairing is on, not only the edit tools.
- **`/pair:scout`.** A map of where to start for a task: entry points as `path:line` with one line each on why they matter.
- **`/pair:explain-back`.** Claude asks you to explain what you just wrote, and checks your understanding.
- **Session stats.** Hints used and at which rung, tests written and files delegated, to show what's worth practising.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to run the plugin from a checkout, test changes and propose prompt changes. Everyone taking part is expected to follow the [code of conduct](CODE_OF_CONDUCT.md). To report a security problem, see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
