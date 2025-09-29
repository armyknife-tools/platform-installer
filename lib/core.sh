#!/usr/bin/env bash
#
# ArmyknifeLabs Platform - Core Library Functions
# lib/core.sh
#
# Core utility functions used across all ArmyknifeLabs components
# These functions provide OS detection, logging, error handling, and common utilities
#
# Usage:
#   source ~/.armyknife/lib/core.sh
#   ak_detect_os
#   ak_log "INFO" "Installation started"
#

# Prevent multiple sourcing
if [ -n "${AK_CORE_LOADED:-}" ]; then
    return 0
fi
export AK_CORE_LOADED=1

# ArmyknifeLabs configuration
export ARMYKNIFE_VERSION="${ARMYKNIFE_VERSION:-1.0.0}"
export ARMYKNIFE_DIR="${ARMYKNIFE_DIR:-$HOME/.armyknife}"
export ARMYKNIFE_LOG_DIR="${ARMYKNIFE_LOG_DIR:-$ARMYKNIFE_DIR/logs}"
export ARMYKNIFE_CONFIG_DIR="${ARMYKNIFE_CONFIG_DIR:-$ARMYKNIFE_DIR/config}"
export ARMYKNIFE_BIN_DIR="${ARMYKNIFE_BIN_DIR:-$ARMYKNIFE_DIR/bin}"
export ARMYKNIFE_LIB_DIR="${ARMYKNIFE_LIB_DIR:-$ARMYKNIFE_DIR/lib}"
export ARMYKNIFE_BACKUP_DIR="${ARMYKNIFE_BACKUP_DIR:-$ARMYKNIFE_DIR/backups}"

# Colors for output
export AK_RED='\033[0;31m'
export AK_GREEN='\033[0;32m'
export AK_YELLOW='\033[1;33m'
export AK_BLUE='\033[0;34m'
export AK_PURPLE='\033[0;35m'
export AK_CYAN='\033[0;36m'
export AK_WHITE='\033[1;37m'
export AK_NC='\033[0m' # No Color

# OS detection variables
export AK_OS_TYPE="unknown"
export AK_OS_VERSION="unknown"
export AK_OS_ARCH="$(uname -m)"
export AK_OS_KERNEL="$(uname -s)"
export AK_PACKAGE_MANAGER="unknown"
export AK_IS_MACOS="false"
export AK_IS_LINUX="false"
export AK_IS_WSL="false"
export AK_IS_DOCKER="false"

# Logging configuration
export AK_LOG_LEVEL="${AK_LOG_LEVEL:-INFO}"
export AK_LOG_FILE="${AK_LOG_FILE:-$ARMYKNIFE_LOG_DIR/armyknife-$(date +%Y%m%d).log}"

# Create required directories
mkdir -p "$ARMYKNIFE_LOG_DIR" "$ARMYKNIFE_CONFIG_DIR" "$ARMYKNIFE_BIN_DIR" "$ARMYKNIFE_BACKUP_DIR" 2>/dev/null

# ==============================================================================
# OS Detection Functions
# ==============================================================================

# Detect operating system type and version
# Usage: ak_detect_os
# Sets: AK_OS_TYPE, AK_OS_VERSION, AK_PACKAGE_MANAGER, etc.
ak_detect_os() {
    local os_type="unknown"
    local os_version="unknown"
    local package_manager="unknown"

    # Detect kernel type
    case "$(uname -s)" in
        Linux*)
            AK_IS_LINUX="true"
            AK_OS_KERNEL="Linux"

            # Check if running in WSL
            if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ] || grep -qi microsoft /proc/version 2>/dev/null; then
                AK_IS_WSL="true"
            fi

            # Check if running in Docker
            if [ -f /.dockerenv ] || [ -n "${DOCKER_CONTAINER:-}" ]; then
                AK_IS_DOCKER="true"
            fi

            # Detect Linux distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                os_type="$ID"
                os_version="$VERSION_ID"

                case "$ID" in
                    ubuntu|debian|linuxmint)
                        package_manager="apt"
                        # Linux Mint is Ubuntu-based
                        if [ "$ID" = "linuxmint" ]; then
                            ak_log "DEBUG" "Detected Linux Mint - using Ubuntu compatibility"
                        fi
                        ;;
                    fedora|rhel|almalinux|rocky|centos)
                        package_manager="dnf"
                        # Fallback to yum for older systems
                        if ! command -v dnf &>/dev/null && command -v yum &>/dev/null; then
                            package_manager="yum"
                        fi
                        ;;
                    arch|manjaro)
                        package_manager="pacman"
                        ;;
                    opensuse*)
                        package_manager="zypper"
                        ;;
                    alpine)
                        package_manager="apk"
                        ;;
                    *)
                        package_manager="unknown"
                        ;;
                esac
            fi
            ;;

        Darwin*)
            AK_IS_MACOS="true"
            AK_OS_KERNEL="Darwin"
            os_type="macos"
            os_version="$(sw_vers -productVersion)"
            package_manager="brew"

            # Detect Apple Silicon vs Intel
            if [ "$AK_OS_ARCH" = "arm64" ]; then
                export AK_MACOS_ARCH="arm64"
                export AK_HOMEBREW_PREFIX="/opt/homebrew"
            else
                export AK_MACOS_ARCH="x86_64"
                export AK_HOMEBREW_PREFIX="/usr/local"
            fi
            ;;

        MINGW*|CYGWIN*|MSYS*)
            os_type="windows"
            os_version="$(uname -r)"
            package_manager="none"
            ;;

        *)
            os_type="unknown"
            os_version="unknown"
            package_manager="unknown"
            ;;
    esac

    # Export detected values
    export AK_OS_TYPE="$os_type"
    export AK_OS_VERSION="$os_version"
    export AK_PACKAGE_MANAGER="$package_manager"

    # Set sudo command based on OS
    if [ "$AK_IS_MACOS" = "true" ] || [ "$AK_IS_DOCKER" = "true" ] || [ "$UID" = "0" ]; then
        export AK_SUDO=""
    else
        export AK_SUDO="sudo"
    fi

    ak_log "DEBUG" "OS Detection: $AK_OS_TYPE $AK_OS_VERSION ($AK_OS_ARCH) - Package Manager: $AK_PACKAGE_MANAGER"
}

# Get human-readable OS description
# Usage: os_desc=$(ak_get_os_description)
ak_get_os_description() {
    local desc=""

    case "$AK_OS_TYPE" in
        ubuntu)
            desc="Ubuntu $AK_OS_VERSION"
            ;;
        debian)
            desc="Debian $AK_OS_VERSION"
            ;;
        fedora)
            desc="Fedora $AK_OS_VERSION"
            ;;
        rhel)
            desc="Red Hat Enterprise Linux $AK_OS_VERSION"
            ;;
        macos)
            desc="macOS $AK_OS_VERSION"
            if [ "$AK_MACOS_ARCH" = "arm64" ]; then
                desc="$desc (Apple Silicon)"
            else
                desc="$desc (Intel)"
            fi
            ;;
        *)
            desc="$AK_OS_TYPE $AK_OS_VERSION"
            ;;
    esac

    [ "$AK_IS_WSL" = "true" ] && desc="$desc (WSL)"
    [ "$AK_IS_DOCKER" = "true" ] && desc="$desc (Docker)"

    echo "$desc"
}

# ==============================================================================
# Logging Functions
# ==============================================================================

# Log message with timestamp and level
# Usage: ak_log "LEVEL" "Message"
# Levels: DEBUG, INFO, WARNING, ERROR, SUCCESS
ak_log() {
    local level="${1:-INFO}"
    local message="$2"
    local timestamp="$(date +'%Y-%m-%d %H:%M:%S')"
    local color="$AK_NC"
    local symbol=""

    # Set color and symbol based on level
    case "$level" in
        DEBUG)
            [ "$AK_LOG_LEVEL" != "DEBUG" ] && return 0
            color="$AK_WHITE"
            symbol="🔍"
            ;;
        INFO)
            color="$AK_BLUE"
            symbol="ℹ"
            ;;
        WARNING)
            color="$AK_YELLOW"
            symbol="⚠"
            ;;
        ERROR)
            color="$AK_RED"
            symbol="✗"
            ;;
        SUCCESS)
            color="$AK_GREEN"
            symbol="✓"
            ;;
        *)
            color="$AK_NC"
            symbol="•"
            ;;
    esac

    # Log to file
    echo "[$timestamp] [$level] $message" >> "$AK_LOG_FILE"

    # Log to console (if not in quiet mode)
    if [ "${AK_QUIET:-false}" != "true" ]; then
        echo -e "${color}${symbol}${AK_NC} $message" >&2
    fi
}

# Shortcuts for common log levels
ak_info() { ak_log "INFO" "$1"; }
ak_success() { ak_log "SUCCESS" "$1"; }
ak_warning() { ak_log "WARNING" "$1"; }
ak_error() { ak_log "ERROR" "$1"; }
ak_debug() { ak_log "DEBUG" "$1"; }

# ==============================================================================
# Error Handling Functions
# ==============================================================================

# Display error and exit
# Usage: ak_die "Error message"
ak_die() {
    local message="${1:-Unknown error occurred}"
    local exit_code="${2:-1}"

    ak_error "$message"
    exit "$exit_code"
}

# Check last command status and exit on error
# Usage: command || ak_check_error "Failed to run command"
ak_check_error() {
    local exit_code=$?
    local message="${1:-Command failed}"

    if [ $exit_code -ne 0 ]; then
        ak_die "$message (exit code: $exit_code)" $exit_code
    fi
}

# Run command with error checking
# Usage: ak_run_command "command" "Error message"
ak_run_command() {
    local command="$1"
    local error_message="${2:-Command failed: $1}"

    ak_debug "Running: $command"
    eval "$command"
    ak_check_error "$error_message"
}

# ==============================================================================
# User Interaction Functions
# ==============================================================================

# Ask for user confirmation
# Usage: ak_confirm "Are you sure?" && echo "Proceeding..."
ak_confirm() {
    local message="${1:-Continue?}"
    local default="${2:-n}"

    # In non-interactive mode, use default
    if [ "${AK_NON_INTERACTIVE:-false}" = "true" ]; then
        [ "$default" = "y" ] && return 0 || return 1
    fi

    local prompt="$message"
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    echo -en "${AK_YELLOW}${prompt}${AK_NC}"
    read -r response

    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        [nN][oO]|[nN])
            return 1
            ;;
        "")
            [ "$default" = "y" ] && return 0 || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Prompt for user input
# Usage: value=$(ak_prompt "Enter your name" "Default Name")
ak_prompt() {
    local message="${1:-Enter value}"
    local default="${2:-}"

    # In non-interactive mode, use default
    if [ "${AK_NON_INTERACTIVE:-false}" = "true" ]; then
        echo "$default"
        return 0
    fi

    local prompt="$message"
    [ -n "$default" ] && prompt="$prompt [$default]"
    prompt="$prompt: "

    echo -en "${AK_CYAN}${prompt}${AK_NC}" >&2
    read -r response

    if [ -z "$response" ] && [ -n "$default" ]; then
        response="$default"
    fi

    echo "$response"
}

# ==============================================================================
# File and Directory Functions
# ==============================================================================

# Create backup of file with timestamp
# Usage: ak_backup_file "/path/to/file"
ak_backup_file() {
    local file="$1"

    if [ -f "$file" ]; then
        local backup_file="$ARMYKNIFE_BACKUP_DIR/$(basename "$file").backup-$(date +%s)"
        cp "$file" "$backup_file"
        ak_info "Backed up $file to $backup_file"
        echo "$backup_file"
    fi
}

# Create directory if it doesn't exist
# Usage: ak_ensure_dir "/path/to/directory"
ak_ensure_dir() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        ak_debug "Created directory: $dir"
    fi
}

# Add line to file if not already present
# Usage: ak_add_line_to_file "export PATH=..." "$HOME/.bashrc"
ak_add_line_to_file() {
    local line="$1"
    local file="$2"

    if ! grep -Fxq "$line" "$file" 2>/dev/null; then
        echo "$line" >> "$file"
        ak_debug "Added line to $file: $line"
        return 0
    else
        ak_debug "Line already exists in $file: $line"
        return 1
    fi
}

# ==============================================================================
# Command Execution Functions
# ==============================================================================

# Check if command exists
# Usage: ak_command_exists "git" || echo "Git not found"
ak_command_exists() {
    local command="$1"
    command -v "$command" &>/dev/null
}

# Run command with timeout
# Usage: ak_run_with_timeout 30 "long-running-command"
ak_run_with_timeout() {
    local timeout="$1"
    shift

    if ak_command_exists "timeout"; then
        timeout "$timeout" "$@"
    else
        "$@"
    fi
}

# Retry command multiple times
# Usage: ak_retry 3 "flaky-command"
ak_retry() {
    local max_attempts="${1:-3}"
    local delay="${2:-1}"
    shift 2

    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if "$@"; then
            return 0
        fi

        ak_warning "Attempt $attempt failed, retrying in ${delay}s..."
        sleep "$delay"
        attempt=$((attempt + 1))
    done

    ak_error "Failed after $max_attempts attempts"
    return 1
}

# ==============================================================================
# System Information Functions
# ==============================================================================

# Get available CPU cores
# Usage: cores=$(ak_get_cpu_cores)
ak_get_cpu_cores() {
    local cores=1

    if [ "$AK_IS_MACOS" = "true" ]; then
        cores=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
    elif [ "$AK_IS_LINUX" = "true" ]; then
        cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)
    fi

    echo "$cores"
}

# Get available memory in MB
# Usage: memory=$(ak_get_memory_mb)
ak_get_memory_mb() {
    local memory=1024

    if [ "$AK_IS_MACOS" = "true" ]; then
        memory=$(($(sysctl -n hw.memsize 2>/dev/null || echo 1073741824) / 1024 / 1024))
    elif [ "$AK_IS_LINUX" = "true" ]; then
        memory=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo 1024)
    fi

    echo "$memory"
}

# Check if running with root/admin privileges
# Usage: ak_is_root && echo "Running as root"
ak_is_root() {
    [ "$UID" = "0" ] || [ "$EUID" = "0" ]
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# Generate random string
# Usage: random=$(ak_random_string 16)
ak_random_string() {
    local length="${1:-16}"

    if ak_command_exists "openssl"; then
        openssl rand -hex "$length" | cut -c1-"$length"
    elif [ -r /dev/urandom ]; then
        tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
    else
        echo "random_$(date +%s)"
    fi
}

# Get timestamp
# Usage: ts=$(ak_timestamp)
ak_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

# Check if variable is set
# Usage: ak_is_set "$VAR" || echo "Variable not set"
ak_is_set() {
    [ -n "${1+x}" ]
}

# ==============================================================================
# Version Comparison Functions
# ==============================================================================

# Compare two version strings
# Usage: ak_version_compare "1.2.3" "1.2.4" && echo "First is older"
# Returns: 0 if v1 < v2, 1 if v1 > v2, 2 if v1 == v2
ak_version_compare() {
    local v1="$1"
    local v2="$2"

    if [ "$v1" = "$v2" ]; then
        return 2
    fi

    local sorted=$(printf '%s\n' "$v1" "$v2" | sort -V | head -n1)

    if [ "$sorted" = "$v1" ]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# Network Functions
# ==============================================================================

# Check internet connectivity
# Usage: ak_check_internet || echo "No internet"
ak_check_internet() {
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com")

    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &>/dev/null; then
            return 0
        fi
    done

    return 1
}

# Download file with retry
# Usage: ak_download "https://example.com/file" "/path/to/output"
ak_download() {
    local url="$1"
    local output="${2:-$(basename "$url")}"

    ak_info "Downloading: $url"

    if ak_command_exists "wget"; then
        ak_retry 3 2 wget -q -O "$output" "$url"
    elif ak_command_exists "curl"; then
        ak_retry 3 2 curl -fsSL -o "$output" "$url"
    else
        ak_error "Neither wget nor curl is available"
        return 1
    fi

    ak_success "Downloaded: $output"
}

# ==============================================================================
# Initialization
# ==============================================================================

# Auto-detect OS on sourcing
ak_detect_os

# Export all functions
export -f ak_detect_os ak_get_os_description
export -f ak_log ak_info ak_success ak_warning ak_error ak_debug
export -f ak_die ak_check_error ak_run_command
export -f ak_confirm ak_prompt
export -f ak_backup_file ak_ensure_dir ak_add_line_to_file
export -f ak_command_exists ak_run_with_timeout ak_retry
export -f ak_get_cpu_cores ak_get_memory_mb ak_is_root
export -f ak_random_string ak_timestamp ak_is_set
export -f ak_version_compare
export -f ak_check_internet ak_download

ak_debug "ArmyknifeLabs Core Library loaded (v$ARMYKNIFE_VERSION)"