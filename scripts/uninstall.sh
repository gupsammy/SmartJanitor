#!/bin/bash
# SmartJanitor - Uninstaller
# Safely dismisses your automated cleanup crew

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.smartjanitor"
BIN_LINK="$HOME/.local/bin/smartjanitor"

print_header() {
    echo -e "${RED}${BOLD}"
    echo "    🧹💔 SmartJanitor Departure"
    echo "    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "    Saying goodbye to your cleaning crew..."
    echo -e "${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✨ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}🚨 $1${NC}"
}

print_janitor() {
    echo -e "${CYAN}🧹 $1${NC}"
}

unload_services() {
    print_step "Stopping the janitor's work schedule..."
    
    # Unload services
    if launchctl list | grep -q "com.user.smartjanitor.weekly"; then
        launchctl unload "$HOME/Library/LaunchAgents/com.user.smartjanitor.weekly.plist" 2>/dev/null || true
        print_success "Weekly cleaning service stopped"
    fi
    
    if launchctl list | grep -q "com.user.smartjanitor.monthly"; then
        launchctl unload "$HOME/Library/LaunchAgents/com.user.smartjanitor.monthly.plist" 2>/dev/null || true
        print_success "Monthly AI analysis service stopped"
    fi
}

remove_plists() {
    print_step "Removing janitor's scheduling system..."
    
    local plists=(
        "$HOME/Library/LaunchAgents/com.user.smartjanitor.weekly.plist"
        "$HOME/Library/LaunchAgents/com.user.smartjanitor.monthly.plist"
    )
    
    for plist in "${plists[@]}"; do
        if [ -f "$plist" ]; then
            rm "$plist"
        fi
    done
    
    print_success "Scheduling system removed"
}

remove_symlink() {
    print_step "Removing janitor's remote control..."
    
    if [ -L "$BIN_LINK" ]; then
        rm "$BIN_LINK" 2>/dev/null && print_success "Personal smartjanitor command removed" || print_warning "Could not remove command"
    else
        print_janitor "No personal command was installed"
    fi
    
    # Also check for old location
    if [ -L "/usr/local/bin/smartjanitor" ]; then
        print_janitor "Found old system-wide installation - you may need to remove it manually:"
        print_janitor "sudo rm /usr/local/bin/smartjanitor"
    fi
}

remove_files() {
    print_step "Clearing out the janitor's workspace..."
    
    if [ -d "$INSTALL_DIR" ]; then
        # Show what will be removed
        echo -e "${YELLOW}The janitor's belongings to be removed:${NC}"
        echo "  $INSTALL_DIR/"
        echo "    ├── scripts/ (cleaning tools)"
        echo "    └── logs/ (cleaning history)"
        echo ""
        
        read -p "Remove all janitor files and logs? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
            print_success "Janitor workspace completely cleared"
        else
            print_warning "Janitor's files preserved at $INSTALL_DIR"
            print_janitor "You can clean them up manually later if needed"
        fi
    else
        print_success "No janitor workspace found (already clean!)"
    fi
}

show_completion() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "    🧹💔 Your Janitor Has Left the Building"
    echo "    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${NC}"
    
    echo -e "${BLUE}What was cleared out:${NC}"
    echo -e "  ✨ Stopped all scheduled cleaning services"
    echo -e "  ✨ Removed automation scheduling"
    echo -e "  ✨ Disconnected remote control commands"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "  ✨ Cleaned out all scripts and logs"
    else
        echo -e "  🗂️  Preserved cleaning history and tools"
    fi
    echo ""
    
    echo -e "${YELLOW}⚠️  Your Mac will no longer automatically clean itself${NC}"
    echo "Storage bloat may start accumulating again."
    echo ""
    echo -e "${CYAN}💡 Missing your janitor already?${NC}"
    echo "Rehire anytime with:"
    echo -e "${BLUE}  curl -fsSL https://raw.githubusercontent.com/gupsammy/SmartJanitor/main/install.sh | bash${NC}"
    echo ""
    echo -e "${PURPLE}Thanks for trying SmartJanitor! 🧹✨${NC}"
    echo ""
}

main() {
    print_header
    
    echo -e "${YELLOW}This will dismiss your SmartJanitor and stop all automated cleaning.${NC}"
    echo "Your Mac will go back to accumulating digital dust."
    echo "Are you sure about this?"
    echo ""
    
    read -p "Fire your janitor? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_janitor "Smart choice! Your janitor stays on the job."
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
trap 'echo -e "\n${RED}💥 Uninstall interrupted! Your janitor is confused but still working.${NC}"; exit 1' INT

# Run main function
main "$@"