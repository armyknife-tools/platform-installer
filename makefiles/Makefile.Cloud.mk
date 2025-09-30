# ArmyknifeLabs Platform Installer - Cloud Providers Module
# Makefile.Cloud.mk

ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-$(shell date +%Y%m%d-%H%M%S).log
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

# Shell configuration - use bash for all commands
SHELL := /bin/bash
.SHELLFLAGS := -ec

OS_TYPE := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo macos)
IS_MACOS := $(shell if [ "$$(uname -s)" = "Darwin" ]; then echo true; else echo false; fi)
PACKAGE_MANAGER := $(if $(filter ubuntu debian linuxmint,$(OS_TYPE)),apt,$(if $(filter fedora rhel,$(OS_TYPE)),dnf,brew))
SUDO := $(if $(IS_MACOS),,sudo)

.PHONY: all install-aws install-azure install-gcp install-terraform verify-cloud

all: install-aws install-azure install-gcp install-terraform verify-cloud

install-aws:
	@echo -e "${BLUE}ℹ${NC} Installing AWS CLI..."
	@if ! command -v aws &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install awscli; \
		else \
			curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip; \
			unzip -q /tmp/awscliv2.zip -d /tmp/; \
			$(SUDO) /tmp/aws/install; \
			rm -rf /tmp/awscliv2.zip /tmp/aws; \
		fi; \
	else \
		echo -e "${GREEN}✓${NC} AWS CLI already installed"; \
	fi
	@# aws-vault
	@if ! command -v aws-vault &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install --cask aws-vault; \
		elif command -v go &> /dev/null; then \
			go install github.com/99designs/aws-vault/v7@latest; \
		fi; \
	fi

install-azure:
	@echo -e "${BLUE}ℹ${NC} Installing Azure CLI..."
	@if ! command -v az &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install azure-cli; \
		elif [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			curl -sL https://aka.ms/InstallAzureCLIDeb | $(SUDO) bash; \
		fi; \
	else \
		echo -e "${GREEN}✓${NC} Azure CLI already installed"; \
	fi

install-gcp:
	@echo -e "${BLUE}ℹ${NC} Installing Google Cloud SDK..."
	@if ! command -v gcloud &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install --cask google-cloud-sdk; \
		else \
			echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
				$(SUDO) tee /etc/apt/sources.list.d/google-cloud-sdk.list; \
			curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
				$(SUDO) apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -; \
			$(SUDO) apt update && $(SUDO) apt install -y google-cloud-sdk; \
		fi; \
	else \
		echo -e "${GREEN}✓${NC} Google Cloud SDK already installed"; \
	fi

install-terraform:
	@echo -e "${BLUE}ℹ${NC} Installing Terraform..."
	@if ! command -v terraform &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install terraform; \
		else \
			wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | $(SUDO) tee /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
			echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | \
				$(SUDO) tee /etc/apt/sources.list.d/hashicorp.list; \
			$(SUDO) apt update && $(SUDO) apt install -y terraform; \
		fi; \
	else \
		echo -e "${GREEN}✓${NC} Terraform already installed"; \
	fi
	@# terragrunt
	@if ! command -v terragrunt &> /dev/null; then \
		if [ "$(IS_MACOS)" = "true" ]; then \
			brew install terragrunt; \
		fi; \
	fi

verify-cloud:
	@echo -e "${BLUE}ℹ${NC} Verifying cloud tools..."
	@for tool in aws az gcloud terraform terragrunt aws-vault; do \
		if command -v $$tool &> /dev/null; then \
			echo -e "  ${GREEN}✓${NC} $$tool installed"; \
		else \
			echo -e "  ${YELLOW}⚠${NC} $$tool not found"; \
		fi; \
	done

update-cloud-tools:
	@echo -e "${BLUE}ℹ${NC} Updating cloud tools..."
	@if [ "$(IS_MACOS)" = "true" ]; then \
		brew upgrade awscli azure-cli terraform terragrunt 2>/dev/null || true; \
	fi
	@if command -v gcloud &> /dev/null; then \
		gcloud components update --quiet 2>/dev/null || true; \
	fi
