# G/S Tools Test Suite

## Overview

This directory contains comprehensive tests for the `g` (search) and `s` (replace) command-line tools.

## Test Files

- `test_gs_tools` - Main test suite with real behavior verification
- `safety_test` - Quick safety checks for core functionality

## Running Tests

```bash
# Run main test suite
cd ~/bin/tests
./test_gs_tools

# Run safety tests
./safety_test
```

## Test Coverage

### Main Test Suite (`test_gs_tools`)

1. **Basic Search** - Simple pattern matching
2. **Basic Replacement** - Text substitution without confirmation
3. **Regex Replacement** - Word boundaries and complex patterns
4. **Capture Groups** - Backreferences in replacements
5. **Dry-run Mode** - Preview changes without modification
6. **Error Handling** - Empty patterns, invalid directories
7. **Exit Codes** - Proper return values for success/failure

### Safety Tests (`safety_test`)

1. **Dry-run Safety** - Files unchanged during preview
2. **Backup/Restore** - Protection against failures
3. **No Matches** - Graceful handling of empty results
4. **Input Validation** - Rejection of invalid inputs
5. **User Cancellation** - Respect for user choice

## Test Design Principles

- **No False Positives** - Tests verify actual file content changes
- **Isolated Environment** - Each test runs in `/tmp` with cleanup
- **Real Tool Behavior** - No mocked confirmation prompts
- **Content Verification** - Check actual file contents, not just grep counts
- **Error Propagation** - Let real errors surface instead of using `|| true`

## Test Environment

- Tests create temporary files in `/tmp/gs_test_$$`
- Automatic cleanup after each test run
- No interference with actual bin directory
- Cross-platform path handling verification

## Expected Behavior

The tools should:
- Replace text without requiring user confirmation
- Handle Windows/Unix path separators correctly
- Return exit code 0 on success, non-zero on failure
- Support full regex patterns with capture groups
- Preserve files during dry-run operations
- Create backups and restore on failures