if [ $# -ne 2 ]; then
    echo "Usage: $0 dir malicious_dir" >&2
    exit 1
fi

DIR="$1"
MAL_DIR="$2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WHITELIST="$SCRIPT_DIR/whitelist.txt"

[ -d "$DIR" ] || { echo "Error: $DIR is not a directory" >&2; exit 1; }
[ -d "$MAL_DIR" ] || { echo "No malicious files to review."; exit 0; }
touch "$WHITELIST"

while true; do
    files=()
    for f in "$MAL_DIR"/*; do
        [ -f "$f" ] && files+=("$(basename "$f")")
    done

    if [ ${#files[@]} -eq 0 ]; then
        echo "No malicious files to review."
        exit 0
    fi

    echo
    echo "Files in quarantine ($MAL_DIR):"
    for i in "${!files[@]}"; do
        echo "  $((i+1))) ${files[$i]}"
    done
    read -r -p "Pick a file by number (q to quit): " choice || exit 0
    [ "$choice" = "q" ] && exit 0
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#files[@]} ]; then
        echo "Invalid choice."
        continue
    fi
    file="${files[$((choice-1))]}"

    echo "Selected: $file"
    echo "  1) Restore this file back into $DIR (false positive)"
    echo "  2) Permanently delete this file (genuinely malicious)"
    echo "  3) Leave this file as-is and go back to the list"
    read -r -p "Option: " opt || exit 0
    case "$opt" in
        1)
            mv -- "$MAL_DIR/$file" "$DIR/$file"
            grep -qxF -- "$file" "$WHITELIST" || echo "$file" >> "$WHITELIST"
            echo "Restored $file to $DIR."
            ;;
        2)
            rm -- "$MAL_DIR/$file"
            echo "$file permanently deleted."
            ;;
        3) ;;
        *) echo "Invalid option." ;;
    esac
done
