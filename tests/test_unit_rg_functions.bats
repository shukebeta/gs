#!/usr/bin/env bats

# Unit tests for ripgrep functions in gs_functions.sh
# Converted from tests/unit/test_rg_functions.sh

setup() {
    # Determine repository root using BATS_TEST_DIRNAME
    if [ -n "${BATS_TEST_DIRNAME:-}" ]; then
        REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    else
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    fi
    
    # Load the function library
    source "$REPO_ROOT/lib/gs_functions.sh"
    
    # Create unique test directory and switch into it
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"
    
    # Create standard test files
    echo "hello world" > "test1.txt"
    echo "function test() {}" > "test2.js"
    echo "no match here" > "test3.txt"
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "rg_search_content finds pattern in files" {
    run rg_search_content "hello" "."
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"test1.txt"* ]]
    [[ "$output" == *"hello world"* ]]
}

@test "rg_search_content returns 1 for no matches" {
    run rg_search_content "nonexistent" "."
    
    [ "$status" -eq 1 ]
}

@test "rg_search_content with extra options works" {
    echo "Hello World" > case_test.txt
    
    # Test case-insensitive search
    run rg_search_content "hello" "." "--ignore-case"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"case_test.txt"* ]]
}

@test "rg_find_files returns correct file list" {
    run rg_find_files "hello" "."
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"test1.txt"* ]]
    # Should only return file names, not content
    [[ "$output" != *"hello world"* ]]
}

@test "rg_find_files returns 1 for no matches" {
    run rg_find_files "nonexistent" "."
    
    [ "$status" -eq 1 ]
}

@test "rg_find_files with extra options works" {
    echo "Hello World" > case_test2.txt
    
    run rg_find_files "hello" "." "--ignore-case"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"case_test2.txt"* ]]
}

@test "handle_rg_exit_code handles success case (0)" {
    run handle_rg_exit_code 0 "test" "search"
    
    [ "$status" -eq 0 ]
}

@test "handle_rg_exit_code handles no matches (1)" {
    run handle_rg_exit_code 1 "test" "search"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"No matches found"* ]]
    [[ "$output" == *"test"* ]]
}

@test "handle_rg_exit_code handles ripgrep error (2)" {
    run handle_rg_exit_code 2 "test" "search"
    
    [ "$status" -eq 2 ]
    [[ "$output" == *"Error running ripgrep"* ]]
    [[ "$output" == *"search"* ]]
}

@test "handle_rg_exit_code handles unexpected exit code" {
    run handle_rg_exit_code 42 "test" "search"
    
    [ "$status" -eq 42 ]
    [[ "$output" == *"Unexpected ripgrep exit code: 42"* ]]
}

@test "normalize_path converts backslashes to forward slashes" {
    run normalize_path "path\\with\\backslashes"
    
    [ "$status" -eq 0 ]
    [ "$output" = "path/with/backslashes" ]
}

@test "normalize_path leaves forward slashes unchanged" {
    run normalize_path "path/with/forward/slashes"
    
    [ "$status" -eq 0 ]
    [ "$output" = "path/with/forward/slashes" ]
}

@test "escape_replacement with capture groups preserves $1, $2, etc" {
    run escape_replacement '$1 and $2 and $10' '(hello) (world)'
    
    [ "$status" -eq 0 ]
    [ "$output" = '$1 and $2 and $10' ]
}

@test "escape_replacement without capture groups escapes $1, $2, etc" {
    run escape_replacement '$1 and $2 and $10' 'hello world'
    
    [ "$status" -eq 0 ]
    [ "$output" = '$$1 and $$2 and $$10' ]
}

@test "escape_replacement with capture groups escapes literal variables" {
    run escape_replacement '$USER and $PATH' '(pattern)'
    
    [ "$status" -eq 0 ]
    [ "$output" = '$$USER and $$PATH' ]
}

@test "escape_replacement without capture groups escapes everything" {
    run escape_replacement '$USER and $PATH' 'pattern'
    
    [ "$status" -eq 0 ]
    [ "$output" = '$$USER and $$PATH' ]
}

@test "escape_replacement mixed scenario with capture groups" {
    run escape_replacement '$1 costs $$5 but $USER pays' '(item)'
    
    [ "$status" -eq 0 ]
    [ "$output" = '$1 costs $$$5 but $$USER pays' ]
}

@test "escape_replacement mixed scenario without capture groups" {
    run escape_replacement '$1 costs $$5 but $USER pays' 'item'
    
    [ "$status" -eq 0 ]
    [ "$output" = '$$1 costs $$$$5 but $$USER pays' ]
}

@test "rg_get_preview generates correct preview" {
    run rg_get_preview "hello" "hi" "test1.txt"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"hi world"* ]]
}

@test "rg_get_preview with capture groups works" {
    echo "2023-12-25" > date_test.txt
    
    run rg_get_preview '([0-9]{4})-([0-9]{2})-([0-9]{2})' '$3/$2/$1' "date_test.txt"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"25/12/2023"* ]]
}

@test "safe_replace_file creates backup and replaces content" {
    echo "original content" > replace_test.txt
    
    run safe_replace_file "replace_test.txt" "original" "modified"
    
    [ "$status" -eq 0 ]
    
    # File should be modified
    run cat replace_test.txt
    [ "$output" = "modified content" ]
    
    # Backup file should not exist (cleaned up on success)
    [ ! -f "replace_test.txt.bak" ]
}

@test "safe_replace_file restores backup on failure" {
    echo "original content" > fail_test.txt
    
    # This should fail - no pattern match
    run safe_replace_file "fail_test.txt" "nonexistent" "replacement"
    
    [ "$status" -eq 1 ]
    
    # Original file should be unchanged
    run cat fail_test.txt
    [ "$output" = "original content" ]
    
    # Backup should be cleaned up
    [ ! -f "fail_test.txt.bak" ]
}