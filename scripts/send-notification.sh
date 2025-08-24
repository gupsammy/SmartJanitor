#!/bin/bash
# Notification sender for cleanup results

SCRIPT_DIR="$HOME/.smartjanitor"
CLEANUP_TYPE="$1"  # "weekly" or "monthly"
SUMMARY_FILE="$SCRIPT_DIR/logs/latest-$CLEANUP_TYPE.log"

if [ ! -f "$SUMMARY_FILE" ]; then
    echo "Summary file not found: $SUMMARY_FILE"
    exit 1
fi

# Read the summary
SUMMARY_CONTENT=$(cat "$SUMMARY_FILE")

# Create AppleScript for interactive notification
osascript << EOF
try
    set cleanupSummary to "$SUMMARY_CONTENT"
    
    -- Show notification with action buttons
    display dialog cleanupSummary with title "Storage Cleanup Complete" buttons {"View Logs", "OK"} default button "OK" with icon note
    
    set buttonPressed to button returned of result
    
    if buttonPressed is "View Logs" then
        -- Open log directory in Finder
        tell application "Finder"
            activate
            open folder POSIX file "$SCRIPT_DIR/logs"
        end tell
        
        -- Also show detailed log in TextEdit for easy reading
        tell application "TextEdit"
            activate
            open POSIX file "$SUMMARY_FILE"
        end tell
    end if
    
on error errorMessage number errorNumber
    display dialog "Notification error: " & errorMessage buttons {"OK"} default button "OK" with icon stop
end try
EOF