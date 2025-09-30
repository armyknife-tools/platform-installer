#!/usr/bin/env bash
# Core functions for ArmyknifeLabs bash libraries

# Version info
ARMYKNIFE_BASHLIB_VERSION="1.0.0"

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Logging functions
ak_log() { echo -e "${BLUE}[INFO]${NC} $@"; }
ak_info() { echo -e "${BLUE}[INFO]${NC} $@"; }  # Alias for ak_log
ak_success() { echo -e "${GREEN}[SUCCESS]${NC} $@"; }
ak_error() { echo -e "${RED}[ERROR]${NC} $@" >&2; }
ak_warning() { echo -e "${YELLOW}[WARNING]${NC} $@"; }
ak_debug() { [ "${DEBUG:-0}" = "1" ] && echo -e "${CYAN}[DEBUG]${NC} $@"; }

# Check if command exists
ak_command_exists() {
    command -v "$1" &> /dev/null
}

# Retry command with exponential backoff
ak_retry() {
    local retries=${1:-3}
    local delay=${2:-1}
    shift 2
    local count=0
    until "$@"; do
        exit=$?
        count=$((count + 1))
        if [ $count -lt $retries ]; then
            ak_warning "Command failed. Attempt $count/$retries. Retrying in ${delay}s..."
            sleep $delay
            delay=$((delay * 2))
        else
            ak_error "Command failed after $retries attempts"
            return $exit
        fi
    done
    return 0
}

# Confirmation prompt
ak_confirm() {
    local prompt="${1:-Are you sure?} [y/N]: "
    read -p "$prompt" -n 1 -r
    echo
    case $REPLY in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Get current timestamp
ak_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Check if running in Docker
ak_is_docker() {
    [ -f /.dockerenv ] || [ -n "${DOCKER_CONTAINER:-}" ]
}

# Check if running in WSL
ak_is_wsl() {
    [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null
}

# Export all core functions
export -f ak_log ak_info ak_success ak_error ak_warning ak_debug
export -f ak_command_exists ak_retry ak_confirm ak_timestamp
export -f ak_is_docker ak_is_wsl