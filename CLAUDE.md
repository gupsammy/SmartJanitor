# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SmartJanitor is an automated macOS storage cleanup tool that uses a dual approach:
- **Weekly bash cleanup**: Fast automated cleanup of common storage bloat
- **Monthly AI analysis**: Claude Code performs intelligent storage analysis

The system uses macOS `launchd` for reliable scheduling and runs even when the Mac is sleeping.

## Architecture

### Core Components
- `scripts/standard-cleanup.sh` - Pure bash cleanup script for speed and reliability
- `scripts/smart-ai-cleanup.sh` - AI-powered deep analysis using Claude Code
- `scripts/manage-cleanup.sh` - Management interface and user commands  
- `scripts/send-notification.sh` - Interactive notification system using AppleScript
- `install.sh` - One-line installer that sets up everything

### Installation Structure
```
~/.smartjanitor/
├── scripts/                    # All executable scripts
│   ├── standard-cleanup.sh      # Fast bash cleanup
│   ├── smart-ai-cleanup.sh      # AI analysis
│   ├── manage-cleanup.sh      # Management commands  
│   └── send-notification.sh   # Notifications
├── logs/                      # Cleanup logs and summaries
└── .claude/                   # Claude Code settings (created dynamically)
```

### Scheduling
- **Weekly**: Every Sunday at 10:00 AM via `com.user.smartjanitor.standard.plist`
- **Monthly**: 1st of each month at 9:00 AM via `com.user.smartjanitor.smart-ai.plist`
- Uses macOS `launchd` which handles sleep/wake scenarios properly

## Development Commands

### Installation & Testing
```bash
# Install in development mode (creates symlinks for live editing)
./install.sh --dev

# Install normally (copies files)
./install.sh

# Run standard cleanup immediately 
smartjanitor standard

# Run smart AI analysis (requires Claude Code)
smartjanitor smart-ai

# Check system status
smartjanitor status

# View cleanup logs
smartjanitor logs
```

### Management Commands
The main interface is through the `smartjanitor` global command (symlinked to `manage-cleanup.sh`):
```bash
smartjanitor status      # Show service status and recent activity
smartjanitor schedule    # Show next scheduled run times  
smartjanitor logs        # Open logs directory in Finder
smartjanitor uninstall   # Remove all services and configs
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
- LaunchAgents: `~/Library/LaunchAgents/com.user.smartjanitor.*.plist`
- Install directory: `~/.smartjanitor/`
- Global command: `$HOME/.local/bin/smartjanitor`
- Logs: `~/.smartjanitor/logs/`

## Logging & Notifications

### Log Structure
- Detailed logs: `logs/standard-cleanup-YYYYMMDD-HHMMSS.log`
- Summary logs: `logs/latest-standard.log`, `logs/latest-smart-ai.log`
- LaunchD logs: `logs/standard-launchd.out`, `logs/smart-ai-launchd.out`

### Interactive Notifications
Uses AppleScript to show cleanup results with clickable buttons:
- "OK" - Dismiss notification  
- "View Logs" - Opens Finder + TextEdit with detailed logs

## Storage Cleanup Categories

The system targets these common macOS storage bloat sources:
- **Docker**: 20-50GB (images, containers, build cache, volumes)
- **Package Managers**: 5-20GB (npm, yarn, bun, pnpm, uv, pip, go, brew caches)
- **Browser Caches**: 2-10GB (Chrome, Safari, Firefox, Edge, Arc, Comet + more)
- **Build Artifacts**: 5-15GB (.next, node_modules, target, dist, build, __pycache__)
- **Logs**: 500MB-2GB (large log files)

## Claude Code Safety Context

When working on this project, remember:
1. This is a **defensive security tool** - storage cleanup automation
2. All cleanup operations are **conservative and safe**
3. The monthly script demonstrates **proper Claude Code permission restriction**
4. Never modify the safety rules or expand file deletion beyond the approved categories
5. Prioritize safety over cleanup effectiveness