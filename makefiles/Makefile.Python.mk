# ArmyknifeLabs Platform Installer - Python Ecosystem Module
# Makefile.Python.mk
#
# The most comprehensive Python development environment ever created
# For: Data Scientists, AI/ML Engineers, Cybersecurity Experts, Cloud Engineers
# Features: Multiple Python versions, modern package managers, AI/ML frameworks,
#           security tools, cloud SDKs, data analysis tools, and more

# Import parent variables
ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-python-$(shell date +%Y%m%d-%H%M%S).log
PYTHON_DIR := $(ARMYKNIFE_DIR)/python

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

# Package manager - also check ID_LIKE for derivatives
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

# Python versions to install (comprehensive coverage)
# Note: Older versions may fail on newer systems due to SSL/pip issues
# Using system Python as fallback
PYTHON_VERSIONS := 3.11.10 3.12.7
DEFAULT_PYTHON := system

# Core Python tools
PYENV_INSTALLER := https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer
UV_INSTALLER := https://astral.sh/uv/install.sh
POETRY_INSTALLER := https://install.python-poetry.org
CONDA_INSTALLER := https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
MAMBA_INSTALLER := https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh

ifeq ($(IS_MACOS),true)
    ifeq ($(ARCH),arm64)
        CONDA_INSTALLER := https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh
        MAMBA_INSTALLER := https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh
    else
        CONDA_INSTALLER := https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
        MAMBA_INSTALLER := https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh
    endif
endif

# Phony targets
.PHONY: all install-system-deps install-pyenv install-uv install-poetry install-conda \
        install-mamba install-pipx install-python-versions install-formatters \
        install-modern-tools install-linters install-testers install-ml-frameworks \
        install-data-science install-cybersecurity install-cloud-tools install-web-frameworks \
        install-devtools install-jupyter configure-python verify-python \
        create-environments help-python

# IMPORTANT: System dependencies are REQUIRED for Python builds to work
# They are now the first step in all installation profiles

# Main target - install everything
all: install-system-deps install-pyenv install-python-versions install-uv \
     install-poetry install-conda install-mamba install-pipx install-formatters \
     install-modern-tools install-linters install-testers install-ml-frameworks \
     install-data-science install-cybersecurity install-cloud-tools install-web-frameworks \
     install-devtools install-jupyter configure-python create-environments verify-python

# Minimal install for quick setup
minimal: install-system-deps install-pyenv install-python-versions install-uv \
         install-pipx install-formatters install-linters configure-python

# Prerequisites only - useful for testing
prereqs: install-system-deps

# Check if prerequisites are installed
check-prereqs:
	@echo -e "${BLUE}ℹ${NC} Checking Python build prerequisites..."
	@missing=""; \
	for pkg in build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
	           libsqlite3-dev libffi-dev liblzma-dev; do \
		if ! dpkg -l | grep -q "^ii  $$pkg"; then \
			missing="$$missing $$pkg"; \
		fi; \
	done; \
	if [ -n "$$missing" ]; then \
		echo -e "${RED}✗${NC} Missing packages:$$missing"; \
		echo -e "${YELLOW}Run 'make prereqs' or 'sudo apt install$$missing'${NC}"; \
		exit 1; \
	else \
		echo -e "${GREEN}✓${NC} All prerequisites installed"; \
	fi

# Install system dependencies
install-system-deps:
	@echo -e "${BLUE}ℹ${NC} Installing Python system dependencies..."
	@echo -e "${YELLOW}⚠${NC} This requires sudo access to install system packages"
	@mkdir -p $$(dirname $(LOG_FILE))
ifeq ($(PACKAGE_MANAGER),apt)
	@# Fix Cursor GPG key issue if present
	@if [ -f /etc/apt/sources.list.d/cursor.list ] && ! [ -f /usr/share/keyrings/cursor-archive-keyring.gpg ]; then \
		echo -e "${YELLOW}Fixing Cursor repository GPG key...${NC}"; \
		curl -fsSL https://downloads.cursor.com/aptrepo/public.gpg.key | \
			$(SUDO) gpg --dearmor -o /usr/share/keyrings/cursor-archive-keyring.gpg 2>/dev/null || true; \
		echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cursor-archive-keyring.gpg] https://downloads.cursor.com/aptrepo stable main" | \
			$(SUDO) tee /etc/apt/sources.list.d/cursor.list > /dev/null; \
	fi
	@echo "Installing essential build dependencies for Python..."
	@# Try to update, but continue even if there are repo errors
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE) || true
	@echo "Installing packages (ignoring repository errors)..."
	@$(SUDO) apt install -y \
		build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
		libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
		xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git \
		libxml2-dev libxmlsec1-dev libffi-dev libcairo2-dev libgirepository1.0-dev \
		pkg-config python3-dev libpq-dev libmysqlclient-dev \
		libhdf5-dev libnetcdf-dev libopenblas-dev liblapack-dev gfortran \
		cmake ninja-build ccache swig \
		graphviz pandoc texlive-xetex texlive-fonts-recommended \
		2>&1 | tee -a $(LOG_FILE) || { \
			echo -e "${YELLOW}⚠${NC} Some packages may have failed to install"; \
			echo "Installing core dependencies only..."; \
			$(SUDO) apt install -y \
				build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
				libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
				xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git \
				2>&1 | tee -a $(LOG_FILE); \
		}
else ifeq ($(PACKAGE_MANAGER),dnf)
	@$(SUDO) dnf install -y gcc gcc-c++ make git patch openssl-devel \
		zlib-devel bzip2-devel readline-devel sqlite-devel tk-devel \
		libffi-devel xz-devel libuuid-devel gdbm-devel libxml2-devel \
		libxslt-devel cairo-devel cairo-gobject-devel \
		postgresql-devel mysql-devel hdf5-devel netcdf-devel \
		openblas-devel lapack-devel gcc-gfortran \
		cmake ninja-build ccache swig graphviz pandoc \
		2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@brew install openssl readline sqlite3 xz zlib tcl-tk libffi \
		libxml2 libxmlsec1 cairo pkg-config postgresql mysql hdf5 netcdf \
		openblas lapack gcc cmake ninja ccache swig graphviz pandoc \
		2>/dev/null || true
endif
	@echo -e "${GREEN}✓${NC} System dependencies installed"

# Install pyenv for Python version management
# Now depends on system deps to ensure prerequisites are installed
install-pyenv: install-system-deps
	@echo -e "${BLUE}ℹ${NC} Installing pyenv..."
	@if [ -d "$$HOME/.pyenv" ]; then \
		echo -e "${GREEN}✓${NC} pyenv already installed"; \
		# Skip update - can be done manually if needed \
	else \
		curl -L $(PYENV_INSTALLER) | bash 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} pyenv installed"; \
	fi
	@# Configure shell
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

# Install Python versions
install-python-versions:
	@echo -e "${BLUE}ℹ${NC} Installing Python versions..."
	@if [ -d "$$HOME/.pyenv" ]; then \
		export PYENV_ROOT="$$HOME/.pyenv" && \
		export PATH="$$PYENV_ROOT/bin:$$PATH" && \
		for version in $(PYTHON_VERSIONS); do \
			$(SHELL) scripts/install-python-pyenv.sh $$version 2>&1 | tee -a $(LOG_FILE) || \
			echo -e "  ${YELLOW}⚠${NC} Failed to install Python $$version, continuing..."; \
		done; \
		eval "$$($$HOME/.pyenv/bin/pyenv init --path)" && \
		if $$HOME/.pyenv/bin/pyenv versions | grep -q "3.12"; then \
			$$HOME/.pyenv/bin/pyenv global 3.12.7 2>/dev/null || $$HOME/.pyenv/bin/pyenv global system; \
		else \
			$$HOME/.pyenv/bin/pyenv global system; \
		fi; \
		$$HOME/.pyenv/bin/pyenv rehash; \
	else \
		echo -e "${YELLOW}⚠${NC} pyenv not installed, using system Python"; \
	fi
	@echo -e "${GREEN}✓${NC} Python setup complete"

# Install uv (Astral's ultra-fast Python package manager)
install-uv:
	@echo -e "${BLUE}ℹ${NC} Installing uv and uvx..."
	@if command -v uv &> /dev/null; then \
		echo -e "${GREEN}✓${NC} uv already installed, updating..."; \
		uv self update 2>/dev/null || true; \
	else \
		curl -LsSf $(UV_INSTALLER) | sh 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} uv installed"; \
	fi
	@# Configure uv
	@mkdir -p ~/.config/uv
	@echo "# UV Configuration" > ~/.config/uv/config.toml
	@echo "native-tls = true" >> ~/.config/uv/config.toml
	@echo "cache-dir = \"~/.cache/uv\"" >> ~/.config/uv/config.toml
	@echo -e "${GREEN}✓${NC} uv configured"

# Install Poetry
install-poetry:
	@echo -e "${BLUE}ℹ${NC} Installing Poetry..."
	@if command -v poetry &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Poetry already installed, updating..."; \
		poetry self update 2>/dev/null || true; \
	else \
		curl -sSL $(POETRY_INSTALLER) | python3 - 2>&1 | tee -a $(LOG_FILE) || \
		echo -e "${YELLOW}⚠${NC} Poetry installation failed, continuing..."; \
	fi
	@# Configure Poetry (only if successfully installed)
	@if command -v poetry &> /dev/null; then \
		poetry config virtualenvs.in-project true 2>/dev/null || true; \
		poetry config virtualenvs.create true 2>/dev/null || true; \
		echo -e "${GREEN}✓${NC} Poetry configured"; \
	fi

# Install Conda/Miniconda
install-conda:
	@echo -e "${BLUE}ℹ${NC} Installing Miniconda..."
	@if [ -d "$$HOME/miniconda3" ] || [ -d "$$HOME/anaconda3" ]; then \
		echo -e "${GREEN}✓${NC} Conda already installed"; \
	else \
		wget -O /tmp/miniconda.sh $(CONDA_INSTALLER) 2>&1 | tee -a $(LOG_FILE); \
		bash /tmp/miniconda.sh -b -p $$HOME/miniconda3 2>&1 | tee -a $(LOG_FILE); \
		rm /tmp/miniconda.sh; \
		echo -e "${GREEN}✓${NC} Miniconda installed"; \
	fi
	@# Initialize conda
	@~/miniconda3/bin/conda init bash zsh 2>/dev/null || true
	@# Configure conda
	@~/miniconda3/bin/conda config --set auto_activate_base false
	@~/miniconda3/bin/conda config --add channels conda-forge
	@~/miniconda3/bin/conda config --add channels pytorch
	@~/miniconda3/bin/conda config --add channels nvidia
	@echo -e "${GREEN}✓${NC} Conda configured"

# Install Mamba (Fast conda alternative)
install-mamba:
	@echo -e "${BLUE}ℹ${NC} Installing Mamba (Miniforge)..."
	@if command -v mamba &> /dev/null || [ -d "$$HOME/miniforge3" ]; then \
		echo -e "${GREEN}✓${NC} Mamba already installed"; \
	else \
		wget -O /tmp/miniforge.sh $(MAMBA_INSTALLER) 2>&1 | tee -a $(LOG_FILE); \
		bash /tmp/miniforge.sh -b -p $$HOME/miniforge3 2>&1 | tee -a $(LOG_FILE); \
		rm /tmp/miniforge.sh; \
		echo -e "${GREEN}✓${NC} Mamba installed"; \
	fi
	@# Add to PATH
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q "miniforge3" $$rc; then \
			echo 'export PATH="$$HOME/miniforge3/bin:$$PATH"' >> $$rc; \
		fi; \
	done

# Install pipx for isolated tool installations
install-pipx:
	@echo -e "${BLUE}ℹ${NC} Installing pipx..."
	@if command -v pipx &> /dev/null; then \
		echo -e "${GREEN}✓${NC} pipx already installed"; \
	else \
		if command -v uv &> /dev/null; then \
			uv tool install pipx 2>/dev/null || true; \
		elif command -v pip3 &> /dev/null; then \
			python3 -m pip install --user pipx 2>&1 | tee -a $(LOG_FILE) || true; \
			python3 -m pipx ensurepath 2>/dev/null || true; \
		fi; \
		if command -v pipx &> /dev/null; then \
			echo -e "${GREEN}✓${NC} pipx installed"; \
		else \
			echo -e "${YELLOW}⚠${NC} pipx installation failed, continuing..."; \
		fi; \
	fi

# Install Python formatters
install-formatters:
	@echo -e "${BLUE}ℹ${NC} Installing Python formatters..."
	@uv tool install ruff --with ruff-lsp  # Ultra-fast Rust-based linter/formatter
	@pipx install black
	@pipx install isort
	@pipx install autopep8
	@pipx install yapf
	@pipx install blue  # Black but with single quotes
	@echo -e "${GREEN}✓${NC} Formatters installed"

# Install cutting-edge Python tools (2024-2025 innovations)
install-modern-tools:
	@echo -e "${BLUE}ℹ${NC} Installing modern Python tools..."
	@# Package management
	@echo -e "${YELLOW}Installing Pixi (conda-forge package manager)...${NC}"
	@curl -fsSL https://pixi.sh/install.sh | bash 2>/dev/null || true
	@# Build tools
	@pipx install maturin  # Build/publish Rust-based Python extensions
	@pipx install hatch  # Modern Python project management
	@pipx install pdm  # Modern Python package manager
	@# Data tools
	@uv tool install polars  # Lightning-fast DataFrame library
	@pipx install duckdb  # In-process SQL OLAP database
	@# Type checking and validation
	@pipx install pydantic  # Data validation using Python type annotations
	@pipx install pydantic-ai  # AI framework from Pydantic team
	@pipx install mypy
	@pipx install pyright
	@pipx install beartype  # Runtime type checking
	@# Performance tools
	@pipx install scalene  # High-performance CPU/GPU/memory profiler
	@pipx install memray  # Memory profiler by Bloomberg
	@pipx install py-spy  # Sampling profiler
	@pipx install austin  # Frame stack sampler
	@# Modern web frameworks
	@pipx install litestar  # High-performance ASGI framework
	@pipx install "fastapi[all]"
	@pipx install reflex  # Full-stack Python framework
	@# AI/LLM tools
	@pipx install langchain
	@pipx install llama-index
	@pipx install instructor  # Structured extraction with LLMs
	@pipx install marvin  # AI engineering toolkit
	@pipx install outlines  # Structured text generation
	@echo -e "${GREEN}✓${NC} Modern tools installed"

# Install Python linters
install-linters:
	@echo -e "${BLUE}ℹ${NC} Installing Python linters..."
	@pipx install flake8
	@pipx install pylint
	@pipx install mypy
	@pipx install pyright
	@pipx install bandit  # Security linter
	@pipx install vulture  # Dead code finder
	@pipx install pydocstyle  # Docstring linter
	@pipx install pycodestyle
	@pipx install mccabe  # Complexity checker
	@uv tool install semgrep
	@echo -e "${GREEN}✓${NC} Linters installed"

# Install Python testing tools
install-testers:
	@echo -e "${BLUE}ℹ${NC} Installing Python testing tools..."
	@pipx install pytest --include-deps
	@pipx inject pytest pytest-cov pytest-xdist pytest-mock pytest-benchmark
	@pipx inject pytest pytest-asyncio pytest-timeout pytest-html pytest-sugar
	@pipx install tox
	@pipx install nox
	@pipx install hypothesis
	@pipx install locust  # Load testing
	@pipx install green  # Colorful test runner
	@pipx install nose2
	@uv tool install ward  # Modern test framework
	@echo -e "${GREEN}✓${NC} Testing tools installed"

# Install ML/AI frameworks
install-ml-frameworks:
	@echo -e "${BLUE}ℹ${NC} Installing ML/AI frameworks..."
	@# Create ML environment
	@python3 -m venv $(PYTHON_DIR)/ml-env
	@$(PYTHON_DIR)/ml-env/bin/pip install --upgrade pip setuptools wheel
	@# Core ML libraries
	@$(PYTHON_DIR)/ml-env/bin/pip install numpy pandas scipy scikit-learn
	@$(PYTHON_DIR)/ml-env/bin/pip install matplotlib seaborn plotly bokeh altair
	@# Deep Learning
	@$(PYTHON_DIR)/ml-env/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
	@$(PYTHON_DIR)/ml-env/bin/pip install tensorflow keras
	@$(PYTHON_DIR)/ml-env/bin/pip install jax jaxlib flax
	@# ML Tools
	@$(PYTHON_DIR)/ml-env/bin/pip install xgboost lightgbm catboost
	@$(PYTHON_DIR)/ml-env/bin/pip install optuna hyperopt ray[tune]
	@$(PYTHON_DIR)/ml-env/bin/pip install mlflow wandb tensorboard
	@# NLP
	@$(PYTHON_DIR)/ml-env/bin/pip install transformers datasets tokenizers
	@$(PYTHON_DIR)/ml-env/bin/pip install spacy nltk gensim
	@$(PYTHON_DIR)/ml-env/bin/python -m spacy download en_core_web_sm
	@# Computer Vision
	@$(PYTHON_DIR)/ml-env/bin/pip install opencv-python pillow scikit-image
	@$(PYTHON_DIR)/ml-env/bin/pip install albumentations imgaug
	@# AutoML
	@$(PYTHON_DIR)/ml-env/bin/pip install auto-sklearn autogluon pycaret
	@echo -e "${GREEN}✓${NC} ML/AI frameworks installed"

# Install Data Science tools
install-data-science:
	@echo -e "${BLUE}ℹ${NC} Installing Data Science tools..."
	@pipx install jupyterlab --include-deps
	@pipx inject jupyterlab notebook ipywidgets jupyterlab-git jupyterlab-lsp
	@pipx inject jupyterlab jupyterlab-code-formatter black isort
	@pipx install streamlit
	@pipx install gradio
	@pipx install datasette
	@pipx install papermill  # Parameterized notebooks
	@pipx install kedro  # Data pipeline framework
	@pipx install dvc  # Data version control
	@pipx install great-expectations  # Data validation
	@# Data manipulation tools
	@uv tool install polars
	@uv tool install duckdb
	@uv tool install pyarrow
	@uv tool install vaex
	@echo -e "${GREEN}✓${NC} Data Science tools installed"

# Install Cybersecurity tools
install-cybersecurity:
	@echo -e "${BLUE}ℹ${NC} Installing Cybersecurity tools..."
	@pipx install httpx  # Modern HTTP client
	@pipx install mitmproxy  # HTTP proxy
	@pipx install sqlmap  # SQL injection tool
	@pipx install impacket  # Network protocols
	@pipx install scapy  # Packet manipulation
	@pipx install pwntools  # CTF framework
	@pipx install volatility3  # Memory forensics
	@pipx install yara-python  # Pattern matching
	@pipx install pymetasploit3  # Metasploit API
	@pipx install shodan  # Shodan API
	@pipx install theHarvester  # OSINT
	@pipx install sherlock-project  # Username search
	@pipx install holehe  # Email OSINT
	@pipx install crackmapexec  # Network scanner
	@echo -e "${GREEN}✓${NC} Cybersecurity tools installed"

# Install Cloud tools
install-cloud-tools:
	@echo -e "${BLUE}ℹ${NC} Installing Cloud tools..."
	@# AWS
	@pipx install awscli
	@pipx install aws-sam-cli
	@pipx install chalice  # Serverless framework
	@pipx install awslogs
	@pipx install aws-shell
	@uv tool install boto3-stubs[essential]
	@# Azure
	@pipx install azure-cli
	@# Google Cloud
	@pipx install gcloud
	@# Multi-cloud
	@pipx install terraform-compliance
	@pipx install checkov  # IaC security scanner
	@pipx install cloudsplaining  # AWS IAM scanner
	@pipx install prowler  # Cloud security tool
	@pipx install pacu  # AWS exploitation framework
	@# Kubernetes
	@pipx install kubectl
	@pipx install k9s
	@pipx install kubepy
	@pipx install ansible
	@pipx install ansible-lint
	@echo -e "${GREEN}✓${NC} Cloud tools installed"

# Install Web frameworks
install-web-frameworks:
	@echo -e "${BLUE}ℹ${NC} Installing Web frameworks..."
	@pipx install django
	@pipx install fastapi
	@pipx install flask
	@pipx install pyramid
	@pipx install tornado
	@pipx install sanic
	@pipx install aiohttp
	@pipx install uvicorn[standard]
	@pipx install gunicorn
	@pipx install hypercorn
	@pipx install daphne
	@pipx install locust  # Load testing
	@echo -e "${GREEN}✓${NC} Web frameworks installed"

# Install development tools
install-devtools:
	@echo -e "${BLUE}ℹ${NC} Installing development tools..."
	@pipx install ipython
	@pipx install bpython
	@pipx install ptpython
	@pipx install python-lsp-server[all]
	@pipx install cookiecutter  # Project templates
	@pipx install copier  # Project scaffolding
	@pipx install pre-commit
	@pipx install commitizen
	@pipx install bump2version
	@pipx install towncrier  # Changelog management
	@pipx install invoke  # Task runner
	@pipx install doit  # Build tool
	@pipx install pydeps  # Dependency visualization
	@pipx install pipdeptree
	@pipx install pip-tools
	@pipx install pip-audit  # Security audit
	@pipx install safety  # Security check
	@pipx install licensecheck
	@uv tool install hatch  # Modern project manager
	@uv tool install pdm  # Another package manager
	@uv tool install flit  # Simple packaging
	@echo -e "${GREEN}✓${NC} Development tools installed"

# Install Jupyter and extensions
install-jupyter:
	@echo -e "${BLUE}ℹ${NC} Installing Jupyter ecosystem..."
	@# Jupyter Lab extensions
	@jupyter labextension install @jupyter-widgets/jupyterlab-manager
	@jupyter labextension install @jupyterlab/toc
	@jupyter labextension install @aquirdturtle/collapsible_headings
	@jupyter labextension install jupyterlab-plotly
	@jupyter labextension install @bokeh/jupyter_bokeh
	@# Jupyter kernels
	@python3 -m ipykernel install --user --name python3
	@# Additional kernels (if languages installed)
	@if command -v julia &> /dev/null; then \
		julia -e 'using Pkg; Pkg.add("IJulia")' 2>/dev/null || true; \
	fi
	@if command -v R &> /dev/null; then \
		R -e 'install.packages("IRkernel"); IRkernel::installspec()' 2>/dev/null || true; \
	fi
	@echo -e "${GREEN}✓${NC} Jupyter ecosystem installed"

# Configure Python environment
configure-python:
	@echo -e "${BLUE}ℹ${NC} Configuring Python environment..."
	@# Create directories
	@mkdir -p ~/.config/pip
	@mkdir -p ~/.config/pypoetry
	@mkdir -p ~/.config/ruff
	@mkdir -p ~/.config/mypy
	@mkdir -p $(PYTHON_DIR)/{envs,projects,notebooks}
	@# Pip configuration
	@cat > ~/.config/pip/pip.conf <<-EOF
		[global]
		user = true
		break-system-packages = true
		timeout = 60
		index-url = https://pypi.org/simple
		extra-index-url = https://pypi.python.org/simple
		trusted-host = pypi.org pypi.python.org

		[install]
		compile = true
		progress-bar = on

		[list]
		format = columns
	EOF
	@# Ruff configuration
	@cat > ~/.config/ruff/ruff.toml <<-EOF
		line-length = 100
		target-version = "py312"

		[lint]
		select = ["E", "F", "I", "N", "W", "UP", "B", "C4", "SIM", "RUF"]
		ignore = ["E501"]

		[format]
		quote-style = "double"
		indent-style = "space"
		docstring-code-format = true
	EOF
	@# MyPy configuration
	@cat > ~/.config/mypy/config <<-EOF
		[mypy]
		python_version = 3.12
		warn_return_any = True
		warn_unused_configs = True
		disallow_untyped_defs = True
		disallow_any_unimported = True
		no_implicit_optional = True
		warn_redundant_casts = True
		warn_unused_ignores = True
		warn_no_return = True
		warn_unreachable = True
		strict_equality = True
	EOF
	@echo -e "${GREEN}✓${NC} Python environment configured"

# Create example environments
create-environments:
	@echo -e "${BLUE}ℹ${NC} Creating example environments..."
	@# Data Science environment
	@uv venv $(PYTHON_DIR)/envs/datascience
	@$(PYTHON_DIR)/envs/datascience/bin/pip install pandas numpy scipy matplotlib seaborn jupyter
	@# Web API environment
	@uv venv $(PYTHON_DIR)/envs/webapi
	@$(PYTHON_DIR)/envs/webapi/bin/pip install fastapi uvicorn sqlalchemy redis celery
	@# Security environment
	@uv venv $(PYTHON_DIR)/envs/security
	@$(PYTHON_DIR)/envs/security/bin/pip install requests cryptography paramiko nmap-python
	@echo -e "${GREEN}✓${NC} Example environments created"

# Verify Python installation
verify-python:
	@echo -e "${BLUE}ℹ${NC} Verifying Python installation..."
	@echo "=== Python Versions ==="
	@if command -v pyenv &> /dev/null; then \
		pyenv versions; \
	fi
	@echo ""
	@echo "=== Package Managers ==="
	@command -v uv &> /dev/null && echo -e "  ${GREEN}✓${NC} uv: $$(uv --version)"
	@command -v poetry &> /dev/null && echo -e "  ${GREEN}✓${NC} poetry: $$(poetry --version)"
	@command -v pipx &> /dev/null && echo -e "  ${GREEN}✓${NC} pipx: $$(pipx --version)"
	@command -v conda &> /dev/null && echo -e "  ${GREEN}✓${NC} conda: $$(conda --version)"
	@command -v mamba &> /dev/null && echo -e "  ${GREEN}✓${NC} mamba: $$(mamba --version)"
	@echo ""
	@echo "=== Formatters & Linters ==="
	@command -v black &> /dev/null && echo -e "  ${GREEN}✓${NC} black installed"
	@command -v ruff &> /dev/null && echo -e "  ${GREEN}✓${NC} ruff installed"
	@command -v mypy &> /dev/null && echo -e "  ${GREEN}✓${NC} mypy installed"
	@echo ""
	@echo "=== Testing Tools ==="
	@command -v pytest &> /dev/null && echo -e "  ${GREEN}✓${NC} pytest installed"
	@command -v tox &> /dev/null && echo -e "  ${GREEN}✓${NC} tox installed"
	@echo ""
	@echo "=== Development Tools ==="
	@command -v jupyter &> /dev/null && echo -e "  ${GREEN}✓${NC} jupyter installed"
	@command -v ipython &> /dev/null && echo -e "  ${GREEN}✓${NC} ipython installed"
	@echo -e "${GREEN}✓${NC} Python verification complete"

# Help
help-python:
	@echo "ArmyknifeLabs Python Ecosystem Module"
	@echo "The most comprehensive Python development environment"
	@echo ""
	@echo "Installation Profiles:"
	@echo "  make all      - Complete installation (recommended)"
	@echo "  make minimal  - Basic setup with essential tools"
	@echo ""
	@echo "Components:"
	@echo "  install-system-deps    - System libraries and dependencies"
	@echo "  install-pyenv         - Python version manager"
	@echo "  install-python-versions - Multiple Python versions"
	@echo "  install-uv            - Ultra-fast package manager"
	@echo "  install-poetry        - Dependency management"
	@echo "  install-conda         - Scientific Python distribution"
	@echo "  install-mamba         - Fast conda alternative"
	@echo "  install-pipx          - Isolated tool installations"
	@echo "  install-formatters    - Code formatters (black, ruff, etc.)"
	@echo "  install-linters       - Code linters and analyzers"
	@echo "  install-testers       - Testing frameworks and tools"
	@echo "  install-ml-frameworks - AI/ML libraries (PyTorch, TensorFlow, etc.)"
	@echo "  install-data-science  - Data analysis and visualization"
	@echo "  install-cybersecurity - Security testing tools"
	@echo "  install-cloud-tools   - AWS, Azure, GCP SDKs and tools"
	@echo "  install-web-frameworks - Django, FastAPI, Flask, etc."
	@echo "  install-devtools      - Development utilities"
	@echo "  install-jupyter       - Jupyter Lab and extensions"
	@echo ""
	@echo "Configuration:"
	@echo "  configure-python      - Set up config files and directories"
	@echo "  create-environments   - Create example virtual environments"
	@echo "  verify-python         - Verify installation"
	@echo ""
	@echo "Python Versions: $(PYTHON_VERSIONS)"
	@echo "Default Version: $(DEFAULT_PYTHON)"