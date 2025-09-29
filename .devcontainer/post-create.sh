#!/bin/bash
# Post-create script for ArmyknifeLabs Platform dev container

echo "=========================================="
echo "Setting up ArmyknifeLabs Dev Environment"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create necessary directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p ~/.armyknife/{bin,lib,config,logs,cache}
mkdir -p ~/workspace

# Set up the library path
echo -e "${BLUE}Setting up library path...${NC}"
if [ -d "/workspace/lib" ]; then
    cp -r /workspace/lib/* ~/.armyknife/lib/ 2>/dev/null || true
fi

# Source the core library
if [ -f ~/.armyknife/lib/core.sh ]; then
    source ~/.armyknife/lib/core.sh
fi

# Make scripts executable
echo -e "${BLUE}Making scripts executable...${NC}"
chmod +x /workspace/install.sh 2>/dev/null || true
chmod +x /workspace/scripts/*.sh 2>/dev/null || true

# Run initial verification
echo -e "${BLUE}Running initial system check...${NC}"
if [ -f /workspace/scripts/verify-install.sh ]; then
    bash /workspace/scripts/verify-install.sh --quick
fi

# Display help information
echo ""
echo -e "${GREEN}=========================================="
echo "ArmyknifeLabs Development Container Ready!"
echo "==========================================${NC}"
echo ""
echo "Available commands:"
echo "  make help           - Show all available targets"
echo "  make verify-base    - Verify base installation"
echo "  make install-base   - Install base components"
echo "  make minimal        - Minimal installation"
echo "  make standard       - Standard installation"
echo "  make full          - Full installation"
echo ""
echo "Quick actions:"
echo "  ./install.sh        - Run one-liner installer"
echo "  ./scripts/interactive-install.sh - Interactive installer"
echo "  ./scripts/verify-install.sh      - Verify installation"
echo "  ./scripts/doctor.sh              - Diagnostic tool"
echo ""
echo "Test individual modules:"
echo "  make install-shell  - Install shell enhancements"
echo "  make install-shelltools - Install shell tools"
echo "  make install-git    - Install git tools"
echo ""
echo -e "${YELLOW}Note: This is a containerized environment.${NC}"
echo -e "${YELLOW}Some system-level operations may be limited.${NC}"
echo ""