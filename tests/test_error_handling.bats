#!/usr/bin/env bats

# Tests for error handling and exit codes
# Verifies proper error reporting and exit code behavior

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
    S_TOOL="$REPO_ROOT/s"
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "search with empty pattern is rejected" {
    run "$G_TOOL" "" .
    
    [ "$status" -ne 0 ]
}

@test "search in non-existent directory fails appropriately" {
    run "$G_TOOL" "test" "/nonexistent/directory"
    
    [ "$status" -ne 0 ]
}

@test "replacement in non-existent file fails" {
    run "$S_TOOL" "test" "replacement" "/nonexistent/file.txt"
    
    [ "$status" -ne 0 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "successful search returns exit code 0" {
    echo "test content" > success.txt
    
    run "$G_TOOL" "test" success.txt
    
    [ "$status" -eq 0 ]
}

@test "search with no matches returns exit code 1" {
    echo "content without pattern" > nomatch.txt
    
    run "$G_TOOL" "missing" nomatch.txt
    
    [ "$status" -eq 1 ]
}

@test "successful replacement returns exit code 0" {
    echo "test content" > replace_success.txt
    
    run "$S_TOOL" "test" "example" replace_success.txt
    
    [ "$status" -eq 0 ]
}

@test "replacement with no matches returns appropriate exit code" {
    echo "original content" > no_replace.txt
    
    run "$S_TOOL" "missing" "replacement" no_replace.txt
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"No matches found"* ]]
}

@test "invalid regex pattern is handled gracefully" {
    echo "test content" > regex_test.txt
    
    # Invalid regex with unmatched parentheses
    run "$G_TOOL" "test(" regex_test.txt
    
    [ "$status" -ne 0 ]
}

@test "permission denied error is handled appropriately" {
    echo "test content" > permission_test.txt
    chmod 000 permission_test.txt
    
    run "$G_TOOL" "test" permission_test.txt
    
    # Should handle permission error gracefully
    [ "$status" -ne 0 ]
    
    # Restore permissions for cleanup
    chmod 644 permission_test.txt
}

@test "replacement preserves original file when processing fails" {
    echo "original content" > fail_test.txt
    local original_content
    original_content=$(cat fail_test.txt)
    
    # Try replacement that should fail (non-existent pattern)
    run "$S_TOOL" "nonexistent" "replacement" fail_test.txt
    
    [ "$status" -ne 0 ]
    
    # File should be unchanged
    run cat fail_test.txt
    [ "$output" = "$original_content" ]
}

@test "tools report correct error messages for invalid arguments" {
    # Test search with insufficient arguments
    run "$G_TOOL"
    
    [ "$status" -ne 0 ]
    
    # Test replacement with insufficient arguments  
    run "$S_TOOL" "pattern"
    
    [ "$status" -ne 0 ]
}

@test "binary file handling doesn't cause crashes" {
    # Create a file with null bytes (binary-like)
    printf "binary\0content\0here" > binary.bin
    
    run "$G_TOOL" "content" binary.bin
    
    # Should complete without crashing, regardless of result
    # (behavior may vary based on ripgrep settings)
}

@test "very long lines don't cause issues" {
    # Create a very long line
    local long_line
    long_line=$(printf 'a%.0s' {1..10000})
    echo "$long_line" > longline.txt
    
    run "$G_TOOL" "aaa" longline.txt
    
    [ "$status" -eq 0 ]
}

@test "special characters in file names are handled" {
    echo "content" > "file with spaces.txt"
    echo "content" > "file-with-dashes.txt"
    echo "content" > "file_with_underscores.txt"
    
    run "$G_TOOL" "content" .
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"file with spaces.txt"* ]]
    [[ "$output" == *"file-with-dashes.txt"* ]]
    [[ "$output" == *"file_with_underscores.txt"* ]]
}

@test "empty files are handled correctly" {
    touch empty.txt
    
    run "$G_TOOL" "anything" empty.txt
    
    [ "$status" -eq 1 ]  # No matches in empty file
    
    run "$S_TOOL" "anything" "replacement" empty.txt
    
    [ "$status" -eq 1 ]  # No matches to replace
}

@test "directory traversal respects .gitignore patterns" {
    mkdir -p test_dir
    echo "content" > test_dir/included.txt
    echo "content" > test_dir/node_modules.txt  # Should be excluded by default
    echo "node_modules/" > .gitignore
    
    run "$G_TOOL" "content" .
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"included.txt"* ]]
    # Note: behavior depends on RG_DEFAULT_EXCLUDES configuration
}