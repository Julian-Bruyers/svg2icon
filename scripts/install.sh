#!/bin/bash
# svg2icon installer script for Unix/Linux/macOS
# Downloads and installs the latest release from GitHub
#
# Usage: curl -sSL https://raw.githubusercontent.com/julian-bruyers/svg2icon/main/scripts/install.sh | bash

set -e

REPO="julian-bruyers/svg2icon"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="svg2icon"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    echo "$1"
}

# Detect OS and architecture
detect_platform() {
    local os arch
    
    # Detect OS
    case "$(uname -s)" in
        Linux*)     os="linux" ;;
        Darwin*)    os="darwin" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
        *)          error "Unsupported OS: $(uname -s)" ;;
    esac
    
    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64)   arch="amd64" ;;
        arm64|aarch64)  arch="arm64" ;;
        *)              error "Unsupported architecture: $(uname -m)" ;;
    esac
    
    echo "${os}_${arch}"
}

# Check if running as root for system installation
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        INSTALL_DIR="/usr/local/bin"
        return 0
    fi
    
    # Try to use sudo for system installation
    if command -v sudo >/dev/null 2>&1; then
        warning "This script will install svg2icon to $INSTALL_DIR"
        warning "You may be prompted for your password to continue."
        return 0
    fi
    
    # Fallback to user installation
    INSTALL_DIR="$HOME/.local/bin"
    warning "Installing to user directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
}

# Get the latest release version with improved error handling
get_latest_version() {
    local api_url="https://api.github.com/repos/$REPO/releases/latest"
    local version=""
    
    if command -v curl >/dev/null 2>&1; then
        version=$(curl -s --connect-timeout 10 --max-time 30 "$api_url" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
    elif command -v wget >/dev/null 2>&1; then
        version=$(wget --timeout=30 --tries=2 -qO- "$api_url" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
    else
        error "Neither curl nor wget is available. Please install one of them."
    fi
    
    # Validate version format
    if [[ -z "$version" ]]; then
        error "Could not retrieve version information. Please check your internet connection."
    fi
    
    if [[ ! "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9\.-]+)?(\+[a-zA-Z0-9\.-]+)?$ ]]; then
        error "Retrieved invalid version format: $version"
    fi
    
    echo "$version"
}

# Download and install binary with safety checks
install_binary() {
    local platform="$1"
    local version="$2"
    local temp_dir
    
    # Create secure temporary directory
    temp_dir=$(mktemp -d) || error "Failed to create temporary directory"
    trap "rm -rf '$temp_dir'" EXIT
    
    # Validate inputs
    if [[ -z "$platform" ]] || [[ -z "$version" ]]; then
        error "Invalid platform or version"
    fi
    
    # Determine file extension
    local extension=""
    if [[ $platform == windows_* ]]; then
        extension=".exe"
    fi
    
    local binary_name="svg2icon_${platform}${extension}"
    local download_url="https://github.com/$REPO/releases/download/$version/$binary_name"
    
    info "Downloading svg2icon $version for $platform..."
    
    # Download binary with error handling
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fL "$download_url" -o "$temp_dir/$binary_name"; then
            error "Failed to download binary from $download_url"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$download_url" -O "$temp_dir/$binary_name"; then
            error "Failed to download binary from $download_url"
        fi
    else
        error "Neither curl nor wget is available"
    fi
    
    # Verify downloaded file exists and is not empty
    if [[ ! -f "$temp_dir/$binary_name" ]] || [[ ! -s "$temp_dir/$binary_name" ]]; then
        error "Downloaded file is missing or empty"
    fi
    
    # Make binary executable
    chmod +x "$temp_dir/$binary_name" || error "Failed to make binary executable"
    
    # Create installation directory if it doesn't exist
    if [[ ! -d "$INSTALL_DIR" ]]; then
        if [[ $EUID -eq 0 ]]; then
            mkdir -p "$INSTALL_DIR" || error "Failed to create installation directory"
        elif [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
            mkdir -p "$INSTALL_DIR" || error "Failed to create user installation directory"
        else
            sudo mkdir -p "$INSTALL_DIR" || error "Failed to create system installation directory"
        fi
    fi
    
    # Install binary safely
    local target_path="$INSTALL_DIR/$BINARY_NAME"
    
    # Check if target already exists and create backup
    if [[ -f "$target_path" ]]; then
        local backup_path="$target_path.backup-$(date +%Y%m%d-%H%M%S)"
        if [[ $EUID -eq 0 ]]; then
            cp "$target_path" "$backup_path" 2>/dev/null || warning "Could not create backup of existing binary"
        elif [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
            cp "$target_path" "$backup_path" 2>/dev/null || warning "Could not create backup of existing binary"
        else
            sudo cp "$target_path" "$backup_path" 2>/dev/null || warning "Could not create backup of existing binary"
        fi
        [[ -f "$backup_path" ]] && info "Backup created: $backup_path"
    fi
    
    # Copy binary to target location
    if [[ $EUID -eq 0 ]]; then
        # Running as root
        cp "$temp_dir/$binary_name" "$target_path" || error "Failed to install binary as root"
    elif [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
        # User installation
        cp "$temp_dir/$binary_name" "$target_path" || error "Failed to install binary to user directory"
    else
        # System installation with sudo
        sudo cp "$temp_dir/$binary_name" "$target_path" || error "Failed to install binary with sudo"
    fi
    
    # Verify installation
    if [[ ! -f "$target_path" ]] || [[ ! -x "$target_path" ]]; then
        error "Binary installation verification failed"
    fi
    
    success "svg2icon installed to $target_path"
}

# Update PATH if necessary with safety checks
update_path() {
    if [[ "$INSTALL_DIR" == "/usr/local/bin" ]]; then
        # /usr/local/bin is usually in PATH by default
        return 0
    fi
    
    # Check if directory is already in PATH
    if echo "$PATH" | grep -q ":$INSTALL_DIR:" || echo "$PATH" | grep -q "^$INSTALL_DIR:" || echo "$PATH" | grep -q ":$INSTALL_DIR$" || [[ "$PATH" == "$INSTALL_DIR" ]]; then
        info "Directory $INSTALL_DIR is already in PATH"
        return 0
    fi
    
    # Determine shell profile with safety checks
    local shell_profile=""
    
    case "$SHELL" in
        */bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                shell_profile="$HOME/.bashrc"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                shell_profile="$HOME/.bash_profile"
            fi
            ;;
        */zsh)
            shell_profile="$HOME/.zshrc"
            ;;
        */fish)
            # Create fish config directory safely
            if [[ ! -d "$HOME/.config/fish" ]]; then
                mkdir -p "$HOME/.config/fish" 2>/dev/null || {
                    warning "Could not create fish config directory"
                    return 1
                }
            fi
            shell_profile="$HOME/.config/fish/config.fish"
            ;;
        *)
            warning "Unknown shell: $SHELL"
            shell_profile="$HOME/.profile"
            ;;
    esac
    
    if [[ -n "$shell_profile" ]]; then
        # Create backup of shell profile before modification
        if [[ -f "$shell_profile" ]]; then
            cp "$shell_profile" "$shell_profile.svg2icon-backup-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || {
                warning "Could not create backup of $shell_profile"
                return 1
            }
        fi
        
        # Check if our PATH entry already exists (more thorough check)
        if [[ -f "$shell_profile" ]] && grep -Fq "export PATH=\"$INSTALL_DIR:\$PATH\"" "$shell_profile" 2>/dev/null; then
            info "PATH entry already exists in $shell_profile"
            return 0
        fi
        
        # Safely append PATH entry with validation
        if ! echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$shell_profile" 2>/dev/null; then
            error "Failed to update $shell_profile - check file permissions"
        fi
        
        success "Added $INSTALL_DIR to PATH in $shell_profile"
        info "Backup created: $shell_profile.svg2icon-backup-$(date +%Y%m%d-%H%M%S)"
        warning "Please restart your terminal or run: source $shell_profile"
    else
        warning "Could not determine shell profile. Please manually add $INSTALL_DIR to your PATH."
        info "Add this line to your shell profile: export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
}

# Verify installation
verify_installation() {
    local target_path="$INSTALL_DIR/$BINARY_NAME"
    
    if [[ -x "$target_path" ]]; then
        local version_output
        if version_output=$("$target_path" --help 2>&1); then
            success "Installation verified successfully!"
            info "You can now use 'svg2icon' command."
        else
            warning "Binary installed but may not be working correctly."
        fi
    else
        error "Installation failed - binary not found or not executable"
    fi
}

# Main installation process
main() {
    info "svg2icon Installation Script"
    info "============================"
    
    # Detect platform
    local platform
    platform=$(detect_platform)
    info "Detected platform: $platform"
    
    # Check permissions
    check_permissions
    
    # Get latest version
    local version
    version=$(get_latest_version)
    if [[ -z "$version" ]]; then
        error "Could not determine latest version"
    fi
    info "Latest version: $version"
    
    # Install binary
    install_binary "$platform" "$version"
    
    # Update PATH if necessary
    update_path
    
    # Verify installation
    verify_installation
    
    success "svg2icon installation completed!"
}

# Run main function
main "$@"