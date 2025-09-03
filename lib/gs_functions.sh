#!bin/bash

# G/S Tools Function Library
# Core functions for search and replace operations

# Global exclusion patterns for ripgrep
readonly RG_DEFAULT_EXCLUDES=(
    "--glob" "!*.{min.js,min.css}"
    "--glob" "!*.{ttf,woff,woff2,eot}"
    "--glob" "!*.{jpg,jpeg,png,gif,bmp,ico,svg}"
    "--glob" "!*.{mp4,avi,mov,wmv,flv,webm}"
    "--glob" "!*.{pdf,doc,docx,xls,xlsx,ppt,pptx}"
    "--glob" "!*.{zip,tar,gz,rar,7z}"
    "--glob" "!*.map"
    "--glob" "!node_modules/**"
    "--glob" "!dist/**"
    "--glob" "!build/**"
    "--glob" "!.git/**"
    "--glob" "!.idea/**"
    "--glob" "!.vscode/**"
    "--glob" "!vendor/**"
    "--glob" "!public/**"
    "--glob" "!assets/**"
    "--glob" "!MathJax/**"
    "--glob" "!PHPExcel/**"
    "--glob" "!phpQuery/**"
    "--glob" "!PHPQRCode/**"
    "--glob" "!database/**"
    "--glob" "!Zend/**"
    "--glob" "!css/**"
)

# Path conversion for Git Bash compatibility
normalize_path() {
    local path="$1"
    echo "$path" | sed 's|\\|/|g'
}

# Escape dollar signs in replacement string for ripgrep
# Converts literal $VARIABLE to $$VARIABLE while preserving capture groups $1, $2, etc.
escape_replacement() {
    local replacement="$1"
    local pattern="${2:-}"
    
    # Check if pattern contains capture groups (parentheses that aren't escaped)
    local has_groups=false
    if [[ -n "$pattern" ]] && echo "$pattern" | grep -q '([^)]*)'  ; then
        has_groups=true
    fi
    
    if [[ "$has_groups" == "true" ]]; then
        # Pattern has capture groups - preserve $1, $2, etc., escape everything else
        echo "$replacement" | sed 's/\$\([^0-9{]\)/$$\1/g'
    else
        # Pattern has no capture groups - escape ALL dollars including $1, $2, etc.
        echo "$replacement" | sed 's/\$/$$/g'
    fi
}


# Search for content with line numbers (for display)
rg_search_content() {
    local pattern="$1"
    local directory="$2"
    shift 2
    local extra_opts=("$@")

    local base_opts=(
        "--line-number"
        "--no-heading"
        "--color=never"
    )

    rg "${extra_opts[@]}" "${base_opts[@]}" "${RG_DEFAULT_EXCLUDES[@]}" "$pattern" "$directory"
    local rg_exit=$?

    return $rg_exit
}

# Search for content in a single file (for dry-run display)
rg_search_file() {
    local pattern="$1"
    local file="$2"
    shift 2
    local extra_opts=("$@")

    local base_opts=(
        "--line-number"
        "--no-heading"
        "--color=never"
    )

    # Let caller handle exit codes - don't modify set -e behavior
    rg "${extra_opts[@]}" "${base_opts[@]}" "$pattern" "$file"
    local rg_exit=$?
    return $rg_exit
}

# Find files containing pattern (for replacement)
rg_find_files() {
    local pattern="$1"
    local directory="$2"
    shift 2
    local extra_opts=("$@")

    local base_opts=(
        "--files-with-matches"
        "--color=never"
    )

    # Let caller handle exit codes - don't modify set -e behavior
    rg "${extra_opts[@]}" "${base_opts[@]}" "${RG_DEFAULT_EXCLUDES[@]}" "$pattern" "$directory"
    local rg_exit=$?
    return $rg_exit
}

# Handle ripgrep exit codes consistently
handle_rg_exit_code() {
    local exit_code="$1"
    local pattern="$2"
    local operation="${3:-search}"

    case $exit_code in
        0)
            return 0  # Success
            ;;
        1)
            echo "No matches found for pattern: $pattern" >&2
            return 1
            ;;
        2)
            echo "Error running ripgrep during $operation" >&2
            return 2
            ;;
        *)
            echo "Unexpected ripgrep exit code: $exit_code" >&2
            return $exit_code
            ;;
    esac
}

# Generate preview of replacements using the same mechanism as safe_replace_file
rg_get_preview() {
    local pattern="$1"
    local replacement="$2"
    local file="$3"
    shift 3
    local extra_opts=("$@")

    # Use the same --passthru mechanism as safe_replace_file for consistency
    # Escape dollar signs to prevent shell variable expansion
    local escaped_replacement
    escaped_replacement=$(escape_replacement "$replacement" "$pattern")
    
    rg "${extra_opts[@]}" --replace "$escaped_replacement" --passthru --color=never "$pattern" "$file" 2>/dev/null
}

# Perform safe file replacement with backup
safe_replace_file() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    shift 3
    local extra_opts=("$@")

    # Create backup
    cp "$file" "$file.bak"

    # Perform replacement
    # Escape dollar signs to prevent shell variable expansion
    local escaped_replacement
    escaped_replacement=$(escape_replacement "$replacement" "$pattern")
    
    rg "${extra_opts[@]}" --replace "$escaped_replacement" --passthru --color=never "$pattern" "$file" > "$file.tmp" 2>/dev/null
    local rg_exit=$?

    if [[ $rg_exit -eq 0 ]] || [[ $rg_exit -eq 1 ]]; then
        # rg succeeded (0) or found no matches (1) - both are OK
        # Check if file was actually modified
        if ! diff -q "$file" "$file.tmp" >/dev/null 2>&1; then
            mv "$file.tmp" "$file"
            rm "$file.bak"
            return 0
        else
            # No changes made
            rm "$file.tmp" "$file.bak"
            return 1
        fi
    else
        # Replacement failed with error, restore backup
        mv "$file.bak" "$file"
        rm -f "$file.tmp"
        echo "✗ Failed: $file" >&2
        return 2
    fi
}

# Count successful and failed operations
count_results() {
    local results=("$@")
    local success_count=0
    local error_count=0

    for result in "${results[@]}"; do
        case $result in
            0) ((success_count++)) ;;
            *) ((error_count++)) ;;
        esac
    done

    echo "$success_count $error_count"
}
