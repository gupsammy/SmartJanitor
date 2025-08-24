#!/bin/bash
# Weekly Storage Cleanup Script
# Safe automated cleanup of common storage bloat

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$HOME/.smartjanitor"
LOG_FILE="$SCRIPT_DIR/logs/standard-cleanup-$(date +%Y%m%d-%H%M%S).log"
SUMMARY_FILE="$SCRIPT_DIR/logs/latest-standard.log"

# Ensure log directory exists
mkdir -p "$SCRIPT_DIR/logs"

# Redirect all output to log file and terminal
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "=================================="
echo "Weekly Storage Cleanup Started"
echo "Date: $(date)"
echo "=================================="

# Record initial disk usage
INITIAL_USAGE=$(df -h /System/Volumes/Data | tail -1 | awk '{print $3}')
echo "Initial disk usage: $INITIAL_USAGE"

TOTAL_SAVED=0

# Function to calculate space saved
calculate_saved() {
    local before=$1
    local after=$2
    local saved=$((before - after))
    TOTAL_SAVED=$((TOTAL_SAVED + saved))
    if [ $saved -gt 0 ]; then
        echo "  ✅ Freed: $(numfmt --to=iec $saved)"
    else
        echo "  ℹ️  No space freed"
    fi
}

echo -e "\n🐳 Cleaning Docker..."
if command -v docker &> /dev/null && docker info &> /dev/null; then
    DOCKER_BEFORE=$(docker system df --format "table {{.Size}}" | tail -n +2 | sed 's/[A-Za-z]*//g' | awk '{sum+=$1} END {print sum}' || echo "0")
    docker system prune -a -f --volumes
    DOCKER_AFTER=$(docker system df --format "table {{.Size}}" | tail -n +2 | sed 's/[A-Za-z]*//g' | awk '{sum+=$1} END {print sum}' || echo "0")
    echo "Docker cleanup completed"
else
    echo "Docker not running or not available"
fi

echo -e "\n📦 Cleaning Package Managers..."
# pnpm store cleanup
if command -v pnpm &> /dev/null; then
    PNPM_BEFORE=$(du -sk "$HOME/Library/pnpm" 2>/dev/null | cut -f1 || echo "0")
    pnpm store prune 2>/dev/null || echo "pnpm cleanup failed (may not have packages)"
    PNPM_AFTER=$(du -sk "$HOME/Library/pnpm" 2>/dev/null | cut -f1 || echo "0")
    calculate_saved $PNPM_BEFORE $PNPM_AFTER
else
    echo "pnpm not available"
fi

# Homebrew cleanup
if command -v brew &> /dev/null; then
    BREW_CACHE_BEFORE=$(du -sk "$(brew --cache)" 2>/dev/null | cut -f1 || echo "0")
    brew cleanup --prune=all -s 2>/dev/null || echo "Homebrew cleanup completed with warnings"
    BREW_CACHE_AFTER=$(du -sk "$(brew --cache)" 2>/dev/null | cut -f1 || echo "0")
    calculate_saved $BREW_CACHE_BEFORE $BREW_CACHE_AFTER
else
    echo "Homebrew not available"
fi

# npm cache cleanup
if command -v npm &> /dev/null; then
    echo "Cleaning npm cache..."
    npm cache clean --force 2>/dev/null || echo "npm cache cleanup completed with warnings"
fi

echo -e "\n🏗️ Removing Build Artifacts (>7 days old)..."
BUILD_COUNT=0
# Next.js build folders
BUILD_COUNT=$(find "$HOME/Documents" -name ".next" -type d -mtime +7 2>/dev/null | wc -l | tr -d ' ')
if [ "$BUILD_COUNT" -gt 0 ]; then
    echo "Found $BUILD_COUNT .next folders to remove"
    find "$HOME/Documents" -name ".next" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
fi

# Node modules older than 30 days in project folders
NODE_COUNT=$(find "$HOME/Documents" -name "node_modules" -type d -mtime +30 2>/dev/null | wc -l | tr -d ' ')
if [ "$NODE_COUNT" -gt 0 ]; then
    echo "Found $NODE_COUNT old node_modules folders to remove"
    find "$HOME/Documents" -name "node_modules" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true
fi

echo -e "\n🗂️ Cleaning Application Caches..."
# Safe cache cleanup
CACHE_CLEANED=0

# Homebrew caches
if [ -d "$HOME/Library/Caches/Homebrew" ]; then
    rm -rf "$HOME/Library/Caches/Homebrew"/* 2>/dev/null || true
    echo "Cleaned Homebrew caches"
    CACHE_CLEANED=$((CACHE_CLEANED + 1))
fi

# Google updater cache (safe to remove)
if [ -d "$HOME/Library/Application Support/Google/GoogleUpdater/crx_cache" ]; then
    rm -rf "$HOME/Library/Application Support/Google/GoogleUpdater/crx_cache" 2>/dev/null || true
    echo "Cleaned Google updater cache"
    CACHE_CLEANED=$((CACHE_CLEANED + 1))
fi

# Chrome component caches (regenerated automatically)
find "$HOME/Library/Application Support" -name "*component_crx_cache*" -type d -exec rm -rf {} + 2>/dev/null || true
find "$HOME/Library/Application Support" -name "*extensions_crx_cache*" -type d -exec rm -rf {} + 2>/dev/null || true
echo "Cleaned browser component caches"

echo -e "\n📝 Cleaning Large Log Files (>10MB)..."
LOG_COUNT=$(find "$HOME/Library/Logs" -name "*.log" -size +10M 2>/dev/null | wc -l | tr -d ' ')
if [ "$LOG_COUNT" -gt 0 ]; then
    echo "Found $LOG_COUNT large log files to clean"
    find "$HOME/Library/Logs" -name "*.log" -size +10M -delete 2>/dev/null || true
fi

# Clean up old cleanup logs (keep last 10)
find "$SCRIPT_DIR/logs" -name "standard-cleanup-*.log" -type f | sort -r | tail -n +11 | xargs rm -f 2>/dev/null || true
find "$SCRIPT_DIR/logs" -name "smart-ai-*.log" -type f | sort -r | tail -n +6 | xargs rm -f 2>/dev/null || true

echo -e "\n📊 Final Results"
echo "=================================="
FINAL_USAGE=$(df -h /System/Volumes/Data | tail -1 | awk '{print $3}')
AVAILABLE_SPACE=$(df -h /System/Volumes/Data | tail -1 | awk '{print $4}')
echo "Initial usage: $INITIAL_USAGE"
echo "Final usage: $FINAL_USAGE"
echo "Available space: $AVAILABLE_SPACE"
echo "Cleanup completed: $(date)"
echo "=================================="

# Create summary for notification
cat > "$SUMMARY_FILE" << EOF
Weekly Cleanup Summary - $(date '+%Y-%m-%d %H:%M')
==============================================
Initial disk usage: $INITIAL_USAGE
Final disk usage: $FINAL_USAGE  
Available space: $AVAILABLE_SPACE

Actions performed:
- Docker cleanup
- Package manager cleanup (pnpm, brew, npm)
- Removed $BUILD_COUNT old build artifacts
- Removed $NODE_COUNT old node_modules folders  
- Cleaned $CACHE_CLEANED cache directories
- Removed $LOG_COUNT large log files

Full log: $LOG_FILE
EOF

echo -e "\n✅ Weekly cleanup completed successfully!"
echo "Check summary: $SUMMARY_FILE"