#!/usr/bin/env bash
#
# ArmyknifeLabs Platform - Installation Verification
# scripts/verify-install.sh
#
# Verifies that all installed components are working correctly
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source libraries
source "$PROJECT_DIR/lib/core.sh" 2>/dev/null || source "$HOME/.armyknife/lib/core.sh" 2>/dev/null || true
source "$PROJECT_DIR/lib/ui.sh" 2>/dev/null || source "$HOME/.armyknife/lib/ui.sh" 2>/dev/null || true

# Verification results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
SKIPPED_CHECKS=0
VERIFICATION_LOG="$ARMYKNIFE_LOG_DIR/verify-$(date +%Y%m%d-%H%M%S).log"

# Component check lists
declare -a CORE_COMMANDS=(git make gcc curl wget)
declare -a BUILD_TOOLS=(cmake autoconf automake pkg-config)
declare -a PYTHON_TOOLS=(python3 pip3 pyenv uv)
declare -a NODE_TOOLS=(node npm fnm pnpm)
declare -a GO_TOOLS=(go gvm)
declare -a RUST_TOOLS=(rustc cargo rustup)
declare -a JAVA_TOOLS=(java javac mvn gradle)
declare -a SHELL_TOOLS=(fzf rg fd bat exa zoxide)
declare -a GIT_TOOLS=(gh hub gitleaks lazygit)
declare -a SECURITY_TOOLS=(gpg age pass)
declare -a CONTAINER_TOOLS=(docker docker-compose podman kubectl helm k9s)
declare -a VM_TOOLS=(VBoxManage vagrant packer)
declare -a CLOUD_TOOLS=(aws az gcloud linode-cli)
declare -a NETWORK_TOOLS=(tailscale)

# Start verification
start_verification() {
    ui_clear
    ui_banner "ArmyknifeLabs Platform Verification" "Checking installed components"
    echo
    ui_info "Starting verification process..."
    ui_info "Log file: $VERIFICATION_LOG"
    echo
    echo "[$(date)] ArmyknifeLabs Platform Verification Started" > "$VERIFICATION_LOG"
}

# Check command existence and version
check_command() {
    local cmd="$1"
    local name="${2:-$cmd}"
    local required="${3:-false}"

    ((TOTAL_CHECKS++))

    if command -v "$cmd" &> /dev/null; then
        local version=""
        case "$cmd" in
            python3|python)
                version=$($cmd --version 2>&1 | head -n1)
                ;;
            node|npm|pnpm)
                version=$($cmd --version 2>&1)
                ;;
            go)
                version=$($cmd version 2>&1)
                ;;
            rustc|cargo)
                version=$($cmd --version 2>&1 | head -n1)
                ;;
            java|javac)
                version=$($cmd -version 2>&1 | head -n1)
                ;;
            docker)
                version=$(docker version --format '{{.Client.Version}}' 2>&1 || docker --version)
                ;;
            *)
                version=$($cmd --version 2>&1 | head -n1 || echo "installed")
                ;;
        esac

        ui_success "$name: $version"
        echo "✓ $name: $version" >> "$VERIFICATION_LOG"
        ((PASSED_CHECKS++))
        return 0
    else
        if [ "$required" = "true" ]; then
            ui_error "$name: NOT FOUND (required)"
            echo "✗ $name: NOT FOUND (required)" >> "$VERIFICATION_LOG"
            ((FAILED_CHECKS++))
            return 1
        else
            ui_warning "$name: not installed (optional)"
            echo "⚠ $name: not installed (optional)" >> "$VERIFICATION_LOG"
            ((SKIPPED_CHECKS++))
            return 2
        fi
    fi
}

# Check directory existence
check_directory() {
    local dir="$1"
    local name="$2"

    ((TOTAL_CHECKS++))

    if [ -d "$dir" ]; then
        ui_success "$name directory exists: $dir"
        echo "✓ $name directory: $dir" >> "$VERIFICATION_LOG"
        ((PASSED_CHECKS++))
        return 0
    else
        ui_error "$name directory missing: $dir"
        echo "✗ $name directory missing: $dir" >> "$VERIFICATION_LOG"
        ((FAILED_CHECKS++))
        return 1
    fi
}

# Check file existence
check_file() {
    local file="$1"
    local name="$2"

    ((TOTAL_CHECKS++))

    if [ -f "$file" ]; then
        ui_success "$name file exists: $file"
        echo "✓ $name file: $file" >> "$VERIFICATION_LOG"
        ((PASSED_CHECKS++))
        return 0
    else
        ui_warning "$name file missing: $file"
        echo "⚠ $name file missing: $file" >> "$VERIFICATION_LOG"
        ((SKIPPED_CHECKS++))
        return 2
    fi
}

# Check environment variable
check_env_var() {
    local var="$1"
    local name="$2"

    ((TOTAL_CHECKS++))

    if [ -n "${!var}" ]; then
        ui_success "$name is set: $var=${!var}"
        echo "✓ $name: $var=${!var}" >> "$VERIFICATION_LOG"
        ((PASSED_CHECKS++))
        return 0
    else
        ui_warning "$name not set: $var"
        echo "⚠ $name not set: $var" >> "$VERIFICATION_LOG"
        ((SKIPPED_CHECKS++))
        return 2
    fi
}

# Verify core system
verify_core_system() {
    ui_header "Core System"
    echo

    # Check OS detection
    check_env_var "AK_OS_TYPE" "OS Type"
    check_env_var "AK_OS_VERSION" "OS Version"
    check_env_var "AK_PACKAGE_MANAGER" "Package Manager"

    # Check core commands
    for cmd in "${CORE_COMMANDS[@]}"; do
        check_command "$cmd" "$cmd" "true"
    done

    # Check build tools
    for tool in "${BUILD_TOOLS[@]}"; do
        check_command "$tool" "$tool" "false"
    done

    echo
}

# Verify ArmyknifeLabs structure
verify_armyknife_structure() {
    ui_header "ArmyknifeLabs Structure"
    echo

    check_directory "$ARMYKNIFE_DIR" "ArmyknifeLabs home"
    check_directory "$ARMYKNIFE_LIB_DIR" "Library"
    check_directory "$ARMYKNIFE_CONFIG_DIR" "Config"
    check_directory "$ARMYKNIFE_BIN_DIR" "Bin"
    check_directory "$ARMYKNIFE_LOG_DIR" "Logs"
    check_directory "$ARMYKNIFE_BACKUP_DIR" "Backups"

    check_file "$ARMYKNIFE_LIB_DIR/core.sh" "Core library"
    check_file "$ARMYKNIFE_LIB_DIR/ui.sh" "UI library"

    echo
}

# Verify shell configuration
verify_shell_config() {
    ui_header "Shell Configuration"
    echo

    # Check shell type
    local shell_rc=""
    if [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
        check_file "$shell_rc" "Bash RC"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
        check_file "$shell_rc" "Zsh RC"
    fi

    # Check Oh-My-Bash/Zsh
    if [ -d "$HOME/.oh-my-bash" ]; then
        ui_success "Oh-My-Bash is installed"
        ((PASSED_CHECKS++))
    elif [ -d "$HOME/.oh-my-zsh" ]; then
        ui_success "Oh-My-Zsh is installed"
        ((PASSED_CHECKS++))
    else
        ui_warning "Oh-My-Bash/Zsh not installed"
        ((SKIPPED_CHECKS++))
    fi

    # Check for ArmyknifeLabs integration in shell RC
    if [ -f "$shell_rc" ]; then
        if grep -q "armyknife" "$shell_rc" 2>/dev/null; then
            ui_success "ArmyknifeLabs integrated in shell RC"
            ((PASSED_CHECKS++))
        else
            ui_warning "ArmyknifeLabs not integrated in shell RC"
            ((SKIPPED_CHECKS++))
        fi
    fi

    echo
}

# Verify programming languages
verify_languages() {
    ui_header "Programming Languages"
    echo

    ui_subheader "Python"
    for tool in "${PYTHON_TOOLS[@]}"; do
        check_command "$tool"
    done

    ui_subheader "Node.js"
    for tool in "${NODE_TOOLS[@]}"; do
        check_command "$tool"
    done

    ui_subheader "Go"
    for tool in "${GO_TOOLS[@]}"; do
        check_command "$tool"
    done

    ui_subheader "Rust"
    for tool in "${RUST_TOOLS[@]}"; do
        check_command "$tool"
    done

    ui_subheader "Java"
    for tool in "${JAVA_TOOLS[@]}"; do
        check_command "$tool"
    done

    echo
}

# Verify shell tools
verify_shell_tools() {
    ui_header "Shell Enhancement Tools"
    echo

    for tool in "${SHELL_TOOLS[@]}"; do
        check_command "$tool"
    done

    # Check for special tools
    check_command "starship" "Starship prompt"
    check_command "direnv" "direnv"
    check_command "tmux" "tmux"
    check_command "zellij" "Zellij"

    echo
}

# Verify Git tools
verify_git_tools() {
    ui_header "Git & GitHub Tools"
    echo

    for tool in "${GIT_TOOLS[@]}"; do
        check_command "$tool"
    done

    # Check git configuration
    ((TOTAL_CHECKS++))
    local git_user=$(git config --global user.name 2>/dev/null || echo "")
    if [ -n "$git_user" ]; then
        ui_success "Git user configured: $git_user"
        ((PASSED_CHECKS++))
    else
        ui_warning "Git user not configured"
        ((SKIPPED_CHECKS++))
    fi

    echo
}

# Verify security tools
verify_security_tools() {
    ui_header "Security & Encryption Tools"
    echo

    for tool in "${SECURITY_TOOLS[@]}"; do
        check_command "$tool"
    done

    # Check for password managers
    check_command "lpass" "LastPass CLI"
    check_command "op" "1Password CLI"
    check_command "bw" "Bitwarden CLI"

    echo
}

# Verify container tools
verify_container_tools() {
    ui_header "Container & Kubernetes Tools"
    echo

    for tool in "${CONTAINER_TOOLS[@]}"; do
        check_command "$tool"
    done

    # Check Docker daemon
    if command -v docker &> /dev/null; then
        ((TOTAL_CHECKS++))
        if docker info &> /dev/null; then
            ui_success "Docker daemon is running"
            ((PASSED_CHECKS++))
        else
            ui_warning "Docker daemon not running or not accessible"
            ((SKIPPED_CHECKS++))
        fi
    fi

    echo
}

# Verify virtualization tools
verify_vm_tools() {
    ui_header "Virtualization Tools"
    echo

    for tool in "${VM_TOOLS[@]}"; do
        check_command "$tool"
    done

    # Check VirtualBox kernel modules
    if [ "$AK_IS_LINUX" = "true" ]; then
        ((TOTAL_CHECKS++))
        if lsmod | grep -q vboxdrv 2>/dev/null; then
            ui_success "VirtualBox kernel modules loaded"
            ((PASSED_CHECKS++))
        else
            ui_warning "VirtualBox kernel modules not loaded"
            ((SKIPPED_CHECKS++))
        fi
    fi

    echo
}

# Verify cloud tools
verify_cloud_tools() {
    ui_header "Cloud Provider Tools"
    echo

    for tool in "${CLOUD_TOOLS[@]}"; do
        check_command "$tool"
    done

    # Check Terraform and related
    check_command "terraform" "Terraform"
    check_command "terragrunt" "Terragrunt"
    check_command "pulumi" "Pulumi"

    echo
}

# Verify network tools
verify_network_tools() {
    ui_header "Network & Remote Management"
    echo

    for tool in "${NETWORK_TOOLS[@]}"; do
        check_command "$tool"
    done

    # Check Tailscale status
    if command -v tailscale &> /dev/null; then
        ((TOTAL_CHECKS++))
        if tailscale status &> /dev/null; then
            ui_success "Tailscale is configured"
            ((PASSED_CHECKS++))
        else
            ui_warning "Tailscale not configured or not running"
            ((SKIPPED_CHECKS++))
        fi
    fi

    echo
}

# Generate summary report
generate_summary() {
    ui_header "Verification Summary"
    echo

    local pass_rate=0
    if [ $TOTAL_CHECKS -gt 0 ]; then
        pass_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    fi

    ui_table "Status,Count,Percentage" \
        "Passed,$PASSED_CHECKS,$((PASSED_CHECKS * 100 / TOTAL_CHECKS))%" \
        "Failed,$FAILED_CHECKS,$((FAILED_CHECKS * 100 / TOTAL_CHECKS))%" \
        "Skipped,$SKIPPED_CHECKS,$((SKIPPED_CHECKS * 100 / TOTAL_CHECKS))%" \
        "Total,$TOTAL_CHECKS,100%"

    echo
    echo "Pass Rate: $pass_rate%" >> "$VERIFICATION_LOG"

    if [ $FAILED_CHECKS -eq 0 ]; then
        ui_success "All required components are installed and working!"
        echo
        ui_info "Some optional components were skipped. This is normal."
    elif [ $pass_rate -ge 80 ]; then
        ui_warning "Most components are working, but some issues were found."
        echo
        ui_info "Run 'make doctor' to diagnose and fix issues."
    else
        ui_error "Several components are missing or not working properly."
        echo
        ui_info "Run 'make doctor' for detailed diagnostics."
        ui_info "You may need to re-run the installation."
    fi

    echo
    ui_info "Full verification log: $VERIFICATION_LOG"
    echo
}

# Main verification flow
main() {
    start_verification

    # Run all verification checks
    verify_core_system
    verify_armyknife_structure
    verify_shell_config
    verify_languages
    verify_shell_tools
    verify_git_tools
    verify_security_tools
    verify_container_tools
    verify_vm_tools
    verify_cloud_tools
    verify_network_tools

    # Generate summary
    generate_summary

    # Return appropriate exit code
    if [ $FAILED_CHECKS -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"