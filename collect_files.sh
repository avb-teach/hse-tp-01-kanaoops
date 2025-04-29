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
                echo "Error: Invalid --max_depth value" >&2
                exit 1
            fi
            ;;
        *)
            if [[ -z "$input_dir" ]]; then
                input_dir=$(realpath -s "$1")
            else
                output_dir=$(realpath -s "$1")
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
    echo "Error: Input directory not found" >&2
    exit 1
fi

mkdir -p "$output_dir"

generate_name() {
    local path="$1"
    local dir=$(dirname "$path")
    local filename=$(basename "$path")
    local base="${filename%.*}"
    local ext="${filename##*.}"
    local counter=1
    local candidate="$filename"

    while [[ -e "$output_dir/$dir/$candidate" ]]; do
        if [[ "$base" != "$filename" ]]; then
            candidate="${base}${counter}.${ext}"
        else
            candidate="${filename}${counter}"
        fi
        ((counter++))
    done

    echo "$candidate"
}

input_depth=$(echo "$input_dir" | tr '/' '\n' | wc -l)

find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
    file_depth=$(echo "$file" | tr '/' '\n' | wc -l)
    relative_depth=$((file_depth - input_depth))

    if [[ -n "$max_depth" && $relative_depth -gt "$max_depth" ]]; then
        continue
    fi

    rel_path=$(realpath --relative-to="$input_dir" "$file")
    target_dir="$output_dir/$(dirname "$rel_path")"
    
    mkdir -p "$target_dir"
    unique_name=$(generate_name "$rel_path")
    
    cp -- "$file" "$target_dir/$unique_name" 2>/dev/null
done

exit 0
