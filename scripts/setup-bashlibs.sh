#!/usr/bin/env bash
# ArmyknifeLabs Platform Installer - Bash Libraries Setup Script
# This script creates comprehensive bash libraries for all installed tools

set -e

# Configuration
ARMYKNIFE_DIR="${ARMYKNIFE_DIR:-$HOME/.armyknife}"
BASHLIB_DIR="$ARMYKNIFE_DIR/bashlib"
LIB_DIR="$BASHLIB_DIR/lib"
BIN_DIR="$BASHLIB_DIR/bin"
COMPLETIONS_DIR="$BASHLIB_DIR/completions"
TEMPLATES_DIR="$BASHLIB_DIR/templates"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Create directory structure
echo -e "${BLUE}Creating bashlib directory structure...${NC}"
mkdir -p "$LIB_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$COMPLETIONS_DIR"
mkdir -p "$TEMPLATES_DIR"
mkdir -p "$BASHLIB_DIR/docs"

# Create Core library
echo -e "${BLUE}Creating core library...${NC}"
cat > "$LIB_DIR/00_core.sh" << 'EOF'
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
    local prompt="${1:-Continue?}"
    read -r -p "$prompt [y/N] " response
    case "$response" in
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

# Export functions
export -f ak_log ak_success ak_error ak_warning ak_debug
export -f ak_command_exists ak_retry ak_confirm ak_timestamp
export -f ak_is_docker ak_is_wsl
EOF

# Create Git library
echo -e "${BLUE}Creating git library...${NC}"
cat > "$LIB_DIR/10_git.sh" << 'EOF'
#!/usr/bin/env bash
# Git functions for ArmyknifeLabs

# Git status with formatting
gst() {
    git status --short --branch "${@}"
}

# Interactive git add
gia() {
    git add -i "${@}"
}

# Git log with graph
glg() {
    git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit "${@}"
}

# Quick commit with message
gcm() {
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
EOF

# Create Docker library
echo -e "${BLUE}Creating docker library...${NC}"
cat > "$LIB_DIR/20_docker.sh" << 'EOF'
#!/usr/bin/env bash
# Docker functions for ArmyknifeLabs

# Docker ps with better formatting
dps() {
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" "${@}"
}

# Docker exec into container
dex() {
    local container="$1"
    shift
    docker exec -it "$container" ${@:-/bin/bash}
}

# Docker logs with follow
dlogs() {
    docker logs -f "${@}"
}

# Stop all running containers
dstop() {
    local containers=$(docker ps -q)
    if [ -n "$containers" ]; then
        docker stop $containers
    else
        ak_log "No running containers"
    fi
}

# Remove all stopped containers
dclean() {
    docker container prune -f
    docker image prune -f
}

# Docker compose shortcuts
dcu() { docker-compose up "${@}"; }
dcd() { docker-compose down "${@}"; }
dcr() { docker-compose restart "${@}"; }
dcl() { docker-compose logs -f "${@}"; }

# Build and tag image
dbuild() {
    local name="$1"
    local tag="${2:-latest}"
    if [ -z "$name" ]; then
        ak_error "Image name required"
        return 1
    fi
    docker build -t "$name:$tag" .
}

# Run container with common options
drun() {
    local image="$1"
    shift
    docker run -it --rm "${@}" "$image"
}

# Show docker disk usage
dsize() {
    docker system df -v
}

# Export functions
export -f dps dex dlogs dstop dclean dcu dcd dcr dcl dbuild drun dsize
EOF

# Create Kubernetes library
echo -e "${BLUE}Creating kubernetes library...${NC}"
cat > "$LIB_DIR/30_kubernetes.sh" << 'EOF'
#!/usr/bin/env bash
# Kubernetes functions for ArmyknifeLabs

# Kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias klog='kubectl logs -f'
alias kex='kubectl exec -it'

# Get pods with more info
kpods() {
    kubectl get pods -o wide "${@}"
}

# Describe pod
kdesc() {
    kubectl describe pod "${@}"
}

# Get pod logs
klogs() {
    local pod="$1"
    shift
    kubectl logs -f "$pod" "${@}"
}

# Execute into pod
kexec() {
    local pod="$1"
    shift
    kubectl exec -it "$pod" -- ${@:-/bin/bash}
}

# Port forward
kpf() {
    local pod="$1"
    local ports="$2"
    kubectl port-forward "$pod" "$ports"
}

# Get all resources
kall() {
    kubectl get all "${@}"
}

# Switch context
kctx() {
    if [ -z "$1" ]; then
        kubectl config get-contexts
    else
        kubectl config use-context "$1"
    fi
}

# Switch namespace
kns() {
    if [ -z "$1" ]; then
        kubectl get namespaces
    else
        kubectl config set-context --current --namespace="$1"
    fi
}

# Get events
kevents() {
    kubectl get events --sort-by='.lastTimestamp' "${@}"
}

# Scale deployment
kscale() {
    local deployment="$1"
    local replicas="$2"
    kubectl scale deployment "$deployment" --replicas="$replicas"
}

# Export functions
export -f kpods kdesc klogs kexec kpf kall kctx kns kevents kscale
EOF

# Create Cloud library
echo -e "${BLUE}Creating cloud library...${NC}"
cat > "$LIB_DIR/40_cloud.sh" << 'EOF'
#!/usr/bin/env bash
# Cloud provider functions for ArmyknifeLabs

# AWS functions
aws_profile() {
    if [ -z "$1" ]; then
        echo "Current profile: ${AWS_PROFILE:-default}"
        aws configure list-profiles
    else
        export AWS_PROFILE="$1"
        ak_success "Switched to AWS profile: $1"
    fi
}

aws_regions() {
    aws ec2 describe-regions --query 'Regions[].RegionName' --output text
}

aws_whoami() {
    aws sts get-caller-identity
}

# Azure functions
az_login() {
    az login "${@}"
}

az_subs() {
    az account list --output table
}

az_set_sub() {
    local sub="$1"
    az account set --subscription "$sub"
}

# GCP functions
gcp_project() {
    if [ -z "$1" ]; then
        gcloud config get-value project
    else
        gcloud config set project "$1"
    fi
}

gcp_regions() {
    gcloud compute regions list
}

# Terraform shortcuts
tf() { terraform "${@}"; }
tfi() { terraform init; }
tfp() { terraform plan; }
tfa() { terraform apply; }
tfd() { terraform destroy; }
tfv() { terraform validate; }
tff() { terraform fmt -recursive; }

# Export functions
export -f aws_profile aws_regions aws_whoami
export -f az_login az_subs az_set_sub
export -f gcp_project gcp_regions
export -f tf tfi tfp tfa tfd tfv tff
EOF

# Create Python library
echo -e "${BLUE}Creating python library...${NC}"
cat > "$LIB_DIR/50_python.sh" << 'EOF'
#!/usr/bin/env bash
# Python functions for ArmyknifeLabs

# Python virtual environment management
pyvenv() {
    local name="${1:-.venv}"
    python3 -m venv "$name"
    ak_success "Created virtual environment: $name"
    echo "Activate with: source $name/bin/activate"
}

pyactivate() {
    local name="${1:-.venv}"
    if [ -f "$name/bin/activate" ]; then
        source "$name/bin/activate"
    else
        ak_error "Virtual environment not found: $name"
    fi
}

# Pip shortcuts
pipi() { pip install "${@}"; }
pipu() { pip install --upgrade "${@}"; }
pipf() { pip freeze > requirements.txt; }
pipr() { pip install -r requirements.txt; }

# Python version management with pyenv
pyv() {
    if ak_command_exists pyenv; then
        pyenv versions
    else
        python3 --version
    fi
}

# Jupyter shortcuts
jnb() { jupyter notebook "${@}"; }
jlab() { jupyter lab "${@}"; }

# Export functions
export -f pyvenv pyactivate pipi pipu pipf pipr pyv jnb jlab
EOF

# Create Node library
echo -e "${BLUE}Creating node library...${NC}"
cat > "$LIB_DIR/51_node.sh" << 'EOF'
#!/usr/bin/env bash
# Node.js functions for ArmyknifeLabs

# NPM shortcuts
ni() { npm install "${@}"; }
nid() { npm install --save-dev "${@}"; }
nig() { npm install -g "${@}"; }
nr() { npm run "${@}"; }
ns() { npm start; }
nt() { npm test; }
nb() { npm run build; }

# Yarn shortcuts
yi() { yarn install; }
ya() { yarn add "${@}"; }
yad() { yarn add --dev "${@}"; }
yr() { yarn run "${@}"; }
ys() { yarn start; }
yt() { yarn test; }
yb() { yarn build; }

# Node version management
nvm_use() {
    if [ -f .nvmrc ]; then
        nvm use
    else
        nvm use default
    fi
}

# Export functions
export -f ni nid nig nr ns nt nb yi ya yad yr ys yt yb nvm_use
EOF

# Create Go library
echo -e "${BLUE}Creating go library...${NC}"
cat > "$LIB_DIR/52_golang.sh" << 'EOF'
#!/usr/bin/env bash
# Go functions for ArmyknifeLabs

# Go shortcuts
gob() { go build "${@}"; }
gor() { go run "${@}"; }
got() { go test "${@}"; }
gog() { go get "${@}"; }
gom() { go mod "${@}"; }
gomi() { go mod init "${@}"; }
gomt() { go mod tidy; }
gomv() { go mod vendor; }

# Go workspace
gowork() {
    local name="$1"
    if [ -z "$name" ]; then
        ak_error "Project name required"
        return 1
    fi
    mkdir -p "$name"
    cd "$name"
    go mod init "$name"
    ak_success "Created Go project: $name"
}

# Export functions
export -f gob gor got gog gom gomi gomt gomv gowork
EOF

# Create Rust library
echo -e "${BLUE}Creating rust library...${NC}"
cat > "$LIB_DIR/53_rust.sh" << 'EOF'
#!/usr/bin/env bash
# Rust functions for ArmyknifeLabs

# Cargo shortcuts
cb() { cargo build "${@}"; }
cr() { cargo run "${@}"; }
ct() { cargo test "${@}"; }
cc() { cargo check "${@}"; }
cf() { cargo fmt "${@}"; }
ccl() { cargo clippy "${@}"; }
crel() { cargo build --release "${@}"; }

# Rust project
rustwork() {
    local name="$1"
    if [ -z "$name" ]; then
        ak_error "Project name required"
        return 1
    fi
    cargo new "$name"
    cd "$name"
    ak_success "Created Rust project: $name"
}

# Export functions
export -f cb cr ct cc cf ccl crel rustwork
EOF

# Create Shell Tools library
echo -e "${BLUE}Creating shell tools library...${NC}"
cat > "$LIB_DIR/60_shell_tools.sh" << 'EOF'
#!/usr/bin/env bash
# Shell tools functions for ArmyknifeLabs

# FZF powered functions
# Interactive file search and open
fo() {
    local file
    file=$(fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}')
    [ -n "$file" ] && ${EDITOR:-vim} "$file"
}

# Interactive directory change
fd() {
    local dir
    dir=$(find ${1:-.} -type d 2> /dev/null | fzf +m)
    [ -n "$dir" ] && cd "$dir"
}

# Interactive process kill
fkill() {
    local pid
    pid=$(ps aux | sed 1d | fzf -m | awk '{print $2}')
    if [ -n "$pid" ]; then
        echo "$pid" | xargs kill -${1:-9}
    fi
}

# Interactive git branch checkout
fgco() {
    local branch
    branch=$(git branch -a | fzf | sed 's/^\*//' | awk '{print $1}')
    [ -n "$branch" ] && git checkout "$branch"
}

# Ripgrep with preview
rgf() {
    rg --color=always --line-number --no-heading "${@}" |
        fzf --ansi --delimiter=: \
            --preview 'bat --color=always --highlight-line={2} {1}' \
            --preview-window=right:60%
}

# Bat shortcuts
batl() { bat --language "${@}"; }
batn() { bat --style=numbers "${@}"; }

# Exa/eza shortcuts (if installed)
if ak_command_exists eza; then
    alias ls='eza'
    alias ll='eza -la'
    alias lt='eza --tree'
    alias la='eza -la --git'
fi

# Zoxide shortcuts (if installed)
if ak_command_exists zoxide; then
    eval "$(zoxide init bash)"
fi

# Export functions
export -f fo fd fkill fgco rgf batl batn
EOF

# Create Security library
echo -e "${BLUE}Creating security library...${NC}"
cat > "$LIB_DIR/70_security.sh" << 'EOF'
#!/usr/bin/env bash
# Security functions for ArmyknifeLabs

# Generate secure password
genpass() {
    local length=${1:-20}
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

# Generate SSH key
genssh() {
    local email="$1"
    local keyname="${2:-id_ed25519}"
    if [ -z "$email" ]; then
        ak_error "Email required"
        return 1
    fi
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/$keyname"
}

# Check SSL certificate
checkssl() {
    local domain="$1"
    if [ -z "$domain" ]; then
        ak_error "Domain required"
        return 1
    fi
    echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | \
        openssl x509 -noout -dates
}

# Encrypt/decrypt with GPG
gpgenc() {
    local file="$1"
    gpg --encrypt --armor --output "$file.asc" "$file"
}

gpgdec() {
    local file="$1"
    gpg --decrypt "$file"
}

# Base64 encode/decode
b64e() { echo -n "${@}" | base64; }
b64d() { echo -n "${@}" | base64 -d; }

# Hash functions
sha256sum() { shasum -a 256 "${@}"; }
md5sum() { md5 "${@}"; }

# Export functions
export -f genpass genssh checkssl gpgenc gpgdec b64e b64d sha256sum md5sum
EOF

# Create Network library
echo -e "${BLUE}Creating network library...${NC}"
cat > "$LIB_DIR/80_network.sh" << 'EOF'
#!/usr/bin/env bash
# Network functions for ArmyknifeLabs

# Port check
portcheck() {
    local host="$1"
    local port="$2"
    nc -zv "$host" "$port" 2>&1
}

# Local port usage
ports() {
    sudo lsof -i -P -n | grep LISTEN
}

# Public IP
pubip() {
    curl -s https://ipinfo.io/ip
}

# DNS lookup
dnslook() {
    dig +short "${@}"
}

# Network interfaces
netif() {
    ip -br addr show
}

# Speed test
speedtest() {
    if ak_command_exists speedtest-cli; then
        speedtest-cli
    else
        curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
    fi
}

# HTTP status check
httpstat() {
    local url="$1"
    curl -o /dev/null -s -w "HTTP Code: %{http_code}\nTime Total: %{time_total}s\n" "$url"
}

# Export functions
export -f portcheck ports pubip dnslook netif speedtest httpstat
EOF

# Create Utilities library
echo -e "${BLUE}Creating utilities library...${NC}"
cat > "$LIB_DIR/90_utils.sh" << 'EOF'
#!/usr/bin/env bash
# Utility functions for ArmyknifeLabs

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           ak_error "Cannot extract '$1'" ;;
        esac
    else
        ak_error "'$1' is not a valid file"
    fi
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Backup file
backup() {
    cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
}

# Find and replace in files
replace() {
    local find="$1"
    local replace="$2"
    local files="${3:-*}"
    grep -rl "$find" $files | xargs sed -i "s/$find/$replace/g"
}

# System info
sysinfo() {
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s) $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
    echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
}

# Weather
weather() {
    curl -s "wttr.in/${1:-}"
}

# Cheat sheet
cheat() {
    curl -s "cheat.sh/$1"
}

# Calculator
calc() {
    echo "scale=2; $*" | bc -l
}

# Export functions
export -f extract mkcd backup replace sysinfo weather cheat calc
EOF

# Create Main library
echo -e "${BLUE}Creating main library...${NC}"
cat > "$LIB_DIR/main.sh" << 'EOF'
#!/usr/bin/env bash
# Main library file that sources all ArmyknifeLabs bash libraries

# Get the library directory
BASHLIB_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Source all library files in order
for lib in "$BASHLIB_DIR"/*.sh; do
    if [ "$lib" != "${BASH_SOURCE[0]}" ]; then
        source "$lib"
    fi
done

# Display loaded libraries if DEBUG is set
if [ "${DEBUG:-0}" = "1" ]; then
    echo "ArmyknifeLabs Bash Libraries loaded:"
    for lib in "$BASHLIB_DIR"/*.sh; do
        if [ "$lib" != "${BASH_SOURCE[0]}" ]; then
            echo "  - $(basename $lib)"
        fi
    done
fi

# Version check
ak_bashlib_version() {
    echo "ArmyknifeLabs Bash Libraries v$ARMYKNIFE_BASHLIB_VERSION"
}

# Help function
ak_help() {
    cat << HELP
ArmyknifeLabs Bash Libraries - Available Functions

Core:
  ak_log, ak_success, ak_error, ak_warning, ak_debug
  ak_command_exists, ak_retry, ak_confirm, ak_timestamp

Git:
  gst, gia, glg, gcm, gnb, gpush, gpull, grebase, gstash, gfind, gcleanup

Docker:
  dps, dex, dlogs, dstop, dclean, dcu, dcd, dcr, dcl, dbuild, drun

Kubernetes:
  kpods, kdesc, klogs, kexec, kpf, kall, kctx, kns, kevents, kscale

Cloud:
  aws_profile, aws_regions, az_login, az_subs, gcp_project, tf, tfi, tfp

Languages:
  Python: pyvenv, pyactivate, pipi, pipu, pipf
  Node: ni, nr, ns, nt, nb, yi, ya, yr
  Go: gob, gor, got, gom, gowork
  Rust: cb, cr, ct, cc, cf, rustwork

Shell Tools:
  fo, fd, fkill, fgco, rgf, batl, batn

Security:
  genpass, genssh, checkssl, gpgenc, gpgdec, b64e, b64d

Network:
  portcheck, ports, pubip, dnslook, netif, speedtest, httpstat

Utilities:
  extract, mkcd, backup, replace, sysinfo, weather, cheat, calc

Type 'ak_help' to see this help again.
Type 'ak_bashlib_version' to see version info.
HELP
}

export -f ak_bashlib_version ak_help
EOF

# Create example scripts
echo -e "${BLUE}Creating example scripts...${NC}"

# Git workflow script
cat > "$BIN_DIR/git-workflow" << 'EOF'
#!/usr/bin/env bash
# Example git workflow script using ArmyknifeLabs bash libraries

source "$(dirname "$0")/../lib/main.sh"

ak_log "Starting git workflow helper"

# Check git status
echo -e "\n${CYAN}Current git status:${NC}"
gst

# Show recent commits
echo -e "\n${CYAN}Recent commits:${NC}"
glg -5

# Interactive menu
echo -e "\n${CYAN}What would you like to do?${NC}"
select action in "Create branch" "Commit changes" "Push changes" "Pull latest" "Quit"; do
    case $action in
        "Create branch")
            read -p "Branch name: " branch
            gnb "$branch"
            ;;
        "Commit changes")
            gia
            read -p "Commit message: " msg
            gcm "$msg"
            ;;
        "Push changes")
            gpush
            ;;
        "Pull latest")
            gpull
            ;;
        "Quit")
            break
            ;;
    esac
done
EOF
chmod +x "$BIN_DIR/git-workflow"

# Docker helper script
cat > "$BIN_DIR/docker-helper" << 'EOF'
#!/usr/bin/env bash
# Docker helper script using ArmyknifeLabs bash libraries

source "$(dirname "$0")/../lib/main.sh"

ak_log "Docker Helper"

# Show running containers
echo -e "\n${CYAN}Running containers:${NC}"
dps

# Menu
echo -e "\n${CYAN}Docker actions:${NC}"
select action in "Execute into container" "View logs" "Stop all" "Clean up" "Quit"; do
    case $action in
        "Execute into container")
            read -p "Container name/ID: " container
            dex "$container"
            ;;
        "View logs")
            read -p "Container name/ID: " container
            dlogs "$container"
            ;;
        "Stop all")
            dstop
            ;;
        "Clean up")
            dclean
            ;;
        "Quit")
            break
            ;;
    esac
done
EOF
chmod +x "$BIN_DIR/docker-helper"

# System check script
cat > "$BIN_DIR/syscheck" << 'EOF'
#!/usr/bin/env bash
# System check script using ArmyknifeLabs bash libraries

source "$(dirname "$0")/../lib/main.sh"

ak_log "System Check Report"
echo "===================="
sysinfo
echo ""

ak_log "Network Info"
echo "===================="
echo "Public IP: $(pubip)"
netif
echo ""

ak_log "Available Commands"
echo "===================="
for cmd in docker kubectl aws gcloud terraform python node go rust; do
    if ak_command_exists $cmd; then
        ak_success "$cmd is installed"
    else
        ak_warning "$cmd is not installed"
    fi
done
EOF
chmod +x "$BIN_DIR/syscheck"

# Create template README
echo -e "${BLUE}Creating template files...${NC}"
cat > "$TEMPLATES_DIR/README_template.md" << 'EOF'
# ArmyknifeLabs Bash Libraries

## Quick Start

Add to your `.bashrc` or `.zshrc`:

```bash
source ~/.armyknife/bashlib/lib/main.sh
```

## Available Functions

See all functions with: `ak_help`

## Creating Custom Libraries

1. Create a new file in `~/.armyknife/bashlib/lib/`
2. Add your functions
3. They will be automatically sourced

## Examples

See example scripts in `~/.armyknife/bashlib/bin/`
EOF

# Install into shell configuration
echo -e "${BLUE}Installing bash libraries into shell...${NC}"

# Add to bashrc
if [ -f ~/.bashrc ]; then
    if ! grep -q "ArmyknifeLabs Bash Libraries" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# ArmyknifeLabs Bash Libraries" >> ~/.bashrc
        echo "if [ -f $LIB_DIR/main.sh ]; then" >> ~/.bashrc
        echo "    source $LIB_DIR/main.sh" >> ~/.bashrc
        echo "fi" >> ~/.bashrc
        echo "" >> ~/.bashrc
        echo "# Add bashlib bin to PATH" >> ~/.bashrc
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> ~/.bashrc
        echo -e "${GREEN}✓ Added to .bashrc${NC}"
    else
        echo -e "${YELLOW}⚠ Already in .bashrc${NC}"
    fi
fi

# Add to zshrc
if [ -f ~/.zshrc ]; then
    if ! grep -q "ArmyknifeLabs Bash Libraries" ~/.zshrc; then
        echo "" >> ~/.zshrc
        echo "# ArmyknifeLabs Bash Libraries" >> ~/.zshrc
        echo "if [ -f $LIB_DIR/main.sh ]; then" >> ~/.zshrc
        echo "    source $LIB_DIR/main.sh" >> ~/.zshrc
        echo "fi" >> ~/.zshrc
        echo "" >> ~/.zshrc
        echo "# Add bashlib bin to PATH" >> ~/.zshrc
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> ~/.zshrc
        echo -e "${GREEN}✓ Added to .zshrc${NC}"
    else
        echo -e "${YELLOW}⚠ Already in .zshrc${NC}"
    fi
fi

echo -e "${GREEN}✓ Bash libraries setup complete!${NC}"
echo ""
echo "To activate the bash libraries, run:"
echo "  source ~/.bashrc  (or ~/.zshrc)"
echo ""
echo "Then try:"
echo "  ak_help          - See all available functions"
echo "  git-workflow     - Interactive git helper"
echo "  docker-helper    - Docker management tool"
echo "  syscheck         - System information report"