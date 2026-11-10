# Command-not-found: name the package that provides the binary.
# Needs the pacman files database (`sudo pacman -Fy`, refreshed weekly by
# pacman-filesdb-refresh.timer when enabled).
command_not_found_handler() {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf "${green}zsh${reset}: command ${purple}not${reset} found: ${bright}%s${reset}\n" "$1" >&2

    local -a pkgs
    pkgs=(${(f)"$(pacman -Fq -- "/usr/bin/$1" 2>/dev/null)"})
    if ((${#pkgs})); then
        printf "${bright}%s${reset} is provided by:\n" "$1" >&2
        printf "  ${green}%s${reset}\n" "${pkgs[@]}" >&2
    else
        printf "no package provides it.\n" >&2
    fi
    return 127
}
