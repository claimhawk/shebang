#!/bin/bash
# Pack the .shebang knowledge base into a zip archive for new projects
#
# Usage: ./scripts/pack-shebang.sh
#
# Creates: Sources/ShebangApp/Resources/shebang.zip
#
# The zip contains the full .shebang folder structure that gets extracted
# into every new project created with Shebang.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHEBANG_ROOT="$(dirname "$SCRIPT_DIR")"
SHEBANG_DIR="$SHEBANG_ROOT/.shebang"
DOCS_DIR="$SHEBANG_ROOT/docs"
WEB_DIR="$SHEBANG_ROOT/web"
OUTPUT_DIR="$SHEBANG_ROOT/Sources/ShebangApp/Resources"
OUTPUT_FILE="$OUTPUT_DIR/shebang.zip"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "Packing .shebang knowledge base..."

# Create temp directory for assembling the archive structure
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Create the .shebang directory structure in temp
TEMP_SHEBANG="$TEMP_DIR/.shebang"
mkdir -p "$TEMP_SHEBANG"

# Knowledge base files to include from .shebang/
KNOWLEDGE_FILES=(
    "ANTI_PATTERNS.md"
    "BEST_PRACTICES.md"
    "CODE_QUALITY.md"
    "system.md"
    "TESTING.md"
    "TESTING_ANTIPATTERNS.md"
    "TESTING_BY_LANGUAGE.md"
    "TESTING_PRACTICES.md"
    "VOICE.md"
)

echo "  Knowledge base files:"
for file in "${KNOWLEDGE_FILES[@]}"; do
    if [[ -f "$SHEBANG_DIR/$file" ]]; then
        cp "$SHEBANG_DIR/$file" "$TEMP_SHEBANG/"
        echo "    + $file"
    fi
done

# Copy templates subdirectory
if [[ -d "$SHEBANG_DIR/templates" ]]; then
    cp -r "$SHEBANG_DIR/templates" "$TEMP_SHEBANG/"
    echo "    + templates/"
fi

# Copy docs to .shebang/docs/
if [[ -d "$DOCS_DIR" ]]; then
    echo "  Documentation:"
    mkdir -p "$TEMP_SHEBANG/docs"
    # Copy key documentation files (exclude marketing and build-specific)
    DOCS_FILES=(
        "PHILOSOPHY.md"
        "USER_GUIDE.md"
        "POWER_USER_GUIDE.md"
        "ARCHITECTURE_DIAGRAM.md"
        "FEATURES.md"
        "ROADMAP.md"
    )
    for file in "${DOCS_FILES[@]}"; do
        if [[ -f "$DOCS_DIR/$file" ]]; then
            cp "$DOCS_DIR/$file" "$TEMP_SHEBANG/docs/"
            echo "    + docs/$file"
        fi
    done
fi

# Copy web folder to .shebang/web/
if [[ -d "$WEB_DIR" ]]; then
    echo "  Web assets:"
    cp -r "$WEB_DIR" "$TEMP_SHEBANG/"
    echo "    + web/ (full directory)"
fi

# Create the zip archive
cd "$TEMP_DIR"
rm -f "$OUTPUT_FILE"
zip -rq "$OUTPUT_FILE" .shebang

# Show result
SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
FILE_COUNT=$(unzip -l "$OUTPUT_FILE" | tail -1 | awk '{print $2}')
echo ""
echo "Created: $OUTPUT_FILE"
echo "  Size: $SIZE"
echo "  Files: $FILE_COUNT"
echo ""
echo "This archive is bundled with the Shebang app and extracted into"
echo "new projects created via the 'New Project' button."
