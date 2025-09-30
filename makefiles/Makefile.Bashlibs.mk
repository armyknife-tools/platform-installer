# ArmyknifeLabs Platform Installer - Bash Libraries Module
# Makefile.Bashlibs.mk
#
# Creates a comprehensive bash library structure for all installed tools
# Provides functions, aliases, and utilities for enhanced developer experience

# Import parent variables
ARMYKNIFE_DIR ?= $(HOME)/.armyknife
BASHLIB_DIR := $(ARMYKNIFE_DIR)/bashlib
LIB_DIR := $(BASHLIB_DIR)/lib
BIN_DIR := $(BASHLIB_DIR)/bin

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m

# Phony targets
.PHONY: all setup-bashlibs verify-bashlibs clean-bashlibs help-bashlibs

# Main target
all: setup-bashlibs

# Setup complete bashlib structure using the shell script
setup-bashlibs:
	@echo -e "${BLUE}ℹ${NC} Setting up ArmyknifeLabs bash libraries..."
	@chmod +x scripts/setup-bashlibs.sh
	@scripts/setup-bashlibs.sh
	$(call show_completion_banner,BASH LIBS READY)
	@echo -e "${GREEN}✓${NC} Bash libraries setup complete!"
	@echo ""
	@echo "To activate the bash libraries, run:"
	@echo "  source ~/.bashrc  (or ~/.zshrc)"
	@echo ""
	@echo "Then try these commands:"
	@echo "  ak_help          - See all available functions"
	@echo "  git-workflow     - Interactive git helper"
	@echo "  docker-helper    - Docker management tool"
	@echo "  syscheck         - System information report"

# Verify bashlibs installation
verify-bashlibs:
	@echo -e "${BLUE}ℹ${NC} Verifying bash libraries..."
	@if [ -d $(BASHLIB_DIR) ]; then \
		echo -e "  ${GREEN}✓${NC} Bashlib directory exists"; \
	else \
		echo -e "  ${RED}✗${NC} Bashlib directory missing"; \
	fi
	@if [ -f $(LIB_DIR)/main.sh ]; then \
		echo -e "  ${GREEN}✓${NC} Main library exists"; \
	else \
		echo -e "  ${RED}✗${NC} Main library missing"; \
	fi
	@count=$$(ls -1 $(LIB_DIR)/*.sh 2>/dev/null | wc -l); \
	echo -e "  ${GREEN}✓${NC} $$count library files found"
	@count=$$(ls -1 $(BIN_DIR)/* 2>/dev/null | wc -l); \
	echo -e "  ${GREEN}✓${NC} $$count executable scripts found"
	@if grep -q "ArmyknifeLabs Bash Libraries" ~/.bashrc 2>/dev/null || \
	   grep -q "ArmyknifeLabs Bash Libraries" ~/.zshrc 2>/dev/null; then \
		echo -e "  ${GREEN}✓${NC} Shell configuration updated"; \
	else \
		echo -e "  ${YELLOW}⚠${NC} Shell configuration not updated"; \
	fi
	@echo -e "${GREEN}✓${NC} Verification complete"

# Clean bashlibs
clean-bashlibs:
	@echo -e "${YELLOW}⚠${NC} Removing bash libraries..."
	@rm -rf $(BASHLIB_DIR)
	@echo -e "${GREEN}✓${NC} Bash libraries removed"

# Help for bashlibs
help-bashlibs:
	@echo "ArmyknifeLabs Bash Libraries Module"
	@echo ""
	@echo "This module creates a comprehensive bash library system for all installed tools,"
	@echo "providing functions, aliases, and utilities for enhanced developer experience."
	@echo ""
	@echo "Targets:"
	@echo "  make bashlibs        - Create and install complete bash library system"
	@echo "  make verify-bashlibs - Verify installation"
	@echo "  make clean-bashlibs  - Remove bash libraries"
	@echo "  make help-bashlibs   - Show this help"
	@echo ""
	@echo "Libraries created:"
	@echo "  - Core functions (logging, utilities)"
	@echo "  - Git workflows and shortcuts"
	@echo "  - Docker & container management"
	@echo "  - Kubernetes operations"
	@echo "  - Cloud provider tools (AWS, Azure, GCP)"
	@echo "  - Programming languages (Python, Node, Go, Rust)"
	@echo "  - Shell tools (fzf, ripgrep, bat)"
	@echo "  - Security utilities"
	@echo "  - Network tools"
	@echo "  - General utilities"
	@echo ""
	@echo "Example scripts:"
	@echo "  - git-workflow    : Interactive git helper"
	@echo "  - docker-helper   : Docker management tool"
	@echo "  - syscheck        : System information report"
	@echo ""
	@echo "Functions are organized by category and prefixed for easy discovery:"
	@echo "  - ak_*  : Core ArmyknifeLabs functions"
	@echo "  - g*    : Git shortcuts (gst, glg, gpush, etc.)"
	@echo "  - d*    : Docker shortcuts (dps, dex, dlogs, etc.)"
	@echo "  - k*    : Kubernetes shortcuts (kpods, kexec, etc.)"
	@echo "  - f*    : FZF-powered functions (fo, fd, fkill, etc.)"