#!/bin/bash
# SmartJanitor - One-Line Installer
# Your automated cleanup utility for modern MacBooks
# Usage: curl -fsSL https://raw.githubusercontent.com/gupsammy/SmartJanitor/main/install.sh | bash

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
SCRIPTS_DIR="$INSTALL_DIR/scripts"
LOGS_DIR="$INSTALL_DIR/logs"
BIN_LINK="/usr/local/bin/smartjanitor"
REPO_URL="https://raw.githubusercontent.com/gupsammy/SmartJanitor/main"
ENABLE_AI=false

print_header() {
    echo -e "${PURPLE}${BOLD}"
    echo "    🧹 SmartJanitor Installation"
    echo "    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "    Your automated cleanup crew is ready!"
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

print_error() {
    echo -e "${RED}💥 $1${NC}"
}

print_janitor() {
    echo -e "${CYAN}🧹 $1${NC}"
}

ask_user_choice() {
    echo -e "${CYAN}${BOLD}🤖 AI Enhancement Available!${NC}"
    echo ""
    echo "SmartJanitor can work with Claude Code for intelligent cleanup analysis."
    echo "This adds monthly AI-powered deep cleaning to catch edge cases."
    echo ""
    echo "Requirements:"
    echo "  • Claude Code installed (npm install -g @anthropic-ai/claude-code)"  
    echo "  • Anthropic API key or subscription"
    echo ""
    echo -e "${YELLOW}Without AI: Weekly bash cleanup only (still very effective!)${NC}"
    echo -e "${GREEN}With AI: Weekly cleanup + monthly intelligent analysis${NC}"
    echo ""
    read -p "Enable AI-powered cleaning? (y/N): " -n 1 -r
    echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ENABLE_AI=true
        print_success "AI cleaning enabled! Your janitor just got smarter."
    else
        print_janitor "Basic cleaning mode selected. Still plenty powerful!"
    fi
}

check_requirements() {
    print_step "Inspecting your Mac for cleaning compatibility..."
    
    # Check macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "SmartJanitor only works on macOS. Sorry Windows folks!"
        exit 1
    fi
    
    # Check if we have required commands
    local missing_commands=()
    
    if ! command -v curl &> /dev/null; then
        missing_commands+=("curl")
    fi
    
    if ! command -v launchctl &> /dev/null; then
        missing_commands+=("launchctl")
    fi
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        print_error "Missing essential tools: ${missing_commands[*]}"
        print_error "These are required for the janitor to do its job!"
        exit 1
    fi
    
    print_success "Your Mac is ready for some serious tidying up"
    
    # Check what cleaning tools are available
    local cleaning_tools=0
    
    if command -v docker &> /dev/null; then
        print_success "Docker detected - we can tackle those chunky containers"
        cleaning_tools=$((cleaning_tools + 1))
    else
        print_janitor "No Docker found - that's one less mess to clean"
    fi
    
    if command -v brew &> /dev/null; then
        print_success "Homebrew spotted - time to clear those cached bottles"
        cleaning_tools=$((cleaning_tools + 1))
    else
        print_janitor "No Homebrew detected - fewer crumbs to sweep up"
    fi
    
    if command -v npm &> /dev/null; then
        print_success "npm found - lots of node_modules to potentially tidy"
        cleaning_tools=$((cleaning_tools + 1))
    fi
    
    if command -v pnpm &> /dev/null; then
        print_success "pnpm discovered - another package manager to clean"
        cleaning_tools=$((cleaning_tools + 1))
    fi
    
    if [ $cleaning_tools -eq 0 ]; then
        print_warning "Limited cleaning tools found, but we'll still tidy what we can!"
    else
        print_janitor "Found $cleaning_tools cleaning targets. This will be satisfying!"
    fi
    
    # Check AI capability after user choice
    if [ "$ENABLE_AI" = true ]; then
        if command -v claude &> /dev/null; then
            print_success "Claude Code ready - your janitor has a PhD now"
        else
            print_warning "Claude Code not found - AI cleaning won't be available"
            print_janitor "Install it later: npm install -g @anthropic-ai/claude-code"
        fi
    fi
}

create_directories() {
    print_step "Setting up the janitor's workspace..."
    
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$LOGS_DIR"
    
    print_success "Janitor workspace ready for business"
}

download_scripts() {
    print_step "Fetching the janitor's cleaning tools..."
    
    # Download main scripts
    local scripts=(
        "scripts/weekly-cleanup.sh"
        "scripts/send-notification.sh"
        "scripts/manage-cleanup.sh"
    )
    
    # Add AI script only if requested
    if [ "$ENABLE_AI" = true ]; then
        scripts+=("scripts/monthly-claude-cleanup.sh")
    fi
    
    local downloaded=0
    for script in "${scripts[@]}"; do
        local filename=$(basename "$script")
        local url="$REPO_URL/$script"
        
        echo -e "${CYAN}  📦 Fetching $filename...${NC}"
        if curl -fsSL "$url" -o "$SCRIPTS_DIR/$filename"; then
            chmod +x "$SCRIPTS_DIR/$filename"
            downloaded=$((downloaded + 1))
        else
            print_error "Failed to download $filename - the janitor is missing a tool!"
            exit 1
        fi
    done
    
    print_success "All $downloaded cleaning tools successfully downloaded and activated"
}

create_launchd_plists() {
    print_step "Teaching macOS when to summon the janitor..."
    
    # Weekly plist
    cat > "$HOME/Library/LaunchAgents/com.user.smartjanitor.weekly.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.smartjanitor.weekly</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>$SCRIPTS_DIR/weekly-cleanup.sh && $SCRIPTS_DIR/send-notification.sh weekly</string>
    </array>
    
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>10</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    
    <key>RunAtLoad</key>
    <false/>
    
    <key>WorkingDirectory</key>
    <string>$HOME</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>$HOME</string>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
    </dict>
    
    <key>StandardOutPath</key>
    <string>$LOGS_DIR/weekly-launchd.out</string>
    <key>StandardErrorPath</key>
    <string>$LOGS_DIR/weekly-launchd.err</string>
    
    <key>UserName</key>
    <string>$(whoami)</string>
    
    <key>Nice</key>
    <integer>10</integer>
</dict>
</plist>
EOF

    # Monthly plist (only if AI is enabled)
    if [ "$ENABLE_AI" = true ]; then
        cat > "$HOME/Library/LaunchAgents/com.user.smartjanitor.monthly.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.smartjanitor.monthly</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>$SCRIPTS_DIR/monthly-claude-cleanup.sh && $SCRIPTS_DIR/send-notification.sh monthly</string>
    </array>
    
    <key>StartCalendarInterval</key>
    <dict>
        <key>Day</key>
        <integer>1</integer>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    
    <key>RunAtLoad</key>
    <false/>
    
    <key>WorkingDirectory</key>
    <string>$HOME</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>$HOME</string>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:$HOME/.npm-global/bin</string>
        <key>NODE_PATH</key>
        <string>$HOME/.npm-global/lib/node_modules</string>
    </dict>
    
    <key>StandardOutPath</key>
    <string>$LOGS_DIR/monthly-launchd.out</string>
    <key>StandardErrorPath</key>
    <string>$LOGS_DIR/monthly-launchd.err</string>
    
    <key>UserName</key>
    <string>$(whoami)</string>
    
    <key>Nice</key>
    <integer>10</integer>
</dict>
</plist>
EOF
    fi
    
    print_success "Scheduling system configured - janitor will work on autopilot"
}

create_symlink() {
    print_step "Installing the janitor's remote control..."
    
    # Create symlink for easy access
    if [ -L "$BIN_LINK" ]; then
        rm "$BIN_LINK"
    fi
    
    # Ensure /usr/local/bin exists
    sudo mkdir -p /usr/local/bin 2>/dev/null || true
    
    if sudo ln -sf "$SCRIPTS_DIR/manage-cleanup.sh" "$BIN_LINK" 2>/dev/null; then
        print_success "Command 'smartjanitor' is now available everywhere"
    else
        print_warning "Could not create global command (sudo failed)"
        print_janitor "You can still summon the janitor: $SCRIPTS_DIR/manage-cleanup.sh"
    fi
}

install_services() {
    print_step "Putting the janitor on duty..."
    
    # Load weekly service
    if launchctl load "$HOME/Library/LaunchAgents/com.user.smartjanitor.weekly.plist" 2>/dev/null; then
        print_success "Weekly cleaning crew is now on the schedule"
    else
        print_warning "Weekly service may already be on duty"
    fi
    
    # Load monthly service (if AI is enabled)
    if [ "$ENABLE_AI" = true ] && [ -f "$HOME/Library/LaunchAgents/com.user.smartjanitor.monthly.plist" ]; then
        if launchctl load "$HOME/Library/LaunchAgents/com.user.smartjanitor.monthly.plist" 2>/dev/null; then
            print_success "AI-powered monthly deep clean is scheduled"
        else
            print_warning "Monthly AI service may already be active"
        fi
    fi
}

show_completion() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "    🧹✨ SmartJanitor is Ready to Work!"
    echo "    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${NC}"
    
    echo -e "${CYAN}🗓️ Cleaning schedule:${NC}"
    echo "   • Weekly tidy-up: Every Sunday at 10:00 AM"
    if [ "$ENABLE_AI" = true ]; then
        echo "   • Monthly deep clean: 1st of every month at 9:00 AM (AI-powered)"
    fi
    echo "   • Works even when your Mac is napping"
    echo ""
    
    echo -e "${CYAN}🎮 Remote control commands:${NC}"
    if command -v smartjanitor &> /dev/null; then
        echo "   smartjanitor status       # Check what the janitor is up to"
        echo "   smartjanitor test-weekly  # Start cleaning right now"
        echo "   smartjanitor logs         # See cleaning reports"
        echo "   smartjanitor schedule     # When's the next cleanup?"
        echo "   smartjanitor uninstall    # Fire the janitor (sadly)"
    else
        echo "   $SCRIPTS_DIR/manage-cleanup.sh status"
        echo "   $SCRIPTS_DIR/manage-cleanup.sh test-weekly"
    fi
    echo ""
    
    echo -e "${CYAN}📱 You'll get notified:${NC}"
    echo "   Interactive popups after each cleaning session"
    echo "   Click 'View Logs' to see what got tidied up"
    echo ""
    
    echo -e "${YELLOW}🧽 Pro janitor tips:${NC}"
    echo "   • First cleanup might take a while (spring cleaning!)"
    if command -v smartjanitor &> /dev/null; then
        echo "   • Check in occasionally: smartjanitor status"
    fi
    if [ "$ENABLE_AI" = false ] && ! command -v claude &> /dev/null; then
        echo "   • Want AI cleaning? Install Claude Code: npm install -g @anthropic-ai/claude-code"
    fi
    echo ""
    
    echo -e "${PURPLE}🎉 Your Mac now has a personal cleaning service!${NC}"
    echo ""
    
    # Show current disk usage
    echo -e "${CYAN}📊 Current mess level:${NC}"
    df -h /System/Volumes/Data | tail -1 | awk '{print "   💾 Storage: " $3 " used / " $4 " available (" $5 " full)"}'
    echo ""
    echo -e "${CYAN}Soon this will look much better. Happy tidying! 🧹${NC}"
    echo ""
}

main() {
    print_header
    
    echo -e "${CYAN}SmartJanitor will set up automated cleanup for your MacBook.${NC}"
    echo "No more 'disk almost full' warnings. No more manual tidying."
    echo "Just a clean Mac that maintains itself."
    echo ""
    
    read -p "Ready to hire your personal janitor? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_janitor "Maybe next time when the mess gets too much!"
        exit 0
    fi
    
    echo ""
    
    ask_user_choice
    check_requirements
    create_directories
    download_scripts
    create_launchd_plists
    create_symlink
    install_services
    show_completion
}

# Handle interruption  
trap 'echo -e "\n${RED}💥 Installation interrupted! The janitor will try again later.${NC}"; exit 1' INT

# Run main function
main "$@"