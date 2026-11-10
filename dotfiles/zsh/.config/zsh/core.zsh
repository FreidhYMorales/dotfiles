#!/usr/bin/env zsh
# Core interactive behaviour that oh-my-zsh used to provide:
# history, key bindings and completion. Sourced from .zshrc before plugins.

# --- History -------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt extended_history       # timestamps in HISTFILE
setopt hist_expire_dups_first # trim duplicates first when the file is full
setopt hist_ignore_dups       # no consecutive duplicates
setopt hist_ignore_space      # " cmd" stays out of history
setopt hist_verify            # !! expands into the buffer instead of running
setopt share_history          # live history across open terminals

# --- Misc ----------------------------------------------------------------
setopt interactive_comments multios long_list_jobs
setopt auto_cd auto_pushd pushd_ignore_dups pushdminus

# --- Key bindings (emacs mode) ------------------------------------------
bindkey -e
zmodload zsh/terminfo
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search   # Up: prefix history search
bindkey '^[[B' down-line-or-beginning-search # Down
[[ -n ${terminfo[kcuu1]} ]] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
[[ -n ${terminfo[kcud1]} ]] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
[[ -n ${terminfo[khome]} ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n ${terminfo[kend]} ]] && bindkey "${terminfo[kend]}" end-of-line
[[ -n ${terminfo[kdch1]} ]] && bindkey "${terminfo[kdch1]}" delete-char
[[ -n ${terminfo[kcbt]} ]] && bindkey "${terminfo[kcbt]}" reverse-menu-complete
bindkey '^[[1;5C' forward-word  # Ctrl+Right
bindkey '^[[1;5D' backward-word # Ctrl+Left
bindkey '^H' backward-kill-word # Ctrl+Backspace

# --- Completion ----------------------------------------------------------
zmodload zsh/complist
setopt complete_in_word always_to_end
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
zstyle ':completion:*:descriptions' format '[%d]' # group headers for fzf-tab

# compinit with a cached dump: full security check at most once a day.
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d ${_zcompdump:h} ]] || mkdir -p "${_zcompdump:h}"
if [[ -n ${_zcompdump}(#qN.mh+24) ]]; then
    compinit -d "$_zcompdump"
else
    compinit -C -d "$_zcompdump"
fi
unset _zcompdump
