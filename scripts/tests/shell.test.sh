#!/usr/bin/env bash
# Integration tests for the zsh + starship config (story 01).
# Runs real zsh shells in a clean environment against the stowed dotfiles.
# Usage: scripts/tests/shell.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

FUNCTIONS_DIR="$HOME/.config/zsh/functions"
failures=0

# Clean environment so inherited PATH/vars from the caller don't mask bugs.
zsh_clean() {
    env -i HOME="$HOME" USER="$USER" TERM=xterm-256color \
        PATH=/usr/local/bin:/usr/bin zsh "$@"
}

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

test_modules_load_once_and_path_has_no_duplicates() {
    local trace file count
    trace=$(zsh_clean -i -x -c exit 2>&1)
    for file in "$FUNCTIONS_DIR"/*.zsh; do
        count=$(grep -cE "^\+[^ ]*> (source|\.) \"?${file}\"?\$" <<<"$trace")
        assert_eq "$(basename "$file") sourced once" 1 "$count"
    done
    local path_out
    # shellcheck disable=SC2016 # $path expands inside zsh, not bash
    path_out=$(zsh_clean -i -c 'print -l $path' 2>/dev/null)
    assert_eq "HOME/.local/bin appears once in PATH" 1 "$(grep -cx "$HOME/.local/bin" <<<"$path_out")"
    assert_eq "no duplicated PATH entries" "" "$(sort <<<"$path_out" | uniq -d)"
}

test_plugins_load_without_oh_my_zsh() {
    local out
    # shellcheck disable=SC2016 # expansions happen inside zsh
    out=$(zsh_clean -i -c '
        print "omz=$(( ${+functions[omz]} ))"
        print "autosuggest=$(( ${+functions[_zsh_autosuggest_start]} ))"
        print "highlight=$(( ${+functions[_zsh_highlight]} ))"
        print "fzftab=$(( ${+widgets[fzf-tab-complete]} ))"
    ' 2>/dev/null)
    assert_eq "oh-my-zsh not loaded" "omz=0" "$(grep '^omz=' <<<"$out")"
    # zsh-256color unsets its own functions after running; detect it by its source line.
    assert_eq "zsh-256color not loaded" 0 \
        "$(zsh_clean -i -x -c exit 2>&1 | grep -c 'zsh-256color.plugin.zsh')"
    assert_eq "autosuggestions active" "autosuggest=1" "$(grep '^autosuggest=' <<<"$out")"
    assert_eq "syntax-highlighting active" "highlight=1" "$(grep '^highlight=' <<<"$out")"
    assert_eq "fzf-tab active" "fzftab=1" "$(grep '^fzftab=' <<<"$out")"
}

test_non_interactive_shell_loads_no_interactive_config() {
    local out
    # shellcheck disable=SC2016 # expansions happen inside zsh
    out=$(zsh_clean -c '
        print "aliases=${#aliases}"
        print "starship=$(( ${+functions[starship_precmd]} ))"
        print "atuin=$(( ${+functions[_atuin_precmd]} ))"
    ' 2>&1)
    # zsh itself defines run-help/which-command; compare against a config-less shell.
    local builtin_aliases
    # shellcheck disable=SC2016
    builtin_aliases=$(zsh_clean -f -c 'print "aliases=${#aliases}"')
    assert_eq "no config aliases in zsh -c" "$builtin_aliases" "$(grep '^aliases=' <<<"$out")"
    assert_eq "no starship hook in zsh -c" "starship=0" "$(grep '^starship=' <<<"$out")"
    assert_eq "no atuin hook in zsh -c" "atuin=0" "$(grep '^atuin=' <<<"$out")"
    # Companion: the interactive shell does get them.
    # shellcheck disable=SC2016
    out=$(zsh_clean -i -c 'print "aliases=$(( ${#aliases} > 0 ))"' 2>/dev/null)
    assert_eq "aliases present in zsh -i" "aliases=1" "$(grep '^aliases=' <<<"$out")"
}

test_command_not_found_suggests_package() {
    local out status
    # cowsay is not installed but extra/cowsay provides /usr/bin/cowsay.
    out=$(zsh_clean -i -c 'cowsay' 2>&1)
    status=$?
    assert_eq "missing command exits 127" 127 "$status"
    assert_eq "suggests extra/cowsay" 1 "$(grep -c 'extra/cowsay' <<<"$out")"
    # Triangulation: a name no package provides.
    out=$(zsh_clean -i -c 'zzqx-no-such-cmd' 2>&1)
    status=$?
    assert_eq "unknown command exits 127" 127 "$status"
    assert_eq "says no package provides it" 1 "$(grep -c 'no package provides it' <<<"$out")"
}

test_sudo_widget_and_git_aliases() {
    local out
    # shellcheck disable=SC2016 # expansions happen inside zsh
    out=$(zsh_clean -i -c '
        print "bind=$(bindkey "\e\e")"
        BUFFER="pacman -Syu"; sudo-command-line; print "add=$BUFFER"
        BUFFER="sudo pacman -Syu"; sudo-command-line; print "remove=$BUFFER"
        print "gs=${aliases[gs]}"
        print "gsw=${aliases[gsw]}"
        print "glog=${aliases[glog]}"
    ' 2>/dev/null)
    assert_eq "Esc Esc bound to sudo widget" '"^[^[" sudo-command-line' "$(grep '^bind=' <<<"$out" | cut -d= -f2-)"
    assert_eq "widget prepends sudo" "add=sudo pacman -Syu" "$(grep '^add=' <<<"$out")"
    assert_eq "widget removes sudo" "remove=pacman -Syu" "$(grep '^remove=' <<<"$out")"
    assert_eq "gs alias" "gs=git status -sb" "$(grep '^gs=' <<<"$out")"
    assert_eq "gsw alias" "gsw=git switch" "$(grep '^gsw=' <<<"$out")"
    assert_eq "glog alias" "glog=git log --oneline --graph --decorate" "$(grep '^glog=' <<<"$out")"
}

test_starship_follows_terminal_palette() {
    local cfg="$HOME/.config/starship/starship.toml"
    # Colors must be ANSI names so kitty's matugen palette drives them.
    assert_eq "no hex colors in starship.toml" 0 \
        "$(grep -v '^\s*#' "$cfg" | grep -cE '#[0-9a-fA-F]{6}')"
    # Right prompt lists only the toolchains installed on this machine, once each.
    local right
    right=$(python3 -I -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["right_format"].replace("\n", ""))' "$cfg")
    # shellcheck disable=SC2016 # literal starship module names
    assert_eq "right_format modules" \
        '$c$cpp$golang$java$lua$nodejs$deno$python$rust$cmd_duration$status$time' "$right"
    # No cloud/infra noise in a plain directory.
    assert_eq "no gcloud segment in home" 0 \
        "$(cd "$HOME" && starship prompt --right 2>/dev/null | grep -c gcloud)"
}

main() {
    local tests=("$@")
    if ((${#tests[@]} == 0)); then
        mapfile -t tests < <(declare -F | awk '{print $3}' | grep '^test_')
    fi
    local t
    for t in "${tests[@]}"; do
        printf '%s\n' "$t"
        "$t"
    done
    if ((failures > 0)); then
        printf '\n%d assertion(s) failed\n' "$failures"
        exit 1
    fi
    printf '\nall passed\n'
}

main "$@"
