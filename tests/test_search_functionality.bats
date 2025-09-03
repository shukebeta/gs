#!/usr/bin/env bats

# Tests for search functionality (g tool)
# Converted from test_gs_tools script - search related tests

setup() {
    # Determine repository root using BATS_TEST_DIRNAME
    if [ -n "${BATS_TEST_DIRNAME:-}" ]; then
        REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    else
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    fi
    
    # Create unique test directory and switch into it
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"
    
    # Use the repository tools directly
    G_TOOL="$REPO_ROOT/g"
    
    # Create standard test files
    echo "hello world" > "test1.txt"
    echo "function test() { return 42; }" > "test2.js"
    echo "var oldVar = 'value';" > "test3.js"
    echo "2023-12-25 Christmas" > "dates.txt"
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "basic search finds correct file" {
    run "$G_TOOL" "hello" .
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"test1.txt"* ]]
}

@test "basic search finds content in file" {
    run "$G_TOOL" "hello" .
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello world"* ]]
}

@test "search finds multiple matches across files" {
    echo "test function here" > test4.txt
    
    run "$G_TOOL" "test" .
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"test2.js"* ]]
    [[ "$output" == *"test4.txt"* ]]
}

@test "search with no matches reports correctly" {
    run "$G_TOOL" "nonexistent" .
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"No matches found"* ]]
}

@test "case sensitive search works correctly" {
    echo "Hello World" > case_test.txt
    echo "hello world" > case_test2.txt
    
    run "$G_TOOL" "Hello" .
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"case_test.txt"* ]]
    [[ "$output" != *"case_test2.txt"* ]]
}

@test "search in specific file works" {
    run "$G_TOOL" "function" test2.js
    
    [ "$status" -eq 0 ]
    # When searching single file, output may not include filename
    [[ "$output" == *"function test()"* ]]
}

@test "search with regex patterns works" {
    echo "email@example.com" > emails.txt
    echo "user@domain.org" >> emails.txt
    echo "not an email" >> emails.txt
    
    run "$G_TOOL" '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' emails.txt
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"email@example.com"* ]]
    [[ "$output" == *"user@domain.org"* ]]
    [[ "$output" != *"not an email"* ]]
}

@test "search handles special characters in patterns" {
    echo "price: \$15.99" > prices.txt
    echo "total: \$25.00" >> prices.txt
    
    run "$G_TOOL" '\$' prices.txt
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"\$15.99"* ]]
    [[ "$output" == *"\$25.00"* ]]
}

@test "search with word boundaries works" {
    echo "variable var_name" > word_test.txt
    
    run "$G_TOOL" '\bvar\b' word_test.txt
    
    [ "$status" -eq 1 ]  # Should not match var_name
    
    echo "var is a keyword" > word_test2.txt
    
    run "$G_TOOL" '\bvar\b' word_test2.txt
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"var is a keyword"* ]]
}

@test "search ignores binary files appropriately" {
    # Create a binary-like file with null bytes
    printf "text\0binary\0data" > binary.bin
    echo "normal text file" > text.txt
    
    run "$G_TOOL" "text" .
    
    [ "$status" -eq 0 ]
    # Should find the text file but handle binary appropriately
    [[ "$output" == *"text.txt"* ]]
}