#!/bin/bash
# Mac Storage Cleaner - Uninstaller
# Safely removes all components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.mac-storage-cleaner"
BIN_LINK="/usr/local/bin/mac-cleanup"

print_header() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════╗"
    echo "║        Mac Storage Cleaner Uninstall   ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

unload_services() {
    print_step "Stopping launchd services..."
    
    # Unload services
    if launchctl list | grep -q "com.user.storage-cleanup.weekly"; then
        launchctl unload "$HOME/Library/LaunchAgents/com.user.storage-cleanup.weekly.plist" 2>/dev/null || true
        print_success "Weekly service stopped"
    fi
    
    if launchctl list | grep -q "com.user.storage-cleanup.monthly"; then
        launchctl unload "$HOME/Library/LaunchAgents/com.user.storage-cleanup.monthly.plist" 2>/dev/null || true
        print_success "Monthly service stopped"
    fi
}

remove_plists() {
    print_step "Removing launchd configuration..."
    
    local plists=(
        "$HOME/Library/LaunchAgents/com.user.storage-cleanup.weekly.plist"
        "$HOME/Library/LaunchAgents/com.user.storage-cleanup.monthly.plist"
    )
    
    for plist in "${plists[@]}"; do
        if [ -f "$plist" ]; then
            rm "$plist"
        fi
    done
    
    print_success "launchd configuration removed"
}

remove_symlink() {
    print_step "Removing command-line shortcut..."
    
    if [ -L "$BIN_LINK" ]; then
        sudo rm "$BIN_LINK" 2>/dev/null && print_success "Global command removed" || print_warning "Could not remove global command"
    fi
}

remove_files() {
    print_step "Removing installation directory..."
    
    if [ -d "$INSTALL_DIR" ]; then
        # Show what will be removed
        echo -e "${YELLOW}The following will be removed:${NC}"
        echo "  $INSTALL_DIR/"
        echo "    ├── scripts/"
        echo "    └── logs/"
        echo ""
        
        read -p "Remove all files and logs? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
            print_success "All files removed"
        else
            print_warning "Files kept at $INSTALL_DIR"
            echo -e "  ${BLUE}You can manually remove them later if desired${NC}"
        fi
    else
        print_success "No installation directory found"
    fi
}

show_completion() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Uninstall Complete!           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BLUE}What was removed:${NC}"
    echo -e "  ✅ Scheduled cleanup services"
    echo -e "  ✅ launchd configuration files"
    echo -e "  ✅ Command-line shortcuts"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "  ✅ All scripts and logs"
    else
        echo -e "  ⏸️  Scripts and logs preserved"
    fi
    echo ""
    
    echo -e "${YELLOW}💡 Your Mac will no longer automatically clean storage${NC}"
    echo -e "${BLUE}You can reinstall anytime with:${NC}"
    echo -e "  curl -fsSL https://raw.githubusercontent.com/samarthguptadev/mac-storage-cleaner/main/install.sh | bash"
    echo ""
}

main() {
    print_header
    
    echo -e "${YELLOW}This will completely remove Mac Storage Cleaner from your system.${NC}"
    echo -e "${YELLOW}Scheduled cleanups will stop running.${NC}"
    echo ""
    
    read -p "Continue with uninstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi
    
    echo ""
    
    unload_services
    remove_plists
    remove_symlink
    remove_files
    show_completion
}

# Handle interruption
trap 'echo -e "\n${RED}Uninstall interrupted!${NC}"; exit 1' INT

# Run main function
main "$@"