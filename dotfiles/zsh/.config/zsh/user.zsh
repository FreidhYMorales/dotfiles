#  Startup 
# Commands to execute on startup (before the prompt is shown)
# Check if the interactive shell option is set
if [[ $- == *i* ]]; then
    # This is a good place to load graphic/ascii art, display system information, etc.
    if command -v pokego >/dev/null; then
        pokego --no-title -r 1,3,6
    elif command -v pokemon-colorscripts >/dev/null; then
        pokemon-colorscripts --no-title -r 1,3,6
    elif command -v fastfetch >/dev/null; then
        if do_render "image"; then
            fastfetch --logo-type kitty
        fi
    fi
fi

#Configuracion Yazi
function y() {
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    YAZI_CONFIG_HOME=/home/deadlock/.config/yazi \
        yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

if [[ $- == *i* ]] && [ -f "$HOME/.config/zsh/terminal.zsh" ]; then
    . "$HOME/.config/zsh/terminal.zsh" || echo "Error: Could not source $HOME/terminal.zsh"
fi

export aurhelper="yay"

export SUDO_EDITOR="nvim -u /home/$USER/.config/nvim/init.lua"
# O una alternativa más limpia si usas alias:
export EDITOR="nvim"

export XDG_CONFIG_HOME="$HOME/.config"

# Configuraciones man
# Para usar bat como visor:
# export MANPAGER="sh -c 'col -bx | bat -l man -p'"
# export MANROFFOPT="-c"
# Para usar neovim como visor:
export MANPAGER='nvim +Man!'
export MANWIDTH=100
# export $(dbus-launch)
# export SSH_AUTH_SOCK
# mysql-workbench
