#!/bin/bash
# ~/.config/yazi/scripts/ouch-extract.sh

FILE="$1"
EXT="${FILE##*.}"
EXT_LOWER="${EXT,,}"

ask_password() {
    printf "Password para '%s': " "$(basename "$FILE")"
    read -rs PASS
    echo
    echo "$PASS"
}

extract_with_password() {
    local PASS="$1"
    case "$EXT_LOWER" in
    rar)
        unrar x -p"$PASS" -y "$FILE"
        ;;
    zip)
        unzip -P "$PASS" "$FILE"
        ;;
    7z)
        7z x -p"$PASS" "$FILE"
        ;;
    tar | gz | bz2 | xz | zst | tgz | tbz2 | txz)
        bsdtar -xf "$FILE" --passphrase "$PASS"
        ;;
    *)
        7z x -p"$PASS" "$FILE"
        ;;
    esac
}

# Intenta sin password con timeout de 5s
OUTPUT=$(timeout 5s ouch decompress -y "$FILE" 2>&1)
EXIT=$?

# timeout devuelve 124 si se agotó el tiempo
if echo "$OUTPUT" | grep -qi "MissingPassword\|WrongPassword\|password\|encrypted" || [ $EXIT -eq 124 ]; then
    PASS=$(ask_password)
    extract_with_password "$PASS"
else
    echo "$OUTPUT"
fi
