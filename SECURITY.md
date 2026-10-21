# Security Policy

## Supported Versions

Only the latest released minor version receives security fixes.

| Version | Supported      |
|---------|----------------|
| 0.1.x   | ✓ current      |

Once 1.0 ships this table will follow semver: the latest patch of each
supported minor line will receive fixes.

Update with `claude plugin update pair@driverseat`.

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

If you discover a vulnerability, report it privately through **GitHub private
vulnerability reporting**: use the
[Report a vulnerability](../../security/advisories/new) button on the Security
tab of this repository. This keeps the report private until a fix is released.

Include as much of the following as possible:

- Type of issue (e.g. path traversal, command injection)
- The affected script(s) or file(s)
- The plugin version or git commit where the issue was introduced
- Your operating system and `bash --version`
- Any special configuration required to reproduce, such as plugin settings
- Step-by-step instructions to reproduce
- Proof-of-concept or exploit code (if available)
- Impact and how an attacker might exploit it

## Scope

This plugin runs shell scripts as Claude Code hooks on your machine. In scope
are ways for input, such as a crafted session id, file path or plugin setting,
to make those scripts:

- read, write or delete files outside the plugin's data directory
- run commands

Claude bypassing the edit guard, for example by writing files through the
shell, is a known limitation listed in the README, not a vulnerability. Ideas
for closing that gap are welcome as regular issues.

## Response

This project is maintained on a best-effort basis. There are no guaranteed
response times. Reports will be reviewed and addressed as time permits.

We aim to coordinate disclosure with the reporter before making any fix public.
Reporters who wish to be credited will be acknowledged in the release notes.
