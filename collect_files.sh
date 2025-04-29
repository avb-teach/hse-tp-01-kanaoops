#!/bin/bash

input_dir=""
output_dir=""
max_depth=""
valid_args=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                max_depth="$2"
                shift 2
            else
                echo "Error: --max_depth requires a positive integer" >&2
                valid_args=0
                break
            fi
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

if [[ $valid_args -ne 1 || -z "$input_dir" || -z "$output_dir" ]]; then
    echo "Usage: $0 [--max_depth N] input_dir output_dir" >&2
    exit 1
fi

if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory '$input_dir' does not exist" >&2
    exit 1
fi

mkdir -p "$output_dir"

generate_name() {
    local filename="$1"
    local base="${filename%.*}"
    local ext="${filename##*.}"
    local counter=1
    local candidate="$filename"

    while [[ -e "$output_dir/$candidate" ]]; do
        if [[ "$base" != "$filename" ]]; then
            candidate="${base}_${counter}.${ext}"
        else
            candidate="${filename}_${counter}"
        fi
        ((counter++))
    done

    echo "$candidate"
}

find_args=("$input_dir" -type f)
if [[ -n "$max_depth" ]]; then
    find_args+=(-mindepth 1 -maxdepth "$max_depth")
fi

while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    unique_name=$(generate_name "$filename")
    cp -- "$file" "$output_dir/$unique_name"
done < <(find "${find_args[@]}" -print0 2>/dev/null)

echo "Files copied successfully to: $output_dir"
