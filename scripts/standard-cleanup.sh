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

# Yarn cache cleanup (both v1 and v2/Berry)
if command -v yarn &> /dev/null; then
    echo "Cleaning Yarn cache..."
    yarn cache clean 2>/dev/null || echo "Yarn cache cleanup completed with warnings"
fi

# Bun cache cleanup
if command -v bun &> /dev/null; then
    echo "Cleaning Bun cache..."
    rm -rf ~/.bun/cache 2>/dev/null || true
    echo "Bun cache cleaned"
fi

# UV (Python) cache cleanup  
if command -v uv &> /dev/null; then
    echo "Cleaning UV cache..."
    uv cache clean 2>/dev/null || echo "UV cache cleanup completed"
fi

# Go modules cache cleanup
if command -v go &> /dev/null; then
    echo "Cleaning Go module cache..."
    go clean -modcache 2>/dev/null || echo "Go module cache cleanup completed"
fi

# pip cache cleanup
if command -v pip3 &> /dev/null || command -v pip &> /dev/null; then
    echo "Cleaning pip cache..."
    python3 -m pip cache purge 2>/dev/null || pip cache purge 2>/dev/null || echo "pip cache cleanup completed"
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

# Rust target directories (older than 7 days)
TARGET_COUNT=$(find "$HOME/Documents" -name "target" -type d -mtime +7 2>/dev/null | wc -l | tr -d ' ')
if [ "$TARGET_COUNT" -gt 0 ]; then
    echo "Found $TARGET_COUNT old Rust target folders to remove"
    find "$HOME/Documents" -name "target" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
fi

# Python __pycache__ directories
PYCACHE_COUNT=$(find "$HOME/Documents" -name "__pycache__" -type d 2>/dev/null | wc -l | tr -d ' ')
if [ "$PYCACHE_COUNT" -gt 0 ]; then
    echo "Found $PYCACHE_COUNT Python cache folders to remove"
    find "$HOME/Documents" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
fi

# Go build artifacts (vendor directories older than 7 days)
VENDOR_COUNT=$(find "$HOME/Documents" -name "vendor" -type d -mtime +7 2>/dev/null | wc -l | tr -d ' ')
if [ "$VENDOR_COUNT" -gt 0 ]; then
    echo "Found $VENDOR_COUNT old vendor folders to remove"
    find "$HOME/Documents" -name "vendor" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
fi

# Generic build/dist directories (older than 7 days)
BUILD_EXTRA_COUNT=$(find "$HOME/Documents" -name "build" -type d -mtime +7 2>/dev/null | wc -l | tr -d ' ')
DIST_COUNT=$(find "$HOME/Documents" -name "dist" -type d -mtime +7 2>/dev/null | wc -l | tr -d ' ')
if [ "$BUILD_EXTRA_COUNT" -gt 0 ]; then
    echo "Found $BUILD_EXTRA_COUNT old build folders to remove"
    find "$HOME/Documents" -name "build" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
fi
if [ "$DIST_COUNT" -gt 0 ]; then
    echo "Found $DIST_COUNT old dist folders to remove"  
    find "$HOME/Documents" -name "dist" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
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

# Microsoft Edge cache
if [ -d "$HOME/Library/Caches/Microsoft Edge" ]; then
    rm -rf "$HOME/Library/Caches/Microsoft Edge"/* 2>/dev/null || true
    echo "Cleaned Microsoft Edge cache"
fi

# Arc browser cache (based on bundle ID company.thebrowser.Browser)
if [ -d "$HOME/Library/Caches/company.thebrowser.Browser" ]; then
    rm -rf "$HOME/Library/Caches/company.thebrowser.Browser"/* 2>/dev/null || true
    echo "Cleaned Arc browser cache"
fi

# Firefox cache
if [ -d "$HOME/Library/Caches/Firefox" ]; then
    rm -rf "$HOME/Library/Caches/Firefox"/* 2>/dev/null || true
    echo "Cleaned Firefox cache"
fi

# Comet browser (Chromium-based, search for likely locations)
find "$HOME/Library/Caches" -name "*comet*" -type d -exec rm -rf {}/* + 2>/dev/null || true
find "$HOME/Library/Caches" -name "*perplexity*" -type d -exec rm -rf {}/* + 2>/dev/null || true

# DIA Browser (search for likely cache locations)
find "$HOME/Library/Caches" -name "*dia*" -type d -exec rm -rf {}/* + 2>/dev/null || true

# General browser cache cleanup (catch remaining browsers)
find "$HOME/Library/Caches" -name "*Browser*" -type d -exec rm -rf {}/* + 2>/dev/null || true

echo "Cleaned browser component and application caches"

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
- Package manager cleanup (pnpm, brew, npm, yarn, bun, uv, go, pip)
- Removed $BUILD_COUNT old .next build artifacts
- Removed $NODE_COUNT old node_modules folders
- Removed $TARGET_COUNT old Rust target folders
- Removed $PYCACHE_COUNT Python cache folders  
- Removed $VENDOR_COUNT old vendor folders
- Removed $BUILD_EXTRA_COUNT old build + $DIST_COUNT old dist folders
- Cleaned $CACHE_CLEANED app cache directories + comprehensive browser caches
- Removed $LOG_COUNT large log files

Full log: $LOG_FILE
EOF

echo -e "\n✅ Weekly cleanup completed successfully!"
echo "Check summary: $SUMMARY_FILE"