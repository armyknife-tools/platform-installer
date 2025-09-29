# ArmyknifeLabs Platform Installer - Containers & Kubernetes Module
# Makefile.Containers.mk

ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-$(shell date +%Y%m%d-%H%M%S).log

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# OS detection
OS_TYPE := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo macos)
IS_MACOS := $(shell [[ "$$(uname -s)" == "Darwin" ]] && echo true || echo false)
IS_LINUX := $(shell [[ "$$(uname -s)" == "Linux" ]] && echo true || echo false)
PACKAGE_MANAGER := $(if $(filter ubuntu debian linuxmint,$(OS_TYPE)),apt,$(if $(filter fedora rhel,$(OS_TYPE)),dnf,brew))
SUDO := $(if $(IS_MACOS),,sudo)

.PHONY: all install-docker install-podman install-kubernetes-tools install-container-tools verify-containers

all: install-docker install-podman install-kubernetes-tools install-container-tools verify-containers

install-docker:
	@echo -e "${BLUE}ℹ${NC} Installing Docker..."
ifeq ($(IS_MACOS),true)
	@if ! command -v docker &> /dev/null; then \
		echo "  Installing Docker Desktop for Mac..."; \
		brew install --cask docker; \
		echo -e "${YELLOW}⚠${NC} Please start Docker Desktop from Applications"; \
	else \
		echo -e "${GREEN}✓${NC} Docker already installed"; \
	fi
else ifeq ($(IS_LINUX),true)
	@if ! command -v docker &> /dev/null; then \
		echo "  Installing Docker CE..."; \
		if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt update; \
			$(SUDO) apt install -y ca-certificates curl gnupg lsb-release; \
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $(SUDO) gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; \
			echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $$(lsb_release -cs) stable" | \
				$(SUDO) tee /etc/apt/sources.list.d/docker.list; \
			$(SUDO) apt update; \
			$(SUDO) apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin; \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y dnf-plugins-core; \
			$(SUDO) dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo; \
			$(SUDO) dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin; \
		fi; \
		$(SUDO) systemctl enable --now docker; \
		$(SUDO) usermod -aG docker $$USER 2>/dev/null || true; \
		echo -e "${YELLOW}⚠${NC} Log out and back in for docker group to take effect"; \
	else \
		echo -e "${GREEN}✓${NC} Docker already installed"; \
	fi
endif
	@# Install Docker Compose standalone
	@if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then \
		echo "  Installing Docker Compose..."; \
		if [ "$(IS_LINUX)" = "true" ]; then \
			$(SUDO) curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$$(uname -s)-$$(uname -m)" -o /usr/local/bin/docker-compose; \
			$(SUDO) chmod +x /usr/local/bin/docker-compose; \
		fi; \
	fi

install-podman:
	@echo -e "${BLUE}ℹ${NC} Installing Podman..."
ifeq ($(IS_LINUX),true)
	@if ! command -v podman &> /dev/null; then \
		if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y podman; \
		elif [ "$(PACKAGE_MANAGER)" = "dnf" ]; then \
			$(SUDO) dnf install -y podman; \
		fi; \
		echo -e "${GREEN}✓${NC} Podman installed"; \
	else \
		echo -e "${GREEN}✓${NC} Podman already installed"; \
	fi
else
	@echo "  Skipping Podman (Linux only)"
endif

install-kubernetes-tools:
	@echo -e "${BLUE}ℹ${NC} Installing Kubernetes tools..."
	@# kubectl
	@if ! command -v kubectl &> /dev/null; then \
		echo "  Installing kubectl..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install kubectl; \
		else \
			curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; \
			$(SUDO) install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; \
			rm kubectl; \
		fi; \
	fi
	@# helm
	@if ! command -v helm &> /dev/null; then \
		echo "  Installing Helm..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install helm; \
		else \
			curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; \
		fi; \
	fi
	@# k9s
	@if ! command -v k9s &> /dev/null; then \
		echo "  Installing k9s..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install k9s; \
		elif command -v go &> /dev/null; then \
			go install github.com/derailed/k9s@latest; \
		fi; \
	fi
	@# minikube
	@if ! command -v minikube &> /dev/null; then \
		echo "  Installing minikube..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install minikube; \
		elif [ "$(IS_LINUX)" = "true" ]; then \
			curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64; \
			$(SUDO) install minikube-linux-amd64 /usr/local/bin/minikube; \
			rm minikube-linux-amd64; \
		fi; \
	fi
	@# kind
	@if ! command -v kind &> /dev/null; then \
		echo "  Installing kind..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install kind; \
		elif command -v go &> /dev/null; then \
			go install sigs.k8s.io/kind@latest; \
		fi; \
	fi
	@# kubectx & kubens
	@if ! command -v kubectx &> /dev/null; then \
		echo "  Installing kubectx/kubens..."; \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install kubectx; \
		else \
			git clone https://github.com/ahmetb/kubectx /tmp/kubectx; \
			$(SUDO) cp /tmp/kubectx/kubectx /usr/local/bin/; \
			$(SUDO) cp /tmp/kubectx/kubens /usr/local/bin/; \
			rm -rf /tmp/kubectx; \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Kubernetes tools installed"

install-container-tools:
	@echo -e "${BLUE}ℹ${NC} Installing container utilities..."
	@# dive
	@if ! command -v dive &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install dive; \
		elif command -v go &> /dev/null; then \
			go install github.com/wagoodman/dive@latest; \
		fi; \
	fi
	@# lazydocker
	@if ! command -v lazydocker &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install lazydocker; \
		elif command -v go &> /dev/null; then \
			go install github.com/jesseduffield/lazydocker@latest; \
		fi; \
	fi
	@# ctop
	@if ! command -v ctop &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install ctop; \
		else \
			$(SUDO) wget https://github.com/bcicen/ctop/releases/latest/download/ctop-$$(uname -s)-$$(uname -m) -O /usr/local/bin/ctop; \
			$(SUDO) chmod +x /usr/local/bin/ctop; \
		fi; \
	fi
	@echo -e "${GREEN}✓${NC} Container utilities installed"

verify-containers:
	@echo -e "${BLUE}ℹ${NC} Verifying container tools..."
	@if command -v docker &> /dev/null; then \
		echo -e "  ${GREEN}✓${NC} Docker: $$(docker --version | cut -d' ' -f3 | tr -d ',')"; \
		if docker info &> /dev/null; then \
			echo -e "  ${GREEN}✓${NC} Docker daemon is running"; \
		else \
			echo -e "  ${YELLOW}⚠${NC} Docker daemon not accessible"; \
		fi; \
	else \
		echo -e "  ${RED}✗${NC} Docker not found"; \
	fi
	@for tool in podman kubectl helm k9s minikube kind kubectx dive lazydocker ctop; do \
		if command -v $$tool &> /dev/null; then \
			echo -e "  ${GREEN}✓${NC} $$tool installed"; \
		else \
			echo -e "  ${YELLOW}⚠${NC} $$tool not found"; \
		fi; \
	done
	@echo -e "${GREEN}✓${NC} Container verification complete"

update-containers:
	@echo -e "${BLUE}ℹ${NC} Updating container tools..."
	@if [ "$(IS_MACOS)" = "true" ]; then \
		brew upgrade docker kubectl helm k9s minikube kind 2>/dev/null || true; \
	fi
	@echo -e "${GREEN}✓${NC} Container tools updated"