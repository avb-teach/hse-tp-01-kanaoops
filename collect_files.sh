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
                input_dir=$(realpath -s "$1")
            else
                output_dir=$(realpath -s "$1")
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
    local path="$1"
    local dir=$(dirname "$path")
    local filename=$(basename "$path")
    local base="${filename%.*}"
    local ext="${filename##*.}"
    local counter=1
    local candidate="$filename"

    while [[ -e "$output_dir/$dir/$candidate" ]]; do
        if [[ "$base" != "$filename" ]]; then
            candidate="${base}_${counter}.${ext}"
        else
            candidate="${filename}_${counter}"
        fi
        ((counter++))
    done

    echo "$candidate"
}

if [[ -n "$max_depth" ]]; then
    base_depth=$(find "$input_dir" -type d | awk -F/ '{print NF}' | sort -nu | head -n1)
    max_depth=$((base_depth + max_depth - 1))
fi

find "$input_dir" -type f | while read -r file; do
    file_depth=$(echo "$file" | awk -F/ '{print NF}')
    
    if [[ -n "$max_depth" && $file_depth -gt $max_depth ]]; then
        continue
    fi

    rel_path=$(realpath --relative-to="$input_dir" "$file")
    target_dir="$output_dir/$(dirname "$rel_path")"
    
    mkdir -p "$target_dir"
    
    filename=$(basename "$file")
    unique_name=$(generate_name "$rel_path")
    
    cp -- "$file" "$target_dir/$unique_name"
done

echo "Files copied successfully to: $output_dir"
