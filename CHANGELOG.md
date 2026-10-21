# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0] - Unreleased

### Added

- `pair:Pairing` output style: the navigator stance. Hold back on solutions, never on context.
- `/pair:start` and `/pair:stop` to turn pairing on and off per session, with a recap when stopping.
- `/pair:hint`: a four-rung hint ladder from question to snippet.
- `/pair:critique`: finds the holes in the driver's plan before any code is written.
- `/pair:tdd`: ping-pong TDD where Claude writes the failing test and the driver makes it pass.
- `/pair:delegate`: hands specific files or folders to Claude while pairing stays on.
- Edit guard hook that blocks Claude from editing project files other than tests while pairing is on.
- `enforce_edits` and `allowed_paths` settings.
- Plugin icon.
