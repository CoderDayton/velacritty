#!/usr/bin/env bash
# Generate Velacritty icons from SVG sources in multiple formats and sizes
# Requires: Inkscape or ImageMagick + libsvg2

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGO_DIR="$REPO_ROOT/extra/logo"
COMPAT_DIR="$LOGO_DIR/compat"
OSX_RES_DIR="$REPO_ROOT/extra/osx/Velacritty.app/Contents/Resources"
WINDOWS_DIR="$REPO_ROOT/velacritty/windows"

# Create output directories
mkdir -p "$COMPAT_DIR" "$OSX_RES_DIR" "$WINDOWS_DIR"

# Define sizes
SIZES=(16 32 64 128 256 512)

echo "📦 Generating Velacritty icons..."

# ============================================================================
# Method 1: Try Inkscape (recommended for best quality)
# ============================================================================
if command -v inkscape &>/dev/null; then
    echo "  ✓ Using Inkscape"

    for size in "${SIZES[@]}"; do
        # Main icon
        inkscape \
            --export-type=png \
            --export-width="$size" \
            --export-height="$size" \
            "$LOGO_DIR/velacritty-term.svg" \
            -o "$COMPAT_DIR/velacritty-term_${size}x${size}.png"

        # Scanlines variant
        inkscape \
            --export-type=png \
            --export-width="$size" \
            --export-height="$size" \
            "$LOGO_DIR/velacritty-term+scanlines.svg" \
            -o "$COMPAT_DIR/velacritty-term+scanlines_${size}x${size}.png"

        echo "    Generated ${size}×${size} PNGs"
    done

# ============================================================================
# Method 2: Try ImageMagick convert + librsvg
# ============================================================================
elif command -v convert &>/dev/null; then
    echo "  ✓ Using ImageMagick"

    for size in "${SIZES[@]}"; do
        convert \
            -density 96 \
            -resize "${size}x${size}" \
            "$LOGO_DIR/velacritty-term.svg" \
            "$COMPAT_DIR/velacritty-term_${size}x${size}.png"

        convert \
            -density 96 \
            -resize "${size}x${size}" \
            "$LOGO_DIR/velacritty-term+scanlines.svg" \
            "$COMPAT_DIR/velacritty-term+scanlines_${size}x${size}.png"

        echo "    Generated ${size}×${size} PNGs"
    done

# ============================================================================
# Method 3: Try rsvg-convert
# ============================================================================
elif command -v rsvg-convert &>/dev/null; then
    echo "  ✓ Using rsvg-convert (librsvg2)"

    for size in "${SIZES[@]}"; do
        rsvg-convert \
            -w "$size" -h "$size" \
            "$LOGO_DIR/velacritty-term.svg" \
            -o "$COMPAT_DIR/velacritty-term_${size}x${size}.png"

        rsvg-convert \
            -w "$size" -h "$size" \
            "$LOGO_DIR/velacritty-term+scanlines.svg" \
            -o "$COMPAT_DIR/velacritty-term+scanlines_${size}x${size}.png"

        echo "    Generated ${size}×${size} PNGs"
    done

else
    echo "  ✗ ERROR: No SVG rendering tool found"
    echo ""
    echo "  Please install one of:"
    echo "    - Inkscape:  sudo apt install inkscape"
    echo "    - ImageMagick: sudo apt install imagemagick libsvg2"
    echo "    - rsvg-convert: sudo apt install librsvg2-bin"
    exit 1
fi

# ============================================================================
# Convert to Platform-Specific Formats
# ============================================================================

echo ""
echo "🎨 Converting to platform formats..."

# --- macOS: PNG → ICNS ---
if [ -f "$COMPAT_DIR/velacritty-term_512x512.png" ]; then
    if command -v magick &>/dev/null; then
        echo "  Converting to ICNS (macOS)..."
        magick "$COMPAT_DIR/velacritty-term_512x512.png" \
            -define icon:auto-resize=256,128,64,32,16 \
            "$OSX_RES_DIR/velacritty.icns"
        echo "    ✓ Created $OSX_RES_DIR/velacritty.icns"
    elif command -v sips &>/dev/null; then
        # macOS built-in tool
        echo "  Converting to ICNS (macOS sips)..."
        sips -s format icns "$COMPAT_DIR/velacritty-term_512x512.png" \
            --out "$OSX_RES_DIR/velacritty.icns"
        echo "    ✓ Created $OSX_RES_DIR/velacritty.icns"
    else
        echo "    ⚠ Skipping ICNS: install ImageMagick or use macOS sips"
    fi
fi

# --- Windows: PNGs → ICO ---
if [ -f "$COMPAT_DIR/velacritty-term_256x256.png" ] && command -v magick &>/dev/null; then
    echo "  Converting to ICO (Windows)..."
    magick "$COMPAT_DIR/velacritty-term_"*.png \
        -alpha off -background white \
        "$WINDOWS_DIR/velacritty.ico"
    echo "    ✓ Created $WINDOWS_DIR/velacritty.ico"
fi

# ============================================================================
# Verify
# ============================================================================

echo ""
echo "✅ Icon generation complete!"
echo ""
echo "Generated assets:"
ls -1 "$COMPAT_DIR"/velacritty-term* 2>/dev/null || echo "  (PNG files pending)"
[ -f "$OSX_RES_DIR/velacritty.icns" ] && echo "  ✓ $OSX_RES_DIR/velacritty.icns"
[ -f "$WINDOWS_DIR/velacritty.ico" ] && echo "  ✓ $WINDOWS_DIR/velacritty.ico"
