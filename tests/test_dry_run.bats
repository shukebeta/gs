#!/usr/bin/env bats

# Tests for dry-run functionality
# Verifies --dry-run flag works correctly and doesn't modify files

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

@test "dry run shows DRY RUN indicator" {
    run "$S_TOOL" "world" "universe" test1.txt --dry-run
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
}

@test "dry run preserves original file content" {
    local original_content
    original_content=$(cat test1.txt)
    
    run "$S_TOOL" "world" "universe" test1.txt --dry-run
    
    [ "$status" -eq 0 ]
    
    # Check file wasn't modified
    run cat test1.txt
    [ "$output" = "$original_content" ]
}

@test "dry run shows what changes would be made" {
    run "$S_TOOL" "world" "universe" test1.txt --dry-run
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello universe"* ]]
}

@test "dry run works with multiple files" {
    echo "hello everyone" > multi1.txt
    echo "hello there" > multi2.txt
    echo "goodbye world" > multi3.txt
    
    run "$S_TOOL" "hello" "hi" . --dry-run
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
    [[ "$output" == *"hi everyone"* ]]
    [[ "$output" == *"hi there"* ]]
    
    # Verify no files were changed
    run cat multi1.txt
    [ "$output" = "hello everyone" ]
    
    run cat multi2.txt
    [ "$output" = "hello there" ]
    
    run cat multi3.txt
    [ "$output" = "goodbye world" ]
}

@test "dry run with regex patterns shows preview" {
    run "$S_TOOL" '\bvar\b' 'let' test3.js --dry-run
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
    [[ "$output" == *"let oldVar"* ]]
    
    # Original file unchanged
    run cat test3.js
    [ "$output" = "var oldVar = 'value';" ]
}

@test "dry run with capture groups shows correct preview" {
    run "$S_TOOL" '([0-9]{4})-([0-9]{2})-([0-9]{2})' '$3/$2/$1' dates.txt --dry-run
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
    [[ "$output" == *"25/12/2023"* ]]
    
    # Original file unchanged
    run cat dates.txt
    [ "$output" = "2023-12-25 Christmas" ]
}

@test "dry run with no matches reports appropriately" {
    run "$S_TOOL" "nonexistent" "replacement" test1.txt --dry-run
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"No matches found"* ]]
    
    # File should still be unchanged
    run cat test1.txt
    [ "$output" = "hello world" ]
}

@test "dry run shows file paths being processed" {
    run "$S_TOOL" "test" "example" test2.js --dry-run
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"test2.js"* ]]
    [[ "$output" == *"DRY RUN"* ]]
}

@test "dry run with literal dollar variables shows correct preview" {
    echo "user info" > user.txt
    
    run "$S_TOOL" "user" '$USER' user.txt --dry-run
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
    [[ "$output" == *"\$USER info"* ]]
    
    # File unchanged
    run cat user.txt
    [ "$output" = "user info" ]
}

@test "dry run exit code is 0 when matches are found" {
    run "$S_TOOL" "hello" "hi" test1.txt --dry-run
    
    [ "$status" -eq 0 ]
}

@test "dry run exit code is 1 when no matches found" {
    run "$S_TOOL" "nomatch" "replacement" test1.txt --dry-run
    
    [ "$status" -eq 1 ]
}

@test "single file dry run works correctly" {
    echo "dry run test content" > dry_single.txt
    
    run "$S_TOOL" "test" "modified" dry_single.txt --dry-run
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
    [[ "$output" == *"dry run modified content"* ]]
    
    # Verify file content unchanged
    run cat dry_single.txt
    [ "$output" = "dry run test content" ]
}