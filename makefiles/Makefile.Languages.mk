# ArmyknifeLabs Platform Installer - Programming Languages Orchestrator
# Makefile.Languages.mk
#
# Orchestrates installation of comprehensive language-specific environments
# Delegates to specialized makefiles for Python, TypeScript/JavaScript, Go, Rust, and Java

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

# Shell configuration - use bash for all commands
SHELL := /bin/bash
.SHELLFLAGS := -ec

# OS detection
OS_TYPE := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo macos)
IS_MACOS := $(shell if [ "$$(uname -s)" = "Darwin" ]; then echo true; else echo false; fi)
IS_LINUX := $(shell if [ "$$(uname -s)" = "Linux" ]; then echo true; else echo false; fi)
ARCH := $(shell uname -m)

# Package manager
ifeq ($(OS_TYPE),ubuntu)
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifeq ($(OS_TYPE),debian)
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifeq ($(OS_TYPE),linuxmint)
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifeq ($(OS_TYPE),fedora)
    PACKAGE_MANAGER := dnf
    SUDO := sudo
else ifeq ($(IS_MACOS),true)
    PACKAGE_MANAGER := brew
    SUDO :=
endif

# Language versions to install
PYTHON_VERSIONS := 3.11.9 3.12.7 3.13.0
NODE_LTS_VERSION := 20.18.0
NODE_LATEST_VERSION := 22.11.0
GO_VERSION := 1.23.3
RUST_CHANNELS := stable nightly
JAVA_VERSION := 21

# Installer URLs
PYENV_INSTALLER := https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer
UV_INSTALLER := https://astral.sh/uv/install.sh
FNM_INSTALLER := https://fnm.vercel.app/install
PNPM_INSTALLER := https://get.pnpm.io/install.sh
BUN_INSTALLER := https://bun.sh/install
GVM_INSTALLER := https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer
RUSTUP_INSTALLER := https://sh.rustup.rs
SDKMAN_INSTALLER := https://get.sdkman.io

# Phony targets
.PHONY: all minimal python typescript golang rust java \
    install-python install-typescript install-golang install-rust install-java \
    verify-languages update-languages clean-languages help-languages

# Main target - install essential language tools (not everything!)
# For standard/full installations, we install minimal versions to keep it reasonable
all: all-minimal verify-languages

# Complete installation - everything for power users (manual trigger only)
all-complete: python typescript golang rust java verify-languages

# Minimal installation - essential tools for each language
all-minimal: python-minimal typescript-minimal golang-minimal rust-minimal java verify-languages

# Minimal installation - just Python and TypeScript
minimal: python-minimal typescript-minimal verify-languages

# Delegate to specialized language makefiles
python:
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@echo -e "${CYAN} Installing Python Ecosystem (Most Comprehensive Edition)${NC}"
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@$(MAKE) -f makefiles/Makefile.Python.mk all

python-minimal:
	@echo -e "${BLUE}ℹ${NC} Installing minimal Python ecosystem..."
	@$(MAKE) -f makefiles/Makefile.Python.mk minimal

typescript:
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@echo -e "${CYAN} Installing TypeScript/JavaScript Ecosystem${NC}"
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@$(MAKE) -f makefiles/Makefile.Typescript.mk all

typescript-minimal:
	@echo -e "${BLUE}ℹ${NC} Installing minimal TypeScript ecosystem..."
	@$(MAKE) -f makefiles/Makefile.Typescript.mk minimal

golang:
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@echo -e "${CYAN} Installing Go Ecosystem${NC}"
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@$(MAKE) -f makefiles/Makefile.Golang.mk all

golang-minimal:
	@echo -e "${BLUE}ℹ${NC} Installing minimal Go ecosystem..."
	@$(MAKE) -f makefiles/Makefile.Golang.mk minimal

rust:
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@echo -e "${CYAN} Installing Rust Ecosystem${NC}"
	@echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	@$(MAKE) -f makefiles/Makefile.Rust.mk all

rust-minimal:
	@echo -e "${BLUE}ℹ${NC} Installing minimal Rust ecosystem..."
	@$(MAKE) -f makefiles/Makefile.Rust.mk minimal

# Keep Java as-is for now (can be broken out later)
java: install-java

# Legacy install targets for backwards compatibility
install-python: python
install-typescript: typescript
install-nodejs: typescript
install-golang: golang
install-go: golang
install-rust: rust

# Python ecosystem (legacy implementation kept for reference)
	@# Install Python build dependencies
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt install -y build-essential libssl-dev zlib1g-dev \
		libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
		libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev \
		liblzma-dev python3-openssl git 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(PACKAGE_MANAGER),dnf)
	@$(SUDO) dnf install -y gcc gcc-c++ make git patch openssl-devel \
		zlib-devel bzip2-devel readline-devel sqlite-devel tk-devel \
		libffi-devel xz-devel libuuid-devel gdbm-devel 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@brew install openssl readline sqlite3 xz zlib tcl-tk 2>/dev/null || true
endif
	@# Install Python versions with pyenv
	@echo "  Installing Python versions..."
	@for version in $(PYTHON_VERSIONS); do \
		if ! pyenv versions | grep -q $$version; then \
			echo "  Installing Python $$version..."; \
			CONFIGURE_OPTS="--enable-optimizations --with-lto" \
				pyenv install $$version 2>&1 | tee -a $(LOG_FILE) || \
				echo -e "${YELLOW}⚠${NC} Failed to install Python $$version"; \
		else \
			echo -e "  ${GREEN}✓${NC} Python $$version already installed"; \
		fi; \
	done
	@# Set global Python version
	@echo "  Setting Python 3.12 as global default..."
	@pyenv global 3.12.7 2>/dev/null || pyenv global system
	@echo -e "${GREEN}✓${NC} Python ecosystem configured"

# Install pyenv
install-pyenv:
	@echo -e "${BLUE}ℹ${NC} Installing pyenv..."
	@if [ -d "$$HOME/.pyenv" ]; then \
		echo -e "${GREEN}✓${NC} pyenv already installed"; \
		cd ~/.pyenv && git pull 2>&1 | tee -a $(LOG_FILE); \
	else \
		echo "  Downloading pyenv installer..."; \
		curl -L $(PYENV_INSTALLER) | bash 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} pyenv installed"; \
	fi
	@# Add to shell RC
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q "pyenv init" $$rc; then \
			echo '' >> $$rc; \
			echo '# Pyenv' >> $$rc; \
			echo 'export PYENV_ROOT="$$HOME/.pyenv"' >> $$rc; \
			echo 'export PATH="$$PYENV_ROOT/bin:$$PATH"' >> $$rc; \
			echo 'eval "$$(pyenv init --path)"' >> $$rc; \
			echo 'eval "$$(pyenv init -)"' >> $$rc; \
			echo 'eval "$$(pyenv virtualenv-init -)" 2>/dev/null || true' >> $$rc; \
		fi; \
	done
	@# Source for current session
	@export PYENV_ROOT="$$HOME/.pyenv" && \
		export PATH="$$PYENV_ROOT/bin:$$PATH" && \
		eval "$$($$HOME/.pyenv/bin/pyenv init --path)"

# Install uv (Astral's fast Python package manager)
install-uv:
	@echo -e "${BLUE}ℹ${NC} Installing uv (Astral)..."
	@if command -v uv &> /dev/null; then \
		echo -e "${GREEN}✓${NC} uv already installed ($$(uv --version))"; \
	else \
		echo "  Downloading uv installer..."; \
		curl -LsSf $(UV_INSTALLER) | sh 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} uv installed"; \
	fi
	@# Also install uvx
	@if ! command -v uvx &> /dev/null; then \
		echo "  Installing uvx..."; \
		~/.cargo/bin/uv tool install uvx 2>/dev/null || \
			pip3 install --user uvx 2>/dev/null || true; \
	fi

# Install pipx
install-pipx:
	@echo -e "${BLUE}ℹ${NC} Installing pipx..."
	@if command -v pipx &> /dev/null; then \
		echo -e "${GREEN}✓${NC} pipx already installed ($$(pipx --version))"; \
	else \
		if command -v pip3 &> /dev/null; then \
			pip3 install --user pipx 2>&1 | tee -a $(LOG_FILE); \
			echo -e "${GREEN}✓${NC} pipx installed"; \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y pipx 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y pipx 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(IS_MACOS)" = "true" ]; then \
			brew install pipx 2>&1 | tee -a $(LOG_FILE); \
		fi; \
	fi
	@pipx ensurepath 2>/dev/null || true

# Node.js ecosystem
install-nodejs: install-fnm install-pnpm install-bun
	@echo -e "${BLUE}ℹ${NC} Setting up Node.js ecosystem..."
	@# Install Node versions with fnm
	@echo "  Installing Node.js versions..."
	@export PATH="$$HOME/.local/share/fnm:$$PATH" && \
		eval "$$(fnm env)" 2>/dev/null || true
	@# Install LTS version
	@if ! fnm list | grep -q $(NODE_LTS_VERSION) 2>/dev/null; then \
		echo "  Installing Node.js LTS ($(NODE_LTS_VERSION))..."; \
		fnm install $(NODE_LTS_VERSION) 2>&1 | tee -a $(LOG_FILE); \
	else \
		echo -e "  ${GREEN}✓${NC} Node.js $(NODE_LTS_VERSION) already installed"; \
	fi
	@# Install latest version
	@if ! fnm list | grep -q $(NODE_LATEST_VERSION) 2>/dev/null; then \
		echo "  Installing Node.js latest ($(NODE_LATEST_VERSION))..."; \
		fnm install $(NODE_LATEST_VERSION) 2>&1 | tee -a $(LOG_FILE); \
	else \
		echo -e "  ${GREEN}✓${NC} Node.js $(NODE_LATEST_VERSION) already installed"; \
	fi
	@# Set default to LTS
	@fnm default $(NODE_LTS_VERSION) 2>/dev/null || true
	@fnm use $(NODE_LTS_VERSION) 2>/dev/null || true
	@echo -e "${GREEN}✓${NC} Node.js ecosystem configured"

# Install fnm (Fast Node Manager)
install-fnm:
	@echo -e "${BLUE}ℹ${NC} Installing fnm..."
	@if command -v fnm &> /dev/null; then \
		echo -e "${GREEN}✓${NC} fnm already installed ($$(fnm --version))"; \
	else \
		echo "  Downloading fnm installer..."; \
		curl -fsSL $(FNM_INSTALLER) | bash -s -- --skip-shell 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} fnm installed"; \
	fi
	@# Add to shell RC
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q "fnm env" $$rc; then \
			echo '' >> $$rc; \
			echo '# fnm (Fast Node Manager)' >> $$rc; \
			echo 'export PATH="$$HOME/.local/share/fnm:$$PATH"' >> $$rc; \
			echo 'eval "$$(fnm env --use-on-cd)"' >> $$rc; \
		fi; \
	done

# Install pnpm
install-pnpm:
	@echo -e "${BLUE}ℹ${NC} Installing pnpm..."
	@if command -v pnpm &> /dev/null; then \
		echo -e "${GREEN}✓${NC} pnpm already installed ($$(pnpm --version))"; \
	else \
		echo "  Downloading pnpm installer..."; \
		curl -fsSL $(PNPM_INSTALLER) | sh - 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} pnpm installed"; \
	fi
	@# Setup pnpm
	@pnpm setup 2>/dev/null || true
	@pnpm config set store-dir ~/.pnpm-store 2>/dev/null || true

# Install Bun
install-bun:
	@echo -e "${BLUE}ℹ${NC} Installing Bun..."
	@if command -v bun &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Bun already installed ($$(bun --version))"; \
	else \
		echo "  Downloading Bun installer..."; \
		curl -fsSL $(BUN_INSTALLER) | bash 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} Bun installed"; \
	fi
	@# Add to PATH if needed
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q ".bun/bin" $$rc; then \
			echo 'export PATH="$$HOME/.bun/bin:$$PATH"' >> $$rc; \
		fi; \
	done

# Go ecosystem
install-go: install-gvm
	@echo -e "${BLUE}ℹ${NC} Setting up Go ecosystem..."
	@# Install Go with gvm
	@if command -v gvm &> /dev/null; then \
		source ~/.gvm/scripts/gvm; \
		echo "  Installing Go $(GO_VERSION)..."; \
		gvm install go$(GO_VERSION) -B 2>&1 | tee -a $(LOG_FILE) || \
			(echo "  Installing from binary..."; \
			 gvm install go$(GO_VERSION) --binary 2>&1 | tee -a $(LOG_FILE)); \
		gvm use go$(GO_VERSION) --default 2>&1 | tee -a $(LOG_FILE); \
	else \
		echo -e "${YELLOW}⚠${NC} gvm not available, installing Go directly..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install go 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y golang-go 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y golang 2>&1 | tee -a $(LOG_FILE); \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Go ecosystem configured"

# Install gvm (Go Version Manager)
install-gvm:
	@echo -e "${BLUE}ℹ${NC} Installing gvm..."
	@if [ -d "$$HOME/.gvm" ]; then \
		echo -e "${GREEN}✓${NC} gvm already installed"; \
	else \
		echo "  Installing dependencies..."; \
		if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y curl git mercurial make binutils bison gcc build-essential 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y curl git mercurial make binutils bison gcc glibc-devel 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo "  Downloading gvm installer..."; \
		bash < <(curl -s -S -L $(GVM_INSTALLER)) 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} gvm installed"; \
	fi
	@# Add to shell RC
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q "gvm/scripts/gvm" $$rc; then \
			echo '' >> $$rc; \
			echo '# GVM (Go Version Manager)' >> $$rc; \
			echo '[[ -s "$$HOME/.gvm/scripts/gvm" ]] && source "$$HOME/.gvm/scripts/gvm"' >> $$rc; \
		fi; \
	done

# Rust ecosystem - removed (now handled by Makefile.Rust.mk)

# Install rustup
install-rustup:
	@echo -e "${BLUE}ℹ${NC} Installing rustup..."
	@if command -v rustup &> /dev/null; then \
		echo -e "${GREEN}✓${NC} rustup already installed ($$(rustup --version))"; \
		rustup update 2>&1 | tee -a $(LOG_FILE); \
	else \
		echo "  Downloading rustup installer..."; \
		curl --proto '=https' --tlsv1.2 -sSf $(RUSTUP_INSTALLER) | sh -s -- -y 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} rustup installed"; \
	fi
	@# Add to PATH
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q ".cargo/bin" $$rc; then \
			echo '' >> $$rc; \
			echo '# Rust' >> $$rc; \
			echo 'export PATH="$$HOME/.cargo/bin:$$PATH"' >> $$rc; \
		fi; \
	done
	@# Source for current session
	@source "$$HOME/.cargo/env" 2>/dev/null || true

# Java ecosystem
install-java: install-sdkman
	@echo -e "${BLUE}ℹ${NC} Setting up Java ecosystem..."
	@if [ -d "$$HOME/.sdkman" ]; then \
		export SDKMAN_DIR="$$HOME/.sdkman" && \
		source "$$HOME/.sdkman/bin/sdkman-init.sh"; \
		echo "  Installing Java $(JAVA_VERSION)..."; \
		sdk install java $(JAVA_VERSION)-tem 2>&1 | tee -a $(LOG_FILE) || \
			sdk install java 2>&1 | tee -a $(LOG_FILE); \
		echo "  Installing Maven..."; \
		sdk install maven 2>&1 | tee -a $(LOG_FILE); \
		echo "  Installing Gradle..."; \
		sdk install gradle 2>&1 | tee -a $(LOG_FILE); \
		echo "  Installing Kotlin..."; \
		sdk install kotlin 2>&1 | tee -a $(LOG_FILE) || true; \
	else \
		echo -e "${YELLOW}⚠${NC} SDKMAN not available, installing Java directly..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install openjdk@$(JAVA_VERSION) maven gradle 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y openjdk-$(JAVA_VERSION)-jdk maven gradle 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y java-$(JAVA_VERSION)-openjdk-devel maven gradle 2>&1 | tee -a $(LOG_FILE); \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Java ecosystem configured"

# Install SDKMAN!
install-sdkman:
	@echo -e "${BLUE}ℹ${NC} Installing SDKMAN!..."
	@if [ -d "$$HOME/.sdkman" ]; then \
		echo -e "${GREEN}✓${NC} SDKMAN! already installed"; \
		export SDKMAN_DIR="$$HOME/.sdkman" && \
		source "$$HOME/.sdkman/bin/sdkman-init.sh" && \
		sdk update 2>&1 | tee -a $(LOG_FILE); \
	else \
		echo "  Downloading SDKMAN! installer..."; \
		curl -s $(SDKMAN_INSTALLER) | bash 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} SDKMAN! installed"; \
	fi
	@# Add to shell RC
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q "sdkman-init.sh" $$rc; then \
			echo '' >> $$rc; \
			echo '# SDKMAN!' >> $$rc; \
			echo 'export SDKMAN_DIR="$$HOME/.sdkman"' >> $$rc; \
			echo '[[ -s "$$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$$HOME/.sdkman/bin/sdkman-init.sh"' >> $$rc; \
		fi; \
	done

# Configure all language environments
configure-languages:
	@echo -e "${BLUE}ℹ${NC} Configuring language environments..."
	@# Create default configs
	@mkdir -p ~/.config/pip
	@if [ ! -f ~/.config/pip/pip.conf ]; then \
		echo "[global]" > ~/.config/pip/pip.conf; \
		echo "user = true" >> ~/.config/pip/pip.conf; \
		echo "break-system-packages = true" >> ~/.config/pip/pip.conf; \
	fi
	@# Configure npm
	@npm config set prefix ~/.npm-global 2>/dev/null || true
	@# Create Go workspace
	@mkdir -p ~/go/{bin,src,pkg}
	@# Configure Cargo
	@mkdir -p ~/.cargo
	@if [ ! -f ~/.cargo/config.toml ]; then \
		echo "[build]" > ~/.cargo/config.toml; \
		echo "jobs = 4" >> ~/.cargo/config.toml; \
		echo "[net]" >> ~/.cargo/config.toml; \
		echo "git-fetch-with-cli = true" >> ~/.cargo/config.toml; \
	fi
	@echo -e "${GREEN}✓${NC} Language environments configured"

# Verify language installations
verify-languages:
	@echo -e "${BLUE}ℹ${NC} Verifying language installations..."
	@# Python
	@if command -v python3 &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Python: $$(python3 --version)"; \
	else \
		echo -e "  ${RED}✗${NC} Python not found"; \
	fi
	@if command -v pyenv &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} pyenv installed"; \
	fi
	@if command -v uv &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} uv installed"; \
	fi
	@# Node.js
	@if command -v node &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Node.js: $$(node --version)"; \
	else \
		echo -e "  ${RED}✗${NC} Node.js not found"; \
	fi
	@if command -v fnm &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} fnm installed"; \
	fi
	@if command -v pnpm &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} pnpm: $$(pnpm --version)"; \
	fi
	@if command -v bun &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Bun: $$(bun --version)"; \
	fi
	@# Go
	@if command -v go &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Go: $$(go version)"; \
	else \
		echo -e "  ${YELLOW}⚠${NC} Go not found"; \
	fi
	@# Rust
	@if command -v rustc &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Rust: $$(rustc --version)"; \
	else \
		echo -e "  ${YELLOW}⚠${NC} Rust not found"; \
	fi
	@if command -v cargo &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Cargo: $$(cargo --version)"; \
	fi
	@# Java
	@if command -v java &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Java: $$(java -version 2>&1 | head -1)"; \
	else \
		echo -e "  ${YELLOW}⚠${NC} Java not found"; \
	fi
	@echo -e "${GREEN}✓${NC} Language verification complete"

# Update language tools
update-languages:
	@echo -e "${BLUE}ℹ${NC} Updating language tools..."
	@if command -v pyenv &> /dev/null; then \
		cd ~/.pyenv && git pull; \
	fi
	@if command -v rustup &> /dev/null; then \
		rustup update; \
	fi
	@if [ -d ~/.sdkman ]; then \
		source ~/.sdkman/bin/sdkman-init.sh && sdk update && sdk upgrade; \
	fi
	@echo -e "${GREEN}✓${NC} Language tools updated"

# Clean language artifacts
clean-languages:
	@echo -e "${YELLOW}⚠${NC} Cleaning language artifacts..."
	@rm -rf ~/.npm/_cacache ~/.pnpm-store/_tmp
	@cargo cache -a 2>/dev/null || true
	@echo -e "${GREEN}✓${NC} Language cleanup complete"

# Help
help-languages:
	@echo "ArmyknifeLabs Programming Languages Orchestrator"
	@echo "The most comprehensive language development environments ever created"
	@echo ""
	@echo -e "${CYAN}Main Targets:${NC}"
	@echo "  all         - Install essential tools for all languages (DEFAULT - fast)"
	@echo "  all-complete - Install EVERYTHING for all languages (WARNING: 2+ hours)"
	@echo "  minimal     - Install only Python and TypeScript essentials"
	@echo ""
	@echo -e "${CYAN}Individual Languages:${NC}"
	@echo "  python      - Complete Python ecosystem (AI/ML, Data Science, Security, Cloud)"
	@echo "  typescript  - Complete TypeScript/JavaScript ecosystem (Web, Mobile, Desktop)"
	@echo "  golang      - Complete Go ecosystem (Cloud-native, DevOps, CLI tools)"
	@echo "  rust        - Complete Rust ecosystem (Systems, WASM, Embedded)"
	@echo "  java        - Java ecosystem with SDKMAN"
	@echo ""
	@echo -e "${CYAN}Minimal Installations:${NC}"
	@echo "  python-minimal     - Basic Python with formatters and linters"
	@echo "  typescript-minimal - Basic TypeScript with bundlers and linters"
	@echo "  golang-minimal     - Basic Go with core tools"
	@echo "  rust-minimal       - Basic Rust with cargo tools"
	@echo ""
	@echo -e "${CYAN}Language-Specific Help:${NC}"
	@echo "  make -f makefiles/Makefile.Python.mk help-python"
	@echo "  make -f makefiles/Makefile.Typescript.mk help-typescript"
	@echo "  make -f makefiles/Makefile.Golang.mk help-golang"
	@echo "  make -f makefiles/Makefile.Rust.mk help-rust"
	@echo ""
	@echo -e "${CYAN}Maintenance:${NC}"
	@echo "  verify-languages - Verify all language installations"
	@echo "  update-languages - Update all language tools"
	@echo "  clean-languages  - Clean language artifacts"
	@echo ""
	@echo -e "${PURPLE}Each language makefile includes:${NC}"
	@echo "  • Multiple version management"
	@echo "  • Modern package managers and build tools"
	@echo "  • Comprehensive linters and formatters"
	@echo "  • Testing frameworks and tools"
	@echo "  • Domain-specific libraries and frameworks"
	@echo "  • IDE/Editor integration tools"
	@echo "  • Performance and security tools"
	@echo ""
	@echo -e "${GREEN}This is the most innovative and comprehensive"
	@echo -e "developer platform you've ever seen!${NC}"