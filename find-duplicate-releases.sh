#!/usr/bin/env bash
set -euo pipefail

if (( $# < 1 || $# > 2 )); then
    printf 'Usage: %s ROOT_DIRECTORY [--remove-empty]\n' "${0##*/}" >&2
    exit 2
fi

remove_empty=false
if (( $# == 2 )); then
    case $2 in
        remove-empty|--remove-empty) remove_empty=true ;;
        *)
            printf 'Usage: %s ROOT_DIRECTORY [--remove-empty]\n' "${0##*/}" >&2
            exit 2
            ;;
    esac
fi

if [[ ! -d $1 ]]; then
    printf 'Error: directory does not exist: %s\n' "$1" >&2
    exit 1
fi

# Resolve the root so every reported path is absolute.
root=$(cd -- "$1" && pwd -P)

if [[ $remove_empty == true ]]; then
    # Visit children first so parents emptied by deletions are removed too.
    # For ZIP files, empty means a zero-byte file.
    find "$root" -mindepth 1 -depth \
        \( \( -type f -iname '*.zip' -empty \) -o \( -type d -empty \) \) -delete
fi

tmp=$(mktemp)
trap 'rm -f -- "$tmp"' EXIT

# Include every subdirectory and regular ZIP file, at any depth.
find "$root" -mindepth 1 \( -type d -o \( -type f -iname '*.zip' \) \) -print0 > "$tmp"

declare -A counts=() group_indices=() types=()
paths=()

while IFS= read -r -d '' path; do
    base=${path##*/}
    if [[ -d $path ]]; then
        name=$base
        types["$path"]=DIR
    else
        name=${base:0:${#base}-4}
        types["$path"]=ZIP
    fi

    # Prefix the key because Bash associative arrays do not accept empty keys.
    key="x$name"
    index=${#paths[@]}
    paths+=("$path")
    counts["$key"]=$(( ${counts["$key"]:-0} + 1 ))
    group_indices["$key"]+="$index "
done < "$tmp"

(( ${#paths[@]} > 0 )) || exit 0

# NUL delimiters keep spaces and other special characters intact while sorting.
while IFS= read -r -d '' key; do
    (( ${counts["$key"]} >= 2 )) || continue
    printf '%s\n' "${key:1}"

    read -r -a indices <<< "${group_indices["$key"]}"
    group_paths=()
    for index in "${indices[@]}"; do
        group_paths+=("${paths[index]}")
    done

    while IFS= read -r -d '' path; do
        # Apparent size includes a directory's contents and the ZIP's file size.
        size_line=$(du -sh --apparent-size -- "$path")
        size=${size_line%%$'\t'*}
        printf '  [%s] %s %s\n' "${types["$path"]}" "$size" "$path"
    done < <(printf '%s\0' "${group_paths[@]}" | sort -z)
done < <(printf '%s\0' "${!counts[@]}" | sort -z)
