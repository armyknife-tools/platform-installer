# ArmyknifeLabs Platform Installer - Shell Configuration Module
# Makefile.Shell.mk
#
# Installs and configures Oh-My-Bash (Linux) or Oh-My-Zsh (macOS)
# Sets up modern shell prompts, themes, and productivity enhancements

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

# Shell detection
SHELL_TYPE := bash
ifeq ($(shell echo $$SHELL | grep -c zsh),1)
    SHELL_TYPE := zsh
endif

# OS detection (from Base.mk)
OS_TYPE := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo macos)
IS_MACOS := $(shell [[ "$$(uname -s)" == "Darwin" ]] && echo true || echo false)
IS_LINUX := $(shell [[ "$$(uname -s)" == "Linux" ]] && echo true || echo false)

# Sudo command
ifeq ($(IS_MACOS),true)
    SUDO :=
else
    SUDO := sudo
endif

# Oh-My-Bash/Zsh URLs
OMB_INSTALLER := https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh
OMZ_INSTALLER := https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
STARSHIP_INSTALLER := https://starship.rs/install.sh

# Phony targets
.PHONY: all install-oh-my-shell install-oh-my-bash install-oh-my-zsh \
    configure-shell install-fonts install-starship install-powerline \
    setup-plugins configure-aliases integrate-armyknife verify-shell \
    update-shell clean-shell help-shell

# Main target
all: install-oh-my-shell configure-shell install-fonts install-starship \
    setup-plugins configure-aliases integrate-armyknife verify-shell

# Install appropriate Oh-My-Shell based on OS
install-oh-my-shell:
	@echo -e "${BLUE}ℹ${NC} Installing shell enhancements..."
ifeq ($(IS_MACOS),true)
	@$(MAKE) install-oh-my-zsh
else
	@$(MAKE) install-oh-my-bash
endif

# Install Oh-My-Bash (Linux)
install-oh-my-bash:
	@echo -e "${BLUE}ℹ${NC} Installing Oh-My-Bash..."
	@if [ -d "$$HOME/.oh-my-bash" ]; then \
		echo -e "${GREEN}✓${NC} Oh-My-Bash already installed"; \
	else \
		echo "  Backing up existing .bashrc..."; \
		cp ~/.bashrc ~/.bashrc.backup-$$(date +%s) 2>/dev/null || true; \
		echo "  Downloading Oh-My-Bash installer..."; \
		curl -fsSL $(OMB_INSTALLER) -o /tmp/install-omb.sh; \
		echo "  Running installer..."; \
		OSH= sh /tmp/install-omb.sh --unattended 2>&1 | tee -a $(LOG_FILE); \
		rm -f /tmp/install-omb.sh; \
		echo -e "${GREEN}✓${NC} Oh-My-Bash installed"; \
	fi
	@# Set theme
	@echo "  Setting theme to powerline-multiline..."
	@sed -i 's/^OSH_THEME=.*/OSH_THEME="powerline-multiline"/' ~/.bashrc 2>/dev/null || \
		echo 'OSH_THEME="powerline-multiline"' >> ~/.bashrc

# Install Oh-My-Zsh (macOS and optional for Linux)
install-oh-my-zsh:
	@echo -e "${BLUE}ℹ${NC} Installing Oh-My-Zsh..."
	@if [ -d "$$HOME/.oh-my-zsh" ]; then \
		echo -e "${GREEN}✓${NC} Oh-My-Zsh already installed"; \
	else \
		echo "  Backing up existing .zshrc..."; \
		cp ~/.zshrc ~/.zshrc.backup-$$(date +%s) 2>/dev/null || true; \
		echo "  Downloading Oh-My-Zsh installer..."; \
		curl -fsSL $(OMZ_INSTALLER) -o /tmp/install-omz.sh; \
		echo "  Running installer..."; \
		ZSH= sh /tmp/install-omz.sh --unattended 2>&1 | tee -a $(LOG_FILE); \
		rm -f /tmp/install-omz.sh; \
		echo -e "${GREEN}✓${NC} Oh-My-Zsh installed"; \
	fi
	@# Set theme
	@echo "  Setting theme to agnoster..."
	@sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc 2>/dev/null || \
		sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc 2>/dev/null || \
		echo 'ZSH_THEME="agnoster"' >> ~/.zshrc

# Install Powerline fonts
install-fonts:
	@echo -e "${BLUE}ℹ${NC} Installing Nerd Fonts..."
ifeq ($(IS_MACOS),true)
	@# macOS - Install via Homebrew
	@brew tap homebrew/cask-fonts 2>/dev/null || true
	@brew install --cask font-fira-code-nerd-font 2>/dev/null || \
		echo -e "${YELLOW}⚠${NC} Font already installed or not available"
	@brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || true
	@brew install --cask font-hack-nerd-font 2>/dev/null || true
else
	@# Linux - Download and install manually
	@echo "  Creating fonts directory..."
	@mkdir -p ~/.local/share/fonts
	@if [ ! -f ~/.local/share/fonts/FiraCode-Regular-Nerd-Font.ttf ]; then \
		echo "  Downloading FiraCode Nerd Font..."; \
		curl -fLo ~/.local/share/fonts/FiraCode-Regular-Nerd-Font.ttf \
			https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf; \
	fi
	@if [ ! -f ~/.local/share/fonts/JetBrainsMono-Regular-Nerd-Font.ttf ]; then \
		echo "  Downloading JetBrains Mono Nerd Font..."; \
		curl -fLo ~/.local/share/fonts/JetBrainsMono-Regular-Nerd-Font.ttf \
			https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf; \
	fi
	@echo "  Updating font cache..."
	@fc-cache -fv ~/.local/share/fonts 2>/dev/null || true
endif
	@echo -e "${GREEN}✓${NC} Fonts installed"

# Install Starship prompt
install-starship:
	@echo -e "${BLUE}ℹ${NC} Installing Starship prompt..."
	@if command -v starship &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Starship already installed ($$(starship --version))"; \
	else \
		echo "  Downloading Starship installer..."; \
		curl -sS $(STARSHIP_INSTALLER) -o /tmp/install-starship.sh; \
		echo "  Running installer..."; \
		sh /tmp/install-starship.sh -y 2>&1 | tee -a $(LOG_FILE); \
		rm -f /tmp/install-starship.sh; \
		echo -e "${GREEN}✓${NC} Starship installed"; \
	fi
	@# Configure Starship
	@echo "  Creating Starship configuration..."
	@mkdir -p ~/.config
	@if [ ! -f ~/.config/starship.toml ]; then \
		echo '# Starship Configuration' > ~/.config/starship.toml; \
		echo 'format = """$$all$$character"""' >> ~/.config/starship.toml; \
		echo '' >> ~/.config/starship.toml; \
		echo '[character]' >> ~/.config/starship.toml; \
		echo 'success_symbol = "[➜](bold green)"' >> ~/.config/starship.toml; \
		echo 'error_symbol = "[✗](bold red)"' >> ~/.config/starship.toml; \
		echo '' >> ~/.config/starship.toml; \
		echo '[directory]' >> ~/.config/starship.toml; \
		echo 'truncation_length = 3' >> ~/.config/starship.toml; \
		echo 'truncation_symbol = "…/"' >> ~/.config/starship.toml; \
	fi
	@# Add to shell RC
	@if [ "$(SHELL_TYPE)" = "bash" ]; then \
		grep -q 'eval "$$(starship init bash)"' ~/.bashrc 2>/dev/null || \
			echo 'eval "$$(starship init bash)"' >> ~/.bashrc; \
	elif [ "$(SHELL_TYPE)" = "zsh" ]; then \
		grep -q 'eval "$$(starship init zsh)"' ~/.zshrc 2>/dev/null || \
			echo 'eval "$$(starship init zsh)"' >> ~/.zshrc; \
	fi

# Install Powerline (optional)
install-powerline:
	@echo -e "${BLUE}ℹ${NC} Installing Powerline..."
	@if command -v pip3 &> /dev/null; then \
		pip3 install --user powerline-status 2>&1 | tee -a $(LOG_FILE) || \
			echo -e "${YELLOW}⚠${NC} Powerline installation failed"; \
	else \
		echo -e "${YELLOW}⚠${NC} pip3 not found, skipping Powerline"; \
	fi

# Configure shell settings
configure-shell:
	@echo -e "${BLUE}ℹ${NC} Configuring shell settings..."
	@# Bash configuration
	@if [ -f ~/.bashrc ]; then \
		echo "  Configuring Bash..."; \
		grep -q 'HISTSIZE=10000' ~/.bashrc || echo 'export HISTSIZE=10000' >> ~/.bashrc; \
		grep -q 'HISTFILESIZE=20000' ~/.bashrc || echo 'export HISTFILESIZE=20000' >> ~/.bashrc; \
		grep -q 'HISTCONTROL=ignoreboth' ~/.bashrc || echo 'export HISTCONTROL=ignoreboth:erasedups' >> ~/.bashrc; \
		grep -q 'shopt -s histappend' ~/.bashrc || echo 'shopt -s histappend' >> ~/.bashrc; \
		grep -q 'shopt -s checkwinsize' ~/.bashrc || echo 'shopt -s checkwinsize' >> ~/.bashrc; \
	fi
	@# Zsh configuration
	@if [ -f ~/.zshrc ]; then \
		echo "  Configuring Zsh..."; \
		grep -q 'HISTSIZE=10000' ~/.zshrc || echo 'export HISTSIZE=10000' >> ~/.zshrc; \
		grep -q 'SAVEHIST=20000' ~/.zshrc || echo 'export SAVEHIST=20000' >> ~/.zshrc; \
		grep -q 'setopt SHARE_HISTORY' ~/.zshrc || echo 'setopt SHARE_HISTORY' >> ~/.zshrc; \
		grep -q 'setopt HIST_EXPIRE_DUPS_FIRST' ~/.zshrc || echo 'setopt HIST_EXPIRE_DUPS_FIRST' >> ~/.zshrc; \
		grep -q 'setopt HIST_IGNORE_DUPS' ~/.zshrc || echo 'setopt HIST_IGNORE_DUPS' >> ~/.zshrc; \
		grep -q 'setopt HIST_VERIFY' ~/.zshrc || echo 'setopt HIST_VERIFY' >> ~/.zshrc; \
	fi
	@echo -e "${GREEN}✓${NC} Shell configured"

# Setup Oh-My-Bash/Zsh plugins
setup-plugins:
	@echo -e "${BLUE}ℹ${NC} Setting up shell plugins..."
	@# Oh-My-Bash plugins
	@if [ -d ~/.oh-my-bash ]; then \
		echo "  Configuring Oh-My-Bash plugins..."; \
		if grep -q "^plugins=" ~/.bashrc 2>/dev/null; then \
			sed -i 's/^plugins=.*/plugins=(git bashmarks kubectl docker aws)/' ~/.bashrc; \
		else \
			echo 'plugins=(git bashmarks kubectl docker aws)' >> ~/.bashrc; \
		fi; \
	fi
	@# Oh-My-Zsh plugins
	@if [ -d ~/.oh-my-zsh ]; then \
		echo "  Configuring Oh-My-Zsh plugins..."; \
		if grep -q "^plugins=" ~/.zshrc 2>/dev/null; then \
			if [ "$$(uname)" = "Darwin" ]; then \
				sed -i '' 's/^plugins=.*/plugins=(git docker kubectl aws terraform helm z sudo)/' ~/.zshrc; \
			else \
				sed -i 's/^plugins=.*/plugins=(git docker kubectl aws terraform helm z sudo)/' ~/.zshrc; \
			fi; \
		else \
			echo 'plugins=(git docker kubectl aws terraform helm z sudo)' >> ~/.zshrc; \
		fi; \
		if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then \
			echo "  Installing zsh-autosuggestions..."; \
			git clone https://github.com/zsh-users/zsh-autosuggestions \
				~/.oh-my-zsh/custom/plugins/zsh-autosuggestions 2>/dev/null || true; \
		fi; \
		if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then \
			echo "  Installing zsh-syntax-highlighting..."; \
			git clone https://github.com/zsh-users/zsh-syntax-highlighting \
				~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting 2>/dev/null || true; \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Plugins configured"

# Configure useful aliases
configure-aliases:
	@echo -e "${BLUE}ℹ${NC} Configuring shell aliases..."
	@# Create aliases file
	@mkdir -p $(ARMYKNIFE_CONFIG_DIR)
	@echo '# ArmyknifeLabs Shell Aliases' > $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo '' >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo '# Navigation' >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias ..='cd ..'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias ...='cd ../..'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias ....='cd ../../..'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias ~='cd ~'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias -- -='cd -'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo '' >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo '# Git shortcuts' >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias g='git'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias gs='git status'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias ga='git add'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias gc='git commit'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias gp='git push'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias gl='git pull'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo '' >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo '# Docker shortcuts' >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias d='docker'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias dc='docker-compose'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias dps='docker ps'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo '' >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo '# Kubernetes shortcuts' >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias k='kubectl'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias kgp='kubectl get pods'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo '' >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo '# ArmyknifeLabs shortcuts' >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias ak='make -C ~/armyknife-platform'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@echo "alias armyknife='ak'" >> $(ARMYKNIFE_CONFIG_DIR)/aliases.sh
	@# Source aliases in shell RC
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ]; then \
			grep -q 'source.*aliases.sh' $$rc || \
				echo "source $(ARMYKNIFE_CONFIG_DIR)/aliases.sh" >> $$rc; \
		fi; \
	done
	@echo -e "${GREEN}✓${NC} Aliases configured"

# Integrate ArmyknifeLabs libraries
integrate-armyknife:
	@echo -e "${BLUE}ℹ${NC} Integrating ArmyknifeLabs into shell..."
	@# Add to bashrc
	@if [ -f ~/.bashrc ]; then \
		if ! grep -q "ArmyknifeLabs Platform" ~/.bashrc; then \
			echo "" >> ~/.bashrc; \
			echo "# ArmyknifeLabs Platform Integration" >> ~/.bashrc; \
			echo 'if [ -d "$$HOME/.armyknife/lib" ]; then' >> ~/.bashrc; \
			echo '    for lib in "$$HOME/.armyknife/lib"/*.sh; do' >> ~/.bashrc; \
			echo '        [ -f "$$lib" ] && source "$$lib"' >> ~/.bashrc; \
			echo '    done' >> ~/.bashrc; \
			echo 'fi' >> ~/.bashrc; \
			echo 'export PATH="$$HOME/.armyknife/bin:$$PATH"' >> ~/.bashrc; \
		fi; \
	fi
	@# Add to zshrc
	@if [ -f ~/.zshrc ]; then \
		if ! grep -q "ArmyknifeLabs Platform" ~/.zshrc; then \
			echo "" >> ~/.zshrc; \
			echo "# ArmyknifeLabs Platform Integration" >> ~/.zshrc; \
			echo 'if [ -d "$$HOME/.armyknife/lib" ]; then' >> ~/.zshrc; \
			echo '    for lib in "$$HOME/.armyknife/lib"/*.sh; do' >> ~/.zshrc; \
			echo '        [ -f "$$lib" ] && source "$$lib"' >> ~/.zshrc; \
			echo '    done' >> ~/.zshrc; \
			echo 'fi' >> ~/.zshrc; \
			echo 'export PATH="$$HOME/.armyknife/bin:$$PATH"' >> ~/.zshrc; \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} ArmyknifeLabs integrated"

# Verify shell installation
verify-shell:
	@echo -e "${BLUE}ℹ${NC} Verifying shell configuration..."
	@# Check Oh-My-Bash/Zsh
	@if [ -d ~/.oh-my-bash ] || [ -d ~/.oh-my-zsh ]; then \
		echo -e "  ${GREEN}✓${NC} Oh-My-Shell installed"; \
	else \
		echo -e "  ${RED}✗${NC} Oh-My-Shell not installed"; \
	fi
	@# Check Starship
	@if command -v starship &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Starship installed ($$(starship --version))"; \
	else \
		echo -e "  ${YELLOW}⚠${NC} Starship not installed"; \
	fi
	@# Check fonts
	@if [ -d ~/.local/share/fonts ] && ls ~/.local/share/fonts/*Nerd* &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Nerd Fonts installed"; \
	elif [ "$(IS_MACOS)" = "true" ] && brew list --cask | grep -q font-.*nerd; then \
		echo -e "  ${GREEN}✓${NC} Nerd Fonts installed via Homebrew"; \
	else \
		echo -e "  ${YELLOW}⚠${NC} Nerd Fonts not installed"; \
	fi
	@# Check integration
	@if grep -q "ArmyknifeLabs" ~/.bashrc ~/.zshrc 2>/dev/null; then \
		echo -e "  ${GREEN}✓${NC} ArmyknifeLabs integrated in shell"; \
	else \
		echo -e "  ${YELLOW}⚠${NC} ArmyknifeLabs not integrated"; \
	fi
	@echo -e "${GREEN}✓${NC} Shell verification complete"

# Update shell components
update-shell:
	@echo -e "${BLUE}ℹ${NC} Updating shell components..."
	@# Update Oh-My-Bash
	@if [ -d ~/.oh-my-bash ]; then \
		echo "  Updating Oh-My-Bash..."; \
		cd ~/.oh-my-bash && git pull 2>&1 | tee -a $(LOG_FILE); \
	fi
	@# Update Oh-My-Zsh
	@if [ -d ~/.oh-my-zsh ]; then \
		echo "  Updating Oh-My-Zsh..."; \
		cd ~/.oh-my-zsh && git pull 2>&1 | tee -a $(LOG_FILE); \
	fi
	@# Update Starship
	@if command -v starship &> /dev/null; then \
		echo "  Updating Starship..."; \
		curl -sS $(STARSHIP_INSTALLER) | sh -s -- -y 2>&1 | tee -a $(LOG_FILE); \
	fi
	@echo -e "${GREEN}✓${NC} Shell components updated"

# Clean shell artifacts
clean-shell:
	@echo -e "${YELLOW}⚠${NC} Cleaning shell artifacts..."
	@rm -rf /tmp/install-om*.sh /tmp/install-starship.sh
	@echo -e "${GREEN}✓${NC} Shell cleanup complete"

# Help for shell module
help-shell:
	@echo "ArmyknifeLabs Shell Configuration Module"
	@echo ""
	@echo "Targets:"
	@echo "  all                 - Install and configure complete shell environment"
	@echo "  install-oh-my-bash  - Install Oh-My-Bash (Linux)"
	@echo "  install-oh-my-zsh   - Install Oh-My-Zsh (macOS/Linux)"
	@echo "  install-starship    - Install Starship prompt"
	@echo "  install-fonts       - Install Nerd Fonts"
	@echo "  configure-aliases   - Setup useful shell aliases"
	@echo "  verify-shell        - Verify shell installation"
	@echo "  update-shell        - Update shell components"
	@echo "  clean-shell         - Clean temporary files"
	@echo ""
	@echo "Current Shell: $(SHELL_TYPE)"
	@echo "OS Type: $(OS_TYPE)"