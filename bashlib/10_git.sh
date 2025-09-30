#!/usr/bin/env bash
# Git functions for ArmyknifeLabs

# Guard to prevent double sourcing
if [ -z "${ARMYKNIFE_GIT_LOADED}" ]; then
export ARMYKNIFE_GIT_LOADED=1

# Unalias conflicting aliases from oh-my-bash or other plugins
unalias gst glg gcm 2>/dev/null || true

# Git status with formatting
function gst {
    git status --short --branch "${@}"
}

# Interactive git add
gia() {
    git add -i "${@}"
}

# Git log with graph
function glg {
    git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit "${@}"
}

# Quick commit with message
function gcm {
    local message="$1"
    if [ -z "$message" ]; then
        ak_error "Commit message required"
        return 1
    fi
    git commit -m "$message"
}

# Create and checkout new branch
gnb() {
    local branch="$1"
    if [ -z "$branch" ]; then
        ak_error "Branch name required"
        return 1
    fi
    git checkout -b "$branch"
}

# Push current branch to origin
gpush() {
    local branch=$(git branch --show-current)
    git push -u origin "$branch" "${@}"
}

# Pull with rebase
gpull() {
    git pull --rebase "${@}"
}

# Interactive rebase
grebase() {
    local commits=${1:-3}
    git rebase -i HEAD~$commits
}

# Stash with message
gstash() {
    local message="$1"
    if [ -z "$message" ]; then
        git stash
    else
        git stash push -m "$message"
    fi
}

# Find commits by message
gfind() {
    local pattern="$1"
    git log --grep="$pattern" --oneline
}

# Git cleanup - remove merged branches
gcleanup() {
    ak_log "Cleaning up merged branches..."
    git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 git branch -d
}

# Show git aliases
galias() {
    git config --get-regexp '^alias\.' | sed 's/alias\.\([^ ]*\) \(.*\)/\1\t=> \2/' | sort
}

# Export functions
export -f gst gia glg gcm gnb gpush gpull grebase gstash gfind gcleanup galias

fi # End of guard