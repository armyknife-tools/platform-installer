# ArmyknifeLabs Platform Installer - Main Orchestrator
# https://github.com/armyknife-tools/platform-installer
#
# The Ultimate Software Development Workstation Setup System
# Supports: Ubuntu/Debian, Fedora/RHEL 9+, macOS (Intel & Apple Silicon)
#
# Usage:
#   make              # Show help
#   make minimal      # Base system + shell only (~15 min)
#   make standard     # Common developer tools (~45 min, recommended)
#   make full         # Everything including VMs and cloud tools (~90 min)
#   make custom       # Interactive component selection
#   make verify       # Verify installation
#   make doctor       # Diagnose issues
#   make update       # Update all components
#   make uninstall    # Remove ArmyknifeLabs Platform

# Version and metadata
ARMYKNIFE_VERSION := 1.0.0
ARMYKNIFE_DIR := $(HOME)/.armyknife
LOG_DIR := $(ARMYKNIFE_DIR)/logs
LOG_FILE := $(LOG_DIR)/install-$(shell date +%Y%m%d-%H%M%S).log

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Shell configuration
SHELL := /bin/bash
.SHELLFLAGS := -ec

# Export variables for sub-makefiles
export ARMYKNIFE_VERSION
export ARMYKNIFE_DIR
export LOG_DIR
export LOG_FILE

# Default goal
.DEFAULT_GOAL := help

# Detect if running in CI/non-interactive mode
ifdef CI
    export ARMYKNIFE_NON_INTERACTIVE := 1
endif

# Include all sub-makefiles
-include makefiles/Makefile.Base.mk
-include makefiles/Makefile.Shell.mk
-include makefiles/Makefile.PackageMgrs.mk
-include makefiles/Makefile.Languages.mk
-include makefiles/Makefile.ShellTools.mk
-include makefiles/Makefile.Git.mk
-include makefiles/Makefile.Security.mk
-include makefiles/Makefile.Containers.mk
-include makefiles/Makefile.Virtualization.mk
-include makefiles/Makefile.Network.mk
-include makefiles/Makefile.Cloud.mk
-include makefiles/Makefile.Extras.mk

# Phony targets
.PHONY: all banner help minimal standard full custom verify doctor update uninstall clean
.PHONY: init-dirs init-logs backup-configs

# Banner display
banner:
	@echo ""
	@echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
	@echo -e "${PURPLE}║                                                           ║${NC}"
	@echo -e "${PURPLE}║         ArmyknifeLabs Platform Installer v$(ARMYKNIFE_VERSION)            ║${NC}"
	@echo -e "${PURPLE}║                                                           ║${NC}"
	@echo -e "${PURPLE}║     The Ultimate Software Development Workstation         ║${NC}"
	@echo -e "${PURPLE}║                                                           ║${NC}"
	@echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"
	@echo ""

# Initialize directories
init-dirs:
	@mkdir -p $(ARMYKNIFE_DIR)/{lib,config,bin,logs,backups}
	@mkdir -p $(LOG_DIR)

# Initialize logging
init-logs: init-dirs
	@echo "[$(shell date +'%Y-%m-%d %H:%M:%S')] ArmyknifeLabs Platform Installation Started" >> $(LOG_FILE)
	@echo "Version: $(ARMYKNIFE_VERSION)" >> $(LOG_FILE)
	@echo "OS: $(shell uname -s)" >> $(LOG_FILE)
	@echo "Architecture: $(shell uname -m)" >> $(LOG_FILE)
	@echo "User: $(USER)" >> $(LOG_FILE)
	@echo "Home: $(HOME)" >> $(LOG_FILE)
	@echo "" >> $(LOG_FILE)

# Backup existing configurations
backup-configs: init-dirs
	@echo -e "${BLUE}ℹ${NC} Backing up existing configurations..."
	@if [ -f ~/.bashrc ]; then cp ~/.bashrc $(ARMYKNIFE_DIR)/backups/.bashrc.backup-$(shell date +%s) 2>/dev/null || true; fi
	@if [ -f ~/.zshrc ]; then cp ~/.zshrc $(ARMYKNIFE_DIR)/backups/.zshrc.backup-$(shell date +%s) 2>/dev/null || true; fi
	@if [ -f ~/.gitconfig ]; then cp ~/.gitconfig $(ARMYKNIFE_DIR)/backups/.gitconfig.backup-$(shell date +%s) 2>/dev/null || true; fi

# Installation profiles
all: banner full

# Minimal: Just base system + shell
minimal: banner init-logs backup-configs
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@echo -e "${CYAN} Starting Minimal Installation${NC}"
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@$(MAKE) -f makefiles/Makefile.Base.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Shell.mk all 2>&1 | tee -a $(LOG_FILE)
	@echo ""
	@echo -e "${GREEN}✓${NC} ArmyknifeLabs Platform - Minimal installation complete!"
	@echo ""
	@$(MAKE) post-install-message

# Standard: Common developer setup (no VMs, minimal cloud)
standard: banner init-logs backup-configs
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@echo -e "${CYAN} Starting Standard Installation (Recommended)${NC}"
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@$(MAKE) -f makefiles/Makefile.Base.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Shell.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.PackageMgrs.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Languages.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.ShellTools.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Git.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Security.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Containers.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Network.mk minimal 2>&1 | tee -a $(LOG_FILE)
	@echo ""
	@echo -e "${GREEN}✓${NC} ArmyknifeLabs Platform - Standard installation complete!"
	@echo ""
	@$(MAKE) post-install-message

# Full: Everything including VMs and all cloud tools
full: banner init-logs backup-configs
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@echo -e "${CYAN} Starting Full Installation (Everything)${NC}"
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@$(MAKE) -f makefiles/Makefile.Base.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Shell.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.PackageMgrs.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Languages.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.ShellTools.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Git.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Security.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Containers.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Virtualization.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Network.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Cloud.mk all 2>&1 | tee -a $(LOG_FILE)
	@echo ""
	@echo -e "${GREEN}✓${NC} ArmyknifeLabs Platform - Full installation complete!"
	@echo ""
	@echo "🎉 Your ultimate development workstation is ready!"
	@echo ""
	@$(MAKE) post-install-message

# Custom: User selects components interactively
custom: banner init-logs
	@echo -e "${CYAN}=== ArmyknifeLabs Custom Installation ===${NC}"
	@echo "Select components to install:"
	@./scripts/interactive-install.sh

# Help target
help: banner
	@echo "Usage: make [target]"
	@echo ""
	@echo -e "${CYAN}Installation Profiles:${NC}"
	@echo "  minimal      - Base system + shell only (~15 min)"
	@echo "  standard     - Common developer tools (~45 min, ${GREEN}recommended${NC})"
	@echo "  full         - Everything including VMs and cloud tools (~90 min)"
	@echo "  custom       - Interactive component selection"
	@echo ""
	@echo -e "${CYAN}Individual Components:${NC}"
	@echo "  base         - OS updates, build tools, compiler toolchain"
	@echo "  shell        - Oh-My-Bash/Zsh with modern prompt"
	@echo "  package-mgrs - Enhanced package managers (Nix, etc.)"
	@echo "  languages    - Python, Node, Go, Rust, Java version managers"
	@echo "  shell-tools  - Terminal enhancements (fzf, bat, ripgrep, etc.)"
	@echo "  git          - Git and GitHub ecosystem"
	@echo "  security     - Encryption, GPG, password managers"
	@echo "  containers   - Docker, Podman, Kubernetes"
	@echo "  virtualization - VirtualBox, Vagrant, Packer"
	@echo "  network      - Tailscale VPN, fleet management"
	@echo "  cloud        - AWS, Azure, GCP, Linode CLIs"
	@echo ""
	@echo -e "${CYAN}Utility Commands:${NC}"
	@echo "  verify       - Verify all installed components"
	@echo "  update       - Update all installed components"
	@echo "  clean        - Remove installation artifacts"
	@echo "  uninstall    - Remove all ArmyknifeLabs components"
	@echo "  doctor       - Diagnose installation issues"
	@echo ""
	@echo -e "${CYAN}Documentation:${NC}"
	@echo "  docs/README.md           - Full documentation"
	@echo "  docs/USAGE.md            - Command reference"
	@echo "  docs/TROUBLESHOOTING.md  - Common issues and solutions"
	@echo ""
	@echo -e "${CYAN}Examples:${NC}"
	@echo "  make standard              # Recommended for most users"
	@echo "  make base shell languages  # Custom component selection"
	@echo "  make -j4 languages shell-tools  # Parallel installation"
	@echo ""

# Post-installation message
post-install-message:
	@echo "Next steps:"
	@echo "  1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
	@echo "  2. Run 'make verify' to validate installation"
	@echo "  3. Check $(LOG_DIR) for detailed logs"
	@echo ""
	@echo "Quick commands:"
	@echo "  armyknife help    - Show all commands"
	@echo "  ak update         - Update components"
	@echo "  ak doctor         - Diagnose issues"
	@echo ""

# Verification
verify:
	@echo -e "${BLUE}ℹ${NC} Verifying ArmyknifeLabs Platform installation..."
	@./scripts/verify-install.sh

# Doctor - Diagnose issues
doctor:
	@echo -e "${BLUE}ℹ${NC} Running ArmyknifeLabs Platform diagnostics..."
	@./scripts/doctor.sh

# Update all components
update:
	@echo -e "${BLUE}ℹ${NC} Updating ArmyknifeLabs Platform components..."
	@$(MAKE) -f makefiles/Makefile.Base.mk update-system 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Languages.mk update-languages 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Containers.mk update-containers 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Cloud.mk update-cloud-tools 2>&1 | tee -a $(LOG_FILE)
	@echo -e "${GREEN}✓${NC} All components updated!"

# Clean installation artifacts
clean:
	@echo -e "${YELLOW}⚠${NC} Cleaning ArmyknifeLabs installation artifacts..."
	@rm -rf $(LOG_DIR)/*.log
	@rm -rf /tmp/armyknife-*
	@echo -e "${GREEN}✓${NC} Cleanup complete!"

# Uninstall (with confirmation)
uninstall:
	@echo -e "${RED}⚠ WARNING: This will remove all ArmyknifeLabs components!${NC}"
	@echo "This action cannot be undone."
	@read -p "Are you sure you want to uninstall? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "Uninstalling ArmyknifeLabs Platform..."; \
		./scripts/uninstall.sh; \
	else \
		echo "Uninstall cancelled."; \
	fi

# Individual component targets (for direct access)
base: init-logs
	@$(MAKE) -f makefiles/Makefile.Base.mk all

shell: init-logs
	@$(MAKE) -f makefiles/Makefile.Shell.mk all

package-mgrs: init-logs
	@$(MAKE) -f makefiles/Makefile.PackageMgrs.mk all

languages: init-logs
	@$(MAKE) -f makefiles/Makefile.Languages.mk all

shell-tools: init-logs
	@$(MAKE) -f makefiles/Makefile.ShellTools.mk all

git: init-logs
	@$(MAKE) -f makefiles/Makefile.Git.mk all

security: init-logs
	@$(MAKE) -f makefiles/Makefile.Security.mk all

containers: init-logs
	@$(MAKE) -f makefiles/Makefile.Containers.mk all

virtualization: init-logs
	@$(MAKE) -f makefiles/Makefile.Virtualization.mk all

network: init-logs
	@$(MAKE) -f makefiles/Makefile.Network.mk all

cloud: init-logs
	@$(MAKE) -f makefiles/Makefile.Cloud.mk all

# Testing target (for development)
test:
	@echo "Running ArmyknifeLabs Platform tests..."
	@./tests/run-tests.sh

# Version information
version:
	@echo "ArmyknifeLabs Platform Installer v$(ARMYKNIFE_VERSION)"
	@echo "Repository: https://github.com/armyknife-tools/platform-installer"

# Install specific version of a component
install-%:
	@echo "Installing $*..."
	@$(MAKE) -f makefiles/Makefile.$(shell echo $* | sed 's/-/_/g' | sed 's/\([A-Z]\)/_\L\1/g' | sed 's/^_//').mk install-$*

.SILENT: banner help post-install-message version