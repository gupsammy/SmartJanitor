# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mac Storage Cleaner is an automated macOS storage cleanup tool that uses a dual approach:
- **Weekly bash cleanup**: Fast automated cleanup of common storage bloat
- **Monthly AI analysis**: Claude Code performs intelligent storage analysis

The system uses macOS `launchd` for reliable scheduling and runs even when the Mac is sleeping.

## Architecture

### Core Components
- `scripts/weekly-cleanup.sh` - Pure bash cleanup script for speed and reliability
- `scripts/monthly-claude-cleanup.sh` - AI-powered deep analysis using Claude Code
- `scripts/manage-cleanup.sh` - Management interface and user commands  
- `scripts/send-notification.sh` - Interactive notification system using AppleScript
- `install.sh` - One-line installer that sets up everything

### Installation Structure
```
~/.mac-storage-cleaner/
├── scripts/                    # All executable scripts
│   ├── weekly-cleanup.sh      # Fast bash cleanup
│   ├── monthly-claude.sh      # AI analysis
│   ├── manage-cleanup.sh      # Management commands  
│   └── send-notification.sh   # Notifications
├── logs/                      # Cleanup logs and summaries
└── .claude/                   # Claude Code settings (created dynamically)
```

### Scheduling
- **Weekly**: Every Sunday at 10:00 AM via `com.user.storage-cleanup.weekly.plist`
- **Monthly**: 1st of each month at 9:00 AM via `com.user.storage-cleanup.monthly.plist`
- Uses macOS `launchd` which handles sleep/wake scenarios properly

## Development Commands

### Installation & Testing
```bash
# Install in development mode
./scripts/install-dev.sh

# Test weekly cleanup immediately 
mac-cleanup test-weekly

# Test monthly AI analysis (requires Claude Code)
mac-cleanup test-monthly

# Check system status
mac-cleanup status

# View cleanup logs
mac-cleanup logs
```

### Management Commands
The main interface is through the `mac-cleanup` global command (symlinked to `manage-cleanup.sh`):
```bash
mac-cleanup status      # Show service status and recent activity
mac-cleanup schedule    # Show next scheduled run times  
mac-cleanup logs        # Open logs directory in Finder
mac-cleanup uninstall   # Remove all services and configs
```

## Claude Code Integration

The monthly cleanup uses Claude Code with restricted permissions for safety:

### Safety Configuration
- **Allowed tools**: Bash (specific commands), Read, Glob, Grep, LS, TodoWrite
- **Denied tools**: Write, Edit, MultiEdit, WebSearch, WebFetch
- **Allowed bash patterns**: Cleanup commands only (docker, brew, npm, etc.)
- **Denied bash patterns**: Any operations on user documents/Applications

### Claude Code Usage Pattern
```bash
claude -p "$CLAUDE_PROMPT" \
  --allowedTools "Bash,Read,Glob,Grep,LS,TodoWrite" \
  --disallowedTools "Write,Edit,MultiEdit,WebSearch,WebFetch" \
  --output-format json \
  --append-system-prompt "Safety-first conservative cleanup approach" \
  --dangerously-skip-permissions
```

## Safety Rules

### What Gets Cleaned
- ✅ Caches (Homebrew, npm, browser components)
- ✅ Build artifacts (.next, dist, build folders >7 days old)
- ✅ Old dependencies (node_modules >30 days old)
- ✅ Docker unused images/containers/volumes  
- ✅ Large log files (>10MB)
- ✅ Package manager caches

### What's Never Touched
- ❌ User documents, photos, music
- ❌ Applications and system files
- ❌ Active projects and recent builds (<7 days)
- ❌ Configuration files
- ❌ Claude Code settings

## Development Setup

### Requirements
- macOS 14+ (uses modern launchd features)
- Homebrew (for package cache cleanup)
- Docker (optional, for Docker cleanup)
- Claude Code (optional, for AI analysis)

### Key File Locations
- LaunchAgents: `~/Library/LaunchAgents/com.user.storage-cleanup.*.plist`
- Install directory: `~/.mac-storage-cleaner/`
- Global command: `/usr/local/bin/mac-cleanup`
- Logs: `~/.mac-storage-cleaner/logs/`

## Logging & Notifications

### Log Structure
- Detailed logs: `logs/weekly-cleanup-YYYYMMDD-HHMMSS.log`
- Summary logs: `logs/latest-weekly.log`, `logs/latest-monthly.log`
- LaunchD logs: `logs/weekly-launchd.out`, `logs/monthly-launchd.out`

### Interactive Notifications
Uses AppleScript to show cleanup results with clickable buttons:
- "OK" - Dismiss notification  
- "View Logs" - Opens Finder + TextEdit with detailed logs

## Storage Cleanup Categories

The system targets these common macOS storage bloat sources:
- **Docker**: 20-50GB (images, containers, build cache)
- **Dependencies**: 5-15GB (old node_modules, package caches)
- **App Caches**: 2-10GB (browser components, updater caches) 
- **Build Artifacts**: 1-5GB (.next, dist folders)
- **Logs**: 500MB-2GB (large log files)

## Claude Code Safety Context

When working on this project, remember:
1. This is a **defensive security tool** - storage cleanup automation
2. All cleanup operations are **conservative and safe**
3. The monthly script demonstrates **proper Claude Code permission restriction**
4. Never modify the safety rules or expand file deletion beyond the approved categories
5. Prioritize safety over cleanup effectiveness