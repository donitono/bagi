#!/bin/bash

# File watcher script for auto-commit
# Usage: ./watch_files.sh

cd /workspaces/bagi

echo "👀 Starting file watcher for auto-commit..."
echo "📁 Watching directory: $(pwd)"
echo "🔄 Will auto-commit and push changes every 30 seconds"
echo "⏹️  Press Ctrl+C to stop"

while true; do
    # Check if there are any changes
    if [[ -n $(git status --porcelain) ]]; then
        echo ""
        echo "🔍 Changes detected at $(date '+%H:%M:%S'):"
        git status --porcelain
        
        # Add all changes
        git add .
        
        # Commit with timestamp
        COMMIT_MSG="🔄 Auto-update: $(date '+%Y-%m-%d %H:%M:%S')"
        git commit -m "$COMMIT_MSG"
        
        echo "✅ Changes committed and pushed automatically!"
        echo "📝 Commit: $COMMIT_MSG"
    else
        printf "."
    fi
    
    # Wait 30 seconds before checking again
    sleep 30
done
