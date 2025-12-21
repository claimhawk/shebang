#!/bin/bash
# Extract documentation from Swift source files
# Parses /// doc comments and generates Markdown

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SOURCES_DIR="$PROJECT_ROOT/Sources/ShebangApp"

cat << 'EOF'
# Swift API Reference

Auto-generated from source code docstrings.

---

EOF

# Extract struct/class definitions with their doc comments
find "$SOURCES_DIR" -name "*.swift" -type f | sort | while read -r file; do
    filename=$(basename "$file" .swift)
    relative_path="${file#$PROJECT_ROOT/}"

    # Check if file has any doc comments (///)
    if grep -q "^[[:space:]]*///" "$file"; then
        echo "## $filename"
        echo ""
        echo "_Source: \`$relative_path\`_"
        echo ""

        # Extract documented types and functions
        awk '
        BEGIN { in_doc = 0; doc = "" }

        # Capture doc comments
        /^[[:space:]]*\/\/\// {
            # Remove leading whitespace and ///
            gsub(/^[[:space:]]*\/\/\/[[:space:]]?/, "")
            if (doc != "") doc = doc "\n"
            doc = doc $0
            in_doc = 1
            next
        }

        # If we hit a struct/class/func/enum after doc comments
        in_doc && /^[[:space:]]*(public |private |internal |fileprivate )?(@[A-Za-z]+ )?(struct|class|enum|func|var|let|protocol)/ {
            # Extract the declaration
            gsub(/^[[:space:]]+/, "")
            decl = $0
            # Truncate at { or newline
            gsub(/\{.*$/, "", decl)
            gsub(/[[:space:]]+$/, "", decl)

            print "### `" decl "`"
            print ""
            print doc
            print ""
            doc = ""
            in_doc = 0
            next
        }

        # Reset if we hit non-doc content
        /^[[:space:]]*[^\/]/ && !/^[[:space:]]*$/ {
            if (in_doc) {
                doc = ""
                in_doc = 0
            }
        }
        ' "$file"

        echo "---"
        echo ""
    fi
done

cat << 'EOF'

## Architecture Overview

### State Management

Shebang uses a React-like state decomposition pattern:

- `AppState` - Root singleton containing all sub-stores
- `SessionState` - Manages terminal sessions
- `UIState` - UI visibility and preferences
- `FileState` - File browser state
- `TerminalState` - Terminal output and command queue

### View Components

| Component | Purpose |
|-----------|---------|
| `MainWindowView` | Root HSplitView layout |
| `SidebarView` | File browser with reactive CWD |
| `TerminalCanvasView` | Terminal display (interactive/block modes) |
| `SessionPanelView` | Session list and management |
| `CommandBarView` | Input with command routing |

### Command Routing

The `CommandRouter` enum handles input classification:

1. `/commands` → Internal Shebang commands
2. `$ prefix` → Explicit shell command
3. Known commands (`ls`, `git`, etc.) → Shell
4. Natural language → Claude Code AI

EOF
