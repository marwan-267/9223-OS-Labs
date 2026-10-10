FLAGGED_EXTENSIONS=(.exe .bat .vbs .scr .ps1)
FLAGGED_KEYWORDS=(virus trojan malware worm ransomware)

[ $# -eq 2 ] || { echo "Usage: $0 dir malicious_dir" >&2; exit 1; }

sleep 23  

DIR="$1"
MAL_DIR="$2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WHITELIST="$SCRIPT_DIR/whitelist.txt"
LAST="$SCRIPT_DIR/directory-info.cron.last"
NEW="$SCRIPT_DIR/directory-info.cron.new"

[ -d "$DIR" ] || exit 1
mkdir -p "$MAL_DIR"
touch "$WHITELIST"

is_malicious() {
    local name ext kw
    name="$(basename "$1")"
    if [[ "$name" == *.* ]]; then
        ext=".${name##*.}"; ext="${ext,,}"
        for e in "${FLAGGED_EXTENSIONS[@]}"; do [ "$ext" = "$e" ] && return 0; done
    fi
    for kw in "${FLAGGED_KEYWORDS[@]}"; do
        grep -qai -- "$kw" "$1" && return 0
    done
    return 1
}

scan() {
    local f name
    for f in "$DIR"/*; do
        [ -f "$f" ] || continue
        name="$(basename "$f")"
        grep -qxF -- "$name" "$WHITELIST" && continue
        if is_malicious "$f"; then
            echo "$name is malicious and it is DELETED"
            cp -- "$f" "$MAL_DIR/$name" && rm -- "$f"
        fi
    done
}

ls -l "$DIR" > "$NEW"
if [ ! -f "$LAST" ] || ! diff -q "$LAST" "$NEW" > /dev/null; then
    scan
    cp "$NEW" "$LAST"
fi
