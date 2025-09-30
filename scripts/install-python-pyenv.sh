#!/usr/bin/env bash
# Install Python via pyenv with workarounds for pip installation issues
# This script handles the common pip --root '/' permission error

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PYTHON_VERSION="${1:-3.12.7}"
PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export PATH="$PYENV_ROOT/bin:$PATH"

echo -e "${BLUE}Installing Python $PYTHON_VERSION via pyenv...${NC}"

# Initialize pyenv
if [ -f "$PYENV_ROOT/bin/pyenv" ]; then
    eval "$($PYENV_ROOT/bin/pyenv init --path)"
    eval "$($PYENV_ROOT/bin/pyenv init -)"
else
    echo -e "${RED}Error: pyenv not found at $PYENV_ROOT${NC}"
    exit 1
fi

# Check if version is already installed
if pyenv versions | grep -q "$PYTHON_VERSION"; then
    echo -e "${GREEN}✓${NC} Python $PYTHON_VERSION already installed"
    exit 0
fi

# Set build configuration to avoid pip installation issues
export PYTHON_CONFIGURE_OPTS="--enable-shared --enable-optimizations --with-lto"
export PYTHON_CFLAGS="-march=native -O2"
export MAKE_OPTS="-j$(nproc)"

# Disable pip/setuptools installation during build to avoid permission issues
export PYENV_BOOTSTRAP_VERSION=none

echo -e "${YELLOW}Building Python $PYTHON_VERSION...${NC}"
echo "This may take several minutes..."

# Install Python
if pyenv install -v "$PYTHON_VERSION" 2>&1; then
    echo -e "${GREEN}✓${NC} Python $PYTHON_VERSION installed successfully"

    # Now install pip properly for this version
    echo -e "${BLUE}Installing pip for Python $PYTHON_VERSION...${NC}"

    # Switch to the new Python version temporarily
    PYENV_VERSION="$PYTHON_VERSION" python -m ensurepip --default-pip 2>/dev/null || {
        echo -e "${YELLOW}Installing pip via get-pip.py...${NC}"
        curl -sS https://bootstrap.pypa.io/get-pip.py | PYENV_VERSION="$PYTHON_VERSION" python
    }

    # Upgrade pip to latest
    PYENV_VERSION="$PYTHON_VERSION" python -m pip install --upgrade pip setuptools wheel

    echo -e "${GREEN}✓${NC} Python $PYTHON_VERSION setup complete"
else
    echo -e "${RED}✗${NC} Failed to install Python $PYTHON_VERSION"
    echo -e "${YELLOW}Common issues and solutions:${NC}"
    echo "1. Missing build dependencies - run: make -f makefiles/Makefile.Python.mk install-system-deps"
    echo "2. SSL/TLS issues - try a newer Python version"
    echo "3. Disk space - check available space in /tmp and $HOME"
    echo ""
    echo "Alternative: Use the fast setup with uv instead:"
    echo "  make -f makefiles/Makefile.Python-Fast.mk all"
    exit 1
fi