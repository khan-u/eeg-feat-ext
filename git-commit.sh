#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
LOG=".commit-log"

ENTRIES=()
if [ -f "$LOG" ]; then
    while IFS= read -r line; do
        [ -n "$line" ] && ENTRIES+=("$line")
    done < "$LOG"
fi

if [ ${#ENTRIES[@]} -eq 0 ]; then
    MSG="${1:-checkpoint}"
    git add .
    git commit --allow-empty -m "$MSG"
    echo "committed: $MSG"
    exit 0
fi

LAST=$(( ${#ENTRIES[@]} - 1 ))
for i in "${!ENTRIES[@]}"; do
    MSG="${ENTRIES[$i]}"
    if [ "$i" -eq "$LAST" ] && [ -n "$1" ]; then
        MSG="$1 — $MSG"
    fi
    git add .
    git commit --allow-empty -m "$MSG"
    echo "committed ($((i + 1))/${#ENTRIES[@]}): ${MSG:0:120}…"
done

: > "$LOG"
echo "log consumed (${#ENTRIES[@]} entries → ${#ENTRIES[@]} commits)"
