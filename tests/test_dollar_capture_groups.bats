#!/usr/bin/env bats

# Tests for capture group functionality and dollar sign handling
# Includes basic capture groups, dollar variable handling, and complex regex patterns

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

@test "basic capture group replacement - date format" {
    echo "2023-12-25" > dates.txt
    
    run "$S_TOOL" '([0-9]{4})-([0-9]{2})-([0-9]{2})' '$3/$2/$1' dates.txt
    
    [ "$status" -eq 0 ]
    
    # Check the actual file content
    run cat dates.txt
    [ "$output" = "25/12/2023" ]
}

@test "multiple capture groups in replacement" {
    echo "function test() {" > code.js
    
    run "$S_TOOL" 'function ([a-zA-Z_][a-zA-Z0-9_]*)\(\)' 'const $1 = ()' code.js
    
    [ "$status" -eq 0 ]
    
    run cat code.js  
    [ "$output" = "const test = () {" ]
}

@test "capture groups mixed with literal text" {
    echo "name: John Doe" > person.txt
    
    run "$S_TOOL" 'name: (.*)' 'full_name: $1' person.txt
    
    [ "$status" -eq 0 ]
    
    run cat person.txt
    [ "$output" = "full_name: John Doe" ]
}

@test "dollar number gets escaped when no capture groups" {
    echo "hello world" > test.txt
    
    run "$S_TOOL" 'world' '$5 replacement' test.txt
    
    [ "$status" -eq 0 ]
    
    # $5 gets escaped to $$5 when no capture groups exist
    run cat test.txt
    [ "$output" = "hello \$5 replacement" ]
}

@test "dollar zero captures entire match" {
    echo "test123" > match.txt
    
    run "$S_TOOL" 'test([0-9]+)' 'found: $0, number: $1' match.txt
    
    [ "$status" -eq 0 ]
    
    run cat match.txt
    [ "$output" = "found: test123, number: 123" ]
}

@test "double dollar gets escaped when no capture groups" {
    echo "price value" > cost.txt
    
    run "$S_TOOL" 'value' '$$5.00' cost.txt
    
    [ "$status" -eq 0 ]
    
    run cat cost.txt
    # $$5.00 becomes $$$$5.00 with no capture groups, which renders as $$5.00
    [ "$output" = "price \$\$5.00" ]
}

@test "dry run shows correct capture group replacement" {
    echo "2024-01-01 New Year" > drytest.txt
    
    run "$S_TOOL" '([0-9]{4})-([0-9]{2})-([0-9]{2})' '$3/$2/$1' drytest.txt --dry-run
    
    [ "$status" -eq 0 ]
    
    # Should show the preview but not modify file
    [[ "$output" == *"01/01/2024"* ]]
    
    # Original file unchanged
    run cat drytest.txt
    [ "$output" = "2024-01-01 New Year" ]
}

@test "capture groups work with quotes in replacement" {
    echo 'title="old title"' > quotes.txt
    
    run "$S_TOOL" 'title="([^"]*)"' 'title="$1 (updated)"' quotes.txt
    
    [ "$status" -eq 0 ]
    
    run cat quotes.txt
    [ "$output" = 'title="old title (updated)"' ]
}

@test "high numbered capture groups work correctly" {
    echo "a1b2c3d4e5" > multi.txt
    
    # Pattern has 10 groups: (a)([0-9])(b)([0-9])(c)([0-9])(d)([0-9])(e)([0-9])
    # Groups: $1=a, $2=1, $3=b, $4=2, $5=c, $6=3, $7=d, $8=4, $9=e, $10=5
    run "$S_TOOL" '(a)([0-9])(b)([0-9])(c)([0-9])(d)([0-9])(e)([0-9])' 'result:$1$2$3$4$5$6$7$8$9' multi.txt
    
    [ "$status" -eq 0 ]
    
    run cat multi.txt
    # Expected result: a1b2c3d4e (groups 1-9, note $9=e not a digit)
    [ "$output" = "result:a1b2c3d4e" ]
}

@test "mixed capture groups and literal dollars" {
    echo "cost: 10 dollars" > price.txt
    
    run "$S_TOOL" 'cost: ([0-9]+) dollars' 'price: $$1 = $1 USD' price.txt
    
    [ "$status" -eq 0 ]
    
    run cat price.txt
    # $$1 means literal $ + capture group 1, $1 is capture group 1
    [ "$output" = "price: \$10 = 10 USD" ]
}

@test "literal dollar variable names stay literal" {
    echo "Hello world" > test.txt
    
    # $USER should become literal $USER, not expand to environment variable
    run "$S_TOOL" 'world' '$USER' test.txt
    
    [ "$status" -eq 0 ]
    
    run cat test.txt
    [ "$output" = "Hello \$USER" ]
}

@test "custom variable names stay literal" {
    echo "price: 100" > price.txt
    
    # $CUSTOM_VAR should stay as literal text
    run "$S_TOOL" 'price:' 'cost: $CUSTOM_VAR' price.txt
    
    [ "$status" -eq 0 ]
    
    run cat price.txt
    [ "$output" = "cost: \$CUSTOM_VAR 100" ]
}

@test "date format conversion with capture groups" {
    echo "2023-12-25 Christmas" > dates.txt
    
    # Convert YYYY-MM-DD to DD/MM/YYYY format
    run "$S_TOOL" '([0-9]{4})-([0-9]{2})-([0-9]{2})' '$3/$2/$1' dates.txt
    
    [ "$status" -eq 0 ]
    
    run cat dates.txt
    [ "$output" = "25/12/2023 Christmas" ]
}

@test "complex capture group patterns work correctly" {
    echo "function oldName(param1, param2) {" > complex.js
    
    # Convert function declaration syntax
    run "$S_TOOL" 'function ([a-zA-Z_][a-zA-Z0-9_]*)\(([^)]*)\)' 'const $1 = ($2) =>' complex.js
    
    [ "$status" -eq 0 ]
    
    run cat complex.js
    [ "$output" = "const oldName = (param1, param2) => {" ]
}

@test "nested capture groups with complex patterns" {
    echo "email: john.doe@example.com, phone: 123-456-7890" > contact.txt
    
    # Extract domain from email
    run "$S_TOOL" '([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+)\.([a-zA-Z]{2,})' 'user: $1, domain: $2.$3' contact.txt
    
    [ "$status" -eq 0 ]
    
    run cat contact.txt
    [ "$output" = "email: user: john.doe, domain: example.com, phone: 123-456-7890" ]
}