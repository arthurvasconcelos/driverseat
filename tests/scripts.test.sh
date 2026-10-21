#!/usr/bin/env bash
#
# Tests for the hook and state scripts, and the commit message checks.
#
# Usage: tests/scripts.test.sh
# Set TEST_BASH to run the scripts with a specific bash, e.g. /bin/bash on macOS.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT
readonly TEST_BASH="${TEST_BASH:-bash}"
readonly GUARD="${ROOT}/scripts/guard-edits.sh"
readonly STATE="${ROOT}/scripts/pairing-state.sh"
readonly MESSAGE_CHECK="${ROOT}/.github/scripts/check-commit-message.sh"
readonly COMMITS_CHECK="${ROOT}/.github/scripts/check-commits.sh"

PASSED=0
FAILED=0

CLAUDE_PLUGIN_DATA="$(mktemp -d)"
export CLAUDE_PLUGIN_DATA
export CLAUDE_PROJECT_DIR="/proj"
TEST_REPO="$(mktemp -d)"
trap 'rm -rf "${CLAUDE_PLUGIN_DATA}" "${TEST_REPO}"' EXIT

function state {
    "${TEST_BASH}" "${STATE}" "$@" 2>&1
}

function edit_input {
    jq -nc --arg SESSION "${1}" --arg FILE "${2}" \
        '{session_id: $SESSION, cwd: "/proj", tool_name: "Edit", tool_input: {file_path: $FILE}}'
}

function decision {
    local OUTPUT
    OUTPUT="$("${TEST_BASH}" "${GUARD}")"
    if [[ "${OUTPUT}" == "" ]]; then
        echo "allow"
    else
        jq -r '.hookSpecificOutput.permissionDecision' <<< "${OUTPUT}"
    fi
}

function edit_decision {
    edit_input "${1}" "${2}" | decision
}

function check {
    local NAME="${1}"
    local EXPECTED="${2}"
    local ACTUAL="${3}"

    if [[ "${ACTUAL}" == *"${EXPECTED}"* ]]; then
        PASSED=$((PASSED + 1))
        echo "ok   ${NAME}"
    else
        FAILED=$((FAILED + 1))
        echo "FAIL ${NAME}: expected '${EXPECTED}', got '${ACTUAL}'"
    fi
}

function test_guard {
    check "pairing off: source edit allowed" "allow" "$(edit_decision S1 /proj/src/a.ts)"

    state on S1 > /dev/null
    check "pairing on: source edit denied" "deny" "$(edit_decision S1 /proj/src/a.ts)"
    check "test file allowed" "allow" "$(edit_decision S1 /proj/src/a.test.ts)"
    check "root-level test file allowed" "allow" "$(edit_decision S1 /proj/a.spec.ts)"
    check "java test allowed" "allow" "$(edit_decision S1 /proj/src/test/java/FooTest.java)"
    check "java main denied" "deny" "$(edit_decision S1 /proj/src/main/java/Foo.java)"
    check "file outside project allowed" "allow" "$(edit_decision S1 /Users/someone/plan.md)"
    check "relative path denied" "deny" "$(edit_decision S1 src/b.ts)"
    check "other session unaffected" "allow" "$(edit_decision S2 /proj/src/a.ts)"
    check "notebook denied" "deny" \
        "$(jq -nc '{session_id: "S1", cwd: "/proj", tool_input: {notebook_path: "/proj/nb.ipynb"}}' | decision)"
    check "enforce_edits=false allows" "allow" \
        "$(edit_input S1 /proj/src/a.ts | CLAUDE_PLUGIN_OPTION_ENFORCE_EDITS=false decision)"
    check "enforce_edits=TRUE still denies" "deny" \
        "$(edit_input S1 /proj/src/a.ts | CLAUDE_PLUGIN_OPTION_ENFORCE_EDITS=TRUE decision)"
    check "custom allowed_paths, newline separated" "allow" \
        "$(edit_input S1 /proj/docs/x.md | CLAUDE_PLUGIN_OPTION_ALLOWED_PATHS=$'docs/*\n*.test.*' decision)"
    check "deny reason names the delegate command" "/pair:delegate src/a.ts" \
        "$(edit_input S1 /proj/src/a.ts | "${TEST_BASH}" "${GUARD}" | jq -r '.hookSpecificOutput.permissionDecisionReason')"
}

function test_delegation {
    check "list when nothing delegated" "Nothing is delegated" "$(state delegate S1)"

    local OUTPUT
    OUTPUT="$(state delegate S1 /proj/src/cart.js ./config/ 'src/migrations/*' /etc/hosts)"
    check "absolute path normalized" "src/cart.js" "${OUTPUT}"
    check "folder becomes a glob" "config/*" "${OUTPUT}"
    check "path outside project skipped" "outside the project" "${OUTPUT}"

    check "delegated file allowed" "allow" "$(edit_decision S1 /proj/src/cart.js)"
    check "delegated folder allowed" "allow" "$(edit_decision S1 /proj/config/app.yml)"
    check "delegated glob allowed" "allow" "$(edit_decision S1 /proj/src/migrations/001.sql)"
    check "non-delegated file still denied" "deny" "$(edit_decision S1 /proj/src/other.js)"

    state on S2 > /dev/null
    check "delegation is per session" "deny" "$(edit_decision S2 /proj/src/cart.js)"

    state delegate S1 src/cart.js > /dev/null
    check "no duplicate delegations" "1" "$(grep -c 'src/cart.js' "${CLAUDE_PLUGIN_DATA}/sessions/S1.delegated")"
    check "status lists delegations" "config/*" "$(state status S1)"
    check "clear delegations" "Cleared" "$(state delegate S1 --clear)"
    check "denied again after clear" "deny" "$(edit_decision S1 /proj/src/cart.js)"
}

function test_state {
    state delegate S1 src/cart.js > /dev/null
    jq -nc '{session_id: "S1"}' | "${TEST_BASH}" "${STATE}" off > /dev/null
    check "SessionEnd removes marker" "gone" \
        "$([[ -e "${CLAUDE_PLUGIN_DATA}/sessions/S1" ]] && echo present || echo gone)"
    check "SessionEnd removes delegations" "gone" \
        "$([[ -e "${CLAUDE_PLUGIN_DATA}/sessions/S1.delegated" ]] && echo present || echo gone)"
    check "delegate while pairing is off" "Pairing is off" "$(state delegate S1 src/x.js)"

    check "path traversal session id rejected" "invalid session id" "$(state on ../evil)"
    check "dot session id rejected" "invalid session id" "$(state on ..)"
    check "delegate without session id rejected" "invalid session id" "$(state delegate)"
    check "unknown action rejected" "Usage" "$(state foo S1)"
}

function message_result {
    local OUTPUT
    if OUTPUT="$("${TEST_BASH}" "${MESSAGE_CHECK}" "$@" 2>&1)"; then
        echo "ACCEPTED"
    else
        echo "REJECTED: ${OUTPUT}"
    fi
}

function repeat {
    head -c "${2}" < /dev/zero | tr '\0' "${1}"
}

function test_commit_message {
    check "plain type accepted" "ACCEPTED" "$(message_result <<< "feat: add the hint ladder")"
    check "scope and breaking marker accepted" "ACCEPTED" "$(message_result <<< "fix(hook)!: deny notebook edits")"
    check "release merge subject accepted" "ACCEPTED" "$(message_result <<< "release: pair 0.1.0 (#1)")"
    check "short body accepted" "ACCEPTED" "$(message_result <<< $'docs: explain delegation\n\nWhat and why, briefly.')"
    check "leading blank lines ignored" "ACCEPTED" "$(message_result <<< $'\n\nci: run tests on macOS')"
    check "comments and scissors ignored" "ACCEPTED" \
        "$(message_result <<< $'chore: tidy\n# Please enter the commit message\n# ------------------------ >8 ------------------------\ndiff --git a/x b/x')"
    check "message from a file" "ACCEPTED" "$(echo "test: cover the guard" > "${TEST_REPO}/msg" && message_result "${TEST_REPO}/msg")"

    check "missing type rejected" "type one of" "$(message_result <<< "Update the README")"
    check "unknown type rejected" "type one of" "$(message_result <<< "feature: add x")"
    check "capitalised type rejected" "type one of" "$(message_result <<< "Feat: add x")"
    check "missing space rejected" "type one of" "$(message_result <<< "feat:add x")"
    check "empty subject rejected" "type one of" "$(message_result <<< "feat: ")"
    check "empty message rejected" "type one of" "$(message_result <<< "")"
    check "long subject rejected" "73 characters" "$(message_result <<< "feat: $(repeat a 67)")"
    check "trailing period rejected" "period" "$(message_result <<< "fix: handle empty ids.")"
    check "body without blank line rejected" "blank line" "$(message_result <<< $'feat: add x\nmore text')"
    check "long body rejected" "801 characters" "$(message_result <<< $'feat: add x\n\n'"$(repeat b 801)")"

    check "format-only allows a long body" "ACCEPTED" \
        "$(message_result --format-only <<< $'ci(deps): bump actions/checkout from 7 to 8\n\n'"$(repeat c 2000)")"
    check "format-only still needs a type" "type one of" "$(message_result --format-only <<< "Bump actions/checkout from 7 to 8")"
}

function test_commits {
    local -a GIT=(git -C "${TEST_REPO}" -c user.name=Test -c user.email=test@example.com -c commit.gpgsign=false)
    "${GIT[@]}" init -q
    "${GIT[@]}" commit -q --allow-empty -m "chore: initial commit"
    local BASE
    BASE="$("${GIT[@]}" rev-parse HEAD)"
    "${GIT[@]}" commit -q --allow-empty -m "feat: add x"
    "${GIT[@]}" commit -q --allow-empty -m "ci(deps): bump x from 1 to 2" -m "$(repeat d 2000)" \
        --author="dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com>"

    check "good range passes" "follow the format" \
        "$(cd "${TEST_REPO}" && "${TEST_BASH}" "${COMMITS_CHECK}" "${BASE}" HEAD 2>&1)"

    "${GIT[@]}" commit -q --allow-empty -m "wip"
    local OUTPUT
    OUTPUT="$(cd "${TEST_REPO}" && "${TEST_BASH}" "${COMMITS_CHECK}" "${BASE}" HEAD 2>&1; echo "exit=$?")"
    check "bad commit named" "wip" "${OUTPUT}"
    check "bad commit fails the range" "exit=1" "${OUTPUT}"
    check "unknown base fails" "exit=1" \
        "$(cd "${TEST_REPO}" && "${TEST_BASH}" "${COMMITS_CHECK}" no-such-ref HEAD > /dev/null 2>&1; echo "exit=$?")"
    check "new branch checks only the head" "exit=1" \
        "$(cd "${TEST_REPO}" && "${TEST_BASH}" "${COMMITS_CHECK}" 0000000000000000000000000000000000000000 HEAD > /dev/null 2>&1; echo "exit=$?")"
}

function main {
    # Single quotes on purpose: the bash under test expands it.
    # shellcheck disable=SC2016
    echo "Running with $("${TEST_BASH}" -c 'echo "bash ${BASH_VERSION}"')"
    test_guard
    test_delegation
    test_state
    test_commit_message
    test_commits
    echo
    echo "${PASSED} passed, ${FAILED} failed"
    [[ "${FAILED}" -eq 0 ]]
}

main "$@"
