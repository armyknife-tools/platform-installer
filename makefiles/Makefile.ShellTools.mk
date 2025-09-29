# ArmyknifeLabs Platform Installer - Shell Tools Module
# Makefile.ShellTools.mk
#
# Installs modern CLI tools and terminal enhancements
# fzf, ripgrep, bat, fd, eza, zoxide, tmux, and more

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
IS_MACOS := $(shell [[ "$$(uname -s)" == "Darwin" ]] && echo true || echo false)
IS_LINUX := $(shell [[ "$$(uname -s)" == "Linux" ]] && echo true || echo false)
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

# Tool URLs
FZF_REPO := https://github.com/junegunn/fzf.git
ZOXIDE_INSTALLER := https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh
GUM_INSTALLER := https://github.com/charmbracelet/gum/releases/latest

# Phony targets
.PHONY: all install-search-tools install-file-tools install-terminal-tools \
    install-system-tools install-text-tools install-gum install-fzf \
    install-ripgrep install-fd install-bat install-eza install-zoxide \
    install-tmux install-direnv install-atuin configure-shell-tools \
    verify-shell-tools update-shell-tools help-shell-tools

# Main target
all: install-search-tools install-file-tools install-terminal-tools \
    install-system-tools install-text-tools install-gum \
    configure-shell-tools verify-shell-tools

# Search tools
install-search-tools: install-fzf install-ripgrep install-fd
	@echo -e "${GREEN}✓${NC} Search tools installed"

# Install fzf (fuzzy finder)
install-fzf:
	@echo -e "${BLUE}ℹ${NC} Installing fzf..."
	@if command -v fzf &> /dev/null; then \
		echo -e "${GREEN}✓${NC} fzf already installed ($$(fzf --version))"; \
	else \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install fzf 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y fzf 2>&1 | tee -a $(LOG_FILE) || \
				(git clone --depth 1 $(FZF_REPO) ~/.fzf && ~/.fzf/install --all); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y fzf 2>&1 | tee -a $(LOG_FILE) || \
				(git clone --depth 1 $(FZF_REPO) ~/.fzf && ~/.fzf/install --all); \
		fi; \
		echo -e "${GREEN}✓${NC} fzf installed"; \
	fi
	@# Configure fzf key bindings
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q "fzf" $$rc; then \
			echo '' >> $$rc; \
			echo '# fzf' >> $$rc; \
			echo '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' >> $$rc; \
			echo 'export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"' >> $$rc; \
			echo 'export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"' >> $$rc; \
		fi; \
	done

# Install ripgrep (better grep)
install-ripgrep:
	@echo -e "${BLUE}ℹ${NC} Installing ripgrep..."
	@if command -v rg &> /dev/null; then \
		echo -e "${GREEN}✓${NC} ripgrep already installed ($$(rg --version | head -1))"; \
	else \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install ripgrep 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y ripgrep 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y ripgrep 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo -e "${GREEN}✓${NC} ripgrep installed"; \
	fi

# Install fd (better find)
install-fd:
	@echo -e "${BLUE}ℹ${NC} Installing fd..."
	@if command -v fd &> /dev/null || command -v fdfind &> /dev/null; then \
		echo -e "${GREEN}✓${NC} fd already installed"; \
	else \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install fd 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y fd-find 2>&1 | tee -a $(LOG_FILE); \
			$(SUDO) ln -sf $$(which fdfind) /usr/local/bin/fd 2>/dev/null || true; \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y fd-find 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo -e "${GREEN}✓${NC} fd installed"; \
	fi

# File management tools
install-file-tools: install-bat install-eza install-zoxide
	@echo -e "${GREEN}✓${NC} File tools installed"

# Install bat (better cat)
install-bat:
	@echo -e "${BLUE}ℹ${NC} Installing bat..."
	@if command -v bat &> /dev/null || command -v batcat &> /dev/null; then \
		echo -e "${GREEN}✓${NC} bat already installed"; \
	else \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install bat 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y bat 2>&1 | tee -a $(LOG_FILE); \
			$(SUDO) ln -sf $$(which batcat) /usr/local/bin/bat 2>/dev/null || true; \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y bat 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo -e "${GREEN}✓${NC} bat installed"; \
	fi

# Install eza (better ls)
install-eza:
	@echo -e "${BLUE}ℹ${NC} Installing eza..."
	@if command -v eza &> /dev/null || command -v exa &> /dev/null; then \
		echo -e "${GREEN}✓${NC} eza/exa already installed"; \
	else \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install eza 2>&1 | tee -a $(LOG_FILE) || \
				brew install exa 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y exa 2>&1 | tee -a $(LOG_FILE) || \
				(curl -Lo /tmp/eza.tar.gz https://github.com/eza-community/eza/releases/latest/download/eza_$$(uname -m)-unknown-linux-gnu.tar.gz && \
				 tar -xzf /tmp/eza.tar.gz -C /tmp && \
				 $(SUDO) mv /tmp/eza /usr/local/bin/); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y exa 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo -e "${GREEN}✓${NC} eza installed"; \
	fi

# Install zoxide (better cd)
install-zoxide:
	@echo -e "${BLUE}ℹ${NC} Installing zoxide..."
	@if command -v zoxide &> /dev/null; then \
		echo -e "${GREEN}✓${NC} zoxide already installed ($$(zoxide --version))"; \
	else \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install zoxide 2>&1 | tee -a $(LOG_FILE); \
		elif command -v cargo &> /dev/null; then \
			cargo install zoxide --locked 2>&1 | tee -a $(LOG_FILE); \
		else \
			curl -sS $(ZOXIDE_INSTALLER) | bash 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo -e "${GREEN}✓${NC} zoxide installed"; \
	fi
	@# Add zoxide to shell
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q "zoxide init" $$rc; then \
			echo '' >> $$rc; \
			echo '# zoxide' >> $$rc; \
			echo 'eval "$$(zoxide init bash)"' >> $$rc; \
		fi; \
	done

# Terminal tools
install-terminal-tools: install-tmux install-direnv install-atuin
	@echo -e "${GREEN}✓${NC} Terminal tools installed"

# Install tmux
install-tmux:
	@echo -e "${BLUE}ℹ${NC} Installing tmux..."
	@if command -v tmux &> /dev/null; then \
		echo -e "${GREEN}✓${NC} tmux already installed ($$(tmux -V))"; \
	else \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install tmux 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y tmux 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y tmux 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo -e "${GREEN}✓${NC} tmux installed"; \
	fi
	@# Install TPM (Tmux Plugin Manager)
	@if [ ! -d ~/.tmux/plugins/tpm ]; then \
		echo "  Installing TPM..."; \
		git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm; \
		echo "  Creating tmux config..."; \
		echo "  TPM installed (configure tmux manually)"; 
	fi

# Install direnv
install-direnv:
	@echo -e "${BLUE}ℹ${NC} Installing direnv..."
	@if command -v direnv &> /dev/null; then \
		echo -e "${GREEN}✓${NC} direnv already installed ($$(direnv version))"; \
	else \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install direnv 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y direnv 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y direnv 2>&1 | tee -a $(LOG_FILE); \
		else \
			curl -sfL https://direnv.net/install.sh | bash 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo -e "${GREEN}✓${NC} direnv installed"; \
	fi
	@# Hook direnv into shell
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q "direnv hook" $$rc; then \
			echo '' >> $$rc; \
			echo '# direnv' >> $$rc; \
			echo 'eval "$$(direnv hook bash)"' >> $$rc; \
		fi; \
	done

# Install atuin (magical shell history)
install-atuin:
	@echo -e "${BLUE}ℹ${NC} Installing atuin..."
	@if command -v atuin &> /dev/null; then \
		echo -e "${GREEN}✓${NC} atuin already installed ($$(atuin --version))"; \
	else \
		if command -v cargo &> /dev/null; then \
			cargo install atuin 2>&1 | tee -a $(LOG_FILE); \
		else \
			bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh) 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo -e "${GREEN}✓${NC} atuin installed"; \
	fi

# System monitoring tools
install-system-tools:
	@echo -e "${BLUE}ℹ${NC} Installing system tools..."
	@# htop
	@if ! command -v htop &> /dev/null; then \
		echo "  Installing htop..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install htop 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y htop 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y htop 2>&1 | tee -a $(LOG_FILE); \
		fi; \
	fi
	@# btop
	@if ! command -v btop &> /dev/null; then \
		echo "  Installing btop..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install btop 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ] && [ "$$(lsb_release -rs 2>/dev/null)" \> "21.10" ]; then \
			$(SUDO) apt install -y btop 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y btop 2>&1 | tee -a $(LOG_FILE); \
		fi; \
	fi
	@# ncdu
	@if ! command -v ncdu &> /dev/null; then \
		echo "  Installing ncdu..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install ncdu 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y ncdu 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y ncdu 2>&1 | tee -a $(LOG_FILE); \
		fi; \
	fi
	@# duf
	@if ! command -v duf &> /dev/null; then \
		echo "  Installing duf..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install duf 2>&1 | tee -a $(LOG_FILE); \
		elif command -v go &> /dev/null; then \
			go install github.com/muesli/duf@latest 2>&1 | tee -a $(LOG_FILE); \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} System tools installed"

# Text processing tools
install-text-tools:
	@echo -e "${BLUE}ℹ${NC} Installing text tools..."
	@# jq
	@if ! command -v jq &> /dev/null; then \
		echo "  Installing jq..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install jq 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y jq 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y jq 2>&1 | tee -a $(LOG_FILE); \
		fi; \
	fi
	@# yq
	@if ! command -v yq &> /dev/null; then \
		echo "  Installing yq..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install yq 2>&1 | tee -a $(LOG_FILE); \
		elif command -v go &> /dev/null; then \
			go install github.com/mikefarah/yq/v4@latest 2>&1 | tee -a $(LOG_FILE); \
		fi; \
	fi
	@# tldr
	@if ! command -v tldr &> /dev/null; then \
		echo "  Installing tldr..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install tldr 2>&1 | tee -a $(LOG_FILE); \
		elif command -v npm &> /dev/null; then \
			npm install -g tldr 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y tldr 2>&1 | tee -a $(LOG_FILE); \
		fi; \
	fi
	@# httpie
	@if ! command -v http &> /dev/null; then \
		echo "  Installing httpie..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install httpie 2>&1 | tee -a $(LOG_FILE); \
		elif command -v pipx &> /dev/null; then \
			pipx install httpie 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y httpie 2>&1 | tee -a $(LOG_FILE); \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Text tools installed"

# Install gum (TUI toolkit)
install-gum:
	@echo -e "${BLUE}ℹ${NC} Installing gum..."
	@if command -v gum &> /dev/null; then \
		echo -e "${GREEN}✓${NC} gum already installed ($$(gum --version))"; \
	else \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install gum 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) mkdir -p /etc/apt/keyrings; \
			curl -fsSL https://repo.charm.sh/apt/gpg.key | $(SUDO) gpg --dearmor -o /etc/apt/keyrings/charm.gpg; \
			echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | \
				$(SUDO) tee /etc/apt/sources.list.d/charm.list; \
			$(SUDO) apt update && $(SUDO) apt install -y gum 2>&1 | tee -a $(LOG_FILE); \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			echo '[charm]' | $(SUDO) tee /etc/yum.repos.d/charm.repo; \
			echo 'name=Charm' | $(SUDO) tee -a /etc/yum.repos.d/charm.repo; \
			echo 'baseurl=https://repo.charm.sh/yum/' | $(SUDO) tee -a /etc/yum.repos.d/charm.repo; \
			echo 'enabled=1' | $(SUDO) tee -a /etc/yum.repos.d/charm.repo; \
			echo 'gpgcheck=1' | $(SUDO) tee -a /etc/yum.repos.d/charm.repo; \
			echo 'gpgkey=https://repo.charm.sh/yum/gpg.key' | $(SUDO) tee -a /etc/yum.repos.d/charm.repo; \
			$(SUDO) dnf install -y gum 2>&1 | tee -a $(LOG_FILE); \
		fi; \
		echo -e "${GREEN}✓${NC} gum installed"; \
	fi

# Configure shell tools
configure-shell-tools:
	@echo -e "${BLUE}ℹ${NC} Configuring shell tool integrations..."
	@# Create config directory
	@mkdir -p ~/.config/{bat,ripgrep}
	@# Configure bat
	@if [ ! -f ~/.config/bat/config ]; then \
		echo '--theme="TwoDark"' > ~/.config/bat/config; \
		echo '--style="numbers,changes,header"' >> ~/.config/bat/config; \
		echo '--paging="always"' >> ~/.config/bat/config; \
	fi
	@# Configure ripgrep
	@if [ ! -f ~/.config/ripgrep/config ]; then \
		echo '--max-columns=150' > ~/.config/ripgrep/config; \
		echo '--max-columns-preview' >> ~/.config/ripgrep/config; \
		echo '--smart-case' >> ~/.config/ripgrep/config; \
		echo '--glob=!.git' >> ~/.config/ripgrep/config; \
	fi
	@echo -e "${GREEN}✓${NC} Shell tools configured"

# Verify installations
verify-shell-tools:
	@echo -e "${BLUE}ℹ${NC} Verifying shell tools..."
	@# Check each tool
	@for tool in fzf rg fd bat eza zoxide tmux direnv htop jq gum; do \
		if command -v $$tool &> /dev/null; then \
			echo -e "  ${GREEN}✓${NC} $$tool installed"; \
		else \
			echo -e "  ${YELLOW}⚠${NC} $$tool not found"; \
		fi; \
	done
	@echo -e "${GREEN}✓${NC} Shell tools verification complete"

# Update shell tools
update-shell-tools:
	@echo -e "${BLUE}ℹ${NC} Updating shell tools..."
	@if [ "$(IS_MACOS)" = "true" ]; then \
		brew upgrade fzf ripgrep fd bat eza zoxide tmux gum 2>/dev/null || true; \
	fi
	@if [ -d ~/.fzf ]; then \
		cd ~/.fzf && git pull && ./install --all; \
	fi
	@echo -e "${GREEN}✓${NC} Shell tools updated"

# Help
help-shell-tools:
	@echo "ArmyknifeLabs Shell Tools Module"
	@echo ""
	@echo "Tools installed:"
	@echo "  Search: fzf, ripgrep, fd"
	@echo "  Files: bat, eza, zoxide"
	@echo "  Terminal: tmux, direnv, atuin"
	@echo "  System: htop, btop, ncdu, duf"
	@echo "  Text: jq, yq, tldr, httpie"
	@echo "  TUI: gum"