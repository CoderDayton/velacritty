#!/usr/bin/env bash
#
# Build all macOS release artifacts for Velacritty
#
# Builds universal binary (x86_64 + ARM64), .app bundle, and .dmg installer.
# Automatically extracts version from Cargo.toml.
#
# Usage:
#   ./scripts/build-macos-release.sh [VERSION] [--skip-build]
#
# Examples:
#   ./scripts/build-macos-release.sh
#   ./scripts/build-macos-release.sh 0.17.0 --skip-build

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

VERSION=""
SKIP_BUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        *)
            if [[ -z "$VERSION" ]]; then
                VERSION="$1"
            else
                echo -e "${RED}Error: Unknown argument: $1${NC}" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Extract version from Cargo.toml if not provided
if [[ -z "$VERSION" ]]; then
    echo -e "${CYAN}📦 Extracting version from Cargo.toml...${NC}"
    if VERSION=$(grep -oP '(?<=^version = ")[^"]+' velacritty/Cargo.toml | head -1); then
        echo -e "${GREEN}   Version detected: $VERSION${NC}"
    else
        echo -e "${RED}❌ Failed to extract version from velacritty/Cargo.toml${NC}" >&2
        exit 1
    fi
fi

# Validate version format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    echo -e "${RED}❌ Invalid version format: $VERSION (expected: X.Y.Z or X.Y.Z-suffix)${NC}" >&2
    exit 1
fi

BUILD_NAME="velacritty-v$VERSION"
DIST_DIR="dist/macos"
TARGET_X86="target/x86_64-apple-darwin/release/velacritty"
TARGET_ARM="target/aarch64-apple-darwin/release/velacritty"
UNIVERSAL_BINARY="target/release/velacritty-universal"

echo ""
echo -e "${MAGENTA}========================================${NC}"
echo -e "${MAGENTA}  Velacritty macOS Release Builder${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo -e "Version:      $VERSION"
echo -e "Output Dir:   $DIST_DIR"
echo -e "Skip Build:   $SKIP_BUILD"
echo -e "${MAGENTA}========================================${NC}"
echo ""

# Create output directory
mkdir -p "$DIST_DIR"
echo -e "${GREEN}✓ Created output directory: $DIST_DIR${NC}"

# Step 1: Build architecture-specific binaries
if [[ "$SKIP_BUILD" == false ]]; then
    echo -e "\n${YELLOW}[1/4] 🔨 Building release binaries...${NC}"

    # Build x86_64
    echo -e "${CYAN}   Building x86_64 binary...${NC}"
    cargo build --release --target=x86_64-apple-darwin
    echo -e "${GREEN}   ✓ x86_64 build complete${NC}"

    # Build ARM64
    echo -e "${CYAN}   Building ARM64 binary...${NC}"
    cargo build --release --target=aarch64-apple-darwin
    echo -e "${GREEN}   ✓ ARM64 build complete${NC}"
else
    echo -e "\n${YELLOW}[1/4] ⏭️  Skipping cargo build (using existing binaries)${NC}"
fi

# Validate binaries exist
if [[ ! -f "$TARGET_X86" ]]; then
    echo -e "${RED}❌ x86_64 binary not found: $TARGET_X86${NC}" >&2
    exit 1
fi
if [[ ! -f "$TARGET_ARM" ]]; then
    echo -e "${RED}❌ ARM64 binary not found: $TARGET_ARM${NC}" >&2
    exit 1
fi

X86_SIZE=$(du -h "$TARGET_X86" | cut -f1)
ARM_SIZE=$(du -h "$TARGET_ARM" | cut -f1)
echo -e "${GRAY}   x86_64 binary size: $X86_SIZE${NC}"
echo -e "${GRAY}   ARM64 binary size: $ARM_SIZE${NC}"

# Step 2: Create universal binary
echo -e "\n${YELLOW}[2/4] 🔗 Creating universal binary...${NC}"
lipo -create "$TARGET_X86" "$TARGET_ARM" -output "$UNIVERSAL_BINARY"
echo -e "${GREEN}✓ Universal binary created${NC}"

UNIVERSAL_SIZE=$(du -h "$UNIVERSAL_BINARY" | cut -f1)
echo -e "${GRAY}   Universal binary size: $UNIVERSAL_SIZE${NC}"

# Step 3: Create .app bundle
echo -e "\n${YELLOW}[3/4] 📦 Creating .app bundle...${NC}"

APP_BUNDLE="$DIST_DIR/Velacritty.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"

# Create directory structure
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
mkdir -p "$APP_RESOURCES"

# Copy universal binary
cp "$UNIVERSAL_BINARY" "$APP_MACOS/velacritty"
chmod +x "$APP_MACOS/velacritty"
echo -e "${GREEN}   ✓ Copied universal binary${NC}"

# Copy icon (if exists)
if [[ -f "extra/logo/velacritty-term.svg" ]]; then
    # Note: In production, should convert SVG to .icns using iconutil
    cp "extra/logo/velacritty-term.svg" "$APP_RESOURCES/velacritty.svg"
    echo -e "${YELLOW}   ⚠️  SVG icon copied (convert to .icns for production)${NC}"
elif [[ -f "extra/logo/alacritty-term.svg" ]]; then
    cp "extra/logo/alacritty-term.svg" "$APP_RESOURCES/velacritty.svg"
    echo -e "${YELLOW}   ⚠️  SVG icon copied (convert to .icns for production)${NC}"
fi

# Generate Info.plist
cat > "$APP_CONTENTS/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>velacritty</string>
    <key>CFBundleIdentifier</key>
    <string>org.velacritty.Velacritty</string>
    <key>CFBundleName</key>
    <string>Velacritty</string>
    <key>CFBundleDisplayName</key>
    <string>Velacritty</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleIconFile</key>
    <string>velacritty</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
</dict>
</plist>
EOF

echo -e "${GREEN}   ✓ Generated Info.plist${NC}"
echo -e "${GREEN}✓ .app bundle created: $APP_BUNDLE${NC}"

# Step 4: Create DMG
echo -e "\n${YELLOW}[4/4] 💿 Creating DMG installer...${NC}"

DMG_NAME="$BUILD_NAME-universal-macos.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
DMG_TEMP_DIR="$DIST_DIR/dmg-temp"

# Create temporary DMG directory
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"

# Copy .app bundle to temp directory
cp -R "$APP_BUNDLE" "$DMG_TEMP_DIR/"

# Create symbolic link to Applications
ln -s /Applications "$DMG_TEMP_DIR/Applications"

echo -e "${CYAN}   Creating DMG image...${NC}"

# Remove existing DMG if present
rm -f "$DMG_PATH"

# Create DMG
hdiutil create \
    -volname "Velacritty $VERSION" \
    -srcfolder "$DMG_TEMP_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# Clean up temp directory
rm -rf "$DMG_TEMP_DIR"

DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
echo -e "${GREEN}✓ DMG created: $DMG_PATH ($DMG_SIZE)${NC}"

# Optional: Code signing check
echo -e "\n${CYAN}🔐 Code Signing Status${NC}"
if command -v codesign &> /dev/null; then
    if codesign --verify --deep --strict "$APP_BUNDLE" 2>/dev/null; then
        echo -e "${GREEN}   ✓ App bundle is signed${NC}"
    else
        echo -e "${YELLOW}   ⚠️  App bundle is not code-signed${NC}"
        echo -e "${GRAY}   For distribution, sign with: codesign -s \"Developer ID\" -f --deep \"$APP_BUNDLE\"${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  codesign not available${NC}"
fi

# Summary
echo ""
echo -e "${MAGENTA}========================================${NC}"
echo -e "${GREEN}  ✅ Build Complete!${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo -e "Artifacts created in $DIST_DIR:"
find "$DIST_DIR" -maxdepth 1 -type f -name "*$VERSION*" -o -name "*.app" | while read -r file; do
    if [[ -f "$file" ]]; then
        SIZE=$(du -h "$file" | cut -f1)
        echo -e "  ${CYAN}• $(basename "$file") ($SIZE)${NC}"
    elif [[ -d "$file" ]]; then
        echo -e "  ${CYAN}• $(basename "$file") (app bundle)${NC}"
    fi
done
echo ""
echo -e "${GRAY}Note: For App Store or production distribution:${NC}"
echo -e "${GRAY}  1. Convert SVG icon to .icns format${NC}"
echo -e "${GRAY}  2. Code-sign with Apple Developer certificate${NC}"
echo -e "${GRAY}  3. Notarize the app bundle with Apple${NC}"
echo ""
