#!/usr/bin/env bash
#
# ArmyknifeLabs Platform - Doctor (Diagnostic & Repair Tool)
# scripts/doctor.sh
#
# Diagnoses installation issues and provides automated fixes
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source libraries
source "$PROJECT_DIR/lib/core.sh" 2>/dev/null || source "$HOME/.armyknife/lib/core.sh" 2>/dev/null || true
source "$PROJECT_DIR/lib/ui.sh" 2>/dev/null || source "$HOME/.armyknife/lib/ui.sh" 2>/dev/null || true

# Doctor configuration
DOCTOR_LOG="$ARMYKNIFE_LOG_DIR/doctor-$(date +%Y%m%d-%H%M%S).log"
AUTO_FIX="${AUTO_FIX:-false}"
ISSUES_FOUND=0
ISSUES_FIXED=0
ISSUES_MANUAL=0

# Common issues database
declare -A ISSUE_FIXES=(
    ["PATH_MISSING"]="add_to_path"
    ["SHELL_INTEGRATION"]="fix_shell_integration"
    ["DOCKER_PERMISSION"]="fix_docker_permission"
    ["GIT_CONFIG"]="fix_git_config"
    ["MISSING_DIRECTORY"]="create_directories"
    ["BROKEN_SYMLINK"]="fix_symlinks"
    ["OUTDATED_PACKAGE"]="update_package"
    ["MISSING_DEPENDENCY"]="install_dependency"
    ["PERMISSION_DENIED"]="fix_permissions"
)

# Start doctor session
start_doctor() {
    ui_clear

    if [ "$HAVE_GUM" = true ]; then
        cat << 'EOF' | gum style --foreground 212 --align center
    ____             __
   / __ \____  _____/ /_____  _____
  / / / / __ \/ ___/ __/ __ \/ ___/
 / /_/ / /_/ / /__/ /_/ /_/ / /
/_____/\____/\___/\__/\____/_/

ArmyknifeLabs Platform Doctor v1.0
EOF
    else
        ui_banner "ArmyknifeLabs Platform Doctor" "Diagnostic & Repair Tool"
    fi

    echo
    ui_info "Starting system diagnosis..."
    ui_info "This may take a few minutes..."
    echo

    echo "[$(date)] ArmyknifeLabs Doctor Session Started" > "$DOCTOR_LOG"
    echo "OS: $(ak_get_os_description)" >> "$DOCTOR_LOG"
    echo "" >> "$DOCTOR_LOG"

    if [ "$AUTO_FIX" = "true" ]; then
        ui_warning "Auto-fix mode enabled - will attempt to fix issues automatically"
    else
        ui_info "Running in diagnostic mode only (use --fix to enable auto-repair)"
    fi
    echo
}

# Diagnose PATH issues
diagnose_path() {
    ui_header "PATH Configuration"
    echo

    local path_ok=true

    # Check if ArmyknifeLabs bin is in PATH
    if [[ ":$PATH:" != *":$ARMYKNIFE_BIN_DIR:"* ]]; then
        ui_error "ArmyknifeLabs bin directory not in PATH"
        echo "Missing from PATH: $ARMYKNIFE_BIN_DIR" >> "$DOCTOR_LOG"
        ((ISSUES_FOUND++))
        path_ok=false

        if [ "$AUTO_FIX" = "true" ]; then
            fix_path_issue
        else
            ui_info "Fix: Add to your shell RC file:"
            ui_code "bash" 'export PATH="$HOME/.armyknife/bin:$PATH"'
        fi
    else
        ui_success "ArmyknifeLabs bin directory in PATH"
    fi

    # Check for common tool paths
    local tool_paths=(
        "$HOME/.local/bin"
        "$HOME/.cargo/bin"
        "$HOME/.pyenv/bin"
        "$HOME/.fnm"
        "/usr/local/bin"
    )

    for tool_path in "${tool_paths[@]}"; do
        if [ -d "$tool_path" ]; then
            if [[ ":$PATH:" != *":$tool_path:"* ]]; then
                ui_warning "$tool_path exists but not in PATH"
                ((ISSUES_FOUND++))
            fi
        fi
    done

    echo
    return $([ "$path_ok" = "true" ] && echo 0 || echo 1)
}

# Fix PATH issues
fix_path_issue() {
    ui_progress "Adding ArmyknifeLabs to PATH" "sleep 1"

    local shell_rc=""
    if [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    fi

    if [ -f "$shell_rc" ]; then
        ak_backup_file "$shell_rc"
        echo 'export PATH="$HOME/.armyknife/bin:$PATH"' >> "$shell_rc"
        ui_success "Added ArmyknifeLabs to PATH in $shell_rc"
        ((ISSUES_FIXED++))
    fi
}

# Diagnose shell integration
diagnose_shell_integration() {
    ui_header "Shell Integration"
    echo

    local shell_rc=""
    local shell_type=""

    if [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
        shell_type="bash"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
        shell_type="zsh"
    fi

    # Check if shell RC exists
    if [ ! -f "$shell_rc" ]; then
        ui_error "Shell RC file not found: $shell_rc"
        ((ISSUES_FOUND++))

        if [ "$AUTO_FIX" = "true" ]; then
            touch "$shell_rc"
            ui_success "Created $shell_rc"
            ((ISSUES_FIXED++))
        fi
    fi

    # Check for ArmyknifeLabs integration
    if [ -f "$shell_rc" ]; then
        if ! grep -q "armyknife" "$shell_rc" 2>/dev/null; then
            ui_error "ArmyknifeLabs not integrated in $shell_rc"
            ((ISSUES_FOUND++))

            if [ "$AUTO_FIX" = "true" ]; then
                fix_shell_integration "$shell_rc"
            else
                ui_info "Fix: Add to $shell_rc:"
                ui_code "bash" 'source ~/.armyknife/lib/core.sh
source ~/.armyknife/lib/ui.sh
alias armyknife="make -C ~/armyknife-platform"
alias ak="armyknife"'
            fi
        else
            ui_success "ArmyknifeLabs integrated in shell"
        fi
    fi

    # Check Oh-My-Bash/Zsh
    if [ "$shell_type" = "bash" ] && [ ! -d "$HOME/.oh-my-bash" ]; then
        ui_warning "Oh-My-Bash not installed"
        ((ISSUES_FOUND++))
        ui_info "Install with: make -f makefiles/Makefile.Shell.mk install-oh-my-bash"
    elif [ "$shell_type" = "zsh" ] && [ ! -d "$HOME/.oh-my-zsh" ]; then
        ui_warning "Oh-My-Zsh not installed"
        ((ISSUES_FOUND++))
        ui_info "Install with: make -f makefiles/Makefile.Shell.mk install-oh-my-zsh"
    fi

    echo
}

# Fix shell integration
fix_shell_integration() {
    local shell_rc="$1"

    ui_progress "Fixing shell integration" "sleep 1"

    cat >> "$shell_rc" << 'EOF'

# ArmyknifeLabs Platform Integration
if [ -d "$HOME/.armyknife/lib" ]; then
    for lib in "$HOME/.armyknife/lib"/*.sh; do
        [ -f "$lib" ] && source "$lib"
    done
fi

export PATH="$HOME/.armyknife/bin:$PATH"
alias armyknife="make -C ~/armyknife-platform"
alias ak="armyknife"
EOF

    ui_success "Fixed shell integration"
    ((ISSUES_FIXED++))
}

# Diagnose Docker issues
diagnose_docker() {
    ui_header "Docker Configuration"
    echo

    if ! command -v docker &> /dev/null; then
        ui_warning "Docker not installed"
        echo
        return
    fi

    # Check Docker daemon
    if ! docker info &> /dev/null; then
        ui_error "Docker daemon not accessible"
        ((ISSUES_FOUND++))

        # Check if it's a permission issue
        if [ "$AK_IS_LINUX" = "true" ]; then
            if ! groups | grep -q docker; then
                ui_error "User not in docker group"

                if [ "$AUTO_FIX" = "true" ]; then
                    fix_docker_permission
                else
                    ui_info "Fix: Add user to docker group:"
                    ui_code "bash" "sudo usermod -aG docker $USER"
                    ui_info "Then log out and back in"
                fi
            fi
        elif [ "$AK_IS_MACOS" = "true" ]; then
            ui_info "Ensure Docker Desktop is running"
        fi
    else
        ui_success "Docker daemon is accessible"

        # Check Docker Compose
        if command -v docker-compose &> /dev/null; then
            ui_success "Docker Compose v1 found"
        fi

        if docker compose version &> /dev/null; then
            ui_success "Docker Compose v2 found"
        elif ! command -v docker-compose &> /dev/null; then
            ui_warning "Docker Compose not found"
            ((ISSUES_FOUND++))
        fi
    fi

    echo
}

# Fix Docker permission
fix_docker_permission() {
    ui_progress "Adding user to docker group" "sleep 1"

    if [ "$AK_IS_LINUX" = "true" ]; then
        $AK_SUDO usermod -aG docker "$USER"
        ui_success "Added $USER to docker group"
        ui_warning "You must log out and back in for changes to take effect"
        ((ISSUES_FIXED++))
    fi
}

# Diagnose Git configuration
diagnose_git() {
    ui_header "Git Configuration"
    echo

    if ! command -v git &> /dev/null; then
        ui_error "Git not installed"
        ((ISSUES_FOUND++))
        echo
        return
    fi

    # Check git user configuration
    local git_user=$(git config --global user.name 2>/dev/null || echo "")
    local git_email=$(git config --global user.email 2>/dev/null || echo "")

    if [ -z "$git_user" ] || [ -z "$git_email" ]; then
        ui_error "Git user configuration incomplete"
        ((ISSUES_FOUND++))

        if [ "$AUTO_FIX" = "true" ]; then
            ui_info "Please provide Git configuration:"
            git_user=$(ui_input "Git username" "")
            git_email=$(ui_input "Git email" "")

            if [ -n "$git_user" ] && [ -n "$git_email" ]; then
                git config --global user.name "$git_user"
                git config --global user.email "$git_email"
                ui_success "Git configuration updated"
                ((ISSUES_FIXED++))
            fi
        else
            ui_info "Fix: Configure git user:"
            ui_code "bash" 'git config --global user.name "Your Name"
git config --global user.email "you@example.com"'
        fi
    else
        ui_success "Git configured: $git_user <$git_email>"
    fi

    # Check for GitHub CLI authentication
    if command -v gh &> /dev/null; then
        if ! gh auth status &> /dev/null; then
            ui_warning "GitHub CLI not authenticated"
            ui_info "Fix: Run 'gh auth login'"
        else
            ui_success "GitHub CLI authenticated"
        fi
    fi

    echo
}

# Diagnose package managers
diagnose_package_managers() {
    ui_header "Package Managers"
    echo

    # Check system package manager
    case "$AK_PACKAGE_MANAGER" in
        apt)
            if ! $AK_SUDO apt update &> /dev/null; then
                ui_error "APT update failed"
                ((ISSUES_FOUND++))
            else
                ui_success "APT is working"
            fi
            ;;
        dnf)
            if ! $AK_SUDO dnf check-update &> /dev/null; then
                ui_warning "DNF check-update had issues (this might be normal)"
            else
                ui_success "DNF is working"
            fi
            ;;
        brew)
            if ! brew doctor &> /dev/null; then
                ui_warning "Homebrew has issues - run 'brew doctor'"
                ((ISSUES_FOUND++))
            else
                ui_success "Homebrew is healthy"
            fi
            ;;
    esac

    # Check language-specific package managers
    if command -v pip3 &> /dev/null; then
        local pip_version=$(pip3 --version 2>&1 | cut -d' ' -f2)
        ui_success "pip3: $pip_version"

        # Check if pip is outdated
        if command -v python3 &> /dev/null; then
            if python3 -m pip list --outdated 2>/dev/null | grep -q "^pip "; then
                ui_warning "pip is outdated"
                ui_info "Fix: python3 -m pip install --upgrade pip"
            fi
        fi
    fi

    if command -v npm &> /dev/null; then
        local npm_version=$(npm --version)
        ui_success "npm: $npm_version"
    fi

    echo
}

# Diagnose directory structure
diagnose_directories() {
    ui_header "Directory Structure"
    echo

    local dirs=(
        "$ARMYKNIFE_DIR"
        "$ARMYKNIFE_LIB_DIR"
        "$ARMYKNIFE_CONFIG_DIR"
        "$ARMYKNIFE_BIN_DIR"
        "$ARMYKNIFE_LOG_DIR"
        "$ARMYKNIFE_BACKUP_DIR"
    )

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            ui_error "Missing directory: $dir"
            ((ISSUES_FOUND++))

            if [ "$AUTO_FIX" = "true" ]; then
                mkdir -p "$dir"
                ui_success "Created $dir"
                ((ISSUES_FIXED++))
            fi
        else
            ui_success "Directory exists: $dir"
        fi
    done

    # Check permissions
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ] && [ ! -w "$dir" ]; then
            ui_error "No write permission: $dir"
            ((ISSUES_FOUND++))

            if [ "$AUTO_FIX" = "true" ]; then
                chmod u+w "$dir"
                ui_success "Fixed permissions for $dir"
                ((ISSUES_FIXED++))
            fi
        fi
    done

    echo
}

# Check for broken symlinks
diagnose_symlinks() {
    ui_header "Symbolic Links"
    echo

    local symlink_dirs=(
        "$HOME/.local/bin"
        "$ARMYKNIFE_BIN_DIR"
        "/usr/local/bin"
    )

    local broken_links=0

    for dir in "${symlink_dirs[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r -d '' link; do
                if [ ! -e "$link" ]; then
                    ui_error "Broken symlink: $link"
                    ((broken_links++))
                    ((ISSUES_FOUND++))

                    if [ "$AUTO_FIX" = "true" ]; then
                        rm "$link"
                        ui_success "Removed broken symlink"
                        ((ISSUES_FIXED++))
                    fi
                fi
            done < <(find "$dir" -type l -print0 2>/dev/null)
        fi
    done

    if [ $broken_links -eq 0 ]; then
        ui_success "No broken symlinks found"
    fi

    echo
}

# Diagnose network connectivity
diagnose_network() {
    ui_header "Network Connectivity"
    echo

    # Check internet connectivity
    if ak_check_internet; then
        ui_success "Internet connection is working"
    else
        ui_error "No internet connection detected"
        ((ISSUES_FOUND++))
        ((ISSUES_MANUAL++))
        ui_info "Please check your network connection"
    fi

    # Check access to common repositories
    local test_urls=(
        "https://github.com"
        "https://pypi.org"
        "https://registry.npmjs.org"
        "https://hub.docker.com"
    )

    for url in "${test_urls[@]}"; do
        if curl -fsS --connect-timeout 5 "$url" > /dev/null 2>&1; then
            ui_success "Can reach: $url"
        else
            ui_warning "Cannot reach: $url"
        fi
    done

    # Check DNS
    if host google.com &> /dev/null || nslookup google.com &> /dev/null; then
        ui_success "DNS resolution is working"
    else
        ui_error "DNS resolution issues detected"
        ((ISSUES_FOUND++))
    fi

    echo
}

# Check disk space
diagnose_disk_space() {
    ui_header "Disk Space"
    echo

    local min_space_gb=5
    local available_space=$(df -BG "$HOME" | tail -1 | awk '{print $4}' | sed 's/G//')

    if [ "$available_space" -lt "$min_space_gb" ]; then
        ui_error "Low disk space: ${available_space}GB available (minimum ${min_space_gb}GB recommended)"
        ((ISSUES_FOUND++))
        ((ISSUES_MANUAL++))
        ui_info "Free up disk space by:"
        ui_list \
            "Running 'docker system prune -a'" \
            "Clearing package manager cache" \
            "Removing old log files"
    else
        ui_success "Sufficient disk space: ${available_space}GB available"
    fi

    # Check inodes
    local available_inodes=$(df -i "$HOME" | tail -1 | awk '{print $4}')
    if [ "$available_inodes" -lt 10000 ]; then
        ui_warning "Low inode count: $available_inodes"
        ui_info "You may have too many small files"
    fi

    echo
}

# Generate recommendations
generate_recommendations() {
    ui_header "Recommendations"
    echo

    if [ $ISSUES_FOUND -eq 0 ]; then
        ui_success "No issues found! Your ArmyknifeLabs Platform is healthy."
        echo
        return
    fi

    ui_info "Found $ISSUES_FOUND issue(s)"

    if [ "$AUTO_FIX" = "false" ]; then
        echo
        ui_info "Run with --fix flag to attempt automatic repairs:"
        ui_code "bash" "$0 --fix"
    else
        echo
        ui_info "Fixed $ISSUES_FIXED issue(s) automatically"

        if [ $((ISSUES_FOUND - ISSUES_FIXED)) -gt 0 ]; then
            ui_warning "$((ISSUES_FOUND - ISSUES_FIXED)) issue(s) require manual intervention"
        fi
    fi

    if [ $ISSUES_MANUAL -gt 0 ]; then
        echo
        ui_warning "$ISSUES_MANUAL issue(s) require manual intervention"
        ui_info "Please review the recommendations above"
    fi

    echo
    ui_info "Full diagnostic log: $DOCTOR_LOG"
    echo
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix|--auto-fix|-f)
                AUTO_FIX=true
                shift
                ;;
            --help|-h)
                echo "ArmyknifeLabs Platform Doctor"
                echo ""
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --fix, -f    Attempt to automatically fix issues"
                echo "  --help, -h   Show this help message"
                echo ""
                exit 0
                ;;
            *)
                ui_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Main doctor flow
main() {
    parse_args "$@"

    start_doctor

    # Run all diagnostics
    diagnose_path
    diagnose_shell_integration
    diagnose_directories
    diagnose_symlinks
    diagnose_git
    diagnose_docker
    diagnose_package_managers
    diagnose_network
    diagnose_disk_space

    # Generate recommendations
    generate_recommendations

    # Return appropriate exit code
    if [ $((ISSUES_FOUND - ISSUES_FIXED)) -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"