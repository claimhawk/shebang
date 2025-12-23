#!/bin/bash
# Shebang Build Script
# Builds the app and creates a proper macOS app bundle

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Shebang"
BUNDLE_ID="com.shebang.app"

# Read version from VERSION file (semantic versioning)
VERSION_FILE="$SCRIPT_DIR/VERSION"
if [[ -f "$VERSION_FILE" ]]; then
    VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
    VERSION="0.0.1"
    echo "$VERSION" > "$VERSION_FILE"
fi

# Auto-bump patch version if --bump flag is passed
if [[ "$1" == "--bump" || "$2" == "--bump" ]]; then
    IFS='.' read -r major minor patch <<< "$VERSION"
    patch=$((patch + 1))
    VERSION="$major.$minor.$patch"
    echo "$VERSION" > "$VERSION_FILE"
    echo "📦 Bumped version to $VERSION"
fi

# Build version is patch number
IFS='.' read -r major minor patch <<< "$VERSION"
BUILD_VERSION="$patch"

echo "🔨 Building $APP_NAME..."

# Preprocess icon (add macOS bezel) if needed
ICON_SOURCE="$SCRIPT_DIR/Assets/AppIcon.png"
ICON_PROCESSED="$SCRIPT_DIR/Assets/AppIcon_processed.png"
if [[ -f "$ICON_SOURCE" ]] && command -v python3 &> /dev/null; then
    echo "🎨 Preprocessing app icon..."
    python3 "$SCRIPT_DIR/scripts/preprocess-icon.py" "$ICON_SOURCE" -o "$ICON_PROCESSED" --padding 0.10 2>/dev/null && \
        ICON_SOURCE="$ICON_PROCESSED"
fi

# Build in release mode
swift build --configuration release

echo "📦 Creating app bundle..."

# Create app bundle structure
rm -rf "$APP_NAME.app"
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# Copy binary
cp ".build/release/$APP_NAME" "$APP_NAME.app/Contents/MacOS/"

# Create icon if source PNG exists (use processed version if available)
if [[ -f "$ICON_PROCESSED" ]]; then
    ICON_FOR_ICNS="$ICON_PROCESSED"
else
    ICON_FOR_ICNS="$SCRIPT_DIR/Assets/AppIcon.png"
fi
ICON_DEST="$APP_NAME.app/Contents/Resources/AppIcon.icns"

if [[ -f "$ICON_FOR_ICNS" ]]; then
    echo "🎨 Creating app icon from ${ICON_FOR_ICNS}..."
    # Create iconset directory
    ICONSET="$SCRIPT_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET"

    # Generate all required sizes
    sips -z 16 16     "$ICON_FOR_ICNS" --out "$ICONSET/icon_16x16.png" 2>/dev/null
    sips -z 32 32     "$ICON_FOR_ICNS" --out "$ICONSET/icon_16x16@2x.png" 2>/dev/null
    sips -z 32 32     "$ICON_FOR_ICNS" --out "$ICONSET/icon_32x32.png" 2>/dev/null
    sips -z 64 64     "$ICON_FOR_ICNS" --out "$ICONSET/icon_32x32@2x.png" 2>/dev/null
    sips -z 128 128   "$ICON_FOR_ICNS" --out "$ICONSET/icon_128x128.png" 2>/dev/null
    sips -z 256 256   "$ICON_FOR_ICNS" --out "$ICONSET/icon_128x128@2x.png" 2>/dev/null
    sips -z 256 256   "$ICON_FOR_ICNS" --out "$ICONSET/icon_256x256.png" 2>/dev/null
    sips -z 512 512   "$ICON_FOR_ICNS" --out "$ICONSET/icon_256x256@2x.png" 2>/dev/null
    sips -z 512 512   "$ICON_FOR_ICNS" --out "$ICONSET/icon_512x512.png" 2>/dev/null
    sips -z 1024 1024 "$ICON_FOR_ICNS" --out "$ICONSET/icon_512x512@2x.png" 2>/dev/null

    # Convert to icns
    iconutil -c icns "$ICONSET" -o "$ICON_DEST"
    rm -rf "$ICONSET"

    ICON_KEY="<key>CFBundleIconFile</key>
    <string>AppIcon</string>"
else
    echo "⚠️  No icon found at $ICON_FOR_ICNS - using default"
    ICON_KEY=""
fi

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
    $ICON_KEY
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "$APP_NAME.app/Contents/PkgInfo"

# Sign with entitlements for persistent permissions
ENTITLEMENTS="$SCRIPT_DIR/Shebang.entitlements"
if [[ -f "$ENTITLEMENTS" ]]; then
    echo "🔐 Signing with entitlements..."
    codesign --force --deep --sign - --entitlements "$ENTITLEMENTS" "$APP_NAME.app"
fi

echo "✅ Build complete: $SCRIPT_DIR/$APP_NAME.app"

# Option to run
if [[ "$1" == "--run" || "$1" == "-r" ]]; then
    echo "🚀 Launching $APP_NAME..."
    open "$APP_NAME.app"
fi
