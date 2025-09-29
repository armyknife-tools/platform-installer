#!/usr/bin/env bash
#
# ArmyknifeLabs Platform Installer
# https://github.com/armyknife-tools/platform-installer
#
# The Ultimate Software Development Workstation Setup System
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/armyknife-tools/platform-installer/main/install.sh | bash
#   wget -qO- https://raw.githubusercontent.com/armyknife-tools/platform-installer/main/install.sh | bash
#
# Advanced Usage:
#   curl -fsSL https://armyknife.dev/install.sh | bash -s -- --version v1.2.3
#   curl -fsSL https://armyknife.dev/install.sh | bash -s -- --profile minimal
#   curl -fsSL https://armyknife.dev/install.sh | bash -s -- --prefix /opt/armyknife
#   curl -fsSL https://armyknife.dev/install.sh | bash -s -- --yes --profile standard
#
# Environment Variables:
#   ARMYKNIFE_PROFILE      - Installation profile (minimal|standard|full|custom)
#   ARMYKNIFE_VERSION      - Version to install (default: latest)
#   ARMYKNIFE_INSTALL_DIR  - Installation directory (default: ~/armyknife-platform)
#   ARMYKNIFE_NON_INTERACTIVE - Skip all prompts (default: false)

set -e

# Configuration
ARMYKNIFE_REPO="${ARMYKNIFE_REPO:-armyknife-tools/platform-installer}"
INSTALL_DIR="${ARMYKNIFE_INSTALL_DIR:-$HOME/armyknife-platform}"
PROFILE="${ARMYKNIFE_PROFILE:-standard}"
VERSION="${ARMYKNIFE_VERSION:-latest}"
GITHUB_BASE_URL="https://github.com"
GITHUB_RAW_URL="https://raw.githubusercontent.com"
NON_INTERACTIVE="${ARMYKNIFE_NON_INTERACTIVE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Detect if stdout is a terminal
if [ -t 1 ]; then
    # Terminal supports colors
    USE_COLOR=true
else
    # No color support (piped output)
    USE_COLOR=false
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    PURPLE=""
    CYAN=""
    NC=""
fi

# Logging functions
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Error handler
error_handler() {
    local line_no=$1
    log_error "Installation failed at line $line_no"
    log_error "Please check the logs and try again"
    log_error "For help, visit: ${GITHUB_BASE_URL}/${ARMYKNIFE_REPO}/issues"
    exit 1
}

# Set error trap
trap 'error_handler $LINENO' ERR

# Banner display
print_banner() {
    if [ "$USE_COLOR" = true ]; then
        echo ""
        echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║                                                           ║${NC}"
        echo -e "${PURPLE}║         ArmyknifeLabs Platform Installer v1.0             ║${NC}"
        echo -e "${PURPLE}║                                                           ║${NC}"
        echo -e "${PURPLE}║     The Ultimate Software Development Workstation         ║${NC}"
        echo -e "${PURPLE}║                                                           ║${NC}"
        echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
    else
        cat << "EOF"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         ArmyknifeLabs Platform Installer v1.0             ║
║                                                           ║
║     The Ultimate Software Development Workstation         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

EOF
    fi
}

# Detect operating system
detect_os() {
    log_info "Detecting operating system..."

    OS_TYPE="unknown"
    OS_VERSION="unknown"
    ARCH="$(uname -m)"

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            # Save our VERSION variable before sourcing os-release
            local SAVED_VERSION="$VERSION"
            . /etc/os-release
            OS_TYPE="$ID"
            OS_VERSION="$VERSION_ID"
            # Restore our VERSION variable
            VERSION="$SAVED_VERSION"
        fi
        # Check for WSL
        if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ] || grep -qi microsoft /proc/version 2>/dev/null; then
            log_info "Windows Subsystem for Linux detected"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        OS_VERSION="$(sw_vers -productVersion)"
        # Check for Apple Silicon
        if [ "$ARCH" = "arm64" ]; then
            log_info "Apple Silicon Mac detected"
        else
            log_info "Intel Mac detected"
        fi
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi

    log_info "Detected: $OS_TYPE $OS_VERSION ($ARCH)"

    # Validate supported OS
    case "$OS_TYPE" in
        ubuntu|debian|linuxmint|fedora|rhel|almalinux|rocky|macos)
            log_success "Operating system is supported"
            ;;
        *)
            log_error "Operating system '$OS_TYPE' is not yet supported"
            log_error "Supported: Ubuntu, Debian, Linux Mint, Fedora, RHEL, AlmaLinux, Rocky, macOS"
            exit 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing_deps=()

    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    # Check for make
    if ! command -v make &> /dev/null; then
        missing_deps+=("make")
    fi

    # Check for curl or wget
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_deps+=("curl or wget")
    fi

    # If prerequisites are missing, try to install them
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_warning "Missing prerequisites: ${missing_deps[*]}"
        log_info "Attempting to install missing prerequisites..."

        # Determine package manager and install
        if [ "$OS_TYPE" = "ubuntu" ] || [ "$OS_TYPE" = "debian" ]; then
            sudo apt update
            sudo apt install -y git make curl
        elif [ "$OS_TYPE" = "fedora" ] || [[ "$OS_TYPE" =~ ^(rhel|almalinux|rocky)$ ]]; then
            sudo dnf install -y git make curl
        elif [ "$OS_TYPE" = "macos" ]; then
            # Check for Homebrew
            if ! command -v brew &> /dev/null; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                # Add Homebrew to PATH for current session
                if [ -f /opt/homebrew/bin/brew ]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [ -f /usr/local/bin/brew ]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
            fi
            brew install git make curl
        else
            log_error "Unable to automatically install prerequisites on $OS_TYPE"
            log_error "Please install: ${missing_deps[*]}"
            exit 1
        fi
    fi

    log_success "Prerequisites check passed"
}

# Clone or update repository
clone_repository() {
    log_info "Setting up ArmyknifeLabs Platform..."

    # Check if installation directory exists
    if [ -d "$INSTALL_DIR" ]; then
        if [ "$NON_INTERACTIVE" = "false" ]; then
            log_warning "Installation directory already exists: $INSTALL_DIR"
            read -p "$(echo -e "${YELLOW}Remove and reinstall? (y/N): ${NC}")" -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_info "Removing existing installation..."
                rm -rf "$INSTALL_DIR"
            else
                log_info "Using existing installation..."
                cd "$INSTALL_DIR"

                # Try to update if it's a git repo
                if [ -d .git ]; then
                    log_info "Updating existing repository..."
                    git fetch origin
                    if [ "$VERSION" = "latest" ]; then
                        git pull origin main || git pull origin master
                    else
                        git checkout "$VERSION"
                    fi
                fi
                return 0
            fi
        else
            log_info "Removing existing installation..."
            rm -rf "$INSTALL_DIR"
        fi
    fi

    # Clone repository
    log_info "Cloning ArmyknifeLabs Platform repository..."

    if [ "$VERSION" = "latest" ]; then
        git clone --depth 1 "${GITHUB_BASE_URL}/${ARMYKNIFE_REPO}.git" "$INSTALL_DIR"
    else
        git clone --depth 1 --branch "$VERSION" "${GITHUB_BASE_URL}/${ARMYKNIFE_REPO}.git" "$INSTALL_DIR"
    fi

    if [ $? -ne 0 ]; then
        log_error "Failed to clone repository"
        exit 1
    fi

    log_success "Repository cloned successfully"
}

# Validate installation profile
validate_profile() {
    case "$PROFILE" in
        minimal|standard|full|custom)
            log_info "Installation profile: $PROFILE"
            ;;
        *)
            log_error "Invalid profile: $PROFILE"
            log_error "Valid profiles: minimal, standard, full, custom"
            exit 1
            ;;
    esac
}

# Run installation
run_installation() {
    log_info "Starting installation with profile: $PROFILE"

    # Change to installation directory
    cd "$INSTALL_DIR"

    # Make scripts executable
    find scripts -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    chmod +x install.sh 2>/dev/null || true

    # Export environment variables for make
    export ARMYKNIFE_NON_INTERACTIVE="$NON_INTERACTIVE"
    export ARMYKNIFE_PROFILE="$PROFILE"

    # Show what will be installed
    case "$PROFILE" in
        minimal)
            log_info "Installing: Base system + Shell configuration"
            log_info "Estimated time: ~15 minutes"
            ;;
        standard)
            log_info "Installing: Base + Shell + Languages + Developer tools + Containers"
            log_info "Estimated time: ~45 minutes"
            ;;
        full)
            log_info "Installing: Everything including VMs and all cloud tools"
            log_info "Estimated time: ~90 minutes"
            ;;
        custom)
            log_info "Launching interactive component selector..."
            ;;
    esac

    # Confirm installation (unless non-interactive)
    if [ "$NON_INTERACTIVE" = "false" ] && [ "$PROFILE" != "custom" ]; then
        read -p "$(echo -e "${CYAN}Proceed with installation? (Y/n): ${NC}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [ -n "$REPLY" ]; then
            log_warning "Installation cancelled by user"
            exit 0
        fi
    fi

    # Run make with selected profile
    log_info "Running installation..."
    make "$PROFILE"

    if [ $? -ne 0 ]; then
        log_error "Installation failed"
        log_error "Check logs at: ~/.armyknife/logs/"
        exit 1
    fi

    log_success "Installation completed successfully!"
}

# Post-installation message
post_install_message() {
    echo ""
    echo -e "${GREEN}🎉 ArmyknifeLabs Platform has been installed successfully!${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "📝 Next Steps:"
    echo ""
    echo "  1. Restart your shell or run:"
    echo "     ${CYAN}source ~/.bashrc${NC}  (Linux/WSL)"
    echo "     ${CYAN}source ~/.zshrc${NC}   (macOS)"
    echo ""
    echo "  2. Verify installation:"
    echo "     ${CYAN}make -C $INSTALL_DIR verify${NC}"
    echo ""
    echo "  3. View available commands:"
    echo "     ${CYAN}make -C $INSTALL_DIR help${NC}"
    echo ""
    echo "🚀 Quick Commands:"
    echo ""
    echo "  ${CYAN}armyknife help${NC}    - Show all commands"
    echo "  ${CYAN}ak update${NC}         - Update all components"
    echo "  ${CYAN}ak doctor${NC}         - Diagnose issues"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "📚 Documentation: ${GITHUB_BASE_URL}/${ARMYKNIFE_REPO}"
    echo "🐛 Issues: ${GITHUB_BASE_URL}/${ARMYKNIFE_REPO}/issues"
    echo "⭐ Star us: ${GITHUB_BASE_URL}/${ARMYKNIFE_REPO}"
    echo ""
    echo "Thank you for choosing ArmyknifeLabs Platform!"
    echo ""
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version|-v)
                VERSION="$2"
                shift 2
                ;;
            --profile|-p)
                PROFILE="$2"
                shift 2
                ;;
            --prefix|--install-dir|-d)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --yes|-y|--non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            --repo|-r)
                ARMYKNIFE_REPO="$2"
                shift 2
                ;;
            --help|-h)
                cat << HELP
ArmyknifeLabs Platform Installer

Usage:
  install.sh [OPTIONS]

Options:
  --version, -v VERSION       Install specific version (default: latest)
  --profile, -p PROFILE       Installation profile (default: standard)
                             Options: minimal, standard, full, custom
  --prefix, -d DIR           Installation directory (default: ~/armyknife-platform)
  --yes, -y                  Non-interactive mode (accept all defaults)
  --repo, -r REPO           GitHub repository (default: armyknife-tools/platform-installer)
  --help, -h                Show this help message

Examples:
  # Standard installation (recommended)
  ./install.sh

  # Minimal installation
  ./install.sh --profile minimal

  # Full installation to custom directory
  ./install.sh --profile full --prefix /opt/armyknife

  # Non-interactive installation
  ./install.sh --yes --profile standard

  # Install specific version
  ./install.sh --version v1.2.3

Environment Variables:
  ARMYKNIFE_PROFILE         Installation profile
  ARMYKNIFE_VERSION         Version to install
  ARMYKNIFE_INSTALL_DIR     Installation directory
  ARMYKNIFE_NON_INTERACTIVE Skip all prompts

For more information, visit:
  ${GITHUB_BASE_URL}/${ARMYKNIFE_REPO}

HELP
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                log_error "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Main installation flow
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Show banner
    print_banner

    # Detect OS
    detect_os

    # Check and install prerequisites
    check_prerequisites

    # Validate profile
    validate_profile

    # Clone repository
    clone_repository

    # Run installation
    run_installation

    # Show post-installation message
    post_install_message
}

# Run main function if script is executed directly or piped
# When piped through curl | bash, BASH_SOURCE might be empty
if [ "${BASH_SOURCE[0]}" = "${0}" ] || [ -z "${BASH_SOURCE[0]}" ]; then
    main "$@"
fi