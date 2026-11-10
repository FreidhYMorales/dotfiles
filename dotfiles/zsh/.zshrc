# Interactive zsh entry point. Environment-only settings live in .zshenv.
# Load order matters: core (compinit) -> fzf-tab -> modules/prompt ->
# autosuggestions -> syntax-highlighting (must be last).

ZSH_CONFIG="$HOME/.config/zsh"
ZSH_PLUGINS_SYS=/usr/share/zsh/plugins
ZSH_PLUGINS_USER="$HOME/.local/share/zsh/plugins"

source "$ZSH_CONFIG/core.zsh"

# fzf-tab: must load after compinit and before widget-wrapping plugins.
[[ -r $ZSH_PLUGINS_USER/fzf-tab/fzf-tab.plugin.zsh ]] &&
    source "$ZSH_PLUGINS_USER/fzf-tab/fzf-tab.plugin.zsh"

source "$ZSH_CONFIG/terminal.zsh"
source "$ZSH_CONFIG/prompt.zsh"
source "$ZSH_CONFIG/user.zsh"

# PATH: unique entries only (installers keep appending their own lines here;
# fold them into this array instead).
typeset -U path
path=("$HOME/.local/bin" "$HOME/.opencode/bin" $path "$HOME/.spicetify")
export LIBVIRT_DEFAULT_URI="qemu:///system"

[[ -r $ZSH_PLUGINS_SYS/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source "$ZSH_PLUGINS_SYS/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r $ZSH_PLUGINS_SYS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
    source "$ZSH_PLUGINS_SYS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
