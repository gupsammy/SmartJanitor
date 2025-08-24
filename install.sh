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
BIN_LINK="$HOME/.local/bin/smartjanitor"
REPO_URL="https://raw.githubusercontent.com/gupsammy/SmartJanitor/main"

# Auto-detect installation mode and AI capability
if [ -d "scripts" ] && [ -f "scripts/weekly-cleanup.sh" ]; then
    INSTALL_MODE="local"
    SOURCE_DIR="$(pwd)/scripts"
else 
    INSTALL_MODE="remote"
fi

# Auto-detect AI capability
if command -v claude &> /dev/null; then
    ENABLE_AI=true
else
    ENABLE_AI=false
fi

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

show_detected_config() {
    echo -e "${CYAN}${BOLD}🧹 Your Janitor's Toolkit Assembly${NC}"
    echo ""
    
    # Show installation mode
    if [ "$INSTALL_MODE" = "local" ]; then
        print_success "Local janitor deployment - using your workshop files"
        print_janitor "Grabbing tools from: $SOURCE_DIR"
    else
        print_janitor "Remote janitor deployment - fetching tools from the cloud"
        print_janitor "Downloading from: GitHub headquarters"
    fi
    echo ""
    
    # Show AI capability
    if [ "$ENABLE_AI" = true ]; then
        print_success "Smart janitor detected - AI brain found and ready!"
        print_janitor "Your janitor has a PhD: Weekly tidying + monthly deep analysis"
    else
        print_janitor "Standard janitor mode - no AI brain found (but still mighty!)" 
        print_janitor "Weekly bash cleanup crew deployed (plenty powerful for most messes!)"
        echo -e "${CYAN}🤖 Want a smarter janitor? Install Claude Code: npm install -g @anthropic-ai/claude-code${NC}"
    fi
    echo ""
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

copy_or_download_scripts() {
    print_step "Gathering the janitor's cleaning arsenal..."
    
    # Main scripts needed
    local script_files=(
        "weekly-cleanup.sh"
        "send-notification.sh"
        "manage-cleanup.sh"
        "uninstall.sh"
    )
    
    # Add AI script only if AI is enabled
    if [ "$ENABLE_AI" = true ]; then
        script_files+=("monthly-claude-cleanup.sh")
    fi
    
    local processed=0
    
    if [ "$INSTALL_MODE" = "local" ]; then
        # Local mode: Copy from repository directory
        print_janitor "Copying tools from your local workshop..."
        for script in "${script_files[@]}"; do
            echo -e "${CYAN}  🔧 Installing $script...${NC}"
            if cp "$SOURCE_DIR/$script" "$SCRIPTS_DIR/$script"; then
                chmod +x "$SCRIPTS_DIR/$script"
                processed=$((processed + 1))
            else
                print_error "Failed to copy $script - missing from workshop!"
                exit 1
            fi
        done
        print_success "All $processed cleaning tools copied from your workshop and activated"
    else
        # Remote mode: Download from GitHub
        print_janitor "Downloading professional-grade tools from the cloud..."
        for script in "${script_files[@]}"; do
            local url="$REPO_URL/scripts/$script"
            
            echo -e "${CYAN}  📦 Fetching $script...${NC}"
            if curl -fsSL "$url" -o "$SCRIPTS_DIR/$script"; then
                chmod +x "$SCRIPTS_DIR/$script"
                processed=$((processed + 1))
            else
                print_error "Failed to download $script - the janitor is missing a tool!"
                exit 1
            fi
        done
        print_success "All $processed cleaning tools successfully downloaded and activated"
    fi
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
        <string>$SCRIPTS_DIR/weekly-cleanup.sh && $SCRIPTS_DIR/send-notification.sh standard</string>
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
        <string>$SCRIPTS_DIR/monthly-claude-cleanup.sh && $SCRIPTS_DIR/send-notification.sh smart-ai</string>
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
    
    # Create user bin directory (no sudo needed!)
    mkdir -p "$(dirname "$BIN_LINK")"
    
    # Remove existing symlink if it exists
    if [ -L "$BIN_LINK" ]; then
        rm "$BIN_LINK"
    fi
    
    # Create symlink in user space
    if ln -sf "$SCRIPTS_DIR/manage-cleanup.sh" "$BIN_LINK"; then
        print_success "Command 'smartjanitor' ready in your personal toolkit"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$(dirname "$BIN_LINK"):"* ]]; then
            print_janitor "Adding janitor tools to your PATH..."
            
            # Add to shell profile
            local shell_profile=""
            if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ]; then
                shell_profile="$HOME/.zshrc"
            elif [ -n "$BASH_VERSION" ] || [ "$SHELL" = "/bin/bash" ]; then
                shell_profile="$HOME/.bash_profile"
            fi
            
            if [ -n "$shell_profile" ]; then
                echo "export PATH=\"$(dirname "$BIN_LINK"):\$PATH\"" >> "$shell_profile"
                print_success "Added to $shell_profile - restart terminal or run: source $shell_profile"
            fi
        else
            print_success "Already in your PATH - ready to use!"
        fi
    else
        print_warning "Could not create command shortcut"
        print_janitor "No worries! You can still summon the janitor: $SCRIPTS_DIR/manage-cleanup.sh"
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
    if [ -x "$BIN_LINK" ]; then
        echo "   smartjanitor status       # Check what the janitor is up to"
        echo "   smartjanitor standard     # Start cleaning right now"
        echo "   smartjanitor logs         # See cleaning reports"
        echo "   smartjanitor schedule     # When's the next cleanup?"
        echo "   smartjanitor uninstall    # Fire the janitor (sadly)"
        echo ""
        echo -e "${CYAN}💡 If 'smartjanitor' command not found, restart your terminal first!${NC}"
    else
        echo "   $SCRIPTS_DIR/manage-cleanup.sh status"
        echo "   $SCRIPTS_DIR/manage-cleanup.sh standard"
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
    
    echo -e "${YELLOW}🚀 Ready to start cleaning? Try these commands:${NC}"
    if command -v smartjanitor &> /dev/null; then
        echo "   smartjanitor standard     # Quick standard cleanup"
        if [ "$ENABLE_AI" = true ]; then
            echo "   smartjanitor smart-ai     # Deep AI-powered analysis"
        fi
    else
        echo "   $SCRIPTS_DIR/manage-cleanup.sh standard"
        if [ "$ENABLE_AI" = true ]; then
            echo "   $SCRIPTS_DIR/manage-cleanup.sh smart-ai"
        fi
    fi
    echo ""
}

main() {
    print_header
    
    echo -e "${CYAN}SmartJanitor will set up automated cleanup for your MacBook.${NC}"
    echo "No more 'disk almost full' warnings. No more manual tidying."
    echo "Just a clean Mac that maintains itself."
    echo ""
    
    show_detected_config
    
    print_janitor "Deploying your automated cleanup crew..."
    echo ""
    
    check_requirements
    create_directories
    copy_or_download_scripts
    create_launchd_plists
    create_symlink
    install_services
    show_completion
}

# Handle interruption  
trap 'echo -e "\n${RED}💥 Installation interrupted! The janitor will try again later.${NC}"; exit 1' INT

# Run main function
main "$@"