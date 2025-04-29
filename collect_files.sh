#!/bin/bash

input_dir=""
output_dir=""
max_depth=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            max_depth="$2"
            shift 2
            ;;
        *)
            if [[ -z "$input_dir" ]]; then
                input_dir="$1"
            else
                output_dir="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$input_dir" || -z "$output_dir" ]]; then
    echo "Usage: $0 [--max_depth N] input_dir output_dir" >&2
    exit 1
fi

if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory '$input_dir' does not exist" >&2
    exit 1
fi

mkdir -p "$output_dir"

generate_name() {
    local base="${1%.*}"
    local ext="${1##*.}"
    local counter=1
    local candidate="$1"

    while [[ -e "$output_dir/$candidate" ]]; do
        if [[ "$base" != "$1" ]]; then
            candidate="${base}_${counter}.${ext}"
        else
            candidate="${1}_${counter}"
        fi
        ((counter++))
    done

    echo "$candidate"
}

find_args=("$input_dir" -type f)
[[ -n "$max_depth" ]] && find_args+=(-maxdepth "$max_depth")

while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    unique_name=$(generate_name "$filename")
    cp -- "$file" "$output_dir/$unique_name"
done < <(find "${find_args[@]}" -print0)

echo "Files copied successfully to: $output_dir"
