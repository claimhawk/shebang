#!/bin/bash
# Shebang Build Script
# Builds the app and creates a proper macOS app bundle

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Shebang"
BUNDLE_ID="com.shebang.app"
VERSION="1.0"
BUILD_VERSION="1"

echo "🔨 Building $APP_NAME..."

# Build in release mode
swift build --configuration release

echo "📦 Creating app bundle..."

# Create app bundle structure
rm -rf "$APP_NAME.app"
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# Copy binary
cp ".build/release/$APP_NAME" "$APP_NAME.app/Contents/MacOS/"

# Create Info.plist
cat > "$APP_NAME.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Shebang!</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "$APP_NAME.app/Contents/PkgInfo"

echo "✅ Build complete: $SCRIPT_DIR/$APP_NAME.app"

# Option to run
if [[ "$1" == "--run" || "$1" == "-r" ]]; then
    echo "🚀 Launching $APP_NAME..."
    open "$APP_NAME.app"
fi
