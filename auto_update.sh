#!/bin/bash

# Auto-commit and push script for bagi repository
# Usage: ./auto_update.sh "Your commit message"

cd /workspaces/bagi

# Check if there are any changes
if [[ -n $(git status --porcelain) ]]; then
    echo "🔍 Changes detected, updating repository..."
    
    # Add all changes
    git add .
    
    # Use provided commit message or default
    if [ -z "$1" ]; then
        COMMIT_MSG="🔄 Auto-update: $(date '+%Y-%m-%d %H:%M:%S')"
    else
        COMMIT_MSG="$1"
    fi
    
    # Commit changes
    git commit -m "$COMMIT_MSG"
    
    # Push to repository
    git push origin main
    
    echo "✅ Repository updated successfully!"
    echo "📝 Commit message: $COMMIT_MSG"
else
    echo "ℹ️ No changes detected."
fi
