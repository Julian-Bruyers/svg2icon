#!/bin/bash
# Build script for svg2icon - Unix Shell
# Compiles svg2icon for Windows, macOS, and Linux on AMD64 and ARM architectures

set -e

# Validate environment
if ! command -v go >/dev/null 2>&1; then
    echo "Error: Go is not installed or not in PATH" >&2
    exit 1
fi

# Check if we're in the correct directory
if [[ ! -f "go.mod" ]] || [[ ! -f "main.go" ]]; then
    echo "Error: Must be run from the project root directory (where go.mod exists)" >&2
    exit 1
fi

echo "Building svg2icon for multiple platforms..."

# Get project root and validate
PROJECT_ROOT="$(pwd)"
BUILD_DIR="$PROJECT_ROOT/build"

# Create build directory safely
if ! mkdir -p "$BUILD_DIR"; then
    echo "Error: Failed to create build directory" >&2
    exit 1
fi

# Clean previous builds safely
if [[ -d "$BUILD_DIR" ]]; then
    rm -f "$BUILD_DIR"/svg2icon_* 2>/dev/null || true
fi

# Build targets with error checking
build_target() {
    local goos="$1"
    local goarch="$2"
    local extension="$3"
    local description="$4"
    
    echo "Building for $description..."
    
    local binary_name="svg2icon_${goos}_${goarch}${extension}"
    local output_path="$BUILD_DIR/$binary_name"
    
    if ! GOOS="$goos" GOARCH="$goarch" go build -ldflags="-s -w" -o "$output_path" .; then
        echo "Error: Failed to build $description" >&2
        return 1
    fi
    
    # Verify binary was created and is not empty
    if [[ ! -f "$output_path" ]] || [[ ! -s "$output_path" ]]; then
        echo "Error: Binary $binary_name was not created or is empty" >&2
        return 1
    fi
    
    echo "✓ $description built successfully"
    return 0
}

echo
# Build all targets
build_target "windows" "amd64" ".exe" "Windows AMD64" || exit 1
build_target "windows" "arm64" ".exe" "Windows ARM64" || exit 1

echo
build_target "darwin" "amd64" "" "macOS AMD64" || exit 1
build_target "darwin" "arm64" "" "macOS ARM64" || exit 1

echo
build_target "linux" "amd64" "" "Linux AMD64" || exit 1
build_target "linux" "arm64" "" "Linux ARM64" || exit 1

echo
echo "Build completed successfully!"
echo "Binaries available in build/ directory:"

# List binaries safely
if [[ -d "$BUILD_DIR" ]]; then
    ls -la "$BUILD_DIR"/svg2icon_* 2>/dev/null || echo "No binaries found"
    
    # Display file sizes for reference
    echo
    echo "Binary sizes:"
    du -h "$BUILD_DIR"/svg2icon_* 2>/dev/null || echo "No binaries to measure"
else
    echo "Build directory not found"
    exit 1
fi