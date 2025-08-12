# Git Aliases untuk update cepat
# Tambahkan ke ~/.bashrc atau ~/.zshrc

# Quick update dengan message default
alias gup='cd /workspaces/bagi && git add . && git commit -m "🔄 Quick update: $(date)" && git push origin main'

# Update dengan custom message
gitupdate() {
    cd /workspaces/bagi
    git add .
    git commit -m "$1"
    git push origin main
    echo "✅ Repository updated with message: $1"
}

# Quick status check
alias gst='cd /workspaces/bagi && git status'

# Quick file check
alias gfiles='cd /workspaces/bagi && git status --porcelain'

# Usage examples:
# gup                           # Quick update with timestamp
# gitupdate "Fix fishing bug"   # Update with custom message
# gst                          # Check status
# gfiles                       # Check changed files
