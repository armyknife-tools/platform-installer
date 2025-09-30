# ArmyknifeLabs Platform Installer - AI Code Assistants Module
# Makefile.AI-Assistants.mk
#
# Comprehensive AI-powered development environment setup
# Installs: VS Code, Cursor, Windsurf, Continue, and other AI coding assistants
# Features: GPG key management, extension installation, configuration

# Import parent variables
ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-ai-assistants-$(shell date +%Y%m%d-%H%M%S).log
AI_DIR := $(ARMYKNIFE_DIR)/ai-assistants

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m

# Shell configuration
SHELL := /bin/bash
.SHELLFLAGS := -ec

# OS detection
OS_TYPE := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo macos)
OS_LIKE := $(shell . /etc/os-release 2>/dev/null && echo $$ID_LIKE || echo "")
IS_MACOS := $(shell if [ "$$(uname -s)" = "Darwin" ]; then echo true; else echo false; fi)
IS_LINUX := $(shell if [ "$$(uname -s)" = "Linux" ]; then echo true; else echo false; fi)
ARCH := $(shell uname -m)

# Package manager detection
ifeq ($(OS_TYPE),ubuntu)
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifeq ($(OS_TYPE),linuxmint)
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifeq ($(OS_TYPE),debian)
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifneq (,$(findstring ubuntu,$(OS_LIKE)))
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifneq (,$(findstring debian,$(OS_LIKE)))
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifeq ($(OS_TYPE),fedora)
    PACKAGE_MANAGER := dnf
    SUDO := sudo
else ifeq ($(IS_MACOS),true)
    PACKAGE_MANAGER := brew
    SUDO :=
endif

# URLs for downloads
VSCODE_URL := https://code.visualstudio.com/sha/download?build=stable&os=linux-x64
CURSOR_URL := https://downloader.cursor.sh/linux/appImage/x64
WINDSURF_URL := https://windsurf.com/download/editor?os=linux
WINDSURF_GPG := https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg
CONTINUE_URL := https://continue.dev/install.sh
ZEDITOR_URL := https://zed.dev/install.sh

# GPG Keys
VSCODE_GPG_KEY := https://packages.microsoft.com/keys/microsoft.asc
CURSOR_GPG_KEY := https://downloads.cursor.com/aptrepo/public.gpg.key

# Repository URLs
# Use microsoft.gpg if it exists, otherwise use packages.microsoft.gpg
ifeq ($(PACKAGE_MANAGER),apt)
    MICROSOFT_GPG := $(shell if [ -f /usr/share/keyrings/microsoft.gpg ]; then echo "/usr/share/keyrings/microsoft.gpg"; else echo "/usr/share/keyrings/packages.microsoft.gpg"; fi)
    VSCODE_REPO := "deb [arch=amd64,arm64,armhf signed-by=$(MICROSOFT_GPG)] https://packages.microsoft.com/repos/code stable main"
    CURSOR_REPO := "deb [arch=amd64 signed-by=/usr/share/keyrings/cursor-archive-keyring.gpg] https://downloads.cursor.com/aptrepo stable main"
endif

# Phony targets
.PHONY: all minimal setup-repos install-vscode install-cursor install-cursor-cli \
        install-windsurf install-continue install-zed install-extensions configure-ai \
        install-github-copilot-cli install-codeium-cli verify-ai help-ai

# Main target - install everything
all: setup-repos install-vscode install-cursor install-windsurf install-continue \
     install-zed install-extensions install-github-copilot-cli install-codeium-cli \
     configure-ai verify-ai

# Minimal install - just VS Code and essential AI extensions
minimal: setup-repos install-vscode install-vscode-extensions configure-ai

# Setup repositories and GPG keys
setup-repos:
	@echo -e "${BLUE}Setting up AI assistant repositories...${NC}"
	@mkdir -p $$(dirname $(LOG_FILE))
ifeq ($(PACKAGE_MANAGER),apt)
	@# Microsoft GPG key for VS Code - check both possible locations
	@if [ ! -f /usr/share/keyrings/microsoft.gpg ] && [ ! -f /usr/share/keyrings/packages.microsoft.gpg ]; then \
		echo -e "${YELLOW}Adding Microsoft GPG key...${NC}"; \
		curl -fsSL $(VSCODE_GPG_KEY) | $(SUDO) gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg; \
	fi
	@# Cursor GPG key
	@if [ ! -f /usr/share/keyrings/cursor-archive-keyring.gpg ]; then \
		echo -e "${YELLOW}Adding Cursor GPG key...${NC}"; \
		curl -fsSL $(CURSOR_GPG_KEY) | $(SUDO) gpg --dearmor -o /usr/share/keyrings/cursor-archive-keyring.gpg; \
	fi
	@# Add VS Code repository
	@if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then \
		echo -e "${YELLOW}Adding VS Code repository...${NC}"; \
		echo $(VSCODE_REPO) | $(SUDO) tee /etc/apt/sources.list.d/vscode.list; \
	fi
	@# Fix/Add Cursor repository with proper signing
	@echo -e "${YELLOW}Updating Cursor repository configuration...${NC}"
	@echo $(CURSOR_REPO) | $(SUDO) tee /etc/apt/sources.list.d/cursor.list
	@# Update package lists
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE) || true
endif
	@echo -e "${GREEN}✓${NC} Repositories configured"

# Install VS Code
install-vscode: setup-repos
	@echo -e "${BLUE}Installing Visual Studio Code...${NC}"
ifeq ($(PACKAGE_MANAGER),apt)
	@if command -v code &> /dev/null; then \
		echo -e "${GREEN}✓${NC} VS Code already installed"; \
	else \
		$(SUDO) apt install -y code 2>&1 | tee -a $(LOG_FILE) || { \
			echo -e "${YELLOW}Falling back to direct download...${NC}"; \
			wget -O /tmp/vscode.deb "$(VSCODE_URL)"; \
			$(SUDO) dpkg -i /tmp/vscode.deb || $(SUDO) apt-get install -f -y; \
			rm /tmp/vscode.deb; \
		}; \
	fi
else ifeq ($(IS_MACOS),true)
	@if command -v code &> /dev/null; then \
		echo -e "${GREEN}✓${NC} VS Code already installed"; \
	else \
		brew install --cask visual-studio-code; \
	fi
endif
	@echo -e "${GREEN}✓${NC} VS Code installed"

# Install Cursor
install-cursor: setup-repos install-cursor-cli
	@echo -e "${BLUE}Installing Cursor...${NC}"
ifeq ($(PACKAGE_MANAGER),apt)
	@if command -v cursor &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Cursor already installed"; \
	else \
		$(SUDO) apt install -y cursor 2>&1 | tee -a $(LOG_FILE) || { \
			echo -e "${YELLOW}Falling back to AppImage...${NC}"; \
			mkdir -p $(HOME)/.local/bin; \
			wget -O $(HOME)/.local/bin/cursor.AppImage "$(CURSOR_URL)"; \
			chmod +x $(HOME)/.local/bin/cursor.AppImage; \
			ln -sf $(HOME)/.local/bin/cursor.AppImage $(HOME)/.local/bin/cursor; \
		}; \
	fi
else ifeq ($(IS_MACOS),true)
	@if command -v cursor &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Cursor already installed"; \
	else \
		brew install --cask cursor; \
	fi
endif
	@echo -e "${GREEN}✓${NC} Cursor installed"

# Install cursor-cli (command line interface for Cursor)
install-cursor-cli:
	@echo -e "${BLUE}Installing cursor-cli...${NC}"
	@if command -v cursor-cli &> /dev/null || command -v cursor &> /dev/null; then \
		echo -e "${GREEN}✓${NC} cursor-cli already installed"; \
	else \
		echo -e "${YELLOW}Installing cursor-cli...${NC}"; \
		if command -v npm &> /dev/null; then \
			NPM_PREFIX=$$(npm config get prefix 2>/dev/null || echo "/usr/local"); \
			if [ -w "$$NPM_PREFIX/lib/node_modules" ]; then \
				npm install -g cursor-cli 2>&1 | tee -a $(LOG_FILE) || true; \
			else \
				echo -e "${YELLOW}Global npm directory not writable, trying with sudo...${NC}"; \
				$(SUDO) npm install -g cursor-cli 2>&1 | tee -a $(LOG_FILE) || { \
					echo -e "${YELLOW}npm install failed, trying alternative methods...${NC}"; \
					mkdir -p $(HOME)/.local/bin; \
					npm config set prefix $(HOME)/.local 2>/dev/null; \
					npm install -g cursor-cli 2>&1 | tee -a $(LOG_FILE) || { \
						echo -e "${YELLOW}Installing from GitHub release...${NC}"; \
						curl -L https://github.com/getcursor/cursor-cli/releases/latest/download/cursor-cli-linux-x64 \
							-o $(HOME)/.local/bin/cursor-cli 2>/dev/null || \
						curl -L https://raw.githubusercontent.com/getcursor/cursor/main/scripts/cursor-cli \
							-o $(HOME)/.local/bin/cursor-cli; \
						chmod +x $(HOME)/.local/bin/cursor-cli; \
					}; \
				}; \
			fi; \
		elif command -v cargo &> /dev/null; then \
			echo -e "${YELLOW}Installing cursor-cli via cargo...${NC}"; \
			cargo install cursor-cli 2>&1 | tee -a $(LOG_FILE); \
		else \
			echo -e "${YELLOW}Installing cursor-cli from GitHub...${NC}"; \
			mkdir -p $(HOME)/.local/bin; \
			curl -L https://github.com/getcursor/cursor-cli/releases/latest/download/cursor-cli-linux-x64 \
				-o $(HOME)/.local/bin/cursor-cli 2>/dev/null || \
			curl -L https://raw.githubusercontent.com/getcursor/cursor/main/scripts/cursor-cli \
				-o $(HOME)/.local/bin/cursor-cli; \
			chmod +x $(HOME)/.local/bin/cursor-cli; \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} cursor-cli installed"

# Install Windsurf
install-windsurf:
	@echo -e "${BLUE}Installing Windsurf...${NC}"
	@if command -v windsurf &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Windsurf already installed"; \
	else \
		mkdir -p $(HOME)/.local/bin; \
		if [ "$(IS_LINUX)" = "true" ]; then \
			echo -e "${YELLOW}Downloading Windsurf...${NC}"; \
			wget --content-disposition -O /tmp/windsurf-download "$(WINDSURF_URL)" 2>/dev/null || { \
				echo -e "${YELLOW}⚠ Windsurf download failed.${NC}"; \
				echo -e "${YELLOW}Please install manually from: https://windsurf.com/download/editor${NC}"; \
				false; \
			}; \
			if [ -f /tmp/windsurf-download ]; then \
				FILE_TYPE=$$(file -b /tmp/windsurf-download | cut -d' ' -f1); \
				if echo "$$FILE_TYPE" | grep -q "Debian"; then \
					$(SUDO) dpkg -i /tmp/windsurf-download 2>/dev/null || $(SUDO) apt-get install -f -y; \
				elif echo "$$FILE_TYPE" | grep -q "gzip"; then \
					tar -xzf /tmp/windsurf-download -C $(HOME)/.local/bin/; \
				elif echo "$$FILE_TYPE" | grep -q "AppImage"; then \
					mv /tmp/windsurf-download $(HOME)/.local/bin/windsurf; \
					chmod +x $(HOME)/.local/bin/windsurf; \
				fi; \
				rm -f /tmp/windsurf-download; \
			fi; \
		elif [ "$(IS_MACOS)" = "true" ]; then \
			brew install --cask windsurf || { \
				echo -e "${YELLOW}Installing via direct download...${NC}"; \
				curl -L https://windsurf-stable.codeiumdata.com/macos/windsurf.dmg -o /tmp/windsurf.dmg; \
				hdiutil attach /tmp/windsurf.dmg; \
				cp -R "/Volumes/Windsurf/Windsurf.app" /Applications/; \
				hdiutil detach "/Volumes/Windsurf"; \
				rm /tmp/windsurf.dmg; \
			}; \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Windsurf installed"

# Install Continue.dev
install-continue:
	@echo -e "${BLUE}Installing Continue.dev...${NC}"
	@if [ -d $(HOME)/.continue ]; then \
		echo -e "${GREEN}✓${NC} Continue already installed"; \
	else \
		curl -fsSL $(CONTINUE_URL) | bash 2>&1 | tee -a $(LOG_FILE); \
	fi
	@echo -e "${GREEN}✓${NC} Continue installed"

# Install Zed Editor
install-zed:
	@echo -e "${BLUE}Installing Zed Editor...${NC}"
	@if command -v zed &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Zed already installed"; \
	else \
		if [ "$(IS_LINUX)" = "true" ]; then \
			curl -fsSL $(ZEDITOR_URL) | sh 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(IS_MACOS)" = "true" ]; then \
			brew install --cask zed; \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Zed installed"

# Install VS Code extensions for AI assistance
install-vscode-extensions:
	@echo -e "${BLUE}Installing VS Code AI extensions...${NC}"
	@if command -v code &> /dev/null; then \
		code --install-extension GitHub.copilot || true; \
		code --install-extension GitHub.copilot-chat || true; \
		code --install-extension GitHub.copilot-labs || true; \
		code --install-extension Codeium.codeium || true; \
		code --install-extension Continue.continue || true; \
		code --install-extension TabNine.tabnine-vscode || true; \
		code --install-extension OpenAI.openai || true; \
		code --install-extension AmazonWebServices.aws-toolkit-vscode || true; \
		code --install-extension ms-python.python || true; \
		code --install-extension ms-python.vscode-pylance || true; \
		code --install-extension ms-toolsai.jupyter || true; \
		code --install-extension ms-vscode.cpptools || true; \
		code --install-extension rust-lang.rust-analyzer || true; \
		code --install-extension golang.go || true; \
		code --install-extension ms-vscode.typescript-next || true; \
		echo -e "${GREEN}✓${NC} VS Code extensions installed"; \
	else \
		echo -e "${YELLOW}⚠${NC} VS Code not installed, skipping extensions"; \
	fi

# Install all extensions for all editors
install-extensions: install-vscode-extensions
	@echo -e "${BLUE}Installing extensions for other editors...${NC}"
	@# Cursor uses VS Code extensions
	@if command -v cursor &> /dev/null; then \
		cursor --install-extension GitHub.copilot 2>/dev/null || true; \
		cursor --install-extension Codeium.codeium 2>/dev/null || true; \
	fi
	@echo -e "${GREEN}✓${NC} All extensions installed"

# Install GitHub Copilot CLI
install-github-copilot-cli:
	@echo -e "${BLUE}Installing GitHub Copilot CLI...${NC}"
	@if command -v gh &> /dev/null; then \
		gh extension install github/gh-copilot 2>/dev/null || \
		echo -e "${YELLOW}⚠${NC} GitHub CLI not authenticated or extension already installed"; \
	else \
		echo -e "${YELLOW}Installing GitHub CLI first...${NC}"; \
		if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
				$(SUDO) dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg; \
			echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
				$(SUDO) tee /etc/apt/sources.list.d/github-cli.list; \
			$(SUDO) apt update && $(SUDO) apt install -y gh; \
		elif [ "$(IS_MACOS)" = "true" ]; then \
			brew install gh; \
		fi; \
		gh extension install github/gh-copilot 2>/dev/null || \
		echo -e "${YELLOW}⚠${NC} Please authenticate with 'gh auth login' first"; \
	fi
	@echo -e "${GREEN}✓${NC} GitHub Copilot CLI setup complete"

# Install Codeium CLI
install-codeium-cli:
	@echo -e "${BLUE}Installing Codeium CLI...${NC}"
	@if command -v codeium &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Codeium CLI already installed"; \
	else \
		curl -fsSL https://codeium.com/install_script.sh | bash 2>&1 | tee -a $(LOG_FILE) || \
		echo -e "${YELLOW}⚠${NC} Codeium CLI installation requires manual setup"; \
	fi

# Configure AI assistants
configure-ai:
	@echo -e "${BLUE}Configuring AI assistants...${NC}"
	@mkdir -p $(AI_DIR)/configs
	@# VS Code settings for AI
	@mkdir -p $(HOME)/.config/Code/User
	@echo '{' > $(AI_DIR)/configs/vscode-ai-settings.json
	@echo '  "github.copilot.enable": {' >> $(AI_DIR)/configs/vscode-ai-settings.json
	@echo '    "*": true' >> $(AI_DIR)/configs/vscode-ai-settings.json
	@echo '  },' >> $(AI_DIR)/configs/vscode-ai-settings.json
	@echo '  "github.copilot.advanced": {},' >> $(AI_DIR)/configs/vscode-ai-settings.json
	@echo '  "codeium.enableConfig": {' >> $(AI_DIR)/configs/vscode-ai-settings.json
	@echo '    "*": true' >> $(AI_DIR)/configs/vscode-ai-settings.json
	@echo '  },' >> $(AI_DIR)/configs/vscode-ai-settings.json
	@echo '  "continue.enableTabAutocomplete": true,' >> $(AI_DIR)/configs/vscode-ai-settings.json
	@echo '  "editor.inlineSuggest.enabled": true,' >> $(AI_DIR)/configs/vscode-ai-settings.json
	@echo '  "editor.suggestSelection": "first"' >> $(AI_DIR)/configs/vscode-ai-settings.json
	@echo '}' >> $(AI_DIR)/configs/vscode-ai-settings.json
	@echo -e "${GREEN}✓${NC} AI assistants configured"
	@echo -e "${YELLOW}Note: Individual authentication required for:${NC}"
	@echo "  - GitHub Copilot: Sign in through VS Code/Cursor"
	@echo "  - Codeium: Create account at codeium.com"
	@echo "  - Continue: Configure models in ~/.continue/config.json"
	@echo "  - Windsurf: Sign in on first launch"

# Verify installation
verify-ai:
	@echo -e "${BLUE}Verifying AI assistant installations...${NC}"
	@echo "Installed AI Code Editors:"
	@command -v code &> /dev/null && echo -e "  ${GREEN}✓${NC} VS Code: $$(code --version | head -1)" || echo -e "  ${RED}✗${NC} VS Code"
	@command -v cursor &> /dev/null && echo -e "  ${GREEN}✓${NC} Cursor: installed" || echo -e "  ${RED}✗${NC} Cursor"
	@command -v cursor-cli &> /dev/null && echo -e "  ${GREEN}✓${NC} cursor-cli: installed" || echo -e "  ${RED}✗${NC} cursor-cli"
	@command -v windsurf &> /dev/null && echo -e "  ${GREEN}✓${NC} Windsurf: installed" || echo -e "  ${RED}✗${NC} Windsurf"
	@command -v zed &> /dev/null && echo -e "  ${GREEN}✓${NC} Zed: installed" || echo -e "  ${RED}✗${NC} Zed"
	@echo ""
	@echo "AI Extensions & Tools:"
	@[ -d $(HOME)/.continue ] && echo -e "  ${GREEN}✓${NC} Continue.dev" || echo -e "  ${RED}✗${NC} Continue.dev"
	@command -v gh &> /dev/null && gh extension list | grep -q copilot && \
		echo -e "  ${GREEN}✓${NC} GitHub Copilot CLI" || echo -e "  ${YELLOW}⚠${NC} GitHub Copilot CLI (auth required)"
	@command -v codeium &> /dev/null && echo -e "  ${GREEN}✓${NC} Codeium CLI" || echo -e "  ${RED}✗${NC} Codeium CLI"
	@echo ""
	$(call show_completion_banner,AI TOOLS READY)
	@echo -e "${GREEN}✓${NC} AI assistants verification complete"

# Help target
help-ai:
	@echo "ArmyknifeLabs AI Code Assistants Module"
	@echo "======================================="
	@echo ""
	@echo "Targets:"
	@echo "  all                - Install all AI code assistants and tools"
	@echo "  minimal            - Install VS Code with essential AI extensions"
	@echo "  setup-repos        - Setup GPG keys and repositories"
	@echo "  install-vscode     - Install Visual Studio Code"
	@echo "  install-cursor     - Install Cursor Editor"
	@echo "  install-windsurf   - Install Windsurf Editor"
	@echo "  install-continue   - Install Continue.dev"
	@echo "  install-zed        - Install Zed Editor"
	@echo "  install-extensions - Install AI extensions for all editors"
	@echo "  configure-ai       - Configure AI assistant settings"
	@echo "  verify-ai          - Verify all installations"
	@echo ""
	@echo "Authentication Required:"
	@echo "  - GitHub Copilot: GitHub account with Copilot subscription"
	@echo "  - Codeium: Free account at codeium.com"
	@echo "  - Continue: Configure LLM providers in ~/.continue/config.json"
	@echo "  - Windsurf: Account creation on first launch"
	@echo ""
	@echo "Usage:"
	@echo "  make -f makefiles/Makefile.AI-Assistants.mk all"
	@echo "  make -f makefiles/Makefile.AI-Assistants.mk minimal"