FLAGGED_EXTENSIONS=(.exe .bat .vbs .scr .ps1)
FLAGGED_KEYWORDS=(virus trojan malware worm ransomware)


if [ $# -ne 3 ]; then
    echo "Usage: $0 dir malicious_dir interval-secs" >&2
    exit 1
fi

DIR="$1"
MAL_DIR="$2"
INTERVAL="$3"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WHITELIST="$SCRIPT_DIR/whitelist.txt"
LAST="directory-info.last"
NEW="directory-info.new"

[ -d "$DIR" ] || { echo "Error: $DIR is not a directory" >&2; exit 1; }
case "$INTERVAL" in ''|*[!0-9]*) echo "Error: interval must be a positive integer" >&2; exit 1;; esac
mkdir -p "$MAL_DIR"
touch "$WHITELIST"

is_whitelisted() {
    grep -qxF -- "$1" "$WHITELIST"
}

is_malicious() {
    local file="$1" name ext kw
    name="$(basename "$file")"
    # Flagged extension
    if [[ "$name" == *.* ]]; then
        ext=".${name##*.}"
        ext="${ext,,}"
        for e in "${FLAGGED_EXTENSIONS[@]}"; do
            [ "$ext" = "$e" ] && return 0
        done
    fi
    # Flagged content (case-insensitive)
    for kw in "${FLAGGED_KEYWORDS[@]}"; do
        grep -qai -- "$kw" "$file" && return 0
    done
    return 1
}

scan() {
    local f name
    for f in "$DIR"/*; do
        [ -f "$f" ] || continue
        name="$(basename "$f")"
        is_whitelisted "$name" && continue
        if is_malicious "$f"; then
            echo "$name is malicious and it is DELETED"
            cp -- "$f" "$MAL_DIR/$name" && rm -- "$f"
        fi
    done
}


if [ ! -f "$LAST" ]; then
    scan
    ls -l "$DIR" > "$LAST"
fi

while true; do
    sleep "$INTERVAL"
    ls -l "$DIR" > "$NEW"
    if ! diff -q "$LAST" "$NEW" > /dev/null; then
        scan
        cp "$NEW" "$LAST"
    fi
done
