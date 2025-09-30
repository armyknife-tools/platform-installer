# ArmyknifeLabs Platform Installer - Network Tools Module
# Makefile.Network.mk
#
# Network management, VPN, and fleet management tools

# Import parent variables
ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-network-$(shell date +%Y%m%d-%H%M%S).log
NETWORK_DIR := $(ARMYKNIFE_DIR)/network

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
OS_LIKE := $(shell . /etc/os-release 2>/dev/null && echo $$ID_LIKE || echo "")
IS_MACOS := $(shell if [ "$$(uname -s)" = "Darwin" ]; then echo true; else echo false; fi)
IS_LINUX := $(shell if [ "$$(uname -s)" = "Linux" ]; then echo true; else echo false; fi)
ARCH := $(shell uname -m)

# Package manager
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

# Phony targets
.PHONY: all minimal install-vpn install-tailscale install-wireguard \
        install-network-tools install-monitoring install-fleet-management \
        configure-network verify-network

# Main target
all: install-vpn install-network-tools install-monitoring \
     install-fleet-management configure-network verify-network

# Minimal installation
minimal: install-tailscale install-network-tools configure-network

# Install VPN tools
install-vpn: install-tailscale install-wireguard
	@echo -e "${GREEN}✓${NC} VPN tools installed"

# Install Tailscale
install-tailscale:
	@echo -e "${BLUE}ℹ${NC} Installing Tailscale..."
	@mkdir -p $$(dirname $(LOG_FILE))
ifeq ($(PACKAGE_MANAGER),apt)
	@# Add Tailscale GPG key and repository
	@curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | \
		$(SUDO) tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
	@curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | \
		$(SUDO) tee /etc/apt/sources.list.d/tailscale.list
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) apt install -y tailscale 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@if ! command -v tailscale &> /dev/null; then \
		brew install --cask tailscale; \
	fi
endif
	@echo -e "${GREEN}✓${NC} Tailscale installed"
	@echo -e "${YELLOW}Note: Run 'sudo tailscale up' to connect${NC}"

# Install WireGuard
install-wireguard:
	@echo -e "${BLUE}ℹ${NC} Installing WireGuard..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt install -y wireguard wireguard-tools 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(PACKAGE_MANAGER),dnf)
	@$(SUDO) dnf install -y wireguard-tools 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@if ! command -v wg &> /dev/null; then \
		brew install wireguard-tools; \
	fi
endif
	@echo -e "${GREEN}✓${NC} WireGuard installed"

# Install network tools
install-network-tools:
	@echo -e "${BLUE}ℹ${NC} Installing network tools..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt install -y \
		net-tools iproute2 iputils-ping traceroute \
		nmap tcpdump wireshark tshark \
		iperf3 mtr-tiny netcat-openbsd \
		dnsutils whois curl wget \
		socat bridge-utils ethtool \
		iftop nethogs bandwhich \
		2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@brew install \
		nmap tcpdump wireshark \
		iperf3 mtr netcat \
		socat wget curl \
		iftop bandwhich \
		2>/dev/null || true
endif
	@# Install modern network tools via cargo if available
	@if command -v cargo &> /dev/null; then \
		cargo install bandwhich 2>/dev/null || true; \
		cargo install gping 2>/dev/null || true; \
		cargo install sniffnet 2>/dev/null || true; \
		cargo install netscanner 2>/dev/null || true; \
	fi
	@echo -e "${GREEN}✓${NC} Network tools installed"

# Install monitoring tools
install-monitoring:
	@echo -e "${BLUE}ℹ${NC} Installing monitoring tools..."
	@# Install netdata for system monitoring
ifeq ($(PACKAGE_MANAGER),apt)
	@curl -s https://packagecloud.io/install/repositories/netdata/netdata/script.deb.sh | \
		$(SUDO) bash 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) apt install -y netdata 2>&1 | tee -a $(LOG_FILE) || true
endif
	@# Install additional monitoring tools
	@if command -v npm &> /dev/null; then \
		npm install -g vtop gtop 2>/dev/null || true; \
	fi
	@if command -v pip3 &> /dev/null; then \
		pip3 install --user glances 2>/dev/null || true; \
	fi
	@echo -e "${GREEN}✓${NC} Monitoring tools installed"

# Install fleet management tools
install-fleet-management:
	@echo -e "${BLUE}ℹ${NC} Installing fleet management tools..."
	@# Install Ansible
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt install -y ansible ansible-lint 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@brew install ansible ansible-lint 2>/dev/null || true
endif
	@# Install Salt (SaltStack) - optional, may fail on some systems
	@echo -e "${YELLOW}Installing Salt (optional)...${NC}"
	@if ! command -v salt-minion &> /dev/null; then \
		curl -L https://bootstrap.saltproject.io -o /tmp/install_salt.sh 2>/dev/null && \
		chmod +x /tmp/install_salt.sh && \
		$(SUDO) bash /tmp/install_salt.sh -P 2>&1 | tee -a $(LOG_FILE) || \
		echo -e "${YELLOW}⚠ Salt installation failed (optional component)${NC}"; \
		rm -f /tmp/install_salt.sh; \
	else \
		echo -e "${GREEN}✓${NC} Salt already installed"; \
	fi
	@echo -e "${GREEN}✓${NC} Fleet management tools installed"

# Configure network settings
configure-network:
	@echo -e "${BLUE}ℹ${NC} Configuring network settings..."
	@mkdir -p $(NETWORK_DIR)/configs
	@# Create network utilities script
	@echo '#!/bin/bash' > $(NETWORK_DIR)/network-utils.sh
	@echo '# Network utility functions' >> $(NETWORK_DIR)/network-utils.sh
	@echo '' >> $(NETWORK_DIR)/network-utils.sh
	@echo '# Show network interfaces' >> $(NETWORK_DIR)/network-utils.sh
	@echo 'net_interfaces() {' >> $(NETWORK_DIR)/network-utils.sh
	@echo '    ip -c -br addr' >> $(NETWORK_DIR)/network-utils.sh
	@echo '}' >> $(NETWORK_DIR)/network-utils.sh
	@echo '' >> $(NETWORK_DIR)/network-utils.sh
	@echo '# Test connectivity' >> $(NETWORK_DIR)/network-utils.sh
	@echo 'net_test() {' >> $(NETWORK_DIR)/network-utils.sh
	@echo '    echo "Testing connectivity..."' >> $(NETWORK_DIR)/network-utils.sh
	@echo '    ping -c 1 8.8.8.8 &>/dev/null && echo "✓ Internet connected" || echo "✗ No internet"' >> $(NETWORK_DIR)/network-utils.sh
	@echo '    ping -c 1 github.com &>/dev/null && echo "✓ DNS working" || echo "✗ DNS issues"' >> $(NETWORK_DIR)/network-utils.sh
	@echo '}' >> $(NETWORK_DIR)/network-utils.sh
	@chmod +x $(NETWORK_DIR)/network-utils.sh
	@echo -e "${GREEN}✓${NC} Network configured"

# Verify installation
verify-network:
	@echo -e "${BLUE}ℹ${NC} Verifying network tools installation..."
	@echo "VPN Tools:"
	@command -v tailscale &> /dev/null && echo -e "  ${GREEN}✓${NC} Tailscale" || echo -e "  ${RED}✗${NC} Tailscale"
	@command -v wg &> /dev/null && echo -e "  ${GREEN}✓${NC} WireGuard" || echo -e "  ${RED}✗${NC} WireGuard"
	@echo ""
	@echo "Network Tools:"
	@command -v nmap &> /dev/null && echo -e "  ${GREEN}✓${NC} nmap" || echo -e "  ${RED}✗${NC} nmap"
	@command -v tcpdump &> /dev/null && echo -e "  ${GREEN}✓${NC} tcpdump" || echo -e "  ${RED}✗${NC} tcpdump"
	@command -v iperf3 &> /dev/null && echo -e "  ${GREEN}✓${NC} iperf3" || echo -e "  ${RED}✗${NC} iperf3"
	@command -v mtr &> /dev/null && echo -e "  ${GREEN}✓${NC} mtr" || echo -e "  ${RED}✗${NC} mtr"
	@echo ""
	@echo "Fleet Management:"
	@command -v ansible &> /dev/null && echo -e "  ${GREEN}✓${NC} Ansible" || echo -e "  ${RED}✗${NC} Ansible"
	@command -v salt &> /dev/null && echo -e "  ${GREEN}✓${NC} Salt" || echo -e "  ${YELLOW}⚠${NC} Salt (optional)"
	@echo ""
	$(call show_completion_banner,NETWORK READY)
	@echo -e "${GREEN}✓${NC} Network verification complete"

# Help target
help-network:
	@echo "ArmyknifeLabs Network Tools Module"
	@echo "=================================="
	@echo ""
	@echo "Targets:"
	@echo "  all                   - Install all network tools"
	@echo "  minimal               - Install essential network tools"
	@echo "  install-vpn           - Install VPN tools (Tailscale, WireGuard)"
	@echo "  install-tailscale     - Install Tailscale VPN"
	@echo "  install-wireguard     - Install WireGuard VPN"
	@echo "  install-network-tools - Install network utilities"
	@echo "  install-monitoring    - Install monitoring tools"
	@echo "  install-fleet-management - Install Ansible, Salt"
	@echo "  verify-network        - Verify installations"
	@echo ""
	@echo "Usage:"
	@echo "  make -f makefiles/Makefile.Network.mk all"
	@echo "  make -f makefiles/Makefile.Network.mk minimal"