#!/usr/bin/env zsh
# Prompt and directory jumping. Init scripts are cached (see core.zsh).

export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
export STARSHIP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/starship"
_zsh_cached_init starship starship init zsh --print-full-init
_zsh_cached_init zoxide zoxide init zsh
