#!/usr/bin/env bash
#
# Checks a commit message against the project's format:
#
#   type(scope)!: subject
#
#   Optional body after a blank line, kept short.
#
# Reads the message from FILE, or from stdin without one. Like git, it ignores
# lines starting with # and everything below the scissors line.
#
# Usage: check-commit-message.sh [--format-only] [FILE]
#   --format-only  Only check the type prefix. For generated bot commits.

set -euo pipefail

readonly TYPES="feat|fix|docs|ci|chore|release|refactor|test|perf|build|revert"
readonly MAX_SUBJECT=72
readonly MAX_BODY=800

FAILED=0

function fail {
    if [[ "${FAILED}" -eq 0 ]]; then
        >&2 echo "Commit message doesn't follow the project format:"
    fi
    >&2 echo "  - ${1}"
    FAILED=1
}

function strip_comments {
    awk '/^# -+ >8 -+$/ { exit } !/^#/ { print }'
}

function main {
    local FORMAT_ONLY=false
    if [[ "${1:-}" == "--format-only" ]]; then
        FORMAT_ONLY=true
        shift
    fi
    local FILE="${1:-/dev/stdin}"

    local MESSAGE
    MESSAGE="$(strip_comments < "${FILE}" | sed '/./,$!d')"
    local SUBJECT="${MESSAGE%%$'\n'*}"

    local PATTERN="^(${TYPES})(\([a-z0-9._/-]+\))?!?: [^[:space:]]"
    if [[ ! "${SUBJECT}" =~ ${PATTERN} ]]; then
        fail "The subject must look like 'type: subject' or 'type(scope): subject', with type one of: ${TYPES//|/, }."
    fi

    if [[ "${FORMAT_ONLY}" == false ]]; then
        if [[ "${#SUBJECT}" -gt "${MAX_SUBJECT}" ]]; then
            fail "The subject is ${#SUBJECT} characters. Keep it to ${MAX_SUBJECT}."
        fi
        if [[ "${SUBJECT}" == *. ]]; then
            fail "The subject ends with a period. Leave it off."
        fi

        if [[ "${MESSAGE}" == *$'\n'* ]]; then
            local REST="${MESSAGE#*$'\n'}"
            if [[ "${REST%%$'\n'*}" != "" ]]; then
                fail "Leave a blank line between the subject and the body."
            fi
            local BODY
            BODY="$(sed '/./,$!d' <<< "${REST}")"
            if [[ "${#BODY}" -gt "${MAX_BODY}" ]]; then
                fail "The body is ${#BODY} characters. Keep it to ${MAX_BODY}, and put longer explanations in the pull request or an issue."
            fi
        fi
    fi

    if [[ "${FAILED}" -ne 0 ]]; then
        >&2 echo "See 'Commit messages' in CONTRIBUTING.md."
        exit 1
    fi
}

main "$@"
