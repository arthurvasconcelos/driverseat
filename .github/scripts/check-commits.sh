#!/usr/bin/env bash
#
# Checks the message of every commit in BASE..HEAD, skipping merge commits.
# Dependabot's commits only need the type prefix, since their bodies are generated.
#
# Usage: check-commits.sh BASE HEAD

set -euo pipefail

CHECK="$(dirname "${BASH_SOURCE[0]}")/check-commit-message.sh"
readonly CHECK
readonly BOT_EMAIL="49699333+dependabot[bot]@users.noreply.github.com"

function main {
    local BASE="${1:-}"
    local HEAD="${2:-}"

    if [[ "${BASE}" == "" || "${HEAD}" == "" ]]; then
        >&2 echo "Usage: check-commits.sh BASE HEAD"
        exit 1
    fi

    local RANGE="${BASE}..${HEAD}"
    if [[ "${BASE}" =~ ^0+$ ]]; then
        RANGE="${HEAD}^!"
    fi

    local SHAS
    if ! SHAS="$(git rev-list --no-merges --reverse "${RANGE}")"; then
        >&2 echo "Can't list the commits in ${RANGE}."
        exit 1
    fi

    local FAILED=0
    local SHA OPTION OUTPUT
    for SHA in ${SHAS}; do
        OPTION=""
        if [[ "$(git log -1 --format=%ae "${SHA}")" == "${BOT_EMAIL}" ]]; then
            OPTION="--format-only"
        fi
        if ! OUTPUT="$(git log -1 --format=%B "${SHA}" | "${BASH}" "${CHECK}" ${OPTION:+"${OPTION}"} 2>&1)"; then
            echo "${SHA:0:7} $(git log -1 --format=%s "${SHA}")"
            echo "${OUTPUT}"
            echo
            FAILED=1
        fi
    done

    if [[ "${FAILED}" -ne 0 ]]; then
        exit 1
    fi
    echo "All commit messages in ${RANGE} follow the format."
}

main "$@"
