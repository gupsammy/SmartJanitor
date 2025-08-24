#!/bin/bash
# SmartJanitor - Development Installation
# Creates symlinks instead of copying files for easier development

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$HOME/.smartjanitor"
SCRIPTS_DIR="$INSTALL_DIR/scripts"
LOGS_DIR="$INSTALL_DIR/logs"
BIN_LINK="$HOME/.local/bin/smartjanitor"

print_header() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════╗"
    echo "║       SmartJanitor - Dev Install       ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

main() {
    print_header
    
    echo -e "${YELLOW}Development installation creates symlinks to project files.${NC}"
    echo -e "${YELLOW}Changes to scripts will be reflected immediately.${NC}"
    echo ""
    
    print_step "Creating directories..."
    mkdir -p "$SCRIPTS_DIR" "$LOGS_DIR"
    
    print_step "Creating symlinks to development scripts..."
    ln -sf "$PROJECT_DIR/scripts/weekly-cleanup.sh" "$SCRIPTS_DIR/"
    ln -sf "$PROJECT_DIR/scripts/monthly-claude-cleanup.sh" "$SCRIPTS_DIR/"
    ln -sf "$PROJECT_DIR/scripts/send-notification.sh" "$SCRIPTS_DIR/"
    ln -sf "$PROJECT_DIR/scripts/manage-cleanup.sh" "$SCRIPTS_DIR/"
    
    print_step "Creating command-line shortcut..."
    mkdir -p "$(dirname "$BIN_LINK")"
    ln -sf "$SCRIPTS_DIR/manage-cleanup.sh" "$BIN_LINK" 2>/dev/null || true
    
    print_success "Development environment ready!"
    echo ""
    echo -e "${BLUE}💡 Edit files in: $PROJECT_DIR/scripts/${NC}"
    echo -e "${BLUE}💡 Test with: smartjanitor test-weekly${NC}"
    echo ""
}

main "$@"