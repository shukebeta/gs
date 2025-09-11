#!/usr/bin/env bats

# Tests for replace functionality (s tool)
# Converted from test_gs_tools script - replacement related tests

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
    S_TOOL="$REPO_ROOT/s"

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

@test "basic text replacement works" {
    run "$S_TOOL" "hello" "hi" test1.txt

    [ "$status" -eq 0 ]
    [[ "$output" == *"✓ Updated: test1.txt"* ]]

    run cat test1.txt
    [ "$output" = "hi world" ]
}

@test "replacement in multiple files works" {
    echo "hello everyone" > test_multi1.txt
    echo "hello there" > test_multi2.txt
    echo "goodbye world" > test_multi3.txt

    run "$S_TOOL" "hello" "hi" .

    [ "$status" -eq 0 ]
    [[ "$output" == *"2"* ]] && [[ "$output" == *"0"* ]]

    run cat test_multi1.txt
    [ "$output" = "hi everyone" ]

    run cat test_multi2.txt
    [ "$output" = "hi there" ]

    run cat test_multi3.txt
    [ "$output" = "goodbye world" ]  # Should be unchanged
}

@test "regex word boundary replacement works" {
    run "$S_TOOL" '\bvar\b' 'let' test3.js

    [ "$status" -eq 0 ]

    run cat test3.js
    [ "$output" = "let oldVar = 'value';" ]
}

@test "regex replacement with special characters" {
    echo "price: 15.99 dollars" > price.txt

    run "$S_TOOL" '[0-9][0-9]*\.[0-9][0-9]' '$0.00' price.txt

    [ "$status" -eq 0 ]

    run cat price.txt
    # Note: $0 gets escaped to $$0 when no capture groups, renders as literal $0
    [[ "$output" == *"\$0.00"* ]]
}

@test "replacement preserves file when no matches" {
    echo "original content" > no_match.txt

    run "$S_TOOL" "nonexistent" "replacement" no_match.txt

    [ "$status" -eq 1 ]  # Should fail when no matches
    [[ "$output" == *"No matches found"* ]]

    run cat no_match.txt
    [ "$output" = "original content" ]
}

@test "single file replacement works" {
    echo "single file content for testing" > single_test.txt
    echo "another line with pattern" >> single_test.txt

    run "$S_TOOL" "pattern" "replacement" single_test.txt

    [ "$status" -eq 0 ]
    [[ "$output" == *"✓ Updated: single_test.txt"* ]]

    run cat single_test.txt
    [[ "$output" == *"replacement"* ]]
    [[ "$output" != *"pattern"* ]]
}

@test "replacement handles quotes in text" {
    echo "text with 'single' quotes" > quotes.txt
    echo 'text with "double" quotes' >> quotes.txt

    run "$S_TOOL" "single" "replaced" quotes.txt

    [ "$status" -eq 0 ]

    run cat quotes.txt
    [[ "$output" == *"'replaced'"* ]]
    [[ "$output" == *'"double"'* ]]
}

@test "replacement handles backslashes correctly" {
    echo "path\\to\\file" > backslash.txt

    run "$S_TOOL" "path" "new" backslash.txt

    [ "$status" -eq 0 ]

    run cat backslash.txt
    [ "$output" = "new\\to\\file" ]
}

@test "replacement with minimal string works" {
    echo "remove this text" > minimal.txt

    run "$S_TOOL" "remove " "X" minimal.txt

    [ "$status" -eq 0 ]

    run cat minimal.txt
    [ "$output" = "Xthis text" ]
}

@test "case sensitive replacement works correctly" {
    echo "Hello hello HELLO" > case.txt

    run "$S_TOOL" "hello" "hi" case.txt

    [ "$status" -eq 0 ]

    run cat case.txt
    [ "$output" = "Hello hi HELLO" ]
}

@test "replacement in directory recursively finds files" {
    mkdir -p subdir/deep
    echo "find this text" > subdir/file1.txt
    echo "find this text too" > subdir/deep/file2.txt
    echo "other content" > subdir/file3.txt

    run "$S_TOOL" "find" "found" .

    [ "$status" -eq 0 ]
    [[ "$output" == *"2"* ]] && [[ "$output" == *"0"* ]]

    run cat subdir/file1.txt
    [ "$output" = "found this text" ]

    run cat subdir/deep/file2.txt
    [ "$output" = "found this text too" ]

    run cat subdir/file3.txt
    [ "$output" = "other content" ]
}

@test "empty replacement deletes matching pattern" {
    echo "remove this word from text" > empty_replace.txt

    run "$S_TOOL" "this " "" empty_replace.txt

    [ "$status" -eq 0 ]
    [[ "$output" == *"✓ Updated: empty_replace.txt"* ]]

    run cat empty_replace.txt
    [ "$output" = "remove word from text" ]
}

@test "empty replacement works in dry run mode" {
    echo "delete this pattern here" > empty_dry.txt

    run "$S_TOOL" "pattern " "" empty_dry.txt --dry-run

    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
    [[ "$output" == *"delete this here"* ]]

    # Original file should be unchanged after dry run
    run cat empty_dry.txt
    [ "$output" = "delete this pattern here" ]
}

@test "empty replacement with regex patterns" {
    echo "prefix123suffix and prefix456suffix" > regex_empty.txt

    run "$S_TOOL" "prefix[0-9]+suffix" "" regex_empty.txt

    [ "$status" -eq 0 ]

    run cat regex_empty.txt
    [ "$output" = " and " ]
}