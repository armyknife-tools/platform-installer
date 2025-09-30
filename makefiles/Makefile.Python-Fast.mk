# ArmyknifeLabs Platform Installer - Fast Python Setup
# Makefile.Python-Fast.mk
#
# Quick Python setup using system Python and modern tools
# Avoids lengthy Python compilation from source

# Import parent variables
ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-python-fast-$(shell date +%Y%m%d-%H%M%S).log
PYTHON_DIR := $(ARMYKNIFE_DIR)/python

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

# Core installers
UV_INSTALLER := https://astral.sh/uv/install.sh
POETRY_INSTALLER := https://install.python-poetry.org

# Phony targets
.PHONY: all install-uv install-pipx install-essential-tools install-dev-tools \
        install-data-science-core install-web-core verify-python-fast

# Main target - fast setup
all: install-uv install-pipx install-essential-tools install-dev-tools \
     install-data-science-core install-web-core verify-python-fast

# Install uv - the fastest Python package manager
install-uv:
	@echo -e "${BLUE}ℹ${NC} Installing uv (ultra-fast Python package manager)..."
	@if command -v uv &> /dev/null; then \
		echo -e "${GREEN}✓${NC} uv already installed, updating..."; \
		uv self update 2>/dev/null || true; \
	else \
		curl -LsSf $(UV_INSTALLER) | sh; \
		echo -e "${GREEN}✓${NC} uv installed"; \
	fi
	@echo 'export PATH="$$HOME/.cargo/bin:$$PATH"' >> ~/.bashrc

# Install pipx for isolated tools
install-pipx:
	@echo -e "${BLUE}ℹ${NC} Installing pipx..."
	@if command -v pipx &> /dev/null; then \
		echo -e "${GREEN}✓${NC} pipx already installed"; \
	else \
		if command -v uv &> /dev/null; then \
			uv tool install pipx && \
			echo -e "${GREEN}✓${NC} pipx installed via uv"; \
		else \
			python3 -m ensurepip --user 2>/dev/null || true && \
			python3 -m pip install --user pipx 2>/dev/null && \
			python3 -m pipx ensurepath || \
			echo -e "${YELLOW}⚠${NC} Could not install pipx, continuing..."; \
		fi; \
	fi

# Install essential Python tools
install-essential-tools:
	@echo -e "${BLUE}ℹ${NC} Installing essential Python tools..."
	@# Use uv tool if available, fallback to pipx
	@if command -v uv &> /dev/null; then \
		uv tool install black || true; \
		uv tool install ruff || true; \
		uv tool install mypy || true; \
		uv tool install isort || true; \
		uv tool install pytest || true; \
		uv tool install tox || true; \
		uv tool install poetry || true; \
	elif command -v pipx &> /dev/null; then \
		pipx install black || true; \
		pipx install ruff || true; \
		pipx install mypy || true; \
		pipx install isort || true; \
		pipx install pytest || true; \
		pipx install tox || true; \
		pipx install poetry || true; \
	fi
	@echo -e "${GREEN}✓${NC} Essential tools installed"

# Install development tools
install-dev-tools:
	@echo -e "${BLUE}ℹ${NC} Installing development tools..."
	@pipx install ipython || true
	@pipx install jupyter || true
	@pipx install pre-commit || true
	@pipx install cookiecutter || true
	@pipx install httpie || true
	@pipx install tldr || true
	@echo -e "${GREEN}✓${NC} Development tools installed"

# Install data science core
install-data-science-core:
	@echo -e "${BLUE}ℹ${NC} Setting up data science environment..."
	@mkdir -p $(PYTHON_DIR)/envs
	@# Create a data science virtual environment using uv
	@if command -v uv &> /dev/null; then \
		cd $(PYTHON_DIR)/envs && \
		uv venv datascience && \
		source datascience/bin/activate && \
		uv pip install numpy pandas matplotlib seaborn scikit-learn jupyter notebook; \
		echo -e "${GREEN}✓${NC} Data science environment created at $(PYTHON_DIR)/envs/datascience"; \
	else \
		echo -e "${YELLOW}⚠${NC} uv not found, skipping data science setup"; \
	fi

# Install web development core
install-web-core:
	@echo -e "${BLUE}ℹ${NC} Installing web framework tools..."
	@pipx install fastapi || true
	@pipx install django || true
	@pipx install flask || true
	@pipx install uvicorn || true
	@pipx install gunicorn || true
	@echo -e "${GREEN}✓${NC} Web tools installed"

# Verify installation
verify-python-fast:
	@echo -e "${BLUE}ℹ${NC} Verifying fast Python setup..."
	@echo "=== Python Version ==="
	@python3 --version
	@echo ""
	@echo "=== Installed Tools ==="
	@command -v uv &> /dev/null && echo -e "  ${GREEN}✓${NC} uv installed"
	@command -v pipx &> /dev/null && echo -e "  ${GREEN}✓${NC} pipx installed"
	@command -v black &> /dev/null && echo -e "  ${GREEN}✓${NC} black installed"
	@command -v ruff &> /dev/null && echo -e "  ${GREEN}✓${NC} ruff installed"
	@command -v pytest &> /dev/null && echo -e "  ${GREEN}✓${NC} pytest installed"
	@command -v poetry &> /dev/null && echo -e "  ${GREEN}✓${NC} poetry installed"
	@command -v jupyter &> /dev/null && echo -e "  ${GREEN}✓${NC} jupyter installed"
	@echo ""
	@echo -e "${GREEN}✓${NC} Fast Python setup complete!"
	@echo ""
	@echo "To create a new project with uv:"
	@echo "  uv venv myproject"
	@echo "  cd myproject && source .venv/bin/activate"
	@echo "  uv pip install requests fastapi"

# Help
help:
	@echo "Fast Python Setup - Using system Python with modern tools"
	@echo ""
	@echo "This avoids the lengthy Python compilation process and uses:"
	@echo "  - System Python 3"
	@echo "  - uv for ultra-fast package management"
	@echo "  - pipx for isolated tool installations"
	@echo ""
	@echo "Targets:"
	@echo "  all                     - Install everything"
	@echo "  install-uv              - Install uv package manager"
	@echo "  install-pipx            - Install pipx"
	@echo "  install-essential-tools - Black, ruff, pytest, etc."
	@echo "  install-dev-tools       - IPython, Jupyter, etc."
	@echo "  install-data-science-core - NumPy, pandas, etc."
	@echo "  install-web-core        - FastAPI, Django, Flask"
	@echo "  verify-python-fast      - Verify installation"