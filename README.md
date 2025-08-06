<!--  README badges  -->
<a href="https://github.com/Julian-Bruyers/svg2icon/releases"><img src="https://img.shields.io/github/v/release/Julian-Bruyers/svg2icon?label=Latest&labelColor=2D3748&color=003087"></a>
<a href="https://github.com/Julian-Bruyers/svg2icon/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Julian-Bruyers/svg2icon?&label=License&logo=opensourceinitiative&logoColor=ffffff&labelColor=2D3748&color=2D3748"></a>
<a href="https://goreportcard.com/report/github.com/Julian-Bruyers/svg2icon"><img src="https://goreportcard.com/badge/github.com/Julian-Bruyers/svg2icon"></a>
<a href="#installation"><img src="https://img.shields.io/badge/Go-00ADD8?logo=go&logoColor=white&labelColor=2D3748&color=2D3748" align="right"></a>
<a href="#platform-support"><img src="https://img.shields.io/badge/Linux-E95420?logo=linux&logoColor=white" align="right"></a>
<a href="#platform-support"><img src="https://custom-icon-badges.demolab.com/badge/Windows-0078D6?logo=windows11&logoColor=white" align="right"></a>
<a href="#platform-support"><img src="https://img.shields.io/badge/macOS-333333?logo=apple&logoColor=F0F0F0" align="right"></a>

# svg2icon
A fast and lightweight command-line tool for converting SVG files to platform-specific icon formats. Generates high-quality ICO files for Windows and ICNS files for macOS from SVG sources.

## Features

- **Cross-platform support**: Windows, macOS, and Linux
- **Multiple output formats**: ICO (Windows) and ICNS (macOS)
- **High-quality rendering**: Vector-based conversion with anti-aliasing
- **Multiple resolutions**: Generates all standard icon sizes automatically
- **Retina support**: Includes high-DPI variants for modern displays
- **Simple interface**: Single command with flexible output options
- **No dependencies**: Standalone binary with no external requirements

## Installation

### Quick Install

**Unix/Linux/macOS:**

```bash
curl -sSL https://raw.githubusercontent.com/Julian-Bruyers/svg2icon/main/scripts/install.sh | bash
```

**Windows PowerShell:**

```powershell
iwr -useb https://raw.githubusercontent.com/Julian-Bruyers/svg2icon/main/scripts/install.ps1 | iex
```

### Manual Installation

1. Download the appropriate binary from the [releases page](https://github.com/Julian-Bruyers/svg2icon/releases)
2. Rename it to `svg2icon` (or `svg2icon.exe` on Windows)
3. Place it in your PATH

### Build from Source

**Prerequisites:**

- Go 1.21 or later

**Clone and build:**

```bash
git clone https://github.com/Julian-Bruyers/svg2icon.git
cd svg2icon
go build -o svg2icon .
```

**Unix/Linux/macOS**
```bash
./scripts/build.sh
```

**Windows**
```bash
scripts\build.bat
```

## Usage

**Basic Syntax**

```bash
svg2icon <input.svg> <output>
```

**Generate ICO file only:**

```bash
svg2icon input.svg output.ico
```

**Generate ICNS file only:**

```bash
svg2icon input.svg output.icns
```

**Generate both formats in directory:**

```bash
svg2icon input.svg ./icons/
# Creates: icons/input.ico and icons/input.icns
```

**Generate both formats with custom name:**

```bash
svg2icon input.svg myicon.icon
# Creates: myicon.ico and myicon.icns
```

### Examples

```bash
# Convert app icon for Windows
svg2icon app-icon.svg app.ico

# Convert app icon for macOS
svg2icon app-icon.svg app.icns

# Generate both formats
svg2icon app-icon.svg ./build/icons/

# Convert with custom naming
svg2icon logo.svg brand.icon
```

## Icon Specifications

### ICO Format (Windows)

- **Sizes**: 16x16, 24x24, 32x32, 48x48, 64x64, 128x128, 256x256
- **Format**: PNG-encoded images within ICO container
- **Color depth**: 32-bit RGBA

### ICNS Format (macOS)

- **Standard sizes**: 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024
- **Retina variants**: 32x32 (16x16@2x), 64x64 (32x32@2x), 256x256 (128x128@2x), 512x512 (256x256@2x)
- **Format**: PNG-encoded images with Apple OSType identifiers
- **Color depth**: 32-bit RGBA

## Development Scripts

**Build for all platforms:**

```bash
./scripts/build.sh        # Creates binaries in ./build/
scripts\build.bat         # Windows equivalent
```

**Install locally:**

```bash
./scripts/install.sh      # Unix/Linux/macOS
scripts\install.ps1       # Windows
```

**Uninstall:**

```bash
./scripts/uninstall.sh    # Unix/Linux/macOS
scripts\uninstall.bat     # Windows
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [oksvg](https://github.com/srwiley/oksvg) - SVG parsing and rendering
- [rasterx](https://github.com/srwiley/rasterx) - Rasterization engine
