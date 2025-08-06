#!/bin/bash
# svg2icon Release Creation Script
# Builds binaries and creates a GitHub release with automatic tag creation
# Requires: gh CLI tool (GitHub CLI)

set -e

REPO_OWNER="Julian-Bruyers"
REPO_NAME="svg2icon"
BUILD_DIR="build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}$1${NC}"
}

warning() {
    echo -e "${YELLOW}$1${NC}"
}

info() {
    echo -e "${BLUE}$1${NC}"
}

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not in a git repository"
    fi
    
    # Check if gh CLI is installed
    if ! command -v gh >/dev/null 2>&1; then
        error "GitHub CLI (gh) is not installed. Please install it from https://cli.github.com/"
    fi
    
    # Check if authenticated with GitHub
    if ! gh auth status >/dev/null 2>&1; then
        error "Not authenticated with GitHub. Please run: gh auth login"
    fi
    
    # Check if Go is installed
    if ! command -v go >/dev/null 2>&1; then
        error "Go is not installed. Please install Go from https://golang.org/"
    fi
    
    # Check if build script exists
    if [[ ! -f "$SCRIPT_DIR/build.sh" ]]; then
        error "Build script not found at $SCRIPT_DIR/build.sh"
    fi
    
    success "All prerequisites satisfied"
}

# Validate semantic version format
validate_version() {
    local version="$1"
    
    # Check semantic version format (vX.Y.Z or X.Y.Z)
    if [[ ! "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9\.-]+)?(\+[a-zA-Z0-9\.-]+)?$ ]]; then
        error "Invalid version format. Please use semantic versioning (e.g., 1.0.0 or v1.0.0)"
    fi
    
    # Ensure version starts with 'v'
    if [[ ! "$version" =~ ^v ]]; then
        version="v$version"
    fi
    
    echo "$version"
}

# Check if tag already exists
check_tag_exists() {
    local tag="$1"
    
    if git rev-parse "$tag" >/dev/null 2>&1; then
        error "Tag $tag already exists. Please use a different version."
    fi
    
    # Also check remote tags
    if git ls-remote --tags origin | grep -q "refs/tags/$tag$"; then
        error "Tag $tag already exists on remote. Please use a different version."
    fi
}

# Get version input from user
get_version() {
    local current_version=""
    
    # Try to get the latest tag as reference
    if latest_tag=$(git describe --tags --abbrev=0 2>/dev/null); then
        info "Latest tag: $latest_tag"
    fi
    
    echo
    echo "Please enter the version for this release (semantic versioning):"
    echo "Examples: 1.0.0, v1.2.3, 2.0.0-beta.1"
    echo -n "Version: "
    read -r version
    
    if [[ -z "$version" ]]; then
        error "Version cannot be empty"
    fi
    
    version=$(validate_version "$version")
    check_tag_exists "$version"
    
    echo "$version"
}

# Generate release notes
generate_release_notes() {
    local version="$1"
    local latest_tag="$2"
    
    local release_notes=""
    
    if [[ -n "$latest_tag" ]]; then
        info "Generating release notes from commits since $latest_tag..."
        
        # Get commits since last tag
        local commits
        commits=$(git log "$latest_tag..HEAD" --oneline --no-merges 2>/dev/null || true)
        
        if [[ -n "$commits" ]]; then
            release_notes+="## Changes since $latest_tag"$'\n\n'
            while IFS= read -r commit; do
                release_notes+="- $commit"$'\n'
            done <<< "$commits"
            release_notes+=$'\n'
        fi
    else
        info "No previous tags found, creating initial release notes..."
        release_notes+="## Initial Release"$'\n\n'
        release_notes+="First release of svg2icon - a tool for converting SVG files to ICO and ICNS icon formats."$'\n\n'
    fi
    
    # Add standard release notes
    release_notes+="## Platform Support"$'\n\n'
    release_notes+="This release includes pre-built binaries for:"$'\n'
    release_notes+="- **Windows**: AMD64 and ARM64"$'\n'
    release_notes+="- **macOS**: AMD64 (Intel) and ARM64 (Apple Silicon)"$'\n'
    release_notes+="- **Linux**: AMD64 and ARM64"$'\n\n'
    
    release_notes+="## Installation"$'\n\n'
    release_notes+="### Quick Install (Unix/Linux/macOS)"$'\n'
    release_notes+='```bash'$'\n'
    release_notes+='curl -sSL https://raw.githubusercontent.com/Julian-Bruyers/svg2icon/main/scripts/install.sh | bash'$'\n'
    release_notes+='```'$'\n\n'
    
    release_notes+="### Quick Install (Windows PowerShell)"$'\n'
    release_notes+='```powershell'$'\n'
    release_notes+='iwr -useb https://raw.githubusercontent.com/Julian-Bruyers/svg2icon/main/scripts/install.ps1 | iex'$'\n'
    release_notes+='```'$'\n\n'
    
    release_notes+="### Manual Installation"$'\n'
    release_notes+="1. Download the appropriate binary for your platform"$'\n'
    release_notes+="2. Rename it to \`svg2icon\` (or \`svg2icon.exe\` on Windows)"$'\n'
    release_notes+="3. Place it in your PATH"$'\n\n'
    
    release_notes+="## Usage"$'\n'
    release_notes+='```bash'$'\n'
    release_notes+='svg2icon input.svg output.ico    # Generate ICO file'$'\n'
    release_notes+='svg2icon input.svg output.icns   # Generate ICNS file'$'\n'
    release_notes+='svg2icon input.svg ./icons/      # Generate both formats'$'\n'
    release_notes+='```'$'\n'
    
    echo "$release_notes"
}

# Build binaries
build_binaries() {
    info "Building binaries for all platforms..."
    
    cd "$PROJECT_ROOT"
    
    # Run build script
    if [[ -x "$SCRIPT_DIR/build.sh" ]]; then
        "$SCRIPT_DIR/build.sh"
    else
        bash "$SCRIPT_DIR/build.sh"
    fi
    
    # Verify all binaries were created
    local expected_binaries=(
        "svg2icon_windows_amd64.exe"
        "svg2icon_windows_arm64.exe"
        "svg2icon_darwin_amd64"
        "svg2icon_darwin_arm64"
        "svg2icon_linux_amd64"
        "svg2icon_linux_arm64"
    )
    
    for binary in "${expected_binaries[@]}"; do
        if [[ ! -f "$BUILD_DIR/$binary" ]]; then
            error "Binary $binary was not created"
        fi
    done
    
    success "All binaries built successfully"
}

# Create git tag
create_tag() {
    local version="$1"
    local release_notes="$2"
    
    info "Creating git tag $version..."
    
    # Ensure we're on the main branch (or at least not detached)
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    if [[ "$current_branch" == "HEAD" ]]; then
        error "You are in a detached HEAD state. Please checkout a branch first."
    fi
    
    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        warning "You have uncommitted changes. They will not be included in the release."
        echo -n "Continue anyway? (y/N): "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            error "Aborted by user"
        fi
    fi
    
    # Create annotated tag
    git tag -a "$version" -m "Release $version"$'\n\n'"$release_notes"
    
    success "Tag $version created"
}

# Create GitHub release
create_github_release() {
    local version="$1"
    local release_notes="$2"
    
    info "Creating GitHub release $version..."
    
    # Push tag to remote
    git push origin "$version"
    
    # Create release with binaries
    cd "$PROJECT_ROOT"
    
    gh release create "$version" \
        --title "svg2icon $version" \
        --notes "$release_notes" \
        "$BUILD_DIR"/*
    
    success "GitHub release $version created successfully"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        warning "Script failed. You may need to manually clean up any created tags or releases."
    fi
}

# Main release process
main() {
    trap cleanup EXIT
    
    info "svg2icon Release Creation Script"
    info "================================="
    
    # Check prerequisites
    check_prerequisites
    
    # Get version from user
    local version
    version=$(get_version)
    info "Creating release for version: $version"
    
    # Get latest tag for release notes
    local latest_tag
    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    # Generate release notes
    local release_notes
    release_notes=$(generate_release_notes "$version" "$latest_tag")
    
    # Show release notes preview
    echo
    info "Release notes preview:"
    echo "----------------------"
    echo "$release_notes"
    echo "----------------------"
    echo
    
    # Confirm with user
    echo -n "Proceed with creating release $version? (y/N): "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Release creation cancelled"
        exit 0
    fi
    
    # Build binaries
    build_binaries
    
    # Create git tag
    create_tag "$version" "$release_notes"
    
    # Create GitHub release
    create_github_release "$version" "$release_notes"
    
    success "Release $version created successfully!"
    info ""
    info "Release URL: https://github.com/$REPO_OWNER/$REPO_NAME/releases/tag/$version"
    info ""
    info "Users can now install using:"
    info "  curl -sSL https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main/scripts/install.sh | bash"
}

# Run main function
main "$@"