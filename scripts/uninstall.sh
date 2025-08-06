#!/bin/bash
# svg2icon uninstaller script for Unix/Linux/macOS
# Removes svg2icon binary from the system
#
# Usage: ./uninstall.sh or curl -sSL https://raw.githubusercontent.com/julian-bruyers/svg2icon/main/scripts/uninstall.sh | bash

set -e

BINARY_NAME="svg2icon"
POSSIBLE_INSTALL_DIRS=(
    "/usr/local/bin"
    "$HOME/.local/bin"
    "/opt/svg2icon/bin"
    "/usr/bin"
)

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

# Find installed binary
find_installed_binary() {
    local found_paths=()
    
    # Check common installation directories
    for dir in "${POSSIBLE_INSTALL_DIRS[@]}"; do
        if [[ -f "$dir/$BINARY_NAME" ]]; then
            found_paths+=("$dir/$BINARY_NAME")
        fi
    done
    
    # Also check if it's in PATH
    if command -v "$BINARY_NAME" >/dev/null 2>&1; then
        local path_location
        path_location=$(command -v "$BINARY_NAME")
        # Add to found_paths if not already there
        if [[ ! " ${found_paths[*]} " =~ " ${path_location} " ]]; then
            found_paths+=("$path_location")
        fi
    fi
    
    printf '%s\n' "${found_paths[@]}"
}

# Remove binary file
remove_binary() {
    local binary_path="$1"
    local install_dir
    install_dir=$(dirname "$binary_path")
    
    info "Removing binary: $binary_path"
    
    # Check if we need sudo
    if [[ ! -w "$install_dir" ]]; then
        if command -v sudo >/dev/null 2>&1; then
            sudo rm -f "$binary_path"
        else
            error "Cannot remove $binary_path - no write permission and sudo not available"
        fi
    else
        rm -f "$binary_path"
    fi
    
    if [[ ! -f "$binary_path" ]]; then
        success "Successfully removed: $binary_path"
        return 0
    else
        error "Failed to remove: $binary_path"
    fi
}

# Clean PATH entries from shell profiles - DISABLED
# PATH entries are preserved to avoid breaking user configuration
clean_path_entries() {
    local install_dir="$1"
    
    info "Preserving PATH entries (they will remain in your shell profiles)"
    info "If you want to remove PATH entries manually, check these files:"
    
    # List of shell profile files to check
    local profiles=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.zshrc"
        "$HOME/.config/fish/config.fish"
        "$HOME/.profile"
    )
    
    for profile in "${profiles[@]}"; do
        if [[ -f "$profile" ]]; then
            # Check if the profile contains PATH entries for our install directory
            if grep -q "$install_dir" "$profile" 2>/dev/null; then
                info "  - $profile (contains PATH entry for $install_dir)"
            fi
        fi
    done
}

# Remove empty installation directories - DISABLED
# Directories are preserved to avoid breaking user setup
cleanup_directories() {
    local install_dir="$1"
    
    info "Preserving installation directory: $install_dir"
    info "Directory will not be removed even if empty"
}

# Check if svg2icon is actually installed
check_installation() {
    local found_paths
    readarray -t found_paths < <(find_installed_binary)
    
    if [[ ${#found_paths[@]} -eq 0 ]]; then
        info "svg2icon is not installed or not found in common locations"
        return 1
    fi
    
    return 0
}

# Interactive confirmation
confirm_uninstall() {
    local found_paths
    readarray -t found_paths < <(find_installed_binary)
    
    echo
    info "Found svg2icon installations:"
    for path in "${found_paths[@]}"; do
        echo "  - $path"
    done
    echo
    
    warning "This will remove svg2icon from your system."
    echo -n "Do you want to continue? (y/N): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Uninstallation cancelled"
        exit 0
    fi
}

# Main uninstallation process
main() {
    info "svg2icon Uninstallation Script"
    info "=============================="
    
    # Check if svg2icon is installed
    if ! check_installation; then
        exit 0
    fi
    
    # Get all installed locations
    local found_paths
    readarray -t found_paths < <(find_installed_binary)
    
    # Confirm with user (unless running non-interactively)
    if [[ -t 0 ]]; then  # Check if running interactively
        confirm_uninstall
    fi
    
    # Remove all found binaries
    local removed_count=0
    for binary_path in "${found_paths[@]}"; do
        if remove_binary "$binary_path"; then
            ((removed_count++))
            
            # Clean PATH entries for this installation directory
            local install_dir
            install_dir=$(dirname "$binary_path")
            clean_path_entries "$install_dir"
            
            # Cleanup empty directories
            cleanup_directories "$install_dir"
        fi
    done
    
    if [[ $removed_count -gt 0 ]]; then
        success "svg2icon uninstallation completed!"
        info "Removed $removed_count installation(s)"
        
        # Final verification
        if command -v "$BINARY_NAME" >/dev/null 2>&1; then
            warning "svg2icon is still found in PATH (but PATH entries were preserved)"
            info "The binary has been removed, but PATH entries remain in your shell profiles"
        else
            success "svg2icon binary successfully removed"
        fi
    else
        error "No installations were removed"
    fi
}

# Run main function
main "$@"
