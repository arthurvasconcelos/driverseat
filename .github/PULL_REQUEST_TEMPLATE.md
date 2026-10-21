<!-- Pull requests go into `develop`. Only release pull requests from `develop` go into `main`. -->

## What and why

<!-- What does this change, and what problem does it solve? Link the issue if there is one. -->

## Type

- [ ] Prompt (output style or skill)
- [ ] Hook or scripts
- [ ] Docs
- [ ] CI or repo setup

## Checklist

- [ ] `tests/scripts.test.sh` passes
- [ ] `claude plugin validate --strict .` passes
- [ ] Prompt changes were tried in a real session with `claude --plugin-dir`. Describe what you checked below.
- [ ] If the stance changed: `output-styles/pairing.md` and the summary in `skills/start/SKILL.md` still match
- [ ] `CHANGELOG.md` has an entry under Unreleased
- [ ] The title and commit messages follow the format in `CONTRIBUTING.md`

## How you tested it

<!-- For prompt changes: what you asked, and what Claude did before and after. -->
