# G/S - Powerful Search and Replace Tools

[![GitHub stars](https://img.shields.io/github/stars/shukebeta/gs?style=flat-square)](https://github.com/shukebeta/gs/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/shukebeta/gs?style=flat-square)](https://github.com/shukebeta/gs/issues)
[![License](https://img.shields.io/github/license/shukebeta/gs?style=flat-square)](LICENSE)

**G/S** is a powerful command-line toolkit that provides lightning-fast search (`g`) and replace (`s`) capabilities built on top of [ripgrep](https://github.com/BurntSushi/ripgrep). Designed for developers who need reliable, safe, and efficient text processing tools.

## ✨ Features

### 🔍 Search Tool (`g`)
- **Fast ripgrep-powered search** with regex support
- **Smart file filtering** - automatically excludes binaries, node_modules, .git, etc.
- **Context options** - show lines before/after matches
- **Multiple output modes** - content, filenames, or counts
- **Gitignore aware** - respects your project's ignore rules

### 🔄 Replace Tool (`s`)
- **Safe replacements** with automatic backups
- **Dry-run mode** - preview changes before applying
- **Regex capture groups** - advanced pattern substitution with `$1`, `$2`, etc.
- **Smart dollar escaping** - prevents shell variable expansion issues
- **Multi-file operations** - replace across entire projects safely

### 🛡️ Safety Features
- **Automatic backups** and restore on failures  
- **Dollar sign handling** - no more `$USER` expanding to empty strings
- **Binary file detection** and smart filtering
- **Comprehensive error handling** with helpful messages

## 🚀 Quick Start

### Prerequisites
- [ripgrep](https://github.com/BurntSushi/ripgrep) (rg command)
- bash 4.0+

### Installation

```bash
# Clone the repository
git clone https://github.com/shukebeta/gs.git
cd gs

# Make tools executable
chmod +x g s

# Add to your PATH (optional)
ln -s $(pwd)/g ~/.local/bin/g
ln -s $(pwd)/s ~/.local/bin/s
```

### Basic Usage

```bash
# Search for patterns
g 'function.*Promise'           # Find async functions
g '\bTODO\b' src/              # Find TODO comments  
g 'import.*React' .            # Find React imports

# Replace text safely
s 'var\b' 'let' src/ --dry-run # Preview changes first
s 'var\b' 'let' src/           # Apply changes

# Advanced replacements with capture groups
s '(\d{4})-(\d{2})-(\d{2})' '$3/$2/$1' data/  # Date format conversion
s 'function (\w+)\(' 'const $1 = (' src/      # Function to arrow syntax
```

## 📖 Detailed Usage

### Search Tool (`g`)

```bash
Usage: g <pattern> [directory] [options]

Options:
  -i, --ignore-case    Case insensitive search
  -w, --word-regexp    Match whole words only
  -v, --invert-match   Invert match (show non-matching lines)
  -A, --after N        Show N lines after match
  -B, --before N       Show N lines before match  
  -C, --context N      Show N lines before and after match
  --files              Show only filenames with matches
  --no-ignore          Don't use .gitignore

# Examples
g 'class.*Component' src/                    # Find React components
g 'TODO|FIXME|XXX' . -i                    # Find all todo items
g 'function' --files src/                   # Files containing functions
g 'error' logs/ -A 3 -B 1                  # Show context around errors
```

### Replace Tool (`s`)

```bash
Usage: s <search_pattern> <replacement> <directory> [options]

Options:
  -i, --ignore-case    Case insensitive search
  -w, --word-regexp    Match whole words only
  --dry-run           Show what would be changed without making changes
  --no-ignore         Don't use .gitignore

# Always preview first!
s 'oldFunction' 'newFunction' src/ --dry-run

# Basic replacements
s 'var\b' 'const' src/                      # Update variable declarations
s 'http://' 'https://' config/              # Update URLs

# Regex with capture groups
s '([A-Z]+)_([A-Z]+)' '$1-$2' src/         # SNAKE_CASE to kebab-case
s 'new Date\(\)' 'Date.now()' src/         # Modernize date creation
```

## 💡 Advanced Examples

### Date Format Conversion
```bash
# Convert YYYY-MM-DD to DD/MM/YYYY
s '([0-9]{4})-([0-9]{2})-([0-9]{2})' '$3/$2/$1' data.txt
```

### Function Declaration to Arrow Functions
```bash  
# Convert: function name() {} → const name = () => {}
s 'function (\w+)\(\)' 'const $1 = ()' src/
```

### Import Statement Updates
```bash
# Add .js extensions to imports
s "import (.*) from '(.+)'" "import $1 from '$2.js'" src/
```

### CSS Property Updates
```bash
# Update old flexbox properties
s 'display: -webkit-flex' 'display: flex' styles/
s '-webkit-flex-direction' 'flex-direction' styles/
```

## ⚠️ Important Notes

### Always Use Single Quotes!
```bash
# ✅ Correct - prevents shell interpretation
g '$USER' src/
s '\$[A-Z_]+' 'REPLACED' src/

# ❌ Wrong - shell expands variables
g "$USER" src/          # Searches for actual username
s "\$USER" 'fixed' src/ # May not work as expected
```

### Dollar Sign Handling
The tools automatically handle dollar signs in replacements:
- Literal variables like `$USER`, `$PATH` are automatically escaped
- Capture groups like `$1`, `$2` work as expected
- Use `--dry-run` to preview complex replacements

### File Safety
- Original files are automatically backed up during replacements
- Backups are cleaned up on success, restored on failure
- Binary files and large files are handled safely
- Respects `.gitignore` and common ignore patterns

## 🧪 Testing

The project includes a comprehensive test suite using [bats](https://github.com/bats-core/bats-core):

```bash
# Install bats (if needed)
npm install -g bats

# Run all tests
bats tests/test_*.bats

# Run specific test categories
bats tests/test_search_functionality.bats
bats tests/test_replace_functionality.bats
bats tests/test_dollar_capture_groups.bats
```

**Test Coverage:** 126 tests covering:
- ✅ Search functionality and edge cases
- ✅ Replace operations with regex patterns  
- ✅ Dollar sign and capture group handling
- ✅ Dry-run mode and preview functionality
- ✅ Error handling and file safety
- ✅ Binary file detection and filtering
- ✅ Unit tests for all core functions

## 🔧 Architecture

```
gs/
├── g              # Search tool executable
├── s              # Replace tool executable  
├── lib/
│   └── gs_functions.sh  # Core function library
├── tests/         # Comprehensive bats test suite
│   ├── test_search_functionality.bats
│   ├── test_replace_functionality.bats
│   ├── test_dollar_capture_groups.bats
│   ├── test_dry_run.bats
│   ├── test_error_handling.bats
│   ├── test_safety.bats
│   └── test_unit_*.bats
└── README.md
```

### Core Components
- **Search Engine**: Built on ripgrep for maximum performance
- **Safety System**: Automatic backups, validation, and recovery
- **Escape Handler**: Smart dollar sign processing for shell safety
- **File Filter**: Intelligent binary/text detection with ignore patterns

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality  
4. Ensure all tests pass: `bats tests/test_*.bats`
5. Submit a pull request

### Coding Standards
- Follow existing bash style conventions
- Add comprehensive test coverage for new features
- Update documentation for user-facing changes
- Use meaningful commit messages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [ripgrep](https://github.com/BurntSushi/ripgrep) - The blazing fast search engine that powers our tools
- [bats-core](https://github.com/bats-core/bats-core) - Bash testing framework used for our comprehensive test suite

## 📊 Project Stats

- **Lines of Code**: ~2,000+ (including tests)
- **Test Coverage**: 126 comprehensive tests
- **Success Rate**: 100% passing tests
- **Shell Compatibility**: bash 4.0+
- **Dependencies**: ripgrep only

---

**Made with ❤️ for developers who need reliable text processing tools.**

*If you find this project helpful, please consider giving it a ⭐ on GitHub!*