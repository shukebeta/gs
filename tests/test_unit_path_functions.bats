#!/usr/bin/env bats

# Unit tests for path functions in gs_functions.sh
# Converted from tests/unit/test_path_functions.sh

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
}

@test "normalize_path converts backslashes to forward slashes" {
    run normalize_path "src\\file.txt"
    
    [ "$status" -eq 0 ]
    [ "$output" = "src/file.txt" ]
}

@test "normalize_path keeps forward slashes unchanged" {
    run normalize_path "src/file.txt"
    
    [ "$status" -eq 0 ]
    [ "$output" = "src/file.txt" ]
}

@test "normalize_path converts mixed separators" {
    run normalize_path "src\\sub/file.txt"
    
    [ "$status" -eq 0 ]
    [ "$output" = "src/sub/file.txt" ]
}

@test "normalize_path converts Windows absolute path" {
    run normalize_path "C:\\Users\\Name\\file.txt"
    
    [ "$status" -eq 0 ]
    [ "$output" = "C:/Users/Name/file.txt" ]
}

@test "normalize_path handles empty path" {
    run normalize_path ""
    
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "normalize_path handles single filename" {
    run normalize_path "file.txt"
    
    [ "$status" -eq 0 ]
    [ "$output" = "file.txt" ]
}

@test "normalize_path handles complex Windows path" {
    run normalize_path "D:\\Projects\\my-app\\src\\components\\Button\\index.tsx"
    
    [ "$status" -eq 0 ]
    [ "$output" = "D:/Projects/my-app/src/components/Button/index.tsx" ]
}

@test "normalize_path handles path with spaces" {
    run normalize_path "C:\\Program Files\\My App\\file.txt"
    
    [ "$status" -eq 0 ]
    [ "$output" = "C:/Program Files/My App/file.txt" ]
}

@test "normalize_path handles UNC path" {
    run normalize_path "\\\\server\\share\\file.txt"
    
    [ "$status" -eq 0 ]
    [ "$output" = "//server/share/file.txt" ]
}

@test "normalize_path handles path with trailing backslash" {
    run normalize_path "src\\folder\\"
    
    [ "$status" -eq 0 ]
    [ "$output" = "src/folder/" ]
}

@test "normalize_path handles already normalized Unix path" {
    run normalize_path "/usr/local/bin/tool"
    
    [ "$status" -eq 0 ]
    [ "$output" = "/usr/local/bin/tool" ]
}

@test "normalize_path handles relative path with parent references" {
    run normalize_path "..\\..\\parent\\file.txt"
    
    [ "$status" -eq 0 ]
    [ "$output" = "../../parent/file.txt" ]
}