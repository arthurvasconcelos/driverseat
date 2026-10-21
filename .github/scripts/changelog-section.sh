#!/usr/bin/env bash
#
# Prints the body of a version's section in CHANGELOG.md.
# Fails if the section is missing, has no release date, or is empty.
#
# Usage: changelog-section.sh VERSION [CHANGELOG]

set -euo pipefail

function main {
    local VERSION="${1:-}"
    local CHANGELOG="${2:-CHANGELOG.md}"

    if [[ "${VERSION}" == "" ]]; then
        >&2 echo "Usage: changelog-section.sh VERSION [CHANGELOG]"
        exit 1
    fi

    local HEADING
    HEADING="$(grep -F "## [${VERSION}]" "${CHANGELOG}" | head -n 1 || true)"
    if [[ "${HEADING}" == "" ]]; then
        >&2 echo "${CHANGELOG} has no section for ${VERSION}. Add '## [${VERSION}] - YYYY-MM-DD'."
        exit 1
    fi
    if [[ ! "${HEADING}" =~ ^"## [${VERSION}] - "[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        >&2 echo "The ${VERSION} section needs a release date: '## [${VERSION}] - YYYY-MM-DD', found '${HEADING}'."
        exit 1
    fi

    local BODY
    BODY="$(awk -v HEADING="${HEADING}" '
        $0 == HEADING { FOUND = 1; next }
        FOUND && /^## \[/ { exit }
        FOUND { print }
    ' "${CHANGELOG}")"
    if [[ "$(tr -d '[:space:]' <<< "${BODY}")" == "" ]]; then
        >&2 echo "The ${VERSION} section in ${CHANGELOG} is empty."
        exit 1
    fi

    sed '/./,$!d' <<< "${BODY}"
}

main "$@"
