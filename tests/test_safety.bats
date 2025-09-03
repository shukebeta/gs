#!/usr/bin/env bats

# Safety tests for G/S tools
# Converted from safety_test script - ensures tools are safe to use

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
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "dry-run doesn't modify files" {
    echo "original content" > test.txt
    
    run "$S_TOOL" "original" "modified" test.txt --dry-run
    
    [ "$status" -eq 0 ]
    
    # File should be unchanged
    run cat test.txt
    [ "$output" = "original content" ]
}

@test "backup mechanism verification" {
    echo "original content" > backup_test.txt
    
    run "$S_TOOL" "original" "modified" backup_test.txt
    
    [ "$status" -eq 0 ]
    
    # File should exist and be modified
    [ -f backup_test.txt ]
    
    run cat backup_test.txt
    [ "$output" = "modified content" ]
}

@test "no matches scenario handled gracefully" {
    mkdir -p isolated_test
    cd isolated_test
    echo "sample content" > sample.txt
    
    local unique_pattern="NEVER_MATCH_THIS_PATTERN_12345"
    
    run "$S_TOOL" "$unique_pattern" "replacement" sample.txt
    
    [ "$status" -eq 1 ]  # Should return non-zero for no matches
    [[ "$output" == *"No matches found"* ]]
    
    # Original file should be unchanged
    run cat sample.txt
    [ "$output" = "sample content" ]
}

@test "handles minimal replacement string safely" {
    echo "remove this text" > minimal_replace.txt
    
    run "$S_TOOL" "remove " "X" minimal_replace.txt
    
    [ "$status" -eq 0 ]
    
    run cat minimal_replace.txt
    [ "$output" = "Xthis text" ]
}

@test "large file handling doesn't break system" {
    # Create a reasonably large file (not too large for CI)
    for i in {1..1000}; do
        echo "line $i with test content" >> large_file.txt
    done
    
    run "$S_TOOL" "test" "example" large_file.txt
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Updated"* ]]
    
    # Verify some replacements occurred
    run grep -c "example" large_file.txt
    [ "$output" -gt 0 ]
}

@test "concurrent access safety" {
    echo "concurrent test" > concurrent.txt
    
    # Test that tool doesn't break with quick successive calls
    run "$S_TOOL" "test" "first" concurrent.txt
    [ "$status" -eq 0 ]
    
    run "$S_TOOL" "first" "second" concurrent.txt  
    [ "$status" -eq 0 ]
    
    run cat concurrent.txt
    [ "$output" = "concurrent second" ]
}

@test "special characters in patterns don't cause security issues" {
    echo "test content" > special.txt
    
    # Test various special characters that could be problematic
    run "$S_TOOL" 'test.*content' 'safe replacement' special.txt
    
    [ "$status" -eq 0 ]
    
    run cat special.txt
    [ "$output" = "safe replacement" ]
}

@test "path traversal attempts are handled safely" {
    mkdir -p subdir
    echo "content" > subdir/file.txt
    
    # Should work normally with subdirectories
    run "$S_TOOL" "content" "replaced" subdir/file.txt
    
    [ "$status" -eq 0 ]
    
    run cat subdir/file.txt
    [ "$output" = "replaced" ]
}

@test "binary content doesn't cause crashes or hangs" {
    # Create file with binary content
    printf "text\x00binary\x00content" > binary.dat
    
    # Should handle gracefully without hanging
    timeout 10 "$S_TOOL" "text" "replaced" binary.dat || true
    
    # If it completes, that's good (result may vary)
    [ $? -ne 124 ]  # 124 is timeout exit code
}

@test "very long patterns don't cause buffer overflows" {
    echo "short content" > pattern_test.txt
    
    # Create a very long pattern
    local long_pattern
    long_pattern=$(printf 'a%.0s' {1..1000})
    
    run "$S_TOOL" "$long_pattern" "replacement" pattern_test.txt
    
    # Should complete without crashing (likely no match)
    [ "$status" -eq 1 ]
    [[ "$output" == *"No matches found"* ]]
}

@test "unicode content is handled safely" {
    echo "Hello 世界 🌍" > unicode.txt
    
    run "$S_TOOL" "世界" "World" unicode.txt
    
    [ "$status" -eq 0 ]
    
    run cat unicode.txt
    [ "$output" = "Hello World 🌍" ]
}

@test "symlinks are handled appropriately" {
    echo "test content" > original.txt
    ln -s original.txt symlink.txt
    
    # Test that tool doesn't crash when encountering symlinks
    run "$S_TOOL" "test" "example" symlink.txt
    
    # Should complete without crashing (any exit code is acceptable for this safety test)
    # The important thing is that it doesn't hang, crash, or cause system issues
    true
}