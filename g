#!/bin/bash

set -uo pipefail

# Load function library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/gs_functions.sh"

show_usage() {
    echo "Usage: g <pattern> [directory] [options]"
    echo "Search for pattern in files using ripgrep"
    echo ""
    echo "Options:"
    echo "  -i, --ignore-case    Case insensitive search"
    echo "  -w, --word-regexp    Match whole words only"
    echo "  -v, --invert-match   Invert match (show non-matching lines)"
    echo "  -A, --after N        Show N lines after match"
    echo "  -B, --before N       Show N lines before match"
    echo "  -C, --context N      Show N lines before and after match"
    echo "  --files              Show only filenames with matches"
    echo "  --no-ignore          Don't use .gitignore"
    echo ""
    echo "Examples:"
    echo "  g 'function.*Promise'           # Find async functions"
    echo "  g '\\bTODO\\b' src/             # Find TODO comments"
    echo "  g 'class.*extends.*Component'   # Find React class components"
}

# Parse arguments
PATTERN=""
TARGET="."
EXTRA_RG_OPTS=()

parse_args() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    PATTERN="$1"
    shift

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--ignore-case)
                EXTRA_RG_OPTS+=("--ignore-case")
                ;;
            -w|--word-regexp)
                EXTRA_RG_OPTS+=("--word-regexp")
                ;;
            -v|--invert-match)
                EXTRA_RG_OPTS+=("--invert-match")
                ;;
            -A|--after)
                shift
                if [[ $# -gt 0 ]]; then
                    EXTRA_RG_OPTS+=("--after-context" "$1")
                fi
                ;;
            -B|--before)
                shift
                if [[ $# -gt 0 ]]; then
                    EXTRA_RG_OPTS+=("--before-context" "$1")
                fi
                ;;
            -C|--context)
                shift
                if [[ $# -gt 0 ]]; then
                    EXTRA_RG_OPTS+=("--context" "$1")
                fi
                ;;
            --files)
                EXTRA_RG_OPTS+=("--files-with-matches")
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
            *)
                # Assume it's a directory
                TARGET="$1"
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

    if [[ ! -d "$TARGET" && ! -f "$TARGET" ]]; then
        echo "Error: File or directory.*does not exist" >&2
        exit 1
    fi
}

# Main search function
do_search() {
    rg_search_content "$PATTERN" "$TARGET" "${EXTRA_RG_OPTS[@]}"
    local exit_code=$?
    
    handle_rg_exit_code $exit_code "$PATTERN" "search"
    local handle_exit=$?
    
    if [[ $handle_exit -ne 0 ]]; then
        exit $handle_exit
    fi
}

# Main execution
main() {
    parse_args "$@"
    validate_inputs
    do_search
}

main "$@"