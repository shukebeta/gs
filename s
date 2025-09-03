#!/bin/bash

set -uo pipefail

# Load function library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/gs_functions.sh"

show_usage() {
    echo "Usage: s <search_pattern> <replacement> <directory> [options]"
    echo "Replace search_pattern with replacement in files (supports full regex)"
    echo ""
    echo "Options:"
    echo "  -i, --ignore-case    Case insensitive search"
    echo "  -w, --word-regexp    Match whole words only"
    echo "  --dry-run           Show what would be changed without making changes"
    echo "  --no-ignore         Don't use .gitignore"
    echo ""
    echo "Regex Examples:"
    echo "  # Convert function declarations to arrow functions"
    echo "  s 'function (\\w+)\\((.*?)\\)' 'const \$1 = (\$2) =>' src/"
    echo ""
    echo "  # Update import statements"
    echo "  s \"import (.*) from ['\\\"](.+)['\\\"]\" 'import \$1 from \"\$2.js\"' src/"
    echo ""
    echo "  # Convert var to const with word boundaries"
    echo "  s '\\bvar\\b' 'const' src/"
    echo ""
    echo "  # Reformat dates from YYYY-MM-DD to DD/MM/YYYY"
    echo "  s '(\\d{4})-(\\d{2})-(\\d{2})' '\$3/\$2/\$1' data/"
    echo ""
    echo "WARNING: Always use --dry-run first to preview changes!"
}

# Parse arguments
PATTERN=""
REPLACEMENT=""
TARGET=""
DRY_RUN=false
EXTRA_RG_OPTS=()

parse_args() {
    if [[ $# -lt 3 ]]; then
        show_usage
        exit 1
    fi

    PATTERN="$1"
    REPLACEMENT="$2"
    TARGET="$3"
    shift 3

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--ignore-case)
                EXTRA_RG_OPTS+=("--ignore-case")
                ;;
            -w|--word-regexp)
                EXTRA_RG_OPTS+=("--word-regexp")
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --no-ignore)
                EXTRA_RG_OPTS+=("--no-ignore")
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
        shift
    done
}

# Validate inputs
validate_inputs() {
    if [[ -z "$PATTERN" ]]; then
        echo "Error: Pattern cannot be empty" >&2
        exit 1
    fi

    if [[ -z "$REPLACEMENT" ]]; then
        echo "Error: Replacement cannot be empty" >&2
        exit 1
    fi

    if [[ ! -d "$TARGET" && ! -f "$TARGET" ]]; then
        echo "Error: File or directory.*does not exist" >&2
        exit 1
    fi
}

# Main replace function
do_replace() {
    # Get list of files containing the pattern
    local files
    files=$(rg_find_files "$PATTERN" "$TARGET" "${EXTRA_RG_OPTS[@]}")
    local exit_code=$?

    handle_rg_exit_code $exit_code "$PATTERN" "file search"
    local handle_exit=$?

    if [[ $handle_exit -ne 0 ]]; then
        exit $handle_exit
    fi

    local file_count
    file_count=$(echo "$files" | wc -l)

    echo "Found pattern in $file_count file(s):"
    echo "$files"
    echo

    # Normalize paths for Git Bash compatibility
    files=$(normalize_path "$files")

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN - showing changes that would be made:"
        echo
        local total_files_changed=0
        while IFS= read -r file; do
            if [[ -f "$file" ]]; then
                echo "File: $file"
                # Generate preview using the same mechanism as actual replacement
                local preview_content
                preview_content=$(rg_get_preview "$PATTERN" "$REPLACEMENT" "$file" "${EXTRA_RG_OPTS[@]}")
                local rg_exit=$?
                
                # Check if there would be changes
                if [[ $rg_exit -eq 0 ]] || [[ $rg_exit -eq 1 ]]; then
                    if ! diff -q "$file" <(echo "$preview_content") >/dev/null 2>&1; then
                        # Show line-by-line diff in a clean format
                        diff --unified=0 "$file" <(echo "$preview_content") | tail -n +4 | sed 's/^-/  -/;s/^+/  +/'
                        ((total_files_changed++))
                    else
                        echo "  (no changes in this file)"
                    fi
                else
                    echo "  (error previewing changes)"
                fi
                echo
            fi
        done <<< "$files"
        echo "Summary: $total_files_changed of $file_count files would change"
        return 0
    fi

    # Perform actual replacement
    local success_count=0
    local error_count=0

    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            if safe_replace_file "$file" "$PATTERN" "$REPLACEMENT" "${EXTRA_RG_OPTS[@]}"; then
                echo "✓ Updated: $file"
                success_count=$((success_count + 1))
            else
                echo "✗ Failed: $file" >&2
                error_count=$((error_count + 1))
            fi
        fi
    done <<< "$files"

    echo
    echo "Replacement completed: $success_count successful, $error_count failed"

    if [[ $error_count -gt 0 ]]; then
        exit 1
    fi
}

# Main execution
main() {
    parse_args "$@"
    validate_inputs
    do_replace
}

main "$@"