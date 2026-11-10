#Alias config

alias c='clear'                                                        # clear terminal
alias l='eza -lh --icons=auto'                                         # long list
alias ls='eza -1 --icons=auto'                                         # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto'                                       # long list dirs
alias lt='eza --icons=auto --tree'                                     # list folder as tree
alias un='$aurhelper -Rns'                                             # uninstall package
alias up='$aurhelper -Syu'                                             # update system/package/aur
alias pl='$aurhelper -Qs'                                              # list installed package
alias pa='$aurhelper -Ss'                                              # list available package
alias pc='$aurhelper -Sc'                                              # remove unused cache
alias po='$aurhelper -Qtdq | $aurhelper -Rns -'                        # remove unused packages, also try > $aurhelper -Qqd | $aurhelper -Rsu --print -
alias n='nvim'                                                         # gui code editor
alias ff='fastfetch --logo-type kitty'                                 # fastfetch on demand
alias e='exit'                                                         # exit
alias music='ncmpcpp'                                                  # ncmpcpp music player cli (local music)

# Git (curated; history showed no use of the oh-my-zsh set)
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gds='git diff --staged'
alias gsw='git switch'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate'
