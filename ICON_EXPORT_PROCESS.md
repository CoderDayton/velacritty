# Velacritty Icon Export Process

## Status
✅ SVG source files created with color-swapped gradients:
- `extra/logo/velacritty-term.svg` (cyan → purple)
- `extra/logo/velacritty-term+scanlines.svg` (variant)

## Next Steps: Rasterize to PNG

### Option 1: Inkscape (Recommended for best quality)
```bash
# Export at different DPI settings for multi-size support
inkscape --export-type=png --export-dpi=96  extra/logo/velacritty-term.svg -o extra/logo/compat/velacritty-term_64x64.png
inkscape --export-type=png --export-dpi=192 extra/logo/velacritty-term.svg -o extra/logo/compat/velacritty-term_128x128.png
```

### Option 2: ImageMagick `convert`
```bash
convert -density 96 -resize 64x64 extra/logo/velacritty-term.svg extra/logo/compat/velacritty-term_64x64.png
convert -density 96 -resize 512x512 extra/logo/velacritty-term.svg extra/logo/compat/velacritty-term_512x512.png
```

### Option 3: rsvg-convert (librsvg)
```bash
rsvg-convert -w 64 -h 64 extra/logo/velacritty-term.svg -o extra/logo/compat/velacritty-term_64x64.png
```

## Icon Sizes Required

| Size | Platform | Use Case |
|------|----------|----------|
| 16×16 | Windows, Linux | Taskbar, menu |
| 32×32 | Windows, macOS | General icon |
| 64×64 | Linux | Standard icon |
| 128×128 | macOS | Dock preview |
| 256×256 | macOS, Windows | Finder/Explorer |
| 512×512 | macOS, Linux | High-res display |

## Platform-Specific Conversions

### macOS: PNG → ICNS
```bash
# Using ImageMagick
magick velacritty-term_512x512.png -define icon:auto-resize=256,128,64,32,16 extra/osx/Velacritty.app/Contents/Resources/velacritty.icns

# Or using sips (macOS built-in)
sips -s format icns velacritty-term_512x512.png --out velacritty.icns
```

### Windows: PNG → ICO
```bash
magick velacritty-term*.png -alpha off -background white velacritty.ico
```

### Linux: Use PNG directly in desktop files
PNG files are referenced directly in `.desktop` files and AppData XML.

## Build System Integration

Once tools are available, add to `Makefile` or CI:
```makefile
.PHONY: icons
icons:
	@echo "Exporting icons..."
	inkscape --export-type=png -w 64 -h 64 extra/logo/velacritty-term.svg -o extra/logo/compat/velacritty-term_64x64.png
	# ... repeat for other sizes
```

## Status Tracking
- [ ] SVG source files created
- [ ] 64×64 PNG exported
- [ ] 256×256 PNG exported
- [ ] 512×512 PNG exported
- [ ] ICNS created (macOS)
- [ ] ICO created (Windows)
- [ ] Desktop file updated with icon path
- [ ] App bundle rebuilt and tested
