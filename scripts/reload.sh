#!/bin/bash
# Reload Shebang - rebuild and restart the app
# Called by /reload slash command

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🔄 Rebuilding Shebang..."
./build.sh

echo "🔄 Restarting app..."
osascript -e 'quit app "Shebang"' 2>/dev/null || true
sleep 1
open Shebang.app

echo "✅ Shebang reloaded!"
