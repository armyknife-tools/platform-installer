# ArmyknifeLabs Platform Installer - Enhanced Package Managers Module
# Makefile.PackageMgrs.mk
#
# Installs advanced package managers: Nix, Homebrew (Linux), Flatpak, Snap
# Configures repositories and enhances system package management

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

# OS detection
OS_TYPE := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo macos)
OS_VERSION := $(shell . /etc/os-release 2>/dev/null && echo $$VERSION_ID || sw_vers -productVersion 2>/dev/null)
IS_MACOS := $(shell [[ "$$(uname -s)" == "Darwin" ]] && echo true || echo false)
IS_LINUX := $(shell [[ "$$(uname -s)" == "Linux" ]] && echo true || echo false)
ARCH := $(shell uname -m)

# Package manager detection
PACKAGE_MANAGER := unknown
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
else ifeq ($(OS_TYPE),arch)
    PACKAGE_MANAGER := pacman
else ifeq ($(IS_MACOS),true)
    PACKAGE_MANAGER := brew
endif

# Sudo command
ifeq ($(IS_MACOS),true)
    SUDO :=
else
    SUDO := sudo
endif

# Installer URLs
NIX_INSTALLER := https://nixos.org/nix/install
HOMEBREW_INSTALLER := https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh

# Phony targets
.PHONY: all install-nix configure-nix install-homebrew-linux install-flatpak \
    install-snap configure-repositories add-ppas add-rpm-repos \
    install-package-tools verify-package-managers update-package-managers \
    clean-package-managers help-package-managers

# Main target
all: configure-repositories install-nix install-homebrew-linux \
    install-flatpak install-snap install-package-tools verify-package-managers

# Configure system repositories
configure-repositories:
	@echo -e "${BLUE}ℹ${NC} Configuring system repositories..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(MAKE) add-ppas
else ifeq ($(PACKAGE_MANAGER),dnf)
	@$(MAKE) add-rpm-repos
endif
	@echo -e "${GREEN}✓${NC} Repositories configured"

# Add Ubuntu/Debian PPAs
add-ppas:
	@echo -e "${BLUE}ℹ${NC} Adding PPAs and repositories..."
	@# Ensure software-properties-common is installed
	@$(SUDO) apt install -y software-properties-common apt-transport-https ca-certificates gnupg lsb-release 2>&1 | tee -a $(LOG_FILE)
	@# Git PPA (latest Git)
	@echo "  Adding Git PPA..."
	@$(SUDO) add-apt-repository -y ppa:git-core/ppa 2>/dev/null || echo "  Git PPA already added or not available"
	@# Deadsnakes PPA (multiple Python versions)
	@echo "  Adding Deadsnakes PPA..."
	@$(SUDO) add-apt-repository -y ppa:deadsnakes/ppa 2>/dev/null || echo "  Deadsnakes PPA already added or not available"
	@# Neovim PPA
	@echo "  Adding Neovim PPA..."
	@$(SUDO) add-apt-repository -y ppa:neovim-ppa/stable 2>/dev/null || echo "  Neovim PPA already added or not available"
	@# Update package lists
	@echo "  Updating package lists..."
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE)
	@echo -e "${GREEN}✓${NC} PPAs added"

# Add Fedora/RHEL repositories
add-rpm-repos:
	@echo -e "${BLUE}ℹ${NC} Adding RPM repositories..."
	@# EPEL (Extra Packages for Enterprise Linux)
	@echo "  Installing EPEL..."
	@$(SUDO) dnf install -y epel-release 2>&1 | tee -a $(LOG_FILE) || \
		$(SUDO) dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm 2>&1 | tee -a $(LOG_FILE) || \
		echo "  EPEL already installed or not available"
	@# RPM Fusion (free and non-free)
	@echo "  Installing RPM Fusion..."
	@if [ "$(OS_TYPE)" = "fedora" ]; then \
		$(SUDO) dnf install -y \
			https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$$(rpm -E %fedora).noarch.rpm \
			https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$$(rpm -E %fedora).noarch.rpm \
			2>&1 | tee -a $(LOG_FILE) || echo "  RPM Fusion already installed"; \
	fi
	@# Enable PowerTools/CRB
	@echo "  Enabling PowerTools/CRB..."
	@$(SUDO) dnf config-manager --set-enabled crb 2>/dev/null || \
		$(SUDO) dnf config-manager --set-enabled powertools 2>/dev/null || \
		echo "  PowerTools/CRB already enabled or not available"
	@# Update metadata
	@echo "  Updating metadata..."
	@$(SUDO) dnf makecache 2>&1 | tee -a $(LOG_FILE)
	@echo -e "${GREEN}✓${NC} RPM repositories added"

# Install Nix package manager
install-nix:
	@echo -e "${BLUE}ℹ${NC} Installing Nix package manager..."
	@if [ -d /nix ]; then \
		echo -e "${GREEN}✓${NC} Nix already installed"; \
		echo "  Version: $$(nix --version 2>/dev/null || echo 'unknown')"; \
	else \
		echo "  Downloading Nix installer..."; \
		curl -L $(NIX_INSTALLER) -o /tmp/install-nix.sh; \
		echo "  Running Nix installer (this may take a few minutes)..."; \
		sh /tmp/install-nix.sh --daemon --yes 2>&1 | tee -a $(LOG_FILE) || \
			sh /tmp/install-nix.sh --yes 2>&1 | tee -a $(LOG_FILE); \
		rm -f /tmp/install-nix.sh; \
		echo -e "${GREEN}✓${NC} Nix installed"; \
		echo ""; \
		echo -e "${YELLOW}⚠${NC} IMPORTANT: You need to restart your shell or run:"; \
		echo "    source /etc/profile.d/nix.sh  # On Linux"; \
		echo "    source ~/.nix-profile/etc/profile.d/nix.sh  # Alternative"; \
	fi
	@$(MAKE) configure-nix

# Configure Nix
configure-nix:
	@echo -e "${BLUE}ℹ${NC} Configuring Nix..."
	@# Create Nix configuration directory
	@mkdir -p ~/.config/nix
	@# Enable experimental features (flakes)
	@if [ ! -f ~/.config/nix/nix.conf ]; then \
		echo "# Nix Configuration" > ~/.config/nix/nix.conf; \
		echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf; \
		echo "max-jobs = auto" >> ~/.config/nix/nix.conf; \
		echo "cores = 0" >> ~/.config/nix/nix.conf; \
		echo "sandbox = true" >> ~/.config/nix/nix.conf; \
		echo -e "${GREEN}✓${NC} Nix configured with flakes support"; \
	fi
	@# Add Nix to shell RC files
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ]; then \
			if ! grep -q "nix.sh" $$rc; then \
				echo "" >> $$rc; \
				echo "# Nix Package Manager" >> $$rc; \
				echo '[ -f /etc/profile.d/nix.sh ] && source /etc/profile.d/nix.sh' >> $$rc; \
				echo '[ -f ~/.nix-profile/etc/profile.d/nix.sh ] && source ~/.nix-profile/etc/profile.d/nix.sh' >> $$rc; \
			fi; \
		fi; \
	done

# Install Homebrew on Linux
install-homebrew-linux:
ifeq ($(IS_LINUX),true)
	@echo -e "${BLUE}ℹ${NC} Installing Homebrew for Linux..."
	@if command -v brew &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Homebrew already installed ($$(brew --version | head -1))"; \
	else \
		echo "  Installing dependencies..."; \
		if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y build-essential procps curl file git 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf groupinstall -y 'Development Tools' 2>&1 | tee -a $(LOG_FILE); \
			$(SUDO) dnf install -y procps-ng curl file git 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo "  Downloading Homebrew installer..."; \
		curl -fsSL $(HOMEBREW_INSTALLER) -o /tmp/install-brew.sh; \
		echo "  Running installer..."; \
		NONINTERACTIVE=1 bash /tmp/install-brew.sh 2>&1 | tee -a $(LOG_FILE); \
		rm -f /tmp/install-brew.sh; \
		echo "  Configuring Homebrew in shell..."; \
		test -d ~/.linuxbrew && eval "$$(~/.linuxbrew/bin/brew shellenv)"; \
		test -d /home/linuxbrew/.linuxbrew && eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; \
		for rc in ~/.bashrc ~/.zshrc; do \
			if [ -f $$rc ] && ! grep -q "linuxbrew" $$rc; then \
				echo "" >> $$rc; \
				echo '# Homebrew on Linux' >> $$rc; \
				echo 'test -d ~/.linuxbrew && eval "$$(~/.linuxbrew/bin/brew shellenv)"' >> $$rc; \
				echo 'test -d /home/linuxbrew/.linuxbrew && eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $$rc; \
			fi; \
		done; \
		echo -e "${GREEN}✓${NC} Homebrew installed"; \
	fi
else
	@echo -e "${BLUE}ℹ${NC} Skipping Homebrew installation (not Linux)"
endif

# Install Flatpak
install-flatpak:
ifeq ($(IS_LINUX),true)
	@echo -e "${BLUE}ℹ${NC} Installing Flatpak..."
	@if command -v flatpak &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Flatpak already installed ($$(flatpak --version))"; \
	else \
		if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y flatpak 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y flatpak 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo "  Adding Flathub repository..."; \
		$(SUDO) flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} Flatpak installed"; \
	fi
else
	@echo -e "${BLUE}ℹ${NC} Skipping Flatpak (not Linux)"
endif

# Install Snap
install-snap:
ifeq ($(PACKAGE_MANAGER),apt)
	@echo -e "${BLUE}ℹ${NC} Installing Snap..."
	@if command -v snap &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Snap already installed ($$(snap version | head -1))"; \
	else \
		$(SUDO) apt install -y snapd 2>&1 | tee -a $(LOG_FILE); \
		$(SUDO) systemctl enable --now snapd.socket 2>&1 | tee -a $(LOG_FILE); \
		$(SUDO) ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true; \
		echo -e "${GREEN}✓${NC} Snap installed"; \
		echo -e "${YELLOW}⚠${NC} You may need to log out and back in for snap to work properly"; \
	fi
else ifeq ($(PACKAGE_MANAGER),dnf)
	@echo -e "${BLUE}ℹ${NC} Installing Snap..."
	@if command -v snap &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Snap already installed"; \
	else \
		$(SUDO) dnf install -y snapd 2>&1 | tee -a $(LOG_FILE); \
		$(SUDO) systemctl enable --now snapd.socket 2>&1 | tee -a $(LOG_FILE); \
		$(SUDO) ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true; \
		echo -e "${GREEN}✓${NC} Snap installed"; \
	fi
else
	@echo -e "${BLUE}ℹ${NC} Skipping Snap (not supported on $(PACKAGE_MANAGER))"
endif

# Install additional package management tools
install-package-tools:
	@echo -e "${BLUE}ℹ${NC} Installing package management tools..."
	@# AppImage support
ifeq ($(IS_LINUX),true)
	@echo "  Installing AppImage support..."
	@if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
		$(SUDO) apt install -y libfuse2 2>&1 | tee -a $(LOG_FILE) || true; \
	elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
		$(SUDO) dnf install -y fuse-libs 2>&1 | tee -a $(LOG_FILE) || true; \
	fi
endif
	@# mise (formerly rtx) - universal version manager
	@echo "  Installing mise (universal version manager)..."
	@if ! command -v mise &> /dev/null; then \
		curl https://mise.run | sh 2>&1 | tee -a $(LOG_FILE) || \
			echo -e "${YELLOW}⚠${NC} mise installation failed"; \
		for rc in ~/.bashrc ~/.zshrc; do \
			if [ -f $$rc ] && ! grep -q "mise activate" $$rc; then \
				echo 'eval "$$(~/.local/bin/mise activate bash)"' >> $$rc; \
			fi; \
		done; \
	else \
		echo -e "${GREEN}✓${NC} mise already installed"; \
	fi
	@# proto - next-gen version manager
	@echo "  Installing proto..."
	@if ! command -v proto &> /dev/null; then \
		curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes 2>&1 | tee -a $(LOG_FILE) || \
			echo -e "${YELLOW}⚠${NC} proto installation failed"; \
	else \
		echo -e "${GREEN}✓${NC} proto already installed"; \
	fi
	@echo -e "${GREEN}✓${NC} Package tools installed"

# Verify package managers
verify-package-managers:
	@echo -e "${BLUE}ℹ${NC} Verifying package managers..."
	@# System package manager
	@echo -e "  System: $(PACKAGE_MANAGER)"
	@# Nix
	@if [ -d /nix ] || command -v nix &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Nix installed"; \
	else \
		echo -e "  ${YELLOW}⚠${NC} Nix not installed"; \
	fi
	@# Homebrew (Linux)
	@if [ "$(IS_LINUX)" = "true" ] && command -v brew &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Homebrew for Linux installed"; \
	elif [ "$(IS_LINUX)" = "true" ]; then \
		echo -e "  ${YELLOW}⚠${NC} Homebrew for Linux not installed"; \
	fi
	@# Flatpak
	@if command -v flatpak &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Flatpak installed"; \
		echo "    Remotes: $$(flatpak remotes | wc -l)"; \
	else \
		echo -e "  ${YELLOW}⚠${NC} Flatpak not installed"; \
	fi
	@# Snap
	@if command -v snap &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Snap installed"; \
	else \
		echo -e "  ${YELLOW}⚠${NC} Snap not installed"; \
	fi
	@# mise
	@if command -v mise &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} mise installed"; \
	else \
		echo -e "  ${YELLOW}⚠${NC} mise not installed"; \
	fi
	$(call show_completion_banner,PACKAGE MGRS READY)
	@echo -e "${GREEN}✓${NC} Package manager verification complete"

# Update all package managers
update-package-managers:
	@echo -e "${BLUE}ℹ${NC} Updating package managers..."
	@# System package manager
	@echo "  Updating system packages..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt update && $(SUDO) apt upgrade -y 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(PACKAGE_MANAGER),dnf)
	@$(SUDO) dnf upgrade -y 2>&1 | tee -a $(LOG_FILE)
endif
	@# Nix
	@if command -v nix &> /dev/null; then \
		echo "  Updating Nix channels..."; \
		nix-channel --update 2>&1 | tee -a $(LOG_FILE) || true; \
	fi
	@# Homebrew
	@if command -v brew &> /dev/null; then \
		echo "  Updating Homebrew..."; \
		brew update && brew upgrade 2>&1 | tee -a $(LOG_FILE); \
	fi
	@# Flatpak
	@if command -v flatpak &> /dev/null; then \
		echo "  Updating Flatpak apps..."; \
		flatpak update -y 2>&1 | tee -a $(LOG_FILE); \
	fi
	@# Snap
	@if command -v snap &> /dev/null; then \
		echo "  Updating Snap packages..."; \
		$(SUDO) snap refresh 2>&1 | tee -a $(LOG_FILE); \
	fi
	@echo -e "${GREEN}✓${NC} Package managers updated"

# Clean package manager caches
clean-package-managers:
	@echo -e "${YELLOW}⚠${NC} Cleaning package manager caches..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt autoremove -y && $(SUDO) apt autoclean
else ifeq ($(PACKAGE_MANAGER),dnf)
	@$(SUDO) dnf clean all
endif
	@if command -v brew &> /dev/null; then brew cleanup; fi
	@if command -v nix &> /dev/null; then nix-collect-garbage -d 2>/dev/null || true; fi
	@echo -e "${GREEN}✓${NC} Package manager cleanup complete"

# Help for package managers module
help-package-managers:
	@echo "ArmyknifeLabs Package Managers Module"
	@echo ""
	@echo "Targets:"
	@echo "  all                    - Install all package managers"
	@echo "  install-nix            - Install Nix package manager"
	@echo "  install-homebrew-linux - Install Homebrew on Linux"
	@echo "  install-flatpak        - Install Flatpak"
	@echo "  install-snap           - Install Snap"
	@echo "  configure-repositories - Configure system repositories"
	@echo "  verify-package-managers - Verify installations"
	@echo "  update-package-managers - Update all package managers"
	@echo "  clean-package-managers  - Clean package caches"
	@echo ""
	@echo "Detected:"
	@echo "  OS: $(OS_TYPE)"
	@echo "  Package Manager: $(PACKAGE_MANAGER)"
	@echo "  Architecture: $(ARCH)"