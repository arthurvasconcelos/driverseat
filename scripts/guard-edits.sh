#!/usr/bin/env bash
#
# PreToolUse hook for Edit|Write|MultiEdit|NotebookEdit.
#
# While pairing is on for the session, denies edits to project files that
# don't match the allowed paths or the paths the driver delegated. Files
# outside the project are always allowed.

set -euo pipefail

readonly DEFAULT_ALLOWED_PATHS="*.test.*,*.spec.*,*_test.*,test_*,*Test.java,*Tests.java,*IT.java,test/*,tests/*,*/test/*,*/tests/*,*/__tests__/*,*/e2e/*"

function is_true {
    case "$(tr '[:upper:]' '[:lower:]' <<< "${1}")" in
        true | 1 | yes) return 0 ;;
        *) return 1 ;;
    esac
}

function is_allowed {
    local REL_PATH="${1}"
    local PATTERNS="${2}"
    local PATTERN

    while IFS= read -r PATTERN; do
        PATTERN="${PATTERN#"${PATTERN%%[![:space:]]*}"}"
        PATTERN="${PATTERN%"${PATTERN##*[![:space:]]}"}"
        if [[ "${PATTERN}" != "" && "${REL_PATH}" == ${PATTERN} ]]; then
            return 0
        fi
    done < <(tr ',' '\n' <<< "${PATTERNS}")

    return 1
}

function deny {
    local REL_PATH="${1}"
    local REASON="Pairing mode is on: ${REL_PATH} is the driver's to write. Don't retry the edit or work around it, and don't change the pairing state yourself. Describe the change, point to file:line, or give a hint instead. If the driver wants to hand this file over, they can run /pair:delegate ${REL_PATH}, or /pair:stop to end pairing."

    jq -n --arg REASON "${REASON}" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $REASON
        }
    }'
}

function main {
    if ! command -v jq > /dev/null; then
        >&2 echo "driverseat: jq is not installed, so source edits are not being blocked"
        exit 1
    fi

    if ! is_true "${CLAUDE_PLUGIN_OPTION_ENFORCE_EDITS:-true}"; then
        exit 0
    fi

    local INPUT
    INPUT="$(cat)"

    local SESSION_ID
    SESSION_ID="$(jq -r '.session_id // empty' <<< "${INPUT}")"
    if [[ "${SESSION_ID}" == "" || "${CLAUDE_PLUGIN_DATA:-}" == "" ]]; then
        exit 0
    fi
    if [[ ! -f "${CLAUDE_PLUGIN_DATA}/sessions/${SESSION_ID}" ]]; then
        exit 0
    fi

    local FILE_PATH
    FILE_PATH="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<< "${INPUT}")"
    if [[ "${FILE_PATH}" == "" ]]; then
        exit 0
    fi

    local PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(jq -r '.cwd // empty' <<< "${INPUT}")}"
    if [[ "${FILE_PATH}" != /* ]]; then
        FILE_PATH="$(jq -r '.cwd // empty' <<< "${INPUT}")/${FILE_PATH}"
    fi
    if [[ "${PROJECT_DIR}" == "" || "${FILE_PATH}" != "${PROJECT_DIR%/}/"* ]]; then
        exit 0
    fi

    local REL_PATH="${FILE_PATH#"${PROJECT_DIR%/}/"}"
    local ALLOWED_PATHS="${CLAUDE_PLUGIN_OPTION_ALLOWED_PATHS:-${DEFAULT_ALLOWED_PATHS}}"

    if is_allowed "${REL_PATH}" "${ALLOWED_PATHS}"; then
        exit 0
    fi

    local DELEGATED="${CLAUDE_PLUGIN_DATA}/sessions/${SESSION_ID}.delegated"
    if [[ -f "${DELEGATED}" ]] && is_allowed "${REL_PATH}" "$(cat "${DELEGATED}")"; then
        exit 0
    fi

    deny "${REL_PATH}"
}

main "$@"
