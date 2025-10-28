# Building Velacritty from Source

This guide covers building Velacritty release artifacts using the automated build scripts. For manual installation from source, see [INSTALL.md](../INSTALL.md).

## Table of Contents

- [Quick Start](#quick-start)
- [Build Scripts Overview](#build-scripts-overview)
- [Platform-Specific Instructions](#platform-specific-instructions)
  - [Linux](#linux)
  - [Windows](#windows)
  - [macOS](#macos)
- [Build Artifacts](#build-artifacts)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

**Prerequisites**: Rust toolchain (1.70+), platform-specific dependencies (see [INSTALL.md](../INSTALL.md#dependencies)).

```bash
# Clone repository
git clone https://github.com/CoderDayton/velacritty.git
cd velacritty

# Build for your platform
./scripts/build-linux-release.sh      # Linux
./scripts/build-macos-release.sh      # macOS
./scripts/build-windows-release.ps1   # Windows (PowerShell)
```

Artifacts will be created in `dist/`.

---

## Build Scripts Overview

All build scripts:
- Extract version automatically from `velacritty/Cargo.toml`
- Support custom version override via CLI argument
- Generate SHA256 checksums (`SHA256SUMS`) for all artifacts
- Provide colored terminal output with build progress
- Create release-ready distribution packages

### Common Options

```bash
# Use auto-detected version from Cargo.toml
./scripts/build-<platform>-release.sh

# Override version
./scripts/build-<platform>-release.sh 0.17.0

# Skip cargo build (reuse existing binary)
./scripts/build-<platform>-release.sh --skip-build
./scripts/build-<platform>-release.sh 0.17.0 --skip-build
```

---

## Platform-Specific Instructions

### Linux

**Script**: `scripts/build-linux-release.sh`

**Build Dependencies**:
```bash
# Debian/Ubuntu
sudo apt-get install -y \
    cmake pkg-config libfreetype6-dev libfontconfig1-dev \
    libxcb-xfixes0-dev libxkbcommon-dev python3

# Arch Linux
sudo pacman -S cmake freetype2 fontconfig pkg-config \
    libxcb libxkbcommon python

# Fedora
sudo dnf install cmake freetype-devel fontconfig-devel \
    libxcb-devel libxkbcommon-devel python3
```

**Optional Dependencies**:
- `scdoc` - Generate manual pages from `.scd` sources
- `cargo-deb` - Generate `.deb` packages (install: `cargo install cargo-deb`)

**Build Process**:
```bash
./scripts/build-linux-release.sh
```

**Artifacts Created**:
- `dist/velacritty-v<VERSION>.tar.gz` - Binary tarball with manpages, completions, desktop entry
- `dist/velacritty-v<VERSION>.deb` - Debian package (if cargo-deb installed and `[package.metadata.deb]` configured)
- `dist/SHA256SUMS` - SHA256 checksums for all artifacts

**What's Included in tar.gz**:
```
velacritty-v0.17.0/
├── velacritty                    # Binary
├── extra/
│   ├── completions/
│   │   ├── velacritty.bash
│   │   ├── velacritty.fish
│   │   └── _velacritty           # Zsh
│   ├── linux/
│   │   ├── Velacritty.desktop
│   │   └── org.velacritty.Velacritty.appdata.xml
│   └── logo/
│       └── velacritty-term.svg
└── extra/man/                    # If scdoc available
    ├── alacritty.1.gz
    ├── alacritty.5.gz
    ├── alacritty-msg.1.gz
    └── alacritty-bindings.5.gz
```

---

### Windows

**Script**: `scripts/build-windows-release.ps1`

**Build Dependencies**:
- **Rust toolchain**: `rustup-init.exe` (MSVC toolchain)
- **Visual Studio Build Tools** or **Visual Studio 2019+** with C++ development tools
- **WiX Toolset 4.x**: Download from https://wixtoolset.org/
  ```powershell
  # Verify WiX installation
  wix --version
  ```
- **Python 3**: For build automation

**Build Process**:
```powershell
# Run from PowerShell (not CMD)
.\scripts\build-windows-release.ps1

# Or with custom version
.\scripts\build-windows-release.ps1 -Version "0.17.0"

# Skip rebuild
.\scripts\build-windows-release.ps1 -SkipBuild
```

**Artifacts Created**:
- `dist/windows/Velacritty-v<VERSION>-portable.exe` - Standalone executable
- `dist/windows/Velacritty-v<VERSION>-portable.zip` - Portable archive with executable + config template
- `dist/windows/Velacritty-v<VERSION>-installer.msi` - Windows Installer package
- `dist/windows/SHA256SUMS` - SHA256 checksums

**MSI Installer Features**:
- Side-by-side installation with Alacritty (separate UpgradeCode)
- Per-user installation (no admin required)
- Optional PATH addition
- Optional desktop shortcut
- Automatic uninstallation via Windows Settings

**WiX Configuration**: `velacritty/windows/wix/velacritty.wxs`

---

### macOS

**Script**: `scripts/build-macos-release.sh`

**Build Dependencies**:
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Rust toolchain with both architectures
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin
```

**Optional Dependencies**:
- `scdoc` - Generate manual pages (install via Homebrew: `brew install scdoc`)
- `iconutil` - Convert SVG icons to `.icns` format (included in Xcode)

**Build Process**:
```bash
./scripts/build-macos-release.sh

# Or with custom version
./scripts/build-macos-release.sh 0.17.0

# Skip rebuild
./scripts/build-macos-release.sh --skip-build
```

**Artifacts Created**:
- `dist/Velacritty.app/` - Universal `.app` bundle (Intel + Apple Silicon)
- `dist/velacritty-v<VERSION>-universal-macos.dmg` - Disk image installer
- `dist/SHA256SUMS` - SHA256 checksums

**Universal Binary**:
- Built for both `x86_64` (Intel) and `aarch64` (Apple Silicon)
- Combined using `lipo` for single fat binary
- Works natively on all macOS hardware

**App Bundle Structure**:
```
Velacritty.app/
├── Contents/
│   ├── Info.plist              # App metadata
│   ├── MacOS/
│   │   └── velacritty          # Universal binary
│   └── Resources/
│       └── velacritty.svg      # App icon (convert to .icns for production)
```

**DMG Installer**:
- Drag-and-drop installation
- Symbolic link to `/Applications` for easy install
- Volume label: "Velacritty <VERSION>"

**Code Signing** (for distribution):
```bash
# Sign app bundle
codesign -s "Developer ID Application: Your Name" \
    -f --deep "dist/Velacritty.app"

# Notarize with Apple (requires Apple Developer account)
xcrun notarytool submit "dist/velacritty-v<VERSION>-universal-macos.dmg" \
    --apple-id "your@email.com" \
    --team-id "TEAM_ID" \
    --password "app-specific-password" \
    --wait

# Staple notarization ticket
xcrun stapler staple "dist/Velacritty.app"
```

---

## Build Artifacts

### Directory Structure

After running a build script:

```
velacritty/
├── dist/                              # All platforms
│   ├── SHA256SUMS                     # Linux/macOS checksums
│   ├── velacritty-v0.17.0.tar.gz     # Linux tarball
│   ├── velacritty-v0.17.0.deb        # Linux Debian package
│   ├── Velacritty.app/               # macOS app bundle
│   ├── velacritty-v0.17.0-universal-macos.dmg  # macOS installer
│   └── windows/                       # Windows artifacts
│       ├── SHA256SUMS
│       ├── Velacritty-v0.17.0-portable.exe
│       ├── Velacritty-v0.17.0-portable.zip
│       └── Velacritty-v0.17.0-installer.msi
└── target/
    └── release/
        └── velacritty                 # Compiled binary (all platforms)
```

### Versioning

Version is automatically extracted from `velacritty/Cargo.toml`:
```toml
[package]
version = "0.17.0-dev"
```

The `-dev` suffix is stripped for release artifact names.

---

## Verification

### Checksum Verification

**Linux/macOS**:
```bash
cd dist
sha256sum -c SHA256SUMS
# or on macOS:
shasum -a 256 -c SHA256SUMS
```

**Windows** (PowerShell):
```powershell
cd dist\windows
Get-Content SHA256SUMS | ForEach-Object {
    $hash, $file = $_ -split '  '
    $computed = (Get-FileHash $file -Algorithm SHA256).Hash.ToLower()
    if ($hash -eq $computed) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ $file" -ForegroundColor Red
    }
}
```

### Test Builds

**Linux**:
```bash
# Test tarball
tar -tzf dist/velacritty-v0.17.0.tar.gz
tar -xzf dist/velacritty-v0.17.0.tar.gz
./velacritty-v0.17.0/velacritty --version

# Test .deb package
dpkg-deb -c dist/velacritty-v0.17.0.deb
sudo dpkg -i dist/velacritty-v0.17.0.deb
velacritty --version
```

**macOS**:
```bash
# Test app bundle
open dist/Velacritty.app

# Test DMG
hdiutil attach dist/velacritty-v0.17.0-universal-macos.dmg
# Drag Velacritty.app to /Applications
hdiutil detach /Volumes/Velacritty\ 0.17.0

# Verify universal binary
lipo -info /Applications/Velacritty.app/Contents/MacOS/velacritty
# Expected: Architectures in the fat file: x86_64 arm64
```

**Windows**:
```powershell
# Test portable executable
.\dist\windows\Velacritty-v0.17.0-portable.exe --version

# Test MSI installer (uninstall via Settings afterward)
msiexec /i dist\windows\Velacritty-v0.17.0-installer.msi /qn
"$env:LOCALAPPDATA\Programs\Velacritty\velacritty.exe" --version
```

---

## Troubleshooting

### Linux

**Error: `cargo-deb not found`**
```bash
cargo install cargo-deb
```

**Error: `scdoc not found`**
```bash
# Debian/Ubuntu
sudo apt-get install scdoc

# Arch Linux
sudo pacman -S scdoc

# Build continues without manpages if missing
```

**Error: Missing shared libraries**
```bash
# Check binary dependencies
ldd target/release/velacritty

# Install missing libraries (Debian/Ubuntu example)
sudo apt-get install libfontconfig1 libfreetype6 libxcb-xfixes0 libxkbcommon0
```

### Windows

**Error: `wix: command not found`**
- Download WiX Toolset 4.x from https://wixtoolset.org/
- Add WiX to PATH: `C:\Program Files\WiX Toolset\bin`
- Restart PowerShell

**Error: `MSVC toolchain not found`**
```powershell
# Install Visual Studio Build Tools
# https://visualstudio.microsoft.com/downloads/
# Select "Desktop development with C++"

# Or use rustup to switch toolchain
rustup default stable-msvc
```

**Error: WiX build fails with `LGHT0217` (DuplicateUpgradeCode)**
- Velacritty uses a unique UpgradeCode to allow side-by-side installation with Alacritty
- If you see this error, ensure `velacritty/windows/wix/velacritty.wxs` has a different UpgradeCode than Alacritty

### macOS

**Error: `Target aarch64-apple-darwin not installed`**
```bash
rustup target add aarch64-apple-darwin
```

**Error: `Target x86_64-apple-darwin not installed`**
```bash
rustup target add x86_64-apple-darwin
```

**Error: `lipo: can't open input file`**
- Ensure both architectures built successfully
- Check `target/x86_64-apple-darwin/release/` and `target/aarch64-apple-darwin/release/`
- Run without `--skip-build` to rebuild both targets

**Warning: App icon is SVG instead of .icns**
```bash
# Convert SVG to .icns (requires iconutil from Xcode)
brew install librsvg  # For rsvg-convert
rsvg-convert -w 1024 -h 1024 extra/logo/velacritty-term.svg > /tmp/velacritty-1024.png
mkdir velacritty.iconset
sips -z 16 16     /tmp/velacritty-1024.png --out velacritty.iconset/icon_16x16.png
sips -z 32 32     /tmp/velacritty-1024.png --out velacritty.iconset/icon_16x16@2x.png
sips -z 32 32     /tmp/velacritty-1024.png --out velacritty.iconset/icon_32x32.png
sips -z 64 64     /tmp/velacritty-1024.png --out velacritty.iconset/icon_32x32@2x.png
sips -z 128 128   /tmp/velacritty-1024.png --out velacritty.iconset/icon_128x128.png
sips -z 256 256   /tmp/velacritty-1024.png --out velacritty.iconset/icon_128x128@2x.png
sips -z 256 256   /tmp/velacritty-1024.png --out velacritty.iconset/icon_256x256.png
sips -z 512 512   /tmp/velacritty-1024.png --out velacritty.iconset/icon_256x256@2x.png
sips -z 512 512   /tmp/velacritty-1024.png --out velacritty.iconset/icon_512x512.png
sips -z 1024 1024 /tmp/velacritty-1024.png --out velacritty.iconset/icon_512x512@2x.png
iconutil -c icns velacritty.iconset -o velacritty.icns
```

---

## CI/CD Integration

The build scripts are designed for both local development and CI/CD pipelines.

### GitHub Actions Example

See `.github/workflows/release.yml` for the production release workflow.

**Key CI features**:
- Dependency caching for faster builds
- Artifact upload to GitHub Releases
- Cross-platform matrix builds (Linux, macOS, Windows)
- Automatic checksum verification

### Local CI Testing

```bash
# Simulate CI environment
export CI=true

# Build with verbose output
./scripts/build-linux-release.sh 2>&1 | tee build.log

# Check exit codes
echo $?  # Should be 0 on success
```

---

## Additional Resources

- **Installation Guide**: [INSTALL.md](../INSTALL.md) - Manual installation from source
- **Release Workflow**: `.github/workflows/release.yml` - Automated release process
- **WiX Configuration**: `velacritty/windows/wix/velacritty.wxs` - Windows installer customization
- **Cargo Metadata**: `velacritty/Cargo.toml` - Package metadata for cargo-deb

---

## Contributing

When modifying build scripts:

1. **Test on target platform** before committing
2. **Update this document** if adding new features or dependencies
3. **Maintain checksum generation** for all new artifact types
4. **Follow script conventions**: colored output, error handling, version extraction
5. **Keep scripts idempotent**: safe to run multiple times

**Questions?** Open an issue at https://github.com/CoderDayton/velacritty/issues
