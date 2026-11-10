# Esc Esc: toggle "sudo " at the start of the command line.
# Empty line: recall the previous command with sudo (replaces OMZ's sudo plugin).
sudo-command-line() {
    [[ -z $BUFFER ]] && BUFFER=$(fc -ln -1 2>/dev/null)
    if [[ $BUFFER == sudo\ * ]]; then
        BUFFER=${BUFFER#sudo }
    else
        BUFFER="sudo $BUFFER"
    fi
    CURSOR=${#BUFFER}
}
zle -N sudo-command-line
bindkey -M emacs '\e\e' sudo-command-line
