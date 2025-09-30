# ArmyknifeLabs Platform Installer - Security & Encryption Module
# Makefile.Security.mk

ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-$(shell date +%Y%m%d-%H%M%S).log

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

# OS detection
OS_TYPE := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo macos)
IS_MACOS := $(shell [[ "$$(uname -s)" == "Darwin" ]] && echo true || echo false)
PACKAGE_MANAGER := $(if $(filter ubuntu debian linuxmint,$(OS_TYPE)),apt,$(if $(filter fedora rhel,$(OS_TYPE)),dnf,brew))
SUDO := $(if $(IS_MACOS),,sudo)

.PHONY: all install-encryption install-password-managers install-secret-scanners configure-security verify-security

all: install-encryption install-password-managers install-secret-scanners configure-security verify-security

install-encryption:
	@echo -e "${BLUE}ℹ${NC} Installing encryption tools..."
	@# GnuPG
	@if ! command -v gpg &> /dev/null; then \
		if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y gnupg gnupg2 gnupg-agent; \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y gnupg2; \
		elif [ "$(IS_MACOS)" = "true" ]; then \
			brew install gnupg; \
		fi; \
	fi
	@# age
	@if ! command -v age &> /dev/null; then \
		echo "  Installing age..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install age; \
		elif command -v go &> /dev/null; then \
			go install filippo.io/age/cmd/...@latest; \
		else \
			curl -L https://github.com/FiloSottile/age/releases/latest/download/age-linux-amd64.tar.gz | \
				tar -xz -C /tmp && $(SUDO) mv /tmp/age/age* /usr/local/bin/; \
		fi; \
	fi
	@# sops
	@if ! command -v sops &> /dev/null; then \
		echo "  Installing sops..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install sops; \
		elif command -v go &> /dev/null; then \
			go install github.com/getsops/sops/v3/cmd/sops@latest; \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Encryption tools installed"

install-password-managers:
	@echo -e "${BLUE}ℹ${NC} Installing password managers..."
	@# pass
	@if ! command -v pass &> /dev/null; then \
		if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y pass; \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y pass; \
		elif [ "$(IS_MACOS)" = "true" ]; then \
			brew install pass; \
		fi; \
	fi
	@# 1Password CLI
	@if ! command -v op &> /dev/null; then \
		echo "  Installing 1Password CLI..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install --cask 1password-cli; \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
				$(SUDO) gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg; \
			echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main" | \
				$(SUDO) tee /etc/apt/sources.list.d/1password.list; \
			$(SUDO) apt update && $(SUDO) apt install -y 1password-cli; \
		fi; \
	fi
	@# Bitwarden CLI
	@if ! command -v bw &> /dev/null; then \
		echo "  Installing Bitwarden CLI..."; \
		if command -v npm &> /dev/null; then \
			npm install -g @bitwarden/cli; \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Password managers installed"

install-secret-scanners:
	@echo -e "${BLUE}ℹ${NC} Installing secret scanners..."
	@# trufflehog
	@if ! command -v trufflehog &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install trufflehog; \
		elif command -v go &> /dev/null; then \
			go install github.com/trufflesecurity/trufflehog/v3@latest; \
		fi; \
	fi
	@# git-secrets
	@if ! command -v git-secrets &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install git-secrets; \
		else \
			git clone https://github.com/awslabs/git-secrets.git /tmp/git-secrets && \
			cd /tmp/git-secrets && $(SUDO) make install && rm -rf /tmp/git-secrets; \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Secret scanners installed"

configure-security:
	@echo -e "${BLUE}ℹ${NC} Configuring security tools..."
	@# Create GPG directory
	@mkdir -p ~/.gnupg
	@chmod 700 ~/.gnupg
	@# Create age key if not exists
	@if [ ! -f ~/.config/age/key.txt ] && command -v age-keygen &> /dev/null; then \
		mkdir -p ~/.config/age; \
		age-keygen -o ~/.config/age/key.txt 2>/dev/null || true; \
	fi
	@# Configure git-secrets
	@if command -v git-secrets &> /dev/null; then \
		git secrets --register-aws --global 2>/dev/null || true; \
		git secrets --install ~/.git-templates/git-secrets 2>/dev/null || true; \
		git config --global init.templateDir ~/.git-templates/git-secrets 2>/dev/null || true; \
	fi
	@echo -e "${GREEN}✓${NC} Security tools configured"

verify-security:
	@echo -e "${BLUE}ℹ${NC} Verifying security tools..."
	@for tool in gpg age sops pass op bw gitleaks trufflehog git-secrets; do \
		if command -v $$tool &> /dev/null; then \
			echo -e "  ${GREEN}✓${NC} $$tool installed"; \
		else \
			echo -e "  ${YELLOW}⚠${NC} $$tool not found"; \
		fi; \
	done
	$(call show_completion_banner,SECURITY READY)
	@echo -e "${GREEN}✓${NC} Security verification complete"