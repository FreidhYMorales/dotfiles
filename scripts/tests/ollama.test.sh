#!/usr/bin/env bash
# Tests for the Ollama setup (story 11): the service drop-ins the repo ships
# and bootstrap installs, and the doc that names where models live. The live_*
# tests compare the repo with this machine.
# Usage: scripts/tests/ollama.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
BOOTSTRAP="${BOOTSTRAP:-$ROOT/dotfiles/bootstrap.sh}"
REPO_DROPINS="$ROOT/system/systemd/ollama.service.d"
LIVE_DROPINS="${LIVE_DROPINS:-/etc/systemd/system/ollama.service.d}"
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

test_bootstrap_installs_dropins() {
    # The download tweak (one transfer stream, so a model pull does not
    # saturate the Wi-Fi) lives in the repo and bootstrap copies it in place.
    assert_eq "repo download.conf limits pulls to one stream" \
        'Environment="OLLAMA_MAX_TRANSFER_STREAMS=1"' \
        "$(grep -h '^Environment=' "$REPO_DROPINS/download.conf" 2>/dev/null || echo missing)"
    assert_eq "bootstrap copies the repo drop-ins to $LIVE_DROPINS" yes \
        "$(grep -v '^\s*#' "$BOOTSTRAP" | grep -cE "cp .*system/systemd/ollama\.service\.d/.* $LIVE_DROPINS" |
            awk '{print ($1 > 0) ? "yes" : "no"}')"
}

all_tests=(test_bootstrap_installs_dropins)
for t in "${@:-${all_tests[@]}}"; do
    echo "$t"
    "$t"
done
((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
