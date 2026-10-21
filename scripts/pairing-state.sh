#!/usr/bin/env bash
#
# Turns pairing on or off for one Claude Code session, and manages the files
# the driver has delegated to Claude while pairing is on.
#
# Usage: pairing-state.sh <on|off|status> [SESSION_ID]
#        pairing-state.sh delegate SESSION_ID [--clear | PATH...]
#
# Without SESSION_ID, the session id is read from hook input on stdin.
# State lives in ${CLAUDE_PLUGIN_DATA}/sessions/<session id>, and delegated
# paths in ${CLAUDE_PLUGIN_DATA}/sessions/<session id>.delegated.

set -euo pipefail

function read_session_id_from_stdin {
    if ! command -v jq > /dev/null; then
        >&2 echo "driverseat: jq is required to read hook input"
        exit 1
    fi
    jq -r '.session_id // empty'
}

function normalize_path {
    local DELEGATED_PATH="${1}"
    local PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"

    if [[ "${PROJECT_DIR}" != "" && "${DELEGATED_PATH}" == "${PROJECT_DIR%/}/"* ]]; then
        DELEGATED_PATH="${DELEGATED_PATH#"${PROJECT_DIR%/}/"}"
    fi
    DELEGATED_PATH="${DELEGATED_PATH#./}"
    if [[ "${DELEGATED_PATH}" == */ ]]; then
        DELEGATED_PATH="${DELEGATED_PATH}*"
    fi

    echo "${DELEGATED_PATH}"
}

function list_delegated {
    local DELEGATED="${1}"

    if [[ -s "${DELEGATED}" ]]; then
        echo "Delegated to Claude in this session:"
        sed 's/^/  - /' "${DELEGATED}"
    else
        echo "Nothing is delegated in this session."
    fi
}

function delegate {
    local MARKER="${1}"
    local DELEGATED="${2}"
    shift 2

    if [[ ! -f "${MARKER}" ]]; then
        echo "Pairing is off for this session, so Claude can already edit any file."
        return
    fi

    if [[ "$#" -eq 0 ]]; then
        list_delegated "${DELEGATED}"
        return
    fi

    if [[ "${1}" == "--clear" ]]; then
        rm -f "${DELEGATED}"
        echo "Cleared all delegated paths."
        return
    fi

    local DELEGATED_PATH
    for DELEGATED_PATH in "$@"; do
        DELEGATED_PATH="$(normalize_path "${DELEGATED_PATH}")"
        if [[ "${DELEGATED_PATH}" == "" ]]; then
            continue
        fi
        if [[ "${DELEGATED_PATH}" == /* ]]; then
            echo "Skipped ${DELEGATED_PATH}: it's outside the project, so it was never blocked."
            continue
        fi
        if ! grep -qxF -- "${DELEGATED_PATH}" "${DELEGATED}" 2> /dev/null; then
            echo "${DELEGATED_PATH}" >> "${DELEGATED}"
        fi
    done

    list_delegated "${DELEGATED}"
}

function main {
    local ACTION="${1:-}"
    local SESSION_ID="${2:-}"
    shift $(( $# < 2 ? $# : 2 ))

    if [[ "${CLAUDE_PLUGIN_DATA:-}" == "" ]]; then
        >&2 echo "driverseat: CLAUDE_PLUGIN_DATA is not set"
        exit 1
    fi

    if [[ "${SESSION_ID}" == "" && "${ACTION}" != "delegate" ]]; then
        SESSION_ID="$(read_session_id_from_stdin)"
    fi

    if [[ "${SESSION_ID}" == "" || "${SESSION_ID}" == */* || "${SESSION_ID}" == .* ]]; then
        >&2 echo "driverseat: missing or invalid session id"
        exit 1
    fi

    local SESSIONS_DIR="${CLAUDE_PLUGIN_DATA}/sessions"
    local MARKER="${SESSIONS_DIR}/${SESSION_ID}"
    local DELEGATED="${MARKER}.delegated"

    case "${ACTION}" in
        on)
            mkdir -p "${SESSIONS_DIR}"
            date -u +%Y-%m-%dT%H:%M:%SZ > "${MARKER}"
            echo "Pairing is on for this session."
            ;;
        off)
            rm -f "${MARKER}" "${DELEGATED}"
            echo "Pairing is off for this session."
            ;;
        status)
            if [[ -f "${MARKER}" ]]; then
                echo "Pairing is on for this session (since $(cat "${MARKER}"))."
                list_delegated "${DELEGATED}"
            else
                echo "Pairing is off for this session."
            fi
            ;;
        delegate)
            delegate "${MARKER}" "${DELEGATED}" "$@"
            ;;
        *)
            >&2 echo "Usage: pairing-state.sh <on|off|status> [SESSION_ID]"
            >&2 echo "       pairing-state.sh delegate SESSION_ID [--clear | PATH...]"
            exit 1
            ;;
    esac
}

main "$@"
