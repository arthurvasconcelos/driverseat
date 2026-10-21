# Contributing to driverseat

Thanks for helping. This plugin is mostly prompts plus a small hook, so most contributions are about how Claude behaves while pairing.

## The idea to keep in mind

The human drives and Claude navigates. Claude holds back on solutions, never on context. Changes that make Claude more helpful by doing the driver's thinking for them go against the point of the plugin, even when they're convenient.

## Setup

You need [Claude Code](https://code.claude.com), `jq` and bash.

Load the plugin from your checkout:

```bash
claude --plugin-dir /path/to/driverseat
```

Restart the session after changing the output style. Skills are re-read when invoked.

## Layout

| Path | What it is |
|---|---|
| `output-styles/pairing.md` | The navigator stance for the whole session |
| `skills/<name>/SKILL.md` | One procedure per `/pair:<name>` command |
| `hooks/hooks.json` | The edit guard and the session-end cleanup |
| `scripts/` | Hook and state scripts |
| `tests/scripts.test.sh` | Tests for the scripts |
| `assets/` | The icon. Edit `icon.svg`, then export `icon.png` at 1024 px |
| `.githooks/` | Optional local git hooks, see [Commit messages](#commit-messages) |

## Changing prompts

- **Give the reason with the rule.** Claude handles cases the rules don't cover much better when it knows why.
- **Say what to do, not only what to avoid.** A prompt that's mostly "don't" makes Claude hesitant and vague.
- **Write calmly.** No capitals or warnings. Plain instructions are followed closely.
- **Cover the edge cases you can foresee**, like empty arguments, repeated calls or a missing plan.
- **Use examples sparingly.** One example shows the idea, several get copied word for word.
- **Keep stance and procedure apart.** The stance lives in the output style. A skill holds one procedure. `skills/start/SKILL.md` carries a short summary of the stance, so keep the two in sync.

Then try the change in a real session. Test the case you meant to fix, and a case you didn't mean to change. Describe both in the pull request.

## Changing scripts

Run the tests:

```bash
tests/scripts.test.sh
TEST_BASH=/bin/bash tests/scripts.test.sh   # macOS bash 3.2
```

The scripts must work on bash 3.2, because that's what macOS ships with. That rules out things like `${VAR,,}`, associative arrays and `mapfile`. CI runs the tests on Linux and on macOS bash 3.2, and ShellCheck on all scripts.

Style: 4-space indent, `function name { ... }`, `[[ ]]`, upper-case variable names, `${VAR}` braces, and `>&2 echo` for errors.

## Commit messages

Commits follow [Conventional Commits](https://www.conventionalcommits.org/), plus a `release` type:

```
type(scope)!: subject

Optional body.
```

- Type is one of `feat`, `fix`, `docs`, `ci`, `chore`, `release`, `refactor`, `test`, `perf`, `build` or `revert`. The scope and `!` are optional.
- The subject has at most 72 characters and no trailing period.
- The body is optional. It comes after a blank line and has at most 800 characters: say what changed and why, and put longer explanations in the pull request or an issue.
- Pull request titles follow the same format, because the title becomes the merge commit's subject.

CI checks the title and every commit in a pull request. To catch problems before you commit, turn on the hook once per clone:

```sh
git config core.hooksPath .githooks
```

## Pull requests

- Branch from `develop` and open your pull request against `develop`. `main` only receives releases, and CI rejects pull requests into `main` from anywhere else.
- Keep each pull request to one change.
- Sign your commits ([how](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)). `develop` and `main` only accept verified commits.
- Add a line to `CHANGELOG.md` under **Unreleased**.
- Don't change `version` in `plugin.json`. That happens at release time.

## Releases

Maintainers only. `main` is what users install, so it only moves on a release.

1. When a release is getting close, open a draft pull request from `develop` into `main` titled `release: pair <version>`, with the `release` label. It follows `develop` as work lands, so it always shows what the release will contain. Its release check fails until step 2, which is expected.
2. On `develop`, set the new `version` in `.claude-plugin/plugin.json`, and move the **Unreleased** entries in `CHANGELOG.md` under `## [<version>] - YYYY-MM-DD`.
3. Mark the pull request ready for review. CI checks that it comes from `develop`, that the version is new, and that the changelog has a dated entry for it.
4. Merge it with a merge commit, not a squash, so `develop` and `main` keep a shared history.
5. The Release workflow then runs CI again, creates the `pair--v<version>` tag, and publishes a GitHub Release with that changelog section.

Users who update get the new version as soon as it's on `main`. See the README for how they update.
