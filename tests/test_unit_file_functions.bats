#!/usr/bin/env bats

# Unit tests for file functions in gs_functions.sh
# Converted from tests/unit/test_file_functions.sh

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
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "safe_replace_file successfully replaces content" {
    echo "hello world" > test1.txt
    
    run safe_replace_file "test1.txt" "hello" "hi"
    
    [ "$status" -eq 0 ]
    
    run cat test1.txt
    [ "$output" = "hi world" ]
}

@test "safe_replace_file handles no matches correctly" {
    echo "no matches here" > test2.txt
    
    run safe_replace_file "test2.txt" "hello" "hi"
    
    [ "$status" -eq 1 ]
    
    # File should be unchanged
    run cat test2.txt
    [ "$output" = "no matches here" ]
}

@test "safe_replace_file cleans up backup files on success" {
    echo "test content" > test3.txt
    
    run safe_replace_file "test3.txt" "test" "example"
    
    [ "$status" -eq 0 ]
    
    # Backup file should not exist
    [ ! -f "test3.txt.bak" ]
    
    # Content should be changed
    run cat test3.txt
    [ "$output" = "example content" ]
}

@test "safe_replace_file cleans up backup files on failure" {
    echo "original content" > test4.txt
    
    run safe_replace_file "test4.txt" "nonexistent" "replacement"
    
    [ "$status" -eq 1 ]
    
    # Backup file should not exist
    [ ! -f "test4.txt.bak" ]
    
    # Content should be unchanged
    run cat test4.txt
    [ "$output" = "original content" ]
}

@test "safe_replace_file handles regex patterns correctly" {
    echo "var oldName = 'value';" > regex_test.txt
    
    run safe_replace_file "regex_test.txt" '\bvar\b' 'let'
    
    [ "$status" -eq 0 ]
    
    run cat regex_test.txt
    [ "$output" = "let oldName = 'value';" ]
}

@test "safe_replace_file handles capture groups correctly" {
    echo "2023-12-25" > date_test.txt
    
    run safe_replace_file "date_test.txt" '([0-9]{4})-([0-9]{2})-([0-9]{2})' '$3/$2/$1'
    
    [ "$status" -eq 0 ]
    
    run cat date_test.txt
    [ "$output" = "25/12/2023" ]
}

@test "safe_replace_file handles literal dollar variables" {
    echo "user data" > dollar_test.txt
    
    run safe_replace_file "dollar_test.txt" "user" '$USER'
    
    [ "$status" -eq 0 ]
    
    run cat dollar_test.txt
    [ "$output" = "\$USER data" ]
}

@test "safe_replace_file handles empty replacement" {
    echo "remove this text" > empty_test.txt
    
    run safe_replace_file "empty_test.txt" "remove " ""
    
    [ "$status" -eq 0 ]
    
    run cat empty_test.txt
    [ "$output" = "this text" ]
}

@test "safe_replace_file handles multiple occurrences" {
    echo "test test test" > multi_test.txt
    
    run safe_replace_file "multi_test.txt" "test" "example"
    
    [ "$status" -eq 0 ]
    
    run cat multi_test.txt
    [ "$output" = "example example example" ]
}

@test "count_results correctly counts successes and failures" {
    run count_results 0 0 1 2 0 1
    
    [ "$status" -eq 0 ]
    [ "$output" = "3 3" ]
}

@test "count_results handles all successes" {
    run count_results 0 0 0
    
    [ "$status" -eq 0 ]
    [ "$output" = "3 0" ]
}

@test "count_results handles all failures" {
    run count_results 1 2 1
    
    [ "$status" -eq 0 ]
    [ "$output" = "0 3" ]
}

@test "count_results handles empty input" {
    run count_results
    
    [ "$status" -eq 0 ]
    [ "$output" = "0 0" ]
}

@test "count_results handles single success" {
    run count_results 0
    
    [ "$status" -eq 0 ]
    [ "$output" = "1 0" ]
}

@test "count_results handles single failure" {
    run count_results 1
    
    [ "$status" -eq 0 ]
    [ "$output" = "0 1" ]
}

@test "count_results handles mixed exit codes" {
    run count_results 0 3 0 5 0 1 2
    
    [ "$status" -eq 0 ]
    [ "$output" = "3 4" ]
}