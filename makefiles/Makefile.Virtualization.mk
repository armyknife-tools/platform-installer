# ArmyknifeLabs Platform Installer - Virtualization Module
# Makefile.Virtualization.mk

ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-$(shell date +%Y%m%d-%H%M%S).log
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

OS_TYPE := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo macos)
IS_MACOS := $(shell [[ "$$(uname -s)" == "Darwin" ]] && echo true || echo false)
IS_LINUX := $(shell [[ "$$(uname -s)" == "Linux" ]] && echo true || echo false)
PACKAGE_MANAGER := $(if $(filter ubuntu debian linuxmint,$(OS_TYPE)),apt,$(if $(filter fedora rhel,$(OS_TYPE)),dnf,brew))
SUDO := $(if $(IS_MACOS),,sudo)

.PHONY: all install-virtualbox install-vagrant install-packer verify-virtualization

all: install-virtualbox install-vagrant install-packer verify-virtualization

install-virtualbox:
	@echo -e "${BLUE}ℹ${NC} Installing VirtualBox..."
ifeq ($(IS_MACOS),true)
	@if ! command -v VBoxManage &> /dev/null; then \
		brew install --cask virtualbox virtualbox-extension-pack; \
	else \
		echo -e "${GREEN}✓${NC} VirtualBox already installed"; \
	fi
else ifeq ($(IS_LINUX),true)
	@if ! command -v VBoxManage &> /dev/null; then \
		if [ "$(OS_TYPE)" = "ubuntu" ] || [ "$(OS_TYPE)" = "debian" ]; then \
			wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | $(SUDO) apt-key add -; \
			$(SUDO) add-apt-repository "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $$(lsb_release -cs) contrib"; \
			$(SUDO) apt update && $(SUDO) apt install -y virtualbox-7.0; \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y VirtualBox; \
		fi; \
	else \
		echo -e "${GREEN}✓${NC} VirtualBox already installed"; \
	fi
endif

install-vagrant:
	@echo -e "${BLUE}ℹ${NC} Installing Vagrant..."
	@if ! command -v vagrant &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install --cask vagrant; \
		else \
			wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | $(SUDO) tee /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
			echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | \
				$(SUDO) tee /etc/apt/sources.list.d/hashicorp.list; \
			$(SUDO) apt update && $(SUDO) apt install -y vagrant; \
		fi; \
	else \
		echo -e "${GREEN}✓${NC} Vagrant already installed"; \
	fi
	@# Install plugins
	@vagrant plugin install vagrant-vbguest vagrant-disksize vagrant-hostmanager 2>/dev/null || true

install-packer:
	@echo -e "${BLUE}ℹ${NC} Installing Packer..."
	@if ! command -v packer &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install packer; \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y packer; \
		fi; \
	else \
		echo -e "${GREEN}✓${NC} Packer already installed"; \
	fi

verify-virtualization:
	@echo -e "${BLUE}ℹ${NC} Verifying virtualization tools..."
	@for tool in VBoxManage vagrant packer; do \
		if command -v $$tool &> /dev/null; then \
			echo -e "  ${GREEN}✓${NC} $$tool installed"; \
		else \
			echo -e "  ${YELLOW}⚠${NC} $$tool not found"; \
		fi; \
	done
