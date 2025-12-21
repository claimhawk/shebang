#!/bin/bash
# Build documentation from Markdown to HTML
# Source: docs/*.md → Output: site/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCS_DIR="$PROJECT_ROOT/docs"
SITE_DIR="$PROJECT_ROOT/site"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}📚 Building Shebang documentation...${NC}"

# Find mkdocs - try PATH first, then user site-packages
MKDOCS="mkdocs"
if ! command -v mkdocs &> /dev/null; then
    # Check user Python bin directory
    USER_BIN="$HOME/Library/Python/3.9/bin"
    if [ -x "$USER_BIN/mkdocs" ]; then
        MKDOCS="$USER_BIN/mkdocs"
    else
        echo -e "${YELLOW}mkdocs not found. Installing...${NC}"
        pip3 install --user mkdocs mkdocs-material
        MKDOCS="$USER_BIN/mkdocs"
    fi
fi

# Copy root docs to docs folder for building
echo "Copying documentation files..."
cp "$PROJECT_ROOT/README.md" "$DOCS_DIR/index.md" 2>/dev/null || true
cp "$PROJECT_ROOT/PHILOSOPHY.md" "$DOCS_DIR/PHILOSOPHY.md" 2>/dev/null || true
cp "$PROJECT_ROOT/VOICE.md" "$DOCS_DIR/VOICE.md" 2>/dev/null || true

# Generate Swift API docs from docstrings
echo "Extracting Swift documentation..."
mkdir -p "$DOCS_DIR/api"
"$SCRIPT_DIR/extract-swift-docs.sh" > "$DOCS_DIR/api/swift.md"

# Build docs (mkdocs.yml is now at project root)
cd "$PROJECT_ROOT"
$MKDOCS build

echo -e "${GREEN}✅ Documentation built to: $SITE_DIR${NC}"
echo ""
echo "To preview locally: mkdocs serve"
echo "Then open: http://127.0.0.1:8000"
