<#
.SYNOPSIS
    Build all Windows release artifacts for Velacritty
.DESCRIPTION
    Builds portable executables, ZIP package, and MSI installer for Windows releases.
    Automatically extracts version from Cargo.toml.
.PARAMETER Version
    Override version string (default: reads from velacritty/Cargo.toml)
.PARAMETER SkipBuild
    Skip cargo build step (use existing target/release/velacritty.exe)
.EXAMPLE
    .\scripts\build-windows-release.ps1
.EXAMPLE
    .\scripts\build-windows-release.ps1 -Version "0.17.0" -SkipBuild
#>

[CmdletBinding()]
param(
    [string]$Version = "",
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"

# Get script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Push-Location $ProjectRoot

try {
    # Extract version from Cargo.toml if not provided
    if ([string]::IsNullOrWhiteSpace($Version)) {
        Write-Host "📦 Extracting version from Cargo.toml..." -ForegroundColor Cyan
        $CargoToml = Get-Content "velacritty\Cargo.toml" -Raw
        if ($CargoToml -match 'version\s*=\s*"([^"]+)"') {
            $Version = $matches[1]
            Write-Host "   Version detected: $Version" -ForegroundColor Green
        } else {
            throw "Failed to extract version from velacritty/Cargo.toml"
        }
    }

    # Validate version format
    if ($Version -notmatch '^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$') {
        throw "Invalid version format: $Version (expected: X.Y.Z or X.Y.Z-suffix)"
    }

    $BuildName = "Velacritty-v$Version"
    $DistDir = "dist\windows"
    $BinaryPath = "target\release\velacritty.exe"

    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "  Velacritty Windows Release Builder" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "Version:      $Version" -ForegroundColor White
    Write-Host "Output Dir:   $DistDir" -ForegroundColor White
    Write-Host "Skip Build:   $SkipBuild" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Magenta

    # Create output directory
    if (-not (Test-Path $DistDir)) {
        New-Item -ItemType Directory -Path $DistDir | Out-Null
        Write-Host "✓ Created output directory: $DistDir" -ForegroundColor Green
    }

    # Step 1: Build release binary
    if (-not $SkipBuild) {
        Write-Host "`n[1/3] 🔨 Building release binary..." -ForegroundColor Yellow
        cargo build --release
        if ($LASTEXITCODE -ne 0) {
            throw "Cargo build failed with exit code $LASTEXITCODE"
        }
        Write-Host "✓ Binary built successfully" -ForegroundColor Green
    } else {
        Write-Host "`n[1/3] ⏭️  Skipping cargo build (using existing binary)" -ForegroundColor Yellow
    }

    # Validate binary exists
    if (-not (Test-Path $BinaryPath)) {
        throw "Binary not found: $BinaryPath"
    }
    $BinarySize = (Get-Item $BinaryPath).Length / 1MB
    Write-Host "   Binary size: $([math]::Round($BinarySize, 2)) MB" -ForegroundColor Gray

    # Step 2: Create portable packages
    Write-Host "`n[2/3] 📦 Creating portable packages..." -ForegroundColor Yellow

    # Standalone executable
    $PortableExe = "$DistDir\$BuildName-portable.exe"
    Copy-Item $BinaryPath $PortableExe -Force
    Write-Host "✓ Standalone: $PortableExe" -ForegroundColor Green

    # ZIP package with extras
    $PortableZip = "$DistDir\$BuildName-portable.zip"
    $ZipItems = @(
        "target\release\velacritty.exe",
        "README.md",
        "LICENSE-APACHE",
        "LICENSE-MIT"
    )

    # Add completions if they exist
    if (Test-Path "extra\completions") {
        $ZipItems += Get-ChildItem "extra\completions\*" | Select-Object -ExpandProperty FullName
    }

    Compress-Archive -Path $ZipItems -DestinationPath $PortableZip -Force
    $ZipSize = (Get-Item $PortableZip).Length / 1MB
    Write-Host "✓ ZIP package: $PortableZip ($([math]::Round($ZipSize, 2)) MB)" -ForegroundColor Green

    # Step 3: Create MSI installer
    Write-Host "`n[3/3] 🛠️  Building MSI installer..." -ForegroundColor Yellow

    $MsiPath = "$DistDir\$BuildName-installer.msi"
    $WixArgs = @(
        "build",
        "-arch", "x64",
        "-ext", "WixToolset.UI.wixext",
        "-ext", "WixToolset.Util.wixext",
        "-out", $MsiPath,
        "velacritty\windows\wix\velacritty.wxs"
    )

    & wix @WixArgs
    if ($LASTEXITCODE -ne 0) {
        throw "WiX build failed with exit code $LASTEXITCODE"
    }

    if (Test-Path $MsiPath) {
        $MsiSize = (Get-Item $MsiPath).Length / 1MB
        Write-Host "✓ MSI installer: $MsiPath ($([math]::Round($MsiSize, 2)) MB)" -ForegroundColor Green
    } else {
        throw "MSI installer not found after build: $MsiPath"
    }

    # Summary
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "  ✅ Build Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "Artifacts created in $DistDir:" -ForegroundColor White
    Get-ChildItem $DistDir | Where-Object { $_.Name -like "$BuildName*" } | ForEach-Object {
        $Size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  • $($_.Name) ($Size MB)" -ForegroundColor Cyan
    }
    Write-Host ""

} catch {
    Write-Host "`n❌ Build failed: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
