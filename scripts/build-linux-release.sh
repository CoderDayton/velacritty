#!/usr/bin/env bash
#
# Build all Linux release artifacts for Velacritty
#
# Builds tar.gz archive and .deb package for Linux releases.
# Automatically extracts version from Cargo.toml.
#
# Usage:
#   ./scripts/build-linux-release.sh [VERSION] [--skip-build]
#
# Examples:
#   ./scripts/build-linux-release.sh
#   ./scripts/build-linux-release.sh 0.17.0 --skip-build

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
DIST_DIR="dist/linux"
BINARY_PATH="target/release/velacritty"

echo ""
echo -e "${MAGENTA}========================================${NC}"
echo -e "${MAGENTA}  Velacritty Linux Release Builder${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo -e "Version:      $VERSION"
echo -e "Output Dir:   $DIST_DIR"
echo -e "Skip Build:   $SKIP_BUILD"
echo -e "${MAGENTA}========================================${NC}"
echo ""

# Create output directory
mkdir -p "$DIST_DIR"
echo -e "${GREEN}✓ Created output directory: $DIST_DIR${NC}"

# Step 1: Build release binary
if [[ "$SKIP_BUILD" == false ]]; then
    echo -e "\n${YELLOW}[1/3] 🔨 Building release binary...${NC}"
    cargo build --release
    echo -e "${GREEN}✓ Binary built successfully${NC}"
else
    echo -e "\n${YELLOW}[1/3] ⏭️  Skipping cargo build (using existing binary)${NC}"
fi

# Validate binary exists
if [[ ! -f "$BINARY_PATH" ]]; then
    echo -e "${RED}❌ Binary not found: $BINARY_PATH${NC}" >&2
    exit 1
fi
BINARY_SIZE=$(du -h "$BINARY_PATH" | cut -f1)
echo -e "${GRAY}   Binary size: $BINARY_SIZE${NC}"

# Step 2: Generate manpages
echo -e "\n${YELLOW}[2/3] 📄 Generating manpages...${NC}"
MAN_DIR="$DIST_DIR/man"
mkdir -p "$MAN_DIR"

if command -v scdoc &> /dev/null; then
    scdoc < extra/man/alacritty.1.scd | gzip -c > "$MAN_DIR/velacritty.1.gz"
    scdoc < extra/man/alacritty-msg.1.scd | gzip -c > "$MAN_DIR/velacritty-msg.1.gz"
    scdoc < extra/man/alacritty.5.scd | gzip -c > "$MAN_DIR/velacritty.5.gz"
    scdoc < extra/man/alacritty-bindings.5.scd | gzip -c > "$MAN_DIR/velacritty-bindings.5.gz"
    echo -e "${GREEN}✓ Manpages generated${NC}"
else
    echo -e "${YELLOW}⚠️  scdoc not found, skipping manpage generation${NC}"
fi

# Step 3: Create tar.gz archive
echo -e "\n${YELLOW}[3/3] 📦 Creating release packages...${NC}"

TAR_NAME="$BUILD_NAME-x86_64-unknown-linux-gnu.tar.gz"
TAR_PATH="$DIST_DIR/$TAR_NAME"
TMP_TAR_DIR="$DIST_DIR/tmp-tar"

mkdir -p "$TMP_TAR_DIR/$BUILD_NAME"

# Copy files for tar.gz
cp "$BINARY_PATH" "$TMP_TAR_DIR/$BUILD_NAME/velacritty"
cp README.md LICENSE-APACHE LICENSE-MIT "$TMP_TAR_DIR/$BUILD_NAME/" 2>/dev/null || true

# Copy extras
if [[ -d "extra/completions" ]]; then
    cp -r extra/completions "$TMP_TAR_DIR/$BUILD_NAME/" 2>/dev/null || true
fi
if [[ -f "extra/linux/Velacritty.desktop" ]]; then
    cp extra/linux/Velacritty.desktop "$TMP_TAR_DIR/$BUILD_NAME/" 2>/dev/null || true
fi
if [[ -f "extra/velacritty.info" ]]; then
    cp extra/velacritty.info "$TMP_TAR_DIR/$BUILD_NAME/" 2>/dev/null || true
fi
if [[ -d "$MAN_DIR" ]]; then
    mkdir -p "$TMP_TAR_DIR/$BUILD_NAME/man"
    cp "$MAN_DIR"/*.gz "$TMP_TAR_DIR/$BUILD_NAME/man/" 2>/dev/null || true
fi

# Create archive
tar -czf "$TAR_PATH" -C "$TMP_TAR_DIR" "$BUILD_NAME"
rm -rf "$TMP_TAR_DIR"

TAR_SIZE=$(du -h "$TAR_PATH" | cut -f1)
echo -e "${GREEN}✓ tar.gz archive: $TAR_PATH ($TAR_SIZE)${NC}"

# Step 4: Create .deb package (if cargo-deb is available)
if command -v cargo-deb &> /dev/null; then
    echo -e "\n${CYAN}📦 Building .deb package...${NC}"

    # Check if metadata exists in Cargo.toml
    if grep -q '\[package\.metadata\.deb\]' velacritty/Cargo.toml; then
        cargo deb --manifest-path=velacritty/Cargo.toml --output="$DIST_DIR/$BUILD_NAME.deb"
        if [[ -f "$DIST_DIR/$BUILD_NAME.deb" ]]; then
            DEB_SIZE=$(du -h "$DIST_DIR/$BUILD_NAME.deb" | cut -f1)
            echo -e "${GREEN}✓ .deb package: $DIST_DIR/$BUILD_NAME.deb ($DEB_SIZE)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No [package.metadata.deb] section in Cargo.toml, skipping .deb build${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  cargo-deb not found, skipping .deb package${NC}"
    echo -e "${GRAY}   Install: cargo install cargo-deb${NC}"
fi

# Summary
echo ""
echo -e "${MAGENTA}========================================${NC}"
echo -e "${GREEN}  ✅ Build Complete!${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo -e "Artifacts created in $DIST_DIR:"
find "$DIST_DIR" -maxdepth 1 -type f -name "*$VERSION*" | while read -r file; do
    SIZE=$(du -h "$file" | cut -f1)
    echo -e "  ${CYAN}• $(basename "$file") ($SIZE)${NC}"
done
echo ""
