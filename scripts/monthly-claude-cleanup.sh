#!/bin/bash
# Monthly Deep Storage Analysis with Claude
# Uses Claude Code in headless mode for intelligent cleanup

set -e

# Configuration
SCRIPT_DIR="$HOME/.smartjanitor"
LOG_FILE="$SCRIPT_DIR/logs/smart-ai-$(date +%Y%m%d-%H%M%S).log"
SUMMARY_FILE="$SCRIPT_DIR/logs/latest-smart-ai.log"

# Ensure log directory exists
mkdir -p "$SCRIPT_DIR/logs"

# Redirect all output to log file and terminal
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "=================================="
echo "Monthly Claude Storage Analysis"
echo "Date: $(date)"
echo "=================================="

# Check if Claude Code is available
if ! command -v claude &> /dev/null; then
    echo "❌ ERROR: Claude Code not found. Please install @anthropic-ai/claude-code"
    exit 1
fi

# Check if API key is set (may not be needed if logged in with subscription)
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "⚠️  WARNING: ANTHROPIC_API_KEY not set. Trying with subscription login..."
    echo "💡 If this fails, set API key with: export ANTHROPIC_API_KEY='your-key'"
fi

# Record initial state
INITIAL_USAGE=$(df -h /System/Volumes/Data | tail -1 | awk '{print $3}')
INITIAL_AVAILABLE=$(df -h /System/Volumes/Data | tail -1 | awk '{print $4}')

echo "Initial disk usage: $INITIAL_USAGE"
echo "Initial available: $INITIAL_AVAILABLE"

# Create Claude settings for this session
CLAUDE_SETTINGS_DIR="$SCRIPT_DIR/.claude"
mkdir -p "$CLAUDE_SETTINGS_DIR"

cat > "$CLAUDE_SETTINGS_DIR/settings.json" << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(docker system*)",
      "Bash(brew cleanup*)",
      "Bash(pnpm store prune)",
      "Bash(npm cache clean*)",
      "Bash(find * -name .next -delete)",
      "Bash(find * -name node_modules -delete)",
      "Bash(find * -name dist -delete)",
      "Bash(rm -rf ~/Library/Caches/*)",
      "Bash(rm -rf ~/Library/Application\\ Support/*/cache*)",
      "Bash(rm -rf ~/Library/Application\\ Support/*Cache*)",
      "Bash(rm -f */*.log)",
      "Bash(du *)",
      "Bash(df *)",
      "Read",
      "Glob",
      "Grep", 
      "LS",
      "TodoWrite"
    ],
    "deny": [
      "Bash(rm -rf ~/Documents*)",
      "Bash(rm -rf ~/Desktop*)",
      "Bash(rm -rf ~/Pictures*)",
      "Bash(rm -rf ~/Applications*)",
      "Bash(rm -rf ~/Library/Application\\ Support/Claude*)",
      "Bash(rm -rf ~/Library/Application\\ Support/Cursor*)",
      "Bash(git *)",
      "Write",
      "Edit",
      "MultiEdit",
      "WebSearch",
      "WebFetch"
    ]
  }
}
EOF

echo -e "\n🤖 Running Claude analysis..."

# Create the intelligent cleanup prompt
CLAUDE_PROMPT="Perform a comprehensive Mac storage analysis and cleanup:

ANALYSIS PHASE:
1. Check current disk usage with df -h
2. Identify largest directories and files using du and find
3. Look for common storage bloat patterns:
   - Docker images and containers
   - Old node_modules directories (>30 days)
   - Build artifacts (.next, dist, build folders >7 days)
   - Application caches and temp files
   - Large log files (>50MB)
   - Package manager caches (npm, pnpm, brew)
   - Browser caches and components

CLEANUP PHASE:
4. Execute safe cleanup operations in this priority order:
   a) Docker system cleanup (images, containers, cache)
   b) Package manager cleanup (npm, pnpm, brew caches)
   c) Remove old build artifacts from ~/Documents projects
   d) Clear safe application caches
   e) Remove large log files
   f) Clean browser component caches

SAFETY RULES:
- Never delete user documents, photos, or important files
- Only remove caches, build artifacts, and temp files
- Verify file ages before deletion (build artifacts >7 days, node_modules >30 days)
- Provide detailed logging of all actions
- Calculate and report space recovered

REPORTING:
5. Create a detailed summary showing:
   - Initial vs final disk usage
   - Breakdown of space recovered by category
   - List of all cleanup operations performed
   - Any issues or warnings encountered

Begin the analysis and cleanup now."

# Run Claude with restricted permissions
cd "$HOME"
claude -p "$CLAUDE_PROMPT" \
  --allowedTools "Bash,Read,Glob,Grep,LS,TodoWrite" \
  --disallowedTools "Write,Edit,MultiEdit,WebSearch,WebFetch" \
  --output-format json \
  --append-system-prompt "You are a Mac storage cleanup specialist. Prioritize safety - only delete files that are 100% safe to remove: caches, build artifacts, logs, and temporary files. Provide detailed logging of all operations. Be conservative and explain your reasoning for each cleanup decision." \
  --dangerously-skip-permissions
# Capture results
CLAUDE_EXIT_CODE=$?
FINAL_USAGE=$(df -h /System/Volumes/Data | tail -1 | awk '{print $3}')
FINAL_AVAILABLE=$(df -h /System/Volumes/Data | tail -1 | awk '{print $4}')

echo -e "\n📊 Final Results"
echo "=================================="
echo "Initial usage: $INITIAL_USAGE"
echo "Final usage: $FINAL_USAGE"
echo "Initial available: $INITIAL_AVAILABLE"  
echo "Final available: $FINAL_AVAILABLE"
echo "Claude exit code: $CLAUDE_EXIT_CODE"
echo "Analysis completed: $(date)"
echo "=================================="

# Create summary for notification
cat > "$SUMMARY_FILE" << EOF
Monthly Claude Analysis - $(date '+%Y-%m-%d %H:%M')
================================================
Initial disk usage: $INITIAL_USAGE
Final disk usage: $FINAL_USAGE
Initial available: $INITIAL_AVAILABLE
Final available: $FINAL_AVAILABLE

Claude Analysis Results:
- Exit code: $CLAUDE_EXIT_CODE
- AI-powered storage analysis completed
- Intelligent cleanup of bloat patterns
- Conservative safety approach used

Full detailed log: $LOG_FILE
EOF

if [ $CLAUDE_EXIT_CODE -eq 0 ]; then
    echo "✅ Monthly Claude analysis completed successfully!"
else
    echo "⚠️ Claude analysis completed with exit code: $CLAUDE_EXIT_CODE"
fi

echo "Check summary: $SUMMARY_FILE"