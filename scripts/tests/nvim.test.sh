#!/usr/bin/env bash
# Integration tests for nvim editing keymaps and startup (story 03).
# Runs headless nvim against the stowed config.
# Usage: scripts/tests/nvim.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

# nvim_keys <line> <keys>: opens a buffer "a b c" (one per line), puts the
# cursor on <line>, feeds <keys> (termcodes allowed) and prints the buffer
# lines joined by "|", then "err=" with the last error message, if any.
nvim_keys() {
    local tmp out
    tmp=$(mktemp -d)
    printf 'a\nb\nc\n' >"$tmp/buf.txt"
    NVIM_TEST_LINE="$1" NVIM_TEST_KEYS="$2" NVIM_TEST_OUT="$tmp/out" \
        timeout 30 nvim --headless "$tmp/buf.txt" '+lua vim.defer_fn(function()
            vim.v.errmsg = ""
            vim.api.nvim_win_set_cursor(0, { tonumber(vim.env.NVIM_TEST_LINE), 0 })
            local keys = vim.api.nvim_replace_termcodes(vim.env.NVIM_TEST_KEYS, true, false, true)
            pcall(vim.api.nvim_feedkeys, keys, "x", false)
            local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "|")
            local err = vim.v.errmsg:gsub("%s+", " ")
            vim.fn.writefile({ text .. " err=" .. err }, vim.env.NVIM_TEST_OUT)
            vim.cmd("qa!")
        end, 1500)' >/dev/null 2>&1
    out=$(<"$tmp/out")
    rm -rf "$tmp"
    printf '%s' "$out"
}

test_move_down_at_last_line_stays_put() {
    assert_eq "Alt j on the last line leaves the buffer as is, no error" \
        "a|b|c err=" "$(nvim_keys 3 '<M-j>')"
}

tests=("$@")
if ((${#tests[@]} == 0)); then
    mapfile -t tests < <(declare -F | awk '{print $3}' | rg '^test_')
fi
for t in "${tests[@]}"; do "$t"; done
((failures == 0))
