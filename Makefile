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
-include makefiles/Makefile.Database.mk
-include makefiles/Makefile.ShellTools.mk
-include makefiles/Makefile.Git.mk
-include makefiles/Makefile.Security.mk
-include makefiles/Makefile.Containers.mk
-include makefiles/Makefile.Virtualization.mk
-include makefiles/Makefile.Network.mk
-include makefiles/Makefile.Cloud.mk
-include makefiles/Makefile.AI-Assistants.mk
-include makefiles/Makefile.Bashlibs.mk
-include makefiles/Makefile.Extras.mk

# Phony targets
.PHONY: all banner help minimal standard full custom menu verify doctor update uninstall clean
.PHONY: init-dirs init-logs backup-configs
.PHONY: base shell package-mgrs languages databases shell-tools git security
.PHONY: containers virtualization network cloud ai-assistants bashlibs
.PHONY: install-base install-shell install-package-mgrs install-languages
.PHONY: install-databases install-shell-tools install-git-tools install-security
.PHONY: install-containers install-vms install-network install-cloud
.PHONY: install-ai-tools install-bashlibs

# Banner display with figlet
banner:
	@echo ""
	@if command -v figlet &> /dev/null; then \
		echo -e "${PURPLE}"; \
		figlet -f slant "ArmyknifeLabs" 2>/dev/null || figlet "ArmyknifeLabs"; \
		echo -e "${NC}"; \
		echo -e "${CYAN}         Platform Installer v$(ARMYKNIFE_VERSION)${NC}"; \
		echo -e "${BLUE}    The Ultimate Software Development Workstation${NC}"; \
	else \
		echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"; \
		echo -e "${PURPLE}║                                                           ║${NC}"; \
		echo -e "${PURPLE}║         ArmyknifeLabs Platform Installer v$(ARMYKNIFE_VERSION)            ║${NC}"; \
		echo -e "${PURPLE}║                                                           ║${NC}"; \
		echo -e "${PURPLE}║     The Ultimate Software Development Workstation         ║${NC}"; \
		echo -e "${PURPLE}║                                                           ║${NC}"; \
		echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"; \
	fi
	@echo ""
	@echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

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
	@$(MAKE) -f makefiles/Makefile.Database.mk minimal 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.ShellTools.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Git.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Security.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Containers.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Network.mk minimal 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.AI-Assistants.mk minimal 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Bashlibs.mk all 2>&1 | tee -a $(LOG_FILE)
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
	@$(MAKE) -f makefiles/Makefile.Database.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.ShellTools.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Git.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Security.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Containers.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Virtualization.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Network.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Cloud.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.AI-Assistants.mk all 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) -f makefiles/Makefile.Bashlibs.mk all 2>&1 | tee -a $(LOG_FILE)
	@echo ""
	@echo -e "${GREEN}✓${NC} ArmyknifeLabs Platform - Full installation complete!"
	@echo ""
	@echo "🎉 Your ultimate development workstation is ready!"
	@echo ""
	@$(MAKE) post-install-message

# Interactive menu for component selection
menu: banner init-logs
	@./scripts/interactive-menu.sh

# Alias for backwards compatibility
custom: menu

# Help target - Enhanced menu with categories
help: banner
	@echo "Usage: make [target]"
	@echo ""
	@echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
	@echo -e "${GREEN}│              📦 INSTALLATION PROFILES                   │${NC}"
	@echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
	@echo -e "  ${CYAN}minimal${NC}      ${BLUE}➜${NC} Base system + shell only (~15 min)"
	@echo -e "  ${CYAN}standard${NC}     ${BLUE}➜${NC} Common developer tools (~45 min) ${GREEN}[RECOMMENDED]${NC}"
	@echo -e "  ${CYAN}full${NC}         ${BLUE}➜${NC} Everything including VMs and cloud (~90 min)"
	@echo -e "  ${CYAN}menu${NC}         ${BLUE}➜${NC} ${YELLOW}Interactive menu for component selection${NC}"
	@echo ""
	@echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
	@echo -e "${GREEN}│              🔧 BASE COMPONENTS                         │${NC}"
	@echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
	@echo -e "  ${CYAN}install-base${NC}         ${BLUE}➜${NC} OS updates, build tools, compilers"
	@echo -e "  ${CYAN}install-shell${NC}        ${BLUE}➜${NC} Oh-My-Bash/Zsh, Starship prompt"
	@echo -e "  ${CYAN}install-package-mgrs${NC} ${BLUE}➜${NC} Nix, Homebrew, enhanced managers"
	@echo ""
	@echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
	@echo -e "${GREEN}│              💻 DEVELOPMENT TOOLS                       │${NC}"
	@echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
	@echo -e "  ${CYAN}install-languages${NC}    ${BLUE}➜${NC} Python, Node.js, Go, Rust, Java"
	@echo -e "  ${CYAN}install-databases${NC}    ${BLUE}➜${NC} PostgreSQL, MySQL, MongoDB, Redis"
	@echo -e "  ${CYAN}install-shell-tools${NC}  ${BLUE}➜${NC} fzf, bat, ripgrep, exa, zoxide"
	@echo -e "  ${CYAN}install-git-tools${NC}    ${BLUE}➜${NC} Git, GitHub CLI, git-flow, delta"
	@echo ""
	@echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
	@echo -e "${GREEN}│              🐳 INFRASTRUCTURE                          │${NC}"
	@echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
	@echo -e "  ${CYAN}install-containers${NC}   ${BLUE}➜${NC} Docker, Podman, Kubernetes tools"
	@echo -e "  ${CYAN}install-vms${NC}          ${BLUE}➜${NC} VirtualBox, Vagrant, Packer"
	@echo -e "  ${CYAN}install-network${NC}      ${BLUE}➜${NC} Tailscale, Saltstack, monitoring"
	@echo -e "  ${CYAN}install-cloud${NC}        ${BLUE}➜${NC} AWS, Azure, GCP, Linode CLIs"
	@echo ""
	@echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
	@echo -e "${GREEN}│              🤖 AI & EDITORS                            │${NC}"
	@echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
	@echo -e "  ${CYAN}install-ai-tools${NC}     ${BLUE}➜${NC} VS Code, Cursor, Windsurf, AI tools"
	@echo -e "  ${CYAN}install-vscode${NC}       ${BLUE}➜${NC} Visual Studio Code only"
	@echo -e "  ${CYAN}install-cursor${NC}       ${BLUE}➜${NC} Cursor IDE only"
	@echo -e "  ${CYAN}install-windsurf${NC}     ${BLUE}➜${NC} Windsurf IDE only"
	@echo ""
	@echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
	@echo -e "${GREEN}│              🛠️  MAINTENANCE                             │${NC}"
	@echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
	@echo -e "  ${CYAN}verify${NC}       ${BLUE}➜${NC} Verify all installed components"
	@echo -e "  ${CYAN}update${NC}       ${BLUE}➜${NC} Update all installed components"
	@echo -e "  ${CYAN}doctor${NC}       ${BLUE}➜${NC} Diagnose installation issues"
	@echo -e "  ${CYAN}clean${NC}        ${BLUE}➜${NC} Remove installation artifacts"
	@echo -e "  ${CYAN}uninstall${NC}    ${BLUE}➜${NC} Remove all ArmyknifeLabs components"
	@echo ""
	@echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@echo -e "${BLUE}Examples:${NC}"
	@echo "  make menu                        # Interactive selection"
	@echo "  make standard                    # Recommended setup"
	@echo "  make install-languages install-databases  # Specific components"
	@echo "  make -j4 install-shell-tools     # Parallel installation"
	@echo ""
	@echo -e "${BLUE}Type '${CYAN}make menu${BLUE}' for interactive component selection${NC}"

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
base install-base: init-logs
	@$(MAKE) -f makefiles/Makefile.Base.mk all

shell install-shell: init-logs
	@$(MAKE) -f makefiles/Makefile.Shell.mk all

package-mgrs install-package-mgrs: init-logs
	@$(MAKE) -f makefiles/Makefile.PackageMgrs.mk all

languages install-languages: init-logs
	@$(MAKE) -f makefiles/Makefile.Languages.mk all

databases install-databases: init-logs
	@$(MAKE) -f makefiles/Makefile.Database.mk all

shell-tools install-shell-tools: init-logs
	@$(MAKE) -f makefiles/Makefile.ShellTools.mk all

git install-git-tools: init-logs
	@$(MAKE) -f makefiles/Makefile.Git.mk all

security install-security: init-logs
	@$(MAKE) -f makefiles/Makefile.Security.mk all

containers install-containers: init-logs
	@$(MAKE) -f makefiles/Makefile.Containers.mk all

virtualization install-vms: init-logs
	@$(MAKE) -f makefiles/Makefile.Virtualization.mk all

network install-network: init-logs
	@$(MAKE) -f makefiles/Makefile.Network.mk all

cloud install-cloud: init-logs
	@$(MAKE) -f makefiles/Makefile.Cloud.mk all

ai-assistants install-ai-tools: init-logs
	@$(MAKE) -f makefiles/Makefile.AI-Assistants.mk all

bashlibs install-bashlibs: init-logs
	@$(MAKE) -f makefiles/Makefile.Bashlibs.mk all


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