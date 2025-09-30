# ArmyknifeLabs Platform Installer - Base System Module
# Makefile.Base.mk
#
# Phase 1: Foundation - OS Detection, Updates, Build Tools, Core Dependencies
# This module MUST complete successfully before any other components
#
# Supported Operating Systems:
#   - Ubuntu 20.04 LTS, 22.04 LTS, 24.04 LTS
#   - Debian 11 (Bullseye), 12 (Bookworm)
#   - Fedora 39, 40
#   - RHEL/AlmaLinux/Rocky 9+
#   - macOS 13+ (Ventura, Sonoma, Sequoia) - Intel & Apple Silicon

# Import parent variables
ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-$(shell date +%Y%m%d-%H%M%S).log

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m

# Banner function - will use figlet if available, fallback to echo
define show_completion_banner
	@if command -v figlet &> /dev/null; then \
		echo ""; \
		echo -e "${GREEN}"; \
		figlet -f small "$(1)"; \
		echo -e "${NC}"; \
	else \
		echo ""; \
		echo -e "${GREEN}========================================${NC}"; \
		echo -e "${GREEN}   $(1)${NC}"; \
		echo -e "${GREEN}========================================${NC}"; \
	fi
endef

# OS Detection variables
OS_TYPE := unknown
OS_VERSION := unknown
OS_ARCH := $(shell uname -m)
PACKAGE_MANAGER := unknown
IS_MACOS := false
IS_LINUX := false
IS_WSL := false

# Detect operating system
ifeq ($(shell uname -s),Linux)
    IS_LINUX := true
    ifneq ($(wildcard /etc/os-release),)
        OS_TYPE := $(shell . /etc/os-release && echo $$ID)
        OS_VERSION := $(shell . /etc/os-release && echo $$VERSION_ID)
    endif
    # Check if running in WSL
    ifneq ($(wildcard /proc/sys/fs/binfmt_misc/WSLInterop),)
        IS_WSL := true
    endif
else ifeq ($(shell uname -s),Darwin)
    IS_MACOS := true
    OS_TYPE := macos
    OS_VERSION := $(shell sw_vers -productVersion)
endif

# Determine package manager
ifeq ($(OS_TYPE),ubuntu)
    PACKAGE_MANAGER := apt
else ifeq ($(OS_TYPE),debian)
    PACKAGE_MANAGER := apt
else ifeq ($(OS_TYPE),linuxmint)
    PACKAGE_MANAGER := apt
else ifeq ($(OS_TYPE),fedora)
    PACKAGE_MANAGER := dnf
else ifeq ($(OS_TYPE),rhel)
    PACKAGE_MANAGER := dnf
else ifeq ($(OS_TYPE),almalinux)
    PACKAGE_MANAGER := dnf
else ifeq ($(OS_TYPE),rocky)
    PACKAGE_MANAGER := dnf
else ifeq ($(OS_TYPE),macos)
    PACKAGE_MANAGER := brew
endif

# Sudo command (not needed on macOS for Homebrew)
ifeq ($(IS_MACOS),true)
    SUDO :=
else
    SUDO := sudo
endif

# Package lists by OS
APT_BUILD_PACKAGES := build-essential cmake pkg-config autoconf automake libtool \
    gcc g++ make git curl wget openssl libssl-dev ca-certificates gnupg lsb-release \
    software-properties-common apt-transport-https unzip zip gzip tar bzip2 xz-utils \
    python3 python3-pip python3-venv python3-dev libffi-dev libbz2-dev libreadline-dev \
    libsqlite3-dev libncurses5-dev libncursesw5-dev libxml2-dev libxmlsec1-dev \
    liblzma-dev tk-dev libgdbm-dev libc6-dev zlib1g-dev figlet toilet lolcat

DNF_BUILD_PACKAGES := @development-tools gcc gcc-c++ make cmake pkg-config \
    autoconf automake libtool git curl wget openssl openssl-devel ca-certificates \
    gnupg2 unzip zip gzip tar bzip2 xz python3 python3-pip python3-devel \
    libffi-devel bzip2-devel readline-devel sqlite-devel ncurses-devel \
    libxml2-devel xmlsec1-devel xz-devel tk-devel gdbm-devel zlib-devel figlet

BREW_BUILD_PACKAGES := cmake pkg-config autoconf automake libtool \
    git curl wget openssl gnupg unzip zip gzip tar bzip2 xz \
    python@3 libffi readline sqlite ncurses libxml2 zlib figlet toilet lolcat

# Phony targets
.PHONY: all detect-os check-prerequisites update-system install-build-tools \
    setup-shell-foundation configure-automatic-updates install-homebrew \
    install-xcode-tools backup-system-files test-base verify-base

# Main target
all: detect-os check-prerequisites backup-system-files update-system \
    install-build-tools setup-shell-foundation configure-automatic-updates \
    verify-base

# Detect OS and architecture
detect-os:
	@echo -e "${BLUE}ℹ${NC} Detecting operating system..."
	@echo "  OS Type: $(OS_TYPE)"
	@echo "  OS Version: $(OS_VERSION)"
	@echo "  Architecture: $(OS_ARCH)"
	@echo "  Package Manager: $(PACKAGE_MANAGER)"
	@echo "  Is macOS: $(IS_MACOS)"
	@echo "  Is Linux: $(IS_LINUX)"
	@echo "  Is WSL: $(IS_WSL)"
	@echo "[$(shell date +'%Y-%m-%d %H:%M:%S')] OS Detection: $(OS_TYPE) $(OS_VERSION) $(OS_ARCH)" >> $(LOG_FILE)
	@if [ "$(OS_TYPE)" = "unknown" ]; then \
		echo -e "${RED}✗${NC} Unsupported operating system!"; \
		exit 1; \
	fi
	@echo -e "${GREEN}✓${NC} Operating system detected successfully"

# Check prerequisites
check-prerequisites:
	@echo -e "${BLUE}ℹ${NC} Checking prerequisites..."
	@# Check for sudo (Linux only)
	@if [ "$(IS_LINUX)" = "true" ]; then \
		if ! command -v sudo &> /dev/null; then \
			echo -e "${RED}✗${NC} sudo is not installed"; \
			exit 1; \
		fi; \
	fi
	@# Check for curl or wget
	@if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then \
		echo -e "${RED}✗${NC} Neither curl nor wget is installed"; \
		exit 1; \
	fi
	@echo -e "${GREEN}✓${NC} Prerequisites check passed"

# Backup system files before modification
backup-system-files:
	@echo -e "${BLUE}ℹ${NC} Backing up system configuration files..."
	@mkdir -p $(ARMYKNIFE_DIR)/backups
	@# Backup shell configs
	@for file in .bashrc .bash_profile .zshrc .zprofile .profile; do \
		if [ -f "$$HOME/$$file" ]; then \
			cp "$$HOME/$$file" "$(ARMYKNIFE_DIR)/backups/$$file.backup-$$(date +%s)" 2>/dev/null || true; \
			echo "  Backed up ~/$$file"; \
		fi; \
	done
	@# Backup git config
	@if [ -f "$$HOME/.gitconfig" ]; then \
		cp "$$HOME/.gitconfig" "$(ARMYKNIFE_DIR)/backups/.gitconfig.backup-$$(date +%s)" 2>/dev/null || true; \
		echo "  Backed up ~/.gitconfig"; \
	fi
	@echo -e "${GREEN}✓${NC} Backup complete"

# Update system packages
update-system:
	@echo -e "${BLUE}ℹ${NC} Updating system packages..."
	@echo "[$(shell date +'%Y-%m-%d %H:%M:%S')] Starting system update" >> $(LOG_FILE)
ifeq ($(PACKAGE_MANAGER),apt)
	@echo "  Running apt update..."
	@$(SUDO) apt update -qq 2>&1 | tee -a $(LOG_FILE)
	@echo "  Running apt upgrade..."
	@$(SUDO) DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq 2>&1 | tee -a $(LOG_FILE)
	@echo "  Running apt dist-upgrade..."
	@$(SUDO) DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y -qq 2>&1 | tee -a $(LOG_FILE)
	@echo "  Cleaning up..."
	@$(SUDO) apt autoremove -y -qq 2>&1 | tee -a $(LOG_FILE)
	@$(SUDO) apt autoclean -qq 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(PACKAGE_MANAGER),dnf)
	@echo "  Running dnf upgrade..."
	@$(SUDO) dnf upgrade --refresh -y -q 2>&1 | tee -a $(LOG_FILE)
	@echo "  Cleaning up..."
	@$(SUDO) dnf autoremove -y -q 2>&1 | tee -a $(LOG_FILE)
	@$(SUDO) dnf clean all -q 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@echo "  Running macOS software update..."
	@softwareupdate -ia --agree-to-license 2>&1 | tee -a $(LOG_FILE) || true
	@# Update Homebrew if installed
	@if command -v brew &> /dev/null; then \
		echo "  Updating Homebrew..."; \
		brew update 2>&1 | tee -a $(LOG_FILE); \
		brew upgrade 2>&1 | tee -a $(LOG_FILE); \
		brew cleanup 2>&1 | tee -a $(LOG_FILE); \
	fi
endif
	@echo -e "${GREEN}✓${NC} System packages updated"

# Install Xcode Command Line Tools (macOS only)
install-xcode-tools:
ifeq ($(IS_MACOS),true)
	@echo -e "${BLUE}ℹ${NC} Checking Xcode Command Line Tools..."
	@if ! xcode-select -p &> /dev/null; then \
		echo "  Installing Xcode Command Line Tools..."; \
		touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress; \
		softwareupdate -ia --verbose 2>&1 | grep "Command Line Tools" | tee -a $(LOG_FILE); \
		rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress; \
		xcode-select --install 2>/dev/null || true; \
		echo "  Waiting for installation to complete..."; \
		until xcode-select -p &> /dev/null; do sleep 5; done; \
		echo -e "${GREEN}✓${NC} Xcode Command Line Tools installed"; \
	else \
		echo -e "${GREEN}✓${NC} Xcode Command Line Tools already installed"; \
	fi
endif

# Install Homebrew (macOS only)
install-homebrew: install-xcode-tools
ifeq ($(IS_MACOS),true)
	@echo -e "${BLUE}ℹ${NC} Checking Homebrew..."
	@if ! command -v brew &> /dev/null; then \
		echo "  Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a $(LOG_FILE); \
		echo "  Configuring Homebrew in shell..."; \
		if [ -f /opt/homebrew/bin/brew ]; then \
			echo 'eval "$$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile; \
			eval "$$(/opt/homebrew/bin/brew shellenv)"; \
		elif [ -f /usr/local/bin/brew ]; then \
			echo 'eval "$$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile; \
			eval "$$(/usr/local/bin/brew shellenv)"; \
		fi; \
		echo -e "${GREEN}✓${NC} Homebrew installed"; \
	else \
		echo -e "${GREEN}✓${NC} Homebrew already installed"; \
	fi
endif

# Install build tools and compilers
install-build-tools:
	@echo -e "${BLUE}ℹ${NC} Installing build tools and compilers..."
	@echo "[$(shell date +'%Y-%m-%d %H:%M:%S')] Installing build tools" >> $(LOG_FILE)
ifeq ($(PACKAGE_MANAGER),apt)
	@echo "  Installing essential build packages..."
	@$(SUDO) DEBIAN_FRONTEND=noninteractive apt install -y -qq $(APT_BUILD_PACKAGES) 2>&1 | tee -a $(LOG_FILE)
	@# Add essential PPAs (skip on Linux Mint as it has different PPA handling)
	@if [ "$(OS_TYPE)" != "linuxmint" ]; then \
		echo "  Adding PPAs for latest versions..."; \
		$(SUDO) add-apt-repository -y ppa:git-core/ppa 2>&1 | tee -a $(LOG_FILE) || true; \
		$(SUDO) add-apt-repository -y ppa:deadsnakes/ppa 2>&1 | tee -a $(LOG_FILE) || true; \
		$(SUDO) apt update -qq 2>&1 | tee -a $(LOG_FILE); \
	else \
		echo "  Skipping PPA addition on Linux Mint (uses Ubuntu base)"; \
	fi
else ifeq ($(PACKAGE_MANAGER),dnf)
	@echo "  Installing development tools..."
	@$(SUDO) dnf groupinstall -y -q "Development Tools" 2>&1 | tee -a $(LOG_FILE)
	@$(SUDO) dnf install -y -q $(DNF_BUILD_PACKAGES) 2>&1 | tee -a $(LOG_FILE)
	@# Enable EPEL and additional repositories
	@echo "  Enabling additional repositories..."
	@$(SUDO) dnf install -y -q epel-release 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) dnf config-manager --set-enabled crb 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) dnf config-manager --set-enabled powertools 2>&1 | tee -a $(LOG_FILE) || true
else ifeq ($(IS_MACOS),true)
	@$(MAKE) install-homebrew
	@echo "  Installing build packages via Homebrew..."
	@brew install $(BREW_BUILD_PACKAGES) 2>&1 | tee -a $(LOG_FILE) || true
	@# Configure Homebrew taps
	@echo "  Adding Homebrew taps..."
	@brew tap homebrew/cask 2>&1 | tee -a $(LOG_FILE) || true
	@brew tap homebrew/cask-fonts 2>&1 | tee -a $(LOG_FILE) || true
	@brew tap homebrew/cask-versions 2>&1 | tee -a $(LOG_FILE) || true
endif
	@echo -e "${GREEN}✓${NC} Build tools installed"

# Setup shell foundation (prepare for Oh-My-Bash/Zsh installation)
setup-shell-foundation:
	@echo -e "${BLUE}ℹ${NC} Setting up shell foundation..."
	@mkdir -p $(ARMYKNIFE_DIR)/{lib,config,bin}
	@# Create ArmyknifeLabs library directory structure
	@echo "  Creating library structure..."
	@touch $(ARMYKNIFE_DIR)/lib/core.sh
	@touch $(ARMYKNIFE_DIR)/lib/os-detection.sh
	@touch $(ARMYKNIFE_DIR)/lib/package-mgmt.sh
	@touch $(ARMYKNIFE_DIR)/lib/version-mgmt.sh
	@touch $(ARMYKNIFE_DIR)/lib/docker.sh
	@touch $(ARMYKNIFE_DIR)/lib/cloud.sh
	@touch $(ARMYKNIFE_DIR)/lib/security.sh
	@touch $(ARMYKNIFE_DIR)/lib/secrets.sh
	@touch $(ARMYKNIFE_DIR)/lib/virtualization.sh
	@touch $(ARMYKNIFE_DIR)/lib/tailscale.sh
	@# Set permissions
	@chmod 755 $(ARMYKNIFE_DIR)/lib/*.sh
	@# Add shell integration snippet (to be activated by Shell module)
	@echo "# ArmyknifeLabs Platform" > $(ARMYKNIFE_DIR)/config/shell-integration.sh
	@echo 'if [ -d "$$HOME/.armyknife/lib" ]; then' >> $(ARMYKNIFE_DIR)/config/shell-integration.sh
	@echo '    for lib in "$$HOME/.armyknife/lib"/*.sh; do' >> $(ARMYKNIFE_DIR)/config/shell-integration.sh
	@echo '        [ -f "$$lib" ] && source "$$lib"' >> $(ARMYKNIFE_DIR)/config/shell-integration.sh
	@echo '    done' >> $(ARMYKNIFE_DIR)/config/shell-integration.sh
	@echo 'fi' >> $(ARMYKNIFE_DIR)/config/shell-integration.sh
	@echo 'export PATH="$$HOME/.armyknife/bin:$$PATH"' >> $(ARMYKNIFE_DIR)/config/shell-integration.sh
	@echo 'alias armyknife="make -C $$HOME/armyknife-platform"' >> $(ARMYKNIFE_DIR)/config/shell-integration.sh
	@echo 'alias ak="armyknife"' >> $(ARMYKNIFE_DIR)/config/shell-integration.sh
	@echo -e "${GREEN}✓${NC} Shell foundation prepared"

# Configure automatic updates
configure-automatic-updates:
	@echo -e "${BLUE}ℹ${NC} Configuring automatic system updates..."
ifeq ($(PACKAGE_MANAGER),apt)
	@echo "  Installing unattended-upgrades..."
	@$(SUDO) DEBIAN_FRONTEND=noninteractive apt install -y -qq unattended-upgrades apt-listchanges 2>&1 | tee -a $(LOG_FILE)
	@echo "  Configuring automatic updates..."
	@echo 'APT::Periodic::Update-Package-Lists "1";' | $(SUDO) tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null
	@echo 'APT::Periodic::Download-Upgradeable-Packages "1";' | $(SUDO) tee -a /etc/apt/apt.conf.d/20auto-upgrades > /dev/null
	@echo 'APT::Periodic::AutocleanInterval "7";' | $(SUDO) tee -a /etc/apt/apt.conf.d/20auto-upgrades > /dev/null
	@echo 'APT::Periodic::Unattended-Upgrade "1";' | $(SUDO) tee -a /etc/apt/apt.conf.d/20auto-upgrades > /dev/null
	@$(SUDO) dpkg-reconfigure -plow unattended-upgrades 2>&1 | tee -a $(LOG_FILE) || true
else ifeq ($(PACKAGE_MANAGER),dnf)
	@echo "  Installing dnf-automatic..."
	@$(SUDO) dnf install -y -q dnf-automatic 2>&1 | tee -a $(LOG_FILE)
	@echo "  Configuring automatic updates..."
	@$(SUDO) sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
	@$(SUDO) systemctl enable --now dnf-automatic.timer 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@echo "  Configuring macOS automatic updates..."
	@$(SUDO) defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
	@$(SUDO) defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
	@$(SUDO) defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true
	@$(SUDO) defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool true
	@softwareupdate --schedule on 2>&1 | tee -a $(LOG_FILE) || true
endif
	@# Create custom update script
	@echo "#!/bin/bash" > $(ARMYKNIFE_DIR)/bin/ak-auto-update
	@echo "# ArmyknifeLabs Auto-Update Script" >> $(ARMYKNIFE_DIR)/bin/ak-auto-update
	@echo "LOG_FILE=$(ARMYKNIFE_DIR)/logs/auto-update-\$$(date +%Y%m%d).log" >> $(ARMYKNIFE_DIR)/bin/ak-auto-update
	@echo "echo \"[\$$(date +'%Y-%m-%d %H:%M:%S')] Starting auto-update\" >> \$$LOG_FILE" >> $(ARMYKNIFE_DIR)/bin/ak-auto-update
ifeq ($(PACKAGE_MANAGER),apt)
	@echo "sudo apt update >> \$$LOG_FILE 2>&1" >> $(ARMYKNIFE_DIR)/bin/ak-auto-update
	@echo "sudo apt upgrade -y >> \$$LOG_FILE 2>&1" >> $(ARMYKNIFE_DIR)/bin/ak-auto-update
else ifeq ($(PACKAGE_MANAGER),dnf)
	@echo "sudo dnf upgrade -y >> \$$LOG_FILE 2>&1" >> $(ARMYKNIFE_DIR)/bin/ak-auto-update
else ifeq ($(IS_MACOS),true)
	@echo "softwareupdate -ia --agree-to-license >> \$$LOG_FILE 2>&1" >> $(ARMYKNIFE_DIR)/bin/ak-auto-update
	@echo "brew update >> \$$LOG_FILE 2>&1" >> $(ARMYKNIFE_DIR)/bin/ak-auto-update
	@echo "brew upgrade >> \$$LOG_FILE 2>&1" >> $(ARMYKNIFE_DIR)/bin/ak-auto-update
endif
	@echo "echo \"[\$$(date +'%Y-%m-%d %H:%M:%S')] Auto-update complete\" >> \$$LOG_FILE" >> $(ARMYKNIFE_DIR)/bin/ak-auto-update
	@chmod +x $(ARMYKNIFE_DIR)/bin/ak-auto-update
	@# Setup cron job for auto-updates (Linux only)
ifeq ($(IS_LINUX),true)
	@echo "  Setting up cron job for automatic updates..."
	@echo "0 2 * * * $(ARMYKNIFE_DIR)/bin/ak-auto-update" | crontab -l 2>/dev/null | { cat; echo "0 2 * * * $(ARMYKNIFE_DIR)/bin/ak-auto-update"; } | crontab - || true
endif
	@echo -e "${GREEN}✓${NC} Automatic updates configured"

# Verify base installation
verify-base:
	@echo -e "${BLUE}ℹ${NC} Verifying base installation..."
	@# Check for essential commands
	@for cmd in git make gcc curl wget; do \
		if command -v $$cmd &> /dev/null; then \
			echo -e "  ${GREEN}✓${NC} $$cmd is installed ($$($$cmd --version 2>&1 | head -n1))"; \
		else \
			echo -e "  ${RED}✗${NC} $$cmd is not installed"; \
		fi; \
	done
	@# Check directory structure
	@if [ -d "$(ARMYKNIFE_DIR)/lib" ]; then \
		echo -e "  ${GREEN}✓${NC} ArmyknifeLabs library directory exists"; \
	else \
		echo -e "  ${RED}✗${NC} ArmyknifeLabs library directory missing"; \
	fi
	$(call show_completion_banner,BASE SYSTEM READY)
	@echo -e "${GREEN}✓${NC} Base system verification complete"

# Test base installation
test-base:
	@echo -e "${BLUE}ℹ${NC} Testing base installation..."
	@# Test compiler
	@echo "  Testing C compiler..."
	@echo '#include <stdio.h>\nint main() { printf("Hello from ArmyknifeLabs!\\n"); return 0; }' > /tmp/test.c
	@gcc /tmp/test.c -o /tmp/test && /tmp/test
	@rm -f /tmp/test.c /tmp/test
	@echo -e "  ${GREEN}✓${NC} C compiler works"
	@# Test Python
	@echo "  Testing Python..."
	@python3 -c "print('Python is working!')"
	@echo -e "  ${GREEN}✓${NC} Python works"
	@echo -e "${GREEN}✓${NC} All base tests passed"

# Update only the base system components
update-base:
	@echo -e "${BLUE}ℹ${NC} Updating base system components..."
	@$(MAKE) update-system
	@echo -e "${GREEN}✓${NC} Base system updated"

# Clean base installation artifacts
clean-base:
	@echo -e "${YELLOW}⚠${NC} Cleaning base installation artifacts..."
	@rm -rf /tmp/armyknife-base-*
	@echo -e "${GREEN}✓${NC} Base cleanup complete"

# Help for base module
help-base:
	@echo "ArmyknifeLabs Base System Module"
	@echo ""
	@echo "Targets:"
	@echo "  all                      - Install complete base system"
	@echo "  detect-os                - Detect operating system"
	@echo "  update-system            - Update system packages"
	@echo "  install-build-tools      - Install compilers and build tools"
	@echo "  setup-shell-foundation   - Prepare shell environment"
	@echo "  configure-automatic-updates - Setup auto-updates"
	@echo "  verify-base              - Verify installation"
	@echo "  test-base                - Test installation"
	@echo "  update-base              - Update base components"
	@echo "  clean-base               - Clean temporary files"
	@echo ""
	@echo "Detected Configuration:"
	@echo "  OS: $(OS_TYPE) $(OS_VERSION)"
	@echo "  Architecture: $(OS_ARCH)"
	@echo "  Package Manager: $(PACKAGE_MANAGER)"