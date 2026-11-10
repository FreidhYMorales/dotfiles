#!/usr/bin/env zsh
# Personal interactive bits: startup banner and small helpers.

# fastfetch only in the first kitty terminal of the login session
# (marker lives in XDG_RUNTIME_DIR, wiped on logout). Run `ff` any time.
if [[ $TERM == xterm-kitty && -n $XDG_RUNTIME_DIR ]] && (( $+commands[fastfetch] )); then
    if [[ ! -e $XDG_RUNTIME_DIR/zsh-fastfetch-shown ]]; then
        : >"$XDG_RUNTIME_DIR/zsh-fastfetch-shown"
        fastfetch --logo-type kitty
    fi
fi

# y: yazi that cd's into the directory you quit in.
y() {
    local tmp cwd
    tmp=$(mktemp -t yazi-cwd.XXXXXX)
    yazi "$@" --cwd-file="$tmp"
    if cwd=$(<"$tmp") && [[ -n $cwd && $cwd != "$PWD" ]]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
