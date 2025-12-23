#!/bin/bash
# dev-build.sh - Build and hot-reload Shebang app
#
# Usage: ./dev-build.sh [--watch]
#   --watch: Continuously watch for changes and rebuild

set -e

APP_NAME="ShebangApp"
BUILD_DIR=".build/debug"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() { echo -e "${GREEN}→${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

kill_app() {
    if pgrep -x "$APP_NAME" > /dev/null 2>&1; then
        log "Stopping running $APP_NAME..."
        pkill -x "$APP_NAME" 2>/dev/null || true
        sleep 0.5
    fi
}

build_and_run() {
    log "Building $APP_NAME..."

    if swift build 2>&1; then
        log "Build successful"

        kill_app

        log "Launching $APP_NAME..."
        "$BUILD_DIR/$APP_NAME" &
        disown

        echo -e "${GREEN}✓${NC} $APP_NAME is running (PID: $!)"
    else
        error "Build failed"
        return 1
    fi
}

# Watch mode using fswatch
watch_and_rebuild() {
    if ! command -v fswatch &> /dev/null; then
        error "fswatch not installed. Install with: brew install fswatch"
        exit 1
    fi

    log "Starting watch mode... (Ctrl+C to stop)"
    log "Watching Sources/ for changes"

    # Initial build
    build_and_run

    # Watch for changes
    fswatch -o Sources/ | while read; do
        echo ""
        warn "Change detected, rebuilding..."
        build_and_run
    done
}

# Main
case "${1:-}" in
    --watch|-w)
        watch_and_rebuild
        ;;
    *)
        build_and_run
        ;;
esac
