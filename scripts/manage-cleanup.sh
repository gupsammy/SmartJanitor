#!/bin/bash
# Management script for storage cleanup automation

SCRIPT_DIR="$HOME/.cleanup-scripts"
cd "$SCRIPT_DIR"

show_usage() {
    echo "Storage Cleanup Manager"
    echo "====================="
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  install    - Install and start the launchd services"
    echo "  uninstall  - Stop and remove the launchd services"
    echo "  status     - Show status of services and recent logs"
    echo "  logs       - Open logs directory in Finder"
    echo "  test-weekly   - Run weekly cleanup immediately"
    echo "  test-monthly  - Run monthly cleanup immediately (requires API key)"
    echo "  schedule   - Show next scheduled run times"
    echo ""
    echo "Examples:"
    echo "  $0 install     # Set up automation"
    echo "  $0 status      # Check if everything is working"
    echo "  $0 test-weekly # Test the weekly cleanup now"
}

install_services() {
    echo "Installing storage cleanup automation..."
    
    # Load the weekly service
    launchctl load ~/Library/LaunchAgents/com.user.storage-cleanup.weekly.plist
    if [ $? -eq 0 ]; then
        echo "✅ Weekly cleanup service installed"
    else
        echo "❌ Failed to install weekly cleanup service"
    fi
    
    # Load the monthly service
    launchctl load ~/Library/LaunchAgents/com.user.storage-cleanup.monthly.plist
    if [ $? -eq 0 ]; then
        echo "✅ Monthly cleanup service installed"
    else
        echo "❌ Failed to install monthly cleanup service"
    fi
    
    echo ""
    echo "📋 Services installed! They will run:"
    echo "  • Weekly: Every Sunday at 10 AM"
    echo "  • Monthly: 1st of each month at 9 AM"
    echo ""
    echo "💡 If your Mac is asleep, tasks will run when it wakes up"
    echo "💡 You'll get notifications with clickable log viewing"
}

uninstall_services() {
    echo "Uninstalling storage cleanup automation..."
    
    # Unload services
    launchctl unload ~/Library/LaunchAgents/com.user.storage-cleanup.weekly.plist 2>/dev/null
    launchctl unload ~/Library/LaunchAgents/com.user.storage-cleanup.monthly.plist 2>/dev/null
    
    echo "✅ Services uninstalled"
    echo "💡 Scripts and logs remain in $SCRIPT_DIR"
    echo "💡 To completely remove: rm -rf $SCRIPT_DIR"
}

show_status() {
    echo "Storage Cleanup Status"
    echo "===================="
    
    # Check if services are loaded
    echo "Service Status:"
    if launchctl list | grep -q "com.user.storage-cleanup.weekly"; then
        echo "  ✅ Weekly service: Running"
    else
        echo "  ❌ Weekly service: Not running"
    fi
    
    if launchctl list | grep -q "com.user.storage-cleanup.monthly"; then
        echo "  ✅ Monthly service: Running"  
    else
        echo "  ❌ Monthly service: Not running"
    fi
    
    echo ""
    
    # Show recent logs
    echo "Recent Activity:"
    if [ -f "$SCRIPT_DIR/logs/latest-weekly.log" ]; then
        echo "  📝 Last weekly cleanup:"
        head -n 2 "$SCRIPT_DIR/logs/latest-weekly.log" | tail -n 1
    else
        echo "  📝 No weekly cleanup logs found"
    fi
    
    if [ -f "$SCRIPT_DIR/logs/latest-monthly.log" ]; then
        echo "  📝 Last monthly cleanup:"
        head -n 2 "$SCRIPT_DIR/logs/latest-monthly.log" | tail -n 1
    else
        echo "  📝 No monthly cleanup logs found"
    fi
    
    echo ""
    
    # Show disk usage
    echo "Current Disk Usage:"
    df -h /System/Volumes/Data | tail -1 | awk '{print "  💾 Used: " $3 " / Available: " $4 " (" $5 " full)"}'
    
    echo ""
    echo "💡 Use '$0 logs' to view detailed logs"
    echo "💡 Use '$0 schedule' to see next run times"
}

show_schedule() {
    echo "Next Scheduled Runs"
    echo "=================="
    
    # Get next Sunday 10 AM
    NEXT_SUNDAY=$(date -v+1w -v0 +"%Y-%m-%d")
    echo "📅 Next weekly cleanup: Sunday $NEXT_SUNDAY at 10:00 AM"
    
    # Get first of next month
    NEXT_MONTH=$(date -v+1m -v1d +"%Y-%m-%d")
    echo "📅 Next monthly cleanup: $NEXT_MONTH at 9:00 AM"
    
    echo ""
    echo "💡 Tasks will run when your Mac wakes up if it was asleep during scheduled time"
}

open_logs() {
    if [ ! -d "$SCRIPT_DIR/logs" ]; then
        echo "❌ No logs directory found"
        return 1
    fi
    
    echo "Opening logs directory..."
    open "$SCRIPT_DIR/logs"
}

test_weekly() {
    echo "🧪 Testing weekly cleanup..."
    echo "This will run the actual cleanup process!"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        return 0
    fi
    
    "$SCRIPT_DIR/weekly-cleanup.sh"
    "$SCRIPT_DIR/send-notification.sh" weekly
}

test_monthly() {
    echo "🧪 Testing monthly Claude cleanup..."
    
    # Check for API key (optional if using subscription)
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "⚠️  No ANTHROPIC_API_KEY set - trying with subscription login"
        echo "💡 If this fails, set API key with: export ANTHROPIC_API_KEY='your-key'"
        echo ""
    fi
    
    echo "This will run Claude Code analysis and cleanup!"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        return 0
    fi
    
    "$SCRIPT_DIR/monthly-claude-cleanup.sh"
    "$SCRIPT_DIR/send-notification.sh" monthly
}

# Main script logic
case "${1:-}" in
    "install")
        install_services
        ;;
    "uninstall")
        uninstall_services
        ;;
    "status")
        show_status
        ;;
    "logs")
        open_logs
        ;;
    "test-weekly")
        test_weekly
        ;;
    "test-monthly")
        test_monthly
        ;;
    "schedule")
        show_schedule
        ;;
    *)
        show_usage
        ;;
esac