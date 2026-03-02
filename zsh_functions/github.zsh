# GitHub / Git setup for terminal
# Git aliases and optional identity reminder. gh (GitHub CLI) uses PATH from zshrc (Homebrew).

# Git aliases
alias g='git'
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gbr='git branch'
alias gci='git commit'
alias gcm='git commit -m'
alias gpl='git pull'
alias gps='git push'
alias gpsu='git push -u origin "$(git branch --show-current)"'
alias glg='git log --oneline -20'
alias gdf='git diff'
alias gdfc='git diff --cached'
alias gadd='git add'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gsw='git switch'
alias gres='git restore'
alias gresst='git restore --staged'

# One-time reminder if Git user identity is not set (quiet after first run)
if [[ -z "$GIT_CONFIG_CHECKED" ]]; then
  if ! git config --global user.name &>/dev/null || ! git config --global user.email &>/dev/null; then
    echo "Git: set identity with: git config --global user.name 'Your Name' && git config --global user.email 'you@example.com'"
  fi
  export GIT_CONFIG_CHECKED=1
fi
