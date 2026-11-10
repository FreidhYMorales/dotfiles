# fzf helpers. fd/rg respect .gitignore and skip hidden VCS dirs.
# History search is atuin's job (Ctrl-R); there is no fzf history helper here.

_ff_opts=(--height 80% --layout=reverse --cycle --preview-window right:60%)

# ffcd [query]: fuzzy cd into a subdirectory
_fuzzy_change_directory() {
    local dir
    dir=$(fd --type d --hidden --exclude .git --max-depth 7 |
        fzf "${_ff_opts[@]}" --preview 'eza -1 --icons=always --color=always {}' ${1:+--query="$1"}) &&
        builtin cd -- "$dir"
}

# ffe [query]: fuzzy pick a file and open it in $EDITOR
_fuzzy_edit_search_file() {
    local file
    file=$(fd --type f --hidden --exclude .git --max-depth 5 |
        fzf "${_ff_opts[@]}" --preview 'bat --color=always --style=plain {}' ${1:+--query="$1"}) &&
        "$EDITOR" "$file"
}

# ffec <pattern>: pick among files whose content matches, open in $EDITOR
_fuzzy_edit_search_file_content() {
    local file
    file=$(rg --files-with-matches --ignore-case --hidden --glob '!.git' -- "${1:-.}" |
        fzf "${_ff_opts[@]}" --preview "rg --color=always --ignore-case --context 3 -- ${(q)1:-.} {}") &&
        "$EDITOR" "$file"
}

alias ffcd='_fuzzy_change_directory' \
    ffe='_fuzzy_edit_search_file' \
    ffec='_fuzzy_edit_search_file_content'
