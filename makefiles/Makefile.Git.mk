# ArmyknifeLabs Platform Installer - Git Ecosystem Module
# Makefile.Git.mk

ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-$(shell date +%Y%m%d-%H%M%S).log

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

# Shell configuration - use bash for all commands
SHELL := /bin/bash
.SHELLFLAGS := -ec

# OS detection
OS_TYPE := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo macos)
IS_MACOS := $(shell if [ "$$(uname -s)" = "Darwin" ]; then echo true; else echo false; fi)
PACKAGE_MANAGER := $(if $(filter ubuntu debian linuxmint,$(OS_TYPE)),apt,$(if $(filter fedora rhel,$(OS_TYPE)),dnf,brew))
SUDO := $(if $(IS_MACOS),,sudo)

.PHONY: all install-git-tools configure-git verify-git

all: install-git-tools configure-git verify-git

install-git-tools:
	@echo -e "${BLUE}ℹ${NC} Installing Git ecosystem tools..."
	@# GitHub CLI
	@if ! command -v gh &> /dev/null; then \
		echo "  Installing GitHub CLI..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install gh; \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $(SUDO) dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg; \
			echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $(SUDO) tee /etc/apt/sources.list.d/github-cli.list; \
			$(SUDO) apt update && $(SUDO) apt install -y gh; \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y gh; \
		fi; \
	fi
	@# lazygit
	@if ! command -v lazygit &> /dev/null; then \
		echo "  Installing lazygit..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install lazygit; \
		elif command -v go &> /dev/null; then \
			go install github.com/jesseduffield/lazygit@latest; \
		fi; \
	fi
	@# delta
	@if ! command -v delta &> /dev/null; then \
		echo "  Installing delta..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install git-delta; \
		elif command -v cargo &> /dev/null; then \
			cargo install git-delta; \
		fi; \
	fi
	@# gitleaks
	@if ! command -v gitleaks &> /dev/null; then \
		echo "  Installing gitleaks..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install gitleaks; \
		elif command -v go &> /dev/null; then \
			go install github.com/gitleaks/gitleaks/v8@latest; \
		fi; \
	fi
	@# tig
	@if ! command -v tig &> /dev/null; then \
		if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y tig; \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y tig; \
		elif [ "$(IS_MACOS)" = "true" ]; then \
			brew install tig; \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Git tools installed"

configure-git:
	@echo -e "${BLUE}ℹ${NC} Configuring Git..."
	@git config --global init.defaultBranch main 2>/dev/null || true
	@git config --global core.editor "$${EDITOR:-vim}" 2>/dev/null || true
	@git config --global pull.rebase false 2>/dev/null || true
	@git config --global fetch.prune true 2>/dev/null || true
	@git config --global diff.colorMoved zebra 2>/dev/null || true
	@if command -v delta &> /dev/null; then \
		git config --global core.pager delta; \
		git config --global interactive.diffFilter "delta --color-only"; \
	fi
	@# Git aliases
	@git config --global alias.st status 2>/dev/null || true
	@git config --global alias.co checkout 2>/dev/null || true
	@git config --global alias.br branch 2>/dev/null || true
	@git config --global alias.ci commit 2>/dev/null || true
	@git config --global alias.unstage "reset HEAD --" 2>/dev/null || true
	@git config --global alias.last "log -1 HEAD" 2>/dev/null || true
	@git config --global alias.visual "!gitk" 2>/dev/null || true
	@echo -e "${GREEN}✓${NC} Git configured"

verify-git:
	@echo -e "${BLUE}ℹ${NC} Verifying Git tools..."
	@for tool in git gh lazygit delta gitleaks tig; do \
		if command -v $$tool &> /dev/null; then \
			echo -e "  ${GREEN}✓${NC} $$tool installed"; \
		else \
			echo -e "  ${YELLOW}⚠${NC} $$tool not found"; \
		fi; \
	done
	$(call show_completion_banner,GIT READY)
	@echo -e "${GREEN}✓${NC} Git verification complete"