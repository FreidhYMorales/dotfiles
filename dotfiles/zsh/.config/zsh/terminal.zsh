#!/usr/bin/env zsh
# Interactive modules: every functions/*.zsh and completions/*.zsh file.

for _f in "$ZSH_CONFIG"/functions/*.zsh(N) "$ZSH_CONFIG"/completions/*.zsh(N); do
    source "$_f"
done
unset _f

# fzf --zsh also binds Ctrl-R; atuin owns history search.
(( $+widgets[atuin-search] )) && bindkey -M emacs '^r' atuin-search
